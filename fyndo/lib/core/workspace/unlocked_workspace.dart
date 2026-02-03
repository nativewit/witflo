// ═══════════════════════════════════════════════════════════════════════════
// FYNDO - Zero-Trust Notes OS
// Unlocked Workspace - In-memory state after unlocking
// ═══════════════════════════════════════════════════════════════════════════
//
// UPDATED FOR WORKSPACE MASTER PASSWORD (spec-002):
// This class represents the unlocked workspace state, including:
// - Master Unlock Key (MUK) - memory only, derived from master password
// - Workspace Keyring - vault keys encrypted with MUK
// - Cached vault keys - decoded SecureBytes for performance
//
// Spec: docs/specs/spec-002-workspace-master-password.md
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:convert';

import 'package:fyndo_app/core/crypto/types/key_types.dart';
import 'package:fyndo_app/core/crypto/types/secure_bytes.dart';
import 'package:fyndo_app/core/logging/app_logger.dart';
import 'package:fyndo_app/core/workspace/workspace_keyring.dart';

/// Session state for an unlocked workspace.
///
/// This class holds sensitive cryptographic material in memory during an
/// active session. It MUST be properly disposed when the workspace is locked
/// to prevent key material from remaining in memory.
///
/// **CRITICAL SECURITY NOTES:**
///
/// 1. **Lifecycle Management:**
///    - Create: Only when workspace is successfully unlocked
///    - Active: While user is actively using the workspace
///    - Dispose: On lock, background, idle timeout, or app exit
///
/// 2. **Memory Security:**
///    - MUK (Master Unlock Key) is cached for fast keyring operations
///    - Vault keys are cached on first access to avoid repeated decryption
///    - All keys are zeroized on dispose() - no exceptions
///
/// 3. **Thread Safety:**
///    - This class is NOT thread-safe
///    - Access only from UI thread / main isolate
///
/// 4. **Never Serialize:**
///    - This is mutable session state, not a model
///    - Never serialize to JSON or persist to disk
///    - Keys exist in memory only during active session
///
/// **Usage Pattern:**
/// ```dart
/// // Unlock workspace
/// final workspace = await workspaceService.unlockWorkspace(
///   rootPath: '/path/to/workspace',
///   masterPassword: password,
/// );
///
/// try {
///   // Use workspace to access vaults
///   final vaultKey = workspace.getVaultKey('vault-uuid-1');
///
///   // ... perform operations ...
/// } finally {
///   // ALWAYS dispose when done
///   workspace.dispose();
/// }
/// ```
class UnlockedWorkspace {
  /// Master Unlock Key (MUK) - derived from master password.
  ///
  /// This key is used to:
  /// - Decrypt the workspace keyring
  /// - Re-encrypt keyring after vault creation/deletion
  /// - Verify password during password change
  ///
  /// **SECURITY:** This key is zeroized on dispose(). Never copy or leak.
  final MasterUnlockKey muk;

  /// Decrypted workspace keyring containing vault keys.
  ///
  /// The keyring maps vaultId → VaultKeyEntry (containing base64 vault key).
  /// This is the decrypted version of .fyndo-keyring.enc
  ///
  /// **NOTE:** This field is mutable to support keyring updates (add/remove vaults).
  WorkspaceKeyring keyring;

  /// Workspace root directory path (absolute).
  ///
  /// Example: `/Users/alice/Documents/Fyndo`
  ///
  /// Used to:
  /// - Locate vault directories (under `vaults/`)
  /// - Save keyring changes to `.fyndo-keyring.enc`
  /// - Access workspace metadata (`.fyndo-workspace`)
  final String rootPath;

  /// Cache of decrypted vault keys (vaultId → vault key material).
  ///
  /// Vault keys are decoded from base64 and cached on first access via
  /// [getVaultKey]. This avoids repeated base64 decoding.
  ///
  /// **SECURITY:** All cached keys are zeroized on dispose().
  final Map<String, SecureBytes> _vaultKeyCache = {};

  /// Creates an unlocked workspace session.
  ///
  /// **DO NOT** call this constructor directly. Use [WorkspaceService.unlockWorkspace]
  /// which properly derives the MUK and decrypts the keyring.
  ///
  /// Parameters:
  /// - [muk]: Master Unlock Key (ownership transferred to this instance)
  /// - [keyring]: Decrypted workspace keyring
  /// - [rootPath]: Absolute path to workspace directory
  UnlockedWorkspace({
    required this.muk,
    required this.keyring,
    required this.rootPath,
  }) {
    final log = AppLogger.get('UnlockedWorkspace');
    log.debug(
      'UnlockedWorkspace created: '
      'instance=${identityHashCode(this)}, '
      'vaults in keyring=${keyring.vaults.length}, '
      'vault IDs=${keyring.vaults.keys.join(", ")}',
    );
  }

  /// Gets the vault key for a specific vault.
  ///
  /// This method returns the raw vault key material (32 bytes) for the given
  /// vault. The key is cached after first access to avoid repeated base64
  /// decoding.
  ///
  /// **SECURITY:**
  /// - The returned key is owned by this UnlockedWorkspace
  /// - DO NOT dispose the returned key - it will be disposed on workspace lock
  /// - The key is cached and reused for subsequent calls
  ///
  /// **Usage:**
  /// ```dart
  /// final vaultKey = workspace.getVaultKey('vault-uuid-1');
  /// final unlockedVault = await vaultService.unlockVault(
  ///   vaultPath: vaultPath,
  ///   vaultKey: vaultKey,
  /// );
  /// ```
  ///
  /// Throws [StateError] if the vault ID is not found in the keyring.
  SecureBytes getVaultKey(String vaultId) {
    final log = AppLogger.get('UnlockedWorkspace');
    log.debug(
      'getVaultKey() called: '
      'instance=${identityHashCode(this)}, '
      'vaultId=$vaultId',
    );

    // Check cache first
    if (_vaultKeyCache.containsKey(vaultId)) {
      final cachedKey = _vaultKeyCache[vaultId]!;
      log.debug(
        'Vault key found in cache. '
        'Is disposed: ${cachedKey.isDisposed}, '
        'Length: ${cachedKey.isDisposed ? "N/A" : cachedKey.length}',
      );
      if (cachedKey.isDisposed) {
        log.error(
          'CRITICAL: Cached vault key is already disposed!',
          error: StateError('Cached vault key for $vaultId is disposed'),
        );
      }
      return cachedKey;
    }

    log.debug(
      'Vault key not in cache, decoding from keyring... '
      'Available vaults in this instance: ${keyring.vaults.keys.join(", ")}',
    );

    // Lookup in keyring
    final entry = keyring.vaults[vaultId];
    if (entry == null) {
      log.error(
        'Vault not found in keyring!',
        error: StateError(
          'Vault "$vaultId" not found in workspace keyring. '
          'Available vaults: ${keyring.vaults.keys.join(', ')}',
        ),
      );
      throw StateError(
        'Vault "$vaultId" not found in workspace keyring. '
        'Available vaults: ${keyring.vaults.keys.join(', ')}',
      );
    }

    // Decode vault key from base64
    final vaultKeyBytes = base64Decode(entry.vaultKey);
    final vaultKey = SecureBytes.fromList(vaultKeyBytes);

    // Cache for future access
    _vaultKeyCache[vaultId] = vaultKey;

    log.debug('Vault key decoded and cached. Length: ${vaultKey.length}');

    return vaultKey;
  }

  /// Disposes all cryptographic material and locks the workspace.
  ///
  /// This method:
  /// 1. Zeroizes the Master Unlock Key (MUK)
  /// 2. Zeroizes all cached vault keys
  /// 3. Clears the vault key cache
  ///
  /// **CRITICAL:** Always call this when:
  /// - User explicitly locks workspace
  /// - App goes to background (iOS/Android)
  /// - Idle timer expires
  /// - App is about to exit
  ///
  /// After calling dispose(), this instance is unusable and any access to
  /// keys will throw [StateError].
  ///
  /// **Usage:**
  /// ```dart
  /// // Lock workspace on user action
  /// void lockWorkspace() {
  ///   _unlockedWorkspace?.dispose();
  ///   _unlockedWorkspace = null;
  ///   // Update UI to show locked state
  /// }
  ///
  /// // Lock on app background (WidgetsBindingObserver)
  /// @override
  /// void didChangeAppLifecycleState(AppLifecycleState state) {
  ///   if (state == AppLifecycleState.paused) {
  ///     lockWorkspace();
  ///   }
  /// }
  /// ```
  void dispose() {
    try {
      // 1. Dispose MUK
      muk.dispose();

      // 2. Dispose all cached vault keys
      for (final vaultKey in _vaultKeyCache.values) {
        vaultKey.dispose();
      }
    } finally {
      // 3. Clear cache (even if dispose throws)
      _vaultKeyCache.clear();
    }
  }

  @override
  String toString() {
    // NEVER log key material
    return 'UnlockedWorkspace('
        'rootPath: $rootPath, '
        'vaults: ${keyring.vaults.length}, '
        'cached: ${_vaultKeyCache.length}'
        ')';
  }
}
