// ═══════════════════════════════════════════════════════════════════════════
// FYNDO - Zero-Trust Notes OS
// Sharing Model - Zero-Knowledge Note and Notebook Sharing
// ═══════════════════════════════════════════════════════════════════════════
//
// SHARING PHILOSOPHY:
// Sharing in Fyndo means securely transmitting a scope key (NK, NSK)
// to another user/device without the server ever seeing it.
//
// SHARING FLOW:
// 1. Alice wants to share notebook X with Bob
// 2. Alice gets Bob's public identity (UserPublicIdentity)
// 3. Alice wraps NotebookKey(X) with Bob's X25519 public key
// 4. Alice uploads: {recipientPubKeyHash, wrappedKey, role, metadata}
// 5. Server stores this - it cannot decrypt wrappedKey
// 6. Bob downloads the share invite
// 7. Bob unwraps NotebookKey(X) with his X25519 secret key
// 8. Bob can now decrypt notebook X content
//
// REVOCATION:
// 1. Alice revokes Bob's access
// 2. Alice generates NEW NotebookKey(X')
// 3. Alice re-encrypts all content with NK(X')
// 4. Alice re-wraps NK(X') for remaining members
// 5. Bob's old NK(X) can no longer decrypt new content
//
// SERVER KNOWLEDGE (ZERO-TRUST):
// - Server sees: wrappedKey blobs, role strings, timestamps
// - Server does NOT see: actual keys, note content, who is sharing with whom
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'dart:typed_data';

import 'package:fyndo_app/core/crypto/crypto.dart';
import 'package:fyndo_app/core/identity/identity.dart';
import 'package:fyndo_app/core/sharing/sharing_service_interface.dart';
import 'package:uuid/uuid.dart';

/// Role in a shared resource.
enum ShareRole {
  viewer, // Can read only
  editor, // Can read and write
  admin, // Can read, write, and manage sharing
}

/// Types of shareable resources.
enum ShareType {
  note, // Single note
  notebook, // Notebook with all notes
  vault, // Entire vault (for team vaults)
}

/// A share invitation/membership.
class Share {
  /// Unique share ID
  final String shareId;

  /// Type of shared resource
  final ShareType type;

  /// ID of the shared resource
  final String resourceId;

  /// Human-readable name (encrypted separately)
  final String? resourceName;

  /// Role granted to recipient
  final ShareRole role;

  /// Hash of sharer's public key (for identification)
  final String sharerPublicKeyHash;

  /// Hash of recipient's public key
  final String recipientPublicKeyHash;

  /// The wrapped scope key
  final WrappedKey wrappedKey;

  /// When the share was created
  final DateTime createdAt;

  /// When the share expires (null = never)
  final DateTime? expiresAt;

  /// Whether the share is currently active
  final bool isActive;

  Share({
    required this.shareId,
    required this.type,
    required this.resourceId,
    this.resourceName,
    required this.role,
    required this.sharerPublicKeyHash,
    required this.recipientPublicKeyHash,
    required this.wrappedKey,
    required this.createdAt,
    this.expiresAt,
    this.isActive = true,
  });

  /// Creates a new share.
  factory Share.create({
    required ShareType type,
    required String resourceId,
    String? resourceName,
    required ShareRole role,
    required String sharerPublicKeyHash,
    required String recipientPublicKeyHash,
    required WrappedKey wrappedKey,
    DateTime? expiresAt,
  }) {
    return Share(
      shareId: const Uuid().v4(),
      type: type,
      resourceId: resourceId,
      resourceName: resourceName,
      role: role,
      sharerPublicKeyHash: sharerPublicKeyHash,
      recipientPublicKeyHash: recipientPublicKeyHash,
      wrappedKey: wrappedKey,
      createdAt: DateTime.now().toUtc(),
      expiresAt: expiresAt,
    );
  }

  /// Revokes this share.
  Share revoke() {
    return Share(
      shareId: shareId,
      type: type,
      resourceId: resourceId,
      resourceName: resourceName,
      role: role,
      sharerPublicKeyHash: sharerPublicKeyHash,
      recipientPublicKeyHash: recipientPublicKeyHash,
      wrappedKey: wrappedKey,
      createdAt: createdAt,
      expiresAt: expiresAt,
      isActive: false,
    );
  }

  /// Checks if the share is expired.
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Checks if the share is usable.
  bool get isUsable => isActive && !isExpired;

  Map<String, dynamic> toJson() => {
    'share_id': shareId,
    'type': type.name,
    'resource_id': resourceId,
    'resource_name': resourceName,
    'role': role.name,
    'sharer_public_key_hash': sharerPublicKeyHash,
    'recipient_public_key_hash': recipientPublicKeyHash,
    'wrapped_key': base64Encode(wrappedKey.toBytes()),
    'created_at': createdAt.toIso8601String(),
    'expires_at': expiresAt?.toIso8601String(),
    'is_active': isActive,
  };

  factory Share.fromJson(Map<String, dynamic> json) {
    return Share(
      shareId: json['share_id'] as String,
      type: ShareType.values.firstWhere((t) => t.name == json['type']),
      resourceId: json['resource_id'] as String,
      resourceName: json['resource_name'] as String?,
      role: ShareRole.values.firstWhere((r) => r.name == json['role']),
      sharerPublicKeyHash: json['sharer_public_key_hash'] as String,
      recipientPublicKeyHash: json['recipient_public_key_hash'] as String,
      wrappedKey: WrappedKey.fromBytes(
        base64Decode(json['wrapped_key'] as String),
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}

/// Service for managing sharing.
class SharingService implements ISharingService {
  final CryptoService _crypto;

  SharingService(this._crypto);

  /// Computes a hash of a public key for identification.
  @override
  String publicKeyHash(Uint8List publicKey) {
    final hash = _crypto.blake3.hash(publicKey);
    return hash.hex;
  }

  /// Creates a share for a notebook.
  @override
  Share shareNotebook({
    required NotebookKey notebookKey,
    required String notebookId,
    String? notebookName,
    required ShareRole role,
    required UserPublicIdentity recipient,
    required UserIdentity sharer,
    DateTime? expiresAt,
  }) {
    // Wrap the notebook key with recipient's public key
    final wrappedKey = _crypto.x25519.wrapKey(
      keyToWrap: notebookKey,
      recipientPublicKey: recipient.encryptionPublicKey,
    );

    return Share.create(
      type: ShareType.notebook,
      resourceId: notebookId,
      resourceName: notebookName,
      role: role,
      sharerPublicKeyHash: publicKeyHash(sharer.encryptionKey.publicKey),
      recipientPublicKeyHash: publicKeyHash(recipient.encryptionPublicKey),
      wrappedKey: wrappedKey,
      expiresAt: expiresAt,
    );
  }

  /// Creates a share for a single note.
  @override
  Share shareNote({
    required NoteShareKey noteShareKey,
    required String noteId,
    String? noteTitle,
    required ShareRole role,
    required UserPublicIdentity recipient,
    required UserIdentity sharer,
    DateTime? expiresAt,
  }) {
    final wrappedKey = _crypto.x25519.wrapKey(
      keyToWrap: noteShareKey,
      recipientPublicKey: recipient.encryptionPublicKey,
    );

    return Share.create(
      type: ShareType.note,
      resourceId: noteId,
      resourceName: noteTitle,
      role: role,
      sharerPublicKeyHash: publicKeyHash(sharer.encryptionKey.publicKey),
      recipientPublicKeyHash: publicKeyHash(recipient.encryptionPublicKey),
      wrappedKey: wrappedKey,
      expiresAt: expiresAt,
    );
  }

  /// Accepts a share and unwraps the key.
  @override
  SecureBytes acceptShare({
    required Share share,
    required UserIdentity recipient,
  }) {
    // Verify this share is for us
    final ourKeyHash = publicKeyHash(recipient.encryptionKey.publicKey);
    if (share.recipientPublicKeyHash != ourKeyHash) {
      throw ArgumentError('This share is not for this user');
    }

    if (!share.isUsable) {
      throw StateError('This share is not usable (revoked or expired)');
    }

    // Unwrap the key
    return _crypto.x25519.unwrapKey(
      wrappedKey: share.wrappedKey,
      ourSecretKey: recipient.encryptionKey.secretKey,
    );
  }

  /// Lists shares where we are the recipient.
  @override
  List<Share> filterSharesForRecipient({
    required List<Share> allShares,
    required UserIdentity recipient,
  }) {
    final ourKeyHash = publicKeyHash(recipient.encryptionKey.publicKey);
    return allShares
        .where((s) => s.recipientPublicKeyHash == ourKeyHash)
        .where((s) => s.isUsable)
        .toList();
  }

  /// Lists shares where we are the sharer.
  @override
  List<Share> filterSharesFromSharer({
    required List<Share> allShares,
    required UserIdentity sharer,
  }) {
    final ourKeyHash = publicKeyHash(sharer.encryptionKey.publicKey);
    return allShares.where((s) => s.sharerPublicKeyHash == ourKeyHash).toList();
  }
}

/// Manages notebook key rotation for revocation.
class NotebookKeyRotation {
  final CryptoService _crypto;

  NotebookKeyRotation(this._crypto);

  /// Rotates a notebook key when revoking access.
  ///
  /// Returns the new key and updated shares for remaining members.
  NotebookKeyRotationResult rotate({
    required NotebookKey oldKey,
    required String notebookId,
    required List<Share> existingShares,
    required String revokedRecipientKeyHash,
    required UserIdentity sharer,
  }) {
    // Generate new notebook key
    final newKeyBytes = _crypto.random.symmetricKey();
    final newKey = NotebookKey(newKeyBytes, notebookId: notebookId);

    // Create new shares for remaining members
    final newShares = <Share>[];
    final sharerKeyHash = SharingService(
      _crypto,
    ).publicKeyHash(sharer.encryptionKey.publicKey);

    for (final oldShare in existingShares) {
      // Skip the revoked recipient
      if (oldShare.recipientPublicKeyHash == revokedRecipientKeyHash) {
        continue;
      }

      // Skip inactive shares
      if (!oldShare.isUsable) {
        continue;
      }

      // Re-wrap new key for this recipient
      final wrappedKey = _crypto.x25519.wrapKey(
        keyToWrap: newKey,
        recipientPublicKey: oldShare.wrappedKey.recipientPublicKey,
      );

      newShares.add(
        Share.create(
          type: ShareType.notebook,
          resourceId: notebookId,
          role: oldShare.role,
          sharerPublicKeyHash: sharerKeyHash,
          recipientPublicKeyHash: oldShare.recipientPublicKeyHash,
          wrappedKey: wrappedKey,
        ),
      );
    }

    return NotebookKeyRotationResult(
      newKey: newKey,
      updatedShares: newShares,
      revokedShareIds: existingShares
          .where((s) => s.recipientPublicKeyHash == revokedRecipientKeyHash)
          .map((s) => s.shareId)
          .toList(),
    );
  }
}

/// Result of notebook key rotation.
class NotebookKeyRotationResult {
  final NotebookKey newKey;
  final List<Share> updatedShares;
  final List<String> revokedShareIds;

  NotebookKeyRotationResult({
    required this.newKey,
    required this.updatedShares,
    required this.revokedShareIds,
  });
}
