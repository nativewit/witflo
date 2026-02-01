// ═══════════════════════════════════════════════════════════════════════════
// FYNDO - Zero-Trust Notes OS
// IWorkspaceMigrationService - Workspace Migration Service Interface
// ═══════════════════════════════════════════════════════════════════════════

import 'package:fyndo_app/core/crypto/types/types.dart';

/// Service for migrating v1 workspaces (per-vault passwords) to v2 (master password).
abstract interface class IWorkspaceMigrationService {
  /// Migrates a v1 workspace to v2 with master password.
  ///
  /// This is a destructive operation that replaces the workspace authentication
  /// model. The user should backup their workspace before proceeding.
  ///
  /// [rootPath] - Absolute path to workspace directory
  /// [newMasterPassword] - New master password for v2 workspace
  /// [vaultPasswords] - Map of vaultId → old vault password
  ///
  /// Throws [MigrationException] if migration fails at any step.
  Future<void> migrateWorkspaceV1ToV2({
    required String rootPath,
    required SecureBytes newMasterPassword,
    required Map<String, SecureBytes> vaultPasswords,
  });

  /// Discovers all v1 vaults in a workspace.
  ///
  /// Returns a list of absolute paths to vault directories.
  Future<List<String>> discoverV1Vaults(String rootPath);

  /// Updates workspace version marker file.
  Future<void> updateWorkspaceVersion(String rootPath, int version);
}

/// Exception thrown during workspace migration.
class MigrationException implements Exception {
  final String message;
  final Object? cause;

  MigrationException(this.message, [this.cause]);

  @override
  String toString() =>
      'MigrationException: $message${cause != null ? ' (caused by: $cause)' : ''}';
}
