// WITFLO - Zero-Trust Notes OS
// Notebook Page - Split View with Notes List and Editor

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:witflo_app/core/agentic/app_keys.dart';
import 'package:witflo_app/core/logging/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:witflo_app/features/notes/models/note.dart';
import 'package:witflo_app/providers/note_providers.dart';
import 'package:witflo_app/providers/notebook_providers.dart';
import 'package:witflo_app/providers/unlocked_workspace_provider.dart';
import 'package:witflo_app/ui/consumers/note_consumer.dart';
import 'package:witflo_app/ui/consumers/notebook_consumer.dart';
import 'package:witflo_app/ui/theme/app_theme.dart';
import 'package:witflo_app/ui/widgets/common/app_bar.dart';
import 'package:witflo_app/ui/widgets/common/app_empty_state.dart';
import 'package:witflo_app/ui/widgets/note/note_editor.dart';
import 'package:witflo_app/ui/widgets/note/note_export_helper.dart';
import 'package:witflo_app/ui/widgets/note/note_share_dialog.dart';
import 'package:witflo_app/core/config/feature_flags.dart';
import 'package:witflo_app/ui/widgets/notebook/notebook_menu.dart';
import 'package:intl/intl.dart';

/// Notebook page showing notes in a split view - list on left, editor on right.
class NotebookPage extends ConsumerWidget {
  final String notebookId;
  final String? initialNoteId;

  const NotebookPage({super.key, required this.notebookId, this.initialNoteId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleNotebookConsumer(
      notebookId: notebookId,
      builder: (context, notebook, _) {
        if (notebook == null) {
          return Scaffold(
            appBar: const AppAppBar(title: AppBarTitle('Notebook')),
            body: const AppEmptyState(
              icon: Icons.book,
              title: 'Notebook Not Found',
              description: 'This notebook may have been deleted.',
            ),
          );
        }

        return _NotebookPageContent(
          notebook: notebook,
          initialNoteId: initialNoteId,
        );
      },
    );
  }
}

class _NotebookPageContent extends ConsumerStatefulWidget {
  final Notebook notebook;
  final String? initialNoteId;

  const _NotebookPageContent({required this.notebook, this.initialNoteId});

  @override
  ConsumerState<_NotebookPageContent> createState() =>
      _NotebookPageContentState();
}

class _NotebookPageContentState extends ConsumerState<_NotebookPageContent>
    with WidgetsBindingObserver {
  static final _log = AppLogger.get('NotebookPage');

  String? _selectedNoteId;
  Note? _currentNote;
  final _titleController = TextEditingController();
  // Create a new GlobalKey for each note selection to force widget rebuild
  GlobalKey<NoteEditorState>? _editorKey;
  Timer? _saveTimer;
  bool _hasChanges = false;
  bool _isSaving = false;
  DateTime? _lastSavedAt;
  DateTime? _lastLocalSaveAt; // Track when we last saved locally
  String? _lastSavedNoteId; // Track which note we last saved

  // Stream subscription for external notes changes (live sync)
  StreamSubscription<String>? _notesChangedSubscription;

  Notebook get notebook => widget.notebook;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Pre-select note if initialNoteId is provided
    if (widget.initialNoteId != null) {
      _selectedNoteId = widget.initialNoteId;
    }

    // Subscribe to external notes changes for live sync
    // This refreshes the notes list when another app instance makes changes
    final workspaceNotifier = ref.read(unlockedWorkspaceProvider.notifier);
    _log.debug(
      'Setting up external notes change listener for vault in workspace',
    );
    _notesChangedSubscription = workspaceNotifier.onNotesChanged.listen(
      _handleExternalNotesChange,
    );
  }

  /// Handles external notes changes (from another app instance via file watcher)
  void _handleExternalNotesChange(String vaultId) async {
    _log.info(
      'External notes change event received for vault: $vaultId '
      '(isSaving=$_isSaving, hasChanges=$_hasChanges, selectedNoteId=$_selectedNoteId)',
    );

    // Ignore file changes while we're actively saving
    // This prevents the editor from resetting when detecting our own writes
    if (_isSaving || _hasChanges) {
      _log.debug(
        'Ignoring external change - currently saving or have local changes',
      );
      return;
    }

    _log.info('Processing external notes change - will refresh notes list');

    // Invalidate the notes list for this notebook to trigger a rebuild
    ref.invalidate(notebookNotesProvider(notebook.id));

    // If we have a note selected, reload it from disk and update the editor
    if (_selectedNoteId != null && _currentNote != null) {
      // Check if this is the same note we just saved recently
      // Only apply 2-second window if it's the SAME note (to ignore our own write)
      if (_lastSavedNoteId == _selectedNoteId && _lastLocalSaveAt != null) {
        final timeSinceLastSave = DateTime.now().difference(_lastLocalSaveAt!);
        if (timeSinceLastSave.inSeconds < 2) {
          _log.debug(
            'Ignoring external change for note $_selectedNoteId - '
            'we saved it ${timeSinceLastSave.inMilliseconds}ms ago',
          );
          return;
        }
      }

      try {
        _log.debug(
          'Invalidating and reloading note ${_selectedNoteId} from disk...',
        );

        // Invalidate the provider to force a fresh read from disk
        ref.invalidate(noteProvider(_selectedNoteId!));

        final updatedNote = await ref.read(
          noteProvider(_selectedNoteId!).future,
        );

        if (updatedNote == null) {
          _log.warning(
            'Note ${_selectedNoteId} not found after external change',
          );
          return;
        }

        _log.debug(
          'Loaded note: modifiedAt=${updatedNote.modifiedAt}, '
          'current modifiedAt=${_currentNote!.modifiedAt}, '
          'content length=${updatedNote.content.length}',
        );

        if (updatedNote.modifiedAt != _currentNote!.modifiedAt && mounted) {
          _log.info(
            'External update detected for note ${updatedNote.id}, updating editor content',
          );
          // Update editor with external changes
          _editorKey?.currentState?.setContent(updatedNote.content);
          _titleController.text = updatedNote.title;
          setState(() {
            _currentNote = updatedNote;
          });
        } else {
          _log.debug('Note timestamps match, no update needed');
        }
      } catch (e, stack) {
        _log.error(
          'Failed to reload note after external change',
          error: e,
          stackTrace: stack,
        );
      }
    } else {
      _log.debug('No note currently selected, only refreshed list');
    }
  }

  @override
  void dispose() {
    // Cancel stream subscription for live sync
    _notesChangedSubscription?.cancel();
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

    _log.debug(
      'Starting save for note ${_currentNote!.id}: '
      'hasChanges=$_hasChanges, isSaving=$_isSaving',
    );
    setState(() => _isSaving = true);

    try {
      final content = _editorKey?.currentState?.getContent() ?? '';
      _log.debug(
        'Saving note ${_currentNote!.id}: '
        'title="${_titleController.text}", '
        'content length=${content.length}, '
        'preview: ${content.substring(0, content.length.clamp(0, 100))}',
      );
      final updatedNote = _currentNote!.copyWith(
        title: _titleController.text,
        content: content,
      );

      await ref.read(noteOperationsProvider.notifier).updateNote(updatedNote);
      _log.debug('Note saved successfully: ${updatedNote.id}');

      if (mounted) {
        // Invalidate the notes LIST to refresh it
        // But DON'T invalidate the individual note provider - that would reset the editor
        ref.invalidate(notebookNotesProvider(notebook.id));
        // Don't call: ref.invalidate(noteProvider(updatedNote.id));

        setState(() {
          _hasChanges = false;
          _currentNote = updatedNote;
          _lastSavedAt = DateTime.now();
          _lastLocalSaveAt = DateTime.now(); // Track local save time
          _lastSavedNoteId = updatedNote.id; // Track which note we saved
        });
        _log.debug(
          'Save completed, state updated: hasChanges=$_hasChanges, isSaving=$_isSaving',
        );
      }
    } catch (e) {
      _log.error('Failed to save note', error: e);
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
    _log.debug(
      'Selected note ${note?.id}: '
      'content length=${note?.content.length ?? 0}, '
      'preview: ${note != null ? note.content.substring(0, note.content.length.clamp(0, 100)) : "null"}',
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Note exported successfully')),
          );
        }
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
      appBar: AppAppBar(
        title: Row(
          children: [
            Icon(_getIconData(notebook.icon), color: color, size: 24),
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
          NotebookMenu(
            key: AppKeys.menuNotebookActions,
            notebook: notebook,
            onRename: () => _showRenameDialog(context, ref),
            onDelete: () => _confirmDelete(context, ref),
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
                  key: AppKeys.btnBackToNotes,
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
              return AppEmptyState(
                icon: Icons.note_outlined,
                title: 'No Notes Yet',
                description: 'Create your first note in this notebook.',
                actionText: 'Create Note',
                onAction: _createNote,
              );
            }

            final pinnedNotes = notes.where((n) => n.isPinned).toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
            final regularNotes = notes.where((n) => !n.isPinned).toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

            return Column(
              children: [
                // Header with create button
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.padding,
                    vertical: AppTheme.paddingSmall,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: theme.dividerColor),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Notes',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _createNote,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('New'),
                      ),
                    ],
                  ),
                ),
                // Notes list
                Expanded(
                  child: ListView(
                    key: AppKeys.listNotes,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      if (pinnedNotes.isNotEmpty) ...[
                        const _SectionHeader(title: 'PINNED'),
                        ...pinnedNotes.map(
                          (note) => _NoteListItem(
                            note: note,
                            isSelected: note.id == _selectedNoteId,
                            onTap: () => _selectNote(note.id),
                            onLongPress: () =>
                                _showNoteOptions(context, ref, note),
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
                            onLongPress: () =>
                                _showNoteOptions(context, ref, note),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Footer with total count and save status
                Container(
                  padding: const EdgeInsets.all(AppTheme.paddingSmall),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: theme.dividerColor)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.note_outlined,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${notes.length} ${notes.length == 1 ? 'note' : 'notes'}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (_selectedNoteId != null) ...[
                        const Spacer(),
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
                    ],
                  ),
                ),
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
      return AppEmptyState(
        icon: Icons.edit_note,
        title: 'Select a Note',
        description: 'Choose a note from the list to start editing.',
        actionText: 'Create Note',
        onAction: _createNote,
      );
    }

    // Use local state for rendering to avoid unnecessary rebuilds
    // We only update from the provider when external changes are detected
    if (_currentNote == null) {
      // Initial load - fetch the note
      return FutureBuilder<Note?>(
        future: ref.read(noteProvider(_selectedNoteId!).future),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final note = snapshot.data;
          if (note == null) {
            return const Center(child: Text('Note not found'));
          }

          // Initialize local state
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _currentNote == null) {
              setState(() {
                _currentNote = note;
                _titleController.text = note.title;
              });
            }
          });

          return _buildEditorContent(theme, note);
        },
      );
    }

    return _buildEditorContent(theme, _currentNote!);
  }

  /// Builds the actual editor content (extracted from original _buildEditorArea)
  Widget _buildEditorContent(ThemeData theme, Note note) {
    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
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
              horizontal: AppTheme.paddingSmall,
              vertical: 4,
            ),
            color: theme.colorScheme.surface,
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
                  key: AppKeys.btnNotePin,
                  icon: Icon(
                    note.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                    size: 20,
                  ),
                  onPressed: () => ref
                      .read(noteOperationsProvider.notifier)
                      .togglePin(note.id),
                  tooltip: note.isPinned ? 'Unpin note' : 'Pin note',
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 4),
                // Export button
                IconButton(
                  icon: const Icon(Icons.download_outlined, size: 20),
                  onPressed: () => _exportNoteAsMarkdown(note.id),
                  tooltip: 'Export as Markdown',
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 4),
                // Duplicate button
                IconButton(
                  icon: const Icon(Icons.copy_outlined, size: 20),
                  onPressed: () => _duplicateNote(note.id),
                  tooltip: 'Duplicate',
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 4),
                // Archive button
                IconButton(
                  icon: const Icon(Icons.archive_outlined, size: 20),
                  onPressed: () {
                    ref
                        .read(noteOperationsProvider.notifier)
                        .archiveNote(note.id);
                    setState(() {
                      _selectedNoteId = null;
                      _currentNote = null;
                    });
                  },
                  tooltip: 'Archive',
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 4),
                // Delete button
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: theme.colorScheme.error,
                  ),
                  onPressed: () => _confirmDeleteNote(context),
                  tooltip: 'Delete',
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
                if (FeatureFlags.shareEnabled) ...[
                  const SizedBox(width: 4),
                  // Share button
                  IconButton(
                    icon: const Icon(Icons.share_outlined, size: 20),
                    onPressed: () {
                      ShareDialog.show(
                        context,
                        itemName: note.title.isEmpty ? 'Untitled' : note.title,
                        itemType: ShareItemType.note,
                      );
                    },
                    tooltip: 'Share',
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                  ),
                ],
              ],
            ),
          ),
          // Note title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.padding),
            child: TextField(
              key: AppKeys.inputNoteTitle,
              controller: _titleController,
              onChanged: (value) => _onContentChanged(value),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
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
              horizontal: AppTheme.padding,
              vertical: AppTheme.paddingSmall,
            ),
            height: 1,
            color: theme.dividerColor.withValues(alpha: 0.5),
          ),
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
    );
  }

  void _confirmDeleteNote(BuildContext context) {
    if (_currentNote == null) return;

    final theme = Theme.of(context);
    final note = _currentNote!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: theme.colorScheme.error),
            const SizedBox(width: 12),
            const Text('Delete Permanently?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This note will be permanently deleted:',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
                border: Border.all(color: theme.colorScheme.error),
              ),
              child: Text(
                note.title.isEmpty ? 'Untitled' : note.title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'This action cannot be undone. The note and all its contents will be permanently removed.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(noteOperationsProvider.notifier).deleteNote(note.id);
              setState(() {
                _selectedNoteId = null;
                _currentNote = null;
              });
            },
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
            ),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
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

  void _confirmDeleteNoteFromMenu(
    BuildContext context,
    WidgetRef ref,
    NoteMetadata note,
  ) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: theme.colorScheme.error),
            const SizedBox(width: 12),
            const Text('Delete Permanently?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This note will be permanently deleted:',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
                border: Border.all(color: theme.colorScheme.error),
              ),
              child: Text(
                note.title.isEmpty ? 'Untitled' : note.title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'This action cannot be undone. The note and all its contents will be permanently removed.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(noteOperationsProvider.notifier).deleteNote(note.id);
              if (note.id == _selectedNoteId) {
                setState(() {
                  _selectedNoteId = null;
                  _currentNote = null;
                });
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
            ),
            child: const Text('Delete Permanently'),
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
            if (FeatureFlags.shareEnabled)
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
                'Delete',
                style: TextStyle(color: theme.colorScheme.error),
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteNoteFromMenu(context, ref, note);
              },
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconData(String? iconName) {
    switch (iconName) {
      case 'work':
        return Icons.work;
      case 'personal':
        return Icons.person;
      case 'ideas':
        return Icons.lightbulb;
      case 'journal':
        return Icons.auto_stories;
      case 'finance':
        return Icons.attach_money;
      case 'health':
        return Icons.favorite;
      case 'travel':
        return Icons.flight;
      case 'education':
        return Icons.school;
      case 'project':
        return Icons.folder_special;
      default:
        return Icons.book;
    }
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
      key: AppKeys.noteItem(note.id),
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
                _formatDate(note.createdAt),
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

    if (diff.inDays == 0) {
      return 'Today, ${DateFormat.jm().format(date)}';
    } else if (diff.inDays == 1) {
      return 'Yesterday, ${DateFormat.jm().format(date)}';
    } else if (diff.inDays < 7) {
      return '${DateFormat.EEEE().format(date)}, ${DateFormat.jm().format(date)}';
    } else if (date.year == now.year) {
      return '${DateFormat.MMMd().format(date)}, ${DateFormat.jm().format(date)}';
    } else {
      return '${DateFormat.yMMMd().format(date)}, ${DateFormat.jm().format(date)}';
    }
  }
}
