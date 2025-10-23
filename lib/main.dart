import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/app/app.dart';
import 'package:hydracat/core/config/flavor_config.dart';
import 'package:hydracat/features/notifications/providers/notification_provider.dart';
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
}

/// Initialize timezone database for scheduling notifications.
///
/// This must be called before scheduling any timezone-aware notifications.
/// Uses the device's local timezone automatically.
Future<void> _initializeTimezone() async {
  try {
    _devLog('Initializing timezone database...');
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.local);
    _devLog('Timezone initialized: ${tz.local.name}');
  } on Exception catch (e) {
    _devLog('Failed to initialize timezone: $e');
    // Continue anyway - timezone will use UTC as fallback
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

/// Log messages only in development flavor.
void _devLog(String message) {
  if (FlavorConfig.isDevelopment) {
    debugPrint('[Main Dev] $message');
  }
}
