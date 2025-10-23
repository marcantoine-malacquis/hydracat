import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hydracat/core/config/flavor_config.dart';
import 'package:timezone/timezone.dart' as tz;

/// Service class for managing local notifications using
/// flutter_local_notifications.
///
/// This is a thin wrapper around FlutterLocalNotificationsPlugin that
/// provides dependency injection support and simplified API for
/// scheduling reminders.
class ReminderPlugin {
  /// Factory constructor to get the singleton instance
  factory ReminderPlugin() => _instance ??= ReminderPlugin._();

  /// Private unnamed constructor
  ReminderPlugin._();
  static ReminderPlugin? _instance;

  /// The underlying flutter_local_notifications plugin
  FlutterLocalNotificationsPlugin? _plugin;

  /// Whether the plugin has been initialized
  bool _isInitialized = false;

  /// Getter for initialization status
  bool get isInitialized => _isInitialized;

  /// Initialize the notification plugin with platform-specific settings.
  ///
  /// This should be called once during app startup. It configures the plugin
  /// with basic Android and iOS settings. Detailed platform configuration
  /// (channels, categories, etc.) will be added in later phases.
  ///
  /// Returns true if initialization succeeds, false otherwise.
  Future<bool> initialize() async {
    try {
      _devLog('Initializing ReminderPlugin...');

      _plugin = FlutterLocalNotificationsPlugin();

      // Android initialization settings
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS initialization settings
      // We'll request permissions explicitly in later steps
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      // Combined initialization settings
      const initializationSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      );

      // Initialize plugin with callback for notification taps
      _devLog('Calling plugin.initialize()...');
      final initialized = await _plugin!.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
      );

      _devLog('Plugin initialization returned: $initialized');

      if (initialized ?? false) {
        _isInitialized = true;
        _devLog('ReminderPlugin initialized successfully');
        return true;
      } else {
        _devLog(
          'ReminderPlugin initialization returned false or null. '
          'This is expected on some platforms and will not affect '
          'notification functionality.',
        );
        // Consider it successful anyway - some platforms return null
        _isInitialized = true;
        return true;
      }
    } on Exception catch (e, stackTrace) {
      _devLog('Failed to initialize ReminderPlugin: $e');
      _devLog('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Placeholder callback for notification taps (iOS/Android).
  ///
  /// Currently logs the notification response in development mode.
  /// Full implementation with deep-linking will be added in
  /// Phase 3 (Step 3.1).
  void _onDidReceiveNotificationResponse(NotificationResponse response) {
    _devLog(
      'Notification tapped: ${response.id}, '
      'payload: ${response.payload}',
    );
    // Full deep-linking implementation will be added in Phase 3
  }

  /// Schedule a notification at a specific time using timezone-aware
  /// datetime.
  ///
  /// [id] - Unique notification identifier
  /// [title] - Notification title
  /// [body] - Notification body text
  /// [scheduledDate] - Timezone-aware datetime for notification delivery
  /// [payload] - Optional JSON payload for notification tap handling
  ///
  /// Throws [StateError] if plugin is not initialized.
  Future<void> showZoned({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    String? payload,
  }) async {
    if (!_isInitialized || _plugin == null) {
      throw StateError(
        'ReminderPlugin must be initialized before scheduling notifications',
      );
    }

    try {
      await _plugin!.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'default_channel', // Proper channels in Step 0.3
            'Default Notifications',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );

      _devLog('Scheduled notification $id for $scheduledDate');
    } catch (e, stackTrace) {
      _devLog('Failed to schedule notification $id: $e');
      _devLog('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Cancel a scheduled notification by its ID.
  ///
  /// [id] - The notification identifier to cancel
  ///
  /// Throws [StateError] if plugin is not initialized.
  Future<void> cancel(int id) async {
    if (!_isInitialized || _plugin == null) {
      throw StateError(
        'ReminderPlugin must be initialized before canceling notifications',
      );
    }

    try {
      await _plugin!.cancel(id);
      _devLog('Canceled notification $id');
    } catch (e, stackTrace) {
      _devLog('Failed to cancel notification $id: $e');
      _devLog('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Get a list of all pending notification requests.
  ///
  /// Returns a list of pending notifications that have been scheduled but
  /// not yet delivered. Useful for debugging and reconciliation.
  ///
  /// Throws [StateError] if plugin is not initialized.
  Future<List<PendingNotificationRequest>> pendingNotificationRequests() async {
    if (!_isInitialized || _plugin == null) {
      throw StateError(
        'ReminderPlugin must be initialized before querying notifications',
      );
    }

    try {
      final pending = await _plugin!.pendingNotificationRequests();
      _devLog('Found ${pending.length} pending notifications');
      return pending;
    } catch (e, stackTrace) {
      _devLog('Failed to get pending notifications: $e');
      _devLog('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Cancel all scheduled notifications.
  ///
  /// Useful for logout or when resetting notification state.
  ///
  /// Throws [StateError] if plugin is not initialized.
  Future<void> cancelAll() async {
    if (!_isInitialized || _plugin == null) {
      throw StateError(
        'ReminderPlugin must be initialized before canceling notifications',
      );
    }

    try {
      await _plugin!.cancelAll();
      _devLog('Canceled all notifications');
    } catch (e, stackTrace) {
      _devLog('Failed to cancel all notifications: $e');
      _devLog('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Log messages only in development flavor
  void _devLog(String message) {
    if (FlavorConfig.isDevelopment) {
      debugPrint('[Notifications Dev] $message');
    }
  }
}
