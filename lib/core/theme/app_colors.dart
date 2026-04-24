import 'package:flutter/material.dart';

/// All colour tokens for WorkNet.
/// Signal-native aesthetic: deep space navy base · electric cyan accent.
abstract final class AppColors {
  // ── Background Layer ──────────────────────────────────────────────
  static const Color background       = Color(0xFF080D1A); // deep space navy
  static const Color surface          = Color(0xFF111827); // card surface
  static const Color surfaceElevated  = Color(0xFF1C2333); // bottom sheets, modals
  static const Color border           = Color(0xFF1E2D40); // subtle dividers

  // ── Brand / Accent ────────────────────────────────────────────────
  static const Color cyan             = Color(0xFF00D4FF); // primary accent, LIVE badge
  static const Color cyanDim          = Color(0x2600D4FF); // 15% — glow fills
  static const Color cyanDark         = Color(0xFF0099BB); // pressed state

  // ── Semantic surface composites ──────────────────────────────────
  // Use these instead of .withOpacity() to be Dart 3.x compliant
  static Color get cyanSurface     => const Color(0xFF00D4FF).withAlpha(25);
  static Color get cyanBorder      => const Color(0xFF00D4FF).withAlpha(77);
  static Color get errorSurface    => const Color(0xFFFF4C6A).withAlpha(13);
  static Color get errorBorder     => const Color(0xFFFF4C6A).withAlpha(77);
  static Color get warningSurface  => const Color(0xFFFFB300).withAlpha(30);
  static Color get successSurface  => const Color(0xFF00E676).withAlpha(25);

  // ── Spotlight Palette ─────────────────────────────────────────────
  static const Color spotlightHiring     = Color(0xFF00D4FF); // cyan
  static const Color spotlightOpenToWork = Color(0xFF00E676); // emerald
  static const Color spotlightBuilding   = Color(0xFF7B61FF); // purple
  static const Color spotlightLearning   = Color(0xFFFFB300); // amber
  static const Color spotlightExploring  = Color(0xFF8892A4); // slate

  // ── Text ──────────────────────────────────────────────────────────
  static const Color textPrimary    = Color(0xFFF0F4FF);
  static const Color textSecondary  = Color(0xFF8892A4);
  static const Color textMuted      = Color(0xFF4A5568);

  // ── Semantic ──────────────────────────────────────────────────────
  static const Color success  = Color(0xFF00E676);
  static const Color warning  = Color(0xFFFFB300);
  static const Color error    = Color(0xFFFF4C6A);

  // ── Hop Badges ────────────────────────────────────────────────────
  static const Color hopDirect   = Color(0xFF00D4FF); // 0 hops
  static const Color hopNearby   = Color(0xFF7B61FF); // 1 hop
  static const Color hopInVenue  = Color(0xFF8892A4); // 2 hops
}
