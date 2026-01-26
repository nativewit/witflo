// ═══════════════════════════════════════════════════════════════════════════
// FYNDO - Zero-Trust Notes OS
// Vault Filesystem - Encrypted File Layout and Management
// ═══════════════════════════════════════════════════════════════════════════
//
// VAULT STRUCTURE:
// /VaultRoot/
//   vault.header        # Plaintext: version, salt, KDF params
//   vault.vk            # VK encrypted with MUK
//   /objects/           # Encrypted content-addressed blobs
//     /ab/cdef...       # Hash prefix directory structure
//   /refs/              # Encrypted reference files
//     notes.jsonl.enc   # Note metadata index
//     tags.jsonl.enc    # Tag index
//     notebooks.jsonl.enc
//   /sync/              # Sync state
//     cursor.enc        # Last sync position
//     pending/          # Outbound operations
//
// SECURITY:
// - Only vault.header is plaintext
// - All other files are encrypted with derived keys
// - Content is addressed by hash of ciphertext (not plaintext)
//
// PLATFORM SUPPORT:
// - Native (iOS, Android, macOS, Linux, Windows): Uses dart:io File/Directory
// - Web: Uses IndexedDB via StorageProvider abstraction
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:fyndo_app/platform/storage/storage_provider.dart';

/// Vault filesystem paths and utilities.
class VaultPaths {
  /// Root directory of the vault
  final String rootPath;

  VaultPaths(this.rootPath);

  /// Path to vault header (plaintext metadata)
  String get header => p.join(rootPath, 'vault.header');

  /// Path to encrypted vault key
  String get vaultKey => p.join(rootPath, 'vault.vk');

  /// Path to device-wrapped vault key (for biometric unlock)
  String get deviceKey => p.join(rootPath, 'device.key');

  /// Directory for content-addressed encrypted objects
  String get objectsDir => p.join(rootPath, 'objects');

  /// Directory for encrypted reference/index files
  String get refsDir => p.join(rootPath, 'refs');

  /// Path to encrypted notes index
  String get notesIndex => p.join(refsDir, 'notes.jsonl.enc');

  /// Path to encrypted tags index
  String get tagsIndex => p.join(refsDir, 'tags.jsonl.enc');

  /// Path to encrypted notebooks index
  String get notebooksIndex => p.join(refsDir, 'notebooks.jsonl.enc');

  /// Path to encrypted search index database
  String get searchIndex => p.join(refsDir, 'search.db.enc');

  /// Directory for sync state
  String get syncDir => p.join(rootPath, 'sync');

  /// Path to sync cursor
  String get syncCursor => p.join(syncDir, 'cursor.enc');

  /// Directory for pending sync operations
  String get pendingOpsDir => p.join(syncDir, 'pending');

  /// Path for a content-addressed object by its hash.
  /// Uses first 2 hex chars as subdirectory for filesystem efficiency.
  String objectPath(String hexHash) {
    final prefix = hexHash.substring(0, 2);
    final rest = hexHash.substring(2);
    return p.join(objectsDir, prefix, rest);
  }

  /// Path for a pending sync operation.
  String pendingOpPath(String opId) {
    return p.join(pendingOpsDir, '$opId.op.enc');
  }
}

/// Manages vault directory structure using platform-agnostic storage.
class VaultFilesystem {
  final VaultPaths paths;

  VaultFilesystem(String rootPath) : paths = VaultPaths(rootPath);

  /// Gets the storage provider
  StorageProvider get _storage => storageProvider;

  /// Creates the vault directory structure.
  Future<void> initialize() async {
    await _storage.createDirectory(paths.rootPath);
    await _storage.createDirectory(paths.objectsDir);
    await _storage.createDirectory(paths.refsDir);
    await _storage.createDirectory(paths.syncDir);
    await _storage.createDirectory(paths.pendingOpsDir);

    // Create hash prefix directories (00-ff)
    for (var i = 0; i < 256; i++) {
      final hex = i.toRadixString(16).padLeft(2, '0');
      await _storage.createDirectory(p.join(paths.objectsDir, hex));
    }
  }

  /// Checks if a vault exists at this path.
  Future<bool> exists() async {
    return await _storage.exists(paths.header) &&
        await _storage.exists(paths.vaultKey);
  }

  /// Checks if vault is locked (no device key for fast unlock).
  Future<bool> isLocked() async {
    return !await _storage.exists(paths.deviceKey);
  }

  /// Writes a file atomically.
  Future<void> writeAtomic(String filePath, List<int> data) async {
    await _storage.writeAtomic(filePath, data);
  }

  /// Reads a file if it exists, returns null otherwise.
  Future<Uint8List?> readIfExists(String filePath) async {
    return await _storage.readFile(filePath);
  }

  /// Writes an encrypted object and returns its storage path.
  Future<String> writeObject(String hexHash, List<int> encryptedData) async {
    final objectPath = paths.objectPath(hexHash);
    await writeAtomic(objectPath, encryptedData);
    return objectPath;
  }

  /// Reads an encrypted object by hash.
  Future<Uint8List?> readObject(String hexHash) async {
    return await readIfExists(paths.objectPath(hexHash));
  }

  /// Checks if an object exists.
  Future<bool> objectExists(String hexHash) async {
    return await _storage.exists(paths.objectPath(hexHash));
  }

  /// Lists all pending sync operations.
  Future<List<String>> listPendingOps() async {
    final files = await _storage.listFiles(paths.pendingOpsDir);
    return files
        .map((f) => p.basenameWithoutExtension(p.basenameWithoutExtension(f)))
        .toList();
  }

  /// Deletes a pending operation after successful sync.
  Future<void> deletePendingOp(String opId) async {
    final path = paths.pendingOpPath(opId);
    if (await _storage.exists(path)) {
      await _storage.deleteFile(path);
    }
  }

  /// Gets vault size in bytes (approximate for web).
  Future<int> calculateSize() async {
    // For now, return 0 - calculating size requires iterating all files
    // which is expensive. Implement proper size tracking later.
    return 0;
  }
}

