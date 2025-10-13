import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/features/logging/models/medication_session.dart';

import '../../../helpers/test_data_builders.dart';

void main() {
  group('MedicationSession', () {
    group('Factory Constructors', () {
      test('create() generates UUID and sets createdAt', () {
        final session = MedicationSession.create(
          petId: 'pet-123',
          userId: 'user-456',
          dateTime: DateTime(2024, 1, 15, 8),
          medicationName: 'Amlodipine',
          dosageGiven: 1,
          dosageScheduled: 1,
          medicationUnit: 'pills',
          completed: true,
        );

        expect(session.id, isNotEmpty);
        expect(session.id.length, 36); // UUID length
        expect(session.createdAt, isNotNull);
        expect(session.petId, 'pet-123');
        expect(session.userId, 'user-456');
      });

      test('fromSchedule() pre-fills from schedule data', () {
        final schedule = ScheduleBuilder()
            .withMedicationName('Amlodipine')
            .withTargetDosage(2.5)
            .withMedicationUnit('mg')
            .withStrength('2.5', 'mg')
            .build();

        final session = MedicationSession.fromSchedule(
          schedule: schedule,
          scheduledTime: DateTime(2024, 1, 15, 8),
          petId: 'pet-123',
          userId: 'user-456',
        );

        expect(session.medicationName, 'Amlodipine');
        expect(session.dosageScheduled, 2.5);
        expect(session.dosageGiven, 2.5); // Defaults to scheduled
        expect(session.medicationUnit, 'mg');
        expect(session.medicationStrengthAmount, '2.5');
        expect(session.medicationStrengthUnit, 'mg');
        expect(session.scheduleId, schedule.id);
        expect(session.completed, true); // Default
      });

      test('fromSchedule() uses actualDateTime if provided', () {
        final schedule = ScheduleBuilder.medication('Test Med').build();
        final scheduledTime = DateTime(2024, 1, 15, 8);
        final actualTime = DateTime(2024, 1, 15, 8, 30);

        final session = MedicationSession.fromSchedule(
          schedule: schedule,
          scheduledTime: scheduledTime,
          petId: 'pet-123',
          userId: 'user-456',
          actualDateTime: actualTime,
        );

        expect(session.dateTime, actualTime);
        expect(session.scheduledTime, scheduledTime);
      });

      test('fromSchedule() uses actualDosage if provided', () {
        final schedule = ScheduleBuilder()
            .withMedicationName('Test Med')
            .withTargetDosage(2)
            .withMedicationUnit('pills')
            .build();

        final session = MedicationSession.fromSchedule(
          schedule: schedule,
          scheduledTime: DateTime(2024, 1, 15, 8),
          petId: 'pet-123',
          userId: 'user-456',
          actualDosage: 1.5,
        );

        expect(session.dosageGiven, 1.5);
        expect(session.dosageScheduled, 2.0);
      });
    });

    group('Validation', () {
      test('valid session passes validation', () {
        final session = MedicationSessionBuilder().build();

        final result = session.validate();

        expect(result.isEmpty, true);
      });

      test('invalid: dosageGiven < 0', () {
        final session = MedicationSessionBuilder().withDosageGiven(-1).build();

        final result = session.validate();

        expect(result.isNotEmpty, true);
        expect(
          result.any((error) => error.contains('negative')),
          true,
        );
      });

      test('invalid: dosageScheduled <= 0', () {
        final session = MedicationSessionBuilder()
            .withDosageScheduled(-1)
            .build();

        final result = session.validate();

        expect(result.isNotEmpty, true);
        expect(
          result.any((error) => error.contains('greater than 0')),
          true,
        );
      });

      test('invalid: empty medicationName', () {
        final session = MedicationSessionBuilder()
            .withMedicationName('')
            .build();

        final result = session.validate();

        expect(result.isNotEmpty, true);
        expect(
          result.any((error) => error.contains('Medication name')),
          true,
        );
      });

      test('invalid: empty medicationUnit', () {
        final session = MedicationSessionBuilder()
            .withMedicationUnit('')
            .build();

        final result = session.validate();

        expect(result.isNotEmpty, true);
        expect(
          result.any((error) => error.contains('Medication unit')),
          true,
        );
      });

      test('invalid: future dateTime', () {
        final futureDate = DateTime.now().add(const Duration(days: 1));
        final session = MedicationSessionBuilder()
            .withDateTime(futureDate)
            .build();

        final result = session.validate();

        expect(result.isNotEmpty, true);
        expect(
          result.any((error) => error.contains('future')),
          true,
        );
      });
    });

    group('Adherence Helpers', () {
      test('adherencePercentage calculates correctly', () {
        final session = MedicationSessionBuilder()
            .withDosageGiven(0.75)
            .withDosageScheduled(1)
            .build();

        expect(session.adherencePercentage, 75.0);
      });

      test('adherencePercentage returns 0.0 when dosageScheduled is 0', () {
        final session = MedicationSessionBuilder()
            .withDosageGiven(1)
            .withDosageScheduled(0)
            .build();

        expect(session.adherencePercentage, 0.0);
      });

      test('isFullDose returns true when dosageGiven >= dosageScheduled', () {
        final session = MedicationSessionBuilder()
            .withDosageGiven(1)
            .withDosageScheduled(1)
            .build();

        expect(session.isFullDose, true);
      });

      test('isFullDose returns false when dosageGiven < dosageScheduled', () {
        final session = MedicationSessionBuilder()
            .withDosageGiven(0.5)
            .withDosageScheduled(1)
            .build();

        expect(session.isFullDose, false);
      });

      test('isPartialDose returns true for partial dose', () {
        final session = MedicationSessionBuilder()
            .withDosageGiven(0.5)
            .withDosageScheduled(1)
            .build();

        expect(session.isPartialDose, true);
      });

      test('isPartialDose returns false for full dose', () {
        final session = MedicationSessionBuilder()
            .withDosageGiven(1)
            .withDosageScheduled(1)
            .build();

        expect(session.isPartialDose, false);
      });

      test('isPartialDose returns false for missed dose', () {
        final session = MedicationSessionBuilder()
            .withDosageGiven(0)
            .withDosageScheduled(1)
            .build();

        expect(session.isPartialDose, false);
      });

      test('isMissed returns true when dosageGiven is 0', () {
        final session = MedicationSessionBuilder().withDosageGiven(0).build();

        expect(session.isMissed, true);
      });

      test('isMissed returns false when dosageGiven > 0', () {
        final session = MedicationSessionBuilder().withDosageGiven(0.5).build();

        expect(session.isMissed, false);
      });
    });

    group('Sync Helpers', () {
      test('wasModified returns true when updatedAt is not null', () {
        final session = MedicationSessionBuilder()
            .withUpdatedAt(DateTime.now())
            .build();

        expect(session.wasModified, true);
      });

      test('wasModified returns false when updatedAt is null', () {
        final session = MedicationSessionBuilder().build();

        expect(session.wasModified, false);
      });
    });

    group('JSON Serialization', () {
      test('toJson() includes all non-null fields', () {
        final session = MedicationSessionBuilder()
            .withMedicationName('Amlodipine')
            .withDosageGiven(2.5)
            .withNotes('Test notes')
            .withScheduleId('schedule-123')
            .build();

        final json = session.toJson();

        expect(json['id'], session.id);
        expect(json['medicationName'], 'Amlodipine');
        expect(json['dosageGiven'], 2.5);
        expect(json['notes'], 'Test notes');
        expect(json['scheduleId'], 'schedule-123');
      });

      test('toJson() omits null customMedicationStrengthUnit', () {
        final session = MedicationSessionBuilder().build();

        final json = session.toJson();

        expect(json.containsKey('customMedicationStrengthUnit'), false);
      });

      test('fromJson() parses Firestore Timestamp correctly', () {
        final now = DateTime.now();
        final json = {
          'id': 'test-id',
          'petId': 'pet-123',
          'userId': 'user-456',
          'dateTime': Timestamp.fromDate(now),
          'medicationName': 'Amlodipine',
          'dosageGiven': 1.0,
          'dosageScheduled': 1.0,
          'medicationUnit': 'pills',
          'completed': true,
          'createdAt': Timestamp.fromDate(now),
        };

        final session = MedicationSession.fromJson(json);

        expect(session.dateTime.year, now.year);
        expect(session.dateTime.month, now.month);
        expect(session.dateTime.day, now.day);
      });

      test('fromJson() handles null optional fields', () {
        final now = DateTime.now();
        final json = {
          'id': 'test-id',
          'petId': 'pet-123',
          'userId': 'user-456',
          'dateTime': Timestamp.fromDate(now),
          'medicationName': 'Amlodipine',
          'dosageGiven': 1.0,
          'dosageScheduled': 1.0,
          'medicationUnit': 'pills',
          'completed': true,
          'createdAt': Timestamp.fromDate(now),
          // All optional fields omitted
        };

        final session = MedicationSession.fromJson(json);

        expect(session.notes, null);
        expect(session.scheduleId, null);
        expect(session.updatedAt, null);
      });

      test('round-trip: toJson → fromJson preserves data', () {
        final originalSession = MedicationSessionBuilder()
            .withMedicationName('Amlodipine')
            .withDosageGiven(2.5)
            .withDosageScheduled(2.5)
            .withNotes('Test notes')
            .withScheduleId('schedule-123')
            .build();

        final json = originalSession.toJson();
        final restoredSession = MedicationSession.fromJson(json);

        expect(restoredSession.id, originalSession.id);
        expect(restoredSession.medicationName, originalSession.medicationName);
        expect(restoredSession.dosageGiven, originalSession.dosageGiven);
        expect(restoredSession.notes, originalSession.notes);
        expect(restoredSession.scheduleId, originalSession.scheduleId);
      });
    });

    group('copyWith', () {
      test('copies with updated fields', () {
        final session = MedicationSessionBuilder()
            .withMedicationName('Amlodipine')
            .withDosageGiven(1)
            .build();

        final updated = session.copyWith(
          dosageGiven: 2,
          notes: 'Updated notes',
        );

        expect(updated.dosageGiven, 2.0);
        expect(updated.notes, 'Updated notes');
      });

      test('preserves unchanged fields', () {
        final session = MedicationSessionBuilder()
            .withMedicationName('Amlodipine')
            .withDosageGiven(1)
            .withScheduleId('schedule-123')
            .build();

        final updated = session.copyWith(
          dosageGiven: 2,
        );

        expect(updated.medicationName, session.medicationName);
        expect(updated.scheduleId, session.scheduleId);
        expect(updated.id, session.id);
      });

      test('preserves fields when no parameters provided', () {
        final session = MedicationSessionBuilder()
            .withNotes('Original notes')
            .withScheduleId('schedule-123')
            .build();

        final updated = session.copyWith();

        expect(updated.notes, 'Original notes'); // Preserved
        expect(updated.scheduleId, 'schedule-123'); // Preserved
        expect(updated.id, session.id); // Preserved
      });
    });
  });
}
