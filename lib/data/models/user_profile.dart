import 'package:isar/isar.dart';

part 'user_profile.g.dart';

// ════════════════════════════════════════════════════════════════════
// Spotlight Type Enum
// ════════════════════════════════════════════════════════════════════

enum SpotlightType {
  hiring,
  openToWork,
  building,
  learning,
  exploring;

  String get displayLabel => switch (this) {
        SpotlightType.hiring     => 'Hiring',
        SpotlightType.openToWork => 'Open to Work',
        SpotlightType.building   => 'Building / Collab',
        SpotlightType.learning   => 'Learning',
        SpotlightType.exploring  => 'Just Exploring',
      };

  String get emoji => switch (this) {
        SpotlightType.hiring     => '🟦',
        SpotlightType.openToWork => '🟩',
        SpotlightType.building   => '🟣',
        SpotlightType.learning   => '🟠',
        SpotlightType.exploring  => '⚪',
      };
}

// ════════════════════════════════════════════════════════════════════
// Experience Level
// ════════════════════════════════════════════════════════════════════

enum ExperienceLevel {
  student,
  fresher,
  oneToThree,
  threeToSix,
  sixPlus;

  String get label => switch (this) {
        ExperienceLevel.student    => 'Student',
        ExperienceLevel.fresher    => 'Fresher (< 1 yr)',
        ExperienceLevel.oneToThree => '1–3 yrs',
        ExperienceLevel.threeToSix => '3–6 yrs',
        ExperienceLevel.sixPlus    => '6+ yrs',
      };
}

// ════════════════════════════════════════════════════════════════════
// ProfileSection — embedded in UserProfile
// ════════════════════════════════════════════════════════════════════

@embedded
class ProfileSection {
  late String heading;
  late String content;
  late bool isVisible;

  ProfileSection();
}

// ════════════════════════════════════════════════════════════════════
// ProfileLink — a titled URL (e.g. GitHub, Portfolio, Twitter)
// ════════════════════════════════════════════════════════════════════

@embedded
class ProfileLink {
  late String label;   // e.g. "GitHub", "Portfolio"
  late String url;     // full URL e.g. https://github.com/...

  ProfileLink();
}

// ════════════════════════════════════════════════════════════════════
// UserProfile — Isar collection
// ════════════════════════════════════════════════════════════════════

@collection
class UserProfile {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String userId;

  // ── Locked fields (always broadcast) ────────────────────────────
  late String name;
  late String currentRole;
  late String companyOrCollege;
  late String experienceLabel;
  late String linkedInHandle;

  // ── Spotlight ────────────────────────────────────────────────────
  @enumerated
  SpotlightType spotlightType = SpotlightType.exploring;
  String spotlightNote = '';

  // ── Optional broadcast fields (toggleable) ───────────────────────
  int? ageYears;
  bool showAge = false;

  String? gender;
  bool showGender = false;

  String? bio;
  bool showBio = true;

  List<String> skills = [];
  bool showSkills = true;

  // ── Custom sections ───────────────────────────────────────────────
  List<ProfileSection> customSections = [];

  // ── Custom links (GitHub, Portfolio, Twitter, etc.) ───────────────
  List<ProfileLink> links = [];
  bool showLinks = true;

  // ── App state ─────────────────────────────────────────────────────
  bool stealthMode = false;
  bool onboardingComplete = false;
  DateTime? lastUpdated;

  // ── Derived ───────────────────────────────────────────────────────
  @ignore
  String get linkedInUrl => 'https://linkedin.com/in/$linkedInHandle';

  @ignore
  List<String> get topBroadcastSkills => skills.take(5).toList();

  Map<String, dynamic> toBroadcastJson() => {
        'name': name,
        'role': currentRole,
        'company': companyOrCollege,
        'experience': experienceLabel,
        'spotlightType': spotlightType.name,
        'spotlightNote': spotlightNote,
        if (showAge && ageYears != null) 'age': ageYears,
        if (showGender && gender != null) 'gender': gender,
        if (showBio && bio != null) 'bio': bio,
        if (showSkills && skills.isNotEmpty) 'skills': topBroadcastSkills,
        'linkedInHandle': linkedInHandle,
      };
}
