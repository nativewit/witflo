// ═══════════════════════════════════════════════════════════════════════════
// WITFLO - Zero-Trust Notes OS
// Note Providers - Riverpod State Management
// ═══════════════════════════════════════════════════════════════════════════
//
// UPDATED FOR WORKSPACE MASTER PASSWORD (spec-002):
// - Uses unlockedWorkspaceProvider instead of deprecated unlockedVaultProvider
// - Vault keys come from workspace keyring, not individual vault passwords
// - Active vault is determined by selectedVaultIdProvider (user selection)
//
// Spec: docs/specs/spec-002-workspace-master-password.md
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:witflo_app/core/core.dart';
import 'package:witflo_app/core/logging/app_logger.dart';
import 'package:witflo_app/features/notes/data/note_repository.dart';
import 'package:witflo_app/features/notes/models/note.dart';
import 'package:witflo_app/providers/crypto_providers.dart';
import 'package:witflo_app/providers/sync_providers.dart';
import 'package:witflo_app/providers/unlocked_workspace_provider.dart';
import 'package:witflo_app/providers/vault_providers.dart';
import 'package:witflo_app/providers/vault_selection_providers.dart';
import 'package:path/path.dart' as p;

// Re-export activeVaultIdProvider for backward compatibility
export 'package:witflo_app/providers/vault_selection_providers.dart'
    show activeVaultIdProvider;

/// Provider for the unlocked active vault.
///
/// This replaces the deprecated unlockedVaultProvider and uses the new
/// workspace-based architecture from spec-002.
///
/// NOTE: This is an async provider that unlocks the vault on demand.
/// The vault is cached and automatically disposed when the workspace is locked.
final unlockedActiveVaultProvider = FutureProvider.autoDispose<UnlockedVault>((
  ref,
) async {
  final log = AppLogger.get('unlockedActiveVaultProvider');
  log.debug('Provider build started');

  final workspace = ref.watch(unlockedWorkspaceProvider);
  if (workspace == null) {
    log.error(
      'Provider build failed: Workspace is not unlocked',
      error: StateError('Workspace is not unlocked'),
    );
    throw StateError('Workspace is not unlocked');
  }
  log.debug('Workspace is unlocked, getting active vault ID...');

  final vaultId = ref.watch(activeVaultIdProvider);
  if (vaultId == null) {
    log.error(
      'Provider build failed: No vaults available',
      error: StateError('No vaults available'),
    );
    throw StateError('No vaults available in workspace');
  }
  log.debug('Active vault ID: $vaultId');

  // Get the vault key from the workspace
  log.debug('Getting vault key from workspace...');
  final vaultKeyBytes = workspace.getVaultKey(vaultId);
  log.debug(
    'Got vault key from workspace (disposed: ${vaultKeyBytes.isDisposed})',
  );

  // Wrap in VaultKey type
  final vaultKey = VaultKey(vaultKeyBytes);
  log.debug('Wrapped in VaultKey');

  // Get the vault path
  final vaultPath = p.join(workspace.rootPath, 'vaults', vaultId);
  log.debug('Vault path: $vaultPath');

  // Unlock the vault using the vault service
  final vaultService = ref.watch(vaultServiceProvider);
  log.debug('Unlocking vault...');
  final unlockedVault = await vaultService.unlockVault(
    vaultPath: vaultPath,
    vaultKey: vaultKey,
  );
  log.debug('Vault unlocked successfully');

  // Register vault for file monitoring (Phase 5)
  final workspaceNotifier = ref.read(unlockedWorkspaceProvider.notifier);
  await workspaceNotifier.registerVaultWatcher(unlockedVault);
  log.debug('Vault watcher registered');

  // Dispose the vault when the provider is disposed
  // NOTE: We do NOT dispose vaultKey here because it's owned by the workspace
  // The workspace manages the lifecycle of all vault keys and will dispose them
  // when the workspace is locked. Disposing here would break the cached keys.
  ref.onDispose(() {
    log.debug('Provider disposing, disposing unlockedVault only');
    unlockedVault.dispose();
  });

  log.debug('Provider build completed successfully');
  return unlockedVault;
});

/// Provider for note repository.
///
/// This now uses the async unlockedActiveVaultProvider.
/// Consumer widgets must handle the async nature via FutureProviders or AsyncValue.
final noteRepositoryProvider =
    FutureProvider.autoDispose<EncryptedNoteRepository>((ref) async {
      final vault = await ref.watch(unlockedActiveVaultProvider.future);
      final crypto = ref.watch(cryptoServiceProvider);

      return EncryptedNoteRepository(vault: vault, crypto: crypto);
    });

/// Provider for all notes metadata.
final notesMetadataProvider = FutureProvider<List<NoteMetadata>>((ref) async {
  final repo = await ref.watch(noteRepositoryProvider.future);
  return repo.listAll();
});

/// Provider for active (non-trashed, non-archived) notes.
/// Uses optimized repository query method (Phase 3).
final activeNotesProvider = FutureProvider<List<NoteMetadata>>((ref) async {
  final repo = await ref.watch(noteRepositoryProvider.future);
  return repo.getActiveNotes();
});

/// Provider for trashed notes.
final trashedNotesProvider = FutureProvider<List<NoteMetadata>>((ref) async {
  final repo = await ref.watch(noteRepositoryProvider.future);
  return repo.listTrashed();
});

/// Provider for archived notes.
/// Uses optimized repository query method (Phase 3).
final archivedNotesProvider = FutureProvider<List<NoteMetadata>>((ref) async {
  final repo = await ref.watch(noteRepositoryProvider.future);
  return repo.getArchivedNotes();
});

/// Provider for pinned notes.
/// Uses optimized repository query method (Phase 3).
final pinnedNotesProvider = FutureProvider<List<NoteMetadata>>((ref) async {
  final repo = await ref.watch(noteRepositoryProvider.future);
  return repo.getPinnedNotes();
});

/// Provider for notes in a specific notebook.
/// Uses optimized repository query method (Phase 3).
final notebookNotesProvider =
    FutureProvider.family<List<NoteMetadata>, String?>((ref, notebookId) async {
      final repo = await ref.watch(noteRepositoryProvider.future);
      return repo.getNotesByNotebook(notebookId);
    });

/// Provider for notes with a specific tag.
/// Uses optimized repository query method (Phase 3).
final tagNotesProvider = FutureProvider.family<List<NoteMetadata>, String>((
  ref,
  tag,
) async {
  final repo = await ref.watch(noteRepositoryProvider.future);
  return repo.getNotesByTag(tag);
});

/// Provider for a single note.
final noteProvider = FutureProvider.family<Note?, String>((ref, noteId) async {
  final repo = await ref.watch(noteRepositoryProvider.future);
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
  final repo = await ref.watch(noteRepositoryProvider.future);
  return repo.getStats();
});

/// Provider for search results.
final noteSearchProvider = FutureProvider.family<List<NoteMetadata>, String>((
  ref,
  query,
) async {
  if (query.isEmpty) return [];
  final repo = await ref.watch(noteRepositoryProvider.future);
  return repo.searchByTitle(query);
});

/// Notifier for note operations.
class NoteOperationsNotifier extends AsyncNotifier<void> {
  static final _log = AppLogger.get('NoteOperationsNotifier');

  @override
  Future<void> build() async {}

  /// Helper to create a sync operation for note changes.
  /// This writes an encrypted operation to sync/pending/ for other app instances.
  Future<void> _createSyncOperation({
    required SyncOpType type,
    required String targetId,
    required Map<String, dynamic> payload,
  }) async {
    try {
      final syncService = await ref.read(syncServiceProvider.future);
      await syncService.createOperation(
        type: type,
        targetId: targetId,
        payload: payload,
      );
      _log.debug('Created sync operation: $type for $targetId');
    } catch (e) {
      // Log but don't fail the operation - sync is best-effort
      _log.warning('Failed to create sync operation: $e');
    }
  }

  /// Creates a new note.
  Future<Note> createNote({
    required String title,
    String content = '',
    String? notebookId,
    List<String> tags = const [],
  }) async {
    final repo = await ref.read(noteRepositoryProvider.future);
    final note = Note.create(
      title: title,
      content: content,
      notebookId: notebookId,
      tags: tags,
    );
    final saved = await repo.save(note);

    // Create sync operation for other app instances
    await _createSyncOperation(
      type: SyncOpType.createNote,
      targetId: saved.id,
      payload: {
        'title': saved.title,
        'content': saved.content,
        'notebook_id': saved.notebookId,
        'tags': saved.tags,
        'created_at': saved.createdAt.toIso8601String(),
        'modified_at': saved.modifiedAt.toIso8601String(),
      },
    );

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
    _log.debug('[NoteOperationsNotifier] Starting updateNote: ${note.id}');
    final repo = await ref.read(noteRepositoryProvider.future);
    final updated = note.copyWith(modifiedAt: DateTime.now().toUtc());
    final saved = await repo.save(updated);
    _log.debug(
      '[NoteOperationsNotifier] Note saved to repository: ${saved.id}',
    );

    // Create sync operation for other app instances
    await _createSyncOperation(
      type: SyncOpType.updateNote,
      targetId: saved.id,
      payload: {
        'title': saved.title,
        'content': saved.content,
        'notebook_id': saved.notebookId,
        'tags': saved.tags,
        'is_pinned': saved.isPinned,
        'is_archived': saved.isArchived,
        'is_trashed': saved.isTrashed,
        'modified_at': saved.modifiedAt.toIso8601String(),
      },
    );
    _log.debug(
      '[NoteOperationsNotifier] Sync operation created for: ${saved.id}',
    );

    // Invalidate related providers
    ref.invalidate(noteProvider(note.id));
    ref.invalidate(notesMetadataProvider);
    ref.invalidate(activeNotesProvider);

    _log.info('[NoteOperationsNotifier] updateNote completed: ${saved.id}');
    return saved;
  }

  /// Moves a note to trash.
  Future<void> trashNote(String noteId) async {
    final repo = await ref.read(noteRepositoryProvider.future);
    final note = await repo.load(noteId);
    if (note != null) {
      final trashed = note.trash();
      await repo.save(trashed);

      // Create sync operation for other app instances
      await _createSyncOperation(
        type: SyncOpType.updateNote,
        targetId: noteId,
        payload: {
          'is_trashed': true,
          'trashed_at': trashed.trashedAt?.toIso8601String(),
          'modified_at': trashed.modifiedAt.toIso8601String(),
        },
      );

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
    final repo = await ref.read(noteRepositoryProvider.future);
    final note = await repo.load(noteId);
    if (note != null) {
      final restored = note.restore();
      await repo.save(restored);

      // Create sync operation for other app instances
      await _createSyncOperation(
        type: SyncOpType.updateNote,
        targetId: noteId,
        payload: {
          'is_trashed': false,
          'trashed_at': null,
          'modified_at': restored.modifiedAt.toIso8601String(),
        },
      );

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
    final repo = await ref.read(noteRepositoryProvider.future);
    // Load note first to get notebookId before deleting
    final note = await repo.load(noteId);
    await repo.delete(noteId);

    // Create sync operation for other app instances
    await _createSyncOperation(
      type: SyncOpType.deleteNote,
      targetId: noteId,
      payload: {'deleted_at': DateTime.now().toUtc().toIso8601String()},
    );

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
    final repo = await ref.read(noteRepositoryProvider.future);
    final note = await repo.load(noteId);
    if (note != null) {
      final updated = note.copyWith(
        isPinned: !note.isPinned,
        modifiedAt: DateTime.now().toUtc(),
      );
      await repo.save(updated);

      // Create sync operation for other app instances
      await _createSyncOperation(
        type: SyncOpType.updateNote,
        targetId: noteId,
        payload: {
          'is_pinned': updated.isPinned,
          'modified_at': updated.modifiedAt.toIso8601String(),
        },
      );

      ref.invalidate(noteProvider(noteId));
      ref.invalidate(notesMetadataProvider);
      ref.invalidate(activeNotesProvider);
      if (note.notebookId != null) {
        ref.invalidate(notebookNotesProvider(note.notebookId));
      }
    }
  }

  /// Archives a note.
  Future<void> archiveNote(String noteId) async {
    final repo = await ref.read(noteRepositoryProvider.future);
    final note = await repo.load(noteId);
    if (note != null) {
      final archived = note.archive();
      await repo.save(archived);

      // Create sync operation for other app instances
      await _createSyncOperation(
        type: SyncOpType.updateNote,
        targetId: noteId,
        payload: {
          'is_archived': true,
          'modified_at': archived.modifiedAt.toIso8601String(),
        },
      );

      ref.invalidate(noteProvider(noteId));
      ref.invalidate(notesMetadataProvider);
      ref.invalidate(activeNotesProvider);
      ref.invalidate(noteStatsProvider);
      if (note.notebookId != null) {
        ref.invalidate(notebookNotesProvider(note.notebookId));
      }
    }
  }

  /// Unarchives a note.
  Future<void> unarchiveNote(String noteId) async {
    final repo = await ref.read(noteRepositoryProvider.future);
    final note = await repo.load(noteId);
    if (note != null) {
      final unarchived = note.unarchive();
      await repo.save(unarchived);

      // Create sync operation for other app instances
      await _createSyncOperation(
        type: SyncOpType.updateNote,
        targetId: noteId,
        payload: {
          'is_archived': false,
          'modified_at': unarchived.modifiedAt.toIso8601String(),
        },
      );

      ref.invalidate(noteProvider(noteId));
      ref.invalidate(notesMetadataProvider);
      ref.invalidate(activeNotesProvider);
      ref.invalidate(noteStatsProvider);
      if (note.notebookId != null) {
        ref.invalidate(notebookNotesProvider(note.notebookId));
      }
    }
  }

  /// Moves a note to a different notebook.
  ///
  /// Used when assigning orphan notes (notes without a notebook) to a notebook,
  /// or when reorganizing notes between notebooks.
  Future<Note?> moveToNotebook(String noteId, String notebookId) async {
    final repo = await ref.read(noteRepositoryProvider.future);
    final note = await repo.load(noteId);
    if (note == null) return null;

    final oldNotebookId = note.notebookId;
    final updated = note.copyWith(
      notebookId: notebookId,
      modifiedAt: DateTime.now().toUtc(),
    );
    final saved = await repo.save(updated);

    // Create sync operation for other app instances
    await _createSyncOperation(
      type: SyncOpType.moveNote,
      targetId: noteId,
      payload: {
        'old_notebook_id': oldNotebookId,
        'new_notebook_id': notebookId,
        'modified_at': saved.modifiedAt.toIso8601String(),
      },
    );

    // Invalidate related providers
    ref.invalidate(noteProvider(noteId));
    ref.invalidate(notesMetadataProvider);
    ref.invalidate(activeNotesProvider);
    ref.invalidate(notebookNotesProvider(notebookId));
    if (oldNotebookId != null) {
      ref.invalidate(notebookNotesProvider(oldNotebookId));
    }
    // Also invalidate the null notebook provider (orphan notes)
    ref.invalidate(notebookNotesProvider(null));

    return saved;
  }
}

/// Provider for note operations.
final noteOperationsProvider =
    AsyncNotifierProvider<NoteOperationsNotifier, void>(
      NoteOperationsNotifier.new,
    );
