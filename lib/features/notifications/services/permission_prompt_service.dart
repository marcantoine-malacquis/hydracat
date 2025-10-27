import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for tracking whether the notification permission pre-prompt
/// has been shown to a user.
///
/// Uses SharedPreferences to persist the "shown" state per user,
/// ensuring the permission pre-prompt is displayed proactively only once
/// after onboarding completion. This respects user agency and prevents
/// permission prompt fatigue.
///
/// Storage key format: `notif_permission_prompt_shown_{userId}`
///
/// Example usage:
/// ```dart
/// // Check if prompt has been shown before
/// final hasShown = await PermissionPromptService.hasShownPrompt(userId);
///
/// if (!hasShown) {
///   // Show the prompt
///   await showDialog(...);
///
///   // Mark as shown
///   await PermissionPromptService.markPromptAsShown(userId);
/// }
/// ```
class PermissionPromptService {
  static const String _keyPrefix = 'notif_permission_prompt_shown_';

  /// Checks whether the permission pre-prompt has been shown to a user.
  ///
  /// Returns `true` if the prompt has been displayed before (proactively),
  /// `false` if it hasn't been shown yet.
  ///
  /// This check is used to determine whether to show the proactive post-
  /// onboarding permission prompt. Once marked as shown, the prompt will
  /// not be displayed proactively again, though users can still access it
  /// via the notification bell icon or settings screen.
  ///
  /// Returns `false` on error to fail open (show prompt rather than hide).
  static Future<bool> hasShownPrompt(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_keyPrefix$userId';
      final hasShown = prefs.getBool(key) ?? false;

      if (kDebugMode) {
        debugPrint(
          '[PermissionPromptService] hasShownPrompt for user $userId: '
          '$hasShown',
        );
      }

      return hasShown;
    } on Exception catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          '[PermissionPromptService] Failed to check prompt status for '
          'user $userId: $e',
        );
        debugPrint('Stack trace: $stackTrace');
        debugPrint('Defaulting to false (will show prompt)');
      }
      // Fail open - better to show the prompt than hide it
      return false;
    }
  }

  /// Marks the permission pre-prompt as shown for a user.
  ///
  /// Call this immediately BEFORE displaying the prompt dialog to prevent
  /// duplicate displays if the user closes the app or navigates away during
  /// the prompt.
  ///
  /// Once marked, the prompt will not be shown proactively again, though
  /// users can still access it reactively via the notification bell icon
  /// or settings screen.
  ///
  /// This persists across app restarts and survives logout (restored on
  /// re-login for the same user).
  static Future<void> markPromptAsShown(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_keyPrefix$userId';
      await prefs.setBool(key, true);

      if (kDebugMode) {
        debugPrint(
          '[PermissionPromptService] Marked prompt as shown for user $userId',
        );
      }
    } on Exception catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          '[PermissionPromptService] Failed to mark prompt as shown for '
          'user $userId: $e',
        );
        debugPrint('Stack trace: $stackTrace');
        // Don't rethrow - this is a non-critical operation
        // Worst case: user sees prompt again on next session
      }
    }
  }

  /// Clears the shown state for a user.
  ///
  /// This is primarily for testing and debugging purposes. Call this to
  /// reset the prompt state and allow the proactive prompt to be shown
  /// again.
  ///
  /// In production, this might be called:
  /// - When user deletes their account (cleanup)
  /// - In a debug "Reset permission prompts" option
  /// - During integration tests
  static Future<void> clearPromptState(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_keyPrefix$userId';
      await prefs.remove(key);

      if (kDebugMode) {
        debugPrint(
          '[PermissionPromptService] Cleared prompt state for user $userId',
        );
      }
    } on Exception catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          '[PermissionPromptService] Failed to clear prompt state for '
          'user $userId: $e',
        );
        debugPrint('Stack trace: $stackTrace');
      }
    }
  }

  /// Gets all prompt state keys for all users (debug/testing utility).
  ///
  /// Returns a list of all SharedPreferences keys related to permission
  /// prompt state. Useful for debugging multi-user scenarios or auditing
  /// storage usage.
  ///
  /// Example output:
  /// ```dart
  /// [
  ///   'notif_permission_prompt_shown_user123',
  ///   'notif_permission_prompt_shown_user456'
  /// ]
  /// ```
  static Future<List<String>> getAllPromptStateKeys() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs
          .getKeys()
          .where((key) => key.startsWith(_keyPrefix))
          .toList();

      if (kDebugMode) {
        debugPrint(
          '[PermissionPromptService] Found ${keys.length} prompt state keys',
        );
      }

      return keys;
    } on Exception catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          '[PermissionPromptService] Failed to get prompt state keys: $e',
        );
        debugPrint('Stack trace: $stackTrace');
      }
      return [];
    }
  }
}
