// ═══════════════════════════════════════════════════════════════════════════
// WITFLO - Zero-Trust Notes OS
// Vault Registry - Manage Multiple Vaults
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:witflo_app/platform/platform.dart';
import 'package:witflo_app/platform/platform_init.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Metadata for a registered vault.
class VaultInfo {
  final String id;
  final String name;
  final String path;
  final DateTime createdAt;
  final DateTime? lastAccessedAt;
  final bool isDefault;

  const VaultInfo({
    required this.id,
    required this.name,
    required this.path,
    required this.createdAt,
    this.lastAccessedAt,
    this.isDefault = false,
  });

  VaultInfo copyWith({
    String? id,
    String? name,
    String? path,
    DateTime? createdAt,
    DateTime? lastAccessedAt,
    bool? isDefault,
  }) {
    return VaultInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      createdAt: createdAt ?? this.createdAt,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'path': path,
    'createdAt': createdAt.toIso8601String(),
    'lastAccessedAt': lastAccessedAt?.toIso8601String(),
    'isDefault': isDefault,
  };

  factory VaultInfo.fromJson(Map<String, dynamic> json) => VaultInfo(
    id: json['id'] as String,
    name: json['name'] as String,
    path: json['path'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    lastAccessedAt: json['lastAccessedAt'] != null
        ? DateTime.parse(json['lastAccessedAt'] as String)
        : null,
    isDefault: json['isDefault'] as bool? ?? false,
  );
}

/// State for the vault registry.
class VaultRegistryState {
  final List<VaultInfo> vaults;
  final bool isLoading;
  final String? error;

  const VaultRegistryState({
    this.vaults = const [],
    this.isLoading = false,
    this.error,
  });

  VaultRegistryState copyWith({
    List<VaultInfo>? vaults,
    bool? isLoading,
    String? error,
  }) {
    return VaultRegistryState(
      vaults: vaults ?? this.vaults,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  VaultInfo? get defaultVault {
    try {
      return vaults.firstWhere((v) => v.isDefault);
    } catch (_) {
      return vaults.isNotEmpty ? vaults.first : null;
    }
  }
}

/// Notifier for vault registry management.
class VaultRegistryNotifier extends AsyncNotifier<VaultRegistryState> {
  static const _storageKey = 'witflo_vault_registry';
  static const _oldStorageKey = 'fyndo_vault_registry'; // For migration

  @override
  Future<VaultRegistryState> build() async {
    return _loadRegistry();
  }

  Future<VaultRegistryState> _loadRegistry() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var jsonStr = prefs.getString(_storageKey);

      // Migration: try old Fyndo key if new key not found
      if (jsonStr == null) {
        jsonStr = prefs.getString(_oldStorageKey);
        if (jsonStr != null) {
          // Migrate to new key
          await prefs.setString(_storageKey, jsonStr);
          await prefs.remove(_oldStorageKey);
        }
      }

      if (jsonStr == null) {
        // Check if there's a default vault from the old system
        final defaultPath = await getAppDocumentsPath();
        final defaultVault = await _checkExistingVault(defaultPath);

        if (defaultVault != null) {
          // Migrate existing vault to registry
          final vaults = [defaultVault];
          await _saveRegistry(vaults);
          return VaultRegistryState(vaults: vaults);
        }

        return const VaultRegistryState();
      }

      final List<dynamic> jsonList = jsonDecode(jsonStr);
      final vaults = jsonList
          .map((j) => VaultInfo.fromJson(j as Map<String, dynamic>))
          .toList();

      return VaultRegistryState(vaults: vaults);
    } catch (e) {
      return VaultRegistryState(error: e.toString());
    }
  }

  Future<VaultInfo?> _checkExistingVault(String path) async {
    try {
      final storage = storageProvider;
      final headerPath = '$path/vault.header';
      final exists = await storage.exists(headerPath);

      if (exists) {
        return VaultInfo(
          id: 'default',
          name: 'My Vault',
          path: path,
          createdAt: DateTime.now(),
          isDefault: true,
        );
      }
    } catch (_) {}
    return null;
  }

  Future<void> _saveRegistry(List<VaultInfo> vaults) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(vaults.map((v) => v.toJson()).toList());
    await prefs.setString(_storageKey, jsonStr);
  }

  /// Registers a new vault.
  Future<VaultInfo> registerVault({
    required String name,
    required String path,
    bool setAsDefault = false,
  }) async {
    final currentState = state.valueOrNull ?? const VaultRegistryState();
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    final vault = VaultInfo(
      id: id,
      name: name,
      path: path,
      createdAt: DateTime.now(),
      isDefault: setAsDefault || currentState.vaults.isEmpty,
    );

    List<VaultInfo> updatedVaults;
    if (vault.isDefault) {
      // Clear default from other vaults
      updatedVaults = currentState.vaults
          .map((v) => v.copyWith(isDefault: false))
          .toList();
    } else {
      updatedVaults = List.from(currentState.vaults);
    }
    updatedVaults.add(vault);

    await _saveRegistry(updatedVaults);
    state = AsyncValue.data(currentState.copyWith(vaults: updatedVaults));

    return vault;
  }

  /// Updates a vault's metadata.
  Future<void> updateVault(VaultInfo vault) async {
    final currentState = state.valueOrNull ?? const VaultRegistryState();
    final updatedVaults = currentState.vaults
        .map((v) => v.id == vault.id ? vault : v)
        .toList();

    await _saveRegistry(updatedVaults);
    state = AsyncValue.data(currentState.copyWith(vaults: updatedVaults));
  }

  /// Sets a vault as default.
  Future<void> setDefaultVault(String id) async {
    final currentState = state.valueOrNull ?? const VaultRegistryState();
    final updatedVaults = currentState.vaults.map((v) {
      return v.copyWith(isDefault: v.id == id);
    }).toList();

    await _saveRegistry(updatedVaults);
    state = AsyncValue.data(currentState.copyWith(vaults: updatedVaults));
  }

  /// Records vault access time.
  Future<void> recordAccess(String id) async {
    final currentState = state.valueOrNull ?? const VaultRegistryState();
    final updatedVaults = currentState.vaults.map((v) {
      if (v.id == id) {
        return v.copyWith(lastAccessedAt: DateTime.now());
      }
      return v;
    }).toList();

    await _saveRegistry(updatedVaults);
    state = AsyncValue.data(currentState.copyWith(vaults: updatedVaults));
  }

  /// Removes a vault from the registry (does not delete files).
  Future<void> unregisterVault(String id) async {
    final currentState = state.valueOrNull ?? const VaultRegistryState();
    final updatedVaults = currentState.vaults.where((v) => v.id != id).toList();

    // If we removed the default vault, set a new default
    if (updatedVaults.isNotEmpty && !updatedVaults.any((v) => v.isDefault)) {
      updatedVaults[0] = updatedVaults[0].copyWith(isDefault: true);
    }

    await _saveRegistry(updatedVaults);
    state = AsyncValue.data(currentState.copyWith(vaults: updatedVaults));
  }

  /// Deletes a vault and its files.
  Future<void> deleteVault(String id) async {
    final currentState = state.valueOrNull ?? const VaultRegistryState();
    final vault = currentState.vaults.firstWhere((v) => v.id == id);

    // Delete vault files
    try {
      final storage = storageProvider;
      await storage.deleteDirectory(vault.path);
    } catch (_) {
      // Ignore file deletion errors
    }

    await unregisterVault(id);
  }

  /// Renames a vault.
  Future<void> renameVault(String id, String newName) async {
    final currentState = state.valueOrNull ?? const VaultRegistryState();
    final vault = currentState.vaults.firstWhere((v) => v.id == id);
    await updateVault(vault.copyWith(name: newName));
  }

  /// Refreshes the registry.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = AsyncValue.data(await _loadRegistry());
  }

  /// Loads vaults from a workspace directory.
  ///
  /// Discovers all vaults in the workspace's vaults/ subdirectory and
  /// registers them in the vault registry. Existing vaults are preserved.
  ///
  /// [workspaceRoot] - Absolute path to the workspace root directory
  /// [vaultPaths] - List of discovered vault paths from WorkspaceService
  ///
  /// Usage:
  /// ```dart
  /// final workspaceState = ref.read(workspaceProvider).value;
  /// if (workspaceState?.discoveredVaults != null) {
  ///   await ref.read(vaultRegistryProvider.notifier)
  ///     .loadFromWorkspace(
  ///       workspaceState.rootPath!,
  ///       workspaceState.discoveredVaults!,
  ///     );
  /// }
  /// ```
  Future<void> loadFromWorkspace(
    String workspaceRoot,
    List<String> vaultPaths,
  ) async {
    final currentState = state.valueOrNull ?? const VaultRegistryState();
    final existingVaults = Map.fromEntries(
      currentState.vaults.map((v) => MapEntry(v.path, v)),
    );

    final updatedVaults = <VaultInfo>[];

    // Add existing vaults that are still in the workspace
    for (final vault in currentState.vaults) {
      if (vaultPaths.contains(vault.path)) {
        updatedVaults.add(vault);
      }
    }

    // Add new vaults discovered in workspace
    for (final vaultPath in vaultPaths) {
      if (!existingVaults.containsKey(vaultPath)) {
        // Extract vault ID from path (last component)
        final vaultId = p.basename(vaultPath);

        // Try to read vault name from vault.header
        String vaultName = 'Vault';
        try {
          final headerFile = File(p.join(vaultPath, 'vault.header'));
          if (await headerFile.exists()) {
            // Parse header for name (if we add that in the future)
            // For now, use vault ID as name
            vaultName = vaultId;
          }
        } catch (_) {
          vaultName = vaultId;
        }

        final vault = VaultInfo(
          id: vaultId,
          name: vaultName,
          path: vaultPath,
          createdAt: DateTime.now(),
          isDefault: updatedVaults.isEmpty, // First vault becomes default
        );

        updatedVaults.add(vault);
      }
    }

    await _saveRegistry(updatedVaults);
    state = AsyncValue.data(currentState.copyWith(vaults: updatedVaults));
  }
}

/// Provider for vault registry.
final vaultRegistryProvider =
    AsyncNotifierProvider<VaultRegistryNotifier, VaultRegistryState>(
      VaultRegistryNotifier.new,
    );
