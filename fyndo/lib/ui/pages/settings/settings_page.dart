// ═══════════════════════════════════════════════════════════════════════════
// FYNDO - Zero-Trust Notes OS
// Settings Page - App settings and vault management
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fyndo_app/core/agentic/fyndo_keys.dart';
import 'package:fyndo_app/core/crypto/crypto.dart';
import 'package:fyndo_app/core/workspace/auto_lock_settings.dart';
import 'package:fyndo_app/providers/auto_lock_settings_provider.dart';
import 'package:fyndo_app/providers/crypto_providers.dart';
import 'package:fyndo_app/providers/unlocked_workspace_provider.dart';
import 'package:fyndo_app/providers/workspace_provider.dart';
import 'package:fyndo_app/ui/theme/fyndo_theme.dart';
import 'package:fyndo_app/ui/widgets/common/password_field.dart';

/// Settings page for app configuration and workspace management.
///
/// This page implements spec-002 workspace settings including:
/// - Change master password (workspace-level, re-encrypts keyring)
/// - Auto-lock settings (idle timeout, lock on background)
/// - Lock workspace button
///
/// Spec: docs/specs/spec-002-workspace-master-password.md (Section 3.4)
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(FyndoTheme.paddingLarge),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Security Section
                _buildSectionHeader('Security', Icons.security, theme),
                const SizedBox(height: 16),
                const _SecuritySettingsSection(),

                const SizedBox(height: 32),

                // About Section
                _buildSectionHeader('About', Icons.info_outline, theme),
                const SizedBox(height: 16),
                const _AboutSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, ThemeData theme) {
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 20),
        const SizedBox(width: 12),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }
}

class _SecuritySettingsSection extends ConsumerWidget {
  const _SecuritySettingsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final unlockedWorkspace = ref.watch(unlockedWorkspaceProvider);
    final autoLockSettings = ref.watch(autoLockSettingsProvider);
    final isUnlocked = unlockedWorkspace != null;

    return Container(
      decoration: BoxDecoration(border: Border.all(color: theme.dividerColor)),
      child: Column(
        children: [
          // Change Master Password
          _buildSettingTile(
            key: FyndoKeys.btnSettingsChangePassword,
            context: context,
            title: 'Change Master Password',
            subtitle: isUnlocked
                ? 'Update your workspace password'
                : 'Unlock workspace to change password',
            icon: Icons.key,
            enabled: isUnlocked,
            onTap: isUnlocked
                ? () => _showChangePasswordDialog(context, ref)
                : null,
            theme: theme,
          ),
          Divider(height: 1, color: theme.dividerColor),

          // Auto-Lock Duration
          _buildAutoLockDurationTile(
            key: FyndoKeys.btnAutoLockTimer,
            context: context,
            theme: theme,
            settings: autoLockSettings,
            onChanged: (duration) {
              ref.read(autoLockSettingsProvider.notifier).setDuration(duration);
            },
          ),
          Divider(height: 1, color: theme.dividerColor),

          // Lock on Background
          _buildSwitchTile(
            key: FyndoKeys.switchLockOnBackground,
            context: context,
            title: 'Lock on Background',
            subtitle: 'Automatically lock when app goes to background',
            icon: Icons.phonelink_lock,
            value: autoLockSettings.lockOnBackground,
            onChanged: (value) {
              ref
                  .read(autoLockSettingsProvider.notifier)
                  .setLockOnBackground(value);
            },
            theme: theme,
          ),
          Divider(height: 1, color: theme.dividerColor),

          // Lock Now
          _buildSettingTile(
            key: FyndoKeys.btnLockWorkspaceNow,
            context: context,
            title: 'Lock Workspace Now',
            subtitle: 'Immediately lock workspace',
            icon: Icons.lock,
            enabled: isUnlocked,
            onTap: isUnlocked
                ? () {
                    ref.read(unlockedWorkspaceProvider.notifier).lock();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Workspace locked')),
                    );
                    Navigator.of(context).pop();
                  }
                : null,
            theme: theme,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    Key? key,
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool enabled,
    VoidCallback? onTap,
    required ThemeData theme,
  }) {
    return Material(
      key: key,
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.all(FyndoTheme.padding),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: enabled
                      ? theme.colorScheme.primaryContainer.withValues(
                          alpha: 0.3,
                        )
                      : theme.colorScheme.surfaceContainerHighest,
                  border: Border.all(
                    color: enabled
                        ? theme.colorScheme.primary
                        : theme.dividerColor,
                  ),
                ),
                child: Icon(
                  icon,
                  color: enabled
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: enabled
                            ? theme.textTheme.titleSmall?.color
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (enabled)
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAutoLockDurationTile({
    Key? key,
    required BuildContext context,
    required ThemeData theme,
    required AutoLockSettings settings,
    required Function(int) onChanged,
  }) {
    final durationMinutes = settings.durationSeconds ~/ 60;
    final durationText = settings.enabled
        ? '${durationMinutes} minutes'
        : 'Disabled';

    return Material(
      key: key,
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showAutoLockDurationDialog(context, settings, onChanged),
        child: Container(
          padding: const EdgeInsets.all(FyndoTheme.padding),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(
                    alpha: 0.3,
                  ),
                  border: Border.all(color: theme.colorScheme.primary),
                ),
                child: Icon(
                  Icons.timer,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Auto-Lock Timer', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text(
                      'Lock after idle time: ${durationText}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    Key? key,
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required Function(bool) onChanged,
    required ThemeData theme,
  }) {
    return Material(
      key: key,
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(!value),
        child: Container(
          padding: const EdgeInsets.all(FyndoTheme.padding),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(
                    alpha: 0.3,
                  ),
                  border: Border.all(color: theme.colorScheme.primary),
                ),
                child: Icon(icon, color: theme.colorScheme.primary, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(value: value, onChanged: onChanged),
            ],
          ),
        ),
      ),
    );
  }

  void _showAutoLockDurationDialog(
    BuildContext context,
    AutoLockSettings settings,
    Function(int) onChanged,
  ) {
    final options = [
      (0, 'Disabled', FyndoKeys.radioAutoLockDisabled),
      (5, '5 minutes', FyndoKeys.radioAutoLock5Min),
      (15, '15 minutes', FyndoKeys.radioAutoLock15Min),
      (30, '30 minutes', FyndoKeys.radioAutoLock30Min),
      (60, '60 minutes', FyndoKeys.radioAutoLock60Min),
    ];

    showDialog(
      context: context,
      builder: (context) {
        final currentMinutes = settings.durationSeconds ~/ 60;

        return AlertDialog(
          title: const Text('Auto-Lock Timer'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: options.map((option) {
              final (minutes, label, key) = option;
              final isSelected =
                  (minutes == 0 && !settings.enabled) ||
                  (minutes == currentMinutes && settings.enabled);

              return RadioListTile<int>(
                key: key,
                title: Text(label),
                value: minutes,
                groupValue: isSelected ? minutes : -1,
                onChanged: (_) {
                  onChanged(minutes);
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              key: FyndoKeys.btnAutoLockCancel,
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showChangePasswordDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => const _ChangePasswordDialog(),
    );
  }
}

class _AboutSection extends StatelessWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(FyndoTheme.padding),
      decoration: BoxDecoration(border: Border.all(color: theme.dividerColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: theme.colorScheme.primary,
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.lock,
                  size: 24,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fyndo',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                  Text(
                    'Zero-Trust Notes OS',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Version 0.1.0', style: theme.textTheme.bodySmall),
          const SizedBox(height: 8),
          Text(
            'End-to-end encrypted notes with offline-first architecture.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChangePasswordDialog extends ConsumerStatefulWidget {
  const _ChangePasswordDialog();

  @override
  ConsumerState<_ChangePasswordDialog> createState() =>
      _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends ConsumerState<_ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isChanging = false;
  String? _error;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isChanging = true;
      _error = null;
    });

    try {
      // Get workspace state and unlocked workspace
      final workspaceState = ref.read(workspaceProvider).valueOrNull;
      final unlockedWorkspace = ref.read(unlockedWorkspaceProvider);

      if (workspaceState?.rootPath == null || unlockedWorkspace == null) {
        throw Exception('No workspace unlocked');
      }

      // Prepare passwords
      final currentPassword = SecureBytes.fromList(
        utf8.encode(_currentPasswordController.text),
      );
      final newPassword = SecureBytes.fromList(
        utf8.encode(_newPasswordController.text),
      );

      // Change password (this will verify current password internally)
      final workspaceService = ref.read(workspaceServiceProvider);
      await workspaceService.changeMasterPassword(
        workspace: unlockedWorkspace,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      // Lock the current workspace so user must unlock with new password
      ref.read(unlockedWorkspaceProvider.notifier).lock();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Password changed successfully. Please unlock with your new password.',
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error =
            e.toString().contains('password') ||
                e.toString().contains('incorrect')
            ? 'Current password is incorrect'
            : 'Failed to change password: ${e.toString()}';
        _isChanging = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 450),
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
                    Icon(Icons.key, color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Text(
                      'Change Master Password',
                      style: theme.textTheme.titleLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

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
                          'This will re-encrypt your vault with the new password. '
                          'Make sure to remember it - lost passwords cannot be recovered.',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
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
                        Icon(
                          Icons.error,
                          color: theme.colorScheme.error,
                          size: 20,
                        ),
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

                PasswordField(
                  key: FyndoKeys.inputCurrentPassword,
                  controller: _currentPasswordController,
                  labelText: 'Current Password',
                  hintText: 'Enter your current password',
                  enabled: !_isChanging,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your current password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                PasswordField(
                  key: FyndoKeys.inputNewPassword,
                  controller: _newPasswordController,
                  labelText: 'New Password',
                  hintText: 'Enter a new password',
                  enabled: !_isChanging,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a new password';
                    }
                    if (value.length < 8) {
                      return 'Password must be at least 8 characters';
                    }
                    if (value == _currentPasswordController.text) {
                      return 'New password must be different';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                ConfirmPasswordField(
                  key: FyndoKeys.inputConfirmNewPassword,
                  controller: _confirmPasswordController,
                  passwordController: _newPasswordController,
                  labelText: 'Confirm New Password',
                  enabled: !_isChanging,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      key: FyndoKeys.btnPasswordCancel,
                      onPressed: _isChanging
                          ? null
                          : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      key: FyndoKeys.btnPasswordConfirm,
                      onPressed: _isChanging ? null : _changePassword,
                      child: _isChanging
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Change Password'),
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
