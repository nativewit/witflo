// ═══════════════════════════════════════════════════════════════════════════
// FYNDO - Zero-Trust Notes OS
// Color System - Paper-like Black & White Theme
// ═══════════════════════════════════════════════════════════════════════════
//
// DESIGN PHILOSOPHY:
// - Paper-like aesthetic with high contrast
// - Black and white primary palette
// - No round corners (pointed edges like notebook)
// - Clean, minimal, professional
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

/// Fyndo color palette - paper-like notebook aesthetic.
abstract final class FyndoColors {
  // ─────────────────────────────────────────────────────────────────────────
  // PRIMARY PALETTE - Black & White
  // ─────────────────────────────────────────────────────────────────────────

  /// Pure black - primary text, icons
  static const Color black = Color(0xFF000000);

  /// Off-black - softer text
  static const Color charcoal = Color(0xFF1A1A1A);

  /// Dark gray - secondary text
  static const Color darkGray = Color(0xFF4A4A4A);

  /// Medium gray - tertiary text, borders
  static const Color gray = Color(0xFF808080);

  /// Light gray - disabled, subtle borders
  static const Color lightGray = Color(0xFFB8B8B8);

  /// Very light gray - dividers, backgrounds
  static const Color paleGray = Color(0xFFE8E8E8);

  /// Off-white - paper color
  static const Color paper = Color(0xFFFAFAFA);

  /// Pure white - backgrounds
  static const Color white = Color(0xFFFFFFFF);

  // ─────────────────────────────────────────────────────────────────────────
  // SEMANTIC COLORS
  // ─────────────────────────────────────────────────────────────────────────

  /// Error - muted red
  static const Color error = Color(0xFFB71C1C);

  /// Success - muted green
  static const Color success = Color(0xFF2E7D32);

  /// Warning - muted amber
  static const Color warning = Color(0xFFE65100);

  /// Info - muted blue
  static const Color info = Color(0xFF1565C0);

  // ─────────────────────────────────────────────────────────────────────────
  // DARK MODE PALETTE
  // ─────────────────────────────────────────────────────────────────────────

  /// Dark mode background
  static const Color darkBackground = Color(0xFF121212);

  /// Dark mode surface
  static const Color darkSurface = Color(0xFF1E1E1E);

  /// Dark mode elevated surface
  static const Color darkSurfaceElevated = Color(0xFF2A2A2A);

  /// Dark mode text
  static const Color darkText = Color(0xFFE8E8E8);

  /// Dark mode secondary text
  static const Color darkTextSecondary = Color(0xFFB0B0B0);
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
    onSurface: FyndoColors.charcoal,
    surfaceContainerHighest: FyndoColors.paleGray,
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
    surface: FyndoColors.darkBackground,
    onSurface: FyndoColors.darkText,
    surfaceContainerHighest: FyndoColors.darkSurfaceElevated,
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
