import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

/// Abstract interface for notification plugin operations.
///
/// This interface provides a clean abstraction for notification scheduling,
/// enabling dependency injection and testability.
///
/// All methods mirror the ReminderPlugin implementation exactly.
abstract class ReminderPluginInterface {
  /// iOS notification category identifier for treatment reminders
  static const String iosCategoryId = 'TREATMENT_REMINDER';

  /// Android notification channel ID for medication reminders
  static const String channelIdMedicationReminders = 'medication_reminders';

  /// Android notification channel ID for fluid therapy reminders
  static const String channelIdFluidReminders = 'fluid_reminders';

  /// Android notification channel ID for weekly summaries
  static const String channelIdWeeklySummaries = 'weekly_summaries';

  /// Getter for initialization status
  bool get isInitialized;

  /// Initialize the notification plugin with platform-specific settings.
  ///
  /// This should be called once during app startup. It configures the plugin
  /// with basic Android and iOS settings. Detailed platform configuration
  /// (channels, categories, etc.) will be added in later phases.
  ///
  /// Returns true if initialization succeeds, false otherwise.
  Future<bool> initialize();

  /// Schedule a notification at a specific time using timezone-aware datetime.
  ///
  /// Throws StateError if plugin is not initialized.
  Future<void> showZoned({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    String channelId = 'medication_reminders',
    String? payload,
    String? groupId,
    String? threadIdentifier,
  });

  /// Cancel a scheduled notification by its ID.
  ///
  /// [id] - The notification identifier to cancel
  ///
  /// Throws [StateError] if plugin is not initialized.
  Future<void> cancel(int id);

  /// Cancel all scheduled notifications.
  ///
  /// Useful for logout or when resetting notification state.
  ///
  /// Throws [StateError] if plugin is not initialized.
  Future<void> cancelAll();

  /// Get a list of all pending notification requests.
  ///
  /// Returns a list of pending notifications that have been scheduled but
  /// not yet delivered. Useful for debugging and reconciliation.
  ///
  /// Throws [StateError] if plugin is not initialized.
  Future<List<PendingNotificationRequest>> pendingNotificationRequests();

  /// Show a group summary notification for a pet's reminders.
  ///
  /// On Android, this creates a group summary notification that collects
  /// all individual notifications for a pet. On iOS, this appears as a
  /// regular notification (iOS doesn't support Android-style group summaries).
  ///
  /// [petId] - Pet identifier for generating deterministic notification ID
  /// [petName] - Pet name for display in summary
  /// [medicationCount] - Number of pending medication reminders
  /// [fluidCount] - Number of pending fluid therapy reminders
  /// [groupId] - Group identifier (should match individual notifications)
  /// [threadIdentifier] - Thread identifier for iOS grouping
  ///
  /// The summary notification uses a deterministic ID based on petId to
  /// enable idempotent updates.
  ///
  /// Throws [StateError] if plugin is not initialized.
  Future<void> showGroupSummary({
    required String petId,
    required String petName,
    required int medicationCount,
    required int fluidCount,
    required String groupId,
    String? threadIdentifier,
  });

  /// Cancel the group summary notification for a pet.
  ///
  /// Call this when all individual notifications for a pet have been canceled,
  /// or when the pet is removed.
  ///
  /// [petId] - Pet identifier used to generate the summary notification ID
  ///
  /// Throws [StateError] if plugin is not initialized.
  Future<void> cancelGroupSummary(String petId);

  /// Check if the app can schedule exact notifications (Android 12+).
  ///
  /// On Android 12+, the SCHEDULE_EXACT_ALARM permission is required for
  /// medical-grade timing accuracy. This permission prevents notification
  /// delays of 10-15 minutes that can occur with inexact alarms due to
  /// battery optimization.
  ///
  /// Returns:
  /// - `true` if exact alarms can be scheduled
  /// - `false` if permission is denied (should fallback to inexact alarms)
  /// - `true` on iOS (not applicable)
  /// - `true` on Android <12 (permission auto-granted)
  ///
  /// If denied, app should:
  /// 1. Use inexact alarms as fallback
  /// 2. Show warning in notification settings UI
  /// 3. Provide button to open system settings for permission grant
  Future<bool> canScheduleExactNotifications();

  /// Get notification app launch details (for cold start handling).
  ///
  /// Returns details about whether the app was launched by tapping a
  /// notification, and if so, what the notification response was.
  ///
  /// This is used for handling "cold start" scenarios where the app is
  /// not running when the user taps a notification. The payload can then
  /// be processed to deep-link to the appropriate screen.
  ///
  /// Returns null if:
  /// - The plugin is not initialized
  /// - The details cannot be retrieved
  /// - An error occurs during retrieval
  Future<NotificationAppLaunchDetails?> getNotificationAppLaunchDetails();
}
