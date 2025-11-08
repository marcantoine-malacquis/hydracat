import 'package:flutter/foundation.dart';
import 'package:hydracat/features/profile/exceptions/profile_exceptions.dart';
import 'package:hydracat/features/profile/models/schedule.dart';
import 'package:hydracat/features/profile/services/schedule_service.dart';

/// Result returned by schedule operations
class ScheduleOperationResult {
  /// Creates a [ScheduleOperationResult]
  const ScheduleOperationResult({
    required this.success,
    this.schedule,
    this.schedules,
    this.error,
  });

  /// Whether the operation was successful
  final bool success;

  /// Single schedule result (for fluid schedule operations)
  final Schedule? schedule;

  /// List of schedules result (for medication schedule operations)
  final List<Schedule>? schedules;

  /// Error if operation failed
  final ProfileException? error;
}

/// Coordinates schedule operations for ProfileNotifier
///
/// This class handles all fluid and medication schedule CRUD operations,
/// managing the coordination between ScheduleService and business logic.
/// ProfileNotifier delegates to this coordinator for all schedule-related
/// operations, maintaining sole responsibility for state management.
///
/// Design:
/// - Returns structured results, doesn't manage state directly
/// - Accepts state data as parameters (userId, petId)
/// - Calls notification callbacks passed from ProfileNotifier
/// - Maintains same error handling patterns as original ProfileNotifier
class ScheduleCoordinator {
  /// Creates a [ScheduleCoordinator] with required dependencies
  ScheduleCoordinator({
    required ScheduleService scheduleService,
  }) : _scheduleService = scheduleService;

  final ScheduleService _scheduleService;

  // ==========================================================================
  // FLUID SCHEDULE OPERATIONS
  // ==========================================================================

  /// Load fluid schedule for a pet
  ///
  /// Returns [ScheduleOperationResult] with success status, schedule data,
  /// and optional error.
  Future<ScheduleOperationResult> loadFluidSchedule({
    required String userId,
    required String petId,
  }) async {
    try {
      final schedule = await _scheduleService.getFluidSchedule(
        userId: userId,
        petId: petId,
      );

      return ScheduleOperationResult(
        success: schedule != null,
        schedule: schedule,
      );
    } on FormatException catch (e) {
      if (kDebugMode) {
        debugPrint('[ScheduleCoordinator] Schedule serialization error: $e');
      }
      return const ScheduleOperationResult(
        success: false,
        error: PetServiceException(
          'Schedule data format error. '
          'Please contact support if this persists.',
        ),
      );
    } on Exception catch (e) {
      if (kDebugMode) {
        debugPrint('[ScheduleCoordinator] Error loading fluid schedule: $e');
      }
      return ScheduleOperationResult(
        success: false,
        error: PetServiceException('Failed to load fluid schedule: $e'),
      );
    }
  }

  /// Refresh fluid schedule for a pet (force reload from Firestore)
  ///
  /// Returns [ScheduleOperationResult] with success status, schedule data,
  /// and optional error.
  Future<ScheduleOperationResult> refreshFluidSchedule({
    required String userId,
    required String petId,
  }) async {
    try {
      final schedule = await _scheduleService.getFluidSchedule(
        userId: userId,
        petId: petId,
      );

      return ScheduleOperationResult(
        success: schedule != null,
        schedule: schedule,
      );
    } on FormatException catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[ScheduleCoordinator] Schedule serialization error on refresh: $e',
        );
      }
      return const ScheduleOperationResult(
        success: false,
        error: PetServiceException(
          'Schedule data format error. '
          'Please contact support if this persists.',
        ),
      );
    } on Exception catch (e) {
      if (kDebugMode) {
        debugPrint('[ScheduleCoordinator] Error refreshing fluid schedule: $e');
      }
      return ScheduleOperationResult(
        success: false,
        error: PetServiceException('Failed to refresh fluid schedule: $e'),
      );
    }
  }

  /// Create a new fluid schedule
  ///
  /// [onSuccess] callback is called after successful creation with the new
  /// schedule (includes assigned ID). Use this for notification scheduling.
  ///
  /// Returns [ScheduleOperationResult] with success status, created schedule,
  /// and optional error.
  Future<ScheduleOperationResult> createFluidSchedule({
    required String userId,
    required String petId,
    required Schedule schedule,
    Future<void> Function(Schedule)? onSuccess,
  }) async {
    try {
      final scheduleId = await _scheduleService.createSchedule(
        userId: userId,
        petId: petId,
        scheduleDto: schedule.toDto(),
      );

      // Create the new schedule with the assigned ID
      final newSchedule = schedule.copyWith(id: scheduleId);

      // Call success callback for notification scheduling
      if (onSuccess != null) {
        await onSuccess(newSchedule);
      }

      return ScheduleOperationResult(
        success: true,
        schedule: newSchedule,
      );
    } on Exception catch (e) {
      if (kDebugMode) {
        debugPrint('[ScheduleCoordinator] Error creating fluid schedule: $e');
      }
      return ScheduleOperationResult(
        success: false,
        error: PetServiceException('Failed to create fluid schedule: $e'),
      );
    }
  }

  /// Update an existing fluid schedule
  ///
  /// [oldSchedule] is used to check if schedule was deactivated for
  /// notification cancellation.
  ///
  /// [onDeactivated] callback is called if schedule was deactivated.
  /// [onActiveUpdate] callback is called if schedule is/stays active.
  ///
  /// Returns [ScheduleOperationResult] with success status and optional error.
  Future<ScheduleOperationResult> updateFluidSchedule({
    required String userId,
    required String petId,
    required Schedule schedule,
    Schedule? oldSchedule,
    Future<void> Function(Schedule)? onDeactivated,
    Future<void> Function(Schedule)? onActiveUpdate,
  }) async {
    try {
      await _scheduleService.updateSchedule(
        userId: userId,
        petId: petId,
        scheduleId: schedule.id,
        updates: schedule.toJson(),
      );

      // Handle notification callbacks
      if (oldSchedule != null && oldSchedule.isActive && !schedule.isActive) {
        // Schedule was deactivated - cancel notifications
        if (onDeactivated != null) {
          await onDeactivated(schedule);
        }
      } else if (schedule.isActive) {
        // Schedule is active (either stayed active or was activated)
        if (onActiveUpdate != null) {
          await onActiveUpdate(schedule);
        }
      }

      return const ScheduleOperationResult(success: true);
    } on Exception catch (e) {
      if (kDebugMode) {
        debugPrint('[ScheduleCoordinator] Error updating fluid schedule: $e');
      }
      return ScheduleOperationResult(
        success: false,
        error: PetServiceException('Failed to update fluid schedule: $e'),
      );
    }
  }

  // ==========================================================================
  // MEDICATION SCHEDULE OPERATIONS
  // ==========================================================================

  /// Load medication schedules for a pet
  ///
  /// Returns [ScheduleOperationResult] with success status, schedules list,
  /// and optional error.
  Future<ScheduleOperationResult> loadMedicationSchedules({
    required String userId,
    required String petId,
  }) async {
    try {
      final schedules = await _scheduleService.getMedicationSchedules(
        userId: userId,
        petId: petId,
      );

      return ScheduleOperationResult(
        success: schedules.isNotEmpty,
        schedules: schedules,
      );
    } on FormatException catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[ScheduleCoordinator] Medication schedule serialization error: $e',
        );
      }
      return const ScheduleOperationResult(
        success: false,
        error: PetServiceException(
          'Medication schedule data format error. '
          'Please contact support if this persists.',
        ),
      );
    } on Exception catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[ScheduleCoordinator] Error loading medication schedules: $e',
        );
      }
      return ScheduleOperationResult(
        success: false,
        error: PetServiceException('Failed to load medication schedules: $e'),
      );
    }
  }

  /// Refresh medication schedules for a pet (force reload from Firestore)
  ///
  /// Returns [ScheduleOperationResult] with success status, schedules list,
  /// and optional error.
  Future<ScheduleOperationResult> refreshMedicationSchedules({
    required String userId,
    required String petId,
  }) async {
    try {
      final schedules = await _scheduleService.getMedicationSchedules(
        userId: userId,
        petId: petId,
      );

      return ScheduleOperationResult(
        success: schedules.isNotEmpty,
        schedules: schedules,
      );
    } on FormatException catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[ScheduleCoordinator] Medication schedule serialization error '
          'on refresh: $e',
        );
      }
      return const ScheduleOperationResult(
        success: false,
        error: PetServiceException(
          'Medication schedule data format error. '
          'Please contact support if this persists.',
        ),
      );
    } on Exception catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[ScheduleCoordinator] Error refreshing medication schedules: $e',
        );
      }
      return ScheduleOperationResult(
        success: false,
        error: PetServiceException(
          'Failed to refresh medication schedules: $e',
        ),
      );
    }
  }

  /// Add a new medication schedule
  ///
  /// [onSuccess] callback is called after successful creation with the new
  /// schedule (includes assigned ID). Use this for notification scheduling.
  ///
  /// Returns [ScheduleOperationResult] with success status, created schedule,
  /// and optional error.
  Future<ScheduleOperationResult> addMedicationSchedule({
    required String userId,
    required String petId,
    required Schedule schedule,
    Future<void> Function(Schedule)? onSuccess,
  }) async {
    try {
      final scheduleId = await _scheduleService.createSchedule(
        userId: userId,
        petId: petId,
        scheduleDto: schedule.toDto(),
      );

      // Create the new schedule with the assigned ID
      final newSchedule = schedule.copyWith(id: scheduleId);

      // Call success callback for notification scheduling
      if (onSuccess != null) {
        await onSuccess(newSchedule);
      }

      return ScheduleOperationResult(
        success: true,
        schedule: newSchedule,
      );
    } on Exception catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[ScheduleCoordinator] Error adding medication schedule: $e',
        );
      }
      return ScheduleOperationResult(
        success: false,
        error: PetServiceException('Failed to add medication schedule: $e'),
      );
    }
  }

  /// Update an existing medication schedule
  ///
  /// [currentSchedules] is the list of all medication schedules before update.
  /// Used to find the old schedule for deactivation checking.
  ///
  /// [onDeactivated] callback is called if schedule was deactivated.
  /// [onActiveUpdate] callback is called if schedule is/stays active.
  ///
  /// Returns [ScheduleOperationResult] with success status and optional error.
  Future<ScheduleOperationResult> updateMedicationSchedule({
    required String userId,
    required String petId,
    required Schedule schedule,
    required List<Schedule> currentSchedules,
    Future<void> Function(Schedule)? onDeactivated,
    Future<void> Function(Schedule)? onActiveUpdate,
  }) async {
    try {
      // Find old schedule to check if isActive changed
      final oldSchedule = currentSchedules
          .where((s) => s.id == schedule.id)
          .firstOrNull;

      await _scheduleService.updateSchedule(
        userId: userId,
        petId: petId,
        scheduleId: schedule.id,
        updates: schedule.toJson(),
      );

      // Handle notification callbacks
      if (oldSchedule != null && oldSchedule.isActive && !schedule.isActive) {
        // Schedule was deactivated - cancel notifications
        if (onDeactivated != null) {
          await onDeactivated(schedule);
        }
      } else if (schedule.isActive) {
        // Schedule is active (either stayed active or was activated)
        if (onActiveUpdate != null) {
          await onActiveUpdate(schedule);
        }
      }

      return const ScheduleOperationResult(success: true);
    } on Exception catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[ScheduleCoordinator] Error updating medication schedule: $e',
        );
      }
      return ScheduleOperationResult(
        success: false,
        error: PetServiceException('Failed to update medication schedule: $e'),
      );
    }
  }

  /// Delete a medication schedule
  ///
  /// [onSuccess] callback is called after successful deletion with the deleted
  /// schedule data. Use this for notification cancellation.
  ///
  /// Returns [ScheduleOperationResult] with success status and optional error.
  Future<ScheduleOperationResult> deleteMedicationSchedule({
    required String userId,
    required String petId,
    required String scheduleId,
    Schedule? scheduleToDelete,
    Future<void> Function(String scheduleId, Schedule? schedule)? onSuccess,
  }) async {
    try {
      await _scheduleService.deleteSchedule(
        userId: userId,
        petId: petId,
        scheduleId: scheduleId,
      );

      // Call success callback for notification cancellation
      if (onSuccess != null) {
        await onSuccess(scheduleId, scheduleToDelete);
      }

      return const ScheduleOperationResult(success: true);
    } on Exception catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[ScheduleCoordinator] Error deleting medication schedule: $e',
        );
      }
      return ScheduleOperationResult(
        success: false,
        error: PetServiceException('Failed to delete medication schedule: $e'),
      );
    }
  }

  // ==========================================================================
  // PROACTIVE SCHEDULE LOADING
  // ==========================================================================

  /// Load all schedules (fluid + medication) concurrently
  ///
  /// This method is used for proactive loading on app startup/resume.
  /// Returns both fluid schedule and medication schedules list.
  ///
  /// Returns [ScheduleOperationResult] with success status, schedule data,
  /// schedules list, and optional error.
  Future<ScheduleOperationResult> loadAllSchedules({
    required String userId,
    required String petId,
  }) async {
    try {
      // Load both schedules concurrently
      final results = await Future.wait([
        _scheduleService.getFluidSchedule(
          userId: userId,
          petId: petId,
        ),
        _scheduleService.getMedicationSchedules(
          userId: userId,
          petId: petId,
        ),
      ]);

      final fluidSchedule = results[0] as Schedule?;
      final medicationSchedules = results[1] as List<Schedule>? ?? [];

      if (kDebugMode) {
        debugPrint(
          '[ScheduleCoordinator] Loaded all schedules: '
          '${medicationSchedules.length} medications, '
          'fluid: ${fluidSchedule != null}',
        );
      }

      return ScheduleOperationResult(
        success: true,
        schedule: fluidSchedule,
        schedules: medicationSchedules,
      );
    } on Exception catch (e) {
      if (kDebugMode) {
        debugPrint('[ScheduleCoordinator] Failed to load all schedules: $e');
      }
      return ScheduleOperationResult(
        success: false,
        error: PetServiceException('Failed to load schedules: $e'),
      );
    }
  }
}
