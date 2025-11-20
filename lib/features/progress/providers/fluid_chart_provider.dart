import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/features/progress/models/fluid_chart_data.dart';
import 'package:hydracat/providers/progress_provider.dart';
import 'package:hydracat/shared/models/daily_summary.dart';

/// Provides chart-ready fluid data for a given week
///
/// Transforms raw daily summaries into structured chart data with:
/// - Volume and goal for each day (Mon-Sun)
/// - Scheduled vs actual tracking
/// - Goal achievement percentages
/// - Unified goal line position (if goals are consistent)
///
/// Returns `null` while data is loading or if an error occurs.
///
/// Cost: 0 Firestore reads (reuses weekSummariesProvider data)
///
/// Example:
/// ```dart
/// final weekStart = AppDateUtils.startOfWeekMonday(DateTime.now());
/// final chartData = ref.watch(weeklyFluidChartDataProvider(weekStart));
///
/// if (chartData != null && chartData.shouldShowChart) {
///   // Render chart with chartData.days
/// }
/// ```
final AutoDisposeProviderFamily<FluidChartData?, DateTime>
    weeklyFluidChartDataProvider =
    Provider.autoDispose.family<FluidChartData?, DateTime>(
  (ref, weekStart) {
    // Watch week summaries (already cached, 0 additional reads)
    final summariesAsync = ref.watch(weekSummariesProvider(weekStart));

    return summariesAsync.when(
      data: (summaries) => _transformToChartData(weekStart, summaries),
      loading: () => null,
      error: (_, _) => null,
    );
  },
);

/// Transform raw summaries into chart-ready data
///
/// Processes 7 days (Monday-Sunday) of daily summaries and computes:
/// - Individual day data (volume, goal, schedule status, percentage)
/// - Maximum volume for Y-axis scaling (with 10% headroom)
/// - Unified goal line position (if all scheduled days have same goal)
///
/// Handles missing data gracefully:
/// - Missing summaries default to 0ml volume, 0ml goal, not scheduled
/// - Returns minimum 100ml scale even if no data exists
///
/// Parameters:
/// - [weekStart]: Monday at 00:00 for the target week
/// - [summaries]: Map of date → DailySummary from weekSummariesProvider
///
/// Returns: [FluidChartData] with complete weekly chart information
FluidChartData _transformToChartData(
  DateTime weekStart,
  Map<DateTime, DailySummary?> summaries,
) {
  final days = <FluidDayData>[];
  var maxVolume = 0.0;
  final goals = <double>{};

  // Process all 7 days (Mon-Sun)
  for (var i = 0; i < 7; i++) {
    final date = weekStart.add(Duration(days: i));
    final summary = summaries[date];

    final volumeMl = summary?.fluidTotalVolume ?? 0.0;
    final goalMl = (summary?.fluidDailyGoalMl ?? 0).toDouble();
    final wasScheduled = (summary?.fluidScheduledSessions ?? 0) > 0;
    final percentage = goalMl > 0 ? (volumeMl / goalMl * 100) : 0.0;

    days.add(
      FluidDayData(
        date: date,
        volumeMl: volumeMl,
        goalMl: goalMl,
        wasScheduled: wasScheduled,
        percentage: percentage,
      ),
    );

    // Track max for Y-axis scaling
    if (volumeMl > maxVolume) maxVolume = volumeMl;
    if (goalMl > maxVolume) maxVolume = goalMl;

    // Track unique goals for unified line
    if (goalMl > 0) goals.add(goalMl);
  }

  // Unified goal line only if all scheduled days have same goal
  final goalLineY = goals.length == 1 ? goals.first : null;

  // Add 10% headroom for Y-axis
  final adjustedMax = maxVolume * 1.1;

  return FluidChartData(
    days: days,
    maxVolume: adjustedMax > 0 ? adjustedMax : 100, // Minimum 100ml scale
    goalLineY: goalLineY,
  );
}
