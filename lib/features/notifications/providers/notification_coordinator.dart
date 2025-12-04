import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/core/config/flavor_config.dart';
import 'package:hydracat/features/notifications/models/scheduled_notification_entry.dart';
import 'package:hydracat/features/notifications/providers/notification_provider.dart';
import 'package:hydracat/features/notifications/services/notification_error_handler.dart';
import 'package:hydracat/features/notifications/services/notification_index_store.dart';
import 'package:hydracat/features/notifications/services/reminder_plugin.dart';
import 'package:hydracat/features/notifications/utils/notification_id.dart';
import 'package:hydracat/features/profile/models/schedule.dart';
import 'package:hydracat/l10n/app_localizations.dart';
import 'package:hydracat/providers/analytics_provider.dart';
import 'package:hydracat/providers/auth_provider.dart';
import 'package:hydracat/providers/profile_provider.dart';
import 'package:timezone/timezone.dart' as tz;

/// Provider for the NotificationCoordinator.
///
/// This provider acts as the business logic layer between the app and
/// the platform notification APIs. It:
/// - Decides when to schedule/cancel/refresh notifications
/// - Reads app state from other providers (profile, auth, settings)
/// - Coordinates with ReminderPlugin (platform layer)
/// - Handles bundling logic and timing decisions
///
/// **Usage from any context:**
/// ```dart
/// // From a Widget (WidgetRef)
/// ref.read(notificationCoordinatorProvider).refreshAll();
///
/// // From a StateNotifier (Ref)
/// _ref.read(notificationCoordinatorProvider).refreshAll();
///
/// // From another Provider (Ref)
/// ref.read(notificationCoordinatorProvider).scheduleAllForToday();
/// ```
final notificationCoordinatorProvider =
    Provider<NotificationCoordinator>((ref) {
  return NotificationCoordinator(ref);
});

/// Business logic coordinator for notification operations.
///
/// This class contains all the "when to schedule" and "what to schedule"
/// logic, while delegating the actual platform calls to ReminderPlugin.
class NotificationCoordinator {
  /// Creates a notification coordinator with access to Riverpod providers.
  NotificationCoordinator(this._ref);

  final Ref _ref;

  // Constants for follow-up scheduling
  static const int _defaultFollowupOffsetHours = 2;

  // Multi-day scheduling constant
  static const int _schedulingWindowDays = 3; // Today + 2 days

  // Platform and storage dependencies (no Ref needed in method signatures)
  ReminderPlugin get _plugin => _ref.read(reminderPluginProvider);
  NotificationIndexStore get _indexStore =>
      _ref.read(notificationIndexStoreProvider);

  /// Schedule all notifications for today based on active schedules.
  ///
  /// **Updated behavior**: Now schedules for the next 3 days to ensure
  /// notifications fire even if user doesn't open app daily.
  ///
  /// Returns: Map with scheduling results (scheduled, immediate, missed counts)
  Future<Map<String, dynamic>> scheduleAllForToday() async {
    // Delegate to multi-day scheduler
    return scheduleForNext3Days();
  }

  /// Schedule notifications for the next 3 days.
  ///
  /// This ensures notifications fire even if user doesn't open app daily.
  /// Follow-ups are only scheduled for today to conserve notification quota.
  ///
  /// **Scheduling window:**
  /// - Day 0 (today): Initial + follow-up notifications
  /// - Day 1: Initial notifications only
  /// - Day 2: Initial notifications only
  ///
  /// **Returns**: Map with scheduling results:
  /// - `scheduled`: Number of notifications scheduled
  /// - `immediate`: Number of notifications fired immediately (grace period)
  /// - `missed`: Number of notifications skipped (too far in past)
  /// - `daysScheduled`: Number of days successfully scheduled
  /// - `dailyResults`: Per-day breakdown
  /// - `errors`: List of error messages
  Future<Map<String, dynamic>> scheduleForNext3Days() async {
    final user = _ref.read(currentUserProvider);
    final pet = _ref.read(primaryPetProvider);

    if (user == null || pet == null) {
      return _emptyResult(reason: 'no_user_or_pet');
    }

    _devLog(
      '═══ Scheduling notifications for next $_schedulingWindowDays days...',
    );

    var totalScheduled = 0;
    var totalImmediate = 0;
    var totalMissed = 0;
    final allErrors = <String>[];
    final dailyResults = <String, Map<String, dynamic>>{};

    // Get pet name for notifications
    final profileState = _ref.read(profileProvider);
    final petName = profileState.primaryPet?.name ?? 'your pet';

    // Schedule for each day
    for (var dayOffset = 0; dayOffset < _schedulingWindowDays; dayOffset++) {
      final targetDate = DateTime.now().add(Duration(days: dayOffset));
      final dateKey = _formatDate(targetDate);

      try {
        final result = await _scheduleForSpecificDate(
          date: targetDate,
          userId: user.id,
          petId: pet.id,
          petName: petName,
          includeFollowups: dayOffset == 0, // Only today gets follow-ups
        );

        dailyResults[dateKey] = result;
        totalScheduled += result['scheduled'] as int;
        totalImmediate += result['immediate'] as int;
        totalMissed += result['missed'] as int;

        final errors = result['errors'] as List<dynamic>?;
        if (errors != null && errors.isNotEmpty) {
          allErrors.addAll(errors.cast<String>());
        }
      } on Exception catch (e) {
        final error = 'Day $dayOffset ($dateKey): $e';
        allErrors.add(error);
        _devLog('❌ Failed to schedule day $dayOffset: $e');
      }
    }

    _devLog(
      '✅ Multi-day scheduling complete: $totalScheduled scheduled, '
      '$totalImmediate immediate, $totalMissed missed',
    );

    // Track analytics
    try {
      await _ref.read(analyticsServiceDirectProvider).trackMultiDayScheduling(
        daysScheduled: dailyResults.length,
        totalNotifications: totalScheduled,
      );
    } on Exception catch (e) {
      _devLog('Analytics tracking failed: $e');
    }

    return {
      'scheduled': totalScheduled,
      'immediate': totalImmediate,
      'missed': totalMissed,
      'daysScheduled': dailyResults.length,
      'dailyResults': dailyResults,
      'errors': allErrors,
    };
  }

  /// Refresh all notifications by canceling and rescheduling everything.
  ///
  /// This is the "nuclear option" for simplicity:
  /// 1. Cancel all existing notifications
  /// 2. Reschedule based on current active schedules
  ///
  /// Called after schedule changes or treatment logging.
  Future<Map<String, dynamic>> refreshAll() async {
    final user = _ref.read(currentUserProvider);
    final pet = _ref.read(primaryPetProvider);

    if (user == null || pet == null) {
      return _emptyResult(reason: 'no_user_or_pet');
    }

    try {
      // Step 1: Cancel all
      await _cancelAllForToday(user.id, pet.id);

      // Step 2: Reschedule
      return await scheduleAllForToday();
    } on Exception catch (e) {
      _devLog('[NotificationCoordinator] Refresh failed: $e');
      return {
        'scheduled': 0,
        'immediate': 0,
        'missed': 0,
        'errors': [e.toString()],
      };
    }
  }

  /// Schedule weekly summary notification.
  ///
  /// Reads notification settings and schedules weekly summary if enabled.
  Future<Map<String, dynamic>> scheduleWeeklySummary() async {
    final user = _ref.read(currentUserProvider);
    final pet = _ref.read(primaryPetProvider);

    if (user == null || pet == null) {
      return {
        'success': false,
        'reason': 'no_user_or_pet',
      };
    }

    return _scheduleWeeklySummaryImpl(user.id, pet.id);
  }

  /// Cancel weekly summary notification.
  Future<bool> cancelWeeklySummary() async {
    final user = _ref.read(currentUserProvider);
    final pet = _ref.read(primaryPetProvider);

    if (user == null || pet == null) {
      return false;
    }

    return _cancelWeeklySummaryImpl(user.id, pet.id);
  }

  /// Cancel all notifications for today.
  Future<void> cancelAllForToday() async {
    final user = _ref.read(currentUserProvider);
    final pet = _ref.read(primaryPetProvider);

    if (user == null || pet == null) return;

    await _cancelAllForToday(user.id, pet.id);
  }

  /// Reschedule all notifications (idempotent reconciliation).
  ///
  /// Call this:
  /// - On app startup (if needed)
  /// - On date change (midnight rollover)
  /// - When recovering from errors
  Future<Map<String, dynamic>> rescheduleAll() async {
    final user = _ref.read(currentUserProvider);
    final pet = _ref.read(primaryPetProvider);

    if (user == null || pet == null) {
      return {
        'orphansCanceled': 0,
        'missingCount': 0,
        'errors': ['no_user_or_pet'],
      };
    }

    return _rescheduleAllImpl(user.id, pet.id);
  }

  /// Schedule notifications for a single schedule.
  ///
  /// This method is called when:
  /// - A new schedule is created
  /// - An existing schedule is updated
  ///
  /// **Strategy:**
  /// Always uses refreshAll() to ensure correctness and avoid edge cases.
  /// This prioritizes simplicity and reliability over performance optimization.
  ///
  /// **Why not surgical updates?**
  /// Surgical updates fail when reminder times change because notification IDs
  /// include the time slot. When times change, old notifications can't be
  /// canceled using new time-based IDs, resulting in duplicate notifications.
  Future<Map<String, dynamic>> scheduleForSchedule(Schedule schedule) async {
    final user = _ref.read(currentUserProvider);
    final pet = _ref.read(primaryPetProvider);

    if (user == null || pet == null) {
      return _emptyResult(reason: 'no_user_or_pet');
    }

    _devLog('scheduleForSchedule called for schedule ${schedule.id}');

    // Validation
    if (!schedule.isActive) {
      _devLog(
        'Schedule ${schedule.id} is inactive, canceling its notifications',
      );
      await cancelFutureNotificationsForSchedule(schedule.id);
      return _emptyResult(reason: 'inactive_schedule');
    }

    // Always use refreshAll() for correctness
    // This ensures we cancel old notifications and reschedule correctly,
    // avoiding bugs where surgical updates fail to cancel notifications
    // with old time-based IDs when reminder times change.
    _devLog(
      'Using refreshAll() to ensure all notifications are synchronized',
    );
    return refreshAll();
  }

  /// Cancel all notifications for a schedule.
  ///
  /// Used when a schedule is deleted. Cancels for the next 3 days.
  Future<int> cancelForSchedule(String scheduleId) async {
    final user = _ref.read(currentUserProvider);
    final pet = _ref.read(primaryPetProvider);

    if (user == null || pet == null) {
      return 0;
    }

    _devLog('cancelForSchedule called for schedule $scheduleId');

    final canceledCount =
        await cancelFutureNotificationsForSchedule(scheduleId);

    return canceledCount;
  }

  /// Cancel notifications for a specific time slot.
  Future<int> cancelSlot(String scheduleId, String timeSlot) async {
    final user = _ref.read(currentUserProvider);
    final pet = _ref.read(primaryPetProvider);

    if (user == null || pet == null) {
      return 0;
    }

    return _cancelSlotImpl(user.id, pet.id, scheduleId, timeSlot);
  }

  // ==========================================================================
  // PRIVATE IMPLEMENTATION METHODS
  // ==========================================================================

  /// Schedule notifications for a specific date.
  ///
  /// Internal method used by [scheduleForNext3Days].
  ///
  /// **Parameters:**
  /// - [date]: Target date to schedule for
  /// - [userId]: User identifier
  /// - [petId]: Pet identifier
  /// - [petName]: Pet name for notification content
  /// - [includeFollowups]: Whether to schedule follow-up notifications
  ///
  /// **Returns**: Map with counts (scheduled, immediate, missed, errors)
  Future<Map<String, dynamic>> _scheduleForSpecificDate({
    required DateTime date,
    required String userId,
    required String petId,
    required String petName,
    required bool includeFollowups,
  }) async {
    var scheduledCount = 0;
    var immediateCount = 0;
    var missedCount = 0;
    final errors = <String>[];

    try {
      // Get cached schedules from profileProvider
      final profileState = _ref.read(profileProvider);
      final allSchedules = <Schedule>[
        if (profileState.fluidSchedule != null) profileState.fluidSchedule!,
        ...profileState.medicationSchedules ?? [],
      ];

      if (allSchedules.isEmpty) {
        return {
          'scheduled': 0,
          'immediate': 0,
          'missed': 0,
          'errors': <String>[],
        };
      }

      // Filter to schedules active on this date
      final activeSchedules = allSchedules.where((schedule) {
        return schedule.isActive && schedule.hasReminderOnDate(date);
      }).toList();

      if (activeSchedules.isEmpty) {
        return {
          'scheduled': 0,
          'immediate': 0,
          'missed': 0,
          'errors': <String>[],
        };
      }

      // Group by time slot for bundling
      final schedulesByTimeSlot = <String, List<Schedule>>{};

      for (final schedule in activeSchedules) {
        final reminderTimes = schedule.reminderTimesOnDate(date);

        for (final reminderTime in reminderTimes) {
          final timeSlot = '${reminderTime.hour.toString().padLeft(2, '0')}:'
              '${reminderTime.minute.toString().padLeft(2, '0')}';

          schedulesByTimeSlot.putIfAbsent(timeSlot, () => []).add(schedule);
        }
      }

      // Schedule bundled notifications for each time slot
      for (final entry in schedulesByTimeSlot.entries) {
        final timeSlot = entry.key;
        final schedules = entry.value;

        try {
          final result = await _scheduleNotificationForDateAndTimeSlot(
            userId: userId,
            petId: petId,
            schedules: schedules,
            timeSlot: timeSlot,
            date: date,
            petName: petName,
            includeFollowup: includeFollowups,
          );

          scheduledCount += result['scheduled'] as int;
          immediateCount += result['immediate'] as int;
          missedCount += result['missed'] as int;
        } on Exception catch (e) {
          errors.add('Failed to schedule $timeSlot: $e');
          _devLog('❌ Error scheduling $timeSlot on ${_formatDate(date)}: $e');
        }
      }

      return {
        'scheduled': scheduledCount,
        'immediate': immediateCount,
        'missed': missedCount,
        'errors': errors,
      };
    } on Exception catch (e, stackTrace) {
      _devLog('❌ ERROR in _scheduleForSpecificDate: $e');
      _devLog('Stack trace: $stackTrace');
      return {
        'scheduled': 0,
        'immediate': 0,
        'missed': 0,
        'errors': [e.toString()],
      };
    }
  }

  /// Schedule notification for specific date and time slot.
  ///
  /// Handles both initial notification and optional follow-up.
  /// Uses date-aware ID generation to prevent collisions across days.
  ///
  /// **Parameters:**
  /// - [userId]: User identifier
  /// - [petId]: Pet identifier
  /// - [schedules]: List of schedules bundled at this time slot
  /// - [timeSlot]: Time in "HH:mm" format
  /// - [date]: Target date
  /// - [petName]: Pet name for notification content
  /// - [includeFollowup]: Whether to schedule follow-up notification
  ///
  /// **Returns**: Map with counts (scheduled, immediate, missed)
  Future<Map<String, dynamic>> _scheduleNotificationForDateAndTimeSlot({
    required String userId,
    required String petId,
    required List<Schedule> schedules,
    required String timeSlot,
    required DateTime date,
    required String petName,
    required bool includeFollowup,
  }) async {
    var scheduledCount = 0;
    var immediateCount = 0;
    var missedCount = 0;

    if (schedules.isEmpty) {
      return {'scheduled': 0, 'immediate': 0, 'missed': 0};
    }

    try {
      // Parse time slot
      final timeParts = timeSlot.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      // Create TZDateTime for this specific date and time
      final scheduledTime = tz.TZDateTime(
        tz.local,
        date.year,
        date.month,
        date.day,
        hour,
        minute,
      );

      // Check if this is in the past
      final now = tz.TZDateTime.now(tz.local);
      final isPast = scheduledTime.isBefore(now);
      final isWithinGracePeriod =
          isPast && now.difference(scheduledTime).inMinutes <= 30;

      // Decide action
      if (isPast && !isWithinGracePeriod) {
        // Too far in past, skip
        missedCount++;
        return {'scheduled': 0, 'immediate': 0, 'missed': 1};
      }

      // Generate notification content
      final content = _generateBundledNotificationContent(
        schedules: schedules,
        kind: 'initial',
        petName: petName,
      );

      // Generate unique notification ID including date
      final notificationId = generateTimeSlotNotificationIdForDate(
        userId: userId,
        petId: petId,
        timeSlot: timeSlot,
        kind: 'initial',
        date: date,
      );

      // Build payload
      final scheduleIds = schedules.map((s) => s.id).join(',');
      final payload = jsonEncode({
        'type': 'treatment_reminder',
        'userId': userId,
        'petId': petId,
        'scheduleIds': scheduleIds,
        'timeSlot': timeSlot,
        'kind': 'initial',
        'treatmentTypes': schedules.map((s) => s.treatmentType.name).join(','),
        'scheduledFor': scheduledTime.toIso8601String(),
        'date': _formatDate(date),
      });

      final groupId = 'pet_$petId';
      final threadIdentifier = 'pet_$petId';

      // Schedule notification
      // Add a 1-second buffer for immediate notifications to ensure they're
      // always in the future when validated by the platform
      final actualScheduledTime = isWithinGracePeriod
          ? tz.TZDateTime.now(tz.local).add(const Duration(seconds: 1))
          : scheduledTime;

      await _plugin.showZoned(
        id: notificationId,
        title: content['title']!,
        body: content['body']!,
        scheduledDate: actualScheduledTime,
        channelId: content['channelId']!,
        payload: payload,
        groupId: groupId,
        threadIdentifier: threadIdentifier,
      );

      if (isWithinGracePeriod) {
        immediateCount++;
        _devLog(
          'Fired immediate notification for $timeSlot on ${_formatDate(date)}',
        );
      } else {
        scheduledCount++;
        _devLog('Scheduled notification for $timeSlot on ${_formatDate(date)}');
      }

      // Record in index (only if today)
      if (_isSameDay(date, DateTime.now())) {
        await _indexStore.putEntry(
          userId,
          petId,
          ScheduledNotificationEntry.create(
            notificationId: notificationId,
            scheduleId: schedules.first.id,
            treatmentType: schedules.first.treatmentType.name,
            timeSlotISO: timeSlot,
            kind: 'initial',
          ),
        );
      }

      // Schedule follow-up if requested
      if (includeFollowup && !isPast) {
        try {
          final followupResult = await _scheduleFollowupForDateAndTimeSlot(
            userId: userId,
            petId: petId,
            schedules: schedules,
            timeSlot: timeSlot,
            date: date,
            petName: petName,
            initialScheduledTime: scheduledTime,
          );
          scheduledCount += followupResult['scheduled'] as int;
        } on Exception catch (e) {
          _devLog('⚠️ Failed to schedule follow-up: $e');
        }
      }

      return {
        'scheduled': scheduledCount,
        'immediate': immediateCount,
        'missed': missedCount,
      };
    } on Exception catch (e, stackTrace) {
      _devLog('❌ ERROR in _scheduleNotificationForDateAndTimeSlot: $e');
      _devLog('Stack trace: $stackTrace');
      return {
        'scheduled': 0,
        'immediate': 0,
        'missed': missedCount,
      };
    }
  }

  /// Schedule follow-up for specific date.
  ///
  /// Follow-ups are only scheduled for today to conserve notification quota.
  ///
  /// **Parameters:**
  /// - [userId]: User identifier
  /// - [petId]: Pet identifier
  /// - [schedules]: List of schedules bundled at this time slot
  /// - [timeSlot]: Time in "HH:mm" format
  /// - [date]: Target date
  /// - [petName]: Pet name for notification content
  /// - [initialScheduledTime]: When the initial notification was scheduled
  ///
  /// **Returns**: Map with count (scheduled)
  Future<Map<String, dynamic>> _scheduleFollowupForDateAndTimeSlot({
    required String userId,
    required String petId,
    required List<Schedule> schedules,
    required String timeSlot,
    required DateTime date,
    required String petName,
    required tz.TZDateTime initialScheduledTime,
  }) async {
    var scheduledCount = 0;

    try {
      final followupTime = initialScheduledTime.add(
        const Duration(hours: _defaultFollowupOffsetHours),
      );

      // Skip if in the past
      if (followupTime.isBefore(tz.TZDateTime.now(tz.local))) {
        return {'scheduled': 0};
      }

      final content = _generateBundledNotificationContent(
        schedules: schedules,
        kind: 'followup',
        petName: petName,
      );

      final followupId = generateTimeSlotNotificationIdForDate(
        userId: userId,
        petId: petId,
        timeSlot: timeSlot,
        kind: 'followup',
        date: date,
      );

      final scheduleIds = schedules.map((s) => s.id).join(',');
      final payload = jsonEncode({
        'type': 'treatment_reminder',
        'userId': userId,
        'petId': petId,
        'scheduleIds': scheduleIds,
        'timeSlot': timeSlot,
        'kind': 'followup',
        'treatmentTypes': schedules.map((s) => s.treatmentType.name).join(','),
        'scheduledFor': followupTime.toIso8601String(),
        'date': _formatDate(date),
      });

      final groupId = 'pet_$petId';
      final threadIdentifier = 'pet_$petId';

      await _plugin.showZoned(
        id: followupId,
        title: content['title']!,
        body: content['body']!,
        scheduledDate: followupTime,
        channelId: content['channelId']!,
        payload: payload,
        groupId: groupId,
        threadIdentifier: threadIdentifier,
      );
      scheduledCount++;

      // Record in index (only if today)
      if (_isSameDay(date, DateTime.now())) {
        await _indexStore.putEntry(
          userId,
          petId,
          ScheduledNotificationEntry.create(
            notificationId: followupId,
            scheduleId: schedules.first.id,
            treatmentType: schedules.first.treatmentType.name,
            timeSlotISO: timeSlot,
            kind: 'followup',
          ),
        );
      }

      return {'scheduled': scheduledCount};
    } on Exception catch (e) {
      _devLog('❌ ERROR scheduling follow-up: $e');
      return {'scheduled': 0};
    }
  }

  /// Cancel all future notifications for a specific schedule.
  ///
  /// Used when schedule is deleted or modified. Cancels notifications
  /// for the next 3 days.
  ///
  /// **Strategy:**
  /// 1. Get schedule from cache to find its time slots
  /// 2. For each of next 3 days:
  ///    - Cancel initial notification at each time slot
  ///    - Cancel follow-up notification (only exists for today)
  /// 3. Remove from today's index
  ///
  /// **Note**: This method tries to cancel notifications but doesn't validate
  /// if they actually exist. Platform cancel() is idempotent.
  ///
  /// **Returns**: Number of cancel operations performed (not necessarily
  /// successful)
  Future<int> cancelFutureNotificationsForSchedule(String scheduleId) async {
    final user = _ref.read(currentUserProvider);
    final pet = _ref.read(primaryPetProvider);

    if (user == null || pet == null) return 0;

    _devLog('Canceling future notifications for schedule $scheduleId');

    var canceledCount = 0;

    // Cancel for each of the next 3 days
    for (var dayOffset = 0; dayOffset < _schedulingWindowDays; dayOffset++) {
      final date = DateTime.now().add(Duration(days: dayOffset));

      try {
        // Get the schedule to find its time slots
        final profileState = _ref.read(profileProvider);
        final allSchedules = <Schedule>[
          if (profileState.fluidSchedule?.id == scheduleId)
            profileState.fluidSchedule!,
          ...profileState.medicationSchedules
                  ?.where((s) => s.id == scheduleId) ??
              [],
        ];

        if (allSchedules.isEmpty) {
          _devLog('Schedule $scheduleId not found in cache');
          continue;
        }

        final schedule = allSchedules.first;

        // Get reminder times for this date
        final reminderTimes = schedule.reminderTimesOnDate(date);

        for (final reminderTime in reminderTimes) {
          final timeSlot = '${reminderTime.hour.toString().padLeft(2, '0')}:'
              '${reminderTime.minute.toString().padLeft(2, '0')}';

          // Cancel initial notification
          final initialId = generateTimeSlotNotificationIdForDate(
            userId: user.id,
            petId: pet.id,
            timeSlot: timeSlot,
            kind: 'initial',
            date: date,
          );

          try {
            await _plugin.cancel(initialId);
            canceledCount++;
            _devLog(
              'Canceled notification $initialId for ${_formatDate(date)} '
              '$timeSlot',
            );
          } on Exception catch (e) {
            _devLog('Failed to cancel notification $initialId: $e');
          }

          // Cancel follow-up notification (only exists for today)
          if (dayOffset == 0) {
            final followupId = generateTimeSlotNotificationIdForDate(
              userId: user.id,
              petId: pet.id,
              timeSlot: timeSlot,
              kind: 'followup',
              date: date,
            );

            try {
              await _plugin.cancel(followupId);
              canceledCount++;
              _devLog('Canceled follow-up $followupId');
            } on Exception catch (e) {
              _devLog('Failed to cancel follow-up $followupId: $e');
            }
          }
        }

        // Remove from index (only for today)
        if (dayOffset == 0) {
          await _indexStore.removeAllForSchedule(user.id, pet.id, scheduleId);
        }
      } on Exception catch (e) {
        _devLog('Error canceling notifications for day $dayOffset: $e');
      }
    }

    _devLog('✅ Canceled $canceledCount notifications for schedule $scheduleId');
    return canceledCount;
  }

  /// Generate notification content for single or bundled treatments.
  Map<String, String> _generateBundledNotificationContent({
    required List<Schedule> schedules,
    required String kind,
    required String petName,
  }) {
    final l10n = _getLocalizations();

    if (schedules.isEmpty) {
      throw ArgumentError('schedules list cannot be empty');
    }

    // Single treatment - use existing specific messaging
    if (schedules.length == 1) {
      final treatmentType = schedules.first.treatmentType.name;

      if (kind == 'initial') {
        if (treatmentType == 'medication') {
          return {
            'title': l10n.notificationMedicationTitleA11y(petName),
            'body': l10n.notificationMedicationBodyA11y(petName),
            'channelId': 'medication_reminders',
          };
        } else {
          // fluid
          return {
            'title': l10n.notificationFluidTitleA11y(petName),
            'body': l10n.notificationFluidBodyA11y(petName),
            'channelId': 'fluid_reminders',
          };
        }
      } else {
        // followup
        return {
          'title': l10n.notificationFollowupTitleA11y(petName),
          'body': l10n.notificationFollowupBodyA11y(petName),
          'channelId': treatmentType == 'medication'
              ? 'medication_reminders'
              : 'fluid_reminders',
        };
      }
    }

    // Multiple treatments - use bundled messaging
    final medicationCount =
        schedules.where((s) => s.treatmentType.name == 'medication').length;
    final fluidCount =
        schedules.where((s) => s.treatmentType.name == 'fluid').length;

    if (kind == 'initial') {
      String body;
      if (medicationCount > 0 && fluidCount > 0) {
        // Mixed types - specific message
        body = l10n.notificationMixedTreatmentsBody;
      } else {
        // All same type - count message
        body = l10n.notificationMultipleTreatmentsBody(schedules.length);
      }

      return {
        'title': l10n.notificationMultipleTreatmentsTitle(petName),
        'body': body,
        'channelId': 'medication_reminders', // Use high-priority channel
      };
    } else {
      // followup bundled
      return {
        'title': l10n.notificationMultipleFollowupTitle(petName),
        'body':
            l10n.notificationMultipleFollowupBody(petName, schedules.length),
        'channelId': 'medication_reminders',
      };
    }
  }

  /// Internal implementation of scheduleWeeklySummary.
  Future<Map<String, dynamic>> _scheduleWeeklySummaryImpl(
    String userId,
    String petId,
  ) async {
    _devLog('scheduleWeeklySummary called for userId=$userId, petId=$petId');

    try {
      // Step 1: Check if weekly summary is enabled in user settings
      _devLog('Step 1: Checking notification settings...');
      final settings = _ref.read(notificationSettingsProvider(userId));
      _devLog(
        '  enableNotifications: ${settings.enableNotifications}',
      );
      _devLog('  weeklySummaryEnabled: ${settings.weeklySummaryEnabled}');

      if (!settings.enableNotifications || !settings.weeklySummaryEnabled) {
        _devLog('❌ Weekly summary disabled in settings');
        return {
          'success': false,
          'reason': 'disabled_in_settings',
        };
      }
      _devLog('✅ Weekly summary enabled in settings');

      // Step 2: Calculate next Monday 09:00
      _devLog('');
      _devLog('Step 2: Calculating next Monday 09:00...');
      final nextMonday = _calculateNextMonday09();
      _devLog('  Next Monday 09:00: $nextMonday');

      // Step 3: Generate deterministic notification ID
      _devLog('');
      _devLog('Step 3: Generating notification ID...');
      final notificationId = generateWeeklySummaryNotificationId(
        userId: userId,
        petId: petId,
        weekStartDate: nextMonday,
      );
      _devLog('  Notification ID: $notificationId');

      // Step 4: Check if notification already scheduled (idempotent check)
      _devLog('');
      _devLog('Step 4: Checking if already scheduled...');
      final pendingNotifications = await _plugin.pendingNotificationRequests();
      final alreadyScheduled = pendingNotifications.any(
        (n) => n.id == notificationId,
      );

      if (alreadyScheduled) {
        _devLog('ℹ️ Weekly summary already scheduled (idempotent)');
        return {
          'success': false,
          'reason': 'already_scheduled',
          'scheduledFor': nextMonday.toIso8601String(),
          'notificationId': notificationId,
        };
      }
      _devLog('✅ No duplicate found, proceeding with scheduling');

      // Step 5: Build generic notification content
      _devLog('');
      _devLog('Step 5: Building notification content...');
      final l10n = _getLocalizations();
      final title = l10n.notificationWeeklySummaryTitle;
      final body = l10n.notificationWeeklySummaryBody;
      final payload = json.encode({
        'type': 'weekly_summary',
        'route': '/progress',
      });
      _devLog('  Title: $title');
      _devLog('  Body: $body');
      _devLog('  Payload: $payload');

      // Step 6: Schedule notification
      _devLog('');
      _devLog('Step 6: Scheduling notification...');
      await _plugin.showZoned(
        id: notificationId,
        title: title,
        body: body,
        scheduledDate: nextMonday,
        channelId: ReminderPlugin.channelIdWeeklySummaries,
        payload: payload,
        // No grouping - standalone notification (defaults to null)
      );

      _devLog('✅ Weekly summary scheduled successfully');
      _devLog('');

      return {
        'success': true,
        'scheduledFor': nextMonday.toIso8601String(),
        'notificationId': notificationId,
      };
    } on Exception catch (e, stackTrace) {
      _devLog('❌ ERROR in scheduleWeeklySummary: $e');
      _devLog('Stack trace: $stackTrace');

      NotificationErrorHandler.handleSchedulingError(
        context: null,
        operation: 'schedule_weekly_summary',
        error: e,
        userId: userId,
        petId: petId,
      );

      return {
        'success': false,
        'reason': 'error',
        'error': e.toString(),
      };
    }
  }

  /// Internal implementation of cancelWeeklySummary.
  Future<bool> _cancelWeeklySummaryImpl(
    String userId,
    String petId,
  ) async {
    _devLog('cancelWeeklySummary called for userId=$userId, petId=$petId');

    try {
      var canceledCount = 0;

      // Check next Monday and up to 4 weeks in advance
      for (var i = 0; i < 4; i++) {
        final monday = _calculateNextMonday09().add(Duration(days: 7 * i));
        final notificationId = generateWeeklySummaryNotificationId(
          userId: userId,
          petId: petId,
          weekStartDate: monday,
        );

        try {
          await _plugin.cancel(notificationId);
          canceledCount++;
          _devLog('Canceled weekly summary notification $notificationId');
        } on Exception catch (e) {
          _devLog('No notification found for ID $notificationId: $e');
          // Continue checking other weeks
        }
      }

      if (canceledCount > 0) {
        _devLog('✅ Canceled $canceledCount weekly summary notification(s)');
        return true;
      } else {
        _devLog('ℹ️ No weekly summary notifications found to cancel');
        return false;
      }
    } on Exception catch (e, stackTrace) {
      _devLog('❌ ERROR in cancelWeeklySummary: $e');
      _devLog('Stack trace: $stackTrace');

      NotificationErrorHandler.handleSchedulingError(
        context: null,
        operation: 'cancel_weekly_summary',
        error: e,
        userId: userId,
        petId: petId,
      );

      return false;
    }
  }

  /// Internal implementation of cancelAllForToday.
  Future<void> _cancelAllForToday(String userId, String petId) async {
    _devLog('cancelAllForToday called for userId=$userId, petId=$petId');
    try {
      // Cancel all indexed notifications for today
      final entries = await _indexStore.getForToday(userId, petId);
      for (final entry in entries) {
        try {
          await _plugin.cancel(entry.notificationId);
        } on Exception catch (e) {
          _devLog('Failed cancel id ${entry.notificationId}: $e');
        }
      }

      // Clear today's index
      await _indexStore.clearForDate(userId, petId, DateTime.now());

      // Cancel weekly summary notifications as well
      await _cancelWeeklySummaryImpl(userId, petId);
    } on Exception catch (e, stackTrace) {
      _devLog('ERROR in cancelAllForToday: $e');
      _devLog('Stack trace: $stackTrace');
      // best-effort cleanup, do not throw
    }
  }

  /// Internal implementation of rescheduleAll.
  Future<Map<String, dynamic>> _rescheduleAllImpl(
    String userId,
    String petId,
  ) async {
    _devLog('rescheduleAll called for userId=$userId, petId=$petId');

    try {
      // Get pending notifications from plugin
      final pendingNotifications = await _plugin.pendingNotificationRequests();

      // Limit reconciliation to today's treatment reminders only.
      // Multi-day notifications for future dates must NOT be treated
      // as orphans.
      final todayStr = _formatDate(DateTime.now());

      final pendingToday = pendingNotifications.where((n) {
        final payload = n.payload;
        if (payload == null) {
          // Legacy notifications without payload – treat as "today"
          return true;
        }

        try {
          final data = jsonDecode(payload) as Map<String, dynamic>;

          // Only reconcile treatment reminders here; weekly summaries and
          // other types are handled separately.
          if (data['type'] != 'treatment_reminder') {
            return false;
          }

          // Multi-day payloads include an explicit date field.
          final dateStr = data['date'] as String?;
          if (dateStr == null) {
            // Backwards compatibility: payloads without `date` are treated
            // as today.
            return true;
          }

          return dateStr == todayStr;
        } on Exception catch (_) {
          // On parsing errors, fail-open and treat as today so we don't
          // accidentally cancel valid future-day notifications.
          return true;
        }
      }).toList();

      final pendingIds = pendingToday.map((n) => n.id).toSet();

      _devLog(
        'Found ${pendingNotifications.length} pending notifications '
        "(${pendingToday.length} for today's treatment reminders)",
      );

      // Get index entries for today
      final analyticsService = _ref.read(analyticsServiceDirectProvider);
      final indexEntries = await _indexStore.getForToday(
        userId,
        petId,
        analyticsService: analyticsService,
        plugin: _plugin,
      );
      final indexedIds = indexEntries.map((e) => e.notificationId).toSet();

      _devLog('Found ${indexEntries.length} indexed notifications');

      // Find orphans (in plugin but not in index) and cancel them
      final orphanIds = pendingIds.difference(indexedIds);
      var orphansCanceled = 0;

      for (final orphanId in orphanIds) {
        try {
          await _plugin.cancel(orphanId);
          orphansCanceled++;
          _devLog('Canceled orphan notification $orphanId');
        } on Exception catch (e) {
          _devLog('ERROR canceling orphan notification $orphanId: $e');
        }
      }

      // Find missing (in index but not in plugin)
      final missingIds = indexedIds.difference(pendingIds);
      _devLog('Found ${missingIds.length} missing notifications in plugin');

      // Clear today's index to start fresh
      await _indexStore.clearForDate(userId, petId, DateTime.now());

      // Reschedule all treatment reminders from cached schedules
      final scheduleResult = await scheduleAllForToday();

      // Cancel and reschedule weekly summary notification
      await _cancelWeeklySummaryImpl(userId, petId);
      final weeklySummaryResult = await _scheduleWeeklySummaryImpl(
        userId,
        petId,
      );

      _devLog(
        'Reconciliation complete: $orphansCanceled orphans canceled, '
        'rescheduled all from cache, weekly summary: '
        '${weeklySummaryResult['success']}',
      );

      return {
        'orphansCanceled': orphansCanceled,
        'missingCount': missingIds.length,
        'scheduleResult': scheduleResult,
        'weeklySummaryResult': weeklySummaryResult,
      };
    } on Exception catch (e, stackTrace) {
      _devLog('ERROR in rescheduleAll: $e');
      _devLog('Stack trace: $stackTrace');

      NotificationErrorHandler.handleSchedulingError(
        context: null,
        operation: 'reschedule_all',
        error: e,
        userId: userId,
        petId: petId,
      );

      return {
        'orphansCanceled': 0,
        'missingCount': 0,
        'errors': [e.toString()],
      };
    }
  }

  /// Internal implementation of cancelSlot.
  Future<int> _cancelSlotImpl(
    String userId,
    String petId,
    String scheduleId,
    String timeSlot,
  ) async {
    _devLog(
      'cancelSlot called for schedule $scheduleId, timeSlot $timeSlot',
    );

    try {
      // Get all index entries for this schedule + timeSlot
      final entries = await _indexStore.getForToday(userId, petId);
      final slotEntries = entries.where((e) {
        return e.scheduleId == scheduleId && e.timeSlotISO == timeSlot;
      }).toList();

      _devLog('Found ${slotEntries.length} notifications to cancel for slot');

      var canceledCount = 0;

      // Cancel all kinds (initial, followup)
      for (final entry in slotEntries) {
        try {
          await _plugin.cancel(entry.notificationId);
          await _indexStore.removeEntryBy(
            userId,
            petId,
            scheduleId,
            timeSlot,
            entry.kind,
          );
          canceledCount++;
        } on Exception catch (e) {
          _devLog(
            'ERROR canceling notification ${entry.notificationId}: $e',
          );
          // Continue canceling other notifications
        }
      }

      _devLog('Canceled $canceledCount notifications for time slot $timeSlot');
      return canceledCount;
    } on Exception catch (e, stackTrace) {
      _devLog('ERROR in cancelSlot: $e');
      _devLog('Stack trace: $stackTrace');
      return 0;
    }
  }

  /// Calculate next Monday at 09:00 (timezone-aware).
  tz.TZDateTime _calculateNextMonday09() {
    final now = DateTime.now();

    // weekday: 1 = Monday, 7 = Sunday
    final currentWeekday = now.weekday;

    DateTime mondayDate;

    if (currentWeekday == DateTime.monday && now.hour < 9) {
      // Today is Monday and it's before 09:00, use today
      mondayDate = now;
    } else {
      // Find next Monday
      final daysUntilMonday = (DateTime.monday - currentWeekday + 7) % 7;
      final daysToAdd = daysUntilMonday == 0 ? 7 : daysUntilMonday;
      mondayDate = now.add(Duration(days: daysToAdd));
    }

    // Create TZDateTime for Monday at 09:00
    final monday09 = tz.TZDateTime(
      tz.local,
      mondayDate.year,
      mondayDate.month,
      mondayDate.day,
      9, // hour
    );

    return monday09;
  }

  /// Get localized strings without BuildContext.
  AppLocalizations _getLocalizations() {
    // Resolve device locale with safe fallbacks
    try {
      final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;

      // Try full locale first (e.g., en_US)
      try {
        return lookupAppLocalizations(deviceLocale);
      } on Exception catch (_) {
        // fall through to languageCode-only attempt
      }

      // Try language-only locale (e.g., en)
      try {
        return lookupAppLocalizations(Locale(deviceLocale.languageCode));
      } on Exception catch (_) {
        // fall through to English fallback
      }
    } on Exception catch (_) {
      // If platformDispatcher is not available, fallback to English
    }

    // Final fallback: English
    return lookupAppLocalizations(const Locale('en'));
  }

  /// Returns an empty result map.
  Map<String, dynamic> _emptyResult({String? reason}) {
    return {
      'scheduled': 0,
      'immediate': 0,
      'missed': 0,
      'errors': <String>[],
      if (reason != null) 'reason': reason,
    };
  }

  /// Format date as YYYY-MM-DD
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  /// Check if two dates are the same day
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Log messages only in development flavor.
  void _devLog(String message) {
    if (FlavorConfig.isDevelopment) {
      debugPrint('[NotificationCoordinator] $message');
    }
  }
}
