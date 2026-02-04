// ═══════════════════════════════════════════════════════════════════════════
// WITFLO - Zero-Trust Notes OS
// Witflo Empty State - Consistent Empty State Widget
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:witflo_app/ui/theme/app_theme.dart';

/// Empty state widget with icon, title, and optional action.
class AppEmptyState extends StatelessWidget {
  /// Icon to display.
  final IconData icon;

  /// Title text.
  final String title;

  /// Optional description.
  final String? description;

  /// Optional action button text.
  final String? actionText;

  /// Optional action callback.
  final VoidCallback? onAction;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            if (description != null) ...[
              const SizedBox(height: 8),
              Text(
                description!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 24),
              FilledButton(onPressed: onAction, child: Text(actionText!)),
            ],
          ],
        ),
      ),
    );
  }
}
