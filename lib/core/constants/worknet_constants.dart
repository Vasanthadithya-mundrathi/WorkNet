/// WorkNet global constants
abstract final class WorkNetConstants {
  // ── BLE / Mesh ────────────────────────────────────────────────────
  /// Maximum gossip relay hops (0 = direct, 1 = nearby, 2 = in-venue)
  static const int maxHopCount = 2;

  /// Packet TTL in milliseconds (8 seconds — fast eviction)
  static const int packetTtlMs = 8000;

  /// BLE scan duration in milliseconds
  static const int bleScanDurationMs = 3000;

  /// BLE scan pause between cycles in milliseconds
  static const int bleScanPauseMs = 1000;

  /// Broadcast re-advertise interval in milliseconds (every 2s)
  static const int broadcastIntervalMs = 2000;

  /// UDP broadcast port
  static const int udpPort = 41234;

  /// Max broadcast payload size in bytes
  static const int maxPayloadBytes = 1536; // 1.5 KB

  /// Max accepted clock skew for incoming packets
  static const int maxPacketClockSkewMs = 120000;

  /// Max age for incoming packet timestamps
  static const int maxPacketAgeMs = 300000;

  /// RSSI rolling average sample count
  static const int rssiSampleCount = 5;

  /// Seen-cache max entries
  static const int seenCacheMaxEntries = 500;

  // ── Profile ───────────────────────────────────────────────────────
  /// Maximum total profile sections (locked + custom)
  static const int maxProfileSections = 15;

  /// Maximum custom sections (user-created)
  static const int maxCustomSections = 7;

  /// Spotlight note max character count
  static const int spotlightNoteMaxChars = 140;

  /// Bio max character count
  static const int bioMaxChars = 500;

  /// Maximum skills to include in broadcast packet
  static const int broadcastMaxSkills = 5;

  /// Local avatar render size stored in app documents
  static const int avatarImageSizePx = 512;

  /// Tiny avatar included in the local broadcast packet
  static const int avatarBroadcastSizePx = 96;

  /// Base64 thumbnail cap inside the broadcast packet
  static const int avatarBroadcastMaxBase64Chars = 12000;

  /// Max profile text lengths accepted from nearby packets
  static const int maxNameChars = 80;
  static const int maxRoleChars = 80;
  static const int maxCompanyChars = 100;
  static const int maxExperienceChars = 40;
  static const int maxSectionHeadingChars = 80;
  static const int maxSectionContentChars = 500;
  static const int maxLinkLabelChars = 60;
  static const int maxLinkUrlChars = 240;

  // ── UX ────────────────────────────────────────────────────────────
  /// Target: feed loads within this many milliseconds
  static const int feedLoadTargetMs = 3000;

  /// LinkedIn URL base
  static const String linkedInBase = 'https://linkedin.com/in/';

  /// LinkedIn handle regex
  static const String linkedInHandlePattern = r'^[a-zA-Z0-9\-]{3,100}$';

  // ── Packet schema ─────────────────────────────────────────────────
  static const int packetSchemaVersion = 1;
}
