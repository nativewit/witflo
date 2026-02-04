// ═══════════════════════════════════════════════════════════════════════════
// WITFLO - Zero-Trust Notes OS
// FolderPicker - Desktop Implementation (macOS, Windows, Linux)
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:witflo_app/core/config/env.dart';
import 'package:witflo_app/core/workspace/folder_picker.dart';

/// Desktop implementation of [FolderPicker] using file_selector.
///
/// Supports:
/// - macOS (with com.apple.security.files.user-selected.read-write entitlement)
/// - Windows
/// - Linux
///
/// Security:
/// - macOS sandbox requires user-selected.read-write entitlement
/// - Selected folders are bookmarked for persistent access
///
/// Spec: docs/specs/spec-001-workspace-management.md (Section 4.1.1)
class FolderPickerDesktop implements FolderPicker {
  @override
  Future<String?> pickFolder() async {
    try {
      final String? directoryPath = await getDirectoryPath(
        confirmButtonText: 'Select Workspace Folder',
      );

      if (directoryPath == null) {
        // User cancelled
        return null;
      }

      // Verify we can access the directory
      if (!await canAccessDirectory(directoryPath)) {
        throw FolderPickerException(
          'Cannot access selected directory: $directoryPath',
        );
      }

      return directoryPath;
    } catch (e) {
      if (e is FolderPickerException) rethrow;
      throw FolderPickerException('Failed to pick folder', e);
    }
  }

  @override
  Future<String> getDefaultWorkspaceDirectory() async {
    try {
      // Get platform-appropriate documents directory
      final Directory documentsDir = await getApplicationDocumentsDirectory();

      // Create default workspace path
      final String workspacePath = p.join(documentsDir.path, 'Witflo');

      return workspacePath;
    } catch (e) {
      throw FolderPickerException(
        'Failed to get default workspace directory',
        e,
      );
    }
  }

  @override
  Future<bool> canAccessDirectory(String path) async {
    try {
      final dir = Directory(path);

      // Check if directory exists
      if (!await dir.exists()) {
        return false;
      }

      // Try to list contents to verify read permission
      try {
        await dir.list().isEmpty;
      } catch (_) {
        return false; // No read permission
      }

      // Try to create a temp file to verify write permission
      final testFile = File(
        p.join(path, AppEnvironment.instance.accessTestFile),
      );
      try {
        await testFile.writeAsString('test', flush: true);
        await testFile.delete();
        return true;
      } catch (_) {
        return false; // No write permission
      }
    } catch (e) {
      return false;
    }
  }
}
