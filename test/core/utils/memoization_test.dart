import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/core/utils/memoization.dart';
import 'package:hydracat/features/onboarding/models/treatment_data.dart';
import 'package:hydracat/features/profile/models/schedule.dart';
import 'package:hydracat/features/progress/models/day_dot_status.dart';
import 'package:hydracat/shared/models/daily_summary.dart';

void main() {
  group('computeWeekStatusesMemoized', () {
    late DateTime weekStart;
    late DateTime now;
    late List<Schedule> medicationSchedules;
    late Schedule fluidSchedule;
    late Map<DateTime, DailySummary?> summaries;

    setUp(() {
      // Clear cache before each test to ensure clean state
      clearWeekStatusCache();

      // Initialize test data
      weekStart = DateTime(2025, 10, 20); // Monday
      now = DateTime(2025, 10, 21, 10, 30);

      // Create a sample medication schedule
      medicationSchedules = [
        Schedule(
          id: 'med1',
          treatmentType: TreatmentType.medication,
          frequency: TreatmentFrequency.twiceDaily,
          reminderTimes: [
            DateTime(2025, 10, 20, 9),
            DateTime(2025, 10, 20, 21),
          ],
          isActive: true,
          createdAt: DateTime(2025, 10),
          updatedAt: DateTime(2025, 10),
          medicationName: 'Test Med',
          targetDosage: 5,
          medicationUnit: 'ml',
        ),
      ];

      // Create a sample fluid schedule
      fluidSchedule = Schedule(
        id: 'fluid1',
        treatmentType: TreatmentType.fluid,
        frequency: TreatmentFrequency.onceDaily,
        reminderTimes: [
          DateTime(2025, 10, 20, 10),
        ],
        isActive: true,
        createdAt: DateTime(2025, 10),
        updatedAt: DateTime(2025, 10),
        targetVolume: 100,
      );

      // Create sample summaries
      summaries = {
        DateTime(2025, 10, 20): DailySummary(
          date: DateTime(2025, 10, 20),
          overallStreak: 5,
          medicationTotalDoses: 2,
          medicationScheduledDoses: 2,
          medicationMissedCount: 0,
          fluidTotalVolume: 100,
          fluidTreatmentDone: true,
          fluidSessionCount: 1,
          overallTreatmentDone: true,
          createdAt: DateTime(2025, 10, 20),
        ),
        DateTime(2025, 10, 21): null,
      };
    });

    test('returns cached result for identical inputs', () {
      // First call - computes
      final result1 = computeWeekStatusesMemoized(
        weekStart: weekStart,
        medicationSchedules: medicationSchedules,
        fluidSchedule: fluidSchedule,
        summaries: summaries,
        now: now,
      );

      // Second call - should return cached (identical reference)
      final result2 = computeWeekStatusesMemoized(
        weekStart: weekStart,
        medicationSchedules: medicationSchedules,
        fluidSchedule: fluidSchedule,
        summaries: summaries,
        now: now,
      );

      expect(identical(result1, result2), true);
      expect(result1, isA<Map<DateTime, DayDotStatus>>());
    });

    test('1-minute tolerance for now parameter (same cache)', () {
      final now1 = DateTime(2025, 10, 21, 10, 30);
      final now2 = DateTime(2025, 10, 21, 10, 30, 59);

      final result1 = computeWeekStatusesMemoized(
        weekStart: weekStart,
        medicationSchedules: medicationSchedules,
        fluidSchedule: fluidSchedule,
        summaries: summaries,
        now: now1,
      );

      final result2 = computeWeekStatusesMemoized(
        weekStart: weekStart,
        medicationSchedules: medicationSchedules,
        fluidSchedule: fluidSchedule,
        summaries: summaries,
        now: now2,
      );

      expect(identical(result1, result2), true);
    });

    test('cache miss when now difference is >= 1 minute', () {
      final now1 = DateTime(2025, 10, 21, 10, 30);
      final now2 = DateTime(2025, 10, 21, 10, 31);

      final result1 = computeWeekStatusesMemoized(
        weekStart: weekStart,
        medicationSchedules: medicationSchedules,
        fluidSchedule: fluidSchedule,
        summaries: summaries,
        now: now1,
      );

      final result2 = computeWeekStatusesMemoized(
        weekStart: weekStart,
        medicationSchedules: medicationSchedules,
        fluidSchedule: fluidSchedule,
        summaries: summaries,
        now: now2,
      );

      // Different references (cache miss)
      expect(identical(result1, result2), false);
      // But same values
      expect(result1.length, result2.length);
    });

    test('cache miss with different weekStart', () {
      final weekStart1 = DateTime(2025, 10, 20);
      final weekStart2 = DateTime(2025, 10, 27);

      final result1 = computeWeekStatusesMemoized(
        weekStart: weekStart1,
        medicationSchedules: medicationSchedules,
        fluidSchedule: fluidSchedule,
        summaries: summaries,
        now: now,
      );

      final result2 = computeWeekStatusesMemoized(
        weekStart: weekStart2,
        medicationSchedules: medicationSchedules,
        fluidSchedule: fluidSchedule,
        summaries: summaries,
        now: now,
      );

      expect(identical(result1, result2), false);
    });

    test('cache miss with different medication schedules', () {
      final schedules2 = [
        Schedule(
          id: 'med2',
          treatmentType: TreatmentType.medication,
          frequency: TreatmentFrequency.onceDaily,
          reminderTimes: [
            DateTime(2025, 10, 20, 8),
          ],
          isActive: true,
          createdAt: DateTime(2025, 10),
          updatedAt: DateTime(2025, 10),
          medicationName: 'Test Med 2',
          targetDosage: 10,
          medicationUnit: 'ml',
        ),
      ];

      final result1 = computeWeekStatusesMemoized(
        weekStart: weekStart,
        medicationSchedules: medicationSchedules,
        fluidSchedule: fluidSchedule,
        summaries: summaries,
        now: now,
      );

      final result2 = computeWeekStatusesMemoized(
        weekStart: weekStart,
        medicationSchedules: schedules2,
        fluidSchedule: fluidSchedule,
        summaries: summaries,
        now: now,
      );

      expect(identical(result1, result2), false);
    });

    test('cache miss with different fluid schedule', () {
      final fluidSchedule2 = Schedule(
        id: 'fluid2',
        treatmentType: TreatmentType.fluid,
        frequency: TreatmentFrequency.twiceDaily,
        reminderTimes: [
          DateTime(2025, 10, 20, 10),
          DateTime(2025, 10, 20, 22),
        ],
        isActive: true,
        createdAt: DateTime(2025, 10),
        updatedAt: DateTime(2025, 10),
        targetVolume: 150,
      );

      final result1 = computeWeekStatusesMemoized(
        weekStart: weekStart,
        medicationSchedules: medicationSchedules,
        fluidSchedule: fluidSchedule,
        summaries: summaries,
        now: now,
      );

      final result2 = computeWeekStatusesMemoized(
        weekStart: weekStart,
        medicationSchedules: medicationSchedules,
        fluidSchedule: fluidSchedule2,
        summaries: summaries,
        now: now,
      );

      expect(identical(result1, result2), false);
    });

    test('cache miss with different summaries', () {
      final summaries2 = <DateTime, DailySummary?>{
        DateTime(2025, 10, 20): DailySummary(
          date: DateTime(2025, 10, 20),
          overallStreak: 6, // Different streak
          medicationTotalDoses: 2,
          medicationScheduledDoses: 2,
          medicationMissedCount: 0,
          fluidTotalVolume: 100,
          fluidTreatmentDone: true,
          fluidSessionCount: 1,
          overallTreatmentDone: true,
          createdAt: DateTime(2025, 10, 20),
        ),
      };

      final result1 = computeWeekStatusesMemoized(
        weekStart: weekStart,
        medicationSchedules: medicationSchedules,
        fluidSchedule: fluidSchedule,
        summaries: summaries,
        now: now,
      );

      final result2 = computeWeekStatusesMemoized(
        weekStart: weekStart,
        medicationSchedules: medicationSchedules,
        fluidSchedule: fluidSchedule,
        summaries: summaries2,
        now: now,
      );

      expect(identical(result1, result2), false);
    });

    test('works with empty medication schedules list', () {
      final result = computeWeekStatusesMemoized(
        weekStart: weekStart,
        medicationSchedules: [], // Empty list
        fluidSchedule: fluidSchedule,
        summaries: summaries,
        now: now,
      );

      expect(result, isA<Map<DateTime, DayDotStatus>>());
      expect(result.length, 7); // Still returns 7 days
    });

    test('works with null fluid schedule', () {
      final result = computeWeekStatusesMemoized(
        weekStart: weekStart,
        medicationSchedules: medicationSchedules,
        fluidSchedule: null, // Null schedule
        summaries: summaries,
        now: now,
      );

      expect(result, isA<Map<DateTime, DayDotStatus>>());
      expect(result.length, 7);
    });

    test('works with empty summaries map', () {
      final result = computeWeekStatusesMemoized(
        weekStart: weekStart,
        medicationSchedules: medicationSchedules,
        fluidSchedule: fluidSchedule,
        summaries: {}, // Empty map
        now: now,
      );

      expect(result, isA<Map<DateTime, DayDotStatus>>());
      expect(result.length, 7);
    });

    test('works with null values in summaries map', () {
      final summariesWithNulls = <DateTime, DailySummary?>{
        DateTime(2025, 10, 20): null,
        DateTime(2025, 10, 21): null,
        DateTime(2025, 10, 22): null,
      };

      final result = computeWeekStatusesMemoized(
        weekStart: weekStart,
        medicationSchedules: medicationSchedules,
        fluidSchedule: fluidSchedule,
        summaries: summariesWithNulls,
        now: now,
      );

      expect(result, isA<Map<DateTime, DayDotStatus>>());
      expect(result.length, 7);
    });

    test('LRU eviction behavior - cache only keeps 10 entries', () {
      // Add 15 different weeks to trigger eviction
      final results = <Map<DateTime, DayDotStatus>>[];

      for (var i = 0; i < 15; i++) {
        final ws = weekStart.add(Duration(days: i * 7));
        final result = computeWeekStatusesMemoized(
          weekStart: ws,
          medicationSchedules: medicationSchedules,
          fluidSchedule: fluidSchedule,
          summaries: summaries,
          now: now,
        );
        results.add(result);
      }

      // The first 5 entries should have been evicted (15 - 10 = 5)
      // Re-call the first entry - should be a cache miss (different object)
      final firstWeekRecomputed = computeWeekStatusesMemoized(
        weekStart: weekStart,
        medicationSchedules: medicationSchedules,
        fluidSchedule: fluidSchedule,
        summaries: summaries,
        now: now,
      );

      // Should be a new object (cache miss)
      expect(identical(results[0], firstWeekRecomputed), false);

      // But the 11th entry (index 10) should still be cached
      final eleventhWeekRecalled = computeWeekStatusesMemoized(
        weekStart: weekStart.add(const Duration(days: 10 * 7)),
        medicationSchedules: medicationSchedules,
        fluidSchedule: fluidSchedule,
        summaries: summaries,
        now: now,
      );

      // Should be the same object (cache hit)
      expect(identical(results[10], eleventhWeekRecalled), true);
    });

    test('cache returns correct status values', () {
      final result = computeWeekStatusesMemoized(
        weekStart: weekStart,
        medicationSchedules: medicationSchedules,
        fluidSchedule: fluidSchedule,
        summaries: summaries,
        now: now,
      );

      // Verify the structure
      expect(result.length, 7);
      expect(result.keys.first, weekStart);
      expect(result.keys.last, weekStart.add(const Duration(days: 6)));

      // All values should be DayDotStatus enums
      for (final status in result.values) {
        expect(status, isA<DayDotStatus>());
      }
    });
  });
}
