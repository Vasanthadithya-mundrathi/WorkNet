import 'dart:async';

import 'package:worknet/services/broadcast/broadcast_packet.dart';
import 'package:worknet/services/proximity/ble_discovery_service.dart';
import 'package:worknet/services/proximity/nearby_connections_service.dart';
import 'package:worknet/services/proximity/proximity_service.dart';
import 'package:worknet/services/proximity/udp_discovery_service.dart';

// ════════════════════════════════════════════════════════════════════
// MultiTransportService — combines all discovery transports
//
// Priority  Transport          Latency    Range        Notes
// ─────────────────────────────────────────────────────────────────
// 1st       UDP Broadcast      ~50 ms     Same WiFi    Fastest
// 2nd       BLE Scan           ~200 ms    ~30 m        No WiFi needed
// 3rd       Nearby Connections ~1-2 s     ~100 m       BLE+WiFi Direct
//
// All three run in parallel. Deduplication is handled upstream
// by SeenCache in GossipRelay (packet.dedupKey = userId+seq).
// ════════════════════════════════════════════════════════════════════

class MultiTransportService implements ProximityServiceInterface {
  final ProximityServiceInterface _udp;
  final ProximityServiceInterface _ble;
  final ProximityServiceInterface _nearby;

  late final Stream<BroadcastPacket> _merged;
  bool _active = false;

  MultiTransportService()
      : _udp    = UdpDiscoveryService(),
        _ble    = BleDiscoveryService(),
        _nearby = NearbyConnectionsService() {
    // Merge all three transport streams into one
    _merged = StreamGroup.merge([
      _udp.incomingPackets,
      _ble.incomingPackets,
      _nearby.incomingPackets,
    ]);
  }

  @override
  Stream<BroadcastPacket> get incomingPackets => _merged;

  @override
  bool get isActive => _active;

  @override
  Future<void> startEventMode(BroadcastPacket ownPacket) async {
    if (_active) return;
    _active = true;

    // Start all transports concurrently — if one fails it won't block others
    await Future.wait([
      _safeStart(_udp, ownPacket),
      _safeStart(_ble, ownPacket),
      _safeStart(_nearby, ownPacket),
    ]);
  }

  Future<void> _safeStart(
    ProximityServiceInterface svc,
    BroadcastPacket packet,
  ) async {
    try {
      await svc.startEventMode(packet);
    } catch (_) {
      // Individual transport failure must not crash the whole system
    }
  }

  @override
  Future<void> stopEventMode() async {
    _active = false;
    await Future.wait([
      _safeStop(_udp),
      _safeStop(_ble),
      _safeStop(_nearby),
    ]);
  }

  Future<void> _safeStop(ProximityServiceInterface svc) async {
    try {
      await svc.stopEventMode();
    } catch (_) {}
  }

  @override
  Future<void> relayPacket(BroadcastPacket packet) async {
    if (!_active) return;
    // Relay via UDP and Nearby (BLE relay not implemented — scan-only)
    await Future.wait([
      _safeRelay(_udp, packet),
      _safeRelay(_nearby, packet),
    ]);
  }

  Future<void> _safeRelay(
    ProximityServiceInterface svc,
    BroadcastPacket packet,
  ) async {
    try {
      await svc.relayPacket(packet);
    } catch (_) {}
  }

  @override
  Future<void> dispose() async {
    await Future.wait([
      _udp.dispose(),
      _ble.dispose(),
      _nearby.dispose(),
    ]);
  }
}

// ── StreamGroup helper (no extra dependency) ───────────────────────

class StreamGroup {
  static Stream<T> merge<T>(List<Stream<T>> streams) {
    final controller = StreamController<T>.broadcast();
    var activeCount = streams.length;

    for (final stream in streams) {
      stream.listen(
        controller.add,
        onError: controller.addError,
        onDone: () {
          activeCount--;
          if (activeCount == 0) {
            controller.close();
          }
        },
      );
    }

    return controller.stream;
  }
}
