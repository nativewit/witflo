// ═══════════════════════════════════════════════════════════════════════════
// FYNDO - Zero-Trust Notes OS
// Vault Header - Minimal Plaintext Metadata
// ═══════════════════════════════════════════════════════════════════════════
//
// UPDATED FOR WORKSPACE MASTER PASSWORD (v2):
// With workspace-level master passwords, vault headers no longer store
// cryptographic parameters (salt/KDF params). These are now in the workspace
// keyring which is encrypted with the Master Unlock Key (MUK).
//
// SECURITY RATIONALE:
// The vault header is now minimal and contains ONLY:
// - Version information (for migrations)
// - Vault identifier (for keyring lookup)
// - Timestamps (created, modified)
// - Feature flags (optional)
//
// It does NOT contain:
// - Any user data
// - Any cryptographic parameters (moved to workspace keyring)
// - Any keys or encrypted keys
// - Any metadata about note contents
//
// Vault keys are now:
// 1. Generated randomly (not derived from password)
// 2. Stored in workspace keyring (encrypted with MUK)
// 3. Retrieved from UnlockedWorkspace after master password unlock
//
// Spec: docs/specs/spec-002-workspace-master-password.md (Section 3.3)
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'dart:typed_data';

/// Vault header version for migrations.
const int currentVaultVersion = 2;

/// Vault header containing minimal vault metadata.
///
/// This is stored in plaintext at vault.header
///
/// Version 2 Changes:
/// - Removed: salt (now in workspace metadata)
/// - Removed: kdfParams (now in workspace metadata)
/// - Vault keys are now retrieved from workspace keyring
class VaultHeader {
  /// Schema version for future migrations
  final int version;

  /// When the vault was created
  final DateTime createdAt;

  /// When the vault was last modified
  final DateTime? modifiedAt;

  /// Vault UUID (must match keyring entry and vault directory name)
  final String vaultId;

  /// Optional feature flags
  final Map<String, bool> features;

  VaultHeader({
    required this.version,
    required this.createdAt,
    required this.vaultId,
    this.modifiedAt,
    this.features = const {},
  });

  /// Creates a new vault header for vault creation.
  factory VaultHeader.create({required String vaultId}) {
    return VaultHeader(
      version: currentVaultVersion,
      createdAt: DateTime.now().toUtc(),
      vaultId: vaultId,
    );
  }

  /// Serialize to JSON for storage.
  Map<String, dynamic> toJson() => {
    'version': version,
    'created_at': createdAt.toIso8601String(),
    'modified_at': modifiedAt?.toIso8601String(),
    'vault_id': vaultId,
    'features': features,
  };

  /// Serialize to bytes for file storage.
  Uint8List toBytes() {
    final json = jsonEncode(toJson());
    return Uint8List.fromList(utf8.encode(json));
  }

  /// Deserialize from JSON.
  factory VaultHeader.fromJson(Map<String, dynamic> json) {
    return VaultHeader(
      version: json['version'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      modifiedAt: json['modified_at'] != null
          ? DateTime.parse(json['modified_at'] as String)
          : null,
      vaultId: json['vault_id'] as String,
      features:
          (json['features'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v as bool),
          ) ??
          {},
    );
  }

  /// Deserialize from bytes.
  factory VaultHeader.fromBytes(Uint8List bytes) {
    final json = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    return VaultHeader.fromJson(json);
  }

  /// Creates a copy with updated modification time.
  VaultHeader touch() {
    return VaultHeader(
      version: version,
      createdAt: createdAt,
      modifiedAt: DateTime.now().toUtc(),
      vaultId: vaultId,
      features: features,
    );
  }

  @override
  String toString() =>
      'VaultHeader(v$version, vault=$vaultId, created=$createdAt)';
}
