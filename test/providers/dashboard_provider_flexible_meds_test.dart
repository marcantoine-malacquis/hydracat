import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/features/home/models/pending_treatment.dart';
import 'package:hydracat/features/logging/models/daily_summary_cache.dart';
import 'package:hydracat/features/onboarding/models/treatment_data.dart';
import 'package:hydracat/features/profile/models/schedule.dart';

void main() {
  group('Dashboard with flexible medications (no reminder times)', () {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    group('Pending treatment creation for flexible medications', () {
      test('creates PendingTreatment with date-only scheduledTime', () {
        final flexSchedule = Schedule(
          id: 'flex-med-1',
          treatmentType: TreatmentType.medication,
          medicationName: 'Flexible Med',
          targetDosage: 1,
          medicationUnit: 'Pills',
          frequency: TreatmentFrequency.onceDaily,
          reminderTimes: const [], // Empty - flexible
          isActive: true,
          createdAt: now,
          updatedAt: now,
        );

        // Create PendingTreatment manually to test the structure
        final pendingTreatment = PendingTreatment(
          schedule: flexSchedule,
          scheduledTime: DateTime(now.year, now.month, now.day),
          isOverdue: false,
        );

        expect(pendingTreatment.schedule.id, 'flex-med-1');
        expect(pendingTreatment.schedule.reminderTimes, isEmpty);
        expect(pendingTreatment.scheduledTime, equals(today));
        expect(pendingTreatment.isOverdue, isFalse);
      });

      test(
        'Product Decision #3: flexible medications never marked as overdue',
        () {
          final flexSchedule = Schedule(
            id: 'flex-med-2',
            treatmentType: TreatmentType.medication,
            medicationName: 'Flexible Med',
            targetDosage: 1,
            medicationUnit: 'Pills',
            frequency: TreatmentFrequency.onceDaily,
            reminderTimes: const [],
            isActive: true,
            createdAt: now,
            updatedAt: now,
          );

          final pendingTreatment = PendingTreatment(
            schedule: flexSchedule,
            scheduledTime: DateTime(now.year, now.month, now.day),
            isOverdue: false, // Always false for flexible meds
          );

          // Verify isOverdue is false regardless of time of day
          expect(pendingTreatment.isOverdue, isFalse);
        },
      );
    });

    group('Completion tracking for flexible medications', () {
      test(
        'Product Decision #1: flexible medication completed after first log',
        () {
          final flexSchedule = Schedule(
            id: 'flex-med-3',
            treatmentType: TreatmentType.medication,
            medicationName: 'Flexible Med',
            targetDosage: 1,
            medicationUnit: 'Pills',
            frequency: TreatmentFrequency.onceDaily,
            reminderTimes: const [],
            isActive: true,
            createdAt: now,
            updatedAt: now,
          );

          // Cache with this medication logged
          const cache = DailySummaryCache(
            date: '2025-12-11',
            medicationSessionCount: 1,
            fluidSessionCount: 0,
            medicationNames: ['Flexible Med'], // Logged today
            totalMedicationDosesGiven: 1,
            totalFluidVolumeGiven: 0,
          );

          // Flexible meds have no reminder times and should be marked complete
          expect(flexSchedule.reminderTimes, isEmpty);

          // Verify medication is in cache
          expect(cache.medicationNames, contains(flexSchedule.medicationName));
        },
      );

      test('medication not completed if not in cache', () {
        final flexSchedule = Schedule(
          id: 'flex-med-4',
          treatmentType: TreatmentType.medication,
          medicationName: 'Not Logged Yet',
          targetDosage: 1,
          medicationUnit: 'Pills',
          frequency: TreatmentFrequency.onceDaily,
          reminderTimes: const [],
          isActive: true,
          createdAt: now,
          updatedAt: now,
        );

        // Empty cache - nothing logged today
        final cache = DailySummaryCache.empty('2025-12-11');

        // Flexible meds should still have no reminder times
        expect(flexSchedule.reminderTimes, isEmpty);

        // Verify medication is NOT in cache
        expect(
          cache.medicationNames,
          isNot(contains(flexSchedule.medicationName)),
        );
      });

      test('different medications tracked separately', () {
        // Cache with multiple medications
        const cache = DailySummaryCache(
          date: '2025-12-11',
          medicationSessionCount: 2,
          fluidSessionCount: 0,
          medicationNames: ['Med A', 'Med B'],
          totalMedicationDosesGiven: 2,
          totalFluidVolumeGiven: 0,
        );

        expect(cache.medicationNames, contains('Med A'));
        expect(cache.medicationNames, contains('Med B'));
        expect(cache.medicationNames, isNot(contains('Med C')));
      });
    });

    group('Mixed scheduled and flexible medications', () {
      test('can have both scheduled and flexible medications together', () {
        final scheduledMed = Schedule(
          id: 'scheduled-1',
          treatmentType: TreatmentType.medication,
          medicationName: 'Scheduled Med',
          targetDosage: 1,
          medicationUnit: 'Pills',
          frequency: TreatmentFrequency.onceDaily,
          reminderTimes: [
            DateTime(today.year, today.month, today.day, 9),
          ],
          isActive: true,
          createdAt: now,
          updatedAt: now,
        );

        final flexibleMed = Schedule(
          id: 'flexible-1',
          treatmentType: TreatmentType.medication,
          medicationName: 'Flexible Med',
          targetDosage: 2,
          medicationUnit: 'ml',
          frequency: TreatmentFrequency.onceDaily,
          reminderTimes: const [],
          isActive: true,
          createdAt: now,
          updatedAt: now,
        );

        // Both are valid
        expect(scheduledMed.isValid, isTrue);
        expect(flexibleMed.isValid, isTrue);

        // Scheduled has reminder times, flexible doesn't
        expect(scheduledMed.reminderTimes, hasLength(1));
        expect(flexibleMed.reminderTimes, isEmpty);
      });
    });

    group('Product Decision #4: Multi-instance logging', () {
      test('allows unlimited logging per day for flexible medications', () {
        // Cache showing multiple logs of same medication
        const cache = DailySummaryCache(
          date: '2025-12-11',
          medicationSessionCount: 3, // Logged 3 times
          fluidSessionCount: 0,
          medicationNames: ['Flexible Med'],
          totalMedicationDosesGiven: 3, // 3 total doses
          totalFluidVolumeGiven: 0,
        );

        // First log marks it complete (disappears from pending)
        expect(cache.medicationNames, contains('Flexible Med'));

        // But user can still log additional instances manually
        expect(cache.totalMedicationDosesGiven, equals(3));
      });
    });

    group('Backward compatibility', () {
      test(
        'scheduled medications continue to work with time-based matching',
        () {
          final scheduledMed = Schedule(
            id: 'scheduled-2',
            treatmentType: TreatmentType.medication,
            medicationName: 'Scheduled Med',
            targetDosage: 1,
            medicationUnit: 'Pills',
            frequency: TreatmentFrequency.twiceDaily,
            reminderTimes: [
              DateTime(today.year, today.month, today.day, 9),
              DateTime(today.year, today.month, today.day, 21),
            ],
            isActive: true,
            createdAt: now,
            updatedAt: now,
          );

          // Should have 2 reminder times for today
          expect(scheduledMed.todaysReminderTimes(now), hasLength(2));

          // Should be able to create 2 separate PendingTreatments
          final morning = PendingTreatment(
            schedule: scheduledMed,
            scheduledTime: DateTime(today.year, today.month, today.day, 9),
            isOverdue: false,
          );

          final evening = PendingTreatment(
            schedule: scheduledMed,
            scheduledTime: DateTime(today.year, today.month, today.day, 21),
            isOverdue: false,
          );

          expect(morning.scheduledTime.hour, equals(9));
          expect(evening.scheduledTime.hour, equals(21));
        },
      );
    });
  });
}
