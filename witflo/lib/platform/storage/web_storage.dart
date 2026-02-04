// ═══════════════════════════════════════════════════════════════════════════
// WITFLO - Zero-Trust Notes OS
// Web Storage - In-Memory Storage for Web Platform (Stub)
// ═══════════════════════════════════════════════════════════════════════════
//
// On web, we use an in-memory virtual file system.
// For production, this should be replaced with proper IndexedDB via package:web.
//
// NOTE: This is a simplified implementation. For persistence across sessions,
// implement proper IndexedDB storage using the 'web' package.
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'dart:typed_data';

import 'package:witflo_app/platform/storage/storage_provider.dart';

/// Web storage implementation using in-memory map.
///
/// This is a stub implementation that stores everything in memory.
/// Data will be lost on page refresh. For production, implement
/// proper IndexedDB storage using package:web.
class WebStorageProvider implements StorageProvider {
  /// In-memory storage (path -> base64 encoded data)
  final Map<String, String> _storage = {};

  @override
  Future<void> initialize() async {
    // No initialization needed for in-memory storage
  }

  @override
  Future<bool> exists(String path) async {
    return _storage.containsKey(path);
  }

  @override
  Future<bool> directoryExists(String path) async {
    // In virtual FS, directories exist if any file has that prefix
    final prefix = path.endsWith('/') ? path : '$path/';
    return _storage.keys.any((key) => key.startsWith(prefix));
  }

  @override
  Future<void> createDirectory(String path) async {
    // Virtual directories don't need explicit creation
    // They exist implicitly when files are created
  }

  @override
  Future<Uint8List?> readFile(String path) async {
    final data = _storage[path];
    if (data == null) return null;
    return Uint8List.fromList(base64Decode(data));
  }

  @override
  Future<String?> readFileAsString(String path) async {
    final data = await readFile(path);
    if (data == null) return null;
    return utf8.decode(data);
  }

  @override
  Future<void> writeFile(String path, List<int> data) async {
    _storage[path] = base64Encode(data);
  }

  @override
  Future<void> writeFileAsString(String path, String data) async {
    await writeFile(path, utf8.encode(data));
  }

  @override
  Future<void> writeAtomic(String path, List<int> data) async {
    // In-memory writes are effectively atomic
    await writeFile(path, data);
  }

  @override
  Future<void> deleteFile(String path) async {
    _storage.remove(path);
  }

  @override
  Future<void> deleteDirectory(String path) async {
    final prefix = path.endsWith('/') ? path : '$path/';
    _storage.removeWhere((key, value) => key.startsWith(prefix) || key == path);
  }

  @override
  Future<List<String>> listDirectory(String path) async {
    final prefix = path.endsWith('/') ? path : '$path/';
    return _storage.keys.where((key) => key.startsWith(prefix)).toList();
  }

  @override
  Future<List<String>> listFiles(String path) async {
    // In virtual FS, everything is a file
    return listDirectory(path);
  }

  @override
  Future<void> copyFile(String from, String to) async {
    final data = _storage[from];
    if (data != null) {
      _storage[to] = data;
    }
  }

  @override
  Future<void> moveFile(String from, String to) async {
    await copyFile(from, to);
    await deleteFile(from);
  }
}
