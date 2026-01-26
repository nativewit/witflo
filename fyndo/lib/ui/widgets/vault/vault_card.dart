// ═══════════════════════════════════════════════════════════════════════════
// FYNDO - Zero-Trust Notes OS
// Vault Card - Visual Representation of a Vault
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:fyndo_app/ui/theme/fyndo_theme.dart';
import 'package:fyndo_app/ui/widgets/common/fyndo_card.dart';

/// A card representing a vault.
class VaultCard extends StatelessWidget {
  /// Vault name.
  final String name;

  /// Optional description.
  final String? description;

  /// Whether vault is locked.
  final bool isLocked;

  /// Note count.
  final int noteCount;

  /// Notebook count.
  final int notebookCount;

  /// Last modified date.
  final DateTime? lastModified;

  /// Tap callback.
  final VoidCallback? onTap;

  /// More options callback.
  final VoidCallback? onMoreOptions;

  /// Whether card is selected.
  final bool isSelected;

  const VaultCard({
    super.key,
    required this.name,
    this.description,
    this.isLocked = true,
    this.noteCount = 0,
    this.notebookCount = 0,
    this.lastModified,
    this.onTap,
    this.onMoreOptions,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FyndoCard(
      onTap: onTap,
      isSelected: isSelected,
      padding: const EdgeInsets.all(FyndoTheme.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isLocked ? Icons.lock : Icons.lock_open,
                size: 24,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
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
          const SizedBox(height: 12),
          Row(
            children: [
              _StatChip(icon: Icons.note, label: '$noteCount notes'),
              const SizedBox(width: 12),
              _StatChip(icon: Icons.book, label: '$notebookCount notebooks'),
            ],
          ),
          if (lastModified != null) ...[
            const SizedBox(height: 8),
            Text(
              'Last modified: ${_formatDate(lastModified!)}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
