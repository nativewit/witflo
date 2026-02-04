// ═══════════════════════════════════════════════════════════════════════════
// WITFLO - Zero-Trust Notes OS
// Vault Switcher Dialog - Switch between vaults or create new ones
// ═══════════════════════════════════════════════════════════════════════════
//
// PURPOSE:
// This dialog allows users to:
// 1. View all available vaults in the workspace
// 2. Switch between vaults by tapping on one
// 3. Create a new vault via the VaultCreateDialog
//
// Spec: docs/specs/spec-002-workspace-master-password.md
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:witflo_app/core/agentic/app_keys.dart';
import 'package:witflo_app/providers/vault_selection_providers.dart';
import 'package:witflo_app/ui/theme/app_theme.dart';
import 'package:witflo_app/ui/widgets/vault/vault_create_dialog.dart';

/// Dialog for switching between vaults or creating new ones.
class VaultSwitcherDialog extends ConsumerWidget {
  /// Callback when a vault is selected.
  final void Function(String vaultId)? onVaultSelected;

  /// Callback when a new vault is created.
  final Future<void> Function({
    required String name,
    String? description,
    String? icon,
    String? color,
  })?
  onCreateVault;

  const VaultSwitcherDialog({
    super.key,
    this.onVaultSelected,
    this.onCreateVault,
  });

  /// Shows the vault switcher dialog.
  static Future<void> show(
    BuildContext context, {
    void Function(String vaultId)? onVaultSelected,
    Future<void> Function({
      required String name,
      String? description,
      String? icon,
      String? color,
    })?
    onCreateVault,
  }) {
    return showDialog(
      context: context,
      builder: (context) => VaultSwitcherDialog(
        onVaultSelected: onVaultSelected,
        onCreateVault: onCreateVault,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final availableVaultsAsync = ref.watch(availableVaultsProvider);

    return Dialog(
      key: AppKeys.vaultSwitcherDialog,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(AppTheme.paddingLarge),
              child: Row(
                children: [
                  Icon(Icons.folder_copy, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Text('Switch Vault', style: theme.textTheme.titleLarge),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Vault list
            Flexible(
              child: availableVaultsAsync.when(
                data: (vaults) {
                  if (vaults.isEmpty) {
                    return _buildEmptyState(context, theme);
                  }

                  return ListView.builder(
                    key: AppKeys.vaultList,
                    shrinkWrap: true,
                    itemCount: vaults.length,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppTheme.paddingSmall,
                    ),
                    itemBuilder: (context, index) {
                      final vault = vaults[index];
                      return _VaultListItem(
                        vault: vault,
                        onTap: () {
                          ref
                              .read(selectedVaultIdProvider.notifier)
                              .selectVault(vault.vaultId);
                          onVaultSelected?.call(vault.vaultId);
                          Navigator.pop(context);
                        },
                      );
                    },
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(AppTheme.paddingLarge),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, stack) => Padding(
                  padding: const EdgeInsets.all(AppTheme.paddingLarge),
                  child: Center(
                    child: Text(
                      'Error loading vaults: $error',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                ),
              ),
            ),

            const Divider(height: 1),

            // Create vault button
            Padding(
              padding: const EdgeInsets.all(AppTheme.padding),
              child: TextButton.icon(
                key: AppKeys.btnCreateVaultSwitcher,
                onPressed: () => _showCreateVaultDialog(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('Create New Vault'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.paddingLarge),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.folder_off,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text('No Vaults', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Create your first vault to get started.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showCreateVaultDialog(BuildContext context, WidgetRef ref) {
    Navigator.pop(context); // Close switcher first
    VaultCreateDialog.show(context, onCreateVault: onCreateVault);
  }
}

/// List item for a vault in the switcher.
class _VaultListItem extends StatelessWidget {
  final VaultInfo vault;
  final VoidCallback? onTap;

  const _VaultListItem({required this.vault, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metadata = vault.metadata;

    // Parse color from metadata
    Color? vaultColor;
    if (metadata.color != null) {
      try {
        final colorStr = metadata.color!.replaceFirst('#', '');
        vaultColor = Color(int.parse('FF$colorStr', radix: 16));
      } catch (_) {
        // Ignore invalid color
      }
    }

    return InkWell(
      key: AppKeys.vaultSwitcherItem(vault.vaultId),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.paddingLarge,
          vertical: AppTheme.padding,
        ),
        decoration: BoxDecoration(
          color: vault.isSelected
              ? theme.colorScheme.primaryContainer.withOpacity(0.3)
              : null,
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (vaultColor ?? theme.colorScheme.primary).withOpacity(
                  0.15,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: metadata.icon != null
                    ? Text(metadata.icon!, style: const TextStyle(fontSize: 20))
                    : Icon(
                        Icons.folder,
                        color: vaultColor ?? theme.colorScheme.primary,
                      ),
              ),
            ),
            const SizedBox(width: 16),

            // Name and description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    metadata.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: vault.isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  if (metadata.description != null &&
                      metadata.description!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        metadata.description!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),

            // Selected indicator
            if (vault.isSelected)
              Icon(
                Icons.check_circle,
                color: theme.colorScheme.primary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
