// ═══════════════════════════════════════════════════════════════════════════
// FYNDO - Zero-Trust Notes OS
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

/// Fyndo color palette - paper-like notebook aesthetic.
abstract final class FyndoColors {
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
ColorScheme fyndoLightColorScheme() {
  return const ColorScheme(
    brightness: Brightness.light,
    primary: FyndoColors.black,
    onPrimary: FyndoColors.white,
    primaryContainer: FyndoColors.charcoal,
    onPrimaryContainer: FyndoColors.white,
    secondary: FyndoColors.darkGray,
    onSecondary: FyndoColors.white,
    secondaryContainer: FyndoColors.paleGray,
    onSecondaryContainer: FyndoColors.charcoal,
    tertiary: FyndoColors.gray,
    onTertiary: FyndoColors.white,
    tertiaryContainer: FyndoColors.lightGray,
    onTertiaryContainer: FyndoColors.charcoal,
    error: FyndoColors.error,
    onError: FyndoColors.white,
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
    surface: FyndoColors.white,
    surfaceDim: FyndoColors.paleGray,
    surfaceBright: FyndoColors.white,
    surfaceContainerLowest: FyndoColors.white,
    surfaceContainerLow: FyndoColors.white,
    surfaceContainer: FyndoColors.white,
    surfaceContainerHigh: FyndoColors.white,
    surfaceContainerHighest: FyndoColors.white,
    onSurface: FyndoColors.charcoal,
    onSurfaceVariant: FyndoColors.darkGray,
    outline: FyndoColors.gray,
    outlineVariant: FyndoColors.lightGray,
    shadow: FyndoColors.black,
    scrim: FyndoColors.black,
    inverseSurface: FyndoColors.charcoal,
    onInverseSurface: FyndoColors.paper,
    inversePrimary: FyndoColors.lightGray,
  );
}

/// Dark theme color scheme.
ColorScheme fyndoDarkColorScheme() {
  return const ColorScheme(
    brightness: Brightness.dark,
    primary: FyndoColors.white,
    onPrimary: FyndoColors.black,
    primaryContainer: FyndoColors.darkSurfaceElevated,
    onPrimaryContainer: FyndoColors.darkText,
    secondary: FyndoColors.darkTextSecondary,
    onSecondary: FyndoColors.black,
    secondaryContainer: FyndoColors.darkSurface,
    onSecondaryContainer: FyndoColors.darkText,
    tertiary: FyndoColors.gray,
    onTertiary: FyndoColors.black,
    tertiaryContainer: FyndoColors.darkSurfaceElevated,
    onTertiaryContainer: FyndoColors.darkText,
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: FyndoColors.darkSurface,
    surfaceDim: FyndoColors.darkBackground,
    surfaceBright: FyndoColors.darkSurfaceElevated,
    surfaceContainerLowest: FyndoColors.darkBackground,
    surfaceContainerLow: FyndoColors.darkSurface,
    surfaceContainer: FyndoColors.darkSurface,
    surfaceContainerHigh: FyndoColors.darkSurfaceElevated,
    surfaceContainerHighest: FyndoColors.darkSurfaceElevated,
    onSurface: FyndoColors.darkText,
    onSurfaceVariant: FyndoColors.darkTextSecondary,
    outline: FyndoColors.gray,
    outlineVariant: FyndoColors.darkGray,
    shadow: FyndoColors.black,
    scrim: FyndoColors.black,
    inverseSurface: FyndoColors.paper,
    onInverseSurface: FyndoColors.charcoal,
    inversePrimary: FyndoColors.darkGray,
  );
}
