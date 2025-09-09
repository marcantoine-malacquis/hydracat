import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/shared/services/theme_service.dart';

/// Notifier for managing theme mode state with persistence.
class ThemeNotifier extends StateNotifier<ThemeMode> {
  /// Creates a theme notifier with light mode as default.
  ThemeNotifier() : super(ThemeMode.light) {
    _loadThemeMode();
  }

  /// Loads the saved theme mode from storage.
  Future<void> _loadThemeMode() async {
    final themeMode = await ThemeService.loadThemeMode();
    state = themeMode;
  }

  /// Toggles between light and dark theme modes.
  Future<void> toggleTheme() async {
    final newThemeMode = state == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    await setThemeMode(newThemeMode);
  }

  /// Sets a specific theme mode.
  Future<void> setThemeMode(ThemeMode themeMode) async {
    state = themeMode;
    await ThemeService.saveThemeMode(themeMode);
  }

  /// Resets theme to light mode and clears saved preference.
  Future<void> resetToLight() async {
    state = ThemeMode.light;
    await ThemeService.clearThemeMode();
  }
}

/// Provider for theme mode state management.
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>(
  (ref) => ThemeNotifier(),
);
