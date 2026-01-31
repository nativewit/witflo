// ═══════════════════════════════════════════════════════════════════════════
// FYNDO - Zero-Trust Notes OS
// Vault Providers - Riverpod State Management
// ═══════════════════════════════════════════════════════════════════════════
//
// IMPORTANT - SPEC-002 CHANGES:
// With the workspace master password architecture, this provider's role has changed:
// - Vaults no longer have individual passwords (keys are random, stored in keyring)
// - createVault() and unlock() are DEPRECATED - use workspace-level operations instead
// - This provider now mainly tracks vault state for UI consumers
// - In future refactoring, consider merging with workspace providers
//
// Migration path:
// - Old: vaultProvider.notifier.createVault(path, password)
// - New: workspaceService.createVault(vaultKey from keyring, ...)
// - Old: vaultProvider.notifier.unlock(password)
// - New: workspaceService.unlockWorkspace(masterPassword) → all vaults accessible
//
// Spec: docs/specs/spec-002-workspace-master-password.md
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fyndo_app/core/core.dart';
import 'package:fyndo_app/providers/crypto_providers.dart';

/// Vault state.
enum VaultStatus {
  uninitialized, // No vault exists
  locked, // Vault exists but not unlocked
  unlocked, // Vault is unlocked
  unlocking, // Currently unlocking
  creating, // Currently creating
  error, // Error state
}

/// State for the vault.
class VaultState {
  final VaultStatus status;
  final UnlockedVault? vault;
  final String? vaultPath;
  final String? error;

  const VaultState({
    this.status = VaultStatus.uninitialized,
    this.vault,
    this.vaultPath,
    this.error,
  });

  VaultState copyWith({
    VaultStatus? status,
    UnlockedVault? vault,
    String? vaultPath,
    String? error,
  }) {
    return VaultState(
      status: status ?? this.status,
      vault: vault ?? this.vault,
      vaultPath: vaultPath ?? this.vaultPath,
      error: error,
    );
  }

  bool get isUnlocked => status == VaultStatus.unlocked && vault != null;
}

/// Notifier for vault state management.
///
/// NOTE: This notifier is largely deprecated in spec-002. It only tracks state
/// for backward compatibility with existing UI consumers. All vault operations
/// should now go through workspace-level services.
class VaultNotifier extends Notifier<VaultState> {
  @override
  VaultState build() {
    return const VaultState();
  }

  /// Sets the vault path for an existing vault.
  Future<void> setVaultPath(String path) async {
    final filesystem = VaultFilesystem(path);
    final exists = await filesystem.exists();

    state = state.copyWith(
      status: exists ? VaultStatus.locked : VaultStatus.uninitialized,
      vaultPath: path,
    );
  }

  /// Creates a new vault.
  ///
  /// DEPRECATED in spec-002: Vaults no longer have passwords.
  /// Use workspace-level vault creation instead:
  /// 1. Ensure workspace is unlocked
  /// 2. Generate random vault key
  /// 3. Add key to workspace keyring
  /// 4. Call vaultService.createVault(vaultKey, ...)
  ///
  /// This method is kept for backward compatibility but should not be used.
  @Deprecated('Use workspace-level vault creation with random keys')
  Future<void> createVault({
    required String path,
    required SecureBytes password,
    Argon2Params? kdfParams,
  }) async {
    throw UnsupportedError(
      'createVault with password is deprecated in spec-002. '
      'Use workspace-level vault creation with random vault keys. '
      'See: docs/specs/spec-002-workspace-master-password.md',
    );
  }

  /// Unlocks the vault with a password.
  ///
  /// DEPRECATED in spec-002: Vaults no longer have individual passwords.
  /// Use workspace-level unlock instead:
  /// 1. Call workspaceService.unlockWorkspace(masterPassword)
  /// 2. All vaults become accessible via the unlocked keyring
  ///
  /// This method is kept for backward compatibility but should not be used.
  @Deprecated('Use workspace-level unlock with master password')
  Future<void> unlock(SecureBytes password) async {
    throw UnsupportedError(
      'unlock with password is deprecated in spec-002. '
      'Use workspaceService.unlockWorkspace(masterPassword) instead. '
      'See: docs/specs/spec-002-workspace-master-password.md',
    );
  }

  /// Locks the vault.
  void lock() {
    state.vault?.dispose();
    state = state.copyWith(status: VaultStatus.locked, vault: null);
  }

  /// Changes the vault password.
  ///
  /// DEPRECATED in spec-002: Vault password changes are now workspace-level.
  /// Use workspaceService.changeMasterPassword() instead, which re-encrypts
  /// the entire keyring (not individual vault content).
  ///
  /// This method is kept for backward compatibility but should not be used.
  @Deprecated('Use workspace-level password change')
  Future<void> changePassword({
    required SecureBytes newPassword,
    Argon2Params? newKdfParams,
  }) async {
    throw UnsupportedError(
      'changePassword is deprecated in spec-002. '
      'Use workspaceService.changeMasterPassword() instead. '
      'See: docs/specs/spec-002-workspace-master-password.md',
    );
  }
}

/// Provider for vault state.
final vaultProvider = NotifierProvider<VaultNotifier, VaultState>(
  VaultNotifier.new,
);

/// Provider for vault service.
final vaultServiceProvider = Provider<VaultService>((ref) {
  return VaultService(ref.watch(cryptoServiceProvider));
});

/// Provider for the unlocked vault (throws if not unlocked).
final unlockedVaultProvider = Provider<UnlockedVault>((ref) {
  final vaultState = ref.watch(vaultProvider);
  if (!vaultState.isUnlocked) {
    throw StateError('Vault is not unlocked');
  }
  return vaultState.vault!;
});
