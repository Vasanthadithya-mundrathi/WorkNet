import 'package:worknet/core/constants/worknet_constants.dart';
import 'package:worknet/services/broadcast/broadcast_packet.dart';

// ════════════════════════════════════════════════════════════════════
// SeenCache — deduplicates gossip relay packets
// Evicts entries after TTL and caps size to maxEntries
// ════════════════════════════════════════════════════════════════════

class SeenCache {
  final int ttlMs;
  final int maxEntries;

  /// dedupKey → timestamp when first seen
  final Map<String, int> _cache = {};

  SeenCache({
    this.ttlMs    = WorkNetConstants.packetTtlMs,
    this.maxEntries = WorkNetConstants.seenCacheMaxEntries,
  });

  /// Returns true if the packet was already seen (should be dropped).
  /// Returns false and records it if it's new.
  bool isSeen(BroadcastPacket packet) {
    _evictStale();
    final key = packet.dedupKey;
    if (_cache.containsKey(key)) return true;
    _record(key);
    return false;
  }

  void _record(String key) {
    if (_cache.length >= maxEntries) {
      // Evict the oldest entry
      final oldest = _cache.entries
          .reduce((a, b) => a.value < b.value ? a : b)
          .key;
      _cache.remove(oldest);
    }
    _cache[key] = DateTime.now().millisecondsSinceEpoch;
  }

  void _evictStale() {
    final now = DateTime.now().millisecondsSinceEpoch;
    _cache.removeWhere((_, ts) => now - ts > ttlMs);
  }

  void clear() => _cache.clear();

  int get size => _cache.length;
}
