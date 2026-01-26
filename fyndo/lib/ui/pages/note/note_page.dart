// ═══════════════════════════════════════════════════════════════════════════
// FYNDO - Zero-Trust Notes OS
// Note Page - Note Editor with Quill
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fyndo_app/features/notes/models/note.dart';
import 'package:fyndo_app/providers/note_providers.dart';
import 'package:fyndo_app/ui/consumers/note_consumer.dart';
import 'package:fyndo_app/ui/theme/fyndo_theme.dart';
import 'package:fyndo_app/ui/widgets/common/fyndo_app_bar.dart';
import 'package:fyndo_app/ui/widgets/note/note_editor.dart';
import 'package:fyndo_app/ui/widgets/note/note_export_helper.dart';
import 'package:fyndo_app/ui/widgets/note/note_share_dialog.dart';
import 'package:go_router/go_router.dart';

/// Note page with Quill editor.
class NotePage extends ConsumerStatefulWidget {
  final String noteId;

  const NotePage({super.key, required this.noteId});

  @override
  ConsumerState<NotePage> createState() => _NotePageState();
}

class _NotePageState extends ConsumerState<NotePage>
    with WidgetsBindingObserver {
  final _titleController = TextEditingController();
  final _editorKey = GlobalKey<NoteEditorState>();
  Timer? _saveTimer;
  Note? _note;
  bool _hasChanges = false;
  bool _isSaving = false;
  DateTime? _lastSavedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Save any pending changes before disposing
    if (_hasChanges && !_isSaving) {
      _saveNoteSync();
    }
    _titleController.dispose();
    _saveTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Save when app goes to background or is paused
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (_hasChanges && !_isSaving) {
        _saveNote();
      }
    }
  }

  void _onTitleChanged(String value) {
    _hasChanges = true;
    _debounceSave();
  }

  void _onContentChanged(String content) {
    _hasChanges = true;
    _debounceSave();
  }

  void _debounceSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 2), _saveNote);
  }

  Future<void> _saveNote() async {
    if (_note == null || !_hasChanges || _isSaving) return;

    setState(() => _isSaving = true);

    try {
      final content = _editorKey.currentState?.getContent() ?? '';

      final updatedNote = _note!.copyWith(
        title: _titleController.text,
        content: content,
      );

      await ref.read(noteOperationsProvider.notifier).updateNote(updatedNote);

      if (mounted) {
        setState(() {
          _hasChanges = false;
          _note = updatedNote;
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

  /// Sync save for dispose - fire and forget
  void _saveNoteSync() {
    if (_note == null || !_hasChanges) return;

    final content = _editorKey.currentState?.getContent() ?? '';
    final updatedNote = _note!.copyWith(
      title: _titleController.text,
      content: content,
    );

    // Fire and forget - we can't await in dispose
    ref.read(noteOperationsProvider.notifier).updateNote(updatedNote);
  }

  @override
  Widget build(BuildContext context) {
    return SingleNoteConsumer(
      noteId: widget.noteId,
      builder: (context, noteAsync, _) {
        return noteAsync.when(
          data: (note) {
            if (note == null) {
              return Scaffold(
                appBar: const FyndoAppBar(title: FyndoAppBarTitle('Note')),
                body: const Center(child: Text('Note not found')),
              );
            }

            // Initialize state on first load
            if (_note == null) {
              _note = note;
              _titleController.text = note.title;
            }

            return _buildEditor(context, note);
          },
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (error, _) => Scaffold(
            appBar: const FyndoAppBar(title: FyndoAppBarTitle('Note')),
            body: Center(child: Text('Error: $error')),
          ),
        );
      },
    );
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

  Widget _buildEditor(BuildContext context, Note note) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && _hasChanges) {
          await _saveNote();
          if (mounted && context.mounted) {
            Navigator.pop(context);
          }
        }
      },
      child: Scaffold(
        appBar: FyndoAppBar(
          title: Row(
            children: [
              if (_isSaving)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              if (_hasChanges && !_isSaving)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              Text(
                _getStatusText(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(
                note.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
              ),
              onPressed: () => _togglePin(note),
              tooltip: note.isPinned ? 'Unpin' : 'Pin',
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) => _handleMenuAction(context, value, note),
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
                  value: 'archive',
                  child: ListTile(
                    leading: Icon(Icons.archive),
                    title: Text('Archive'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'tags',
                  child: ListTile(
                    leading: Icon(Icons.label),
                    title: Text('Tags'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete, color: theme.colorScheme.error),
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
        body: Container(
          // Paper-like background with subtle texture effect
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
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
              // Paper margin indicator (left red line like real paper)
              Expanded(
                child: Row(
                  children: [
                    // Left margin line (optional paper aesthetic)
                    Container(
                      width: 2,
                      margin: const EdgeInsets.only(left: 32),
                      color: theme.colorScheme.error.withValues(alpha: 0.15),
                    ),
                    // Main content area
                    Expanded(
                      child: Column(
                        children: [
                          // Title field
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

                          // Tags
                          if (note.tags.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: FyndoTheme.padding,
                              ),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: note.tags.map((tag) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: theme.dividerColor,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          tag,
                                          style: theme.textTheme.labelSmall,
                                        ),
                                        const SizedBox(width: 4),
                                        InkWell(
                                          onTap: () => _removeTag(note, tag),
                                          child: Icon(
                                            Icons.close,
                                            size: 14,
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),

                          // Subtle divider
                          Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: FyndoTheme.padding,
                              vertical: FyndoTheme.paddingSmall,
                            ),
                            height: 1,
                            color: theme.dividerColor.withValues(alpha: 0.5),
                          ),

                          // Editor
                          Expanded(
                            child: NoteEditor(
                              key: _editorKey,
                              initialContent: note.content,
                              onContentChanged: _onContentChanged,
                              autofocus: note.title.isEmpty,
                              placeholder: 'Start writing...',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _togglePin(Note note) {
    ref.read(noteOperationsProvider.notifier).togglePin(note.id);
    setState(() {
      _note = note.copyWith(isPinned: !note.isPinned);
    });
  }

  void _handleMenuAction(BuildContext context, String action, Note note) {
    switch (action) {
      case 'share':
        ShareDialog.show(
          context,
          itemName: note.title.isEmpty ? 'Untitled' : note.title,
          itemType: ShareItemType.note,
          onGenerateLink: () async {
            return 'https://fyndo.app/share/note/${note.id}';
          },
          onShareWithUser: (email, role) {
            // TODO: Share with user
          },
        );
        break;
      case 'export':
        _exportNote(note);
        break;
      case 'archive':
        _archiveNote(note);
        break;
      case 'tags':
        _showTagsDialog(note);
        break;
      case 'delete':
        _confirmDelete(note);
        break;
    }
  }

  void _exportNote(Note note) {
    final content = _editorKey.currentState?.getPlainText() ?? note.content;

    NoteExportHelper.exportAsMarkdown(
      title: note.title.isEmpty ? 'Untitled' : note.title,
      content: content,
      tags: note.tags.toList(),
    );
  }

  void _archiveNote(Note note) {
    ref.read(noteOperationsProvider.notifier).archiveNote(note.id);
    context.pop();
  }

  void _showTagsDialog(Note note) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tags'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (note.tags.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: note.tags.map((tag) {
                  return Chip(
                    label: Text(tag),
                    onDeleted: () {
                      Navigator.pop(context);
                      _removeTag(note, tag);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Add tag',
                hintText: 'Enter tag name',
              ),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  Navigator.pop(context);
                  _addTag(note, value.trim());
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _addTag(Note note, String tag) async {
    final updatedNote = note.copyWith(tags: [...note.tags, tag]);
    await ref.read(noteOperationsProvider.notifier).updateNote(updatedNote);
    setState(() => _note = updatedNote);
  }

  void _removeTag(Note note, String tag) async {
    final updatedNote = note.copyWith(
      tags: note.tags.where((t) => t != tag).toList(),
    );
    await ref.read(noteOperationsProvider.notifier).updateNote(updatedNote);
    setState(() => _note = updatedNote);
  }

  void _confirmDelete(Note note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Move to Trash?'),
        content: const Text(
          'This note will be moved to trash. You can restore it within 30 days.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(noteOperationsProvider.notifier).trashNote(note.id);
              context.pop();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Move to Trash'),
          ),
        ],
      ),
    );
  }
}
