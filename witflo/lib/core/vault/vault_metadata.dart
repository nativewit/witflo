// ═══════════════════════════════════════════════════════════════════════════
// WITFLO - Zero-Trust Notes OS
// Vault Metadata (.vault-meta.json file)
// ═══════════════════════════════════════════════════════════════════════════
//
// PURPOSE:
// This file represents plaintext metadata for each vault, containing:
// 1. Vault identification (vaultId)
// 2. User-visible properties (name, icon, color)
// 3. Descriptive information (description)
// 4. Timestamps (createdAt, modifiedAt)
//
// SECURITY:
// - Safe to expose (contains no secrets)
// - Vault names/icons are organizational metadata
// - Zero-knowledge maintained (note content still encrypted)
// - Enables vault discovery without password (better UX)
//
// WHY PLAINTEXT?
// - User can see vault list before unlocking workspace
// - Vault discovery without decryption
// - Organizational metadata is not sensitive
//
// Spec: docs/specs/spec-002-workspace-master-password.md (Section 2.5)
// ═══════════════════════════════════════════════════════════════════════════

// ignore_for_file: library_private_types_in_public_api
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'vault_metadata.g.dart';

/// Vault metadata stored in .vault-meta.json file (plaintext JSON).
///
/// Contains user-visible vault properties that are safe to expose without
/// decryption. This enables vault discovery and identification before
/// workspace unlock.
///
/// Security Notes:
/// - All fields are public (no secrets stored here)
/// - Vault names/icons are organizational, not sensitive
/// - Content encryption is still maintained (notes are encrypted)
abstract class VaultMetadata
    implements Built<VaultMetadata, VaultMetadataBuilder> {
  /// Vault metadata file format version.
  ///
  /// Version history:
  /// - v1: Initial format (current)
  static const int currentVersion = 1;

  /// Metadata file format version.
  ///
  /// Used for future migrations if metadata schema changes.
  int get version;

  /// Unique vault identifier (UUID v4).
  ///
  /// Must match the vault directory name and the vaultId in VaultHeader.
  /// Used for:
  /// - Cross-referencing with workspace keyring
  /// - Vault discovery
  /// - Sync operations
  ///
  /// Example: "vault-uuid-1"
  String get vaultId;

  /// User-visible vault name.
  ///
  /// Examples: "Personal", "Work", "Family", "Projects"
  ///
  /// This is the primary identifier shown to users in the vault list.
  String get name;

  /// Optional vault description.
  ///
  /// Examples:
  /// - "Personal notes and documents"
  /// - "Work-related project documentation"
  /// - "Family recipes and memories"
  ///
  /// Shown in vault details/tooltips.
  String? get description;

  /// Optional emoji icon for visual identification.
  ///
  /// Examples: "📓", "💼", "👨‍👩‍👧‍👦", "🎨", "📁"
  ///
  /// Displayed alongside vault name in the UI.
  String? get icon;

  /// Optional color for visual identification (hex format).
  ///
  /// Examples:
  /// - "#3B82F6" (blue)
  /// - "#10B981" (green)
  /// - "#F59E0B" (amber)
  /// - "#8B5CF6" (purple)
  ///
  /// Used for vault card background or accent color.
  String? get color;

  /// Timestamp when vault was created (UTC).
  ///
  /// Should match VaultHeader.createdAt
  DateTime get createdAt;

  /// Timestamp when vault metadata was last modified (UTC).
  ///
  /// Updated when user changes vault name, icon, color, or description.
  DateTime get modifiedAt;

  VaultMetadata._();

  factory VaultMetadata([void Function(VaultMetadataBuilder) updates]) =
      _$VaultMetadata;

  /// Creates a new vault metadata instance.
  ///
  /// [vaultId] - UUID v4 identifier for this vault
  /// [name] - User-visible vault name
  /// [description] - Optional description
  /// [icon] - Optional emoji icon
  /// [color] - Optional hex color
  ///
  /// The version is automatically set to [currentVersion] (1).
  /// Both createdAt and modifiedAt are set to the current UTC time.
  static VaultMetadata create({
    required String vaultId,
    required String name,
    String? description,
    String? icon,
    String? color,
  }) {
    final now = DateTime.now().toUtc();
    return VaultMetadata(
      (b) => b
        ..version = currentVersion
        ..vaultId = vaultId
        ..name = name
        ..description = description
        ..icon = icon
        ..color = color
        ..createdAt = now
        ..modifiedAt = now,
    );
  }

  /// Serializer for built_value JSON serialization.
  static Serializer<VaultMetadata> get serializer => _$vaultMetadataSerializer;

  /// Converts to JSON map for .vault-meta.json file.
  ///
  /// Format:
  /// ```json
  /// {
  ///   "version": 1,
  ///   "vaultId": "vault-uuid-1",
  ///   "name": "Personal",
  ///   "description": "Personal notes and documents",
  ///   "icon": "📓",
  ///   "color": "#3B82F6",
  ///   "createdAt": "2026-01-31T12:00:00.000Z",
  ///   "modifiedAt": "2026-01-31T12:00:00.000Z"
  /// }
  /// ```
  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'vaultId': vaultId,
      'name': name,
      if (description != null) 'description': description,
      if (icon != null) 'icon': icon,
      if (color != null) 'color': color,
      'createdAt': createdAt.toIso8601String(),
      'modifiedAt': modifiedAt.toIso8601String(),
    };
  }

  /// Creates VaultMetadata from JSON map.
  ///
  /// Throws:
  /// - [FormatException] if JSON is invalid
  /// - [ArgumentError] if version is not supported
  static VaultMetadata fromJson(Map<String, dynamic> json) {
    final version = json['version'] as int;
    if (version > currentVersion) {
      throw ArgumentError(
        'Unsupported vault metadata version: $version (max supported: $currentVersion)',
      );
    }

    return VaultMetadata(
      (b) => b
        ..version = version
        ..vaultId = json['vaultId'] as String
        ..name = json['name'] as String
        ..description = json['description'] as String?
        ..icon = json['icon'] as String?
        ..color = json['color'] as String?
        ..createdAt = DateTime.parse(json['createdAt'] as String)
        ..modifiedAt = DateTime.parse(json['modifiedAt'] as String),
    );
  }

  /// Creates a copy with updated modification timestamp.
  ///
  /// Useful when updating vault name, icon, color, or description.
  VaultMetadata touch() {
    return rebuild((b) => b..modifiedAt = DateTime.now().toUtc());
  }
}
