// ═══════════════════════════════════════════════════════════════════════════
// WITFLO - Zero-Trust Notes OS
// Security Badges - Visual Security Indicators
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:witflo_app/ui/theme/app_colors.dart';

/// Security badges showing Witflo's security features.
class SecurityBadges extends StatelessWidget {
  /// Whether to show compact badges.
  final bool compact;

  /// Alignment of badges.
  final WrapAlignment alignment;

  const SecurityBadges({
    super.key,
    this.compact = false,
    this.alignment = WrapAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: alignment,
      children: [
        _SecurityBadge(
          icon: Icons.lock,
          label: 'E2E Encrypted',
          compact: compact,
        ),
        _SecurityBadge(
          icon: Icons.cloud_off,
          label: 'Local-First',
          compact: compact,
        ),
        _SecurityBadge(
          icon: Icons.verified_user,
          label: 'Zero-Trust',
          compact: compact,
        ),
        _SecurityBadge(
          icon: Icons.code,
          label: 'Open Source',
          compact: compact,
        ),
      ],
    );
  }
}

class _SecurityBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool compact;

  const _SecurityBadge({
    required this.icon,
    required this.label,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : AppColors.paleGray,
        border: Border.all(
          color: isDark ? AppColors.darkGray : AppColors.lightGray,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: compact ? 12 : 14,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: compact ? 10 : 12,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
