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

  // ── UX ────────────────────────────────────────────────────────────
  /// Target: feed loads within this many milliseconds
  static const int feedLoadTargetMs = 3000;

  /// LinkedIn URL base
  static const String linkedInBase = 'https://linkedin.com/in/';

  /// LinkedIn handle regex
  static const String linkedInHandlePattern =
      r'^[a-zA-Z0-9\-]{3,100}$';

  // ── Packet schema ─────────────────────────────────────────────────
  static const int packetSchemaVersion = 1;
}
