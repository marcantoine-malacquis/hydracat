import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/features/onboarding/models/treatment_data.dart';
import 'package:hydracat/features/profile/models/schedule.dart';
import 'package:hydracat/features/profile/models/schedule_history_entry.dart';
import 'package:hydracat/features/profile/services/schedule_history_service.dart';

import '../../../helpers/profile_test_data_builders.dart';

void main() {
  group('ScheduleHistoryService', () {
    late FakeFirebaseFirestore firestore;
    late ScheduleHistoryService service;

    const userId = 'test-user-123';
    const petId = 'test-pet-456';
    const scheduleId = 'test-schedule-789';

    setUp(() {
      firestore = FakeFirebaseFirestore();
      service = ScheduleHistoryService(firestore: firestore);
    });

    group('saveScheduleSnapshot', () {
      test('saves schedule snapshot to history subcollection', () async {
        final schedule = ScheduleBuilder.medication()
            .withId(scheduleId)
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

        await service.saveScheduleSnapshot(
          userId: userId,
          petId: petId,
          schedule: schedule,
          effectiveFrom: effectiveFrom,
          effectiveTo: effectiveTo,
        );

        // Verify document was created
        final historyDoc = await firestore
            .collection('users')
            .doc(userId)
            .collection('pets')
            .doc(petId)
            .collection('schedules')
            .doc(scheduleId)
            .collection('history')
            .doc(effectiveFrom.millisecondsSinceEpoch.toString())
            .get();

        expect(historyDoc.exists, true);
        final data = historyDoc.data()!;
        expect(data['scheduleId'], scheduleId);
        expect(data['medicationName'], 'Benazepril');
        expect(data['targetDosage'], 2.5);
        expect(data['reminderTimesIso'], ['09:00:00', '21:00:00']);
      });

      test('uses millisecondsSinceEpoch as document ID', () async {
        final schedule = ScheduleBuilder.medication()
            .withId(scheduleId)
            .build();

        final effectiveFrom = DateTime(2024, 10, 15, 14, 30);
        final expectedDocId = effectiveFrom.millisecondsSinceEpoch.toString();

        await service.saveScheduleSnapshot(
          userId: userId,
          petId: petId,
          schedule: schedule,
          effectiveFrom: effectiveFrom,
        );

        final doc = await firestore
            .collection('users')
            .doc(userId)
            .collection('pets')
            .doc(petId)
            .collection('schedules')
            .doc(scheduleId)
            .collection('history')
            .doc(expectedDocId)
            .get();

        expect(doc.exists, true);
      });

      test('saves null effectiveTo for current version', () async {
        final schedule = ScheduleBuilder.medication()
            .withId(scheduleId)
            .build();

        final effectiveFrom = DateTime(2024, 11);

        await service.saveScheduleSnapshot(
          userId: userId,
          petId: petId,
          schedule: schedule,
          effectiveFrom: effectiveFrom,
        );

        final doc = await firestore
            .collection('users')
            .doc(userId)
            .collection('pets')
            .doc(petId)
            .collection('schedules')
            .doc(scheduleId)
            .collection('history')
            .doc(effectiveFrom.millisecondsSinceEpoch.toString())
            .get();

        final data = doc.data()!;
        expect(data['effectiveTo'], null);
      });
    });

    group('getScheduleAtDate', () {
      test('returns schedule history for exact date', () async {
        // Setup: Create history entry
        final effectiveFrom = DateTime(2024, 10);
        final entry = ScheduleHistoryEntry(
          scheduleId: scheduleId,
          effectiveFrom: effectiveFrom,
          effectiveTo: DateTime(2024, 11),
          treatmentType: TreatmentType.medication,
          frequency: TreatmentFrequency.twiceDaily,
          reminderTimesIso: const ['09:00:00', '21:00:00'],
          medicationName: 'Benazepril',
          targetDosage: 2.5,
          medicationUnit: 'mg',
        );

        await firestore
            .collection('users')
            .doc(userId)
            .collection('pets')
            .doc(petId)
            .collection('schedules')
            .doc(scheduleId)
            .collection('history')
            .doc(effectiveFrom.millisecondsSinceEpoch.toString())
            .set(entry.toJson());

        // Query for date within effective range
        final result = await service.getScheduleAtDate(
          userId: userId,
          petId: petId,
          scheduleId: scheduleId,
          date: DateTime(2024, 10, 15),
        );

        expect(result, isNotNull);
        expect(result!.scheduleId, scheduleId);
        expect(result.medicationName, 'Benazepril');
        expect(result.targetDosage, 2.5);
      });

      test('returns most recent entry when multiple versions exist', () async {
        // Create three history entries
        final entry1 = ScheduleHistoryEntry(
          scheduleId: scheduleId,
          effectiveFrom: DateTime(2024, 9),
          effectiveTo: DateTime(2024, 10),
          treatmentType: TreatmentType.medication,
          frequency: TreatmentFrequency.onceDaily,
          reminderTimesIso: const ['08:00:00'],
          medicationName: 'Benazepril',
          targetDosage: 1.25,
          medicationUnit: 'mg',
        );

        final entry2 = ScheduleHistoryEntry(
          scheduleId: scheduleId,
          effectiveFrom: DateTime(2024, 10),
          effectiveTo: DateTime(2024, 11),
          treatmentType: TreatmentType.medication,
          frequency: TreatmentFrequency.twiceDaily,
          reminderTimesIso: const ['09:00:00', '21:00:00'],
          medicationName: 'Benazepril',
          targetDosage: 2.5,
          medicationUnit: 'mg',
        );

        final entry3 = ScheduleHistoryEntry(
          scheduleId: scheduleId,
          effectiveFrom: DateTime(2024, 11),
          treatmentType: TreatmentType.medication,
          frequency: TreatmentFrequency.thriceDaily,
          reminderTimesIso: const ['08:00:00', '16:00:00', '22:00:00'],
          medicationName: 'Benazepril',
          targetDosage: 3,
          medicationUnit: 'mg',
        );

        final historyRef = firestore
            .collection('users')
            .doc(userId)
            .collection('pets')
            .doc(petId)
            .collection('schedules')
            .doc(scheduleId)
            .collection('history');

        await historyRef
            .doc(entry1.effectiveFrom.millisecondsSinceEpoch.toString())
            .set(entry1.toJson());
        await historyRef
            .doc(entry2.effectiveFrom.millisecondsSinceEpoch.toString())
            .set(entry2.toJson());
        await historyRef
            .doc(entry3.effectiveFrom.millisecondsSinceEpoch.toString())
            .set(entry3.toJson());

        // Query for date in October (should get entry2)
        final result = await service.getScheduleAtDate(
          userId: userId,
          petId: petId,
          scheduleId: scheduleId,
          date: DateTime(2024, 10, 15),
        );

        expect(result, isNotNull);
        expect(result!.targetDosage, 2.5);
        expect(result.frequency, TreatmentFrequency.twiceDaily);
        expect(result.reminderTimesIso, ['09:00:00', '21:00:00']);
      });

      test('returns null when no history exists for date', () async {
        // No history entries created

        final result = await service.getScheduleAtDate(
          userId: userId,
          petId: petId,
          scheduleId: scheduleId,
          date: DateTime(2024, 10, 15),
        );

        expect(result, isNull);
      });

      test('returns null when date is after effectiveTo', () async {
        final entry = ScheduleHistoryEntry(
          scheduleId: scheduleId,
          effectiveFrom: DateTime(2024, 9),
          effectiveTo: DateTime(2024, 10),
          treatmentType: TreatmentType.medication,
          frequency: TreatmentFrequency.onceDaily,
          reminderTimesIso: const ['08:00:00'],
          medicationName: 'Test',
        );

        await firestore
            .collection('users')
            .doc(userId)
            .collection('pets')
            .doc(petId)
            .collection('schedules')
            .doc(scheduleId)
            .collection('history')
            .doc(entry.effectiveFrom.millisecondsSinceEpoch.toString())
            .set(entry.toJson());

        // Query for date after effectiveTo
        final result = await service.getScheduleAtDate(
          userId: userId,
          petId: petId,
          scheduleId: scheduleId,
          date: DateTime(2024, 10, 15), // After Oct 1
        );

        expect(result, isNull);
      });

      test(
        'returns entry when effectiveTo is null (current version)',
        () async {
          final entry = ScheduleHistoryEntry(
            scheduleId: scheduleId,
            effectiveFrom: DateTime(2024, 10),
            treatmentType: TreatmentType.medication,
            frequency: TreatmentFrequency.onceDaily,
            reminderTimesIso: const ['08:00:00'],
            medicationName: 'Test',
          );

          await firestore
              .collection('users')
              .doc(userId)
              .collection('pets')
              .doc(petId)
              .collection('schedules')
              .doc(scheduleId)
              .collection('history')
              .doc(entry.effectiveFrom.millisecondsSinceEpoch.toString())
              .set(entry.toJson());

          // Query for any date after effectiveFrom
          final result = await service.getScheduleAtDate(
            userId: userId,
            petId: petId,
            scheduleId: scheduleId,
            date: DateTime(2024, 12),
          );

          expect(result, isNotNull);
          expect(result!.medicationName, 'Test');
        },
      );
    });

    group('getScheduleHistory', () {
      test(
        'returns all history entries ordered by effectiveFrom descending',
        () async {
          final entry1 = ScheduleHistoryEntry(
            scheduleId: scheduleId,
            effectiveFrom: DateTime(2024, 9),
            effectiveTo: DateTime(2024, 10),
            treatmentType: TreatmentType.medication,
            frequency: TreatmentFrequency.onceDaily,
            reminderTimesIso: const ['08:00:00'],
            medicationName: 'Version 1',
          );

          final entry2 = ScheduleHistoryEntry(
            scheduleId: scheduleId,
            effectiveFrom: DateTime(2024, 10),
            effectiveTo: DateTime(2024, 11),
            treatmentType: TreatmentType.medication,
            frequency: TreatmentFrequency.twiceDaily,
            reminderTimesIso: const ['09:00:00', '21:00:00'],
            medicationName: 'Version 2',
          );

          final entry3 = ScheduleHistoryEntry(
            scheduleId: scheduleId,
            effectiveFrom: DateTime(2024, 11),
            treatmentType: TreatmentType.medication,
            frequency: TreatmentFrequency.thriceDaily,
            reminderTimesIso: const ['08:00:00', '16:00:00', '22:00:00'],
            medicationName: 'Version 3',
          );

          final historyRef = firestore
              .collection('users')
              .doc(userId)
              .collection('pets')
              .doc(petId)
              .collection('schedules')
              .doc(scheduleId)
              .collection('history');

          await historyRef
              .doc(entry1.effectiveFrom.millisecondsSinceEpoch.toString())
              .set(entry1.toJson());
          await historyRef
              .doc(entry2.effectiveFrom.millisecondsSinceEpoch.toString())
              .set(entry2.toJson());
          await historyRef
              .doc(entry3.effectiveFrom.millisecondsSinceEpoch.toString())
              .set(entry3.toJson());

          final result = await service.getScheduleHistory(
            userId: userId,
            petId: petId,
            scheduleId: scheduleId,
          );

          expect(result.length, 3);
          // Should be ordered descending (most recent first)
          expect(result[0].medicationName, 'Version 3');
          expect(result[1].medicationName, 'Version 2');
          expect(result[2].medicationName, 'Version 1');
        },
      );

      test('returns empty list when no history exists', () async {
        final result = await service.getScheduleHistory(
          userId: userId,
          petId: petId,
          scheduleId: scheduleId,
        );

        expect(result, isEmpty);
      });
    });
  });
}
