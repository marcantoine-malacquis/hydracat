import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/core/utils/date_utils.dart';
import 'package:hydracat/features/health/models/symptom_bucket.dart';
import 'package:hydracat/features/health/models/symptom_granularity.dart';
import 'package:hydracat/features/health/models/symptom_type.dart';
import 'package:hydracat/providers/auth_provider.dart';
import 'package:hydracat/providers/logging_provider.dart';
import 'package:hydracat/providers/profile_provider.dart';
import 'package:hydracat/providers/progress_provider.dart';
import 'package:hydracat/shared/models/daily_summary.dart';
import 'package:hydracat/shared/models/monthly_summary.dart';

/// Sentinel value for [SymptomsChartState.copyWith] to distinguish between
/// "not provided" and "explicitly set to null"
const _undefined = Object();

/// State class for symptoms chart visualization
///
/// Manages the focused date (a day inside the visible period), granularity
/// (week/month/year), and selected symptom key (null for "All").
@immutable
class SymptomsChartState {
  /// Creates a [SymptomsChartState]
  SymptomsChartState({
    DateTime? focusedDate,
    this.granularity = SymptomGranularity.week,
    this.selectedSymptomKey,
  }) : focusedDate = focusedDate ?? DateTime.now();

  /// A day inside the currently visible period
  ///
  /// Used to derive the period start (weekStart, monthStart, yearStart).
  /// Defaults to today at construction.
  final DateTime focusedDate;

  /// Current graph granularity (week/month/year)
  final SymptomGranularity granularity;

  /// Selected symptom key for single-symptom view
  ///
  /// - `null` means "All symptoms" (stacked view)
  /// - Non-null is a specific symptom key (e.g., `SymptomType.vomiting`)
  final String? selectedSymptomKey;

  /// Start of week (Monday) containing [focusedDate]
  DateTime get weekStart => AppDateUtils.startOfWeekMonday(focusedDate);

  /// Start of month containing [focusedDate]
  DateTime get monthStart => DateTime(focusedDate.year, focusedDate.month);

  /// Start of year containing [focusedDate]
  DateTime get yearStart => DateTime(focusedDate.year);

  /// Whether the current week includes today
  bool get isOnCurrentWeek {
    final now = DateTime.now();
    final currentWeekStart = AppDateUtils.startOfWeekMonday(now);
    return weekStart.isAtSameMomentAs(currentWeekStart);
  }

  /// Whether the current month includes today
  bool get isOnCurrentMonth {
    final now = DateTime.now();
    final currentMonthStart = DateTime(now.year, now.month);
    return monthStart.isAtSameMomentAs(currentMonthStart);
  }

  /// Whether the current year includes today
  bool get isOnCurrentYear {
    final now = DateTime.now();
    final currentYearStart = DateTime(now.year);
    return yearStart.isAtSameMomentAs(currentYearStart);
  }

  /// Whether currently viewing a period that includes today
  bool get isOnCurrentPeriod {
    return switch (granularity) {
      SymptomGranularity.week => isOnCurrentWeek,
      SymptomGranularity.month => isOnCurrentMonth,
      SymptomGranularity.year => isOnCurrentYear,
    };
  }

  /// Creates a copy with updated fields
  SymptomsChartState copyWith({
    Object? focusedDate = _undefined,
    SymptomGranularity? granularity,
    Object? selectedSymptomKey = _undefined,
  }) {
    return SymptomsChartState(
      focusedDate: focusedDate == _undefined
          ? this.focusedDate
          : focusedDate as DateTime?,
      granularity: granularity ?? this.granularity,
      selectedSymptomKey: selectedSymptomKey == _undefined
          ? this.selectedSymptomKey
          : selectedSymptomKey as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SymptomsChartState &&
          runtimeType == other.runtimeType &&
          focusedDate.isAtSameMomentAs(other.focusedDate) &&
          granularity == other.granularity &&
          selectedSymptomKey == other.selectedSymptomKey;

  @override
  int get hashCode =>
      focusedDate.hashCode ^
      granularity.hashCode ^
      (selectedSymptomKey?.hashCode ?? 0);

  @override
  String toString() {
    return 'SymptomsChartState('
        'focusedDate: $focusedDate, '
        'granularity: $granularity, '
        'selectedSymptomKey: $selectedSymptomKey'
        ')';
  }
}

/// Notifier for managing symptoms chart state
///
/// Handles navigation between periods, granularity changes, and symptom
/// selection, mirroring the weight chart patterns but scoped to symptoms.
class SymptomsChartNotifier extends StateNotifier<SymptomsChartState> {
  /// Creates a symptoms chart notifier
  ///
  /// Initializes with today's date, week granularity, and "All" symptoms.
  SymptomsChartNotifier()
    : super(
        SymptomsChartState(
          focusedDate: DateTime.now(),
        ),
      );

  /// Changes the graph granularity
  ///
  /// Always snaps to the current period for the new granularity (current week,
  /// current month, or current year), matching the Weight screen behavior.
  /// This ensures that switching granularity always returns to today's period,
  /// regardless of where the user had navigated before.
  /// Resets the selected symptom to null to avoid confusing state when
  /// switching scales.
  void setGranularity(SymptomGranularity newGranularity) {
    final now = DateTime.now();
    final newFocusedDate = _normalizeFocusedDate(
      newGranularity,
      now,
    );

    if (kDebugMode) {
      debugPrint(
        '[SymptomsChartNotifier] Setting granularity to '
        '${newGranularity.label}, focusedDate: $newFocusedDate '
        '(snapped to current period)',
      );
    }

    state = state.copyWith(
      granularity: newGranularity,
      focusedDate: newFocusedDate,
      selectedSymptomKey: null, // Reset to "All" when switching scales
    );
  }

  /// Navigates to the previous period (week/month/year)
  void previousPeriod() {
    final newFocusedDate = _shiftByGranularity(
      anchor: _getPeriodAnchor(),
      granularity: state.granularity,
      delta: -1,
    );

    if (kDebugMode) {
      debugPrint(
        '[SymptomsChartNotifier] Previous period: ${state.granularity.label}, '
        'new focusedDate: $newFocusedDate',
      );
    }

    state = state.copyWith(focusedDate: newFocusedDate);
  }

  /// Navigates to the next period (week/month/year)
  ///
  /// Prevents moving to a future period that does not include today.
  void nextPeriod() {
    final newFocusedDate = _shiftByGranularity(
      anchor: _getPeriodAnchor(),
      granularity: state.granularity,
      delta: 1,
    );

    final clampedDate = _clampToTodayIfFuture(newFocusedDate);

    if (kDebugMode) {
      debugPrint(
        '[SymptomsChartNotifier] Next period: ${state.granularity.label}, '
        'new focusedDate: $clampedDate',
      );
    }

    state = state.copyWith(focusedDate: clampedDate);
  }

  /// Jumps to the current period (today's week/month/year)
  ///
  /// Keeps current granularity and selected symptom unchanged.
  void goToToday() {
    final now = DateTime.now();
    final normalizedDate = _normalizeFocusedDate(state.granularity, now);

    if (kDebugMode) {
      debugPrint(
        '[SymptomsChartNotifier] Go to today: ${state.granularity.label}, '
        'focusedDate: $normalizedDate',
      );
    }

    state = state.copyWith(focusedDate: normalizedDate);
  }

  /// Sets the selected symptom key for single-symptom view
  ///
  /// - `null` means "All symptoms" (stacked view)
  /// - Non-null is a specific symptom key
  void setSelectedSymptom(String? key) {
    if (kDebugMode) {
      debugPrint(
        '[SymptomsChartNotifier] Setting selected symptom: ${key ?? "All"}',
      );
    }

    state = state.copyWith(selectedSymptomKey: key);
  }

  // ============================================
  // PRIVATE HELPERS
  // ============================================

  /// Gets the period anchor (start) for the current granularity
  DateTime _getPeriodAnchor() {
    return switch (state.granularity) {
      SymptomGranularity.week => state.weekStart,
      SymptomGranularity.month => state.monthStart,
      SymptomGranularity.year => state.yearStart,
    };
  }

  /// Normalizes focused date to the start of the period for
  ///  the given granularity
  ///
  /// This ensures cleaner period boundaries when switching granularities.
  DateTime _normalizeFocusedDate(
    SymptomGranularity granularity,
    DateTime date,
  ) {
    return switch (granularity) {
      SymptomGranularity.week => AppDateUtils.startOfWeekMonday(date),
      SymptomGranularity.month => DateTime(date.year, date.month),
      SymptomGranularity.year => DateTime(date.year),
    };
  }

  /// Shifts the anchor date by the specified number of periods
  ///
  /// For months, handles day clamping (e.g., Jan 31 -> Feb 28/29).
  DateTime _shiftByGranularity({
    required DateTime anchor,
    required SymptomGranularity granularity,
    required int delta,
  }) {
    return switch (granularity) {
      SymptomGranularity.week => anchor.add(Duration(days: 7 * delta)),
      SymptomGranularity.month => _shiftMonth(anchor, delta),
      SymptomGranularity.year => DateTime(
        anchor.year + delta,
        anchor.month,
        anchor.day,
      ),
    };
  }

  /// Shifts a date by the specified number of months, handling day clamping
  ///
  /// Example: Jan 31 + 1 month -> Feb 28 (or 29 in leap years)
  DateTime _shiftMonth(DateTime date, int delta) {
    final targetYear = date.year;
    final targetMonth = date.month + delta;

    // Calculate the actual year and month after overflow/underflow
    final year = targetYear + ((targetMonth - 1) ~/ 12);
    final month = ((targetMonth - 1) % 12) + 1;

    // Clamp day to last day of target month if needed
    final lastDayOfMonth = DateTime(year, month + 1, 0).day;
    final day = date.day > lastDayOfMonth ? lastDayOfMonth : date.day;

    return DateTime(year, month, day);
  }

  /// Clamps a date to today if it's in the future
  ///
  /// Prevents navigation to periods that don't include today.
  DateTime _clampToTodayIfFuture(DateTime value) {
    final now = DateTime.now();
    if (value.isAfter(now)) {
      return now;
    }
    return value;
  }
}

/// Provider for symptoms chart state
///
/// Uses autoDispose to avoid keeping state alive when the Symptoms screen
/// is not in use.
// ignore: specify_nonobvious_property_types
final symptomsChartStateProvider =
    StateNotifierProvider.autoDispose<
      SymptomsChartNotifier,
      SymptomsChartState
    >(
      (ref) => SymptomsChartNotifier(),
    );

/// Builds 7 daily symptom buckets (Mon-Sun) from weekly daily summaries
///
/// Transforms a map of daily summaries into a fixed list of 7 [SymptomBucket]
/// instances, one per day of the week. Each bucket represents a single day with
/// symptom counts (0 or 1 per symptom for week view).
///
/// Parameters:
/// - [weekStart]: Monday at 00:00 for the target week (should be normalized)
/// - [summaries]: Map of date → DailySummary? from weekSummariesProvider
///
/// Returns:
/// A list of exactly 7 [SymptomBucket] instances, ordered Monday → Sunday.
/// Each bucket has `start == end == day date` for week view.
///
/// Example:
/// ```dart
/// final weekStart = AppDateUtils.startOfWeekMonday(DateTime.now());
/// final summaries = await ref.read(weekSummariesProvider(weekStart).future);
/// final buckets = buildWeeklySymptomBuckets(
///   weekStart: weekStart,
///   summaries: summaries,
/// );
/// // buckets.length == 7
/// ```
List<SymptomBucket> buildWeeklySymptomBuckets({
  required DateTime weekStart,
  required Map<DateTime, DailySummary?> summaries,
}) {
  // Normalize weekStart to start-of-day for safety
  final normalizedWeekStart = AppDateUtils.startOfDay(weekStart);
  final buckets = <SymptomBucket>[];

  // Build one bucket per day (Mon-Sun, i = 0..6)
  for (var i = 0; i < 7; i++) {
    final date = normalizedWeekStart.add(Duration(days: i));
    final summary = summaries[date];

    // Start with empty bucket
    var bucket = SymptomBucket.empty(date);

    if (summary != null) {
      // Build daysWithSymptom map: only include symptoms that were present
      final daysWithSymptom = <String, int>{};

      if (summary.hadVomiting) {
        daysWithSymptom[SymptomType.vomiting] = 1;
      }
      if (summary.hadDiarrhea) {
        daysWithSymptom[SymptomType.diarrhea] = 1;
      }
      if (summary.hadConstipation) {
        daysWithSymptom[SymptomType.constipation] = 1;
      }
      if (summary.hadLethargy) {
        daysWithSymptom[SymptomType.lethargy] = 1;
      }
      if (summary.hadSuppressedAppetite) {
        daysWithSymptom[SymptomType.suppressedAppetite] = 1;
      }
      if (summary.hadInjectionSiteReaction) {
        daysWithSymptom[SymptomType.injectionSiteReaction] = 1;
      }

      // Set daysWithAnySymptoms based on hasSymptoms flag
      final daysWithAnySymptoms = summary.hasSymptoms ? 1 : 0;

      // Update bucket with symptom data
      bucket = bucket.copyWith(
        daysWithSymptom: daysWithSymptom,
        daysWithAnySymptoms: daysWithAnySymptoms,
      );
    }
    // If summary is null, bucket remains empty (already initialized)

    buckets.add(bucket);
  }

  return buckets;
}

/// Provides symptom buckets for a given week (7 daily buckets, Mon-Sun)
///
/// Transforms weekly daily summaries into [SymptomBucket] instances ready for
/// chart visualization. Each bucket represents a single day with symptom
/// counts.
///
/// **Cost**: 0 extra Firestore reads - reuses data from [weekSummariesProvider]
/// which is already cached and adheres to CRUD rules.
///
/// **Reactivity**: Automatically recomputes
/// when [weekSummariesProvider] changes
/// (e.g., after logging new symptoms), ensuring the chart stays up-to-date.
///
/// Returns:
/// - `null` while data is loading or if an error occurs
/// - `List<SymptomBucket>` of length 7 when data is available
///
/// Example:
/// ```dart
/// final weekStart = AppDateUtils.startOfWeekMonday(DateTime.now());
/// final bucketsAsync = ref.watch(weeklySymptomBucketsProvider(weekStart));
///
/// bucketsAsync.when(
///   data: (buckets) {
///     if (buckets != null) {
///       // Render chart with buckets
///     }
///   },
///   loading: () => CircularProgressIndicator(),
///   error: (_, __) => ErrorWidget(),
/// );
/// ```
final AutoDisposeProviderFamily<List<SymptomBucket>?, DateTime>
weeklySymptomBucketsProvider = Provider.autoDispose
    .family<List<SymptomBucket>?, DateTime>(
      (ref, weekStart) {
        // Watch week summaries (already cached, 0 additional reads)
        final summariesAsync = ref.watch(weekSummariesProvider(weekStart));

        return summariesAsync.when(
          data: (summaries) => buildWeeklySymptomBuckets(
            weekStart: weekStart,
            summaries: summaries,
          ),
          loading: () => null,
          error: (_, _) => null,
        );
      },
    );

/// Builds 4-5 weekly symptom buckets for a given month from daily summaries
///
/// Transforms a map of daily summaries into
/// a list of [SymptomBucket] instances,
/// where each bucket represents a week segment within the visible month. Days
/// are grouped by their week start (Monday), but only days within the target
/// month are included in each bucket.
///
/// **Important**: This function uses **daily summaries**, not weekly summaries,
/// because weekly summaries aggregate full Mon-Sun weeks and cannot be split
/// to exclude days from adjacent months. For correct "weeks of the month"
/// visualization, we need per-day granularity.
///
/// Parameters:
/// - [monthStart]: First day of the target month at 00:00
/// (should be normalized)
/// - [dailySummaries]: Map of date → DailySummary? for all days in the month
///
/// Returns:
/// A list of [SymptomBucket] instances, one per week segment that contains
/// at least one day from the target month. Buckets are sorted by `start` date
/// ascending. Each bucket's `start` and `end` represent the first and last
/// in-month days of that week segment.
///
/// Example:
/// ```dart
/// final monthStart = DateTime(2025, 10, 1); // October 2025
/// final summaries = await fetchDailySummariesForMonth(monthStart);
/// final buckets = buildMonthlySymptomBuckets(
///   monthStart: monthStart,
///   dailySummaries: summaries,
/// );
/// // buckets.length == 4 or 5 (depending on how weeks fall in the month)
/// ```
List<SymptomBucket> buildMonthlySymptomBuckets({
  required DateTime monthStart,
  required Map<DateTime, DailySummary?> dailySummaries,
}) {
  // Normalize monthStart to first day of month at start-of-day
  final normalizedMonthStart = DateTime(monthStart.year, monthStart.month);
  final monthEnd = AppDateUtils.endOfMonth(normalizedMonthStart);

  // Map of weekStart (Monday) -> SymptomBucket for that week segment
  final weekBuckets = <DateTime, SymptomBucket>{};

  // Iterate through all days in the month
  var currentDate = normalizedMonthStart;
  while (currentDate.isBefore(monthEnd) ||
      currentDate.isAtSameMomentAs(monthEnd)) {
    // Only process days that belong to the target month
    if (currentDate.month == normalizedMonthStart.month) {
      final summary = dailySummaries[currentDate];
      final weekStart = AppDateUtils.startOfWeekMonday(currentDate);

      // Get or create bucket for this week segment
      var bucket = weekBuckets[weekStart];
      if (bucket == null) {
        // Initialize bucket with current date as both start and end
        bucket = SymptomBucket.forRange(
          start: currentDate,
          end: currentDate,
        );
      } else {
        // Extend bucket's end date to include current day
        bucket = bucket.copyWith(end: currentDate);
      }

      // Build or update daysWithSymptom map
      final daysWithSymptom = Map<String, int>.from(bucket.daysWithSymptom);
      var daysWithAnySymptoms = bucket.daysWithAnySymptoms;

      if (summary != null) {
        // Increment symptom counts for each present symptom
        if (summary.hadVomiting) {
          daysWithSymptom[SymptomType.vomiting] =
              (daysWithSymptom[SymptomType.vomiting] ?? 0) + 1;
        }
        if (summary.hadDiarrhea) {
          daysWithSymptom[SymptomType.diarrhea] =
              (daysWithSymptom[SymptomType.diarrhea] ?? 0) + 1;
        }
        if (summary.hadConstipation) {
          daysWithSymptom[SymptomType.constipation] =
              (daysWithSymptom[SymptomType.constipation] ?? 0) + 1;
        }
        if (summary.hadLethargy) {
          daysWithSymptom[SymptomType.lethargy] =
              (daysWithSymptom[SymptomType.lethargy] ?? 0) + 1;
        }
        if (summary.hadSuppressedAppetite) {
          daysWithSymptom[SymptomType.suppressedAppetite] =
              (daysWithSymptom[SymptomType.suppressedAppetite] ?? 0) + 1;
        }
        if (summary.hadInjectionSiteReaction) {
          daysWithSymptom[SymptomType.injectionSiteReaction] =
              (daysWithSymptom[SymptomType.injectionSiteReaction] ?? 0) + 1;
        }

        // Increment daysWithAnySymptoms if any symptom was present
        if (summary.hasSymptoms) {
          daysWithAnySymptoms++;
        }
      }

      // Update bucket with accumulated counts
      bucket = bucket.copyWith(
        daysWithSymptom: daysWithSymptom,
        daysWithAnySymptoms: daysWithAnySymptoms,
      );

      weekBuckets[weekStart] = bucket;
    }

    // Move to next day
    currentDate = currentDate.add(const Duration(days: 1));
  }

  // Sort buckets by start date ascending and return as list
  final sortedBuckets = weekBuckets.values.toList()
    ..sort((a, b) => a.start.compareTo(b.start));

  return sortedBuckets;
}

/// Provides symptom buckets for a given month (4-5 weekly buckets)
///
/// Transforms daily summaries for a month into [SymptomBucket] instances ready
/// for chart visualization. Each bucket represents a week segment within the
/// visible month, aggregating symptom counts from the days in that segment.
///
/// **Cost**: At most 31 Firestore reads per month (one per day), TTL-cached
/// for 5 minutes. This aligns with `firebase_CRUDrules.md` and is similar to
/// the planned "recent 30-day trends" feature. Only fetched when the user
/// views that month; no background polling.
///
/// **Reactivity**: Automatically recomputes when daily summaries change
/// (e.g., after logging new symptoms), ensuring the chart stays up-to-date.
///
/// Returns:
/// - `null` while data is loading or if an error occurs
/// - `List<SymptomBucket>` (4-5 buckets) when data is available
///
/// Example:
/// ```dart
/// final monthStart = DateTime(2025, 10, 1);
/// final bucketsAsync = ref.watch(monthlySymptomBucketsProvider(monthStart));
///
/// bucketsAsync.when(
///   data: (buckets) {
///     if (buckets != null) {
///       // Render chart with buckets
///     }
///   },
///   loading: () => CircularProgressIndicator(),
///   error: (_, __) => ErrorWidget(),
/// );
/// ```
final AutoDisposeFutureProviderFamily<List<SymptomBucket>?, DateTime>
monthlySymptomBucketsProvider = FutureProvider.autoDispose
    .family<List<SymptomBucket>?, DateTime>(
      (ref, monthStart) async {
        // Invalidate when today's local cache changes so UI updates instantly
        ref.watch(dailyCacheProvider);

        final user = ref.read(currentUserProvider);
        final pet = ref.read(primaryPetProvider);
        if (user == null || pet == null) return null;

        // Normalize monthStart to first day of month at start-of-day
        final normalizedMonthStart = DateTime(
          monthStart.year,
          monthStart.month,
        );
        final monthEnd = AppDateUtils.endOfMonth(normalizedMonthStart);

        // Generate all dates in the month
        final days = <DateTime>[];
        var currentDate = normalizedMonthStart;
        while (currentDate.isBefore(monthEnd) ||
            currentDate.isAtSameMomentAs(monthEnd)) {
          days.add(currentDate);
          currentDate = currentDate.add(const Duration(days: 1));
        }

        if (kDebugMode) {
          debugPrint(
            '[monthlySymptomBucketsProvider] Fetching ${days.length} daily '
            'summaries for month '
            '${AppDateUtils.formatMonthForSummary(normalizedMonthStart)}',
          );
        }

        final summaryService = ref.read(summaryServiceProvider);

        // Fetch all daily summaries in parallel
        final results = await Future.wait(
          days.map(
            (d) => summaryService.getDailySummary(
              userId: user.id,
              petId: pet.id,
              date: d,
            ),
          ),
        );

        // Build map from results
        final dailySummaries = {
          for (var i = 0; i < days.length; i++) days[i]: results[i],
        };

        if (kDebugMode) {
          final nonNullCount = dailySummaries.values
              .where((s) => s != null)
              .length;
          debugPrint(
            '[monthlySymptomBucketsProvider] Fetched ${dailySummaries.length} '
            'summaries, $nonNullCount non-null',
          );
        }

        // Build buckets from daily summaries
        return buildMonthlySymptomBuckets(
          monthStart: normalizedMonthStart,
          dailySummaries: dailySummaries,
        );
      },
    );

/// Builds up to 12 monthly symptom buckets for a given year from monthly
/// summaries
///
/// Transforms a map of monthly summaries into a list of [SymptomBucket]
/// instances, where each bucket represents a calendar month within the visible
/// year. Each bucket aggregates symptom counts directly from the monthly
/// summary fields.
///
/// **Important**: This function uses **monthly summaries**, which already
/// contain pre-aggregated symptom counts (`daysWithX` fields). This is more
/// efficient than fetching daily summaries for an entire year.
///
/// Parameters:
/// - [yearStart]: First day of the target year (Jan 1 at 00:00, should be
///   normalized)
/// - [monthlySummaries]: Map of month start date → MonthlySummary? for all
///   months in the year
///
/// Returns:
/// A list of [SymptomBucket] instances, one per month from January to December
/// (or fewer if stopping at current month). Buckets are sorted by `start` date
/// ascending. Each bucket's `start` and `end` represent the first and last days
/// of that calendar month.
///
/// Example:
/// ```dart
/// final yearStart = DateTime(2025, 1, 1); // January 2025
/// final summaries = await fetchMonthlySummariesForYear(yearStart);
/// final buckets = buildYearlySymptomBuckets(
///   yearStart: yearStart,
///   monthlySummaries: summaries,
/// );
/// // buckets.length == 12 (or fewer if current month is before December)
/// ```
List<SymptomBucket> buildYearlySymptomBuckets({
  required DateTime yearStart,
  required Map<DateTime, MonthlySummary?> monthlySummaries,
}) {
  // Normalize yearStart to first day of year at start-of-day
  final normalizedYearStart = DateTime(yearStart.year);
  final now = DateTime.now();
  final currentMonthStart = DateTime(now.year, now.month);

  final buckets = <SymptomBucket>[];

  // Iterate through months from January to December (or stop at current month)
  for (var month = 1; month <= 12; month++) {
    final monthStart = DateTime(normalizedYearStart.year, month);
    final monthEnd = AppDateUtils.endOfMonth(monthStart);

    // Stop if this month is in the future
    if (monthStart.isAfter(currentMonthStart)) {
      break;
    }

    final summary = monthlySummaries[monthStart];

    // Build daysWithSymptom map from summary fields
    final daysWithSymptom = <String, int>{};

    if (summary != null) {
      // Only include symptoms with count > 0 to keep map compact
      if (summary.daysWithVomiting > 0) {
        daysWithSymptom[SymptomType.vomiting] = summary.daysWithVomiting;
      }
      if (summary.daysWithDiarrhea > 0) {
        daysWithSymptom[SymptomType.diarrhea] = summary.daysWithDiarrhea;
      }
      if (summary.daysWithConstipation > 0) {
        daysWithSymptom[SymptomType.constipation] =
            summary.daysWithConstipation;
      }
      if (summary.daysWithLethargy > 0) {
        daysWithSymptom[SymptomType.lethargy] = summary.daysWithLethargy;
      }
      if (summary.daysWithSuppressedAppetite > 0) {
        daysWithSymptom[SymptomType.suppressedAppetite] =
            summary.daysWithSuppressedAppetite;
      }
      if (summary.daysWithInjectionSiteReaction > 0) {
        daysWithSymptom[SymptomType.injectionSiteReaction] =
            summary.daysWithInjectionSiteReaction;
      }

      // Create bucket with summary data
      final bucket = SymptomBucket(
        start: summary.startDate,
        end: summary.endDate,
        daysWithSymptom: daysWithSymptom,
        daysWithAnySymptoms: summary.daysWithAnySymptoms,
      );
      buckets.add(bucket);
    } else {
      // Create empty bucket for month with no summary
      final bucket = SymptomBucket.forRange(
        start: monthStart,
        end: monthEnd,
      );
      buckets.add(bucket);
    }
  }

  // Buckets are already in chronological order, but sort to be safe
  buckets.sort((a, b) => a.start.compareTo(b.start));

  return buckets;
}

/// Provides symptom buckets for a given year (up to 12 monthly buckets)
///
/// Transforms monthly summaries for a year into [SymptomBucket] instances
/// ready for chart visualization. Each bucket represents a calendar month,
/// aggregating symptom counts directly from monthly summary documents.
///
/// **Cost**: Up to 12 Firestore reads per year view (one per month),
/// TTL-cached for 15 minutes. This aligns with `firebase_CRUDrules.md` and is
/// efficient compared to fetching daily summaries for an entire year. Only
/// fetched when the user views that year; no background polling.
///
/// **Reactivity**: Automatically recomputes when daily summaries change
/// (e.g., after logging new symptoms), ensuring the chart stays up-to-date.
///
/// Returns:
/// - `null` while data is loading or if an error occurs
/// - `List<SymptomBucket>` (up to 12 buckets) when data is available
///
/// Example:
/// ```dart
/// final yearStart = DateTime(2025, 1, 1);
/// final bucketsAsync = ref.watch(yearlySymptomBucketsProvider(yearStart));
///
/// bucketsAsync.when(
///   data: (buckets) {
///     if (buckets != null) {
///       // Render chart with buckets
///     }
///   },
///   loading: () => CircularProgressIndicator(),
///   error: (_, __) => ErrorWidget(),
/// );
/// ```
final AutoDisposeFutureProviderFamily<List<SymptomBucket>?, DateTime>
yearlySymptomBucketsProvider = FutureProvider.autoDispose
    .family<List<SymptomBucket>?, DateTime>(
      (ref, yearStart) async {
        // Invalidate when today's local cache changes so UI updates instantly
        ref.watch(dailyCacheProvider);

        final user = ref.read(currentUserProvider);
        final pet = ref.read(primaryPetProvider);
        if (user == null || pet == null) return null;

        // Normalize yearStart to first day of year at start-of-day
        final normalizedYearStart = DateTime(yearStart.year);
        final now = DateTime.now();
        final currentMonthStart = DateTime(now.year, now.month);

        // Generate list of month dates (up to 12 months, stopping at current
        // month)
        final monthDates = <DateTime>[];
        for (var month = 1; month <= 12; month++) {
          final monthDate = DateTime(normalizedYearStart.year, month);
          // Stop if this month is in the future
          if (monthDate.isAfter(currentMonthStart)) {
            break;
          }
          monthDates.add(monthDate);
        }

        if (kDebugMode) {
          debugPrint(
            '[yearlySymptomBucketsProvider] Fetching '
            '${monthDates.length} monthly summaries for year '
            '${normalizedYearStart.year}',
          );
        }

        final summaryService = ref.read(summaryServiceProvider);

        // Fetch all monthly summaries in parallel
        final results = await Future.wait(
          monthDates.map(
            (monthDate) => summaryService.getMonthlySummary(
              userId: user.id,
              petId: pet.id,
              date: monthDate,
            ),
          ),
        );

        // Build map from results
        final monthlySummaries = {
          for (var i = 0; i < monthDates.length; i++)
            monthDates[i]: results[i],
        };

        if (kDebugMode) {
          final nonNullCount = monthlySummaries.values
              .where((s) => s != null)
              .length;
          debugPrint(
            '[yearlySymptomBucketsProvider] Fetched '
            '${monthlySummaries.length} summaries, $nonNullCount non-null',
          );
        }

        // Build buckets from monthly summaries
        return buildYearlySymptomBuckets(
          yearStart: normalizedYearStart,
          monthlySummaries: monthlySummaries,
        );
      },
    );

/// View-model for symptoms chart visualization
///
/// Encapsulates the buckets and symptom visibility information needed by the
/// chart widget to render stacked bars and legend. The chart widget computes
/// per-bucket "Other" counts by subtracting visible symptom totals from
/// `bucket.totalSymptomDays`.
@immutable
class SymptomsChartViewModel {
  /// Creates a [SymptomsChartViewModel]
  ///
  /// Parameters:
  /// - [buckets]: List of symptom buckets for the current period
  /// - [visibleSymptoms]: Ordered list of symptom keys to render as individual
  ///   stacked segments (top 5 by total count)
  /// - [hasOther]: Whether an "Other" segment is needed for symptoms not in
  ///   [visibleSymptoms]
  const SymptomsChartViewModel({
    required this.buckets,
    required this.visibleSymptoms,
    required this.hasOther,
  });

  /// List of symptom buckets for the current period
  ///
  /// Each bucket represents a time period (day/week/month) with aggregated
  /// symptom counts.
  final List<SymptomBucket> buckets;

  /// Ordered list of symptom keys to render as individual stacked segments
  ///
  /// These are the top symptoms by total count across all buckets, ordered by
  /// count (descending) with static priority as tie-breaker. Typically up to 5
  /// symptoms, but may be fewer if fewer distinct symptoms exist.
  final List<String> visibleSymptoms;

  /// Whether an "Other" segment is needed
  ///
  /// `true` when there are symptom keys not in [visibleSymptoms] with
  /// non-zero counts across buckets. The chart widget computes per-bucket
  /// "Other" counts by subtracting visible symptom totals from
  /// `bucket.totalSymptomDays`.
  final bool hasOther;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SymptomsChartViewModel &&
          runtimeType == other.runtimeType &&
          _listEquals(buckets, other.buckets) &&
          _listEquals(visibleSymptoms, other.visibleSymptoms) &&
          hasOther == other.hasOther;

  @override
  int get hashCode =>
      Object.hash(
        Object.hashAll(buckets),
        Object.hashAll(visibleSymptoms),
        hasOther,
      );

  @override
  String toString() {
    return 'SymptomsChartViewModel('
        'buckets: ${buckets.length}, '
        'visibleSymptoms: $visibleSymptoms, '
        'hasOther: $hasOther'
        ')';
  }

  /// Helper to compare lists by value
  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Static priority order for symptoms (from most important to least important)
///
/// Used as a tie-breaker when sorting symptoms by total count. This ensures
/// deterministic ordering when multiple symptoms have the same total count.
const List<String> _symptomPriorityOrder = [
  SymptomType.lethargy,
  SymptomType.suppressedAppetite,
  SymptomType.vomiting,
  SymptomType.injectionSiteReaction,
  SymptomType.constipation,
  SymptomType.diarrhea,
];

/// Computes the visible symptoms list from buckets using global ranking
///
/// Aggregates symptom counts across all buckets, sorts by total count
/// (descending) with static priority as tie-breaker, and returns the top 5
/// (or fewer if fewer exist).
///
/// Parameters:
/// - [buckets]: List of symptom buckets to aggregate
///
/// Returns:
/// Ordered list of symptom keys (up to 5) to render as individual stacked
/// segments.
List<String> _buildVisibleSymptoms(List<SymptomBucket> buckets) {
  // Aggregate total counts per symptom across all buckets
  final totalCounts = <String, int>{};
  for (final bucket in buckets) {
    for (final entry in bucket.daysWithSymptom.entries) {
      totalCounts[entry.key] = (totalCounts[entry.key] ?? 0) + entry.value;
    }
  }

  // Get all symptom keys that have non-zero counts
  final symptomsWithCounts = totalCounts.entries
      .where((e) => e.value > 0)
      .map((e) => e.key)
      .toList()
    ..sort((a, b) {
    final countA = totalCounts[a]!;
    final countB = totalCounts[b]!;
    if (countA != countB) {
      return countB.compareTo(countA); // Descending by count
    }
    // Tie-breaker: use static priority order
    final priorityA = _symptomPriorityOrder.indexOf(a);
    final priorityB = _symptomPriorityOrder.indexOf(b);
    // If not in priority list, treat as lowest priority
    if (priorityA == -1 && priorityB == -1) {
      return 0;
    }
    if (priorityA == -1) {
      return 1;
    }
    if (priorityB == -1) {
      return -1;
    }
    return priorityA.compareTo(priorityB); // Ascending by priority index
  });

  // Take top 5 (or fewer if fewer exist)
  return symptomsWithCounts.take(5).toList();
}

/// Determines whether an "Other" segment is needed
///
/// Returns `true` when there are symptom keys not in [visibleSymptoms] with
/// non-zero counts across buckets.
///
/// Parameters:
/// - [buckets]: List of symptom buckets to check
/// - [visibleSymptoms]: List of symptom keys that will be rendered individually
///
/// Returns:
/// `true` if there are symptoms not in [visibleSymptoms] with counts > 0
bool _hasOtherSymptoms(
  List<SymptomBucket> buckets,
  List<String> visibleSymptoms,
) {
  final visibleSet = visibleSymptoms.toSet();

  // Check if any bucket has symptoms not in visibleSymptoms
  for (final bucket in buckets) {
    for (final symptomKey in bucket.daysWithSymptom.keys) {
      if (!visibleSet.contains(symptomKey) &&
          bucket.daysWithSymptom[symptomKey]! > 0) {
        return true;
      }
    }
  }

  return false;
}

/// Unified provider for symptoms chart data
///
/// Abstracts week/month/year bucket providers behind a single provider and
/// computes the global top-5 symptoms ordering plus an optional "Other" bucket.
/// The chart widget can depend on this provider to get all data needed for
/// rendering stacked bars and legend.
///
/// **Reactivity**: Automatically recomputes when:
/// - Chart state changes (granularity, focused date, selected symptom)
/// - Underlying bucket providers update (e.g., after logging new symptoms)
///
/// Returns:
/// - `null` while data is loading or if an error occurs
/// - `SymptomsChartViewModel` when data is available
///
/// Example:
/// ```dart
/// final viewModelAsync = ref.watch(symptomsChartDataProvider);
///
/// viewModelAsync.when(
///   data: (viewModel) {
///     if (viewModel != null) {
///       // Render chart with viewModel.buckets, viewModel.visibleSymptoms,
///       // and viewModel.hasOther
///     }
///   },
///   loading: () => CircularProgressIndicator(),
///   error: (_, __) => ErrorWidget(),
/// );
/// ```
// ignore: specify_nonobvious_property_types
final symptomsChartDataProvider =
    Provider.autoDispose<SymptomsChartViewModel?>(
  (ref) {
    final state = ref.watch(symptomsChartStateProvider);

    // Get buckets based on granularity
    List<SymptomBucket>? buckets;
    switch (state.granularity) {
      case SymptomGranularity.week:
        // Weekly provider returns List<SymptomBucket>? directly
        buckets = ref.watch(weeklySymptomBucketsProvider(state.weekStart));
      case SymptomGranularity.month:
        // Monthly provider returns AsyncValue
        final bucketsAsync = ref.watch(
          monthlySymptomBucketsProvider(state.monthStart),
        );
        buckets = bucketsAsync.valueOrNull;
      case SymptomGranularity.year:
        // Yearly provider returns AsyncValue
        final bucketsAsync = ref.watch(
          yearlySymptomBucketsProvider(state.yearStart),
        );
        buckets = bucketsAsync.valueOrNull;
    }

    // Return null if buckets are not available (loading or error)
    if (buckets == null) {
      return null;
    }

    // Compute visible symptoms and hasOther
    final visibleSymptoms = _buildVisibleSymptoms(buckets);
    final hasOther = _hasOtherSymptoms(buckets, visibleSymptoms);

    if (kDebugMode) {
      debugPrint(
        '[symptomsChartDataProvider] Granularity: ${state.granularity.label}, '
        'buckets: ${buckets.length}, visibleSymptoms: $visibleSymptoms, '
        'hasOther: $hasOther',
      );
    }

    return SymptomsChartViewModel(
      buckets: buckets,
      visibleSymptoms: visibleSymptoms,
      hasOther: hasOther,
    );
  },
);

/// Provider that determines if the user has any symptom history
///
/// Checks multiple sources to determine if the user has ever logged symptoms:
/// 1. Current month's summary (via [currentMonthSymptomsSummaryProvider])
/// 2. Current year's monthly buckets (via [yearlySymptomBucketsProvider])
/// 3. Previous year's monthly buckets (via [yearlySymptomBucketsProvider])
///
/// Returns `true` if any of these sources indicate symptom data exists,
/// `false` otherwise. This provider is used to decide whether to show the
/// onboarding empty state (first-time user) or the analytics layout.
///
/// **Cost**: Reuses existing providers with TTL caching, no additional
/// Firestore reads beyond what's already loaded.
///
/// **Reactivity**: Automatically recomputes when underlying summary providers
/// update (e.g., after logging new symptoms).
final AutoDisposeFutureProvider<bool> hasSymptomsHistoryProvider =
    FutureProvider.autoDispose<bool>(
  (ref) async {
    // Check current month summary first (fastest path)
    final currentMonthSummaryAsync =
        ref.watch(currentMonthSymptomsSummaryProvider);
    final currentMonthSummary = currentMonthSummaryAsync.valueOrNull;
    if (currentMonthSummary != null &&
        currentMonthSummary.daysWithAnySymptoms > 0) {
      if (kDebugMode) {
        debugPrint(
          '[hasSymptomsHistoryProvider] Found data in current month: '
          '${currentMonthSummary.daysWithAnySymptoms} days',
        );
      }
      return true;
    }

    // Check current year's buckets
    final now = DateTime.now();
    final currentYearStart = DateTime(now.year);
    final currentYearBucketsAsync =
        ref.watch(yearlySymptomBucketsProvider(currentYearStart));
    final currentYearBuckets = currentYearBucketsAsync.valueOrNull;
    if (currentYearBuckets != null &&
        currentYearBuckets.isNotEmpty &&
        currentYearBuckets.any((bucket) => bucket.totalSymptomDays > 0)) {
      if (kDebugMode) {
        debugPrint(
          '[hasSymptomsHistoryProvider] Found data in current year: '
          '${currentYearBuckets.length} buckets',
        );
      }
      return true;
    }

    // Check previous year's buckets (for extra robustness)
    final previousYearStart = DateTime(now.year - 1);
    final previousYearBucketsAsync =
        ref.watch(yearlySymptomBucketsProvider(previousYearStart));
    final previousYearBuckets = previousYearBucketsAsync.valueOrNull;
    if (previousYearBuckets != null &&
        previousYearBuckets.isNotEmpty &&
        previousYearBuckets.any((bucket) => bucket.totalSymptomDays > 0)) {
      if (kDebugMode) {
        debugPrint(
          '[hasSymptomsHistoryProvider] Found data in previous year: '
          '${previousYearBuckets.length} buckets',
        );
      }
      return true;
    }

    if (kDebugMode) {
      debugPrint('[hasSymptomsHistoryProvider] No symptom history found');
    }
    return false;
  },
);
