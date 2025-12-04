import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/features/progress/models/day_dot_status.dart';
import 'package:hydracat/features/progress/models/treatment_day_bucket.dart';
import 'package:hydracat/providers/progress_provider.dart';
import 'package:hydracat/shared/models/monthly_summary.dart';

void main() {
  group('buildMonthlyTreatmentBuckets', () {
    final october = DateTime(2025, 10);

    MonthlySummary buildSummary() => MonthlySummary.empty(october);

    test('returns null when summary is null', () {
      final result = buildMonthlyTreatmentBuckets(
        monthStart: october,
        summary: null,
      );
      expect(result, isNull);
    });

    test('returns null when array lengths mismatch', () {
      final summary = buildSummary().copyWith(
        dailyMedicationDoses: List.filled(30, 0),
      );
      final result = buildMonthlyTreatmentBuckets(
        monthStart: october,
        summary: summary,
      );
      expect(result, isNull);
    });

    test('builds buckets when arrays align with month length', () {
      final summary = buildSummary().copyWith(
        dailyVolumes: List.generate(31, (i) => i * 10),
        dailyGoals: List.filled(31, 250),
        dailyScheduledSessions: List.filled(31, 2),
        dailyMedicationDoses: List.generate(31, (i) => i % 3),
        dailyMedicationScheduledDoses: List.filled(31, 2),
      );

      final buckets = buildMonthlyTreatmentBuckets(
        monthStart: october,
        summary: summary,
      );

      expect(buckets, isNotNull);
      expect(buckets!.length, 31);
      expect(buckets.first.fluidVolumeMl, 0);
      expect(buckets[1].fluidVolumeMl, 10);
      expect(buckets.first.medicationDoses, 0);
      expect(buckets[1].medicationDoses, 1);
    });
  });

  group('_buildMonthStatusesFromBuckets', () {
    final now = DateTime(2025, 10, 15);
    TreatmentDayBucket bucketFor(
      DateTime date, {
      int fluidVolume = 0,
      int fluidGoal = 0,
      int fluidScheduled = 0,
      int fluidSessionCount = 0,
      int medicationDoses = 0,
      int medicationScheduled = 0,
    }) {
      return TreatmentDayBucket(
        date: date,
        fluidVolumeMl: fluidVolume,
        fluidGoalMl: fluidGoal,
        fluidScheduledSessions: fluidScheduled,
        fluidSessionCount: fluidSessionCount,
        medicationDoses: medicationDoses,
        medicationScheduledDoses: medicationScheduled,
      );
    }

    test('returns empty map when buckets null or empty', () {
      expect(buildMonthStatusesFromBuckets(null, now), isEmpty);
      expect(buildMonthStatusesFromBuckets([], now), isEmpty);
    });

    test('future days are marked none', () {
      final future = bucketFor(DateTime(2025, 11));
      final map = buildMonthStatusesFromBuckets([future], now);
      expect(map[future.date], DayDotStatus.none);
    });

    test('today without schedules is DayDotStatus.today', () {
      final todayBucket = bucketFor(now);
      final map = buildMonthStatusesFromBuckets([todayBucket], now);
      expect(map[todayBucket.date], DayDotStatus.today);
    });

    test('today with schedules complete is green', () {
      final todayBucket = bucketFor(
        now,
        fluidScheduled: 1,
        fluidGoal: 100,
        fluidVolume: 120,
      );
      final map = buildMonthStatusesFromBuckets([todayBucket], now);
      expect(map[todayBucket.date], DayDotStatus.complete);
    });

    test('today incomplete schedules stay gold', () {
      final todayBucket = bucketFor(
        now,
        medicationScheduled: 2,
        medicationDoses: 1,
      );
      final map = buildMonthStatusesFromBuckets([todayBucket], now);
      expect(map[todayBucket.date], DayDotStatus.today);
    });

    test('past days with no schedules are none', () {
      final past = bucketFor(DateTime(2025, 10, 10));
      final map = buildMonthStatusesFromBuckets([past], now);
      expect(map[past.date], DayDotStatus.none);
    });

    test('fluid-only miss shows red', () {
      final past = bucketFor(
        DateTime(2025, 10, 10),
        fluidScheduled: 1,
        fluidGoal: 200,
        fluidVolume: 100,
      );
      final map = buildMonthStatusesFromBuckets([past], now);
      expect(map[past.date], DayDotStatus.missed);
    });

    test('medication miss shows red', () {
      final past = bucketFor(
        DateTime(2025, 10, 10),
        medicationScheduled: 2,
        medicationDoses: 1,
      );
      final map = buildMonthStatusesFromBuckets([past], now);
      expect(map[past.date], DayDotStatus.missed);
    });

    test('complete past day is green', () {
      final past = bucketFor(
        DateTime(2025, 10, 10),
        fluidScheduled: 1,
        fluidGoal: 200,
        fluidVolume: 220,
        medicationScheduled: 1,
        medicationDoses: 1,
      );
      final map = buildMonthStatusesFromBuckets([past], now);
      expect(map[past.date], DayDotStatus.complete);
    });
  });
}
