// ═══════════════════════════════════════════════════════════════════════════
// WITFLO - Zero-Trust Notes OS
// Vault Export Dialog - Export Vault Data in Decrypted Format
// ═══════════════════════════════════════════════════════════════════════════
//
// WARNING: This exports DECRYPTED data to disk!
// This is a power-user feature for debugging/backup purposes only.
// The user must explicitly acknowledge the security risks.
//
// ═══════════════════════════════════════════════════════════════════════════

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:witflo_app/core/agentic/app_keys.dart';
import 'package:witflo_app/providers/vault_export_providers.dart';
import 'package:witflo_app/providers/vault_selection_providers.dart';
import 'package:witflo_app/ui/theme/app_theme.dart';

/// Dialog for exporting vault data in decrypted format.
///
/// This is a power-user feature that exports all vault data (metadata,
/// notebooks, notes) in plain JSON format to a selected folder.
///
/// SECURITY WARNING: The exported data is NOT encrypted and can be read
/// by anyone with access to the export folder.
class VaultExportDialog extends ConsumerStatefulWidget {
  const VaultExportDialog({super.key});

  /// Shows the export vault dialog.
  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const VaultExportDialog(),
    );
  }

  @override
  ConsumerState<VaultExportDialog> createState() => _VaultExportDialogState();
}

class _VaultExportDialogState extends ConsumerState<VaultExportDialog> {
  String? _selectedVaultId;
  String? _selectedFolderPath;
  bool _acknowledgedWarning = false;
  bool _isExporting = false;

  Future<void> _selectFolder() async {
    final path = await getDirectoryPath();
    if (path != null) {
      setState(() {
        _selectedFolderPath = path;
      });
    }
  }

  Future<void> _export() async {
    if (_selectedVaultId == null || _selectedFolderPath == null) return;
    if (!_acknowledgedWarning) return;

    setState(() => _isExporting = true);

    try {
      final result = await ref
          .read(vaultExportProvider.notifier)
          .exportVault(
            vaultId: _selectedVaultId!,
            exportPath: _selectedFolderPath!,
          );

      if (!mounted) return;

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully exported ${result.noteCount} notes and '
              '${result.notebookCount} notebooks',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: ${result.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vaultsAsync = ref.watch(availableVaultsProvider);

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(AppTheme.paddingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.upload_file, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Text('Export Vault Data', style: theme.textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 24),

            // Security Warning Box
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
                        Icons.warning_amber_rounded,
                        color: theme.colorScheme.error,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'SECURITY WARNING',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Exported data will NOT be encrypted!',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Data will be stored in plain text JSON files\n'
                    '• Anyone with access can read your notes\n'
                    '• Use this feature for debugging or backup only\n'
                    '• Delete exported files when done',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Vault Selection Dropdown
            vaultsAsync.when(
              data: (vaults) {
                if (vaults.isEmpty) {
                  return const Text('No vaults available');
                }

                // Auto-select first vault if none selected
                if (_selectedVaultId == null && vaults.isNotEmpty) {
                  Future.microtask(() {
                    setState(() {
                      _selectedVaultId = vaults.first.vaultId;
                    });
                  });
                }

                return DropdownButtonFormField<String>(
                  key: AppKeys.dropdownExportVaultSelect,
                  initialValue: _selectedVaultId,
                  decoration: const InputDecoration(
                    labelText: 'Select Vault',
                    prefixIcon: Icon(Icons.folder_special),
                  ),
                  items: vaults.map((vault) {
                    return DropdownMenuItem(
                      value: vault.vaultId,
                      child: Text(vault.metadata.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedVaultId = value;
                    });
                  },
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (err, stack) => Text('Error loading vaults: $err'),
            ),
            const SizedBox(height: 16),

            // Folder Selection
            OutlinedButton.icon(
              key: AppKeys.btnExportSelectFolder,
              onPressed: _isExporting ? null : _selectFolder,
              icon: const Icon(Icons.folder_open),
              label: Text(_selectedFolderPath ?? 'Select Export Folder'),
            ),
            if (_selectedFolderPath != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(AppTheme.paddingSmall),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _selectedFolderPath!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Acknowledgment Checkbox
            CheckboxListTile(
              key: AppKeys.checkboxExportWarning,
              value: _acknowledgedWarning,
              onChanged: _isExporting
                  ? null
                  : (value) {
                      setState(() {
                        _acknowledgedWarning = value ?? false;
                      });
                    },
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(
                'I understand the security risks of exporting unencrypted data',
                style: theme.textTheme.bodyMedium,
              ),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  key: AppKeys.btnExportCancel,
                  onPressed: _isExporting ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  key: AppKeys.btnExportConfirm,
                  onPressed:
                      (_selectedVaultId != null &&
                          _selectedFolderPath != null &&
                          _acknowledgedWarning &&
                          !_isExporting)
                      ? _export
                      : null,
                  icon: _isExporting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.upload_file),
                  label: Text(_isExporting ? 'Exporting...' : 'Export'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
