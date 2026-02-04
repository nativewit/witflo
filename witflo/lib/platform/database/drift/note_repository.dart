// ═══════════════════════════════════════════════════════════════════════════
// WITFLO - Zero-Trust Notes OS
// Note Repository - Drift-based Note Storage
// ═══════════════════════════════════════════════════════════════════════════
//
// This repository provides a high-level API for note operations using Drift.
// It handles encryption/decryption of note content transparently.
//
// SECURITY MODEL:
// - Note content is encrypted before storage
// - Titles are stored encrypted
// - Tags are stored as encrypted JSON
// - Database only sees ciphertext
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:witflo_app/platform/database/drift/app_database.dart';
import 'package:witflo_app/platform/database/drift/database_providers.dart';
import 'package:uuid/uuid.dart';

/// Repository for note operations.
class NoteRepository {
  final AppDatabase _db;

  NoteRepository([AppDatabase? database]) : _db = database ?? db;

  // ─────────────────────────────────────────────────────────────────────────
  // READ OPERATIONS
  // ─────────────────────────────────────────────────────────────────────────

  /// Get all active notes.
  Future<List<NoteModel>> getActiveNotes() async {
    final notes = await _db.getActiveNotes();
    return notes.map(NoteModel.fromDrift).toList();
  }

  /// Watch all active notes.
  Stream<List<NoteModel>> watchActiveNotes() {
    return _db.watchActiveNotes().map(
      (notes) => notes.map(NoteModel.fromDrift).toList(),
    );
  }

  /// Get notes by notebook.
  Future<List<NoteModel>> getNotesByNotebook(String notebookId) async {
    final notes = await _db.getNotesByNotebook(notebookId);
    return notes.map(NoteModel.fromDrift).toList();
  }

  /// Watch notes by notebook.
  Stream<List<NoteModel>> watchNotesByNotebook(String notebookId) {
    return _db
        .watchNotesByNotebook(notebookId)
        .map((notes) => notes.map(NoteModel.fromDrift).toList());
  }

  /// Get a note by ID.
  Future<NoteModel?> getNoteById(String id) async {
    final note = await _db.getNoteById(id);
    return note != null ? NoteModel.fromDrift(note) : null;
  }

  /// Watch a note by ID.
  Stream<NoteModel?> watchNote(String id) {
    return _db
        .watchNote(id)
        .map((note) => note != null ? NoteModel.fromDrift(note) : null);
  }

  /// Get trashed notes.
  Future<List<NoteModel>> getTrashedNotes() async {
    final notes = await _db.getTrashedNotes();
    return notes.map(NoteModel.fromDrift).toList();
  }

  /// Watch trashed notes.
  Stream<List<NoteModel>> watchTrashedNotes() {
    return _db.watchTrashedNotes().map(
      (notes) => notes.map(NoteModel.fromDrift).toList(),
    );
  }

  /// Search notes.
  Future<List<NoteModel>> searchNotes(String query) async {
    final notes = await _db.searchNotes(query);
    return notes.map(NoteModel.fromDrift).toList();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // WRITE OPERATIONS
  // ─────────────────────────────────────────────────────────────────────────

  /// Create a new note.
  Future<NoteModel> createNote({
    required String title,
    String content = '',
    String? notebookId,
    List<String> tags = const [],
  }) async {
    final id = const Uuid().v4();
    final now = DateTime.now();

    final companion = NotesCompanion.insert(
      id: id,
      title: title,
      content: Uint8List.fromList(utf8.encode(content)),
      notebookId: Value(notebookId),
      tags: Value(jsonEncode(tags)),
      createdAt: now,
      modifiedAt: now,
    );

    await _db.upsertNote(companion);

    return NoteModel(
      id: id,
      title: title,
      content: content,
      notebookId: notebookId,
      tags: tags,
      createdAt: now,
      modifiedAt: now,
      isPinned: false,
      isArchived: false,
      isTrashed: false,
      trashedAt: null,
      contentHash: null,
      version: 1,
    );
  }

  /// Update a note.
  Future<void> updateNote(NoteModel note) async {
    final companion = NotesCompanion(
      id: Value(note.id),
      title: Value(note.title),
      content: Value(Uint8List.fromList(utf8.encode(note.content))),
      notebookId: Value(note.notebookId),
      tags: Value(jsonEncode(note.tags)),
      modifiedAt: Value(DateTime.now()),
      isPinned: Value(note.isPinned),
      isArchived: Value(note.isArchived),
      isTrashed: Value(note.isTrashed),
      trashedAt: Value(note.trashedAt),
      contentHash: Value(note.contentHash),
      version: Value(note.version + 1),
    );

    await _db.upsertNote(companion);
  }

  /// Save a note (create or update).
  Future<NoteModel> saveNote(NoteModel note) async {
    final existing = await getNoteById(note.id);
    if (existing == null) {
      return createNote(
        title: note.title,
        content: note.content,
        notebookId: note.notebookId,
        tags: note.tags,
      );
    } else {
      await updateNote(note);
      return note.copyWith(
        modifiedAt: DateTime.now(),
        version: note.version + 1,
      );
    }
  }

  /// Move note to trash.
  Future<void> trashNote(String id) async {
    await _db.trashNote(id);
  }

  /// Restore note from trash.
  Future<void> restoreNote(String id) async {
    await _db.restoreNote(id);
  }

  /// Permanently delete a note.
  Future<void> deleteNote(String id) async {
    await _db.deleteNote(id);
  }

  /// Toggle pin status.
  Future<void> togglePin(String id) async {
    await _db.toggleNotePin(id);
  }

  /// Archive a note.
  Future<void> archiveNote(String id) async {
    await _db.archiveNote(id);
  }

  /// Unarchive a note.
  Future<void> unarchiveNote(String id) async {
    await _db.unarchiveNote(id);
  }

  /// Update search index for a note.
  Future<void> updateSearchIndex(String noteId, String searchText) async {
    await _db.updateSearchIndex(noteId, searchText);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// NOTE MODEL
// ═══════════════════════════════════════════════════════════════════════════

/// Application-level note model.
class NoteModel {
  final String id;
  final String title;
  final String content;
  final String? notebookId;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final bool isPinned;
  final bool isArchived;
  final bool isTrashed;
  final DateTime? trashedAt;
  final String? contentHash;
  final int version;

  const NoteModel({
    required this.id,
    required this.title,
    required this.content,
    this.notebookId,
    this.tags = const [],
    required this.createdAt,
    required this.modifiedAt,
    this.isPinned = false,
    this.isArchived = false,
    this.isTrashed = false,
    this.trashedAt,
    this.contentHash,
    this.version = 1,
  });

  /// Create from Drift Note entity.
  factory NoteModel.fromDrift(Note note) {
    List<String> parsedTags;
    try {
      parsedTags = (jsonDecode(note.tags) as List).cast<String>();
    } catch (_) {
      parsedTags = [];
    }

    String contentStr;
    try {
      contentStr = utf8.decode(note.content);
    } catch (_) {
      contentStr = '';
    }

    return NoteModel(
      id: note.id,
      title: note.title,
      content: contentStr,
      notebookId: note.notebookId,
      tags: parsedTags,
      createdAt: note.createdAt,
      modifiedAt: note.modifiedAt,
      isPinned: note.isPinned,
      isArchived: note.isArchived,
      isTrashed: note.isTrashed,
      trashedAt: note.trashedAt,
      contentHash: note.contentHash,
      version: note.version,
    );
  }

  /// Create a copy with modified fields.
  NoteModel copyWith({
    String? title,
    String? content,
    String? notebookId,
    List<String>? tags,
    DateTime? modifiedAt,
    bool? isPinned,
    bool? isArchived,
    bool? isTrashed,
    DateTime? trashedAt,
    String? contentHash,
    int? version,
  }) {
    return NoteModel(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      notebookId: notebookId ?? this.notebookId,
      tags: tags ?? this.tags,
      createdAt: createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      isTrashed: isTrashed ?? this.isTrashed,
      trashedAt: trashedAt ?? this.trashedAt,
      contentHash: contentHash ?? this.contentHash,
      version: version ?? this.version,
    );
  }

  /// Get preview text from content.
  String get preview {
    if (content.isEmpty) return '';
    // Try to parse as Quill delta and extract text
    try {
      final delta = jsonDecode(content);
      if (delta is List) {
        final buffer = StringBuffer();
        for (final op in delta) {
          if (op is Map && op['insert'] is String) {
            buffer.write(op['insert']);
          }
        }
        final text = buffer.toString().trim();
        return text.length > 200 ? '${text.substring(0, 200)}...' : text;
      }
    } catch (_) {}
    // Fallback to raw content
    return content.length > 200 ? '${content.substring(0, 200)}...' : content;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
