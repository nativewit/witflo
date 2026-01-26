// ═══════════════════════════════════════════════════════════════════════════
// FYNDO - Zero-Trust Notes OS
// Note Model - Core Note Data Structure
// ═══════════════════════════════════════════════════════════════════════════
//
// SECURITY MODEL:
// - Note content is always encrypted at rest
// - Note ID is a UUID (not derived from content)
// - Metadata (title, tags) is also encrypted
// - Only ciphertext hashes are used for storage paths
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

/// A note in Fyndo.
class Note extends Equatable {
  /// Unique identifier (UUID v4)
  final String id;

  /// Note title (encrypted)
  final String title;

  /// Note content in markdown (encrypted)
  final String content;

  /// Parent notebook ID (null for root)
  final String? notebookId;

  /// Tags for organization
  final List<String> tags;

  /// Creation timestamp (UTC)
  final DateTime createdAt;

  /// Last modification timestamp (UTC)
  final DateTime modifiedAt;

  /// Whether this note is pinned
  final bool isPinned;

  /// Whether this note is archived
  final bool isArchived;

  /// Whether this note is in trash
  final bool isTrashed;

  /// Trash timestamp (for auto-delete)
  final DateTime? trashedAt;

  /// Content hash for sync/dedup (hash of encrypted content)
  final String? contentHash;

  /// Version for conflict resolution
  final int version;

  const Note({
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

  /// Creates a new note with generated ID and timestamps.
  factory Note.create({
    required String title,
    required String content,
    String? notebookId,
    List<String> tags = const [],
  }) {
    final now = DateTime.now().toUtc();
    return Note(
      id: const Uuid().v4(),
      title: title,
      content: content,
      notebookId: notebookId,
      tags: tags,
      createdAt: now,
      modifiedAt: now,
    );
  }

  /// Creates a copy with updated fields.
  Note copyWith({
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
    return Note(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      notebookId: notebookId ?? this.notebookId,
      tags: tags ?? this.tags,
      createdAt: createdAt,
      modifiedAt: modifiedAt ?? DateTime.now().toUtc(),
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      isTrashed: isTrashed ?? this.isTrashed,
      trashedAt: trashedAt ?? this.trashedAt,
      contentHash: contentHash ?? this.contentHash,
      version: version ?? this.version + 1,
    );
  }

  /// Moves note to trash.
  Note trash() {
    return copyWith(isTrashed: true, trashedAt: DateTime.now().toUtc());
  }

  /// Restores note from trash.
  Note restore() {
    return Note(
      id: id,
      title: title,
      content: content,
      notebookId: notebookId,
      tags: tags,
      createdAt: createdAt,
      modifiedAt: DateTime.now().toUtc(),
      isPinned: isPinned,
      isArchived: isArchived,
      isTrashed: false,
      trashedAt: null,
      contentHash: contentHash,
      version: version + 1,
    );
  }

  /// Archives the note.
  Note archive() {
    return copyWith(isArchived: true);
  }

  /// Unarchives the note.
  Note unarchive() {
    return copyWith(isArchived: false);
  }

  /// Serializes to JSON (for encryption).
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'notebook_id': notebookId,
    'tags': tags,
    'created_at': createdAt.toIso8601String(),
    'modified_at': modifiedAt.toIso8601String(),
    'is_pinned': isPinned,
    'is_archived': isArchived,
    'is_trashed': isTrashed,
    'trashed_at': trashedAt?.toIso8601String(),
    'content_hash': contentHash,
    'version': version,
  };

  /// Serializes to bytes (for encryption).
  Uint8List toBytes() {
    return Uint8List.fromList(utf8.encode(jsonEncode(toJson())));
  }

  /// Deserializes from JSON.
  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      notebookId: json['notebook_id'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      createdAt: DateTime.parse(json['created_at'] as String),
      modifiedAt: DateTime.parse(json['modified_at'] as String),
      isPinned: json['is_pinned'] as bool? ?? false,
      isArchived: json['is_archived'] as bool? ?? false,
      isTrashed: json['is_trashed'] as bool? ?? false,
      trashedAt: json['trashed_at'] != null
          ? DateTime.parse(json['trashed_at'] as String)
          : null,
      contentHash: json['content_hash'] as String?,
      version: json['version'] as int? ?? 1,
    );
  }

  /// Deserializes from bytes (after decryption).
  factory Note.fromBytes(Uint8List bytes) {
    final json = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    return Note.fromJson(json);
  }

  @override
  List<Object?> get props => [
    id,
    title,
    content,
    notebookId,
    tags,
    createdAt,
    modifiedAt,
    isPinned,
    isArchived,
    isTrashed,
    trashedAt,
    version,
  ];

  @override
  String toString() => 'Note(id=$id, title="$title", v$version)';
}

/// Metadata for a note (for index storage).
/// Contains only enough info to display in list view.
class NoteMetadata extends Equatable {
  final String id;
  final String title;
  final String? notebookId;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final bool isPinned;
  final bool isArchived;
  final bool isTrashed;
  final String? contentHash;
  final int version;

  /// Preview text (first ~100 chars of content)
  final String? preview;

  const NoteMetadata({
    required this.id,
    required this.title,
    this.notebookId,
    this.tags = const [],
    required this.createdAt,
    required this.modifiedAt,
    this.isPinned = false,
    this.isArchived = false,
    this.isTrashed = false,
    this.contentHash,
    this.version = 1,
    this.preview,
  });

  /// Creates metadata from a full note.
  factory NoteMetadata.fromNote(Note note, {int previewLength = 100}) {
    return NoteMetadata(
      id: note.id,
      title: note.title,
      notebookId: note.notebookId,
      tags: note.tags,
      createdAt: note.createdAt,
      modifiedAt: note.modifiedAt,
      isPinned: note.isPinned,
      isArchived: note.isArchived,
      isTrashed: note.isTrashed,
      contentHash: note.contentHash,
      version: note.version,
      preview: note.content.length > previewLength
          ? note.content.substring(0, previewLength)
          : note.content,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'notebook_id': notebookId,
    'tags': tags,
    'created_at': createdAt.toIso8601String(),
    'modified_at': modifiedAt.toIso8601String(),
    'is_pinned': isPinned,
    'is_archived': isArchived,
    'is_trashed': isTrashed,
    'content_hash': contentHash,
    'version': version,
    'preview': preview,
  };

  factory NoteMetadata.fromJson(Map<String, dynamic> json) {
    return NoteMetadata(
      id: json['id'] as String,
      title: json['title'] as String,
      notebookId: json['notebook_id'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      createdAt: DateTime.parse(json['created_at'] as String),
      modifiedAt: DateTime.parse(json['modified_at'] as String),
      isPinned: json['is_pinned'] as bool? ?? false,
      isArchived: json['is_archived'] as bool? ?? false,
      isTrashed: json['is_trashed'] as bool? ?? false,
      contentHash: json['content_hash'] as String?,
      version: json['version'] as int? ?? 1,
      preview: json['preview'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, version];
}
