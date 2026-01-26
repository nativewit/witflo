// ═══════════════════════════════════════════════════════════════════════════
// FYNDO - Zero-Trust Notes OS
// Password Field - Secure Password Input
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

/// A secure password input field with toggle visibility.
class PasswordField extends StatefulWidget {
  /// Controller for the text field.
  final TextEditingController? controller;

  /// Label text.
  final String? labelText;

  /// Hint text.
  final String? hintText;

  /// Error text.
  final String? errorText;

  /// Validation callback.
  final String? Function(String?)? validator;

  /// On changed callback.
  final ValueChanged<String>? onChanged;

  /// On submitted callback.
  final ValueChanged<String>? onSubmitted;

  /// Focus node.
  final FocusNode? focusNode;

  /// Whether to autofocus.
  final bool autofocus;

  /// Text input action.
  final TextInputAction? textInputAction;

  /// Whether field is enabled.
  final bool enabled;

  const PasswordField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.errorText,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.autofocus = false,
    this.textInputAction,
    this.enabled = true,
  });

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscureText,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      textInputAction: widget.textInputAction,
      enabled: widget.enabled,
      validator: widget.validator,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onSubmitted,
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: widget.hintText,
        errorText: widget.errorText,
        prefixIcon: const Icon(Icons.key),
        suffixIcon: IconButton(
          icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility),
          onPressed: () {
            setState(() {
              _obscureText = !_obscureText;
            });
          },
          tooltip: _obscureText ? 'Show password' : 'Hide password',
        ),
      ),
    );
  }
}

/// A confirm password field that validates against another password.
class ConfirmPasswordField extends StatefulWidget {
  /// Controller for the text field.
  final TextEditingController? controller;

  /// Controller for the password to match.
  final TextEditingController passwordController;

  /// Label text.
  final String? labelText;

  /// Error text.
  final String? errorText;

  /// On changed callback.
  final ValueChanged<String>? onChanged;

  /// On submitted callback.
  final ValueChanged<String>? onSubmitted;

  /// Focus node.
  final FocusNode? focusNode;

  /// Text input action.
  final TextInputAction? textInputAction;

  /// Whether field is enabled.
  final bool enabled;

  const ConfirmPasswordField({
    super.key,
    this.controller,
    required this.passwordController,
    this.labelText,
    this.errorText,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.textInputAction,
    this.enabled = true,
  });

  @override
  State<ConfirmPasswordField> createState() => _ConfirmPasswordFieldState();
}

class _ConfirmPasswordFieldState extends State<ConfirmPasswordField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscureText,
      focusNode: widget.focusNode,
      textInputAction: widget.textInputAction,
      enabled: widget.enabled,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onSubmitted,
      validator: (value) {
        if (value != widget.passwordController.text) {
          return 'Passwords do not match';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: widget.labelText ?? 'Confirm Password',
        errorText: widget.errorText,
        prefixIcon: const Icon(Icons.key),
        suffixIcon: IconButton(
          icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility),
          onPressed: () {
            setState(() {
              _obscureText = !_obscureText;
            });
          },
          tooltip: _obscureText ? 'Show password' : 'Hide password',
        ),
      ),
    );
  }
}
