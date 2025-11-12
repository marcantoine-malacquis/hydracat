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
import 'package:hydracat/features/notifications/utils/scheduling_helpers.dart';
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

  // Platform and storage dependencies (no Ref needed in method signatures)
  ReminderPlugin get _plugin => _ref.read(reminderPluginProvider);
  NotificationIndexStore get _indexStore =>
      _ref.read(notificationIndexStoreProvider);

  /// Schedule all notifications for today based on active schedules.
  ///
  /// Reads schedules from profile provider and creates bundled notifications
  /// grouped by time slot. This is the main entry point for scheduling.
  ///
  /// Returns: Map with scheduling results (scheduled, immediate, missed counts)
  Future<Map<String, dynamic>> scheduleAllForToday() async {
    // Read current user and pet from providers
    final user = _ref.read(currentUserProvider);
    final pet = _ref.read(primaryPetProvider);

    if (user == null || pet == null) {
      return _emptyResult(reason: 'no_user_or_pet');
    }

    return _scheduleAllForTodayImpl(
      userId: user.id,
      petId: pet.id,
    );
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
  /// This method is idempotent: it first cancels any existing notifications
  /// for this schedule, then schedules new ones.
  Future<Map<String, dynamic>> scheduleForSchedule(Schedule schedule) async {
    final user = _ref.read(currentUserProvider);
    final pet = _ref.read(primaryPetProvider);

    if (user == null || pet == null) {
      return _emptyResult(reason: 'no_user_or_pet');
    }

    _devLog('scheduleForSchedule called for schedule ${schedule.id}');

    // Validation checks
    if (!schedule.isActive) {
      _devLog('Schedule ${schedule.id} is inactive, skipping scheduling');
      return _emptyResult();
    }

    // Simple approach: refresh all notifications
    // This ensures correct bundling without complex logic
    return refreshAll();
  }

  /// Cancel all notifications for a schedule.
  Future<int> cancelForSchedule(String scheduleId) async {
    final user = _ref.read(currentUserProvider);
    final pet = _ref.read(primaryPetProvider);

    if (user == null || pet == null) {
      return 0;
    }

    return _cancelForScheduleImpl(user.id, pet.id, scheduleId);
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

  /// Internal implementation of scheduleAllForToday with explicit parameters.
  Future<Map<String, dynamic>> _scheduleAllForTodayImpl({
    required String userId,
    required String petId,
  }) async {
    _devLog('scheduleAllForToday called for userId=$userId, petId=$petId');

    final now = DateTime.now();
    var scheduledCount = 0;
    var immediateCount = 0;
    var missedCount = 0;
    final errors = <String>[];

    try {
      // Get cached schedules from profileProvider
      final profileState = _ref.read(profileProvider);
      final fluidSchedule = profileState.fluidSchedule;
      final medicationSchedules = profileState.medicationSchedules ?? [];

      // Check if cache is empty
      if (fluidSchedule == null && medicationSchedules.isEmpty) {
        _devLog(
          'No schedules in cache. Skipping scheduling (cache-only policy).',
        );
        return {
          'scheduled': 0,
          'immediate': 0,
          'missed': 0,
          'errors': <String>[],
          'cacheEmpty': true,
        };
      }

      // Get pet name for notification content
      final petName = profileState.primaryPet?.name ?? 'your pet';

      // Combine all schedules
      final allSchedules = <Schedule>[
        if (fluidSchedule != null) fluidSchedule,
        ...medicationSchedules,
      ];

      _devLog('Found ${allSchedules.length} total schedules in cache');

      // Filter to active schedules for today
      final activeSchedulesForToday = allSchedules.where((schedule) {
        return schedule.isActive && schedule.hasReminderTimeToday(now);
      }).toList();

      _devLog(
        '${activeSchedulesForToday.length} active schedules for today',
      );

      // Group schedules by time slot for bundling
      final schedulesByTimeSlot = <String, List<Schedule>>{};

      for (final schedule in activeSchedulesForToday) {
        final reminderTimes = schedule.todaysReminderTimes(now).toList();

        for (final reminderTime in reminderTimes) {
          final timeSlot = '${reminderTime.hour.toString().padLeft(2, '0')}:'
              '${reminderTime.minute.toString().padLeft(2, '0')}';

          schedulesByTimeSlot.putIfAbsent(timeSlot, () => []).add(schedule);
        }
      }

      _devLog('Grouped into ${schedulesByTimeSlot.length} time slots');

      // Schedule one bundled notification per time slot
      for (final entry in schedulesByTimeSlot.entries) {
        final timeSlot = entry.key;
        final schedules = entry.value;

        _devLog(
          'Time slot $timeSlot has ${schedules.length} schedule(s): '
          '${schedules.map((s) => s.id).join(", ")}',
        );

        try {
          final result = await _scheduleNotificationForTimeSlot(
            userId: userId,
            petId: petId,
            schedules: schedules,
            timeSlot: timeSlot,
            petName: petName,
            now: now,
          );

          scheduledCount += result['scheduled'] as int;
          immediateCount += result['immediate'] as int;
          missedCount += result['missed'] as int;
        } on Exception catch (e) {
          final error = 'Failed to schedule time slot $timeSlot: $e';
          errors.add(error);
          _devLog('ERROR: $error');
          // Continue processing other time slots
        }
      }

      _devLog(
        'Scheduling complete: $scheduledCount scheduled, '
        '$immediateCount immediate, $missedCount missed, '
        '${errors.length} errors',
      );

      // Update group summary to reflect current notification state
      await _updateGroupSummary(
        userId: userId,
        petId: petId,
        petName: petName,
      );

      return {
        'scheduled': scheduledCount,
        'immediate': immediateCount,
        'missed': missedCount,
        'errors': errors,
      };
    } on Exception catch (e, stackTrace) {
      _devLog('ERROR in scheduleAllForToday: $e');
      _devLog('Stack trace: $stackTrace');
      return {
        'scheduled': scheduledCount,
        'immediate': immediateCount,
        'missed': missedCount,
        'errors': [...errors, e.toString()],
      };
    }
  }

  /// Schedule a bundled notification for a time slot with one or more
  /// schedules.
  Future<Map<String, dynamic>> _scheduleNotificationForTimeSlot({
    required String userId,
    required String petId,
    required List<Schedule> schedules,
    required String timeSlot,
    required String petName,
    required DateTime now,
  }) async {
    var scheduledCount = 0;
    var immediateCount = 0;
    var missedCount = 0;

    if (schedules.isEmpty) {
      _devLog(
        'WARNING: _scheduleNotificationForTimeSlot called with empty schedules',
      );
      return {
        'scheduled': 0,
        'immediate': 0,
        'missed': 0,
      };
    }

    try {
      // Convert timeSlot to TZDateTime for today
      final scheduledTime = zonedDateTimeForToday(timeSlot, now);

      // Evaluate grace period
      final decision = evaluateGracePeriod(
        scheduledTime: scheduledTime,
        now: now,
      );

      // Generate bundled notification content
      final content = _generateBundledNotificationContent(
        schedules: schedules,
        kind: 'initial',
        petName: petName,
      );

      // Generate notification ID based on time slot (not schedule)
      final notificationId = generateTimeSlotNotificationId(
        userId: userId,
        petId: petId,
        timeSlot: timeSlot,
        kind: 'initial',
      );

      // Build payload with all schedule IDs (comma-separated)
      final scheduleIds = schedules.map((s) => s.id).join(',');
      final payload = jsonEncode({
        'type': 'treatment_reminder',
        'userId': userId,
        'petId': petId,
        'scheduleIds': scheduleIds, // Multiple schedules
        'timeSlot': timeSlot,
        'kind': 'initial',
        'treatmentTypes': schedules.map((s) => s.treatmentType.name).join(','),
      });

      // Generate group ID and thread identifier for pet grouping
      final groupId = 'pet_$petId';
      final threadIdentifier = 'pet_$petId';

      // Schedule or fire based on grace period decision
      if (decision == NotificationSchedulingDecision.scheduled) {
        // Schedule for future time
        try {
          await _plugin.showZoned(
            id: notificationId,
            title: content['title']!,
            body: content['body']!,
            scheduledDate: scheduledTime,
            channelId: content['channelId']!,
            payload: payload,
            groupId: groupId,
            threadIdentifier: threadIdentifier,
          );
          scheduledCount++;
          _devLog(
            'Scheduled bundled notification $notificationId for $timeSlot '
            '(${schedules.length} schedule(s))',
          );

          // Record in index - ONE ENTRY per time slot
          await _indexStore.putEntry(
            userId,
            petId,
            ScheduledNotificationEntry.create(
              notificationId: notificationId,
              scheduleId: schedules.first.id, // Representative
              treatmentType: schedules.first.treatmentType.name,
              timeSlotISO: timeSlot,
              kind: 'initial',
            ),
          );
        } on Exception catch (e) {
          NotificationErrorHandler.handleSchedulingError(
            context: null,
            operation: 'schedule_bundled_notification',
            error: e,
            userId: userId,
            petId: petId,
            scheduleId: schedules.first.id,
          );
          return {
            'scheduled': 0,
            'immediate': 0,
            'missed': 0,
          };
        }
      } else if (decision == NotificationSchedulingDecision.immediate) {
        // Fire immediately (within grace period)
        try {
          await _plugin.showZoned(
            id: notificationId,
            title: content['title']!,
            body: content['body']!,
            scheduledDate: tz.TZDateTime.now(tz.local),
            channelId: content['channelId']!,
            payload: payload,
            groupId: groupId,
            threadIdentifier: threadIdentifier,
          );
          immediateCount++;
          _devLog(
            'Fired immediate bundled notification for $timeSlot (grace period)',
          );

          // Record in index
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
        } on Exception catch (e) {
          _devLog('ERROR firing immediate bundled notification: $e');
        }
      } else {
        // missed - skip
        missedCount++;
        _devLog('Skipped time slot $timeSlot (missed)');
      }

      // Schedule follow-up notifications (also bundled)
      if (decision == NotificationSchedulingDecision.scheduled ||
          decision == NotificationSchedulingDecision.immediate) {
        try {
          final followupResult = await _scheduleFollowupForTimeSlot(
            userId: userId,
            petId: petId,
            schedules: schedules,
            timeSlot: timeSlot,
            petName: petName,
            initialScheduledTime: scheduledTime,
          );
          scheduledCount += followupResult['scheduled'] as int;
        } on Exception catch (e) {
          _devLog('ERROR scheduling bundled follow-up: $e');
        }
      }

      return {
        'scheduled': scheduledCount,
        'immediate': immediateCount,
        'missed': missedCount,
      };
    } on Exception catch (e, stackTrace) {
      _devLog('ERROR in _scheduleNotificationForTimeSlot: $e');
      _devLog('Stack trace: $stackTrace');
      return {
        'scheduled': 0,
        'immediate': 0,
        'missed': 0,
      };
    }
  }

  /// Schedule a bundled follow-up notification for multiple schedules at a
  /// time slot.
  Future<Map<String, dynamic>> _scheduleFollowupForTimeSlot({
    required String userId,
    required String petId,
    required List<Schedule> schedules,
    required String timeSlot,
    required String petName,
    required tz.TZDateTime initialScheduledTime,
  }) async {
    var scheduledCount = 0;

    try {
      // Calculate follow-up time
      final followupTime = initialScheduledTime
          .add(const Duration(hours: _defaultFollowupOffsetHours));

      // Generate bundled follow-up content
      final content = _generateBundledNotificationContent(
        schedules: schedules,
        kind: 'followup',
        petName: petName,
      );

      // Generate follow-up notification ID
      final followupId = generateTimeSlotNotificationId(
        userId: userId,
        petId: petId,
        timeSlot: timeSlot,
        kind: 'followup',
      );

      // Build payload
      final scheduleIds = schedules.map((s) => s.id).join(',');
      final payload = jsonEncode({
        'type': 'treatment_reminder',
        'userId': userId,
        'petId': petId,
        'scheduleIds': scheduleIds,
        'timeSlot': timeSlot,
        'kind': 'followup',
        'treatmentTypes': schedules.map((s) => s.treatmentType.name).join(','),
      });

      // Generate group ID
      final groupId = 'pet_$petId';
      final threadIdentifier = 'pet_$petId';

      // Schedule follow-up
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
      _devLog(
        'Scheduled bundled follow-up $followupId for $timeSlot at '
        '${followupTime.hour}:'
        '${followupTime.minute.toString().padLeft(2, '0')}',
      );

      // Record in index - one entry per time slot
      await _indexStore.putEntry(
        userId,
        petId,
        ScheduledNotificationEntry.create(
          notificationId: followupId,
          scheduleId: schedules.first.id, // Representative
          treatmentType: schedules.first.treatmentType.name,
          timeSlotISO: timeSlot,
          kind: 'followup',
        ),
      );

      return {'scheduled': scheduledCount};
    } on Exception catch (e) {
      _devLog('ERROR scheduling bundled follow-up: $e');
      return {'scheduled': 0};
    }
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

  /// Update the group summary notification for a pet.
  Future<void> _updateGroupSummary({
    required String userId,
    required String petId,
    required String petName,
  }) async {
    try {
      // Get all entries for the pet today
      final now = DateTime.now();
      final entries = await _indexStore.getEntriesForPet(userId, petId, now);

      // If no notifications, cancel the summary
      if (entries.isEmpty) {
        await _plugin.cancelGroupSummary(petId);
        _devLog('Canceled group summary for $petName (no notifications)');
        return;
      }

      // Categorize entries by treatment type
      final breakdown = NotificationIndexStore.categorizeByType(entries);
      final medicationCount = breakdown['medication'] ?? 0;
      final fluidCount = breakdown['fluid'] ?? 0;

      // Generate group ID and thread identifier for this pet
      final groupId = 'pet_$petId';
      final threadIdentifier = 'pet_$petId';

      // Show or update group summary
      await _plugin.showGroupSummary(
        petId: petId,
        petName: petName,
        medicationCount: medicationCount,
        fluidCount: fluidCount,
        groupId: groupId,
        threadIdentifier: threadIdentifier,
      );

      _devLog(
        'Updated group summary for $petName: '
        '$medicationCount medications, $fluidCount fluids',
      );
    } on Exception catch (e, stackTrace) {
      _devLog('ERROR updating group summary for pet $petId: $e');
      _devLog('Stack trace: $stackTrace');
      // Don't rethrow - summary update failure shouldn't block main operations
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
      final pendingIds = pendingNotifications.map((n) => n.id).toSet();

      _devLog('Found ${pendingNotifications.length} pending notifications');

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
      final scheduleResult = await _scheduleAllForTodayImpl(
        userId: userId,
        petId: petId,
      );

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

  /// Internal implementation of cancelForSchedule.
  Future<int> _cancelForScheduleImpl(
    String userId,
    String petId,
    String scheduleId,
  ) async {
    _devLog('cancelForSchedule called for schedule $scheduleId');

    try {
      // Get all index entries for this schedule today
      final entries = await _indexStore.getForToday(userId, petId);
      final scheduleEntries = entries
          .where((e) => e.scheduleId == scheduleId)
          .toList();

      _devLog('Found ${scheduleEntries.length} notifications to cancel');

      var canceledCount = 0;

      // Cancel each notification
      for (final entry in scheduleEntries) {
        try {
          await _plugin.cancel(entry.notificationId);
          await _indexStore.removeEntryBy(
            userId,
            petId,
            scheduleId,
            entry.timeSlotISO,
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

      _devLog('Canceled $canceledCount notifications for schedule $scheduleId');

      // Update group summary to reflect current notification state
      final profileState = _ref.read(profileProvider);
      final petName = profileState.primaryPet?.name ?? 'your pet';
      await _updateGroupSummary(
        userId: userId,
        petId: petId,
        petName: petName,
      );

      return canceledCount;
    } on Exception catch (e, stackTrace) {
      _devLog('ERROR in cancelForSchedule: $e');
      _devLog('Stack trace: $stackTrace');

      NotificationErrorHandler.handleSchedulingError(
        context: null,
        operation: 'cancel_for_schedule',
        error: e,
        userId: userId,
        petId: petId,
        scheduleId: scheduleId,
      );

      return 0;
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

  /// Log messages only in development flavor.
  void _devLog(String message) {
    if (FlavorConfig.isDevelopment) {
      debugPrint('[NotificationCoordinator] $message');
    }
  }
}
