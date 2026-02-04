// ═══════════════════════════════════════════════════════════════════════════
// WITFLO - Zero-Trust Notes OS
// Migration Wizard - v1 → v2 workspace upgrade flow
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:witflo_app/core/crypto/crypto.dart';
import 'package:witflo_app/core/workspace/workspace_migration_service.dart';
import 'package:witflo_app/ui/widgets/common/password_field.dart';
import 'package:go_router/go_router.dart';

/// Migration wizard for upgrading v1 workspaces to v2.
///
/// Flow:
/// 1. Welcome screen explaining the upgrade
/// 2. New master password creation
/// 3. Collect old passwords for each vault
/// 4. Migration progress
/// 5. Success screen
///
/// Spec: docs/specs/spec-002-workspace-master-password.md (Section 4)
class MigrationWizard extends ConsumerStatefulWidget {
  final String workspacePath;

  const MigrationWizard({required this.workspacePath, super.key});

  @override
  ConsumerState<MigrationWizard> createState() => _MigrationWizardState();
}

class _MigrationWizardState extends ConsumerState<MigrationWizard> {
  int _currentStep = 0;
  String _newMasterPassword = '';
  String _confirmPassword = '';
  final Map<String, String> _vaultPasswords = {};
  List<String> _vaultIds = [];
  bool _isProcessing = false;
  String? _error;
  double _migrationProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _discoverVaults();
  }

  Future<void> _discoverVaults() async {
    try {
      final migrationService = WorkspaceMigrationService();
      final vaultPaths = await migrationService.discoverV1Vaults(
        widget.workspacePath,
      );

      setState(() {
        _vaultIds = vaultPaths.map((path) {
          // Extract vault ID from path (last component)
          return path.split('/').last;
        }).toList();
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to discover vaults: $e';
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

                  // Step content
                  _buildStepContent(theme),

                  const SizedBox(height: 32),

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
        Icon(Icons.upgrade, size: 64, color: theme.colorScheme.primary),
        const SizedBox(height: 16),
        Text(
          'Workspace Upgrade',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Upgrade to master password for easier access',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStepper(ThemeData theme) {
    final steps = ['Welcome', 'Master Password', 'Vault Passwords', 'Complete'];

    return Row(
      children: List.generate(steps.length * 2 - 1, (index) {
        if (index.isOdd) {
          // Connector
          return Expanded(
            child: Container(
              height: 2,
              color: index ~/ 2 < _currentStep
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surfaceContainerHighest,
            ),
          );
        }

        final stepIndex = index ~/ 2;
        final isActive = stepIndex == _currentStep;
        final isComplete = stepIndex < _currentStep;

        return Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isComplete || isActive
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHighest,
              ),
              child: Center(
                child: isComplete
                    ? Icon(
                        Icons.check,
                        size: 18,
                        color: theme.colorScheme.onPrimary,
                      )
                    : Text(
                        '${stepIndex + 1}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: isActive
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              steps[stepIndex],
              style: theme.textTheme.labelSmall?.copyWith(
                color: isActive
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildStepContent(ThemeData theme) {
    switch (_currentStep) {
      case 0:
        return _buildWelcomeStep(theme);
      case 1:
        return _buildMasterPasswordStep(theme);
      case 2:
        return _buildVaultPasswordsStep(theme);
      case 3:
        return _buildCompleteStep(theme);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildWelcomeStep(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'What\'s changing?',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              theme,
              Icons.lock,
              'One password to unlock all vaults',
              'No more remembering separate passwords for each vault.',
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              theme,
              Icons.speed,
              'Faster vault access',
              'Switch between vaults without re-entering passwords.',
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              theme,
              Icons.security,
              'Same security, better UX',
              'Your vault data remains encrypted with the same strength.',
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(
                  alpha: 0.3,
                ),
                border: Border.all(color: theme.colorScheme.primary),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.backup,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'We recommend backing up your workspace before proceeding.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    ThemeData theme,
    IconData icon,
    String title,
    String description,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMasterPasswordStep(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create Master Password',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This password will unlock your entire workspace',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            PasswordField(
              labelText: 'Master Password',
              onChanged: (value) {
                setState(() {
                  _newMasterPassword = value;
                  _error = null;
                });
              },
            ),
            const SizedBox(height: 16),
            PasswordField(
              labelText: 'Confirm Password',
              onChanged: (value) {
                setState(() {
                  _confirmPassword = value;
                  _error = null;
                });
              },
            ),
            const SizedBox(height: 16),
            _buildPasswordStrengthIndicator(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordStrengthIndicator(ThemeData theme) {
    final strength = _calculatePasswordStrength(_newMasterPassword);
    final strengthLabel = ['Weak', 'Fair', 'Good', 'Strong'][strength];
    final strengthColor = [
      theme.colorScheme.error,
      Colors.orange,
      Colors.yellow,
      Colors.green,
    ][strength];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Password Strength: $strengthLabel',
          style: theme.textTheme.bodySmall?.copyWith(color: strengthColor),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: (strength + 1) / 4,
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          valueColor: AlwaysStoppedAnimation(strengthColor),
        ),
      ],
    );
  }

  int _calculatePasswordStrength(String password) {
    if (password.length < 8) return 0;
    if (password.length < 12) return 1;
    if (password.length < 16) return 2;
    return 3;
  }

  Widget _buildVaultPasswordsStep(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter Vault Passwords',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We need your old passwords to unlock each vault',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            if (_vaultIds.isEmpty)
              const Center(child: CircularProgressIndicator())
            else
              ..._vaultIds.map((vaultId) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vault: $vaultId',
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      PasswordField(
                        labelText: 'Password',
                        onChanged: (value) {
                          setState(() {
                            _vaultPasswords[vaultId] = value;
                            _error = null;
                          });
                        },
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildCompleteStep(ThemeData theme) {
    if (_isProcessing) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              Text(
                'Migrating workspace...',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '${(_migrationProgress * 100).toInt()}%',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.check_circle, size: 64, color: Colors.green),
            const SizedBox(height: 16),
            Text(
              'Migration Complete!',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Your workspace has been successfully upgraded to v2.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Text(
              'From now on, use your master password to unlock all vaults.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButtons(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Back button
        if (_currentStep > 0 && !_isProcessing)
          TextButton(
            onPressed: () {
              setState(() {
                _currentStep--;
                _error = null;
              });
            },
            child: const Text('Back'),
          )
        else
          const SizedBox.shrink(),

        // Next/Finish button
        if (_currentStep < 3 && !_isProcessing)
          FilledButton(
            onPressed: _canProceed() ? _handleNext : null,
            child: Text(_currentStep == 2 ? 'Start Migration' : 'Next'),
          )
        else if (!_isProcessing)
          FilledButton(
            onPressed: () {
              // Navigate to main app
              context.go('/');
            },
            child: const Text('Go to App'),
          )
        else
          const SizedBox.shrink(),
      ],
    );
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return true; // Welcome step always allows proceeding
      case 1:
        // Master password step
        return _newMasterPassword.isNotEmpty &&
            _newMasterPassword == _confirmPassword &&
            _newMasterPassword.length >= 8;
      case 2:
        // Vault passwords step
        return _vaultIds.every(
          (id) => _vaultPasswords[id]?.isNotEmpty ?? false,
        );
      default:
        return false;
    }
  }

  Future<void> _handleNext() async {
    if (_currentStep == 2) {
      // Start migration
      await _performMigration();
    } else {
      setState(() {
        _currentStep++;
        _error = null;
      });
    }
  }

  Future<void> _performMigration() async {
    setState(() {
      _isProcessing = true;
      _currentStep = 3; // Move to completion step
      _migrationProgress = 0.0;
      _error = null;
    });

    try {
      final migrationService = WorkspaceMigrationService();

      // Convert password strings to SecureBytes
      final masterPassword = SecureBytes.fromList(_newMasterPassword.codeUnits);
      final vaultPasswordsSecure = <String, SecureBytes>{};

      for (final entry in _vaultPasswords.entries) {
        vaultPasswordsSecure[entry.key] = SecureBytes.fromList(
          entry.value.codeUnits,
        );
      }

      // Perform migration
      await migrationService.migrateWorkspaceV1ToV2(
        rootPath: widget.workspacePath,
        newMasterPassword: masterPassword,
        vaultPasswords: vaultPasswordsSecure,
      );

      setState(() {
        _migrationProgress = 1.0;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Migration failed: $e';
        _isProcessing = false;
        _currentStep = 2; // Go back to vault passwords step
      });
    }
  }
}
