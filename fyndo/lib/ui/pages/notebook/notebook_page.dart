// FYNDO - Zero-Trust Notes OS
// Notebook Page - Split View with Notes List and Editor

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fyndo_app/core/agentic/fyndo_keys.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fyndo_app/features/notes/models/note.dart';
import 'package:fyndo_app/providers/note_providers.dart';
import 'package:fyndo_app/providers/notebook_providers.dart';
import 'package:fyndo_app/ui/consumers/note_consumer.dart';
import 'package:fyndo_app/ui/consumers/notebook_consumer.dart';
import 'package:fyndo_app/ui/theme/fyndo_theme.dart';
import 'package:fyndo_app/ui/widgets/common/fyndo_app_bar.dart';
import 'package:fyndo_app/ui/widgets/common/fyndo_empty_state.dart';
import 'package:fyndo_app/ui/widgets/note/note_editor.dart';
import 'package:fyndo_app/ui/widgets/note/note_export_helper.dart';
import 'package:fyndo_app/ui/widgets/note/note_share_dialog.dart';
import 'package:intl/intl.dart';

/// Notebook page showing notes in a split view - list on left, editor on right.
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

class _NotebookPageContent extends ConsumerStatefulWidget {
  final Notebook notebook;

  const _NotebookPageContent({required this.notebook});

  @override
  ConsumerState<_NotebookPageContent> createState() =>
      _NotebookPageContentState();
}

class _NotebookPageContentState extends ConsumerState<_NotebookPageContent>
    with WidgetsBindingObserver {
  String? _selectedNoteId;
  Note? _currentNote;
  final _titleController = TextEditingController();
  // Create a new GlobalKey for each note selection to force widget rebuild
  GlobalKey<NoteEditorState>? _editorKey;
  Timer? _saveTimer;
  bool _hasChanges = false;
  bool _isSaving = false;
  DateTime? _lastSavedAt;

  Notebook get notebook => widget.notebook;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_hasChanges && !_isSaving) {
      _saveNoteSync();
    }
    _titleController.dispose();
    _saveTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (_hasChanges && !_isSaving) {
        _saveNote();
      }
    }
  }

  void _onTitleChanged(String value) {
    setState(() => _hasChanges = true);
    _debounceSave();
  }

  void _onContentChanged(String content) {
    setState(() => _hasChanges = true);
    _debounceSave();
  }

  void _debounceSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 2), _saveNote);
  }

  Future<void> _saveNote() async {
    if (_currentNote == null || !_hasChanges || _isSaving) return;

    setState(() => _isSaving = true);

    try {
      final content = _editorKey?.currentState?.getContent() ?? '';
      debugPrint('_saveNote: saving note ${_currentNote!.id}');
      debugPrint(
        '_saveNote: title="${_titleController.text}", content length=${content.length}',
      );
      debugPrint(
        '_saveNote: content preview: ${content.substring(0, content.length.clamp(0, 100))}',
      );
      final updatedNote = _currentNote!.copyWith(
        title: _titleController.text,
        content: content,
      );

      await ref.read(noteOperationsProvider.notifier).updateNote(updatedNote);

      if (mounted) {
        // Invalidate providers to refresh cached data
        ref.invalidate(notebookNotesProvider(notebook.id));
        ref.invalidate(noteProvider(updatedNote.id));
        setState(() {
          _hasChanges = false;
          _currentNote = updatedNote;
          _lastSavedAt = DateTime.now();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _saveNoteSync() {
    if (_currentNote == null || !_hasChanges) return;
    final content = _editorKey?.currentState?.getContent() ?? '';
    final updatedNote = _currentNote!.copyWith(
      title: _titleController.text,
      content: content,
    );
    ref.read(noteOperationsProvider.notifier).updateNote(updatedNote);
  }

  Future<void> _selectNote(String noteId) async {
    if (_hasChanges && !_isSaving) {
      await _saveNote();
    }

    setState(() {
      _selectedNoteId = noteId;
      _currentNote = null;
      _hasChanges = false;
      // Create new key to force NoteEditor rebuild with fresh content
      _editorKey = GlobalKey<NoteEditorState>();
    });

    // Invalidate to ensure we get fresh data from the repository
    ref.invalidate(noteProvider(noteId));
    final note = await ref.read(noteProvider(noteId).future);
    debugPrint(
      '_selectNote: loaded note ${note?.id}, content length: ${note?.content.length ?? 0}',
    );
    debugPrint(
      '_selectNote: content preview: ${note != null ? note.content.substring(0, note.content.length.clamp(0, 100)) : "null"}',
    );
    if (note != null && mounted) {
      setState(() {
        _currentNote = note;
        _titleController.text = note.title;
      });
    }
  }

  Future<void> _createNote() async {
    if (_hasChanges && !_isSaving) {
      await _saveNote();
    }

    try {
      final note = await ref
          .read(noteOperationsProvider.notifier)
          .createNote(title: '', content: '', notebookId: notebook.id);

      if (mounted) {
        setState(() {
          _selectedNoteId = note.id;
          _currentNote = note;
          _titleController.text = '';
          _hasChanges = false;
          // Create new key to force NoteEditor rebuild
          _editorKey = GlobalKey<NoteEditorState>();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to create note: $e')));
      }
    }
  }

  Future<void> _exportNoteAsMarkdown(String noteId) async {
    try {
      final note = await ref.read(noteProvider(noteId).future);
      if (note != null) {
        await NoteExportHelper.exportAsMarkdown(
          title: note.title.isEmpty ? 'Untitled' : note.title,
          content: note.content,
          tags: note.tags.toList(),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to export: $e')));
      }
    }
  }

  Future<void> _duplicateNote(String noteId) async {
    try {
      final note = await ref.read(noteProvider(noteId).future);
      if (note != null) {
        await ref
            .read(noteOperationsProvider.notifier)
            .createNote(
              title: '${note.title} (Copy)',
              content: note.content,
              notebookId: notebook.id,
              tags: note.tags.toList(),
            );
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Note duplicated')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to duplicate: $e')));
      }
    }
  }

  String _getStatusText() {
    if (_isSaving) return 'Saving...';
    if (_hasChanges) return 'Edited';
    if (_lastSavedAt != null) {
      final diff = DateTime.now().difference(_lastSavedAt!);
      if (diff.inSeconds < 5) return 'Saved just now';
      if (diff.inMinutes < 1) return 'Saved ${diff.inSeconds}s ago';
      if (diff.inMinutes < 60) return 'Saved ${diff.inMinutes}m ago';
      return 'Saved';
    }
    return 'Saved';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 600;
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
                  if (_selectedNoteId != null) ...[
                    Row(
                      children: [
                        if (_isSaving)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: SizedBox(
                              width: 10,
                              height: 10,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        if (_hasChanges && !_isSaving)
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.only(right: 4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        Text(
                          _getStatusText(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ] else if (notebook.description != null)
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
            key: FyndoKeys.btnNoteCreate,
            icon: const Icon(Icons.add),
            onPressed: _createNote,
            tooltip: 'New Note',
          ),
          PopupMenuButton<String>(
            key: FyndoKeys.menuNotebookActions,
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
      body: isWide ? _buildWideLayout(theme) : _buildNarrowLayout(theme),
    );
  }

  Widget _buildWideLayout(ThemeData theme) {
    return Row(
      children: [
        SizedBox(width: 300, child: _buildNotesList(theme)),
        Container(width: 1, color: theme.dividerColor),
        Expanded(child: _buildEditorArea(theme)),
      ],
    );
  }

  Widget _buildNarrowLayout(ThemeData theme) {
    if (_selectedNoteId == null) {
      return _buildNotesList(theme);
    } else {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: theme.dividerColor)),
            ),
            child: Row(
              children: [
                IconButton(
                  key: FyndoKeys.btnBackToNotes,
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    if (_hasChanges) _saveNote();
                    setState(() {
                      _selectedNoteId = null;
                      _currentNote = null;
                    });
                  },
                ),
                const Text('Back to notes'),
              ],
            ),
          ),
          Expanded(child: _buildEditorArea(theme)),
        ],
      );
    }
  }

  Widget _buildNotesList(ThemeData theme) {
    return NotebookNotesConsumer(
      notebookId: notebook.id,
      builder: (context, notesAsync, _) {
        return notesAsync.when(
          data: (notes) {
            if (notes.isEmpty) {
              return FyndoEmptyState(
                icon: Icons.note_outlined,
                title: 'No Notes Yet',
                description: 'Create your first note in this notebook.',
                actionText: 'Create Note',
                onAction: _createNote,
              );
            }

            final pinnedNotes = notes.where((n) => n.isPinned).toList();
            final regularNotes = notes.where((n) => !n.isPinned).toList();

            return ListView(
              key: FyndoKeys.listNotes,
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                if (pinnedNotes.isNotEmpty) ...[
                  const _SectionHeader(title: 'PINNED'),
                  ...pinnedNotes.map(
                    (note) => _NoteListItem(
                      note: note,
                      isSelected: note.id == _selectedNoteId,
                      onTap: () => _selectNote(note.id),
                      onLongPress: () => _showNoteOptions(context, ref, note),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                if (regularNotes.isNotEmpty) ...[
                  if (pinnedNotes.isNotEmpty)
                    const _SectionHeader(title: 'NOTES'),
                  ...regularNotes.map(
                    (note) => _NoteListItem(
                      note: note,
                      isSelected: note.id == _selectedNoteId,
                      onTap: () => _selectNote(note.id),
                      onLongPress: () => _showNoteOptions(context, ref, note),
                    ),
                  ),
                ],
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Error: $error')),
        );
      },
    );
  }

  Widget _buildEditorArea(ThemeData theme) {
    if (_selectedNoteId == null) {
      return FyndoEmptyState(
        icon: Icons.edit_note,
        title: 'Select a Note',
        description: 'Choose a note from the list to start editing.',
        actionText: 'Create Note',
        onAction: _createNote,
      );
    }

    if (_currentNote == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Use pure white for light theme, pure black for dark theme
    final editorBackground = theme.brightness == Brightness.light
        ? Colors.white
        : Colors.black;

    return Container(
      decoration: BoxDecoration(
        color: editorBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Note actions toolbar
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: FyndoTheme.paddingSmall,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: theme.dividerColor.withValues(alpha: 0.3),
                ),
              ),
            ),
            child: Row(
              children: [
                // Status indicator
                Text(
                  _getStatusText(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: _hasChanges
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                // Pin button
                IconButton(
                  key: FyndoKeys.btnNotePin,
                  icon: Icon(
                    _currentNote!.isPinned
                        ? Icons.push_pin
                        : Icons.push_pin_outlined,
                    size: 20,
                  ),
                  onPressed: () => ref
                      .read(noteOperationsProvider.notifier)
                      .togglePin(_currentNote!.id),
                  tooltip: _currentNote!.isPinned ? 'Unpin note' : 'Pin note',
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 4),
                // More options menu
                PopupMenuButton<String>(
                  key: FyndoKeys.menuNoteActions,
                  icon: const Icon(Icons.more_vert, size: 20),
                  padding: const EdgeInsets.all(8),
                  onSelected: (value) => _handleNoteMenuAction(context, value),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'share',
                      child: ListTile(
                        leading: Icon(Icons.share),
                        title: Text('Share'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'export',
                      child: ListTile(
                        leading: Icon(Icons.download),
                        title: Text('Export as Markdown'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'duplicate',
                      child: ListTile(
                        leading: Icon(Icons.copy),
                        title: Text('Duplicate'),
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
                        leading: Icon(
                          Icons.delete,
                          color: theme.colorScheme.error,
                        ),
                        title: Text(
                          'Move to Trash',
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              FyndoTheme.padding,
              FyndoTheme.padding,
              FyndoTheme.padding,
              FyndoTheme.paddingSmall,
            ),
            child: TextField(
              controller: _titleController,
              onChanged: _onTitleChanged,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              decoration: const InputDecoration(
                hintText: 'Untitled',
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              maxLines: 1,
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(
              horizontal: FyndoTheme.padding,
              vertical: FyndoTheme.paddingSmall,
            ),
            height: 1,
            color: theme.dividerColor.withValues(alpha: 0.5),
          ),
          Expanded(
            child: NoteEditor(
              key: _editorKey,
              initialContent: _currentNote!.content,
              onContentChanged: _onContentChanged,
              autofocus: _currentNote!.title.isEmpty,
              placeholder: 'Start writing...',
            ),
          ),
        ],
      ),
    );
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
          onShareWithUser: (email, role) {},
        );
        break;
      case 'rename':
        _showRenameDialog(context, ref);
        break;
      case 'delete':
        _confirmDelete(context, ref);
        break;
    }
  }

  void _handleNoteMenuAction(BuildContext context, String action) {
    if (_currentNote == null) return;

    switch (action) {
      case 'share':
        ShareDialog.show(
          context,
          itemName: _currentNote!.title.isEmpty
              ? 'Untitled'
              : _currentNote!.title,
          itemType: ShareItemType.note,
        );
        break;
      case 'export':
        _exportNoteAsMarkdown(_currentNote!.id);
        break;
      case 'duplicate':
        _duplicateNote(_currentNote!.id);
        break;
      case 'archive':
        ref.read(noteOperationsProvider.notifier).archiveNote(_currentNote!.id);
        setState(() {
          _selectedNoteId = null;
          _currentNote = null;
        });
        break;
      case 'delete':
        ref.read(noteOperationsProvider.notifier).trashNote(_currentNote!.id);
        setState(() {
          _selectedNoteId = null;
          _currentNote = null;
        });
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
              Navigator.of(context).pop();
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
              leading: const Icon(Icons.download),
              title: const Text('Export as Markdown'),
              onTap: () async {
                Navigator.pop(context);
                await _exportNoteAsMarkdown(note.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Duplicate'),
              onTap: () async {
                Navigator.pop(context);
                await _duplicateNote(note.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.archive),
              title: const Text('Archive'),
              onTap: () {
                Navigator.pop(context);
                ref.read(noteOperationsProvider.notifier).archiveNote(note.id);
                if (note.id == _selectedNoteId) {
                  setState(() {
                    _selectedNoteId = null;
                    _currentNote = null;
                  });
                }
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
                if (note.id == _selectedNoteId) {
                  setState(() {
                    _selectedNoteId = null;
                    _currentNote = null;
                  });
                }
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        title,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _NoteListItem extends StatelessWidget {
  final NoteMetadata note;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _NoteListItem({
    required this.note,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      key: FyndoKeys.noteItem(note.id),
      color: isSelected
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: isSelected
                    ? theme.colorScheme.primary
                    : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (note.isPinned)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Icon(
                        Icons.push_pin,
                        size: 14,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  Expanded(
                    child: Text(
                      note.title.isEmpty ? 'Untitled' : note.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontStyle: note.title.isEmpty ? FontStyle.italic : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _formatDate(note.modifiedAt),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inDays == 0) {
      return DateFormat.jm().format(date);
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return DateFormat.EEEE().format(date);
    } else {
      return DateFormat.MMMd().format(date);
    }
  }
}
