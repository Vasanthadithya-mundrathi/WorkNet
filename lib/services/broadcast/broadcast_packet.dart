import 'dart:convert';
import 'package:worknet/core/constants/worknet_constants.dart';
import 'package:worknet/data/models/user_profile.dart';

// ════════════════════════════════════════════════════════════════════
// BroadcastPacket — wire format over BLE/WiFi mesh
// ════════════════════════════════════════════════════════════════════

class BroadcastPacket {
  final String userId;
  final ProfileSnapshot profile;
  final int hopCount;
  final int broadcastTimestamp;
  final int version;
  final String? signature;

  const BroadcastPacket({
    required this.userId,
    required this.profile,
    required this.hopCount,
    required this.broadcastTimestamp,
    this.version = 1,
    this.signature,
  });

  String get dedupKey => '$userId:$broadcastTimestamp';

  BroadcastPacket withIncrementedHop() => BroadcastPacket(
        userId: userId,
        profile: profile,
        hopCount: hopCount + 1,
        broadcastTimestamp: broadcastTimestamp,
        version: version,
        signature: signature,
      );

  BroadcastPacket refreshedForBroadcast({int hopCount = 0}) => BroadcastPacket(
        userId: userId,
        profile: profile,
        hopCount: hopCount,
        broadcastTimestamp: DateTime.now().millisecondsSinceEpoch,
        version: version,
        signature: signature,
      );

  Map<String, dynamic> toJson() => {
        'uid': userId,
        'p': profile.toJson(),
        'h': hopCount,
        't': broadcastTimestamp,
        'v': version,
        if (signature != null) 's': signature,
      };

  factory BroadcastPacket.fromJson(Map<String, dynamic> json) {
    final version = (json['v'] as int?) ?? 1;
    if (version != WorkNetConstants.packetSchemaVersion) {
      throw const FormatException('Unsupported packet schema version');
    }

    final userId = _readString(json, 'uid', max: 80);
    final hopCount = _readInt(json, 'h');
    final timestamp = _readInt(json, 't');
    _validatePacketEnvelope(userId, hopCount, timestamp);

    return BroadcastPacket(
      userId: userId,
      profile: ProfileSnapshot.fromJson(json['p'] as Map<String, dynamic>),
      hopCount: hopCount,
      broadcastTimestamp: timestamp,
      version: version,
      signature: json['s'] as String?,
    );
  }

  List<int> toBytes() {
    final bytes = utf8.encode(jsonEncode(toJson()));
    if (bytes.length > WorkNetConstants.maxPayloadBytes) {
      throw const FormatException('Packet exceeds payload limit');
    }
    return bytes;
  }

  factory BroadcastPacket.fromBytes(List<int> bytes) {
    if (bytes.length > WorkNetConstants.maxPayloadBytes) {
      throw const FormatException('Packet exceeds payload limit');
    }
    final json = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    return BroadcastPacket.fromJson(json);
  }

  factory BroadcastPacket.fromUserProfile(UserProfile p) {
    return BroadcastPacket(
      userId: p.userId,
      profile: ProfileSnapshot.fromUserProfile(p),
      hopCount: 0,
      broadcastTimestamp: DateTime.now().millisecondsSinceEpoch,
      version: WorkNetConstants.packetSchemaVersion,
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// ProfileSnapshot — profile data inside the packet
// ════════════════════════════════════════════════════════════════════

class ProfileSnapshot {
  final String name;
  final String currentRole;
  final String companyOrCollege;
  final String experienceLabel;
  final SpotlightType spotlightType;
  final String spotlightNote;
  final String linkedInHandle;
  final int? ageYears;
  final String? gender;
  final String? bio;
  final List<String>? skills;
  final List<Map<String, String>>? sections; // {heading, content}
  final List<Map<String, String>>? links; // {label, url}
  final String? avatarThumbBase64;
  final String? avatarHash;

  const ProfileSnapshot({
    required this.name,
    required this.currentRole,
    required this.companyOrCollege,
    required this.experienceLabel,
    required this.spotlightType,
    required this.spotlightNote,
    required this.linkedInHandle,
    this.ageYears,
    this.gender,
    this.bio,
    this.skills,
    this.sections,
    this.links,
    this.avatarThumbBase64,
    this.avatarHash,
  });

  String get linkedInUrl => 'https://linkedin.com/in/$linkedInHandle';

  Map<String, dynamic> toJson() => {
        'n': name,
        'r': currentRole,
        'c': companyOrCollege,
        'x': experienceLabel,
        'st': spotlightType.name,
        'sn': spotlightNote,
        'li': linkedInHandle,
        if (ageYears != null) 'a': ageYears,
        if (gender != null) 'g': gender,
        if (bio != null) 'b': bio,
        if (skills != null && skills!.isNotEmpty) 'sk': skills,
        if (sections != null && sections!.isNotEmpty) 'sc': sections,
        if (links != null && links!.isNotEmpty) 'lk': links,
        if (avatarThumbBase64 != null && avatarThumbBase64!.isNotEmpty)
          'av': avatarThumbBase64,
        if (avatarHash != null && avatarHash!.isNotEmpty) 'ah': avatarHash,
      };

  factory ProfileSnapshot.fromJson(Map<String, dynamic> j) {
    final spotlightName = _readString(j, 'st', max: 32);
    SpotlightType? spotlight;
    for (final type in SpotlightType.values) {
      if (type.name == spotlightName) {
        spotlight = type;
        break;
      }
    }
    if (spotlight == null) {
      throw const FormatException('Invalid spotlight type');
    }

    return ProfileSnapshot(
      name: _readString(j, 'n', max: WorkNetConstants.maxNameChars),
      currentRole: _readString(j, 'r', max: WorkNetConstants.maxRoleChars),
      companyOrCollege:
          _readString(j, 'c', max: WorkNetConstants.maxCompanyChars),
      experienceLabel:
          _readString(j, 'x', max: WorkNetConstants.maxExperienceChars),
      spotlightType: spotlight,
      spotlightNote: _readOptionalString(
            j,
            'sn',
            max: WorkNetConstants.spotlightNoteMaxChars,
          ) ??
          '',
      linkedInHandle: _sanitizeLinkedInHandle(_readString(j, 'li', max: 100)),
      ageYears: j['a'] as int?,
      gender: _readOptionalString(j, 'g', max: 60),
      bio: _readOptionalString(j, 'b', max: WorkNetConstants.bioMaxChars),
      skills: _readStringList(
        j,
        'sk',
        maxItems: WorkNetConstants.broadcastMaxSkills,
        maxItemChars: 40,
      ),
      sections: _readSections(j),
      links: _readLinks(j),
      avatarThumbBase64: _readOptionalString(
        j,
        'av',
        max: WorkNetConstants.avatarBroadcastMaxBase64Chars,
      ),
      avatarHash: _readOptionalString(j, 'ah', max: 96),
    );
  }

  factory ProfileSnapshot.fromUserProfile(UserProfile p) {
    return ProfileSnapshot(
      name: p.name,
      currentRole: p.currentRole,
      companyOrCollege: p.companyOrCollege,
      experienceLabel: p.experienceLabel,
      spotlightType: p.spotlightType,
      spotlightNote: p.spotlightNote,
      linkedInHandle: p.linkedInHandle,
      avatarThumbBase64: p.shareAvatar ? p.avatarThumbBase64 : null,
      avatarHash: p.shareAvatar ? p.avatarHash : null,
      ageYears: p.showAge ? p.ageYears : null,
      gender: p.showGender ? p.gender : null,
      bio: p.showBio ? p.bio : null,
      skills: p.showSkills && p.skills.isNotEmpty ? p.topBroadcastSkills : null,
      sections: p.customSections.isNotEmpty
          ? p.customSections
              .where((s) => s.isVisible && s.content.isNotEmpty)
              .map((s) => {'h': s.heading, 'c': s.content})
              .toList()
          : null,
      links: p.showLinks && p.links.isNotEmpty
          ? p.links
              .where((l) => l.url.isNotEmpty)
              .map((l) => {'l': l.label, 'u': l.url})
              .toList()
          : null,
    );
  }
}

void _validatePacketEnvelope(String userId, int hopCount, int timestamp) {
  if (userId.isEmpty) {
    throw const FormatException('Missing user id');
  }
  if (hopCount < 0 || hopCount > WorkNetConstants.maxHopCount) {
    throw const FormatException('Invalid hop count');
  }
  final now = DateTime.now().millisecondsSinceEpoch;
  if (timestamp > now + WorkNetConstants.maxPacketClockSkewMs) {
    throw const FormatException('Packet timestamp is in the future');
  }
  if (now - timestamp > WorkNetConstants.maxPacketAgeMs) {
    throw const FormatException('Packet is too old');
  }
}

String _readString(Map<String, dynamic> json, String key, {required int max}) {
  final value = json[key];
  if (value is! String) {
    throw FormatException('Missing string field $key');
  }
  final trimmed = value.trim();
  if (trimmed.isEmpty || trimmed.length > max) {
    throw FormatException('Invalid string field $key');
  }
  return trimmed;
}

String? _readOptionalString(
  Map<String, dynamic> json,
  String key, {
  required int max,
}) {
  final value = json[key];
  if (value == null) return null;
  if (value is! String) {
    throw FormatException('Invalid string field $key');
  }
  final trimmed = value.trim();
  if (trimmed.length > max) {
    throw FormatException('String field $key exceeds limit');
  }
  return trimmed.isEmpty ? null : trimmed;
}

int _readInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! int) {
    throw FormatException('Missing int field $key');
  }
  return value;
}

List<String>? _readStringList(
  Map<String, dynamic> json,
  String key, {
  required int maxItems,
  required int maxItemChars,
}) {
  final value = json[key];
  if (value == null) return null;
  if (value is! List) {
    throw FormatException('Invalid list field $key');
  }
  if (value.length > maxItems) {
    throw FormatException('List field $key exceeds limit');
  }
  final items = value
      .whereType<String>()
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty && s.length <= maxItemChars)
      .toList();
  return items.isEmpty ? null : items;
}

List<Map<String, String>>? _readSections(Map<String, dynamic> json) {
  final value = json['sc'];
  if (value == null) return null;
  if (value is! List || value.length > WorkNetConstants.maxCustomSections) {
    throw const FormatException('Invalid sections');
  }
  final sections = <Map<String, String>>[];
  for (final item in value) {
    if (item is! Map) continue;
    final heading = (item['h'] as String?)?.trim() ?? '';
    final content = (item['c'] as String?)?.trim() ?? '';
    if (heading.isEmpty || content.isEmpty) continue;
    if (heading.length > WorkNetConstants.maxSectionHeadingChars ||
        content.length > WorkNetConstants.maxSectionContentChars) {
      throw const FormatException('Section exceeds limit');
    }
    sections.add({'h': heading, 'c': content});
  }
  return sections.isEmpty ? null : sections;
}

List<Map<String, String>>? _readLinks(Map<String, dynamic> json) {
  final value = json['lk'];
  if (value == null) return null;
  if (value is! List || value.length > WorkNetConstants.maxProfileSections) {
    throw const FormatException('Invalid links');
  }
  final links = <Map<String, String>>[];
  for (final item in value) {
    if (item is! Map) continue;
    final label = (item['l'] as String?)?.trim() ?? '';
    final url = _sanitizeUrl((item['u'] as String?)?.trim() ?? '');
    if (url == null) continue;
    if (label.length > WorkNetConstants.maxLinkLabelChars) {
      throw const FormatException('Link label exceeds limit');
    }
    links.add({'l': label.isEmpty ? url : label, 'u': url});
  }
  return links.isEmpty ? null : links;
}

String _sanitizeLinkedInHandle(String handle) {
  final valid = RegExp(WorkNetConstants.linkedInHandlePattern).hasMatch(handle);
  if (!valid) {
    throw const FormatException('Invalid LinkedIn handle');
  }
  return handle;
}

String? _sanitizeUrl(String raw) {
  final uri = Uri.tryParse(raw);
  if (uri == null || !(uri.scheme == 'https' || uri.scheme == 'http')) {
    return null;
  }
  final text = uri.toString();
  if (text.length > WorkNetConstants.maxLinkUrlChars) {
    throw const FormatException('Link URL exceeds limit');
  }
  return text;
}
