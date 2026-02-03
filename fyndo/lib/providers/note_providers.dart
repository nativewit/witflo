// ═══════════════════════════════════════════════════════════════════════════
// FYNDO - Zero-Trust Notes OS
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
import 'package:fyndo_app/core/core.dart';
import 'package:fyndo_app/core/logging/app_logger.dart';
import 'package:fyndo_app/features/notes/data/note_repository.dart';
import 'package:fyndo_app/features/notes/models/note.dart';
import 'package:fyndo_app/providers/crypto_providers.dart';
import 'package:fyndo_app/providers/unlocked_workspace_provider.dart';
import 'package:fyndo_app/providers/vault_providers.dart';
import 'package:fyndo_app/providers/vault_selection_providers.dart';
import 'package:path/path.dart' as p;

// Re-export activeVaultIdProvider for backward compatibility
export 'package:fyndo_app/providers/vault_selection_providers.dart'
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
final activeNotesProvider = FutureProvider<List<NoteMetadata>>((ref) async {
  final repo = await ref.watch(noteRepositoryProvider.future);
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
  final repo = await ref.watch(noteRepositoryProvider.future);
  return repo.listTrashed();
});

/// Provider for archived notes.
final archivedNotesProvider = FutureProvider<List<NoteMetadata>>((ref) async {
  final repo = await ref.watch(noteRepositoryProvider.future);
  final all = await repo.listAll();
  return all.where((n) => n.isArchived && !n.isTrashed).toList()
    ..sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
});

/// Provider for notes in a specific notebook.
final notebookNotesProvider =
    FutureProvider.family<List<NoteMetadata>, String?>((ref, notebookId) async {
      final repo = await ref.watch(noteRepositoryProvider.future);
      return repo.listByNotebook(notebookId);
    });

/// Provider for notes with a specific tag.
final tagNotesProvider = FutureProvider.family<List<NoteMetadata>, String>((
  ref,
  tag,
) async {
  final repo = await ref.watch(noteRepositoryProvider.future);
  return repo.listByTag(tag);
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
  @override
  Future<void> build() async {}

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
    final repo = await ref.read(noteRepositoryProvider.future);
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
    final repo = await ref.read(noteRepositoryProvider.future);
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
    final repo = await ref.read(noteRepositoryProvider.future);
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
    final repo = await ref.read(noteRepositoryProvider.future);
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
    final repo = await ref.read(noteRepositoryProvider.future);
    final note = await repo.load(noteId);
    if (note != null) {
      await repo.save(note.copyWith(isPinned: !note.isPinned));

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
      await repo.save(note.archive());

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
      await repo.save(note.unarchive());

      ref.invalidate(noteProvider(noteId));
      ref.invalidate(notesMetadataProvider);
      ref.invalidate(activeNotesProvider);
      ref.invalidate(noteStatsProvider);
      if (note.notebookId != null) {
        ref.invalidate(notebookNotesProvider(note.notebookId));
      }
    }
  }
}

/// Provider for note operations.
final noteOperationsProvider =
    AsyncNotifierProvider<NoteOperationsNotifier, void>(
      NoteOperationsNotifier.new,
    );
