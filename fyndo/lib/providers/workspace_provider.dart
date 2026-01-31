// ═══════════════════════════════════════════════════════════════════════════
// FYNDO - Zero-Trust Notes OS
// Workspace Provider - Riverpod state management for workspace
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fyndo_app/core/workspace/workspace_config.dart';
import 'package:fyndo_app/core/workspace/workspace_service.dart';

/// State for the workspace.
class WorkspaceState {
  final WorkspaceConfig? config;
  final bool isLoading;
  final String? error;
  final List<String>? discoveredVaults; // Vault paths in current workspace

  const WorkspaceState({
    this.config,
    this.isLoading = false,
    this.error,
    this.discoveredVaults,
  });

  WorkspaceState copyWith({
    WorkspaceConfig? config,
    bool? isLoading,
    String? error,
    List<String>? discoveredVaults,
  }) {
    return WorkspaceState(
      config: config ?? this.config,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      discoveredVaults: discoveredVaults ?? this.discoveredVaults,
    );
  }

  bool get hasWorkspace => config != null;
  String? get rootPath => config?.rootPath;
}

/// Notifier for workspace management.
class WorkspaceNotifier extends AsyncNotifier<WorkspaceState> {
  late final WorkspaceService _service;

  @override
  Future<WorkspaceState> build() async {
    // Web platform doesn't support workspace management yet
    // Return a mock workspace state to skip onboarding
    if (kIsWeb) {
      return WorkspaceState(
        config: WorkspaceConfig.create(rootPath: '/web-storage'),
      );
    }

    _service = WorkspaceService();
    return await _loadWorkspace();
  }

  Future<WorkspaceState> _loadWorkspace() async {
    try {
      final config = await _service.loadWorkspaceConfig();

      if (config == null) {
        // No workspace configured yet
        return const WorkspaceState();
      }

      // Validate that workspace still exists
      if (!await _service.isValidWorkspace(config.rootPath)) {
        // Workspace no longer valid (folder deleted, etc.)
        return WorkspaceState(
          error: 'Workspace directory no longer accessible: ${config.rootPath}',
        );
      }

      // Discover vaults in the workspace
      final vaults = await _service.discoverVaults(config.rootPath);

      // Update last accessed timestamp
      final updatedConfig = config.touch();
      await _service.saveWorkspaceConfig(updatedConfig);

      return WorkspaceState(config: updatedConfig, discoveredVaults: vaults);
    } catch (e) {
      return WorkspaceState(error: e.toString());
    }
  }

  /// Initializes a new workspace at the given path.
  ///
  /// Creates directory structure and marker files.
  Future<void> initializeWorkspace(String rootPath) async {
    state = const AsyncValue.data(WorkspaceState(isLoading: true));

    try {
      final config = await _service.initializeWorkspace(rootPath);
      final vaults = await _service.discoverVaults(rootPath);

      state = AsyncValue.data(
        WorkspaceState(config: config, discoveredVaults: vaults),
      );
    } catch (e) {
      state = AsyncValue.data(WorkspaceState(error: e.toString()));
      rethrow;
    }
  }

  /// Switches to an existing workspace.
  ///
  /// Validates workspace and adds current to recent workspaces.
  Future<void> switchWorkspace(String newRootPath) async {
    state = const AsyncValue.data(WorkspaceState(isLoading: true));

    try {
      final config = await _service.switchWorkspace(newRootPath);
      final vaults = await _service.discoverVaults(newRootPath);

      state = AsyncValue.data(
        WorkspaceState(config: config, discoveredVaults: vaults),
      );
    } catch (e) {
      state = AsyncValue.data(WorkspaceState(error: e.toString()));
      rethrow;
    }
  }

  /// Refreshes the list of discovered vaults in the current workspace.
  Future<void> refreshVaults() async {
    final currentState = state.valueOrNull;
    if (currentState?.config == null) {
      return; // No workspace to refresh
    }

    try {
      final vaults = await _service.discoverVaults(
        currentState!.config!.rootPath,
      );

      state = AsyncValue.data(currentState.copyWith(discoveredVaults: vaults));
    } catch (e) {
      state = AsyncValue.data(currentState!.copyWith(error: e.toString()));
    }
  }

  /// Opens folder picker and returns selected path (or null if cancelled).
  Future<String?> pickWorkspaceFolder() async {
    return await _service.pickWorkspaceFolder();
  }

  /// Returns the default workspace directory for the current platform.
  Future<String> getDefaultWorkspaceDirectory() async {
    return await _service.getDefaultWorkspaceDirectory();
  }

  /// Returns the path where a new vault should be created.
  String getNewVaultPath(String vaultId) {
    final currentState = state.valueOrNull;
    if (currentState?.config == null) {
      throw WorkspaceException('No workspace configured');
    }

    return _service.getNewVaultPath(currentState!.config!.rootPath, vaultId);
  }
}

/// Provider for workspace state management.
final workspaceProvider =
    AsyncNotifierProvider<WorkspaceNotifier, WorkspaceState>(
      () => WorkspaceNotifier(),
    );
