import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/features/notifications/providers/notification_provider.dart';
import 'package:hydracat/features/notifications/services/notification_error_handler.dart';
import 'package:hydracat/features/profile/models/schedule.dart';
import 'package:hydracat/providers/analytics_provider.dart';

/// Handles notification scheduling and cancellation for schedule operations
///
/// This handler is responsible for:
/// - Scheduling notifications when schedules are created or updated
/// - Canceling notifications when schedules are deleted or deactivated
/// - Tracking analytics for notification operations
/// - Handling errors silently without blocking schedule operations
///
/// Note: Uses Ref-to-WidgetRef cast which is safe because ReminderService
/// only uses ref.read() which is available on both types.
class ScheduleNotificationHandler {
  /// Creates a [ScheduleNotificationHandler] with required dependencies
  ScheduleNotificationHandler(this._ref);

  final Ref _ref;

  /// Schedule notifications for a schedule (silent, non-blocking)
  ///
  /// Called after successful schedule create/update operations.
  /// Failures are logged to analytics but do not block the schedule
  /// operation.
  ///
  /// Algorithm:
  /// 1. Validate prerequisites (userId, petId)
  /// 2. Get ReminderService from ref
  /// 3. Call reminderService.scheduleForSchedule() with ref cast
  /// 4. Track analytics for success or failure
  /// 5. Catch all exceptions and log silently
  /// 6. Never throw/rethrow
  ///
  /// Parameters:
  /// - [userId]: The user ID
  /// - [petId]: The pet ID
  /// - [schedule]: The schedule to schedule notifications for
  /// - [operationType]: 'create' or 'update' for analytics tracking
  ///
  /// Returns: void (all errors logged silently)
  Future<void> scheduleForSchedule({
    required String userId,
    required String petId,
    required Schedule schedule,
    required String operationType,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint(
          '[ScheduleNotificationHandler] Scheduling notifications for '
          '${schedule.treatmentType.name} schedule ${schedule.id} '
          '(operation: $operationType)',
        );
      }

      // Use NotificationCoordinator to refresh all notifications
      // (includes the new/updated schedule)
      final result =
          await _ref.read(notificationCoordinatorProvider).refreshAll();
      final reminderCount = result['scheduled'] as int? ?? 0;

      if (kDebugMode) {
        debugPrint(
          '[ScheduleNotificationHandler] Notifications refreshed: '
          '$reminderCount scheduled',
        );
      }

      // Track analytics event
      try {
        final analyticsService = _ref.read(analyticsServiceDirectProvider);
        if (operationType == 'create') {
          await analyticsService.trackScheduleCreatedRemindersScheduled(
            treatmentType: schedule.treatmentType.name,
            scheduleId: schedule.id,
            reminderCount: reminderCount,
            result: 'success',
          );
        } else {
          await analyticsService.trackScheduleUpdatedRemindersRescheduled(
            treatmentType: schedule.treatmentType.name,
            scheduleId: schedule.id,
            reminderCount: reminderCount,
            result: 'success',
          );
        }
      } on Exception catch (e) {
        if (kDebugMode) {
          debugPrint(
            '[ScheduleNotificationHandler] Analytics tracking failed: $e',
          );
        }
      }
    } on Exception catch (e) {
      // Silent error logging - don't block schedule operation
      if (kDebugMode) {
        debugPrint(
          '[ScheduleNotificationHandler] Failed to schedule notifications: $e',
        );
      }

      // Report to Crashlytics
      NotificationErrorHandler.handleSchedulingError(
        context: null,
        operation: 'schedule_for_schedule_$operationType',
        error: e,
        userId: userId,
        petId: petId,
        scheduleId: schedule.id,
      );

      // Track error analytics for schedule create/update
      try {
        final analyticsService = _ref.read(analyticsServiceDirectProvider);
        if (operationType == 'create') {
          await analyticsService.trackScheduleCreatedRemindersScheduled(
            treatmentType: schedule.treatmentType.name,
            scheduleId: schedule.id,
            reminderCount: 0,
            result: 'error',
          );
        } else {
          await analyticsService.trackScheduleUpdatedRemindersRescheduled(
            treatmentType: schedule.treatmentType.name,
            scheduleId: schedule.id,
            reminderCount: 0,
            result: 'error',
          );
        }
      } on Exception catch (analyticsError) {
        if (kDebugMode) {
          debugPrint(
            '[ScheduleNotificationHandler] Analytics tracking failed: '
            '$analyticsError',
          );
        }
      }
    }
  }

  /// Cancel notifications for a schedule (silent, non-blocking)
  ///
  /// Called after successful schedule delete or deactivation operations.
  /// Failures are logged to analytics but do not block the schedule
  /// operation.
  ///
  /// Algorithm:
  /// 1. Validate prerequisites (userId, petId)
  /// 2. Get ReminderService from ref
  /// 3. Call reminderService.cancelForSchedule() with ref cast
  /// 4. Track analytics for success or failure
  /// 5. Catch all exceptions and log silently
  /// 6. Never throw/rethrow
  ///
  /// Parameters:
  /// - [userId]: The user ID
  /// - [petId]: The pet ID
  /// - [scheduleId]: The schedule ID to cancel notifications for
  /// - [treatmentType]: 'fluid' or 'medication' for analytics tracking
  /// - [operationType]: 'delete' or 'deactivate' for analytics tracking
  ///
  /// Returns: void (all errors logged silently)
  Future<void> cancelForSchedule({
    required String userId,
    required String petId,
    required String scheduleId,
    required String treatmentType,
    required String operationType,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint(
          '[ScheduleNotificationHandler] Canceling notifications for '
          '$treatmentType schedule $scheduleId '
          '(operation: $operationType)',
        );
      }

      // Use NotificationCoordinator to cancel notifications for this schedule
      final canceledCount = await _ref
          .read(notificationCoordinatorProvider)
          .cancelForSchedule(scheduleId);

      if (kDebugMode) {
        debugPrint(
          '[ScheduleNotificationHandler] Canceled $canceledCount '
          'notification(s) for schedule $scheduleId',
        );
      }

      // Track analytics event
      try {
        final analyticsService = _ref.read(analyticsServiceDirectProvider);
        if (operationType == 'delete') {
          await analyticsService.trackScheduleDeletedRemindersCanceled(
            treatmentType: treatmentType,
            scheduleId: scheduleId,
            canceledCount: canceledCount,
            result: 'success',
          );
        } else {
          await analyticsService.trackScheduleDeactivatedRemindersCanceled(
            treatmentType: treatmentType,
            scheduleId: scheduleId,
            canceledCount: canceledCount,
            result: 'success',
          );
        }
      } on Exception catch (e) {
        if (kDebugMode) {
          debugPrint(
            '[ScheduleNotificationHandler] Analytics tracking failed: $e',
          );
        }
      }
    } on Exception catch (e) {
      // Silent error logging - don't block schedule operation
      if (kDebugMode) {
        debugPrint(
          '[ScheduleNotificationHandler] Failed to cancel notifications: $e',
        );
      }

      // Report to Crashlytics
      NotificationErrorHandler.handleSchedulingError(
        context: null,
        operation: 'cancel_for_schedule_$operationType',
        error: e,
        userId: userId,
        petId: petId,
        scheduleId: scheduleId,
      );

      // Track error analytics for schedule delete/deactivate
      try {
        final analyticsService = _ref.read(analyticsServiceDirectProvider);
        if (operationType == 'delete') {
          await analyticsService.trackScheduleDeletedRemindersCanceled(
            treatmentType: treatmentType,
            scheduleId: scheduleId,
            canceledCount: 0,
            result: 'error',
          );
        } else {
          await analyticsService.trackScheduleDeactivatedRemindersCanceled(
            treatmentType: treatmentType,
            scheduleId: scheduleId,
            canceledCount: 0,
            result: 'error',
          );
        }
      } on Exception catch (analyticsError) {
        if (kDebugMode) {
          debugPrint(
            '[ScheduleNotificationHandler] Analytics tracking failed: '
            '$analyticsError',
          );
        }
      }
    }
  }
}
