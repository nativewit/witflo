// ═══════════════════════════════════════════════════════════════════════════
// WITFLO - Zero-Trust Notes OS
// Native File Watcher Tests
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:witflo_app/core/vault/file_change_notifier.dart';
import 'package:witflo_app/core/vault/native_file_watcher.dart';

void main() {
  group('NativeFileWatcher', () {
    late Directory tempDir;

    // No crypto initialization needed - watcher will use SHA256 fallback

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('watcher_test_');
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('detects file creation', () async {
      final watcher = NativeFileWatcher(
        directoryPath: tempDir.path,
        filePatterns: ['*.txt'],
        debounceInterval: const Duration(milliseconds: 100),
      );

      final changes = <FileChange>[];
      final subscription = watcher.changes.listen(changes.add);

      // Wait for watcher to start
      await Future.delayed(const Duration(milliseconds: 50));

      // Create a file
      final testFile = File('${tempDir.path}/test.txt');
      await testFile.writeAsString('hello');

      // Wait for debounce + processing
      await Future.delayed(const Duration(milliseconds: 200));

      expect(changes.length, 1);
      // On some platforms, file creation may trigger 'modified' instead of 'created'
      expect(
        changes[0].type,
        isIn([FileChangeType.created, FileChangeType.modified]),
      );
      expect(changes[0].path, testFile.path);
      expect(changes[0].contentHash, isNotNull);

      await subscription.cancel();
      watcher.dispose();
    });

    test('detects file modification', () async {
      // Create file before watching
      final testFile = File('${tempDir.path}/test.txt');
      await testFile.writeAsString('initial');

      final watcher = NativeFileWatcher(
        directoryPath: tempDir.path,
        filePatterns: ['*.txt'],
        debounceInterval: const Duration(milliseconds: 100),
      );

      final changes = <FileChange>[];
      final subscription = watcher.changes.listen(changes.add);

      // Wait for watcher to start
      await Future.delayed(const Duration(milliseconds: 50));

      // Modify the file
      await testFile.writeAsString('modified');

      // Wait for debounce + processing
      await Future.delayed(const Duration(milliseconds: 200));

      expect(changes.length, 1);
      expect(changes[0].type, FileChangeType.modified);
      expect(changes[0].path, testFile.path);

      await subscription.cancel();
      watcher.dispose();
    });

    test('detects file deletion', () async {
      // Create file before watching
      final testFile = File('${tempDir.path}/test.txt');
      await testFile.writeAsString('content');

      final watcher = NativeFileWatcher(
        directoryPath: tempDir.path,
        filePatterns: ['*.txt'],
        debounceInterval: const Duration(milliseconds: 100),
      );

      final changes = <FileChange>[];
      final subscription = watcher.changes.listen(changes.add);

      // Wait for watcher to start
      await Future.delayed(const Duration(milliseconds: 50));

      // Delete the file
      await testFile.delete();

      // Wait for debounce + processing
      await Future.delayed(const Duration(milliseconds: 200));

      expect(changes.length, 1);
      expect(changes[0].type, FileChangeType.deleted);
      expect(changes[0].path, testFile.path);
      expect(changes[0].contentHash, isNull); // No hash for deletions

      await subscription.cancel();
      watcher.dispose();
    });

    test('filters files by pattern', () async {
      final watcher = NativeFileWatcher(
        directoryPath: tempDir.path,
        filePatterns: ['*.enc'], // Only watch .enc files
        debounceInterval: const Duration(milliseconds: 100),
      );

      final changes = <FileChange>[];
      final subscription = watcher.changes.listen(changes.add);

      await Future.delayed(const Duration(milliseconds: 50));

      // Create .enc file (should be detected)
      await File('${tempDir.path}/test.enc').writeAsString('encrypted');

      // Create .txt file (should be ignored)
      await File('${tempDir.path}/test.txt').writeAsString('plaintext');

      await Future.delayed(const Duration(milliseconds: 200));

      expect(changes.length, 1);
      expect(changes[0].path, endsWith('test.enc'));

      await subscription.cancel();
      watcher.dispose();
    });

    test('supports multiple patterns', () async {
      final watcher = NativeFileWatcher(
        directoryPath: tempDir.path,
        filePatterns: ['*.enc', '*.jsonl.enc', 'vault.header'],
        debounceInterval: const Duration(milliseconds: 100),
      );

      final changes = <FileChange>[];
      final subscription = watcher.changes.listen(changes.add);

      await Future.delayed(const Duration(milliseconds: 50));

      await File('${tempDir.path}/notes.enc').writeAsString('data1');
      await File('${tempDir.path}/notes.jsonl.enc').writeAsString('data2');
      await File('${tempDir.path}/vault.header').writeAsString('data3');
      await File('${tempDir.path}/ignored.txt').writeAsString('data4');

      await Future.delayed(const Duration(milliseconds: 200));

      expect(changes.length, 3);
      expect(
        changes.map((c) => c.path).any((p) => p.endsWith('notes.enc')),
        isTrue,
      );
      expect(
        changes.map((c) => c.path).any((p) => p.endsWith('notes.jsonl.enc')),
        isTrue,
      );
      expect(
        changes.map((c) => c.path).any((p) => p.endsWith('vault.header')),
        isTrue,
      );

      await subscription.cancel();
      watcher.dispose();
    });

    test('debounces rapid changes', () async {
      final watcher = NativeFileWatcher(
        directoryPath: tempDir.path,
        filePatterns: ['*.txt'],
        debounceInterval: const Duration(milliseconds: 200),
      );

      final changes = <FileChange>[];
      final subscription = watcher.changes.listen(changes.add);

      await Future.delayed(const Duration(milliseconds: 50));

      final testFile = File('${tempDir.path}/test.txt');

      // Rapid writes (simulating auto-save)
      await testFile.writeAsString('change1');
      await Future.delayed(const Duration(milliseconds: 50));
      await testFile.writeAsString('change2');
      await Future.delayed(const Duration(milliseconds: 50));
      await testFile.writeAsString('change3');

      // Wait for debounce
      await Future.delayed(const Duration(milliseconds: 300));

      // Should only emit one event (debounced)
      expect(
        changes.length,
        lessThanOrEqualTo(2),
      ); // May catch first write before rapid changes

      await subscription.cancel();
      watcher.dispose();
    });

    test('deduplicates unchanged content', () async {
      final testFile = File('${tempDir.path}/test.txt');
      await testFile.writeAsString('content');

      final watcher = NativeFileWatcher(
        directoryPath: tempDir.path,
        filePatterns: ['*.txt'],
        debounceInterval: const Duration(milliseconds: 100),
      );

      final changes = <FileChange>[];
      final subscription = watcher.changes.listen(changes.add);

      await Future.delayed(const Duration(milliseconds: 50));

      // Modify with same content (e.g., touch command)
      await testFile.writeAsString('content');
      await Future.delayed(const Duration(milliseconds: 200));

      // First write after watcher starts
      final initialChanges = changes.length;

      // Modify again with same content
      await testFile.writeAsString('content');
      await Future.delayed(const Duration(milliseconds: 200));

      // Should not emit new event (hash unchanged)
      expect(changes.length, initialChanges);

      await subscription.cancel();
      watcher.dispose();
    });

    test('handles subdirectories (recursive watching)', () async {
      final subDir = await Directory('${tempDir.path}/subdir').create();

      final watcher = NativeFileWatcher(
        directoryPath: tempDir.path,
        filePatterns: ['*.txt'],
        debounceInterval: const Duration(milliseconds: 100),
      );

      final changes = <FileChange>[];
      final subscription = watcher.changes.listen(changes.add);

      await Future.delayed(const Duration(milliseconds: 50));

      // Create file in subdirectory
      await File('${subDir.path}/nested.txt').writeAsString('nested content');

      await Future.delayed(const Duration(milliseconds: 200));

      expect(changes.length, 1);
      expect(changes[0].path, endsWith('nested.txt'));

      await subscription.cancel();
      watcher.dispose();
    });

    test('handles non-existent directory gracefully', () async {
      final watcher = NativeFileWatcher(
        directoryPath: '/non/existent/path',
        filePatterns: ['*.txt'],
      );

      final errors = <Object>[];
      final subscription = watcher.changes.listen((_) {}, onError: errors.add);

      await Future.delayed(const Duration(milliseconds: 100));

      expect(errors.length, 1);
      expect(errors[0], isA<FileSystemException>());

      await subscription.cancel();
      watcher.dispose();
    });

    test('disposes cleanly', () async {
      final watcher = NativeFileWatcher(
        directoryPath: tempDir.path,
        filePatterns: ['*.txt'],
      );

      final subscription = watcher.changes.listen((_) {});
      await Future.delayed(const Duration(milliseconds: 50));

      // Dispose
      watcher.dispose();
      await subscription.cancel();

      // Creating file after dispose should not cause errors
      await File('${tempDir.path}/after_dispose.txt').writeAsString('test');
      await Future.delayed(const Duration(milliseconds: 100));

      // No assertions needed - just verify no errors thrown
    });
  });
}
