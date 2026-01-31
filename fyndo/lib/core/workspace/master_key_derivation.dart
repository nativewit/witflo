// ═══════════════════════════════════════════════════════════════════════════
// FYNDO - Zero-Trust Notes OS
// Master Key Derivation Service - Workspace Master Password Cryptography
// ═══════════════════════════════════════════════════════════════════════════
//
// ARCHITECTURE:
// This service is the foundation of Fyndo's workspace master password model.
// It provides three core operations:
//
// 1. deriveMasterUnlockKey() - Derives the Master Unlock Key (MUK) from
//    the user's master password using Argon2id. The MUK is then used to
//    encrypt/decrypt the workspace keyring.
//
// 2. benchmarkArgon2Params() - Benchmarks Argon2id on the current device to
//    find optimal parameters that balance security (higher is better) with
//    UX (target ~1 second unlock time).
//
// 3. generateWorkspaceSalt() - Generates a cryptographically secure random
//    16-byte salt for workspace initialization.
//
// SECURITY MODEL:
// - Master Password: User input, never stored, zeroized immediately after MUK derivation
// - Master Unlock Key (MUK): Derived from password + salt, cached in memory during session
// - Workspace Keyring: Encrypted JSON containing all vault keys, protected by MUK
// - Vault Keys: Random 32-byte keys (NOT derived from password), enable vault isolation
//
// KEY HIERARCHY:
// ```
// Master Password (user input)
//   ↓ Argon2id(password, workspace-salt)
// Master Unlock Key (MUK) - 32 bytes
//   ↓ XChaCha20.decrypt(keyring.enc)
// Workspace Keyring - {vault-id → vault-key}
//   ↓ Random keys per vault
// Vault Keys (VK1, VK2, ...) - 32 bytes each
//   ↓ HKDF per content
// Content Keys - per note/notebook
// ```
//
// USAGE:
// ```dart
// final service = MasterKeyDerivation.instance;
//
// // On workspace creation:
// final salt = service.generateWorkspaceSalt();
// final params = await service.benchmarkArgon2Params();
// final muk = await service.deriveMasterUnlockKey(password, salt, params);
//
// // On workspace unlock:
// final muk = await service.deriveMasterUnlockKey(password, salt, params);
//
// // Always dispose MUK when locking workspace:
// muk.dispose();
// ```
//
// REFERENCES:
// - Spec: docs/specs/spec-002-workspace-master-password.md
// - Argon2id: lib/core/crypto/primitives/argon2id.dart
// - CryptoService: lib/core/crypto/crypto_service.dart
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:typed_data';

import 'package:fyndo_app/core/crypto/crypto.dart';

/// Service for deriving Master Unlock Keys from master passwords.
///
/// This is a stateless service that wraps the underlying Argon2id primitive
/// with workspace-specific semantics. All methods use the singleton
/// [CryptoService] instance.
///
/// **CRITICAL SECURITY NOTES**:
/// - The [deriveMasterUnlockKey] method WILL zeroize the password parameter
/// - The returned [MasterUnlockKey] MUST be disposed when no longer needed
/// - Never log or serialize MUK material
/// - MUK should only exist in memory during an active session
class MasterKeyDerivation {
  /// Singleton instance.
  static final MasterKeyDerivation instance = MasterKeyDerivation._();

  MasterKeyDerivation._();

  /// Gets the underlying crypto service.
  CryptoService get _crypto => CryptoService.instance;

  /// Derives the Master Unlock Key (MUK) from a master password.
  ///
  /// This is the core operation for unlocking a workspace. The MUK is derived
  /// using Argon2id with the provided salt and parameters.
  ///
  /// **SECURITY CRITICAL**:
  /// - The [password] parameter is ZEROIZED after derivation (by Argon2id primitive)
  /// - The returned [MasterUnlockKey] MUST be disposed after use
  /// - The MUK should never be persisted to disk
  /// - Cache MUK in memory only during active session
  ///
  /// **Parameters**:
  /// - [password]: User's master password (WILL BE ZEROIZED)
  /// - [salt]: 16-byte workspace salt from `.fyndo-workspace`
  /// - [params]: Argon2id parameters from `.fyndo-workspace`
  ///
  /// **Returns**: [MasterUnlockKey] that unlocks the workspace keyring
  ///
  /// **Throws**:
  /// - [ArgumentError] if salt is not exactly 16 bytes
  /// - [StateError] if CryptoService not initialized
  ///
  /// **Example**:
  /// ```dart
  /// final salt = base64Decode(metadata['crypto']['masterKeySalt']);
  /// final params = Argon2Params.fromJson(metadata['crypto']['argon2Params']);
  /// final password = SecureBytes.fromString(userInput);
  ///
  /// final muk = await MasterKeyDerivation.instance.deriveMasterUnlockKey(
  ///   password,
  ///   salt,
  ///   params,
  /// );
  ///
  /// // Use MUK to decrypt keyring...
  ///
  /// // Always dispose when done
  /// muk.dispose();
  /// ```
  Future<MasterUnlockKey> deriveMasterUnlockKey(
    SecureBytes password,
    Uint8List salt,
    Argon2Params params,
  ) async {
    return _crypto.argon2id.deriveKey(
      password: password,
      salt: salt,
      params: params,
    );
  }

  /// Benchmarks Argon2id to find optimal parameters for this device.
  ///
  /// This should be called once during workspace initialization to determine
  /// parameters that balance security (higher memory/iterations = better) with
  /// UX (target unlock time).
  ///
  /// The benchmark tests different combinations of memory and iterations to
  /// find parameters that achieve approximately [targetDurationMs] milliseconds.
  ///
  /// **When to call**:
  /// - First workspace initialization (no existing params)
  /// - After password change (device may have upgraded)
  /// - Optionally: User requests "optimize security" action
  ///
  /// **Parameters**:
  /// - [targetDurationMs]: Target unlock duration (default 1000ms = 1 second)
  /// - [minMemoryKiB]: Minimum memory cost (default 32 MiB = 32768 KiB)
  /// - [maxMemoryKiB]: Maximum memory cost (default 128 MiB = 131072 KiB)
  ///
  /// **Returns**: [Argon2Params] tuned for this device
  ///
  /// **OWASP Recommendations** (2024):
  /// - Memory: 64 MiB minimum for sensitive applications
  /// - Iterations: 3 minimum
  /// - Parallelism: 1 (mobile battery optimization)
  ///
  /// **Notes**:
  /// - Higher values = better security but slower unlock
  /// - Lower values = faster unlock but weaker security
  /// - Desktop typically achieves higher params than mobile
  /// - Results are deterministic for same device capabilities
  ///
  /// **Example**:
  /// ```dart
  /// // Default: target 1 second, 32-128 MiB range
  /// final params = await MasterKeyDerivation.instance.benchmarkArgon2Params();
  ///
  /// // Custom: target 2 seconds for higher security
  /// final secureParams = await MasterKeyDerivation.instance.benchmarkArgon2Params(
  ///   targetDurationMs: 2000,
  ///   minMemoryKiB: 65536, // 64 MiB minimum
  ///   maxMemoryKiB: 262144, // 256 MiB maximum
  /// );
  /// ```
  Future<Argon2Params> benchmarkArgon2Params({
    int targetDurationMs = 1000,
    int minMemoryKiB = 32768,
    int maxMemoryKiB = 131072,
  }) async {
    return _crypto.argon2id.benchmark(
      targetDurationMs: targetDurationMs,
      minMemoryKiB: minMemoryKiB,
      maxMemoryKiB: maxMemoryKiB,
    );
  }

  /// Generates a cryptographically secure random workspace salt.
  ///
  /// This should be called once during workspace initialization. The salt is
  /// stored in `.fyndo-workspace` (plaintext) and used for all future MUK
  /// derivations.
  ///
  /// **SECURITY NOTES**:
  /// - Salt is public information (stored plaintext)
  /// - Security relies on Argon2id strength, not salt secrecy
  /// - Same salt used for workspace lifetime (unless password changed)
  /// - Salt ensures same password → different MUK across workspaces
  ///
  /// **Returns**: 16-byte random salt
  ///
  /// **When to call**:
  /// - New workspace initialization
  /// - After master password change (generate new salt)
  ///
  /// **Storage**:
  /// ```json
  /// // .fyndo-workspace
  /// {
  ///   "crypto": {
  ///     "masterKeySalt": "<base64-encoded-16-bytes>"
  ///   }
  /// }
  /// ```
  ///
  /// **Example**:
  /// ```dart
  /// final salt = MasterKeyDerivation.instance.generateWorkspaceSalt();
  /// final saltBase64 = base64Encode(salt);
  ///
  /// // Store in workspace metadata
  /// metadata['crypto']['masterKeySalt'] = saltBase64;
  /// ```
  Uint8List generateWorkspaceSalt() {
    return _crypto.random.salt();
  }
}
