// ═══════════════════════════════════════════════════════════════════════════
// WITFLO - Zero-Trust Notes OS
// Notebook Providers
// ═══════════════════════════════════════════════════════════════════════════

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:witflo_app/features/notes/data/notebook_repository.dart';
import 'package:witflo_app/features/notes/models/notebook.dart';
import 'package:witflo_app/providers/crypto_providers.dart';
import 'package:witflo_app/providers/note_providers.dart';
import 'package:witflo_app/providers/vault_providers.dart';

export 'package:witflo_app/features/notes/models/notebook.dart';

part 'notebook_providers.g.dart';

/// Provider for notebook repository.
///
/// Uses the unlocked active vault to create an encrypted notebook repository.
final notebookRepositoryProvider =
    FutureProvider.autoDispose<EncryptedNotebookRepository>((ref) async {
      final vault = await ref.watch(unlockedActiveVaultProvider.future);
      final crypto = ref.watch(cryptoServiceProvider);

      return EncryptedNotebookRepository(vault: vault, crypto: crypto);
    });

/// State for notebooks.
///
/// Uses built_value for immutability and type safety (spec-003 compliance).
abstract class NotebooksState
    implements Built<NotebooksState, NotebooksStateBuilder> {
  /// List of notebooks (uses BuiltList for immutability).
  BuiltList<Notebook> get notebooks;

  /// Whether notebooks are currently loading.
  bool get isLoading;

  /// Error message if loading failed.
  String? get error;

  NotebooksState._();
  factory NotebooksState([void Function(NotebooksStateBuilder) updates]) =
      _$NotebooksState;

  /// Creates initial notebooks state (empty, not loading).
  factory NotebooksState.initial() => NotebooksState(
    (b) => b
      ..notebooks = ListBuilder<Notebook>()
      ..isLoading = false
      ..error = null,
  );
}

/// Notifier for notebooks.
class NotebooksNotifier extends AsyncNotifier<NotebooksState> {
  @override
  Future<NotebooksState> build() async {
    // Load notebooks from repository on initialization
    try {
      final repo = await ref.watch(notebookRepositoryProvider.future);
      final notebooks = await repo.listAll();

      return NotebooksState(
        (b) => b
          ..notebooks = ListBuilder<Notebook>(notebooks)
          ..isLoading = false
          ..error = null,
      );
    } catch (e) {
      return NotebooksState(
        (b) => b
          ..notebooks = ListBuilder<Notebook>()
          ..isLoading = false
          ..error = e.toString(),
      );
    }
  }

  /// Loads notebooks from storage.
  Future<void> loadNotebooks() async {
    state = const AsyncValue.loading();

    try {
      final repo = await ref.read(notebookRepositoryProvider.future);
      final notebooks = await repo.listAll();

      state = AsyncValue.data(
        NotebooksState(
          (b) => b
            ..notebooks = ListBuilder<Notebook>(notebooks)
            ..isLoading = false
            ..error = null,
        ),
      );
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Creates a new notebook.
  Future<Notebook> createNotebook({
    required String name,
    String? description,
    String? color,
    String? icon,
  }) async {
    final vaultState = ref.read(vaultProvider);
    final vaultId = vaultState.vault?.header.vaultId ?? 'default';

    final notebook = Notebook.create(
      name: name,
      vaultId: vaultId,
      description: description,
      color: color,
      icon: icon,
    );

    // Save to repository
    final repo = await ref.read(notebookRepositoryProvider.future);
    final savedNotebook = await repo.save(notebook);

    // Update state
    state.whenData((currentState) {
      state = AsyncValue.data(
        currentState.rebuild((b) => b..notebooks.add(savedNotebook)),
      );
    });

    return savedNotebook;
  }

  /// Updates a notebook.
  Future<void> updateNotebook(Notebook notebook) async {
    final repo = await ref.read(notebookRepositoryProvider.future);
    final updated = await repo.save(notebook);

    state.whenData((currentState) {
      state = AsyncValue.data(
        currentState.rebuild((b) {
          final index = b.notebooks.build().indexWhere(
            (n) => n.id == notebook.id,
          );
          if (index >= 0) {
            b.notebooks[index] = updated;
          }
        }),
      );
    });
  }

  /// Deletes a notebook and all its notes.
  Future<void> deleteNotebook(String notebookId) async {
    final notebookRepo = await ref.read(notebookRepositoryProvider.future);
    final noteRepo = await ref.read(noteRepositoryProvider.future);

    // Get all notes in this notebook
    final notes = await noteRepo.listByNotebook(notebookId);

    // Delete all notes first
    for (final noteMetadata in notes) {
      await noteRepo.delete(noteMetadata.id);
    }

    // Then delete the notebook
    await notebookRepo.delete(notebookId);

    // Update state
    state.whenData((currentState) {
      state = AsyncValue.data(
        currentState.rebuild((b) {
          b.notebooks.removeWhere((n) => n.id == notebookId);
        }),
      );
    });
  }

  /// Archives a notebook.
  Future<void> archiveNotebook(String notebookId) async {
    state.whenData((currentState) async {
      final notebook = currentState.notebooks.firstWhere(
        (n) => n.id == notebookId,
      );
      await updateNotebook(notebook.rebuild((b) => b..isArchived = true));
    });
  }

  /// Unarchives a notebook.
  Future<void> unarchiveNotebook(String notebookId) async {
    state.whenData((currentState) async {
      final notebook = currentState.notebooks.firstWhere(
        (n) => n.id == notebookId,
      );
      await updateNotebook(notebook.rebuild((b) => b..isArchived = false));
    });
  }
}

/// Provider for notebooks.
final notebooksProvider =
    AsyncNotifierProvider<NotebooksNotifier, NotebooksState>(
      NotebooksNotifier.new,
    );

/// Provider for active (non-archived) notebooks.
final activeNotebooksProvider = Provider<List<Notebook>>((ref) {
  final state = ref.watch(notebooksProvider);
  return state.when(
    data: (notebooksState) =>
        notebooksState.notebooks.where((n) => !n.isArchived).toList()
          ..sort((a, b) => a.name.compareTo(b.name)),
    loading: () => [],
    error: (error, stackTrace) => [],
  );
});

/// Provider for a single notebook.
final notebookProvider = Provider.family<Notebook?, String>((ref, id) {
  final state = ref.watch(notebooksProvider);
  return state.when(
    data: (notebooksState) {
      try {
        return notebooksState.notebooks.firstWhere((n) => n.id == id);
      } catch (_) {
        return null;
      }
    },
    loading: () => null,
    error: (error, stackTrace) => null,
  );
});
