import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/core/utils/date_utils.dart';
import 'package:hydracat/core/utils/memoization.dart';
import 'package:hydracat/features/logging/models/fluid_session.dart';
import 'package:hydracat/features/logging/models/medication_session.dart';
import 'package:hydracat/features/logging/services/session_read_service.dart';
import 'package:hydracat/features/profile/models/schedule.dart';
import 'package:hydracat/features/progress/models/day_dot_status.dart';
import 'package:hydracat/providers/auth_provider.dart';
import 'package:hydracat/providers/logging_provider.dart';
import 'package:hydracat/providers/profile_provider.dart';
import 'package:hydracat/shared/models/daily_summary.dart';
import 'package:hydracat/shared/models/fluid_daily_summary_view.dart';
import 'package:table_calendar/table_calendar.dart';

/// Provider for the currently focused day in the progress calendar.
///
/// Used by TableCalendar to track which day is currently selected/visible.
/// Defaults to today.
final focusedDayProvider = StateProvider<DateTime>((ref) => DateTime.now());

/// Provider for the currently selected day in the progress calendar.
///
/// Used to track which day has been tapped by the user (filled circle).
/// Null means no day is selected. Cleared by tapping outside calendar.
final selectedDayProvider = StateProvider<DateTime?>((ref) => null);

/// Provider for the calendar format (week or month view).
///
/// Defaults to week view. User can toggle between formats.
/// Can be persisted to SharedPreferences in future if desired.
final calendarFormatProvider = StateProvider<CalendarFormat>((ref) {
  return CalendarFormat.week;
});

/// Provider for the start of the visible period (week or month).
///
/// Returns the start of the week (Monday) in week format,
/// or the first day of the month in month format.
/// Automatically derives from [focusedDayProvider] and
/// [calendarFormatProvider].
final focusedRangeStartProvider = Provider<DateTime>((ref) {
  final format = ref.watch(calendarFormatProvider);
  final focusedDay = ref.watch(focusedDayProvider);
  return format == CalendarFormat.month
      ? DateTime(focusedDay.year, focusedDay.month)
      : AppDateUtils.startOfWeekMonday(focusedDay);
});

/// Provider for the start of the focused week (Monday at 00:00).
///
/// Automatically derives the Monday for the week containing
/// [focusedDayProvider]. Recomputes whenever the focused day changes.
final focusedWeekStartProvider = StateProvider<DateTime>((ref) {
  final day = ref.watch(focusedDayProvider);
  return AppDateUtils.startOfWeekMonday(day);
});

/// Fetches daily summaries for all 7 days of a given week in parallel.
///
/// Returns a map of `date → DailySummary?` for the week starting
///  at `weekStart`.
/// Benefits from SummaryService's in-memory TTL cache (5 min)
/// to minimize reads.
///
/// Returns empty map if user or pet is unavailable.
final AutoDisposeFutureProviderFamily<Map<DateTime, DailySummary?>, DateTime>
weekSummariesProvider = FutureProvider.autoDispose
    .family<Map<DateTime, DailySummary?>, DateTime>(
      (ref, weekStart) async {
        // Invalidate when today's local cache changes so UI updates instantly
        ref.watch(dailyCacheProvider);

        final user = ref.read(currentUserProvider);
        final pet = ref.read(primaryPetProvider);
        if (user == null || pet == null) return {};

        final summaryService = ref.read(summaryServiceProvider);
        final days = List<DateTime>.generate(
          7,
          (i) => weekStart.add(Duration(days: i)),
        );
        final results = await Future.wait(
          days.map(
            (d) => summaryService.getDailySummary(
              userId: user.id,
              petId: pet.id,
              date: d,
            ),
          ),
        );

        // Build initial map from Firestore results
        final map = {for (var i = 0; i < days.length; i++) days[i]: results[i]};

        // Override today's entry with lightweight cache-based summary to avoid
        // TTL delays and extra reads. This ensures immediate dot updates.
        final today = AppDateUtils.startOfDay(DateTime.now());
        if (map.containsKey(today)) {
          final todaySummary = await summaryService.getTodaySummary(
            userId: user.id,
            petId: pet.id,
            lightweight: true,
          );
          if (todaySummary != null) {
            map[today] = todaySummary;
          }
        }

        return map;
      },
    );

/// Computes the status (dot color) for each day of a given week.
///
/// Returns a map of `date → DayDotStatus` for the 7 days (Mon-Sun) starting
/// at `weekStart`.
///
/// Status rules:
/// - Future days: [DayDotStatus.none]
/// - Past days with zero schedules: [DayDotStatus.none]
/// - Today with zero schedules: [DayDotStatus.today]
/// - Today/past with all schedules complete: [DayDotStatus.complete]
/// - Today with incomplete schedules: [DayDotStatus.today]
/// - Past with incomplete schedules: [DayDotStatus.missed]
///
/// Depends on [dailyCacheProvider] to automatically recompute when today's
/// cache updates (e.g., after logging a treatment), causing the dot to flip
/// from gold to green without manual refresh.
final AutoDisposeFutureProviderFamily<Map<DateTime, DayDotStatus>, DateTime>
weekStatusProvider = FutureProvider.autoDispose
    .family<Map<DateTime, DayDotStatus>, DateTime>(
      (ref, weekStart) async {
        // Watch cache to invalidate when today's data changes
        ref.watch(dailyCacheProvider);

        final summaries = await ref.watch(
          weekSummariesProvider(weekStart).future,
        );
        final meds = ref.watch(medicationSchedulesProvider) ?? [];
        final fluid = ref.watch(fluidScheduleProvider);
        final pet = ref.watch(primaryPetProvider);
        final now = DateTime.now();

        // Filter medication schedules only
        final medicationSchedules = meds
            .where((s) => s.treatmentType == TreatmentType.medication)
            .toList();

        return computeWeekStatusesMemoized(
          weekStart: weekStart,
          medicationSchedules: medicationSchedules,
          fluidSchedule: fluid,
          summaries: summaries,
          now: now,
          trackingStartDate: pet?.trackingStartDate,
        );
      },
    );

/// Computes the status for a date range (week or month).
///
/// In week format: Delegates directly to [weekStatusProvider] for the range.
/// In month format: Merges status from 5-6 week chunks covering the month,
/// then filters to only include days within the target month.
///
/// Leverages existing memoized status calculation and Riverpod caching
/// to avoid redundant Firestore reads.
final AutoDisposeFutureProviderFamily<Map<DateTime, DayDotStatus>, DateTime>
dateRangeStatusProvider = FutureProvider.autoDispose
    .family<Map<DateTime, DayDotStatus>, DateTime>(
      (ref, rangeStart) async {
        // Watch cache to invalidate when today's data changes
        ref.watch(dailyCacheProvider);

        final format = ref.watch(calendarFormatProvider);

        // Week mode: delegate to existing week provider
        if (format == CalendarFormat.week) {
          return ref.watch(weekStatusProvider(rangeStart).future);
        }

        // Month mode: merge week chunks covering the entire month
        final firstDayOfMonth = DateTime(rangeStart.year, rangeStart.month);
        final lastDayOfMonth =
            DateTime(rangeStart.year, rangeStart.month + 1, 0);

        // Start from the Monday of the week containing the first day
        var cursor = AppDateUtils.startOfWeekMonday(firstDayOfMonth);
        final merged = <DateTime, DayDotStatus>{};

        // Fetch all weeks that overlap with this month
        while (!cursor.isAfter(lastDayOfMonth)) {
          final weekStatuses = await ref.watch(
            weekStatusProvider(cursor).future,
          );
          merged.addAll(weekStatuses);
          cursor = cursor.add(const Duration(days: 7));
        }

        // Filter to only include days within the target month
        return {
          for (final entry in merged.entries)
            if (entry.key.year == firstDayOfMonth.year &&
                entry.key.month == firstDayOfMonth.month)
              entry.key: entry.value,
        };
      },
    );

/// Pre-fetches all sessions for the focused week (7 days).
///
/// Returns a map of `date → (List<MedicationSession>, List<FluidSession>)`
/// for efficient popup rendering without additional Firestore reads.
///
/// Cache invalidates automatically when:
/// - User logs out (currentUserProvider changes)
/// - User switches pets (primaryPetProvider changes)
/// - New sessions are logged (dailyCacheProvider updates)
///
/// Does NOT use autoDispose to persist cache across navigation
/// (Progress → Home → Progress).
final FutureProviderFamily<
  Map<DateTime, (List<MedicationSession>, List<FluidSession>)>,
  DateTime
>
weekSessionsProvider =
    FutureProvider.family<
      Map<DateTime, (List<MedicationSession>, List<FluidSession>)>,
      DateTime
    >(
      (ref, weekStart) async {
        // Watch cache to invalidate when today's sessions change
        ref.watch(dailyCacheProvider);

        final user = ref.read(currentUserProvider);
        final pet = ref.read(primaryPetProvider);
        if (user == null || pet == null) return {};

        final service = ref.read(sessionReadServiceProvider);
        final days = List<DateTime>.generate(
          7,
          (i) => weekStart.add(Duration(days: i)),
        );

        // Fetch all 7 days in parallel
        final results = await Future.wait(
          days.map(
            (day) => service.getAllSessionsForDate(
              userId: user.id,
              petId: pet.id,
              date: day,
            ),
          ),
        );

        // Build map: date → (medSessions, fluidSessions)
        return {
          for (var i = 0; i < days.length; i++) days[i]: results[i],
        };
      },
    );

/// Fluid daily summary for a specific day using cached weekly summaries and
/// the cached fluid schedule to compute the daily goal. Reads at most the
/// weekly summaries already loaded by [weekSummariesProvider], avoiding any
/// direct session queries per firebase_CRUDrules.
final AutoDisposeProviderFamily<FluidDailySummaryView?, DateTime>
fluidDailySummaryViewProvider = Provider.autoDispose
    .family<FluidDailySummaryView?, DateTime>((ref, day) {
      final normalized = AppDateUtils.startOfDay(day);

      final weekStart = AppDateUtils.startOfWeekMonday(normalized);
      final summariesAsync = ref.watch(weekSummariesProvider(weekStart));
      final schedule = ref.watch(fluidScheduleProvider);

      return summariesAsync.maybeWhen(
        data: (map) {
          final summary = map[normalized];
          final givenMl = (summary?.fluidTotalVolume ?? 0).round();

          // Use stored historical goal if available, otherwise calculate from
          // current schedule. This ensures historical data remains accurate
          // when schedules change.
          final goalMl =
              summary?.fluidDailyGoalMl ??
              _calculateCurrentGoal(schedule, normalized);

          return FluidDailySummaryView(
            givenMl: givenMl,
            goalMl: goalMl,
            isToday: AppDateUtils.isToday(normalized),
          );
        },
        orElse: () => null,
      );
    });

/// Helper function to calculate the current fluid goal from active schedule
///
/// Returns the daily goal based on the current schedule's target volume
/// and number of reminder times for the given date.
/// Returns 0 if no schedule exists or schedule has no reminders for that date.
int _calculateCurrentGoal(Schedule? schedule, DateTime date) {
  if (schedule == null) return 0;

  final goalPerSession = (schedule.targetVolume ?? 0).round();
  final sessionsCount = schedule.reminderTimesOnDate(date).length;
  return goalPerSession * sessionsCount;
}
