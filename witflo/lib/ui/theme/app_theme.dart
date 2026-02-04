// ═══════════════════════════════════════════════════════════════════════════
// WITFLO - Zero-Trust Notes OS
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

import 'app_colors.dart';

/// Application theme configuration.
abstract final class AppTheme {
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
    final colorScheme = appLightColorScheme();
    final textTheme = _buildTextTheme(colorScheme);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: AppColors.paper,

      // AppBar - minimal, clean
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.paper,
        foregroundColor: AppColors.charcoal,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: AppColors.charcoal, size: 24),
      ),

      // Cards - no border radius, subtle border
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: const BorderSide(color: AppColors.paleGray, width: borderWidth),
        ),
        margin: EdgeInsets.zero,
      ),

      // Buttons - pointed edges
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.black,
          foregroundColor: AppColors.white,
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
          backgroundColor: AppColors.black,
          foregroundColor: AppColors.white,
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
          foregroundColor: AppColors.charcoal,
          padding: const EdgeInsets.symmetric(
            horizontal: padding,
            vertical: paddingSmall + 4,
          ),
          side: const BorderSide(color: AppColors.charcoal, width: borderWidth),
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
          foregroundColor: AppColors.charcoal,
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
          foregroundColor: AppColors.charcoal,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
      ),

      // Input fields - pointed edges, underline style
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(
            color: AppColors.gray,
            width: borderWidth,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(
            color: AppColors.lightGray,
            width: borderWidth,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(
            color: AppColors.charcoal,
            width: borderWidthHeavy,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: borderWidth,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: borderWidthHeavy,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: padding,
          vertical: paddingSmall + 4,
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(color: AppColors.darkGray),
        hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.gray),
      ),

      // Dialogs - pointed edges
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: const BorderSide(color: AppColors.paleGray, width: borderWidth),
        ),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),

      // Bottom sheets - pointed edges
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),

      // Chips - pointed edges
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.paleGray,
        labelStyle: textTheme.labelMedium,
        padding: const EdgeInsets.symmetric(
          horizontal: paddingSmall,
          vertical: 4,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: const BorderSide(
            color: AppColors.lightGray,
            width: borderWidth,
          ),
        ),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: AppColors.paleGray,
        thickness: borderWidth,
        space: 1,
      ),

      // FloatingActionButton - pointed edges
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.white,
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
          color: AppColors.darkGray,
        ),
      ),

      // PopupMenu - pointed edges
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: const BorderSide(color: AppColors.paleGray, width: borderWidth),
        ),
        textStyle: textTheme.bodyMedium,
      ),

      // SnackBar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.charcoal,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Tab bar
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.charcoal,
        unselectedLabelColor: AppColors.gray,
        labelStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: textTheme.labelLarge,
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(
            color: AppColors.charcoal,
            width: borderWidthHeavy,
          ),
        ),
      ),

      // Progress indicators
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.charcoal,
        linearTrackColor: AppColors.paleGray,
      ),
    );
  }

  /// Creates the dark theme.
  static ThemeData dark() {
    final colorScheme = appDarkColorScheme();
    final textTheme = _buildTextTheme(colorScheme);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: AppColors.darkBackground,

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: AppColors.darkText,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.darkText,
        ),
        iconTheme: const IconThemeData(color: AppColors.darkText, size: 24),
      ),

      // Cards
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: const BorderSide(
            color: AppColors.darkSurfaceElevated,
            width: borderWidth,
          ),
        ),
        margin: EdgeInsets.zero,
      ),

      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.black,
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
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.black,
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
          foregroundColor: AppColors.darkText,
          padding: const EdgeInsets.symmetric(
            horizontal: padding,
            vertical: paddingSmall + 4,
          ),
          side: const BorderSide(color: AppColors.darkText, width: borderWidth),
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
          foregroundColor: AppColors.darkText,
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
          foregroundColor: AppColors.darkText,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
      ),

      // Input fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(
            color: AppColors.darkSurfaceElevated,
            width: borderWidth,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(
            color: AppColors.darkSurfaceElevated,
            width: borderWidth,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(
            color: AppColors.white,
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
          color: AppColors.darkTextSecondary,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.gray),
      ),

      // Dialogs
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkSurface,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: const BorderSide(
            color: AppColors.darkSurfaceElevated,
            width: borderWidth,
          ),
        ),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.darkText,
        ),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: AppColors.darkSurfaceElevated,
        thickness: borderWidth,
        space: 1,
      ),

      // FloatingActionButton
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.black,
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
          color: AppColors.darkText,
        ),
        subtitleTextStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.darkTextSecondary,
        ),
      ),

      // PopupMenu
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.darkSurface,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: const BorderSide(
            color: AppColors.darkSurfaceElevated,
            width: borderWidth,
          ),
        ),
        textStyle: textTheme.bodyMedium?.copyWith(color: AppColors.darkText),
      ),

      // SnackBar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.white,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.charcoal,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Tab bar
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.darkText,
        unselectedLabelColor: AppColors.gray,
        labelStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: textTheme.labelLarge,
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(
            color: AppColors.white,
            width: borderWidthHeavy,
          ),
        ),
      ),

      // Progress indicators
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.white,
        linearTrackColor: AppColors.darkSurfaceElevated,
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
