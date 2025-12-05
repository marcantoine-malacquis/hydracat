import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/features/progress/models/treatment_day_bucket.dart';

void main() {
  group('TreatmentDayBucket', () {
    final testDate = DateTime(2025, 10, 15);

    TreatmentDayBucket buildBucket({
      DateTime? date,
      int fluidVolumeMl = 0,
      int fluidGoalMl = 0,
      int fluidScheduled = 0,
      int fluidSessionCount = 0,
      int medicationDoses = 0,
      int medicationScheduled = 0,
    }) {
      return TreatmentDayBucket(
        date: date ?? testDate,
        fluidVolumeMl: fluidVolumeMl,
        fluidGoalMl: fluidGoalMl,
        fluidScheduledSessions: fluidScheduled,
        fluidSessionCount: fluidSessionCount,
        medicationDoses: medicationDoses,
        medicationScheduledDoses: medicationScheduled,
      );
    }

    test('equality compares all fields', () {
      final bucket1 = buildBucket();
      final bucket2 = buildBucket();
      expect(bucket1, equals(bucket2));
      expect(bucket1.hashCode, equals(bucket2.hashCode));
    });

    test('hasScheduledTreatments true when either scheduled', () {
      expect(buildBucket(fluidScheduled: 2).hasScheduledTreatments, isTrue);
      expect(
        buildBucket(medicationScheduled: 1).hasScheduledTreatments,
        isTrue,
      );
      expect(buildBucket().hasScheduledTreatments, isFalse);
    });

    test('fluid completion uses session count vs scheduled', () {
      final complete = buildBucket(
        fluidScheduled: 2,
        fluidSessionCount: 2,
      );
      final incomplete = buildBucket(
        fluidScheduled: 2,
        fluidSessionCount: 1,
      );
      expect(complete.isFluidComplete, isTrue);
      expect(incomplete.isFluidComplete, isFalse);
    });

    test('medication completion compares doses vs scheduled', () {
      final complete = buildBucket(
        medicationScheduled: 3,
        medicationDoses: 3,
      );
      final partial = buildBucket(
        medicationScheduled: 3,
        medicationDoses: 2,
      );
      expect(complete.isMedicationComplete, isTrue);
      expect(partial.isMedicationComplete, isFalse);
    });

    test('isMissed true when either treatment missed on past day', () {
      final pastDate = DateTime(2024);
      final bucket = buildBucket(
        date: pastDate,
        fluidScheduled: 1,
      );
      expect(bucket.isMissed, isTrue);

      final medBucket = buildBucket(
        date: pastDate,
        medicationScheduled: 2,
        medicationDoses: 1,
      );
      expect(medBucket.isMissed, isTrue);
    });

    test('isComplete true only when all scheduled treatments complete', () {
      final complete = buildBucket(
        fluidScheduled: 1,
        fluidSessionCount: 1,
        medicationScheduled: 2,
        medicationDoses: 2,
      );

      final incompleteMed = buildBucket(
        fluidScheduled: 1,
        fluidSessionCount: 1,
        medicationScheduled: 2,
        medicationDoses: 1,
      );

      expect(complete.isComplete, isTrue);
      expect(incompleteMed.isComplete, isFalse);
    });

    test('isPending true for today when not complete', () {
      final today = DateTime.now();
      final bucket = buildBucket(
        date: DateTime(today.year, today.month, today.day),
        fluidScheduled: 1,
      );
      expect(bucket.isPending, isTrue);
    });

    test('toString contains key fields', () {
      final bucket = buildBucket(fluidScheduled: 1, medicationScheduled: 2);
      final str = bucket.toString();
      expect(str, contains('TreatmentDayBucket'));
      expect(str, contains('fluidScheduledSessions: 1'));
      expect(str, contains('medicationScheduledDoses: 2'));
    });
  });
}
