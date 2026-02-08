// ═══════════════════════════════════════════════════════════════════════════
// WITFLO - Zero-Trust Notes OS
// Vault File Watcher - Monitor Vault-Level File Changes
// ═══════════════════════════════════════════════════════════════════════════
//
// PURPOSE:
// Monitors vault-level files for external changes (from cloud sync, etc.)
// and triggers index reloads and sync operations to keep the app state current.
//
// MONITORED FILES:
// - refs/notes.jsonl.enc: Note metadata index
// - refs/notebooks.jsonl.enc: Notebook metadata index
// - refs/tags.jsonl.enc: Tag index
// - sync/cursor.enc: Sync cursor
// - sync/pending/*.op.enc: Pending sync operations
//
// USAGE:
// final watcher = VaultFileWatcher(
//   vault: unlockedVault,
//   onNotesIndexChange: () => reloadNotesIndex(),
//   onNotebooksIndexChange: () => reloadNotebooksIndex(),
//   onTagsIndexChange: () => reloadTagsIndex(),
//   onSyncOperation: (opPath) => applySyncOperation(opPath),
// );
//
// await watcher.startWatching();
// // ... later
// watcher.dispose();
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:witflo_app/core/vault/file_change_notifier.dart';
import 'package:witflo_app/core/vault/native_file_watcher.dart';
import 'package:witflo_app/core/vault/vault_service.dart';

/// Callback for index file changes.
typedef IndexChangeHandler = Future<void> Function();

/// Callback for sync operation files.
typedef SyncOperationHandler = Future<void> Function(String operationPath);

/// Watches vault-level files for external changes.
///
/// Monitors:
/// 1. Index files in refs/ directory (notes, notebooks, tags)
/// 2. Sync cursor and pending operations
class VaultFileWatcher {
  /// The unlocked vault being watched.
  final UnlockedVault vault;

  /// Handler for notes index changes.
  final IndexChangeHandler? onNotesIndexChange;

  /// Handler for notebooks index changes.
  final IndexChangeHandler? onNotebooksIndexChange;

  /// Handler for tags index changes.
  final IndexChangeHandler? onTagsIndexChange;

  /// Handler for sync cursor changes.
  final IndexChangeHandler? onSyncCursorChange;

  /// Handler for new sync operations.
  final SyncOperationHandler? onSyncOperation;

  // Internal watchers
  NativeFileWatcher? _refsWatcher;
  NativeFileWatcher? _syncWatcher;

  // Stream subscriptions
  StreamSubscription<FileChange>? _refsSub;
  StreamSubscription<FileChange>? _syncSub;

  VaultFileWatcher({
    required this.vault,
    this.onNotesIndexChange,
    this.onNotebooksIndexChange,
    this.onTagsIndexChange,
    this.onSyncCursorChange,
    this.onSyncOperation,
  });

  /// Start watching vault files.
  Future<void> startWatching() async {
    await _startRefsWatcher();
    await _startSyncWatcher();
  }

  /// Start watching refs directory for index file changes.
  Future<void> _startRefsWatcher() async {
    final refsDir = vault.filesystem.paths.refsDir;

    _refsWatcher = NativeFileWatcher(
      directoryPath: refsDir,
      filePatterns: [
        'notes.jsonl.enc',
        'notebooks.jsonl.enc',
        'tags.jsonl.enc',
      ],
      debounceInterval: const Duration(milliseconds: 500),
      // Disable hash deduplication for index files to detect ALL changes
      // This ensures live sync works correctly even when multiple apps
      // write the same content (timestamps differ but content may be same)
      useHashDeduplication: false,
    );

    _refsSub = _refsWatcher!.changes.listen(
      _handleRefChange,
      onError: (error, stack) {
        print('Vault refs watcher error (${vault.header.vaultId}): $error');
      },
    );
  }

  /// Start watching sync directory for cursor and operation changes.
  Future<void> _startSyncWatcher() async {
    // Watch the pending ops directory directly, not the sync root
    // This ensures we catch file events even if the directory was created after
    // the parent sync directory was being watched
    final pendingOpsDir = vault.filesystem.paths.pendingOpsDir;

    print(
      '[VaultFileWatcher] Starting sync watcher for: $pendingOpsDir (vault: ${vault.header.vaultId})',
    );

    _syncWatcher = NativeFileWatcher(
      directoryPath: pendingOpsDir,
      filePatterns: ['*.op.enc'],
      debounceInterval: const Duration(milliseconds: 500),
    );

    _syncSub = _syncWatcher!.changes.listen(
      (change) {
        print(
          '[VaultFileWatcher] Sync file change detected: ${change.path} (type: ${change.type})',
        );
        _handleSyncChange(change);
      },
      onError: (error, stack) {
        print('Vault sync watcher error (${vault.header.vaultId}): $error');
      },
    );
  }

  /// Handle index file changes in refs directory.
  Future<void> _handleRefChange(FileChange change) async {
    final fileName = p.basename(change.path);

    print(
      '[VaultFileWatcher] Ref file change: $fileName (type: ${change.type}, vault: ${vault.header.vaultId})',
    );

    if (change.type == FileChangeType.deleted) {
      // Index file deleted - this is critical but unusual
      print('Warning: Index file deleted: ${change.path}');
      return;
    }

    switch (fileName) {
      case 'notes.jsonl.enc':
        print('[VaultFileWatcher] Triggering notes index change handler...');
        if (onNotesIndexChange != null) {
          await onNotesIndexChange!();
          print('[VaultFileWatcher] Notes index change handler completed');
        } else {
          print(
            '[VaultFileWatcher] WARNING: No notes index change handler registered!',
          );
        }
        break;

      case 'notebooks.jsonl.enc':
        print(
          '[VaultFileWatcher] Triggering notebooks index change handler...',
        );
        if (onNotebooksIndexChange != null) {
          await onNotebooksIndexChange!();
          print('[VaultFileWatcher] Notebooks index change handler completed');
        }
        break;

      case 'tags.jsonl.enc':
        if (onTagsIndexChange != null) {
          await onTagsIndexChange!();
        }
        break;

      default:
        // Unknown ref file - ignore
        print('[VaultFileWatcher] Ignoring unknown ref file: $fileName');
        break;
    }
  }

  /// Handle sync file changes.
  Future<void> _handleSyncChange(FileChange change) async {
    final fileName = p.basename(change.path);

    if (fileName == 'cursor.enc') {
      // Sync cursor changed
      if (change.type != FileChangeType.deleted && onSyncCursorChange != null) {
        await onSyncCursorChange!();
      }
    } else if (fileName.endsWith('.op.enc')) {
      // New sync operation detected
      if (change.type == FileChangeType.created ||
          change.type == FileChangeType.modified) {
        if (onSyncOperation != null) {
          await onSyncOperation!(change.path);
        }
      }
    }
  }

  /// Dispose watchers and clean up.
  void dispose() {
    _refsSub?.cancel();
    _syncSub?.cancel();
    _refsWatcher?.dispose();
    _syncWatcher?.dispose();
  }
}
