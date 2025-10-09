import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/shared/models/summary_update_dto.dart';

import '../../../helpers/test_data_builders.dart';

void main() {
  group('SummaryUpdateDto', () {
    group('fromMedicationSession (New Sessions)', () {
      test('completed session creates correct increments', () {
        final session = MedicationSessionBuilder.completed().build();

        final dto = SummaryUpdateDto.fromMedicationSession(session);

        expect(dto.medicationDosesDelta, 1);
        expect(dto.medicationScheduledDelta, 1);
        expect(dto.medicationMissedDelta, 0);
        expect(dto.hasUpdates, true);
      });

      test('missed session creates correct increments', () {
        final session = MedicationSessionBuilder.missed().build();

        final dto = SummaryUpdateDto.fromMedicationSession(session);

        expect(dto.medicationDosesDelta, 0);
        expect(dto.medicationScheduledDelta, 1);
        expect(dto.medicationMissedDelta, 1);
        expect(dto.hasUpdates, true);
      });

      test('partial dose session creates correct increments', () {
        final session = MedicationSessionBuilder.partial().build();

        final dto = SummaryUpdateDto.fromMedicationSession(session);

        // Completion flag matters, not dosage amount
        expect(dto.medicationDosesDelta, 1);
        expect(dto.medicationScheduledDelta, 1);
        expect(dto.medicationMissedDelta, 0);
        expect(dto.hasUpdates, true);
      });

      test('marks as update when isUpdate is true', () {
        final session = MedicationSessionBuilder.completed().build();

        final dto = SummaryUpdateDto.fromMedicationSession(
          session,
          isUpdate: true,
        );

        // Updates don't increment scheduled count
        expect(dto.medicationDosesDelta, 1);
        expect(dto.medicationScheduledDelta, 0);
        expect(dto.medicationMissedDelta, 0);
      });
    });

    group('forMedicationSessionUpdate (Deltas)', () {
      test('calculates positive delta for missed to completed', () {
        final oldSession = MedicationSessionBuilder.missed().build();
        final newSession = oldSession.copyWith(
          completed: true,
          dosageGiven: 1,
        );

        final dto = SummaryUpdateDto.forMedicationSessionUpdate(
          oldSession: oldSession,
          newSession: newSession,
        );

        expect(dto.medicationDosesDelta, 1);
        expect(dto.medicationMissedDelta, -1);
        expect(dto.medicationScheduledDelta, null); // Null for updates
        expect(dto.hasUpdates, true);
      });

      test('calculates negative delta for completed to missed', () {
        final oldSession = MedicationSessionBuilder.completed().build();
        final newSession = oldSession.copyWith(
          completed: false,
          dosageGiven: 0,
        );

        final dto = SummaryUpdateDto.forMedicationSessionUpdate(
          oldSession: oldSession,
          newSession: newSession,
        );

        expect(dto.medicationDosesDelta, -1);
        expect(dto.medicationMissedDelta, 1);
        expect(dto.medicationScheduledDelta, null); // Null for updates
        expect(dto.hasUpdates, true);
      });

      test('calculates dosage delta when amount changes', () {
        final oldSession = MedicationSessionBuilder()
            .asCompleted(completed: true)
            .withDosageGiven(1)
            .build();
        final newSession = oldSession.copyWith(dosageGiven: 2);

        final dto = SummaryUpdateDto.forMedicationSessionUpdate(
          oldSession: oldSession,
          newSession: newSession,
        );

        expect(dto.medicationDosesDelta, null); // No completion change
        expect(dto.hasUpdates, false);
      });

      test('returns no updates when nothing changed', () {
        final oldSession = MedicationSessionBuilder.completed().build();
        final newSession = oldSession.copyWith(
          notes: 'New notes',
        );

        final dto = SummaryUpdateDto.forMedicationSessionUpdate(
          oldSession: oldSession,
          newSession: newSession,
        );

        expect(dto.medicationDosesDelta, null); // Null when no change
        expect(dto.medicationMissedDelta, null); // Null when no change
        expect(dto.medicationScheduledDelta, null); // Null for updates
        expect(dto.hasUpdates, false);
      });
    });

    group('fromFluidSession (New Sessions)', () {
      test('creates correct increments for new session', () {
        final session = FluidSessionBuilder().withVolumeGiven(150).build();

        final dto = SummaryUpdateDto.fromFluidSession(session);

        expect(dto.fluidVolumeDelta, 150.0);
        expect(dto.fluidSessionDelta, 1);
        expect(dto.fluidTreatmentDone, true);
        expect(dto.hasUpdates, true);
      });

      test('marks as update when isUpdate is true', () {
        final session = FluidSessionBuilder().withVolumeGiven(100).build();

        final dto = SummaryUpdateDto.fromFluidSession(
          session,
          isUpdate: true,
        );

        // Updates don't increment session count
        expect(dto.fluidVolumeDelta, 100.0);
        expect(dto.fluidSessionDelta, 0);
        expect(dto.fluidTreatmentDone, true);
      });
    });

    group('forFluidSessionUpdate (Deltas)', () {
      test('calculates positive volume delta', () {
        final oldSession = FluidSessionBuilder().withVolumeGiven(100).build();
        final newSession = oldSession.copyWith(volumeGiven: 150);

        final dto = SummaryUpdateDto.forFluidSessionUpdate(
          oldSession: oldSession,
          newSession: newSession,
        );

        expect(dto.fluidVolumeDelta, 50.0);
        expect(dto.fluidSessionDelta, null); // Null for updates
        expect(dto.hasUpdates, true);
      });

      test('calculates negative volume delta', () {
        final oldSession = FluidSessionBuilder().withVolumeGiven(150).build();
        final newSession = oldSession.copyWith(volumeGiven: 100);

        final dto = SummaryUpdateDto.forFluidSessionUpdate(
          oldSession: oldSession,
          newSession: newSession,
        );

        expect(dto.fluidVolumeDelta, -50.0);
        expect(dto.fluidSessionDelta, null); // Null for updates
        expect(dto.hasUpdates, true);
      });

      test('returns no updates when volume unchanged', () {
        final oldSession = FluidSessionBuilder().withVolumeGiven(100).build();
        final newSession = oldSession.copyWith(
          notes: 'New notes',
          stressLevel: 'low',
        );

        final dto = SummaryUpdateDto.forFluidSessionUpdate(
          oldSession: oldSession,
          newSession: newSession,
        );

        expect(dto.fluidVolumeDelta, null); // Null when no change
        expect(dto.fluidSessionDelta, null); // Null for updates
        expect(dto.hasUpdates, false);
      });
    });

    group('toFirestoreUpdate()', () {
      test('returns map with FieldValue.increment() for deltas', () {
        final session = MedicationSessionBuilder.completed().build();
        final dto = SummaryUpdateDto.fromMedicationSession(session);

        final firestoreMap = dto.toFirestoreUpdate();

        expect(firestoreMap['medicationTotalDoses'], isA<FieldValue>());
        expect(firestoreMap['medicationScheduledDoses'], isA<FieldValue>());
        expect(firestoreMap.containsKey('updatedAt'), true);
      });

      test('omits null fields', () {
        const dto = SummaryUpdateDto(
          medicationDosesDelta: 1,
          // All other fields null
        );

        final firestoreMap = dto.toFirestoreUpdate();

        expect(firestoreMap.containsKey('medicationTotalDoses'), true);
        expect(firestoreMap.containsKey('fluidTotalVolume'), false);
        expect(firestoreMap.containsKey('fluidSessionCount'), false);
      });

      test('includes timestamp fields', () {
        const dto = SummaryUpdateDto(
          medicationDosesDelta: 1,
        );

        final firestoreMap = dto.toFirestoreUpdate();

        expect(firestoreMap.containsKey('updatedAt'), true);
        expect(firestoreMap['updatedAt'], isA<FieldValue>());
      });

      test('returns empty map when hasUpdates is false', () {
        const dto = SummaryUpdateDto(
          // All deltas are 0 or null
        );

        final firestoreMap = dto.toFirestoreUpdate();

        // Should only have timestamp
        expect(firestoreMap.length, 1);
        expect(firestoreMap.containsKey('updatedAt'), true);
      });
    });
  });
}
