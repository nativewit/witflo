// ═══════════════════════════════════════════════════════════════════════════
// FYNDO - Zero-Trust Notes OS
// WorkspaceService - Workspace initialization, validation, and discovery
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fyndo_app/core/workspace/workspace_config.dart';
import 'package:fyndo_app/core/workspace/folder_picker.dart';

/// Service for managing workspace lifecycle: initialization, validation,
/// persistence, and discovery of vaults within a workspace.
///
/// Responsibilities:
/// 1. Initialize new workspace directories
/// 2. Validate existing workspaces
/// 3. Load/save workspace configuration
/// 4. Discover vaults within a workspace
/// 5. Manage recent workspaces list
///
/// Usage:
/// ```dart
/// final service = WorkspaceService();
///
/// // Initialize new workspace
/// final config = await service.initializeWorkspace('/path/to/workspace');
///
/// // Load existing workspace
/// final config = await service.loadWorkspaceConfig();
///
/// // Discover vaults in workspace
/// final vaultPaths = await service.discoverVaults(config.rootPath);
/// ```
///
/// Spec: docs/specs/spec-001-workspace-management.md (Section 4.2)
class WorkspaceService {
  static const String _workspaceConfigKey = 'fyndo_workspace_config';
  static const String _workspaceMarkerFile = '.fyndo-workspace';
  static const String _vaultsSubdir = 'vaults';

  final FolderPicker _folderPicker;

  WorkspaceService({FolderPicker? folderPicker})
    : _folderPicker = folderPicker ?? FolderPicker.create();

  // ═══════════════════════════════════════════════════════════════════════════
  // WORKSPACE INITIALIZATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Initializes a new workspace at the given path.
  ///
  /// Creates directory structure:
  /// ```
  /// <rootPath>/
  ///   .fyndo-workspace      # Marker file
  ///   vaults/               # Container for encrypted vaults
  /// ```
  ///
  /// Returns a [WorkspaceConfig] for the new workspace.
  ///
  /// Throws:
  /// - [WorkspaceException] if path is not accessible or already initialized
  Future<WorkspaceConfig> initializeWorkspace(String rootPath) async {
    // Verify we can access the directory
    if (!await _folderPicker.canAccessDirectory(rootPath)) {
      // Try to create it
      try {
        await Directory(rootPath).create(recursive: true);
      } catch (e) {
        throw WorkspaceException(
          'Cannot access or create directory: $rootPath',
          e,
        );
      }
    }

    // Check if already initialized
    final markerFile = File(p.join(rootPath, _workspaceMarkerFile));
    if (await markerFile.exists()) {
      throw WorkspaceException('Workspace already initialized at: $rootPath');
    }

    // Create workspace structure
    try {
      // Create marker file
      await markerFile.writeAsString(
        _createWorkspaceMarkerContent(),
        flush: true,
      );

      // Create vaults directory
      final vaultsDir = Directory(p.join(rootPath, _vaultsSubdir));
      await vaultsDir.create(recursive: true);

      // Create and save configuration
      final config = WorkspaceConfig.create(rootPath: rootPath);
      await saveWorkspaceConfig(config);

      return config;
    } catch (e) {
      throw WorkspaceException('Failed to initialize workspace', e);
    }
  }

  /// Creates the content for the .fyndo-workspace marker file.
  String _createWorkspaceMarkerContent() {
    final now = DateTime.now().toUtc().toIso8601String();
    return '''# Fyndo Workspace
# This directory contains encrypted vaults managed by Fyndo.
# Created: $now
# 
# Structure:
#   vaults/<vault-id>/    - Encrypted vault directories
#
# DO NOT manually delete this file unless you want to reinitialize
# the workspace, which will require re-selecting all vaults.
''';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // WORKSPACE VALIDATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Validates that a directory is a valid Fyndo workspace.
  ///
  /// Checks for:
  /// 1. Directory exists and is accessible
  /// 2. Contains .fyndo-workspace marker file
  /// 3. Contains vaults/ subdirectory
  ///
  /// Returns true if valid, false otherwise.
  Future<bool> isValidWorkspace(String rootPath) async {
    try {
      // Check directory exists
      final dir = Directory(rootPath);
      if (!await dir.exists()) {
        return false;
      }

      // Check for marker file
      final markerFile = File(p.join(rootPath, _workspaceMarkerFile));
      if (!await markerFile.exists()) {
        return false;
      }

      // Check for vaults directory
      final vaultsDir = Directory(p.join(rootPath, _vaultsSubdir));
      if (!await vaultsDir.exists()) {
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // WORKSPACE PERSISTENCE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Saves workspace configuration to SharedPreferences.
  ///
  /// Configuration is persisted as JSON for fast access on app startup.
  Future<void> saveWorkspaceConfig(WorkspaceConfig config) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(config.toJson());
      await prefs.setString(_workspaceConfigKey, json);
    } catch (e) {
      throw WorkspaceException('Failed to save workspace configuration', e);
    }
  }

  /// Loads workspace configuration from SharedPreferences.
  ///
  /// Returns null if no workspace has been configured yet.
  Future<WorkspaceConfig?> loadWorkspaceConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_workspaceConfigKey);

      if (json == null) {
        return null; // No workspace configured
      }

      final map = jsonDecode(json) as Map<String, dynamic>;
      return WorkspaceConfig.fromJson(map);
    } catch (e) {
      throw WorkspaceException('Failed to load workspace configuration', e);
    }
  }

  /// Clears the workspace configuration from SharedPreferences.
  ///
  /// Use when user wants to switch to a different workspace.
  Future<void> clearWorkspaceConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_workspaceConfigKey);
    } catch (e) {
      throw WorkspaceException('Failed to clear workspace configuration', e);
    }
  }

  /// Switches to a different workspace.
  ///
  /// Validates the new workspace, adds the old one to recent workspaces,
  /// and updates the configuration.
  Future<WorkspaceConfig> switchWorkspace(String newRootPath) async {
    // Validate new workspace
    if (!await isValidWorkspace(newRootPath)) {
      throw WorkspaceException('Not a valid Fyndo workspace: $newRootPath');
    }

    // Load current config to get recent workspaces
    final currentConfig = await loadWorkspaceConfig();

    // Create new config with current workspace added to recents
    final newConfig = WorkspaceConfig.create(
      rootPath: newRootPath,
      recentWorkspaces: currentConfig != null
          ? [currentConfig.rootPath, ...currentConfig.recentWorkspaces.toList()]
          : [],
    );

    // Save new config
    await saveWorkspaceConfig(newConfig);

    return newConfig;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // VAULT DISCOVERY
  // ═══════════════════════════════════════════════════════════════════════════

  /// Discovers all vault directories within the workspace.
  ///
  /// Scans the vaults/ subdirectory and returns paths to all directories
  /// containing a valid vault.header file.
  ///
  /// Returns a list of absolute paths to vault directories.
  Future<List<String>> discoverVaults(String workspaceRoot) async {
    final vaultsDir = Directory(p.join(workspaceRoot, _vaultsSubdir));

    if (!await vaultsDir.exists()) {
      return [];
    }

    final vaultPaths = <String>[];

    try {
      await for (final entity in vaultsDir.list(followLinks: false)) {
        if (entity is Directory) {
          // Check if this directory contains a vault.header file
          final headerFile = File(p.join(entity.path, 'vault.header'));
          if (await headerFile.exists()) {
            vaultPaths.add(entity.path);
          }
        }
      }
    } catch (e) {
      throw WorkspaceException('Failed to discover vaults', e);
    }

    return vaultPaths;
  }

  /// Returns the path where a new vault should be created.
  ///
  /// [vaultId] - UUID for the vault (generated by VaultService)
  ///
  /// Example: `/path/to/workspace/vaults/550e8400-e29b-41d4-a716-446655440000`
  String getNewVaultPath(String workspaceRoot, String vaultId) {
    return p.join(workspaceRoot, _vaultsSubdir, vaultId);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // WORKSPACE SELECTION HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Opens folder picker and returns selected path (or null if cancelled).
  Future<String?> pickWorkspaceFolder() async {
    return await _folderPicker.pickFolder();
  }

  /// Returns the default workspace directory for the current platform.
  Future<String> getDefaultWorkspaceDirectory() async {
    return await _folderPicker.getDefaultWorkspaceDirectory();
  }
}

/// Exception thrown by WorkspaceService operations.
class WorkspaceException implements Exception {
  final String message;
  final Object? cause;

  WorkspaceException(this.message, [this.cause]);

  @override
  String toString() =>
      'WorkspaceException: $message${cause != null ? ' ($cause)' : ''}';
}
