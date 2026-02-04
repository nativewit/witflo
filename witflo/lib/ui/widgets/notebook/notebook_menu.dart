// ═══════════════════════════════════════════════════════════════════════════
// WITFLO - Zero-Trust Notes OS
// Notebook Menu - Shared Popup Menu for Notebook Actions
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:witflo_app/features/notes/models/notebook.dart';

/// Shared popup menu for notebook actions.
class NotebookMenu extends StatelessWidget {
  /// The notebook to show actions for.
  final Notebook notebook;

  /// Callback when rename is selected.
  final VoidCallback onRename;

  /// Callback when delete is selected.
  final VoidCallback onDelete;

  /// Optional icon widget. If null, uses default three-dot icon.
  final Widget? icon;

  const NotebookMenu({
    super.key,
    required this.notebook,
    required this.onRename,
    required this.onDelete,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopupMenuButton<String>(
      icon: icon ?? const Icon(Icons.more_vert),
      onSelected: (value) {
        switch (value) {
          case 'rename':
            onRename();
            break;
          case 'delete':
            onDelete();
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'rename',
          child: ListTile(
            leading: Icon(Icons.edit),
            title: Text('Rename'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: ListTile(
            leading: Icon(Icons.delete, color: theme.colorScheme.error),
            title: Text(
              'Delete',
              style: TextStyle(color: theme.colorScheme.error),
            ),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }
}
