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

/// @deprecated This service has been replaced by NotificationCoordinator.
///
/// All business logic for notification scheduling has been moved to
/// [NotificationCoordinator] which provides a cleaner API that works
/// with both Ref and WidgetRef without type casting issues.
///
/// Use [notificationCoordinatorProvider] instead:
/// ```dart
/// // Old (deprecated):
/// final service = ref.read(reminderServiceProvider);
/// await service.scheduleAllForToday(userId, petId, ref);
///
/// // New (recommended):
/// final coordinator = ref.read(notificationCoordinatorProvider);
/// await coordinator.scheduleAllForToday();
/// ```
///
/// This class is kept for backward compatibility with existing tests only.
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
/// See [NotificationCoordinator] for the replacement implementation.
@Deprecated(
  'Use NotificationCoordinator instead. '
  'Access via notificationCoordinatorProvider.',
)
class ReminderService {
  /// Factory constructor to get the singleton instance
  @Deprecated('Use notificationCoordinatorProvider instead')
  factory ReminderService() => _instance ??= ReminderService._();

  /// Private unnamed constructor
  @Deprecated('Use notificationCoordinatorProvider instead')
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
            ref: ref,
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

  /// Refresh all notifications by canceling and rescheduling everything.
  ///
  /// This is the "nuclear option" that ensures notifications are always
  /// correctly bundled without complex rebundling logic. Called after:
  /// - Schedule create/update/delete
  /// - Treatment logging (to update follow-ups)
  ///
  /// Performance: Typically < 200ms even with multiple schedules.
  Future<Map<String, dynamic>> refreshAllNotifications(
    String userId,
    String petId,
    WidgetRef ref,
  ) async {
    _devLog('refreshAllNotifications called');

    try {
      // Step 1: Cancel all existing notifications
      await cancelAllForToday(userId, petId, ref);

      // Step 2: Reschedule everything based on current active schedules
      final result = await scheduleAllForToday(userId, petId, ref);

      _devLog(
        'refreshAllNotifications complete: ${result['scheduled']} scheduled, '
        '${result['immediate']} immediate, ${result['missed']} missed',
      );

      return result;
    } on Exception catch (e) {
      _devLog('ERROR in refreshAllNotifications: $e');
      return {
        'scheduled': 0,
        'immediate': 0,
        'missed': 0,
        'errors': ['Failed to refresh notifications: $e'],
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

    // Validation checks
    if (!schedule.isActive) {
      _devLog('Schedule ${schedule.id} is inactive, skipping scheduling');
      return {
        'scheduled': 0,
        'immediate': 0,
        'missed': 0,
        'errors': <String>[],
      };
    }

    // Simple approach: refresh all notifications
    // This ensures correct bundling without complex logic
    return refreshAllNotifications(userId, petId, ref);
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
  /// (initial, follow-up) for that time slot.
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

      // Cancel all kinds (initial, followup)
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

  /// Schedule a bundled notification for a time slot with one or more
  /// schedules.
  ///
  /// This method creates ONE notification for all schedules at the given time
  /// slot. Only ONE index entry is created per time slot (using the
  /// notificationId as key).
  ///
  /// Parameters:
  /// - [userId]: Current user ID
  /// - [petId]: Primary pet ID
  /// - [schedules]: List of schedules scheduled at this time (1 or more)
  /// - [timeSlot]: Time slot in "HH:mm" format
  /// - [petName]: Pet name for notification content
  /// - [now]: Current time (for grace period evaluation)
  /// - [ref]: Riverpod ref for accessing providers
  Future<Map<String, dynamic>> _scheduleNotificationForTimeSlot({
    required String userId,
    required String petId,
    required List<Schedule> schedules,
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
          _devLog(
            'Scheduled bundled notification $notificationId for $timeSlot '
            '(${schedules.length} schedule(s))',
          );

          // Record in index - ONE ENTRY per time slot
          // Use first schedule's ID as representative (since we refresh all
          // on changes)
          await indexStore.putEntry(
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
          _devLog(
            'Fired immediate bundled notification for $timeSlot (grace period)',
          );

          // Record in index
          await indexStore.putEntry(
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
            ref: ref,
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
  ///
  /// Follow-ups are sent 2 hours after the initial reminder if treatments
  /// aren't logged. Like initial notifications, follow-ups are bundled when
  /// multiple schedules exist at the same time.
  Future<Map<String, dynamic>> _scheduleFollowupForTimeSlot({
    required String userId,
    required String petId,
    required List<Schedule> schedules,
    required String timeSlot,
    required String petName,
    required tz.TZDateTime initialScheduledTime,
    required WidgetRef ref,
  }) async {
    final plugin = ref.read(reminderPluginProvider);
    final indexStore = ref.read(notificationIndexStoreProvider);

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
      scheduledCount++;
      _devLog(
        'Scheduled bundled follow-up $followupId for $timeSlot at '
        '${followupTime.hour}:'
        '${followupTime.minute.toString().padLeft(2, '0')}',
      );

      // Record in index - one entry per time slot
      await indexStore.putEntry(
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
  ///
  /// When [schedules] contains one item, uses treatment-specific messaging.
  /// When [schedules] contains multiple items, uses bundled messaging.
  ///
  /// Returns a map with keys: title, body, channelId
  ///
  /// Privacy-first: All content is generic (no medication names, dosages, etc.)
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

  /// Calculate priority score for a notification entry.
  ///
  /// Priority scoring algorithm:
  /// - Base score by kind:
  ///   - initial: 100 (highest priority - first reminder)
  ///   - followup: 50 (medium priority - second reminder)
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
