import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/features/home/models/pending_treatment.dart';
import 'package:hydracat/features/onboarding/models/treatment_data.dart';
import 'package:hydracat/features/profile/models/schedule.dart';

void main() {
  group('PendingTreatment display properties', () {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    group('Flexible medications (no reminder times)', () {
      test('isFlexible returns true when reminderTimes is empty', () {
        final schedule = Schedule(
          id: 'flex-1',
          treatmentType: TreatmentType.medication,
          medicationName: 'Flexible Med',
          targetDosage: 1,
          medicationUnit: 'Pills',
          frequency: TreatmentFrequency.onceDaily,
          reminderTimes: const [], // Empty
          isActive: true,
          createdAt: now,
          updatedAt: now,
        );

        final pending = PendingTreatment(
          schedule: schedule,
          scheduledTime: today,
          isOverdue: false,
        );

        expect(pending.isFlexible, isTrue);
      });

      test('displayTime returns null for flexible medications', () {
        final schedule = Schedule(
          id: 'flex-2',
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

        final pending = PendingTreatment(
          schedule: schedule,
          scheduledTime: today,
          isOverdue: false,
        );

        // UI will show localized "No time set" when displayTime is null
        expect(pending.displayTime, isNull);
      });

      test('isOverdue is always false for flexible medications', () {
        final schedule = Schedule(
          id: 'flex-3',
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

        final pending = PendingTreatment(
          schedule: schedule,
          scheduledTime: today,
          isOverdue: false, // Always false for flexible meds
        );

        expect(pending.isOverdue, isFalse);
        expect(pending.isFlexible, isTrue);
      });

      test('scheduledTime is date-only for flexible medications', () {
        final schedule = Schedule(
          id: 'flex-4',
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

        final pending = PendingTreatment(
          schedule: schedule,
          scheduledTime: DateTime(now.year, now.month, now.day), // Date only
          isOverdue: false,
        );

        expect(pending.scheduledTime.hour, equals(0));
        expect(pending.scheduledTime.minute, equals(0));
        expect(pending.scheduledTime.second, equals(0));
      });
    });

    group('Scheduled medications (with reminder times)', () {
      test('isFlexible returns false when reminderTimes is not empty', () {
        final schedule = Schedule(
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

        final pending = PendingTreatment(
          schedule: schedule,
          scheduledTime: DateTime(today.year, today.month, today.day, 9),
          isOverdue: false,
        );

        expect(pending.isFlexible, isFalse);
      });

      test('displayTime returns formatted time for scheduled medications', () {
        final schedule = Schedule(
          id: 'scheduled-2',
          treatmentType: TreatmentType.medication,
          medicationName: 'Scheduled Med',
          targetDosage: 1,
          medicationUnit: 'Pills',
          frequency: TreatmentFrequency.onceDaily,
          reminderTimes: [
            DateTime(today.year, today.month, today.day, 9, 30),
          ],
          isActive: true,
          createdAt: now,
          updatedAt: now,
        );

        final pending = PendingTreatment(
          schedule: schedule,
          scheduledTime: DateTime(today.year, today.month, today.day, 9, 30),
          isOverdue: false,
        );

        // Should return formatted time like "09:30"
        expect(pending.displayTime, isNotNull);
        expect(pending.displayTime, contains(':'));
      });

      test('can be marked as overdue', () {
        final schedule = Schedule(
          id: 'scheduled-3',
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

        final pending = PendingTreatment(
          schedule: schedule,
          scheduledTime: DateTime(today.year, today.month, today.day, 9),
          isOverdue: true, // Can be overdue
        );

        expect(pending.isOverdue, isTrue);
        expect(pending.isFlexible, isFalse);
      });
    });

    group('Other display properties', () {
      test('displayName shows medication name', () {
        final schedule = Schedule(
          id: 'med-1',
          treatmentType: TreatmentType.medication,
          medicationName: 'Benazepril',
          targetDosage: 2,
          medicationUnit: 'Pills',
          frequency: TreatmentFrequency.onceDaily,
          reminderTimes: const [],
          isActive: true,
          createdAt: now,
          updatedAt: now,
        );

        final pending = PendingTreatment(
          schedule: schedule,
          scheduledTime: today,
          isOverdue: false,
        );

        expect(pending.displayName, equals('Benazepril'));
      });

      test('displayDosage formats dosage with unit', () {
        final schedule = Schedule(
          id: 'med-2',
          treatmentType: TreatmentType.medication,
          medicationName: 'Med',
          targetDosage: 2.5,
          medicationUnit: 'Pills',
          frequency: TreatmentFrequency.onceDaily,
          reminderTimes: const [],
          isActive: true,
          createdAt: now,
          updatedAt: now,
        );

        final pending = PendingTreatment(
          schedule: schedule,
          scheduledTime: today,
          isOverdue: false,
        );

        // Should format with short form unit
        expect(pending.displayDosage, contains('2.5'));
      });

      test('displayStrength returns formatted strength when present', () {
        final schedule = Schedule(
          id: 'med-3',
          treatmentType: TreatmentType.medication,
          medicationName: 'Med',
          targetDosage: 1,
          medicationUnit: 'Pills',
          frequency: TreatmentFrequency.onceDaily,
          reminderTimes: const [],
          medicationStrengthAmount: '2.5',
          medicationStrengthUnit: 'mg',
          isActive: true,
          createdAt: now,
          updatedAt: now,
        );

        final pending = PendingTreatment(
          schedule: schedule,
          scheduledTime: today,
          isOverdue: false,
        );

        expect(pending.displayStrength, isNotNull);
        expect(pending.displayStrength, contains('2.5'));
        expect(pending.displayStrength, contains('mg'));
      });

      test('displayStrength returns null when not set', () {
        final schedule = Schedule(
          id: 'med-4',
          treatmentType: TreatmentType.medication,
          medicationName: 'Med',
          targetDosage: 1,
          medicationUnit: 'Pills',
          frequency: TreatmentFrequency.onceDaily,
          reminderTimes: const [],
          isActive: true,
          createdAt: now,
          updatedAt: now,
        );

        final pending = PendingTreatment(
          schedule: schedule,
          scheduledTime: today,
          isOverdue: false,
        );

        expect(pending.displayStrength, isNull);
      });
    });
  });
}
