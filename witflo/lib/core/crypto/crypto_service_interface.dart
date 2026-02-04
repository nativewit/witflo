// ═══════════════════════════════════════════════════════════════════════════
// WITFLO - Zero-Trust Notes OS
// ICryptoService - Cryptography Service Interface
// ═══════════════════════════════════════════════════════════════════════════
//
// This interface defines the contract for cryptographic services in Witflo.
// It provides access to cryptographic primitives and convenience methods.
//
// INITIALIZATION:
// Implementations must provide an initialize() method for libsodium setup.
//
// THREAD SAFETY:
// Crypto operations should be performed in Dart isolates for heavy work.
// The service itself must be stateless and can be safely shared.
// ═══════════════════════════════════════════════════════════════════════════

import 'package:witflo_app/core/crypto/primitives/primitives.dart';
import 'package:witflo_app/core/crypto/types/types.dart';
import 'package:sodium_libs/sodium_libs_sumo.dart';

/// Central cryptography service interface for Witflo.
///
/// Must be initialized before use via implementation's initialize() method.
abstract interface class ICryptoService {
  // ═══════════════════════════════════════════════════════════════════════════
  // PRIMITIVE ACCESSORS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Argon2id key derivation function for password hashing.
  Argon2idKdf get argon2id;

  /// XChaCha20-Poly1305 authenticated encryption.
  XChaCha20Poly1305 get xchacha20;

  /// HKDF-SHA256 key derivation.
  HkdfSha256 get hkdf;

  /// BLAKE3 cryptographic hash function.
  Blake3Hash get blake3;

  /// Ed25519 digital signatures.
  Ed25519Signing get ed25519;

  /// X25519 key exchange for Diffie-Hellman.
  X25519KeyExchange get x25519;

  /// Cryptographically secure random number generator.
  SecureRandom get random;

  // ═══════════════════════════════════════════════════════════════════════════
  // LOW-LEVEL ACCESS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Access to raw libsodium (for advanced use only).
  ///
  /// Throws [StateError] if not initialized.
  SodiumSumo get sodium;

  // ═══════════════════════════════════════════════════════════════════════════
  // CONVENIENCE METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Encrypts data with a key, returning the ciphertext.
  EncryptionResult encryptBytes({
    required SecureBytes plaintext,
    required CryptoKey key,
  });

  /// Decrypts ciphertext with a key, returning the plaintext.
  SecureBytes decryptBytes({
    required EncryptionResult ciphertext,
    required CryptoKey key,
  });

  /// Hashes encrypted data and returns a content address.
  ContentHash hashContent(EncryptionResult encrypted);
}
