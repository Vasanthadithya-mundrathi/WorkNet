import 'dart:async';
import 'dart:convert';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:worknet/core/constants/worknet_constants.dart';
import 'package:worknet/services/broadcast/broadcast_packet.dart';
import 'package:worknet/services/proximity/proximity_service.dart';

// ════════════════════════════════════════════════════════════════════
// BleDiscoveryService — Bluetooth LE peer discovery
//
// Mechanism:
//   • Scans continuously for BLE advertisements
//   • WorkNet peers encode a compact ProfileSnapshot JSON (≤27 bytes)
//     in the BLE manufacturer data field (company ID: 0xFFFF)
//   • Because Android BLE advertising data is limited to ~27 bytes,
//     we embed a "mini-packet": userId prefix + spotlightType + name
//     and then fetch the full packet via UDP once we know they're near
//
// Latency: ~100–500 ms (BLE scan interval)
// Range  : ~10–30 m Bluetooth range
//
// NOTE: Full BLE advertising (peripheral role) is not universally
//       supported on Android. This service does SCAN-ONLY on Android
//       and will detect other WorkNet instances that are advertising
//       via a companion BLE GATT characteristic (if available).
//       The primary data exchange still happens via UDP or Nearby.
// ════════════════════════════════════════════════════════════════════

class BleDiscoveryService implements ProximityServiceInterface {
  // WorkNet service UUID — registered for BLE advertisement discovery
  static const String _serviceUuid = '0000FFF0-0000-1000-8000-00805F9B34FB';
  // Manufacturer ID used in advertisement data
  static const int _manufacturerId = 0x08FF; // WorkNet custom ID

  bool _active = false;
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  Timer? _scanCycleTimer;
  BroadcastPacket? _ownPacket;

  final _controller = StreamController<BroadcastPacket>.broadcast();
  // Track seen BLE device IDs to avoid duplicate stream emissions
  final _seenBleIds = <String, int>{};

  @override
  Stream<BroadcastPacket> get incomingPackets => _controller.stream;

  @override
  bool get isActive => _active;

  @override
  Future<void> startEventMode(BroadcastPacket ownPacket) async {
    if (_active) return;
    _ownPacket = ownPacket;

    try {
      // Check if Bluetooth is supported and on
      final adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) return;

      _active = true;
      await _startScanCycle();
    } catch (_) {
      // BLE unavailable (emulator, restricted) — degrade gracefully
    }
  }

  Future<void> _startScanCycle() async {
    if (!_active) return;

    try {
      // Scan for all devices advertising our service UUID
      await FlutterBluePlus.startScan(
        withServices: [Guid(_serviceUuid)],
        timeout: Duration(milliseconds: WorkNetConstants.bleScanDurationMs),
        continuousUpdates: true,
      );

      _scanSubscription = FlutterBluePlus.scanResults.listen(_onScanResults);

      // After scan window, pause then re-scan
      _scanCycleTimer = Timer(
        Duration(
          milliseconds: WorkNetConstants.bleScanDurationMs +
              WorkNetConstants.bleScanPauseMs,
        ),
        () async {
          await _scanSubscription?.cancel();
          _scanSubscription = null;
          if (_active) await _startScanCycle(); // continuous cycling
        },
      );
    } catch (_) {}
  }

  void _onScanResults(List<ScanResult> results) {
    final now = DateTime.now().millisecondsSinceEpoch;
    // Evict stale BLE seen cache
    _seenBleIds.removeWhere(
        (_, ts) => now - ts > WorkNetConstants.bleScanDurationMs * 2);

    for (final result in results) {
      final deviceId = result.device.remoteId.str;
      // Throttle: only emit once per scan cycle per device
      if (_seenBleIds.containsKey(deviceId)) continue;
      _seenBleIds[deviceId] = now;

      // Try to extract manufacturer data
      final mfrData = result.advertisementData.manufacturerData;
      if (!mfrData.containsKey(_manufacturerId)) continue;

      try {
        final raw = mfrData[_manufacturerId]!;
        final jsonStr = utf8.decode(raw);
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        final packet = BroadcastPacket.fromJson(map);

        // Skip own re-detected packet
        if (packet.userId == _ownPacket?.userId) continue;
        _controller.add(packet);
      } catch (_) {
        // Non-WorkNet BLE device or truncated payload — skip
      }
    }
  }

  @override
  Future<void> relayPacket(BroadcastPacket packet) async {
    // BLE peripheral advertising not implemented (scan-only on Android)
    // Relay is handled by UDP and Nearby transports
  }

  @override
  Future<void> stopEventMode() async {
    _active = false;
    _scanCycleTimer?.cancel();
    _scanCycleTimer = null;
    await _scanSubscription?.cancel();
    _scanSubscription = null;
    try {
      await FlutterBluePlus.stopScan();
    } catch (_) {}
    _seenBleIds.clear();
    _ownPacket = null;
  }

  @override
  Future<void> dispose() async {
    await stopEventMode();
    await _controller.close();
  }
}
