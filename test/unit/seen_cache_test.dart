import 'package:flutter_test/flutter_test.dart';
import 'package:worknet/services/broadcast/seen_cache.dart';
import 'package:worknet/services/broadcast/broadcast_packet.dart';
import 'package:worknet/data/models/user_profile.dart';

void main() {
  group('SeenCache', () {
    late SeenCache cache;

    setUp(() {
      cache = SeenCache(ttlMs: 1000, maxEntries: 5);
    });

    test('new packet is NOT seen', () {
      final packet = _makePacket('user1', 1000);
      expect(cache.isSeen(packet), isFalse);
    });

    test('same packet seen twice → second call returns true', () {
      final packet = _makePacket('user1', 1000);
      cache.isSeen(packet);
      expect(cache.isSeen(packet), isTrue);
    });

    test('different timestamp = different packet (not seen)', () {
      final p1 = _makePacket('user1', 1000);
      final p2 = _makePacket('user1', 2000); // same user, new broadcast
      cache.isSeen(p1);
      expect(cache.isSeen(p2), isFalse);
    });

    test('evicts oldest entry when cap reached', () {
      for (int i = 0; i < 5; i++) {
        cache.isSeen(_makePacket('user$i', i));
      }
      expect(cache.size, equals(5));

      // Adding 6th should evict the oldest
      cache.isSeen(_makePacket('user99', 99));
      expect(cache.size, equals(5));
    });

    test('clear resets the cache', () {
      cache.isSeen(_makePacket('user1', 1));
      cache.clear();
      expect(cache.size, equals(0));
    });
  });
}

BroadcastPacket _makePacket(String userId, int timestamp) {
  return BroadcastPacket(
    userId: userId,
    profile: ProfileSnapshot(
      name: 'Test User',
      currentRole: 'Engineer',
      companyOrCollege: 'ACME',
      experienceLabel: '1–3 yrs',
      spotlightType: SpotlightType.exploring,
      spotlightNote: '',
      linkedInHandle: 'testuser',
    ),
    hopCount: 0,
    broadcastTimestamp: timestamp,
  );
}
