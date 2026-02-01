// ═══════════════════════════════════════════════════════════════════════════
// FYNDO - Zero-Trust Notes OS
// Notebook Providers
// ═══════════════════════════════════════════════════════════════════════════

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fyndo_app/features/notes/models/notebook.dart';
import 'package:fyndo_app/providers/vault_providers.dart';

export 'package:fyndo_app/features/notes/models/notebook.dart';

part 'notebook_providers.g.dart';

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
class NotebooksNotifier extends Notifier<NotebooksState> {
  @override
  NotebooksState build() {
    return NotebooksState.initial();
  }

  /// Loads notebooks from storage.
  Future<void> loadNotebooks() async {
    state = state.rebuild(
      (b) => b
        ..isLoading = true
        ..error = null,
    );

    try {
      // TODO: Load from encrypted storage
      // For now, using in-memory storage
      state = state.rebuild((b) => b..isLoading = false);
    } catch (e) {
      state = state.rebuild(
        (b) => b
          ..isLoading = false
          ..error = e.toString(),
      );
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

    state = state.rebuild((b) => b..notebooks.add(notebook));

    // TODO: Persist to encrypted storage
    return notebook;
  }

  /// Updates a notebook.
  Future<void> updateNotebook(Notebook notebook) async {
    final updated = notebook.rebuild(
      (b) => b..modifiedAt = DateTime.now().toUtc(),
    );

    state = state.rebuild((b) {
      final index = b.notebooks.build().indexWhere((n) => n.id == notebook.id);
      if (index >= 0) {
        b.notebooks[index] = updated;
      }
    });

    // TODO: Persist to encrypted storage
  }

  /// Deletes a notebook.
  Future<void> deleteNotebook(String notebookId) async {
    state = state.rebuild((b) {
      b.notebooks.removeWhere((n) => n.id == notebookId);
    });

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
