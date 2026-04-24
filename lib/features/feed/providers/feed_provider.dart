import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worknet/core/constants/worknet_constants.dart';
import 'package:worknet/data/models/nearby_peer.dart';
import 'package:worknet/data/models/user_profile.dart';
import 'package:worknet/data/repositories/profile_repository.dart';
import 'package:worknet/services/broadcast/broadcast_packet.dart';
import 'package:worknet/services/broadcast/gossip_relay.dart';
import 'package:worknet/services/broadcast/seen_cache.dart';
import 'package:worknet/services/proximity/multi_transport_service.dart';
import 'package:worknet/services/proximity/proximity_service.dart';

// ════════════════════════════════════════════════════════════════════
// FeedState — the live peer map + stealth flag
// ════════════════════════════════════════════════════════════════════

class FeedState {
  final Map<String, NearbyPeer> peers; // userId → NearbyPeer
  final bool isEventModeActive;
  final bool isStealthMode;
  final String? error;

  const FeedState({
    this.peers          = const {},
    this.isEventModeActive = false,
    this.isStealthMode  = false,
    this.error,
  });

  List<NearbyPeer> get sortedPeers {
    final list = peers.values.toList();
    // Primary: hop count (lower = closer); Secondary: RSSI (higher = closer)
    list.sort((a, b) {
      final hopCmp = a.hopCount.compareTo(b.hopCount);
      if (hopCmp != 0) return hopCmp;
      return b.rssiAverage.compareTo(a.rssiAverage);
    });
    return list;
  }

  int get hiringCount =>
      peers.values.where((p) => p.profile.spotlightType == SpotlightType.hiring).length;
  int get openToWorkCount =>
      peers.values.where((p) => p.profile.spotlightType == SpotlightType.openToWork).length;

  FeedState copyWith({
    Map<String, NearbyPeer>? peers,
    bool? isEventModeActive,
    bool? isStealthMode,
    String? error,
  }) =>
      FeedState(
        peers:              peers ?? this.peers,
        isEventModeActive:  isEventModeActive ?? this.isEventModeActive,
        isStealthMode:      isStealthMode ?? this.isStealthMode,
        error:              error,
      );
}

// ════════════════════════════════════════════════════════════════════
// FeedNotifier — manages the live peer feed
// ════════════════════════════════════════════════════════════════════

class FeedNotifier extends AsyncNotifier<FeedState> {
  late final ProximityServiceInterface _transport;
  late final GossipRelay _relay;
  StreamSubscription<BroadcastPacket>? _packetSub;
  Timer? _ttlTimer;

  @override
  Future<FeedState> build() async {
    _transport = MultiTransportService();
    _relay = GossipRelay(
      transport: _transport,
      seenCache: SeenCache(),
    );
    _relay.start();

    _packetSub = _relay.validatedPackets.listen(_onPacketReceived);

    // TTL eviction every 10 seconds
    _ttlTimer = Timer.periodic(const Duration(seconds: 10), (_) => _evictStalePeers());

    ref.onDispose(() async {
      _packetSub?.cancel();
      _ttlTimer?.cancel();
      await _relay.dispose();
      await _transport.dispose();
    });

    return const FeedState();
  }

  // ── Event Mode toggle ─────────────────────────────────────────────

  Future<void> startEventMode() async {
    final current = state.valueOrNull;
    if (current == null) return; // Feed not ready yet — bail
    if (current.isEventModeActive) return; // Already scanning

    final profile = await ref.read(myProfileProvider.future);
    if (profile == null) return; // No profile yet — bail gracefully

    try {
      final packet = BroadcastPacket.fromUserProfile(profile);
      await _transport.startEventMode(packet);
      state = AsyncData(current.copyWith(isEventModeActive: true));
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> stopEventMode() async {
    final current = state.valueOrNull;
    if (current == null) return;
    try {
      await _transport.stopEventMode();
      state = AsyncData(current.copyWith(isEventModeActive: false, peers: {}));
    } catch (_) {
      // Best-effort stop
    }
  }

  // ── Stealth Mode ──────────────────────────────────────────────────

  Future<void> toggleStealth() async {
    final current = state.valueOrNull;
    if (current == null) return;
    final repo = await ref.read(profileRepositoryProvider.future);
    final newStealth = !current.isStealthMode;
    await repo.setStealthMode(newStealth);

    if (newStealth) {
      await _transport.stopEventMode();
      state = AsyncData(current.copyWith(isStealthMode: true, isEventModeActive: false, peers: {}));
    } else {
      await startEventMode();
      state = AsyncData(state.valueOrNull!.copyWith(isStealthMode: false));
    }
  }

  // ── Packet handling ───────────────────────────────────────────────

  void _onPacketReceived(BroadcastPacket packet) {
    final current = state.valueOrNull;
    if (current == null) return;

    final existingPeer = current.peers[packet.userId];
    final updatedPeer = existingPeer != null
        ? existingPeer.copyWith(
            profile:     packet.profile,
            hopCount:    packet.hopCount,
            lastSeenAt:  DateTime.now(),
          )
        : NearbyPeer(
            userId:     packet.userId,
            profile:    packet.profile,
            hopCount:   packet.hopCount,
            lastSeenAt: DateTime.now(),
          );

    final updatedPeers = Map<String, NearbyPeer>.from(current.peers);
    updatedPeers[packet.userId] = updatedPeer;
    state = AsyncData(current.copyWith(peers: updatedPeers));
  }

  // ── TTL Eviction ──────────────────────────────────────────────────

  void _evictStalePeers() {
    final current = state.valueOrNull;
    if (current == null) return;
    final ttl = WorkNetConstants.packetTtlMs;
    final now = DateTime.now();
    final updated = Map<String, NearbyPeer>.from(current.peers)
      ..removeWhere((_, p) =>
          now.difference(p.lastSeenAt).inMilliseconds > ttl);
    if (updated.length != current.peers.length) {
      state = AsyncData(current.copyWith(peers: updated));
    }
  }
}

// ── Provider ─────────────────────────────────────────────────────

final feedProvider =
    AsyncNotifierProvider<FeedNotifier, FeedState>(FeedNotifier.new);
