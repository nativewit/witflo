// ═══════════════════════════════════════════════════════════════════════════
// FYNDO - Zero-Trust Notes OS
// Theme Configuration - Paper-like Notebook Theme
// ═══════════════════════════════════════════════════════════════════════════
//
// DESIGN PRINCIPLES:
// 1. Paper-like aesthetic - Black text on white/cream background
// 2. Pointed edges - NO round corners (like a real notebook)
// 3. High contrast - Clear visual hierarchy
// 4. Nunito font - Clean, readable typography
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'fyndo_colors.dart';

/// Fyndo theme configuration.
abstract final class FyndoTheme {
  /// Border radius - ZERO for pointed edges (notebook aesthetic)
  static const double borderRadius = 0.0;

  /// Standard padding
  static const double padding = 16.0;

  /// Small padding
  static const double paddingSmall = 8.0;

  /// Large padding
  static const double paddingLarge = 24.0;

  /// Border width
  static const double borderWidth = 1.0;

  /// Heavy border width
  static const double borderWidthHeavy = 2.0;

  /// Creates the light theme.
  static ThemeData light() {
    final colorScheme = fyndoLightColorScheme();
    final textTheme = _buildTextTheme(colorScheme);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: FyndoColors.paper,

      // AppBar - minimal, clean
      appBarTheme: AppBarTheme(
        backgroundColor: FyndoColors.paper,
        foregroundColor: FyndoColors.charcoal,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: FyndoColors.charcoal, size: 24),
      ),

      // Cards - no border radius, subtle border
      cardTheme: CardThemeData(
        color: FyndoColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: const BorderSide(
            color: FyndoColors.paleGray,
            width: borderWidth,
          ),
        ),
        margin: EdgeInsets.zero,
      ),

      // Buttons - pointed edges
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: FyndoColors.black,
          foregroundColor: FyndoColors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: padding,
            vertical: paddingSmall + 4,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: FyndoColors.black,
          foregroundColor: FyndoColors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: padding,
            vertical: paddingSmall + 4,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: FyndoColors.charcoal,
          padding: const EdgeInsets.symmetric(
            horizontal: padding,
            vertical: paddingSmall + 4,
          ),
          side: const BorderSide(
            color: FyndoColors.charcoal,
            width: borderWidth,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: FyndoColors.charcoal,
          padding: const EdgeInsets.symmetric(
            horizontal: paddingSmall,
            vertical: paddingSmall,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: FyndoColors.charcoal,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
      ),

      // Input fields - pointed edges, underline style
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: FyndoColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(
            color: FyndoColors.gray,
            width: borderWidth,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(
            color: FyndoColors.lightGray,
            width: borderWidth,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(
            color: FyndoColors.charcoal,
            width: borderWidthHeavy,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(
            color: FyndoColors.error,
            width: borderWidth,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(
            color: FyndoColors.error,
            width: borderWidthHeavy,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: padding,
          vertical: paddingSmall + 4,
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(color: FyndoColors.darkGray),
        hintStyle: textTheme.bodyMedium?.copyWith(color: FyndoColors.gray),
      ),

      // Dialogs - pointed edges
      dialogTheme: DialogThemeData(
        backgroundColor: FyndoColors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: const BorderSide(
            color: FyndoColors.paleGray,
            width: borderWidth,
          ),
        ),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),

      // Bottom sheets - pointed edges
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: FyndoColors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),

      // Chips - pointed edges
      chipTheme: ChipThemeData(
        backgroundColor: FyndoColors.paleGray,
        labelStyle: textTheme.labelMedium,
        padding: const EdgeInsets.symmetric(
          horizontal: paddingSmall,
          vertical: 4,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: const BorderSide(
            color: FyndoColors.lightGray,
            width: borderWidth,
          ),
        ),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: FyndoColors.paleGray,
        thickness: borderWidth,
        space: 1,
      ),

      // FloatingActionButton - pointed edges
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: FyndoColors.black,
        foregroundColor: FyndoColors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),

      // ListTile
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: padding,
          vertical: paddingSmall,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        titleTextStyle: textTheme.bodyLarge,
        subtitleTextStyle: textTheme.bodyMedium?.copyWith(
          color: FyndoColors.darkGray,
        ),
      ),

      // PopupMenu - pointed edges
      popupMenuTheme: PopupMenuThemeData(
        color: FyndoColors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: const BorderSide(
            color: FyndoColors.paleGray,
            width: borderWidth,
          ),
        ),
        textStyle: textTheme.bodyMedium,
      ),

      // SnackBar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: FyndoColors.charcoal,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: FyndoColors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Tab bar
      tabBarTheme: TabBarThemeData(
        labelColor: FyndoColors.charcoal,
        unselectedLabelColor: FyndoColors.gray,
        labelStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: textTheme.labelLarge,
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(
            color: FyndoColors.charcoal,
            width: borderWidthHeavy,
          ),
        ),
      ),

      // Progress indicators
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: FyndoColors.charcoal,
        linearTrackColor: FyndoColors.paleGray,
      ),
    );
  }

  /// Creates the dark theme.
  static ThemeData dark() {
    final colorScheme = fyndoDarkColorScheme();
    final textTheme = _buildTextTheme(colorScheme);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: FyndoColors.darkBackground,

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: FyndoColors.darkBackground,
        foregroundColor: FyndoColors.darkText,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: FyndoColors.darkText,
        ),
        iconTheme: const IconThemeData(color: FyndoColors.darkText, size: 24),
      ),

      // Cards
      cardTheme: CardThemeData(
        color: FyndoColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: const BorderSide(
            color: FyndoColors.darkSurfaceElevated,
            width: borderWidth,
          ),
        ),
        margin: EdgeInsets.zero,
      ),

      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: FyndoColors.white,
          foregroundColor: FyndoColors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: padding,
            vertical: paddingSmall + 4,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: FyndoColors.white,
          foregroundColor: FyndoColors.black,
          padding: const EdgeInsets.symmetric(
            horizontal: padding,
            vertical: paddingSmall + 4,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: FyndoColors.darkText,
          padding: const EdgeInsets.symmetric(
            horizontal: padding,
            vertical: paddingSmall + 4,
          ),
          side: const BorderSide(
            color: FyndoColors.darkText,
            width: borderWidth,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: FyndoColors.darkText,
          padding: const EdgeInsets.symmetric(
            horizontal: paddingSmall,
            vertical: paddingSmall,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: FyndoColors.darkText,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
      ),

      // Input fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: FyndoColors.darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(
            color: FyndoColors.darkSurfaceElevated,
            width: borderWidth,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(
            color: FyndoColors.darkSurfaceElevated,
            width: borderWidth,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(
            color: FyndoColors.white,
            width: borderWidthHeavy,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: colorScheme.error, width: borderWidth),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(
            color: colorScheme.error,
            width: borderWidthHeavy,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: padding,
          vertical: paddingSmall + 4,
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: FyndoColors.darkTextSecondary,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: FyndoColors.gray),
      ),

      // Dialogs
      dialogTheme: DialogThemeData(
        backgroundColor: FyndoColors.darkSurface,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: const BorderSide(
            color: FyndoColors.darkSurfaceElevated,
            width: borderWidth,
          ),
        ),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: FyndoColors.darkText,
        ),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: FyndoColors.darkSurfaceElevated,
        thickness: borderWidth,
        space: 1,
      ),

      // FloatingActionButton
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: FyndoColors.white,
        foregroundColor: FyndoColors.black,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),

      // ListTile
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: padding,
          vertical: paddingSmall,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        titleTextStyle: textTheme.bodyLarge?.copyWith(
          color: FyndoColors.darkText,
        ),
        subtitleTextStyle: textTheme.bodyMedium?.copyWith(
          color: FyndoColors.darkTextSecondary,
        ),
      ),

      // PopupMenu
      popupMenuTheme: PopupMenuThemeData(
        color: FyndoColors.darkSurface,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: const BorderSide(
            color: FyndoColors.darkSurfaceElevated,
            width: borderWidth,
          ),
        ),
        textStyle: textTheme.bodyMedium?.copyWith(color: FyndoColors.darkText),
      ),

      // SnackBar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: FyndoColors.white,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: FyndoColors.charcoal,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Tab bar
      tabBarTheme: TabBarThemeData(
        labelColor: FyndoColors.darkText,
        unselectedLabelColor: FyndoColors.gray,
        labelStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: textTheme.labelLarge,
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(
            color: FyndoColors.white,
            width: borderWidthHeavy,
          ),
        ),
      ),

      // Progress indicators
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: FyndoColors.white,
        linearTrackColor: FyndoColors.darkSurfaceElevated,
      ),
    );
  }

  /// Builds text theme using Nunito font.
  static TextTheme _buildTextTheme(ColorScheme colorScheme) {
    final baseTextTheme = GoogleFonts.nunitoTextTheme();

    return baseTextTheme.copyWith(
      displayLarge: baseTextTheme.displayLarge?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w300,
      ),
      displayMedium: baseTextTheme.displayMedium?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w300,
      ),
      displaySmall: baseTextTheme.displaySmall?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w400,
      ),
      headlineLarge: baseTextTheme.headlineLarge?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: baseTextTheme.headlineSmall?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: baseTextTheme.titleLarge?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: baseTextTheme.titleMedium?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: baseTextTheme.titleSmall?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w400,
      ),
      bodySmall: baseTextTheme.bodySmall?.copyWith(
        color: colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w400,
      ),
      labelLarge: baseTextTheme.labelLarge?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
      labelMedium: baseTextTheme.labelMedium?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w500,
      ),
      labelSmall: baseTextTheme.labelSmall?.copyWith(
        color: colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
