// ═══════════════════════════════════════════════════════════════════════════
// FYNDO - Zero-Trust Notes OS
// Fyndo App Bar - Paper-like Notebook Aesthetic
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

/// Custom app bar with paper-like aesthetic.
class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Title text or widget.
  final Widget? title;

  /// Leading widget.
  final Widget? leading;

  /// Trailing actions.
  final List<Widget>? actions;

  /// Whether to show bottom border.
  final bool showBorder;

  /// Whether to center the title.
  final bool centerTitle;

  /// Custom height.
  final double height;

  const AppAppBar({
    super.key,
    this.title,
    this.leading,
    this.actions,
    this.showBorder = true,
    this.centerTitle = false,
    this.height = kToolbarHeight,
  });

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: showBorder
            ? Border(bottom: BorderSide(color: theme.dividerColor, width: 1))
            : null,
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: height,
          child: Row(
            children: [
              if (leading != null) ...[
                leading!,
              ] else if (Navigator.canPop(context)) ...[
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.maybePop(context),
                  tooltip: 'Back',
                ),
              ] else ...[
                const SizedBox(width: 16),
              ],
              if (centerTitle) const Spacer(),
              if (title != null)
                Expanded(
                  flex: centerTitle ? 0 : 1,
                  child: DefaultTextStyle(
                    style: theme.textTheme.titleLarge!.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                    child: title!,
                  ),
                ),
              if (centerTitle) const Spacer(),
              if (actions != null) ...actions!,
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}

/// Simple app bar title text.
class AppBarTitle extends StatelessWidget {
  final String text;

  const AppBarTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      overflow: TextOverflow.ellipsis,
    );
  }
}
