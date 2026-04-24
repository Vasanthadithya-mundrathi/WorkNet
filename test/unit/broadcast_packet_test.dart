import 'package:flutter_test/flutter_test.dart';
import 'package:worknet/services/broadcast/broadcast_packet.dart';
import 'package:worknet/data/models/user_profile.dart';

void main() {
  group('BroadcastPacket', () {
    late BroadcastPacket packet;
    late ProfileSnapshot profile;

    setUp(() {
      profile = const ProfileSnapshot(
        name:             'Riya Sharma',
        currentRole:      'ML Engineer',
        companyOrCollege: 'Zepto',
        experienceLabel:  '1–3 yrs',
        spotlightType:    SpotlightType.hiring,
        spotlightNote:    'Hiring ML interns!',
        linkedInHandle:   'riya-sharma',
        skills:           ['PyTorch', 'Flutter', 'Python'],
      );

      packet = BroadcastPacket(
        userId:             'abc-123',
        profile:            profile,
        hopCount:           0,
        broadcastTimestamp: 1713000000000,
        version:            1,
      );
    });

    test('dedupKey is userId:timestamp', () {
      expect(packet.dedupKey, equals('abc-123:1713000000000'));
    });

    test('withIncrementedHop increases hopCount by 1', () {
      final relayed = packet.withIncrementedHop();
      expect(relayed.hopCount, equals(1));
      expect(relayed.userId, equals(packet.userId));
      expect(relayed.broadcastTimestamp, equals(packet.broadcastTimestamp));
    });

    test('serialize → deserialize round-trip', () {
      final bytes  = packet.toBytes();
      final parsed = BroadcastPacket.fromBytes(bytes);

      expect(parsed.userId,             equals(packet.userId));
      expect(parsed.hopCount,           equals(packet.hopCount));
      expect(parsed.broadcastTimestamp, equals(packet.broadcastTimestamp));
      expect(parsed.profile.name,       equals(profile.name));
      expect(parsed.profile.spotlightType, equals(SpotlightType.hiring));
      expect(parsed.profile.skills,     containsAll(['PyTorch', 'Flutter', 'Python']));
    });

    test('payload is within 1.5KB limit', () {
      final bytes = packet.toBytes();
      expect(bytes.length, lessThanOrEqualTo(1536));
    });

    test('linkedInUrl builds correctly', () {
      expect(profile.linkedInUrl,
          equals('https://linkedin.com/in/riya-sharma'));
    });

    test('hidden fields are not in JSON when null', () {
      final json = profile.toJson();
      expect(json.containsKey('a'), isFalse); // age hidden
      expect(json.containsKey('g'), isFalse); // gender hidden
    });
  });
}
