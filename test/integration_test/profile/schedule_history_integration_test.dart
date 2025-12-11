/// Integration tests for schedule history tracking
///
/// Tests schedule history service integration with Firestore:
/// - Saving schedule snapshots to history
/// - Retrieving historical schedule data
/// - Handling multiple schedule versions over time
library;

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/features/onboarding/models/treatment_data.dart';
import 'package:hydracat/features/profile/models/schedule.dart';
import 'package:hydracat/features/profile/services/schedule_history_service.dart';

import '../../helpers/profile_test_data_builders.dart';

void main() {
  group('Schedule History Integration Tests', () {
    late FakeFirebaseFirestore firestore;
    late ScheduleHistoryService historyService;

    const userId = 'test-user-123';
    const petId = 'test-pet-456';

    setUp(() {
      firestore = FakeFirebaseFirestore();
      historyService = ScheduleHistoryService(firestore: firestore);
    });

    group('Schedule Snapshot Saving', () {
      test('saves initial history entry for medication schedule', () async {
        // Arrange: Create a medication schedule
        final schedule = ScheduleBuilder.medication()
            .withId('med-schedule-001')
            .withMedicationName('Benazepril')
            .withTargetDosage(2.5)
            .withMedicationUnit('mg')
            .withFrequency(TreatmentFrequency.twiceDaily)
            .withReminderTimes([
              DateTime(2024, 11, 1, 9),
              DateTime(2024, 11, 1, 21),
            ])
            .withCreatedAt(DateTime(2024, 11))
            .build();

        // Act: Save snapshot
        await historyService.saveScheduleSnapshot(
          userId: userId,
          petId: petId,
          schedule: schedule,
          effectiveFrom: schedule.createdAt,
        );

        // Assert: Verify history entry was created
        final historyEntries = await historyService.getScheduleHistory(
          userId: userId,
          petId: petId,
          scheduleId: schedule.id,
        );

        expect(historyEntries.length, 1);
        expect(historyEntries[0].scheduleId, schedule.id);
        expect(historyEntries[0].medicationName, 'Benazepril');
        expect(historyEntries[0].targetDosage, 2.5);
        expect(historyEntries[0].reminderTimesIso, ['09:00:00', '21:00:00']);
        expect(historyEntries[0].effectiveTo, null); // Current version
      });

      test('saves initial history entry for fluid schedule', () async {
        // Arrange: Create a fluid schedule
        final schedule = ScheduleBuilder.fluid()
            .withId('fluid-schedule-001')
            .withTargetVolume(150)
            .withPreferredLocation(FluidLocation.shoulderBladeLeft)
            .withNeedleGauge(NeedleGauge.gauge18)
            .withFrequency(TreatmentFrequency.onceDaily)
            .withReminderTimes([DateTime(2024, 11, 1, 19)])
            .withCreatedAt(DateTime(2024, 11))
            .build();

        // Act: Save snapshot
        await historyService.saveScheduleSnapshot(
          userId: userId,
          petId: petId,
          schedule: schedule,
          effectiveFrom: schedule.createdAt,
        );

        // Assert: Verify history entry
        final historyEntries = await historyService.getScheduleHistory(
          userId: userId,
          petId: petId,
          scheduleId: schedule.id,
        );

        expect(historyEntries.length, 1);
        expect(historyEntries[0].treatmentType, TreatmentType.fluid);
        expect(historyEntries[0].targetVolume, 150);
        expect(historyEntries[0].preferredLocation, 'shoulderBladeLeft');
      });
    });

    group('Multiple Version Tracking', () {
      test('tracks multiple versions when schedule is updated', () async {
        // Arrange: Create initial schedule version
        final initialSchedule = ScheduleBuilder.medication()
            .withId('multi-version-001')
            .withMedicationName('Benazepril')
            .withTargetDosage(2.5)
            .withMedicationUnit('mg')
            .withFrequency(TreatmentFrequency.twiceDaily)
            .withReminderTimes([
              DateTime(2024, 10, 1, 9),
              DateTime(2024, 10, 1, 21),
            ])
            .withCreatedAt(DateTime(2024, 10))
            .build();

        // Save initial version
        await historyService.saveScheduleSnapshot(
          userId: userId,
          petId: petId,
          schedule: initialSchedule,
          effectiveFrom: DateTime(2024, 10),
          effectiveTo: DateTime(2024, 11),
        );

        // Act: Save updated version
        final updatedSchedule = initialSchedule.copyWith(
          targetDosage: 5.0,
          frequency: TreatmentFrequency.onceDaily,
          reminderTimes: [DateTime(2024, 11, 1, 10)],
          updatedAt: DateTime(2024, 11),
        );

        await historyService.saveScheduleSnapshot(
          userId: userId,
          petId: petId,
          schedule: updatedSchedule,
          effectiveFrom: DateTime(2024, 11),
        );

        // Assert: Verify history has 2 entries
        final historyEntries = await historyService.getScheduleHistory(
          userId: userId,
          petId: petId,
          scheduleId: initialSchedule.id,
        );

        expect(historyEntries.length, 2);

        // Most recent entry (index 0) should be the updated version
        expect(historyEntries[0].targetDosage, 5.0);
        expect(historyEntries[0].frequency, TreatmentFrequency.onceDaily);
        expect(historyEntries[0].reminderTimesIso, ['10:00:00']);
        expect(historyEntries[0].effectiveTo, null); // Current version

        // Older entry (index 1) should be the initial version
        expect(historyEntries[1].targetDosage, 2.5);
        expect(historyEntries[1].frequency, TreatmentFrequency.twiceDaily);
        expect(historyEntries[1].reminderTimesIso, ['09:00:00', '21:00:00']);
        expect(historyEntries[1].effectiveTo, isNotNull); // Has end date
      });

      test('handles multiple sequential updates', () async {
        // Arrange: Create initial schedule
        final initialSchedule = ScheduleBuilder.medication()
            .withId('sequential-updates-001')
            .withMedicationName('Amlodipine')
            .withTargetDosage(1.25)
            .withReminderTimes([DateTime(2024, 9, 1, 8)])
            .withCreatedAt(DateTime(2024, 9))
            .build();

        // Act: Save 4 versions
        await historyService.saveScheduleSnapshot(
          userId: userId,
          petId: petId,
          schedule: initialSchedule,
          effectiveFrom: DateTime(2024, 9),
          effectiveTo: DateTime(2024, 10),
        );

        final version2 = initialSchedule.copyWith(
          reminderTimes: [DateTime(2024, 10, 1, 9)],
        );
        await historyService.saveScheduleSnapshot(
          userId: userId,
          petId: petId,
          schedule: version2,
          effectiveFrom: DateTime(2024, 10),
          effectiveTo: DateTime(2024, 11),
        );

        final version3 = version2.copyWith(targetDosage: 2.5);
        await historyService.saveScheduleSnapshot(
          userId: userId,
          petId: petId,
          schedule: version3,
          effectiveFrom: DateTime(2024, 11),
          effectiveTo: DateTime(2024, 12),
        );

        final version4 = version3.copyWith(
          frequency: TreatmentFrequency.twiceDaily,
          reminderTimes: [
            DateTime(2024, 12, 1, 9),
            DateTime(2024, 12, 1, 21),
          ],
        );
        await historyService.saveScheduleSnapshot(
          userId: userId,
          petId: petId,
          schedule: version4,
          effectiveFrom: DateTime(2024, 12),
        );

        // Assert: Should have 4 history entries
        final historyEntries = await historyService.getScheduleHistory(
          userId: userId,
          petId: petId,
          scheduleId: initialSchedule.id,
        );

        expect(historyEntries.length, 4);

        // Verify progression (entries are ordered newest first)
        expect(historyEntries[0].frequency, TreatmentFrequency.twiceDaily);
        expect(historyEntries[1].targetDosage, 2.5);
        expect(historyEntries[2].reminderTimesIso, ['09:00:00']);
        expect(historyEntries[3].targetDosage, 1.25); // Original
      });
    });

    group('Historical Data Retrieval', () {
      test('retrieves correct schedule version for past date', () async {
        // Arrange: Create schedule with 3 versions
        const scheduleId = 'retrieval-test-001';

        final schedule1 = ScheduleBuilder.medication()
            .withId(scheduleId)
            .withMedicationName('Benazepril')
            .withTargetDosage(1.25)
            .withReminderTimes([DateTime(2024, 9, 1, 8)])
            .withCreatedAt(DateTime(2024, 9))
            .build();

        await historyService.saveScheduleSnapshot(
          userId: userId,
          petId: petId,
          schedule: schedule1,
          effectiveFrom: DateTime(2024, 9),
          effectiveTo: DateTime(2024, 10),
        );

        final schedule2 = schedule1.copyWith(
          targetDosage: 2.5,
          reminderTimes: [
            DateTime(2024, 10, 1, 9),
            DateTime(2024, 10, 1, 21),
          ],
        );

        await historyService.saveScheduleSnapshot(
          userId: userId,
          petId: petId,
          schedule: schedule2,
          effectiveFrom: DateTime(2024, 10),
          effectiveTo: DateTime(2024, 11),
        );

        final schedule3 = schedule2.copyWith(
          targetDosage: 5.0,
          reminderTimes: [
            DateTime(2024, 11, 1, 8),
            DateTime(2024, 11, 1, 16),
            DateTime(2024, 11, 1, 22),
          ],
        );

        await historyService.saveScheduleSnapshot(
          userId: userId,
          petId: petId,
          schedule: schedule3,
          effectiveFrom: DateTime(2024, 11),
        );

        // Act & Assert: Query for different dates
        // September date should get version 1
        final sept15Entry = await historyService.getScheduleAtDate(
          userId: userId,
          petId: petId,
          scheduleId: scheduleId,
          date: DateTime(2024, 9, 15),
        );

        expect(sept15Entry, isNotNull);
        expect(sept15Entry!.targetDosage, 1.25);
        expect(sept15Entry.reminderTimesIso, ['08:00:00']);

        // October date should get version 2
        final oct15Entry = await historyService.getScheduleAtDate(
          userId: userId,
          petId: petId,
          scheduleId: scheduleId,
          date: DateTime(2024, 10, 15),
        );

        expect(oct15Entry, isNotNull);
        expect(oct15Entry!.targetDosage, 2.5);
        expect(oct15Entry.reminderTimesIso, ['09:00:00', '21:00:00']);

        // November date should get version 3
        final nov15Entry = await historyService.getScheduleAtDate(
          userId: userId,
          petId: petId,
          scheduleId: scheduleId,
          date: DateTime(2024, 11, 15),
        );

        expect(nov15Entry, isNotNull);
        expect(nov15Entry!.targetDosage, 5.0);
        expect(nov15Entry.reminderTimesIso, [
          '08:00:00',
          '16:00:00',
          '22:00:00',
        ]);
      });

      test('returns correct reminder times for specific date', () async {
        // Arrange: Create schedule
        final schedule = ScheduleBuilder.medication()
            .withId('reminder-test-001')
            .withMedicationName('Test Med')
            .withReminderTimes([
              DateTime(2024, 10, 1, 9),
              DateTime(2024, 10, 1, 21),
            ])
            .withCreatedAt(DateTime(2024, 10))
            .build();

        await historyService.saveScheduleSnapshot(
          userId: userId,
          petId: petId,
          schedule: schedule,
          effectiveFrom: DateTime(2024, 10),
        );

        // Act: Query historical entry
        final entry = await historyService.getScheduleAtDate(
          userId: userId,
          petId: petId,
          scheduleId: schedule.id,
          date: DateTime(2024, 10, 15),
        );

        // Get reminder times for specific date
        final reminderTimes = entry!.getReminderTimesForDate(
          DateTime(2024, 10, 15),
        );

        // Assert: Times should be for Oct 15 specifically
        expect(reminderTimes.length, 2);
        expect(reminderTimes[0], DateTime(2024, 10, 15, 9));
        expect(reminderTimes[1], DateTime(2024, 10, 15, 21));
      });
    });
  });
}
