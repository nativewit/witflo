// ═══════════════════════════════════════════════════════════════════════════
// FYNDO - Zero-Trust Notes OS
// Vault Unlock Dialog - Unlock Vault with Password
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:fyndo_app/ui/theme/fyndo_theme.dart';
import 'package:fyndo_app/ui/widgets/common/password_field.dart';

/// Dialog for unlocking a vault.
class VaultUnlockDialog extends StatefulWidget {
  /// Vault name.
  final String vaultName;

  /// Callback when password is submitted.
  final void Function(String password)? onUnlock;

  /// Error message to display.
  final String? errorMessage;

  const VaultUnlockDialog({
    super.key,
    required this.vaultName,
    this.onUnlock,
    this.errorMessage,
  });

  /// Shows the unlock vault dialog.
  static Future<void> show(
    BuildContext context, {
    required String vaultName,
    void Function(String password)? onUnlock,
    String? errorMessage,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => VaultUnlockDialog(
        vaultName: vaultName,
        onUnlock: onUnlock,
        errorMessage: errorMessage,
      ),
    );
  }

  @override
  State<VaultUnlockDialog> createState() => _VaultUnlockDialogState();
}

class _VaultUnlockDialogState extends State<VaultUnlockDialog> {
  final _passwordController = TextEditingController();
  bool _isUnlocking = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _error = widget.errorMessage;
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _unlock() {
    if (_passwordController.text.isEmpty) {
      setState(() => _error = 'Please enter your password');
      return;
    }

    setState(() {
      _isUnlocking = true;
      _error = null;
    });

    widget.onUnlock?.call(_passwordController.text);
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
                        widget.vaultName,
                        style: theme.textTheme.bodyMedium?.copyWith(
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
                FilledButton.icon(
                  onPressed: _isUnlocking ? null : _unlock,
                  icon: _isUnlocking
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.lock_open, size: 18),
                  label: const Text('Unlock'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
