// ═══════════════════════════════════════════════════════════════════════════
// WITFLO - Zero-Trust Notes OS
// Workspace File Watcher - Monitor Workspace-Level File Changes
// ═══════════════════════════════════════════════════════════════════════════
//
// PURPOSE:
// Monitors workspace-level files for external changes (from cloud sync, etc.)
// and triggers appropriate handlers to keep the app state synchronized.
//
// MONITORED FILES:
// - .witflo-workspace: Workspace metadata (ID, crypto params)
// - .witflo-keyring.enc: Encrypted vault keys
// - vaults/*/vault.header: New vault discovery
//
// USAGE:
// final watcher = WorkspaceFileWatcher(
//   workspaceRoot: '/path/to/workspace',
//   onMetadataChange: () => handleWorkspaceMetadataChange(),
//   onKeyringChange: () => handleKeyringChange(),
//   onVaultDiscovered: (vaultId) => handleNewVault(vaultId),
// );
//
// await watcher.startWatching();
// // ... later
// watcher.dispose();
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:witflo_app/core/vault/file_change_notifier.dart';
import 'package:witflo_app/core/vault/native_file_watcher.dart';

/// Callback for workspace metadata changes.
typedef WorkspaceMetadataChangeHandler = Future<void> Function();

/// Callback for keyring changes.
typedef KeyringChangeHandler = Future<void> Function();

/// Callback for new vault discovery.
typedef VaultDiscoveredHandler = Future<void> Function(String vaultId);

/// Watches workspace-level files for external changes.
///
/// Monitors:
/// 1. Workspace metadata file (.witflo-workspace)
/// 2. Encrypted keyring (.witflo-keyring.enc)
/// 3. Vaults directory for new vault.header files
class WorkspaceFileWatcher {
  /// Root directory of the workspace.
  final String workspaceRoot;

  /// Handler for workspace metadata changes.
  final WorkspaceMetadataChangeHandler? onMetadataChange;

  /// Handler for keyring changes.
  final KeyringChangeHandler? onKeyringChange;

  /// Handler for new vault discovery.
  final VaultDiscoveredHandler? onVaultDiscovered;

  // Internal watchers
  NativeFileWatcher? _metadataWatcher;
  NativeFileWatcher? _vaultsDirWatcher;

  // Stream subscriptions
  StreamSubscription<FileChange>? _metadataSub;
  StreamSubscription<FileChange>? _vaultsDirSub;

  // Track discovered vaults to avoid duplicate notifications
  final Set<String> _discoveredVaults = {};

  WorkspaceFileWatcher({
    required this.workspaceRoot,
    this.onMetadataChange,
    this.onKeyringChange,
    this.onVaultDiscovered,
  });

  /// Start watching workspace files.
  Future<void> startWatching() async {
    await _startMetadataWatcher();
    await _startVaultsDirWatcher();
  }

  /// Start watching workspace metadata files (.witflo-workspace, .witflo-keyring.enc).
  Future<void> _startMetadataWatcher() async {
    _metadataWatcher = NativeFileWatcher(
      directoryPath: workspaceRoot,
      filePatterns: ['.witflo-workspace', '.witflo-keyring.enc'],
      debounceInterval: const Duration(milliseconds: 500),
    );

    _metadataSub = _metadataWatcher!.changes.listen(
      _handleMetadataChange,
      onError: (error, stack) {
        // Log error but don't crash
        print('Workspace metadata watcher error: $error');
      },
    );
  }

  /// Start watching vaults directory for new vault.header files.
  Future<void> _startVaultsDirWatcher() async {
    final vaultsDir = p.join(workspaceRoot, 'vaults');

    // Ensure vaults directory exists
    final dir = Directory(vaultsDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    // Scan existing vaults on startup
    await _scanExistingVaults();

    _vaultsDirWatcher = NativeFileWatcher(
      directoryPath: vaultsDir,
      filePatterns: ['vault.header'],
      debounceInterval: const Duration(milliseconds: 500),
    );

    _vaultsDirSub = _vaultsDirWatcher!.changes.listen(
      _handleVaultDiscovery,
      onError: (error, stack) {
        print('Vaults directory watcher error: $error');
      },
    );
  }

  /// Scan existing vaults and add to discovered set.
  Future<void> _scanExistingVaults() async {
    final vaultsDir = Directory(p.join(workspaceRoot, 'vaults'));
    if (!await vaultsDir.exists()) return;

    await for (final entity in vaultsDir.list()) {
      if (entity is Directory) {
        final vaultId = p.basename(entity.path);
        final headerFile = File(p.join(entity.path, 'vault.header'));
        if (await headerFile.exists()) {
          _discoveredVaults.add(vaultId);
        }
      }
    }
  }

  /// Handle workspace metadata or keyring file changes.
  Future<void> _handleMetadataChange(FileChange change) async {
    final fileName = p.basename(change.path);

    if (fileName == '.witflo-workspace') {
      // Workspace metadata changed externally
      if (onMetadataChange != null) {
        await onMetadataChange!();
      }
    } else if (fileName == '.witflo-keyring.enc') {
      // Keyring changed externally
      // This is critical - user should be notified to re-unlock workspace
      if (onKeyringChange != null) {
        await onKeyringChange!();
      }
    }
  }

  /// Handle new vault discovery.
  Future<void> _handleVaultDiscovery(FileChange change) async {
    if (change.type == FileChangeType.deleted) {
      // Vault deleted - not handling this case for now
      return;
    }

    // Extract vault ID from path: vaults/{vaultId}/vault.header
    final vaultId = _extractVaultId(change.path);
    if (vaultId == null) return;

    // Check if already discovered
    if (_discoveredVaults.contains(vaultId)) {
      return;
    }

    // Mark as discovered
    _discoveredVaults.add(vaultId);

    // Notify handler
    if (onVaultDiscovered != null) {
      await onVaultDiscovered!(vaultId);
    }
  }

  /// Extract vault ID from vault.header path.
  ///
  /// Expected format: /path/to/workspace/vaults/{vaultId}/vault.header
  String? _extractVaultId(String headerPath) {
    final parts = p.split(headerPath);
    final vaultsIndex = parts.lastIndexOf('vaults');

    if (vaultsIndex >= 0 && vaultsIndex + 1 < parts.length) {
      return parts[vaultsIndex + 1];
    }

    return null;
  }

  /// Dispose watchers and clean up.
  void dispose() {
    _metadataSub?.cancel();
    _vaultsDirSub?.cancel();
    _metadataWatcher?.dispose();
    _vaultsDirWatcher?.dispose();
    _discoveredVaults.clear();
  }
}
