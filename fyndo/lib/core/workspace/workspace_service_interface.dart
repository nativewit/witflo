// ═══════════════════════════════════════════════════════════════════════════
// FYNDO - Zero-Trust Notes OS
// Workspace Service Interface - SOLID Compliance (Dependency Inversion Principle)
// ═══════════════════════════════════════════════════════════════════════════
//
// This interface enables:
// 1. Dependency Inversion: High-level modules depend on abstractions, not concrete implementations
// 2. Testability: Easy mocking/stubbing for unit tests
// 3. Flexibility: Swap implementations without changing consumers
// 4. Documentation: Clear contract for workspace service operations
//
// Related spec: docs/specs/spec-003-flutter-dev-workflow-optimization.md (Section 2.1)
// Architecture: docs/specs/spec-002-workspace-master-password.md (Section 3)
// ═══════════════════════════════════════════════════════════════════════════

import 'package:fyndo_app/core/crypto/crypto.dart';
import 'package:fyndo_app/core/workspace/unlocked_workspace.dart';
import 'package:fyndo_app/core/workspace/workspace_config.dart';

/// Interface for workspace lifecycle management.
///
/// Defines the contract for:
/// - Workspace initialization and validation
/// - Master password authentication (v2)
/// - Vault discovery
/// - Configuration persistence
/// - Version detection and migration support
///
/// ## Architecture (spec-002)
/// ```
/// Master Password (user input)
///   ↓ Argon2id (workspace salt)
/// Master Unlock Key (MUK) - workspace session key
///   ↓ XChaCha20-Poly1305 (decrypt)
/// Workspace Keyring - contains vault keys
///   ↓ lookup by vault ID
/// Vault Key (VK) - random 32 bytes per vault
/// ```
abstract interface class IWorkspaceService {
  // ═══════════════════════════════════════════════════════════════════════════
  // WORKSPACE INITIALIZATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Initializes a new workspace at the given path (DEPRECATED - v1 API).
  ///
  /// Creates directory structure:
  /// ```
  /// <rootPath>/
  ///   .fyndo-workspace      # Marker file
  ///   vaults/               # Container for encrypted vaults
  /// ```
  ///
  /// Returns a [WorkspaceConfig] for the new workspace.
  ///
  /// ## Throws
  /// - [WorkspaceException] if path is not accessible or already initialized
  ///
  /// ## Deprecated
  /// Use [initializeWorkspace] with master password instead.
  @Deprecated('Use initializeWorkspace with master password instead')
  Future<WorkspaceConfig> initializeWorkspaceV1(String rootPath);

  /// Initializes a new workspace with master password authentication (v2).
  ///
  /// This creates the workspace directory structure and sets up the encrypted
  /// keyring for vault key storage. The master password is used to derive the
  /// Master Unlock Key (MUK) which encrypts the keyring.
  ///
  /// Directory structure created:
  /// ```
  /// <rootPath>/
  ///   .fyndo-workspace      # Plaintext metadata (version 2)
  ///   .fyndo-keyring.enc    # Encrypted keyring
  ///   vaults/               # Container for vault directories
  /// ```
  ///
  /// [rootPath] - Absolute path to workspace directory
  /// [masterPassword] - User's master password (will be zeroized)
  ///
  /// Returns an [UnlockedWorkspace] with the workspace unlocked and ready to use.
  ///
  /// ## Implementation Notes
  /// 1. Benchmark Argon2id params for this device (target 1 second)
  /// 2. Generate workspace salt
  /// 3. Derive MUK (zeroizes masterPassword)
  /// 4. Create empty keyring
  /// 5. Encrypt keyring with MUK
  /// 6. Write workspace files
  /// 7. Return unlocked workspace
  ///
  /// ## Throws
  /// - [WorkspaceException] if initialization fails
  ///
  /// ## Example
  /// ```dart
  /// final password = SecureBytes.fromUtf8('my-secure-password');
  /// final workspace = await service.initializeWorkspace(
  ///   rootPath: '/path/to/workspace',
  ///   masterPassword: password,
  /// );
  /// // password is now zeroized
  /// ```
  ///
  /// Spec: docs/specs/spec-002-workspace-master-password.md (Section 3.1)
  Future<UnlockedWorkspace> initializeWorkspace({
    required String rootPath,
    required SecureBytes masterPassword,
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // WORKSPACE AUTHENTICATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Unlocks an existing workspace with the master password.
  ///
  /// This reads the workspace metadata, derives the Master Unlock Key (MUK)
  /// from the password, and decrypts the keyring to provide access to all
  /// vault keys.
  ///
  /// [rootPath] - Absolute path to workspace directory
  /// [masterPassword] - User's master password (will be zeroized)
  ///
  /// Returns an [UnlockedWorkspace] with the workspace unlocked and ready to use.
  ///
  /// ## Implementation Notes
  /// 1. Read workspace metadata
  /// 2. Extract salt, nonce, Argon2 params
  /// 3. Derive MUK (zeroizes masterPassword)
  /// 4. Read encrypted keyring
  /// 5. Decrypt keyring with MUK
  /// 6. Return unlocked workspace
  ///
  /// ## Throws
  /// - [WorkspaceException] if workspace not found, invalid password, or wrong version
  ///
  /// ## Example
  /// ```dart
  /// final password = SecureBytes.fromUtf8('my-secure-password');
  /// try {
  ///   final workspace = await service.unlockWorkspace(
  ///     rootPath: '/path/to/workspace',
  ///     masterPassword: password,
  ///   );
  ///   // Use workspace...
  /// } catch (e) {
  ///   if (e is WorkspaceException && e.message.contains('Invalid')) {
  ///     print('Wrong password!');
  ///   }
  /// }
  /// ```
  ///
  /// Spec: docs/specs/spec-002-workspace-master-password.md (Section 3.2)
  Future<UnlockedWorkspace> unlockWorkspace({
    required String rootPath,
    required SecureBytes masterPassword,
  });

  /// Locks a workspace by disposing all cryptographic material.
  ///
  /// This zeroizes the Master Unlock Key (MUK) and all cached vault keys
  /// from memory. After calling this, the workspace must be unlocked again
  /// with the master password.
  ///
  /// [workspace] - The unlocked workspace to lock
  ///
  /// ## Example
  /// ```dart
  /// service.lockWorkspace(workspace);
  /// // workspace.muk is now zeroized, cannot access vault keys
  /// ```
  ///
  /// Spec: docs/specs/spec-002-workspace-master-password.md (Section 3.5)
  void lockWorkspace(UnlockedWorkspace workspace);

  /// Changes the master password for a workspace.
  ///
  /// This verifies the current password, generates a new salt and Argon2id
  /// parameters, derives a new MUK, and re-encrypts the keyring. The vault
  /// keys themselves are not changed (they're random, not derived from password).
  ///
  /// This operation is fast (~1-2 seconds) because only the keyring is
  /// re-encrypted, not the vault content.
  ///
  /// [workspace] - Currently unlocked workspace
  /// [currentPassword] - Current master password (for verification)
  /// [newPassword] - New master password (will be zeroized)
  ///
  /// ## Throws
  /// - [WorkspaceException] if current password is incorrect or operation fails
  ///
  /// ## Example
  /// ```dart
  /// final current = SecureBytes.fromUtf8('old-password');
  /// final newPass = SecureBytes.fromUtf8('new-password');
  /// await service.changeMasterPassword(
  ///   workspace: workspace,
  ///   currentPassword: current,
  ///   newPassword: newPass,
  /// );
  /// ```
  ///
  /// Spec: docs/specs/spec-002-workspace-master-password.md (Section 3.4)
  Future<void> changeMasterPassword({
    required UnlockedWorkspace workspace,
    required SecureBytes currentPassword,
    required SecureBytes newPassword,
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // WORKSPACE VALIDATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Validates that a directory is a valid Fyndo workspace.
  ///
  /// Checks for:
  /// 1. Directory exists and is accessible
  /// 2. Contains .fyndo-workspace marker file
  /// 3. Contains vaults/ subdirectory
  ///
  /// Returns true if valid, false otherwise.
  ///
  /// ## Example
  /// ```dart
  /// if (await service.isValidWorkspace('/path/to/dir')) {
  ///   print('Valid workspace!');
  /// } else {
  ///   print('Not a workspace or corrupted');
  /// }
  /// ```
  Future<bool> isValidWorkspace(String rootPath);

  // ═══════════════════════════════════════════════════════════════════════════
  // WORKSPACE PERSISTENCE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Saves workspace configuration to SharedPreferences.
  ///
  /// Configuration is persisted as JSON for fast access on app startup.
  ///
  /// ## Example
  /// ```dart
  /// final config = WorkspaceConfig.create(rootPath: '/path/to/workspace');
  /// await service.saveWorkspaceConfig(config);
  /// ```
  Future<void> saveWorkspaceConfig(WorkspaceConfig config);

  /// Loads workspace configuration from SharedPreferences.
  ///
  /// Returns null if no workspace has been configured yet.
  ///
  /// ## Example
  /// ```dart
  /// final config = await service.loadWorkspaceConfig();
  /// if (config == null) {
  ///   print('No workspace configured, show onboarding');
  /// } else {
  ///   print('Workspace at: ${config.rootPath}');
  /// }
  /// ```
  Future<WorkspaceConfig?> loadWorkspaceConfig();

  /// Clears the workspace configuration from SharedPreferences.
  ///
  /// Use when user wants to switch to a different workspace.
  ///
  /// ## Example
  /// ```dart
  /// await service.clearWorkspaceConfig();
  /// // User will be prompted to select workspace on next launch
  /// ```
  Future<void> clearWorkspaceConfig();

  /// Switches to a different workspace.
  ///
  /// Validates the new workspace, adds the old one to recent workspaces,
  /// and updates the configuration.
  ///
  /// ## Example
  /// ```dart
  /// final newConfig = await service.switchWorkspace('/path/to/other/workspace');
  /// print('Switched to: ${newConfig.rootPath}');
  /// ```
  Future<WorkspaceConfig> switchWorkspace(String newRootPath);

  // ═══════════════════════════════════════════════════════════════════════════
  // VAULT DISCOVERY
  // ═══════════════════════════════════════════════════════════════════════════

  /// Discovers all vault directories within the workspace.
  ///
  /// Scans the vaults/ subdirectory and returns paths to all directories
  /// containing a valid vault.header file.
  ///
  /// Returns a list of absolute paths to vault directories.
  ///
  /// ## Example
  /// ```dart
  /// final vaultPaths = await service.discoverVaults('/path/to/workspace');
  /// for (final path in vaultPaths) {
  ///   print('Found vault: $path');
  /// }
  /// ```
  Future<List<String>> discoverVaults(String workspaceRoot);

  /// Returns the path where a new vault should be created.
  ///
  /// [vaultId] - UUID for the vault (generated by VaultService)
  ///
  /// Returns path in format: `/path/to/workspace/vaults/<vault-uuid>`
  ///
  /// ## Example
  /// ```dart
  /// final vaultId = Uuid().v4();
  /// final path = service.getNewVaultPath('/path/to/workspace', vaultId);
  /// // path = '/path/to/workspace/vaults/550e8400-e29b-41d4-a716-446655440000'
  /// ```
  String getNewVaultPath(String workspaceRoot, String vaultId);

  // ═══════════════════════════════════════════════════════════════════════════
  // KEYRING PERSISTENCE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Saves the workspace keyring to disk (encrypted with MUK).
  ///
  /// This is called after vault creation, deletion, or keyring modifications.
  /// The keyring is encrypted with the workspace's MUK and written atomically.
  ///
  /// [workspace] - Unlocked workspace with current keyring
  ///
  /// ## Throws
  /// - [WorkspaceException] if save operation fails
  ///
  /// ## Example
  /// ```dart
  /// // After adding a vault key to keyring
  /// workspace.keyring.addVaultKey(vaultId, vaultKey);
  /// await service.saveKeyring(workspace);
  /// ```
  Future<void> saveKeyring(UnlockedWorkspace workspace);

  // ═══════════════════════════════════════════════════════════════════════════
  // VERSION DETECTION & MIGRATION SUPPORT
  // ═══════════════════════════════════════════════════════════════════════════

  /// Gets the version of an existing workspace.
  ///
  /// Reads the .fyndo-workspace marker file and extracts the version number.
  /// If the file doesn't exist or has no version field, assumes v1 (legacy).
  ///
  /// [rootPath] - Absolute path to workspace directory
  ///
  /// Returns version number:
  /// - 1 = v1 (per-vault passwords, no workspace metadata)
  /// - 2 = v2 (master password with encrypted keyring)
  ///
  /// ## Example
  /// ```dart
  /// final version = await service.getWorkspaceVersion('/path/to/workspace');
  /// if (version < 2) {
  ///   print('Legacy workspace, migration required');
  /// }
  /// ```
  ///
  /// Spec: docs/specs/spec-002-workspace-master-password.md (Section 4)
  Future<int> getWorkspaceVersion(String rootPath);

  /// Checks if a workspace is using v1 architecture (per-vault passwords).
  ///
  /// [rootPath] - Absolute path to workspace directory
  ///
  /// Returns true if workspace is v1, false if v2 or newer.
  ///
  /// This is useful for triggering migration prompts in the UI.
  ///
  /// ## Example
  /// ```dart
  /// if (await service.isV1Workspace('/path/to/workspace')) {
  ///   showMigrationDialog();
  /// }
  /// ```
  Future<bool> isV1Workspace(String rootPath);

  // ═══════════════════════════════════════════════════════════════════════════
  // WORKSPACE SELECTION HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Opens folder picker and returns selected path (or null if cancelled).
  ///
  /// ## Example
  /// ```dart
  /// final path = await service.pickWorkspaceFolder();
  /// if (path != null) {
  ///   print('User selected: $path');
  /// } else {
  ///   print('User cancelled');
  /// }
  /// ```
  Future<String?> pickWorkspaceFolder();

  /// Returns the default workspace directory for the current platform.
  ///
  /// Platform defaults:
  /// - macOS: ~/Documents/Fyndo
  /// - Windows: %USERPROFILE%\Documents\Fyndo
  /// - Linux: ~/Documents/Fyndo
  ///
  /// ## Example
  /// ```dart
  /// final defaultPath = await service.getDefaultWorkspaceDirectory();
  /// print('Suggested workspace: $defaultPath');
  /// ```
  Future<String> getDefaultWorkspaceDirectory();
}
