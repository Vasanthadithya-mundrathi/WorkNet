import 'dart:async';

import 'package:worknet/services/broadcast/broadcast_packet.dart';
import 'package:worknet/services/proximity/ble_discovery_service.dart';
import 'package:worknet/services/proximity/nearby_connections_service.dart';
import 'package:worknet/services/proximity/proximity_service.dart';
import 'package:worknet/services/proximity/supabase_discovery_service.dart';
import 'package:worknet/services/proximity/udp_discovery_service.dart';

// ════════════════════════════════════════════════════════════════════
// MultiTransportService — combines all discovery transports
//
// Priority  Transport          Latency    Range        Notes
// ─────────────────────────────────────────────────────────────────
// 1st       UDP Broadcast      ~50 ms     Same WiFi    Fastest
// 2nd       BLE Scan           ~200 ms    ~30 m        No WiFi needed
// 3rd       Nearby Connections ~1-2 s     ~100 m       BLE+WiFi Direct
// 4th       Supabase Realtime  internet   global       Cloud fallback
//
// All three run in parallel. Deduplication is handled upstream
// by SeenCache in GossipRelay (packet.dedupKey = userId+seq).
// ════════════════════════════════════════════════════════════════════

class MultiTransportService implements ProximityServiceInterface {
  final ProximityServiceInterface _udp;
  final ProximityServiceInterface _ble;
  final ProximityServiceInterface _nearby;
  final ProximityServiceInterface _supabase;

  late final Stream<BroadcastPacket> _merged;
  final _healthController = StreamController<TransportHealth>.broadcast();
  bool _active = false;

  MultiTransportService()
      : _udp = UdpDiscoveryService(),
        _ble = BleDiscoveryService(),
        _nearby = NearbyConnectionsService(),
        _supabase = SupabaseDiscoveryService() {
    // Merge all three transport streams into one
    _merged = StreamGroup.merge([
      _udp.incomingPackets,
      _ble.incomingPackets,
      _nearby.incomingPackets,
      _supabase.incomingPackets,
    ]);
  }

  @override
  Stream<BroadcastPacket> get incomingPackets => _merged;

  @override
  bool get isActive => _active;

  Stream<TransportHealth> get healthChanges => _healthController.stream;

  @override
  Future<void> startEventMode(BroadcastPacket ownPacket) async {
    if (_active) return;
    _active = true;

    // Start all transports concurrently — if one fails it won't block others
    await Future.wait([
      _safeStart('UDP', _udp, ownPacket),
      _safeStart('BLE', _ble, ownPacket),
      _safeStart('Nearby', _nearby, ownPacket),
      _safeStart('Cloud', _supabase, ownPacket),
    ]);
  }

  Future<void> _safeStart(
    String name,
    ProximityServiceInterface svc,
    BroadcastPacket packet,
  ) async {
    try {
      await svc.startEventMode(packet);
      _healthController.add(TransportHealth(
        name: name,
        available: svc.isActive,
      ));
    } catch (e) {
      _healthController.add(TransportHealth(
        name: name,
        available: false,
        message: e.toString(),
      ));
    }
  }

  @override
  Future<void> stopEventMode() async {
    _active = false;
    await Future.wait([
      _safeStop(_udp),
      _safeStop(_ble),
      _safeStop(_nearby),
      _safeStop(_supabase),
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
      _safeRelay(_supabase, packet),
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
      _supabase.dispose(),
    ]);
    await _healthController.close();
  }
}

class TransportHealth {
  final String name;
  final bool available;
  final String? message;

  const TransportHealth({
    required this.name,
    required this.available,
    this.message,
  });
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
