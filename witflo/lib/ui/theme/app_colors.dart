// ═══════════════════════════════════════════════════════════════════════════
// WITFLO - Zero-Trust Notes OS
// Color System - Warm Notebook Theme
// ═══════════════════════════════════════════════════════════════════════════
//
// DESIGN PHILOSOPHY:
// - Warm notebook aesthetic with cream/beige paper tones
// - Soft dark brown instead of harsh black
// - High contrast for readability
// - Clean, minimal, professional
// - Inspired by physical notebooks and quality stationery
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

/// Application color palette - paper-like notebook aesthetic.
abstract final class AppColors {
  // ─────────────────────────────────────────────────────────────────────────
  // PRIMARY PALETTE - Warm Notebook Colors
  // ─────────────────────────────────────────────────────────────────────────

  /// Warm dark brown - primary text, icons (replaces pure black)
  static const Color black = Color(0xFF2C2416);

  /// Warm charcoal - softer text
  static const Color charcoal = Color(0xFF3D3226);

  /// Warm dark gray - secondary text
  static const Color darkGray = Color(0xFF5A5245);

  /// Medium gray - tertiary text, borders
  static const Color gray = Color(0xFF8B8578);

  /// Light gray - disabled, subtle borders
  static const Color lightGray = Color(0xFFC4BCB0);

  /// Very light gray - dividers, backgrounds
  static const Color paleGray = Color(0xFFE8E3DA);

  /// Warm cream - paper color (notebook aesthetic)
  static const Color paper = Color(0xFFFFFBF5);

  /// Warm white - backgrounds
  static const Color white = Color(0xFFFFFEFA);

  // ─────────────────────────────────────────────────────────────────────────
  // SEMANTIC COLORS
  // ─────────────────────────────────────────────────────────────────────────

  /// Error - warm red
  static const Color error = Color(0xFFB8342C);

  /// Success - muted green
  static const Color success = Color(0xFF2E7D32);

  /// Warning - warm amber
  static const Color warning = Color(0xFFD66A28);

  /// Info - notebook ink blue
  static const Color info = Color(0xFF1E3A5F);

  // ─────────────────────────────────────────────────────────────────────────
  // ACCENT COLORS - Notebook Inspired
  // ─────────────────────────────────────────────────────────────────────────

  /// Notebook ink blue - for special highlights
  static const Color inkBlue = Color(0xFF2C5F8D);

  /// Red pen - for important marks
  static const Color redPen = Color(0xFFB8342C);

  /// Pencil graphite - for sketches/drafts
  static const Color pencilGraphite = Color(0xFF5A5245);

  // ─────────────────────────────────────────────────────────────────────────
  // DARK MODE PALETTE - Warm Dark Tones
  // ─────────────────────────────────────────────────────────────────────────

  /// Dark mode background - warm dark
  static const Color darkBackground = Color(0xFF1C1915);

  /// Dark mode surface - warm surface
  static const Color darkSurface = Color(0xFF272218);

  /// Dark mode elevated surface
  static const Color darkSurfaceElevated = Color(0xFF33291F);

  /// Dark mode text - warm light
  static const Color darkText = Color(0xFFE8DFD5);

  /// Dark mode secondary text
  static const Color darkTextSecondary = Color(0xFFB8AFA0);
}

/// Light theme color scheme.
ColorScheme appLightColorScheme() {
  return const ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.black,
    onPrimary: AppColors.white,
    primaryContainer: AppColors.charcoal,
    onPrimaryContainer: AppColors.white,
    secondary: AppColors.darkGray,
    onSecondary: AppColors.white,
    secondaryContainer: AppColors.paleGray,
    onSecondaryContainer: AppColors.charcoal,
    tertiary: AppColors.gray,
    onTertiary: AppColors.white,
    tertiaryContainer: AppColors.lightGray,
    onTertiaryContainer: AppColors.charcoal,
    error: AppColors.error,
    onError: AppColors.white,
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
    surface: AppColors.white,
    surfaceDim: AppColors.paleGray,
    surfaceBright: AppColors.white,
    surfaceContainerLowest: AppColors.white,
    surfaceContainerLow: AppColors.white,
    surfaceContainer: AppColors.white,
    surfaceContainerHigh: AppColors.white,
    surfaceContainerHighest: AppColors.white,
    onSurface: AppColors.charcoal,
    onSurfaceVariant: AppColors.darkGray,
    outline: AppColors.gray,
    outlineVariant: AppColors.lightGray,
    shadow: AppColors.black,
    scrim: AppColors.black,
    inverseSurface: AppColors.charcoal,
    onInverseSurface: AppColors.paper,
    inversePrimary: AppColors.lightGray,
  );
}

/// Dark theme color scheme.
ColorScheme appDarkColorScheme() {
  return const ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.white,
    onPrimary: AppColors.black,
    primaryContainer: AppColors.darkSurfaceElevated,
    onPrimaryContainer: AppColors.darkText,
    secondary: AppColors.darkTextSecondary,
    onSecondary: AppColors.black,
    secondaryContainer: AppColors.darkSurface,
    onSecondaryContainer: AppColors.darkText,
    tertiary: AppColors.gray,
    onTertiary: AppColors.black,
    tertiaryContainer: AppColors.darkSurfaceElevated,
    onTertiaryContainer: AppColors.darkText,
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: AppColors.darkSurface,
    surfaceDim: AppColors.darkBackground,
    surfaceBright: AppColors.darkSurfaceElevated,
    surfaceContainerLowest: AppColors.darkBackground,
    surfaceContainerLow: AppColors.darkSurface,
    surfaceContainer: AppColors.darkSurface,
    surfaceContainerHigh: AppColors.darkSurfaceElevated,
    surfaceContainerHighest: AppColors.darkSurfaceElevated,
    onSurface: AppColors.darkText,
    onSurfaceVariant: AppColors.darkTextSecondary,
    outline: AppColors.gray,
    outlineVariant: AppColors.darkGray,
    shadow: AppColors.black,
    scrim: AppColors.black,
    inverseSurface: AppColors.paper,
    onInverseSurface: AppColors.charcoal,
    inversePrimary: AppColors.darkGray,
  );
}
