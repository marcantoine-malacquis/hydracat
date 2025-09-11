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
}
