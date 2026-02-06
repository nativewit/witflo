// ═══════════════════════════════════════════════════════════════════════════
// WITFLO - Zero-Trust Notes OS
// Integration Tests - File Watchers + CRDT Sync
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:witflo_app/core/vault/file_change_notifier.dart';
import 'package:witflo_app/core/vault/native_file_watcher.dart';

void main() {
  group('File Watcher Integration Tests', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('witflo_sync_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('detects notes_index.json changes', () async {
      final watcher = NativeFileWatcher(
        directoryPath: tempDir.path,
        filePatterns: ['notes_index.json'],
        debounceInterval: const Duration(milliseconds: 300),
      );

      final changes = <FileChange>[];
      final subscription = watcher.changes.listen(changes.add);

      // Wait for watcher to initialize
      await Future.delayed(const Duration(milliseconds: 100));

      // Create notes_index.json file
      final indexFile = File('${tempDir.path}/notes_index.json');
      final indexData = {
        'note-1': {
          'id': 'note-1',
          'title': 'Test Note',
          'notebookId': 'notebook-1',
          'vaultId': 'vault-1',
          'status': 'active',
          'createdAt': DateTime.now().toIso8601String(),
          'modifiedAt': DateTime.now().toIso8601String(),
        },
      };

      await indexFile.writeAsString(json.encode(indexData));

      // Wait for debounce + processing
      await Future.delayed(const Duration(milliseconds: 500));

      expect(
        changes.isNotEmpty,
        isTrue,
        reason: 'Should detect notes_index.json change',
      );
      expect(
        changes.any((c) => c.path.endsWith('notes_index.json')),
        isTrue,
        reason: 'Should detect the specific file',
      );

      await subscription.cancel();
      watcher.dispose();
    });

    test('detects notebooks_index.json changes', () async {
      final watcher = NativeFileWatcher(
        directoryPath: tempDir.path,
        filePatterns: ['notebooks_index.json'],
        debounceInterval: const Duration(milliseconds: 300),
      );

      final changes = <FileChange>[];
      final subscription = watcher.changes.listen(changes.add);

      await Future.delayed(const Duration(milliseconds: 100));

      // Create notebooks_index.json file
      final indexFile = File('${tempDir.path}/notebooks_index.json');
      final indexData = {
        'notebook-1': {
          'id': 'notebook-1',
          'title': 'Test Notebook',
          'vaultId': 'vault-1',
          'status': 'active',
          'createdAt': DateTime.now().toIso8601String(),
          'modifiedAt': DateTime.now().toIso8601String(),
        },
      };

      await indexFile.writeAsString(json.encode(indexData));

      await Future.delayed(const Duration(milliseconds: 500));

      expect(changes.isNotEmpty, isTrue);
      expect(
        changes.any((c) => c.path.endsWith('notebooks_index.json')),
        isTrue,
      );

      await subscription.cancel();
      watcher.dispose();
    });

    test('detects sync_cursor.json changes', () async {
      final watcher = NativeFileWatcher(
        directoryPath: tempDir.path,
        filePatterns: ['sync_cursor.json'],
        debounceInterval: const Duration(milliseconds: 300),
      );

      final changes = <FileChange>[];
      final subscription = watcher.changes.listen(changes.add);

      await Future.delayed(const Duration(milliseconds: 100));

      // Create sync_cursor.json file
      final cursorFile = File('${tempDir.path}/sync_cursor.json');
      final cursorData = {
        'lastPullTimestamp': DateTime.now().millisecondsSinceEpoch,
        'lastPushTimestamp': DateTime.now().millisecondsSinceEpoch,
      };

      await cursorFile.writeAsString(json.encode(cursorData));

      await Future.delayed(const Duration(milliseconds: 500));

      expect(changes.isNotEmpty, isTrue);
      expect(changes.any((c) => c.path.endsWith('sync_cursor.json')), isTrue);

      await subscription.cancel();
      watcher.dispose();
    });

    test('detects multiple rapid changes with debouncing', () async {
      final watcher = NativeFileWatcher(
        directoryPath: tempDir.path,
        filePatterns: ['notes_index.json'],
        debounceInterval: const Duration(milliseconds: 500),
      );

      final changes = <FileChange>[];
      final subscription = watcher.changes.listen(changes.add);

      await Future.delayed(const Duration(milliseconds: 100));

      final indexFile = File('${tempDir.path}/notes_index.json');

      // Write file 5 times rapidly
      for (int i = 0; i < 5; i++) {
        final indexData = {
          'note-$i': {
            'id': 'note-$i',
            'title': 'Test Note $i',
            'notebookId': 'notebook-1',
            'vaultId': 'vault-1',
            'status': 'active',
            'createdAt': DateTime.now().toIso8601String(),
            'modifiedAt': DateTime.now().toIso8601String(),
          },
        };

        await indexFile.writeAsString(json.encode(indexData));
        // Small delay between writes
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // Wait for debounce to settle
      await Future.delayed(const Duration(milliseconds: 1000));

      // Should have fewer change events than actual writes (debouncing working)
      expect(
        changes.length,
        lessThan(5),
        reason: 'Debouncing should reduce event count',
      );
      expect(
        changes.length,
        greaterThan(0),
        reason: 'At least one event should fire',
      );

      await subscription.cancel();
      watcher.dispose();
    });

    test('stops detecting changes after disposal', () async {
      final watcher = NativeFileWatcher(
        directoryPath: tempDir.path,
        filePatterns: ['notes_index.json'],
        debounceInterval: const Duration(milliseconds: 300),
      );

      final changes = <FileChange>[];
      final subscription = watcher.changes.listen(changes.add);

      await Future.delayed(const Duration(milliseconds: 100));

      // Dispose watcher and subscription
      await subscription.cancel();
      watcher.dispose();

      // Try to create file after disposal
      final indexFile = File('${tempDir.path}/notes_index.json');
      await indexFile.writeAsString('{"test": "data"}');

      await Future.delayed(const Duration(milliseconds: 500));

      // No events should be detected
      expect(
        changes.isEmpty,
        isTrue,
        reason: 'Disposed watcher should not detect changes',
      );
    });

    test(
      'detects external file modification (simulating multi-device sync)',
      () async {
        // Create initial index file
        final indexFile = File('${tempDir.path}/notes_index.json');
        final initialData = {
          'note-1': {
            'id': 'note-1',
            'title': 'Initial Note',
            'status': 'active',
          },
        };
        await indexFile.writeAsString(json.encode(initialData));

        final watcher = NativeFileWatcher(
          directoryPath: tempDir.path,
          filePatterns: ['notes_index.json'],
          debounceInterval: const Duration(milliseconds: 300),
        );

        final changes = <FileChange>[];
        final subscription = watcher.changes.listen(changes.add);

        await Future.delayed(const Duration(milliseconds: 100));

        // Simulate external modification (like sync from another device)
        final updatedData = {
          'note-1': {
            'id': 'note-1',
            'title': 'Initial Note',
            'status': 'active',
          },
          'note-2': {
            'id': 'note-2',
            'title': 'Note from Another Device',
            'status': 'active',
          },
        };

        await indexFile.writeAsString(json.encode(updatedData));

        await Future.delayed(const Duration(milliseconds: 500));

        expect(
          changes.isNotEmpty,
          isTrue,
          reason: 'Should detect external modification',
        );

        final lastChange = changes.last;
        expect(lastChange.type, FileChangeType.modified);
        expect(lastChange.path, indexFile.path);
        expect(lastChange.contentHash, isNotNull);

        await subscription.cancel();
        watcher.dispose();
      },
    );

    test('content hash changes on actual content modification', () async {
      final indexFile = File('${tempDir.path}/notes_index.json');
      await indexFile.writeAsString('{"initial": "content"}');

      final watcher = NativeFileWatcher(
        directoryPath: tempDir.path,
        filePatterns: ['notes_index.json'],
        debounceInterval: const Duration(milliseconds: 300),
      );

      final changes = <FileChange>[];
      final subscription = watcher.changes.listen(changes.add);

      await Future.delayed(const Duration(milliseconds: 100));

      // First modification
      await indexFile.writeAsString('{"modified": "content1"}');
      await Future.delayed(const Duration(milliseconds: 500));

      final hash1 = changes.last.contentHash;

      // Second modification with different content
      await indexFile.writeAsString('{"modified": "content2"}');
      await Future.delayed(const Duration(milliseconds: 500));

      final hash2 = changes.last.contentHash;

      // Hashes should be different for different content
      expect(hash1, isNotNull);
      expect(hash2, isNotNull);
      expect(
        hash1,
        isNot(equals(hash2)),
        reason: 'Different content should have different hashes',
      );

      await subscription.cancel();
      watcher.dispose();
    });

    test('watches multiple file patterns simultaneously', () async {
      final watcher = NativeFileWatcher(
        directoryPath: tempDir.path,
        filePatterns: [
          'notes_index.json',
          'notebooks_index.json',
          'sync_cursor.json',
        ],
        debounceInterval: const Duration(milliseconds: 300),
      );

      final changes = <FileChange>[];
      final subscription = watcher.changes.listen(changes.add);

      await Future.delayed(const Duration(milliseconds: 100));

      // Create all three files
      final notesFile = File('${tempDir.path}/notes_index.json');
      final notebooksFile = File('${tempDir.path}/notebooks_index.json');
      final cursorFile = File('${tempDir.path}/sync_cursor.json');

      await notesFile.writeAsString('{"notes": []}');
      await Future.delayed(const Duration(milliseconds: 100));

      await notebooksFile.writeAsString('{"notebooks": []}');
      await Future.delayed(const Duration(milliseconds: 100));

      await cursorFile.writeAsString('{"cursor": 0}');
      await Future.delayed(const Duration(milliseconds: 500));

      // Should detect all three files
      expect(changes.length, greaterThanOrEqualTo(3));

      final notesChanges = changes.where(
        (c) => c.path.endsWith('notes_index.json'),
      );
      final notebooksChanges = changes.where(
        (c) => c.path.endsWith('notebooks_index.json'),
      );
      final cursorChanges = changes.where(
        (c) => c.path.endsWith('sync_cursor.json'),
      );

      expect(notesChanges.isNotEmpty, isTrue);
      expect(notebooksChanges.isNotEmpty, isTrue);
      expect(cursorChanges.isNotEmpty, isTrue);

      await subscription.cancel();
      watcher.dispose();
    });

    test('ignores unmatched file patterns', () async {
      final watcher = NativeFileWatcher(
        directoryPath: tempDir.path,
        filePatterns: ['notes_index.json'],
        debounceInterval: const Duration(milliseconds: 300),
      );

      final changes = <FileChange>[];
      final subscription = watcher.changes.listen(changes.add);

      await Future.delayed(const Duration(milliseconds: 100));

      // Create files that should NOT be watched
      final unrelatedFile1 = File('${tempDir.path}/other.txt');
      final unrelatedFile2 = File('${tempDir.path}/config.json');
      final unrelatedFile3 = File('${tempDir.path}/data.db');

      await unrelatedFile1.writeAsString('unrelated');
      await unrelatedFile2.writeAsString('{"config": true}');
      await unrelatedFile3.writeAsString('binary data');

      await Future.delayed(const Duration(milliseconds: 500));

      // No changes should be detected
      expect(
        changes.isEmpty,
        isTrue,
        reason: 'Should ignore unmatched patterns',
      );

      // Now create a watched file
      final notesFile = File('${tempDir.path}/notes_index.json');
      await notesFile.writeAsString('{"notes": []}');

      await Future.delayed(const Duration(milliseconds: 500));

      // This should be detected
      expect(changes.isNotEmpty, isTrue);
      expect(changes.length, equals(1));
      expect(changes[0].path, endsWith('notes_index.json'));

      await subscription.cancel();
      watcher.dispose();
    });
  });
}
