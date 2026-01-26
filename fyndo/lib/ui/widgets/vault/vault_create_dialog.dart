// ═══════════════════════════════════════════════════════════════════════════
// FYNDO - Zero-Trust Notes OS
// Vault Create Dialog - Create New Vault Form
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:fyndo_app/ui/theme/fyndo_theme.dart';
import 'package:fyndo_app/ui/widgets/common/password_field.dart';

/// Dialog for creating a new vault.
class VaultCreateDialog extends StatefulWidget {
  /// Callback when vault is created.
  final void Function(String name, String password)? onCreateVault;

  const VaultCreateDialog({super.key, this.onCreateVault});

  /// Shows the create vault dialog.
  static Future<void> show(
    BuildContext context, {
    void Function(String name, String password)? onCreateVault,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => VaultCreateDialog(onCreateVault: onCreateVault),
    );
  }

  @override
  State<VaultCreateDialog> createState() => _VaultCreateDialogState();
}

class _VaultCreateDialogState extends State<VaultCreateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
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

  void _createVault() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreating = true);

    widget.onCreateVault?.call(
      _nameController.text.trim(),
      _passwordController.text,
    );

    Navigator.of(context).pop();
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
                        'Your vault will be encrypted with a master password. '
                        'This password is NEVER stored anywhere.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Vault Name',
                  hintText: 'My Personal Vault',
                  prefixIcon: Icon(Icons.folder),
                ),
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a vault name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              PasswordField(
                controller: _passwordController,
                labelText: 'Master Password',
                hintText: 'Enter a strong password',
                textInputAction: TextInputAction.next,
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
                        : const Text('Create Vault'),
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
