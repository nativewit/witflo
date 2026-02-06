// ═══════════════════════════════════════════════════════════════════════════
// WITFLO - Zero-Trust Notes OS
// Native File Watcher - Platform-Native File System Monitoring
// ═══════════════════════════════════════════════════════════════════════════
//
// PURPOSE:
// Monitors a directory for file changes using Dart's Directory.watch() API.
// Provides debouncing, pattern filtering, and hash-based deduplication.
//
// FEATURES:
// - OS-level file system notifications (inotify on Linux, FSEvents on macOS, etc.)
// - Pattern-based filtering (e.g., "*.enc", "vault.header")
// - Debouncing to prevent event storms (default: 300ms)
// - BLAKE3 content hashing for deduplication
// - Handles file locks and partial writes gracefully
//
// USAGE:
// final watcher = NativeFileWatcher(
//   directoryPath: '/path/to/vault/refs',
//   filePatterns: ['*.jsonl.enc', '*.enc'],
//   crypto: cryptoService,
// );
//
// watcher.changes.listen((change) {
//   if (change.type == FileChangeType.modified) {
//     await reloadIndex(change.path);
//   }
// });
//
// // Clean up
// watcher.dispose();
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart' as dart_crypto;
import 'package:path/path.dart' as p;
import 'package:witflo_app/core/crypto/crypto.dart';
import 'package:witflo_app/core/vault/file_change_notifier.dart';

/// Native file system watcher using Directory.watch().
///
/// Monitors a directory for file changes and emits FileChange events.
/// Supports pattern filtering, debouncing, and content hash deduplication.
class NativeFileWatcher implements FileChangeNotifier {
  /// Directory to watch (absolute path).
  final String directoryPath;

  /// File patterns to monitor (e.g., ['*.enc', 'vault.header']).
  /// Supports wildcards: * matches any characters.
  final List<String> filePatterns;

  /// Debounce interval - waits this duration after last change before emitting.
  /// Prevents event storms during rapid file modifications.
  final Duration debounceInterval;

  /// Crypto service for computing content hashes (optional).
  /// If null, uses Dart's built-in SHA256 for hashing.
  final CryptoService? _crypto;

  /// Stream controller for emitting file changes.
  StreamController<FileChange>? _controller;

  /// Subscription to the directory watcher.
  StreamSubscription<FileSystemEvent>? _subscription;

  /// Debounce timer for each file path.
  final Map<String, Timer> _debounceTimers = {};

  /// Last known content hash for each file (deduplication).
  final Map<String, String> _lastKnownHashes = {};

  /// Whether the watcher is currently active.
  bool _isActive = false;

  NativeFileWatcher({
    required this.directoryPath,
    required this.filePatterns,
    CryptoService? crypto,
    this.debounceInterval = const Duration(milliseconds: 300),
  }) : _crypto = crypto;

  @override
  Stream<FileChange> get changes {
    _controller ??= StreamController<FileChange>.broadcast(
      onListen: _startWatching,
      onCancel: _stopWatching,
    );
    return _controller!.stream;
  }

  /// Start watching the directory.
  void _startWatching() {
    if (_isActive) return;
    _isActive = true;

    final dir = Directory(directoryPath);

    if (!dir.existsSync()) {
      _controller?.addError(
        FileSystemException('Directory does not exist', directoryPath),
      );
      return;
    }

    // Watch directory recursively
    _subscription = dir
        .watch(recursive: true)
        .listen(
          _handleFileSystemEvent,
          onError: (error, stack) {
            _controller?.addError(error, stack);
          },
        );
  }

  /// Stop watching and clean up.
  void _stopWatching() {
    if (!_isActive) return;
    _isActive = false;

    // Cancel all debounce timers
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();

    _subscription?.cancel();
    _subscription = null;
  }

  /// Handle a file system event from Directory.watch().
  void _handleFileSystemEvent(FileSystemEvent event) {
    final fileName = p.basename(event.path);

    // Filter by patterns
    if (!_matchesPattern(fileName)) {
      return;
    }

    // Cancel existing debounce timer for this file
    _debounceTimers[event.path]?.cancel();

    // Start new debounce timer
    _debounceTimers[event.path] = Timer(debounceInterval, () {
      _processFileEvent(event);
      _debounceTimers.remove(event.path);
    });
  }

  /// Check if filename matches any of the file patterns.
  bool _matchesPattern(String fileName) {
    for (final pattern in filePatterns) {
      if (pattern.contains('*')) {
        // Convert glob pattern to regex
        // Example: "*.enc" -> "^.*\.enc$"
        final regexPattern =
            '^${pattern.replaceAll('.', r'\.').replaceAll('*', '.*')}\$';
        final regex = RegExp(regexPattern);
        if (regex.hasMatch(fileName)) {
          return true;
        }
      } else {
        // Exact match
        if (fileName == pattern) {
          return true;
        }
      }
    }
    return false;
  }

  /// Process a debounced file event.
  Future<void> _processFileEvent(FileSystemEvent event) async {
    FileChangeType changeType;
    String? contentHash;

    // Determine change type
    if (event is FileSystemCreateEvent) {
      changeType = FileChangeType.created;
    } else if (event is FileSystemDeleteEvent) {
      changeType = FileChangeType.deleted;
      _lastKnownHashes.remove(event.path);
    } else if (event is FileSystemModifyEvent) {
      changeType = FileChangeType.modified;
    } else if (event is FileSystemMoveEvent) {
      changeType = FileChangeType.moved;
      // Move is like delete + create
      _lastKnownHashes.remove(event.path);
      if (event.destination != null) {
        _lastKnownHashes.remove(event.destination);
      }
    } else {
      // Unknown event type, skip
      return;
    }

    // Compute content hash for create/modify events
    if (changeType != FileChangeType.deleted) {
      final file = File(event.path);

      if (!await file.exists()) {
        // File was deleted between event and now, skip
        return;
      }

      try {
        final bytes = await file.readAsBytes();

        // Compute hash using BLAKE3 (preferred) or fallback to SHA256
        if (_crypto != null) {
          final hash = _crypto!.blake3.hash(bytes);
          contentHash = hash.hex;
        } else {
          // Fallback to Dart's SHA256 for tests
          final digest = dart_crypto.sha256.convert(bytes);
          contentHash = digest.toString();
        }

        // Check if hash changed (deduplication)
        if (_lastKnownHashes[event.path] == contentHash) {
          // File content unchanged (e.g., metadata-only change)
          return;
        }

        _lastKnownHashes[event.path] = contentHash;
      } catch (e) {
        // File might be locked or mid-write
        // Skip this event, we'll catch the next change
        if (e is FileSystemException) {
          // Common during cloud sync operations
          return;
        }
        // Re-throw unexpected errors
        rethrow;
      }
    }

    // Emit the change event
    _controller?.add(
      FileChange(
        path: event.path,
        type: changeType,
        timestamp: DateTime.now(),
        contentHash: contentHash,
      ),
    );
  }

  @override
  void dispose() {
    _stopWatching();
    _controller?.close();
    _controller = null;
    _lastKnownHashes.clear();
  }
}
