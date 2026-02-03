// ═══════════════════════════════════════════════════════════════════════════
// FYNDO - Zero-Trust Notes OS
// Vault Page - Vault Details and Settings
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:fyndo_app/core/agentic/fyndo_keys.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fyndo_app/core/workspace/unlocked_workspace.dart';
import 'package:fyndo_app/providers/crypto_providers.dart';
import 'package:fyndo_app/providers/unlocked_workspace_provider.dart';
import 'package:fyndo_app/providers/vault_selection_providers.dart';
import 'package:fyndo_app/ui/theme/fyndo_theme.dart';
import 'package:fyndo_app/ui/widgets/common/fyndo_app_bar.dart';
import 'package:fyndo_app/ui/widgets/common/fyndo_card.dart';
import 'package:fyndo_app/ui/widgets/note/note_share_dialog.dart';
import 'package:fyndo_app/ui/widgets/vault/vault_delete_dialog.dart';
import 'package:fyndo_app/ui/widgets/vault/vault_export_dialog.dart';
import 'package:go_router/go_router.dart';

/// Vault details and settings page.
class VaultPage extends ConsumerWidget {
  final String? vaultId;

  const VaultPage({super.key, this.vaultId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Check if workspace is unlocked (not individual vault)
    final workspace = ref.watch(unlockedWorkspaceProvider);

    if (workspace == null) {
      // Workspace is locked, redirect to welcome page
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return _VaultPageContent();
  }
}

class _VaultPageContent extends ConsumerWidget {
  const _VaultPageContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final vaultId = ref.watch(activeVaultIdProvider) ?? 'Unknown';

    return Scaffold(
      appBar: FyndoAppBar(
        title: const FyndoAppBarTitle('Vault Settings'),
        actions: [
          PopupMenuButton<String>(
            key: FyndoKeys.menuVaultActions,
            icon: const Icon(Icons.more_vert),
            onSelected: (value) => _handleMenuAction(context, ref, value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'share',
                child: ListTile(
                  leading: Icon(Icons.share),
                  title: Text('Share Vault'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.download),
                  title: Text('Export Vault'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(FyndoTheme.padding),
        children: [
          // Vault info
          FyndoCard(
            padding: const EdgeInsets.all(FyndoTheme.padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        border: Border.all(color: theme.colorScheme.primary),
                      ),
                      child: Icon(Icons.lock, color: theme.colorScheme.primary),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('My Vault', style: theme.textTheme.titleLarge),
                          Text(
                            'Unlocked',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                _buildInfoRow(
                  context,
                  icon: Icons.fingerprint,
                  label: 'Vault ID',
                  value: vaultId,
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  context,
                  icon: Icons.security,
                  label: 'Encryption',
                  value: 'XChaCha20-Poly1305',
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  context,
                  icon: Icons.key,
                  label: 'Key Derivation',
                  value: 'Argon2id',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Security settings
          Text('Security', style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),
          FyndoCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  key: FyndoKeys.btnChangePassword,
                  leading: const Icon(Icons.lock_reset),
                  title: const Text('Change Password'),
                  subtitle: const Text('Update your master password'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showChangePassword(context, ref),
                ),
                const Divider(height: 1),
                ListTile(
                  key: FyndoKeys.btnRecoveryOptions,
                  leading: const Icon(Icons.restore),
                  title: const Text('Recovery Options'),
                  subtitle: const Text('Set up recovery key'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showRecoveryOptions(context),
                ),
                const Divider(height: 1),
                ListTile(
                  key: FyndoKeys.btnLinkedDevices,
                  leading: const Icon(Icons.devices),
                  title: const Text('Linked Devices'),
                  subtitle: const Text('Manage device access'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showLinkedDevices(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Sync settings
          Text('Sync & Backup', style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),
          FyndoCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                SwitchListTile(
                  key: FyndoKeys.switchEnableSync,
                  title: const Text('Enable Sync'),
                  subtitle: const Text('Sync encrypted data across devices'),
                  value: false,
                  onChanged: (value) {
                    // TODO: Enable sync
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  key: FyndoKeys.btnBackupCloud,
                  leading: const Icon(Icons.cloud_upload),
                  title: const Text('Backup to Cloud'),
                  subtitle: const Text('Not configured'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showBackupOptions(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Danger zone
          Text(
            'Danger Zone',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 16),
          FyndoCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  key: FyndoKeys.btnDeleteVault,
                  leading: Icon(
                    Icons.delete_forever,
                    color: theme.colorScheme.error,
                  ),
                  title: Text(
                    'Delete Vault',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                  subtitle: const Text('Permanently delete all data'),
                  onTap: () => _confirmDeleteVault(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(value, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }

  void _handleMenuAction(BuildContext context, WidgetRef ref, String action) {
    switch (action) {
      case 'share':
        ShareDialog.show(
          context,
          itemName: 'My Vault',
          itemType: ShareItemType.vault,
          onGenerateLink: () async {
            // TODO: Generate share link
            return 'https://fyndo.app/share/vault/abc123';
          },
          onShareWithUser: (email, role) {
            // TODO: Share with user
          },
        );
        break;
      case 'export':
        VaultExportDialog.show(context);
        break;
    }
  }

  void _showChangePassword(BuildContext context, WidgetRef ref) {
    // TODO: Show change password dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Change password coming soon')),
    );
  }

  void _showRecoveryOptions(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Recovery options coming soon')),
    );
  }

  void _showLinkedDevices(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Linked devices coming soon')));
  }

  void _showBackupOptions(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Backup options coming soon')));
  }

  void _confirmDeleteVault(BuildContext context, WidgetRef ref) async {
    // Get vault metadata and ID
    final metadataAsync = await ref.read(activeVaultMetadataProvider.future);
    final vaultName = metadataAsync?.name ?? 'My Vault';
    final vaultId = ref.read(activeVaultIdProvider);

    if (!context.mounted) return;

    VaultDeleteDialog.show(
      context,
      vaultName: vaultName,
      onConfirmDelete: () async {
        try {
          // Get workspace and service
          final workspace = ref.read(unlockedWorkspaceProvider);
          final workspaceService = ref.read(workspaceServiceProvider);

          if (workspace == null) {
            throw Exception('Workspace not unlocked');
          }

          // Ensure vaultId is not null or empty
          if (vaultId == null || vaultId.isEmpty) {
            throw Exception('No vault selected');
          }

          // Delete the vault (updates keyring and deletes filesystem)
          await workspaceService.deleteVault(
            workspace: workspace,
            vaultId: vaultId,
          );

          // CRITICAL: Create a NEW workspace instance to trigger Riverpod change detection
          // The deleteVault() method modifies workspace.keyring in-place, but Riverpod
          // uses identity comparison (identical()) to detect changes. Creating a new
          // instance ensures dependent providers rebuild.
          final updatedWorkspace = UnlockedWorkspace(
            muk: workspace.muk, // Reuse the same MUK (don't dispose)
            keyring: workspace.keyring, // Already updated by deleteVault()
            rootPath: workspace.rootPath,
          );

          // CRITICAL: Clear the current vault selection first
          // (since the deleted vault might be selected)
          ref.read(selectedVaultIdProvider.notifier).clearSelection();

          // Update the workspace provider with NEW instance
          // This triggers all dependent providers to rebuild
          ref.read(unlockedWorkspaceProvider.notifier).update(updatedWorkspace);

          // Select a different vault (first available after deletion)
          ref.read(selectedVaultIdProvider.notifier).ensureSelection();

          // Navigate away to home
          if (context.mounted) {
            context.go('/');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Vault "$vaultName" deleted successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          // Show error message
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to delete vault: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
    );
  }
}
