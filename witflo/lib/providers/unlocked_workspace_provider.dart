// ═══════════════════════════════════════════════════════════════════════════
// WITFLO - Zero-Trust Notes OS
// UnlockedWorkspaceProvider - Riverpod state management for workspace session
// ═══════════════════════════════════════════════════════════════════════════
//
// SESSION LIFECYCLE:
// 1. LOCKED: state = null, user must enter password
// 2. UNLOCK: password → MUK → decrypt keyring → state = UnlockedWorkspace
// 3. ACTIVE: UnlockedWorkspace cached, keys in memory for fast access
// 4. LOCK: dispose UnlockedWorkspace, zeroize all keys, state = null
//
// AUTO-LOCK TRIGGERS:
// - Explicit lock button
// - App goes to background (iOS/Android)
// - Configurable idle timer (5/15/30/60 min)
// - App is about to terminate
//
// SECURITY INVARIANTS:
// - All keys zeroized on lock
// - Never serialize UnlockedWorkspace
// - Timer reset on user activity
//
// FILE MONITORING (Phase 5):
// - WorkspaceFileWatcher: monitors workspace-level files
// - VaultFileWatcher: monitors vault-level files for each unlocked vault
// - VaultReloadService: reloads encrypted indices when files change
// - Provider invalidation: triggers UI updates automatically
//
// Spec: docs/specs/spec-002-workspace-master-password.md (Section 3)
// Spec: docs/specs/spec-005-live-sync.md (File monitoring)
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:witflo_app/core/logging/app_logger.dart';
import 'package:witflo_app/core/vault/vault_file_watcher.dart';
import 'package:witflo_app/core/vault/vault_reload_service.dart';
import 'package:witflo_app/core/workspace/unlocked_workspace.dart';
import 'package:witflo_app/core/workspace/workspace_file_watcher.dart';
import 'package:witflo_app/providers/auto_lock_settings_provider.dart';
import 'package:witflo_app/providers/crypto_providers.dart';
import 'package:witflo_app/providers/note_providers.dart';
import 'package:witflo_app/providers/notebook_providers.dart';

/// Provider for unlocked workspace session state.
///
/// This provider manages the lifecycle of an unlocked workspace, including
/// auto-lock functionality based on app lifecycle and idle timer.
///
/// **State**:
/// - `null`: Workspace is locked (user must unlock with password)
/// - `UnlockedWorkspace`: Workspace is unlocked and keys are in memory
///
/// **Usage**:
/// ```dart
/// // Check if locked
/// final workspace = ref.watch(unlockedWorkspaceProvider);
/// if (workspace == null) {
///   // Show unlock screen
/// }
///
/// // Unlock workspace
/// ref.read(unlockedWorkspaceProvider.notifier).unlock(workspace);
///
/// // Lock workspace
/// ref.read(unlockedWorkspaceProvider.notifier).lock();
/// ```
final unlockedWorkspaceProvider =
    StateNotifierProvider<UnlockedWorkspaceNotifier, UnlockedWorkspace?>(
      (ref) => UnlockedWorkspaceNotifier(ref),
    );

/// State notifier for workspace session management.
///
/// This notifier:
/// 1. Tracks the current unlocked workspace (null = locked)
/// 2. Implements auto-lock on app lifecycle changes
/// 3. Implements auto-lock on idle timer
/// 4. Ensures proper cleanup of cryptographic material
/// 5. Monitors file changes and reloads indices automatically (Phase 5)
class UnlockedWorkspaceNotifier extends StateNotifier<UnlockedWorkspace?>
    with WidgetsBindingObserver {
  final Ref _ref;
  Timer? _idleTimer;
  DateTime? _lastActivityTime;

  // File monitoring (Phase 5)
  final _log = AppLogger.get('UnlockedWorkspaceNotifier');
  WorkspaceFileWatcher? _workspaceWatcher;
  final Map<String, VaultFileWatcher> _vaultWatchers = {};
  VaultReloadService? _reloadService;

  UnlockedWorkspaceNotifier(this._ref) : super(null) {
    // Register as app lifecycle observer
    WidgetsBinding.instance.addObserver(this);
  }

  /// Unlocks the workspace and starts auto-lock monitoring.
  ///
  /// This caches the unlocked workspace and starts the idle timer if enabled.
  ///
  /// **SECURITY**: The workspace ownership is transferred to this notifier.
  /// When locking, the workspace will be disposed automatically.
  ///
  /// [workspace] - The unlocked workspace (must not be disposed)
  Future<void> unlock(UnlockedWorkspace workspace) async {
    _log.debug('unlock() called');
    // Lock any existing workspace first
    if (state != null) {
      _log.debug('Locking existing workspace first');
      await lock();
    }

    _log.debug('Setting state to unlocked workspace');
    state = workspace;
    _lastActivityTime = DateTime.now();
    _log.debug(
      'State set! state is now: ${state != null ? "NOT NULL" : "NULL"}',
    );

    // Initialize file monitoring (Phase 5)
    await _startFileMonitoring(workspace);

    // Start idle timer if auto-lock is enabled
    _startIdleTimer();
    _log.debug('unlock() completed');
  }

  /// Updates the workspace with a new instance (e.g., after keyring changes).
  ///
  /// This is used when the keyring is modified (e.g., new vault added) but
  /// we don't want to fully lock/unlock. The old workspace is NOT disposed
  /// because the MUK is shared - caller must ensure proper lifecycle.
  ///
  /// [workspace] - The updated workspace with new keyring
  void update(UnlockedWorkspace workspace) {
    _log.debug('update() called');
    // Don't dispose the old workspace - the MUK is the same object
    // Just replace the state with the updated workspace
    state = workspace;
    _lastActivityTime = DateTime.now();
    _log.debug('update() completed');
  }

  /// Locks the workspace by disposing all cryptographic material.
  ///
  /// This:
  /// 1. Disposes the UnlockedWorkspace (zeroizes MUK and vault keys)
  /// 2. Sets state to null (locked)
  /// 3. Cancels idle timer
  /// 4. Stops all file monitoring (Phase 5)
  ///
  /// After calling this, user must unlock again with password.
  Future<void> lock() async {
    _stopIdleTimer();

    // Stop file monitoring (Phase 5)
    await _stopFileMonitoring();

    // Dispose workspace (zeroizes all keys)
    state?.dispose();
    state = null;

    _lastActivityTime = null;
  }

  /// Checks if workspace is currently locked.
  bool get isLocked => state == null;

  /// Checks if workspace is currently unlocked.
  bool get isUnlocked => state != null;

  /// Registers a vault for file monitoring.
  ///
  /// This should be called by vault providers when a vault is accessed.
  /// The watcher will monitor vault-level files and trigger reloads/invalidations.
  ///
  /// [vault] - The unlocked vault to monitor
  Future<void> registerVaultWatcher(dynamic vault) async {
    if (state == null || _reloadService == null) {
      _log.warning('Cannot register vault watcher: workspace not unlocked');
      return;
    }

    final vaultId = vault.header.vaultId as String;

    // Skip if already watching
    if (_vaultWatchers.containsKey(vaultId)) {
      _log.debug('Vault $vaultId already being monitored');
      return;
    }

    try {
      _log.info('Starting file watcher for vault: $vaultId');

      final watcher = VaultFileWatcher(
        vault: vault,
        onNotesIndexChange: () => _handleNotesIndexChange(vaultId, vault),
        onNotebooksIndexChange: () =>
            _handleNotebooksIndexChange(vaultId, vault),
        onTagsIndexChange: () => _handleTagsIndexChange(vaultId),
        onSyncCursorChange: () => _handleSyncCursorChange(vaultId),
        onSyncOperation: (opPath) => _handleSyncOperation(vaultId, opPath),
      );

      await watcher.startWatching();
      _vaultWatchers[vaultId] = watcher;

      _log.info('Vault watcher started successfully for: $vaultId');
    } catch (e, stack) {
      _log.error(
        'Failed to start vault watcher for $vaultId',
        error: e,
        stackTrace: stack,
      );
    }
  }

  /// Resets the idle timer on user activity.
  ///
  /// This should be called whenever the user interacts with the app to
  /// prevent auto-lock during active use.
  ///
  /// **Note**: In production, this could be hooked into global gesture
  /// detection or route navigation observers.
  void resetIdleTimer() {
    if (state == null) {
      return; // No workspace to keep alive
    }

    _lastActivityTime = DateTime.now();

    // Restart timer
    _startIdleTimer();
  }

  /// Starts the idle timer based on current settings.
  ///
  /// The timer automatically locks the workspace after the configured
  /// idle duration has elapsed.
  void _startIdleTimer() {
    _stopIdleTimer(); // Cancel any existing timer

    final settings = _ref.read(autoLockSettingsProvider);

    if (!settings.enabled || state == null) {
      return; // Auto-lock disabled or no workspace
    }

    _idleTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      final now = DateTime.now();
      final lastActivity = _lastActivityTime ?? now;
      final idleDuration = now.difference(lastActivity);

      if (idleDuration >= settings.duration) {
        // Idle timeout reached, lock workspace
        lock();
      }
    });
  }

  /// Stops the idle timer.
  void _stopIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = null;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // WidgetsBindingObserver - App Lifecycle Handling
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    final settings = _ref.read(autoLockSettingsProvider);

    if (!settings.lockOnBackground) {
      return; // Background lock disabled
    }

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        // App going to background or being terminated
        lock();
        break;

      case AppLifecycleState.resumed:
        // App coming back from background
        // Reset activity time to prevent immediate lock
        _lastActivityTime = DateTime.now();
        break;

      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        // App inactive but not backgrounded (e.g., system dialog)
        // Don't lock yet
        break;
    }
  }

  @override
  void dispose() {
    // Clean up
    _stopIdleTimer();
    WidgetsBinding.instance.removeObserver(this);

    // Stop file monitoring (must be sync, so we don't await)
    _stopFileMonitoring();

    // Dispose workspace if still unlocked
    state?.dispose();

    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // File Monitoring (Phase 5)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Starts file monitoring for workspace and all vaults.
  Future<void> _startFileMonitoring(UnlockedWorkspace workspace) async {
    try {
      _log.info('Starting file monitoring...');

      // Initialize reload service
      final crypto = _ref.read(cryptoServiceProvider);
      _reloadService = VaultReloadService(crypto: crypto);
      _log.debug('VaultReloadService initialized');

      // Start workspace-level watcher
      _workspaceWatcher = WorkspaceFileWatcher(
        workspaceRoot: workspace.rootPath,
        onMetadataChange: _handleWorkspaceMetadataChange,
        onKeyringChange: _handleKeyringChange,
        onVaultDiscovered: _handleVaultDiscovered,
      );
      await _workspaceWatcher!.startWatching();
      _log.info('WorkspaceFileWatcher started');

      // Note: Vault watchers will be started lazily when vaults are accessed
      // via registerVaultWatcher() to avoid circular dependencies
      _log.info('File monitoring initialized successfully');
    } catch (e, stack) {
      _log.error(
        'Failed to start file monitoring',
        error: e,
        stackTrace: stack,
      );
      // Don't throw - file monitoring is not critical for basic functionality
    }
  }

  /// Stops all file monitoring.
  Future<void> _stopFileMonitoring() async {
    try {
      _log.debug('Stopping file monitoring...');

      // Stop workspace watcher
      _workspaceWatcher?.dispose();
      _workspaceWatcher = null;

      // Stop all vault watchers
      for (final watcher in _vaultWatchers.values) {
        watcher.dispose();
      }
      _vaultWatchers.clear();

      // Clear reload service
      _reloadService = null;

      _log.info('File monitoring stopped');
    } catch (e, stack) {
      _log.error('Error stopping file monitoring', error: e, stackTrace: stack);
    }
  }

  /// Handles workspace metadata file changes.
  Future<void> _handleWorkspaceMetadataChange() async {
    _log.info('Workspace metadata changed externally');
    // TODO: Invalidate workspace metadata provider when it exists
    // For now, just log the event
  }

  /// Handles keyring file changes (CRITICAL).
  Future<void> _handleKeyringChange() async {
    _log.warning('Keyring changed externally - workspace must be re-unlocked');
    // TODO: Show notification to user
    // For now, lock the workspace to force re-unlock
    await lock();
  }

  /// Handles discovery of new vaults.
  Future<void> _handleVaultDiscovered(String vaultId) async {
    _log.info('New vault discovered: $vaultId');
    // TODO: Invalidate vault registry provider
    // For now, just log the event
  }

  /// Handles notes index file changes.
  Future<void> _handleNotesIndexChange(String vaultId, dynamic vault) async {
    _log.info('Notes index changed for vault: $vaultId');

    try {
      // Get the note repository - it uses the active vault automatically
      final noteRepo = await _ref.read(noteRepositoryProvider.future);

      // Reload the notes index from disk
      final success = await _reloadService!.reloadNotesIndex(
        vault,
        noteRepo.metadataCache,
      );

      if (success) {
        _log.info('Notes index reloaded successfully for vault: $vaultId');

        // The repository's metadata cache has been updated by reloadNotesIndex.
        // Providers that watch the repository will automatically rebuild on next access.
        // We don't need to explicitly invalidate them here to avoid circular dependency issues.

        _log.debug(
          'Notes index reloaded, providers will rebuild on next access',
        );
      } else {
        _log.warning('Failed to reload notes index for vault: $vaultId');
      }
    } catch (e, stack) {
      _log.error(
        'Error handling notes index change for vault: $vaultId',
        error: e,
        stackTrace: stack,
      );
    }
  }

  /// Handles notebooks index file changes.
  Future<void> _handleNotebooksIndexChange(
    String vaultId,
    dynamic vault,
  ) async {
    _log.info('Notebooks index changed for vault: $vaultId');

    try {
      // Get the notebook repository - it uses the active vault automatically
      final notebookRepo = await _ref.read(notebookRepositoryProvider.future);

      // Reload the notebooks index from disk
      final success = await _reloadService!.reloadNotebooksIndex(
        vault,
        notebookRepo.notebookCache,
      );

      if (success) {
        _log.info('Notebooks index reloaded successfully for vault: $vaultId');

        // The repository's notebook cache has been updated by reloadNotebooksIndex.
        // Providers that watch the repository will automatically rebuild on next access.
        // We don't need to explicitly invalidate them here to avoid circular dependency issues.

        _log.debug(
          'Notebooks index reloaded, providers will rebuild on next access',
        );
      } else {
        _log.warning('Failed to reload notebooks index for vault: $vaultId');
      }
    } catch (e, stack) {
      _log.error(
        'Error handling notebooks index change for vault: $vaultId',
        error: e,
        stackTrace: stack,
      );
    }
  }

  /// Handles tags index file changes.
  Future<void> _handleTagsIndexChange(String vaultId) async {
    _log.info('Tags index changed for vault: $vaultId');
    // TODO: Reload tags when tag system is implemented
  }

  /// Handles sync cursor file changes.
  Future<void> _handleSyncCursorChange(String vaultId) async {
    _log.debug('Sync cursor changed for vault: $vaultId');
    // TODO: Trigger sync when sync system is implemented
  }

  /// Handles new sync operations.
  Future<void> _handleSyncOperation(String vaultId, String opPath) async {
    _log.info('New sync operation detected: $opPath');

    try {
      // TODO: Implement full sync operation application in Phase 6
      // For now, this is a placeholder that will be completed when:
      // 1. SyncService is integrated with providers
      // 2. Encrypted operation format is finalized
      // 3. Full CRDT conflict resolution is tested

      _log.debug('Sync operation handling not fully implemented yet: $opPath');

      // The operation file will be picked up by the next sync() call
      // when SyncService.sync() is triggered manually or on a schedule
    } catch (e, stack) {
      _log.error(
        'Error handling sync operation',
        error: e.toString(),
        stackTrace: stack,
      );
    }
  }
}
