// ═══════════════════════════════════════════════════════════════════════════
// FYNDO - Zero-Trust Notes OS
// Welcome Page - Create or Unlock Vault
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fyndo_app/core/crypto/crypto.dart';
import 'package:fyndo_app/core/vault/vault_service.dart';
import 'package:fyndo_app/providers/vault_providers.dart';
import 'package:fyndo_app/ui/consumers/vault_consumer.dart';
import 'package:fyndo_app/ui/theme/fyndo_theme.dart';
import 'package:fyndo_app/ui/widgets/common/password_field.dart';
import 'package:fyndo_app/ui/widgets/common/security_badges.dart';
import 'package:go_router/go_router.dart';

/// Welcome page for vault creation or unlock.
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
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
        switch (status) {
          case VaultStatus.uninitialized:
            return const _WelcomeView(showUnlock: false);
          case VaultStatus.locked:
            return const _WelcomeView(showUnlock: true);
          case VaultStatus.unlocking:
          case VaultStatus.creating:
            return const _LoadingView();
          case VaultStatus.error:
            return const _WelcomeView(showUnlock: true);
          case VaultStatus.unlocked:
            return const _LoadingView();
        }
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

class _WelcomeView extends StatelessWidget {
  final bool showUnlock;

  const _WelcomeView({required this.showUnlock});

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
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo
                  _buildLogo(theme),
                  const SizedBox(height: 48),

                  // Form
                  if (showUnlock)
                    const _UnlockForm()
                  else
                    const _CreateVaultForm(),

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

class _UnlockForm extends ConsumerStatefulWidget {
  const _UnlockForm();

  @override
  ConsumerState<_UnlockForm> createState() => _UnlockFormState();
}

class _UnlockFormState extends ConsumerState<_UnlockForm> {
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
      final password = SecureBytes.fromList(
        utf8.encode(_passwordController.text),
      );

      await ref.read(vaultProvider.notifier).unlock(password);

      if (mounted) {
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

    return Container(
      padding: const EdgeInsets.all(FyndoTheme.paddingLarge),
      decoration: BoxDecoration(border: Border.all(color: theme.dividerColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.lock_open, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Text('Unlock Vault', style: theme.textTheme.titleLarge),
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
          const SizedBox(height: 16),
          TextButton(
            onPressed: _isUnlocking
                ? null
                : () => _showCreateVaultDialog(context),
            child: const Text('Create New Vault'),
          ),
        ],
      ),
    );
  }

  void _showCreateVaultDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _CreateVaultDialog(),
    );
  }
}

class _CreateVaultForm extends ConsumerStatefulWidget {
  const _CreateVaultForm();

  @override
  ConsumerState<_CreateVaultForm> createState() => _CreateVaultFormState();
}

class _CreateVaultFormState extends ConsumerState<_CreateVaultForm> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isCreating = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _createVault() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreating = true);

    try {
      final vaultPath = ref.read(vaultProvider).vaultPath;
      if (vaultPath == null) {
        throw StateError('Vault path not set');
      }

      final password = SecureBytes.fromList(
        utf8.encode(_passwordController.text),
      );

      await ref
          .read(vaultProvider.notifier)
          .createVault(path: vaultPath, password: password);

      // Unlock the vault after creation
      final unlockPassword = SecureBytes.fromList(
        utf8.encode(_passwordController.text),
      );
      await ref.read(vaultProvider.notifier).unlock(unlockPassword);

      if (mounted) {
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

    return Container(
      padding: const EdgeInsets.all(FyndoTheme.paddingLarge),
      decoration: BoxDecoration(border: Border.all(color: theme.dividerColor)),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.add_box, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Text('Create Your Vault', style: theme.textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(FyndoTheme.padding),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(
                  alpha: 0.2,
                ),
                border: Border.all(color: theme.colorScheme.primary),
              ),
              child: Row(
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
                      'This password is NEVER stored anywhere. If you forget it, '
                      'your data cannot be recovered.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
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
                  : const Text('Create Vault'),
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
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isCreating = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _createVault() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreating = true);

    try {
      final vaultPath = ref.read(vaultProvider).vaultPath;
      if (vaultPath == null) {
        throw StateError('Vault path not set');
      }

      final password = SecureBytes.fromList(
        utf8.encode(_passwordController.text),
      );

      await ref
          .read(vaultProvider.notifier)
          .createVault(path: vaultPath, password: password);

      // Unlock the vault after creation
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
              PasswordField(
                controller: _passwordController,
                labelText: 'Master Password',
                hintText: 'Enter a strong password',
                textInputAction: TextInputAction.next,
                enabled: !_isCreating,
                autofocus: true,
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
    );
  }
}
