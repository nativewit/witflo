// ═══════════════════════════════════════════════════════════════════════════
// FYNDO - Zero-Trust Notes OS
// Notebook Page - Notes List in Notebook
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fyndo_app/features/notes/models/note.dart';
import 'package:fyndo_app/providers/note_providers.dart';
import 'package:fyndo_app/providers/notebook_providers.dart';
import 'package:fyndo_app/ui/consumers/note_consumer.dart';
import 'package:fyndo_app/ui/consumers/notebook_consumer.dart';
import 'package:fyndo_app/ui/theme/fyndo_theme.dart';
import 'package:fyndo_app/ui/widgets/common/fyndo_app_bar.dart';
import 'package:fyndo_app/ui/widgets/common/fyndo_empty_state.dart';
import 'package:fyndo_app/ui/widgets/note/note_card.dart';
import 'package:fyndo_app/ui/widgets/note/note_share_dialog.dart';
import 'package:go_router/go_router.dart';

/// Notebook page showing notes in a notebook.
class NotebookPage extends ConsumerWidget {
  final String notebookId;

  const NotebookPage({super.key, required this.notebookId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleNotebookConsumer(
      notebookId: notebookId,
      builder: (context, notebook, _) {
        if (notebook == null) {
          return Scaffold(
            appBar: const FyndoAppBar(title: FyndoAppBarTitle('Notebook')),
            body: const FyndoEmptyState(
              icon: Icons.book,
              title: 'Notebook Not Found',
              description: 'This notebook may have been deleted.',
            ),
          );
        }

        return _NotebookPageContent(notebook: notebook);
      },
    );
  }
}

class _NotebookPageContent extends ConsumerWidget {
  final Notebook notebook;

  const _NotebookPageContent({required this.notebook});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final color = notebook.color != null
        ? Color(int.parse('0xFF${notebook.color}'))
        : theme.colorScheme.primary;

    return Scaffold(
      appBar: FyndoAppBar(
        title: Row(
          children: [
            Icon(Icons.book, color: color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    notebook.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (notebook.description != null)
                    Text(
                      notebook.description!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearch(context),
            tooltip: 'Search',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) => _handleMenuAction(context, ref, value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'share',
                child: ListTile(
                  leading: Icon(Icons.share),
                  title: Text('Share Notebook'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'rename',
                child: ListTile(
                  leading: Icon(Icons.edit),
                  title: Text('Rename'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'archive',
                child: ListTile(
                  leading: Icon(Icons.archive),
                  title: Text('Archive'),
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
          ),
        ],
      ),
      body: NotebookNotesConsumer(
        notebookId: notebook.id,
        builder: (context, notesAsync, _) {
          return notesAsync.when(
            data: (notes) => _buildNotesList(context, ref, notes),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('Error: $error')),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createNote(context, ref),
        tooltip: 'Create Note',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildNotesList(
    BuildContext context,
    WidgetRef ref,
    List<NoteMetadata> notes,
  ) {
    if (notes.isEmpty) {
      return FyndoEmptyState(
        icon: Icons.note,
        title: 'No Notes Yet',
        description: 'Create your first note in this notebook.',
        actionText: 'Create Note',
        onAction: () => _createNote(context, ref),
      );
    }

    // Separate pinned and regular notes
    final pinnedNotes = notes.where((n) => n.isPinned).toList();
    final regularNotes = notes.where((n) => !n.isPinned).toList();

    return ListView(
      padding: const EdgeInsets.all(FyndoTheme.padding),
      children: [
        if (pinnedNotes.isNotEmpty) ...[
          _SectionHeader(title: 'Pinned'),
          const SizedBox(height: 8),
          ...pinnedNotes.map(
            (note) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: NoteCard(
                title: note.title,
                preview: null,
                modifiedAt: note.modifiedAt,
                tags: note.tags,
                isPinned: note.isPinned,
                onTap: () => context.push('/note/${note.id}'),
                onLongPress: () => _showNoteOptions(context, ref, note),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (regularNotes.isNotEmpty) ...[
          if (pinnedNotes.isNotEmpty) _SectionHeader(title: 'Notes'),
          const SizedBox(height: 8),
          ...regularNotes.map(
            (note) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: NoteCard(
                title: note.title,
                preview: null,
                modifiedAt: note.modifiedAt,
                tags: note.tags,
                isPinned: note.isPinned,
                onTap: () => context.push('/note/${note.id}'),
                onLongPress: () => _showNoteOptions(context, ref, note),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _showSearch(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Search coming soon')));
  }

  void _handleMenuAction(BuildContext context, WidgetRef ref, String action) {
    switch (action) {
      case 'share':
        ShareDialog.show(
          context,
          itemName: notebook.name,
          itemType: ShareItemType.notebook,
          onGenerateLink: () async {
            return 'https://fyndo.app/share/notebook/${notebook.id}';
          },
          onShareWithUser: (email, role) {
            // TODO: Share with user
          },
        );
        break;
      case 'rename':
        _showRenameDialog(context, ref);
        break;
      case 'archive':
        ref.read(notebooksProvider.notifier).archiveNotebook(notebook.id);
        context.pop();
        break;
      case 'delete':
        _confirmDelete(context, ref);
        break;
    }
  }

  void _showRenameDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(text: notebook.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Notebook'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ref
                  .read(notebooksProvider.notifier)
                  .updateNotebook(
                    notebook.copyWith(name: controller.text.trim()),
                  );
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Notebook?'),
        content: Text(
          'Are you sure you want to delete "${notebook.name}"? '
          'All notes in this notebook will also be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(notebooksProvider.notifier).deleteNotebook(notebook.id);
              context.pop();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _createNote(BuildContext context, WidgetRef ref) async {
    try {
      final note = await ref
          .read(noteOperationsProvider.notifier)
          .createNote(title: '', content: '', notebookId: notebook.id);
      if (context.mounted) {
        context.push('/note/${note.id}');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to create note: $e')));
      }
    }
  }

  void _showNoteOptions(
    BuildContext context,
    WidgetRef ref,
    NoteMetadata note,
  ) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                note.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
              ),
              title: Text(note.isPinned ? 'Unpin' : 'Pin'),
              onTap: () {
                Navigator.pop(context);
                ref.read(noteOperationsProvider.notifier).togglePin(note.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share'),
              onTap: () {
                Navigator.pop(context);
                ShareDialog.show(
                  context,
                  itemName: note.title.isEmpty ? 'Untitled' : note.title,
                  itemType: ShareItemType.note,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.archive),
              title: const Text('Archive'),
              onTap: () {
                Navigator.pop(context);
                ref.read(noteOperationsProvider.notifier).archiveNote(note.id);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: theme.colorScheme.error),
              title: Text(
                'Move to Trash',
                style: TextStyle(color: theme.colorScheme.error),
              ),
              onTap: () {
                Navigator.pop(context);
                ref.read(noteOperationsProvider.notifier).trashNote(note.id);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        title,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
