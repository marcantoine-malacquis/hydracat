import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/core/config/flavor_config.dart';
import 'package:hydracat/features/notifications/models/scheduled_notification_entry.dart';
import 'package:hydracat/features/notifications/providers/notification_provider.dart';
import 'package:hydracat/features/notifications/services/notification_index_store.dart';
import 'package:hydracat/features/notifications/utils/notification_id.dart';
import 'package:hydracat/features/notifications/utils/scheduling_helpers.dart';
import 'package:hydracat/features/profile/models/schedule.dart';
import 'package:hydracat/providers/profile_provider.dart';
import 'package:timezone/timezone.dart' as tz;

/// Service for orchestrating treatment reminder notifications.
///
/// Responsibilities:
/// - Schedule notifications for today's active schedules
/// - Cancel notifications when treatments logged or schedules deleted
/// - Reschedule all notifications (idempotent recovery)
/// - Generate notification content (generic, privacy-first)
/// - Maintain notification index for reconciliation
///
/// Offline-first: Only reads from cached schedules, never triggers Firestore.
/// Idempotent: Safe to call schedule methods multiple times.
/// Timezone-aware: Handles DST transitions correctly.
///
/// Example usage:
/// ```dart
/// final service = ref.read(reminderServiceProvider);
/// final result = await service.scheduleAllForToday(userId, petId, ref);
/// ```
class ReminderService {
  /// Factory constructor to get the singleton instance
  factory ReminderService() => _instance ??= ReminderService._();

  /// Private unnamed constructor
  ReminderService._();

  static ReminderService? _instance;

  // Constants for follow-up scheduling
  static const int _defaultFollowupOffsetHours = 2;

  /// Schedule all reminders for today's active schedules.
  ///
  /// This is the main entry point for scheduling notifications. Call this:
  /// - On app startup (after authentication)
  /// - On app resume from background
  /// - After onboarding completion
  ///
  /// Algorithm:
  /// 1. Get cached schedules from profileProvider
  /// 2. Filter to active schedules for today
  /// 3. For each schedule, schedule initial + follow-up notifications
  /// 4. Record entries in notification index
  ///
  /// Parameters:
  /// - [userId]: Current user ID
  /// - [petId]: Primary pet ID
  /// - [ref]: Riverpod ref for accessing providers
  ///
  /// Returns: Map with scheduling results:
  ///   - 'scheduled': Number of notifications scheduled
  ///   - 'immediate': Number fired immediately (grace period)
  ///   - 'missed': Number skipped (past grace period)
  ///   - 'errors': List of error messages if any failures
  ///
  /// Returns early if cache is empty (cache-only policy).
  Future<Map<String, dynamic>> scheduleAllForToday(
    String userId,
    String petId,
    Ref ref,
  ) async {
    _devLog('scheduleAllForToday called for userId=$userId, petId=$petId');

    final now = DateTime.now();
    var scheduledCount = 0;
    var immediateCount = 0;
    var missedCount = 0;
    final errors = <String>[];

    try {
      // Get cached schedules from profileProvider
      final profileState = ref.read(profileProvider);
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

      // Schedule notifications for each active schedule
      for (final schedule in activeSchedulesForToday) {
        try {
          final result = await _scheduleNotificationsForSchedule(
            userId: userId,
            petId: petId,
            schedule: schedule,
            petName: petName,
            now: now,
            ref: ref,
          );

          scheduledCount += result['scheduled'] as int;
          immediateCount += result['immediate'] as int;
          missedCount += result['missed'] as int;
        } on Exception catch (e) {
          final error = 'Failed to schedule ${schedule.id}: $e';
          errors.add(error);
          _devLog('ERROR: $error');
          // Continue processing other schedules
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
        ref: ref,
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

  /// Schedule notifications for a single schedule.
  ///
  /// Call this when:
  /// - Creating a new schedule
  /// - Updating an existing schedule
  ///
  /// This method is idempotent: it first cancels any existing notifications
  /// for this schedule, then schedules new ones.
  ///
  /// Parameters:
  /// - [userId]: Current user ID
  /// - [petId]: Primary pet ID
  /// - [schedule]: Schedule to schedule notifications for
  /// - [ref]: Riverpod ref for accessing providers
  ///
  /// Returns: Map with scheduling results (same format as scheduleAllForToday)
  Future<Map<String, dynamic>> scheduleForSchedule(
    String userId,
    String petId,
    Schedule schedule,
    Ref ref,
  ) async {
    _devLog('scheduleForSchedule called for schedule ${schedule.id}');

    try {
      // First, cancel any existing notifications for this schedule (idempotent)
      await cancelForSchedule(userId, petId, schedule.id, ref);

      // Check if schedule is active and has reminders today
      final now = DateTime.now();
      if (!schedule.isActive || !schedule.hasReminderTimeToday(now)) {
        _devLog(
          'Schedule ${schedule.id} is inactive or not active today, skipping',
        );
        return {
          'scheduled': 0,
          'immediate': 0,
          'missed': 0,
          'errors': <String>[],
          'skipped': true,
        };
      }

      // Get pet name
      final profileState = ref.read(profileProvider);
      final petName = profileState.primaryPet?.name ?? 'your pet';

      // Schedule new notifications
      return await _scheduleNotificationsForSchedule(
        userId: userId,
        petId: petId,
        schedule: schedule,
        petName: petName,
        now: now,
        ref: ref,
      );
    } on Exception catch (e, stackTrace) {
      _devLog('ERROR in scheduleForSchedule: $e');
      _devLog('Stack trace: $stackTrace');
      return {
        'scheduled': 0,
        'immediate': 0,
        'missed': 0,
        'errors': [e.toString()],
      };
    }
  }

  /// Cancel all notifications for a schedule.
  ///
  /// Call this when:
  /// - Deleting a schedule
  /// - Before rescheduling a schedule (idempotent update)
  ///
  /// Parameters:
  /// - [userId]: Current user ID
  /// - [petId]: Primary pet ID
  /// - [scheduleId]: Schedule ID to cancel notifications for
  /// - [ref]: Riverpod ref for accessing providers
  ///
  /// Returns: Number of notifications canceled
  Future<int> cancelForSchedule(
    String userId,
    String petId,
    String scheduleId,
    Ref ref,
  ) async {
    _devLog('cancelForSchedule called for schedule $scheduleId');

    try {
      final plugin = ref.read(reminderPluginProvider);
      final indexStore = ref.read(notificationIndexStoreProvider);

      // Get all index entries for this schedule today
      final entries = await indexStore.getForToday(userId, petId);
      final scheduleEntries =
          entries.where((e) => e.scheduleId == scheduleId).toList();

      _devLog('Found ${scheduleEntries.length} notifications to cancel');

      var canceledCount = 0;

      // Cancel each notification
      for (final entry in scheduleEntries) {
        try {
          await plugin.cancel(entry.notificationId);
          await indexStore.removeEntryBy(
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
      final profileState = ref.read(profileProvider);
      final petName = profileState.primaryPet?.name ?? 'your pet';
      await _updateGroupSummary(
        userId: userId,
        petId: petId,
        petName: petName,
        ref: ref,
      );

      return canceledCount;
    } on Exception catch (e, stackTrace) {
      _devLog('ERROR in cancelForSchedule: $e');
      _devLog('Stack trace: $stackTrace');
      return 0;
    }
  }

  /// Cancel notifications for a specific time slot.
  ///
  /// Call this when a treatment is logged to cancel pending reminders
  /// (initial, follow-up, snooze) for that time slot.
  ///
  /// Parameters:
  /// - [userId]: Current user ID
  /// - [petId]: Primary pet ID
  /// - [scheduleId]: Schedule ID
  /// - [timeSlot]: Time slot in "HH:mm" format
  /// - [ref]: Riverpod ref for accessing providers
  ///
  /// Returns: Number of notifications canceled
  Future<int> cancelSlot(
    String userId,
    String petId,
    String scheduleId,
    String timeSlot,
    Ref ref,
  ) async {
    _devLog(
      'cancelSlot called for schedule $scheduleId, timeSlot $timeSlot',
    );

    try {
      final plugin = ref.read(reminderPluginProvider);
      final indexStore = ref.read(notificationIndexStoreProvider);

      // Get all index entries for this schedule + timeSlot
      final entries = await indexStore.getForToday(userId, petId);
      final slotEntries = entries.where((e) {
        return e.scheduleId == scheduleId && e.timeSlotISO == timeSlot;
      }).toList();

      _devLog('Found ${slotEntries.length} notifications to cancel for slot');

      var canceledCount = 0;

      // Cancel all kinds (initial, followup, snooze)
      for (final entry in slotEntries) {
        try {
          await plugin.cancel(entry.notificationId);
          await indexStore.removeEntryBy(
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

  /// Reschedule all notifications (idempotent reconciliation).
  ///
  /// Call this:
  /// - On app startup (if needed)
  /// - On date change (midnight rollover)
  /// - When recovering from errors
  ///
  /// Algorithm:
  /// 1. Get plugin's pending notifications
  /// 2. Get index entries for today
  /// 3. Reconcile (cancel orphans, reschedule missing)
  /// 4. Call scheduleAllForToday() to ensure complete coverage
  ///
  /// Parameters:
  /// - [userId]: Current user ID
  /// - [petId]: Primary pet ID
  /// - [ref]: Riverpod ref for accessing providers
  ///
  /// Returns: Map with reconciliation results:
  ///   - 'orphansCanceled': Number of orphan notifications canceled
  ///   - 'missingRescheduled': Number of missing notifications rescheduled
  ///   - 'scheduleResult': Result from scheduleAllForToday()
  Future<Map<String, dynamic>> rescheduleAll(
    String userId,
    String petId,
    Ref ref,
  ) async {
    _devLog('rescheduleAll called for userId=$userId, petId=$petId');

    try {
      final plugin = ref.read(reminderPluginProvider);
      final indexStore = ref.read(notificationIndexStoreProvider);

      // Get pending notifications from plugin
      final pendingNotifications = await plugin.pendingNotificationRequests();
      final pendingIds = pendingNotifications.map((n) => n.id).toSet();

      _devLog('Found ${pendingNotifications.length} pending notifications');

      // Get index entries for today
      final indexEntries = await indexStore.getForToday(userId, petId);
      final indexedIds = indexEntries.map((e) => e.notificationId).toSet();

      _devLog('Found ${indexEntries.length} indexed notifications');

      // Find orphans (in plugin but not in index) and cancel them
      final orphanIds = pendingIds.difference(indexedIds);
      var orphansCanceled = 0;

      for (final orphanId in orphanIds) {
        try {
          await plugin.cancel(orphanId);
          orphansCanceled++;
          _devLog('Canceled orphan notification $orphanId');
        } on Exception catch (e) {
          _devLog('ERROR canceling orphan notification $orphanId: $e');
        }
      }

      // Find missing (in index but not in plugin)
      final missingIds = indexedIds.difference(pendingIds);
      _devLog('Found ${missingIds.length} missing notifications in plugin');

      // Note: We don't try to reschedule individual missing notifications here
      // because we don't have enough context. Instead, we rely on
      // scheduleAllForToday() to rebuild from schedules.

      // Clear today's index to start fresh
      await indexStore.clearForDate(userId, petId, DateTime.now());

      // Reschedule all from cached schedules
      final scheduleResult = await scheduleAllForToday(userId, petId, ref);

      _devLog(
        'Reconciliation complete: $orphansCanceled orphans canceled, '
        'rescheduled all from cache',
      );

      return {
        'orphansCanceled': orphansCanceled,
        'missingCount': missingIds.length,
        'scheduleResult': scheduleResult,
      };
    } on Exception catch (e, stackTrace) {
      _devLog('ERROR in rescheduleAll: $e');
      _devLog('Stack trace: $stackTrace');
      return {
        'orphansCanceled': 0,
        'missingCount': 0,
        'errors': [e.toString()],
      };
    }
  }

  /// Internal: Schedule notifications for a single schedule.
  ///
  /// This handles scheduling initial + follow-up notifications for all
  /// reminder times in the schedule.
  ///
  /// Enforces per-pet notification limits (50 max). If limit is reached,
  /// uses rolling 24h window strategy (only schedules next 24h).
  Future<Map<String, dynamic>> _scheduleNotificationsForSchedule({
    required String userId,
    required String petId,
    required Schedule schedule,
    required String petName,
    required DateTime now,
    required Ref ref,
  }) async {
    final indexStore = ref.read(notificationIndexStoreProvider);

    var scheduledCount = 0;
    var immediateCount = 0;
    var missedCount = 0;
    var skippedDueToLimit = 0;

    // Check current notification count for limit enforcement
    final currentCount = await indexStore.getCountForPet(userId, petId, now);

    // Log warnings and apply limits
    if (currentCount >= 50) {
      _devLog(
        '⚠️ LIMIT REACHED: Pet $petId has $currentCount/50 notifications. '
        'Applying rolling 24h window.',
      );
      // TODO(Phase7): Track 'notification_limit_reached' analytics event
      // await ref.read(analyticsProvider).logEvent(
      //   name: 'notification_limit_reached',
      //   parameters: {
      //     'petId': petId,
      //     'currentCount': currentCount,
      //     'scheduleId': schedule.id,
      //   },
      // );
    } else if (currentCount >= 40) {
      _devLog(
        '⚠️ LIMIT WARNING: Pet $petId has $currentCount/50 notifications '
        '(80% threshold reached).',
      );
      // TODO(Phase7): Track 'notification_limit_warning' analytics event
      // await ref.read(analyticsProvider).logEvent(
      //   name: 'notification_limit_warning',
      //   parameters: {
      //     'petId': petId,
      //     'currentCount': currentCount,
      //   },
      // );
    }

    // Get today's reminder times for this schedule
    final todaysReminderTimes = schedule.todaysReminderTimes(now).toList();

    _devLog(
      'Schedule ${schedule.id} has ${todaysReminderTimes.length} '
      'reminder times today (current count: $currentCount/50)',
    );

    // Calculate cutoff time for rolling 24h window (now + 24 hours)
    final cutoffTime = now.add(const Duration(hours: 24));

    // Schedule notifications for each reminder time
    for (final reminderTime in todaysReminderTimes) {
      try {
        // Check if we need to apply rolling 24h window
        if (currentCount >= 50) {
          // Build scheduled time for this reminder
          final scheduledTime = DateTime(
            now.year,
            now.month,
            now.day,
            reminderTime.hour,
            reminderTime.minute,
          );

          // Skip if beyond 24h window
          if (scheduledTime.isAfter(cutoffTime)) {
            skippedDueToLimit++;
            _devLog(
              'Skipped notification at ${reminderTime.hour}:'
              '${reminderTime.minute.toString().padLeft(2, '0')} '
              '(beyond 24h window due to limit)',
            );
            continue;
          }
        }

        // Extract time slot in "HH:mm" format
        final timeSlot = '${reminderTime.hour.toString().padLeft(2, '0')}:'
            '${reminderTime.minute.toString().padLeft(2, '0')}';

        final result = await _scheduleNotificationForSlot(
          userId: userId,
          petId: petId,
          schedule: schedule,
          timeSlot: timeSlot,
          petName: petName,
          now: now,
          ref: ref,
        );

        scheduledCount += result['scheduled'] as int;
        immediateCount += result['immediate'] as int;
        missedCount += result['missed'] as int;
      } on Exception catch (e) {
        _devLog('ERROR scheduling notification for time $reminderTime: $e');
        // Continue processing other times
      }
    }

    if (skippedDueToLimit > 0) {
      _devLog(
        'Skipped $skippedDueToLimit notifications due to 50/pet limit. '
        'These will be rescheduled at next midnight rollover.',
      );
    }

    return {
      'scheduled': scheduledCount,
      'immediate': immediateCount,
      'missed': missedCount,
      'skippedDueToLimit': skippedDueToLimit,
      'errors': <String>[],
    };
  }

  /// Internal: Schedule initial + follow-up notifications for a single
  /// time slot.
  Future<Map<String, dynamic>> _scheduleNotificationForSlot({
    required String userId,
    required String petId,
    required Schedule schedule,
    required String timeSlot,
    required String petName,
    required DateTime now,
    required Ref ref,
  }) async {
    final plugin = ref.read(reminderPluginProvider);
    final indexStore = ref.read(notificationIndexStoreProvider);

    var scheduledCount = 0;
    var immediateCount = 0;
    var missedCount = 0;

    try {
      // Convert timeSlot to TZDateTime for today
      final scheduledTime = zonedDateTimeForToday(timeSlot, now);

      // Evaluate grace period
      final decision = evaluateGracePeriod(
        scheduledTime: scheduledTime,
        now: now,
      );

      // Determine treatment type
      final treatmentType = schedule.treatmentType.name;

      // Generate notification content (initial)
      final content = _generateNotificationContent(
        treatmentType: treatmentType,
        kind: 'initial',
        petName: petName,
      );

      // Generate notification ID (deterministic)
      final notificationId = generateNotificationId(
        userId: userId,
        petId: petId,
        scheduleId: schedule.id,
        timeSlot: timeSlot,
        kind: 'initial',
      );

      // Build payload
      final payload = _buildPayload(
        userId: userId,
        petId: petId,
        scheduleId: schedule.id,
        timeSlot: timeSlot,
        kind: 'initial',
        treatmentType: treatmentType,
      );

      // Generate group ID and thread identifier for pet grouping
      final groupId = 'pet_$petId';
      final threadIdentifier = 'pet_$petId';

      // Schedule or fire based on grace period decision
      if (decision == NotificationSchedulingDecision.scheduled) {
        // Schedule for future
        await plugin.showZoned(
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
        _devLog('Scheduled initial notification for $timeSlot');
      } else if (decision == NotificationSchedulingDecision.immediate) {
        // Fire immediately (within grace period)
        // Note: For immediate notifications, we use a regular show() call
        // but since flutter_local_notifications doesn't have a non-scheduled
        // show method, we schedule it for "now"
        await plugin.showZoned(
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
        _devLog('Fired immediate notification for $timeSlot (grace period)');
      } else {
        // Missed (past grace period)
        missedCount++;
        _devLog('Skipped missed notification for $timeSlot');
        // Don't schedule, but we could track this for analytics/UI
        return {
          'scheduled': 0,
          'immediate': 0,
          'missed': 1,
        };
      }

      // Record in index (for both scheduled and immediate)
      await indexStore.putEntry(
        userId,
        petId,
        ScheduledNotificationEntry(
          notificationId: notificationId,
          scheduleId: schedule.id,
          treatmentType: treatmentType,
          timeSlotISO: timeSlot,
          kind: 'initial',
        ),
      );

      // Schedule follow-up notification
      final followupResult = await _scheduleFollowupNotification(
        userId: userId,
        petId: petId,
        schedule: schedule,
        timeSlot: timeSlot,
        initialTime: scheduledTime,
        petName: petName,
        ref: ref,
      );

      scheduledCount += followupResult['scheduled'] as int;

      return {
        'scheduled': scheduledCount,
        'immediate': immediateCount,
        'missed': missedCount,
      };
    } on Exception catch (e, stackTrace) {
      _devLog('ERROR in _scheduleNotificationForSlot: $e');
      _devLog('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Internal: Schedule follow-up notification.
  Future<Map<String, dynamic>> _scheduleFollowupNotification({
    required String userId,
    required String petId,
    required Schedule schedule,
    required String timeSlot,
    required tz.TZDateTime initialTime,
    required String petName,
    required Ref ref,
  }) async {
    final plugin = ref.read(reminderPluginProvider);
    final indexStore = ref.read(notificationIndexStoreProvider);

    try {
      // Calculate follow-up time (handles late-night edge case)
      final followupTime = calculateFollowupTime(
        initialTime: initialTime,
        followupOffsetHours: _defaultFollowupOffsetHours,
      );

      final treatmentType = schedule.treatmentType.name;

      // Generate follow-up content
      final content = _generateNotificationContent(
        treatmentType: treatmentType,
        kind: 'followup',
        petName: petName,
      );

      // Generate follow-up notification ID
      final followupId = generateNotificationId(
        userId: userId,
        petId: petId,
        scheduleId: schedule.id,
        timeSlot: timeSlot,
        kind: 'followup',
      );

      // Build payload
      final payload = _buildPayload(
        userId: userId,
        petId: petId,
        scheduleId: schedule.id,
        timeSlot: timeSlot,
        kind: 'followup',
        treatmentType: treatmentType,
      );

      // Generate group ID and thread identifier for pet grouping
      final groupId = 'pet_$petId';
      final threadIdentifier = 'pet_$petId';

      // Schedule follow-up
      await plugin.showZoned(
        id: followupId,
        title: content['title']!,
        body: content['body']!,
        scheduledDate: followupTime,
        channelId: content['channelId']!,
        payload: payload,
        groupId: groupId,
        threadIdentifier: threadIdentifier,
      );

      // Record in index
      await indexStore.putEntry(
        userId,
        petId,
        ScheduledNotificationEntry(
          notificationId: followupId,
          scheduleId: schedule.id,
          treatmentType: treatmentType,
          timeSlotISO: timeSlot,
          kind: 'followup',
        ),
      );

      _devLog(
        'Scheduled follow-up notification for $timeSlot at $followupTime',
      );

      return {
        'scheduled': 1,
        'immediate': 0,
        'missed': 0,
      };
    } on Exception catch (e, stackTrace) {
      _devLog('ERROR scheduling follow-up: $e');
      _devLog('Stack trace: $stackTrace');
      return {
        'scheduled': 0,
        'immediate': 0,
        'missed': 0,
      };
    }
  }

  /// Internal: Generate notification content based on type and kind.
  ///
  /// Returns a map with keys: title, body, channelId
  ///
  /// Privacy-first: All content is generic (no medication names, dosages, etc.)
  Map<String, String> _generateNotificationContent({
    required String treatmentType,
    required String kind,
    required String petName,
  }) {
    // Note: In production, we should use l10n (AppLocalizations)
    // For now, using hardcoded English strings that match l10n keys

    if (kind == 'initial') {
      if (treatmentType == 'medication') {
        return {
          'title': 'Medication reminder',
          'body': "Time for $petName's medication",
          'channelId': 'medication_reminders',
        };
      } else {
        // fluid
        return {
          'title': 'Fluid therapy reminder',
          'body': "Time for $petName's fluid therapy",
          'channelId': 'fluid_reminders',
        };
      }
    } else if (kind == 'followup') {
      return {
        'title': 'Treatment reminder',
        'body': '$petName may still need their treatment',
        'channelId': treatmentType == 'medication'
            ? 'medication_reminders'
            : 'fluid_reminders',
      };
    } else {
      // snooze
      return {
        'title': 'Treatment reminder (snoozed)',
        'body': "Time for $petName's treatment",
        'channelId': treatmentType == 'medication'
            ? 'medication_reminders'
            : 'fluid_reminders',
      };
    }
  }

  /// Internal: Build JSON payload for notification tap handling.
  String _buildPayload({
    required String userId,
    required String petId,
    required String scheduleId,
    required String timeSlot,
    required String kind,
    required String treatmentType,
  }) {
    final payloadMap = {
      'userId': userId,
      'petId': petId,
      'scheduleId': scheduleId,
      'timeSlot': timeSlot,
      'kind': kind,
      'treatmentType': treatmentType,
    };

    return json.encode(payloadMap);
  }

  /// Update the group summary notification for a pet.
  ///
  /// This method should be called after scheduling or canceling notifications
  /// to keep the group summary in sync with the current notification state.
  ///
  /// Algorithm:
  /// 1. Get all notification entries for the pet from index
  /// 2. If no entries, cancel the summary notification
  /// 3. Otherwise, categorize entries by type (medication/fluid)
  /// 4. Create or update the group summary notification with breakdown
  ///
  /// The summary uses a deterministic ID based on petId for idempotent updates.
  Future<void> _updateGroupSummary({
    required String userId,
    required String petId,
    required String petName,
    required Ref ref,
  }) async {
    try {
      final plugin = ref.read(reminderPluginProvider);
      final indexStore = ref.read(notificationIndexStoreProvider);

      // Get all entries for the pet today
      final now = DateTime.now();
      final entries = await indexStore.getEntriesForPet(userId, petId, now);

      // If no notifications, cancel the summary
      if (entries.isEmpty) {
        await plugin.cancelGroupSummary(petId);
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
      await plugin.showGroupSummary(
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

  /// Calculate priority score for a notification entry.
  ///
  /// Priority scoring algorithm:
  /// - Base score by kind:
  ///   - initial: 100 (highest priority - first reminder)
  ///   - followup: 50 (medium priority - second reminder)
  ///   - snooze: 25 (lower priority - user-requested delay)
  /// - Type bonus:
  ///   - medication: +10 (medical treatment is higher priority)
  ///   - fluid: +5 (important but slightly lower than medication)
  /// - Time proximity bonus (how soon the notification fires):
  ///   - Within next hour: +20
  ///   - Within next 3 hours: +10
  ///   - Within next 6 hours: +5
  ///   - Beyond 6 hours: 0
  ///
  /// Higher scores = higher priority (scheduled first).
  ///
  /// Example: An initial medication notification firing in 30 minutes
  /// would score: 100 (initial) + 10 (medication) + 20 (within 1h) = 130
  ///
  /// NOTE: This method is currently reserved for future priority-based
  /// scheduling optimization. When implemented, it will be used to sort
  /// notifications across all schedules and prioritize which ones to
  /// schedule when approaching system limits.
  // ignore: unused_element
  int _calculatePriority(
    ScheduledNotificationEntry entry,
    DateTime now,
  ) {
    var score = 0;

    // Base score by kind
    switch (entry.kind) {
      case 'initial':
        score += 100;
      case 'followup':
        score += 50;
      case 'snooze':
        score += 25;
      default:
        score += 0;
    }

    // Type bonus
    switch (entry.treatmentType) {
      case 'medication':
        score += 10;
      case 'fluid':
        score += 5;
      default:
        score += 0;
    }

    // Time proximity bonus
    // Parse timeSlotISO ("HH:mm") and calculate hours until notification
    try {
      final timeParts = entry.timeSlotISO.split(':');
      if (timeParts.length == 2) {
        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);

        // Create scheduled time for today
        final scheduledTime = DateTime(
          now.year,
          now.month,
          now.day,
          hour,
          minute,
        );

        final hoursUntil = scheduledTime.difference(now).inMinutes / 60;

        if (hoursUntil <= 1) {
          score += 20;
        } else if (hoursUntil <= 3) {
          score += 10;
        } else if (hoursUntil <= 6) {
          score += 5;
        }
      }
    } on FormatException {
      // Invalid time format, skip time proximity bonus
      _devLog(
        'WARNING: Invalid time format for priority calculation: '
        '${entry.timeSlotISO}',
      );
    }

    return score;
  }

  /// Log messages only in development flavor
  void _devLog(String message) {
    if (FlavorConfig.isDevelopment) {
      debugPrint('[ReminderService] $message');
    }
  }
}
