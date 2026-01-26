// ═══════════════════════════════════════════════════════════════════════════
// FYNDO - Zero-Trust Notes OS
// Sync Backend Interface - Pluggable Sync Backends
// ═══════════════════════════════════════════════════════════════════════════
//
// ARCHITECTURE:
// Fyndo supports pluggable sync backends. All backends must implement
// the SyncBackend interface. The server never sees plaintext - all data
// is encrypted before being passed to the backend.
//
// AVAILABLE BACKENDS:
// - LocalOnlySyncBackend: No sync, local storage only (default)
// - HttpSyncBackend: Generic HTTP/REST API backend (stub for custom servers)
// - FirebaseSyncBackend: Firebase implementation (future)
// - SupabaseSyncBackend: Supabase implementation (future)
//
// ZERO-TRUST GUARANTEE:
// All backends receive ONLY encrypted data. The backend cannot:
// - Generate or derive keys
// - Decrypt any content
// - See plaintext notes, metadata, or user data
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:typed_data';

import 'package:fyndo_app/core/sync/sync_operation.dart';

/// Result of a sync push operation.
class SyncPushResult {
  final bool success;
  final int pushedCount;
  final String? error;
  final List<String> failedOpIds;

  const SyncPushResult({
    required this.success,
    required this.pushedCount,
    this.error,
    this.failedOpIds = const [],
  });

  factory SyncPushResult.success(int count) => SyncPushResult(
        success: true,
        pushedCount: count,
      );

  factory SyncPushResult.failure(String error) => SyncPushResult(
        success: false,
        pushedCount: 0,
        error: error,
      );
}

/// Result of a sync pull operation.
class SyncPullResult {
  final bool success;
  final List<EncryptedSyncOp> operations;
  final String? newCursor;
  final String? error;

  const SyncPullResult({
    required this.success,
    required this.operations,
    this.newCursor,
    this.error,
  });

  factory SyncPullResult.success(
    List<EncryptedSyncOp> ops, {
    String? cursor,
  }) =>
      SyncPullResult(
        success: true,
        operations: ops,
        newCursor: cursor,
      );

  factory SyncPullResult.failure(String error) => SyncPullResult(
        success: false,
        operations: [],
        error: error,
      );
}

/// Configuration for a sync backend.
abstract class SyncBackendConfig {
  /// Unique identifier for this backend type.
  String get backendType;

  /// Human-readable name.
  String get displayName;

  /// Whether this backend is currently available.
  bool get isAvailable;

  /// Serialize to JSON for storage.
  Map<String, dynamic> toJson();
}

/// Abstract interface for sync backends.
///
/// All sync backends must implement this interface. The sync service
/// calls these methods with encrypted data only.
abstract class SyncBackend {
  /// The configuration for this backend.
  SyncBackendConfig get config;

  /// Whether the backend is currently connected/available.
  bool get isConnected;

  /// Initialize the backend (authenticate, connect, etc.)
  Future<void> initialize();

  /// Dispose resources when the backend is no longer needed.
  Future<void> dispose();

  /// Push encrypted operations to the remote server.
  ///
  /// [vaultId] - The vault these operations belong to
  /// [operations] - List of encrypted sync operations
  ///
  /// Returns [SyncPushResult] with the outcome.
  Future<SyncPushResult> pushOperations({
    required String vaultId,
    required List<EncryptedSyncOp> operations,
  });

  /// Pull encrypted operations from the remote server.
  ///
  /// [vaultId] - The vault to pull operations for
  /// [cursor] - Last known position (null for initial sync)
  /// [limit] - Maximum number of operations to return
  ///
  /// Returns [SyncPullResult] with encrypted operations.
  Future<SyncPullResult> pullOperations({
    required String vaultId,
    String? cursor,
    int limit = 100,
  });

  /// Upload an encrypted blob (for large content).
  ///
  /// [vaultId] - The vault this blob belongs to
  /// [blobId] - Content-addressed ID (hash of encrypted content)
  /// [data] - Encrypted blob data
  ///
  /// Returns the URL/path where the blob was stored.
  Future<String?> uploadBlob({
    required String vaultId,
    required String blobId,
    required Uint8List data,
  });

  /// Download an encrypted blob.
  ///
  /// [vaultId] - The vault this blob belongs to
  /// [blobId] - Content-addressed ID
  ///
  /// Returns the encrypted blob data, or null if not found.
  Future<Uint8List?> downloadBlob({
    required String vaultId,
    required String blobId,
  });

  /// Check if a blob exists on the remote.
  Future<bool> blobExists({
    required String vaultId,
    required String blobId,
  });

  /// Delete a blob from the remote.
  Future<bool> deleteBlob({
    required String vaultId,
    required String blobId,
  });

  /// Get sync status/statistics.
  Future<SyncBackendStatus> getStatus();
}

/// Status information from a sync backend.
class SyncBackendStatus {
  final bool isConnected;
  final bool isAuthenticated;
  final DateTime? lastSyncTime;
  final int pendingOperations;
  final int totalOperations;
  final String? error;

  const SyncBackendStatus({
    required this.isConnected,
    required this.isAuthenticated,
    this.lastSyncTime,
    this.pendingOperations = 0,
    this.totalOperations = 0,
    this.error,
  });

  factory SyncBackendStatus.disconnected() => const SyncBackendStatus(
        isConnected: false,
        isAuthenticated: false,
      );

  factory SyncBackendStatus.connected() => const SyncBackendStatus(
        isConnected: true,
        isAuthenticated: true,
      );
}

