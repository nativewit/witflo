// ═══════════════════════════════════════════════════════════════════════════
// FYNDO - Zero-Trust Notes OS
// AutoLockSettingsProvider - Riverpod state management for auto-lock settings
// ═══════════════════════════════════════════════════════════════════════════
//
// PERSISTENCE:
// Settings are stored in SharedPreferences as JSON for fast access.
//
// USAGE:
// ```dart
// // Read settings
// final settings = ref.watch(autoLockSettingsProvider);
//
// // Update settings
// ref.read(autoLockSettingsProvider.notifier).updateSettings(
//   AutoLockSettings.security,
// );
// ```
//
// Spec: docs/specs/spec-002-workspace-master-password.md (Section 3.5)
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fyndo_app/core/workspace/auto_lock_settings.dart';

/// SharedPreferences key for auto-lock settings.
const _kAutoLockSettingsKey = 'fyndo_auto_lock_settings';

/// Provider for auto-lock settings.
///
/// This provider:
/// 1. Loads settings from SharedPreferences on startup
/// 2. Provides current settings to the app
/// 3. Persists settings changes to SharedPreferences
///
/// **Default**: [AutoLockSettings.standard] if no settings saved.
final autoLockSettingsProvider =
    StateNotifierProvider<AutoLockSettingsNotifier, AutoLockSettings>(
      (ref) => AutoLockSettingsNotifier(),
    );

/// State notifier for auto-lock settings persistence.
class AutoLockSettingsNotifier extends StateNotifier<AutoLockSettings> {
  AutoLockSettingsNotifier() : super(AutoLockSettings.standard) {
    // Load settings asynchronously
    _loadSettings();
  }

  /// Loads settings from SharedPreferences.
  ///
  /// Falls back to [AutoLockSettings.standard] if no settings are saved or
  /// if there's an error loading.
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_kAutoLockSettingsKey);

      if (jsonString == null) {
        // No settings saved, use standard
        state = AutoLockSettings.standard;
        return;
      }

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      state = AutoLockSettings.fromJson(json);
    } catch (e) {
      // Error loading, fall back to standard
      state = AutoLockSettings.standard;
    }
  }

  /// Updates auto-lock settings and persists to SharedPreferences.
  ///
  /// [newSettings] - The new auto-lock settings to apply
  ///
  /// Returns a Future that completes when settings are persisted.
  Future<void> updateSettings(AutoLockSettings newSettings) async {
    // Update state immediately (optimistic update)
    state = newSettings;

    try {
      // Persist to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(newSettings.toJson());
      await prefs.setString(_kAutoLockSettingsKey, jsonString);
    } catch (e) {
      // Persistence failed, but state is still updated in memory
      // In production, you might want to show a warning to the user
    }
  }

  /// Resets settings to standard defaults.
  Future<void> resetToDefaults() async {
    await updateSettings(AutoLockSettings.standard);
  }

  /// Updates only the enabled flag.
  Future<void> setEnabled(bool enabled) async {
    await updateSettings(state.rebuild((b) => b..enabled = enabled));
  }

  /// Updates only the idle duration.
  ///
  /// [durationMinutes] - Duration in minutes (5, 15, 30, or 60)
  Future<void> setDuration(int durationMinutes) async {
    await updateSettings(
      state.rebuild((b) => b..durationSeconds = durationMinutes * 60),
    );
  }

  /// Updates only the lock-on-background flag.
  Future<void> setLockOnBackground(bool lockOnBackground) async {
    await updateSettings(
      state.rebuild((b) => b..lockOnBackground = lockOnBackground),
    );
  }
}
