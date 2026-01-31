// ═══════════════════════════════════════════════════════════════════════════
// FYNDO - Zero-Trust Notes OS
// Key Types - Strongly-typed key containers with lifecycle management
// ═══════════════════════════════════════════════════════════════════════════
//
// SECURITY RATIONALE:
// Type-safe key containers prevent:
// 1. Accidentally using wrong key type (e.g., signing key for encryption)
// 2. Key material leaking through logging/serialization
// 3. Keys remaining in memory after use
//
// KEY HIERARCHY (as per Fyndo security model):
// Master Password (never stored)
//   ↓ Argon2id
// Master Unlock Key (MUK) - memory only, never persisted
//   ↓ decrypts
// Vault Key (VK) - 256-bit, stored encrypted with MUK
//   ↓ HKDF
// Content Key (CK) - per note/chunk
// Notebook Key (NK) - per notebook (for sharing)
// Group Key (GK) - per shared vault
// Note Share Key (NSK) - one-off shares
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:typed_data';

import 'package:fyndo_app/core/crypto/types/secure_bytes.dart';

// ═══════════════════════════════════════════════════════════════════════════
// KEY SIZE CONSTANTS
// ═══════════════════════════════════════════════════════════════════════════

/// Standard key sizes used throughout Fyndo.
/// All sizes are derived from libsodium recommendations.
abstract class KeySizes {
  /// Symmetric key size for XChaCha20-Poly1305 (256 bits)
  static const int symmetricKey = 32;

  /// Salt size for Argon2id (recommended minimum 16 bytes)
  static const int salt = 16;

  /// Nonce size for XChaCha20-Poly1305 (192 bits = 24 bytes)
  static const int xChaCha20Nonce = 24;

  /// Authentication tag size for Poly1305 (128 bits = 16 bytes)
  static const int authTag = 16;

  /// Ed25519 public key size
  static const int ed25519PublicKey = 32;

  /// Ed25519 secret key size
  static const int ed25519SecretKey = 64;

  /// Ed25519 signature size
  static const int ed25519Signature = 64;

  /// X25519 public key size
  static const int x25519PublicKey = 32;

  /// X25519 secret key size
  static const int x25519SecretKey = 32;

  /// BLAKE3 hash output size (default)
  static const int blake3Hash = 32;
}

// ═══════════════════════════════════════════════════════════════════════════
// BASE KEY CLASS
// ═══════════════════════════════════════════════════════════════════════════

/// Base class for all cryptographic keys.
/// Provides automatic zeroization and lifecycle management.
abstract class CryptoKey {
  final SecureBytes _keyMaterial;
  bool _isDisposed = false;

  CryptoKey(this._keyMaterial);

  /// The expected length of this key type in bytes.
  int get expectedLength;

  /// Human-readable name for this key type (for errors/logging).
  String get keyTypeName;

  /// Whether this key has been disposed.
  bool get isDisposed => _isDisposed;

  /// Access the raw key bytes.
  /// Use with extreme caution - prefer using key through crypto operations.
  SecureBytes get material {
    _checkNotDisposed();
    return _keyMaterial;
  }

  /// Securely dispose this key, zeroizing memory.
  void dispose() {
    if (!_isDisposed) {
      _keyMaterial.dispose();
      _isDisposed = true;
    }
  }

  void _checkNotDisposed() {
    if (_isDisposed) {
      throw StateError(
        '$keyTypeName has been disposed. '
        'Using disposed keys is a security violation.',
      );
    }
  }

  @override
  String toString() {
    if (_isDisposed) {
      return '$keyTypeName(disposed)';
    }
    return '$keyTypeName(${_keyMaterial.length} bytes)';
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SYMMETRIC KEYS
// ═══════════════════════════════════════════════════════════════════════════

/// Master Unlock Key - derived from password via Argon2id.
/// CRITICAL: Never persisted, memory-only.
class MasterUnlockKey extends CryptoKey {
  MasterUnlockKey(SecureBytes material) : super(material) {
    if (material.length != KeySizes.symmetricKey) {
      throw ArgumentError(
        'MasterUnlockKey must be ${KeySizes.symmetricKey} bytes, '
        'got ${material.length}',
      );
    }
  }

  @override
  int get expectedLength => KeySizes.symmetricKey;

  @override
  String get keyTypeName => 'MasterUnlockKey';
}

/// Vault Key - the root key for all vault content.
/// Stored encrypted with MUK in vault.vk file.
class VaultKey extends CryptoKey {
  VaultKey(SecureBytes material) : super(material) {
    if (material.length != KeySizes.symmetricKey) {
      throw ArgumentError(
        'VaultKey must be ${KeySizes.symmetricKey} bytes, '
        'got ${material.length}',
      );
    }
  }

  /// Generate a new random VaultKey.
  factory VaultKey.generate(Uint8List randomBytes) {
    if (randomBytes.length != KeySizes.symmetricKey) {
      throw ArgumentError(
        'Random bytes must be ${KeySizes.symmetricKey} bytes',
      );
    }
    return VaultKey(SecureBytes(randomBytes));
  }

  @override
  int get expectedLength => KeySizes.symmetricKey;

  @override
  String get keyTypeName => 'VaultKey';
}

/// Content Key - derived from VaultKey for encrypting specific content.
/// Each note/chunk gets a unique ContentKey derived via HKDF.
class ContentKey extends CryptoKey {
  /// The context string used to derive this key.
  final String context;

  ContentKey(SecureBytes material, {required this.context}) : super(material) {
    if (material.length != KeySizes.symmetricKey) {
      throw ArgumentError(
        'ContentKey must be ${KeySizes.symmetricKey} bytes, '
        'got ${material.length}',
      );
    }
  }

  @override
  int get expectedLength => KeySizes.symmetricKey;

  @override
  String get keyTypeName => 'ContentKey';
}

/// Notebook Key - for encrypting shared notebooks.
/// Wrapped with recipient's public key for sharing.
class NotebookKey extends CryptoKey {
  /// Unique identifier for this notebook.
  final String notebookId;

  NotebookKey(SecureBytes material, {required this.notebookId})
    : super(material) {
    if (material.length != KeySizes.symmetricKey) {
      throw ArgumentError(
        'NotebookKey must be ${KeySizes.symmetricKey} bytes, '
        'got ${material.length}',
      );
    }
  }

  @override
  int get expectedLength => KeySizes.symmetricKey;

  @override
  String get keyTypeName => 'NotebookKey';
}

/// Group Key - for shared vaults.
class GroupKey extends CryptoKey {
  /// Unique identifier for this group.
  final String groupId;

  GroupKey(SecureBytes material, {required this.groupId}) : super(material) {
    if (material.length != KeySizes.symmetricKey) {
      throw ArgumentError(
        'GroupKey must be ${KeySizes.symmetricKey} bytes, '
        'got ${material.length}',
      );
    }
  }

  @override
  int get expectedLength => KeySizes.symmetricKey;

  @override
  String get keyTypeName => 'GroupKey';
}

/// Note Share Key - for one-off note sharing.
class NoteShareKey extends CryptoKey {
  /// Unique identifier for this share.
  final String shareId;

  NoteShareKey(SecureBytes material, {required this.shareId})
    : super(material) {
    if (material.length != KeySizes.symmetricKey) {
      throw ArgumentError(
        'NoteShareKey must be ${KeySizes.symmetricKey} bytes, '
        'got ${material.length}',
      );
    }
  }

  @override
  int get expectedLength => KeySizes.symmetricKey;

  @override
  String get keyTypeName => 'NoteShareKey';
}

// ═══════════════════════════════════════════════════════════════════════════
// ASYMMETRIC KEY PAIRS
// ═══════════════════════════════════════════════════════════════════════════

/// Ed25519 key pair for digital signatures.
/// Used for signing vault operations and identity verification.
class Ed25519KeyPair extends CryptoKey {
  final Uint8List publicKey;

  Ed25519KeyPair({required SecureBytes secretKey, required this.publicKey})
    : super(secretKey) {
    if (secretKey.length != KeySizes.ed25519SecretKey) {
      throw ArgumentError(
        'Ed25519 secret key must be ${KeySizes.ed25519SecretKey} bytes',
      );
    }
    if (publicKey.length != KeySizes.ed25519PublicKey) {
      throw ArgumentError(
        'Ed25519 public key must be ${KeySizes.ed25519PublicKey} bytes',
      );
    }
  }

  /// Access to secret key (via parent's material getter).
  SecureBytes get secretKey => material;

  @override
  int get expectedLength => KeySizes.ed25519SecretKey;

  @override
  String get keyTypeName => 'Ed25519KeyPair';
}

/// X25519 key pair for key exchange (sharing).
/// Used for wrapping keys to share with other users/devices.
class X25519KeyPair extends CryptoKey {
  final Uint8List publicKey;

  X25519KeyPair({required SecureBytes secretKey, required this.publicKey})
    : super(secretKey) {
    if (secretKey.length != KeySizes.x25519SecretKey) {
      throw ArgumentError(
        'X25519 secret key must be ${KeySizes.x25519SecretKey} bytes',
      );
    }
    if (publicKey.length != KeySizes.x25519PublicKey) {
      throw ArgumentError(
        'X25519 public key must be ${KeySizes.x25519PublicKey} bytes',
      );
    }
  }

  /// Access to secret key (via parent's material getter).
  SecureBytes get secretKey => material;

  @override
  int get expectedLength => KeySizes.x25519SecretKey;

  @override
  String get keyTypeName => 'X25519KeyPair';
}

// ═══════════════════════════════════════════════════════════════════════════
// ENCRYPTED KEY CONTAINER
// ═══════════════════════════════════════════════════════════════════════════

/// Container for an encrypted key blob.
/// Used for storing VK encrypted with MUK, or wrapped keys for sharing.
class EncryptedKey {
  /// The encrypted key ciphertext (includes nonce + auth tag).
  final Uint8List ciphertext;

  /// The nonce used for encryption.
  final Uint8List nonce;

  /// Optional: ID of the key used to encrypt this.
  final String? encryptingKeyId;

  EncryptedKey({
    required this.ciphertext,
    required this.nonce,
    this.encryptingKeyId,
  });

  /// Serialize to bytes for storage.
  Uint8List toBytes() {
    // Format: [nonce (24 bytes)] [ciphertext]
    final result = Uint8List(nonce.length + ciphertext.length);
    result.setRange(0, nonce.length, nonce);
    result.setRange(nonce.length, result.length, ciphertext);
    return result;
  }

  /// Deserialize from bytes.
  factory EncryptedKey.fromBytes(Uint8List data) {
    if (data.length < KeySizes.xChaCha20Nonce) {
      throw ArgumentError('Encrypted key data too short');
    }
    return EncryptedKey(
      nonce: Uint8List.fromList(data.sublist(0, KeySizes.xChaCha20Nonce)),
      ciphertext: Uint8List.fromList(data.sublist(KeySizes.xChaCha20Nonce)),
    );
  }
}
