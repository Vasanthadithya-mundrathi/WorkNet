import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// WorkNet type scale.
/// Primary: Space Grotesk — technical, modern.
/// Mono:    JetBrains Mono — hop labels, tech metadata.
abstract final class AppTypography {
  // ── Display ───────────────────────────────────────────────────────
  static TextStyle displayLarge = GoogleFonts.spaceGrotesk(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );

  static TextStyle displayMedium = GoogleFonts.spaceGrotesk(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
  );

  // ── Heading ───────────────────────────────────────────────────────
  static TextStyle headingLarge = GoogleFonts.spaceGrotesk(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
  );

  static TextStyle headingMedium = GoogleFonts.spaceGrotesk(
    fontSize: 17,
    fontWeight: FontWeight.w600,
  );

  static TextStyle headingSmall = GoogleFonts.spaceGrotesk(
    fontSize: 15,
    fontWeight: FontWeight.w600,
  );

  // ── Body ──────────────────────────────────────────────────────────
  static TextStyle bodyLarge = GoogleFonts.spaceGrotesk(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static TextStyle bodyMedium = GoogleFonts.spaceGrotesk(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  static TextStyle bodySmall = GoogleFonts.spaceGrotesk(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  // ── Label ─────────────────────────────────────────────────────────
  static TextStyle labelLarge = GoogleFonts.spaceGrotesk(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  );

  static TextStyle labelSmall = GoogleFonts.spaceGrotesk(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.4,
  );

  // ── Mono (hop badges, tech metadata) ─────────────────────────────
  static TextStyle mono = GoogleFonts.jetBrainsMono(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.3,
  );

  static TextStyle monoBold = GoogleFonts.jetBrainsMono(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.3,
  );
}
