/// Utility functions for formatting time slots for notifications
///
/// Provides standardized formatting for time slots used in notification
/// scheduling and cancellation. All time slots use "HH:mm" format with
/// zero-padding to ensure consistency across the notification system.
library;

/// Formats a DateTime to a time slot string in "HH:mm" format.
///
/// This is the standard format used throughout the notification system for:
/// - Notification IDs (deterministic generation)
/// - NotificationIndexStore entries (time slot keys)
/// - Schedule matching (±2 hour window)
/// - Cancellation operations (cancelSlot)
///
/// The format uses 24-hour time with zero-padding:
/// - 9:00 AM → "09:00"
/// - 3:30 PM → "15:30"
/// - 12:00 AM → "00:00"
///
/// Example usage:
/// ```dart
/// final scheduledTime = DateTime(2025, 1, 28, 9, 30);
/// final timeSlot = formatTimeSlotFromDateTime(scheduledTime);
/// // Returns: "09:30"
///
/// await reminderService.cancelSlot(
///   userId,
///   petId,
///   scheduleId,
///   timeSlot, // "09:30"
///   ref,
/// );
/// ```
///
/// Parameters:
/// - [dateTime]: The DateTime to format (only hour and minute are used)
///
/// Returns: Time slot string in "HH:mm" format
String formatTimeSlotFromDateTime(DateTime dateTime) {
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
