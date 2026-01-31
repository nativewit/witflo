// ═══════════════════════════════════════════════════════════════════════════
// FYNDO - Zero-Trust Notes OS
// Notebook Create Dialog - Create New Notebook Form
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:fyndo_app/core/agentic/fyndo_keys.dart';
import 'package:fyndo_app/ui/theme/fyndo_colors.dart';
import 'package:fyndo_app/ui/theme/fyndo_theme.dart';

/// Dialog for creating a new notebook.
class NotebookCreateDialog extends StatefulWidget {
  /// Callback when notebook is created.
  final void Function(
    String name,
    String? description,
    String? color,
    String? icon,
  )?
  onCreate;

  const NotebookCreateDialog({super.key, this.onCreate});

  /// Shows the create notebook dialog.
  static Future<void> show(
    BuildContext context, {
    void Function(
      String name,
      String? description,
      String? color,
      String? icon,
    )?
    onCreate,
  }) {
    return showDialog(
      context: context,
      builder: (context) => NotebookCreateDialog(onCreate: onCreate),
    );
  }

  @override
  State<NotebookCreateDialog> createState() => _NotebookCreateDialogState();
}

class _NotebookCreateDialogState extends State<NotebookCreateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedColor;
  String? _selectedIcon;

  static const _colors = [
    '000000', // Black
    '424242', // Dark Gray
    'B71C1C', // Red
    'E65100', // Orange
    '1565C0', // Blue
    '2E7D32', // Green
    '6A1B9A', // Purple
    '00695C', // Teal
  ];

  static const _icons = [
    ('book', Icons.book),
    ('work', Icons.work),
    ('personal', Icons.person),
    ('ideas', Icons.lightbulb),
    ('journal', Icons.auto_stories),
    ('finance', Icons.attach_money),
    ('health', Icons.favorite),
    ('travel', Icons.flight),
    ('education', Icons.school),
    ('project', Icons.folder_special),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _create() {
    if (!_formKey.currentState!.validate()) return;

    widget.onCreate?.call(
      _nameController.text.trim(),
      _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      _selectedColor,
      _selectedIcon,
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
                  Icon(Icons.book, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Text('Create Notebook', style: theme.textTheme.titleLarge),
                ],
              ),
              const SizedBox(height: 24),
              TextFormField(
                key: FyndoKeys.inputNotebookName,
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Notebook Name',
                  hintText: 'My Notebook',
                  prefixIcon: Icon(Icons.edit),
                ),
                textInputAction: TextInputAction.next,
                autofocus: true,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a notebook name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: FyndoKeys.inputNotebookDescription,
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'What is this notebook for?',
                  prefixIcon: Icon(Icons.description),
                ),
                textInputAction: TextInputAction.next,
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Text('Color', style: theme.textTheme.labelMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _colors.map((color) {
                  final isSelected = _selectedColor == color;
                  return InkWell(
                    onTap: () => setState(() => _selectedColor = color),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Color(int.parse('0xFF$color')),
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? Icon(
                              Icons.check,
                              size: 16,
                              color: color == '000000' || color == '424242'
                                  ? FyndoColors.white
                                  : FyndoColors.white,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Text('Icon', style: theme.textTheme.labelMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _icons.map((iconData) {
                  final isSelected = _selectedIcon == iconData.$1;
                  return InkWell(
                    onTap: () => setState(() => _selectedIcon = iconData.$1),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primary.withValues(alpha: 0.1)
                            : null,
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.dividerColor,
                        ),
                      ),
                      child: Icon(
                        iconData.$2,
                        size: 20,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    key: FyndoKeys.btnNotebookCancel,
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    key: FyndoKeys.btnNotebookCreateConfirm,
                    onPressed: _create,
                    child: const Text('Create'),
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
