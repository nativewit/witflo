// ═══════════════════════════════════════════════════════════════════════════
// WITFLO - Zero-Trust Notes OS
// FolderPicker - Mobile Implementation (iOS, Android)
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:witflo_app/core/config/env.dart';
import 'package:witflo_app/core/workspace/folder_picker.dart';

/// Mobile implementation of [FolderPicker] using app-scoped storage.
///
/// Supports:
/// - iOS (app documents directory in sandboxed container)
/// - Android (app-specific external storage directory)
///
/// Behavior:
/// - pickFolder() returns app documents directory (no user interaction)
/// - Workspace is always in app-scoped storage (not user-accessible)
/// - No need for storage permissions (using app-scoped directories)
///
/// Security:
/// - iOS: Data protected by device encryption and app sandbox
/// - Android: External app storage, backed up via Android Auto Backup
///
/// Note: For third-party sync (Dropbox, iCloud), users must manually
/// copy vault folders using system file managers. Future versions may
/// add platform-specific sync integrations.
///
/// Spec: docs/specs/spec-001-workspace-management.md (Section 4.1.2)
class FolderPickerMobile implements FolderPicker {
  @override
  Future<String?> pickFolder() async {
    // Mobile: No picker dialog, return app documents directory directly
    return await getDefaultWorkspaceDirectory();
  }

  @override
  Future<String> getDefaultWorkspaceDirectory() async {
    try {
      // iOS: /var/mobile/Containers/Data/Application/<UUID>/Documents/Witflo
      // Android: /data/user/0/com.witflo.app/files/Witflo
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String workspacePath = p.join(appDocDir.path, 'Witflo');

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
        // Try to create it
        try {
          await dir.create(recursive: true);
          return true;
        } catch (_) {
          return false;
        }
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
