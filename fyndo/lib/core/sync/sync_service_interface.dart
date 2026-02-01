// ═══════════════════════════════════════════════════════════════════════════
// FYNDO - Zero-Trust Notes OS
// ISyncService - Sync Service Interface
// ═══════════════════════════════════════════════════════════════════════════

import 'package:fyndo_app/core/sync/sync_backend.dart';
import 'package:fyndo_app/core/sync/sync_operation.dart';

/// Sync state for a vault.
enum SyncState { idle, syncing, error, offline }

/// Result of a sync operation.
class SyncResult {
  final bool success;
  final int pushed;
  final int pulled;
  final String? error;
  final Duration duration;

  SyncResult({
    required this.success,
    required this.pushed,
    required this.pulled,
    this.error,
    required this.duration,
  });
}

/// Sync statistics.
class SyncStats {
  final int pendingCount;
  final int lastSyncedTimestamp;
  final int totalSynced;
  final DateTime lastSyncedAt;
  final bool backendConnected;
  final String backendType;

  SyncStats({
    required this.pendingCount,
    required this.lastSyncedTimestamp,
    required this.totalSynced,
    required this.lastSyncedAt,
    required this.backendConnected,
    required this.backendType,
  });
}

/// Manages sync operations for a vault.
abstract interface class ISyncService {
  /// Current sync state.
  SyncState get state;

  /// Current sync cursor.
  SyncCursor get cursor;

  /// Gets the current backend.
  SyncBackend get backend;

  /// Sets a new sync backend.
  Future<void> setBackend(SyncBackend backend);

  /// Initializes the sync service.
  Future<void> initialize();

  /// Disposes resources.
  Future<void> dispose();

  /// Creates a new sync operation.
  Future<SyncOperation> createOperation({
    required SyncOpType type,
    required String targetId,
    required Map<String, dynamic> payload,
  });

  /// Performs a full sync (push + pull).
  Future<SyncResult> sync();

  /// Lists pending operations waiting to be synced.
  Future<List<EncryptedSyncOp>> listPendingOperations();

  /// Marks an operation as synced.
  Future<void> markOperationSynced(String opId);

  /// Advances the cursor to a new position.
  Future<void> advanceCursor({required String opId, required int timestamp});

  /// Gets sync statistics.
  Future<SyncStats> getStats();
}
