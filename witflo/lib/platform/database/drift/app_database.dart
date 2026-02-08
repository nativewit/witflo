// ═══════════════════════════════════════════════════════════════════════════
// WITFLO - Zero-Trust Notes OS
// Drift Database - Type-safe SQLite ORM
// ═══════════════════════════════════════════════════════════════════════════
//
// TABLES:
// - notes: Encrypted note storage
// - notebooks: Notebook metadata
// - note_fts: Full-text search index
// - sync_state: Sync cursor state
// - key_store: Encrypted key storage
//
// IMPORTANT: All content columns store ciphertext, never plaintext.
// ═══════════════════════════════════════════════════════════════════════════

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

// ═══════════════════════════════════════════════════════════════════════════
// TABLE DEFINITIONS
// ═══════════════════════════════════════════════════════════════════════════

/// Encrypted notes table.
/// Content is always encrypted - the database only stores ciphertext.
class Notes extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()(); // Encrypted
  BlobColumn get content => blob()(); // Encrypted Quill delta
  TextColumn get notebookId => text().nullable()();
  TextColumn get tags =>
      text().withDefault(const Constant('[]'))(); // JSON array
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get modifiedAt => dateTime()();
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  BoolColumn get isTrashed => boolean().withDefault(const Constant(false))();
  DateTimeColumn get trashedAt => dateTime().nullable()();
  TextColumn get contentHash => text().nullable()(); // For sync/dedup
  IntColumn get version => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Notebooks table.
class Notebooks extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get vaultId => text()();
  TextColumn get color => text().nullable()();
  TextColumn get icon => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get modifiedAt => dateTime()();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Full-text search index for notes.
/// Content is decrypted search terms for indexing.
class NoteFts extends Table {
  TextColumn get noteId => text()();
  TextColumn get searchText => text()(); // Decrypted, tokenized text for search

  @override
  Set<Column> get primaryKey => {noteId};

  @override
  String get tableName => 'note_fts';
}

/// Sync state tracking.
class SyncState extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {key};
}

/// Encrypted key storage.
/// Stores wrapped keys for device/sharing.
class KeyStore extends Table {
  TextColumn get id => text()();
  TextColumn get keyType => text()(); // 'device', 'notebook', 'share'
  BlobColumn get wrappedKey => blob()(); // Encrypted key material
  TextColumn get metadata => text().nullable()(); // JSON metadata
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get expiresAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ═══════════════════════════════════════════════════════════════════════════
// DATABASE CLASS
// ═══════════════════════════════════════════════════════════════════════════

@DriftDatabase(tables: [Notes, Notebooks, NoteFts, SyncState, KeyStore])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? _openConnection('witflo_vault'));

  AppDatabase.withName(String name) : super(_openConnection(name));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Handle migrations here
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // NOTE OPERATIONS
  // ─────────────────────────────────────────────────────────────────────────

  /// Get all notes (non-trashed).
  Future<List<Note>> getAllNotes() {
    return (select(notes)
          ..where((t) => t.isTrashed.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.modifiedAt)]))
        .get();
  }

  /// Get active notes (non-trashed, non-archived).
  Future<List<Note>> getActiveNotes() {
    return (select(notes)
          ..where((t) => t.isTrashed.equals(false) & t.isArchived.equals(false))
          ..orderBy([
            (t) => OrderingTerm.desc(t.isPinned),
            (t) => OrderingTerm.desc(t.modifiedAt),
          ]))
        .get();
  }

  /// Watch active notes.
  Stream<List<Note>> watchActiveNotes() {
    return (select(notes)
          ..where((t) => t.isTrashed.equals(false) & t.isArchived.equals(false))
          ..orderBy([
            (t) => OrderingTerm.desc(t.isPinned),
            (t) => OrderingTerm.desc(t.modifiedAt),
          ]))
        .watch();
  }

  /// Get notes by notebook.
  Future<List<Note>> getNotesByNotebook(String notebookId) {
    return (select(notes)
          ..where(
            (t) => t.notebookId.equals(notebookId) & t.isTrashed.equals(false),
          )
          ..orderBy([
            (t) => OrderingTerm.desc(t.isPinned),
            (t) => OrderingTerm.desc(t.modifiedAt),
          ]))
        .get();
  }

  /// Watch notes by notebook.
  Stream<List<Note>> watchNotesByNotebook(String notebookId) {
    return (select(notes)
          ..where(
            (t) => t.notebookId.equals(notebookId) & t.isTrashed.equals(false),
          )
          ..orderBy([
            (t) => OrderingTerm.desc(t.isPinned),
            (t) => OrderingTerm.desc(t.modifiedAt),
          ]))
        .watch();
  }

  /// Get a single note by ID.
  Future<Note?> getNoteById(String id) {
    return (select(notes)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Watch a single note.
  Stream<Note?> watchNote(String id) {
    return (select(notes)..where((t) => t.id.equals(id))).watchSingleOrNull();
  }

  /// Insert or update a note.
  Future<void> upsertNote(NotesCompanion note) {
    return into(notes).insertOnConflictUpdate(note);
  }

  /// Move note to trash.
  Future<void> trashNote(String id) {
    return (update(notes)..where((t) => t.id.equals(id))).write(
      NotesCompanion(
        isTrashed: const Value(true),
        trashedAt: Value(DateTime.now()),
        modifiedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Restore note from trash.
  Future<void> restoreNote(String id) {
    return (update(notes)..where((t) => t.id.equals(id))).write(
      NotesCompanion(
        isTrashed: const Value(false),
        trashedAt: const Value(null),
        modifiedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Permanently delete a note.
  Future<void> deleteNote(String id) {
    return (delete(notes)..where((t) => t.id.equals(id))).go();
  }

  /// Get trashed notes.
  Future<List<Note>> getTrashedNotes() {
    return (select(notes)
          ..where((t) => t.isTrashed.equals(true))
          ..orderBy([(t) => OrderingTerm.desc(t.trashedAt)]))
        .get();
  }

  /// Watch trashed notes.
  Stream<List<Note>> watchTrashedNotes() {
    return (select(notes)
          ..where((t) => t.isTrashed.equals(true))
          ..orderBy([(t) => OrderingTerm.desc(t.trashedAt)]))
        .watch();
  }

  /// Toggle pin status.
  Future<void> toggleNotePin(String id) async {
    final note = await getNoteById(id);
    if (note != null) {
      await (update(notes)..where((t) => t.id.equals(id))).write(
        NotesCompanion(
          isPinned: Value(!note.isPinned),
          modifiedAt: Value(DateTime.now()),
        ),
      );
    }
  }

  /// Archive a note.
  Future<void> archiveNote(String id) {
    return (update(notes)..where((t) => t.id.equals(id))).write(
      NotesCompanion(
        isArchived: const Value(true),
        modifiedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Unarchive a note.
  Future<void> unarchiveNote(String id) {
    return (update(notes)..where((t) => t.id.equals(id))).write(
      NotesCompanion(
        isArchived: const Value(false),
        modifiedAt: Value(DateTime.now()),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // NOTEBOOK OPERATIONS
  // ─────────────────────────────────────────────────────────────────────────

  /// Get all notebooks.
  Future<List<Notebook>> getAllNotebooks() {
    return (select(notebooks)
          ..where((t) => t.isArchived.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
  }

  /// Watch all notebooks.
  Stream<List<Notebook>> watchAllNotebooks() {
    return (select(notebooks)
          ..where((t) => t.isArchived.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  /// Get a notebook by ID.
  Future<Notebook?> getNotebookById(String id) {
    return (select(notebooks)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Watch a notebook.
  Stream<Notebook?> watchNotebook(String id) {
    return (select(
      notebooks,
    )..where((t) => t.id.equals(id))).watchSingleOrNull();
  }

  /// Insert or update a notebook.
  Future<void> upsertNotebook(NotebooksCompanion notebook) {
    return into(notebooks).insertOnConflictUpdate(notebook);
  }

  /// Delete a notebook and optionally its notes.
  Future<void> deleteNotebook(String id, {bool deleteNotes = false}) async {
    if (deleteNotes) {
      await (delete(notes)..where((t) => t.notebookId.equals(id))).go();
    } else {
      // Move notes to no notebook
      await (update(notes)..where((t) => t.notebookId.equals(id))).write(
        const NotesCompanion(notebookId: Value(null)),
      );
    }
    await (delete(notebooks)..where((t) => t.id.equals(id))).go();
  }

  /// Archive a notebook.
  Future<void> archiveNotebook(String id) {
    return (update(notebooks)..where((t) => t.id.equals(id))).write(
      NotebooksCompanion(
        isArchived: const Value(true),
        modifiedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Get note count for a notebook.
  Future<int> getNoteCount(String notebookId) async {
    final count = notes.id.count();
    final query = selectOnly(notes)
      ..addColumns([count])
      ..where(
        notes.notebookId.equals(notebookId) & notes.isTrashed.equals(false),
      );
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  /// Get all note counts by notebook.
  Future<Map<String, int>> getAllNoteCounts() async {
    final results =
        await (selectOnly(notes)
              ..addColumns([notes.notebookId, notes.id.count()])
              ..where(notes.isTrashed.equals(false))
              ..groupBy([notes.notebookId]))
            .get();

    final counts = <String, int>{};
    for (final row in results) {
      final notebookId = row.read(notes.notebookId);
      final count = row.read(notes.id.count());
      if (notebookId != null && count != null) {
        counts[notebookId] = count;
      }
    }
    return counts;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SEARCH OPERATIONS
  // ─────────────────────────────────────────────────────────────────────────

  /// Update search index for a note.
  Future<void> updateSearchIndex(String noteId, String searchText) {
    return into(noteFts).insertOnConflictUpdate(
      NoteFtsCompanion(noteId: Value(noteId), searchText: Value(searchText)),
    );
  }

  /// Remove from search index.
  Future<void> removeFromSearchIndex(String noteId) {
    return (delete(noteFts)..where((t) => t.noteId.equals(noteId))).go();
  }

  /// Simple search in titles.
  Future<List<Note>> searchNotes(String query) {
    final pattern = '%$query%';
    return (select(notes)
          ..where(
            (t) =>
                t.title.like(pattern) &
                t.isTrashed.equals(false) &
                t.isArchived.equals(false),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.modifiedAt)])
          ..limit(50))
        .get();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SYNC STATE OPERATIONS
  // ─────────────────────────────────────────────────────────────────────────

  /// Get sync state value.
  Future<String?> getSyncState(String key) async {
    final result = await (select(
      syncState,
    )..where((t) => t.key.equals(key))).getSingleOrNull();
    return result?.value;
  }

  /// Set sync state value.
  Future<void> setSyncState(String key, String value) {
    return into(syncState).insertOnConflictUpdate(
      SyncStateCompanion(
        key: Value(key),
        value: Value(value),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // KEY STORE OPERATIONS
  // ─────────────────────────────────────────────────────────────────────────

  /// Store a wrapped key.
  Future<void> storeKey(KeyStoreCompanion key) {
    return into(keyStore).insertOnConflictUpdate(key);
  }

  /// Get a stored key.
  Future<KeyStoreData?> getKey(String id) {
    return (select(keyStore)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Get keys by type.
  Future<List<KeyStoreData>> getKeysByType(String keyType) {
    return (select(keyStore)..where((t) => t.keyType.equals(keyType))).get();
  }

  /// Delete a key.
  Future<void> deleteKey(String id) {
    return (delete(keyStore)..where((t) => t.id.equals(id))).go();
  }

  /// Delete expired keys.
  Future<int> deleteExpiredKeys() {
    return (delete(keyStore)..where(
          (t) =>
              t.expiresAt.isNotNull() &
              t.expiresAt.isSmallerThanValue(DateTime.now()),
        ))
        .go();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STATISTICS
  // ─────────────────────────────────────────────────────────────────────────

  /// Get database statistics.
  Future<DbStats> getStats() async {
    final noteCount =
        await (selectOnly(notes)
              ..addColumns([notes.id.count()])
              ..where(notes.isTrashed.equals(false)))
            .map((row) => row.read(notes.id.count()) ?? 0)
            .getSingle();

    final notebookCount =
        await (selectOnly(notebooks)
              ..addColumns([notebooks.id.count()])
              ..where(notebooks.isArchived.equals(false)))
            .map((row) => row.read(notebooks.id.count()) ?? 0)
            .getSingle();

    final trashedCount =
        await (selectOnly(notes)
              ..addColumns([notes.id.count()])
              ..where(notes.isTrashed.equals(true)))
            .map((row) => row.read(notes.id.count()) ?? 0)
            .getSingle();

    return DbStats(
      noteCount: noteCount,
      notebookCount: notebookCount,
      trashedCount: trashedCount,
    );
  }
}

/// Database statistics.
class DbStats {
  final int noteCount;
  final int notebookCount;
  final int trashedCount;

  const DbStats({
    required this.noteCount,
    required this.notebookCount,
    required this.trashedCount,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// DATABASE CONNECTION
// ═══════════════════════════════════════════════════════════════════════════

QueryExecutor _openConnection(String name) {
  return driftDatabase(
    name: name,
    native: const DriftNativeOptions(shareAcrossIsolates: true),
    web: DriftWebOptions(
      sqlite3Wasm: Uri.parse('sqlite3.wasm'),
      driftWorker: Uri.parse('drift_worker.js'),
    ),
  );
}

/// Opens the database with a custom path.
AppDatabase openDatabaseWithPath(String dbPath) {
  final name = p.basenameWithoutExtension(dbPath);
  return AppDatabase.withName(name);
}
