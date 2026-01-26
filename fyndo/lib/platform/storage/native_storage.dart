// ═══════════════════════════════════════════════════════════════════════════
// FYNDO - Zero-Trust Notes OS
// Native Storage - File System Based Storage for Native Platforms
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:io';
import 'dart:typed_data';

import 'package:fyndo_app/platform/storage/storage_provider.dart';

/// Native storage implementation using dart:io.
class NativeStorageProvider implements StorageProvider {
  @override
  Future<void> initialize() async {
    // No initialization needed for native file system
  }

  @override
  Future<bool> exists(String path) async {
    return File(path).exists();
  }

  @override
  Future<bool> directoryExists(String path) async {
    return Directory(path).exists();
  }

  @override
  Future<void> createDirectory(String path) async {
    await Directory(path).create(recursive: true);
  }

  @override
  Future<Uint8List?> readFile(String path) async {
    final file = File(path);
    if (await file.exists()) {
      return file.readAsBytes();
    }
    return null;
  }

  @override
  Future<String?> readFileAsString(String path) async {
    final file = File(path);
    if (await file.exists()) {
      return file.readAsString();
    }
    return null;
  }

  @override
  Future<void> writeFile(String path, List<int> data) async {
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(data);
  }

  @override
  Future<void> writeFileAsString(String path, String data) async {
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsString(data);
  }

  @override
  Future<void> writeAtomic(String path, List<int> data) async {
    final file = File(path);
    await file.parent.create(recursive: true);

    final tempPath = '$path.tmp';
    final tempFile = File(tempPath);

    await tempFile.writeAsBytes(data);
    await tempFile.rename(path);
  }

  @override
  Future<void> deleteFile(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  Future<void> deleteDirectory(String path) async {
    final dir = Directory(path);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }

  @override
  Future<List<String>> listDirectory(String path) async {
    final dir = Directory(path);
    if (!await dir.exists()) {
      return [];
    }

    final entities = await dir.list().toList();
    return entities.map((e) => e.path).toList();
  }

  @override
  Future<List<String>> listFiles(String path) async {
    final dir = Directory(path);
    if (!await dir.exists()) {
      return [];
    }

    final entities = await dir.list().toList();
    return entities
        .whereType<File>()
        .map((e) => e.path)
        .toList();
  }

  @override
  Future<void> copyFile(String from, String to) async {
    final file = File(from);
    await File(to).parent.create(recursive: true);
    await file.copy(to);
  }

  @override
  Future<void> moveFile(String from, String to) async {
    final file = File(from);
    await File(to).parent.create(recursive: true);
    await file.rename(to);
  }
}

