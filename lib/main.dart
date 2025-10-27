import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/app/app.dart';
import 'package:hydracat/core/config/flavor_config.dart';
import 'package:hydracat/features/notifications/providers/notification_provider.dart';
import 'package:hydracat/features/notifications/services/notification_tap_handler.dart';
import 'package:hydracat/features/notifications/services/reminder_plugin.dart';
import 'package:hydracat/providers/logging_provider.dart';
import 'package:hydracat/shared/services/firebase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

Future<void> main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize timezone database for notification scheduling
  await _initializeTimezone();

  // Initialize SharedPreferences for logging cache
  final prefs = await SharedPreferences.getInstance();

  // Initialize notification plugin
  final reminderPlugin = await _initializeNotifications();

  runApp(
    ProviderScope(
      overrides: [
        // Override SharedPreferences provider with actual instance
        sharedPreferencesProvider.overrideWithValue(prefs),
        // Override ReminderPlugin provider with initialized instance
        reminderPluginProvider.overrideWithValue(reminderPlugin),
      ],
      child: const HydraCatApp(),
    ),
  );

  // Check if app was launched by tapping a notification (cold start)
  unawaited(_checkNotificationLaunchDetails(reminderPlugin));
}

/// Initialize timezone database for scheduling notifications.
///
/// This must be called before scheduling any timezone-aware notifications.
/// Detects and uses the device's local timezone.
Future<void> _initializeTimezone() async {
  try {
    _devLog('Initializing timezone database...');
    tz.initializeTimeZones();

    // Detect device timezone
    // Get the device's UTC offset
    final now = DateTime.now();
    final offsetInHours = now.timeZoneOffset.inHours;
    final offsetInMinutes = now.timeZoneOffset.inMinutes % 60;

    _devLog(
      'Device timezone offset: ${offsetInHours >= 0 ? "+" : ""}$offsetInHours:'
      '${offsetInMinutes.abs().toString().padLeft(2, "0")}',
    );

    // Try to find a timezone that matches the device offset
    // Common timezone mappings based on offset
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
    final location = tz.getLocation(locationName);

    tz.setLocalLocation(location);
    _devLog('Timezone initialized: ${location.name} (offset: '
        '${offsetInHours >= 0 ? "+" : ""}$offsetInHours hours)');
  } on Exception catch (e) {
    _devLog('Failed to initialize timezone: $e');
    _devLog('Falling back to UTC');
    // Fallback to UTC
    tz.setLocalLocation(tz.getLocation('UTC'));
  }
}

/// Initialize the notification plugin.
///
/// Returns the initialized ReminderPlugin instance. If initialization fails,
/// returns an uninitialized instance (graceful degradation).
Future<ReminderPlugin> _initializeNotifications() async {
  final plugin = ReminderPlugin();

  try {
    _devLog('Initializing notification plugin...');
    final success = await plugin.initialize();

    if (success) {
      _devLog('Notification plugin initialized successfully');
    } else {
      _devLog('Notification plugin initialization failed');
      // Log to Crashlytics in production
      if (!FlavorConfig.isDevelopment) {
        await _logToCrashlytics(
          'ReminderPlugin initialization returned false',
        );
      }
    }
  } on Exception catch (e, stackTrace) {
    _devLog('Error initializing notification plugin: $e');
    _devLog('Stack trace: $stackTrace');

    // Log to Crashlytics in production
    if (!FlavorConfig.isDevelopment) {
      await _logToCrashlytics(
        'ReminderPlugin initialization failed: $e',
        stackTrace: stackTrace,
      );
    }
  }

  // Always return the plugin (graceful degradation)
  return plugin;
}

/// Log errors to Crashlytics in production.
Future<void> _logToCrashlytics(
  String message, {
  StackTrace? stackTrace,
}) async {
  try {
    final crashlytics = FirebaseService().crashlytics;
    await crashlytics.log(message);
    if (stackTrace != null) {
      await crashlytics.recordError(
        Exception(message),
        stackTrace,
      );
    }
  } on Exception catch (e) {
    // Silently fail if Crashlytics not available
    debugPrint('[Main] Failed to log to Crashlytics: $e');
  }
}

/// Check if app was launched by tapping a notification.
///
/// This handles the "cold start" case where the app is not running when
/// the user taps a notification. The payload is processed after the app
/// fully initializes (auth, onboarding, providers ready).
Future<void> _checkNotificationLaunchDetails(ReminderPlugin plugin) async {
  try {
    _devLog('Checking notification launch details...');

    final details = await plugin.getNotificationAppLaunchDetails();

    if (details != null &&
        details.didNotificationLaunchApp &&
        details.notificationResponse != null) {
      final payload = details.notificationResponse!.payload;

      if (payload != null && payload.isNotEmpty) {
        _devLog(
          'App launched from notification, '
          'payload: ${payload.substring(0, min(50, payload.length))}...',
        );

        // Trigger notification tap handler
        // The AppShell listener will process it once the app is ready
        NotificationTapHandler.notificationTapPayload = payload;
      } else {
        _devLog('App launched from notification but no payload');
      }
    } else {
      _devLog('App not launched from notification');
    }
  } on Exception catch (e, stackTrace) {
    _devLog('Error checking notification launch details: $e');
    _devLog('Stack trace: $stackTrace');
    // Don't rethrow - cold start should continue
  }
}

/// Log messages only in development flavor.
void _devLog(String message) {
  if (FlavorConfig.isDevelopment) {
    debugPrint('[Main Dev] $message');
  }
}
