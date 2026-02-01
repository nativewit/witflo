// ═══════════════════════════════════════════════════════════════════════════
// FYNDO - Zero-Trust Notes OS
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
// Spec: docs/specs/spec-002-workspace-master-password.md (Section 3)
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fyndo_app/core/workspace/unlocked_workspace.dart';
import 'package:fyndo_app/providers/auto_lock_settings_provider.dart';

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
class UnlockedWorkspaceNotifier extends StateNotifier<UnlockedWorkspace?>
    with WidgetsBindingObserver {
  final Ref _ref;
  Timer? _idleTimer;
  DateTime? _lastActivityTime;

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
  void unlock(UnlockedWorkspace workspace) {
    print('[UnlockedWorkspaceProvider] DEBUG: unlock() called');
    // Lock any existing workspace first
    if (state != null) {
      print(
        '[UnlockedWorkspaceProvider] DEBUG: Locking existing workspace first',
      );
      lock();
    }

    print(
      '[UnlockedWorkspaceProvider] DEBUG: Setting state to unlocked workspace',
    );
    state = workspace;
    _lastActivityTime = DateTime.now();
    print(
      '[UnlockedWorkspaceProvider] DEBUG: State set! state is now: ${state != null ? "NOT NULL" : "NULL"}',
    );

    // Start idle timer if auto-lock is enabled
    _startIdleTimer();
    print('[UnlockedWorkspaceProvider] DEBUG: unlock() completed');
  }

  /// Locks the workspace by disposing all cryptographic material.
  ///
  /// This:
  /// 1. Disposes the UnlockedWorkspace (zeroizes MUK and vault keys)
  /// 2. Sets state to null (locked)
  /// 3. Cancels idle timer
  ///
  /// After calling this, user must unlock again with password.
  void lock() {
    _stopIdleTimer();

    // Dispose workspace (zeroizes all keys)
    state?.dispose();
    state = null;

    _lastActivityTime = null;
  }

  /// Checks if workspace is currently locked.
  bool get isLocked => state == null;

  /// Checks if workspace is currently unlocked.
  bool get isUnlocked => state != null;

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

    // Dispose workspace if still unlocked
    state?.dispose();

    super.dispose();
  }
}
