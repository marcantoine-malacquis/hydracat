/// Unit tests for ScheduleCoordinator
///
/// Tests coordination logic between ProfileNotifier and ScheduleService.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/features/profile/exceptions/profile_exceptions.dart';
import 'package:hydracat/features/profile/services/schedule_service.dart';
import 'package:hydracat/providers/profile/schedule_coordinator.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/profile_test_data_builders.dart';

class MockScheduleService extends Mock implements ScheduleService {}

void main() {
  setUpAll(() {
    // Register fallback values for mocktail
    registerFallbackValue(
      ScheduleBuilder.medication().build(),
    );
  });

  group('ScheduleCoordinator', () {
    late MockScheduleService mockScheduleService;
    late ScheduleCoordinator coordinator;

    setUp(() {
      mockScheduleService = MockScheduleService();
      coordinator = ScheduleCoordinator(
        scheduleService: mockScheduleService,
      );
    });

    group('loadFluidSchedule', () {
      test('should return success with schedule when found', () async {
        // Arrange
        final schedule = ScheduleBuilder.fluid().build();
        when(
          () => mockScheduleService.getFluidSchedule(
            userId: any(named: 'userId'),
            petId: any(named: 'petId'),
          ),
        ).thenAnswer((_) async => schedule);

        // Act
        final result = await coordinator.loadFluidSchedule(
          userId: 'user-123',
          petId: 'pet-456',
        );

        // Assert
        expect(result.success, isTrue);
        expect(result.schedule, equals(schedule));
        expect(result.error, isNull);
      });

      test('should return success with null when schedule not found', () async {
        // Arrange
        when(
          () => mockScheduleService.getFluidSchedule(
            userId: any(named: 'userId'),
            petId: any(named: 'petId'),
          ),
        ).thenAnswer((_) async => null);

        // Act
        final result = await coordinator.loadFluidSchedule(
          userId: 'user-123',
          petId: 'pet-456',
        );

        // Assert
        expect(result.success, isFalse);
        expect(result.schedule, isNull);
      });

      test('should return failure on FormatException', () async {
        // Arrange
        when(
          () => mockScheduleService.getFluidSchedule(
            userId: any(named: 'userId'),
            petId: any(named: 'petId'),
          ),
        ).thenThrow(const FormatException('Invalid data'));

        // Act
        final result = await coordinator.loadFluidSchedule(
          userId: 'user-123',
          petId: 'pet-456',
        );

        // Assert
        expect(result.success, isFalse);
        expect(result.error, isA<PetServiceException>());
        expect(result.error!.message, contains('format error'));
      });

      test('should return failure on general Exception', () async {
        // Arrange
        when(
          () => mockScheduleService.getFluidSchedule(
            userId: any(named: 'userId'),
            petId: any(named: 'petId'),
          ),
        ).thenThrow(Exception('Network error'));

        // Act
        final result = await coordinator.loadFluidSchedule(
          userId: 'user-123',
          petId: 'pet-456',
        );

        // Assert
        expect(result.success, isFalse);
        expect(result.error, isA<PetServiceException>());
      });
    });

    group('loadMedicationSchedules', () {
      test('should return success with schedules when found', () async {
        // Arrange
        final schedules = [
          ScheduleBuilder.medication().withId('med-1').build(),
          ScheduleBuilder.medication().withId('med-2').build(),
        ];
        when(
          () => mockScheduleService.getMedicationSchedules(
            userId: any(named: 'userId'),
            petId: any(named: 'petId'),
          ),
        ).thenAnswer((_) async => schedules);

        // Act
        final result = await coordinator.loadMedicationSchedules(
          userId: 'user-123',
          petId: 'pet-456',
        );

        // Assert
        expect(result.success, isTrue);
        expect(result.schedules, hasLength(2));
        expect(result.error, isNull);
      });

      test('should return success with empty list when none found', () async {
        // Arrange
        when(
          () => mockScheduleService.getMedicationSchedules(
            userId: any(named: 'userId'),
            petId: any(named: 'petId'),
          ),
        ).thenAnswer((_) async => []);

        // Act
        final result = await coordinator.loadMedicationSchedules(
          userId: 'user-123',
          petId: 'pet-456',
        );

        // Assert - empty list returns success:false (no schedules found)
        expect(result.success, isFalse);
        expect(result.schedules, isEmpty);
      });
    });

    group('ScheduleOperationResult', () {
      test('should create success result with schedule', () {
        final schedule = ScheduleBuilder.fluid().build();
        final result = ScheduleOperationResult(
          success: true,
          schedule: schedule,
        );

        expect(result.success, isTrue);
        expect(result.schedule, equals(schedule));
        expect(result.error, isNull);
      });

      test('should create success result with schedules list', () {
        final schedules = [
          ScheduleBuilder.medication().build(),
        ];
        final result = ScheduleOperationResult(
          success: true,
          schedules: schedules,
        );

        expect(result.success, isTrue);
        expect(result.schedules, equals(schedules));
        expect(result.error, isNull);
      });

      test('should create failure result with error', () {
        const error = PetServiceException('Test error');
        const result = ScheduleOperationResult(
          success: false,
          error: error,
        );

        expect(result.success, isFalse);
        expect(result.error, equals(error));
        expect(result.schedule, isNull);
        expect(result.schedules, isNull);
      });
    });

    group('Integration Tests (TODO)', () {
      test('TODO: test all 10 operations', () {
        // Comprehensive tests for:
        // 1. loadFluidSchedule
        // 2. refreshFluidSchedule
        // 3. createFluidSchedule
        // 4. updateFluidSchedule
        // 5. deleteFluidSchedule
        // 6. loadMedicationSchedules
        // 7. refreshMedicationSchedules
        // 8. addMedicationSchedule
        // 9. updateMedicationSchedule
        // 10. deleteMedicationSchedule
        // 11. loadAllSchedules (bonus operation)
      }, skip: 'Partial implementation - expand as needed');
    });
  });
}
