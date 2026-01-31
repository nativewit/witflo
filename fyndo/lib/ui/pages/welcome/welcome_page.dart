// ═══════════════════════════════════════════════════════════════════════════
// FYNDO - Zero-Trust Notes OS
// Welcome Page - Vault List and Management
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fyndo_app/core/crypto/crypto.dart';
import 'package:fyndo_app/core/vault/vault_service.dart';
import 'package:fyndo_app/platform/platform_init.dart';
import 'package:fyndo_app/providers/vault_providers.dart';
import 'package:fyndo_app/providers/vault_registry.dart';
import 'package:fyndo_app/ui/consumers/vault_consumer.dart';
import 'package:fyndo_app/ui/theme/fyndo_theme.dart';
import 'package:fyndo_app/ui/widgets/common/password_field.dart';
import 'package:fyndo_app/ui/widgets/common/security_badges.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Welcome page for vault listing and management.
class WelcomePage extends ConsumerWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return VaultStatusConsumer(
      builder: (context, status, _) {
        // If vault is unlocked, navigate to home
        if (status == VaultStatus.unlocked) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go('/home');
          });
          return const _LoadingView();
        }

        // Show appropriate view based on status
        if (status == VaultStatus.unlocking || status == VaultStatus.creating) {
          return const _LoadingView();
        }

        return const _WelcomeView();
      },
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text('Loading...', style: theme.textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}

class _WelcomeView extends ConsumerWidget {
  const _WelcomeView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 600;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isWide ? 48 : 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo
                  _buildLogo(theme),
                  const SizedBox(height: 48),

                  // Vault List Section
                  const _VaultListSection(),

                  const SizedBox(height: 48),

                  // Security badges
                  const SecurityBadges(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(ThemeData theme) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.primary, width: 2),
          ),
          child: Icon(Icons.lock, size: 40, color: theme.colorScheme.primary),
        ),
        const SizedBox(height: 24),
        Text(
          'FYNDO',
          style: theme.textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Zero-Trust Notes',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}

class _VaultListSection extends ConsumerWidget {
  const _VaultListSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final registryAsync = ref.watch(vaultRegistryProvider);

    return Container(
      decoration: BoxDecoration(border: Border.all(color: theme.dividerColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(FyndoTheme.padding),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.3,
              ),
              border: Border(bottom: BorderSide(color: theme.dividerColor)),
            ),
            child: Row(
              children: [
                Icon(Icons.folder_special, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your Vaults',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _showCreateVaultDialog(context, ref),
                  tooltip: 'Create New Vault',
                ),
              ],
            ),
          ),

          // Vault list
          registryAsync.when(
            data: (registry) {
              if (registry.vaults.isEmpty) {
                return _buildEmptyState(context, ref, theme);
              }
              return _buildVaultList(context, ref, registry.vaults, theme);
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => Padding(
              padding: const EdgeInsets.all(FyndoTheme.padding),
              child: Text('Error: $error'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.all(FyndoTheme.paddingLarge),
      child: Column(
        children: [
          Icon(
            Icons.lock_outline,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text('No Vaults Yet', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Create your first encrypted vault to get started.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Create Vault'),
            onPressed: () => _showCreateVaultDialog(context, ref),
          ),
        ],
      ),
    );
  }

  Widget _buildVaultList(
    BuildContext context,
    WidgetRef ref,
    List<VaultInfo> vaults,
    ThemeData theme,
  ) {
    return Column(
      children: vaults.map((vault) {
        return _VaultListItem(vault: vault);
      }).toList(),
    );
  }

  void _showCreateVaultDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => const _CreateVaultDialog(),
    );
  }
}

class _VaultListItem extends ConsumerWidget {
  final VaultInfo vault;

  const _VaultListItem({required this.vault});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, yyyy');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showUnlockDialog(context, ref),
        child: Container(
          padding: const EdgeInsets.all(FyndoTheme.padding),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: theme.dividerColor)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(
                    alpha: 0.3,
                  ),
                  border: Border.all(
                    color: vault.isDefault
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline,
                  ),
                ),
                child: Icon(
                  Icons.lock,
                  color: vault.isDefault
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            vault.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (vault.isDefault) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Default',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      vault.lastAccessedAt != null
                          ? 'Last accessed: ${dateFormat.format(vault.lastAccessedAt!)}'
                          : 'Created: ${dateFormat.format(vault.createdAt)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) => _handleMenuAction(context, ref, value),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'unlock',
                    child: ListTile(
                      leading: Icon(Icons.lock_open),
                      title: Text('Unlock'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'rename',
                    child: ListTile(
                      leading: Icon(Icons.edit),
                      title: Text('Rename'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  if (!vault.isDefault)
                    const PopupMenuItem(
                      value: 'setDefault',
                      child: ListTile(
                        leading: Icon(Icons.star_outline),
                        title: Text('Set as Default'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(
                        Icons.delete,
                        color: theme.colorScheme.error,
                      ),
                      title: Text(
                        'Delete',
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUnlockDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => _UnlockVaultDialog(vault: vault),
    );
  }

  void _handleMenuAction(BuildContext context, WidgetRef ref, String action) {
    switch (action) {
      case 'unlock':
        _showUnlockDialog(context, ref);
        break;
      case 'rename':
        _showRenameDialog(context, ref);
        break;
      case 'setDefault':
        ref.read(vaultRegistryProvider.notifier).setDefaultVault(vault.id);
        break;
      case 'delete':
        _confirmDelete(context, ref);
        break;
    }
  }

  void _showRenameDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(text: vault.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Vault'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Vault Name',
            hintText: 'Enter new name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                ref
                    .read(vaultRegistryProvider.notifier)
                    .renameVault(vault.id, controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: theme.colorScheme.error),
            const SizedBox(width: 12),
            const Text('Delete Vault'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete "${vault.name}"?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
                border: Border.all(color: theme.colorScheme.error),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber,
                    color: theme.colorScheme.error,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This action cannot be undone. All notes in this vault '
                      'will be permanently deleted.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
            ),
            onPressed: () {
              ref.read(vaultRegistryProvider.notifier).deleteVault(vault.id);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _UnlockVaultDialog extends ConsumerStatefulWidget {
  final VaultInfo vault;

  const _UnlockVaultDialog({required this.vault});

  @override
  ConsumerState<_UnlockVaultDialog> createState() => _UnlockVaultDialogState();
}

class _UnlockVaultDialogState extends ConsumerState<_UnlockVaultDialog> {
  final _passwordController = TextEditingController();
  bool _isUnlocking = false;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _unlock() async {
    if (_passwordController.text.isEmpty) {
      setState(() => _error = 'Please enter your password');
      return;
    }

    setState(() {
      _isUnlocking = true;
      _error = null;
    });

    try {
      // Set the vault path first
      await ref.read(vaultProvider.notifier).setVaultPath(widget.vault.path);

      final password = SecureBytes.fromList(
        utf8.encode(_passwordController.text),
      );

      await ref.read(vaultProvider.notifier).unlock(password);

      // Record access time
      await ref
          .read(vaultRegistryProvider.notifier)
          .recordAccess(widget.vault.id);

      if (mounted) {
        Navigator.pop(context);
        context.go('/home');
      }
    } on VaultException catch (e) {
      setState(() {
        _error = e.message;
        _isUnlocking = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to unlock vault';
        _isUnlocking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(FyndoTheme.paddingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.lock_open, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Unlock Vault', style: theme.textTheme.titleLarge),
                      Text(
                        widget.vault.name,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            PasswordField(
              controller: _passwordController,
              labelText: 'Master Password',
              hintText: 'Enter your password',
              errorText: _error,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _unlock(),
              enabled: !_isUnlocking,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isUnlocking ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _isUnlocking ? null : _unlock,
                  child: _isUnlocking
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Unlock'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateVaultDialog extends ConsumerStatefulWidget {
  const _CreateVaultDialog();

  @override
  ConsumerState<_CreateVaultDialog> createState() => _CreateVaultDialogState();
}

class _CreateVaultDialogState extends ConsumerState<_CreateVaultDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'My Vault');
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _createVault() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreating = true);

    try {
      // Generate unique vault path
      final basePath = await getAppDocumentsPath();
      final vaultId = DateTime.now().millisecondsSinceEpoch.toString();
      final vaultPath = '$basePath/vaults/$vaultId';

      final password = SecureBytes.fromList(
        utf8.encode(_passwordController.text),
      );

      // Create the vault
      await ref
          .read(vaultProvider.notifier)
          .createVault(path: vaultPath, password: password);

      // Register in vault registry
      await ref
          .read(vaultRegistryProvider.notifier)
          .registerVault(
            name: _nameController.text,
            path: vaultPath,
            setAsDefault: true,
          );

      // Set path and unlock
      await ref.read(vaultProvider.notifier).setVaultPath(vaultPath);

      final unlockPassword = SecureBytes.fromList(
        utf8.encode(_passwordController.text),
      );
      await ref.read(vaultProvider.notifier).unlock(unlockPassword);

      if (mounted) {
        Navigator.of(context).pop();
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to create vault: $e')));
      }
      setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(FyndoTheme.paddingLarge),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.add_box, color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Text('Create New Vault', style: theme.textTheme.titleLarge),
                  ],
                ),
                const SizedBox(height: 24),

                // Vault name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Vault Name',
                    hintText: 'Enter a name for your vault',
                    prefixIcon: Icon(Icons.folder_special),
                  ),
                  enabled: !_isCreating,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a vault name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Warning
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(
                      alpha: 0.2,
                    ),
                    border: Border.all(color: theme.colorScheme.primary),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your vault is encrypted with your master password. '
                          'This password is NEVER stored. If you forget it, '
                          'your data cannot be recovered.',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                PasswordField(
                  controller: _passwordController,
                  labelText: 'Master Password',
                  hintText: 'Enter a strong password',
                  textInputAction: TextInputAction.next,
                  enabled: !_isCreating,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 8) {
                      return 'Password must be at least 8 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                ConfirmPasswordField(
                  controller: _confirmController,
                  passwordController: _passwordController,
                  labelText: 'Confirm Password',
                  textInputAction: TextInputAction.done,
                  enabled: !_isCreating,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isCreating
                          ? null
                          : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: _isCreating ? null : _createVault,
                      child: _isCreating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Create'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
