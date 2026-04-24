import 'package:flutter_test/flutter_test.dart';
import 'package:worknet/data/models/user_profile.dart';
import 'package:worknet/services/broadcast/broadcast_packet.dart';
import 'package:worknet/services/broadcast/seen_cache.dart';

void main() {
  // Helper to create dummy packets quickly
  BroadcastPacket createPacket(String id, int timestamp) {
    return BroadcastPacket(
      userId: id,
      profile: const ProfileSnapshot(
        name: 'Test',
        currentRole: 'Test',
        companyOrCollege: 'Test',
        experienceLabel: 'Test',
        spotlightType: SpotlightType.exploring,
        spotlightNote: '',
        linkedInHandle: 'test',
      ),
      hopCount: 0,
      broadcastTimestamp: timestamp,
    );
  }

  group('SeenCache Stress Tests', () {
    test('Handles 10,000 rapid inserts and cleanups without performance degradation', () async {
      final cache = SeenCache(ttlMs: 500); // Short TTL for test
      final stopwatch = Stopwatch()..start();

      final baseTime = DateTime.now().millisecondsSinceEpoch;

      // Simulate a flood of packets (e.g., very dense conference)
      for (int i = 0; i < 10000; i++) {
        // Some duplicates, some unique
        final packet = createPacket('packet_${i % 1000}', baseTime);
        cache.isSeen(packet);
      }

      stopwatch.stop();
      // Should take less than 500ms for 10k lookups/inserts (includes object allocation overhead)
      expect(stopwatch.elapsedMilliseconds, lessThan(500));

      // Wait for TTL to pass
      await Future.delayed(const Duration(milliseconds: 600));

      // Force a cleanup by checking a new packet
      cache.isSeen(createPacket('new_packet', baseTime + 600));

      // Now the old 1000 unique packets should have been evicted
      // We know there were 1000 unique because `i % 1000`.
      expect(cache.isSeen(createPacket('packet_1', baseTime)), false,
          reason: 'Old packets should be evicted after TTL');
    });

    test('Eviction boundary logic works under load', () async {
      final cache = SeenCache(ttlMs: 200);
      final baseTime = DateTime.now().millisecondsSinceEpoch;

      // Insert 10 items
      for (int i = 0; i < 10; i++) {
        cache.isSeen(createPacket('item_$i', baseTime));
      }
      
      // They are duplicates right now
      expect(cache.isSeen(createPacket('item_5', baseTime)), true);

      await Future.delayed(const Duration(milliseconds: 250));

      // Insert one to trigger cleanup
      cache.isSeen(createPacket('trigger', baseTime + 250));

      // Now old items should be false (newly seen)
      expect(cache.isSeen(createPacket('item_5', baseTime)), false);
    });
  });
}
