import 'package:flutter/foundation.dart';

/// Service for handling notification tap events and deep-linking.
///
/// This service provides a simple communication channel between the
/// notification plugin layer and the UI layer using a ValueNotifier pattern.
/// When a notification is tapped, the payload is stored here and the
/// AppShell listener processes it to navigate to the appropriate screen.
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
  /// When a notification is tapped, the payload JSON string is stored here.
  /// UI listeners (AppShell) should watch this notifier and process the
  /// payload when it changes from null to a non-null value.
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
  /// - scheduleId: Schedule ID for the treatment
  /// - timeSlot: Time slot in "HH:mm" format
  /// - kind: Notification kind (initial/followup/snooze)
  /// - treatmentType: Type of treatment (medication/fluid)
  ///
  /// The UI layer (AppShell) is responsible for validating the payload
  /// and navigating to the appropriate screen.
  static set notificationTapPayload(String payload) {
    pendingTapPayload.value = payload;
  }

  /// Clear the pending notification tap payload.
  ///
  /// This should be called immediately after processing a notification tap
  /// to prevent re-triggering the handler if the notifier is still being
  /// observed.
  static void clearPendingTap() {
    pendingTapPayload.value = null;
  }
}
