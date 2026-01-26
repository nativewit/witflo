// ═══════════════════════════════════════════════════════════════════════════
// FYNDO - Zero-Trust Notes OS
// Notebook Model - Notebook Data Structure (built_value)
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:convert';

import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:uuid/uuid.dart';

part 'notebook.g.dart';

/// A notebook for organizing notes.
abstract class Notebook implements Built<Notebook, NotebookBuilder> {
  static Serializer<Notebook> get serializer => _$notebookSerializer;

  /// Unique identifier (UUID v4)
  String get id;

  /// Notebook name
  String get name;

  /// Optional description
  String? get description;

  /// Parent vault ID
  String get vaultId;

  /// Color hex code (without #)
  String? get color;

  /// Icon name
  String? get icon;

  /// Creation timestamp (UTC)
  DateTime get createdAt;

  /// Last modification timestamp (UTC)
  DateTime get modifiedAt;

  /// Whether this notebook is archived
  bool get isArchived;

  /// Note count (computed, not stored)
  int get noteCount;

  Notebook._();
  factory Notebook([void Function(NotebookBuilder) updates]) = _$Notebook;

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
      (b) => b
        ..id = const Uuid().v4()
        ..name = name
        ..vaultId = vaultId
        ..description = description
        ..color = color
        ..icon = icon
        ..createdAt = now
        ..modifiedAt = now
        ..isArchived = false
        ..noteCount = 0,
    );
  }

  Map<String, dynamic> toJson() => {
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

  static Notebook fromJson(Map<String, dynamic> json) {
    return Notebook(
      (b) => b
        ..id = json['id'] as String
        ..name = json['name'] as String
        ..description = json['description'] as String?
        ..vaultId = json['vaultId'] as String
        ..color = json['color'] as String?
        ..icon = json['icon'] as String?
        ..createdAt = DateTime.parse(json['createdAt'] as String)
        ..modifiedAt = DateTime.parse(json['modifiedAt'] as String)
        ..isArchived = json['isArchived'] as bool? ?? false
        ..noteCount = 0,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  /// Creates a copy with updated fields (convenience wrapper around rebuild).
  Notebook copyWith({
    String? name,
    String? description,
    String? color,
    String? icon,
    bool? isArchived,
    int? noteCount,
    DateTime? modifiedAt,
  }) {
    return rebuild(
      (b) => b
        ..name = name ?? this.name
        ..description = description ?? this.description
        ..color = color ?? this.color
        ..icon = icon ?? this.icon
        ..isArchived = isArchived ?? this.isArchived
        ..noteCount = noteCount ?? this.noteCount
        ..modifiedAt = modifiedAt ?? DateTime.now().toUtc(),
    );
  }
}
