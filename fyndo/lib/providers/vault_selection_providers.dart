// ═══════════════════════════════════════════════════════════════════════════
// FYNDO - Zero-Trust Notes OS
// Vault Selection Providers - Multi-vault support with user selection
// ═══════════════════════════════════════════════════════════════════════════
//
// PURPOSE:
// These providers enable multi-vault support by tracking:
// - Which vault the user has selected (selectedVaultIdProvider)
// - Metadata for the selected vault (activeVaultMetadataProvider)
// - All available vaults in the workspace (availableVaultsProvider)
// - Statistics for the selected vault (activeVaultStatsProvider)
//
// ARCHITECTURE:
// - selectedVaultIdProvider: StateNotifier that persists selection
// - Other providers react to selection changes via watch()
// - Vault metadata is loaded from .vault-meta.json (plaintext)
//
// Spec: docs/specs/spec-002-workspace-master-password.md
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fyndo_app/core/crypto/crypto.dart';
import 'package:fyndo_app/core/logging/app_logger.dart';
import 'package:fyndo_app/core/vault/vault_metadata.dart';
import 'package:fyndo_app/core/workspace/unlocked_workspace.dart';
import 'package:fyndo_app/providers/crypto_providers.dart';
import 'package:fyndo_app/providers/note_providers.dart';
import 'package:fyndo_app/providers/notebook_providers.dart';
import 'package:fyndo_app/providers/unlocked_workspace_provider.dart';
import 'package:fyndo_app/providers/vault_providers.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

/// Information about a vault for display in the vault switcher.
class VaultInfo {
  final String vaultId;
  final VaultMetadata metadata;
  final bool isSelected;

  const VaultInfo({
    required this.vaultId,
    required this.metadata,
    required this.isSelected,
  });
}

/// Statistics for a vault.
class VaultStats {
  final int noteCount;
  final int notebookCount;
  final DateTime? lastModified;

  const VaultStats({
    required this.noteCount,
    required this.notebookCount,
    this.lastModified,
  });

  static const empty = VaultStats(
    noteCount: 0,
    notebookCount: 0,
    lastModified: null,
  );
}

/// StateNotifier for tracking the selected vault ID.
///
/// The selection is automatically reset when the workspace changes.
/// If no vault is explicitly selected, defaults to the first vault.
class SelectedVaultNotifier extends StateNotifier<String?> {
  final Ref _ref;

  SelectedVaultNotifier(this._ref) : super(null) {
    // Auto-select first vault when workspace is unlocked
    _initializeSelection();
  }

  void _initializeSelection() {
    final workspace = _ref.read(unlockedWorkspaceProvider);
    if (workspace != null && state == null) {
      final vaultIds = workspace.keyring.vaults.keys.toList();
      if (vaultIds.isNotEmpty) {
        state = vaultIds.first;
      }
    }
  }

  /// Selects a vault by ID.
  ///
  /// Throws [ArgumentError] if the vault ID is not in the workspace keyring.
  void selectVault(String vaultId) {
    final workspace = _ref.read(unlockedWorkspaceProvider);
    if (workspace == null) {
      throw StateError('Cannot select vault: workspace is locked');
    }

    if (!workspace.keyring.vaults.containsKey(vaultId)) {
      throw ArgumentError('Vault "$vaultId" not found in workspace');
    }

    state = vaultId;
  }

  /// Clears the selection (used when workspace is locked).
  void clearSelection() {
    state = null;
  }

  /// Ensures a vault is selected, defaulting to first available.
  void ensureSelection() {
    if (state != null) return;

    final workspace = _ref.read(unlockedWorkspaceProvider);
    if (workspace == null) return;

    final vaultIds = workspace.keyring.vaults.keys.toList();
    if (vaultIds.isNotEmpty) {
      state = vaultIds.first;
    }
  }
}

/// Provider for the selected vault ID.
///
/// This tracks which vault the user has selected. Other providers
/// watch this to load the appropriate vault data.
///
/// If null, no vault is selected (workspace may be locked or empty).
final selectedVaultIdProvider =
    StateNotifierProvider<SelectedVaultNotifier, String?>((ref) {
      final notifier = SelectedVaultNotifier(ref);

      // Watch workspace changes to auto-select vault
      ref.listen<UnlockedWorkspace?>(unlockedWorkspaceProvider, (
        previous,
        next,
      ) {
        if (next == null) {
          // Workspace locked, clear selection
          notifier.clearSelection();
        } else if (previous == null) {
          // Workspace just unlocked, ensure selection
          notifier.ensureSelection();
        }
      });

      return notifier;
    });

/// Provider that returns the active vault ID.
///
/// This is a convenience provider that returns the selected vault ID,
/// or falls back to the first vault if none is selected.
///
/// This replaces the old activeVaultIdProvider in note_providers.dart.
final activeVaultIdProvider = Provider<String?>((ref) {
  final selectedId = ref.watch(selectedVaultIdProvider);
  if (selectedId != null) return selectedId;

  // Fallback to first vault
  final workspace = ref.watch(unlockedWorkspaceProvider);
  if (workspace == null) return null;

  final vaultIds = workspace.keyring.vaults.keys.toList();
  return vaultIds.isNotEmpty ? vaultIds.first : null;
});

/// Provider for metadata of the currently selected vault.
///
/// Loads the .vault-meta.json file for the selected vault.
/// Returns null if no vault is selected or metadata cannot be loaded.
final activeVaultMetadataProvider = FutureProvider<VaultMetadata?>((ref) async {
  final workspace = ref.watch(unlockedWorkspaceProvider);
  final vaultId = ref.watch(activeVaultIdProvider);

  if (workspace == null || vaultId == null) return null;

  final vaultPath = p.join(workspace.rootPath, 'vaults', vaultId);
  final vaultService = ref.watch(vaultServiceProvider);

  return vaultService.loadVaultMetadata(vaultPath);
});

/// Provider for all available vaults in the workspace.
///
/// Returns a list of VaultInfo objects with metadata and selection state.
/// Useful for displaying in the vault switcher dialog.
final availableVaultsProvider = FutureProvider<List<VaultInfo>>((ref) async {
  final workspace = ref.watch(unlockedWorkspaceProvider);
  final selectedId = ref.watch(activeVaultIdProvider);

  if (workspace == null) return [];

  final vaultService = ref.watch(vaultServiceProvider);
  final vaults = <VaultInfo>[];

  for (final vaultId in workspace.keyring.vaults.keys) {
    final vaultPath = p.join(workspace.rootPath, 'vaults', vaultId);
    final metadata = await vaultService.loadVaultMetadata(vaultPath);

    if (metadata != null) {
      vaults.add(
        VaultInfo(
          vaultId: vaultId,
          metadata: metadata,
          isSelected: vaultId == selectedId,
        ),
      );
    }
  }

  // Sort by creation date (oldest first)
  vaults.sort((a, b) => a.metadata.createdAt.compareTo(b.metadata.createdAt));

  return vaults;
});

/// Provider for statistics of the currently selected vault.
///
/// Returns note count, notebook count, and last modified time.
final activeVaultStatsProvider = FutureProvider<VaultStats>((ref) async {
  final vaultId = ref.watch(activeVaultIdProvider);
  if (vaultId == null) return VaultStats.empty;

  // Wait for notebook data to load
  final notebooksState = await ref.watch(notebooksProvider.future);
  final notebookCount = notebooksState.notebooks
      .where((n) => !n.isArchived)
      .length;

  // Wait for note stats to load
  final noteStats = await ref.watch(noteStatsProvider.future);
  // Use active count (exclude archived and trashed notes) to match what users see in UI
  final noteCount = noteStats.active;

  // Debug logging
  final log = AppLogger.get('VaultStats');
  log.debug('Vault: $vaultId');
  log.debug('Total notes: ${noteStats.total}');
  log.debug('Active notes: ${noteStats.active}');
  log.debug('Archived notes: ${noteStats.archived}');
  log.debug('Trashed notes: ${noteStats.trashed}');
  log.debug('Notebook count: $notebookCount');

  // Get last modified from the most recent note or notebook
  DateTime? lastModified;
  if (notebooksState.notebooks.isNotEmpty) {
    lastModified = notebooksState.notebooks
        .map((n) => n.modifiedAt)
        .reduce((a, b) => a.isAfter(b) ? a : b);
  }

  return VaultStats(
    noteCount: noteCount,
    notebookCount: notebookCount,
    lastModified: lastModified,
  );
});

/// Provider to count vaults in the workspace.
final vaultCountProvider = Provider<int>((ref) {
  final workspace = ref.watch(unlockedWorkspaceProvider);
  if (workspace == null) return 0;
  return workspace.keyring.vaults.length;
});

// ═══════════════════════════════════════════════════════════════════════════
// VAULT CREATION
// ═══════════════════════════════════════════════════════════════════════════

/// Result of vault creation operation.
class VaultCreationResult {
  final String vaultId;
  final String? error;

  VaultCreationResult.success(this.vaultId) : error = null;
  VaultCreationResult.failure(this.error) : vaultId = '';

  bool get isSuccess => error == null;
}

/// Notifier for creating new vaults.
///
/// This handles the full vault creation flow:
/// 1. Generate random vault key (32 bytes)
/// 2. Generate vault UUID
/// 3. Add key to workspace keyring
/// 4. Save updated keyring to disk
/// 5. Create vault directory and files via VaultService
/// 6. Select the newly created vault
///
/// Spec: docs/specs/spec-002-workspace-master-password.md (Section 3.3)
class VaultCreationNotifier
    extends StateNotifier<AsyncValue<VaultCreationResult?>> {
  final Ref _ref;

  VaultCreationNotifier(this._ref) : super(const AsyncValue.data(null));

  /// Creates a new vault with the given metadata.
  ///
  /// [name] - User-visible vault name (required)
  /// [description] - Optional vault description
  /// [icon] - Optional emoji icon
  /// [color] - Optional hex color (e.g., "4CAF50")
  ///
  /// Returns the vault ID on success, or an error message on failure.
  Future<VaultCreationResult> createVault({
    required String name,
    String? description,
    String? icon,
    String? color,
  }) async {
    state = const AsyncValue.loading();

    try {
      // 1. Get required dependencies
      final workspace = _ref.read(unlockedWorkspaceProvider);
      if (workspace == null) {
        throw StateError('Cannot create vault: workspace is locked');
      }

      final crypto = CryptoService.instance;
      final vaultService = _ref.read(vaultServiceProvider);
      final workspaceService = _ref.read(workspaceServiceProvider);

      // 2. Generate random vault key (32 bytes)
      final vaultKeyBytes = crypto.random.symmetricKey();
      final vaultKeyBase64 = base64Encode(vaultKeyBytes.unsafeBytes);

      // 3. Generate vault UUID
      final vaultId = const Uuid().v4();

      // 4. Add key to workspace keyring
      final updatedKeyring = workspace.keyring.addVault(
        vaultId,
        vaultKeyBase64,
      );

      // 5. Update workspace with new keyring
      // Note: UnlockedWorkspace.keyring is mutable, so we can update it in place
      // by creating a new workspace reference
      final updatedWorkspace = UnlockedWorkspace(
        muk: workspace.muk,
        keyring: updatedKeyring,
        rootPath: workspace.rootPath,
      );

      // 6. Save updated keyring to disk
      await workspaceService.saveKeyring(updatedWorkspace);

      // 7. Update the workspace provider with new keyring
      _ref.read(unlockedWorkspaceProvider.notifier).update(updatedWorkspace);

      // 8. Create vault directory and files
      final vaultPath = p.join(workspace.rootPath, 'vaults', vaultId);

      // Create VaultKey from the generated bytes
      final vaultKey = VaultKey(vaultKeyBytes);

      await vaultService.createVault(
        vaultPath: vaultPath,
        vaultKey: vaultKey,
        vaultId: vaultId,
        name: name,
        description: description,
        icon: icon,
        color: color,
      );

      // 9. Select the newly created vault
      _ref.read(selectedVaultIdProvider.notifier).selectVault(vaultId);

      // 10. Invalidate providers to reload data
      _ref.invalidate(availableVaultsProvider);
      _ref.invalidate(activeVaultMetadataProvider);
      _ref.invalidate(notebooksProvider);

      final result = VaultCreationResult.success(vaultId);
      state = AsyncValue.data(result);
      return result;
    } catch (e, stack) {
      final result = VaultCreationResult.failure(e.toString());
      state = AsyncValue.error(e, stack);
      return result;
    }
  }
}

/// Provider for vault creation operations.
final vaultCreationProvider =
    StateNotifierProvider<
      VaultCreationNotifier,
      AsyncValue<VaultCreationResult?>
    >((ref) {
      return VaultCreationNotifier(ref);
    });
