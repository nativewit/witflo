// ═══════════════════════════════════════════════════════════════════════════
// FYNDO - Zero-Trust Notes OS
// Note Card - Visual Representation of a Note
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:fyndo_app/ui/widgets/common/fyndo_card.dart';
import 'package:intl/intl.dart';

/// A card representing a note.
class NoteCard extends StatelessWidget {
  /// Note title.
  final String title;

  /// Note preview content.
  final String? preview;

  /// Modification date.
  final DateTime modifiedAt;

  /// Tags.
  final List<String> tags;

  /// Whether note is pinned.
  final bool isPinned;

  /// Whether note is archived.
  final bool isArchived;

  /// Tap callback.
  final VoidCallback? onTap;

  /// Long press callback.
  final VoidCallback? onLongPress;

  /// Whether card is selected.
  final bool isSelected;

  const NoteCard({
    super.key,
    required this.title,
    this.preview,
    required this.modifiedAt,
    this.tags = const [],
    this.isPinned = false,
    this.isArchived = false,
    this.onTap,
    this.onLongPress,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      onTap: onTap,
      onLongPress: onLongPress,
      isSelected: isSelected,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isPinned) ...[
                Icon(
                  Icons.push_pin,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  title.isEmpty ? 'Untitled' : title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontStyle: title.isEmpty ? FontStyle.italic : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isArchived)
                Icon(
                  Icons.archive,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
            ],
          ),
          if (preview != null && preview!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              preview!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                _formatDate(modifiedAt),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (tags.isNotEmpty) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: tags.take(3).map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: Text(tag, style: theme.textTheme.labelSmall),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inDays == 0) {
      return DateFormat.jm().format(date);
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return DateFormat.EEEE().format(date);
    } else {
      return DateFormat.MMMd().format(date);
    }
  }
}
