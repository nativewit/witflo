// ═══════════════════════════════════════════════════════════════════════════
// FYNDO - Zero-Trust Notes OS
// Workspace Provider - Riverpod state management for workspace
// ═══════════════════════════════════════════════════════════════════════════

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fyndo_app/core/workspace/workspace_config.dart';
import 'package:fyndo_app/core/workspace/workspace_service.dart';

part 'workspace_provider.g.dart';

/// State for the workspace.
///
/// Uses built_value for immutability and type safety (spec-003 compliance).
abstract class WorkspaceState
    implements Built<WorkspaceState, WorkspaceStateBuilder> {
  @BuiltValueField(wireName: 'config')
  WorkspaceConfig? get config;

  @BuiltValueField(wireName: 'isLoading')
  bool get isLoading;

  @BuiltValueField(wireName: 'error')
  String? get error;

  /// Vault paths in current workspace.
  @BuiltValueField(wireName: 'discoveredVaults')
  BuiltList<String>? get discoveredVaults;

  WorkspaceState._();
  factory WorkspaceState([void Function(WorkspaceStateBuilder) updates]) =
      _$WorkspaceState;

  /// Creates initial workspace state (no workspace configured).
  factory WorkspaceState.initial() => WorkspaceState(
    (b) => b
      ..config = null
      ..isLoading = false
      ..error = null
      ..discoveredVaults = null,
  );

  bool get hasWorkspace => config != null;
  String? get rootPath => config?.rootPath;
}

/// Notifier for workspace management.
class WorkspaceNotifier extends AsyncNotifier<WorkspaceState> {
  WorkspaceService? _service;

  @override
  Future<WorkspaceState> build() async {
    // Web platform doesn't support workspace management yet
    // Return a mock workspace state to skip onboarding
    if (kIsWeb) {
      return WorkspaceState(
        (b) => b
          ..config = WorkspaceConfig.create(
            rootPath: '/web-storage',
          ).toBuilder()
          ..isLoading = false,
      );
    }

    _service ??= WorkspaceService();
    return await _loadWorkspace();
  }

  Future<WorkspaceState> _loadWorkspace() async {
    try {
      final config = await _service!.loadWorkspaceConfig();

      if (config == null) {
        // No workspace configured yet
        return WorkspaceState.initial();
      }

      // Validate that workspace still exists
      if (!await _service!.isValidWorkspace(config.rootPath)) {
        // Workspace no longer valid (folder deleted, etc.)
        return WorkspaceState(
          (b) => b
            ..isLoading = false
            ..error =
                'Workspace directory no longer accessible: ${config.rootPath}',
        );
      }

      // Discover vaults in the workspace
      final vaults = await _service!.discoverVaults(config.rootPath);

      // Update last accessed timestamp
      final updatedConfig = config.touch();
      await _service!.saveWorkspaceConfig(updatedConfig);

      return WorkspaceState(
        (b) => b
          ..config = updatedConfig.toBuilder()
          ..isLoading = false
          ..discoveredVaults = BuiltList<String>(vaults).toBuilder(),
      );
    } catch (e) {
      return WorkspaceState(
        (b) => b
          ..isLoading = false
          ..error = e.toString(),
      );
    }
  }

  /// Initializes a new workspace at the given path.
  ///
  /// DEPRECATED in spec-002: Workspace initialization now requires a master password
  /// and returns an UnlockedWorkspace instead of WorkspaceConfig.
  ///
  /// Use workspaceService.initializeWorkspace() directly instead:
  /// ```dart
  /// final workspaceService = ref.read(workspaceServiceProvider);
  /// final unlocked = await workspaceService.initializeWorkspace(
  ///   rootPath: path,
  ///   masterPassword: password,
  /// );
  /// ref.read(unlockedWorkspaceProvider.notifier).unlock(unlocked);
  /// ```
  ///
  /// This method is kept for backward compatibility but should not be used.
  @Deprecated('Use workspaceService.initializeWorkspace with master password')
  Future<void> initializeWorkspace(String rootPath) async {
    throw UnsupportedError(
      'initializeWorkspace without password is deprecated in spec-002. '
      'Use workspaceService.initializeWorkspace(rootPath, masterPassword) instead. '
      'See: docs/specs/spec-002-workspace-master-password.md',
    );
  }

  /// Switches to an existing workspace.
  ///
  /// Validates workspace and adds current to recent workspaces.
  Future<void> switchWorkspace(String newRootPath) async {
    state = AsyncValue.data(WorkspaceState((b) => b..isLoading = true));

    try {
      final config = await _service!.switchWorkspace(newRootPath);
      final vaults = await _service!.discoverVaults(newRootPath);

      state = AsyncValue.data(
        WorkspaceState(
          (b) => b
            ..config = config.toBuilder()
            ..isLoading = false
            ..discoveredVaults = BuiltList<String>(vaults).toBuilder(),
        ),
      );
    } catch (e) {
      state = AsyncValue.data(
        WorkspaceState(
          (b) => b
            ..isLoading = false
            ..error = e.toString(),
        ),
      );
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
      final vaults = await _service!.discoverVaults(
        currentState!.config!.rootPath,
      );

      state = AsyncValue.data(
        currentState.rebuild(
          (b) => b..discoveredVaults = BuiltList<String>(vaults).toBuilder(),
        ),
      );
    } catch (e) {
      state = AsyncValue.data(
        currentState!.rebuild((b) => b..error = e.toString()),
      );
    }
  }

  /// Opens folder picker and returns selected path (or null if cancelled).
  Future<String?> pickWorkspaceFolder() async {
    return await _service!.pickWorkspaceFolder();
  }

  /// Returns the default workspace directory for the current platform.
  Future<String> getDefaultWorkspaceDirectory() async {
    return await _service!.getDefaultWorkspaceDirectory();
  }

  /// Returns the path where a new vault should be created.
  String getNewVaultPath(String vaultId) {
    final currentState = state.valueOrNull;
    if (currentState?.config == null) {
      throw WorkspaceException('No workspace configured');
    }

    return _service!.getNewVaultPath(currentState!.config!.rootPath, vaultId);
  }
}

/// Provider for workspace state management.
final workspaceProvider =
    AsyncNotifierProvider<WorkspaceNotifier, WorkspaceState>(
      () => WorkspaceNotifier(),
    );
