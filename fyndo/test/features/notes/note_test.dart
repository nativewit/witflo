// ═══════════════════════════════════════════════════════════════════════════
// FYNDO - Zero-Trust Notes OS
// Note Tests - Note Model and Repository Tests
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fyndo_app/core/crypto/crypto.dart';
import 'package:fyndo_app/core/vault/vault.dart';
import 'package:fyndo_app/features/notes/data/note_repository.dart';
import 'package:fyndo_app/features/notes/models/note.dart';

void main() {
  late CryptoService crypto;
  late VaultService vaultService;
  late Directory tempDir;

  setUpAll(() async {
    crypto = await CryptoService.initialize();
    vaultService = VaultService(crypto);
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('fyndo_note_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Note Model', () {
    test('should create note with generated ID', () {
      final note = Note.create(title: 'Test Note', content: 'Some content');

      expect(note.id, isNotEmpty);
      expect(note.title, equals('Test Note'));
      expect(note.content, equals('Some content'));
      expect(note.version, equals(1));
      expect(note.isPinned, isFalse);
      expect(note.isTrashed, isFalse);
    });

    test('should create note with notebook and tags', () {
      final note = Note.create(
        title: 'Tagged Note',
        content: 'Content',
        notebookId: 'notebook-123',
        tags: ['tag1', 'tag2'],
      );

      expect(note.notebookId, equals('notebook-123'));
      expect(note.tags, contains('tag1'));
      expect(note.tags, contains('tag2'));
    });

    test('should increment version on copyWith', () {
      final note = Note.create(title: 'Original', content: 'Content');

      expect(note.version, equals(1));

      final updated = note.copyWith(title: 'Updated');

      expect(updated.version, equals(2));
      expect(updated.title, equals('Updated'));
    });

    test('should move to trash', () {
      final note = Note.create(title: 'Note', content: 'Content');

      final trashed = note.trash();

      expect(trashed.isTrashed, isTrue);
      expect(trashed.trashedAt, isNotNull);
    });

    test('should restore from trash', () {
      final note = Note.create(title: 'Note', content: 'Content');

      final trashed = note.trash();
      final restored = trashed.restore();

      expect(restored.isTrashed, isFalse);
      expect(restored.trashedAt, isNull);
    });

    test('should serialize to JSON and back', () {
      final note = Note.create(
        title: 'Serialize Test',
        content: 'Content here',
        notebookId: 'nb-1',
        tags: ['a', 'b'],
      );

      final json = note.toJson();
      final restored = Note.fromJson(json);

      expect(restored.id, equals(note.id));
      expect(restored.title, equals(note.title));
      expect(restored.content, equals(note.content));
      expect(restored.notebookId, equals(note.notebookId));
      expect(restored.tags, equals(note.tags));
    });

    test('should serialize to bytes and back', () {
      final note = Note.create(title: 'Bytes Test', content: 'Some content');

      final bytes = note.toBytes();
      final restored = Note.fromBytes(bytes);

      expect(restored.id, equals(note.id));
      expect(restored.title, equals(note.title));
    });
  });

  group('NoteMetadata', () {
    test('should create from note with preview', () {
      final longContent = 'A' * 200;
      final note = Note.create(title: 'Long Note', content: longContent);

      final metadata = NoteMetadata.fromNote(note, previewLength: 100);

      expect(metadata.id, equals(note.id));
      expect(metadata.title, equals(note.title));
      expect(metadata.preview?.length, equals(100));
    });

    test('should serialize and deserialize', () {
      final now = DateTime.now();
      final metadata = NoteMetadata(
        (b) => b
          ..id = 'note-1'
          ..title = 'Test'
          ..tags.add('tag')
          ..createdAt = now
          ..modifiedAt = now
          ..isPinned = false
          ..isArchived = false
          ..isTrashed = false
          ..version = 1
          ..preview = 'Preview text',
      );

      final json = metadata.toJson();
      final restored = NoteMetadata.fromJson(json);

      expect(restored.id, equals(metadata.id));
      expect(restored.title, equals(metadata.title));
      expect(restored.preview, equals(metadata.preview));
    });
  });

  group('EncryptedNoteRepository', () {
    late UnlockedVault vault;
    late EncryptedNoteRepository repo;

    setUp(() async {
      // Create and unlock a vault for testing
      final vaultPath = '${tempDir.path}/vault';
      final password = SecureBytes.fromList(utf8.encode('password'));

      await vaultService.createVault(
        vaultPath: vaultPath,
        password: password,
        kdfParams: Argon2Params.test,
      );

      final unlockPassword = SecureBytes.fromList(utf8.encode('password'));
      vault = await vaultService.unlockVault(
        vaultPath: vaultPath,
        password: unlockPassword,
      );

      repo = EncryptedNoteRepository(vault: vault, crypto: crypto);
    });

    tearDown(() {
      vault.dispose();
    });

    test('should save and load note', () async {
      final note = Note.create(
        title: 'Test Note',
        content: 'This is encrypted content',
      );

      final saved = await repo.save(note);
      expect(saved.contentHash, isNotNull);

      final loaded = await repo.load(note.id);

      expect(loaded, isNotNull);
      expect(loaded!.id, equals(note.id));
      expect(loaded.title, equals('Test Note'));
      expect(loaded.content, equals('This is encrypted content'));
    });

    test('should list all notes', () async {
      final note1 = Note.create(title: 'Note 1', content: 'Content 1');
      final note2 = Note.create(title: 'Note 2', content: 'Content 2');

      await repo.save(note1);
      await repo.save(note2);

      final all = await repo.listAll();

      expect(all.length, equals(2));
      expect(all.map((m) => m.title), containsAll(['Note 1', 'Note 2']));
    });

    test('should list notes by notebook', () async {
      final note1 = Note.create(
        title: 'Note 1',
        content: 'C1',
        notebookId: 'nb-1',
      );
      final note2 = Note.create(
        title: 'Note 2',
        content: 'C2',
        notebookId: 'nb-2',
      );
      final note3 = Note.create(
        title: 'Note 3',
        content: 'C3',
        notebookId: 'nb-1',
      );

      await repo.save(note1);
      await repo.save(note2);
      await repo.save(note3);

      final nb1Notes = await repo.listByNotebook('nb-1');

      expect(nb1Notes.length, equals(2));
      expect(nb1Notes.map((m) => m.title), containsAll(['Note 1', 'Note 3']));
    });

    test('should list notes by tag', () async {
      final note1 = Note.create(
        title: 'Tagged',
        content: 'C1',
        tags: ['important'],
      );
      final note2 = Note.create(
        title: 'Not Tagged',
        content: 'C2',
        tags: ['other'],
      );

      await repo.save(note1);
      await repo.save(note2);

      final importantNotes = await repo.listByTag('important');

      expect(importantNotes.length, equals(1));
      expect(importantNotes.first.title, equals('Tagged'));
    });

    test('should list trashed notes', () async {
      final note1 = Note.create(title: 'Active', content: 'C1');
      final note2 = Note.create(title: 'Trashed', content: 'C2').trash();

      await repo.save(note1);
      await repo.save(note2);

      final trashed = await repo.listTrashed();

      expect(trashed.length, equals(1));
      expect(trashed.first.title, equals('Trashed'));
    });

    test('should search by title', () async {
      final note1 = Note.create(
        title: 'Meeting Notes',
        content: 'Discussed...',
      );
      final note2 = Note.create(title: 'Shopping List', content: 'Buy milk');

      await repo.save(note1);
      await repo.save(note2);

      final results = await repo.searchByTitle('meeting');

      expect(results.length, equals(1));
      expect(results.first.title, equals('Meeting Notes'));
    });

    test('should delete note', () async {
      final note = Note.create(title: 'To Delete', content: 'Content');

      await repo.save(note);
      expect(await repo.load(note.id), isNotNull);

      await repo.delete(note.id);

      final metadata = await repo.listAll();
      expect(metadata.where((m) => m.id == note.id), isEmpty);
    });

    test('should update note', () async {
      final note = Note.create(title: 'Original', content: 'Original content');

      await repo.save(note);

      final updated = note.copyWith(
        title: 'Updated',
        content: 'Updated content',
      );

      await repo.save(updated);

      final loaded = await repo.load(note.id);

      expect(loaded?.title, equals('Updated'));
      expect(loaded?.content, equals('Updated content'));
      expect(loaded?.version, equals(2));
    });

    test('should get statistics', () async {
      final active1 = Note.create(title: 'Active 1', content: 'C');
      final active2 = Note.create(title: 'Active 2', content: 'C');
      final pinned = Note.create(
        title: 'Pinned',
        content: 'C',
      ).copyWith(isPinned: true);
      final archived = Note.create(
        title: 'Archived',
        content: 'C',
      ).copyWith(isArchived: true);
      final trashed = Note.create(title: 'Trashed', content: 'C').trash();

      await repo.save(active1);
      await repo.save(active2);
      await repo.save(pinned);
      await repo.save(archived);
      await repo.save(trashed);

      final stats = await repo.getStats();

      expect(stats.total, equals(5));
      expect(stats.active, equals(3)); // active1, active2, pinned
      expect(stats.archived, equals(1));
      expect(stats.trashed, equals(1));
      expect(stats.pinned, equals(1));
    });

    test('should encrypt note content', () async {
      final note = Note.create(
        title: 'Secret Note',
        content: 'Super secret content that should be encrypted',
      );

      final saved = await repo.save(note);

      // Read the raw object file
      final objectData = await vault.filesystem.readObject(saved.contentHash!);
      expect(objectData, isNotNull);

      // The raw data should NOT contain the plaintext
      final rawString = utf8.decode(objectData!, allowMalformed: true);
      expect(rawString.contains('Super secret'), isFalse);
      expect(rawString.contains('Secret Note'), isFalse);
    });
  });
}
