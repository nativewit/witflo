// ═══════════════════════════════════════════════════════════════════════════
// FYNDO - Zero-Trust Notes OS
// Fyndo Card - Paper-like Card with Pointed Edges
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:fyndo_app/ui/theme/fyndo_theme.dart';

/// A card widget with pointed edges (no border radius).
class AppCard extends StatelessWidget {
  /// Card content.
  final Widget child;

  /// Optional padding.
  final EdgeInsets? padding;

  /// Optional margin.
  final EdgeInsets? margin;

  /// Whether to show border.
  final bool showBorder;

  /// Optional tap callback.
  final VoidCallback? onTap;

  /// Optional long press callback.
  final VoidCallback? onLongPress;

  /// Whether card is selected.
  final bool isSelected;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.showBorder = true,
    this.onTap,
    this.onLongPress,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget content = Container(
      padding: padding ?? const EdgeInsets.all(AppTheme.padding),
      decoration: BoxDecoration(
        color: isSelected
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
            : theme.cardTheme.color,
        border: showBorder
            ? Border.all(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.dividerColor,
                width: isSelected ? 2 : 1,
              )
            : null,
      ),
      child: child,
    );

    if (onTap != null || onLongPress != null) {
      content = InkWell(onTap: onTap, onLongPress: onLongPress, child: content);
    }

    if (margin != null) {
      content = Padding(padding: margin!, child: content);
    }

    return content;
  }
}
