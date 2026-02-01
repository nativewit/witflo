// ═══════════════════════════════════════════════════════════════════════════
// FYNDO - Zero-Trust Notes OS
// CryptoService - Unified Cryptography Interface
// ═══════════════════════════════════════════════════════════════════════════
//
// This service provides a unified interface to all cryptographic primitives.
// It ensures libsodium is properly initialized before any crypto operations.
//
// INITIALIZATION:
// Call CryptoService.initialize() once at app startup.
// All crypto operations will fail if not initialized.
//
// THREAD SAFETY:
// Crypto operations should be performed in Dart isolates for heavy work.
// The service itself is stateless and can be safely shared.
//
// NOTE: We use SodiumSumo (not Sodium) to access the full API including
// pwhash (Argon2id). This requires the sumo variant of sodium.js for web.
// ═══════════════════════════════════════════════════════════════════════════

import 'package:fyndo_app/core/crypto/crypto_service_interface.dart';
import 'package:fyndo_app/core/crypto/primitives/primitives.dart';
import 'package:fyndo_app/core/crypto/types/types.dart';
import 'package:sodium_libs/sodium_libs_sumo.dart';

/// Central cryptography service for Fyndo.
///
/// Must be initialized before use via [CryptoService.initialize()].
class CryptoService implements ICryptoService {
  static CryptoService? _instance;
  static SodiumSumo? _sodium;

  /// Whether the crypto service has been initialized.
  static bool get isInitialized => _instance != null && _sodium != null;

  // Primitive accessors
  late final Argon2idKdf argon2id;
  late final XChaCha20Poly1305 xchacha20;
  late final HkdfSha256 hkdf;
  late final Blake3Hash blake3;
  late final Ed25519Signing ed25519;
  late final X25519KeyExchange x25519;
  late final SecureRandom random;

  CryptoService._(SodiumSumo sodium) {
    argon2id = Argon2idKdf(sodium);
    xchacha20 = XChaCha20Poly1305(sodium);
    hkdf = HkdfSha256(sodium);
    blake3 = Blake3Hash(sodium);
    ed25519 = Ed25519Signing(sodium);
    x25519 = X25519KeyExchange(sodium);
    random = SecureRandom(sodium);
  }

  /// Initializes the crypto service.
  ///
  /// Must be called once at app startup before any crypto operations.
  /// Returns the singleton [CryptoService] instance.
  static Future<CryptoService> initialize() async {
    if (_instance != null) {
      return _instance!;
    }

    // Initialize libsodium with SodiumSumo for full API access
    _sodium = await SodiumSumoInit.init();

    _instance = CryptoService._(_sodium!);
    return _instance!;
  }

  /// Gets the singleton instance.
  ///
  /// Throws if [initialize()] hasn't been called.
  static CryptoService get instance {
    if (_instance == null) {
      throw StateError(
        'CryptoService not initialized. Call CryptoService.initialize() first.',
      );
    }
    return _instance!;
  }

  /// Access to raw libsodium (for advanced use only).
  @override
  SodiumSumo get sodium {
    if (_sodium == null) {
      throw StateError('CryptoService not initialized');
    }
    return _sodium!;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CONVENIENCE METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Encrypts data with a key, returning the ciphertext.
  @override
  EncryptionResult encryptBytes({
    required SecureBytes plaintext,
    required CryptoKey key,
  }) {
    return xchacha20.encrypt(plaintext: plaintext, key: key);
  }

  /// Decrypts ciphertext with a key, returning the plaintext.
  @override
  SecureBytes decryptBytes({
    required EncryptionResult ciphertext,
    required CryptoKey key,
  }) {
    return xchacha20.decrypt(ciphertext: ciphertext.ciphertext, key: key);
  }

  /// Hashes data and returns a content address.
  @override
  ContentHash hashContent(EncryptionResult encrypted) {
    return blake3.hash(encrypted.ciphertext);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DEPRECATED EXTENSIONS (kept for backwards compatibility)
// ═══════════════════════════════════════════════════════════════════════════

/// Extension for easy access to crypto service from anywhere.
///
/// DEPRECATED: Use the methods directly on ICryptoService instead.
@Deprecated('Use methods directly on ICryptoService')
extension CryptoExtensions on CryptoService {
  /// Encrypts data with a key, returning the ciphertext.
  EncryptionResult encryptBytes({
    required SecureBytes plaintext,
    required CryptoKey key,
  }) {
    return xchacha20.encrypt(plaintext: plaintext, key: key);
  }

  /// Decrypts ciphertext with a key, returning the plaintext.
  SecureBytes decryptBytes({
    required EncryptionResult ciphertext,
    required CryptoKey key,
  }) {
    return xchacha20.decrypt(ciphertext: ciphertext.ciphertext, key: key);
  }

  /// Hashes data and returns a content address.
  ContentHash hashContent(EncryptionResult encrypted) {
    return blake3.hash(encrypted.ciphertext);
  }
}
