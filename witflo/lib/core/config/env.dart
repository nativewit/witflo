/// Application Environment Configuration
///
/// This singleton provides centralized configuration for the application,
/// making it easy to change app name, file identifiers, and other
/// environment-level settings from a single place.
///
/// Usage:
/// ```dart
/// final appName = AppEnvironment.instance.appName;
/// final workspaceMarker = AppEnvironment.instance.workspaceMarkerFile;
/// ```
class AppEnvironment {
  // Private constructor for singleton pattern
  AppEnvironment._();

  /// Singleton instance
  static final AppEnvironment instance = AppEnvironment._();

  /// Application display name
  ///
  /// Used throughout the UI for branding and display purposes.
  /// Change this single value to rebrand the entire application.
  String get appName => 'Witflo';

  /// Workspace marker file name
  ///
  /// This file is created in the root of a workspace folder to indicate
  /// that it's a valid, initialized workspace. Contains plaintext metadata
  /// like version, salt, and Argon2id parameters.
  ///
  /// File format: `.{app-name}-workspace`
  String get workspaceMarkerFile => '.witflo-workspace';

  /// Workspace keyring file name
  ///
  /// This file contains the encrypted keyring with all vault keys.
  /// Encrypted with the Master Unlock Key (MUK) using XChaCha20-Poly1305.
  ///
  /// File format: `.{app-name}-keyring.enc`
  String get workspaceKeyringFile => '.witflo-keyring.enc';

  /// Vault metadata file name
  ///
  /// This file is created in each vault folder and contains plaintext
  /// metadata about the vault (id, name, creation date, etc.).
  ///
  /// File format: `.vault-meta.json`
  String get vaultMetadataFile => '.vault-meta.json';

  /// Workspace access test file name (temporary)
  ///
  /// Used when testing folder write permissions during folder selection.
  /// Created temporarily and immediately deleted.
  ///
  /// File format: `.{app-name}-access-test`
  String get accessTestFile => '.witflo-access-test';

  /// Application version
  ///
  /// Updated manually with each release.
  String get appVersion => '0.1.0';

  /// Minimum supported workspace version
  ///
  /// Workspaces with versions below this will require migration.
  int get minSupportedWorkspaceVersion => 1;

  /// Current workspace version
  ///
  /// Used when creating new workspaces.
  int get currentWorkspaceVersion => 2;
}
