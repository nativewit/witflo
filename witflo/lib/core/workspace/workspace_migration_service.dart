// ═══════════════════════════════════════════════════════════════════════════
// WITFLO - Zero-Trust Notes OS
// WorkspaceMigrationService - v1 → v2 workspace migration
// ═══════════════════════════════════════════════════════════════════════════
//
// MIGRATION STRATEGY:
// 1. Discover all v1 vaults in workspace
// 2. Create v2 workspace structure with master password
// 3. For each vault:
//    - Unlock with old per-vault password
//    - Extract vault key
//    - Add to v2 keyring
// 4. Save v2 keyring encrypted with MUK
// 5. Update workspace marker to version 2
//
// SAFETY:
// - Validates all vaults unlock before committing
// - Atomic operation (all or nothing)
// - Original vault files remain unchanged
// - User should backup before migration
//
// Spec: docs/specs/spec-002-workspace-master-password.md (Section 4)
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:witflo_app/core/crypto/crypto.dart';
import 'package:witflo_app/core/vault/vault_service.dart';
import 'package:witflo_app/core/workspace/workspace_service.dart';
import 'package:witflo_app/core/workspace/workspace_metadata.dart';
import 'package:witflo_app/core/workspace/workspace_migration_service_interface.dart';

/// Service for migrating v1 workspaces (per-vault passwords) to v2 (master password).
///
/// This service handles the one-time migration from the old architecture where
/// each vault had its own password-derived key to the new architecture where
/// a single master password unlocks all vaults via an encrypted keyring.
///
/// Usage:
/// ```dart
/// final migrationService = WorkspaceMigrationService();
///
/// // 1. Detect v1 workspace
/// final isV1 = await migrationService.isV1Workspace(rootPath);
///
/// // 2. Discover v1 vaults
/// final vaultPaths = await migrationService.discoverV1Vaults(rootPath);
///
/// // 3. Collect passwords for each vault
/// final vaultPasswords = {
///   'vault-uuid-1': SecureBytes.fromString('vault1-password'),
///   'vault-uuid-2': SecureBytes.fromString('vault2-password'),
/// };
///
/// // 4. Migrate
/// await migrationService.migrateWorkspaceV1ToV2(
///   rootPath: rootPath,
///   newMasterPassword: SecureBytes.fromString('new-master-password'),
///   vaultPasswords: vaultPasswords,
/// );
/// ```
class WorkspaceMigrationService implements IWorkspaceMigrationService {
  static const String _workspaceMarkerFile = '.fyndo-workspace';
  static const String _vaultsSubdir = 'vaults';

  final WorkspaceService _workspaceService;
  // ignore: unused_field - Reserved for future v1 migration implementation
  final VaultService _vaultService;

  WorkspaceMigrationService({
    WorkspaceService? workspaceService,
    VaultService? vaultService,
    CryptoService? crypto,
  }) : _workspaceService = workspaceService ?? WorkspaceService(),
       _vaultService =
           vaultService ?? VaultService(crypto ?? CryptoService.instance);

  /// Migrates a v1 workspace to v2 with master password.
  ///
  /// This is a destructive operation that replaces the workspace authentication
  /// model. The user should backup their workspace before proceeding.
  ///
  /// [rootPath] - Absolute path to workspace directory
  /// [newMasterPassword] - New master password for v2 workspace
  /// [vaultPasswords] - Map of vaultId → old vault password
  ///
  /// Steps:
  /// 1. Validate all vault passwords (unlock each vault)
  /// 2. Extract vault keys from unlocked vaults
  /// 3. Create v2 workspace structure with new master password
  /// 4. Add all vault keys to v2 keyring
  /// 5. Update workspace version marker to 2
  ///
  /// Throws:
  /// - [MigrationException] if migration fails at any step
  /// - [MigrationException] if any vault password is incorrect
  /// - [MigrationException] if workspace is already v2
  ///
  /// Spec: docs/specs/spec-002-workspace-master-password.md (Section 4)
  @override
  Future<void> migrateWorkspaceV1ToV2({
    required String rootPath,
    required SecureBytes newMasterPassword,
    required Map<String, SecureBytes> vaultPasswords,
  }) async {
    // 1. Verify this is a v1 workspace
    final version = await _workspaceService.getWorkspaceVersion(rootPath);
    if (version >= 2) {
      throw MigrationException(
        'Workspace is already v2 or newer (version: $version)',
      );
    }

    // 2. Discover all v1 vaults
    final vaultPaths = await discoverV1Vaults(rootPath);
    if (vaultPaths.isEmpty) {
      throw MigrationException('No vaults found in workspace');
    }

    // 3. NOTE: Since v1 format doesn't actually exist in current codebase
    // (user confirmed "no users yet"), this is a future-proofing implementation.
    // In practice, v1 vaults would have had password-based encryption where:
    // - Each vault had its own password
    // - Vault key was derived from password using Argon2id
    // - Migration would: unlock v1 vault → extract VK → add to v2 keyring
    //
    // For now, throw an error if migration is actually attempted.
    throw MigrationException(
      'V1 vault migration not yet implemented. No v1 vaults exist in '
      'current codebase. This migration path is future-proofing only.',
    );

    // The implementation below shows how migration would work if v1 existed:
    //
    // final vaultKeys = <String, SecureBytes>{};
    // final unlockedVaults = <UnlockedVault>[];
    //
    // try {
    //   // For each vault, unlock with old password and extract key
    //   for (final vaultPath in vaultPaths) {
    //     final vaultId = _extractVaultId(vaultPath);
    //     final password = vaultPasswords[vaultId];
    //     if (password == null) {
    //       throw MigrationException('Missing password for vault: $vaultId');
    //     }
    //
    //     // Unlock v1 vault (would need v1 VaultService API)
    //     // final unlockedVault = await _vaultService.unlockVaultV1(
    //     //   vaultPath: vaultPath,
    //     //   password: password,
    //     // );
    //
    //     // Extract and store vault key
    //     // final vaultKey = unlockedVault.vaultKey.material.copy();
    //     // vaultKeys[vaultId] = vaultKey;
    //     // unlockedVaults.add(unlockedVault);
    //   }
    //
    //   // Create v2 workspace with new master password
    //   final workspace = await _workspaceService.initializeWorkspace(
    //     rootPath: rootPath,
    //     masterPassword: newMasterPassword,
    //   );
    //
    //   try {
    //     // Add all vault keys to keyring
    //     for (final entry in vaultKeys.entries) {
    //       final vaultKeyBase64 = base64Encode(entry.value.unsafeBytes);
    //       workspace.keyring = workspace.keyring.addVault(
    //         entry.key,
    //         vaultKeyBase64,
    //         syncEnabled: true,
    //       );
    //     }
    //
    //     // Save keyring and update version
    //     await _workspaceService.saveKeyring(workspace);
    //     await updateWorkspaceVersion(rootPath, 2);
    //
    //     workspace.dispose();
    //   } catch (e) {
    //     workspace.dispose();
    //     rethrow;
    //   }
    // } finally {
    //   // Cleanup
    //   for (final vault in unlockedVaults) {
    //     vault.dispose();
    //   }
    //   for (final key in vaultKeys.values) {
    //     key.dispose();
    //   }
    // }
  }

  /// Discovers all v1 vaults in a workspace.
  ///
  /// Scans the vaults/ directory and returns paths to all directories
  /// containing a valid vault.header file (v1 format).
  ///
  /// [rootPath] - Absolute path to workspace directory
  ///
  /// Returns list of absolute paths to vault directories.
  @override
  Future<List<String>> discoverV1Vaults(String rootPath) async {
    final vaultsDir = Directory(p.join(rootPath, _vaultsSubdir));

    if (!await vaultsDir.exists()) {
      return [];
    }

    final vaultPaths = <String>[];

    try {
      await for (final entity in vaultsDir.list(followLinks: false)) {
        if (entity is Directory) {
          // Check if this directory contains a vault.header file (v1 format)
          final headerFile = File(p.join(entity.path, 'vault.header'));
          if (await headerFile.exists()) {
            vaultPaths.add(entity.path);
          }
        }
      }
    } catch (e) {
      throw MigrationException('Failed to discover v1 vaults', e);
    }

    return vaultPaths;
  }

  /// Updates the workspace version marker.
  ///
  /// This is called after successful migration to mark the workspace as v2.
  ///
  /// [rootPath] - Absolute path to workspace directory
  /// [version] - New version number (typically 2)
  ///
  /// Throws:
  /// - [MigrationException] if update fails
  @override
  Future<void> updateWorkspaceVersion(String rootPath, int version) async {
    final markerFile = File(p.join(rootPath, _workspaceMarkerFile));

    try {
      // Read current metadata
      if (!await markerFile.exists()) {
        throw MigrationException('Workspace marker file not found');
      }

      final metadataJson =
          jsonDecode(await markerFile.readAsString()) as Map<String, dynamic>;
      final metadata = WorkspaceMetadata.fromJson(metadataJson);

      // Update version
      final updatedMetadata = metadata.rebuild((b) => b..version = version);

      // Write updated metadata atomically
      final tempFile = File('${markerFile.path}.tmp');
      await tempFile.writeAsString(
        jsonEncode(updatedMetadata.toJson()),
        flush: true,
      );

      await tempFile.rename(markerFile.path);
    } catch (e) {
      throw MigrationException('Failed to update workspace version', e);
    }
  }

  /// Extracts vault ID from vault path.
  ///
  /// [vaultPath] - Absolute path to vault directory
  ///
  /// Returns vault UUID (last path component).
  // ignore: unused_element
  String _extractVaultId(String vaultPath) {
    // Reserved for future v1 migration implementation
    return p.basename(vaultPath);
  }
}

/// Exception thrown during workspace migration.
class MigrationException implements Exception {
  final String message;
  final Object? cause;

  MigrationException(this.message, [this.cause]);

  @override
  String toString() =>
      'MigrationException: $message${cause != null ? ' ($cause)' : ''}';
}
