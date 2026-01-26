// ═══════════════════════════════════════════════════════════════════════════
// FYNDO - Zero-Trust Notes OS
// Fyndo List Tile - Custom List Tile with Pointed Edges
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:fyndo_app/ui/theme/fyndo_theme.dart';

/// A list tile widget with pointed edges.
class FyndoListTile extends StatelessWidget {
  /// Leading widget.
  final Widget? leading;

  /// Title widget.
  final Widget title;

  /// Subtitle widget.
  final Widget? subtitle;

  /// Trailing widget.
  final Widget? trailing;

  /// Tap callback.
  final VoidCallback? onTap;

  /// Long press callback.
  final VoidCallback? onLongPress;

  /// Whether tile is selected.
  final bool isSelected;

  /// Content padding.
  final EdgeInsets? contentPadding;

  /// Whether to show bottom border.
  final bool showBorder;

  const FyndoListTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.isSelected = false,
    this.contentPadding,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding:
            contentPadding ??
            const EdgeInsets.symmetric(
              horizontal: FyndoTheme.padding,
              vertical: FyndoTheme.paddingSmall + 4,
            ),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
              : null,
          border: showBorder
              ? Border(bottom: BorderSide(color: theme.dividerColor, width: 1))
              : null,
        ),
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 16)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DefaultTextStyle(
                    style: theme.textTheme.bodyLarge!.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                    child: title,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    DefaultTextStyle(
                      style: theme.textTheme.bodyMedium!.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                      child: subtitle!,
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 16), trailing!],
          ],
        ),
      ),
    );
  }
}
