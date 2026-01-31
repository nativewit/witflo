// ═══════════════════════════════════════════════════════════════════════════
// FYNDO - Zero-Trust Notes OS
// Crypto Providers - Riverpod State Management
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fyndo_app/core/crypto/crypto.dart';

/// Provider for the crypto service.
/// Must be initialized at app startup before accessing.
final cryptoServiceProvider = Provider<CryptoService>((ref) {
  if (!CryptoService.isInitialized) {
    throw StateError(
      'CryptoService not initialized. '
      'Call CryptoService.initialize() before running the app.',
    );
  }
  return CryptoService.instance;
});

/// Provider for Argon2id KDF.
final argon2idProvider = Provider<Argon2idKdf>((ref) {
  return ref.watch(cryptoServiceProvider).argon2id;
});

/// Provider for XChaCha20-Poly1305 AEAD.
final aeadProvider = Provider<XChaCha20Poly1305>((ref) {
  return ref.watch(cryptoServiceProvider).xchacha20;
});

/// Provider for HKDF key derivation.
final hkdfProvider = Provider<HkdfSha256>((ref) {
  return ref.watch(cryptoServiceProvider).hkdf;
});

/// Provider for BLAKE3 hashing.
final blake3Provider = Provider<Blake3Hash>((ref) {
  return ref.watch(cryptoServiceProvider).blake3;
});

/// Provider for Ed25519 signing.
final ed25519Provider = Provider<Ed25519Signing>((ref) {
  return ref.watch(cryptoServiceProvider).ed25519;
});

/// Provider for X25519 key exchange.
final x25519Provider = Provider<X25519KeyExchange>((ref) {
  return ref.watch(cryptoServiceProvider).x25519;
});

/// Provider for secure random.
final secureRandomProvider = Provider<SecureRandom>((ref) {
  return ref.watch(cryptoServiceProvider).random;
});
