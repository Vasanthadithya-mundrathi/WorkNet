import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_typography.dart';

abstract final class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary:      AppColors.cyan,
        onPrimary:    AppColors.background,
        secondary:    AppColors.spotlightBuilding,
        onSecondary:  AppColors.textPrimary,
        surface:      AppColors.surface,
        onSurface:    AppColors.textPrimary,
        error:        AppColors.error,
        onError:      AppColors.textPrimary,
        outline:      AppColors.border,
      ),

      // ── App Bar ───────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
        ),
        titleTextStyle: AppTypography.headingMedium.copyWith(
          color: AppColors.textPrimary,
        ),
        iconTheme: const IconThemeData(color: AppColors.textSecondary),
      ),

      // ── Card ──────────────────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── Input ─────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceElevated,
        hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
        labelStyle: AppTypography.labelLarge.copyWith(color: AppColors.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.cyan, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      // ── Elevated Button ───────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.cyan,
          foregroundColor: AppColors.background,
          textStyle: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          minimumSize: const Size(double.infinity, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),

      // ── Text Button ───────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.cyan,
          textStyle: AppTypography.labelLarge,
        ),
      ),

      // ── Chip ──────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceElevated,
        selectedColor: AppColors.cyanDim,
        side: const BorderSide(color: AppColors.border),
        labelStyle: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),

      // ── Divider ───────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 0,
      ),

      // ── Bottom Navigation Bar ──────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.cyanDim,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.cyan, size: 22);
          }
          return const IconThemeData(color: AppColors.textSecondary, size: 22);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return AppTypography.labelSmall.copyWith(
            color: states.contains(WidgetState.selected)
                ? AppColors.cyan
                : AppColors.textSecondary,
          );
        }),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),

      // ── Text Theme ────────────────────────────────────────────────
      textTheme: TextTheme(
        displayLarge:  AppTypography.displayLarge.copyWith(color: AppColors.textPrimary),
        displayMedium: AppTypography.displayMedium.copyWith(color: AppColors.textPrimary),
        headlineLarge: AppTypography.headingLarge.copyWith(color: AppColors.textPrimary),
        headlineMedium: AppTypography.headingMedium.copyWith(color: AppColors.textPrimary),
        headlineSmall: AppTypography.headingSmall.copyWith(color: AppColors.textPrimary),
        bodyLarge:    AppTypography.bodyLarge.copyWith(color: AppColors.textPrimary),
        bodyMedium:   AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
        bodySmall:    AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
        labelLarge:   AppTypography.labelLarge.copyWith(color: AppColors.textPrimary),
        labelSmall:   AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}
