// ═══════════════════════════════════════════════════════════════════════════
// FYNDO - Zero-Trust Notes OS
// Onboarding Wizard - 3-step guided setup for new users
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fyndo_app/core/agentic/fyndo_keys.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fyndo_app/core/crypto/crypto.dart';
import 'package:fyndo_app/core/workspace/workspace_config.dart';
import 'package:fyndo_app/core/workspace/workspace_service.dart';
import 'package:fyndo_app/providers/crypto_providers.dart';
import 'package:fyndo_app/providers/unlocked_workspace_provider.dart';
import 'package:fyndo_app/providers/vault_providers.dart';
import 'package:fyndo_app/providers/vault_registry.dart';
import 'package:fyndo_app/providers/workspace_provider.dart';
import 'package:fyndo_app/ui/theme/fyndo_theme.dart';
import 'package:fyndo_app/ui/widgets/common/password_field.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

/// Onboarding wizard for new users.
///
/// 3-step flow:
/// 1. Select workspace folder (desktop) or auto-select (mobile)
/// 2. Create master password
/// 3. Create first vault
///
/// Spec: docs/specs/spec-001-workspace-management.md (Section 5.1)
class OnboardingWizard extends ConsumerStatefulWidget {
  const OnboardingWizard({super.key});

  @override
  ConsumerState<OnboardingWizard> createState() => _OnboardingWizardState();
}

class _OnboardingWizardState extends ConsumerState<OnboardingWizard> {
  int _currentStep = 0;
  String? _selectedWorkspacePath;
  String _password = '';
  String _vaultName = 'My Vault';
  bool _isProcessing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Check if there's already a workspace config from workspace switching
    // If so, pre-fill the path so user doesn't have to select it again
    Future.microtask(() {
      final workspaceState = ref.read(workspaceProvider).valueOrNull;
      if (workspaceState?.config != null &&
          workspaceState?.isInitialized == false &&
          mounted) {
        setState(() {
          _selectedWorkspacePath = workspaceState!.config!.rootPath;
        });
      }
    });
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
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  _buildHeader(theme),
                  const SizedBox(height: 48),

                  // Stepper
                  _buildStepper(theme),

                  const SizedBox(height: 32),

                  // Error message
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
                    const SizedBox(height: 24),
                  ],

                  // Navigation buttons
                  _buildNavigationButtons(theme),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.primary, width: 2),
          ),
          child: Icon(
            Icons.rocket_launch,
            size: 32,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Welcome to Fyndo',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Let\'s set up your encrypted workspace',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStepper(ThemeData theme) {
    return Column(
      children: [
        // Step indicator
        Row(
          children: [
            for (int i = 0; i < 3; i++) ...[
              Expanded(child: _buildStepIndicator(i, theme)),
              if (i < 2)
                Container(
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  color: i < _currentStep
                      ? theme.colorScheme.primary
                      : theme.dividerColor,
                ),
            ],
          ],
        ),
        const SizedBox(height: 32),

        // Step content
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildStepContent(theme),
        ),
      ],
    );
  }

  Widget _buildStepIndicator(int step, ThemeData theme) {
    final isComplete = step < _currentStep;
    final isCurrent = step == _currentStep;

    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isComplete || isCurrent
                ? theme.colorScheme.primary
                : theme.colorScheme.surfaceContainerHighest,
            border: Border.all(
              color: theme.colorScheme.primary,
              width: isCurrent ? 2 : 1,
            ),
          ),
          child: Center(
            child: isComplete
                ? Icon(
                    Icons.check,
                    color: theme.colorScheme.onPrimary,
                    size: 20,
                  )
                : Text(
                    '${step + 1}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: isCurrent
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _getStepLabel(step),
          style: theme.textTheme.bodySmall?.copyWith(
            color: isCurrent
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _getStepLabel(int step) {
    switch (step) {
      case 0:
        return 'Workspace';
      case 1:
        return 'Password';
      case 2:
        return 'Vault';
      default:
        return '';
    }
  }

  Widget _buildStepContent(ThemeData theme) {
    switch (_currentStep) {
      case 0:
        return _Step1WorkspaceSelection(
          key: const ValueKey(0),
          selectedPath: _selectedWorkspacePath,
          onPathSelected: (path) {
            setState(() {
              _selectedWorkspacePath = path;
              _error = null;
            });
          },
        );
      case 1:
        return _Step2PasswordCreation(
          key: const ValueKey(1),
          password: _password,
          onPasswordChanged: (password) {
            setState(() {
              _password = password;
              _error = null;
            });
          },
        );
      case 2:
        return _Step3VaultCreation(
          key: const ValueKey(2),
          vaultName: _vaultName,
          onVaultNameChanged: (name) {
            setState(() {
              _vaultName = name;
              _error = null;
            });
          },
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildNavigationButtons(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (_currentStep > 0)
          TextButton.icon(
            key: AppKeys.btnOnboardingBack,
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back'),
            onPressed: _isProcessing
                ? null
                : () {
                    setState(() {
                      _currentStep--;
                      _error = null;
                    });
                  },
          )
        else
          const SizedBox.shrink(),
        FilledButton.icon(
          key: AppKeys.btnOnboardingNext,
          icon: Icon(_currentStep == 2 ? Icons.check : Icons.arrow_forward),
          label: Text(_currentStep == 2 ? 'Finish' : 'Next'),
          onPressed: _isProcessing ? null : _handleNext,
        ),
      ],
    );
  }

  Future<void> _handleNext() async {
    if (_currentStep == 0) {
      await _validateStep1();
    } else if (_currentStep == 1) {
      _validateStep2();
    } else if (_currentStep == 2) {
      await _completeOnboarding();
    }
  }

  Future<void> _validateStep1() async {
    if (_selectedWorkspacePath == null || _selectedWorkspacePath!.isEmpty) {
      setState(() => _error = 'Please select a workspace folder');
      return;
    }

    // Check if the selected folder is already an initialized workspace
    final workspaceService = WorkspaceService();
    final isInitialized = await workspaceService.isValidWorkspace(
      _selectedWorkspacePath!,
    );

    if (isInitialized && mounted) {
      // This folder is already a workspace - switch to it and go to unlock screen
      try {
        await ref
            .read(workspaceProvider.notifier)
            .switchWorkspace(_selectedWorkspacePath!);

        if (mounted) {
          // Navigate to welcome page which will show the unlock screen
          context.go('/');
        }
      } catch (e) {
        setState(() => _error = 'Failed to switch to workspace: $e');
      }
      return;
    }

    // Not initialized - continue with onboarding to create new workspace
    setState(() {
      _currentStep = 1;
      _error = null;
    });
  }

  void _validateStep2() {
    if (_password.isEmpty) {
      setState(() => _error = 'Please enter a password');
      return;
    }

    if (_password.length < 8) {
      setState(() => _error = 'Password must be at least 8 characters');
      return;
    }

    // Move to next step
    setState(() {
      _currentStep = 2;
      _error = null;
    });
  }

  Future<void> _completeOnboarding() async {
    if (_vaultName.isEmpty) {
      setState(() => _error = 'Please enter a vault name');
      return;
    }

    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      // Spec-002 Section 3.1: Initialize workspace with master password
      final masterPassword = SecureBytes.fromList(utf8.encode(_password));
      final workspaceService = WorkspaceService();
      final unlockedWorkspace = await workspaceService.initializeWorkspace(
        rootPath: _selectedWorkspacePath!,
        masterPassword: masterPassword,
      );

      // Spec-002 Section 3.3: Create vault with random key
      final crypto = ref.read(cryptoServiceProvider);
      final vaultKeyBytes = crypto.random.symmetricKey();
      final vaultKey = VaultKey(vaultKeyBytes);
      final vaultId = const Uuid().v4();

      // Add vault to keyring
      final vaultKeyBase64 = base64Encode(vaultKeyBytes.bytes);
      unlockedWorkspace.keyring = unlockedWorkspace.keyring.addVault(
        vaultId,
        vaultKeyBase64,
      );

      // Save updated keyring
      await workspaceService.saveKeyring(unlockedWorkspace);

      // Create vault using vault service (spec-002 compliant)
      final vaultPath = p.join(_selectedWorkspacePath!, 'vaults', vaultId);
      final vaultService = ref.read(vaultServiceProvider);
      await vaultService.createVault(
        vaultPath: vaultPath,
        vaultKey: vaultKey,
        vaultId: vaultId,
        name: _vaultName,
        description: null,
        icon: '📓',
        color: '#3B82F6',
      );

      // Register vault in registry
      await ref
          .read(vaultRegistryProvider.notifier)
          .registerVault(name: _vaultName, path: vaultPath, setAsDefault: true);

      // Save workspace config to preferences
      final workspaceConfig = WorkspaceConfig.create(
        rootPath: unlockedWorkspace.rootPath,
      );
      await workspaceService.saveWorkspaceConfig(workspaceConfig);

      // Force workspaceProvider to reload from preferences
      // This is critical - without invalidation, the router will still see
      // hasWorkspace=false and redirect back to onboarding
      ref.invalidate(workspaceProvider);

      // Wait for workspaceProvider to finish rebuilding with the new config
      // The provider's build() method is async, so we need to wait for it
      await ref.read(workspaceProvider.future);

      // Store unlocked workspace in provider (CRITICAL!)
      // Without this, the router will redirect back to unlock screen
      ref.read(unlockedWorkspaceProvider.notifier).unlock(unlockedWorkspace);

      // Navigate to home (workspace is now initialized)
      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to complete setup: ${e.toString()}';
        _isProcessing = false;
      });
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// STEP 1: WORKSPACE SELECTION
// ═══════════════════════════════════════════════════════════════════════════

class _Step1WorkspaceSelection extends ConsumerStatefulWidget {
  final String? selectedPath;
  final ValueChanged<String> onPathSelected;

  const _Step1WorkspaceSelection({
    super.key,
    required this.selectedPath,
    required this.onPathSelected,
  });

  @override
  ConsumerState<_Step1WorkspaceSelection> createState() =>
      _Step1WorkspaceSelectionState();
}

class _Step1WorkspaceSelectionState
    extends ConsumerState<_Step1WorkspaceSelection> {
  bool _isLoadingDefault = false;

  @override
  void initState() {
    super.initState();
    // Auto-select default workspace on mobile
    if (Platform.isIOS || Platform.isAndroid) {
      _selectDefaultWorkspace();
    }
  }

  Future<void> _selectDefaultWorkspace() async {
    setState(() => _isLoadingDefault = true);
    try {
      final defaultPath = await ref
          .read(workspaceProvider.notifier)
          .getDefaultWorkspaceDirectory();
      widget.onPathSelected(defaultPath);
    } catch (e) {
      // Ignore errors, user can still pick manually
    } finally {
      if (mounted) {
        setState(() => _isLoadingDefault = false);
      }
    }
  }

  Future<void> _pickWorkspaceFolder() async {
    final path = await ref
        .read(workspaceProvider.notifier)
        .pickWorkspaceFolder();
    if (path != null) {
      widget.onPathSelected(path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop =
        Platform.isMacOS || Platform.isWindows || Platform.isLinux;

    return Container(
      padding: const EdgeInsets.all(AppTheme.paddingLarge),
      decoration: BoxDecoration(border: Border.all(color: theme.dividerColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.folder, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Text(
                'Select Workspace Location',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            isDesktop
                ? 'Choose where to store your encrypted vaults. You can select '
                      'a folder synced with Dropbox, iCloud, or any cloud service.'
                : 'Your workspace will be created in the app\'s secure storage.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),

          if (_isLoadingDefault)
            const Center(child: CircularProgressIndicator())
          else if (widget.selectedPath != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(
                  alpha: 0.2,
                ),
                border: Border.all(color: theme.colorScheme.primary),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selected folder:',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.selectedPath!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (isDesktop) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                key: AppKeys.btnWorkspaceChange,
                icon: const Icon(Icons.folder_open),
                label: const Text('Choose Different Folder'),
                onPressed: _pickWorkspaceFolder,
              ),
            ],
          ] else if (isDesktop) ...[
            OutlinedButton.icon(
              key: AppKeys.btnWorkspaceChoose,
              icon: const Icon(Icons.folder_open),
              label: const Text('Choose Folder'),
              onPressed: _pickWorkspaceFolder,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              key: AppKeys.btnWorkspaceDefault,
              icon: const Icon(Icons.home),
              label: const Text('Use Default Location'),
              onPressed: _selectDefaultWorkspace,
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// STEP 2: PASSWORD CREATION
// ═══════════════════════════════════════════════════════════════════════════

class _Step2PasswordCreation extends StatefulWidget {
  final String password;
  final ValueChanged<String> onPasswordChanged;

  const _Step2PasswordCreation({
    super.key,
    required this.password,
    required this.onPasswordChanged,
  });

  @override
  State<_Step2PasswordCreation> createState() => _Step2PasswordCreationState();
}

class _Step2PasswordCreationState extends State<_Step2PasswordCreation> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _passwordController.text = widget.password;
    _passwordController.addListener(() {
      widget.onPasswordChanged(_passwordController.text);
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppTheme.paddingLarge),
      decoration: BoxDecoration(border: Border.all(color: theme.dividerColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.lock, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Text(
                'Create Master Password',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'This password unlocks your entire workspace. All vaults and notes will be encrypted with this password.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),

          // Warning
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer.withValues(alpha: 0.2),
              border: Border.all(color: theme.colorScheme.error),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.warning_amber,
                  color: theme.colorScheme.error,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'IMPORTANT: Your password is NEVER stored. If you forget it, '
                    'your data cannot be recovered. Please use a strong, memorable password.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          PasswordField(
            key: AppKeys.inputMasterPasswordCreate,
            controller: _passwordController,
            labelText: 'Master Password',
            hintText: 'Enter a strong password (min 8 characters)',
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          ConfirmPasswordField(
            key: AppKeys.inputMasterPasswordConfirm,
            controller: _confirmController,
            passwordController: _passwordController,
            labelText: 'Confirm Password',
            textInputAction: TextInputAction.done,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// STEP 3: VAULT CREATION
// ═══════════════════════════════════════════════════════════════════════════

class _Step3VaultCreation extends StatefulWidget {
  final String vaultName;
  final ValueChanged<String> onVaultNameChanged;

  const _Step3VaultCreation({
    super.key,
    required this.vaultName,
    required this.onVaultNameChanged,
  });

  @override
  State<_Step3VaultCreation> createState() => _Step3VaultCreationState();
}

class _Step3VaultCreationState extends State<_Step3VaultCreation> {
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.vaultName;
    _nameController.addListener(() {
      widget.onVaultNameChanged(_nameController.text);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppTheme.paddingLarge),
      decoration: BoxDecoration(border: Border.all(color: theme.dividerColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.folder_special, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Text(
                'Create Your First Vault',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Give your first vault a name. Your master password will unlock all vaults, '
            'so you don\'t need to enter separate passwords for each vault.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            key: AppKeys.inputVaultName,
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Vault Name',
              hintText: 'e.g., Personal, Work, Journal',
              prefixIcon: Icon(Icons.label),
            ),
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 24),

          // Info box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
              border: Border.all(color: theme.colorScheme.primary),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your vault will be encrypted with your master password. '
                    'All notes, notebooks, and attachments will be fully encrypted.',
                    style: theme.textTheme.bodySmall,
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
