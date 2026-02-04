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

  /// Number of vaults (shown as indicator if > 1).
  final int? vaultCount;

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
    this.vaultCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      onTap: onTap,
      isSelected: isSelected,
      padding: const EdgeInsets.all(AppTheme.padding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Main content
          Expanded(
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
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (vaultCount != null && vaultCount! > 1) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.folder_copy_outlined,
                                    size: 12,
                                    color: theme.colorScheme.onPrimaryContainer,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$vaultCount',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color:
                                          theme.colorScheme.onPrimaryContainer,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(width: 4),
                          Icon(
                            Icons.settings,
                            size: 20,
                            color: theme.colorScheme.onSurfaceVariant,
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
                const SizedBox(height: 12),
                Row(
                  children: [
                    _StatChip(icon: Icons.note, label: '$noteCount notes'),
                    const SizedBox(width: 12),
                    _StatChip(
                      icon: Icons.book,
                      label: '$notebookCount notebooks',
                    ),
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
          ),
          // Right: Infographic
          const SizedBox(width: 16),
          _VaultInfoGraphic(
            noteCount: noteCount,
            notebookCount: notebookCount,
            isLocked: isLocked,
          ),
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

/// Infographic showing vault security visualization.
class _VaultInfoGraphic extends StatelessWidget {
  final int noteCount;
  final int notebookCount;
  final bool isLocked;

  const _VaultInfoGraphic({
    required this.noteCount,
    required this.notebookCount,
    required this.isLocked,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalItems = noteCount + notebookCount;

    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background pattern (encrypted data visual)
          Positioned.fill(
            child: CustomPaint(
              painter: _EncryptionPatternPainter(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
              ),
            ),
          ),
          // Central icon and count
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isLocked ? Icons.shield : Icons.shield_outlined,
                size: 48,
                color: theme.colorScheme.primary.withValues(alpha: 0.7),
              ),
              const SizedBox(height: 4),
              Text(
                '$totalItems',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'items',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Custom painter for encryption pattern background.
class _EncryptionPatternPainter extends CustomPainter {
  final Color color;

  _EncryptionPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Draw a grid pattern representing encrypted data
    final spacing = 12.0;

    // Vertical lines
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Horizontal lines
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_EncryptionPatternPainter oldDelegate) =>
      oldDelegate.color != color;
}
