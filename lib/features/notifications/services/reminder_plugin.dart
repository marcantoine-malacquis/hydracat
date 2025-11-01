import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hydracat/core/config/flavor_config.dart';
import 'package:hydracat/features/notifications/services/notification_tap_handler.dart';
import 'package:hydracat/l10n/app_localizations.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;

/// Service class for managing local notifications using
/// flutter_local_notifications.
///
/// This is a thin wrapper around FlutterLocalNotificationsPlugin that
/// provides dependency injection support and simplified API for
/// scheduling reminders.
///
/// Can be mocked in tests using mocktail or mockito for dependency
/// injection and testability.
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

  /// iOS notification category identifier for treatment reminders
  /// This category includes the "Log now" action button
  static const String iosCategoryId = 'TREATMENT_REMINDER';

  /// Android notification channel ID for medication reminders
  /// (high priority)
  static const String channelIdMedicationReminders = 'medication_reminders';

  /// Android notification channel ID for fluid therapy reminders
  /// (high priority)
  static const String channelIdFluidReminders = 'fluid_reminders';

  /// Android notification channel ID for weekly summaries
  /// (default priority)
  static const String channelIdWeeklySummaries = 'weekly_summaries';

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

      // Android initialization settings with notification icon
      const androidSettings = AndroidInitializationSettings(
        '@drawable/ic_stat_notification',
      );

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

      // Create notification channels for Android
      await _createNotificationChannels();

      // Create notification categories for iOS
      await _createNotificationCategoriesIOS();

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

  /// Callback for notification taps (iOS/Android).
  ///
  /// Parses the notification payload and triggers the NotificationTapHandler
  /// to initiate deep-linking to the appropriate logging screen.
  ///
  /// The payload should be a JSON string containing:
  /// - userId: User ID who scheduled the notification
  /// - petId: Pet ID for the treatment
  /// - scheduleId: Schedule ID for the treatment
  /// - timeSlot: Time slot in "HH:mm" format
  /// - kind: Notification kind (initial/followup/snooze)
  /// - treatmentType: Type of treatment (medication/fluid)
  ///
  /// If the payload is missing or invalid, the tap is logged and ignored.
  void _onDidReceiveNotificationResponse(NotificationResponse response) {
    _devLog('');
    _devLog('═══════════════════════════════════════════════════════');
    _devLog('🔔 NOTIFICATION TAP DETECTED - ReminderPlugin Callback');
    _devLog('═══════════════════════════════════════════════════════');
    _devLog('Timestamp: ${DateTime.now().toIso8601String()}');
    _devLog('Notification ID: ${response.id}');
    _devLog('Action ID: ${response.actionId}');
    _devLog('Input: ${response.input}');
    _devLog('Notification Type: ${response.notificationResponseType}');
    _devLog('Payload: ${response.payload}');
    _devLog('');

    // Validate payload exists
    if (response.payload == null || response.payload!.isEmpty) {
      _devLog('❌ CRITICAL: Notification tap has no payload, ignoring');
      _devLog('═══════════════════════════════════════════════════════');
      return;
    }

    _devLog('✅ Payload exists, proceeding to parse...');

    try {
      // Parse payload to validate JSON structure
      final payloadMap = json.decode(response.payload!) as Map<String, dynamic>;
      _devLog('✅ Payload JSON parsed successfully');
      _devLog('Payload contents: $payloadMap');

      // Validate required fields
      final requiredFields = [
        'userId',
        'petId',
        'scheduleId',
        'timeSlot',
        'kind',
        'treatmentType',
      ];

      var missingFields = 0;
      for (final field in requiredFields) {
        if (!payloadMap.containsKey(field)) {
          _devLog('⚠️ Notification payload missing required field: $field');
          missingFields++;
          // Continue anyway - handler will validate and fall back gracefully
        }
      }

      if (missingFields == 0) {
        _devLog('✅ All required fields present in payload');
      } else {
        _devLog('⚠️ Missing $missingFields required field(s)');
      }

      // Route to appropriate handler based on action ID
      _devLog('');
      _devLog('Step 3: Routing based on action ID...');
      _devLog('Action ID: ${response.actionId}');

      if (response.actionId == 'snooze') {
        // User tapped "Snooze 15 min" action button
        _devLog('');
        _devLog(
          '📤 SNOOZE ACTION: Calling NotificationTapHandler '
          'notificationSnoozePayload setter...',
        );
        NotificationTapHandler.notificationSnoozePayload = response.payload!;
        _devLog(
          '✅ NotificationTapHandler '
          'notificationSnoozePayload SET',
        );
        _devLog('This should trigger AppShell snooze listener...');
      } else {
        // User tapped notification body or "Log now" action button
        _devLog('');
        _devLog(
          '📤 TAP/LOG NOW: Calling NotificationTapHandler '
          'notificationTapPayload setter...',
        );
        NotificationTapHandler.notificationTapPayload = response.payload!;
        _devLog(
          '✅ NotificationTapHandler '
          'notificationTapPayload SET',
        );
        _devLog('This should trigger AppShell tap listener...');
      }

      _devLog('═══════════════════════════════════════════════════════');
      _devLog('');
    } on Exception catch (e, stackTrace) {
      _devLog('❌ ERROR parsing notification payload: $e');
      _devLog('Stack trace: $stackTrace');
      _devLog('═══════════════════════════════════════════════════════');
      // Don't rethrow - gracefully ignore invalid payloads
    }
  }

  /// Create Android notification channels.
  ///
  /// Channels are created once at initialization and define the behavior
  /// (importance, sound, vibration) for different notification types.
  /// Channels are immutable after creation (only name/description can update).
  Future<void> _createNotificationChannels() async {
    if (_plugin == null) return;

    try {
      // Channel for medication reminders - high priority
      const medicationChannel = AndroidNotificationChannel(
        'medication_reminders',
        'Medication Reminders',
        description: 'Notifications for medication treatment reminders',
        importance: Importance.high,
      );

      // Channel for fluid therapy reminders - high priority
      const fluidChannel = AndroidNotificationChannel(
        'fluid_reminders',
        'Fluid Therapy Reminders',
        description: 'Notifications for fluid therapy reminders',
        importance: Importance.high,
      );

      // Channel for weekly summaries - default priority
      const summaryChannel = AndroidNotificationChannel(
        'weekly_summaries',
        'Weekly Summaries',
        description: 'Weekly progress summary notifications',
      );

      // Create channels
      await _plugin!
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(medicationChannel);

      await _plugin!
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(fluidChannel);

      await _plugin!
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(summaryChannel);

      _devLog('Created Android notification channels successfully');
    } on Exception catch (e, stackTrace) {
      _devLog('Failed to create notification channels: $e');
      _devLog('Stack trace: $stackTrace');
      // Don't rethrow - channel creation failure shouldn't block init
    }
  }

  /// Create iOS notification categories.
  ///
  /// Categories define the actions available when a user swipes or long-presses
  /// a notification on iOS. We create a single category for treatment reminders
  /// with "Log now" and "Snooze 15 min" action buttons.
  ///
  /// This is called once during initialization and allows us to add action
  /// buttons that appear on notifications.
  Future<void> _createNotificationCategoriesIOS() async {
    if (_plugin == null || !Platform.isIOS) return;

    try {
      // Get localized strings
      final l10n = _getLocalizations();

      // Create "Log now" action
      final logNowAction = DarwinNotificationAction.plain(
        'log_now',
        l10n.notificationActionLogNow,
        options: <DarwinNotificationActionOption>{
          // Brings app to foreground when tapped
          DarwinNotificationActionOption.foreground,
        },
      );

      // Create "Snooze 15 min" action
      final snoozeAction = DarwinNotificationAction.plain(
        'snooze',
        l10n.notificationActionSnooze,
        options: <DarwinNotificationActionOption>{
          // Brings app to foreground when tapped
          DarwinNotificationActionOption.foreground,
        },
      );

      // Create notification category for treatment reminders
      // iOS supports up to 4 actions per category
      final treatmentCategory = DarwinNotificationCategory(
        iosCategoryId,
        actions: <DarwinNotificationAction>[logNowAction, snoozeAction],
        options: <DarwinNotificationCategoryOption>{
          // Allow custom dismiss action
          DarwinNotificationCategoryOption.customDismissAction,
        },
      );

      // Register category with plugin
      await _plugin!
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.initialize(
            DarwinInitializationSettings(
              requestAlertPermission: false,
              requestBadgePermission: false,
              requestSoundPermission: false,
              notificationCategories: [treatmentCategory],
            ),
          );

      _devLog('Created iOS notification category successfully');
    } on Exception catch (e, stackTrace) {
      _devLog('Failed to create iOS notification categories: $e');
      _devLog('Stack trace: $stackTrace');
      // Don't rethrow - category creation failure shouldn't block init
    }
  }

  /// Schedule a notification at a specific time using timezone-aware
  /// datetime.
  ///
  /// [id] - Unique notification identifier
  /// [title] - Notification title
  /// [body] - Notification body text
  /// [scheduledDate] - Timezone-aware datetime for notification delivery
  /// [channelId] - Android notification channel ID (medication_reminders,
  ///               fluid_reminders, or weekly_summaries)
  /// [payload] - Optional JSON payload for notification tap handling
  /// [groupId] - Optional group identifier for notification grouping (Android)
  /// [threadIdentifier] - Optional thread identifier for grouping (iOS)
  ///
  /// Throws [StateError] if plugin is not initialized.
  Future<void> showZoned({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    String channelId = 'medication_reminders',
    String? payload,
    String? groupId,
    String? threadIdentifier,
  }) async {
    if (!_isInitialized || _plugin == null) {
      throw StateError(
        'ReminderPlugin must be initialized before scheduling notifications',
      );
    }

    try {
      // Determine channel name based on ID
      String channelName;
      switch (channelId) {
        case 'medication_reminders':
          channelName = 'Medication Reminders';
        case 'fluid_reminders':
          channelName = 'Fluid Therapy Reminders';
        case 'weekly_summaries':
          channelName = 'Weekly Summaries';
        default:
          channelName = 'Medication Reminders';
      }

      // Get localized strings
      final l10n = _getLocalizations();

      // Create Android notification actions
      final androidActions = [
        AndroidNotificationAction(
          'log_now',
          l10n.notificationActionLogNow,
          showsUserInterface: true, // Brings app to foreground
        ),
        AndroidNotificationAction(
          'snooze',
          l10n.notificationActionSnooze,
          // showsUserInterface defaults to false (dismisses notification)
        ),
      ];

      await _plugin!.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelName,
            importance: Importance.high,
            priority: Priority.high,
            color: const Color(0xFF6BB8A8),
            groupKey: groupId,
            actions: androidActions,
          ),
          iOS: DarwinNotificationDetails(
            threadIdentifier: threadIdentifier,
            categoryIdentifier: iosCategoryId,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );

      _devLog(
        'Scheduled notification $id for $scheduledDate on channel $channelId',
      );
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
  }) async {
    if (!_isInitialized || _plugin == null) {
      throw StateError(
        'ReminderPlugin must be initialized before showing notifications',
      );
    }

    try {
      // Generate deterministic ID for summary (hash of "summary_{petId}")
      final summaryId = 'summary_$petId'.hashCode.abs() & 0x7FFFFFFF;

      // Build summary title/body using localized strings
      final l10n = _getLocalizations();

      // Title
      final title = l10n.notificationGroupSummaryTitle(petName);

      // Body
      String body;
      if (medicationCount > 0 && fluidCount == 0) {
        body = l10n.notificationGroupSummaryMedicationOnly(medicationCount);
      } else if (medicationCount == 0 && fluidCount > 0) {
        body = l10n.notificationGroupSummaryFluidOnly(fluidCount);
      } else if (medicationCount > 0 && fluidCount > 0) {
        // Signature is (fluidCount, medCount) in generated l10n
        body = l10n.notificationGroupSummaryBoth(fluidCount, medicationCount);
      } else {
        // No notifications, don't show summary
        _devLog('No notifications for pet $petId, skipping group summary');
        return;
      }

      // Show summary notification
      await _plugin!.show(
        summaryId,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'medication_reminders',
            'Medication Reminders',
            importance: Importance.high,
            priority: Priority.high,
            color: const Color(0xFF6BB8A8),
            groupKey: groupId,
            setAsGroupSummary: true,
          ),
          iOS: DarwinNotificationDetails(
            threadIdentifier: threadIdentifier,
          ),
        ),
      );

      _devLog(
        'Created group summary notification $summaryId for $petName: $body',
      );
    } on Exception catch (e, stackTrace) {
      _devLog('Failed to show group summary for pet $petId: $e');
      _devLog('Stack trace: $stackTrace');
      // Don't rethrow - summary failure shouldn't block main functionality
    }
  }

  /// Cancel the group summary notification for a pet.
  ///
  /// Call this when all individual notifications for a pet have been canceled,
  /// or when the pet is removed.
  ///
  /// [petId] - Pet identifier used to generate the summary notification ID
  ///
  /// Throws [StateError] if plugin is not initialized.
  Future<void> cancelGroupSummary(String petId) async {
    if (!_isInitialized || _plugin == null) {
      throw StateError(
        'ReminderPlugin must be initialized before canceling notifications',
      );
    }

    try {
      // Generate same deterministic ID used in showGroupSummary
      final summaryId = 'summary_$petId'.hashCode.abs() & 0x7FFFFFFF;

      await _plugin!.cancel(summaryId);
      _devLog('Canceled group summary notification $summaryId for pet $petId');
    } on Exception catch (e, stackTrace) {
      _devLog('Failed to cancel group summary for pet $petId: $e');
      _devLog('Stack trace: $stackTrace');
      // Don't rethrow - summary cancellation failure is non-critical
    }
  }

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
  Future<NotificationAppLaunchDetails?>
  getNotificationAppLaunchDetails() async {
    if (!_isInitialized || _plugin == null) {
      _devLog('Cannot get launch details: plugin not initialized');
      return null;
    }

    try {
      final details = await _plugin!.getNotificationAppLaunchDetails();
      _devLog(
        'Launch details: didLaunchApp=${details?.didNotificationLaunchApp}, '
        'hasResponse=${details?.notificationResponse != null}',
      );
      return details;
    } on Exception catch (e, stackTrace) {
      _devLog('Failed to get notification launch details: $e');
      _devLog('Stack trace: $stackTrace');
      return null;
    }
  }

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
  Future<bool> canScheduleExactNotifications() async {
    // iOS always returns true (not applicable)
    if (!Platform.isAndroid) {
      return true;
    }

    try {
      // Check SCHEDULE_EXACT_ALARM permission status
      final status = await Permission.scheduleExactAlarm.status;

      final canSchedule = status.isGranted;

      _devLog(
        'Exact alarm permission status: ${status.name}, '
        'can schedule: $canSchedule',
      );

      return canSchedule;
    } on Exception catch (e, stackTrace) {
      _devLog('Failed to check exact alarm permission: $e');
      _devLog('Stack trace: $stackTrace');
      // Default to true to avoid blocking functionality
      // Actual scheduling will fail gracefully if permission denied
      return true;
    }
  }

  /// Get localized strings without BuildContext.
  ///
  /// This helper method provides access to localization strings for
  /// notification content that's scheduled before the app has a BuildContext
  /// (e.g., during plugin initialization or from background services).
  ///
  /// V1: Returns English localizations only. When adding more languages,
  /// detect the system locale using:
  /// ```dart
  /// final locale = WidgetsBinding.instance.platformDispatcher.locale;
  /// return lookupAppLocalizations(locale);
  /// ```
  AppLocalizations _getLocalizations() {
    // Resolve device locale with safe fallbacks
    try {
      final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;

      try {
        return lookupAppLocalizations(deviceLocale);
      } on Exception catch (_) {}

      try {
        return lookupAppLocalizations(Locale(deviceLocale.languageCode));
      } on Exception catch (_) {}
    } on Exception catch (_) {}

    return lookupAppLocalizations(const Locale('en'));
  }

  /// Log messages only in development flavor
  void _devLog(String message) {
    if (FlavorConfig.isDevelopment) {
      debugPrint('[Notifications Dev] $message');
    }
  }
}
