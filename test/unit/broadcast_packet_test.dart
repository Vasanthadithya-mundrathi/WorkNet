import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:worknet/services/broadcast/broadcast_packet.dart';
import 'package:worknet/data/models/user_profile.dart';

void main() {
  group('BroadcastPacket', () {
    late BroadcastPacket packet;
    late ProfileSnapshot profile;

    setUp(() {
      profile = const ProfileSnapshot(
        name: 'Riya Sharma',
        currentRole: 'ML Engineer',
        companyOrCollege: 'Zepto',
        experienceLabel: '1–3 yrs',
        spotlightType: SpotlightType.hiring,
        spotlightNote: 'Hiring ML interns!',
        linkedInHandle: 'riya-sharma',
        skills: ['PyTorch', 'Flutter', 'Python'],
      );

      packet = BroadcastPacket(
        userId: 'abc-123',
        profile: profile,
        hopCount: 0,
        broadcastTimestamp: DateTime.now().millisecondsSinceEpoch,
        version: 1,
      );
    });

    test('dedupKey is userId:timestamp', () {
      expect(packet.dedupKey, equals('abc-123:${packet.broadcastTimestamp}'));
    });

    test('withIncrementedHop increases hopCount by 1', () {
      final relayed = packet.withIncrementedHop();
      expect(relayed.hopCount, equals(1));
      expect(relayed.userId, equals(packet.userId));
      expect(relayed.broadcastTimestamp, equals(packet.broadcastTimestamp));
    });

    test('serialize → deserialize round-trip', () {
      final bytes = packet.toBytes();
      final parsed = BroadcastPacket.fromBytes(bytes);

      expect(parsed.userId, equals(packet.userId));
      expect(parsed.hopCount, equals(packet.hopCount));
      expect(parsed.broadcastTimestamp, equals(packet.broadcastTimestamp));
      expect(parsed.profile.name, equals(profile.name));
      expect(parsed.profile.spotlightType, equals(SpotlightType.hiring));
      expect(
          parsed.profile.skills, containsAll(['PyTorch', 'Flutter', 'Python']));
    });

    test('payload is within 1.5KB limit', () {
      final bytes = packet.toBytes();
      expect(bytes.length, lessThanOrEqualTo(1536));
    });

    test('linkedInUrl builds correctly', () {
      expect(
          profile.linkedInUrl, equals('https://linkedin.com/in/riya-sharma'));
    });

    test('hidden fields are not in JSON when null', () {
      final json = profile.toJson();
      expect(json.containsKey('a'), isFalse); // age hidden
      expect(json.containsKey('g'), isFalse); // gender hidden
    });

    test('avatar is only serialized when present', () {
      const withAvatar = ProfileSnapshot(
        name: 'Riya Sharma',
        currentRole: 'ML Engineer',
        companyOrCollege: 'Zepto',
        experienceLabel: '1-3 yrs',
        spotlightType: SpotlightType.hiring,
        spotlightNote: 'Hiring ML interns!',
        linkedInHandle: 'riya-sharma',
        avatarThumbBase64: 'abc123',
        avatarHash: 'hash',
      );

      expect(profile.toJson().containsKey('av'), isFalse);
      expect(withAvatar.toJson()['av'], equals('abc123'));
      expect(withAvatar.toJson()['ah'], equals('hash'));
    });

    test('rejects malformed or unsafe packet envelopes', () {
      final json = packet.toJson();
      expect(
        () => BroadcastPacket.fromJson({...json, 'h': 99}),
        throwsFormatException,
      );
      expect(
        () => BroadcastPacket.fromJson({...json, 'v': 999}),
        throwsFormatException,
      );
      expect(
        () => BroadcastPacket.fromJson({
          ...json,
          't': DateTime.now().millisecondsSinceEpoch + 600000,
        }),
        throwsFormatException,
      );
    });

    test('rejects oversized packet payloads', () {
      final oversized = BroadcastPacket(
        userId: 'abc-123',
        profile: const ProfileSnapshot(
          name: 'Riya Sharma',
          currentRole: 'ML Engineer',
          companyOrCollege: 'Zepto',
          experienceLabel: '1-3 yrs',
          spotlightType: SpotlightType.hiring,
          spotlightNote: 'Hiring ML interns!',
          linkedInHandle: 'riya-sharma',
          avatarThumbBase64: String.fromEnvironment('unused'),
        ),
        hopCount: 0,
        broadcastTimestamp: DateTime.now().millisecondsSinceEpoch,
      );

      final json = oversized.toJson();
      json['p'] = {
        ...(json['p'] as Map<String, dynamic>),
        'av': 'a' * 20000,
      };
      final bytes = utf8.encode(jsonEncode(json));
      expect(() => BroadcastPacket.fromBytes(bytes), throwsFormatException);
    });
  });
}
