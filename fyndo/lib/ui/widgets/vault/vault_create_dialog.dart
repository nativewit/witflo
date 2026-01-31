// ═══════════════════════════════════════════════════════════════════════════
// FYNDO - Zero-Trust Notes OS
// Vault Create Dialog - Create New Vault Form (spec-002 workspace master password)
// ═══════════════════════════════════════════════════════════════════════════
//
// CHANGES IN SPEC-002:
// - Removed password fields (vault keys are random, not password-derived)
// - Vault key is generated randomly and stored in workspace keyring
// - Only metadata is collected: name, description, icon, color
//
// Spec: docs/specs/spec-002-workspace-master-password.md (Section 3.3)
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:fyndo_app/core/agentic/fyndo_keys.dart';
import 'package:fyndo_app/ui/theme/fyndo_theme.dart';

/// Dialog for creating a new vault.
///
/// This dialog collects vault metadata (name, description, icon, color).
/// The vault key is generated randomly by the caller, not derived from a password.
class VaultCreateDialog extends StatefulWidget {
  /// Callback when vault is created with name, description, icon, and color.
  final void Function({
    required String name,
    String? description,
    String? icon,
    String? color,
  })?
  onCreateVault;

  const VaultCreateDialog({super.key, this.onCreateVault});

  /// Shows the create vault dialog.
  static Future<void> show(
    BuildContext context, {
    void Function({
      required String name,
      String? description,
      String? icon,
      String? color,
    })?
    onCreateVault,
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
  final _descriptionController = TextEditingController();
  bool _isCreating = false;

  // TODO: Add icon and color pickers in future iterations
  String? _selectedIcon;
  String? _selectedColor;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _createVault() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreating = true);

    widget.onCreateVault?.call(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      icon: _selectedIcon,
      color: _selectedColor,
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
                        'Your vault will be encrypted with a random key stored '
                        'in your workspace keyring. No password required!',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                key: FyndoKeys.inputVaultNameCreate,
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Vault Name',
                  hintText: 'My Personal Vault',
                  prefixIcon: Icon(Icons.folder),
                ),
                textInputAction: TextInputAction.next,
                autofocus: true,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a vault name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: FyndoKeys.inputVaultDescription,
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'Personal notes and documents',
                  prefixIcon: Icon(Icons.description),
                ),
                textInputAction: TextInputAction.done,
                maxLines: 2,
                onFieldSubmitted: (_) => _createVault(),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    key: FyndoKeys.btnVaultCancel,
                    onPressed: _isCreating
                        ? null
                        : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    key: FyndoKeys.btnVaultCreateConfirm,
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
