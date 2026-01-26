// ═══════════════════════════════════════════════════════════════════════════
// FYNDO - Zero-Trust Notes OS
// Notebook Providers
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fyndo_app/features/notes/models/notebook.dart';
import 'package:fyndo_app/providers/vault_providers.dart';

export 'package:fyndo_app/features/notes/models/notebook.dart';

/// State for notebooks.
class NotebooksState {
  final List<Notebook> notebooks;
  final bool isLoading;
  final String? error;

  const NotebooksState({
    this.notebooks = const [],
    this.isLoading = false,
    this.error,
  });

  NotebooksState copyWith({
    List<Notebook>? notebooks,
    bool? isLoading,
    String? error,
  }) {
    return NotebooksState(
      notebooks: notebooks ?? this.notebooks,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for notebooks.
class NotebooksNotifier extends Notifier<NotebooksState> {
  @override
  NotebooksState build() {
    return const NotebooksState();
  }

  /// Loads notebooks from storage.
  Future<void> loadNotebooks() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // TODO: Load from encrypted storage
      // For now, using in-memory storage
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
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

    state = state.copyWith(notebooks: [...state.notebooks, notebook]);

    // TODO: Persist to encrypted storage
    return notebook;
  }

  /// Updates a notebook.
  Future<void> updateNotebook(Notebook notebook) async {
    final updated = notebook.rebuild(
      (b) => b..modifiedAt = DateTime.now().toUtc(),
    );

    state = state.copyWith(
      notebooks: state.notebooks
          .map((n) => n.id == notebook.id ? updated : n)
          .toList(),
    );

    // TODO: Persist to encrypted storage
  }

  /// Deletes a notebook.
  Future<void> deleteNotebook(String notebookId) async {
    state = state.copyWith(
      notebooks: state.notebooks.where((n) => n.id != notebookId).toList(),
    );

    // TODO: Delete from encrypted storage
  }

  /// Archives a notebook.
  Future<void> archiveNotebook(String notebookId) async {
    final notebook = state.notebooks.firstWhere((n) => n.id == notebookId);
    await updateNotebook(notebook.rebuild((b) => b..isArchived = true));
  }

  /// Unarchives a notebook.
  Future<void> unarchiveNotebook(String notebookId) async {
    final notebook = state.notebooks.firstWhere((n) => n.id == notebookId);
    await updateNotebook(notebook.rebuild((b) => b..isArchived = false));
  }
}

/// Provider for notebooks.
final notebooksProvider = NotifierProvider<NotebooksNotifier, NotebooksState>(
  NotebooksNotifier.new,
);

/// Provider for active (non-archived) notebooks.
final activeNotebooksProvider = Provider<List<Notebook>>((ref) {
  final state = ref.watch(notebooksProvider);
  return state.notebooks.where((n) => !n.isArchived).toList()
    ..sort((a, b) => a.name.compareTo(b.name));
});

/// Provider for a single notebook.
final notebookProvider = Provider.family<Notebook?, String>((ref, id) {
  final state = ref.watch(notebooksProvider);
  try {
    return state.notebooks.firstWhere((n) => n.id == id);
  } catch (_) {
    return null;
  }
});
