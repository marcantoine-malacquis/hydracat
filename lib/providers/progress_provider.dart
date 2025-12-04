import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/core/utils/date_utils.dart';
import 'package:hydracat/core/utils/symptom_descriptor_utils.dart';
import 'package:hydracat/features/health/models/symptom_type.dart';
import 'package:hydracat/features/logging/models/fluid_session.dart';
import 'package:hydracat/features/logging/models/medication_session.dart';
import 'package:hydracat/features/logging/services/session_read_service.dart';
import 'package:hydracat/features/profile/models/schedule.dart';
import 'package:hydracat/features/profile/models/schedule_history_entry.dart';
import 'package:hydracat/features/progress/models/day_dot_status.dart';
import 'package:hydracat/features/progress/models/fluid_month_chart_data.dart';
import 'package:hydracat/features/progress/models/treatment_day_bucket.dart';
import 'package:hydracat/features/progress/utils/memoization.dart';
import 'package:hydracat/providers/auth_provider.dart';
import 'package:hydracat/providers/logging_provider.dart';
import 'package:hydracat/providers/profile_provider.dart';
import 'package:hydracat/providers/schedule_history_provider.dart';
import 'package:hydracat/providers/symptoms_chart_provider.dart';
import 'package:hydracat/providers/weight_provider.dart'
    show weightLogVersionProvider, weightServiceProvider;
import 'package:hydracat/shared/models/daily_summary.dart';
import 'package:hydracat/shared/models/fluid_daily_summary_view.dart';
import 'package:hydracat/shared/models/medication_daily_summary_view.dart';
import 'package:hydracat/shared/models/monthly_summary.dart';
import 'package:hydracat/shared/models/symptoms_daily_summary_view.dart';
import 'package:table_calendar/table_calendar.dart';

/// Provider for the currently focused day in the progress calendar.
///
/// Used by TableCalendar to track which day is currently selected/visible.
/// Defaults to today.
final focusedDayProvider = StateProvider<DateTime>((ref) => DateTime.now());

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
        // Watch symptom log version to refetch when symptoms are logged
        ref
          ..watch(symptomLogVersionProvider)
          // Invalidate when today's local cache changes so UI updates instantly
          ..watch(dailyCacheProvider);

        final user = ref.read(currentUserProvider);
        final pet = ref.read(primaryPetProvider);
        if (user == null || pet == null) return {};

        // IMPORTANT: Ensure weekStart is normalized to avoid key mismatches
        final normalizedWeekStart = AppDateUtils.startOfDay(weekStart);

        final summaryService = ref.read(summaryServiceProvider);
        final days = List<DateTime>.generate(
          7,
          (i) => normalizedWeekStart.add(Duration(days: i)),
        );

        if (kDebugMode) {
          debugPrint(
            '[weekSummariesProvider] Fetching summaries for week '
            '${AppDateUtils.formatDateForSummary(normalizedWeekStart)}',
          );
        }

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

        if (kDebugMode) {
          debugPrint(
            '[weekSummariesProvider] Fetched ${map.length} summaries, '
            '${map.values.where((s) => s != null).length} non-null',
          );
        }

        return map;
      },
    );

/// Provides combined treatment buckets (fluid + medication) for a month.
///
/// Each bucket contains fluid volume/goal/schedule data and medication
/// doses/schedules for a single calendar day, allowing the month view to render
/// calendar dots and the 31-bar chart from a single monthly summary read.
final AutoDisposeFutureProviderFamily<List<TreatmentDayBucket>?, DateTime>
monthlyTreatmentBucketsProvider = FutureProvider.autoDispose
    .family<List<TreatmentDayBucket>?, DateTime>(
      (ref, monthStart) async {
        // Watch cache to invalidate when today's data changes
        ref.watch(dailyCacheProvider);

        final user = ref.read(currentUserProvider);
        final pet = ref.read(primaryPetProvider);
        if (user == null || pet == null) return null;

        // Normalize monthStart to first day of month at 00:00
        final normalizedMonthStart = DateTime(
          monthStart.year,
          monthStart.month,
        );

        if (kDebugMode) {
          debugPrint(
            '[monthlyTreatmentBucketsProvider] Fetching monthly summary for '
            '${AppDateUtils.formatMonthForSummary(normalizedMonthStart)}',
          );
        }

        final summaryService = ref.read(summaryServiceProvider);
        final monthlySummary = await summaryService.getMonthlySummary(
          userId: user.id,
          petId: pet.id,
          date: normalizedMonthStart,
        );

        // Build buckets from monthly summary
        final buckets = buildMonthlyTreatmentBuckets(
          monthStart: normalizedMonthStart,
          summary: monthlySummary,
        );

        if (kDebugMode) {
          final count = buckets?.length ?? 0;
          debugPrint(
            '[monthlyTreatmentBucketsProvider] Built $count buckets '
            '(${monthlySummary == null ? 'no summary' : 'summary found'})',
          );
        }

        return buckets;
      },
    );

/// Transforms monthly fluid buckets into chart-ready data for month view.
///
/// Watches [monthlyTreatmentBucketsProvider] and converts the bucket list into
/// a [FluidMonthChartData] object ready for rendering in the 28-31 bar chart.
///
/// Returns null if loading or no monthly summary exists.
///
/// Cost: 0 additional Firestore reads (reuses
/// [monthlyTreatmentBucketsProvider] cache)
///
/// Example:
/// ```dart
/// final chartData = ref.watch(monthlyFluidChartDataProvider(monthStart));
/// if (chartData != null && chartData.shouldShowChart) {
///   // Render 28-31 bar chart
/// }
/// ```
final AutoDisposeProviderFamily<FluidMonthChartData?, DateTime>
monthlyFluidChartDataProvider = Provider.autoDispose
    .family<FluidMonthChartData?, DateTime>(
      (ref, monthStart) {
        final bucketsAsync = ref.watch(
          monthlyTreatmentBucketsProvider(monthStart),
        );

        return bucketsAsync.when(
          data: (buckets) =>
              _transformBucketsToMonthChartData(monthStart, buckets),
          loading: () => null,
          error: (_, _) => null,
        );
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

        return computeWeekStatusesMemoized(
          weekStart: weekStart,
          medicationSchedules: medicationSchedules,
          fluidSchedule: fluid,
          summaries: summaries,
          now: now,
        );
      },
    );

/// Computes the status for a date range (week or month).
///
/// Week mode delegates to [weekStatusProvider] for combined adherence.
/// Month mode uses the optimized monthly treatment buckets to keep dot logic
/// consistent with week view while still requiring only one monthly read.
///
/// Cost: Week mode = 7 daily reads (cached). Month mode = 1 monthly read.
final AutoDisposeFutureProviderFamily<Map<DateTime, DayDotStatus>, DateTime>
dateRangeStatusProvider = FutureProvider.autoDispose
    .family<Map<DateTime, DayDotStatus>, DateTime>(
      (ref, rangeStart) async {
        // Watch cache to invalidate when today's data changes
        ref.watch(dailyCacheProvider);

        final format = ref.watch(calendarFormatProvider);

        // Week mode: delegate to existing week provider (medication + fluid)
        if (format == CalendarFormat.week) {
          return ref.watch(weekStatusProvider(rangeStart).future);
        }

        // Month mode: use unified treatment buckets (optimized single read)
        final firstDayOfMonth = DateTime(rangeStart.year, rangeStart.month);

        final buckets = await ref.watch(
          monthlyTreatmentBucketsProvider(firstDayOfMonth).future,
        );

        // Transform buckets to status map
        return buildMonthStatusesFromBuckets(buckets, DateTime.now());
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

        // IMPORTANT: Ensure weekStart is normalized to avoid key mismatches
        final normalizedWeekStart = AppDateUtils.startOfDay(weekStart);

        final service = ref.read(sessionReadServiceProvider);
        final days = List<DateTime>.generate(
          7,
          (i) => normalizedWeekStart.add(Duration(days: i)),
        );

        if (kDebugMode) {
          debugPrint(
            '[weekSessionsProvider] Fetching sessions for week '
            '${AppDateUtils.formatDateForSummary(normalizedWeekStart)}',
          );
        }

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
        final map = {
          for (var i = 0; i < days.length; i++) days[i]: results[i],
        };

        if (kDebugMode) {
          final totalMed = map.values.fold<int>(
            0,
            (sum, tuple) => sum + tuple.$1.length,
          );
          final totalFluid = map.values.fold<int>(
            0,
            (sum, tuple) => sum + tuple.$2.length,
          );
          debugPrint(
            '[weekSessionsProvider] Fetched $totalMed medication sessions, '
            '$totalFluid fluid sessions',
          );
        }

        return map;
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

/// Symptoms daily summary for a specific day using cached weekly summaries.
/// Reads at most the weekly summaries already loaded by
/// [weekSummariesProvider], avoiding any direct symptom queries per
/// firebase_CRUDrules.
///
/// Returns null if no symptoms were logged for the day.
final AutoDisposeProviderFamily<SymptomsDailySummaryView?, DateTime>
symptomsDailySummaryViewProvider = Provider.autoDispose
    .family<SymptomsDailySummaryView?, DateTime>((ref, day) {
      final normalized = AppDateUtils.startOfDay(day);
      final weekStart = AppDateUtils.startOfWeekMonday(normalized);
      final summariesAsync = ref.watch(weekSummariesProvider(weekStart));

      return summariesAsync.maybeWhen(
        data: (map) {
          final summary = map[normalized];

          // Return null if no summary or no symptoms for this day
          if (summary == null || summary.hasSymptoms == false) {
            return null;
          }

          final symptoms = <SymptomItem>[];

          // Build symptom items in a consistent order matching SymptomType.all
          final symptomData = [
            (
              SymptomType.vomiting,
              summary.hadVomiting,
              summary.vomitingRawValue,
            ),
            (
              SymptomType.diarrhea,
              summary.hadDiarrhea,
              summary.diarrheaRawValue,
            ),
            (
              SymptomType.constipation,
              summary.hadConstipation,
              summary.constipationRawValue,
            ),
            (SymptomType.energy, summary.hadEnergy, summary.energyRawValue),
            (
              SymptomType.suppressedAppetite,
              summary.hadSuppressedAppetite,
              summary.suppressedAppetiteRawValue,
            ),
            (
              SymptomType.injectionSiteReaction,
              summary.hadInjectionSiteReaction,
              summary.injectionSiteReactionRawValue,
            ),
          ];

          for (final (symptomKey, hadSymptom, rawValue) in symptomData) {
            if (hadSymptom) {
              final label = SymptomDescriptorUtils.getSymptomLabel(symptomKey);
              final descriptor =
                  SymptomDescriptorUtils.formatRawValueDescriptor(
                    symptomKey,
                    rawValue,
                  );

              // Only add if we have a valid descriptor
              if (descriptor != null) {
                symptoms.add(
                  SymptomItem(
                    symptomKey: symptomKey,
                    label: label,
                    descriptor: descriptor,
                  ),
                );
              }
            }
          }

          // Return null if no valid symptoms after filtering
          if (symptoms.isEmpty) return null;

          return SymptomsDailySummaryView(
            symptoms: symptoms,
            isToday: AppDateUtils.isToday(normalized),
          );
        },
        orElse: () => null,
      );
    });

/// Provider for current month's symptoms summary
///
/// Fetches the monthly summary for the current month to display symptom
/// statistics on the Progress screen. Automatically invalidates when
/// daily cache changes (after new symptom logs).
///
/// Returns null if:
/// - User or pet is not available
/// - No monthly summary exists for current month
/// - Firestore read fails
///
/// Cost: 0-1 Firestore reads (with 15-minute in-memory TTL cache)
final AutoDisposeFutureProvider<MonthlySummary?>
    currentMonthSymptomsSummaryProvider =
    FutureProvider.autoDispose<MonthlySummary?>(
  (ref) async {
    if (kDebugMode) {
      debugPrint(
        '[currentMonthSymptomsSummaryProvider] Provider executing...',
      );
    }

    // Watch symptom log version to refetch when symptoms are logged
    ref
      ..watch(symptomLogVersionProvider)
      // Also invalidate when weight logs change so monthly summaries stay fresh
      ..watch(weightLogVersionProvider)
      // Watch for invalidation triggers (refetch after logging)
      ..watch(dailyCacheProvider);

    final user = ref.read(currentUserProvider);
    final pet = ref.read(primaryPetProvider);

    if (kDebugMode) {
      debugPrint(
        '[currentMonthSymptomsSummaryProvider] '
        'After reading providers: user=${user?.id ?? 'null'} '
        'pet=${pet?.id ?? 'null'}',
      );
    }

    if (user == null || pet == null) {
      if (kDebugMode) {
        debugPrint(
          '[currentMonthSymptomsSummaryProvider] '
          'Early return: user=${user == null ? 'null' : user.id} '
          'pet=${pet == null ? 'null' : pet.id}',
        );
      }
      return null;
    }

    final summaryService = ref.read(summaryServiceProvider);

    if (kDebugMode) {
      debugPrint(
        '[currentMonthSymptomsSummaryProvider] '
        'About to fetch monthly summary for user=${user.id} '
        'pet=${pet.id}',
      );
    }

    try {
      final monthlySummary = await summaryService.getMonthlySummary(
        userId: user.id,
        petId: pet.id,
        date: DateTime.now(),
      );

      if (kDebugMode) {
        final monthStr = AppDateUtils.formatMonthForSummary(DateTime.now());
        final summaryStr = monthlySummary == null
            ? 'null'
            : 'daysWithAnySymptoms=${monthlySummary.daysWithAnySymptoms}';
        debugPrint(
          '[currentMonthSymptomsSummaryProvider] '
          'user=${user.id} pet=${pet.id} month=$monthStr '
          'summary=$summaryStr',
        );
      }

      return monthlySummary;
    } on Exception catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[currentMonthSymptomsSummaryProvider] '
          'Error fetching monthly summary: $e',
        );
      }
      return null;
    }
  },
);

/// Represents the latest logged weight (in kilograms) and its timestamp
/// for a given day, used by `dayWeightEntryProvider`.
@immutable
class DailyWeightEntry {
  /// Creates a daily weight entry with the recorded weight and timestamp.
  const DailyWeightEntry({
    required this.weightKg,
    required this.loggedAt,
  });

  /// The pet's weight in kilograms at the time of logging.
  final double weightKg;

  /// The exact date and time when the weight was logged.
  final DateTime loggedAt;
}

/// Provides the latest logged weight entry on or before a given day,
/// with a short-lived cache to avoid repeated reads for the same date.
final AutoDisposeFutureProviderFamily<DailyWeightEntry?, DateTime>
dayWeightEntryProvider = FutureProvider.autoDispose
    .family<DailyWeightEntry?, DateTime>(
      (ref, day) async {
        // Recompute when weight logs change
        ref.watch(weightLogVersionProvider);

        // Keep result alive briefly to avoid repeat reads for same focused day
        final link = ref.keepAlive();
        Timer(const Duration(minutes: 15), link.close);

        final user = ref.read(currentUserProvider);
        final pet = ref.read(primaryPetProvider);
        if (user == null || pet == null) return null;

        final weightService = ref.read(weightServiceProvider);
        final result = await weightService.getLatestWeightBeforeDate(
          userId: user.id,
          petId: pet.id,
          date: day,
        );

        if (result == null) return null;
        return DailyWeightEntry(
          weightKg: result.weight,
          loggedAt: result.date,
        );
      },
    );

/// Medication daily summary for a specific day using
/// cached weekly summaries and
/// the cached medication schedules to compute scheduled doses.
/// Reads at most the
/// weekly summaries already loaded by [weekSummariesProvider], avoiding any
/// direct session queries per firebase_CRUDrules.
final AutoDisposeProviderFamily<MedicationDailySummaryView?, DateTime>
medicationDailySummaryViewProvider = Provider.autoDispose
    .family<MedicationDailySummaryView?, DateTime>((ref, day) {
      final normalized = AppDateUtils.startOfDay(day);
      final today = AppDateUtils.startOfDay(DateTime.now());
      final isFuture = normalized.isAfter(today);

      // For future dates, use current schedules
      if (isFuture || normalized.isAtSameMomentAs(today)) {
        return _buildMedicationSummaryFromCurrentSchedules(
          ref,
          normalized,
        );
      }

      // For past dates, use historical schedules
      final historicalSchedulesAsync = ref.watch(
        scheduleHistoryForDateProvider(normalized),
      );

      return historicalSchedulesAsync.maybeWhen(
        data: (historicalMap) {
          if (historicalMap.isEmpty) {
            // Fall back to current schedules if no history
            return _buildMedicationSummaryFromCurrentSchedules(
              ref,
              normalized,
            );
          }

          // Check if we have medication history specifically
          // If only fluid history exists, fallback to
          // current medication schedules
          final hasHistoricalMedication = historicalMap.values.any(
            (e) => e.treatmentType == TreatmentType.medication,
          );

          if (!hasHistoricalMedication) {
            // No medication history, use current schedules
            //(backward compatibility)
            return _buildMedicationSummaryFromCurrentSchedules(
              ref,
              normalized,
            );
          }

          // We have medication history, use it
          return _buildMedicationSummaryFromHistoricalSchedules(
            ref,
            normalized,
            historicalMap,
          );
        },
        orElse: () => _buildMedicationSummaryFromCurrentSchedules(
          ref,
          normalized,
        ),
      );
    });

/// Build medication summary from current schedules
MedicationDailySummaryView? _buildMedicationSummaryFromCurrentSchedules(
  Ref ref,
  DateTime normalized,
) {
  final medSchedules = ref.watch(medicationSchedulesProvider) ?? [];
  final medicationSchedules = medSchedules
      .where((s) => s.treatmentType == TreatmentType.medication)
      .toList();

  // Count scheduled doses from current schedules
  var scheduledDoses = 0;
  for (final schedule in medicationSchedules) {
    scheduledDoses += schedule.reminderTimesOnDate(normalized).length;
  }

  // If no scheduled doses, return null (don't show status)
  if (scheduledDoses == 0) return null;

  // Get completed doses from weekly summaries
  final weekStart = AppDateUtils.startOfWeekMonday(normalized);
  final summariesAsync = ref.watch(weekSummariesProvider(weekStart));

  return summariesAsync.maybeWhen(
    data: (map) {
      final summary = map[normalized];
      final completedDoses = summary?.medicationTotalDoses ?? 0;

      return MedicationDailySummaryView(
        completedDoses: completedDoses,
        scheduledDoses: scheduledDoses,
        isToday: AppDateUtils.isToday(normalized),
      );
    },
    orElse: () => null,
  );
}

/// Build medication summary from historical schedules
MedicationDailySummaryView? _buildMedicationSummaryFromHistoricalSchedules(
  Ref ref,
  DateTime normalized,
  Map<String, ScheduleHistoryEntry> historicalMap,
) {
  // Count scheduled doses from historical schedules
  var scheduledDoses = 0;
  for (final entry in historicalMap.values) {
    if (entry.treatmentType == TreatmentType.medication) {
      scheduledDoses += entry.getReminderTimesForDate(normalized).length;
    }
  }

  // If no scheduled doses, return null (don't show status)
  if (scheduledDoses == 0) return null;

  // Get completed doses from weekly summaries
  final weekStart = AppDateUtils.startOfWeekMonday(normalized);
  final summariesAsync = ref.watch(weekSummariesProvider(weekStart));

  return summariesAsync.maybeWhen(
    data: (map) {
      final summary = map[normalized];
      final completedDoses = summary?.medicationTotalDoses ?? 0;

      return MedicationDailySummaryView(
        completedDoses: completedDoses,
        scheduledDoses: scheduledDoses,
        isToday: AppDateUtils.isToday(normalized),
      );
    },
    orElse: () => null,
  );
}

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

/// Builds combined treatment buckets (fluid + medication) for a month.
///
/// Returns null if no summary exists or the array lengths do not match the
/// expected month length.
List<TreatmentDayBucket>? buildMonthlyTreatmentBuckets({
  required DateTime monthStart,
  required MonthlySummary? summary,
}) {
  final normalizedMonthStart = DateTime(monthStart.year, monthStart.month);
  if (summary == null) {
    return null;
  }

  final monthLength = summary.daysInMonth;

  final hasMismatch =
      summary.dailyVolumes.length != monthLength ||
      summary.dailyGoals.length != monthLength ||
      summary.dailyScheduledSessions.length != monthLength ||
      summary.dailyFluidSessionCounts.length != monthLength ||
      summary.dailyMedicationDoses.length != monthLength ||
      summary.dailyMedicationScheduledDoses.length != monthLength;

  if (hasMismatch) {
    if (kDebugMode) {
      debugPrint(
        '[buildMonthlyTreatmentBuckets] Array length mismatch for '
        '${AppDateUtils.formatMonthForSummary(normalizedMonthStart)}',
      );
    }
    return null;
  }

  final buckets = <TreatmentDayBucket>[];
  for (var dayIndex = 0; dayIndex < monthLength; dayIndex++) {
    final day = dayIndex + 1;
    final date = DateTime(
      normalizedMonthStart.year,
      normalizedMonthStart.month,
      day,
    );

    buckets.add(
      TreatmentDayBucket(
        date: date,
        fluidVolumeMl: summary.dailyVolumes[dayIndex],
        fluidGoalMl: summary.dailyGoals[dayIndex],
        fluidScheduledSessions: summary.dailyScheduledSessions[dayIndex],
        fluidSessionCount: summary.dailyFluidSessionCounts[dayIndex],
        medicationDoses: summary.dailyMedicationDoses[dayIndex],
        medicationScheduledDoses:
            summary.dailyMedicationScheduledDoses[dayIndex],
      ),
    );
  }

  return buckets;
}

/// Transforms monthly fluid buckets into calendar dot statuses (fluid-only).
///
/// Maps each [TreatmentDayBucket] to a [DayDotStatus] using the same logic
/// as week view (combined medication + fluid adherence).
///
/// Returns empty map if buckets is null or empty.
///
/// Example:
/// ```dart
/// final buckets = await ref.watch(
///   monthlyTreatmentBucketsProvider(monthStart).future,
/// );
/// final statuses = _buildMonthStatusesFromBuckets(buckets, DateTime.now());
/// // statuses[Oct 15] == DayDotStatus.complete (if goal met)
/// ```
@visibleForTesting
Map<DateTime, DayDotStatus> buildMonthStatusesFromBuckets(
  List<TreatmentDayBucket>? buckets,
  DateTime now,
) {
  if (buckets == null || buckets.isEmpty) {
    return {};
  }

  final today = DateTime(now.year, now.month, now.day);
  final statuses = <DateTime, DayDotStatus>{};

  for (final bucket in buckets) {
    final isBucketToday =
        bucket.date.year == today.year &&
        bucket.date.month == today.month &&
        bucket.date.day == today.day;
    final isPast = bucket.date.isBefore(today);
    final hasSchedules = bucket.hasScheduledTreatments;
    final isMissed =
        (bucket.hasFluidScheduled && !bucket.isFluidComplete) ||
        (bucket.hasMedicationScheduled && !bucket.isMedicationComplete);

    // Future days → none
    if (bucket.date.isAfter(today)) {
      statuses[bucket.date] = DayDotStatus.none;
      continue;
    }

    if (!hasSchedules) {
      statuses[bucket.date] = isBucketToday
          ? DayDotStatus.today
          : DayDotStatus.none;
      continue;
    }

    if (isBucketToday) {
      statuses[bucket.date] = bucket.isComplete
          ? DayDotStatus.complete
          : DayDotStatus.today;
      continue;
    }

    if (isPast && isMissed) {
      statuses[bucket.date] = DayDotStatus.missed;
      continue;
    }

    statuses[bucket.date] = DayDotStatus.complete;
  }

  return statuses;
}

/// Transforms monthly treatment buckets into fluid chart data.
///
/// Converts a list of [TreatmentDayBucket] objects into a
/// [FluidMonthChartData] object by extracting the fluid fields needed for the
/// 31-bar chart.
///
/// Returns null if buckets is null or empty.
///
/// Example:
/// ```dart
/// final buckets = [bucket1, bucket2, ...bucket31];
/// final chartData = _transformBucketsToMonthChartData(monthStart, buckets);
/// // chartData.days.length == 31 (October)
/// // chartData.maxVolume == 110.0 (if max volume/goal is 100ml)
/// // chartData.goalLineY == 100.0 (if all days have same goal)
/// ```
FluidMonthChartData? _transformBucketsToMonthChartData(
  DateTime monthStart,
  List<TreatmentDayBucket>? buckets,
) {
  if (buckets == null || buckets.isEmpty) return null;

  final monthLength = buckets.length;
  final days = <FluidMonthDayData>[];

  // Transform each bucket to chart day data
  for (var i = 0; i < monthLength; i++) {
    final bucket = buckets[i];
    final volumeMl = bucket.fluidVolumeMl.toDouble();
    final goalMl = bucket.fluidGoalMl.toDouble();
    final percentage = goalMl > 0 ? (volumeMl / goalMl) * 100 : 0.0;

    days.add(
      FluidMonthDayData(
        date: bucket.date,
        dayOfMonth: bucket.date.day,
        volumeMl: volumeMl,
        goalMl: goalMl,
        wasScheduled: bucket.fluidScheduledSessions > 0,
        percentage: percentage,
      ),
    );
  }

  // Calculate Y-axis max (max of volumes and goals, with 10% headroom)
  final volumes = days.map((d) => d.volumeMl).toList();
  final goals = days.map((d) => d.goalMl).where((g) => g > 0).toList();

  double maxValue = 0;
  if (volumes.isNotEmpty) {
    maxValue = volumes.reduce((a, b) => a > b ? a : b);
  }
  if (goals.isNotEmpty) {
    final maxGoal = goals.reduce((a, b) => a > b ? a : b);
    if (maxGoal > maxValue) maxValue = maxGoal;
  }

  final maxVolume = maxValue * 1.1; // 10% headroom
  final minMaxVolume = maxVolume < 100 ? 100.0 : maxVolume; // Min 100ml scale

  // Detect unified goal (all days have same goal AND goal > 0)
  final uniqueGoals = goals.toSet();
  final allDaysHaveGoals = goals.length == monthLength;
  final goalLineY = (uniqueGoals.length == 1 && allDaysHaveGoals)
      ? uniqueGoals.first
      : null;

  return FluidMonthChartData(
    days: days,
    maxVolume: minMaxVolume,
    monthLength: monthLength,
    goalLineY: goalLineY,
  );
}
