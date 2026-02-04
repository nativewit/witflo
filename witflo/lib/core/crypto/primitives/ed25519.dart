// ═══════════════════════════════════════════════════════════════════════════
// WITFLO - Zero-Trust Notes OS
// Ed25519 - Digital Signatures for Vault Operations
// ═══════════════════════════════════════════════════════════════════════════
//
// SECURITY RATIONALE:
// Ed25519 provides fast, secure digital signatures for:
// - Signing CRDT operations (to verify author)
// - User identity verification
// - Vault integrity protection
//
// WHY ED25519:
// 1. Fast: ~15,000 signatures/sec on modern hardware
// 2. Small: 64-byte signatures, 32-byte public keys
// 3. Deterministic: Same message → same signature (no nonce needed)
// 4. Widely audited: Part of TLS 1.3, SSH, Signal Protocol
//
// USAGE IN WITFLO:
// - User Identity Key (UIK): Long-term Ed25519 for identity
// - Device Identity Key (DIK): Per-device Ed25519 for signing
// - Sign sync operations to prove authorship
// - Verify signatures before applying remote changes
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:typed_data';

import 'package:witflo_app/core/crypto/types/types.dart';
import 'package:sodium_libs/sodium_libs_sumo.dart';

/// A detached signature that can be verified separately from the message.
class Signature {
  /// Raw signature bytes (64 bytes)
  final Uint8List bytes;

  Signature(this.bytes) {
    if (bytes.length != KeySizes.ed25519Signature) {
      throw ArgumentError(
        'Signature must be ${KeySizes.ed25519Signature} bytes',
      );
    }
  }

  /// Hexadecimal representation.
  String get hex =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  @override
  String toString() => 'Signature(${hex.substring(0, 16)}...)';
}

/// Ed25519 signing and verification using libsodium.
class Ed25519Signing {
  final SodiumSumo _sodium;

  Ed25519Signing(this._sodium);

  /// Generates a new Ed25519 key pair.
  ///
  /// Use for:
  /// - User Identity Key (UIK) on first vault creation
  /// - Device Identity Key (DIK) on device registration
  Ed25519KeyPair generateKeyPair() {
    final keyPair = _sodium.crypto.sign.keyPair();
    return Ed25519KeyPair(
      secretKey: SecureBytes(
        Uint8List.fromList(keyPair.secretKey.extractBytes()),
      ),
      publicKey: Uint8List.fromList(keyPair.publicKey),
    );
  }

  /// Generates a key pair from a seed (deterministic).
  ///
  /// Use for deriving identity key from vault key:
  /// UIK = Ed25519.fromSeed(HKDF(VK, "fyndo.identity.signing.v1"))
  Ed25519KeyPair generateKeyPairFromSeed(SecureBytes seed) {
    if (seed.length != 32) {
      throw ArgumentError('Seed must be 32 bytes');
    }

    final secureKeySeed = SecureKey.fromList(_sodium, seed.unsafeBytes);
    final keyPair = _sodium.crypto.sign.seedKeyPair(secureKeySeed);

    return Ed25519KeyPair(
      secretKey: SecureBytes(
        Uint8List.fromList(keyPair.secretKey.extractBytes()),
      ),
      publicKey: Uint8List.fromList(keyPair.publicKey),
    );
  }

  /// Signs a message and returns a detached signature.
  ///
  /// The signature can be verified using only the public key.
  ///
  /// [message] - Data to sign (e.g., serialized CRDT operation)
  /// [keyPair] - Ed25519 key pair for signing
  ///
  /// Returns [Signature] that can be stored alongside the message.
  Signature sign({
    required Uint8List message,
    required Ed25519KeyPair keyPair,
  }) {
    // Create SecureKey from the secret key bytes
    final secretKey = SecureKey.fromList(
      _sodium,
      keyPair.secretKey.unsafeBytes,
    );
    try {
      final signature = _sodium.crypto.sign.detached(
        message: message,
        secretKey: secretKey,
      );
      return Signature(signature);
    } finally {
      secretKey.dispose();
    }
  }

  /// Verifies a detached signature.
  ///
  /// [message] - Original message that was signed
  /// [signature] - Signature to verify
  /// [publicKey] - Signer's public key
  ///
  /// Returns true if signature is valid, false otherwise.
  bool verify({
    required Uint8List message,
    required Signature signature,
    required Uint8List publicKey,
  }) {
    if (publicKey.length != KeySizes.ed25519PublicKey) {
      throw ArgumentError(
        'Public key must be ${KeySizes.ed25519PublicKey} bytes',
      );
    }

    try {
      return _sodium.crypto.sign.verifyDetached(
        message: message,
        signature: signature.bytes,
        publicKey: publicKey,
      );
    } catch (e) {
      // Invalid signature format
      return false;
    }
  }

  /// Extracts the public key from a secret key.
  Uint8List publicKeyFromSecretKey(SecureBytes secretKey) {
    if (secretKey.length != KeySizes.ed25519SecretKey) {
      throw ArgumentError(
        'Secret key must be ${KeySizes.ed25519SecretKey} bytes',
      );
    }

    // Ed25519 secret key contains public key in last 32 bytes
    return Uint8List.fromList(secretKey.unsafeBytes.sublist(32, 64));
  }
}
