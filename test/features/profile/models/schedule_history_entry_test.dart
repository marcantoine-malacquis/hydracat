import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/features/onboarding/models/treatment_data.dart';
import 'package:hydracat/features/profile/models/schedule.dart';
import 'package:hydracat/features/profile/models/schedule_history_entry.dart';

import '../../../helpers/profile_test_data_builders.dart';

void main() {
  group('ScheduleHistoryEntry', () {
    group('fromSchedule factory', () {
      test('creates history entry from medication schedule', () {
        final schedule = ScheduleBuilder.medication()
            .withId('med-123')
            .withMedicationName('Benazepril')
            .withTargetDosage(2.5)
            .withMedicationUnit('mg')
            .withFrequency(TreatmentFrequency.twiceDaily)
            .withReminderTimes([
              DateTime(2024, 11, 1, 9),
              DateTime(2024, 11, 1, 21),
            ])
            .withCreatedAt(DateTime(2024, 10))
            .build();

        final effectiveFrom = DateTime(2024, 10);
        final effectiveTo = DateTime(2024, 11);

        final entry = ScheduleHistoryEntry.fromSchedule(
          schedule,
          effectiveFrom: effectiveFrom,
          effectiveTo: effectiveTo,
        );

        expect(entry.scheduleId, 'med-123');
        expect(entry.effectiveFrom, effectiveFrom);
        expect(entry.effectiveTo, effectiveTo);
        expect(entry.treatmentType, TreatmentType.medication);
        expect(entry.frequency, TreatmentFrequency.twiceDaily);
        expect(entry.reminderTimesIso, ['09:00:00', '21:00:00']);
        expect(entry.medicationName, 'Benazepril');
        expect(entry.targetDosage, 2.5);
        expect(entry.medicationUnit, 'mg');
      });

      test('creates history entry from fluid schedule', () {
        final schedule = ScheduleBuilder.fluid()
            .withId('fluid-456')
            .withTargetVolume(150)
            .withPreferredLocation(FluidLocation.shoulderBladeLeft)
            .withNeedleGauge(NeedleGauge.gauge18)
            .withFrequency(TreatmentFrequency.onceDaily)
            .withReminderTimes([DateTime(2024, 11, 1, 19)])
            .withCreatedAt(DateTime(2024, 10))
            .build();

        final effectiveFrom = DateTime(2024, 10);

        final entry = ScheduleHistoryEntry.fromSchedule(
          schedule,
          effectiveFrom: effectiveFrom,
        );

        expect(entry.scheduleId, 'fluid-456');
        expect(entry.effectiveFrom, effectiveFrom);
        expect(entry.effectiveTo, null);
        expect(entry.treatmentType, TreatmentType.fluid);
        expect(entry.frequency, TreatmentFrequency.onceDaily);
        expect(entry.reminderTimesIso, ['19:00:00']);
        expect(entry.targetVolume, 150);
        expect(entry.preferredLocation, 'shoulderBladeLeft');
        expect(entry.needleGauge, NeedleGauge.gauge18);
      });

      test('converts reminder times to ISO time strings correctly', () {
        final schedule = ScheduleBuilder.medication().withReminderTimes([
          DateTime(2024, 11, 5, 8, 30), // 8:30 AM
          DateTime(2024, 11, 5, 14, 15), // 2:15 PM
          DateTime(2024, 11, 5, 20, 45), // 8:45 PM
        ]).build();

        final entry = ScheduleHistoryEntry.fromSchedule(
          schedule,
          effectiveFrom: DateTime(2024, 11),
        );

        expect(entry.reminderTimesIso, [
          '08:30:00',
          '14:15:00',
          '20:45:00',
        ]);
      });
    });

    group('JSON serialization', () {
      test('toJson serializes all fields correctly', () {
        final entry = ScheduleHistoryEntry(
          scheduleId: 'sched-789',
          effectiveFrom: DateTime(2024, 10, 1, 12),
          effectiveTo: DateTime(2024, 11, 1, 12),
          treatmentType: TreatmentType.medication,
          frequency: TreatmentFrequency.twiceDaily,
          reminderTimesIso: const ['09:00:00', '21:00:00'],
          medicationName: 'Amlodipine',
          targetDosage: 1.25,
          medicationUnit: 'mg',
          medicationStrengthAmount: '5',
          medicationStrengthUnit: 'mg',
        );

        final json = entry.toJson();

        expect(json['scheduleId'], 'sched-789');
        expect(json['effectiveFrom'], '2024-10-01T12:00:00.000');
        expect(json['effectiveTo'], '2024-11-01T12:00:00.000');
        expect(json['treatmentType'], 'medication');
        expect(json['frequency'], 'twiceDaily');
        expect(json['reminderTimesIso'], ['09:00:00', '21:00:00']);
        expect(json['medicationName'], 'Amlodipine');
        expect(json['targetDosage'], 1.25);
        expect(json['medicationUnit'], 'mg');
        expect(json['medicationStrengthAmount'], '5');
        expect(json['medicationStrengthUnit'], 'mg');
      });

      test('fromJson deserializes all fields correctly', () {
        final json = {
          'scheduleId': 'sched-789',
          'effectiveFrom': '2024-10-01T12:00:00.000',
          'effectiveTo': '2024-11-01T12:00:00.000',
          'treatmentType': 'medication',
          'frequency': 'twiceDaily',
          'reminderTimesIso': ['09:00:00', '21:00:00'],
          'medicationName': 'Amlodipine',
          'targetDosage': 1.25,
          'medicationUnit': 'mg',
          'medicationStrengthAmount': '5',
          'medicationStrengthUnit': 'mg',
          'customMedicationStrengthUnit': null,
          'targetVolume': null,
          'preferredLocation': null,
          'needleGauge': null,
        };

        final entry = ScheduleHistoryEntry.fromJson(json);

        expect(entry.scheduleId, 'sched-789');
        expect(entry.effectiveFrom, DateTime(2024, 10, 1, 12));
        expect(entry.effectiveTo, DateTime(2024, 11, 1, 12));
        expect(entry.treatmentType, TreatmentType.medication);
        expect(entry.frequency, TreatmentFrequency.twiceDaily);
        expect(entry.reminderTimesIso, ['09:00:00', '21:00:00']);
        expect(entry.medicationName, 'Amlodipine');
        expect(entry.targetDosage, 1.25);
        expect(entry.medicationUnit, 'mg');
      });

      test('roundtrip serialization preserves data', () {
        final original = ScheduleHistoryEntry(
          scheduleId: 'test-id',
          effectiveFrom: DateTime(2024, 10),
          effectiveTo: DateTime(2024, 11),
          treatmentType: TreatmentType.fluid,
          frequency: TreatmentFrequency.onceDaily,
          reminderTimesIso: const ['19:00:00'],
          targetVolume: 150,
          preferredLocation: 'shoulderBladeLeft',
          needleGauge: NeedleGauge.gauge18,
        );

        final json = original.toJson();
        final deserialized = ScheduleHistoryEntry.fromJson(json);

        expect(deserialized, original);
      });
    });

    group('getReminderTimesForDate', () {
      test('converts ISO time strings to DateTime for specific date', () {
        final entry = ScheduleHistoryEntry(
          scheduleId: 'test',
          effectiveFrom: DateTime(2024, 10),
          treatmentType: TreatmentType.medication,
          frequency: TreatmentFrequency.twiceDaily,
          reminderTimesIso: const ['09:00:00', '21:00:00'],
          medicationName: 'Test Med',
        );

        final date = DateTime(2024, 11, 5);
        final reminderTimes = entry.getReminderTimesForDate(date);

        expect(reminderTimes.length, 2);
        expect(reminderTimes[0], DateTime(2024, 11, 5, 9));
        expect(reminderTimes[1], DateTime(2024, 11, 5, 21));
      });

      test('handles different dates correctly', () {
        final entry = ScheduleHistoryEntry(
          scheduleId: 'test',
          effectiveFrom: DateTime(2024, 10),
          treatmentType: TreatmentType.medication,
          frequency: TreatmentFrequency.onceDaily,
          reminderTimesIso: const ['08:30:00'],
          medicationName: 'Test Med',
        );

        final date1 = DateTime(2024, 11);
        final times1 = entry.getReminderTimesForDate(date1);
        expect(times1[0], DateTime(2024, 11, 1, 8, 30));

        final date2 = DateTime(2024, 12, 25);
        final times2 = entry.getReminderTimesForDate(date2);
        expect(times2[0], DateTime(2024, 12, 25, 8, 30));
      });

      test('normalizes date to start of day', () {
        final entry = ScheduleHistoryEntry(
          scheduleId: 'test',
          effectiveFrom: DateTime(2024, 10),
          treatmentType: TreatmentType.medication,
          frequency: TreatmentFrequency.onceDaily,
          reminderTimesIso: const ['12:00:00'],
          medicationName: 'Test Med',
        );

        // Pass a date with time component
        final dateWithTime = DateTime(2024, 11, 5, 15, 30, 45);
        final reminderTimes = entry.getReminderTimesForDate(dateWithTime);

        // Should still use the date part only
        expect(reminderTimes[0], DateTime(2024, 11, 5, 12));
      });
    });

    group('equality and hashCode', () {
      test('equal entries have same hashCode', () {
        final entry1 = ScheduleHistoryEntry(
          scheduleId: 'test',
          effectiveFrom: DateTime(2024, 10),
          effectiveTo: DateTime(2024, 11),
          treatmentType: TreatmentType.medication,
          frequency: TreatmentFrequency.onceDaily,
          reminderTimesIso: const ['09:00:00'],
          medicationName: 'Test',
        );

        final entry2 = ScheduleHistoryEntry(
          scheduleId: 'test',
          effectiveFrom: DateTime(2024, 10),
          effectiveTo: DateTime(2024, 11),
          treatmentType: TreatmentType.medication,
          frequency: TreatmentFrequency.onceDaily,
          reminderTimesIso: const ['09:00:00'],
          medicationName: 'Test',
        );

        expect(entry1, entry2);
        expect(entry1.hashCode, entry2.hashCode);
      });

      test('different entries are not equal', () {
        final entry1 = ScheduleHistoryEntry(
          scheduleId: 'test1',
          effectiveFrom: DateTime(2024, 10),
          treatmentType: TreatmentType.medication,
          frequency: TreatmentFrequency.onceDaily,
          reminderTimesIso: const ['09:00:00'],
        );

        final entry2 = ScheduleHistoryEntry(
          scheduleId: 'test2',
          effectiveFrom: DateTime(2024, 10),
          treatmentType: TreatmentType.medication,
          frequency: TreatmentFrequency.onceDaily,
          reminderTimesIso: const ['09:00:00'],
        );

        expect(entry1 == entry2, false);
      });
    });
  });
}
