import 'dart:async';
import 'package:worknet/core/constants/worknet_constants.dart';
import 'package:worknet/services/broadcast/broadcast_packet.dart';
import 'package:worknet/services/broadcast/seen_cache.dart';
import 'package:worknet/services/proximity/proximity_service.dart';

// ════════════════════════════════════════════════════════════════════
// GossipRelay — handles the 2-hop mesh relay protocol
//
// On receiving a packet:
//   1. Drop if already in SeenCache (duplicate)
//   2. Emit to local feed stream
//   3. If hopCount < maxHopCount → relay with hopCount+1
//   4. Drop if hopCount >= maxHopCount
// ════════════════════════════════════════════════════════════════════

class GossipRelay {
  final ProximityServiceInterface _transport;
  final SeenCache _seenCache;

  final _outgoingController = StreamController<BroadcastPacket>.broadcast();

  /// Packets that passed dedup and should appear in the feed
  Stream<BroadcastPacket> get validatedPackets => _outgoingController.stream;

  StreamSubscription<BroadcastPacket>? _subscription;

  GossipRelay({
    required ProximityServiceInterface transport,
    SeenCache? seenCache,
  })  : _transport = transport,
        _seenCache = seenCache ?? SeenCache();

  void start() {
    _subscription = _transport.incomingPackets.listen(_handlePacket);
  }

  void _handlePacket(BroadcastPacket packet) {
    // Step 1: Dedup check
    if (_seenCache.isSeen(packet)) return;

    // Step 2: Emit to local feed
    _outgoingController.add(packet);

    // Step 3: Relay if within hop limit
    if (packet.hopCount < WorkNetConstants.maxHopCount) {
      _transport.relayPacket(packet.withIncrementedHop());
    }
    // Step 4: otherwise dropped (hop limit reached)
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    _seenCache.clear();
  }

  Future<void> dispose() async {
    await stop();
    await _outgoingController.close();
  }
}
