// ═══════════════════════════════════════════════════════════════════════════
// FYNDO - Zero-Trust Notes OS
// Vault Service - Create, Unlock, and Manage Vaults
// ═══════════════════════════════════════════════════════════════════════════
//
// UPDATED FOR WORKSPACE MASTER PASSWORD (v2):
// Vaults no longer manage their own passwords. Instead:
// 1. Workspace master password → MUK (in workspace service)
// 2. MUK decrypts keyring → vault keys (random, not derived)
// 3. Vault service receives vault key directly from keyring
//
// NEW VAULT LIFECYCLE:
// 1. CREATE: workspace provides vault key → save metadata → save header
// 2. UNLOCK: workspace provides vault key → derive content keys → ready
// 3. LOCK: zeroize all keys → require workspace unlock
// 4. PASSWORD CHANGE: handled at workspace level (no vault changes)
//
// KEY HIERARCHY:
// Master Password (workspace-level)
//   ↓ Argon2id(workspace salt)
// Master Unlock Key (MUK) - workspace session
//   ↓ decrypts workspace keyring
// Vault Key (VK) - random 32 bytes per vault
//   ↓ HKDF
// ContentKey, NotebookKey, GroupKey, NoteShareKey
//
// SECURITY INVARIANTS:
// - Vault keys are random (not password-derived)
// - Vault keys provided by workspace keyring (after unlock)
// - VK remains in memory only while vault is unlocked
// - All derived keys are disposed after use
//
// Spec: docs/specs/spec-002-workspace-master-password.md (Section 3.3)
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:convert';

import 'package:fyndo_app/core/config/env.dart';
import 'package:fyndo_app/core/crypto/crypto.dart';
import 'package:fyndo_app/core/vault/vault_filesystem.dart';
import 'package:fyndo_app/core/vault/vault_header.dart';
import 'package:fyndo_app/core/vault/vault_metadata.dart';
import 'package:fyndo_app/core/vault/vault_service_interface.dart';
import 'package:fyndo_app/platform/storage/storage_provider.dart';
import 'package:path/path.dart' as p;

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

    // NOTE: We do NOT dispose _vaultKey here because it's owned by the workspace.
    // The workspace manages the lifecycle of all vault keys (cached in UnlockedWorkspace).
    // The _vaultKey here is just a wrapper around the workspace's cached SecureBytes.
    // Disposing it would break the workspace cache and cause "disposed key" errors
    // when switching between vaults.
    // The workspace will dispose all vault keys when it's locked via UnlockedWorkspace.dispose().
  }
}

/// Main vault management service.
///
/// Implements [IVaultService] for SOLID compliance (Dependency Inversion Principle).
/// Consumers should depend on the interface, not this concrete implementation.
class VaultService implements IVaultService {
  final CryptoService _crypto;

  VaultService(this._crypto);

  /// Creates a new vault with the provided vault key from workspace keyring.
  ///
  /// [vaultPath] - Directory to create vault in
  /// [vaultKey] - Random vault key from workspace keyring (NOT password-derived)
  /// [vaultId] - UUID identifier for this vault (must match keyring entry)
  /// [name] - User-visible vault name
  /// [description] - Optional vault description
  /// [icon] - Optional emoji icon
  /// [color] - Optional hex color
  ///
  /// Returns [VaultCreationResult] with the created vault info.
  ///
  /// NOTE: This method does NOT generate or encrypt the vault key.
  /// That is handled by the workspace service. This method only:
  /// 1. Creates the vault directory structure
  /// 2. Writes the vault header (plaintext)
  /// 3. Writes the vault metadata (plaintext)
  @override
  Future<VaultCreationResult> createVault({
    required String vaultPath,
    required VaultKey vaultKey,
    required String vaultId,
    required String name,
    String? description,
    String? icon,
    String? color,
  }) async {
    final filesystem = VaultFilesystem(vaultPath);

    // Check if vault already exists
    if (await filesystem.exists()) {
      throw VaultException(
        VaultError.vaultCorrupted,
        'Vault already exists at $vaultPath',
      );
    }

    // Create header (minimal, no crypto params)
    final header = VaultHeader.create(vaultId: vaultId);

    // Create metadata (plaintext user-visible info)
    final metadata = VaultMetadata.create(
      vaultId: vaultId,
      name: name,
      description: description,
      icon: icon,
      color: color,
    );

    // Initialize filesystem
    await filesystem.initialize();

    // Write header (plaintext)
    await filesystem.writeAtomic(filesystem.paths.header, header.toBytes());

    // Write metadata (plaintext)
    await saveVaultMetadata(vaultPath, metadata);

    return VaultCreationResult(header: header, vaultPath: vaultPath);
  }

  /// Unlocks an existing vault with the provided vault key from workspace keyring.
  ///
  /// [vaultPath] - Directory containing the vault
  /// [vaultKey] - Vault key from workspace keyring (after master password unlock)
  ///
  /// Returns [UnlockedVault] which must be disposed when locking.
  ///
  /// NOTE: This method does NOT derive the vault key from a password.
  /// The vault key is retrieved from the workspace keyring after the user
  /// unlocks the workspace with the master password.
  @override
  Future<UnlockedVault> unlockVault({
    required String vaultPath,
    required VaultKey vaultKey,
  }) async {
    final filesystem = VaultFilesystem(vaultPath);

    // Check if vault exists
    if (!await filesystem.exists()) {
      throw VaultException(
        VaultError.vaultNotFound,
        'No vault found at $vaultPath',
      );
    }

    // Read header
    final headerBytes = await storageProvider.readFile(filesystem.paths.header);
    if (headerBytes == null) {
      throw VaultException(
        VaultError.vaultCorrupted,
        'Could not read vault header',
      );
    }
    final header = VaultHeader.fromBytes(headerBytes);

    // Check version compatibility
    if (header.version > currentVaultVersion) {
      throw VaultException(
        VaultError.versionMismatch,
        'Vault version ${header.version} is newer than supported $currentVaultVersion',
      );
    }

    // Return unlocked vault with provided key
    return UnlockedVault(
      header: header,
      filesystem: filesystem,
      vaultKey: vaultKey,
      crypto: _crypto,
    );
  }

  /// Saves vault metadata to .vault-meta.json (plaintext).
  ///
  /// [vaultPath] - Directory containing the vault
  /// [metadata] - Vault metadata to save
  ///
  /// The metadata is written atomically to prevent corruption.
  @override
  Future<void> saveVaultMetadata(
    String vaultPath,
    VaultMetadata metadata,
  ) async {
    final metadataPath = p.join(
      vaultPath,
      AppEnvironment.instance.vaultMetadataFile,
    );
    final json = jsonEncode(metadata.toJson());
    final bytes = utf8.encode(json);
    await storageProvider.writeAtomic(metadataPath, bytes);
  }

  /// Loads vault metadata from .vault-meta.json.
  ///
  /// [vaultPath] - Directory containing the vault
  ///
  /// Returns [VaultMetadata] if the file exists and is valid.
  /// Throws [VaultException] if the file is missing or corrupted.
  @override
  Future<VaultMetadata?> loadVaultMetadata(String vaultPath) async {
    final metadataPath = p.join(
      vaultPath,
      AppEnvironment.instance.vaultMetadataFile,
    );
    final bytes = await storageProvider.readFile(metadataPath);
    if (bytes == null) {
      return null;
    }
    final json = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    return VaultMetadata.fromJson(json);
  }
}
