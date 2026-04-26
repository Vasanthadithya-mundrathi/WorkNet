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
import 'package:worknet/services/proximity/foreground_discovery_service.dart';
import 'package:worknet/services/proximity/proximity_service.dart';
import 'package:worknet/services/permissions/permission_service.dart';

// ════════════════════════════════════════════════════════════════════
// FeedState — the live peer map + stealth flag
// ════════════════════════════════════════════════════════════════════

class FeedState {
  final Map<String, NearbyPeer> peers; // userId → NearbyPeer
  final bool isEventModeActive;
  final bool isStealthMode;
  final Map<String, TransportHealth> transportHealth;
  final String? error;

  const FeedState({
    this.peers = const {},
    this.isEventModeActive = false,
    this.isStealthMode = false,
    this.transportHealth = const {},
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

  int get hiringCount => peers.values
      .where((p) => p.profile.spotlightType == SpotlightType.hiring)
      .length;
  int get openToWorkCount => peers.values
      .where((p) => p.profile.spotlightType == SpotlightType.openToWork)
      .length;

  FeedState copyWith({
    Map<String, NearbyPeer>? peers,
    bool? isEventModeActive,
    bool? isStealthMode,
    Map<String, TransportHealth>? transportHealth,
    String? error,
  }) =>
      FeedState(
        peers: peers ?? this.peers,
        isEventModeActive: isEventModeActive ?? this.isEventModeActive,
        isStealthMode: isStealthMode ?? this.isStealthMode,
        transportHealth: transportHealth ?? this.transportHealth,
        error: error,
      );
}

// ════════════════════════════════════════════════════════════════════
// FeedNotifier — manages the live peer feed
// ════════════════════════════════════════════════════════════════════

class FeedNotifier extends AsyncNotifier<FeedState> {
  late final ProximityServiceInterface _transport;
  late final GossipRelay _relay;
  final _foregroundService = ForegroundDiscoveryService();
  StreamSubscription<BroadcastPacket>? _packetSub;
  StreamSubscription<TransportHealth>? _healthSub;
  Timer? _ttlTimer;
  bool _starting = false;

  @override
  Future<FeedState> build() async {
    _transport = MultiTransportService();
    _relay = GossipRelay(
      transport: _transport,
      seenCache: SeenCache(),
    );
    _relay.start();

    _packetSub = _relay.validatedPackets.listen(_onPacketReceived);
    final transport = _transport;
    if (transport is MultiTransportService) {
      _healthSub = transport.healthChanges.listen(_onTransportHealth);
    }

    // TTL eviction every 10 seconds
    _ttlTimer =
        Timer.periodic(const Duration(seconds: 10), (_) => _evictStalePeers());

    ref.onDispose(() async {
      await _packetSub?.cancel();
      await _healthSub?.cancel();
      _ttlTimer?.cancel();
      await _foregroundService.stop();
      await _relay.dispose();
      await _transport.dispose();
    });

    final profile = await ref.read(myProfileProvider.future);
    return FeedState(isStealthMode: profile?.stealthMode ?? false);
  }

  // ── Event Mode toggle ─────────────────────────────────────────────

  Future<void> startEventMode() async {
    final current = state.valueOrNull;
    if (current == null) return; // Feed not ready yet — bail
    if (current.isEventModeActive) return; // Already scanning
    if (_starting) return;

    final profile = await ref.read(myProfileProvider.future);
    if (profile == null) return; // No profile yet — bail gracefully
    if (profile.stealthMode) {
      state = AsyncData(current.copyWith(isStealthMode: true));
      return;
    }

    final permissions =
        await ref.read(permissionServiceProvider).checkDiscovery();
    if (permissions != WorkNetPermissionStatus.granted) {
      state = AsyncData(current.copyWith(
        isEventModeActive: false,
        error: 'Discovery permissions are not granted.',
      ));
      return;
    }

    _starting = true;
    try {
      final packet = BroadcastPacket.fromUserProfile(profile);
      _relay.setEnabled(true);
      await _transport.startEventMode(packet);
      await _foregroundService.start(peerCount: current.peers.length);
      state = AsyncData(current.copyWith(
        isEventModeActive: true,
        isStealthMode: false,
        error: null,
      ));
    } catch (e) {
      _relay.setEnabled(false);
      state = AsyncError(e, StackTrace.current);
    } finally {
      _starting = false;
    }
  }

  Future<void> stopEventMode() async {
    final current = state.valueOrNull;
    if (current == null) return;
    try {
      _relay.setEnabled(false);
      await _transport.stopEventMode();
      await _foregroundService.stop();
      state = AsyncData(current.copyWith(
        isEventModeActive: false,
        peers: {},
        transportHealth: {},
      ));
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
      _relay.setEnabled(false);
      await _transport.stopEventMode();
      await _foregroundService.stop();
      state = AsyncData(current.copyWith(
        isStealthMode: true,
        isEventModeActive: false,
        peers: {},
        transportHealth: {},
        error: null,
      ));
    } else {
      state = AsyncData(current.copyWith(isStealthMode: false));
      await startEventMode();
    }
  }

  // ── Packet handling ───────────────────────────────────────────────

  void _onPacketReceived(BroadcastPacket packet) {
    final current = state.valueOrNull;
    if (current == null) return;
    if (current.isStealthMode || !current.isEventModeActive) return;

    final existingPeer = current.peers[packet.userId];
    final updatedPeer = existingPeer != null
        ? existingPeer.copyWith(
            profile: packet.profile,
            hopCount: packet.hopCount,
            lastSeenAt: DateTime.now(),
          )
        : NearbyPeer(
            userId: packet.userId,
            profile: packet.profile,
            hopCount: packet.hopCount,
            lastSeenAt: DateTime.now(),
          );

    final updatedPeers = Map<String, NearbyPeer>.from(current.peers);
    updatedPeers[packet.userId] = updatedPeer;
    state = AsyncData(current.copyWith(peers: updatedPeers));
    _foregroundService.updatePeerCount(updatedPeers.length);
  }

  void _onTransportHealth(TransportHealth health) {
    final current = state.valueOrNull;
    if (current == null) return;
    final updated = Map<String, TransportHealth>.from(current.transportHealth);
    updated[health.name] = health;
    state = AsyncData(current.copyWith(transportHealth: updated));
  }

  // ── TTL Eviction ──────────────────────────────────────────────────

  void _evictStalePeers() {
    final current = state.valueOrNull;
    if (current == null) return;
    final ttl = WorkNetConstants.packetTtlMs;
    final now = DateTime.now();
    final updated = Map<String, NearbyPeer>.from(current.peers)
      ..removeWhere(
          (_, p) => now.difference(p.lastSeenAt).inMilliseconds > ttl);
    if (updated.length != current.peers.length) {
      state = AsyncData(current.copyWith(peers: updated));
    }
  }
}

// ── Provider ─────────────────────────────────────────────────────

final feedProvider =
    AsyncNotifierProvider<FeedNotifier, FeedState>(FeedNotifier.new);
