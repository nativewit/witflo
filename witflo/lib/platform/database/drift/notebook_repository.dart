// ═══════════════════════════════════════════════════════════════════════════
// WITFLO - Zero-Trust Notes OS
// Notebook Repository - Drift-based Notebook Storage
// ═══════════════════════════════════════════════════════════════════════════

import 'package:drift/drift.dart';
import 'package:witflo_app/platform/database/drift/app_database.dart';
import 'package:witflo_app/platform/database/drift/database_providers.dart';
import 'package:uuid/uuid.dart';

/// Repository for notebook operations.
class NotebookRepository {
  final AppDatabase _db;

  NotebookRepository([AppDatabase? database]) : _db = database ?? db;

  // ─────────────────────────────────────────────────────────────────────────
  // READ OPERATIONS
  // ─────────────────────────────────────────────────────────────────────────

  /// Get all notebooks.
  Future<List<NotebookModel>> getAllNotebooks() async {
    final notebooks = await _db.getAllNotebooks();
    return notebooks.map(NotebookModel.fromDrift).toList();
  }

  /// Watch all notebooks.
  Stream<List<NotebookModel>> watchAllNotebooks() {
    return _db.watchAllNotebooks().map(
      (notebooks) => notebooks.map(NotebookModel.fromDrift).toList(),
    );
  }

  /// Get a notebook by ID.
  Future<NotebookModel?> getNotebookById(String id) async {
    final notebook = await _db.getNotebookById(id);
    return notebook != null ? NotebookModel.fromDrift(notebook) : null;
  }

  /// Watch a notebook.
  Stream<NotebookModel?> watchNotebook(String id) {
    return _db
        .watchNotebook(id)
        .map(
          (notebook) =>
              notebook != null ? NotebookModel.fromDrift(notebook) : null,
        );
  }

  /// Get note count for a notebook.
  Future<int> getNoteCount(String notebookId) {
    return _db.getNoteCount(notebookId);
  }

  /// Get all note counts.
  Future<Map<String, int>> getAllNoteCounts() {
    return _db.getAllNoteCounts();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // WRITE OPERATIONS
  // ─────────────────────────────────────────────────────────────────────────

  /// Create a new notebook.
  Future<NotebookModel> createNotebook({
    required String name,
    required String vaultId,
    String? description,
    String? color,
    String? icon,
  }) async {
    final id = const Uuid().v4();
    final now = DateTime.now();

    final companion = NotebooksCompanion.insert(
      id: id,
      name: name,
      description: Value(description),
      vaultId: vaultId,
      color: Value(color),
      icon: Value(icon),
      createdAt: now,
      modifiedAt: now,
    );

    await _db.upsertNotebook(companion);

    return NotebookModel(
      id: id,
      name: name,
      description: description,
      vaultId: vaultId,
      color: color,
      icon: icon,
      createdAt: now,
      modifiedAt: now,
      isArchived: false,
      noteCount: 0,
    );
  }

  /// Update a notebook.
  Future<void> updateNotebook(NotebookModel notebook) async {
    final companion = NotebooksCompanion(
      id: Value(notebook.id),
      name: Value(notebook.name),
      description: Value(notebook.description),
      color: Value(notebook.color),
      icon: Value(notebook.icon),
      modifiedAt: Value(DateTime.now()),
      isArchived: Value(notebook.isArchived),
    );

    await _db.upsertNotebook(companion);
  }

  /// Delete a notebook.
  Future<void> deleteNotebook(String id, {bool deleteNotes = false}) async {
    await _db.deleteNotebook(id, deleteNotes: deleteNotes);
  }

  /// Archive a notebook.
  Future<void> archiveNotebook(String id) async {
    await _db.archiveNotebook(id);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// NOTEBOOK MODEL
// ═══════════════════════════════════════════════════════════════════════════

/// Application-level notebook model.
class NotebookModel {
  final String id;
  final String name;
  final String? description;
  final String vaultId;
  final String? color;
  final String? icon;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final bool isArchived;
  final int noteCount;

  const NotebookModel({
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

  /// Create from Drift Notebook entity.
  factory NotebookModel.fromDrift(Notebook notebook, [int noteCount = 0]) {
    return NotebookModel(
      id: notebook.id,
      name: notebook.name,
      description: notebook.description,
      vaultId: notebook.vaultId,
      color: notebook.color,
      icon: notebook.icon,
      createdAt: notebook.createdAt,
      modifiedAt: notebook.modifiedAt,
      isArchived: notebook.isArchived,
      noteCount: noteCount,
    );
  }

  /// Create a copy with modified fields.
  NotebookModel copyWith({
    String? name,
    String? description,
    String? color,
    String? icon,
    DateTime? modifiedAt,
    bool? isArchived,
    int? noteCount,
  }) {
    return NotebookModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      vaultId: vaultId,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      createdAt: createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      isArchived: isArchived ?? this.isArchived,
      noteCount: noteCount ?? this.noteCount,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotebookModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
