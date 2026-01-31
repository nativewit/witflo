// ═══════════════════════════════════════════════════════════════════════════
// FYNDO - Zero-Trust Notes OS
// Secure Random - Cryptographically Secure Random Number Generation
// ═══════════════════════════════════════════════════════════════════════════
//
// SECURITY RATIONALE:
// All random values in Fyndo MUST come from libsodium's CSPRNG.
// This ensures:
// 1. Cryptographic quality randomness
// 2. Platform-appropriate entropy sources
// 3. No weak random from Math.random()
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:typed_data';

import 'package:fyndo_app/core/crypto/types/types.dart';
import 'package:sodium_libs/sodium_libs_sumo.dart';

/// Secure random number generation using libsodium.
class SecureRandom {
  final SodiumSumo _sodium;

  SecureRandom(this._sodium);

  /// Generates random bytes.
  Uint8List bytes(int length) {
    return _sodium.randombytes.buf(length);
  }

  /// Generates random bytes wrapped in SecureBytes (for keys).
  SecureBytes secureBytes(int length) {
    return SecureBytes(_sodium.randombytes.buf(length));
  }

  /// Generates a random symmetric key (32 bytes).
  SecureBytes symmetricKey() {
    return secureBytes(KeySizes.symmetricKey);
  }

  /// Generates a random salt for Argon2id.
  Uint8List salt() {
    return bytes(KeySizes.salt);
  }

  /// Generates a random nonce for XChaCha20.
  Uint8List nonce() {
    return bytes(KeySizes.xChaCha20Nonce);
  }

  /// Generates a random 32-bit unsigned integer.
  int uint32() {
    return _sodium.randombytes.uniform(0xFFFFFFFF);
  }

  /// Generates a random integer in range [0, upperBound).
  int uniformInt(int upperBound) {
    return _sodium.randombytes.uniform(upperBound);
  }
}
