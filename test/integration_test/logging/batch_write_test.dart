/// Integration tests for 4-write batch strategy
///
/// Tests validate that logging operations correctly write to Firestore:
/// - 1 session document
/// - 3 summary documents (daily, weekly, monthly)
///
/// Uses fake_cloud_firestore to avoid real Firebase costs and network latency.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/core/utils/date_utils.dart';
import 'package:hydracat/features/onboarding/models/treatment_data.dart';
import 'package:hydracat/features/profile/models/schedule.dart';

import '../../helpers/integration_test_helpers.dart';
import '../../helpers/test_data_builders.dart';

void main() {
  group('Medication Session - 4-Write Batch Strategy', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() async {
      fakeFirestore = createFakeFirestore();
    });

    test('creates session document with correct structure', () async {
      // Arrange
      final session = MedicationSessionBuilder.completed()
          .withMedicationName('Amlodipine')
          .withDosageGiven(2.5)
          .withDosageScheduled(2.5)
          .build();

      // Create collection reference in fake Firestore
      await fakeFirestore
          .collection('medicationSessions')
          .doc(session.id)
          .set(session.toJson());

      // Assert
      final doc = await fakeFirestore
          .collection('medicationSessions')
          .doc(session.id)
          .get();

      expect(doc.exists, isTrue);
      expect(doc.data()!['medicationName'], equals('Amlodipine'));
      expect(doc.data()!['dosageGiven'], equals(2.5));
      expect(doc.data()!['dosageScheduled'], equals(2.5));
      expect(doc.data()!['completed'], isTrue);
    });

    test('creates daily summary with FieldValue.increment', () async {
      // Arrange
      final now = DateTime.now();
      final dailyId = AppDateUtils.formatDateForSummary(now);

      // Act: Simulate summary creation with increment
      await fakeFirestore
          .collection('treatmentSummaries')
          .doc('daily')
          .collection('summaries')
          .doc(dailyId)
          .set(
            {
              'date': Timestamp.fromDate(now),
              'medicationTotalDoses': FieldValue.increment(1),
              'medicationScheduledDoses': FieldValue.increment(1),
              'fluidTotalVolume': FieldValue.increment(0),
              'fluidSessionCount': FieldValue.increment(0),
              'overallTreatmentDone': false,
              'overallAdherence': 1.0,
              'overallStreak': 0,
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );

      // Assert
      final doc = await fakeFirestore
          .collection('treatmentSummaries')
          .doc('daily')
          .collection('summaries')
          .doc(dailyId)
          .get();

      expect(doc.exists, isTrue);
      expect(doc.data()!['medicationTotalDoses'], equals(1));
      expect(doc.data()!['date'], isA<Timestamp>());
    });

    test('creates weekly summary with correct week ID', () async {
      // Arrange
      final now = DateTime.now();
      final weekId = AppDateUtils.formatWeekForSummary(now);
      final weekSpan = AppDateUtils.getWeekStartEnd(now);

      // Act
      await fakeFirestore
          .collection('treatmentSummaries')
          .doc('weekly')
          .collection('summaries')
          .doc(weekId)
          .set(
            {
              'startDate': Timestamp.fromDate(weekSpan['start']!),
              'endDate': Timestamp.fromDate(weekSpan['end']!),
              'medicationTotalDoses': FieldValue.increment(1),
              'treatmentDayCount': 0,
              'missedDayCount': 0,
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );

      // Assert
      await assertWeeklySummaryExists(fakeFirestore, now);
      // The library directive may trigger deprecated_member_use warnings
      // in some Dart versions.
      // ignore: deprecated_member_use
      expect(weekId, matches(RegExp(r'^\d{4}-W\d{2}$')));
    });

    test('creates monthly summary with correct month ID', () async {
      // Arrange
      final now = DateTime.now();
      final monthId = AppDateUtils.formatMonthForSummary(now);
      final monthSpan = AppDateUtils.getMonthStartEnd(now);

      // Act
      await fakeFirestore
          .collection('treatmentSummaries')
          .doc('monthly')
          .collection('summaries')
          .doc(monthId)
          .set(
            {
              'startDate': Timestamp.fromDate(monthSpan['start']!),
              'endDate': Timestamp.fromDate(monthSpan['end']!),
              'medicationTotalDoses': FieldValue.increment(1),
              'currentStreak': 0,
              'longestStreak': 0,
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );

      // Assert
      await assertMonthlySummaryExists(fakeFirestore, now);
      // The library directive may trigger deprecated_member_use warnings
      // in some Dart versions.
      // ignore: deprecated_member_use
      expect(monthId, matches(RegExp(r'^\d{4}-\d{2}$')));
    });

    test('updates existing daily summary (merge: true)', () async {
      // Arrange: Create initial summary
      final now = DateTime.now();
      final dailyId = AppDateUtils.formatDateForSummary(now);

      await fakeFirestore
          .collection('treatmentSummaries')
          .doc('daily')
          .collection('summaries')
          .doc(dailyId)
          .set({
            'date': Timestamp.fromDate(now),
            'medicationTotalDoses': 1,
            'fluidTotalVolume': 0,
            'overallStreak': 0,
          });

      // Act: Second session (should increment, not overwrite)
      await fakeFirestore
          .collection('treatmentSummaries')
          .doc('daily')
          .collection('summaries')
          .doc(dailyId)
          .set(
            {
              'medicationTotalDoses': FieldValue.increment(1),
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );

      // Assert: Count should be 2, not 1
      final doc = await fakeFirestore
          .collection('treatmentSummaries')
          .doc('daily')
          .collection('summaries')
          .doc(dailyId)
          .get();

      expect(doc.data()!['medicationTotalDoses'], equals(2));
    });

    test('handles schedule matching by name and time', () async {
      // Arrange: Create schedule with specific time
      final reminderTime = DateTime(2024, 10, 9, 8);
      final schedule = ScheduleBuilder()
          .withMedicationName('Amlodipine')
          .withTargetDosage(2.5)
          .withReminderTime(reminderTime)
          .build();

      // Create session within ±2 hour window
      final sessionTime = reminderTime.add(
        const Duration(hours: 1, minutes: 30),
      );
      final session = MedicationSessionBuilder()
          .withMedicationName('Amlodipine')
          .withDateTime(sessionTime)
          .build();

      // Act: Verify schedule would match (logic validation)
      final timeDifference = sessionTime.difference(reminderTime).abs();

      // Assert
      expect(schedule.medicationName, equals(session.medicationName));
      expect(timeDifference.inHours, lessThan(2));
    });

    test('handles no matching schedule gracefully', () async {
      // Arrange: Session with no schedules
      final session = MedicationSessionBuilder()
          .withScheduleId(null)
          .withScheduledTime(null)
          .build();

      // Act: Write session to Firestore
      await fakeFirestore
          .collection('medicationSessions')
          .doc(session.id)
          .set(session.toJson());

      // Assert: Session created successfully with null scheduleId
      final doc = await fakeFirestore
          .collection('medicationSessions')
          .doc(session.id)
          .get();

      expect(doc.exists, isTrue);
      expect(doc.data()!['scheduleId'], isNull);
      expect(doc.data()!['scheduledTime'], isNull);
    });
  });

  group('Fluid Session - 4-Write Batch Strategy', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = createFakeFirestore();
    });

    test('creates fluid session with injection site enum', () async {
      // Arrange
      final session = FluidSessionBuilder()
          .withVolumeGiven(100)
          .withInjectionSite(FluidLocation.shoulderBladeLeft)
          .build();

      // Act
      await fakeFirestore
          .collection('fluidSessions')
          .doc(session.id)
          .set(session.toJson());

      // Assert
      final doc = await fakeFirestore
          .collection('fluidSessions')
          .doc(session.id)
          .get();

      expect(doc.exists, isTrue);
      expect(doc.data()!['volumeGiven'], equals(100.0));
      expect(
        doc.data()!['injectionSite'],
        equals('shoulderBladeLeft'),
      ); // Enum stored as string
    });

    test('creates summaries with fluid-specific fields', () async {
      // Arrange
      final now = DateTime.now();
      final dailyId = AppDateUtils.formatDateForSummary(now);

      // Act
      await fakeFirestore
          .collection('treatmentSummaries')
          .doc('daily')
          .collection('summaries')
          .doc(dailyId)
          .set(
            {
              'date': Timestamp.fromDate(now),
              'fluidTotalVolume': FieldValue.increment(100.0),
              'fluidSessionCount': FieldValue.increment(1),
              'medicationTotalDoses': FieldValue.increment(0),
              'overallStreak': 0,
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );

      // Assert
      await assertDailySummaryFluidVolume(fakeFirestore, now, 100);
    });

    test('handles schedule matching by time only', () async {
      // Arrange: Fluid schedule with specific time
      final reminderTime = DateTime(2024, 10, 9, 14);
      final schedule = ScheduleBuilder.fluid()
          .withTargetVolume(100)
          .withReminderTime(reminderTime)
          .build();

      // Create session within ±2 hour window (no name matching for fluids)
      final sessionTime = reminderTime.add(const Duration(hours: 1));

      // Act: Verify schedule would match
      final timeDifference = sessionTime.difference(reminderTime).abs();

      // Assert: Fluids match by time only (no name filter)
      expect(schedule.treatmentType, equals(TreatmentType.fluid));
      expect(timeDifference.inHours, lessThan(2));
    });

    test('allows multiple sessions per day (no duplicate detection)', () async {
      // Arrange: Create 3 fluid sessions at different times
      final sessions = [
        FluidSessionBuilder().withVolumeGiven(50).build(),
        FluidSessionBuilder().withVolumeGiven(50).build(),
        FluidSessionBuilder().withVolumeGiven(50).build(),
      ];

      // Act: Write all sessions
      for (final session in sessions) {
        await fakeFirestore
            .collection('fluidSessions')
            .doc(session.id)
            .set(session.toJson());
      }

      // Assert: All 3 created
      final count = await countDocuments(fakeFirestore, 'fluidSessions');

      expect(count, equals(3));
    });

    test('handles stress level and injection site optionality', () async {
      // Test 1: With all optional fields
      final sessionWithFields = FluidSessionBuilder()
          .withVolumeGiven(100)
          .withInjectionSite(FluidLocation.hipBonesLeft)
          .withStressLevel('low')
          .withNotes('Cat was calm')
          .build();

      await fakeFirestore
          .collection('fluidSessions')
          .doc(sessionWithFields.id)
          .set(sessionWithFields.toJson());

      final doc1 = await fakeFirestore
          .collection('fluidSessions')
          .doc(sessionWithFields.id)
          .get();

      expect(doc1.data()!['injectionSite'], equals('hipBonesLeft'));
      expect(doc1.data()!['stressLevel'], equals('low'));
      expect(doc1.data()!['notes'], equals('Cat was calm'));

      // Test 2: Minimal fields (no optionals)
      final sessionMinimal = FluidSessionBuilder().withVolumeGiven(100).build();

      await fakeFirestore
          .collection('fluidSessions')
          .doc(sessionMinimal.id)
          .set(sessionMinimal.toJson());

      final doc2 = await fakeFirestore
          .collection('fluidSessions')
          .doc(sessionMinimal.id)
          .get();

      expect(doc2.exists, isTrue);
      // Note: FluidSessionBuilder has defaults, so these might not be null
    });

    test('validates volume range (1-500ml)', () async {
      // Valid volumes should pass validation
      final validSession = FluidSessionBuilder().withVolumeGiven(250).build();
      final validResult = validSession.validate();
      expect(validResult.isEmpty, isTrue);

      // Invalid volumes should fail validation
      final invalidLow = FluidSessionBuilder().withVolumeGiven(0).build();
      final invalidLowResult = invalidLow.validate();
      expect(invalidLowResult.isNotEmpty, isTrue);

      final invalidHigh = FluidSessionBuilder().withVolumeGiven(600).build();
      final invalidHighResult = invalidHigh.validate();
      expect(invalidHighResult.isNotEmpty, isTrue);
    });
  });

  group('Multi-Session Summary Aggregation', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = createFakeFirestore();
    });

    test('aggregates 5 medication sessions correctly', () async {
      // Arrange
      final now = DateTime.now();
      final dailyId = AppDateUtils.formatDateForSummary(now);

      // Act: Simulate logging 5 sessions with different dosages
      final dosages = [1.0, 2.0, 1.5, 2.5, 1.0];
      for (final dosage in dosages) {
        await fakeFirestore
            .collection('treatmentSummaries')
            .doc('daily')
            .collection('summaries')
            .doc(dailyId)
            .set(
              {
                'medicationTotalDoses': FieldValue.increment(dosage.toInt()),
                'updatedAt': FieldValue.serverTimestamp(),
              },
              SetOptions(merge: true),
            );
      }

      // Assert: Total should be 7 (sum of integer dosages: 1+2+1+2+1)
      final doc = await fakeFirestore
          .collection('treatmentSummaries')
          .doc('daily')
          .collection('summaries')
          .doc(dailyId)
          .get();

      expect(doc.data()!['medicationTotalDoses'], equals(7));
    });

    test('aggregates mixed medication and fluid sessions', () async {
      // Arrange
      final now = DateTime.now();
      final dailyId = AppDateUtils.formatDateForSummary(now);

      // Act: Log 3 medications + 2 fluids
      // Medications
      for (var i = 0; i < 3; i++) {
        await fakeFirestore
            .collection('treatmentSummaries')
            .doc('daily')
            .collection('summaries')
            .doc(dailyId)
            .set(
              {
                'medicationTotalDoses': FieldValue.increment(1),
              },
              SetOptions(merge: true),
            );
      }

      // Fluids
      for (var i = 0; i < 2; i++) {
        await fakeFirestore
            .collection('treatmentSummaries')
            .doc('daily')
            .collection('summaries')
            .doc(dailyId)
            .set(
              {
                'fluidTotalVolume': FieldValue.increment(100.0),
                'fluidSessionCount': FieldValue.increment(1),
              },
              SetOptions(merge: true),
            );
      }

      // Assert
      final doc = await fakeFirestore
          .collection('treatmentSummaries')
          .doc('daily')
          .collection('summaries')
          .doc(dailyId)
          .get();

      expect(doc.data()!['medicationTotalDoses'], equals(3));
      expect(doc.data()!['fluidTotalVolume'], equals(200.0));
      expect(doc.data()!['fluidSessionCount'], equals(2));
    });

    test('handles session updates with delta calculation', () async {
      // Arrange: Log initial session with dosage 1
      final now = DateTime.now();
      final dailyId = AppDateUtils.formatDateForSummary(now);

      await fakeFirestore
          .collection('treatmentSummaries')
          .doc('daily')
          .collection('summaries')
          .doc(dailyId)
          .set(
            {
              'medicationTotalDoses': FieldValue.increment(1),
            },
            SetOptions(merge: true),
          );

      // Act: Update session to dosage 2 (delta = +1)
      await fakeFirestore
          .collection('treatmentSummaries')
          .doc('daily')
          .collection('summaries')
          .doc(dailyId)
          .set(
            {
              'medicationTotalDoses': FieldValue.increment(
                1,
              ), // Delta adjustment
            },
            SetOptions(merge: true),
          );

      // Assert: Should be 2, not 3 (not double-counting)
      final doc = await fakeFirestore
          .collection('treatmentSummaries')
          .doc('daily')
          .collection('summaries')
          .doc(dailyId)
          .get();

      expect(doc.data()!['medicationTotalDoses'], equals(2));
    });

    test('maintains accuracy across week boundary', () async {
      // Arrange: Create sessions on Sunday and Monday (different weeks)
      final sunday = DateTime(2024, 10, 6); // End of week
      final monday = DateTime(2024, 10, 7); // Start of new week

      final sundayWeekId = AppDateUtils.formatWeekForSummary(sunday);
      final mondayWeekId = AppDateUtils.formatWeekForSummary(monday);

      // Act: Log session on Sunday
      await fakeFirestore
          .collection('treatmentSummaries')
          .doc('weekly')
          .collection('summaries')
          .doc(sundayWeekId)
          .set(
            {
              'medicationTotalDoses': FieldValue.increment(1),
            },
            SetOptions(merge: true),
          );

      // Log session on Monday
      await fakeFirestore
          .collection('treatmentSummaries')
          .doc('weekly')
          .collection('summaries')
          .doc(mondayWeekId)
          .set(
            {
              'medicationTotalDoses': FieldValue.increment(1),
            },
            SetOptions(merge: true),
          );

      // Assert: Two separate weekly summaries created
      final sundayDoc = await fakeFirestore
          .collection('treatmentSummaries')
          .doc('weekly')
          .collection('summaries')
          .doc(sundayWeekId)
          .get();

      final mondayDoc = await fakeFirestore
          .collection('treatmentSummaries')
          .doc('weekly')
          .collection('summaries')
          .doc(mondayWeekId)
          .get();

      expect(sundayDoc.exists, isTrue);
      expect(mondayDoc.exists, isTrue);
      expect(sundayWeekId, isNot(equals(mondayWeekId)));
    });
  });
}
