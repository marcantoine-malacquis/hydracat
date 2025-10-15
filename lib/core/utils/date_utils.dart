import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Utility class for date and time formatting and manipulation.
class AppDateUtils {
  /// Format date for display
  static String formatDate(DateTime date, {String? pattern}) {
    final formatter = DateFormat(pattern ?? 'MMM dd, yyyy');
    return formatter.format(date);
  }

  /// Format time for display
  static String formatTime(DateTime time, {String? pattern}) {
    final formatter = DateFormat(pattern ?? 'HH:mm');
    return formatter.format(time);
  }

  /// Format date and time for display
  static String formatDateTime(DateTime dateTime, {String? pattern}) {
    final formatter = DateFormat(pattern ?? 'MMM dd, yyyy HH:mm');
    return formatter.format(dateTime);
  }

  /// Get relative time (e.g., "2 hours ago")
  static String getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour'
          '${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute'
          '${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  /// Check if date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Check if date is yesterday
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }

  /// Get start of day
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Get end of day
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }

  /// Get start of week
  static DateTime startOfWeek(DateTime date) {
    final weekday = date.weekday;
    return date.subtract(Duration(days: weekday - 1));
  }

  /// Get start of week (Monday) normalized to 00:00:00
  ///
  /// Returns the Monday at midnight for the week containing the given date.
  /// Uses ISO 8601 week definition (Monday as first day of week).
  /// Normalizes to 00:00:00 to avoid time-of-day drift and DST issues.
  ///
  /// Example:
  /// ```dart
  /// final date = DateTime(2025, 10, 5, 14, 30); // Sunday afternoon
  /// final monday = startOfWeekMonday(date);
  /// // Returns: Monday, September 29, 2025 00:00:00
  /// ```
  static DateTime startOfWeekMonday(DateTime date) {
    final monday = date.subtract(
      Duration(days: date.weekday - DateTime.monday),
    );
    return DateTime(monday.year, monday.month, monday.day);
  }

  /// Check if two dates are the same day (ignoring time)
  ///
  /// Compares only year, month, and day components.
  ///
  /// Example:
  /// ```dart
  /// final date1 = DateTime(2025, 10, 5, 9, 0);
  /// final date2 = DateTime(2025, 10, 5, 18, 30);
  /// isSameDay(date1, date2); // true
  /// ```
  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Get end of week
  static DateTime endOfWeek(DateTime date) {
    final weekday = date.weekday;
    final daysUntilEnd = 7 - weekday;
    return date.add(Duration(days: daysUntilEnd));
  }

  /// Get start of month
  static DateTime startOfMonth(DateTime date) {
    return DateTime(date.year, date.month);
  }

  /// Get end of month
  static DateTime endOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }

  /// Calculate age from birth date
  static int calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    var age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  /// Calculate total age in months from birth date
  static int calculateAgeInMonths(DateTime birthDate) {
    final now = DateTime.now();

    // Calculate total months
    var months = (now.year - birthDate.year) * 12;
    months += now.month - birthDate.month;

    // Adjust if the day hasn't been reached yet this month
    if (now.day < birthDate.day) {
      months--;
    }

    return months;
  }

  /// Calculate age with months precision for display
  static String calculateAgeWithMonths(DateTime birthDate) {
    final totalMonths = calculateAgeInMonths(birthDate);
    final years = totalMonths ~/ 12;
    final months = totalMonths % 12;

    if (years == 0) {
      return months == 1 ? '1 month' : '$months months';
    } else if (months == 0) {
      return years == 1 ? '1 year' : '$years years';
    } else {
      final yearText = years == 1 ? '1 year' : '$years years';
      final monthText = months == 1 ? '1 month' : '$months months';
      return '$yearText, $monthText';
    }
  }

  /// Format duration for display
  static String formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }

  /// Generates default reminder times based on frequency
  ///
  /// Returns evenly spaced reminder times throughout the day:
  /// - 1x daily: 9:00 AM
  /// - 2x daily: 9:00 AM, 9:00 PM
  /// - 3x daily: 9:00 AM, 3:00 PM, 9:00 PM
  static List<TimeOfDay> generateDefaultReminderTimes(
    int administrationsPerDay,
  ) {
    return switch (administrationsPerDay) {
      1 => [const TimeOfDay(hour: 9, minute: 0)], // 9:00 AM
      2 => [
        const TimeOfDay(hour: 9, minute: 0), // 9:00 AM
        const TimeOfDay(hour: 21, minute: 0), // 9:00 PM
      ],
      3 => [
        const TimeOfDay(hour: 9, minute: 0), // 9:00 AM
        const TimeOfDay(hour: 15, minute: 0), // 3:00 PM
        const TimeOfDay(hour: 21, minute: 0), // 9:00 PM
      ],
      _ => [const TimeOfDay(hour: 9, minute: 0)],
    };
  }

  /// Converts TimeOfDay to DateTime for today
  ///
  /// Useful for converting picker times to DateTime objects for storage
  static DateTime timeOfDayToDateTime(TimeOfDay time) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, time.hour, time.minute);
  }

  // Treatment Summary Document ID Generation

  /// Format date for daily summary document ID (YYYY-MM-DD)
  ///
  /// Example: October 5, 2025 → "2025-10-05"
  /// Used for Firestore `treatmentSummaryDaily` collection document IDs.
  static String formatDateForSummary(DateTime date) {
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  /// Format date for weekly summary document ID (YYYY-Www)
  ///
  /// Example: Week 40 of 2025 → "2025-W40"
  /// Uses ISO 8601 week numbering (Monday as first day of week).
  /// Used for Firestore `treatmentSummaryWeekly` collection document IDs.
  static String formatWeekForSummary(DateTime date) {
    final weekNumber = getIso8601WeekNumber(date);
    final year = date.year.toString();
    final week = weekNumber.toString().padLeft(2, '0');
    return '$year-W$week';
  }

  /// Format date for monthly summary document ID (YYYY-MM)
  ///
  /// Example: October 2025 → "2025-10"
  /// Used for Firestore `treatmentSummaryMonthly` collection document IDs.
  static String formatMonthForSummary(DateTime date) {
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    return '$year-$month';
  }

  /// Get ISO 8601 week number (Monday as first day of week)
  ///
  /// Returns week number (1-53) according to ISO 8601 standard.
  /// Week 1 is the week containing the first Thursday of the year.
  ///
  /// Example:
  /// ```dart
  /// final date = DateTime(2025, 10, 5); // Sunday
  /// final week = getIso8601WeekNumber(date); // 40
  /// ```
  static int getIso8601WeekNumber(DateTime date) {
    // Find Thursday of the week containing this date
    final thursday = date.add(Duration(days: 3 - (date.weekday)));

    // Find first Thursday of the year
    final firstThursday = DateTime(thursday.year, 1, 4);

    // Calculate week number
    final diff = thursday.difference(firstThursday).inDays;
    return 1 + (diff / 7).floor();
  }

  /// Get week start and end dates (Monday-Sunday)
  ///
  /// Returns a map with 'start' (Monday 00:00:00) and 'end'
  /// (Sunday 23:59:59) dates for the week containing the given date.
  ///
  /// Example:
  /// ```dart
  /// final dates = getWeekStartEnd(DateTime(2025, 10, 5));
  /// // dates['start'] = Monday, September 29, 2025 00:00:00
  /// // dates['end'] = Sunday, October 5, 2025 23:59:59
  /// ```
  static Map<String, DateTime> getWeekStartEnd(DateTime date) {
    final weekDay = date.weekday;
    final startOfWeek = date.subtract(Duration(days: weekDay - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    return {
      'start': DateTime(
        startOfWeek.year,
        startOfWeek.month,
        startOfWeek.day,
      ),
      'end': DateTime(
        endOfWeek.year,
        endOfWeek.month,
        endOfWeek.day,
        23,
        59,
        59,
      ),
    };
  }

  /// Get month start and end dates
  ///
  /// Returns a map with 'start' (first day 00:00:00) and 'end'
  /// (last day 23:59:59) dates for the month containing the given date.
  ///
  /// Example:
  /// ```dart
  /// final dates = getMonthStartEnd(DateTime(2025, 10, 5));
  /// // dates['start'] = October 1, 2025 00:00:00
  /// // dates['end'] = October 31, 2025 23:59:59
  /// ```
  static Map<String, DateTime> getMonthStartEnd(DateTime date) {
    final startOfMonth = DateTime(date.year, date.month);
    final endOfMonth = DateTime(date.year, date.month + 1, 0, 23, 59, 59);

    return {
      'start': startOfMonth,
      'end': endOfMonth,
    };
  }
}
