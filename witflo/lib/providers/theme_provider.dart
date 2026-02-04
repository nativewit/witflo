// ═══════════════════════════════════════════════════════════════════════════
// WITFLO - Zero-Trust Notes OS
// Theme Provider - Manages theme mode (light/dark/system)
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for theme mode (light/dark/system).
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((
  ref,
) {
  return ThemeModeNotifier();
});

/// Notifier for managing theme mode.
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  static const String _key = 'theme_mode';

  ThemeModeNotifier() : super(ThemeMode.system) {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final modeString = prefs.getString(_key);

    if (modeString != null) {
      state = ThemeMode.values.firstWhere(
        (mode) => mode.toString() == modeString,
        orElse: () => ThemeMode.system,
      );
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.toString());
  }
}
