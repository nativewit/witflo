// ═══════════════════════════════════════════════════════════════════════════
// WITFLO - Zero-Trust Notes OS
// Notebook Card - Visual Representation of a Notebook
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:witflo_app/ui/widgets/common/app_card.dart';

/// A card representing a notebook.
class NotebookCard extends StatelessWidget {
  /// Notebook name.
  final String name;

  /// Optional description.
  final String? description;

  /// Note count.
  final int noteCount;

  /// Color hex code.
  final String? color;

  /// Icon name.
  final String? icon;

  /// Tap callback.
  final VoidCallback? onTap;

  /// More options callback.
  final VoidCallback? onMoreOptions;

  /// Whether card is selected.
  final bool isSelected;

  const NotebookCard({
    super.key,
    required this.name,
    this.description,
    this.noteCount = 0,
    this.color,
    this.icon,
    this.onTap,
    this.onMoreOptions,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = color != null
        ? Color(int.parse('0xFF$color'))
        : theme.colorScheme.primary;

    return AppCard(
      onTap: onTap,
      isSelected: isSelected,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  border: Border.all(color: accentColor),
                ),
                child: Icon(_getIconData(icon), size: 20, color: accentColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '$noteCount notes',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (onMoreOptions != null)
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: onMoreOptions,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  iconSize: 20,
                ),
            ],
          ),
          if (description != null && description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              description!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  IconData _getIconData(String? iconName) {
    switch (iconName) {
      case 'work':
        return Icons.work;
      case 'personal':
        return Icons.person;
      case 'ideas':
        return Icons.lightbulb;
      case 'journal':
        return Icons.auto_stories;
      case 'finance':
        return Icons.attach_money;
      case 'health':
        return Icons.favorite;
      case 'travel':
        return Icons.flight;
      case 'education':
        return Icons.school;
      case 'project':
        return Icons.folder_special;
      default:
        return Icons.book;
    }
  }
}
