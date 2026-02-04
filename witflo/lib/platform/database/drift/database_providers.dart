// ═══════════════════════════════════════════════════════════════════════════
// WITFLO - Zero-Trust Notes OS
// Database Providers - Riverpod Integration for Drift
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:witflo_app/platform/database/drift/app_database.dart';

// ═══════════════════════════════════════════════════════════════════════════
// DATABASE INSTANCE PROVIDER
// ═══════════════════════════════════════════════════════════════════════════

/// Global database instance.
/// This is initialized when the app starts or vault is unlocked.
AppDatabase? _dbInstance;

/// Get the current database instance.
AppDatabase get db {
  if (_dbInstance == null) {
    throw StateError(
      'Database not initialized. Call initializeDatabase() first.',
    );
  }
  return _dbInstance!;
}

/// Initialize the database.
Future<void> initializeDatabase([String? name]) async {
  if (_dbInstance != null) {
    await _dbInstance!.close();
  }
  _dbInstance = name != null ? AppDatabase.withName(name) : AppDatabase();
}

/// Close the database.
Future<void> closeDatabase() async {
  await _dbInstance?.close();
  _dbInstance = null;
}

/// Check if Drift database is initialized.
bool get isDriftDatabaseInitialized => _dbInstance != null;

// ═══════════════════════════════════════════════════════════════════════════
// RIVERPOD PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════

/// Provider for the database instance.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return db;
});

/// Provider for database stats.
final dbStatsProvider = FutureProvider<DbStats>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return database.getStats();
});

// ─────────────────────────────────────────────────────────────────────────
// NOTEBOOK PROVIDERS
// ─────────────────────────────────────────────────────────────────────────

/// Stream provider for all notebooks.
final notebooksStreamProvider = StreamProvider<List<Notebook>>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return database.watchAllNotebooks();
});

/// Future provider for all notebooks.
final notebooksFutureProvider = FutureProvider<List<Notebook>>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return database.getAllNotebooks();
});

/// Provider for a single notebook.
final notebookProvider = StreamProvider.family<Notebook?, String>((ref, id) {
  final database = ref.watch(appDatabaseProvider);
  return database.watchNotebook(id);
});

/// Provider for note counts by notebook.
final noteCountsProvider = FutureProvider<Map<String, int>>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return database.getAllNoteCounts();
});

// ─────────────────────────────────────────────────────────────────────────
// NOTE PROVIDERS
// ─────────────────────────────────────────────────────────────────────────

/// Stream provider for active notes.
final activeNotesStreamProvider = StreamProvider<List<Note>>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return database.watchActiveNotes();
});

/// Stream provider for notes in a notebook.
final notebookNotesStreamProvider = StreamProvider.family<List<Note>, String>((
  ref,
  notebookId,
) {
  final database = ref.watch(appDatabaseProvider);
  return database.watchNotesByNotebook(notebookId);
});

/// Stream provider for a single note.
final noteStreamProvider = StreamProvider.family<Note?, String>((ref, noteId) {
  final database = ref.watch(appDatabaseProvider);
  return database.watchNote(noteId);
});

/// Future provider for a single note.
final noteFutureProvider = FutureProvider.family<Note?, String>((ref, noteId) {
  final database = ref.watch(appDatabaseProvider);
  return database.getNoteById(noteId);
});

/// Stream provider for trashed notes.
final trashedNotesStreamProvider = StreamProvider<List<Note>>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return database.watchTrashedNotes();
});

/// Search notes provider.
final noteSearchProvider = FutureProvider.family<List<Note>, String>((
  ref,
  query,
) {
  if (query.isEmpty) return Future.value([]);
  final database = ref.watch(appDatabaseProvider);
  return database.searchNotes(query);
});
