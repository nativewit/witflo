// ═══════════════════════════════════════════════════════════════════════════
// FYNDO - Zero-Trust Notes OS
// Vault Providers - Riverpod State Management
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
class VaultNotifier extends Notifier<VaultState> {
  late final VaultService _vaultService;

  @override
  VaultState build() {
    _vaultService = VaultService(ref.read(cryptoServiceProvider));
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
  Future<void> createVault({
    required String path,
    required SecureBytes password,
    Argon2Params? kdfParams,
  }) async {
    state = state.copyWith(status: VaultStatus.creating);

    try {
      await _vaultService.createVault(
        vaultPath: path,
        password: password,
        kdfParams: kdfParams,
      );

      state = state.copyWith(status: VaultStatus.locked, vaultPath: path);
    } catch (e) {
      state = state.copyWith(status: VaultStatus.error, error: e.toString());
      rethrow;
    }
  }

  /// Unlocks the vault with a password.
  Future<void> unlock(SecureBytes password) async {
    if (state.vaultPath == null) {
      throw StateError('Vault path not set');
    }

    state = state.copyWith(status: VaultStatus.unlocking);

    try {
      final vault = await _vaultService.unlockVault(
        vaultPath: state.vaultPath!,
        password: password,
      );

      state = state.copyWith(status: VaultStatus.unlocked, vault: vault);
    } on VaultException catch (e) {
      state = state.copyWith(status: VaultStatus.error, error: e.message);
      rethrow;
    }
  }

  /// Locks the vault.
  void lock() {
    state.vault?.dispose();
    state = state.copyWith(status: VaultStatus.locked, vault: null);
  }

  /// Changes the vault password.
  Future<void> changePassword({
    required SecureBytes newPassword,
    Argon2Params? newKdfParams,
  }) async {
    if (!state.isUnlocked) {
      throw StateError('Vault must be unlocked to change password');
    }

    await _vaultService.changePassword(
      vault: state.vault!,
      newPassword: newPassword,
      newKdfParams: newKdfParams,
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
