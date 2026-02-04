// ═══════════════════════════════════════════════════════════════════════════
// WITFLO - Zero-Trust Notes OS
// Vault Delete Dialog - Delete Vault with Strong Warning
// ═══════════════════════════════════════════════════════════════════════════
//
// WARNING: This permanently deletes ALL vault data!
// This is a destructive operation with strong confirmation requirements.
//
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:witflo_app/ui/theme/app_theme.dart';

/// Dialog for deleting a vault with strong warnings.
///
/// Requires the user to type the vault name to confirm deletion.
class VaultDeleteDialog extends StatefulWidget {
  final String vaultName;
  final Future<void> Function()? onConfirmDelete;

  const VaultDeleteDialog({
    super.key,
    required this.vaultName,
    this.onConfirmDelete,
  });

  /// Shows the delete vault dialog.
  static Future<void> show(
    BuildContext context, {
    required String vaultName,
    Future<void> Function()? onConfirmDelete,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => VaultDeleteDialog(
        vaultName: vaultName,
        onConfirmDelete: onConfirmDelete,
      ),
    );
  }

  @override
  State<VaultDeleteDialog> createState() => _VaultDeleteDialogState();
}

class _VaultDeleteDialogState extends State<VaultDeleteDialog> {
  final _confirmController = TextEditingController();
  bool _isDeleting = false;
  bool _canDelete = false;

  @override
  void initState() {
    super.initState();
    _confirmController.addListener(_checkConfirmation);
  }

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  void _checkConfirmation() {
    setState(() {
      _canDelete = _confirmController.text == widget.vaultName;
    });
  }

  Future<void> _delete() async {
    if (!_canDelete) return;

    setState(() => _isDeleting = true);

    try {
      await widget.onConfirmDelete?.call();
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete vault: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(AppTheme.paddingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with error icon
            Row(
              children: [
                Icon(
                  Icons.warning_rounded,
                  color: theme.colorScheme.error,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Delete Vault?',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Danger warning box
            Container(
              padding: const EdgeInsets.all(AppTheme.padding),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
                border: Border.all(color: theme.colorScheme.error, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.delete_forever,
                        color: theme.colorScheme.error,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'THIS ACTION CANNOT BE UNDONE',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'All data in this vault will be permanently deleted:',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• All notes and notebooks\n'
                    '• All attachments and files\n'
                    '• All settings and metadata\n'
                    '• Encryption keys (data cannot be recovered)',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '⚠️ Lost data cannot be recovered, even by Witflo support!',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Confirmation input
            Text(
              'To confirm deletion, type the vault name:',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                widget.vaultName,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmController,
              enabled: !_isDeleting,
              decoration: InputDecoration(
                hintText: 'Type vault name to confirm',
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: theme.colorScheme.error),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: theme.colorScheme.error,
                    width: 2,
                  ),
                ),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 24),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isDeleting ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: (_canDelete && !_isDeleting) ? _delete : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.error,
                    foregroundColor: theme.colorScheme.onError,
                  ),
                  icon: _isDeleting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.delete_forever),
                  label: Text(_isDeleting ? 'Deleting...' : 'Delete Forever'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
