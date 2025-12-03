import 'package:flutter/foundation.dart';

/// Chart-ready data for one day of fluid therapy in month view
///
/// Represents a single day's fluid volume data with goal tracking,
/// schedule status, and computed visual properties for month bar chart rendering.
///
/// Example:
/// ```dart
/// final day = FluidMonthDayData(
///   date: DateTime(2025, 10, 15),
///   dayOfMonth: 15,
///   volumeMl: 85,
///   goalMl: 100,
///   wasScheduled: true,
///   percentage: 85.0,
/// );
/// ```
@immutable
class FluidMonthDayData {
  /// Creates a [FluidMonthDayData] instance
  const FluidMonthDayData({
    required this.date,
    required this.dayOfMonth,
    required this.volumeMl,
    required this.goalMl,
    required this.wasScheduled,
    required this.percentage,
  });

  /// The date this data represents (normalized to start of day)
  final DateTime date;

  /// Day of month (1-31)
  final int dayOfMonth;

  /// Volume of fluid administered in milliliters
  final double volumeMl;

  /// Daily goal volume in milliliters (0 if no schedule)
  final double goalMl;

  /// Whether fluid therapy was scheduled for this day
  ///
  /// True if fluidScheduledSessions > 0 in monthly summary
  final bool wasScheduled;

  /// Percentage of goal achieved (volumeMl / goalMl * 100)
  ///
  /// Returns 0 if goalMl is 0
  final double percentage;

  /// Whether this day should display a bar in the chart
  ///
  /// Returns true if:
  /// - Fluid therapy was scheduled, OR
  /// - Volume > 0 (unscheduled but logged)
  bool get shouldShowBar => wasScheduled || volumeMl > 0;

  /// Whether this represents a missed scheduled session
  ///
  /// Returns true if:
  /// - Date is in the past (before today)
  /// - Fluid therapy was scheduled
  /// - No volume was logged (0ml)
  bool get isMissed {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isInPast = date.isBefore(today);
    return isInPast && wasScheduled && volumeMl == 0;
  }

  /// Bar opacity level based on goal achievement
  ///
  /// Returns:
  /// - 0.4 (40% opacity) if 0-50% of goal achieved
  /// - 0.7 (70% opacity) if 50-100% of goal achieved
  /// - 1.0 (100% opacity) if >100% of goal achieved
  double get barOpacity {
    if (percentage <= 50) return 0.4;
    if (percentage <= 100) return 0.7;
    return 1;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FluidMonthDayData &&
          date == other.date &&
          dayOfMonth == other.dayOfMonth &&
          volumeMl == other.volumeMl &&
          goalMl == other.goalMl &&
          wasScheduled == other.wasScheduled;

  @override
  int get hashCode =>
      Object.hash(date, dayOfMonth, volumeMl, goalMl, wasScheduled);

  @override
  String toString() => 'FluidMonthDayData('
      'date: $date, '
      'dayOfMonth: $dayOfMonth, '
      'volumeMl: $volumeMl, '
      'goalMl: $goalMl, '
      'wasScheduled: $wasScheduled, '
      'percentage: $percentage'
      ')';
}

/// Complete monthly fluid chart data
///
/// Contains all data needed to render a monthly fluid volume bar chart,
/// including 28-31 days of data, Y-axis scaling information, and optional
/// unified goal line position.
///
/// Example:
/// ```dart
/// final chartData = FluidMonthChartData(
///   days: [day1, day2, ...day31],
///   maxVolume: 120.0,
///   goalLineY: 100.0,
///   monthLength: 31,
/// );
/// ```
@immutable
class FluidMonthChartData {
  /// Creates a [FluidMonthChartData] instance
  const FluidMonthChartData({
    required this.days,
    required this.maxVolume,
    required this.monthLength,
    this.goalLineY,
  });

  /// Daily fluid data for the month (28-31 entries based on month length)
  final List<FluidMonthDayData> days;

  /// Maximum volume value for Y-axis scaling
  ///
  /// Calculated as max(all volumes, all goals) * 1.1 (10% headroom)
  /// Minimum value is 100ml for consistent scale
  final double maxVolume;

  /// Number of days in this month (28, 29, 30, or 31)
  final int monthLength;

  /// Unified goal line Y-position in milliliters
  ///
  /// Set only if all scheduled days have the same goal.
  /// Null if goals vary across the month or no goals exist.
  final double? goalLineY;

  /// Whether the chart should be visible
  ///
  /// Returns true if at least one day has:
  /// - A scheduled session, OR
  /// - Volume > 0
  ///
  /// Returns false if no fluid therapy data exists for the month
  bool get shouldShowChart => days.any((d) => d.shouldShowBar);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FluidMonthChartData &&
          listEquals(days, other.days) &&
          maxVolume == other.maxVolume &&
          monthLength == other.monthLength &&
          goalLineY == other.goalLineY;

  @override
  int get hashCode => Object.hash(
        Object.hashAll(days),
        maxVolume,
        monthLength,
        goalLineY,
      );

  @override
  String toString() => 'FluidMonthChartData('
      'days: ${days.length}, '
      'maxVolume: $maxVolume, '
      'monthLength: $monthLength, '
      'goalLineY: $goalLineY, '
      'shouldShowChart: $shouldShowChart'
      ')';
}
