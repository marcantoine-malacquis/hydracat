import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/core/utils/date_utils.dart';
import 'package:hydracat/features/profile/models/schedule.dart';
import 'package:hydracat/features/progress/models/day_dot_status.dart';
import 'package:hydracat/features/progress/services/week_status_calculator.dart';
import 'package:hydracat/providers/auth_provider.dart';
import 'package:hydracat/providers/logging_provider.dart';
import 'package:hydracat/providers/profile_provider.dart';
import 'package:hydracat/shared/models/daily_summary.dart';
import 'package:hydracat/shared/models/fluid_daily_summary_view.dart';

/// Provider for the currently focused day in the progress calendar.
///
/// Used by TableCalendar to track which day is currently selected/visible.
/// Defaults to today.
final focusedDayProvider = StateProvider<DateTime>((ref) => DateTime.now());

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
        final now = DateTime.now();

        // Filter medication schedules only
        final medicationSchedules = meds
            .where((s) => s.treatmentType == TreatmentType.medication)
            .toList();

        return computeWeekStatuses(
          weekStart: weekStart,
          medicationSchedules: medicationSchedules,
          fluidSchedule: fluid,
          summaries: summaries,
          now: now,
        );
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

          final goalPerSession = (schedule?.targetVolume ?? 0).round();
          final sessionsCount =
              schedule?.reminderTimesOnDate(normalized).length ?? 0;
          final goalMl = goalPerSession * sessionsCount;

          return FluidDailySummaryView(
            givenMl: givenMl,
            goalMl: goalMl,
            isToday: AppDateUtils.isToday(normalized),
          );
        },
        orElse: () => null,
      );
    });
