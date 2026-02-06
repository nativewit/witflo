// ═══════════════════════════════════════════════════════════════════════════
// WITFLO - Zero-Trust Notes OS
// Sync Payloads - Type-Safe Payload Structures for Sync Operations
// ═══════════════════════════════════════════════════════════════════════════
//
// This file defines the payload structures for different sync operation types.
// Each payload is a strongly-typed structure that can be serialized to/from JSON.
//
// PAYLOAD TYPES:
// - CreateNotePayload: Data for creating a new note
// - UpdateNotePayload: Data for updating an existing note
// - DeleteNotePayload: Data for deleting a note
// - MoveNotePayload: Data for moving a note to a different notebook
// - CreateNotebookPayload: Data for creating a new notebook
// - UpdateNotebookPayload: Data for updating an existing notebook
// - DeleteNotebookPayload: Data for deleting a notebook
// ═══════════════════════════════════════════════════════════════════════════

import 'package:witflo_app/features/notes/models/note.dart';
import 'package:witflo_app/features/notes/models/notebook.dart';

/// Payload for CreateNote operation.
class CreateNotePayload {
  final String noteId;
  final String title;
  final String content;
  final String? notebookId;
  final List<String> tags;
  final bool isPinned;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime modifiedAt;

  CreateNotePayload({
    required this.noteId,
    required this.title,
    required this.content,
    this.notebookId,
    this.tags = const [],
    this.isPinned = false,
    this.isArchived = false,
    required this.createdAt,
    required this.modifiedAt,
  });

  factory CreateNotePayload.fromNote(Note note) {
    return CreateNotePayload(
      noteId: note.id,
      title: note.title,
      content: note.content,
      notebookId: note.notebookId,
      tags: note.tags.toList(),
      isPinned: note.isPinned,
      isArchived: note.isArchived,
      createdAt: note.createdAt,
      modifiedAt: note.modifiedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'note_id': noteId,
    'title': title,
    'content': content,
    'notebook_id': notebookId,
    'tags': tags,
    'is_pinned': isPinned,
    'is_archived': isArchived,
    'created_at': createdAt.toIso8601String(),
    'modified_at': modifiedAt.toIso8601String(),
  };

  factory CreateNotePayload.fromJson(Map<String, dynamic> json) {
    return CreateNotePayload(
      noteId: json['note_id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      notebookId: json['notebook_id'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      isPinned: json['is_pinned'] as bool? ?? false,
      isArchived: json['is_archived'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      modifiedAt: DateTime.parse(json['modified_at'] as String),
    );
  }
}

/// Payload for UpdateNote operation.
class UpdateNotePayload {
  final String noteId;
  final String? title;
  final String? content;
  final String? notebookId;
  final List<String>? tags;
  final bool? isPinned;
  final bool? isArchived;
  final bool? isTrashed;
  final DateTime modifiedAt;

  UpdateNotePayload({
    required this.noteId,
    this.title,
    this.content,
    this.notebookId,
    this.tags,
    this.isPinned,
    this.isArchived,
    this.isTrashed,
    required this.modifiedAt,
  });

  Map<String, dynamic> toJson() => {
    'note_id': noteId,
    if (title != null) 'title': title,
    if (content != null) 'content': content,
    if (notebookId != null) 'notebook_id': notebookId,
    if (tags != null) 'tags': tags,
    if (isPinned != null) 'is_pinned': isPinned,
    if (isArchived != null) 'is_archived': isArchived,
    if (isTrashed != null) 'is_trashed': isTrashed,
    'modified_at': modifiedAt.toIso8601String(),
  };

  factory UpdateNotePayload.fromJson(Map<String, dynamic> json) {
    return UpdateNotePayload(
      noteId: json['note_id'] as String,
      title: json['title'] as String?,
      content: json['content'] as String?,
      notebookId: json['notebook_id'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>(),
      isPinned: json['is_pinned'] as bool?,
      isArchived: json['is_archived'] as bool?,
      isTrashed: json['is_trashed'] as bool?,
      modifiedAt: DateTime.parse(json['modified_at'] as String),
    );
  }
}

/// Payload for DeleteNote operation.
class DeleteNotePayload {
  final String noteId;
  final DateTime deletedAt;

  DeleteNotePayload({required this.noteId, required this.deletedAt});

  Map<String, dynamic> toJson() => {
    'note_id': noteId,
    'deleted_at': deletedAt.toIso8601String(),
  };

  factory DeleteNotePayload.fromJson(Map<String, dynamic> json) {
    return DeleteNotePayload(
      noteId: json['note_id'] as String,
      deletedAt: DateTime.parse(json['deleted_at'] as String),
    );
  }
}

/// Payload for MoveNote operation.
class MoveNotePayload {
  final String noteId;
  final String? oldNotebookId;
  final String? newNotebookId;
  final DateTime movedAt;

  MoveNotePayload({
    required this.noteId,
    this.oldNotebookId,
    this.newNotebookId,
    required this.movedAt,
  });

  Map<String, dynamic> toJson() => {
    'note_id': noteId,
    'old_notebook_id': oldNotebookId,
    'new_notebook_id': newNotebookId,
    'moved_at': movedAt.toIso8601String(),
  };

  factory MoveNotePayload.fromJson(Map<String, dynamic> json) {
    return MoveNotePayload(
      noteId: json['note_id'] as String,
      oldNotebookId: json['old_notebook_id'] as String?,
      newNotebookId: json['new_notebook_id'] as String?,
      movedAt: DateTime.parse(json['moved_at'] as String),
    );
  }
}

/// Payload for CreateNotebook operation.
class CreateNotebookPayload {
  final String notebookId;
  final String name;
  final String? description;
  final String? color;
  final String? icon;
  final DateTime createdAt;
  final DateTime modifiedAt;

  CreateNotebookPayload({
    required this.notebookId,
    required this.name,
    this.description,
    this.color,
    this.icon,
    required this.createdAt,
    required this.modifiedAt,
  });

  factory CreateNotebookPayload.fromNotebook(Notebook notebook) {
    return CreateNotebookPayload(
      notebookId: notebook.id,
      name: notebook.name,
      description: notebook.description,
      color: notebook.color,
      icon: notebook.icon,
      createdAt: notebook.createdAt,
      modifiedAt: notebook.modifiedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'notebook_id': notebookId,
    'name': name,
    'description': description,
    'color': color,
    'icon': icon,
    'created_at': createdAt.toIso8601String(),
    'modified_at': modifiedAt.toIso8601String(),
  };

  factory CreateNotebookPayload.fromJson(Map<String, dynamic> json) {
    return CreateNotebookPayload(
      notebookId: json['notebook_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      color: json['color'] as String?,
      icon: json['icon'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      modifiedAt: DateTime.parse(json['modified_at'] as String),
    );
  }
}

/// Payload for UpdateNotebook operation.
class UpdateNotebookPayload {
  final String notebookId;
  final String? name;
  final String? description;
  final String? color;
  final String? icon;
  final bool? isArchived;
  final DateTime modifiedAt;

  UpdateNotebookPayload({
    required this.notebookId,
    this.name,
    this.description,
    this.color,
    this.icon,
    this.isArchived,
    required this.modifiedAt,
  });

  Map<String, dynamic> toJson() => {
    'notebook_id': notebookId,
    if (name != null) 'name': name,
    if (description != null) 'description': description,
    if (color != null) 'color': color,
    if (icon != null) 'icon': icon,
    if (isArchived != null) 'is_archived': isArchived,
    'modified_at': modifiedAt.toIso8601String(),
  };

  factory UpdateNotebookPayload.fromJson(Map<String, dynamic> json) {
    return UpdateNotebookPayload(
      notebookId: json['notebook_id'] as String,
      name: json['name'] as String?,
      description: json['description'] as String?,
      color: json['color'] as String?,
      icon: json['icon'] as String?,
      isArchived: json['is_archived'] as bool?,
      modifiedAt: DateTime.parse(json['modified_at'] as String),
    );
  }
}

/// Payload for DeleteNotebook operation.
class DeleteNotebookPayload {
  final String notebookId;
  final DateTime deletedAt;

  DeleteNotebookPayload({required this.notebookId, required this.deletedAt});

  Map<String, dynamic> toJson() => {
    'notebook_id': notebookId,
    'deleted_at': deletedAt.toIso8601String(),
  };

  factory DeleteNotebookPayload.fromJson(Map<String, dynamic> json) {
    return DeleteNotebookPayload(
      notebookId: json['notebook_id'] as String,
      deletedAt: DateTime.parse(json['deleted_at'] as String),
    );
  }
}
