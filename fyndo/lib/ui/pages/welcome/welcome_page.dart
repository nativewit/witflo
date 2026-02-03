// ═══════════════════════════════════════════════════════════════════════════
// FYNDO - Zero-Trust Notes OS
// Welcome Page - Vault List and Management
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fyndo_app/core/agentic/fyndo_keys.dart';
import 'package:fyndo_app/core/crypto/crypto.dart';
import 'package:fyndo_app/providers/crypto_providers.dart';
import 'package:fyndo_app/providers/unlocked_workspace_provider.dart';
import 'package:fyndo_app/providers/vault_registry.dart';
import 'package:fyndo_app/providers/workspace_provider.dart';
import 'package:fyndo_app/ui/theme/fyndo_theme.dart';
import 'package:fyndo_app/ui/widgets/common/password_field.dart';
import 'package:fyndo_app/ui/widgets/common/security_badges.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Welcome page for vault listing and workspace unlock.
///
/// This page implements the spec-002 workspace master password flow:
/// 1. User unlocks workspace with single master password
/// 2. All vaults become accessible without individual passwords
/// 3. Lock button allows re-locking workspace
///
/// Spec: docs/specs/spec-002-workspace-master-password.md (Section 3.2)
class WelcomePage extends ConsumerWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspaceAsync = ref.watch(workspaceProvider);
    final unlockedWorkspace = ref.watch(unlockedWorkspaceProvider);

    return workspaceAsync.when(
      data: (workspaceState) {
        // If workspace is unlocked, show vault list
        if (unlockedWorkspace != null) {
          return const _UnlockedWorkspaceView();
        }

        // If workspace exists but is locked, show unlock screen
        if (workspaceState.hasWorkspace) {
          return const _WorkspaceUnlockView();
        }

        // No workspace configured
        return const _NoWorkspaceView();
      },
      loading: () => const _LoadingView(),
      error: (error, _) => _ErrorView(error: error.toString()),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// View: Loading
// ═══════════════════════════════════════════════════════════════════════════

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

// ═══════════════════════════════════════════════════════════════════════════
// View: Error
// ═══════════════════════════════════════════════════════════════════════════

class _ErrorView extends StatelessWidget {
  final String error;

  const _ErrorView({required this.error});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(FyndoTheme.paddingLarge),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: theme.colorScheme.error),
              const SizedBox(height: 24),
              Text(
                'Error Loading Workspace',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Text(
                error,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// View: No Workspace
// ═══════════════════════════════════════════════════════════════════════════

class _NoWorkspaceView extends StatelessWidget {
  const _NoWorkspaceView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(FyndoTheme.paddingLarge),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.folder_off,
                size: 64,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 24),
              Text(
                'No Workspace Configured',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Text(
                'Please run the onboarding flow to set up your workspace.',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                key: FyndoKeys.btnGetStarted,
                icon: const Icon(Icons.start),
                label: const Text('Get Started'),
                onPressed: () => context.go('/onboarding'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// View: Workspace Unlock (Locked workspace - enter master password)
// ═══════════════════════════════════════════════════════════════════════════

class _WorkspaceUnlockView extends ConsumerStatefulWidget {
  const _WorkspaceUnlockView();

  @override
  ConsumerState<_WorkspaceUnlockView> createState() =>
      _WorkspaceUnlockViewState();
}

class _WorkspaceUnlockViewState extends ConsumerState<_WorkspaceUnlockView> {
  final _passwordController = TextEditingController();
  bool _isUnlocking = false;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _unlock() async {
    print('[WelcomePage] DEBUG: _unlock() called');
    if (_passwordController.text.isEmpty) {
      setState(() => _error = 'Please enter your master password');
      return;
    }

    setState(() {
      _isUnlocking = true;
      _error = null;
    });

    try {
      print('[WelcomePage] DEBUG: Getting workspace state...');
      final workspaceState = ref.read(workspaceProvider).valueOrNull;
      if (workspaceState?.rootPath == null) {
        throw Exception('No workspace configured');
      }
      print('[WelcomePage] DEBUG: Workspace path: ${workspaceState!.rootPath}');

      final password = SecureBytes.fromList(
        utf8.encode(_passwordController.text),
      );
      print(
        '[WelcomePage] DEBUG: Password created, calling unlockWorkspace...',
      );

      final workspaceService = ref.read(workspaceServiceProvider);
      final unlockedWorkspace = await workspaceService.unlockWorkspace(
        rootPath: workspaceState.rootPath!,
        masterPassword: password,
      );
      print('[WelcomePage] DEBUG: unlockWorkspace() succeeded!');

      // Store unlocked workspace in provider
      print('[WelcomePage] DEBUG: Updating unlockedWorkspaceProvider...');
      ref.read(unlockedWorkspaceProvider.notifier).unlock(unlockedWorkspace);
      print('[WelcomePage] DEBUG: Provider updated!');

      // Check if provider state is set
      final updatedState = ref.read(unlockedWorkspaceProvider);
      print(
        '[WelcomePage] DEBUG: Provider state after unlock: ${updatedState != null ? "UNLOCKED" : "STILL LOCKED"}',
      );

      // Clear password field
      _passwordController.clear();

      // Reset unlocking state on success - this will trigger a rebuild
      // which should cause the router to redirect to /home
      if (mounted) {
        setState(() {
          _isUnlocking = false;
        });
      }
      print('[WelcomePage] DEBUG: _unlock() completed successfully');
    } catch (e) {
      print('[WelcomePage] DEBUG: _unlock() error: $e');
      setState(() {
        _error =
            e.toString().contains('password') ||
                e.toString().contains('decrypt')
            ? 'Incorrect password'
            : 'Failed to unlock workspace: ${e.toString()}';
        _isUnlocking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 600;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isWide ? 48 : 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo
                  _buildLogo(theme),
                  const SizedBox(height: 48),

                  // Unlock prompt
                  Text(
                    'Unlock Workspace',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your master password to access all vaults',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Password field
                  PasswordField(
                    key: FyndoKeys.inputMasterPassword,
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

                  // Unlock button
                  FilledButton(
                    key: FyndoKeys.btnUnlockWorkspace,
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
        // Enhanced infographic similar to vault card
        Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
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
              // Central lock icon with glow effect
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(
                        alpha: 0.5,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.lock,
                      size: 48,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      'LOCKED',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
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

// ═══════════════════════════════════════════════════════════════════════════
// View: Unlocked Workspace (Show all vaults, no individual unlock needed)
// ═══════════════════════════════════════════════════════════════════════════

class _UnlockedWorkspaceView extends ConsumerWidget {
  const _UnlockedWorkspaceView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Vaults'),
        actions: [
          IconButton(
            key: FyndoKeys.btnLockWorkspace,
            icon: const Icon(Icons.lock),
            tooltip: 'Lock Workspace',
            onPressed: () {
              ref.read(unlockedWorkspaceProvider.notifier).lock();
            },
          ),
          IconButton(
            key: const Key('nav_settings'),
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
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
                  // Workspace info
                  const _WorkspaceInfoSection(),
                  const SizedBox(height: 24),

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
}

class _WorkspaceInfoSection extends ConsumerWidget {
  const _WorkspaceInfoSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final workspaceAsync = ref.watch(workspaceProvider);

    return workspaceAsync.when(
      data: (workspaceState) {
        if (!workspaceState.hasWorkspace) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.3,
            ),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Row(
            children: [
              Icon(
                Icons.folder_open,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Workspace',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      workspaceState.rootPath ?? '',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                onSelected: (value) =>
                    _handleWorkspaceAction(context, ref, value),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'switch',
                    child: ListTile(
                      leading: Icon(Icons.swap_horiz),
                      title: Text('Switch Workspace'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'info',
                    child: ListTile(
                      leading: Icon(Icons.info_outline),
                      title: Text('Workspace Info'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stackTrace) => const SizedBox.shrink(),
    );
  }

  void _handleWorkspaceAction(
    BuildContext context,
    WidgetRef ref,
    String action,
  ) {
    switch (action) {
      case 'switch':
        _showWorkspaceSwitcherDialog(context, ref);
        break;
      case 'info':
        _showWorkspaceInfoDialog(context, ref);
        break;
    }
  }

  void _showWorkspaceSwitcherDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => const _WorkspaceSwitcherDialog(),
    );
  }

  void _showWorkspaceInfoDialog(BuildContext context, WidgetRef ref) {
    final workspaceState = ref.read(workspaceProvider).valueOrNull;
    if (workspaceState == null) return;

    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline),
            SizedBox(width: 12),
            Text('Workspace Information'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Path:', style: theme.textTheme.labelSmall),
            const SizedBox(height: 4),
            Text(
              workspaceState.rootPath ?? '',
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 16),
            Text('Vaults:', style: theme.textTheme.labelSmall),
            const SizedBox(height: 4),
            Text(
              '${workspaceState.discoveredVaults?.length ?? 0} vault(s) found',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _WorkspaceSwitcherDialog extends ConsumerStatefulWidget {
  const _WorkspaceSwitcherDialog();

  @override
  ConsumerState<_WorkspaceSwitcherDialog> createState() =>
      _WorkspaceSwitcherDialogState();
}

class _WorkspaceSwitcherDialogState
    extends ConsumerState<_WorkspaceSwitcherDialog> {
  bool _isSwitching = false;
  String? _error;

  Future<void> _switchToWorkspace(String path) async {
    setState(() {
      _isSwitching = true;
      _error = null;
    });

    try {
      await ref.read(workspaceProvider.notifier).switchWorkspace(path);

      // Reload vaults from new workspace
      final workspaceState = ref.read(workspaceProvider).valueOrNull;
      if (workspaceState?.discoveredVaults != null) {
        await ref
            .read(vaultRegistryProvider.notifier)
            .loadFromWorkspace(
              workspaceState!.rootPath!,
              workspaceState.discoveredVaults!.toList(),
            );
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isSwitching = false;
      });
    }
  }

  Future<void> _pickNewWorkspace() async {
    final path = await ref
        .read(workspaceProvider.notifier)
        .pickWorkspaceFolder();
    if (path != null) {
      await _switchToWorkspace(path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final workspaceState = ref.watch(workspaceProvider).valueOrNull;
    final recentWorkspaces =
        workspaceState?.config?.recentWorkspaces.toList() ?? [];

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(FyndoTheme.paddingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.swap_horiz, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Switch Workspace',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer.withValues(
                    alpha: 0.3,
                  ),
                  border: Border.all(color: theme.colorScheme.error),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: theme.colorScheme.error, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _error!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Recent workspaces
            if (recentWorkspaces.isNotEmpty) ...[
              Text(
                'Recent Workspaces',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ...recentWorkspaces.take(5).map((path) {
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isSwitching ? null : () => _switchToWorkspace(path),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.folder,
                            size: 20,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              path,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontFamily: 'monospace',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward,
                            size: 16,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
            ],

            // Browse button
            OutlinedButton.icon(
              icon: const Icon(Icons.folder_open),
              label: const Text('Browse for Workspace'),
              onPressed: _isSwitching ? null : _pickNewWorkspace,
            ),

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isSwitching ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ],
        ),
      ),
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
                  key: FyndoKeys.btnVaultCreate,
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
            key: FyndoKeys.btnVaultCreateEmpty,
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
    // TODO: Implement vault creation with workspace keyring
    // This should:
    // 1. Show dialog for vault name/description/icon/color
    // 2. Generate random vault key
    // 3. Add to workspace keyring
    // 4. Call vaultService.createVault(vaultKey, ...)

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Vault creation not yet implemented - need VaultCreateDialog update',
        ),
      ),
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
        key: FyndoKeys.vaultItem(vault.id),
        onTap: () => _openVault(context, ref),
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
                  Icons.lock_open,
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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.arrow_forward,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) =>
                        _handleMenuAction(context, ref, value),
                    itemBuilder: (context) => [
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
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openVault(BuildContext context, WidgetRef ref) async {
    // TODO: Implement vault opening with keyring
    // This should:
    // 1. Get vault key from unlocked workspace keyring
    // 2. Call vaultService.unlockVault(vaultPath, vaultKey)
    // 3. Navigate to /home

    // For now, show message that this is not yet implemented
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Vault opening not yet implemented - need VaultService integration',
          ),
        ),
      );
    }
  }

  void _handleMenuAction(BuildContext context, WidgetRef ref, String action) {
    switch (action) {
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

// ═══════════════════════════════════════════════════════════════════════════
// Custom Painter for Encryption Pattern
// ═══════════════════════════════════════════════════════════════════════════

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
    final spacing = 16.0;

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
