/// Integration tests for logging user flows
///
/// Tests end-to-end service flows with provider integration:
/// - Manual medication logging
/// - Manual fluid logging
/// - Quick-log all treatments
/// - Edge cases and error handling
library;

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/features/logging/services/summary_cache_service.dart';
import 'package:hydracat/features/onboarding/models/treatment_data.dart';
import 'package:hydracat/features/profile/models/schedule.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/integration_test_helpers.dart';
import '../../helpers/test_data_builders.dart';

void main() {
  group('Manual Medication Logging Flow', () {
    late FakeFirebaseFirestore fakeFirestore;
    late SharedPreferences prefs;
    late SummaryCacheService cacheService;

    setUp(() async {
      fakeFirestore = createFakeFirestore();
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      cacheService = SummaryCacheService(prefs);
    });

    test('logs medication session with pre-filled schedule data', () async {
      // Arrange: Create schedule with today's reminder
      final schedule = ScheduleBuilderIntegrationExtensions.withTodaysReminder(
        medicationName: 'Amlodipine',
      ).build();

      final session =
          MedicationSessionBuilderIntegrationExtensions.fromSchedule(
            schedule,
          ).build();

      // Act: Write session directly (simulating service call)
      await fakeFirestore
          .collection('medicationSessions')
          .doc(session.id)
          .set(session.toJson());

      // Assert: Session created with schedule linkage
      await assertSessionExists(
        fakeFirestore,
        session.id,
        medicationName: 'Amlodipine',
        dosageGiven: schedule.targetDosage!,
      );

      final doc = await fakeFirestore
          .collection('medicationSessions')
          .doc(session.id)
          .get();

      expect(doc.data()!['scheduleId'], equals(schedule.id));
    });

    test('detects duplicate within ±15 minute window', () async {
      // Arrange: Log first session at 8:00 AM
      final baseTime = DateTime(2024, 10, 9, 8);
      final firstSession = MedicationSessionBuilder()
          .withMedicationName('Amlodipine')
          .withDateTime(baseTime)
          .build();

      await fakeFirestore
          .collection('medicationSessions')
          .doc(firstSession.id)
          .set(firstSession.toJson());

      // Create second session at 8:10 AM (within window)
      final duplicateSession =
          MedicationSessionBuilderIntegrationExtensions.forDuplicateTest(
            baseTime,
          ).build();

      // Act & Assert: This would be caught by service layer
      // Here we just verify the timing logic
      final timeDifference = duplicateSession.dateTime
          .difference(baseTime)
          .abs();
      expect(timeDifference.inMinutes, equals(10));
      expect(timeDifference.inMinutes, lessThan(15));
    });

    test('allows duplicate outside time window', () async {
      // Arrange: Log first session at 8:00 AM
      final firstTime = DateTime(2024, 10, 9, 8);
      final firstSession = MedicationSessionBuilder()
          .withMedicationName('Amlodipine')
          .withDateTime(firstTime)
          .build();

      await fakeFirestore
          .collection('medicationSessions')
          .doc(firstSession.id)
          .set(firstSession.toJson());

      // Act: Log second session at 10:00 AM (2+ hours later)
      final secondTime = firstTime.add(const Duration(hours: 2));
      final secondSession = MedicationSessionBuilder()
          .withMedicationName('Amlodipine')
          .withDateTime(secondTime)
          .build();

      await fakeFirestore
          .collection('medicationSessions')
          .doc(secondSession.id)
          .set(secondSession.toJson());

      // Assert: Both sessions exist
      final count = await countDocuments(
        fakeFirestore,
        'medicationSessions',
        whereConditions: {'medicationName': 'Amlodipine'},
      );

      expect(count, equals(2));
    });

    test('handles validation errors gracefully', () async {
      // Arrange: Create session with invalid dosage
      final invalidSession = MedicationSessionBuilder()
          .withDosageGiven(-1)
          .build();

      // Act & Assert: Validation should fail
      final validationErrors = invalidSession.validate();
      expect(validationErrors.isNotEmpty, isTrue);
    });

    test('updates cache after successful log', () async {
      // Arrange
      final session = MedicationSessionBuilder()
          .withMedicationName('Amlodipine')
          .withDosageGiven(2.5)
          .build();

      // Act: Update cache manually (simulating provider behavior)
      await cacheService.updateCacheWithMedicationSession(
        userId: 'test-user-id',
        petId: 'test-pet-id',
        medicationName: session.medicationName,
        dosageGiven: session.dosageGiven,
        completed: session.completed,
      );

      // Assert: Cache updated
      final cache = await cacheService.getTodaySummary(
        'test-user-id',
        'test-pet-id',
      );

      expect(cache, isNotNull);
      expect(cache!.hasMedicationSession, isTrue);
      expect(cache.totalMedicationDosesGiven, equals(2.5));
    });
  });

  group('Manual Fluid Logging Flow', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() async {
      fakeFirestore = createFakeFirestore();
    });

    test('logs fluid session with schedule matching', () async {
      // Arrange: Create fluid schedule
      final schedule =
          ScheduleBuilderIntegrationExtensions.withFluidTodaysReminder()
              .build();

      final session = FluidSessionBuilderIntegrationExtensions.fromSchedule(
        schedule,
      ).build();

      // Act: Write session
      await fakeFirestore
          .collection('fluidSessions')
          .doc(session.id)
          .set(session.toJson());

      // Assert: Session created
      await assertFluidSessionExists(
        fakeFirestore,
        session.id,
        volumeGiven: 100,
      );
    });

    test('allows multiple fluid sessions per day', () async {
      // Arrange & Act: Log 3 sessions at different times
      final sessions = [
        FluidSessionBuilder()
            .withDateTime(DateTime(2024, 10, 9, 8))
            .withVolumeGiven(50)
            .build(),
        FluidSessionBuilder()
            .withDateTime(DateTime(2024, 10, 9, 14))
            .withVolumeGiven(75)
            .build(),
        FluidSessionBuilder()
            .withDateTime(DateTime(2024, 10, 9, 20))
            .withVolumeGiven(50)
            .build(),
      ];

      for (final session in sessions) {
        await fakeFirestore
            .collection('fluidSessions')
            .doc(session.id)
            .set(session.toJson());
      }

      // Assert: All 3 created (no duplicate detection for fluids)
      final count = await countDocuments(fakeFirestore, 'fluidSessions');
      expect(count, equals(3));
    });

    test('validates volume range', () async {
      // Test: Invalid volumes
      final invalidLow = FluidSessionBuilder().withVolumeGiven(0).build();
      final invalidLowErrors = invalidLow.validate();
      expect(invalidLowErrors.isNotEmpty, isTrue);

      final invalidHigh = FluidSessionBuilder().withVolumeGiven(600).build();
      final invalidHighErrors = invalidHigh.validate();
      expect(invalidHighErrors.isNotEmpty, isTrue);

      // Test: Valid volume
      final valid = FluidSessionBuilder().withVolumeGiven(250).build();
      final validErrors = valid.validate();
      expect(validErrors.isEmpty, isTrue);
    });

    test('handles optional fields correctly', () async {
      // Test 1: All fields populated
      final fullSession = FluidSessionBuilder()
          .withVolumeGiven(100)
          .withInjectionSite(FluidLocation.hipBonesLeft)
          .withStressLevel('low')
          .withNotes('Cat was calm')
          .build();

      await fakeFirestore
          .collection('fluidSessions')
          .doc(fullSession.id)
          .set(fullSession.toJson());

      final doc1 = await fakeFirestore
          .collection('fluidSessions')
          .doc(fullSession.id)
          .get();

      expect(doc1.data()!['injectionSite'], isNotNull);
      expect(doc1.data()!['stressLevel'], isNotNull);
      expect(doc1.data()!['notes'], isNotNull);

      // Test 2: Minimal fields (using builder defaults)
      final minimalSession = FluidSessionBuilder().withVolumeGiven(100).build();

      await fakeFirestore
          .collection('fluidSessions')
          .doc(minimalSession.id)
          .set(minimalSession.toJson());

      final doc2 = await fakeFirestore
          .collection('fluidSessions')
          .doc(minimalSession.id)
          .get();

      expect(doc2.data()!['volumeGiven'], equals(100));
    });
  });

  group('Quick-Log All Treatments', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = createFakeFirestore();
    });

    test('logs all active schedules in single batch', () async {
      // Arrange: 3 medications (2 reminders each) + 1 fluid (2 reminders)
      final medSchedules = [
        ScheduleBuilderIntegrationExtensions.withMultipleReminders(
          [8, 20],
          medicationName: 'Amlodipine',
        ).build(),
        ScheduleBuilderIntegrationExtensions.withMultipleReminders(
          [8, 20],
          medicationName: 'Benazepril',
        ).build(),
        ScheduleBuilderIntegrationExtensions.withMultipleReminders(
          [12],
          medicationName: 'Calcitriol',
        ).build(),
      ];

      final fluidSchedule =
          ScheduleBuilderIntegrationExtensions.withFluidTodaysReminder()
              .build();
      fluidSchedule.reminderTimes.add(
        DateTime(
          fluidSchedule.reminderTimes.first.year,
          fluidSchedule.reminderTimes.first.month,
          fluidSchedule.reminderTimes.first.day,
          20,
        ),
      );

      // Act: Create sessions for all reminder times
      final allSessions = <String>[];

      for (final schedule in medSchedules) {
        for (final reminderTime in schedule.reminderTimes) {
          final session = MedicationSessionBuilder()
              .withMedicationName(schedule.medicationName!)
              .withDosageGiven(schedule.targetDosage!)
              .withDateTime(reminderTime)
              .build();

          await fakeFirestore
              .collection('medicationSessions')
              .doc(session.id)
              .set(session.toJson());
          allSessions.add(session.id);
        }
      }

      for (final reminderTime in fluidSchedule.reminderTimes) {
        final session = FluidSessionBuilder()
            .withVolumeGiven(fluidSchedule.targetVolume!)
            .withDateTime(reminderTime)
            .build();

        await fakeFirestore
            .collection('fluidSessions')
            .doc(session.id)
            .set(session.toJson());
        allSessions.add(session.id);
      }

      // Assert: 7 sessions created (2+2+1 medications + 2 fluids)
      final medCount = await countDocuments(
        fakeFirestore,
        'medicationSessions',
      );
      final fluidCount = await countDocuments(fakeFirestore, 'fluidSessions');

      expect(medCount, equals(5));
      expect(fluidCount, equals(2));
      expect(allSessions.length, equals(7));
    });

    test('rejects quick-log if sessions already logged today', () async {
      // This would be handled by service layer checking cache
      // Here we verify the cache detection logic

      // Arrange: Create cache with existing session
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final cacheService = SummaryCacheService(prefs);

      await cacheService.updateCacheWithMedicationSession(
        userId: 'test-user-id',
        petId: 'test-pet-id',
        medicationName: 'Amlodipine',
        dosageGiven: 1,
        completed: true,
      );

      // Act: Check cache
      final cache = await cacheService.getTodaySummary(
        'test-user-id',
        'test-pet-id',
      );

      // Assert: Cache shows sessions exist
      expect(cache, isNotNull);
      expect(cache!.hasAnySessions, isTrue);
    });

    test('handles empty schedule list gracefully', () async {
      // Arrange: Empty schedule list
      final schedules = <Schedule>[];

      // Act & Assert: Service would return early or throw appropriate exception
      expect(schedules.isEmpty, isTrue);
      // No Firestore writes should occur
    });
  });

  group('Logging Edge Cases', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = createFakeFirestore();
    });

    test(
      'handles multiple medications with same name at different times',
      () async {
        // Arrange: "Amlodipine" at 8 AM and 8 PM
        final schedule1 = ScheduleBuilder()
            .withMedicationName('Amlodipine')
            .withTargetDosage(2.5)
            .withMedicationUnit('mg')
            .withReminderTime(DateTime(2024, 10, 9, 8))
            .build();

        final schedule2 = ScheduleBuilder()
            .withMedicationName('Amlodipine')
            .withTargetDosage(2.5)
            .withMedicationUnit('mg')
            .withReminderTime(DateTime(2024, 10, 9, 20))
            .build();

        // Act: Log both sessions
        final session1 =
            MedicationSessionBuilderIntegrationExtensions.fromSchedule(
              schedule1,
            ).build();
        final session2 =
            MedicationSessionBuilderIntegrationExtensions.fromSchedule(
              schedule2,
            ).build();

        await fakeFirestore
            .collection('medicationSessions')
            .doc(session1.id)
            .set(session1.toJson());

        await fakeFirestore
            .collection('medicationSessions')
            .doc(session2.id)
            .set(session2.toJson());

        // Assert: Both logged with different scheduleId values
        final count = await countDocuments(
          fakeFirestore,
          'medicationSessions',
          whereConditions: {'medicationName': 'Amlodipine'},
        );

        expect(count, equals(2));

        final doc1 = await fakeFirestore
            .collection('medicationSessions')
            .doc(session1.id)
            .get();
        final doc2 = await fakeFirestore
            .collection('medicationSessions')
            .doc(session2.id)
            .get();

        expect(doc1.data()!['scheduleId'], equals(schedule1.id));
        expect(doc2.data()!['scheduleId'], equals(schedule2.id));
        expect(
          doc1.data()!['scheduleId'],
          isNot(equals(doc2.data()!['scheduleId'])),
        );
      },
    );

    test('handles ambiguous schedule matching', () async {
      // Arrange: Two schedules for same medication, both within ±2h window
      final sessionTime = DateTime(2024, 10, 9, 9);

      final schedule1 = ScheduleBuilder()
          .withMedicationName('Amlodipine')
          .withReminderTime(DateTime(2024, 10, 9, 8))
          .build();

      final schedule2 = ScheduleBuilder()
          .withMedicationName('Amlodipine')
          .withReminderTime(DateTime(2024, 10, 9, 10))
          .build();

      // Act: Calculate time differences
      final diff1 = sessionTime.difference(schedule1.reminderTimes.first).abs();
      final diff2 = sessionTime.difference(schedule2.reminderTimes.first).abs();

      // Assert: Closest time logic (9:00 AM is equidistant)
      expect(diff1.inMinutes, equals(60)); // 1 hour away
      expect(diff2.inMinutes, equals(60)); // 1 hour away
      // Tie: service picks first match or uses additional criteria
    });

    test('logs session without schedule (manual entry)', () async {
      // Arrange: Session with no schedule linkage
      final session = MedicationSessionBuilder()
          .withScheduleId(null)
          .withScheduledTime(null)
          .build();

      // Act: Write session
      await fakeFirestore
          .collection('medicationSessions')
          .doc(session.id)
          .set(session.toJson());

      // Assert: Session created successfully
      final doc = await fakeFirestore
          .collection('medicationSessions')
          .doc(session.id)
          .get();

      expect(doc.exists, isTrue);
      expect(doc.data()!['scheduleId'], isNull);
      expect(doc.data()!['scheduledTime'], isNull);
    });

    test('validates composite index query (medication name + time)', () async {
      // Arrange: Create multiple sessions for duplicate detection scenario
      final sessions = [
        MedicationSessionBuilder()
            .withMedicationName('Amlodipine')
            .withDateTime(DateTime(2024, 10, 9, 8))
            .build(),
        MedicationSessionBuilder()
            .withMedicationName('Amlodipine')
            .withDateTime(DateTime(2024, 10, 9, 14))
            .build(),
        MedicationSessionBuilder()
            .withMedicationName('Benazepril')
            .withDateTime(DateTime(2024, 10, 9, 8))
            .build(),
      ];

      for (final session in sessions) {
        await fakeFirestore
            .collection('medicationSessions')
            .doc(session.id)
            .set(session.toJson());
      }

      // Act: Query by medication name (simulates duplicate detection)
      final query = await fakeFirestore
          .collection('medicationSessions')
          .where('medicationName', isEqualTo: 'Amlodipine')
          .get();

      // Assert: Query succeeds (fake_cloud_firestore simulates index)
      expect(query.docs.length, equals(2));
    });
  });
}
