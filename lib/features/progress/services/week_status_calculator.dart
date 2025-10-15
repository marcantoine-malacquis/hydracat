import 'package:hydracat/core/utils/date_utils.dart';
import 'package:hydracat/features/profile/models/schedule.dart';
import 'package:hydracat/features/progress/models/day_dot_status.dart';
import 'package:hydracat/shared/models/daily_summary.dart';

/// Pure function to compute day status for a week of the progress calendar.
///
/// Given a week start (Monday), schedules, daily summaries, and current time,
/// returns a map of [DayDotStatus] for each of the 7 days (Mon-Sun).
///
/// Status rules:
/// - Future days: [DayDotStatus.none]
/// - Past days with zero schedules: [DayDotStatus.none]
/// - Today with zero schedules: [DayDotStatus.today]
/// - Today with schedules not yet complete: [DayDotStatus.today]
/// - Today/past with all schedules complete: [DayDotStatus.complete]
/// - Past with schedules incomplete: [DayDotStatus.missed]
///
/// Adherence is based on session count (not volume) for fluids.
/// Medication adherence uses total doses vs scheduled doses.
Map<DateTime, DayDotStatus> computeWeekStatuses({
  required DateTime weekStart,
  required List<Schedule> medicationSchedules,
  required Schedule? fluidSchedule,
  required Map<DateTime, DailySummary?> summaries,
  required DateTime now,
}) {
  final statuses = <DateTime, DayDotStatus>{};
  final today = AppDateUtils.startOfDay(now);

  // Process each day of the week (Monday through Sunday)
  for (var i = 0; i < 7; i++) {
    final date = AppDateUtils.startOfDay(weekStart.add(Duration(days: i)));

    // Rule 1: Future days always show no status
    if (date.isAfter(today)) {
      statuses[date] = DayDotStatus.none;
      continue;
    }

    // Count scheduled treatments for this date
    final scheduledMedCount = medicationSchedules.fold<int>(
      0,
      (sum, schedule) => sum + schedule.reminderTimesOnDate(date).length,
    );
    final scheduledFluidCount =
        fluidSchedule?.reminderTimesOnDate(date).length ?? 0;
    final totalScheduled = scheduledMedCount + scheduledFluidCount;

    // Rule 2: Days with zero schedules
    if (totalScheduled == 0) {
      // Today with no schedules shows gold dot
      if (date.isAtSameMomentAs(today)) {
        statuses[date] = DayDotStatus.today;
      } else {
        // Past days with no schedules show no dot
        statuses[date] = DayDotStatus.none;
      }
      continue;
    }

    // Fetch the daily summary for this date
    final summary = summaries[date];

    // Rule 3: Today with schedules
    if (date.isAtSameMomentAs(today)) {
      // Check if all scheduled items are completed
      final medOk =
          scheduledMedCount == 0 ||
          (summary?.medicationTotalDoses ?? 0) == scheduledMedCount;
      final fluidOk =
          scheduledFluidCount == 0 ||
          (summary?.fluidSessionCount ?? 0) == scheduledFluidCount;

      if (medOk && fluidOk) {
        // All scheduled items completed → green
        statuses[date] = DayDotStatus.complete;
      } else {
        // Not yet complete → gold
        statuses[date] = DayDotStatus.today;
      }
      continue;
    }

    // Rule 4: Past days with schedules
    if (summary == null) {
      // Scheduled but no summary data → missed
      statuses[date] = DayDotStatus.missed;
      continue;
    }

    // Check adherence for past day
    final medOk =
        scheduledMedCount == 0 ||
        summary.medicationTotalDoses == scheduledMedCount;
    final fluidOk =
        scheduledFluidCount == 0 ||
        summary.fluidSessionCount == scheduledFluidCount;

    if (medOk && fluidOk) {
      // All scheduled items completed → green
      statuses[date] = DayDotStatus.complete;
    } else {
      // At least one scheduled item missed → red
      statuses[date] = DayDotStatus.missed;
    }
  }

  return statuses;
}
