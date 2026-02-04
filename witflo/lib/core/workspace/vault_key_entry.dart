// ═══════════════════════════════════════════════════════════════════════════
// WITFLO - Zero-Trust Notes OS
// VaultKeyEntry - Entry in workspace keyring for a single vault
// ═══════════════════════════════════════════════════════════════════════════
//
// STRUCTURE:
// Each vault in a workspace has an entry in the keyring containing:
// - vaultKey: Random 32-byte key (base64-encoded) for encrypting vault content
// - createdAt: When this vault was added to the workspace
// - syncEnabled: Whether this vault participates in sync
//
// SECURITY:
// - The vault key is random (not derived from master password)
// - This allows vault sharing in future (wrap key for other users)
// - Keys stored encrypted in the encrypted keyring file (encrypted with MUK)
//
// Spec: docs/specs/spec-002-workspace-master-password.md (Section 2.4)
// ═══════════════════════════════════════════════════════════════════════════

// ignore_for_file: library_private_types_in_public_api
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'vault_key_entry.g.dart';

/// Entry for a single vault in the workspace keyring.
///
/// Contains the encrypted vault key and metadata about when it was created.
/// The entire keyring (map of vaultId → VaultKeyEntry) is encrypted with
/// the workspace Master Unlock Key (MUK).
abstract class VaultKeyEntry
    implements Built<VaultKeyEntry, VaultKeyEntryBuilder> {
  static Serializer<VaultKeyEntry> get serializer => _$vaultKeyEntrySerializer;

  /// Base64-encoded vault key (32 bytes).
  ///
  /// This is a random symmetric key used to encrypt all content in this vault.
  /// NOT derived from the master password - allows independent vault sharing.
  ///
  /// Security: Only accessible after workspace is unlocked with master password.
  String get vaultKey;

  /// When this vault was added to the workspace (ISO 8601 UTC).
  ///
  /// Used for:
  /// - Audit trail
  /// - Sorting vaults by creation time
  /// - Migration tracking
  DateTime get createdAt;

  /// Whether this vault participates in sync.
  ///
  /// If false, vault changes are not synced to other devices.
  /// Useful for device-local vaults (e.g., scratch notes).
  ///
  /// Default: true
  bool get syncEnabled;

  VaultKeyEntry._();

  factory VaultKeyEntry([void Function(VaultKeyEntryBuilder) updates]) =
      _$VaultKeyEntry;

  /// Creates a new vault entry with the given key.
  ///
  /// [vaultKeyBase64] - Base64-encoded 32-byte vault key
  /// [syncEnabled] - Whether to sync this vault (default: true)
  static VaultKeyEntry create({
    required String vaultKeyBase64,
    bool syncEnabled = true,
  }) {
    return VaultKeyEntry(
      (b) => b
        ..vaultKey = vaultKeyBase64
        ..createdAt = DateTime.now().toUtc()
        ..syncEnabled = syncEnabled,
    );
  }

  /// Serializes to JSON for storage in keyring.
  Map<String, dynamic> toJson() => {
    'vault_key': vaultKey,
    'created_at': createdAt.toIso8601String(),
    'sync_enabled': syncEnabled,
  };

  /// Deserializes from JSON.
  static VaultKeyEntry fromJson(Map<String, dynamic> json) {
    return VaultKeyEntry(
      (b) => b
        ..vaultKey = json['vault_key'] as String
        ..createdAt = DateTime.parse(json['created_at'] as String)
        ..syncEnabled = (json['sync_enabled'] as bool?) ?? true,
    );
  }
}
