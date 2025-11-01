import 'package:flutter/material.dart';
import 'package:hydracat/features/notifications/utils/time_validation.dart';

/// Model representing user notification preferences.
///
/// Stores all notification-related settings including master toggle,
/// feature-specific toggles (weekly summary, end-of-day, snooze),
/// and privacy preferences (lock screen content).
///
/// Settings are persisted locally in SharedPreferences, scoped by userId.
/// Future versions may optionally sync to Firestore.
///
/// Example usage:
/// ```dart
/// final settings = NotificationSettings.defaults();
/// final updated = settings.copyWith(enableNotifications: false);
/// ```
@immutable
class NotificationSettings {
  /// Creates a [NotificationSettings] instance.
  const NotificationSettings({
    required this.enableNotifications,
    required this.weeklySummaryEnabled,
    required this.snoozeEnabled,
    required this.endOfDayEnabled,
    required this.endOfDayTime,
  });

  /// Creates default settings for new users.
  ///
  /// Defaults align with medical app best practices:
  /// - Notifications enabled by default (core value proposition)
  /// - Weekly summary enabled (engagement)
  /// - Snooze enabled (flexibility)
  /// - End-of-day disabled (opt-in to avoid notification fatigue)
  /// - Generic notification content (privacy-first, no medication details)
  factory NotificationSettings.defaults() {
    return const NotificationSettings(
      enableNotifications: true,
      weeklySummaryEnabled: true,
      snoozeEnabled: true,
      endOfDayEnabled: false,
      endOfDayTime: '22:00',
    );
  }

  /// Creates a settings instance from a JSON map.
  ///
  /// Returns [NotificationSettings.defaults] if required fields are missing.
  /// Uses default values for optional/new fields to support schema evolution.
  ///
  /// Example:
  /// ```dart
  /// final json = {'enableNotifications': true, ...};
  /// final settings = NotificationSettings.fromJson(json);
  /// ```
  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    try {
      return NotificationSettings(
        enableNotifications: json['enableNotifications'] as bool? ?? true,
        weeklySummaryEnabled: json['weeklySummaryEnabled'] as bool? ?? true,
        snoozeEnabled: json['snoozeEnabled'] as bool? ?? true,
        endOfDayEnabled: json['endOfDayEnabled'] as bool? ?? false,
        endOfDayTime: json['endOfDayTime'] as String? ?? '22:00',
      );
    } on Exception {
      // If parsing fails, return defaults
      return NotificationSettings.defaults();
    }
  }

  /// Master toggle for all notifications.
  ///
  /// When false, no notifications are scheduled even if permission granted.
  /// When true, notifications are scheduled only if platform permission
  /// granted.
  final bool enableNotifications;

  /// Whether weekly summary notifications are enabled.
  ///
  /// Weekly summaries fire on Monday at 09:00 and show treatment adherence
  /// statistics for the past week. Requires [enableNotifications] to be true.
  final bool weeklySummaryEnabled;

  /// Whether snooze functionality is enabled for treatment reminders.
  ///
  /// When enabled, users can snooze reminders for 15 minutes from the
  /// notification. Requires [enableNotifications] to be true.
  final bool snoozeEnabled;

  /// Whether end-of-day summary notifications are enabled.
  ///
  /// End-of-day summaries fire at [endOfDayTime] and show any outstanding
  /// (unlogged) treatments for the day. Requires [enableNotifications]
  /// to be true.
  final bool endOfDayEnabled;

  /// Time of day for end-of-day summary notification in "HH:mm" format.
  ///
  /// Must be a valid 24-hour time string (e.g., "22:00", "08:30").
  /// Default is "22:00". This field is ignored if [endOfDayEnabled] is false.
  ///
  /// Use [isValidTime] to validate before setting.
  /// Use [endOfDayTimeOfDay] to convert to Flutter's TimeOfDay for UI.
  ///
  /// Note: All notifications use generic, privacy-first content by default.
  /// Medication names, dosages, and fluid volumes are never shown in
  /// notification text (lock screen or notification center).
  final String endOfDayTime;

  /// Validates a time string in "HH:mm" format.
  ///
  /// Returns true if the time is valid (00:00 to 23:59).
  ///
  /// Example:
  /// ```dart
  /// NotificationSettings.isValidTime('22:00') // true
  /// NotificationSettings.isValidTime('25:00') // false
  /// NotificationSettings.isValidTime('12:00') // true
  /// NotificationSettings.isValidTime('invalid') // false
  /// ```
  static bool isValidTime(String time) => isValidTimeString(time);

  /// Converts the endOfDayTime string to Flutter's TimeOfDay for UI.
  ///
  /// Assumes endOfDayTime is valid (use isValidTime to check).
  ///
  /// Example:
  /// ```dart
  /// final settings = NotificationSettings.defaults();
  /// // endOfDayTime = "22:00"
  /// final timeOfDay = settings.endOfDayTimeOfDay;
  /// // TimeOfDay(hour: 22, minute: 0)
  /// ```
  TimeOfDay get endOfDayTimeOfDay {
    final parts = endOfDayTime.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  /// Formats a TimeOfDay to "HH:mm" string format.
  ///
  /// Use this when saving time from Flutter's TimePicker widget.
  ///
  /// Example:
  /// ```dart
  /// final time = TimeOfDay(hour: 22, minute: 30);
  /// final formatted = NotificationSettings.formatTimeOfDay(time);
  /// // Returns "22:30"
  /// ```
  static String formatTimeOfDay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }

  /// Creates a copy of this settings with the given fields replaced.
  NotificationSettings copyWith({
    bool? enableNotifications,
    bool? weeklySummaryEnabled,
    bool? snoozeEnabled,
    bool? endOfDayEnabled,
    String? endOfDayTime,
  }) {
    return NotificationSettings(
      enableNotifications: enableNotifications ?? this.enableNotifications,
      weeklySummaryEnabled: weeklySummaryEnabled ?? this.weeklySummaryEnabled,
      snoozeEnabled: snoozeEnabled ?? this.snoozeEnabled,
      endOfDayEnabled: endOfDayEnabled ?? this.endOfDayEnabled,
      endOfDayTime: endOfDayTime ?? this.endOfDayTime,
    );
  }

  /// Converts this settings instance to a JSON-serializable map.
  ///
  /// Used for SharedPreferences persistence and future Firestore sync.
  Map<String, dynamic> toJson() {
    return {
      'enableNotifications': enableNotifications,
      'weeklySummaryEnabled': weeklySummaryEnabled,
      'snoozeEnabled': snoozeEnabled,
      'endOfDayEnabled': endOfDayEnabled,
      'endOfDayTime': endOfDayTime,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is NotificationSettings &&
        other.enableNotifications == enableNotifications &&
        other.weeklySummaryEnabled == weeklySummaryEnabled &&
        other.snoozeEnabled == snoozeEnabled &&
        other.endOfDayEnabled == endOfDayEnabled &&
        other.endOfDayTime == endOfDayTime;
  }

  @override
  int get hashCode {
    return Object.hash(
      enableNotifications,
      weeklySummaryEnabled,
      snoozeEnabled,
      endOfDayEnabled,
      endOfDayTime,
    );
  }

  @override
  String toString() {
    return 'NotificationSettings('
        'enableNotifications: $enableNotifications, '
        'weeklySummaryEnabled: $weeklySummaryEnabled, '
        'snoozeEnabled: $snoozeEnabled, '
        'endOfDayEnabled: $endOfDayEnabled, '
        'endOfDayTime: $endOfDayTime'
        ')';
  }
}
