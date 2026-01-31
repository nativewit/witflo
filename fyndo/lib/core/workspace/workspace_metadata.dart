// ═══════════════════════════════════════════════════════════════════════════
// FYNDO - Zero-Trust Notes OS
// Workspace Metadata (.fyndo-workspace file)
// ═══════════════════════════════════════════════════════════════════════════
//
// PURPOSE:
// This file represents the plaintext metadata stored in .fyndo-workspace.
// It contains public information needed to:
// 1. Identify the workspace (workspaceId)
// 2. Derive the Master Unlock Key from password (crypto params)
// 3. Decrypt the encrypted keyring (.fyndo-keyring.enc)
//
// SECURITY:
// - Safe to expose (contains no secrets)
// - Salt is public (security relies on Argon2id strength)
// - Version must be 2 (workspace master password architecture)
//
// Spec: docs/specs/spec-002-workspace-master-password.md (Section 2.3)
// ═══════════════════════════════════════════════════════════════════════════

// ignore_for_file: library_private_types_in_public_api
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:fyndo_app/core/crypto/primitives/argon2id.dart';

part 'workspace_metadata.g.dart';

/// Workspace metadata stored in .fyndo-workspace file (plaintext JSON).
///
/// This file enables workspace identification and Master Unlock Key (MUK)
/// derivation without requiring the password upfront.
///
/// Security Notes:
/// - All fields are public (no secrets stored here)
/// - Salt is safe to expose (Argon2id security doesn't depend on salt secrecy)
/// - Nonce is safe to expose (XChaCha20 security requires unique nonce, not secret)
abstract class WorkspaceMetadata
    implements Built<WorkspaceMetadata, WorkspaceMetadataBuilder> {
  /// Workspace file format version (MUST be 2 for master password architecture).
  ///
  /// Version history:
  /// - v1: Per-vault passwords (deprecated)
  /// - v2: Workspace master password (current)
  static const int currentVersion = 2;

  /// Workspace file format version.
  ///
  /// This MUST be 2 for the workspace master password architecture.
  /// If a different version is found, the app should prompt for migration.
  int get version;

  /// Unique workspace identifier (UUID v4).
  ///
  /// Used for:
  /// - Workspace identification across devices
  /// - Sync conflict resolution
  /// - Analytics (anonymized)
  ///
  /// Example: "550e8400-e29b-41d4-a716-446655440000"
  String get workspaceId;

  /// Timestamp when this workspace was created (ISO 8601 UTC).
  ///
  /// Example: "2026-01-31T12:00:00.000Z"
  DateTime get createdAt;

  /// Cryptographic parameters for Master Unlock Key derivation.
  ///
  /// Contains:
  /// - masterKeySalt: Salt for Argon2id (16 bytes, base64-encoded)
  /// - argon2Params: Memory/iterations/parallelism for Argon2id
  /// - keyringNonce: Nonce for XChaCha20 keyring encryption (24 bytes, base64)
  WorkspaceCryptoParams get crypto;

  WorkspaceMetadata._();

  factory WorkspaceMetadata([void Function(WorkspaceMetadataBuilder) updates]) =
      _$WorkspaceMetadata;

  /// Creates a new workspace metadata instance.
  ///
  /// [workspaceId] - UUID v4 identifier for this workspace
  /// [crypto] - Cryptographic parameters (salt, Argon2 params, nonce)
  ///
  /// The version is automatically set to [currentVersion] (2).
  /// The createdAt timestamp is set to the current UTC time.
  static WorkspaceMetadata create({
    required String workspaceId,
    required WorkspaceCryptoParams crypto,
  }) {
    return WorkspaceMetadata(
      (b) => b
        ..version = currentVersion
        ..workspaceId = workspaceId
        ..createdAt = DateTime.now().toUtc()
        ..crypto = crypto.toBuilder(),
    );
  }

  /// Serializer for built_value JSON serialization.
  static Serializer<WorkspaceMetadata> get serializer =>
      _$workspaceMetadataSerializer;

  /// Converts to JSON map for .fyndo-workspace file.
  ///
  /// Format:
  /// ```json
  /// {
  ///   "version": 2,
  ///   "workspaceId": "550e8400-...",
  ///   "createdAt": "2026-01-31T12:00:00.000Z",
  ///   "crypto": {
  ///     "masterKeySalt": "hR3X8k2P...",
  ///     "argon2Params": {...},
  ///     "keyringNonce": "2JH4k8x..."
  ///   }
  /// }
  /// ```
  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'workspaceId': workspaceId,
      'createdAt': createdAt.toIso8601String(),
      'crypto': crypto.toJson(),
    };
  }

  /// Creates WorkspaceMetadata from JSON map.
  ///
  /// Throws:
  /// - [FormatException] if JSON is invalid
  /// - [ArgumentError] if version is not 2
  static WorkspaceMetadata fromJson(Map<String, dynamic> json) {
    final version = json['version'] as int;
    if (version != currentVersion) {
      throw ArgumentError(
        'Unsupported workspace version: $version (expected $currentVersion)',
      );
    }

    return WorkspaceMetadata(
      (b) => b
        ..version = version
        ..workspaceId = json['workspaceId'] as String
        ..createdAt = DateTime.parse(json['createdAt'] as String)
        ..crypto = WorkspaceCryptoParams.fromJson(
          json['crypto'] as Map<String, dynamic>,
        ).toBuilder(),
    );
  }
}

/// Cryptographic parameters for workspace master key derivation.
///
/// These parameters are stored in plaintext in .fyndo-workspace and are
/// required to derive the Master Unlock Key (MUK) from the user's password.
abstract class WorkspaceCryptoParams
    implements Built<WorkspaceCryptoParams, WorkspaceCryptoParamsBuilder> {
  /// Salt for Argon2id key derivation (base64-encoded, 16 bytes).
  ///
  /// This is generated randomly during workspace creation and stored
  /// in plaintext. The salt ensures that identical passwords on different
  /// workspaces produce different keys.
  ///
  /// Security: Safe to expose (Argon2id security doesn't rely on salt secrecy)
  ///
  /// Example: "hR3X8k2P1jK4mN7qS9tU2vW5xY8zA3bC"
  String get masterKeySalt;

  /// Argon2id parameters (memory, iterations, parallelism).
  ///
  /// These parameters are benchmarked during workspace creation to achieve
  /// approximately 1 second unlock time on the current device.
  ///
  /// Typical values:
  /// - memoryKiB: 65536 (64 MiB)
  /// - iterations: 3
  /// - parallelism: 1
  Argon2Params get argon2Params;

  /// Nonce for XChaCha20-Poly1305 keyring encryption (base64-encoded, 24 bytes).
  ///
  /// This nonce is used to encrypt the keyring file (.fyndo-keyring.enc)
  /// with the Master Unlock Key (MUK).
  ///
  /// Security: Safe to expose (XChaCha20 security requires unique nonce, not secret)
  ///
  /// Example: "2JH4k8x9mL7nP3qR5sT1uV4wX6yZ2aC"
  String get keyringNonce;

  WorkspaceCryptoParams._();

  factory WorkspaceCryptoParams([
    void Function(WorkspaceCryptoParamsBuilder) updates,
  ]) = _$WorkspaceCryptoParams;

  /// Serializer for built_value JSON serialization.
  static Serializer<WorkspaceCryptoParams> get serializer =>
      _$workspaceCryptoParamsSerializer;

  /// Converts to JSON map.
  Map<String, dynamic> toJson() {
    return {
      'masterKeySalt': masterKeySalt,
      'argon2Params': argon2Params.toJson(),
      'keyringNonce': keyringNonce,
    };
  }

  /// Creates WorkspaceCryptoParams from JSON map.
  static WorkspaceCryptoParams fromJson(Map<String, dynamic> json) {
    return WorkspaceCryptoParams(
      (b) => b
        ..masterKeySalt = json['masterKeySalt'] as String
        ..argon2Params = Argon2Params.fromJson(
          json['argon2Params'] as Map<String, dynamic>,
        )
        ..keyringNonce = json['keyringNonce'] as String,
    );
  }
}
