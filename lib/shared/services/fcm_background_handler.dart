import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/core/config/flavor_config.dart';
import 'package:hydracat/features/notifications/providers/notification_provider.dart';
import 'package:hydracat/features/notifications/services/reminder_plugin.dart';
import 'package:hydracat/features/notifications/services/reminder_service.dart';
import 'package:hydracat/firebase_options.dart';
import 'package:hydracat/providers/analytics_provider.dart';
import 'package:hydracat/providers/logging_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// CRITICAL: Must be top-level function (not inside class).
/// This is called when app is in background or terminated.
///
/// iOS: App has ~30 seconds to complete execution.
/// Android: More lenient, but still time-limited.
///
/// IMPORTANT: This function runs in an isolate separate from the main app.
/// It cannot access existing providers or state. Must initialize everything.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  // Initialize Firebase (required for background execution)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize timezone (required for scheduling)
  tz.initializeTimeZones();

  // Detect device timezone (same logic as main.dart)
  final now = DateTime.now();
  final offsetInHours = now.timeZoneOffset.inHours;
  final timezoneNames = {
    -12: 'Etc/GMT+12',
    -11: 'Pacific/Midway',
    -10: 'Pacific/Honolulu',
    -9: 'America/Anchorage',
    -8: 'America/Los_Angeles',
    -7: 'America/Denver',
    -6: 'America/Chicago',
    -5: 'America/New_York',
    -4: 'America/Halifax',
    -3: 'America/Sao_Paulo',
    -2: 'Atlantic/South_Georgia',
    -1: 'Atlantic/Azores',
    0: 'Europe/London',
    1: 'Europe/Paris',
    2: 'Europe/Athens',
    3: 'Europe/Moscow',
    4: 'Asia/Dubai',
    5: 'Asia/Karachi',
    6: 'Asia/Dhaka',
    7: 'Asia/Bangkok',
    8: 'Asia/Singapore',
    9: 'Asia/Tokyo',
    10: 'Australia/Sydney',
    11: 'Pacific/Guadalcanal',
    12: 'Pacific/Fiji',
  };
  final locationName =
      timezoneNames[offsetInHours] ?? 'Etc/GMT${-offsetInHours}';
  try {
    final location = tz.getLocation(locationName);
    tz.setLocalLocation(location);
  } on Exception {
    tz.setLocalLocation(tz.getLocation('UTC'));
  }

  _devLog('');
  _devLog('===================================================');
  _devLog('=== FCM BACKGROUND HANDLER - Message received ===');
  _devLog('===================================================');
  _devLog('Timestamp: ${DateTime.now().toIso8601String()}');
  _devLog('Message data: ${message.data}');
  _devLog('');

  final messageType = message.data['type'];

  if (messageType == 'daily_wakeup') {
    _devLog('Type: daily_wakeup (daily scheduling trigger)');

    try {
      // Get current user and pet from cached data
      final userId = await _getCachedUserId();
      final petId = await _getCachedPrimaryPetId();

      if (userId == null || petId == null) {
        _devLog('⚠️ No cached user/pet found, skipping scheduling');
        _devLog('User must open app to trigger initial scheduling');
        _devLog('===================================================');
        return;
      }

      _devLog('✅ Cached user/pet found:');
      _devLog('  User ID: ${userId.substring(0, 8)}...');
      _devLog('  Pet ID: ${petId.substring(0, 8)}...');

      // Initialize ReminderPlugin
      final reminderPlugin = ReminderPlugin();
      await reminderPlugin.initialize();

      // Create ProviderContainer for background execution
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          reminderPluginProvider.overrideWithValue(reminderPlugin),
        ],
      );

      try {
        _devLog('Calling scheduleAllForToday()...');
        final reminderService = ReminderService();

        // Set 25-second timeout (iOS gives ~30 seconds max)
        final result = await Future.any([
          _scheduleWithContainer(reminderService, userId, petId, container),
          Future.delayed(const Duration(seconds: 25), () {
            throw TimeoutException('Scheduling timed out after 25 seconds');
          }),
        ]);

        _devLog('✅ Scheduling complete:');
        final scheduledCount = result['scheduled'] as int? ?? 0;
        final immediateCount = result['immediate'] as int? ?? 0;
        final missedCount = result['missed'] as int? ?? 0;
        final errorsList = result['errors'] as List? ?? [];
        _devLog('  Scheduled: $scheduledCount');
        _devLog('  Immediate: $immediateCount');
        _devLog('  Missed: $missedCount');
        _devLog('  Errors: ${errorsList.length}');

        // Track analytics
        try {
          await container.read(analyticsServiceDirectProvider)
            .trackBackgroundSchedulingSuccess(
              notificationCount: scheduledCount,
              triggerSource: 'fcm_daily_wakeup',
            );
        } on Exception catch (e) {
          _devLog('Analytics tracking failed: $e');
        }

        await FirebaseCrashlytics.instance.log(
          'FCM background scheduling: $scheduledCount notifications',
        );

        _devLog('===================================================');
      } finally {
        container.dispose();
      }
    } on Exception catch (e, stackTrace) {
      _devLog('❌ ERROR during background scheduling: $e');
      _devLog('Stack trace: $stackTrace');

      // Report to Crashlytics (non-fatal)
      await FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'FCM background scheduling failed',
      );

      _devLog('===================================================');
    }
  } else {
    _devLog('Unknown message type: $messageType, ignoring');
    _devLog('===================================================');
  }
}

/// Wrapper to call scheduleAllForToday with ProviderContainer.
///
/// Uses a FutureProvider to bridge between ProviderContainer and WidgetRef.
/// Note: The ref parameter is technically a different type, but at runtime
/// it provides the same interface for reading providers.
Future<Map<String, dynamic>> _scheduleWithContainer(
  ReminderService service,
  String userId,
  String petId,
  ProviderContainer container,
) async {
  // Create an auto-dispose provider that executes the scheduling
  final schedulingProvider = FutureProvider.autoDispose<Map<String, dynamic>>(
    (ref) => service.scheduleAllForToday(userId, petId, ref as WidgetRef),
  );

  // Await the future directly
  return container.read(schedulingProvider.future);
}

/// Helper: Get cached user ID from SharedPreferences.
Future<String?> _getCachedUserId() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('cached_user_id');
  } on Exception catch (e) {
    _devLog('Error reading cached user ID: $e');
    return null;
  }
}

/// Helper: Get cached primary pet ID from SharedPreferences.
Future<String?> _getCachedPrimaryPetId() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('cached_primary_pet_id');
  } on Exception catch (e) {
    _devLog('Error reading cached pet ID: $e');
    return null;
  }
}

/// Log messages (visible in device logs and Firebase Console).
void _devLog(String message) {
  if (FlavorConfig.isDevelopment) {
    debugPrint('[FCM Background] $message');
  }
}

/// Timeout exception for background execution limits.
class TimeoutException implements Exception {
  /// Creates a TimeoutException with the given message.
  TimeoutException(this.message);

  /// The timeout error message.
  final String message;

  @override
  String toString() => 'TimeoutException: $message';
}
