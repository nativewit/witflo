// ═══════════════════════════════════════════════════════════════════════════
// WITFLO - Zero-Trust Notes OS
// Argon2id - Password Key Derivation Function
// ═══════════════════════════════════════════════════════════════════════════
//
// SECURITY RATIONALE:
// Argon2id is the winner of the Password Hashing Competition (2015) and is
// recommended by OWASP for password hashing. It combines:
// - Argon2d: Data-dependent memory access (GPU-resistant)
// - Argon2i: Data-independent memory access (side-channel resistant)
//
// WHY ARGON2ID:
// 1. Memory-hard: Requires significant RAM, defeating GPU/ASIC attacks
// 2. Time-hard: Configurable iterations slow down brute force
// 3. Parallelism-aware: Can utilize multiple cores
// 4. Side-channel resistant: Hybrid mode protects against timing attacks
//
// PARAMETERS (OWASP 2024 recommendations for sensitive applications):
// - Memory: 64 MiB minimum (we use 64 MiB = 65536 KiB)
// - Iterations: 3 minimum
// - Parallelism: 1 (single-threaded for mobile battery)
// - Salt: 16 bytes random
// - Output: 32 bytes (256-bit key)
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:typed_data';

import 'package:witflo_app/core/crypto/types/types.dart';
import 'package:sodium_libs/sodium_libs_sumo.dart';

/// Argon2id parameters for key derivation.
///
/// These parameters are stored in the vault header (plaintext)
/// to allow vault recovery.
class Argon2Params {
  /// Memory cost in KiB (default 64 MiB = 65536 KiB)
  final int memoryKiB;

  /// Number of iterations (default 3)
  final int iterations;

  /// Degree of parallelism (default 1)
  final int parallelism;

  /// Version identifier for future parameter upgrades
  final int version;

  const Argon2Params({
    this.memoryKiB = 65536, // 64 MiB
    this.iterations = 3,
    this.parallelism = 1,
    this.version = 1,
  });

  /// Minimal parameters for testing (NOT FOR PRODUCTION)
  static const Argon2Params test = Argon2Params(
    memoryKiB: 8192, // 8 MiB
    iterations: 1,
    parallelism: 1,
    version: 1,
  );

  /// OWASP recommended parameters for high-security applications
  static const Argon2Params highSecurity = Argon2Params(
    memoryKiB: 65536, // 64 MiB
    iterations: 4,
    parallelism: 1,
    version: 1,
  );

  /// Default parameters balancing security and UX
  static const Argon2Params standard = Argon2Params(
    memoryKiB: 65536, // 64 MiB
    iterations: 3,
    parallelism: 1,
    version: 1,
  );

  /// Serialize to JSON-compatible map for vault header storage.
  Map<String, dynamic> toJson() => {
    'memory_kib': memoryKiB,
    'iterations': iterations,
    'parallelism': parallelism,
    'version': version,
  };

  /// Deserialize from vault header.
  factory Argon2Params.fromJson(Map<String, dynamic> json) {
    return Argon2Params(
      memoryKiB: json['memory_kib'] as int,
      iterations: json['iterations'] as int,
      parallelism: json['parallelism'] as int,
      version: json['version'] as int,
    );
  }

  @override
  String toString() =>
      'Argon2Params(mem=${memoryKiB}KiB, t=$iterations, p=$parallelism, v=$version)';
}

/// Argon2id key derivation using libsodium.
///
/// This is the ONLY way to derive a Master Unlock Key (MUK) from a password.
/// The MUK is then used to decrypt the Vault Key (VK).
class Argon2idKdf {
  final SodiumSumo _sodium;

  Argon2idKdf(this._sodium);

  /// Generates a cryptographically secure random salt.
  ///
  /// Call this when creating a new vault. Store the salt in vault.header.
  Uint8List generateSalt() {
    return _sodium.randombytes.buf(KeySizes.salt);
  }

  /// Derives a Master Unlock Key from a password.
  ///
  /// **SECURITY CRITICAL**:
  /// - The password is zeroized after use
  /// - The returned MUK must be disposed after unlocking
  /// - The salt must be stored in vault header (plaintext is OK)
  ///
  /// [password] - User's master password (will be zeroized)
  /// [salt] - Random salt from vault header
  /// [params] - Argon2id parameters from vault header
  ///
  /// Returns [MasterUnlockKey] which must be disposed after use.
  Future<MasterUnlockKey> deriveKey({
    required SecureBytes password,
    required Uint8List salt,
    required Argon2Params params,
  }) async {
    if (salt.length != KeySizes.salt) {
      throw ArgumentError('Salt must be ${KeySizes.salt} bytes');
    }

    try {
      // Convert password to Int8List for sodium API
      final passwordBytes = password.unsafeBytes;
      final passwordInt8 = Int8List.fromList(
        passwordBytes.map((b) => b.toSigned(8)).toList(),
      );

      // Use libsodium's pwhash with Argon2id
      final derivedKey = _sodium.crypto.pwhash.call(
        outLen: KeySizes.symmetricKey,
        password: passwordInt8,
        salt: salt,
        opsLimit: params.iterations,
        memLimit: params.memoryKiB * 1024, // Convert KiB to bytes
        alg: CryptoPwhashAlgorithm.argon2id13,
      );

      // Convert SecureKey to Uint8List
      final keyBytes = Uint8List.fromList(derivedKey.extractBytes());

      return MasterUnlockKey(SecureBytes(keyBytes));
    } finally {
      // Always zeroize the password after use
      password.dispose();
    }
  }

  /// Benchmarks Argon2id to determine optimal parameters for this device.
  ///
  /// Call this on first vault creation to find parameters that take
  /// approximately [targetDurationMs] milliseconds.
  Future<Argon2Params> benchmark({
    int targetDurationMs = 1000,
    int minMemoryKiB = 32768, // 32 MiB minimum
    int maxMemoryKiB = 131072, // 128 MiB maximum
  }) async {
    final testPassword = SecureBytes.fromList(List.filled(32, 0x42));
    final testSalt = generateSalt();

    var bestParams = Argon2Params.standard;
    var closestDiff = double.infinity;

    // Test different memory sizes
    for (var memKiB = minMemoryKiB; memKiB <= maxMemoryKiB; memKiB *= 2) {
      for (var iterations = 1; iterations <= 5; iterations++) {
        final params = Argon2Params(
          memoryKiB: memKiB,
          iterations: iterations,
          parallelism: 1,
        );

        final stopwatch = Stopwatch()..start();

        try {
          final key = await deriveKey(
            password: testPassword.copy(),
            salt: testSalt,
            params: params,
          );
          key.dispose();
        } catch (e) {
          // Memory too high for this device
          continue;
        }

        stopwatch.stop();
        final diff = (stopwatch.elapsedMilliseconds - targetDurationMs).abs();

        if (diff < closestDiff) {
          closestDiff = diff.toDouble();
          bestParams = params;
        }

        // If we're close enough, stop
        if (stopwatch.elapsedMilliseconds >= targetDurationMs * 0.8 &&
            stopwatch.elapsedMilliseconds <= targetDurationMs * 1.2) {
          testPassword.dispose();
          return bestParams;
        }
      }
    }

    testPassword.dispose();
    return bestParams;
  }
}
