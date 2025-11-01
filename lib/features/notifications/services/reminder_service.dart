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
/// ## PRIVACY DESIGN PRINCIPLE
///
/// All notification content is intentionally **generic** to protect user
/// privacy. Notifications may be visible on lock screens, in notification
/// centers, and to others who can see the device screen.
///
/// ### ❌ NEVER include in notifications:
/// - Medication names (e.g., "Benazepril", "Enalapril")
/// - Dosages (e.g., "5mg", "10mg")
/// - Fluid volumes (e.g., "100ml", "150ml subcutaneous")
/// - Injection sites (e.g., "left shoulder")
/// - Any other medical details
/// - Sensitive health information
///
/// ### ✅ DO include in notifications:
/// - Pet name (user's own data, already visible on device)
/// - Generic treatment type ("medication" or "fluid therapy")
/// - Time-of-day context ("morning", "evening")
/// - Encouraging/supportive language
/// - General reminders without specifics
///
/// ### Rationale:
/// - **Lock screen visibility**: Others may see notification previews
/// - **Medical privacy**: Health data is sensitive, even for pets
/// - **User agency**: Users can choose to share or not share their pet's
///   treatment details
/// - **Compliance**: GDPR/HIPAA-aligned approach (even though pets aren't
///   covered, we respect the same principles)
/// - **Social considerations**: Users may not want neighbors/visitors to know
///   about their pet's chronic condition
///
/// For detailed treatment information, users must unlock their device and
/// open the app. This design ensures privacy while still providing helpful
/// reminders.
///
/// ### Example Notification Content:
/// ```text
/// ✅ Good: "Time for Luna's morning medication"
/// ❌ Bad:  "Give Luna 5mg Benazepril now"
///
/// ✅ Good: "Reminder: Fluid therapy for Max"
/// ❌ Bad:  "Administer 150ml subcutaneous fluids to Max's left shoulder"
/// ```
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
    WidgetRef ref,
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
    WidgetRef ref,
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
    WidgetRef ref,
  ) async {
    _devLog('cancelForSchedule called for schedule $scheduleId');

    try {
      final plugin = ref.read(reminderPluginProvider);
      final indexStore = ref.read(notificationIndexStoreProvider);

      // Get all index entries for this schedule today
      final entries = await indexStore.getForToday(userId, petId);
      final scheduleEntries = entries
          .where((e) => e.scheduleId == scheduleId)
          .toList();

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
    WidgetRef ref,
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
    WidgetRef ref,
  ) async {
    _devLog('rescheduleAll called for userId=$userId, petId=$petId');

    try {
      final plugin = ref.read(reminderPluginProvider);
      final indexStore = ref.read(notificationIndexStoreProvider);

      // Get pending notifications from plugin
      final pendingNotifications = await plugin.pendingNotificationRequests();
      final pendingIds = pendingNotifications.map((n) => n.id).toSet();

      _devLog('Found ${pendingNotifications.length} pending notifications');

      // Get index entries for today (with plugin for automatic
      // rebuild on corruption)
      final analyticsService = ref.read(analyticsServiceDirectProvider);
      final indexEntries = await indexStore.getForToday(
        userId,
        petId,
        analyticsService: analyticsService,
        plugin: plugin,
      );
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

      // Reschedule all treatment reminders from cached schedules
      final scheduleResult = await scheduleAllForToday(userId, petId, ref);

      // Cancel and reschedule weekly summary notification
      await cancelWeeklySummary(userId, petId, ref);
      final weeklySummaryResult = await scheduleWeeklySummary(
        userId,
        petId,
        ref,
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
    required WidgetRef ref,
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
      // Track 'notification_limit_reached' analytics event
      try {
        final analyticsService = ref.read(analyticsServiceDirectProvider);
        await analyticsService.trackNotificationLimitReached(
          petId: petId,
          currentCount: currentCount,
          scheduleId: schedule.id,
        );
      } on Exception catch (e) {
        _devLog('Analytics tracking failed: $e');
      }
    } else if (currentCount >= 40) {
      _devLog(
        '⚠️ LIMIT WARNING: Pet $petId has $currentCount/50 notifications '
        '(80% threshold reached).',
      );
      // Track 'notification_limit_warning' analytics event
      try {
        final analyticsService = ref.read(analyticsServiceDirectProvider);
        await analyticsService.trackNotificationLimitWarning(
          petId: petId,
          currentCount: currentCount,
        );
      } on Exception catch (e) {
        _devLog('Analytics tracking failed: $e');
      }
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
        final timeSlot =
            '${reminderTime.hour.toString().padLeft(2, '0')}:'
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
    required WidgetRef ref,
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
        try {
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

          // Record in index only after successful scheduling
          try {
            await indexStore.putEntry(
              userId,
              petId,
              ScheduledNotificationEntry.create(
                notificationId: notificationId,
                scheduleId: schedule.id,
                treatmentType: treatmentType,
                timeSlotISO: timeSlot,
                kind: 'initial',
              ),
            );
          } on Exception catch (e) {
            NotificationErrorHandler.handleSchedulingError(
              context: null,
              operation: 'index_update_initial',
              error: e,
              userId: userId,
              petId: petId,
              scheduleId: schedule.id,
            );
          }
        } on Exception catch (e) {
          NotificationErrorHandler.handleSchedulingError(
            context: null,
            operation: 'schedule_initial_notification',
            error: e,
            userId: userId,
            petId: petId,
            scheduleId: schedule.id,
          );
          // Continue to next time slot - silent failure
          return {
            'scheduled': 0,
            'immediate': 0,
            'missed': 0,
            'errors': ['Failed to schedule notification for $timeSlot'],
          };
        }
      } else if (decision == NotificationSchedulingDecision.immediate) {
        // Fire immediately (within grace period)
        // Note: For immediate notifications, we use a regular show() call
        // but since flutter_local_notifications doesn't have a non-scheduled
        // show method, we schedule it for "now"
        try {
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

          // Record in index only after successful scheduling
          try {
            await indexStore.putEntry(
              userId,
              petId,
              ScheduledNotificationEntry.create(
                notificationId: notificationId,
                scheduleId: schedule.id,
                treatmentType: treatmentType,
                timeSlotISO: timeSlot,
                kind: 'initial',
              ),
            );
          } on Exception catch (e) {
            NotificationErrorHandler.handleSchedulingError(
              context: null,
              operation: 'index_update_immediate',
              error: e,
              userId: userId,
              petId: petId,
              scheduleId: schedule.id,
            );
          }
        } on Exception catch (e) {
          NotificationErrorHandler.handleSchedulingError(
            context: null,
            operation: 'schedule_immediate_notification',
            error: e,
            userId: userId,
            petId: petId,
            scheduleId: schedule.id,
          );
          // Continue to next time slot - silent failure
          return {
            'scheduled': 0,
            'immediate': 0,
            'missed': 0,
            'errors': ['Failed to fire immediate notification for $timeSlot'],
          };
        }
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

      // Report to Crashlytics but don't rethrow (silent failure)
      NotificationErrorHandler.handleSchedulingError(
        context: null,
        operation: 'schedule_notification_for_slot',
        error: e,
        userId: userId,
        petId: petId,
        scheduleId: schedule.id,
      );

      // Return error result instead of rethrowing
      return {
        'scheduled': 0,
        'immediate': 0,
        'missed': 0,
        'errors': [e.toString()],
      };
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
    required WidgetRef ref,
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
      try {
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

        // Record in index only after successful scheduling
        try {
          await indexStore.putEntry(
            userId,
            petId,
            ScheduledNotificationEntry.create(
              notificationId: followupId,
              scheduleId: schedule.id,
              treatmentType: treatmentType,
              timeSlotISO: timeSlot,
              kind: 'followup',
            ),
          );
        } on Exception catch (e) {
          NotificationErrorHandler.handleSchedulingError(
            context: null,
            operation: 'index_update_followup',
            error: e,
            userId: userId,
            petId: petId,
            scheduleId: schedule.id,
          );
        }

        _devLog(
          'Scheduled follow-up notification for $timeSlot at $followupTime',
        );

        return {
          'scheduled': 1,
          'immediate': 0,
          'missed': 0,
        };
      } on Exception catch (e) {
        NotificationErrorHandler.handleSchedulingError(
          context: null,
          operation: 'schedule_followup_notification',
          error: e,
          userId: userId,
          petId: petId,
          scheduleId: schedule.id,
        );
        return {
          'scheduled': 0,
          'immediate': 0,
          'missed': 0,
        };
      }
    } on Exception catch (e, stackTrace) {
      _devLog('ERROR scheduling follow-up: $e');
      _devLog('Stack trace: $stackTrace');

      NotificationErrorHandler.handleSchedulingError(
        context: null,
        operation: 'schedule_followup_notification',
        error: e,
        userId: userId,
        petId: petId,
        scheduleId: schedule.id,
      );

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
    final l10n = _getLocalizations();

    // Prefer A11y long-form strings with petName
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
    } else if (kind == 'followup') {
      return {
        'title': l10n.notificationFollowupTitleA11y(petName),
        'body': l10n.notificationFollowupBodyA11y(petName),
        'channelId': treatmentType == 'medication'
            ? 'medication_reminders'
            : 'fluid_reminders',
      };
    } else {
      // snooze
      return {
        'title': l10n.notificationSnoozeTitleA11y(petName),
        'body': l10n.notificationSnoozeBodyA11y(petName),
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
    required WidgetRef ref,
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

  /// Snooze the current notification by 15 minutes.
  ///
  /// This method is called when the user taps the "Snooze 15 min" action button
  /// on a notification. It validates the snooze operation, cancels existing
  /// notifications for the time slot, and schedules a new notification 15
  /// minutes from now.
  ///
  /// Algorithm:
  /// 1. Parse and validate payload (userId, petId, scheduleId, timeSlot, kind,
  ///    treatmentType)
  /// 2. Check if snoozeEnabled in user notification settings
  /// 3. Validate notification kind (only 'initial' or 'followup' can be
  ///    snoozed, not 'snooze')
  /// 4. Cancel all notifications for this time slot (initial + followup) using
  ///    cancelSlot
  /// 5. Calculate snooze time (now + 15 minutes)
  /// 6. Generate snooze notification content
  /// 7. Schedule snooze notification via plugin with kind='snooze'
  /// 8. Add snooze notification to index
  /// 9. Track analytics event (reminder_snoozed)
  /// 10. Return success/failure map
  ///
  /// Parameters:
  /// - [payload]: JSON string from notification with userId, petId, scheduleId,
  ///              timeSlot, kind, treatmentType
  /// - [ref]: Riverpod ref for accessing providers and services
  ///
  /// Returns: Map with result:
  ///   - 'success': true/false
  ///   - 'reason': Failure reason if success=false
  ///   - 'snoozedUntil': ISO8601 timestamp of snooze notification time (if
  ///     success=true)
  ///
  /// Failure reasons:
  /// - 'snooze_disabled': User has snoozeEnabled=false in settings
  /// - 'invalid_payload': Payload missing required fields or malformed JSON
  /// - 'invalid_kind': Notification kind is 'snooze' (can't snooze a snooze)
  /// - 'settings_not_loaded': NotificationSettings provider unavailable
  /// - 'scheduling_failed': Plugin.showZoned threw exception
  ///
  /// Example usage:
  /// ```dart
  /// final result = await service.snoozeCurrent(payload, ref);
  /// if (result['success'] == true) {
  ///   print('Snoozed until: ${result['snoozedUntil']}');
  /// } else {
  ///   print('Snooze failed: ${result['reason']}');
  /// }
  /// ```
  ///
  /// Note: This method fails silently (returns error map) rather than throwing
  /// exceptions, as notification action button handlers should be non-blocking.
  Future<Map<String, dynamic>> snoozeCurrent(
    String payload,
    WidgetRef ref,
  ) async {
    _devLog('');
    _devLog('═══════════════════════════════════════════════════════');
    _devLog('⏰ SNOOZE CURRENT - snoozeCurrent() called');
    _devLog('═══════════════════════════════════════════════════════');
    _devLog('Timestamp: ${DateTime.now().toIso8601String()}');
    _devLog('Payload: $payload');
    _devLog('');

    try {
      // Step 1: Parse and validate payload
      _devLog('Step 1: Parsing payload JSON...');
      final payloadMap = json.decode(payload) as Map<String, dynamic>;
      _devLog('✅ JSON parsed successfully');

      final userId = payloadMap['userId'] as String?;
      final petId = payloadMap['petId'] as String?;
      final scheduleId = payloadMap['scheduleId'] as String?;
      final timeSlot = payloadMap['timeSlot'] as String?;
      final kind = payloadMap['kind'] as String?;
      final treatmentType = payloadMap['treatmentType'] as String?;

      _devLog('  userId: $userId');
      _devLog('  petId: $petId');
      _devLog('  scheduleId: $scheduleId');
      _devLog('  timeSlot: $timeSlot');
      _devLog('  kind: $kind');
      _devLog('  treatmentType: $treatmentType');

      // Validate all required fields
      if (userId == null ||
          petId == null ||
          scheduleId == null ||
          timeSlot == null ||
          kind == null ||
          treatmentType == null) {
        _devLog('❌ FAILED: Invalid payload - missing required fields');
        _devLog('═══════════════════════════════════════════════════════');
        return {
          'success': false,
          'reason': 'invalid_payload',
        };
      }
      _devLog('✅ All required fields present');

      // Step 2: Check if snooze is enabled in user settings
      _devLog('');
      _devLog('Step 2: Checking snooze settings...');
      try {
        final settings = ref.read(
          notificationSettingsProvider(userId),
        );
        _devLog('  snoozeEnabled: ${settings.snoozeEnabled}');

        if (!settings.snoozeEnabled) {
          _devLog('❌ FAILED: Snooze is disabled in user settings');
          _devLog('═══════════════════════════════════════════════════════');
          return {
            'success': false,
            'reason': 'snooze_disabled',
          };
        }
        _devLog('✅ Snooze is enabled');
      } on Exception catch (e) {
        _devLog('❌ FAILED: Could not read notification settings: $e');
        _devLog('═══════════════════════════════════════════════════════');
        return {
          'success': false,
          'reason': 'settings_not_loaded',
        };
      }

      // Step 3: Validate notification kind (only initial/followup can snooze)
      _devLog('');
      _devLog('Step 3: Validating notification kind...');
      if (kind != 'initial' && kind != 'followup') {
        _devLog(
          "❌ FAILED: Invalid kind '$kind' - only 'initial' or 'followup' "
          'can be snoozed',
        );
        _devLog('═══════════════════════════════════════════════════════');
        return {
          'success': false,
          'reason': 'invalid_kind',
        };
      }
      _devLog("✅ Kind '$kind' is valid for snoozing");

      // Step 4: Cancel existing notifications for this time slot
      _devLog('');
      _devLog('Step 4: Canceling existing notifications for time slot...');
      final canceledCount = await cancelSlot(
        userId,
        petId,
        scheduleId,
        timeSlot,
        ref,
      );
      _devLog(
        '✅ Canceled $canceledCount notification(s) '
        '(initial + followup if present)',
      );

      // Step 5: Calculate snooze time
      _devLog('');
      _devLog('Step 5: Calculating snooze time...');
      final now = DateTime.now();
      final snoozeTime = now.add(const Duration(minutes: 15));
      final snoozeTZ = tz.TZDateTime.from(snoozeTime, tz.local);
      _devLog('  Current time: ${now.toIso8601String()}');
      _devLog('  Snooze time: ${snoozeTime.toIso8601String()}');
      _devLog('  Snooze TZ: $snoozeTZ');

      // Step 6: Generate snooze notification content
      _devLog('');
      _devLog('Step 6: Generating snooze notification content...');
      final profileState = ref.read(profileProvider);
      final petName = profileState.primaryPet?.name ?? 'your pet';
      _devLog('  Pet name: $petName');

      final content = _generateNotificationContent(
        treatmentType: treatmentType,
        kind: 'snooze',
        petName: petName,
      );
      _devLog('  Title: ${content['title']}');
      _devLog('  Body: ${content['body']}');
      _devLog('  Channel: ${content['channelId']}');

      // Step 7: Generate snooze notification ID and payload
      _devLog('');
      _devLog('Step 7: Generating snooze notification ID...');
      final snoozeId = generateNotificationId(
        userId: userId,
        petId: petId,
        scheduleId: scheduleId,
        timeSlot: timeSlot,
        kind: 'snooze',
      );
      _devLog('  Snooze notification ID: $snoozeId');

      final snoozePayload = _buildPayload(
        userId: userId,
        petId: petId,
        scheduleId: scheduleId,
        timeSlot: timeSlot,
        kind: 'snooze',
        treatmentType: treatmentType,
      );

      // Step 8: Schedule snooze notification
      _devLog('');
      _devLog('Step 8: Scheduling snooze notification...');
      final plugin = ref.read(reminderPluginProvider);
      final groupId = 'pet_$petId';
      final threadIdentifier = 'pet_$petId';

      try {
        await plugin.showZoned(
          id: snoozeId,
          title: content['title']!,
          body: content['body']!,
          scheduledDate: snoozeTZ,
          channelId: content['channelId']!,
          payload: snoozePayload,
          groupId: groupId,
          threadIdentifier: threadIdentifier,
        );
        _devLog('✅ Snooze notification scheduled successfully');
      } on Exception catch (e) {
        _devLog('❌ FAILED: Could not schedule snooze notification: $e');
        _devLog('═══════════════════════════════════════════════════════');
        return {
          'success': false,
          'reason': 'scheduling_failed',
        };
      }

      // Step 9: Add snooze notification to index
      _devLog('');
      _devLog('Step 9: Adding snooze notification to index...');
      final indexStore = ref.read(notificationIndexStoreProvider);
      await indexStore.putEntry(
        userId,
        petId,
        ScheduledNotificationEntry.create(
          notificationId: snoozeId,
          scheduleId: scheduleId,
          treatmentType: treatmentType,
          timeSlotISO: timeSlot,
          kind: 'snooze',
        ),
      );
      _devLog('✅ Snooze notification added to index');

      // Step 10: Track analytics event
      _devLog('');
      _devLog('Step 10: Tracking analytics event...');
      try {
        final analyticsService = ref.read(analyticsServiceDirectProvider);
        await analyticsService.trackReminderSnoozed(
          treatmentType: treatmentType,
          kind: kind, // Original kind (initial/followup)
          scheduleId: scheduleId,
          timeSlot: timeSlot,
          result: 'success',
        );
        _devLog('✅ Analytics event tracked successfully');
      } on Exception catch (e) {
        _devLog('⚠️ Failed to track analytics event: $e');
        // Don't fail snooze operation if analytics fails
      }

      _devLog('');
      _devLog('✅ SNOOZE COMPLETE - Notification will fire in 15 minutes');
      _devLog('═══════════════════════════════════════════════════════');
      _devLog('');

      return {
        'success': true,
        'snoozedUntil': snoozeTime.toIso8601String(),
        'snoozeId': snoozeId,
      };
    } on FormatException catch (e) {
      _devLog('❌ ERROR: Invalid JSON in payload: $e');
      _devLog('═══════════════════════════════════════════════════════');
      return {
        'success': false,
        'reason': 'invalid_payload',
      };
    } on Exception catch (e, stackTrace) {
      _devLog('❌ ERROR in snoozeCurrent: $e');
      _devLog('Stack trace: $stackTrace');
      _devLog('═══════════════════════════════════════════════════════');
      return {
        'success': false,
        'reason': 'unknown_error',
        'error': e.toString(),
      };
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

  /// Schedule next Monday's weekly summary notification.
  ///
  /// Call this:
  /// - On app startup (if enableNotifications && weeklySummaryEnabled)
  /// - When user enables weeklySummaryEnabled in settings
  /// - After onboarding completion
  ///
  /// Algorithm:
  /// 1. Check if weeklySummaryEnabled in user settings
  /// 2. If disabled, return early (don't schedule)
  /// 3. Calculate next Monday 09:00 (tz-aware)
  /// 4. Generate deterministic notification ID
  /// 5. Check if notification already scheduled (idempotent check)
  /// 6. If already scheduled, return early (avoid duplicate)
  /// 7. Build generic notification content
  /// 8. Schedule notification via plugin.showZoned()
  /// 9. Log success/failure in dev mode
  ///
  /// Parameters:
  /// - [userId]: Current user ID
  /// - [petId]: Primary pet ID
  /// - [ref]: Riverpod ref for accessing providers
  ///
  /// Returns: Map with result:
  ///   - 'success': bool (true if scheduled, false if already scheduled or
  ///     disabled)
  ///   - 'scheduledFor': ISO8601 timestamp of scheduled time (if success=true)
  ///   - 'notificationId': int (if success=true)
  ///   - 'reason': String (if success=false, e.g., 'already_scheduled',
  ///     'disabled_in_settings')
  ///
  /// Cost: 0 Firestore reads (reads from cached notificationSettingsProvider)
  Future<Map<String, dynamic>> scheduleWeeklySummary(
    String userId,
    String petId,
    WidgetRef ref,
  ) async {
    _devLog('scheduleWeeklySummary called for userId=$userId, petId=$petId');

    try {
      // Step 1: Check if weekly summary is enabled in user settings
      _devLog('Step 1: Checking notification settings...');
      final settings = ref.read(notificationSettingsProvider(userId));
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
      final plugin = ref.read(reminderPluginProvider);
      final pendingNotifications = await plugin.pendingNotificationRequests();
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
      await plugin.showZoned(
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

  /// Cancel weekly summary notification.
  ///
  /// Call this:
  /// - When user disables weeklySummaryEnabled in settings
  /// - When user disables enableNotifications (master toggle)
  /// - On user logout
  /// - During rescheduleAll() cleanup
  ///
  /// Parameters:
  /// - [userId]: Current user ID
  /// - [petId]: Primary pet ID
  /// - [ref]: Riverpod ref for accessing providers
  ///
  /// Returns: bool (true if canceled, false if not found)
  Future<bool> cancelWeeklySummary(
    String userId,
    String petId,
    WidgetRef ref,
  ) async {
    _devLog('cancelWeeklySummary called for userId=$userId, petId=$petId');

    try {
      final plugin = ref.read(reminderPluginProvider);
      var canceledCount = 0;

      // Check next Monday and up to 4 weeks in advance
      // (to catch any scheduled future notifications)
      for (var i = 0; i < 4; i++) {
        final monday = _calculateNextMonday09().add(Duration(days: 7 * i));
        final notificationId = generateWeeklySummaryNotificationId(
          userId: userId,
          petId: petId,
          weekStartDate: monday,
        );

        try {
          await plugin.cancel(notificationId);
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

  /// Cancel all notifications for today for the given user/pet, including weekly summary.
  ///
  /// Used for logout cleanup to avoid stale notifications and indexes.
  Future<void> cancelAllForToday(
    String userId,
    String petId,
    WidgetRef ref,
  ) async {
    _devLog('cancelAllForToday called for userId=$userId, petId=$petId');
    try {
      final plugin = ref.read(reminderPluginProvider);
      final indexStore = ref.read(notificationIndexStoreProvider);

      // Cancel all indexed notifications for today
      final entries = await indexStore.getForToday(userId, petId);
      for (final entry in entries) {
        try {
          await plugin.cancel(entry.notificationId);
        } on Exception catch (e) {
          _devLog('Failed cancel id ${entry.notificationId}: $e');
        }
      }

      // Clear today's index
      await indexStore.clearForDate(userId, petId, DateTime.now());

      // Cancel weekly summary notifications as well
      await cancelWeeklySummary(userId, petId, ref);
    } on Exception catch (e, stackTrace) {
      _devLog('ERROR in cancelAllForToday: $e');
      _devLog('Stack trace: $stackTrace');
      // best-effort cleanup, do not throw
    }
  }

  /// Calculate next Monday at 09:00 (timezone-aware).
  ///
  /// Returns: TZDateTime for next Monday at 09:00 local time
  ///
  /// Algorithm:
  /// 1. Get current date/time
  /// 2. If today is Monday and current time < 09:00, use today
  /// 3. Otherwise, find next Monday
  /// 4. Set time to 09:00:00
  /// 5. Convert to TZDateTime using tz.local
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
  ///
  /// This helper method provides access to localization strings for
  /// notification content that's scheduled from background services
  /// without access to BuildContext.
  ///
  /// V1: Returns English localizations only. When adding more languages,
  /// detect the system locale using:
  /// ```dart
  /// final locale = WidgetsBinding.instance.platformDispatcher.locale;
  /// return lookupAppLocalizations(locale);
  /// ```
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

  /// Log messages only in development flavor
  void _devLog(String message) {
    if (FlavorConfig.isDevelopment) {
      debugPrint('[ReminderService] $message');
    }
  }
}
