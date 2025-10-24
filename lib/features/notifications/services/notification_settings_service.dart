import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hydracat/features/notifications/models/notification_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for persisting notification settings to local storage.
///
/// Uses SharedPreferences to store settings per user (keyed by userId).
/// Settings persist across app restarts and survive logout (restored on
/// re-login). This supports multi-user scenarios where multiple accounts
/// may sign in on the same device.
///
/// Storage key format: `notif_settings_{userId}`
///
/// Example usage:
/// ```dart
/// // Load settings for a user
/// final settings = await NotificationSettingsService.loadSettings(userId);
///
/// // Save updated settings
/// await NotificationSettingsService.saveSettings(userId, settings);
///
/// // Clear settings on logout/delete account
/// await NotificationSettingsService.clearSettings(userId);
/// ```
class NotificationSettingsService {
  static const String _keyPrefix = 'notif_settings_';

  /// Loads notification settings for a specific user.
  ///
  /// Returns [NotificationSettings.defaults] if:
  /// - No settings have been saved for this user yet (new user)
  /// - Stored data is corrupted or invalid
  /// - Time format is invalid (replaced with default "22:00")
  ///
  /// Errors are logged in debug mode but don't throw exceptions,
  /// ensuring graceful degradation.
  static Future<NotificationSettings> loadSettings(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_keyPrefix$userId';
      final jsonString = prefs.getString(key);

      if (jsonString == null) {
        // No settings stored, return defaults for new user
        if (kDebugMode) {
          debugPrint(
            '[NotificationSettings] No settings found for user $userId, '
            'using defaults',
          );
        }
        return NotificationSettings.defaults();
      }

      // Parse JSON and create settings instance
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final settings = NotificationSettings.fromJson(json);

      // Validate time format, use default if invalid
      if (!NotificationSettings.isValidTime(settings.endOfDayTime)) {
        if (kDebugMode) {
          debugPrint(
            '[NotificationSettings] Invalid endOfDayTime format: '
            '${settings.endOfDayTime}, replacing with default "22:00"',
          );
        }
        return settings.copyWith(endOfDayTime: '22:00');
      }

      if (kDebugMode) {
        debugPrint(
          '[NotificationSettings] Loaded settings for user $userId: $settings',
        );
      }

      return settings;
    } on Exception catch (e, stackTrace) {
      // Corrupted data or parsing error, return defaults
      if (kDebugMode) {
        debugPrint(
          '[NotificationSettings] Failed to load settings for user $userId: '
          '$e',
        );
        debugPrint('Stack trace: $stackTrace');
        debugPrint('Returning default settings');
      }
      return NotificationSettings.defaults();
    }
  }

  /// Saves notification settings for a specific user.
  ///
  /// Validates that endOfDayTime is in valid format before saving.
  /// Throws ArgumentError if time format is invalid.
  ///
  /// Settings are immediately persisted to SharedPreferences and will
  /// survive app restarts.
  static Future<void> saveSettings(
    String userId,
    NotificationSettings settings,
  ) async {
    // Validate time format before saving
    if (!NotificationSettings.isValidTime(settings.endOfDayTime)) {
      throw ArgumentError(
        'Invalid endOfDayTime format: ${settings.endOfDayTime}. '
        'Expected "HH:mm" format (e.g., "22:00")',
      );
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_keyPrefix$userId';
      final jsonString = jsonEncode(settings.toJson());
      await prefs.setString(key, jsonString);

      if (kDebugMode) {
        debugPrint(
          '[NotificationSettings] Saved settings for user $userId: $settings',
        );
      }
    } on Exception catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          '[NotificationSettings] Failed to save settings for user $userId: '
          '$e',
        );
        debugPrint('Stack trace: $stackTrace');
      }
      rethrow;
    }
  }

  /// Clears notification settings for a specific user.
  ///
  /// Call this when:
  /// - User logs out (optional - settings can persist for better UX)
  /// - User deletes their account
  /// - "Delete All Data" debug action is triggered
  ///
  /// Settings are permanently removed from SharedPreferences.
  static Future<void> clearSettings(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_keyPrefix$userId';
      await prefs.remove(key);

      if (kDebugMode) {
        debugPrint(
          '[NotificationSettings] Cleared settings for user $userId',
        );
      }
    } on Exception catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          '[NotificationSettings] Failed to clear settings for user $userId: '
          '$e',
        );
        debugPrint('Stack trace: $stackTrace');
      }
      // Don't rethrow - clearing settings is not critical
    }
  }

  /// Returns all stored settings keys (for debugging).
  ///
  /// Use this to audit which users have notification settings stored
  /// on the device. Useful for debugging multi-user scenarios.
  ///
  /// Example output: `['notif_settings_user123', 'notif_settings_user456']`
  static Future<List<String>> getAllSettingsKeys() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs
          .getKeys()
          .where((key) => key.startsWith(_keyPrefix))
          .toList();

      if (kDebugMode) {
        debugPrint(
          '[NotificationSettings] Found ${keys.length} stored settings: $keys',
        );
      }

      return keys;
    } on Exception catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          '[NotificationSettings] Failed to get all settings keys: $e',
        );
        debugPrint('Stack trace: $stackTrace');
      }
      return [];
    }
  }
}
