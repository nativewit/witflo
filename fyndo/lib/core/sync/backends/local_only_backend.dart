// ═══════════════════════════════════════════════════════════════════════════
// FYNDO - Zero-Trust Notes OS
// Local-Only Sync Backend - No Remote Sync (Default)
// ═══════════════════════════════════════════════════════════════════════════
//
// This is the default "backend" that performs no remote sync.
// All operations are stored locally only. Use this when:
// - User hasn't configured any sync backend
// - User wants fully offline/local-only operation
// - Testing without network dependencies
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:typed_data';

import 'package:fyndo_app/core/sync/sync_backend.dart';
import 'package:fyndo_app/core/sync/sync_operation.dart';

/// Configuration for local-only sync (no remote).
class LocalOnlySyncConfig implements SyncBackendConfig {
  const LocalOnlySyncConfig();

  @override
  String get backendType => 'local';

  @override
  String get displayName => 'Local Only (No Sync)';

  @override
  bool get isAvailable => true;

  @override
  Map<String, dynamic> toJson() => {
        'type': backendType,
      };

  factory LocalOnlySyncConfig.fromJson(Map<String, dynamic> json) {
    return const LocalOnlySyncConfig();
  }
}

/// Local-only sync backend - no remote synchronization.
///
/// This backend stores everything locally and never communicates
/// with any remote server. It's the default when no sync is configured.
class LocalOnlySyncBackend implements SyncBackend {
  final LocalOnlySyncConfig _config;

  LocalOnlySyncBackend([LocalOnlySyncConfig? config])
      : _config = config ?? const LocalOnlySyncConfig();

  @override
  SyncBackendConfig get config => _config;

  @override
  bool get isConnected => true; // Always "connected" for local

  @override
  Future<void> initialize() async {
    // No initialization needed for local-only
  }

  @override
  Future<void> dispose() async {
    // No cleanup needed
  }

  @override
  Future<SyncPushResult> pushOperations({
    required String vaultId,
    required List<EncryptedSyncOp> operations,
  }) async {
    // Local-only: operations are already stored locally, nothing to push
    return SyncPushResult.success(0);
  }

  @override
  Future<SyncPullResult> pullOperations({
    required String vaultId,
    String? cursor,
    int limit = 100,
  }) async {
    // Local-only: no remote operations to pull
    return SyncPullResult.success([]);
  }

  @override
  Future<String?> uploadBlob({
    required String vaultId,
    required String blobId,
    required Uint8List data,
  }) async {
    // Local-only: blobs are stored locally, return local path
    return 'local://$vaultId/$blobId';
  }

  @override
  Future<Uint8List?> downloadBlob({
    required String vaultId,
    required String blobId,
  }) async {
    // Local-only: should never be called for remote blobs
    return null;
  }

  @override
  Future<bool> blobExists({
    required String vaultId,
    required String blobId,
  }) async {
    // Local-only: always false for remote check
    return false;
  }

  @override
  Future<bool> deleteBlob({
    required String vaultId,
    required String blobId,
  }) async {
    // Local-only: nothing to delete remotely
    return true;
  }

  @override
  Future<SyncBackendStatus> getStatus() async {
    return SyncBackendStatus.connected();
  }
}

