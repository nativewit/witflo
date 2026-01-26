// ═══════════════════════════════════════════════════════════════════════════
// FYNDO - Zero-Trust Notes OS
// XChaCha20-Poly1305 - Authenticated Encryption with Associated Data (AEAD)
// ═══════════════════════════════════════════════════════════════════════════
//
// SECURITY RATIONALE:
// XChaCha20-Poly1305 is an AEAD cipher combining:
// - XChaCha20: Extended-nonce variant of ChaCha20 stream cipher
// - Poly1305: Message authentication code
//
// WHY XCHACHA20-POLY1305:
// 1. 192-bit nonce: Safe to generate randomly without collision risk
// 2. No AES-NI requirement: Fast on mobile/ARM without hardware support
// 3. Timing-safe: Constant-time implementation prevents side-channel attacks
// 4. Widely audited: Part of libsodium, NaCl, and TLS 1.3
// 5. AEAD: Authentication prevents tampering
//
// NONCE HANDLING:
// - 24-byte nonce is large enough for random generation
// - No need for counter management (unlike AES-GCM's 12-byte nonce)
// - Nonce is prepended to ciphertext for storage
//
// ASSOCIATED DATA (AAD):
// - Authenticated but not encrypted
// - Use for metadata that must be verified (note ID, version, etc.)
// - Prevents ciphertext from being moved between contexts
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:typed_data';

import 'package:fyndo_app/core/crypto/types/types.dart';
import 'package:sodium_libs/sodium_libs_sumo.dart';

/// Result of an encryption operation.
class EncryptionResult {
  /// The encrypted data (nonce || ciphertext || tag)
  final Uint8List ciphertext;

  /// The random nonce used (also prepended to ciphertext)
  final Uint8List nonce;

  const EncryptionResult({required this.ciphertext, required this.nonce});

  /// Total size: nonce (24) + plaintext + auth tag (16)
  int get totalLength => ciphertext.length;

  /// Extract just the encrypted payload (without prepended nonce)
  Uint8List get payloadOnly {
    if (ciphertext.length <= KeySizes.xChaCha20Nonce) {
      throw StateError('Ciphertext too short');
    }
    return Uint8List.fromList(ciphertext.sublist(KeySizes.xChaCha20Nonce));
  }
}

/// XChaCha20-Poly1305 AEAD encryption/decryption using libsodium.
///
/// This is the primary encryption primitive for Fyndo.
/// All note content, keys, and sensitive data are encrypted using this.
class XChaCha20Poly1305 {
  final SodiumSumo _sodium;

  XChaCha20Poly1305(this._sodium);

  /// Size of the authentication tag appended to ciphertext.
  int get authTagLength => 16; // Poly1305 tag is always 16 bytes

  /// Size of the nonce.
  int get nonceLength => 24; // XChaCha20 uses 24-byte nonce

  /// Size of the encryption key.
  int get keyLength => 32; // 256-bit key

  /// Generates a cryptographically secure random nonce.
  ///
  /// XChaCha20's 192-bit nonce is large enough that random generation
  /// is safe - collision probability is negligible.
  Uint8List generateNonce() {
    return _sodium.randombytes.buf(nonceLength);
  }

  /// Encrypts plaintext with authenticated associated data.
  ///
  /// **FORMAT**: The returned ciphertext is [nonce (24) || encrypted || tag (16)]
  ///
  /// [plaintext] - Data to encrypt (zeroized after encryption)
  /// [key] - Symmetric key (ContentKey, NotebookKey, etc.)
  /// [associatedData] - Authenticated but not encrypted metadata
  ///
  /// Returns [EncryptionResult] containing the ciphertext with prepended nonce.
  EncryptionResult encrypt({
    required SecureBytes plaintext,
    required CryptoKey key,
    Uint8List? associatedData,
  }) {
    final nonce = generateNonce();

    try {
      // Create SecureKey for sodium
      final secureKey = SecureKey.fromList(_sodium, key.material.unsafeBytes);

      try {
        final ciphertext = _sodium.crypto.aeadXChaCha20Poly1305IETF.encrypt(
          message: plaintext.unsafeBytes,
          nonce: nonce,
          key: secureKey,
          additionalData: associatedData,
        );

        // Prepend nonce to ciphertext for storage
        final result = Uint8List(nonce.length + ciphertext.length);
        result.setRange(0, nonce.length, nonce);
        result.setRange(nonce.length, result.length, ciphertext);

        return EncryptionResult(ciphertext: result, nonce: nonce);
      } finally {
        secureKey.dispose();
      }
    } finally {
      // Zeroize plaintext after encryption
      plaintext.dispose();
    }
  }

  /// Encrypts plaintext with a specific nonce (for deterministic encryption).
  ///
  /// **WARNING**: Only use when you need deterministic output (e.g., for testing
  /// or when nonce is derived via HKDF). Never reuse a nonce with the same key.
  ///
  /// [plaintext] - Data to encrypt (zeroized after encryption)
  /// [key] - Symmetric key
  /// [nonce] - Pre-generated nonce (MUST be unique per key)
  /// [associatedData] - Authenticated but not encrypted metadata
  EncryptionResult encryptWithNonce({
    required SecureBytes plaintext,
    required CryptoKey key,
    required Uint8List nonce,
    Uint8List? associatedData,
  }) {
    if (nonce.length != nonceLength) {
      throw ArgumentError('Nonce must be $nonceLength bytes');
    }

    try {
      final secureKey = SecureKey.fromList(_sodium, key.material.unsafeBytes);

      try {
        final ciphertext = _sodium.crypto.aeadXChaCha20Poly1305IETF.encrypt(
          message: plaintext.unsafeBytes,
          nonce: nonce,
          key: secureKey,
          additionalData: associatedData,
        );

        // Prepend nonce to ciphertext
        final result = Uint8List(nonce.length + ciphertext.length);
        result.setRange(0, nonce.length, nonce);
        result.setRange(nonce.length, result.length, ciphertext);

        return EncryptionResult(ciphertext: result, nonce: nonce);
      } finally {
        secureKey.dispose();
      }
    } finally {
      plaintext.dispose();
    }
  }

  /// Decrypts ciphertext and verifies authenticity.
  ///
  /// **FORMAT**: Expects [nonce (24) || encrypted || tag (16)]
  ///
  /// [ciphertext] - Data from encrypt() (includes nonce)
  /// [key] - Same key used for encryption
  /// [associatedData] - Must match what was used during encryption
  ///
  /// Returns [SecureBytes] containing the decrypted plaintext.
  /// Throws [SodiumException] if authentication fails (tampering detected).
  SecureBytes decrypt({
    required Uint8List ciphertext,
    required CryptoKey key,
    Uint8List? associatedData,
  }) {
    if (ciphertext.length < nonceLength + authTagLength) {
      throw ArgumentError(
        'Ciphertext too short. Minimum size: ${nonceLength + authTagLength} bytes',
      );
    }

    // Extract nonce and encrypted payload
    final nonce = Uint8List.fromList(ciphertext.sublist(0, nonceLength));
    final encryptedPayload = Uint8List.fromList(
      ciphertext.sublist(nonceLength),
    );

    final secureKey = SecureKey.fromList(_sodium, key.material.unsafeBytes);

    try {
      final plaintext = _sodium.crypto.aeadXChaCha20Poly1305IETF.decrypt(
        cipherText: encryptedPayload,
        nonce: nonce,
        key: secureKey,
        additionalData: associatedData,
      );

      return SecureBytes(plaintext);
    } finally {
      secureKey.dispose();
    }
  }

  /// Decrypts ciphertext when nonce is provided separately.
  ///
  /// Use when nonce is stored separately from ciphertext.
  SecureBytes decryptWithNonce({
    required Uint8List ciphertext,
    required Uint8List nonce,
    required CryptoKey key,
    Uint8List? associatedData,
  }) {
    if (nonce.length != nonceLength) {
      throw ArgumentError('Nonce must be $nonceLength bytes');
    }
    if (ciphertext.length < authTagLength) {
      throw ArgumentError('Ciphertext too short');
    }

    final secureKey = SecureKey.fromList(_sodium, key.material.unsafeBytes);

    try {
      final plaintext = _sodium.crypto.aeadXChaCha20Poly1305IETF.decrypt(
        cipherText: ciphertext,
        nonce: nonce,
        key: secureKey,
        additionalData: associatedData,
      );

      return SecureBytes(plaintext);
    } finally {
      secureKey.dispose();
    }
  }

  /// Calculates the ciphertext size for a given plaintext size.
  int ciphertextSize(int plaintextSize) {
    return nonceLength + plaintextSize + authTagLength;
  }

  /// Calculates the plaintext size from ciphertext size.
  int plaintextSize(int ciphertextSize) {
    final size = ciphertextSize - nonceLength - authTagLength;
    if (size < 0) {
      throw ArgumentError('Invalid ciphertext size');
    }
    return size;
  }
}
