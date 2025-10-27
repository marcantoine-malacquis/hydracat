import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/features/notifications/models/notification_settings.dart'
    as app_settings;
import 'package:hydracat/features/notifications/services/device_token_service.dart';
import 'package:hydracat/features/notifications/services/notification_index_store.dart';
import 'package:hydracat/features/notifications/services/notification_settings_service.dart';
import 'package:hydracat/features/notifications/services/permission_prompt_service.dart';
import 'package:hydracat/features/notifications/services/reminder_plugin.dart';
import 'package:hydracat/features/notifications/services/reminder_service.dart';
import 'package:permission_handler/permission_handler.dart';

/// Provider for the ReminderPlugin singleton instance.
///
/// This provides access to the notification plugin throughout the app
/// via Riverpod dependency injection. The plugin should be initialized
/// during app startup before this provider is used.
///
/// Example usage:
/// ```dart
/// final plugin = ref.read(reminderPluginProvider);
/// await plugin.showZoned(...);
/// ```
final reminderPluginProvider = Provider<ReminderPlugin>((ref) {
  return ReminderPlugin();
});

/// Provider for the DeviceTokenService singleton instance.
///
/// This provides access to the device token registration service
/// throughout the app via Riverpod dependency injection.
///
/// The service handles:
/// - Stable device ID generation and persistence
/// - Device registration in Firestore on sign-in
/// - FCM token refresh handling
///
/// Example usage:
/// ```dart
/// final service = ref.read(deviceTokenServiceProvider);
/// await service.registerDevice(userId);
/// ```
final deviceTokenServiceProvider = Provider<DeviceTokenService>((ref) {
  return DeviceTokenService();
});

/// Provider for the current device ID.
///
/// Returns a FutureProvider that resolves to the stable device ID
/// (UUID v4) for this device installation. The ID is generated once
/// and persisted in secure storage.
///
/// Example usage:
/// ```dart
/// final deviceIdAsync = ref.watch(currentDeviceIdProvider);
/// deviceIdAsync.when(
///   data: (deviceId) => Text('Device: $deviceId'),
///   loading: () => CircularProgressIndicator(),
///   error: (err, stack) => Text('Error: $err'),
/// );
/// ```
final currentDeviceIdProvider = FutureProvider<String>((ref) async {
  final service = ref.read(deviceTokenServiceProvider);
  return service.getOrCreateDeviceId();
});

/// Provider for the NotificationIndexStore singleton instance.
///
/// This provides access to the notification index storage service
/// throughout the app via Riverpod dependency injection.
///
/// The index store handles:
/// - Tracking scheduled notifications in SharedPreferences
/// - Idempotent scheduling operations
/// - Data integrity validation via checksum
/// - Reconciliation with plugin's pending notifications
///
/// Example usage:
/// ```dart
/// final store = ref.read(notificationIndexStoreProvider);
/// await store.putEntry(userId, petId, entry);
/// ```
final notificationIndexStoreProvider = Provider<NotificationIndexStore>((ref) {
  return NotificationIndexStore();
});

/// Provider for the ReminderService singleton instance.
///
/// This provides access to the reminder scheduling service throughout the app
/// via Riverpod dependency injection.
///
/// The service handles:
/// - Scheduling notifications for today's active schedules
/// - Canceling notifications when treatments logged or schedules deleted
/// - Idempotent rescheduling for recovery scenarios
/// - Generating privacy-first notification content
///
/// Example usage:
/// ```dart
/// final service = ref.read(reminderServiceProvider);
/// final result = await service.scheduleAllForToday(userId, petId, ref);
/// ```
final reminderServiceProvider = Provider<ReminderService>((ref) {
  return ReminderService();
});

// ============================================================================
// NOTIFICATION SETTINGS
// ============================================================================

/// Notifier for managing notification settings state with persistence.
///
/// Settings are automatically loaded on creation and persisted immediately
/// when changed. Each setter method updates both the in-memory state and
/// SharedPreferences storage.
///
/// This notifier is scoped by userId via a family provider, supporting
/// multi-user scenarios.
class NotificationSettingsNotifier
    extends StateNotifier<app_settings.NotificationSettings> {
  /// Creates a notification settings notifier for a specific user.
  ///
  /// Automatically loads settings from storage on creation.
  NotificationSettingsNotifier(this._userId)
      : super(app_settings.NotificationSettings.defaults()) {
    _loadSettings();
  }

  final String _userId;

  /// Loads settings from storage and updates state.
  Future<void> _loadSettings() async {
    final settings =
        await NotificationSettingsService.loadSettings(_userId);
    state = settings;
  }

  /// Toggles the master notification enable switch.
  ///
  /// When enabled, notifications will be scheduled (if permission granted).
  /// When disabled, no notifications are scheduled regardless of permission.
  Future<void> setEnableNotifications({required bool enabled}) async {
    final newSettings = state.copyWith(enableNotifications: enabled);
    state = newSettings;
    await NotificationSettingsService.saveSettings(_userId, newSettings);
  }

  /// Toggles weekly summary notifications.
  ///
  /// Weekly summaries fire on Monday at 09:00 and show treatment adherence
  /// for the past week. Requires enableNotifications to be true.
  Future<void> setWeeklySummaryEnabled({required bool enabled}) async {
    final newSettings = state.copyWith(weeklySummaryEnabled: enabled);
    state = newSettings;
    await NotificationSettingsService.saveSettings(_userId, newSettings);
  }

  /// Toggles snooze functionality for treatment reminders.
  ///
  /// When enabled, users can snooze reminders for 15 minutes.
  /// Requires enableNotifications to be true.
  Future<void> setSnoozeEnabled({required bool enabled}) async {
    final newSettings = state.copyWith(snoozeEnabled: enabled);
    state = newSettings;
    await NotificationSettingsService.saveSettings(_userId, newSettings);
  }

  /// Toggles end-of-day summary notifications.
  ///
  /// End-of-day summaries fire at the specified time and show outstanding
  /// treatments. Requires enableNotifications to be true.
  Future<void> setEndOfDayEnabled({required bool enabled}) async {
    final newSettings = state.copyWith(endOfDayEnabled: enabled);
    state = newSettings;
    await NotificationSettingsService.saveSettings(_userId, newSettings);
  }

  /// Sets the time for end-of-day summary notifications.
  ///
  /// Time must be in "HH:mm" format (24-hour).
  /// Throws [ArgumentError] if format is invalid.
  ///
  /// Example: `await setEndOfDayTime('22:00')`
  Future<void> setEndOfDayTime(String time) async {
    if (!app_settings.NotificationSettings.isValidTime(time)) {
      throw ArgumentError('Invalid time format: $time');
    }
    final newSettings = state.copyWith(endOfDayTime: time);
    state = newSettings;
    await NotificationSettingsService.saveSettings(_userId, newSettings);
  }

  /// Manually refreshes settings from storage.
  ///
  /// Call this after external changes to SharedPreferences or when
  /// troubleshooting sync issues. Generally not needed as all changes
  /// go through this notifier.
  Future<void> refresh() async {
    await _loadSettings();
  }
}

/// Provider for notification settings, scoped by user ID.
///
/// Automatically loads settings on creation and persists changes.
/// Use this to read and modify notification settings for a specific user.
///
/// Example usage:
/// ```dart
/// // Watch settings (rebuilds on changes)
/// final settings = ref.watch(notificationSettingsProvider(userId));
///
/// // Toggle notifications
/// await ref.read(notificationSettingsProvider(userId).notifier)
///     .setEnableNotifications(enabled: true);
/// ```
final StateNotifierProvider<NotificationSettingsNotifier,
        app_settings.NotificationSettings>
    Function(String) notificationSettingsProvider =
    StateNotifierProvider.family<
        NotificationSettingsNotifier,
        app_settings.NotificationSettings,
        String>(
  (ref, userId) => NotificationSettingsNotifier(userId),
);

// ============================================================================
// PERMISSION STATUS
// ============================================================================

/// Enum representing notification permission status across platforms.
enum NotificationPermissionStatus {
  /// Permission granted - notifications will be delivered
  granted,

  /// Permission denied by user - can prompt again (iOS) or
  /// show settings (Android)
  denied,

  /// Permission not yet requested (iOS provisional state or initial state)
  notDetermined,

  /// Permission permanently denied (Android only - user selected
  /// "Don't ask again")
  permanentlyDenied,
}

/// Notifier for checking and refreshing notification permission status.
///
/// Queries platform-specific permission APIs:
/// - iOS: Firebase Messaging authorization status
/// - Android: permission_handler notification permission
///
/// Call [refresh] when returning from system settings or on app resume
/// to update the permission status.
class NotificationPermissionNotifier
    extends StateNotifier<AsyncValue<NotificationPermissionStatus>> {
  /// Creates a permission notifier and immediately checks current status.
  NotificationPermissionNotifier() : super(const AsyncValue.loading()) {
    checkPermissionStatus();
  }

  /// Checks current platform notification permission status.
  ///
  /// Updates state with the current permission status. Call this:
  /// - On app startup (automatic via constructor)
  /// - After directing user to system settings
  /// - On app resume from background
  Future<void> checkPermissionStatus() async {
    state = const AsyncValue.loading();

    try {
      if (Platform.isIOS) {
        // iOS: Use Firebase Messaging authorization status
        final messaging = FirebaseMessaging.instance;
        final settings = await messaging.getNotificationSettings();

        final status = switch (settings.authorizationStatus) {
          AuthorizationStatus.authorized ||
          AuthorizationStatus.provisional =>
            NotificationPermissionStatus.granted,
          AuthorizationStatus.denied => NotificationPermissionStatus.denied,
          _ => NotificationPermissionStatus.notDetermined,
        };

        state = AsyncValue.data(status);
      } else {
        // Android: Use permission_handler
        const permission = Permission.notification;
        final permissionStatus = await permission.status;

        final status = switch (permissionStatus) {
          PermissionStatus.granted || PermissionStatus.limited =>
            NotificationPermissionStatus.granted,
          PermissionStatus.permanentlyDenied =>
            NotificationPermissionStatus.permanentlyDenied,
          PermissionStatus.denied => NotificationPermissionStatus.denied,
          _ => NotificationPermissionStatus.notDetermined,
        };

        state = AsyncValue.data(status);
      }
    } on Exception catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Refreshes permission status from platform.
  ///
  /// Call this when:
  /// - User returns from system settings
  /// - App resumes from background
  /// - After requesting permission
  Future<void> refresh() async {
    await checkPermissionStatus();
  }

  /// Requests notification permission from the system.
  ///
  /// Shows platform-specific permission dialog:
  /// - iOS: Firebase Messaging permission dialog with alert, sound, and badge
  /// - Android 13+: System notification permission dialog
  ///
  /// Returns the new permission status after the request completes.
  /// Updates the notifier state with the new status.
  ///
  /// Throws exceptions if the request fails. Caller should handle errors.
  ///
  /// Example usage:
  /// ```dart
  /// try {
  ///   final status = await ref
  ///       .read(notificationPermissionStatusProvider.notifier)
  ///       .requestPermission();
  ///   if (status == NotificationPermissionStatus.granted) {
  ///     // Permission granted!
  ///   }
  /// } catch (e) {
  ///   // Handle error
  /// }
  /// ```
  Future<NotificationPermissionStatus> requestPermission() async {
    try {
      if (Platform.isIOS) {
        // iOS: Request permission via Firebase Messaging
        final settings = await FirebaseMessaging.instance.requestPermission();

        final status = switch (settings.authorizationStatus) {
          AuthorizationStatus.authorized ||
          AuthorizationStatus.provisional =>
            NotificationPermissionStatus.granted,
          AuthorizationStatus.denied => NotificationPermissionStatus.denied,
          _ => NotificationPermissionStatus.notDetermined,
        };

        state = AsyncValue.data(status);
        return status;
      } else {
        // Android: Request permission via permission_handler
        const permission = Permission.notification;
        final result = await permission.request();

        final status = switch (result) {
          PermissionStatus.granted || PermissionStatus.limited =>
            NotificationPermissionStatus.granted,
          PermissionStatus.permanentlyDenied =>
            NotificationPermissionStatus.permanentlyDenied,
          PermissionStatus.denied => NotificationPermissionStatus.denied,
          _ => NotificationPermissionStatus.notDetermined,
        };

        state = AsyncValue.data(status);
        return status;
      }
    } on Exception catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }
}

/// Provider for notification permission status.
///
/// Checks platform permission on creation and provides refresh method.
/// Use AsyncValue.when to handle loading/error states.
///
/// Example usage:
/// ```dart
/// final permissionAsync =
///     ref.watch(notificationPermissionStatusProvider);
/// permissionAsync.when(
///   data: (status) {
///     if (status == NotificationPermissionStatus.granted) {
///       return Text('Notifications enabled');
///     } else {
///       return Text('Please enable notifications');
///     }
///   },
///   loading: () => CircularProgressIndicator(),
///   error: (err, stack) => Text('Error checking permission'),
/// );
///
/// // Refresh after returning from settings
/// ref.read(notificationPermissionStatusProvider.notifier).refresh();
/// ```
final StateNotifierProvider<NotificationPermissionNotifier,
        AsyncValue<NotificationPermissionStatus>>
    notificationPermissionStatusProvider = StateNotifierProvider<
        NotificationPermissionNotifier,
        AsyncValue<NotificationPermissionStatus>>(
  (ref) => NotificationPermissionNotifier(),
);

// ============================================================================
// DERIVED PROVIDERS
// ============================================================================

/// Provider that combines permission status + user setting to determine
/// if notifications are effectively enabled.
///
/// Returns true only if BOTH conditions are met:
/// 1. Platform permission is granted
/// 2. User has enableNotifications set to true
///
/// Use this to conditionally show notification-related UI or schedule
/// notifications.
///
/// Example usage:
/// ```dart
/// final isEnabled = ref.watch(isNotificationEnabledProvider(userId));
/// if (isEnabled) {
///   // Schedule notifications
/// } else {
///   // Show prompt to enable
/// }
/// ```
final Provider<bool> Function(String) isNotificationEnabledProvider =
    Provider.family<bool, String>(
  (ref, userId) {
    final settings = ref.watch(notificationSettingsProvider(userId));
    final permissionAsync = ref.watch(notificationPermissionStatusProvider);

    return permissionAsync.maybeWhen(
      data: (permissionStatus) {
        final permissionGranted =
            permissionStatus == NotificationPermissionStatus.granted;
        final settingEnabled = settings.enableNotifications;
        return permissionGranted && settingEnabled;
      },
      orElse: () => false,
    );
  },
);

/// Enum describing why notifications are disabled.
///
/// Use this to show appropriate prompts to the user.
enum NotificationDisabledReason {
  /// Platform permission denied - direct user to system settings
  permissionDenied,

  /// User disabled notifications in app settings - show in-app toggle
  settingDisabled,

  /// Both permission and setting are disabled
  both,

  /// Notifications are enabled (no issue)
  none,
}

/// Provider that determines why notifications are disabled.
///
/// Use this to show context-appropriate prompts:
/// - permissionDenied: "Enable in Settings" button
/// - settingDisabled: In-app toggle explanation
/// - both: Combined message
/// - none: Notifications working, no prompt needed
///
/// Example usage:
/// ```dart
/// final reason = ref.watch(notificationDisabledReasonProvider(userId));
/// switch (reason) {
///   case NotificationDisabledReason.permissionDenied:
///     return ElevatedButton(
///       onPressed: () => openAppSettings(),
///       child: Text('Enable in Settings'),
///     );
///   case NotificationDisabledReason.settingDisabled:
///     return Text('Enable notifications in app settings');
///   case NotificationDisabledReason.both:
///     return Text('Enable permission and app setting');
///   case NotificationDisabledReason.none:
///     return Text('Notifications enabled');
/// }
/// ```
final Provider<NotificationDisabledReason> Function(String)
    notificationDisabledReasonProvider =
    Provider.family<NotificationDisabledReason, String>(
  (ref, userId) {
    final settings = ref.watch(notificationSettingsProvider(userId));
    final permissionAsync = ref.watch(notificationPermissionStatusProvider);

    return permissionAsync.maybeWhen(
      data: (permissionStatus) {
        final permissionGranted =
            permissionStatus == NotificationPermissionStatus.granted;
        final settingEnabled = settings.enableNotifications;

        if (permissionGranted && settingEnabled) {
          return NotificationDisabledReason.none;
        } else if (!permissionGranted && !settingEnabled) {
          return NotificationDisabledReason.both;
        } else if (!permissionGranted) {
          return NotificationDisabledReason.permissionDenied;
        } else {
          return NotificationDisabledReason.settingDisabled;
        }
      },
      orElse: () => NotificationDisabledReason.permissionDenied,
    );
  },
);

// ============================================================================
// PERMISSION PROMPT CONTROL
// ============================================================================

/// Provider that determines whether the permission pre-prompt should be shown.
///
/// This provider combines multiple conditions to determine if the proactive
/// permission pre-prompt should be displayed to the user:
///
/// Conditions checked:
/// 1. Permission is not granted (permission denied or not determined)
/// 2. Prompt has not been shown before (tracked in SharedPreferences)
/// 3. User has completed onboarding (implicit - caller checks this)
///
/// The prompt is shown proactively only once after onboarding completion.
/// If the user dismisses it with "Maybe Later", it won't be shown again
/// proactively, though they can still access it via:
/// - Tapping the notification bell icon when permission denied
/// - Navigating to notification settings
///
/// Returns `false` if permission is already granted or if prompt has been
/// shown before. Returns `true` if the prompt should be displayed.
///
/// Example usage:
/// ```dart
/// // In AppShell after onboarding completed
/// final shouldShow = await ref.read(
///   shouldShowPermissionPromptProvider(currentUser.id).future
/// );
///
/// if (shouldShow) {
///   await showDialog(
///     context: context,
///     builder: (context) => const NotificationPermissionPreprompt(),
///   );
/// }
/// ```
///
/// Cost: 0 Firestore reads (checks SharedPreferences + in-memory state only)
final FutureProvider<bool> Function(String) shouldShowPermissionPromptProvider =
    FutureProvider.family<bool, String>(
  (ref, userId) async {
    // Check if permission is already granted
    final permissionAsync = ref.watch(notificationPermissionStatusProvider);

    final permissionStatus = permissionAsync.value;
    if (permissionStatus == NotificationPermissionStatus.granted) {
      // Permission already granted, no need to show prompt
      return false;
    }

    // Check if prompt has been shown before
    final hasShown = await PermissionPromptService.hasShownPrompt(userId);

    // Show prompt only if not shown before and permission not granted
    return !hasShown;
  },
);
