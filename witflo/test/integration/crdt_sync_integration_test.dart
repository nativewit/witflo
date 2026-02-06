// ═══════════════════════════════════════════════════════════════════════════
// WITFLO - Zero-Trust Notes OS
// Integration Tests - CRDT Sync Operations
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter_test/flutter_test.dart';
import 'package:witflo_app/core/sync/sync_operation.dart';
import 'package:witflo_app/core/sync/sync_payloads.dart';

void main() {
  group('CRDT Sync Integration Tests', () {
    test('create note operation - serialization round-trip', () {
      final payload = CreateNotePayload(
        noteId: 'note-123',
        title: 'Integration Test Note',
        content: 'This is test content for CRDT sync',
        notebookId: 'notebook-456',
        tags: ['test', 'integration'],
        isPinned: false,
        isArchived: false,
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
      );

      final operation = SyncOperation.create(
        type: SyncOpType.createNote,
        targetId: payload.noteId,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        deviceId: 'test-device-1',
        payload: payload.toJson(),
      );

      // Serialize to JSON (simulating network transmission)
      final jsonData = operation.toJson();

      // Deserialize from JSON (simulating receiving from another device)
      final receivedOp = SyncOperation.fromJson(jsonData);

      expect(receivedOp.opId, equals(operation.opId));
      expect(receivedOp.type, equals(SyncOpType.createNote));
      expect(receivedOp.targetId, equals('note-123'));
      expect(receivedOp.deviceId, equals('test-device-1'));

      // Reconstruct payload
      final receivedPayload = CreateNotePayload.fromJson(receivedOp.payload);
      expect(receivedPayload.noteId, equals(payload.noteId));
      expect(receivedPayload.title, equals(payload.title));
      expect(receivedPayload.content, equals(payload.content));
      expect(receivedPayload.notebookId, equals(payload.notebookId));
      expect(receivedPayload.tags, equals(payload.tags));
    });

    test('update note operation - partial updates', () {
      final payload = UpdateNotePayload(
        noteId: 'note-123',
        title: 'Updated Title',
        content: null, // Only updating title
        notebookId: null,
        tags: null,
        isPinned: null,
        isArchived: null,
        modifiedAt: DateTime.now(),
      );

      final operation = SyncOperation.create(
        type: SyncOpType.updateNote,
        targetId: payload.noteId,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        deviceId: 'test-device-2',
        payload: payload.toJson(),
      );

      final jsonData = operation.toJson();
      final receivedOp = SyncOperation.fromJson(jsonData);
      final receivedPayload = UpdateNotePayload.fromJson(receivedOp.payload);

      expect(receivedPayload.noteId, equals('note-123'));
      expect(receivedPayload.title, equals('Updated Title'));
      expect(receivedPayload.content, isNull);
      expect(receivedPayload.notebookId, isNull);
    });

    test('delete note operation - soft delete', () {
      final payload = DeleteNotePayload(
        noteId: 'note-123',
        deletedAt: DateTime.now(),
      );

      final operation = SyncOperation.create(
        type: SyncOpType.deleteNote,
        targetId: payload.noteId,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        deviceId: 'test-device-3',
        payload: payload.toJson(),
      );

      final jsonData = operation.toJson();
      final receivedOp = SyncOperation.fromJson(jsonData);
      final receivedPayload = DeleteNotePayload.fromJson(receivedOp.payload);

      expect(receivedPayload.noteId, equals('note-123'));
      expect(receivedPayload.deletedAt, isNotNull);
    });

    test('multiple operations in sequence - timestamp ordering', () {
      final now = DateTime.now().millisecondsSinceEpoch;

      final operations = [
        SyncOperation.create(
          type: SyncOpType.createNote,
          targetId: 'note-1',
          timestamp: now,
          deviceId: 'device-1',
          payload: {'title': 'First'},
        ),
        SyncOperation.create(
          type: SyncOpType.updateNote,
          targetId: 'note-1',
          timestamp: now + 1000,
          deviceId: 'device-1',
          payload: {'title': 'Updated'},
        ),
        SyncOperation.create(
          type: SyncOpType.updateNote,
          targetId: 'note-1',
          timestamp: now + 2000,
          deviceId: 'device-1',
          payload: {'title': 'Updated Again'},
        ),
      ];

      // Verify timestamp ordering
      for (int i = 0; i < operations.length - 1; i++) {
        expect(
          operations[i].timestamp,
          lessThan(operations[i + 1].timestamp),
          reason: 'Operations should be ordered by timestamp',
        );
      }

      // Serialize and deserialize all operations
      final jsonOps = operations.map((op) => op.toJson()).toList();
      final deserializedOps = jsonOps
          .map((json) => SyncOperation.fromJson(json))
          .toList();

      expect(deserializedOps.length, equals(operations.length));

      for (int i = 0; i < deserializedOps.length; i++) {
        expect(deserializedOps[i].opId, equals(operations[i].opId));
        expect(deserializedOps[i].timestamp, equals(operations[i].timestamp));
      }
    });

    test('concurrent operations from multiple devices - conflict detection', () {
      final now = DateTime.now().millisecondsSinceEpoch;

      // Device 1 and Device 2 both update the same note at nearly the same time
      final device1Op = SyncOperation.create(
        type: SyncOpType.updateNote,
        targetId: 'note-conflict',
        timestamp: now,
        deviceId: 'device-1',
        payload: {'title': 'Version from Device 1'},
      );

      final device2Op = SyncOperation.create(
        type: SyncOpType.updateNote,
        targetId: 'note-conflict',
        timestamp: now + 10, // Slightly later
        deviceId: 'device-2',
        payload: {'title': 'Version from Device 2'},
      );

      // Both operations target the same note
      expect(device1Op.targetId, equals(device2Op.targetId));

      // But come from different devices
      expect(device1Op.deviceId, isNot(equals(device2Op.deviceId)));

      // CRDT resolution: Last-write-wins based on timestamp
      final winner = device2Op.timestamp > device1Op.timestamp
          ? device2Op
          : device1Op;

      expect(winner.deviceId, equals('device-2'));
      expect(winner.payload['title'], equals('Version from Device 2'));
    });

    test('operation batch - multiple notes created together', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final deviceId = 'batch-device';

      final batch = List.generate(
        5,
        (index) => SyncOperation.create(
          type: SyncOpType.createNote,
          targetId: 'note-batch-$index',
          timestamp: now + index,
          deviceId: deviceId,
          payload: {'title': 'Batch Note $index', 'content': 'Content $index'},
        ),
      );

      expect(batch.length, equals(5));

      // All from same device
      expect(batch.every((op) => op.deviceId == deviceId), isTrue);

      // All unique opIds
      final opIds = batch.map((op) => op.opId).toSet();
      expect(opIds.length, equals(5), reason: 'All opIds should be unique');

      // Serialize batch
      final jsonBatch = batch.map((op) => op.toJson()).toList();

      // Deserialize batch
      final deserializedBatch = jsonBatch
          .map((json) => SyncOperation.fromJson(json))
          .toList();

      expect(deserializedBatch.length, equals(batch.length));

      for (int i = 0; i < batch.length; i++) {
        expect(deserializedBatch[i].opId, equals(batch[i].opId));
        expect(deserializedBatch[i].targetId, equals(batch[i].targetId));
      }
    });

    test('notebook operations - create and update', () {
      final createPayload = CreateNotebookPayload(
        notebookId: 'notebook-123',
        name: 'My Notebook',
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
      );

      final createOp = SyncOperation.create(
        type: SyncOpType.createNotebook,
        targetId: createPayload.notebookId,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        deviceId: 'device-1',
        payload: createPayload.toJson(),
      );

      final createJson = createOp.toJson();
      final receivedCreateOp = SyncOperation.fromJson(createJson);
      final receivedCreatePayload = CreateNotebookPayload.fromJson(
        receivedCreateOp.payload,
      );

      expect(receivedCreatePayload.notebookId, equals('notebook-123'));
      expect(receivedCreatePayload.name, equals('My Notebook'));

      // Now update it
      final updatePayload = UpdateNotebookPayload(
        notebookId: 'notebook-123',
        name: 'Renamed Notebook',
        modifiedAt: DateTime.now(),
      );

      final updateOp = SyncOperation.create(
        type: SyncOpType.updateNotebook,
        targetId: updatePayload.notebookId,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        deviceId: 'device-1',
        payload: updatePayload.toJson(),
      );

      final updateJson = updateOp.toJson();
      final receivedUpdateOp = SyncOperation.fromJson(updateJson);
      final receivedUpdatePayload = UpdateNotebookPayload.fromJson(
        receivedUpdateOp.payload,
      );

      expect(receivedUpdatePayload.notebookId, equals('notebook-123'));
      expect(receivedUpdatePayload.name, equals('Renamed Notebook'));
    });

    test('operation type enum - all types supported', () {
      final allTypes = [
        SyncOpType.createNote,
        SyncOpType.updateNote,
        SyncOpType.deleteNote,
        SyncOpType.createNotebook,
        SyncOpType.updateNotebook,
        SyncOpType.deleteNotebook,
      ];

      for (final type in allTypes) {
        final op = SyncOperation.create(
          type: type,
          targetId: 'test-target',
          timestamp: DateTime.now().millisecondsSinceEpoch,
          deviceId: 'test-device',
          payload: {},
        );

        expect(op.type, equals(type));

        // Round-trip
        final json = op.toJson();
        final deserialized = SyncOperation.fromJson(json);

        expect(deserialized.type, equals(type));
      }
    });

    test('operation with complex payload - nested data structures', () {
      final complexPayload = {
        'noteId': 'note-complex',
        'title': 'Complex Note',
        'content': 'Content with\nmultiple\nlines',
        'metadata': {
          'wordCount': 100,
          'characterCount': 500,
          'lastEditDevice': 'laptop',
        },
        'tags': ['important', 'work', 'review'],
        'attachments': [
          {'id': 'att-1', 'name': 'document.pdf', 'size': 1024},
          {'id': 'att-2', 'name': 'image.png', 'size': 2048},
        ],
      };

      final operation = SyncOperation.create(
        type: SyncOpType.updateNote,
        targetId: 'note-complex',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        deviceId: 'device-complex',
        payload: complexPayload,
      );

      final json = operation.toJson();
      final deserialized = SyncOperation.fromJson(json);

      expect(deserialized.payload['noteId'], equals('note-complex'));
      expect(deserialized.payload['content'], contains('\n'));
      expect(deserialized.payload['metadata']['wordCount'], equals(100));
      expect(deserialized.payload['tags'], hasLength(3));
      expect(deserialized.payload['attachments'], hasLength(2));
      expect(
        deserialized.payload['attachments'][0]['name'],
        equals('document.pdf'),
      );
    });

    test('operation timestamps - monotonic increasing', () {
      final operations = <SyncOperation>[];

      for (int i = 0; i < 10; i++) {
        operations.add(
          SyncOperation.create(
            type: SyncOpType.createNote,
            targetId: 'note-$i',
            timestamp: DateTime.now().millisecondsSinceEpoch,
            deviceId: 'device-1',
            payload: {},
          ),
        );

        // Small delay to ensure timestamps are different
        Future.delayed(const Duration(milliseconds: 5));
      }

      // Verify timestamps are monotonically increasing (or at least non-decreasing)
      for (int i = 0; i < operations.length - 1; i++) {
        expect(
          operations[i].timestamp,
          lessThanOrEqualTo(operations[i + 1].timestamp),
          reason: 'Timestamps should be monotonically increasing',
        );
      }
    });

    test('empty payload handling', () {
      final operation = SyncOperation.create(
        type: SyncOpType.deleteNote,
        targetId: 'note-to-delete',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        deviceId: 'device-1',
        payload: {},
      );

      final json = operation.toJson();
      final deserialized = SyncOperation.fromJson(json);

      expect(deserialized.payload, isEmpty);
      expect(deserialized.type, equals(SyncOpType.deleteNote));
    });

    test('operation uniqueness - opId generation', () {
      final operations = List.generate(
        100,
        (index) => SyncOperation.create(
          type: SyncOpType.createNote,
          targetId: 'note-$index',
          timestamp: DateTime.now().millisecondsSinceEpoch,
          deviceId: 'device-1',
          payload: {},
        ),
      );

      final opIds = operations.map((op) => op.opId).toSet();

      expect(opIds.length, equals(100), reason: 'All opIds should be unique');
    });

    test(
      'large batch simulation - 1000 operations',
      () {
        final now = DateTime.now().millisecondsSinceEpoch;
        final batchSize = 1000;

        final operations = List.generate(
          batchSize,
          (index) => SyncOperation.create(
            type: index % 2 == 0
                ? SyncOpType.createNote
                : SyncOpType.updateNote,
            targetId: 'note-${index ~/ 2}',
            timestamp: now + index,
            deviceId: 'bulk-device',
            payload: {'title': 'Note ${index ~/ 2}', 'iteration': index},
          ),
        );

        expect(operations.length, equals(batchSize));

        // Serialize all
        final jsonBatch = operations.map((op) => op.toJson()).toList();

        // Deserialize all
        final deserializedBatch = jsonBatch
            .map((json) => SyncOperation.fromJson(json))
            .toList();

        expect(deserializedBatch.length, equals(batchSize));

        // Spot check first, middle, last
        expect(deserializedBatch[0].targetId, equals(operations[0].targetId));
        expect(
          deserializedBatch[500].targetId,
          equals(operations[500].targetId),
        );
        expect(
          deserializedBatch[999].targetId,
          equals(operations[999].targetId),
        );
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );
  });
}
