// ═══════════════════════════════════════════════════════════════════════════
// FYNDO - Zero-Trust Notes OS
// Note Providers - Riverpod State Management
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fyndo_app/features/notes/data/note_repository.dart';
import 'package:fyndo_app/features/notes/models/note.dart';
import 'package:fyndo_app/providers/crypto_providers.dart';
import 'package:fyndo_app/providers/vault_providers.dart';

/// Provider for note repository.
final noteRepositoryProvider = Provider<EncryptedNoteRepository>((ref) {
  final vault = ref.watch(unlockedVaultProvider);
  final crypto = ref.watch(cryptoServiceProvider);

  return EncryptedNoteRepository(vault: vault, crypto: crypto);
});

/// Provider for all notes metadata.
final notesMetadataProvider = FutureProvider<List<NoteMetadata>>((ref) async {
  final repo = ref.watch(noteRepositoryProvider);
  return repo.listAll();
});

/// Provider for active (non-trashed, non-archived) notes.
final activeNotesProvider = FutureProvider<List<NoteMetadata>>((ref) async {
  final repo = ref.watch(noteRepositoryProvider);
  final all = await repo.listAll();
  return all.where((n) => !n.isTrashed && !n.isArchived).toList()..sort((a, b) {
    // Pinned first, then by modified date
    if (a.isPinned != b.isPinned) {
      return a.isPinned ? -1 : 1;
    }
    return b.modifiedAt.compareTo(a.modifiedAt);
  });
});

/// Provider for trashed notes.
final trashedNotesProvider = FutureProvider<List<NoteMetadata>>((ref) async {
  final repo = ref.watch(noteRepositoryProvider);
  return repo.listTrashed();
});

/// Provider for archived notes.
final archivedNotesProvider = FutureProvider<List<NoteMetadata>>((ref) async {
  final repo = ref.watch(noteRepositoryProvider);
  final all = await repo.listAll();
  return all.where((n) => n.isArchived && !n.isTrashed).toList()
    ..sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
});

/// Provider for notes in a specific notebook.
final notebookNotesProvider =
    FutureProvider.family<List<NoteMetadata>, String?>((ref, notebookId) async {
      final repo = ref.watch(noteRepositoryProvider);
      return repo.listByNotebook(notebookId);
    });

/// Provider for notes with a specific tag.
final tagNotesProvider = FutureProvider.family<List<NoteMetadata>, String>((
  ref,
  tag,
) async {
  final repo = ref.watch(noteRepositoryProvider);
  return repo.listByTag(tag);
});

/// Provider for a single note.
final noteProvider = FutureProvider.family<Note?, String>((ref, noteId) async {
  final repo = ref.watch(noteRepositoryProvider);
  return repo.load(noteId);
});

/// Provider for note count in a specific notebook.
/// This is computed dynamically from the notes list, so it's always up-to-date.
final notebookNoteCountProvider = FutureProvider.family<int, String?>((
  ref,
  notebookId,
) async {
  final notes = await ref.watch(notebookNotesProvider(notebookId).future);
  return notes.where((n) => !n.isTrashed).length;
});

/// Provider for note statistics.
final noteStatsProvider = FutureProvider<NoteStats>((ref) async {
  final repo = ref.watch(noteRepositoryProvider);
  return repo.getStats();
});

/// Provider for search results.
final noteSearchProvider = FutureProvider.family<List<NoteMetadata>, String>((
  ref,
  query,
) async {
  if (query.isEmpty) return [];
  final repo = ref.watch(noteRepositoryProvider);
  return repo.searchByTitle(query);
});

/// Notifier for note operations.
class NoteOperationsNotifier extends Notifier<void> {
  @override
  void build() {}

  /// Creates a new note.
  Future<Note> createNote({
    required String title,
    String content = '',
    String? notebookId,
    List<String> tags = const [],
  }) async {
    final repo = ref.read(noteRepositoryProvider);
    final note = Note.create(
      title: title,
      content: content,
      notebookId: notebookId,
      tags: tags,
    );
    final saved = await repo.save(note);

    // Invalidate related providers
    ref.invalidate(notesMetadataProvider);
    ref.invalidate(activeNotesProvider);
    ref.invalidate(noteStatsProvider);
    if (notebookId != null) {
      ref.invalidate(notebookNotesProvider(notebookId));
    }
    for (final tag in tags) {
      ref.invalidate(tagNotesProvider(tag));
    }

    return saved;
  }

  /// Updates an existing note.
  Future<Note> updateNote(Note note) async {
    final repo = ref.read(noteRepositoryProvider);
    final updated = note.copyWith(modifiedAt: DateTime.now().toUtc());
    final saved = await repo.save(updated);

    // Invalidate related providers
    ref.invalidate(noteProvider(note.id));
    ref.invalidate(notesMetadataProvider);
    ref.invalidate(activeNotesProvider);

    return saved;
  }

  /// Moves a note to trash.
  Future<void> trashNote(String noteId) async {
    final repo = ref.read(noteRepositoryProvider);
    final note = await repo.load(noteId);
    if (note != null) {
      await repo.save(note.trash());

      ref.invalidate(noteProvider(noteId));
      ref.invalidate(notesMetadataProvider);
      ref.invalidate(activeNotesProvider);
      ref.invalidate(trashedNotesProvider);
      ref.invalidate(noteStatsProvider);
      if (note.notebookId != null) {
        ref.invalidate(notebookNotesProvider(note.notebookId));
      }
    }
  }

  /// Restores a note from trash.
  Future<void> restoreNote(String noteId) async {
    final repo = ref.read(noteRepositoryProvider);
    final note = await repo.load(noteId);
    if (note != null) {
      await repo.save(note.restore());

      ref.invalidate(noteProvider(noteId));
      ref.invalidate(notesMetadataProvider);
      ref.invalidate(activeNotesProvider);
      ref.invalidate(trashedNotesProvider);
      ref.invalidate(noteStatsProvider);
      if (note.notebookId != null) {
        ref.invalidate(notebookNotesProvider(note.notebookId));
      }
    }
  }

  /// Permanently deletes a note.
  Future<void> deleteNote(String noteId) async {
    final repo = ref.read(noteRepositoryProvider);
    // Load note first to get notebookId before deleting
    final note = await repo.load(noteId);
    await repo.delete(noteId);

    ref.invalidate(noteProvider(noteId));
    ref.invalidate(notesMetadataProvider);
    ref.invalidate(activeNotesProvider);
    ref.invalidate(trashedNotesProvider);
    ref.invalidate(noteStatsProvider);
    if (note?.notebookId != null) {
      ref.invalidate(notebookNotesProvider(note!.notebookId));
    }
  }

  /// Toggles pin status of a note.
  Future<void> togglePin(String noteId) async {
    final repo = ref.read(noteRepositoryProvider);
    final note = await repo.load(noteId);
    if (note != null) {
      await repo.save(note.copyWith(isPinned: !note.isPinned));

      ref.invalidate(noteProvider(noteId));
      ref.invalidate(notesMetadataProvider);
      ref.invalidate(activeNotesProvider);
    }
  }

  /// Archives a note.
  Future<void> archiveNote(String noteId) async {
    final repo = ref.read(noteRepositoryProvider);
    final note = await repo.load(noteId);
    if (note != null) {
      await repo.save(note.archive());

      ref.invalidate(noteProvider(noteId));
      ref.invalidate(notesMetadataProvider);
      ref.invalidate(activeNotesProvider);
      ref.invalidate(noteStatsProvider);
    }
  }

  /// Unarchives a note.
  Future<void> unarchiveNote(String noteId) async {
    final repo = ref.read(noteRepositoryProvider);
    final note = await repo.load(noteId);
    if (note != null) {
      await repo.save(note.unarchive());

      ref.invalidate(noteProvider(noteId));
      ref.invalidate(notesMetadataProvider);
      ref.invalidate(activeNotesProvider);
      ref.invalidate(noteStatsProvider);
    }
  }
}

/// Provider for note operations.
final noteOperationsProvider = NotifierProvider<NoteOperationsNotifier, void>(
  NoteOperationsNotifier.new,
);
