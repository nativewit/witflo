import 'package:flutter/material.dart';
import 'encryption_pattern_background.dart';

/// Reusable Witflo logo widget with encryption pattern background
///
/// Provides consistent logo rendering across the app with three size variants:
/// - small: 120x120 (onboarding, dialogs)
/// - medium: 160x160 (default, unlock screen)
/// - large: 240x240 (welcome screen)
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = AppLogoSize.medium,
    this.showLockBadge = false,
    this.showTitle = false,
    this.subtitle,
  });

  /// Size variant for the logo
  final AppLogoSize size;

  /// Whether to show the "LOCKED" badge overlay (for unlock screens)
  final bool showLockBadge;

  /// Whether to show "WITFLO" title below the logo
  final bool showTitle;

  /// Optional subtitle to show below the title
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dimensions = _getDimensions();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo with encryption pattern background
        Stack(
          alignment: Alignment.center,
          children: [
            // Background infographic
            EncryptionPatternBackground(
              width: dimensions.backgroundSize,
              height: dimensions.backgroundSize,
            ),
            // Logo image
            Image.asset(
              dimensions.assetPath,
              width: dimensions.logoSize,
              height: dimensions.logoSize,
              filterQuality: FilterQuality.high,
            ),
            // Optional lock badge overlay
            if (showLockBadge)
              Positioned(
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.primary,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lock,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'LOCKED',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),

        // Optional title
        if (showTitle) ...[
          SizedBox(height: dimensions.titleSpacing),
          Text(
            'WITFLO',
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 4,
            ),
          ),
        ],

        // Optional subtitle
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  _LogoDimensions _getDimensions() {
    switch (size) {
      case AppLogoSize.small:
        return _LogoDimensions(
          assetPath: 'assets/images/logo_256.png',
          logoSize: 120,
          backgroundSize: 136,
          titleSpacing: 16,
        );
      case AppLogoSize.medium:
        return _LogoDimensions(
          assetPath: 'assets/images/logo_256.png',
          logoSize: 160,
          backgroundSize: 176,
          titleSpacing: 24,
        );
      case AppLogoSize.large:
        return _LogoDimensions(
          assetPath: 'assets/images/logo_512.png',
          logoSize: 240,
          backgroundSize: 256,
          titleSpacing: 32,
        );
    }
  }
}

/// Size variants for the AppLogo widget
enum AppLogoSize {
  /// Small (120x120) - for onboarding, dialogs
  small,

  /// Medium (160x160) - default size for unlock screen
  medium,

  /// Large (240x240) - for welcome screen
  large,
}

/// Internal class to hold dimension values for each logo size
class _LogoDimensions {
  const _LogoDimensions({
    required this.assetPath,
    required this.logoSize,
    required this.backgroundSize,
    required this.titleSpacing,
  });

  final String assetPath;
  final double logoSize;
  final double backgroundSize;
  final double titleSpacing;
}
