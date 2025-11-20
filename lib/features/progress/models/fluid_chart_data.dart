import 'package:flutter/foundation.dart';

/// Chart-ready data for one day of fluid therapy
///
/// Represents a single day's fluid volume data with goal tracking,
/// schedule status, and computed visual properties for bar chart rendering.
///
/// Example:
/// ```dart
/// final day = FluidDayData(
///   date: DateTime(2025, 1, 20),
///   volumeMl: 85,
///   goalMl: 100,
///   wasScheduled: true,
///   percentage: 85.0,
/// );
/// ```
@immutable
class FluidDayData {
  /// Creates a [FluidDayData] instance
  const FluidDayData({
    required this.date,
    required this.volumeMl,
    required this.goalMl,
    required this.wasScheduled,
    required this.percentage,
  });

  /// The date this data represents (normalized to start of day)
  final DateTime date;

  /// Volume of fluid administered in milliliters
  final double volumeMl;

  /// Daily goal volume in milliliters (0 if no schedule)
  final double goalMl;

  /// Whether fluid therapy was scheduled for this day
  ///
  /// True if fluidScheduledSessions > 0 in daily summary
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
      other is FluidDayData &&
          date == other.date &&
          volumeMl == other.volumeMl &&
          goalMl == other.goalMl &&
          wasScheduled == other.wasScheduled;

  @override
  int get hashCode => Object.hash(date, volumeMl, goalMl, wasScheduled);

  @override
  String toString() => 'FluidDayData('
      'date: $date, '
      'volumeMl: $volumeMl, '
      'goalMl: $goalMl, '
      'wasScheduled: $wasScheduled, '
      'percentage: $percentage'
      ')';
}

/// Complete weekly fluid chart data
///
/// Contains all data needed to render a weekly fluid volume bar chart,
/// including 7 days of data (Monday-Sunday), Y-axis scaling information,
/// and optional unified goal line position.
///
/// Example:
/// ```dart
/// final chartData = FluidChartData(
///   days: [day1, day2, day3, day4, day5, day6, day7],
///   maxVolume: 120.0,
///   goalLineY: 100.0,
/// );
/// ```
@immutable
class FluidChartData {
  /// Creates a [FluidChartData] instance
  const FluidChartData({
    required this.days,
    required this.maxVolume,
    this.goalLineY,
  });

  /// Daily fluid data for the week (always 7 entries, Monday-Sunday)
  final List<FluidDayData> days;

  /// Maximum volume value for Y-axis scaling
  ///
  /// Calculated as max(all volumes, all goals) * 1.1 (10% headroom)
  /// Minimum value is 100ml for consistent scale
  final double maxVolume;

  /// Unified goal line Y-position in milliliters
  ///
  /// Set only if all scheduled days have the same goal.
  /// Null if goals vary across the week or no goals exist.
  final double? goalLineY;

  /// Whether the chart should be visible
  ///
  /// Returns true if at least one day has:
  /// - A scheduled session, OR
  /// - Volume > 0
  ///
  /// Returns false if no fluid therapy data exists for the week
  bool get shouldShowChart => days.any((d) => d.shouldShowBar);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FluidChartData &&
          listEquals(days, other.days) &&
          maxVolume == other.maxVolume &&
          goalLineY == other.goalLineY;

  @override
  int get hashCode => Object.hash(
        Object.hashAll(days),
        maxVolume,
        goalLineY,
      );

  @override
  String toString() => 'FluidChartData('
      'days: ${days.length}, '
      'maxVolume: $maxVolume, '
      'goalLineY: $goalLineY, '
      'shouldShowChart: $shouldShowChart'
      ')';
}
