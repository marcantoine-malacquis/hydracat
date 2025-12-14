import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/features/onboarding/models/treatment_data.dart';
import 'package:hydracat/features/profile/models/schedule.dart';

void main() {
  group('Schedule validation with optional reminder times', () {
    final now = DateTime.now();

    group('Medication schedules', () {
      test(
        'should be valid with empty reminderTimes (flexible scheduling)',
        () {
          final schedule = Schedule(
            id: 'test-med-flex',
            treatmentType: TreatmentType.medication,
            medicationName: 'Benazepril',
            targetDosage: 2,
            medicationUnit: 'Pills',
            frequency: TreatmentFrequency.onceDaily,
            reminderTimes: const [], // Empty - flexible scheduling
            isActive: true,
            createdAt: now,
            updatedAt: now,
            medicationStrengthAmount: '2.5',
            medicationStrengthUnit: 'mg',
          );

          expect(schedule.isValid, isTrue);
          expect(schedule.reminderTimes, isEmpty);
        },
      );

      test('should be valid with reminder times (scheduled)', () {
        final schedule = Schedule(
          id: 'test-med-scheduled',
          treatmentType: TreatmentType.medication,
          medicationName: 'Benazepril',
          targetDosage: 2,
          medicationUnit: 'Pills',
          frequency: TreatmentFrequency.onceDaily,
          reminderTimes: [
            DateTime(now.year, now.month, now.day, 9),
          ],
          isActive: true,
          createdAt: now,
          updatedAt: now,
        );

        expect(schedule.isValid, isTrue);
        expect(schedule.reminderTimes, hasLength(1));
      });

      test('should be invalid without medication name', () {
        final schedule = Schedule(
          id: 'test-med-invalid',
          treatmentType: TreatmentType.medication,
          targetDosage: 2,
          medicationUnit: 'Pills',
          frequency: TreatmentFrequency.onceDaily,
          reminderTimes: const [],
          isActive: true,
          createdAt: now,
          updatedAt: now,
        );

        expect(schedule.isValid, isFalse);
      });

      test('should be invalid without target dosage', () {
        final schedule = Schedule(
          id: 'test-med-invalid-2',
          treatmentType: TreatmentType.medication,
          medicationName: 'Benazepril',
          medicationUnit: 'Pills',
          frequency: TreatmentFrequency.onceDaily,
          reminderTimes: const [],
          isActive: true,
          createdAt: now,
          updatedAt: now,
        );

        expect(schedule.isValid, isFalse);
      });

      test('should be invalid with zero dosage', () {
        final schedule = Schedule(
          id: 'test-med-invalid-3',
          treatmentType: TreatmentType.medication,
          medicationName: 'Benazepril',
          targetDosage: 0,
          medicationUnit: 'Pills',
          frequency: TreatmentFrequency.onceDaily,
          reminderTimes: const [],
          isActive: true,
          createdAt: now,
          updatedAt: now,
        );

        expect(schedule.isValid, isFalse);
      });

      test('should be invalid without medication unit', () {
        final schedule = Schedule(
          id: 'test-med-invalid-4',
          treatmentType: TreatmentType.medication,
          medicationName: 'Benazepril',
          targetDosage: 2,
          frequency: TreatmentFrequency.onceDaily,
          reminderTimes: const [],
          isActive: true,
          createdAt: now,
          updatedAt: now,
        );

        expect(schedule.isValid, isFalse);
      });
    });

    group('Fluid schedules', () {
      test('should be invalid with empty reminderTimes', () {
        final schedule = Schedule(
          id: 'test-fluid-invalid',
          treatmentType: TreatmentType.fluid,
          targetVolume: 100,
          preferredLocation: FluidLocation.shoulderBladeLeft,
          needleGauge: NeedleGauge.gauge18,
          frequency: TreatmentFrequency.onceDaily,
          reminderTimes: const [], // Empty - NOT allowed for fluids
          isActive: true,
          createdAt: now,
          updatedAt: now,
        );

        expect(schedule.isValid, isFalse);
      });

      test('should be valid with reminder times', () {
        final schedule = Schedule(
          id: 'test-fluid-valid',
          treatmentType: TreatmentType.fluid,
          targetVolume: 100,
          preferredLocation: FluidLocation.shoulderBladeLeft,
          needleGauge: NeedleGauge.gauge18,
          frequency: TreatmentFrequency.onceDaily,
          reminderTimes: [
            DateTime(now.year, now.month, now.day, 9),
          ],
          isActive: true,
          createdAt: now,
          updatedAt: now,
        );

        expect(schedule.isValid, isTrue);
      });

      test('should be invalid without target volume', () {
        final schedule = Schedule(
          id: 'test-fluid-invalid-2',
          treatmentType: TreatmentType.fluid,
          preferredLocation: FluidLocation.shoulderBladeLeft,
          needleGauge: NeedleGauge.gauge18,
          frequency: TreatmentFrequency.onceDaily,
          reminderTimes: [
            DateTime(now.year, now.month, now.day, 9),
          ],
          isActive: true,
          createdAt: now,
          updatedAt: now,
        );

        expect(schedule.isValid, isFalse);
      });

      test('should be invalid with zero volume', () {
        final schedule = Schedule(
          id: 'test-fluid-invalid-3',
          treatmentType: TreatmentType.fluid,
          targetVolume: 0,
          preferredLocation: FluidLocation.shoulderBladeLeft,
          needleGauge: NeedleGauge.gauge18,
          frequency: TreatmentFrequency.onceDaily,
          reminderTimes: [
            DateTime(now.year, now.month, now.day, 9),
          ],
          isActive: true,
          createdAt: now,
          updatedAt: now,
        );

        expect(schedule.isValid, isFalse);
      });

      test('should be invalid without preferred location', () {
        final schedule = Schedule(
          id: 'test-fluid-invalid-4',
          treatmentType: TreatmentType.fluid,
          targetVolume: 100,
          needleGauge: NeedleGauge.gauge18,
          frequency: TreatmentFrequency.onceDaily,
          reminderTimes: [
            DateTime(now.year, now.month, now.day, 9),
          ],
          isActive: true,
          createdAt: now,
          updatedAt: now,
        );

        expect(schedule.isValid, isFalse);
      });

      test('should be invalid without needle gauge', () {
        final schedule = Schedule(
          id: 'test-fluid-invalid-5',
          treatmentType: TreatmentType.fluid,
          targetVolume: 100,
          preferredLocation: FluidLocation.shoulderBladeLeft,
          frequency: TreatmentFrequency.onceDaily,
          reminderTimes: [
            DateTime(now.year, now.month, now.day, 9),
          ],
          isActive: true,
          createdAt: now,
          updatedAt: now,
        );

        expect(schedule.isValid, isFalse);
      });
    });

    group('Backward compatibility', () {
      test('existing medication schedules with times remain valid', () {
        final schedule = Schedule(
          id: 'test-med-existing',
          treatmentType: TreatmentType.medication,
          medicationName: 'Amlodipine',
          targetDosage: 1,
          medicationUnit: 'Pills',
          frequency: TreatmentFrequency.twiceDaily,
          reminderTimes: [
            DateTime(now.year, now.month, now.day, 9),
            DateTime(now.year, now.month, now.day, 21),
          ],
          isActive: true,
          createdAt: now,
          updatedAt: now,
        );

        expect(schedule.isValid, isTrue);
        expect(schedule.reminderTimes, hasLength(2));
      });

      test('existing fluid schedules remain unchanged', () {
        final schedule = Schedule(
          id: 'test-fluid-existing',
          treatmentType: TreatmentType.fluid,
          targetVolume: 150,
          preferredLocation: FluidLocation.shoulderBladeLeft,
          needleGauge: NeedleGauge.gauge20,
          frequency: TreatmentFrequency.onceDaily,
          reminderTimes: [
            DateTime(now.year, now.month, now.day, 10),
          ],
          isActive: true,
          createdAt: now,
          updatedAt: now,
        );

        expect(schedule.isValid, isTrue);
        expect(schedule.reminderTimes, hasLength(1));
      });
    });
  });
}
