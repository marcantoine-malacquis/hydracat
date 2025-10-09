import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/features/logging/models/fluid_session.dart';
import 'package:hydracat/features/onboarding/models/treatment_data.dart';

import '../../../helpers/test_data_builders.dart';

void main() {
  group('FluidSession', () {
    group('Factory Constructors', () {
      test('create() generates UUID and sets createdAt', () {
        final session = FluidSession.create(
          petId: 'pet-123',
          userId: 'user-456',
          dateTime: DateTime(2024, 1, 15, 8),
          volumeGiven: 100,
        );

        expect(session.id, isNotEmpty);
        expect(session.id.length, 36); // UUID length
        expect(session.createdAt, isNotNull);
        expect(session.petId, 'pet-123');
        expect(session.userId, 'user-456');
        expect(session.volumeGiven, 100.0);
      });

      test('fromSchedule() pre-fills volume from targetVolume', () {
        final schedule = ScheduleBuilder.fluid()
            .withTargetVolume(150)
            .withPreferredLocation(FluidLocation.shoulderBladeRight)
            .build();

        final session = FluidSession.fromSchedule(
          schedule: schedule,
          scheduledTime: DateTime(2024, 1, 15, 8),
          petId: 'pet-123',
          userId: 'user-456',
        );

        expect(session.volumeGiven, 150.0);
        expect(session.injectionSite, FluidLocation.shoulderBladeRight);
        expect(session.scheduleId, schedule.id);
      });

      test('fromSchedule() uses preferredLocation for injectionSite', () {
        final schedule = ScheduleBuilder.fluid()
            .withPreferredLocation(FluidLocation.shoulderBladeLeft)
            .build();

        final session = FluidSession.fromSchedule(
          schedule: schedule,
          scheduledTime: DateTime(2024, 1, 15, 8),
          petId: 'pet-123',
          userId: 'user-456',
        );

        expect(session.injectionSite, FluidLocation.shoulderBladeLeft);
      });

      test('fromSchedule() uses actualDateTime if provided', () {
        final schedule = ScheduleBuilder.fluid().build();
        final scheduledTime = DateTime(2024, 1, 15, 8);
        final actualTime = DateTime(2024, 1, 15, 8, 30);

        final session = FluidSession.fromSchedule(
          schedule: schedule,
          scheduledTime: scheduledTime,
          petId: 'pet-123',
          userId: 'user-456',
          actualDateTime: actualTime,
        );

        expect(session.dateTime, actualTime);
        expect(session.scheduledTime, scheduledTime);
      });

      test('fromSchedule() uses actualVolume if provided', () {
        final schedule = ScheduleBuilder.fluid().withTargetVolume(100).build();

        final session = FluidSession.fromSchedule(
          schedule: schedule,
          scheduledTime: DateTime(2024, 1, 15, 8),
          petId: 'pet-123',
          userId: 'user-456',
          actualVolume: 120,
        );

        expect(session.volumeGiven, 120.0);
      });
    });

    group('Validation', () {
      test('valid session passes validation', () {
        final session = FluidSessionBuilder().build();

        final result = session.validate();

        expect(result.isEmpty, true);
      });

      test('invalid: volumeGiven < 1ml', () {
        final session = FluidSessionBuilder().withVolumeGiven(0.5).build();

        final result = session.validate();

        expect(result.isNotEmpty, true);
        expect(
          result.any((error) => error.contains('at least 1ml')),
          true,
        );
      });

      test('invalid: volumeGiven > 500ml', () {
        final session = FluidSessionBuilder().withVolumeGiven(501).build();

        final result = session.validate();

        expect(result.isNotEmpty, true);
        expect(
          result.any((error) => error.contains('500ml or less')),
          true,
        );
      });

      test('invalid: invalid stressLevel value', () {
        final session = FluidSessionBuilder()
            .withStressLevel('very_high') // Not valid
            .build();

        final result = session.validate();

        expect(result.isNotEmpty, true);
        expect(
          result.any((error) => error.contains('Stress level')),
          true,
        );
      });

      test('valid: stressLevel is "low"', () {
        final session = FluidSessionBuilder().withStressLevel('low').build();

        final result = session.validate();

        expect(result.isEmpty, true);
      });

      test('valid: stressLevel is "medium"', () {
        final session = FluidSessionBuilder().withStressLevel('medium').build();

        final result = session.validate();

        expect(result.isEmpty, true);
      });

      test('valid: stressLevel is "high"', () {
        final session = FluidSessionBuilder().withStressLevel('high').build();

        final result = session.validate();

        expect(result.isEmpty, true);
      });

      test('valid: stressLevel is null', () {
        final session = FluidSessionBuilder().withStressLevel(null).build();

        final result = session.validate();

        expect(result.isEmpty, true);
      });

      test('invalid: future dateTime', () {
        final futureDate = DateTime.now().add(const Duration(days: 1));
        final session = FluidSessionBuilder().withDateTime(futureDate).build();

        final result = session.validate();

        expect(result.isNotEmpty, true);
        expect(
          result.any((error) => error.contains('future')),
          true,
        );
      });
    });

    group('Sync Helpers', () {
      test('isSynced returns true when syncedAt is not null', () {
        final session = FluidSessionBuilder()
            .withSyncedAt(DateTime.now())
            .build();

        expect(session.isSynced, true);
      });

      test('isSynced returns false when syncedAt is null', () {
        final session = FluidSessionBuilder().build();

        expect(session.isSynced, false);
      });

      test('wasModified returns true when updatedAt is not null', () {
        final session = FluidSessionBuilder()
            .withUpdatedAt(DateTime.now())
            .build();

        expect(session.wasModified, true);
      });

      test('wasModified returns false when updatedAt is null', () {
        final session = FluidSessionBuilder().build();

        expect(session.wasModified, false);
      });

      test('isPendingSync returns true when not synced', () {
        final session = FluidSessionBuilder().withSyncedAt(null).build();

        expect(session.isPendingSync, true);
      });

      test('isPendingSync returns false when synced', () {
        final session = FluidSessionBuilder()
            .withSyncedAt(DateTime.now())
            .build();

        expect(session.isPendingSync, false);
      });
    });

    group('JSON Serialization', () {
      test('FluidLocation enum converts to string correctly', () {
        final session = FluidSessionBuilder()
            .withInjectionSite(FluidLocation.shoulderBladeLeft)
            .build();

        final json = session.toJson();

        expect(json['injectionSite'], 'shoulderBladeLeft');
      });

      test('toJson() handles null injectionSite', () {
        final session = FluidSessionBuilder().withInjectionSite(null).build();

        final json = session.toJson();

        expect(json['injectionSite'], null);
      });

      test('fromJson() converts string to FluidLocation enum', () {
        final now = DateTime.now();
        final json = {
          'id': 'test-id',
          'petId': 'pet-123',
          'userId': 'user-456',
          'dateTime': Timestamp.fromDate(now),
          'volumeGiven': 100.0,
          'injectionSite': 'shoulderBladeLeft',
          'createdAt': Timestamp.fromDate(now),
        };

        final session = FluidSession.fromJson(json);

        expect(session.injectionSite, FluidLocation.shoulderBladeLeft);
      });

      test('round-trip preserves enum values', () {
        final originalSession = FluidSessionBuilder()
            .withVolumeGiven(150)
            .withInjectionSite(FluidLocation.hipBonesLeft)
            .withStressLevel('medium')
            .withNotes('Test notes')
            .build();

        final json = originalSession.toJson();
        final restoredSession = FluidSession.fromJson(json);

        expect(restoredSession.id, originalSession.id);
        expect(restoredSession.volumeGiven, originalSession.volumeGiven);
        expect(restoredSession.injectionSite, originalSession.injectionSite);
        expect(restoredSession.stressLevel, originalSession.stressLevel);
        expect(restoredSession.notes, originalSession.notes);
      });

      test('fromJson() parses Firestore Timestamp correctly', () {
        final now = DateTime.now();
        final json = {
          'id': 'test-id',
          'petId': 'pet-123',
          'userId': 'user-456',
          'dateTime': Timestamp.fromDate(now),
          'volumeGiven': 100.0,
          'createdAt': Timestamp.fromDate(now),
        };

        final session = FluidSession.fromJson(json);

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
          'volumeGiven': 100.0,
          'createdAt': Timestamp.fromDate(now),
          // All optional fields omitted
        };

        final session = FluidSession.fromJson(json);

        expect(session.injectionSite, null);
        expect(session.stressLevel, null);
        expect(session.notes, null);
        expect(session.scheduleId, null);
        expect(session.syncedAt, null);
        expect(session.updatedAt, null);
      });
    });

    group('copyWith', () {
      test('updates fields correctly', () {
        final session = FluidSessionBuilder()
            .withVolumeGiven(100)
            .withStressLevel('low')
            .build();

        final updated = session.copyWith(
          volumeGiven: 150,
          stressLevel: 'high',
          notes: 'Updated notes',
        );

        expect(updated.volumeGiven, 150.0);
        expect(updated.stressLevel, 'high');
        expect(updated.notes, 'Updated notes');
      });

      test('preserves unchanged fields', () {
        final session = FluidSessionBuilder()
            .withVolumeGiven(100)
            .withInjectionSite(FluidLocation.hipBonesRight)
            .withScheduleId('schedule-123')
            .build();

        final updated = session.copyWith(
          volumeGiven: 150,
        );

        expect(updated.injectionSite, session.injectionSite);
        expect(updated.scheduleId, session.scheduleId);
        expect(updated.id, session.id);
      });

      test('preserves fields when no parameters provided', () {
        final session = FluidSessionBuilder()
            .withNotes('Original notes')
            .withStressLevel('low')
            .build();

        final updated = session.copyWith();

        expect(updated.notes, 'Original notes'); // Preserved
        expect(updated.stressLevel, 'low'); // Preserved
        expect(updated.id, session.id); // Preserved
      });
    });
  });
}
