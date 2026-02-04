// ═══════════════════════════════════════════════════════════════════════════
// WITFLO - Zero-Trust Notes OS
// WorkspaceKeyring - Registry of vault keys encrypted with Master Unlock Key
// ═══════════════════════════════════════════════════════════════════════════
//
// STRUCTURE:
// The keyring is a map of vaultId → VaultKeyEntry, stored encrypted on disk.
// File: .fyndo-keyring.enc (encrypted with MUK via XChaCha20-Poly1305)
//
// SECURITY:
// - Only accessible after workspace unlock with master password
// - Each vault has a random 32-byte key (not derived from master password)
// - Vault isolation: compromising one key doesn't expose others
// - Fast password changes: only keyring re-encrypted, not vault content
//
// USAGE:
//   final keyring = WorkspaceKeyring.empty();
//   keyring = keyring.addVault('vault-uuid', 'base64-key');
//   final vaultKey = keyring.getVaultKey('vault-uuid');
//
// Spec: docs/specs/spec-002-workspace-master-password.md (Section 2.4)
// ═══════════════════════════════════════════════════════════════════════════

// ignore_for_file: library_private_types_in_public_api
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:built_collection/built_collection.dart';
import 'package:witflo_app/core/workspace/vault_key_entry.dart';

part 'workspace_keyring.g.dart';

/// Encrypted registry of vault keys for a workspace.
///
/// This is the core data structure enabling workspace-level master password.
/// After unlocking the workspace with the master password, the keyring is
/// decrypted to provide access to all vault keys.
///
/// The keyring is stored encrypted at `.fyndo-keyring.enc` and synced across
/// devices via the existing CRDT-based sync engine.
abstract class WorkspaceKeyring
    implements Built<WorkspaceKeyring, WorkspaceKeyringBuilder> {
  static Serializer<WorkspaceKeyring> get serializer =>
      _$workspaceKeyringSerializer;

  /// Keyring schema version.
  ///
  /// Current version: 1
  /// Increment when making breaking changes to the keyring structure.
  @BuiltValueField(wireName: 'version')
  int get version;

  /// Map of vault IDs to their respective vault key entries.
  ///
  /// Key: vault UUID (e.g., "550e8400-e29b-41d4-a716-446655440000")
  /// Value: VaultKeyEntry containing the base64-encoded vault key
  ///
  /// This map is encrypted with the Master Unlock Key (MUK) derived from
  /// the user's master password.
  @BuiltValueField(wireName: 'vaults')
  BuiltMap<String, VaultKeyEntry> get vaults;

  /// Timestamp when the keyring was last modified (ISO 8601 UTC).
  ///
  /// Updated whenever a vault is added, removed, or its entry is modified.
  /// Used for CRDT conflict resolution and sync tracking.
  @BuiltValueField(wireName: 'modified_at')
  DateTime get modifiedAt;

  WorkspaceKeyring._();

  factory WorkspaceKeyring([void Function(WorkspaceKeyringBuilder) updates]) =
      _$WorkspaceKeyring;

  /// Creates an empty keyring for a new workspace.
  ///
  /// Used during workspace initialization:
  /// ```dart
  /// final keyring = WorkspaceKeyring.empty();
  /// // Later, add vaults as user creates them
  /// keyring = keyring.addVault(vaultId, vaultKey);
  /// ```
  static WorkspaceKeyring empty() {
    return WorkspaceKeyring(
      (b) => b
        ..version = 1
        ..vaults = MapBuilder<String, VaultKeyEntry>()
        ..modifiedAt = DateTime.now().toUtc(),
    );
  }

  /// Adds a new vault to the keyring.
  ///
  /// If a vault with the same ID already exists, it will be replaced.
  ///
  /// [vaultId] - UUID of the vault
  /// [vaultKeyBase64] - Base64-encoded 32-byte vault key
  /// [syncEnabled] - Whether to sync this vault (default: true)
  ///
  /// Returns a new WorkspaceKeyring with the vault added.
  ///
  /// Example:
  /// ```dart
  /// final updatedKeyring = keyring.addVault(
  ///   'vault-uuid-1',
  ///   'k8x2P4R...',  // base64 vault key
  /// );
  /// ```
  WorkspaceKeyring addVault(
    String vaultId,
    String vaultKeyBase64, {
    bool syncEnabled = true,
  }) {
    final entry = VaultKeyEntry.create(
      vaultKeyBase64: vaultKeyBase64,
      syncEnabled: syncEnabled,
    );

    return rebuild(
      (b) => b
        ..vaults[vaultId] = entry
        ..modifiedAt = DateTime.now().toUtc(),
    );
  }

  /// Removes a vault from the keyring.
  ///
  /// [vaultId] - UUID of the vault to remove
  ///
  /// Returns a new WorkspaceKeyring with the vault removed.
  /// If the vault doesn't exist, returns the keyring unchanged.
  ///
  /// Example:
  /// ```dart
  /// final updatedKeyring = keyring.removeVault('vault-uuid-1');
  /// ```
  WorkspaceKeyring removeVault(String vaultId) {
    if (!vaults.containsKey(vaultId)) {
      return this;
    }

    return rebuild(
      (b) => b
        ..vaults.remove(vaultId)
        ..modifiedAt = DateTime.now().toUtc(),
    );
  }

  /// Retrieves the vault key for a given vault ID.
  ///
  /// [vaultId] - UUID of the vault
  ///
  /// Returns the base64-encoded vault key, or null if the vault doesn't exist.
  ///
  /// Example:
  /// ```dart
  /// final vaultKey = keyring.getVaultKey('vault-uuid-1');
  /// if (vaultKey != null) {
  ///   // Decrypt vault content with this key
  /// }
  /// ```
  String? getVaultKey(String vaultId) {
    return vaults[vaultId]?.vaultKey;
  }

  /// Serializes the keyring to JSON for encryption and storage.
  ///
  /// The JSON structure matches the spec (Section 2.4):
  /// ```json
  /// {
  ///   "version": 1,
  ///   "vaults": {
  ///     "vault-uuid-1": {
  ///       "vault_key": "k8x2P4R...",
  ///       "created_at": "2026-01-31T12:00:00.000Z",
  ///       "sync_enabled": true
  ///     }
  ///   },
  ///   "modified_at": "2026-01-31T12:05:00.000Z"
  /// }
  /// ```
  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'vaults': Map.fromEntries(
        vaults.entries.map((e) => MapEntry(e.key, e.value.toJson())),
      ),
      'modified_at': modifiedAt.toIso8601String(),
    };
  }

  /// Deserializes a keyring from JSON after decryption.
  ///
  /// [json] - Decrypted JSON map from .fyndo-keyring.enc
  ///
  /// Example:
  /// ```dart
  /// final decryptedBytes = crypto.decrypt(encryptedKeyring, muk);
  /// final json = jsonDecode(utf8.decode(decryptedBytes));
  /// final keyring = WorkspaceKeyring.fromJson(json);
  /// ```
  static WorkspaceKeyring fromJson(Map<String, dynamic> json) {
    final vaultsJson = json['vaults'] as Map<String, dynamic>? ?? {};
    final vaultsMap = vaultsJson.map(
      (key, value) =>
          MapEntry(key, VaultKeyEntry.fromJson(value as Map<String, dynamic>)),
    );

    return WorkspaceKeyring(
      (b) => b
        ..version = (json['version'] as int?) ?? 1
        ..vaults = MapBuilder<String, VaultKeyEntry>(vaultsMap)
        ..modifiedAt = DateTime.parse(json['modified_at'] as String),
    );
  }
}
