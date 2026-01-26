// ═══════════════════════════════════════════════════════════════════════════
// FYNDO - Zero-Trust Notes OS
// Notebook Model & Providers
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fyndo_app/providers/vault_providers.dart';
import 'package:uuid/uuid.dart';

/// A notebook for organizing notes.
class Notebook extends Equatable {
  /// Unique identifier (UUID v4)
  final String id;

  /// Notebook name
  final String name;

  /// Optional description
  final String? description;

  /// Parent vault ID
  final String vaultId;

  /// Color hex code (without #)
  final String? color;

  /// Icon name
  final String? icon;

  /// Creation timestamp (UTC)
  final DateTime createdAt;

  /// Last modification timestamp (UTC)
  final DateTime modifiedAt;

  /// Whether this notebook is archived
  final bool isArchived;

  /// Note count (computed, not stored)
  final int noteCount;

  const Notebook({
    required this.id,
    required this.name,
    this.description,
    required this.vaultId,
    this.color,
    this.icon,
    required this.createdAt,
    required this.modifiedAt,
    this.isArchived = false,
    this.noteCount = 0,
  });

  /// Creates a new notebook with generated ID and timestamps.
  factory Notebook.create({
    required String name,
    required String vaultId,
    String? description,
    String? color,
    String? icon,
  }) {
    final now = DateTime.now().toUtc();
    return Notebook(
      id: const Uuid().v4(),
      name: name,
      vaultId: vaultId,
      description: description,
      color: color,
      icon: icon,
      createdAt: now,
      modifiedAt: now,
    );
  }

  Notebook copyWith({
    String? name,
    String? description,
    String? color,
    String? icon,
    bool? isArchived,
    int? noteCount,
    DateTime? modifiedAt,
  }) {
    return Notebook(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      vaultId: vaultId,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      createdAt: createdAt,
      modifiedAt: modifiedAt ?? DateTime.now().toUtc(),
      isArchived: isArchived ?? this.isArchived,
      noteCount: noteCount ?? this.noteCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'vaultId': vaultId,
      'color': color,
      'icon': icon,
      'createdAt': createdAt.toIso8601String(),
      'modifiedAt': modifiedAt.toIso8601String(),
      'isArchived': isArchived,
    };
  }

  factory Notebook.fromJson(Map<String, dynamic> json) {
    return Notebook(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      vaultId: json['vaultId'] as String,
      color: json['color'] as String?,
      icon: json['icon'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      modifiedAt: DateTime.parse(json['modifiedAt'] as String),
      isArchived: json['isArchived'] as bool? ?? false,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    vaultId,
    color,
    icon,
    createdAt,
    modifiedAt,
    isArchived,
    noteCount,
  ];
}

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
    final updated = notebook.copyWith(modifiedAt: DateTime.now().toUtc());

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
    await updateNotebook(notebook.copyWith(isArchived: true));
  }

  /// Unarchives a notebook.
  Future<void> unarchiveNotebook(String notebookId) async {
    final notebook = state.notebooks.firstWhere((n) => n.id == notebookId);
    await updateNotebook(notebook.copyWith(isArchived: false));
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
