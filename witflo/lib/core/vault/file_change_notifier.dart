// ═══════════════════════════════════════════════════════════════════════════
// WITFLO - Zero-Trust Notes OS
// File Change Notifier - Abstract Interface for File System Monitoring
// ═══════════════════════════════════════════════════════════════════════════
//
// PURPOSE:
// Provides a platform-agnostic interface for file system change notifications.
// Implementations:
// - NativeFileWatcher: Uses Dart's Directory.watch() for native platforms
// - PollingFileWatcher: Uses periodic polling for web (future)
//
// USAGE:
// final watcher = NativeFileWatcher(
//   directoryPath: '/path/to/vault',
//   filePatterns: ['*.enc', '*.jsonl.enc'],
//   crypto: cryptoService,
// );
//
// watcher.changes.listen((change) {
//   print('File ${change.type}: ${change.path}');
// });
// ═══════════════════════════════════════════════════════════════════════════

/// Abstract interface for file change notifications across platforms.
abstract class FileChangeNotifier {
  /// Stream of file change events.
  Stream<FileChange> get changes;

  /// Dispose resources and stop watching.
  void dispose();
}

/// Represents a single file system change event.
class FileChange {
  /// Absolute path to the changed file.
  final String path;

  /// Type of change that occurred.
  final FileChangeType type;

  /// When the change was detected.
  final DateTime timestamp;

  /// Optional content hash (BLAKE3) for deduplication.
  /// Only computed for create/modify events.
  final String? contentHash;

  const FileChange({
    required this.path,
    required this.type,
    required this.timestamp,
    this.contentHash,
  });

  @override
  String toString() {
    return 'FileChange($type: $path at $timestamp${contentHash != null ? ', hash: ${contentHash!.substring(0, 8)}...' : ''})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FileChange &&
        other.path == path &&
        other.type == type &&
        other.contentHash == contentHash;
  }

  @override
  int get hashCode => Object.hash(path, type, contentHash);
}

/// Types of file system changes.
enum FileChangeType {
  /// File was created.
  created,

  /// File was modified.
  modified,

  /// File was deleted.
  deleted,

  /// File was moved/renamed.
  moved,
}
