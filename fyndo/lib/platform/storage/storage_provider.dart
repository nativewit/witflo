// ═══════════════════════════════════════════════════════════════════════════
// FYNDO - Zero-Trust Notes OS
// Storage Interface - Platform-Agnostic Storage Abstraction
// ═══════════════════════════════════════════════════════════════════════════
//
// This abstraction allows Fyndo to work on both native (file system) and
// web (IndexedDB) platforms with the same API.
//
// IMPLEMENTATIONS:
// - NativeStorage: Uses dart:io File/Directory for native platforms
// - WebStorage: Uses IndexedDB for web platform
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:typed_data';

/// Abstract interface for platform-agnostic storage.
abstract class StorageProvider {
  /// Initialize the storage provider.
  Future<void> initialize();

  /// Check if a file exists.
  Future<bool> exists(String path);

  /// Check if a directory exists.
  Future<bool> directoryExists(String path);

  /// Create a directory (and parents if needed).
  Future<void> createDirectory(String path);

  /// Read file as bytes.
  Future<Uint8List?> readFile(String path);

  /// Read file as string.
  Future<String?> readFileAsString(String path);

  /// Write bytes to file.
  Future<void> writeFile(String path, List<int> data);

  /// Write string to file.
  Future<void> writeFileAsString(String path, String data);

  /// Write atomically (write to temp then rename).
  Future<void> writeAtomic(String path, List<int> data);

  /// Delete a file.
  Future<void> deleteFile(String path);

  /// Delete a directory and contents.
  Future<void> deleteDirectory(String path);

  /// List files in a directory.
  Future<List<String>> listDirectory(String path);

  /// List only files (not directories) in a directory.
  Future<List<String>> listFiles(String path);

  /// Copy a file.
  Future<void> copyFile(String from, String to);

  /// Move/rename a file.
  Future<void> moveFile(String from, String to);
}

/// Get the storage provider for the current platform.
/// This is set during app initialization.
StorageProvider? _storageProvider;

StorageProvider get storageProvider {
  if (_storageProvider == null) {
    throw StateError('StorageProvider not initialized. Call initializeStorage() first.');
  }
  return _storageProvider!;
}

/// Set the storage provider (called during platform init).
void setStorageProvider(StorageProvider provider) {
  _storageProvider = provider;
}

/// Check if storage is initialized.
bool get isStorageInitialized => _storageProvider != null;

