import 'package:flutter/foundation.dart';
import 'package:hydracat/features/notifications/utils/time_validation.dart';
import 'package:timezone/timezone.dart' as tz;

/// Utility functions for timezone-aware notification scheduling.
///
/// Provides helper functions for:
/// - Converting time-of-day strings to timezone-aware datetimes
/// - Evaluating grace period logic for late/missed reminders
/// - Calculating follow-up notification times with edge-case handling

/// Enum for grace period evaluation results.
enum NotificationSchedulingDecision {
  /// Schedule for future time (not yet due)
  scheduled,

  /// Fire immediately (within grace period)
  immediate,

  /// Don't schedule (past grace period - missed)
  missed,
}

/// Converts a time-of-day string ("HH:mm") to a timezone-aware TZDateTime
/// for today.
///
/// This function takes a time in "HH:mm" format and creates a TZDateTime
/// for the specified time on the reference date, using the local timezone.
/// This handles DST transitions correctly.
///
/// Parameters:
/// - [timeSlot]: Time in "HH:mm" format (e.g., "08:00", "14:30")
/// - [referenceDate]: The date to use (typically DateTime.now())
///
/// Returns: TZDateTime for the specified time on referenceDate in local
/// timezone
///
/// Example:
/// ```dart
/// final scheduledTime = zonedDateTimeForToday(
///   "08:00",
///   DateTime(2024, 1, 15),
/// );
/// // Returns: TZDateTime for 2024-01-15 at 08:00 local time
/// ```
///
/// Throws:
/// - [FormatException] if timeSlot is not in valid "HH:mm" format
tz.TZDateTime zonedDateTimeForToday(
  String timeSlot,
  DateTime referenceDate,
) {
  // Parse and validate time string
  final (hour, minute) = parseTimeString(timeSlot);

  // Create TZDateTime for the specified time today in local timezone
  // This handles DST transitions correctly
  return tz.TZDateTime(
    tz.local,
    referenceDate.year,
    referenceDate.month,
    referenceDate.day,
    hour,
    minute,
  );
}

/// Determines if a scheduled time is within grace period (should fire
/// immediately).
///
/// Grace period logic:
/// - If scheduled time is in the past but within gracePeriodMinutes of now:
///   return immediate
/// - If scheduled time is in the future: return scheduled
/// - If scheduled time is past grace period: return missed (don't schedule)
///
/// Parameters:
/// - [scheduledTime]: The intended notification time
/// - [now]: Current time (for testing injection)
/// - [gracePeriodMinutes]: Grace period in minutes (default: 30)
///
/// Returns: [NotificationSchedulingDecision] enum value
///
/// Example:
/// ```dart
/// final decision = evaluateGracePeriod(
///   scheduledTime: DateTime(2024, 1, 1, 8, 0),
///   now: DateTime(2024, 1, 1, 8, 15), // 15 min late
///   gracePeriodMinutes: 30,
/// );
/// // Returns: NotificationSchedulingDecision.immediate
/// ```
NotificationSchedulingDecision evaluateGracePeriod({
  required DateTime scheduledTime,
  required DateTime now,
  int gracePeriodMinutes = 30,
}) {
  final difference = scheduledTime.difference(now);

  // Future time: schedule normally
  if (difference.inMinutes >= 0) {
    return NotificationSchedulingDecision.scheduled;
  }

  // Past time: check if within grace period
  final minutesLate = difference.inMinutes.abs();

  if (minutesLate <= gracePeriodMinutes) {
    // Within grace period: fire immediately
    if (kDebugMode) {
      debugPrint(
        '[Notifications Dev] Grace period: $minutesLate min late, '
        'firing immediately',
      );
    }
    return NotificationSchedulingDecision.immediate;
  } else {
    // Past grace period: missed
    if (kDebugMode) {
      debugPrint(
        '[Notifications Dev] Missed reminder: $minutesLate min late, '
        'skipping',
      );
    }
    return NotificationSchedulingDecision.missed;
  }
}

/// Calculates follow-up notification time based on initial time and offset.
///
/// If initial time + offset would be past 23:59, schedules for next morning
/// at 08:00 to avoid late-night notifications.
///
/// Parameters:
/// - [initialTime]: The initial reminder time
/// - [followupOffsetHours]: Hours after initial (e.g., 2 for +2h)
///
/// Returns: TZDateTime for follow-up notification
///
/// Example:
/// ```dart
/// final followup = calculateFollowupTime(
///   initialTime: tz.TZDateTime(tz.local, 2024, 1, 1, 22, 0), // 22:00
///   followupOffsetHours: 2,
/// );
/// // Returns: TZDateTime for 2024-01-02 at 08:00 (next day, not 00:00)
/// ```
tz.TZDateTime calculateFollowupTime({
  required tz.TZDateTime initialTime,
  required int followupOffsetHours,
}) {
  // Calculate potential follow-up time by adding offset
  final potentialFollowup =
      initialTime.add(Duration(hours: followupOffsetHours));

  // Check if potential follow-up is past 23:59 (end of day)
  // If so, schedule for next morning at 08:00 instead
  final endOfDay = tz.TZDateTime(
    tz.local,
    initialTime.year,
    initialTime.month,
    initialTime.day,
    23,
  );

  if (potentialFollowup.isAfter(endOfDay)) {
    // Past end of day: schedule for next morning at 08:00
    final nextDay = initialTime.add(const Duration(days: 1));
    final nextMorning = tz.TZDateTime(
      tz.local,
      nextDay.year,
      nextDay.month,
      nextDay.day,
      8, // 08:00
    );

    if (kDebugMode) {
      debugPrint(
        '[Notifications Dev] Follow-up would be past 23:59, '
        'scheduling for next morning at 08:00',
      );
    }

    return nextMorning;
  }

  // Follow-up is same day: return as calculated
  return potentialFollowup;
}
