// ═══════════════════════════════════════════════════════════════════════════
// FYNDO - Zero-Trust Notes OS
// Note Consumer - Wrapper for Note State
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fyndo_app/core/logging/app_logger.dart';
import 'package:fyndo_app/features/notes/data/note_repository.dart';
import 'package:fyndo_app/features/notes/models/note.dart';
import 'package:fyndo_app/providers/note_providers.dart';

/// Consumer widget for notes metadata list.
class NotesMetadataConsumer extends ConsumerWidget {
  /// Builder function called with async value of notes metadata.
  final Widget Function(
    BuildContext context,
    AsyncValue<List<NoteMetadata>> notesAsync,
    Widget? child,
  )
  builder;

  /// Optional child widget.
  final Widget? child;

  const NotesMetadataConsumer({super.key, required this.builder, this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(notesMetadataProvider);
    return builder(context, notesAsync, child);
  }
}

/// Consumer widget for active notes.
class ActiveNotesConsumer extends ConsumerWidget {
  /// Builder function called with async value of active notes.
  final Widget Function(
    BuildContext context,
    AsyncValue<List<NoteMetadata>> notesAsync,
    Widget? child,
  )
  builder;

  /// Optional child widget.
  final Widget? child;

  const ActiveNotesConsumer({super.key, required this.builder, this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(activeNotesProvider);
    return builder(context, notesAsync, child);
  }
}

/// Consumer widget for notes in a notebook.
class NotebookNotesConsumer extends ConsumerWidget {
  static final _log = AppLogger.get('NotebookNotesConsumer');

  /// Notebook ID to filter by.
  final String? notebookId;

  /// Builder function called with async value of notes.
  final Widget Function(
    BuildContext context,
    AsyncValue<List<NoteMetadata>> notesAsync,
    Widget? child,
  )
  builder;

  /// Optional child widget.
  final Widget? child;

  const NotebookNotesConsumer({
    super.key,
    required this.notebookId,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    _log.debug('Building NotebookNotesConsumer for notebook: $notebookId');
    final notesAsync = ref.watch(notebookNotesProvider(notebookId));

    notesAsync.when(
      data: (notes) =>
          _log.debug('Loaded ${notes.length} notes for notebook $notebookId'),
      loading: () => _log.debug('Loading notes for notebook $notebookId...'),
      error: (error, stack) {
        _log.error(
          'Error loading notes for notebook $notebookId',
          error: error,
          stackTrace: stack,
        );
      },
    );

    return builder(context, notesAsync, child);
  }
}

/// Consumer widget for a single note.
class SingleNoteConsumer extends ConsumerWidget {
  /// Note ID to watch.
  final String noteId;

  /// Builder function called with async value of note.
  final Widget Function(
    BuildContext context,
    AsyncValue<Note?> noteAsync,
    Widget? child,
  )
  builder;

  /// Optional child widget.
  final Widget? child;

  const SingleNoteConsumer({
    super.key,
    required this.noteId,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noteAsync = ref.watch(noteProvider(noteId));
    return builder(context, noteAsync, child);
  }
}

/// Consumer widget for note search results.
class NoteSearchConsumer extends ConsumerWidget {
  /// Search query.
  final String query;

  /// Builder function called with async value of search results.
  final Widget Function(
    BuildContext context,
    AsyncValue<List<NoteMetadata>> resultsAsync,
    Widget? child,
  )
  builder;

  /// Optional child widget.
  final Widget? child;

  const NoteSearchConsumer({
    super.key,
    required this.query,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(noteSearchProvider(query));
    return builder(context, resultsAsync, child);
  }
}

/// Consumer widget for note statistics.
class NoteStatsConsumer extends ConsumerWidget {
  /// Builder function called with async value of stats.
  final Widget Function(
    BuildContext context,
    AsyncValue<NoteStats> statsAsync,
    Widget? child,
  )
  builder;

  /// Optional child widget.
  final Widget? child;

  const NoteStatsConsumer({super.key, required this.builder, this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(noteStatsProvider);
    return builder(context, statsAsync, child);
  }
}

/// Consumer widget for trashed notes.
class TrashedNotesConsumer extends ConsumerWidget {
  /// Builder function called with async value of trashed notes.
  final Widget Function(
    BuildContext context,
    AsyncValue<List<NoteMetadata>> notesAsync,
    Widget? child,
  )
  builder;

  /// Optional child widget.
  final Widget? child;

  const TrashedNotesConsumer({super.key, required this.builder, this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(trashedNotesProvider);
    return builder(context, notesAsync, child);
  }
}

/// Consumer widget for archived notes.
class ArchivedNotesConsumer extends ConsumerWidget {
  /// Builder function called with async value of archived notes.
  final Widget Function(
    BuildContext context,
    AsyncValue<List<NoteMetadata>> notesAsync,
    Widget? child,
  )
  builder;

  /// Optional child widget.
  final Widget? child;

  const ArchivedNotesConsumer({super.key, required this.builder, this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(archivedNotesProvider);
    return builder(context, notesAsync, child);
  }
}
