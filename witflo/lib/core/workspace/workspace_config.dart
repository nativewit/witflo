// ignore_for_file: library_private_types_in_public_api
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:built_collection/built_collection.dart';

part 'workspace_config.g.dart';

/// Immutable workspace configuration persisted to disk.
///
/// This represents the user's selected workspace root directory and
/// maintains a list of recently accessed workspaces for quick switching.
///
/// Security: This file is stored unencrypted as it contains no sensitive data,
/// only directory paths. All vault content within the workspace is encrypted.
///
/// Spec: docs/specs/spec-001-workspace-management.md
abstract class WorkspaceConfig
    implements Built<WorkspaceConfig, WorkspaceConfigBuilder> {
  /// Absolute path to the current workspace root directory.
  ///
  /// Example (Desktop): `/Users/alice/WitfloWorkspace`
  /// Example (Mobile): `/data/data/com.fyndo.app/files/workspace`
  ///
  /// This directory contains:
  /// - `.fyndo-workspace` marker file
  /// - `vaults/` subdirectory with encrypted vaults
  String get rootPath;

  /// List of recently accessed workspace paths, most recent first.
  ///
  /// Maximum 10 entries. Used for quick workspace switching UI.
  /// Paths are absolute and platform-specific.
  BuiltList<String> get recentWorkspaces;

  /// Timestamp when this workspace was last accessed (ISO 8601 UTC).
  ///
  /// Used for sorting recent workspaces and cleaning up stale entries.
  String get lastAccessedAt;

  WorkspaceConfig._();

  factory WorkspaceConfig([void Function(WorkspaceConfigBuilder) updates]) =
      _$WorkspaceConfig;

  /// Creates a new workspace configuration with the given root path.
  ///
  /// [rootPath] - Absolute path to the workspace directory
  /// [recentWorkspaces] - Optional list of recent workspace paths (defaults to empty)
  static WorkspaceConfig create({
    required String rootPath,
    List<String>? recentWorkspaces,
  }) {
    return WorkspaceConfig(
      (b) => b
        ..rootPath = rootPath
        ..recentWorkspaces = ListBuilder<String>(recentWorkspaces ?? [])
        ..lastAccessedAt = DateTime.now().toUtc().toIso8601String(),
    );
  }

  /// Adds a workspace path to the recent list, keeping only the 10 most recent.
  ///
  /// If the path already exists, it's moved to the front.
  /// The current [rootPath] is automatically excluded from the recent list.
  WorkspaceConfig addRecentWorkspace(String path) {
    // Remove duplicates and the current workspace
    final filtered = recentWorkspaces
        .where((p) => p != path && p != rootPath)
        .toList();

    // Add new path at the front
    filtered.insert(0, path);

    // Keep only 10 most recent
    final trimmed = filtered.take(10).toList();

    return rebuild(
      (b) => b
        ..recentWorkspaces = ListBuilder<String>(trimmed)
        ..lastAccessedAt = DateTime.now().toUtc().toIso8601String(),
    );
  }

  /// Updates the last accessed timestamp to now.
  WorkspaceConfig touch() {
    return rebuild(
      (b) => b..lastAccessedAt = DateTime.now().toUtc().toIso8601String(),
    );
  }

  /// Serializer for JSON serialization/deserialization.
  static Serializer<WorkspaceConfig> get serializer =>
      _$workspaceConfigSerializer;

  /// Converts this config to a JSON map for persistence.
  Map<String, dynamic> toJson() {
    return {
      'rootPath': rootPath,
      'recentWorkspaces': recentWorkspaces.toList(),
      'lastAccessedAt': lastAccessedAt,
    };
  }

  /// Creates a WorkspaceConfig from a JSON map.
  static WorkspaceConfig fromJson(Map<String, dynamic> json) {
    return WorkspaceConfig(
      (b) => b
        ..rootPath = json['rootPath'] as String
        ..recentWorkspaces = ListBuilder<String>(
          (json['recentWorkspaces'] as List<dynamic>).cast<String>(),
        )
        ..lastAccessedAt = json['lastAccessedAt'] as String,
    );
  }
}
