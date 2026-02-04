// ═══════════════════════════════════════════════════════════════════════════
// WITFLO - Zero-Trust Notes OS
// Vault Service Interface - SOLID Compliance (Dependency Inversion Principle)
// ═══════════════════════════════════════════════════════════════════════════
//
// This interface enables:
// 1. Dependency Inversion: High-level modules depend on abstractions, not concrete implementations
// 2. Testability: Easy mocking/stubbing for unit tests
// 3. Flexibility: Swap implementations without changing consumers
// 4. Documentation: Clear contract for what a vault service must provide
//
// Related spec: docs/specs/spec-003-flutter-dev-workflow-optimization.md (Section 2.1)
// Architecture: docs/specs/spec-002-workspace-master-password.md (Section 3.3)
// ═══════════════════════════════════════════════════════════════════════════

import 'package:witflo_app/core/crypto/crypto.dart';
import 'package:witflo_app/core/vault/vault_metadata.dart';
import 'package:witflo_app/core/vault/vault_service.dart';

/// Interface for vault management operations.
///
/// Defines the contract for creating, unlocking, and managing vaults
/// in the Witflo workspace-based architecture.
///
/// ## Key Hierarchy (spec-002)
/// ```
/// Master Password (workspace-level)
///   ↓ Argon2id(workspace salt)
/// Master Unlock Key (MUK) - workspace session
///   ↓ decrypts workspace keyring
/// Vault Key (VK) - random 32 bytes per vault
///   ↓ HKDF
/// ContentKey, NotebookKey, GroupKey, NoteShareKey
/// ```
///
/// ## Security Invariants
/// - Vault keys are random (not password-derived)
/// - Vault keys provided by workspace keyring (after unlock)
/// - VK remains in memory only while vault is unlocked
/// - All derived keys are disposed after use
abstract interface class IVaultService {
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
  /// ## Implementation Notes
  /// This method does NOT generate or encrypt the vault key.
  /// That is handled by the workspace service. This method only:
  /// 1. Creates the vault directory structure
  /// 2. Writes the vault header (plaintext)
  /// 3. Writes the vault metadata (plaintext)
  ///
  /// ## Throws
  /// - [VaultException] with [VaultError.vaultCorrupted] if vault already exists
  ///
  /// ## Example
  /// ```dart
  /// // After workspace unlock and key generation
  /// final vaultKey = workspaceKeyring.getVaultKey(vaultId);
  /// final result = await vaultService.createVault(
  ///   vaultPath: '/path/to/vault',
  ///   vaultKey: vaultKey,
  ///   vaultId: 'vault-uuid',
  ///   name: 'My Vault',
  /// );
  /// ```
  Future<VaultCreationResult> createVault({
    required String vaultPath,
    required VaultKey vaultKey,
    required String vaultId,
    required String name,
    String? description,
    String? icon,
    String? color,
  });

  /// Unlocks an existing vault with the provided vault key from workspace keyring.
  ///
  /// [vaultPath] - Directory containing the vault
  /// [vaultKey] - Vault key from workspace keyring (after master password unlock)
  ///
  /// Returns [UnlockedVault] which must be disposed when locking.
  ///
  /// ## Implementation Notes
  /// This method does NOT derive the vault key from a password.
  /// The vault key is retrieved from the workspace keyring after the user
  /// unlocks the workspace with the master password.
  ///
  /// ## Throws
  /// - [VaultException] with [VaultError.vaultNotFound] if vault doesn't exist
  /// - [VaultException] with [VaultError.vaultCorrupted] if header is missing
  /// - [VaultException] with [VaultError.versionMismatch] if vault version is too new
  ///
  /// ## Example
  /// ```dart
  /// // After workspace unlock
  /// final vaultKey = workspaceKeyring.getVaultKey(vaultId);
  /// final unlockedVault = await vaultService.unlockVault(
  ///   vaultPath: '/path/to/vault',
  ///   vaultKey: vaultKey,
  /// );
  ///
  /// // Use vault...
  /// final contentKey = unlockedVault.deriveContentKey(noteId);
  ///
  /// // Must dispose when done
  /// unlockedVault.dispose();
  /// ```
  Future<UnlockedVault> unlockVault({
    required String vaultPath,
    required VaultKey vaultKey,
  });

  /// Saves vault metadata to .vault-meta.json (plaintext).
  ///
  /// [vaultPath] - Directory containing the vault
  /// [metadata] - Vault metadata to save
  ///
  /// The metadata is written atomically to prevent corruption.
  ///
  /// ## Metadata Contents
  /// - Vault ID (UUID)
  /// - User-visible name
  /// - Optional description
  /// - Optional emoji icon
  /// - Optional color (hex)
  /// - Creation/modification timestamps
  ///
  /// ## Example
  /// ```dart
  /// final metadata = VaultMetadata.create(
  ///   vaultId: 'vault-uuid',
  ///   name: 'Updated Name',
  ///   icon: '📝',
  ///   color: '#4A90E2',
  /// );
  /// await vaultService.saveVaultMetadata('/path/to/vault', metadata);
  /// ```
  Future<void> saveVaultMetadata(String vaultPath, VaultMetadata metadata);

  /// Loads vault metadata from .vault-meta.json.
  ///
  /// [vaultPath] - Directory containing the vault
  ///
  /// Returns the metadata if the file exists, null otherwise.
  ///
  /// ## Use Cases
  /// - Display vault info in UI before unlocking
  /// - List all vaults in workspace
  /// - Verify vault integrity
  ///
  /// ## Example
  /// ```dart
  /// final metadata = await vaultService.loadVaultMetadata('/path/to/vault');
  /// if (metadata != null) {
  ///   print('Vault: ${metadata.name} (${metadata.vaultId})');
  /// }
  /// ```
  Future<VaultMetadata?> loadVaultMetadata(String vaultPath);
}
