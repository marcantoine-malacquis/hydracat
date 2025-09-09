import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing theme persistence using SharedPreferences.
class ThemeService {
  static const String _themeKey = 'app_theme_mode';

  /// Saves the theme mode to local storage.
  static Future<void> saveThemeMode(ThemeMode themeMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, themeMode.name);
  }

  /// Loads the theme mode from local storage.
  /// Returns [ThemeMode.light] as default if no preference is saved.
  static Future<ThemeMode> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeString = prefs.getString(_themeKey);

    if (themeModeString == null) {
      return ThemeMode.light; // Default to light mode
    }

    return ThemeMode.values.firstWhere(
      (mode) => mode.name == themeModeString,
      orElse: () => ThemeMode.light,
    );
  }

  /// Clears the saved theme preference.
  static Future<void> clearThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_themeKey);
  }
}
