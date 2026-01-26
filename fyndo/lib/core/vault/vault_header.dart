// ═══════════════════════════════════════════════════════════════════════════
// FYNDO - Zero-Trust Notes OS
// Vault Header - Plaintext Metadata for Vault Recovery
// ═══════════════════════════════════════════════════════════════════════════
//
// SECURITY RATIONALE:
// The vault header is the ONLY plaintext file in a vault.
// It contains ONLY:
// - Version information (for migrations)
// - KDF parameters (to derive MUK from password)
// - Salt (random, not secret)
// - Feature flags (optional)
//
// It does NOT contain:
// - Any user data
// - Any keys or encrypted keys
// - Any metadata about note contents
//
// This allows vault recovery with just:
// 1. vault.header (this file)
// 2. vault.vk (encrypted vault key)
// 3. User's master password
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'dart:typed_data';

import 'package:fyndo_app/core/crypto/primitives/primitives.dart';

/// Vault header version for migrations.
const int currentVaultVersion = 1;

/// Vault header containing recovery information.
///
/// This is stored in plaintext at vault.header
class VaultHeader {
  /// Schema version for future migrations
  final int version;

  /// Salt for Argon2id key derivation
  final Uint8List salt;

  /// Argon2id parameters
  final Argon2Params kdfParams;

  /// When the vault was created
  final DateTime createdAt;

  /// When the vault was last modified
  final DateTime? modifiedAt;

  /// Vault UUID
  final String vaultId;

  /// Optional feature flags
  final Map<String, bool> features;

  VaultHeader({
    required this.version,
    required this.salt,
    required this.kdfParams,
    required this.createdAt,
    required this.vaultId,
    this.modifiedAt,
    this.features = const {},
  });

  /// Creates a new vault header for vault creation.
  factory VaultHeader.create({
    required Uint8List salt,
    required Argon2Params kdfParams,
    required String vaultId,
  }) {
    return VaultHeader(
      version: currentVaultVersion,
      salt: salt,
      kdfParams: kdfParams,
      createdAt: DateTime.now().toUtc(),
      vaultId: vaultId,
    );
  }

  /// Serialize to JSON for storage.
  Map<String, dynamic> toJson() => {
        'version': version,
        'salt': base64Encode(salt),
        'kdf': kdfParams.toJson(),
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
      salt: base64Decode(json['salt'] as String),
      kdfParams: Argon2Params.fromJson(json['kdf'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['created_at'] as String),
      modifiedAt: json['modified_at'] != null
          ? DateTime.parse(json['modified_at'] as String)
          : null,
      vaultId: json['vault_id'] as String,
      features: (json['features'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v as bool)) ??
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
      salt: salt,
      kdfParams: kdfParams,
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

