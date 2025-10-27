import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/features/notifications/providers/notification_provider.dart';
import 'package:hydracat/features/notifications/services/notification_index_store.dart';

/// Service for managing notification cleanup operations.
///
/// Provides centralized methods for clearing notification data and handling
/// cleanup during lifecycle events like logout.
///
/// Key operations:
/// - Clear all notification data (cancel + clear index)
/// - Cleanup on logout (preserve settings)
/// - Graceful error handling
///
/// Example usage:
/// ```dart
/// final service = NotificationCleanupService();
///
/// // Clear all notification data
/// final result = await service.clearAllNotificationData(userId, petId, ref);
///
/// // Cleanup on logout
/// await service.cleanupOnLogout(userId, petId, ref);
/// ```
class NotificationCleanupService {
  /// Factory constructor to get the singleton instance
  factory NotificationCleanupService() =>
      _instance ??= NotificationCleanupService._();

  /// Private unnamed constructor
  NotificationCleanupService._();

  static NotificationCleanupService? _instance;

  /// Clears all notification data for the current user/pet.
  ///
  /// This is a "nuclear reset" operation that:
  /// 1. Cancels all scheduled notifications via the plugin
  /// 2. Clears the notification index from SharedPreferences
  /// 3. Preserves notification settings (user preferences)
  /// 4. Keeps system permission status intact
  ///
  /// Parameters:
  /// - [userId]: Current user identifier
  /// - [petId]: Primary pet identifier
  /// - [ref]: Riverpod ref for accessing providers
  ///
  /// Returns: Map with operation results:
  /// - 'success': bool (true if operation completed without errors)
  /// - 'canceledCount': int (number of notifications canceled)
  /// - 'indexCleared': bool (true if index was cleared)
  /// - 'error': String? (error message if operation failed)
  ///
  /// This method is idempotent - safe to call multiple times.
  Future<Map<String, dynamic>> clearAllNotificationData(
    String userId,
    String petId,
    Ref ref,
  ) async {
    _devLog('clearAllNotificationData called for userId=$userId, petId=$petId');

    try {
      // Step 1: Cancel all scheduled notifications
      final canceledCount = await _cancelAllScheduledNotifications(ref);
      _devLog('Canceled $canceledCount scheduled notifications');

      // Step 2: Clear notification index for today
      final indexStore = ref.read(notificationIndexStoreProvider);
      await indexStore.clearForDate(userId, petId, DateTime.now());
      _devLog('Cleared notification index for today');

      // Note: We intentionally preserve notification settings in
      // SharedPreferences. Settings are user preferences and should
      // persist across data clears unless explicitly reset.

      _devLog('✅ Clear all notification data completed successfully');

      return {
        'success': true,
        'canceledCount': canceledCount,
        'indexCleared': true,
      };
    } on Exception catch (e, stackTrace) {
      _devLog('❌ ERROR in clearAllNotificationData: $e');
      _devLog('Stack trace: $stackTrace');

      return {
        'success': false,
        'canceledCount': 0,
        'indexCleared': false,
        'error': e.toString(),
      };
    }
  }

  /// Performs notification cleanup on user logout.
  ///
  /// This method is called automatically when a user signs out. It:
  /// 1. Cancels all scheduled notifications
  /// 2. Clears the notification index
  /// 3. Preserves notification settings for better UX on re-login
  ///
  /// Settings are preserved because:
  /// - They're user preferences, not sensitive data
  /// - Better UX: user doesn't need to reconfigure on re-login
  /// - Settings are keyed by userId, so multi-user scenarios are safe
  ///
  /// Parameters:
  /// - [userId]: Current user identifier
  /// - [petId]: Primary pet identifier
  ///
  /// Errors are logged but don't throw - logout should never be blocked
  /// by notification cleanup failures.
  ///
  /// Note: This version doesn't require Ref, making it easier to call from
  /// contexts where Ref isn't available (e.g., AuthNotifier).
  Future<void> cleanupOnLogout(
    String userId,
    String petId,
  ) async {
    _devLog('cleanupOnLogout called for userId=$userId, petId=$petId');

    try {
      // Cancel all scheduled notifications using plugin directly
      final plugin = await _getReminderPlugin();
      final pendingNotifications = await plugin.pendingNotificationRequests();
      var canceledCount = 0;
      for (final notification in pendingNotifications) {
        try {
          await plugin.cancel(notification.id);
          canceledCount++;
        } on Exception catch (e) {
          _devLog(
            '⚠️ Failed to cancel notification ${notification.id}: $e',
          );
        }
      }
      _devLog('Logout cleanup: Canceled $canceledCount notifications');

      // Clear notification index using store directly
      final indexStore = NotificationIndexStore();
      await indexStore.clearForDate(userId, petId, DateTime.now());
      _devLog('Logout cleanup: Cleared notification index');

      // Note: Settings are preserved in SharedPreferences (keyed by userId)
      // Users who want to fully clear everything can explicitly use
      // "Clear notification data" before logging out

      _devLog('✅ Logout cleanup completed successfully');
    } on Exception catch (e, stackTrace) {
      // Log error but don't rethrow - logout should complete even if
      // notification cleanup fails
      _devLog('❌ ERROR in cleanupOnLogout: $e');
      _devLog('Stack trace: $stackTrace');
      _devLog('⚠️ Logout will continue despite notification cleanup failure');
    }
  }

  /// Internal: Cancels all scheduled notifications via the plugin.
  ///
  /// Returns the number of notifications successfully canceled.
  ///
  /// Note: This uses the plugin's pendingNotificationRequests() to get
  /// all scheduled notifications, then cancels each one individually.
  /// The plugin handles platform-specific cancellation (iOS/Android).
  Future<int> _cancelAllScheduledNotifications(Ref ref) async {
    try {
      final plugin = ref.read(reminderPluginProvider);

      // Get all pending notifications
      final pendingNotifications = await plugin.pendingNotificationRequests();
      _devLog(
        'Found ${pendingNotifications.length} pending notifications to cancel',
      );

      // Cancel each notification
      var canceledCount = 0;
      for (final notification in pendingNotifications) {
        try {
          await plugin.cancel(notification.id);
          canceledCount++;
        } on Exception catch (e) {
          _devLog(
            '⚠️ Failed to cancel notification ${notification.id}: $e',
          );
          // Continue canceling other notifications
        }
      }

      return canceledCount;
    } on Exception catch (e, stackTrace) {
      _devLog('❌ ERROR in _cancelAllScheduledNotifications: $e');
      _devLog('Stack trace: $stackTrace');
      return 0;
    }
  }

  /// Gets the reminder plugin instance
  Future<FlutterLocalNotificationsPlugin> _getReminderPlugin() async {
    return FlutterLocalNotificationsPlugin();
  }

  /// Log messages only in development flavor
  void _devLog(String message) {
    if (kDebugMode) {
      debugPrint('[NotificationCleanupService] $message');
    }
  }
}

/// Provider for NotificationCleanupService singleton
final notificationCleanupServiceProvider = Provider<NotificationCleanupService>(
  (ref) => NotificationCleanupService(),
);
