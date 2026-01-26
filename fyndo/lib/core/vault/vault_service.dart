// ═══════════════════════════════════════════════════════════════════════════
// FYNDO - Zero-Trust Notes OS
// Vault Service - Create, Unlock, and Manage Vaults
// ═══════════════════════════════════════════════════════════════════════════
//
// VAULT LIFECYCLE:
// 1. CREATE: password → MUK → generate VK → encrypt VK → save
// 2. UNLOCK: password → MUK → decrypt VK → derive keys → ready
// 3. LOCK: zeroize all keys → require password again
// 4. CHANGE PASSWORD: derive new MUK → re-encrypt VK
//
// KEY HIERARCHY:
// Password (user input, never stored)
//   ↓ Argon2id(salt)
// Master Unlock Key (MUK) - memory only
//   ↓ decrypts vault.vk
// Vault Key (VK) - root of all content keys
//   ↓ HKDF
// ContentKey, NotebookKey, GroupKey, NoteShareKey
//
// SECURITY INVARIANTS:
// - Password is zeroized immediately after MUK derivation
// - MUK is zeroized immediately after VK decryption
// - VK remains in memory only while vault is unlocked
// - All derived keys are disposed after use
// ═══════════════════════════════════════════════════════════════════════════

import 'package:fyndo_app/core/crypto/crypto.dart';
import 'package:fyndo_app/core/vault/vault_filesystem.dart';
import 'package:fyndo_app/core/vault/vault_header.dart';
import 'package:fyndo_app/platform/storage/storage_provider.dart';
import 'package:uuid/uuid.dart';

/// Result of vault creation.
class VaultCreationResult {
  final VaultHeader header;
  final String vaultPath;

  VaultCreationResult({required this.header, required this.vaultPath});
}

/// Error types for vault operations.
enum VaultError {
  invalidPassword,
  vaultNotFound,
  vaultCorrupted,
  alreadyUnlocked,
  notUnlocked,
  versionMismatch,
}

class VaultException implements Exception {
  final VaultError error;
  final String message;

  VaultException(this.error, this.message);

  @override
  String toString() => 'VaultException($error): $message';
}

/// State of an unlocked vault.
///
/// Contains the decrypted Vault Key and derived key cache.
/// Dispose when locking the vault.
class UnlockedVault {
  final VaultHeader header;
  final VaultFilesystem filesystem;
  final VaultKey _vaultKey;
  final CryptoService _crypto;

  // Cache of derived keys (disposed on lock)
  final Map<String, CryptoKey> _keyCache = {};

  UnlockedVault({
    required this.header,
    required this.filesystem,
    required VaultKey vaultKey,
    required CryptoService crypto,
  }) : _vaultKey = vaultKey,
       _crypto = crypto;

  /// Gets the Vault Key (internal use only).
  VaultKey get vaultKey => _vaultKey;

  /// Derives a ContentKey for a note.
  ///
  /// IMPORTANT: The returned key is cached and owned by the vault.
  /// DO NOT dispose it - it will be disposed when the vault is locked.
  ContentKey deriveContentKey(String noteId) {
    final cacheKey = 'content:$noteId';
    if (_keyCache.containsKey(cacheKey)) {
      return _keyCache[cacheKey] as ContentKey;
    }

    final key = _crypto.hkdf.deriveContentKey(
      vaultKey: _vaultKey,
      noteId: noteId,
    );
    _keyCache[cacheKey] = key;
    return key;
  }

  /// Derives a NotebookKey for a notebook.
  ///
  /// IMPORTANT: The returned key is cached and owned by the vault.
  /// DO NOT dispose it - it will be disposed when the vault is locked.
  NotebookKey deriveNotebookKey(String notebookId) {
    final cacheKey = 'notebook:$notebookId';
    if (_keyCache.containsKey(cacheKey)) {
      return _keyCache[cacheKey] as NotebookKey;
    }

    final key = _crypto.hkdf.deriveNotebookKey(
      vaultKey: _vaultKey,
      notebookId: notebookId,
    );
    _keyCache[cacheKey] = key;
    return key;
  }

  /// Derives the search index key.
  ContentKey deriveSearchIndexKey() {
    const cacheKey = 'search:index';
    if (_keyCache.containsKey(cacheKey)) {
      return _keyCache[cacheKey] as ContentKey;
    }

    final key = _crypto.hkdf.deriveSearchIndexKey(vaultKey: _vaultKey);
    _keyCache[cacheKey] = key;
    return key;
  }

  /// Disposes all keys and locks the vault.
  void dispose() {
    // Dispose all cached keys
    for (final key in _keyCache.values) {
      key.dispose();
    }
    _keyCache.clear();

    // Dispose vault key
    _vaultKey.dispose();
  }
}

/// Main vault management service.
class VaultService {
  final CryptoService _crypto;

  VaultService(this._crypto);

  /// Creates a new vault with the given password.
  ///
  /// [vaultPath] - Directory to create vault in
  /// [password] - Master password (will be zeroized)
  /// [kdfParams] - Optional Argon2id parameters (uses standard if not provided)
  ///
  /// Returns [VaultCreationResult] with the created vault info.
  Future<VaultCreationResult> createVault({
    required String vaultPath,
    required SecureBytes password,
    Argon2Params? kdfParams,
  }) async {
    final filesystem = VaultFilesystem(vaultPath);

    // Check if vault already exists
    if (await filesystem.exists()) {
      password.dispose();
      throw VaultException(
        VaultError.vaultCorrupted,
        'Vault already exists at $vaultPath',
      );
    }

    // Use standard params if not provided
    final params = kdfParams ?? Argon2Params.standard;

    // Generate random salt
    final salt = _crypto.argon2id.generateSalt();

    // Generate vault ID
    final vaultId = const Uuid().v4();

    // Create header
    final header = VaultHeader.create(
      salt: salt,
      kdfParams: params,
      vaultId: vaultId,
    );

    // Derive MUK from password
    final muk = await _crypto.argon2id.deriveKey(
      password: password, // password is disposed by deriveKey
      salt: salt,
      params: params,
    );

    try {
      // Generate random Vault Key
      final vkBytes = _crypto.random.symmetricKey();
      final vaultKey = VaultKey(vkBytes);

      try {
        // Encrypt VK with MUK
        final encryptedVk = _crypto.xchacha20.encrypt(
          plaintext: vaultKey.material.copy(),
          key: muk,
        );

        // Initialize filesystem
        await filesystem.initialize();

        // Write header (plaintext)
        await filesystem.writeAtomic(filesystem.paths.header, header.toBytes());

        // Write encrypted VK
        await filesystem.writeAtomic(
          filesystem.paths.vaultKey,
          encryptedVk.ciphertext,
        );

        return VaultCreationResult(header: header, vaultPath: vaultPath);
      } finally {
        vaultKey.dispose();
      }
    } finally {
      muk.dispose();
    }
  }

  /// Unlocks an existing vault with the given password.
  ///
  /// [vaultPath] - Directory containing the vault
  /// [password] - Master password (will be zeroized)
  ///
  /// Returns [UnlockedVault] which must be disposed when locking.
  Future<UnlockedVault> unlockVault({
    required String vaultPath,
    required SecureBytes password,
  }) async {
    final filesystem = VaultFilesystem(vaultPath);

    // Check if vault exists
    if (!await filesystem.exists()) {
      password.dispose();
      throw VaultException(
        VaultError.vaultNotFound,
        'No vault found at $vaultPath',
      );
    }

    // Read header
    final headerBytes = await storageProvider.readFile(filesystem.paths.header);
    if (headerBytes == null) {
      password.dispose();
      throw VaultException(
        VaultError.vaultCorrupted,
        'Could not read vault header',
      );
    }
    final header = VaultHeader.fromBytes(headerBytes);

    // Check version compatibility
    if (header.version > currentVaultVersion) {
      password.dispose();
      throw VaultException(
        VaultError.versionMismatch,
        'Vault version ${header.version} is newer than supported $currentVaultVersion',
      );
    }

    // Derive MUK from password
    final muk = await _crypto.argon2id.deriveKey(
      password: password, // password is disposed by deriveKey
      salt: header.salt,
      params: header.kdfParams,
    );

    try {
      // Read encrypted VK
      final encryptedVkBytes = await storageProvider.readFile(
        filesystem.paths.vaultKey,
      );
      if (encryptedVkBytes == null) {
        throw VaultException(
          VaultError.vaultCorrupted,
          'Could not read vault key',
        );
      }

      // Decrypt VK
      SecureBytes vkBytes;
      try {
        vkBytes = _crypto.xchacha20.decrypt(
          ciphertext: encryptedVkBytes,
          key: muk,
        );
      } catch (e) {
        throw VaultException(
          VaultError.invalidPassword,
          'Failed to decrypt vault key - incorrect password?',
        );
      }

      final vaultKey = VaultKey(vkBytes);

      return UnlockedVault(
        header: header,
        filesystem: filesystem,
        vaultKey: vaultKey,
        crypto: _crypto,
      );
    } finally {
      muk.dispose();
    }
  }

  /// Changes the vault password.
  ///
  /// [vault] - Currently unlocked vault
  /// [newPassword] - New master password (will be zeroized)
  /// [newKdfParams] - Optional new KDF parameters
  Future<void> changePassword({
    required UnlockedVault vault,
    required SecureBytes newPassword,
    Argon2Params? newKdfParams,
  }) async {
    final params = newKdfParams ?? vault.header.kdfParams;

    // Generate new salt for new password
    final newSalt = _crypto.argon2id.generateSalt();

    // Derive new MUK
    final newMuk = await _crypto.argon2id.deriveKey(
      password: newPassword,
      salt: newSalt,
      params: params,
    );

    try {
      // Re-encrypt VK with new MUK
      final encryptedVk = _crypto.xchacha20.encrypt(
        plaintext: vault.vaultKey.material.copy(),
        key: newMuk,
      );

      // Create new header with updated params
      final newHeader = VaultHeader(
        version: vault.header.version,
        salt: newSalt,
        kdfParams: params,
        createdAt: vault.header.createdAt,
        modifiedAt: DateTime.now().toUtc(),
        vaultId: vault.header.vaultId,
        features: vault.header.features,
      );

      // Write new header
      await vault.filesystem.writeAtomic(
        vault.filesystem.paths.header,
        newHeader.toBytes(),
      );

      // Write new encrypted VK
      await vault.filesystem.writeAtomic(
        vault.filesystem.paths.vaultKey,
        encryptedVk.ciphertext,
      );
    } finally {
      newMuk.dispose();
    }
  }

  /// Verifies a password without fully unlocking the vault.
  Future<bool> verifyPassword({
    required String vaultPath,
    required SecureBytes password,
  }) async {
    try {
      final vault = await unlockVault(vaultPath: vaultPath, password: password);
      vault.dispose();
      return true;
    } on VaultException catch (e) {
      if (e.error == VaultError.invalidPassword) {
        return false;
      }
      rethrow;
    }
  }
}
