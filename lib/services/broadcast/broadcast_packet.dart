import 'dart:convert';
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
        userId:             userId,
        profile:            profile,
        hopCount:           hopCount + 1,
        broadcastTimestamp: broadcastTimestamp,
        version:            version,
        signature:          signature,
      );

  Map<String, dynamic> toJson() => {
        'uid': userId,
        'p':   profile.toJson(),
        'h':   hopCount,
        't':   broadcastTimestamp,
        'v':   version,
        if (signature != null) 's': signature,
      };

  factory BroadcastPacket.fromJson(Map<String, dynamic> json) {
    return BroadcastPacket(
      userId:             json['uid'] as String,
      profile:            ProfileSnapshot.fromJson(json['p'] as Map<String, dynamic>),
      hopCount:           json['h'] as int,
      broadcastTimestamp: json['t'] as int,
      version:            (json['v'] as int?) ?? 1,
      signature:          json['s'] as String?,
    );
  }

  List<int> toBytes() => utf8.encode(jsonEncode(toJson()));

  factory BroadcastPacket.fromBytes(List<int> bytes) {
    final json = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    return BroadcastPacket.fromJson(json);
  }

  factory BroadcastPacket.fromUserProfile(UserProfile p) {
    return BroadcastPacket(
      userId:             p.userId,
      profile:            ProfileSnapshot.fromUserProfile(p),
      hopCount:           0,
      broadcastTimestamp: DateTime.now().millisecondsSinceEpoch,
      version:            1,
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
  final List<Map<String, String>>? links;    // {label, url}

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
  });

  String get linkedInUrl => 'https://linkedin.com/in/$linkedInHandle';

  Map<String, dynamic> toJson() => {
        'n':  name,
        'r':  currentRole,
        'c':  companyOrCollege,
        'x':  experienceLabel,
        'st': spotlightType.name,
        'sn': spotlightNote,
        'li': linkedInHandle,
        if (ageYears != null) 'a': ageYears,
        if (gender != null)   'g': gender,
        if (bio != null)      'b': bio,
        if (skills != null && skills!.isNotEmpty) 'sk': skills,
        if (sections != null && sections!.isNotEmpty) 'sc': sections,
        if (links != null && links!.isNotEmpty) 'lk': links,
      };

  factory ProfileSnapshot.fromJson(Map<String, dynamic> j) {
    return ProfileSnapshot(
      name:             j['n'] as String,
      currentRole:      j['r'] as String,
      companyOrCollege: j['c'] as String,
      experienceLabel:  j['x'] as String,
      spotlightType:    SpotlightType.values.byName(j['st'] as String),
      spotlightNote:    (j['sn'] as String?) ?? '',
      linkedInHandle:   j['li'] as String,
      ageYears:         j['a'] as int?,
      gender:           j['g'] as String?,
      bio:              j['b'] as String?,
      skills:           (j['sk'] as List<dynamic>?)?.cast<String>(),
      sections:         (j['sc'] as List<dynamic>?)
                            ?.map((e) => Map<String, String>.from(e as Map))
                            .toList(),
      links:            (j['lk'] as List<dynamic>?)
                            ?.map((e) => Map<String, String>.from(e as Map))
                            .toList(),
    );
  }

  factory ProfileSnapshot.fromUserProfile(UserProfile p) {
    return ProfileSnapshot(
      name:             p.name,
      currentRole:      p.currentRole,
      companyOrCollege: p.companyOrCollege,
      experienceLabel:  p.experienceLabel,
      spotlightType:    p.spotlightType,
      spotlightNote:    p.spotlightNote,
      linkedInHandle:   p.linkedInHandle,
      ageYears:         p.showAge ? p.ageYears : null,
      gender:           p.showGender ? p.gender : null,
      bio:              p.showBio ? p.bio : null,
      skills:           p.showSkills && p.skills.isNotEmpty
                            ? p.topBroadcastSkills
                            : null,
      sections:         p.customSections.isNotEmpty
                            ? p.customSections
                                .where((s) => s.isVisible && s.content.isNotEmpty)
                                .map((s) => {'h': s.heading, 'c': s.content})
                                .toList()
                            : null,
      links:            p.showLinks && p.links.isNotEmpty
                            ? p.links
                                .where((l) => l.url.isNotEmpty)
                                .map((l) => {'l': l.label, 'u': l.url})
                                .toList()
                            : null,
    );
  }
}
