import 'package:worknet/services/broadcast/broadcast_packet.dart';

// ════════════════════════════════════════════════════════════════════
// NearbyPeer — a discovered peer in the live feed
// ════════════════════════════════════════════════════════════════════

class NearbyPeer {
  final String userId;
  final ProfileSnapshot profile;
  final int hopCount;

  /// RSSI history for rolling average (last N samples)
  final List<int> _rssiSamples;

  /// When this peer was last seen (for TTL eviction)
  final DateTime lastSeenAt;

  /// Endpoint ID from the proximity library (for relay purposes)
  final String? endpointId;

  NearbyPeer({
    required this.userId,
    required this.profile,
    required this.hopCount,
    required this.lastSeenAt,
    List<int> rssiSamples = const [],
    this.endpointId,
  }) : _rssiSamples = List.of(rssiSamples);

  // ── RSSI helpers ─────────────────────────────────────────────────

  int get rssiAverage {
    if (_rssiSamples.isEmpty) return -100;
    return _rssiSamples.reduce((a, b) => a + b) ~/ _rssiSamples.length;
  }

  NearbyPeer withNewRssi(int rssi, {int maxSamples = 5}) {
    final updated = List<int>.from(_rssiSamples);
    if (updated.length >= maxSamples) updated.removeAt(0);
    updated.add(rssi);
    return copyWith(rssiSamples: updated, lastSeenAt: DateTime.now());
  }

  // ── Hop label ────────────────────────────────────────────────────

  String get hopLabel => switch (hopCount) {
        0 => 'Direct',
        1 => 'Nearby',
        _ => 'In Venue',
      };

  // ── copyWith ─────────────────────────────────────────────────────

  NearbyPeer copyWith({
    ProfileSnapshot? profile,
    int? hopCount,
    List<int>? rssiSamples,
    DateTime? lastSeenAt,
    String? endpointId,
  }) {
    return NearbyPeer(
      userId:      userId,
      profile:     profile ?? this.profile,
      hopCount:    hopCount ?? this.hopCount,
      rssiSamples: rssiSamples ?? _rssiSamples,
      lastSeenAt:  lastSeenAt ?? this.lastSeenAt,
      endpointId:  endpointId ?? this.endpointId,
    );
  }
}
