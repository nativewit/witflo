// ═══════════════════════════════════════════════════════════════════════════
// FYNDO - Zero-Trust Notes OS
// Sync Service - Encrypted Sync with Pluggable Backends
// ═══════════════════════════════════════════════════════════════════════════
//
// SYNC ARCHITECTURE:
// 1. Local changes create SyncOperations
// 2. Operations are signed with device key
// 3. Operations are encrypted with vault key
// 4. Encrypted ops pushed to backend (HTTP, Firebase, etc.)
// 5. Other devices pull encrypted ops
// 6. Ops decrypted, verified, and applied locally
//
// PLUGGABLE BACKENDS:
// The sync service uses a SyncBackend interface. You can implement:
// - LocalOnlySyncBackend: No sync (default)
// - HttpSyncBackend: Generic REST API
// - FirebaseSyncBackend: Firebase implementation
// - Custom backends for any service
//
// ZERO-TRUST GUARANTEES:
// - Backend NEVER sees plaintext
// - Backend NEVER generates or derives keys
// - All crypto happens client-side
// - Backend is a dumb blob storage
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'dart:typed_data';

import 'package:fyndo_app/core/crypto/crypto.dart';
import 'package:fyndo_app/core/identity/identity.dart';
import 'package:fyndo_app/core/sync/sync_backend.dart';
import 'package:fyndo_app/core/sync/sync_operation.dart';
import 'package:fyndo_app/core/sync/sync_service_interface.dart';
import 'package:fyndo_app/core/sync/backends/local_only_backend.dart';
import 'package:fyndo_app/core/vault/vault.dart';
import 'package:fyndo_app/platform/storage/storage_provider.dart';

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

  @override
  String toString() =>
      'SyncResult(pushed=$pushed, pulled=$pulled, success=$success)';
}

/// Manages sync operations for a vault.
class SyncService {
  final UnlockedVault _vault;
  final CryptoService _crypto;
  final DeviceIdentity _deviceIdentity;

  /// The sync backend to use (pluggable)
  SyncBackend _backend;

  // Lamport clock for operation ordering
  int _lamportClock = 0;

  // Current sync state
  // ignore: prefer_final_fields
  SyncState _state = SyncState.idle;
  @override
  SyncState get state => _state;

  // Sync cursor
  SyncCursor _cursor = SyncCursor.initial();
  @override
  SyncCursor get cursor => _cursor;

  SyncService({
    required UnlockedVault vault,
    required CryptoService crypto,
    required DeviceIdentity deviceIdentity,
    SyncBackend? backend,
  }) : _vault = vault,
       _crypto = crypto,
       _deviceIdentity = deviceIdentity,
       _backend = backend ?? LocalOnlySyncBackend();

  /// Gets the current backend.
  @override
  SyncBackend get backend => _backend;

  /// Sets a new sync backend.
  @override
  Future<void> setBackend(SyncBackend backend) async {
    await _backend.dispose();
    _backend = backend;
    await _backend.initialize();
  }

  /// Initializes sync service, loading cursor from disk.
  Future<void> initialize() async {
    await _backend.initialize();
    await _loadCursor();
    await _loadLamportClock();
  }

  /// Disposes resources.
  Future<void> dispose() async {
    await _backend.dispose();
  }

  /// Creates and queues a sync operation.
  Future<SyncOperation> createOperation({
    required SyncOpType type,
    required String targetId,
    required Map<String, dynamic> payload,
  }) async {
    // Increment Lamport clock
    _lamportClock++;

    // Create operation
    final op = SyncOperation.create(
      type: type,
      targetId: targetId,
      timestamp: _lamportClock,
      deviceId: _deviceIdentity.deviceId,
      payload: payload,
    );

    // Sign operation
    final signature = _crypto.ed25519.sign(
      message: op.toBytesForSigning(),
      keyPair: _deviceIdentity.signingKey,
    );
    final signedOp = op.withSignature(signature);

    // Encrypt operation
    final encrypted = await _encryptOperation(signedOp);

    // Queue for sync
    await _queueOperation(encrypted);

    // Persist Lamport clock
    await _saveLamportClock();

    return signedOp;
  }

  /// Performs a full sync (push + pull).
  Future<SyncResult> sync() async {
    final stopwatch = Stopwatch()..start();
    _state = SyncState.syncing;

    try {
      // Push pending operations
      final pending = await listPendingOperations();
      final pushResult = await _backend.pushOperations(
        vaultId: _vault.header.vaultId,
        operations: pending,
      );

      int pushed = 0;
      if (pushResult.success) {
        pushed = pushResult.pushedCount;
        // Mark pushed operations as synced
        for (final op in pending) {
          await markOperationSynced(op.opId);
        }
      }

      // Pull new operations
      final pullResult = await _backend.pullOperations(
        vaultId: _vault.header.vaultId,
        cursor: _cursor.lastOpId,
      );

      int pulled = 0;
      if (pullResult.success) {
        pulled = pullResult.operations.length;
        // Apply pulled operations
        for (final encryptedOp in pullResult.operations) {
          final op = await _decryptOperation(encryptedOp);
          // TODO: Apply operation to local state
          await advanceCursor(timestamp: op.timestamp, opId: op.opId);
        }
      }

      stopwatch.stop();
      _state = SyncState.idle;

      return SyncResult(
        success: true,
        pushed: pushed,
        pulled: pulled,
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      _state = SyncState.error;

      return SyncResult(
        success: false,
        pushed: 0,
        pulled: 0,
        error: e.toString(),
        duration: stopwatch.elapsed,
      );
    }
  }

  /// Encrypts a sync operation.
  Future<EncryptedSyncOp> _encryptOperation(SyncOperation op) async {
    final plaintext = SecureBytes(
      Uint8List.fromList(utf8.encode(jsonEncode(op.toJson()))),
    );

    // Use sync-specific key derived from vault key
    final syncKey = _deriveSyncKey();

    try {
      // Encrypt with AAD = op_id
      final aad = Uint8List.fromList(utf8.encode(op.opId));
      final encrypted = _crypto.xchacha20.encrypt(
        plaintext: plaintext,
        key: syncKey,
        associatedData: aad,
      );

      final hash = _crypto.blake3.hash(encrypted.ciphertext);

      return EncryptedSyncOp(
        opId: op.opId,
        ciphertext: encrypted.ciphertext,
        contentHash: hash.hex,
        timestamp: op.timestamp,
      );
    } finally {
      syncKey.dispose();
    }
  }

  /// Decrypts a sync operation.
  Future<SyncOperation> _decryptOperation(EncryptedSyncOp encrypted) async {
    final syncKey = _deriveSyncKey();

    try {
      final aad = Uint8List.fromList(utf8.encode(encrypted.opId));
      final plaintext = _crypto.xchacha20.decrypt(
        ciphertext: encrypted.ciphertext,
        key: syncKey,
        associatedData: aad,
      );

      try {
        final json =
            jsonDecode(utf8.decode(plaintext.unsafeBytes))
                as Map<String, dynamic>;
        return SyncOperation.fromJson(json);
      } finally {
        plaintext.dispose();
      }
    } finally {
      syncKey.dispose();
    }
  }

  /// Derives sync encryption key from vault key.
  ContentKey _deriveSyncKey() {
    return ContentKey(
      _crypto.hkdf.deriveKey(
        inputKey: _vault.vaultKey,
        info: 'fyndo.sync.operations.v1',
      ),
      context: 'sync',
    );
  }

  /// Queues an operation for upload.
  Future<void> _queueOperation(EncryptedSyncOp op) async {
    final path = _vault.filesystem.paths.pendingOpPath(op.opId);
    final data = Uint8List.fromList(
      utf8.encode(jsonEncode(op.toFirestoreDoc())),
    );
    await _vault.filesystem.writeAtomic(path, data);
  }

  /// Lists pending operations.
  Future<List<EncryptedSyncOp>> listPendingOperations() async {
    final opIds = await _vault.filesystem.listPendingOps();
    final ops = <EncryptedSyncOp>[];

    for (final opId in opIds) {
      final path = _vault.filesystem.paths.pendingOpPath(opId);
      final data = await storageProvider.readFile(path);
      if (data != null) {
        final json = jsonDecode(utf8.decode(data)) as Map<String, dynamic>;
        ops.add(EncryptedSyncOp.fromFirestoreDoc(json));
      }
    }

    return ops..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  /// Marks an operation as synced.
  Future<void> markOperationSynced(String opId) async {
    await _vault.filesystem.deletePendingOp(opId);
  }

  /// Updates the Lamport clock when receiving remote operations.
  void updateClock(int remoteTimestamp) {
    _lamportClock = _lamportClock > remoteTimestamp
        ? _lamportClock
        : remoteTimestamp + 1;
  }

  /// Loads cursor from disk.
  Future<void> _loadCursor() async {
    final cursorPath = _vault.filesystem.paths.syncCursor;
    final data = await _vault.filesystem.readIfExists(cursorPath);

    if (data != null) {
      final syncKey = _deriveSyncKey();
      try {
        final plaintext = _crypto.xchacha20.decrypt(
          ciphertext: Uint8List.fromList(data),
          key: syncKey,
        );
        try {
          final json =
              jsonDecode(utf8.decode(plaintext.unsafeBytes))
                  as Map<String, dynamic>;
          _cursor = SyncCursor.fromJson(json);
        } finally {
          plaintext.dispose();
        }
      } finally {
        syncKey.dispose();
      }
    }
  }

  /// Saves cursor to disk.
  Future<void> _saveCursor() async {
    final syncKey = _deriveSyncKey();
    try {
      final plaintext = SecureBytes(
        Uint8List.fromList(utf8.encode(jsonEncode(_cursor.toJson()))),
      );
      final encrypted = _crypto.xchacha20.encrypt(
        plaintext: plaintext,
        key: syncKey,
      );
      await _vault.filesystem.writeAtomic(
        _vault.filesystem.paths.syncCursor,
        encrypted.ciphertext,
      );
    } finally {
      syncKey.dispose();
    }
  }

  /// Loads Lamport clock from disk.
  Future<void> _loadLamportClock() async {
    // For simplicity, derive from cursor
    _lamportClock = _cursor.lastTimestamp;
  }

  /// Saves Lamport clock.
  Future<void> _saveLamportClock() async {
    // Lamport clock is persisted via cursor
    await _saveCursor();
  }

  /// Advances cursor after processing operations.
  Future<void> advanceCursor({
    required int timestamp,
    required String opId,
  }) async {
    _cursor = _cursor.advance(timestamp: timestamp, opId: opId);
    await _saveCursor();
  }

  /// Gets sync statistics.
  Future<SyncStats> getStats() async {
    final pending = await listPendingOperations();
    final backendStatus = await _backend.getStatus();

    return SyncStats(
      pendingCount: pending.length,
      lastSyncedTimestamp: _cursor.lastTimestamp,
      totalSynced: _cursor.syncedCount,
      lastSyncedAt: _cursor.updatedAt,
      backendConnected: backendStatus.isConnected,
      backendType: _backend.config.backendType,
    );
  }
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
