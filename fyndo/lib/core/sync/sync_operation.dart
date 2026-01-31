// ═══════════════════════════════════════════════════════════════════════════
// FYNDO - Zero-Trust Notes OS
// Sync Operations - CRDT-like Operations for Conflict-Free Sync
// ═══════════════════════════════════════════════════════════════════════════
//
// SYNC PHILOSOPHY:
// Fyndo uses operation-based sync where each change is an immutable operation.
// Operations are:
// 1. Signed by the creating device
// 2. Encrypted before upload
// 3. Content-addressed by hash
// 4. Ordered by Lamport timestamp
//
// OPERATION TYPES:
// - CreateNote
// - UpdateNote
// - DeleteNote
// - MoveNote
// - CreateNotebook
// - UpdateNotebook
// - DeleteNotebook
// - AddTag
// - RemoveTag
//
// SERVER ROLE:
// The server is a DUMB MAILBOX. It:
// - Stores encrypted operation blobs
// - Provides ordering cursors
// - Delivers blobs to devices
// - NEVER decrypts or processes content
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'dart:typed_data';

import 'package:fyndo_app/core/crypto/crypto.dart';
import 'package:uuid/uuid.dart';

/// Types of sync operations.
enum SyncOpType {
  createNote,
  updateNote,
  deleteNote,
  moveNote,
  createNotebook,
  updateNotebook,
  deleteNotebook,
  addTag,
  removeTag,
}

/// A sync operation that can be applied to vault state.
class SyncOperation {
  /// Unique operation ID
  final String opId;

  /// Type of operation
  final SyncOpType type;

  /// Target entity ID (note ID, notebook ID, etc.)
  final String targetId;

  /// Lamport timestamp for ordering
  final int timestamp;

  /// Device that created this operation
  final String deviceId;

  /// When the operation was created
  final DateTime createdAt;

  /// Operation payload (type-specific data)
  final Map<String, dynamic> payload;

  /// Signature of the operation (by creating device)
  final Signature? signature;

  SyncOperation({
    required this.opId,
    required this.type,
    required this.targetId,
    required this.timestamp,
    required this.deviceId,
    required this.createdAt,
    required this.payload,
    this.signature,
  });

  /// Creates a new operation with generated ID.
  factory SyncOperation.create({
    required SyncOpType type,
    required String targetId,
    required int timestamp,
    required String deviceId,
    required Map<String, dynamic> payload,
  }) {
    return SyncOperation(
      opId: const Uuid().v4(),
      type: type,
      targetId: targetId,
      timestamp: timestamp,
      deviceId: deviceId,
      createdAt: DateTime.now().toUtc(),
      payload: payload,
    );
  }

  /// Serializes the operation for signing/encryption.
  Map<String, dynamic> toJson() => {
    'op_id': opId,
    'type': type.name,
    'target_id': targetId,
    'timestamp': timestamp,
    'device_id': deviceId,
    'created_at': createdAt.toIso8601String(),
    'payload': payload,
    'signature': signature?.hex,
  };

  /// Serializes to bytes for signing.
  Uint8List toBytesForSigning() {
    final data = {
      'op_id': opId,
      'type': type.name,
      'target_id': targetId,
      'timestamp': timestamp,
      'device_id': deviceId,
      'created_at': createdAt.toIso8601String(),
      'payload': payload,
    };
    return Uint8List.fromList(utf8.encode(jsonEncode(data)));
  }

  factory SyncOperation.fromJson(Map<String, dynamic> json) {
    return SyncOperation(
      opId: json['op_id'] as String,
      type: SyncOpType.values.firstWhere((t) => t.name == json['type']),
      targetId: json['target_id'] as String,
      timestamp: json['timestamp'] as int,
      deviceId: json['device_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      payload: json['payload'] as Map<String, dynamic>,
      signature: json['signature'] != null
          ? Signature(_hexToBytes(json['signature'] as String))
          : null,
    );
  }

  /// Creates a signed copy of this operation.
  SyncOperation withSignature(Signature sig) {
    return SyncOperation(
      opId: opId,
      type: type,
      targetId: targetId,
      timestamp: timestamp,
      deviceId: deviceId,
      createdAt: createdAt,
      payload: payload,
      signature: sig,
    );
  }
}

/// Encrypted sync operation for transmission.
class EncryptedSyncOp {
  /// Operation ID (plaintext for ordering)
  final String opId;

  /// Encrypted operation blob
  final Uint8List ciphertext;

  /// Content hash for deduplication
  final String contentHash;

  /// Timestamp for ordering
  final int timestamp;

  EncryptedSyncOp({
    required this.opId,
    required this.ciphertext,
    required this.contentHash,
    required this.timestamp,
  });

  Map<String, dynamic> toFirestoreDoc() => {
    'op_id': opId,
    'ciphertext': base64Encode(ciphertext),
    'content_hash': contentHash,
    'timestamp': timestamp,
  };

  factory EncryptedSyncOp.fromFirestoreDoc(Map<String, dynamic> doc) {
    return EncryptedSyncOp(
      opId: doc['op_id'] as String,
      ciphertext: base64Decode(doc['ciphertext'] as String),
      contentHash: doc['content_hash'] as String,
      timestamp: doc['timestamp'] as int,
    );
  }
}

/// Sync cursor for incremental sync.
class SyncCursor {
  /// Last processed timestamp
  final int lastTimestamp;

  /// Last processed operation ID (for same-timestamp ordering)
  final String? lastOpId;

  /// Number of operations synced
  final int syncedCount;

  /// When this cursor was updated
  final DateTime updatedAt;

  SyncCursor({
    required this.lastTimestamp,
    this.lastOpId,
    required this.syncedCount,
    required this.updatedAt,
  });

  factory SyncCursor.initial() => SyncCursor(
    lastTimestamp: 0,
    syncedCount: 0,
    updatedAt: DateTime.now().toUtc(),
  );

  SyncCursor advance({required int timestamp, required String opId}) {
    return SyncCursor(
      lastTimestamp: timestamp,
      lastOpId: opId,
      syncedCount: syncedCount + 1,
      updatedAt: DateTime.now().toUtc(),
    );
  }

  Map<String, dynamic> toJson() => {
    'last_timestamp': lastTimestamp,
    'last_op_id': lastOpId,
    'synced_count': syncedCount,
    'updated_at': updatedAt.toIso8601String(),
  };

  factory SyncCursor.fromJson(Map<String, dynamic> json) {
    return SyncCursor(
      lastTimestamp: json['last_timestamp'] as int,
      lastOpId: json['last_op_id'] as String?,
      syncedCount: json['synced_count'] as int,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

// Helper to convert hex string to bytes
Uint8List _hexToBytes(String hex) {
  final result = Uint8List(hex.length ~/ 2);
  for (var i = 0; i < result.length; i++) {
    result[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
  }
  return result;
}
