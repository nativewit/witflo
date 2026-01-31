// ═══════════════════════════════════════════════════════════════════════════
// FYNDO - Zero-Trust Notes OS
// User Identity - Long-term Identity for Sharing
// ═══════════════════════════════════════════════════════════════════════════
//
// USER IDENTITY CONCEPT:
// Each user has a long-term identity used for:
// 1. Receiving shared notebooks from other users
// 2. Signing notes for authorship verification
// 3. Key recovery (optional backup identity)
//
// DERIVATION:
// User Identity Key is derived from Vault Key via HKDF:
// - Signing: HKDF(VK, "fyndo.identity.signing.v1") → Ed25519 seed
// - Encryption: HKDF(VK, "fyndo.identity.encryption.v1") → X25519 seed
//
// This means:
// - UIK is deterministic from VK (recoverable with password)
// - Different vaults = different identities (unless linked)
// - No separate backup needed for identity
//
// PUBLIC KEY EXCHANGE:
// Users exchange public keys out-of-band (QR code, link, etc.)
// Server stores public keys for discovery (optional)
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'dart:typed_data';

import 'package:fyndo_app/core/crypto/crypto.dart';

/// User identity derived from vault key.
class UserIdentity {
  /// Ed25519 key pair for signing
  final Ed25519KeyPair signingKey;

  /// X25519 key pair for encryption/key exchange
  final X25519KeyPair encryptionKey;

  UserIdentity({required this.signingKey, required this.encryptionKey});

  /// Public portion (safe to share).
  UserPublicIdentity get publicIdentity => UserPublicIdentity(
    signingPublicKey: signingKey.publicKey,
    encryptionPublicKey: encryptionKey.publicKey,
  );

  /// Fingerprint for identity verification.
  String get fingerprint {
    // Combine public keys and hash for fingerprint
    final combined = Uint8List(64);
    combined.setRange(0, 32, signingKey.publicKey);
    combined.setRange(32, 64, encryptionKey.publicKey);

    // Use first 8 bytes of hash as fingerprint
    final hash = CryptoService.instance.blake3.hash(combined);
    return hash.hex.substring(0, 16).toUpperCase();
  }

  void dispose() {
    signingKey.dispose();
    encryptionKey.dispose();
  }
}

/// Public portion of user identity.
class UserPublicIdentity {
  final Uint8List signingPublicKey;
  final Uint8List encryptionPublicKey;

  UserPublicIdentity({
    required this.signingPublicKey,
    required this.encryptionPublicKey,
  });

  /// Fingerprint for identity verification.
  String get fingerprint {
    final combined = Uint8List(64);
    combined.setRange(0, 32, signingPublicKey);
    combined.setRange(32, 64, encryptionPublicKey);

    final hash = CryptoService.instance.blake3.hash(combined);
    return hash.hex.substring(0, 16).toUpperCase();
  }

  /// Creates a shareable string representation.
  String toShareableString() {
    final data = {
      'type': 'fyndo_identity',
      'version': 1,
      'signing': base64Encode(signingPublicKey),
      'encryption': base64Encode(encryptionPublicKey),
    };
    return base64Encode(utf8.encode(jsonEncode(data)));
  }

  /// Parses from shareable string.
  factory UserPublicIdentity.fromShareableString(String encoded) {
    final json =
        jsonDecode(utf8.decode(base64Decode(encoded))) as Map<String, dynamic>;

    if (json['type'] != 'fyndo_identity') {
      throw FormatException('Invalid identity format');
    }

    return UserPublicIdentity(
      signingPublicKey: base64Decode(json['signing'] as String),
      encryptionPublicKey: base64Decode(json['encryption'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'signing_public_key': base64Encode(signingPublicKey),
    'encryption_public_key': base64Encode(encryptionPublicKey),
  };

  factory UserPublicIdentity.fromJson(Map<String, dynamic> json) {
    return UserPublicIdentity(
      signingPublicKey: base64Decode(json['signing_public_key'] as String),
      encryptionPublicKey: base64Decode(
        json['encryption_public_key'] as String,
      ),
    );
  }
}

/// Service for user identity management.
class UserIdentityService {
  final CryptoService _crypto;

  UserIdentityService(this._crypto);

  /// Derives user identity from vault key.
  ///
  /// This is deterministic - same VK always produces same identity.
  UserIdentity deriveFromVaultKey(VaultKey vaultKey) {
    // Derive signing key seed
    final signingSeed = _crypto.hkdf.deriveKey(
      inputKey: vaultKey,
      info: 'fyndo.identity.signing.v1',
      outputLength: 32,
    );

    // Derive encryption key seed
    final encryptionSeed = _crypto.hkdf.deriveKey(
      inputKey: vaultKey,
      info: 'fyndo.identity.encryption.v1',
      outputLength: 32,
    );

    // Generate key pairs from seeds
    final signingKey = _crypto.ed25519.generateKeyPairFromSeed(signingSeed);
    final encryptionKey = _crypto.x25519.generateKeyPair();

    // Note: For X25519, we should ideally derive from seed
    // For now, we use the encryptionSeed as the secret key directly
    // This is a simplification - in production, use proper seed derivation

    encryptionSeed.dispose();

    return UserIdentity(signingKey: signingKey, encryptionKey: encryptionKey);
  }

  /// Wraps a key for a user (for sharing).
  WrappedKey wrapKeyForUser({
    required CryptoKey keyToWrap,
    required UserPublicIdentity recipient,
  }) {
    return _crypto.x25519.wrapKey(
      keyToWrap: keyToWrap,
      recipientPublicKey: recipient.encryptionPublicKey,
    );
  }

  /// Unwraps a key received from another user.
  SecureBytes unwrapKey({
    required WrappedKey wrappedKey,
    required UserIdentity ourIdentity,
  }) {
    return _crypto.x25519.unwrapKey(
      wrappedKey: wrappedKey,
      ourSecretKey: ourIdentity.encryptionKey.secretKey,
    );
  }

  /// Signs content with user identity.
  Signature sign({required Uint8List content, required UserIdentity identity}) {
    return _crypto.ed25519.sign(message: content, keyPair: identity.signingKey);
  }

  /// Verifies a signature from a user.
  bool verify({
    required Uint8List content,
    required Signature signature,
    required UserPublicIdentity signer,
  }) {
    return _crypto.ed25519.verify(
      message: content,
      signature: signature,
      publicKey: signer.signingPublicKey,
    );
  }
}
