// ═══════════════════════════════════════════════════════════════════════════
// WITFLO - Zero-Trust Notes OS
// Settings Page - App settings and workspace management
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:witflo_app/core/agentic/app_keys.dart';
import 'package:witflo_app/core/config/env.dart';
import 'package:witflo_app/core/crypto/crypto.dart';
import 'package:witflo_app/core/workspace/auto_lock_settings.dart';
import 'package:witflo_app/providers/auto_lock_settings_provider.dart';
import 'package:witflo_app/providers/crypto_providers.dart';
import 'package:witflo_app/providers/theme_provider.dart';
import 'package:witflo_app/providers/unlocked_workspace_provider.dart';
import 'package:witflo_app/providers/workspace_provider.dart';
import 'package:witflo_app/ui/theme/app_theme.dart';
import 'package:witflo_app/ui/widgets/common/app_bar.dart';
import 'package:witflo_app/ui/widgets/common/app_card.dart';
import 'package:witflo_app/ui/widgets/common/password_field.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Settings page for app configuration and workspace management.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppAppBar(title: const AppBarTitle('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.padding),
        children: [
          // Appearance Section
          Text('Appearance', style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),
          const _AppearanceSection(),
          const SizedBox(height: 24),

          // Workspace Section
          Text('Workspace', style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),
          const _WorkspaceSection(),
          const SizedBox(height: 24),

          // Sync Section (moved from vault settings)
          Row(
            children: [
              Text('Sync & Backup', style: theme.textTheme.titleMedium),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  border: Border.all(color: theme.colorScheme.primary),
                ),
                child: Text(
                  'COMING SOON',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _SyncSection(),
          const SizedBox(height: 24),

          // Security Section
          Text('Security', style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),
          const _SecuritySettingsSection(),
          const SizedBox(height: 24),

          // About Section
          Text('About', style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),
          const _AboutSection(),
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// APPEARANCE SECTION
// ═══════════════════════════════════════════════════════════════════════════

class _AppearanceSection extends ConsumerWidget {
  const _AppearanceSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeModeProvider);

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            leading: const Icon(Icons.brightness_6),
            title: const Text('Theme'),
            subtitle: Text(_getThemeModeLabel(themeMode)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showThemeDialog(context, ref, themeMode),
          ),
        ],
      ),
    );
  }

  String _getThemeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  void _showThemeDialog(
    BuildContext context,
    WidgetRef ref,
    ThemeMode currentMode,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('Light'),
              value: ThemeMode.light,
              groupValue: currentMode,
              onChanged: (mode) {
                if (mode != null) {
                  ref.read(themeModeProvider.notifier).setThemeMode(mode);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Dark'),
              value: ThemeMode.dark,
              groupValue: currentMode,
              onChanged: (mode) {
                if (mode != null) {
                  ref.read(themeModeProvider.notifier).setThemeMode(mode);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('System'),
              value: ThemeMode.system,
              groupValue: currentMode,
              onChanged: (mode) {
                if (mode != null) {
                  ref.read(themeModeProvider.notifier).setThemeMode(mode);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// WORKSPACE SECTION
// ═══════════════════════════════════════════════════════════════════════════

class _WorkspaceSection extends ConsumerWidget {
  const _WorkspaceSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final workspaceState = ref.watch(workspaceProvider).valueOrNull;
    final rootPath = workspaceState?.rootPath ?? 'Not set';

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            leading: const Icon(Icons.folder_open),
            title: const Text('Current Workspace'),
            subtitle: Text(
              rootPath,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.swap_horiz),
            title: const Text('Switch Workspace'),
            subtitle: const Text('Choose a different workspace folder'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _switchWorkspace(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _switchWorkspace(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Switch Workspace'),
        content: const Text(
          'Switching workspaces will lock the current workspace. '
          'If the new folder is empty, you will be prompted to initialize it. '
          'Make sure all your work is saved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      // Pick new workspace folder
      final selectedDir = await getDirectoryPath(
        confirmButtonText: 'Select Workspace',
      );

      if (selectedDir == null) return;

      // Lock current workspace
      ref.read(unlockedWorkspaceProvider.notifier).lock();

      // Switch workspace using the provider
      // This handles both initialized and uninitialized workspaces
      await ref.read(workspaceProvider.notifier).switchWorkspace(selectedDir);

      // Navigation will be handled by the router based on workspace state
      // If initialized: will show unlock screen
      // If uninitialized: will redirect to onboarding
      if (context.mounted) {
        context.go('/');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to switch workspace: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SYNC SECTION (moved from vault settings)
// ═══════════════════════════════════════════════════════════════════════════

class _SyncSection extends ConsumerWidget {
  const _SyncSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return AppCard(
      padding: const EdgeInsets.all(AppTheme.padding),
      child: Row(
        children: [
          Icon(
            Icons.cloud_off_outlined,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sync & Backup', style: theme.textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(
                  'Cloud sync and backup features are coming soon',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SECURITY SECTION
// ═══════════════════════════════════════════════════════════════════════════

class _SecuritySettingsSection extends ConsumerWidget {
  const _SecuritySettingsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final unlockedWorkspace = ref.watch(unlockedWorkspaceProvider);
    final autoLockSettings = ref.watch(autoLockSettingsProvider);
    final isUnlocked = unlockedWorkspace != null;

    final durationMinutes = autoLockSettings.durationSeconds ~/ 60;
    final durationText = autoLockSettings.enabled
        ? 'Lock after idle time: ${durationMinutes} minutes'
        : 'Lock after idle time: Disabled';

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Change Master Password
          ListTile(
            key: AppKeys.btnSettingsChangePassword,
            leading: const Icon(Icons.key),
            title: const Text('Change Master Password'),
            subtitle: Text(
              isUnlocked
                  ? 'Update your workspace password'
                  : 'Unlock workspace to change password',
            ),
            enabled: isUnlocked,
            trailing: isUnlocked ? const Icon(Icons.chevron_right) : null,
            onTap: isUnlocked
                ? () => _showChangePasswordDialog(context, ref)
                : null,
          ),
          const Divider(height: 1),

          // Auto-Lock Duration
          ListTile(
            key: AppKeys.btnAutoLockTimer,
            leading: const Icon(Icons.timer),
            title: const Text('Auto-Lock Timer'),
            subtitle: Text(durationText),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showAutoLockDurationDialog(
              context,
              autoLockSettings,
              (duration) {
                ref
                    .read(autoLockSettingsProvider.notifier)
                    .setDuration(duration);
              },
            ),
          ),
          const Divider(height: 1),

          // Lock on Background
          SwitchListTile(
            key: AppKeys.switchLockOnBackground,
            secondary: const Icon(Icons.phonelink_lock),
            title: const Text('Lock on Background'),
            subtitle: const Text(
              'Automatically lock when app goes to background',
            ),
            value: autoLockSettings.lockOnBackground,
            onChanged: (value) {
              ref
                  .read(autoLockSettingsProvider.notifier)
                  .setLockOnBackground(value);
            },
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => const _ChangePasswordDialog(),
    );
  }
}

void _showAutoLockDurationDialog(
  BuildContext context,
  AutoLockSettings settings,
  Function(int) onChanged,
) {
  final options = [
    (0, 'Disabled', AppKeys.radioAutoLockDisabled),
    (5, '5 minutes', AppKeys.radioAutoLock5Min),
    (15, '15 minutes', AppKeys.radioAutoLock15Min),
    (30, '30 minutes', AppKeys.radioAutoLock30Min),
    (60, '60 minutes', AppKeys.radioAutoLock60Min),
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
            key: AppKeys.btnAutoLockCancel,
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      );
    },
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// ABOUT SECTION
// ═══════════════════════════════════════════════════════════════════════════

class _AboutSection extends StatefulWidget {
  const _AboutSection();

  @override
  State<_AboutSection> createState() => _AboutSectionState();
}

class _AboutSectionState extends State<_AboutSection> {
  String _version = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadVersionInfo();
  }

  Future<void> _loadVersionInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _version =
              'Version ${packageInfo.version} (${packageInfo.buildNumber})';
        });
      }
    } catch (e) {
      // Fallback if package_info_plus is not available on platform
      if (mounted) {
        setState(() {
          _version = 'Version 0.1.0';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      padding: const EdgeInsets.all(AppTheme.padding),
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
                    AppEnvironment.instance.appName,
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
          Text(_version, style: theme.textTheme.bodySmall),
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

// ═══════════════════════════════════════════════════════════════════════════
// CHANGE PASSWORD DIALOG
// ═══════════════════════════════════════════════════════════════════════════

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
        padding: const EdgeInsets.all(AppTheme.paddingLarge),
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
                  key: AppKeys.inputCurrentPassword,
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
                  key: AppKeys.inputNewPassword,
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
                  key: AppKeys.inputConfirmNewPassword,
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
                      key: AppKeys.btnPasswordCancel,
                      onPressed: _isChanging
                          ? null
                          : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      key: AppKeys.btnPasswordConfirm,
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
