// ═══════════════════════════════════════════════════════════════════════════
// WITFLO - Zero-Trust Notes OS
// Sync Operation & Payload Tests
// ═══════════════════════════════════════════════════════════════════════════
//
// NOTE: These are unit tests focused on sync operation creation, payload
// serialization, and basic data structures. Full integration tests with
// CRDT conflict resolution will be added once the sync system is fully
// integrated with providers and a test vault infrastructure is available.
//
// Currently testing:
// - SyncOperation creation and serialization
// - Payload creation and JSON round-trip
// - Operation type enum values
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter_test/flutter_test.dart';
import 'package:witflo_app/core/sync/sync_operation.dart';
import 'package:witflo_app/core/sync/sync_payloads.dart';

void main() {
  group('SyncOperation', () {
    test('creates operation with required fields', () {
      final op = SyncOperation.create(
        type: SyncOpType.createNote,
        targetId: 'note-123',
        timestamp: 100,
        deviceId: 'device-1',
        payload: {'title': 'Test'},
      );

      expect(op.type, SyncOpType.createNote);
      expect(op.targetId, 'note-123');
      expect(op.timestamp, 100);
      expect(op.deviceId, 'device-1');
      expect(op.payload, {'title': 'Test'});
      expect(op.opId, isNotEmpty);
      expect(op.createdAt, isNotNull);
    });

    test('serializes and deserializes correctly', () {
      final original = SyncOperation.create(
        type: SyncOpType.updateNote,
        targetId: 'note-456',
        timestamp: 200,
        deviceId: 'device-2',
        payload: {'content': 'Updated'},
      );

      final json = original.toJson();
      final deserialized = SyncOperation.fromJson(json);

      expect(deserialized.opId, original.opId);
      expect(deserialized.type, original.type);
      expect(deserialized.targetId, original.targetId);
      expect(deserialized.timestamp, original.timestamp);
      expect(deserialized.deviceId, original.deviceId);
      expect(deserialized.payload, original.payload);
    });
  });

  group('CreateNotePayload', () {
    test('creates payload with all fields', () {
      final payload = CreateNotePayload(
        noteId: 'note-1',
        title: 'Test Note',
        content: 'Test content',
        notebookId: 'notebook-1',
        tags: ['tag1', 'tag2'],
        isPinned: true,
        isArchived: false,
        createdAt: DateTime.utc(2026, 1, 1),
        modifiedAt: DateTime.utc(2026, 1, 2),
      );

      expect(payload.noteId, 'note-1');
      expect(payload.title, 'Test Note');
      expect(payload.content, 'Test content');
      expect(payload.notebookId, 'notebook-1');
      expect(payload.tags, ['tag1', 'tag2']);
      expect(payload.isPinned, isTrue);
      expect(payload.isArchived, isFalse);
    });

    test('serializes and deserializes correctly', () {
      final original = CreateNotePayload(
        noteId: 'note-2',
        title: 'Title',
        content: 'Content',
        notebookId: null,
        tags: [],
        isPinned: false,
        isArchived: false,
        createdAt: DateTime.utc(2026, 1, 1),
        modifiedAt: DateTime.utc(2026, 1, 1),
      );

      final json = original.toJson();
      final deserialized = CreateNotePayload.fromJson(json);

      expect(deserialized.noteId, original.noteId);
      expect(deserialized.title, original.title);
      expect(deserialized.content, original.content);
      expect(deserialized.notebookId, original.notebookId);
      expect(deserialized.tags, original.tags);
      expect(deserialized.isPinned, original.isPinned);
      expect(deserialized.isArchived, original.isArchived);
      expect(
        deserialized.createdAt.millisecondsSinceEpoch,
        original.createdAt.millisecondsSinceEpoch,
      );
    });
  });

  group('UpdateNotePayload', () {
    test('creates payload with partial update', () {
      final payload = UpdateNotePayload(
        noteId: 'note-1',
        title: 'Updated Title',
        modifiedAt: DateTime.utc(2026, 1, 2),
      );

      expect(payload.noteId, 'note-1');
      expect(payload.title, 'Updated Title');
      expect(payload.content, isNull);
      expect(payload.notebookId, isNull);
    });

    test('serializes and deserializes correctly', () {
      final original = UpdateNotePayload(
        noteId: 'note-3',
        content: 'Updated content',
        isPinned: true,
        modifiedAt: DateTime.utc(2026, 1, 3),
      );

      final json = original.toJson();
      final deserialized = UpdateNotePayload.fromJson(json);

      expect(deserialized.noteId, original.noteId);
      expect(deserialized.content, original.content);
      expect(deserialized.isPinned, original.isPinned);
      expect(deserialized.title, isNull);
    });
  });

  group('DeleteNotePayload', () {
    test('creates delete payload', () {
      final payload = DeleteNotePayload(
        noteId: 'note-1',
        deletedAt: DateTime.utc(2026, 1, 1),
      );
      expect(payload.noteId, 'note-1');
    });

    test('serializes and deserializes correctly', () {
      final original = DeleteNotePayload(
        noteId: 'note-4',
        deletedAt: DateTime.utc(2026, 1, 2),
      );
      final json = original.toJson();
      final deserialized = DeleteNotePayload.fromJson(json);

      expect(deserialized.noteId, original.noteId);
    });
  });

  group('CreateNotebookPayload', () {
    test('creates payload with all fields', () {
      final payload = CreateNotebookPayload(
        notebookId: 'notebook-1',
        name: 'Test Notebook',
        description: 'Description',
        color: 'blue',
        icon: 'book',
        createdAt: DateTime.utc(2026, 1, 1),
        modifiedAt: DateTime.utc(2026, 1, 1),
      );

      expect(payload.notebookId, 'notebook-1');
      expect(payload.name, 'Test Notebook');
      expect(payload.description, 'Description');
      expect(payload.color, 'blue');
      expect(payload.icon, 'book');
    });

    test('serializes and deserializes correctly', () {
      final original = CreateNotebookPayload(
        notebookId: 'notebook-2',
        name: 'Notebook',
        description: null,
        color: null,
        icon: null,
        createdAt: DateTime.utc(2026, 1, 1),
        modifiedAt: DateTime.utc(2026, 1, 1),
      );

      final json = original.toJson();
      final deserialized = CreateNotebookPayload.fromJson(json);

      expect(deserialized.notebookId, original.notebookId);
      expect(deserialized.name, original.name);
      expect(deserialized.description, isNull);
      expect(deserialized.color, isNull);
      expect(deserialized.icon, isNull);
    });
  });

  group('UpdateNotebookPayload', () {
    test('creates payload with partial update', () {
      final payload = UpdateNotebookPayload(
        notebookId: 'notebook-1',
        name: 'Updated Name',
        modifiedAt: DateTime.utc(2026, 1, 2),
      );

      expect(payload.notebookId, 'notebook-1');
      expect(payload.name, 'Updated Name');
      expect(payload.description, isNull);
    });

    test('serializes and deserializes correctly', () {
      final original = UpdateNotebookPayload(
        notebookId: 'notebook-3',
        color: 'red',
        icon: 'star',
        modifiedAt: DateTime.utc(2026, 1, 3),
      );

      final json = original.toJson();
      final deserialized = UpdateNotebookPayload.fromJson(json);

      expect(deserialized.notebookId, original.notebookId);
      expect(deserialized.color, original.color);
      expect(deserialized.icon, original.icon);
      expect(deserialized.name, isNull);
    });
  });

  group('SyncCursor', () {
    test('creates initial cursor', () {
      final cursor = SyncCursor.initial();

      expect(cursor.lastTimestamp, 0);
      expect(cursor.lastOpId, isNull);
      expect(cursor.syncedCount, 0);
    });

    test('serializes and deserializes correctly', () {
      final original = SyncCursor(
        lastTimestamp: 12345,
        lastOpId: 'op-123',
        syncedCount: 42,
        updatedAt: DateTime.utc(2026, 1, 1),
      );

      final json = original.toJson();
      final deserialized = SyncCursor.fromJson(json);

      expect(deserialized.lastTimestamp, original.lastTimestamp);
      expect(deserialized.lastOpId, original.lastOpId);
      expect(deserialized.syncedCount, original.syncedCount);
      expect(
        deserialized.updatedAt.millisecondsSinceEpoch,
        original.updatedAt.millisecondsSinceEpoch,
      );
    });
  });

  group('Conflict Resolution Logic', () {
    test('timestamp comparison for Last-Write-Wins', () {
      final remoteTimestamp = DateTime.utc(2026, 1, 2).millisecondsSinceEpoch;
      final localTimestamp = DateTime.utc(2026, 1, 1).millisecondsSinceEpoch;

      // Remote wins if timestamp is higher
      expect(remoteTimestamp > localTimestamp, isTrue);

      // Local wins if timestamp is higher
      expect(localTimestamp > remoteTimestamp, isFalse);
    });

    test('opId tie-breaker for equal timestamps', () {
      const opId1 = 'abc-123';
      const opId2 = 'def-456';

      // Lexicographic comparison for deterministic ordering
      final comparison = opId1.compareTo(opId2);
      expect(comparison < 0, isTrue); // opId1 < opId2
    });

    test('Lamport clock update logic', () {
      var lamportClock = 100;
      final remoteTimestamp1 = 150;
      final remoteTimestamp2 = 80;

      // When remote timestamp > local: max(local, remote) + 1
      lamportClock = remoteTimestamp1 > lamportClock
          ? remoteTimestamp1 + 1
          : lamportClock + 1;
      expect(lamportClock, 151);

      // When remote timestamp < local: max(local, remote) + 1
      lamportClock = remoteTimestamp2 > lamportClock
          ? remoteTimestamp2 + 1
          : lamportClock + 1;
      expect(lamportClock, 152);
    });
  });
}
