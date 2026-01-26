// ═══════════════════════════════════════════════════════════════════════════
// FYNDO - Zero-Trust Notes OS
// Note Model - Core Note Data Structure (built_value)
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

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:uuid/uuid.dart';

part 'note.g.dart';

/// A note in Fyndo.
abstract class Note implements Built<Note, NoteBuilder> {
  static Serializer<Note> get serializer => _$noteSerializer;

  /// Unique identifier (UUID v4)
  String get id;

  /// Note title (encrypted)
  String get title;

  /// Note content in markdown (encrypted)
  String get content;

  /// Parent notebook ID (null for root)
  String? get notebookId;

  /// Tags for organization
  BuiltList<String> get tags;

  /// Creation timestamp (UTC)
  DateTime get createdAt;

  /// Last modification timestamp (UTC)
  DateTime get modifiedAt;

  /// Whether this note is pinned
  bool get isPinned;

  /// Whether this note is archived
  bool get isArchived;

  /// Whether this note is in trash
  bool get isTrashed;

  /// Trash timestamp (for auto-delete)
  DateTime? get trashedAt;

  /// Content hash for sync/dedup (hash of encrypted content)
  String? get contentHash;

  /// Version for conflict resolution
  int get version;

  Note._();
  factory Note([void Function(NoteBuilder) updates]) = _$Note;

  /// Creates a new note with generated ID and timestamps.
  factory Note.create({
    required String title,
    required String content,
    String? notebookId,
    List<String> tags = const [],
  }) {
    final now = DateTime.now().toUtc();
    return Note(
      (b) => b
        ..id = const Uuid().v4()
        ..title = title
        ..content = content
        ..notebookId = notebookId
        ..tags = ListBuilder<String>(tags)
        ..createdAt = now
        ..modifiedAt = now
        ..isPinned = false
        ..isArchived = false
        ..isTrashed = false
        ..version = 1,
    );
  }

  /// Moves note to trash.
  Note trash() {
    return rebuild(
      (b) => b
        ..isTrashed = true
        ..trashedAt = DateTime.now().toUtc()
        ..modifiedAt = DateTime.now().toUtc()
        ..version = version + 1,
    );
  }

  /// Restores note from trash.
  Note restore() {
    return rebuild(
      (b) => b
        ..isTrashed = false
        ..trashedAt = null
        ..modifiedAt = DateTime.now().toUtc()
        ..version = version + 1,
    );
  }

  /// Archives the note.
  Note archive() {
    return rebuild(
      (b) => b
        ..isArchived = true
        ..modifiedAt = DateTime.now().toUtc()
        ..version = version + 1,
    );
  }

  /// Unarchives the note.
  Note unarchive() {
    return rebuild(
      (b) => b
        ..isArchived = false
        ..modifiedAt = DateTime.now().toUtc()
        ..version = version + 1,
    );
  }

  /// Creates a copy with updated fields (convenience wrapper around rebuild).
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
    return rebuild(
      (b) => b
        ..title = title ?? this.title
        ..content = content ?? this.content
        ..notebookId = notebookId ?? this.notebookId
        ..tags = (tags != null
            ? ListBuilder<String>(tags)
            : this.tags.toBuilder())
        ..modifiedAt = modifiedAt ?? DateTime.now().toUtc()
        ..isPinned = isPinned ?? this.isPinned
        ..isArchived = isArchived ?? this.isArchived
        ..isTrashed = isTrashed ?? this.isTrashed
        ..trashedAt = trashedAt ?? this.trashedAt
        ..contentHash = contentHash ?? this.contentHash
        ..version = version ?? this.version + 1,
    );
  }

  /// Serializes to JSON (for encryption).
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'notebook_id': notebookId,
    'tags': tags.toList(),
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
  static Note fromJson(Map<String, dynamic> json) {
    return Note(
      (b) => b
        ..id = json['id'] as String
        ..title = json['title'] as String
        ..content = json['content'] as String
        ..notebookId = json['notebook_id'] as String?
        ..tags = ListBuilder<String>(
          (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
        )
        ..createdAt = DateTime.parse(json['created_at'] as String)
        ..modifiedAt = DateTime.parse(json['modified_at'] as String)
        ..isPinned = json['is_pinned'] as bool? ?? false
        ..isArchived = json['is_archived'] as bool? ?? false
        ..isTrashed = json['is_trashed'] as bool? ?? false
        ..trashedAt = json['trashed_at'] != null
            ? DateTime.parse(json['trashed_at'] as String)
            : null
        ..contentHash = json['content_hash'] as String?
        ..version = json['version'] as int? ?? 1,
    );
  }

  /// Deserializes from bytes (after decryption).
  static Note fromBytes(Uint8List bytes) {
    final json = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    return Note.fromJson(json);
  }

  @override
  String toString() => 'Note(id=$id, title="$title", v$version)';
}

/// Metadata for a note (for index storage).
/// Contains only enough info to display in list view.
abstract class NoteMetadata
    implements Built<NoteMetadata, NoteMetadataBuilder> {
  static Serializer<NoteMetadata> get serializer => _$noteMetadataSerializer;

  String get id;
  String get title;
  String? get notebookId;
  BuiltList<String> get tags;
  DateTime get createdAt;
  DateTime get modifiedAt;
  bool get isPinned;
  bool get isArchived;
  bool get isTrashed;
  String? get contentHash;
  int get version;

  /// Preview text (first ~100 chars of content)
  String? get preview;

  NoteMetadata._();
  factory NoteMetadata([void Function(NoteMetadataBuilder) updates]) =
      _$NoteMetadata;

  /// Creates metadata from a full note.
  static NoteMetadata fromNote(Note note, {int previewLength = 100}) {
    return NoteMetadata(
      (b) => b
        ..id = note.id
        ..title = note.title
        ..notebookId = note.notebookId
        ..tags = note.tags.toBuilder()
        ..createdAt = note.createdAt
        ..modifiedAt = note.modifiedAt
        ..isPinned = note.isPinned
        ..isArchived = note.isArchived
        ..isTrashed = note.isTrashed
        ..contentHash = note.contentHash
        ..version = note.version
        ..preview = note.content.length > previewLength
            ? note.content.substring(0, previewLength)
            : note.content,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'notebook_id': notebookId,
    'tags': tags.toList(),
    'created_at': createdAt.toIso8601String(),
    'modified_at': modifiedAt.toIso8601String(),
    'is_pinned': isPinned,
    'is_archived': isArchived,
    'is_trashed': isTrashed,
    'content_hash': contentHash,
    'version': version,
    'preview': preview,
  };

  static NoteMetadata fromJson(Map<String, dynamic> json) {
    return NoteMetadata(
      (b) => b
        ..id = json['id'] as String
        ..title = json['title'] as String
        ..notebookId = json['notebook_id'] as String?
        ..tags = ListBuilder<String>(
          (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
        )
        ..createdAt = DateTime.parse(json['created_at'] as String)
        ..modifiedAt = DateTime.parse(json['modified_at'] as String)
        ..isPinned = json['is_pinned'] as bool? ?? false
        ..isArchived = json['is_archived'] as bool? ?? false
        ..isTrashed = json['is_trashed'] as bool? ?? false
        ..contentHash = json['content_hash'] as String?
        ..version = json['version'] as int? ?? 1
        ..preview = json['preview'] as String?,
    );
  }
}
