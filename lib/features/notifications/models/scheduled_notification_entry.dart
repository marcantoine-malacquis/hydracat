import 'package:flutter/foundation.dart';

/// Model representing a single scheduled notification entry in the local index.
///
/// Each entry corresponds to one notification scheduled via the platform's
/// notification system (flutter_local_notifications). The index enables
/// idempotent scheduling operations and robust reconciliation after app
/// restarts or crashes.
///
/// Entries are stored per-day, per-pet, per-user in SharedPreferences with
/// CRC32 checksum validation for corruption detection.
///
/// Example usage:
/// ```dart
/// final entry = ScheduledNotificationEntry(
///   notificationId: 12345,
///   scheduleId: 'sched_abc123',
///   treatmentType: 'medication',
///   timeSlotISO: '08:00',
///   kind: 'initial',
/// );
/// ```
@immutable
class ScheduledNotificationEntry {
  /// Creates a [ScheduledNotificationEntry] instance.
  ///
  /// Throws [ArgumentError] if any validation fails.
  const ScheduledNotificationEntry({
    required this.notificationId,
    required this.scheduleId,
    required this.treatmentType,
    required this.timeSlotISO,
    required this.kind,
  });

  /// Creates an entry from a JSON map.
  ///
  /// Returns null if required fields are missing or validation fails.
  /// This ensures graceful handling of corrupted data.
  factory ScheduledNotificationEntry.fromJson(Map<String, dynamic> json) {
    try {
      final notificationId = json['notificationId'] as int?;
      final scheduleId = json['scheduleId'] as String?;
      final treatmentType = json['treatmentType'] as String?;
      final timeSlotISO = json['timeSlotISO'] as String?;
      final kind = json['kind'] as String?;

      // Validate required fields exist
      if (notificationId == null ||
          scheduleId == null ||
          treatmentType == null ||
          timeSlotISO == null ||
          kind == null) {
        if (kDebugMode) {
          debugPrint(
            '[ScheduledNotificationEntry] Missing required fields in JSON: '
            '$json',
          );
        }
        throw ArgumentError('Missing required fields');
      }

      // Validate field values
      if (!isValidTreatmentType(treatmentType)) {
        throw ArgumentError('Invalid treatmentType: $treatmentType');
      }
      if (!isValidTimeSlot(timeSlotISO)) {
        throw ArgumentError('Invalid timeSlotISO: $timeSlotISO');
      }
      if (!isValidKind(kind)) {
        throw ArgumentError('Invalid kind: $kind');
      }

      return ScheduledNotificationEntry(
        notificationId: notificationId,
        scheduleId: scheduleId,
        treatmentType: treatmentType,
        timeSlotISO: timeSlotISO,
        kind: kind,
      );
    } on Exception catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[ScheduledNotificationEntry] Failed to parse JSON: $e',
        );
      }
      throw ArgumentError('Invalid JSON data: $e');
    }
  }

  /// Platform notification ID (unique integer for plugin scheduling).
  ///
  /// This ID is deterministically generated from userId, petId, scheduleId,
  /// timeSlot, and kind to ensure idempotent scheduling.
  final int notificationId;

  /// Schedule ID from Firestore (references Schedule.id).
  ///
  /// Used to match notifications to schedules and cancel when schedule deleted.
  final String scheduleId;

  /// Treatment type: "medication" or "fluid".
  ///
  /// Determines notification channel and content on Android.
  final String treatmentType;

  /// Time slot in "HH:mm" format (24-hour time, e.g., "08:00", "22:30").
  ///
  /// Represents the local time when the reminder should fire.
  /// Must be valid time (00:00 to 23:59).
  final String timeSlotISO;

  /// Notification kind: "initial", "followup", or "snooze".
  ///
  /// - "initial": First reminder at scheduled time
  /// - "followup": Follow-up reminder (e.g., +2h after initial)
  /// - "snooze": User-triggered snooze (e.g., +15m)
  final String kind;

  /// Validates a treatment type string.
  ///
  /// Returns true if the type is "medication" or "fluid".
  ///
  /// Example:
  /// ```dart
  /// ScheduledNotificationEntry.isValidTreatmentType('medication') // true
  /// ScheduledNotificationEntry.isValidTreatmentType('invalid') // false
  /// ```
  static bool isValidTreatmentType(String type) {
    return type == 'medication' || type == 'fluid';
  }

  /// Validates a time slot string in "HH:mm" format.
  ///
  /// Returns true if the time is valid (00:00 to 23:59).
  ///
  /// Example:
  /// ```dart
  /// ScheduledNotificationEntry.isValidTimeSlot('08:00') // true
  /// ScheduledNotificationEntry.isValidTimeSlot('25:00') // false
  /// ScheduledNotificationEntry.isValidTimeSlot('invalid') // false
  /// ```
  static bool isValidTimeSlot(String timeSlot) {
    // Check format: exactly 5 characters, format "HH:mm"
    final regex = RegExp(r'^\d{2}:\d{2}$');
    if (!regex.hasMatch(timeSlot)) {
      return false;
    }

    // Parse hour and minute
    final parts = timeSlot.split(':');
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);

    // Validate ranges: 00-23 for hours, 00-59 for minutes
    if (hour == null || minute == null) {
      return false;
    }

    return hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59;
  }

  /// Validates a notification kind string.
  ///
  /// Returns true if the kind is "initial", "followup", or "snooze".
  ///
  /// Example:
  /// ```dart
  /// ScheduledNotificationEntry.isValidKind('initial') // true
  /// ScheduledNotificationEntry.isValidKind('invalid') // false
  /// ```
  static bool isValidKind(String kind) {
    return kind == 'initial' || kind == 'followup' || kind == 'snooze';
  }

  /// Converts this entry to a JSON-serializable map.
  ///
  /// Used for SharedPreferences persistence.
  Map<String, dynamic> toJson() {
    return {
      'notificationId': notificationId,
      'scheduleId': scheduleId,
      'treatmentType': treatmentType,
      'timeSlotISO': timeSlotISO,
      'kind': kind,
    };
  }

  /// Creates a copy of this entry with the given fields replaced.
  ScheduledNotificationEntry copyWith({
    int? notificationId,
    String? scheduleId,
    String? treatmentType,
    String? timeSlotISO,
    String? kind,
  }) {
    return ScheduledNotificationEntry(
      notificationId: notificationId ?? this.notificationId,
      scheduleId: scheduleId ?? this.scheduleId,
      treatmentType: treatmentType ?? this.treatmentType,
      timeSlotISO: timeSlotISO ?? this.timeSlotISO,
      kind: kind ?? this.kind,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ScheduledNotificationEntry &&
        other.notificationId == notificationId &&
        other.scheduleId == scheduleId &&
        other.treatmentType == treatmentType &&
        other.timeSlotISO == timeSlotISO &&
        other.kind == kind;
  }

  @override
  int get hashCode {
    return Object.hash(
      notificationId,
      scheduleId,
      treatmentType,
      timeSlotISO,
      kind,
    );
  }

  @override
  String toString() {
    return 'ScheduledNotificationEntry('
        'notificationId: $notificationId, '
        'scheduleId: $scheduleId, '
        'treatmentType: $treatmentType, '
        'timeSlotISO: $timeSlotISO, '
        'kind: $kind'
        ')';
  }
}
