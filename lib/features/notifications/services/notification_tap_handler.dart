import 'package:flutter/foundation.dart';
import 'package:hydracat/core/config/flavor_config.dart';

/// Service for handling notification tap events and deep-linking.
///
/// This service provides a simple communication channel between the
/// notification plugin layer and the UI layer using a ValueNotifier pattern.
/// When a notification is tapped or an action button is pressed, the payload
/// is stored here and the AppShell listener processes it appropriately.
///
/// Usage:
/// ```dart
/// // In notification plugin callback:
/// NotificationTapHandler.notificationTapPayload = payload;
///
/// // In UI layer (AppShell):
/// NotificationTapHandler.pendingTapPayload.addListener(
///   _handleNotificationTap,
/// );
/// ```
class NotificationTapHandler {
  /// ValueNotifier for pending notification tap payloads.
  ///
  /// When a notification is tapped (body or "Log now" action), the payload
  /// JSON string is stored here. UI listeners (AppShell) should watch this
  /// notifier and process the payload when it changes from null to a non-null
  /// value.
  ///
  /// The payload should be cleared immediately after processing to avoid
  /// re-triggering the handler.
  static final ValueNotifier<String?> pendingTapPayload =
      ValueNotifier<String?>(null);

  /// Get the current notification tap payload.
  ///
  /// Returns the current payload value from the ValueNotifier.
  static String? get notificationTapPayload => pendingTapPayload.value;

  /// Set the notification tap payload.
  ///
  /// This setter is called by the notification plugin when a notification
  /// is tapped. The payload should be a JSON string containing:
  /// - userId: User ID who scheduled the notification
  /// - petId: Pet ID for the treatment
  /// - scheduleIds: Comma-separated schedule IDs (for bundled notifications)
  /// - timeSlot: Time slot in "HH:mm" format
  /// - kind: Notification kind (initial/followup)
  /// - treatmentTypes: Comma-separated treatment types
  ///
  /// The UI layer (AppShell) is responsible for validating the payload
  /// and navigating to the home screen (where treatments are displayed).
  static set notificationTapPayload(String payload) {
    _devLog('');
    _devLog('═══════════════════════════════════════════════════════');
    _devLog('📥 NotificationTapHandler SETTER CALLED');
    _devLog('═══════════════════════════════════════════════════════');
    _devLog('Timestamp: ${DateTime.now().toIso8601String()}');
    _devLog('Previous value: ${pendingTapPayload.value}');
    _devLog('New payload: $payload');
    _devLog('');

    // Set the new value
    pendingTapPayload.value = payload;

    _devLog('✅ ValueNotifier.value SET');
    _devLog('Current value: ${pendingTapPayload.value}');
    _devLog(
      'Listeners should be notified now if any are registered...',
    );
    _devLog('═══════════════════════════════════════════════════════');
    _devLog('');
  }

  /// Clear the pending notification tap payload.
  ///
  /// This should be called immediately after processing a notification tap
  /// to prevent re-triggering the handler if the notifier is still being
  /// observed.
  static void clearPendingTap() {
    _devLog('');
    _devLog('🧹 NotificationTapHandler.clearPendingTap() called');
    _devLog('Previous value: ${pendingTapPayload.value}');
    pendingTapPayload.value = null;
    _devLog('✅ Payload cleared (set to null)');
    _devLog('');
  }

  /// Log messages only in development flavor
  static void _devLog(String message) {
    if (FlavorConfig.isDevelopment) {
      debugPrint('[NotificationTapHandler Dev] $message');
    }
  }
}
