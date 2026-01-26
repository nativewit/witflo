// ═══════════════════════════════════════════════════════════════════════════
// FYNDO - Zero-Trust Notes OS
// Database Provider Interface - Pluggable Database Abstraction
// ═══════════════════════════════════════════════════════════════════════════
//
// This abstraction allows Fyndo to use different database backends:
// - SQLite (default for mobile/desktop)
// - IndexedDB (web)
// - In-memory (testing)
// - Custom implementations
//
// IMPORTANT: All data stored in the database should be encrypted.
// The database itself is just a key-value/document store for ciphertext.
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:typed_data';

/// Configuration for a database provider.
abstract class DatabaseConfig {
  /// Unique identifier for this database type.
  String get databaseType;

  /// Human-readable name.
  String get displayName;

  /// Serialize to JSON for storage.
  Map<String, dynamic> toJson();
}

/// A database query result row.
class DbRow {
  final Map<String, dynamic> data;

  DbRow(this.data);

  /// Get a value by column name.
  T? get<T>(String column) => data[column] as T?;

  /// Get a string value.
  String? getString(String column) => data[column] as String?;

  /// Get an int value.
  int? getInt(String column) => data[column] as int?;

  /// Get bytes (stored as base64 or blob).
  Uint8List? getBytes(String column) {
    final value = data[column];
    if (value == null) return null;
    if (value is Uint8List) return value;
    if (value is List<int>) return Uint8List.fromList(value);
    return null;
  }

  /// Get a DateTime value.
  DateTime? getDateTime(String column) {
    final value = data[column];
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }
}

/// Result of a database query.
class DbResult {
  final List<DbRow> rows;
  final int? insertId;
  final int affectedRows;

  DbResult({
    this.rows = const [],
    this.insertId,
    this.affectedRows = 0,
  });

  bool get isEmpty => rows.isEmpty;
  bool get isNotEmpty => rows.isNotEmpty;
  int get length => rows.length;

  DbRow? get firstOrNull => rows.isNotEmpty ? rows.first : null;
  DbRow get first => rows.first;

  Iterable<T> map<T>(T Function(DbRow row) f) => rows.map(f);
}

/// Abstract interface for database providers.
///
/// All database providers must implement this interface.
/// The interface is designed to be simple and work across
/// SQLite, IndexedDB, and in-memory implementations.
abstract class DatabaseProvider {
  /// The configuration for this database.
  DatabaseConfig get config;

  /// Whether the database is currently open.
  bool get isOpen;

  /// Initialize and open the database.
  ///
  /// [path] - Database path/name (interpretation depends on implementation)
  /// [version] - Schema version for migrations
  /// [onCreate] - Called when database is first created
  /// [onUpgrade] - Called when version increases
  Future<void> open({
    required String path,
    int version = 1,
    Future<void> Function(DatabaseProvider db, int version)? onCreate,
    Future<void> Function(DatabaseProvider db, int oldVersion, int newVersion)?
        onUpgrade,
  });

  /// Close the database.
  Future<void> close();

  /// Execute a SQL statement (no return value).
  ///
  /// For non-SQL databases, this may be interpreted as a command.
  Future<void> execute(String sql, [List<dynamic>? arguments]);

  /// Execute a SQL query and return results.
  Future<DbResult> query(
    String table, {
    List<String>? columns,
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
    int? offset,
  });

  /// Execute a raw SQL query and return results.
  Future<DbResult> rawQuery(String sql, [List<dynamic>? arguments]);

  /// Insert a row into a table.
  Future<int> insert(String table, Map<String, dynamic> values);

  /// Update rows in a table.
  Future<int> update(
    String table,
    Map<String, dynamic> values, {
    String? where,
    List<dynamic>? whereArgs,
  });

  /// Delete rows from a table.
  Future<int> delete(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
  });

  /// Execute multiple statements in a transaction.
  Future<T> transaction<T>(Future<T> Function(DatabaseProvider txn) action);

  /// Execute a batch of operations.
  Future<List<dynamic>> batch(
      void Function(DatabaseBatch batch) operations);
}

/// Batch operations interface.
abstract class DatabaseBatch {
  /// Add an insert to the batch.
  void insert(String table, Map<String, dynamic> values);

  /// Add an update to the batch.
  void update(
    String table,
    Map<String, dynamic> values, {
    String? where,
    List<dynamic>? whereArgs,
  });

  /// Add a delete to the batch.
  void delete(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
  });

  /// Add a raw SQL statement to the batch.
  void execute(String sql, [List<dynamic>? arguments]);
}

/// Get the database provider for the current platform.
/// This is set during app initialization.
DatabaseProvider? _databaseProvider;

DatabaseProvider get databaseProvider {
  if (_databaseProvider == null) {
    throw StateError(
        'DatabaseProvider not initialized. Call setDatabaseProvider() first.');
  }
  return _databaseProvider!;
}

/// Set the database provider (called during platform init or vault unlock).
void setDatabaseProvider(DatabaseProvider provider) {
  _databaseProvider = provider;
}

/// Check if database is initialized.
bool get isDatabaseInitialized => _databaseProvider != null;

/// Clear the database provider (for testing or logout).
void clearDatabaseProvider() {
  _databaseProvider = null;
}

