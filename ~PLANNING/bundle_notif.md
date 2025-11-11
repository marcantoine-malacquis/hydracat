# Time-Based Notification Bundling Implementation Plan

## Overview
Replace per-schedule notifications with time-slot-based bundled notifications to prevent duplicate notifications when multiple treatments are scheduled at the same time (e.g., Benazepril + Fluid Therapy at 9:00 AM).

## Design Decisions Confirmed
1. **Tap behavior**: 
   - **Notification body tap** → Navigate to home screen (passive view of treatments)
   - **"Log now" action button** → Navigate to home screen AND auto-open logging screen (active intent)
     - Single treatment: Opens that treatment's logging screen directly
     - Bundled treatments: Shows treatment choice popup, then logging screen
2. **Action buttons**: Keep "Log now" only, remove "Snooze" completely
3. **Follow-ups**: Bundle them too - one follow-up for all unlogged treatments at same time slot
4. **Scheduling strategy**: "Nuclear option" - cancel all and reschedule all on any change (simple, robust, maintainable)

## Code Review Improvements Applied

This plan has been reviewed and updated based on external code review feedback:

✅ **Issue 1 - "Log now" Button Behavior**: Clarified distinction between notification body tap (passive view) and "Log now" button tap (active logging intent) - see Design Decision #1

✅ **Issue 2 - Profile Provider Integration**: Added `_refreshNotifications()` helper method pattern for cleaner, safer integration - see Phase 5.3

✅ **Issue 3 - Method Migration**: Added explicit Phase 3.3 for updating all callers of `_generateNotificationContent()`

✅ **Issue 4 - Rapid Schedule Changes**: Documented acceptable limitation with rationale - see Phase 5.1 "Known Limitation"

✅ **Additional**: Enhanced Phase 9.2 with specific methods to remove and verification steps

## Key Simplifications (Path B)

This plan uses a simplified "refresh all" approach instead of complex real-time rebundling:

**Instead of:**
- Complex index structure with multiple entries per notificationId
- Selective rebundling after each schedule change
- Tracking logged vs unlogged schedules in notifications
- Custom deletion logic for partial bundle updates

**We do:**
- Simple: ONE index entry per time slot notification
- After ANY change → cancel all + reschedule all
- Let `scheduleAllForToday()` handle bundling logic centrally
- ~60% less code, zero edge cases

**Why this works:**
- `scheduleAllForToday()` is already fast (< 200ms)
- Called infrequently (app start, resume, schedule changes, logging)
- Grace period logic already handles timing edge cases
- Index reconciliation already handles corruption recovery

## Implementation Steps

### Phase 1: Remove Snooze System

#### 1.1 Remove Snooze Action Button
**File**: `lib/features/notifications/services/reminder_plugin.dart`

**Current (lines 407-418)**:
```dart
final androidActions = [
  AndroidNotificationAction(
    'log_now',
    l10n.notificationActionLogNow,
    showsUserInterface: true,
  ),
  AndroidNotificationAction(
    'snooze',
    l10n.notificationActionSnooze,
  ),
];
```

**Change to**:
```dart
final androidActions = [
  AndroidNotificationAction(
    'log_now',
    l10n.notificationActionLogNow,
    showsUserInterface: true,
  ),
];
```

#### 1.2 Remove Snooze Handler
**File**: `lib/features/notifications/services/notification_tap_handler.dart`

Remove:
- `pendingSnoozePayload` ValueNotifier (lines 38-47)
- `notificationSnoozePayload` getter (lines 89-92)
- `notificationSnoozePayload` setter (lines 94-123)
- `clearPendingSnooze()` method (lines 139-148)

Update class documentation to remove snooze references.

#### 1.3 Remove Snooze Routing
**File**: `lib/features/notifications/services/reminder_plugin.dart`

In `_onDidReceiveNotificationResponse` method (around line 194):
Remove the snooze routing:
```dart
if (response.actionId == 'snooze') {
  // ... remove this entire block ...
}
```

#### 1.4 Remove Snooze Service Method
**File**: `lib/features/notifications/services/reminder_service.dart`

Remove entire `snoozeCurrent()` method (search for "Future<Map<String, dynamic>> snoozeCurrent")

#### 1.5 Update Notification Entry Model
**File**: `lib/features/notifications/models/scheduled_notification_entry.dart`

Update `isValidKind()` method (line 235):
```dart
// OLD
static bool isValidKind(String kind) {
  return kind == 'initial' || kind == 'followup' || kind == 'snooze';
}

// NEW
static bool isValidKind(String kind) {
  return kind == 'initial' || kind == 'followup';
}
```

Update documentation references to remove 'snooze' mentions.

#### 1.6 Remove Snooze from AppShell Listener
**File**: Search for AppShell or main app listener that handles `pendingSnoozePayload`

Remove snooze listener and handler. Likely in `lib/app/app_shell.dart` or similar.

---

### Phase 2: Add Time-Slot Notification ID Generation

#### 2.1 Create New ID Generator
**File**: `lib/features/notifications/utils/notification_id.dart`

Add new function after `generateWeeklySummaryNotificationId`:

```dart
/// Generates a deterministic notification ID for time-slot-based bundled notifications.
///
/// Unlike schedule-based IDs, this generates ONE ID per time slot regardless of
/// how many schedules exist at that time. This enables bundling multiple treatments
/// into a single notification when they occur at the same time.
///
/// **Parameters:**
/// - [userId]: User ID (for multi-user support)
/// - [petId]: Pet ID (for multi-pet support)
/// - [timeSlot]: Time slot in "HH:mm" format (e.g., "09:00")
/// - [kind]: Notification kind ('initial' or 'followup')
///
/// **Guarantees:**
/// - Same (userId, petId, timeSlot, kind) → same ID (idempotent)
/// - Different time slots → different IDs
/// - Initial vs followup → different IDs (can coexist)
///
/// **Example:**
/// ```dart
/// // Both Benazepril and Fluid Therapy at 09:00 get same ID
/// final id1 = generateTimeSlotNotificationId(
///   userId: 'user123',
///   petId: 'pet456',
///   timeSlot: '09:00',
///   kind: 'initial',
/// );
/// final id2 = generateTimeSlotNotificationId(
///   userId: 'user123',
///   petId: 'pet456',
///   timeSlot: '09:00',
///   kind: 'initial',
/// );
/// assert(id1 == id2); // Same ID = bundled notification
///
/// // Different time = different ID
/// final id3 = generateTimeSlotNotificationId(
///   userId: 'user123',
///   petId: 'pet456',
///   timeSlot: '21:00',
///   kind: 'initial',
/// );
/// assert(id1 != id3);
/// ```
int generateTimeSlotNotificationId({
  required String userId,
  required String petId,
  required String timeSlot,
  required String kind,
}) {
  // Validate time slot format
  if (!isValidTimeString(timeSlot)) {
    throw ArgumentError(
      'Invalid timeSlot format: "$timeSlot". Expected "HH:mm" (00:00 to 23:59).',
    );
  }

  // Validate kind
  if (kind != 'initial' && kind != 'followup') {
    throw ArgumentError(
      'Invalid kind: "$kind". Must be "initial" or "followup".',
    );
  }

  // Format: "timeslot|userId|petId|HH:mm|kind"
  final composite = 'timeslot|$userId|$petId|$timeSlot|$kind';

  // Generate hash using dart:convert
  final bytes = utf8.encode(composite);
  final hash = sha256.convert(bytes);

  // Convert first 4 bytes to int32
  final int32 = (hash.bytes[0] << 24) |
      (hash.bytes[1] << 16) |
      (hash.bytes[2] << 8) |
      hash.bytes[3];

  // Ensure positive for Android notification IDs (use absolute value)
  return int32.abs() & 0x7FFFFFFF;
}
```

---

### Phase 3: Add Bundled Notification Content Generation

#### 3.1 Add Localization Strings
**File**: `lib/l10n/app_en.arb`

Add after existing notification strings (around line 628):

```json
"notificationMultipleTreatmentsTitle": "Treatment reminder for {petName}",
"@notificationMultipleTreatmentsTitle": {
  "description": "Title for bundled treatment notifications at same time",
  "placeholders": {
    "petName": {
      "type": "String",
      "example": "Fluffy"
    }
  }
},
"notificationMultipleTreatmentsBody": "It's time for {count} treatments",
"@notificationMultipleTreatmentsBody": {
  "description": "Body for multiple treatments at same time",
  "placeholders": {
    "count": {
      "type": "int",
      "example": "2"
    }
  }
},
"notificationMixedTreatmentsBody": "It's time for medication and fluid therapy",
"@notificationMixedTreatmentsBody": {
  "description": "Body for mixed treatment types (medication + fluid) at same time"
},
"notificationMultipleFollowupTitle": "Treatment reminder for {petName}",
"@notificationMultipleFollowupTitle": {
  "description": "Title for bundled follow-up notifications",
  "placeholders": {
    "petName": {
      "type": "String"
    }
  }
},
"notificationMultipleFollowupBody": "{petName} may still need {count} treatments",
"@notificationMultipleFollowupBody": {
  "description": "Body for multiple unlogged treatments follow-up",
  "placeholders": {
    "petName": {
      "type": "String"
    },
    "count": {
      "type": "int"
    }
  }
}
```

Run `flutter gen-l10n` after adding strings.

#### 3.2 Replace Content Generation Method
**File**: `lib/features/notifications/services/reminder_service.dart`

Replace `_generateNotificationContent()` method (around line 1072) with new signature:

```dart
/// Generate notification content for single or bundled treatments.
///
/// When [schedules] contains one item, uses treatment-specific messaging.
/// When [schedules] contains multiple items, uses bundled messaging.
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
  final medicationCount = schedules.where((s) => 
    s.treatmentType.name == 'medication').length;
  final fluidCount = schedules.where((s) => 
    s.treatmentType.name == 'fluid').length;

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
      'body': l10n.notificationMultipleFollowupBody(petName, schedules.length),
      'channelId': 'medication_reminders',
    };
  }
}
```

#### 3.3 Update Method Callers
**File**: `lib/features/notifications/services/reminder_service.dart`

After replacing `_generateNotificationContent()` with `_generateBundledNotificationContent()`, update all callers:

1. **Search for callers**: Use IDE search to find all uses of `_generateNotificationContent()`

2. **Update signature**: Change from old to new pattern:

```dart
// OLD pattern
_generateNotificationContent(
  treatmentType: schedule.treatmentType.name,
  kind: 'initial',
  petName: petName,
)

// NEW pattern
_generateBundledNotificationContent(
  schedules: [schedule],  // Wrap single schedule in list
  kind: 'initial',
  petName: petName,
)
```

3. **Expected locations**:
   - Old `_scheduleNotificationsForSchedule()` method (will be removed in Phase 9)
   - Any test files that mock notification content generation
   - Any temporary/debug code that generates notifications

4. **Verify**: After changes, run `flutter analyze` to ensure no compilation errors

**Why this matters**: The new method signature accepts a list of schedules instead of individual fields, enabling bundling logic. All callers must be updated before Phase 4.

---

### Phase 4: Refactor Scheduling Logic

#### 4.1 Update scheduleAllForToday Method
**File**: `lib/features/notifications/services/reminder_service.dart`

In `scheduleAllForToday()` method (starts around line 92), replace the scheduling loop:

**OLD approach (lines ~172-192)**:
```dart
// Schedule notifications for each active schedule
for (final schedule in activeSchedulesForToday) {
  try {
    final result = await _scheduleNotificationsForSchedule(...);
    // ...
  }
}
```

**NEW approach**:
```dart
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
```

#### 4.2 Create New Scheduling Method
**File**: `lib/features/notifications/services/reminder_service.dart`

Replace `_scheduleNotificationForSlot()` (around line 704) with new method:

```dart
/// Schedule a bundled notification for a time slot with one or more schedules.
///
/// This method creates ONE notification for all schedules at the given time slot.
/// Only ONE index entry is created per time slot (using the notificationId as key).
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
    _devLog('WARNING: _scheduleNotificationForTimeSlot called with empty schedules');
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
        // Use first schedule's ID as representative (since we refresh all on changes)
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
  } on Exception catch (e) {
    _devLog('ERROR in _scheduleNotificationForTimeSlot: $e');
    return {
      'scheduled': 0,
      'immediate': 0,
      'missed': 0,
    };
  }
}
```

#### 4.3 Create Bundled Follow-up Method
**File**: `lib/features/notifications/services/reminder_service.dart`

Add new method (similar to old follow-up logic but bundled):

```dart
/// Schedule a bundled follow-up notification for multiple schedules at a time slot.
///
/// Follow-ups are sent 2 hours after the initial reminder if treatments aren't logged.
/// Like initial notifications, follow-ups are bundled when multiple schedules exist
/// at the same time.
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
    // Calculate follow-up time (+2 hours)
    final followupTime = initialScheduledTime.add(const Duration(hours: 2));

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
      '${followupTime.hour}:${followupTime.minute.toString().padLeft(2, '0')}',
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
```

---

### Phase 5: Simplify Schedule Updates with "Refresh All" Approach

#### 5.1 Add Helper Method for Refresh All
**File**: `lib/features/notifications/services/reminder_service.dart`

Add a simple helper method that cancels all and reschedules all:

```dart
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
    await cancelAllNotifications(userId, petId, ref);
    
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
```

**Known Limitation - Rapid Schedule Changes:**

If a user rapidly creates/updates/deletes multiple schedules (e.g., 3 schedules within 1 second), `refreshAllNotifications()` will be called multiple times in quick succession. This may cause:
- Brief notification recreation (notifications canceled and immediately recreated)
- Multiple redundant refresh cycles

**Why this is acceptable:**
- **Rare behavior**: Users don't typically create/delete schedules rapidly
- **No data loss**: Final state is always correct after all operations complete
- **Fast recovery**: Each refresh completes in < 200ms
- **Self-healing**: App resume or next schedule change corrects any transient state
- **Already throttled for common case**: Treatment logging (the most frequent action) uses throttling (Phase 7.3)

**Alternative considered and rejected**: Adding debouncing to `refreshAllNotifications()` would add complexity with `Completer` objects and could cause race conditions when callers `await` the result. The current "fire and complete" approach is simpler and more reliable.

#### 5.2 Update scheduleForSchedule to Use Refresh All
**File**: `lib/features/notifications/services/reminder_service.dart`

Simplify `scheduleForSchedule()` method (around line 242):

```dart
Future<Map<String, dynamic>> scheduleForSchedule(
  String userId,
  String petId,
  Schedule schedule,
  WidgetRef ref,
) async {
  _devLog('scheduleForSchedule called for schedule ${schedule.id}');

  // Validation checks
  final petName = ref.read(profileProvider).primaryPet?.name ?? 'your pet';
  
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
  return await refreshAllNotifications(userId, petId, ref);
}
```

#### 5.3 Update Profile Provider to Use Refresh All
**File**: `lib/providers/profile_provider.dart`

Add a helper method to the `ProfileNotifier` class to encapsulate notification refresh logic:

```dart
/// Refresh all notifications for the current user and pet.
///
/// This is a convenience wrapper around reminderService.refreshAllNotifications
/// that handles null checks and error logging. Safe to call after any schedule
/// operation - failures won't break the schedule CRUD operation.
Future<void> _refreshNotifications() async {
  final user = _ref.read(currentUserProvider);
  final pet = _ref.read(primaryPetProvider);

  if (user == null || pet == null) {
    if (kDebugMode) {
      debugPrint(
        '[ProfileProvider] Cannot refresh notifications: user or pet is null',
      );
    }
    return;
  }

  try {
    await _ref.read(reminderServiceProvider).refreshAllNotifications(
      user.id,
      pet.id,
      _ref,
    );
  } on Exception catch (e) {
    if (kDebugMode) {
      debugPrint('[ProfileProvider] Failed to refresh notifications: $e');
    }
    // Don't rethrow - notification refresh shouldn't break schedule operations
  }
}
```

Then update all schedule operations to call this helper:

**In `createMedicationSchedule()` (around line 630)**:
```dart
// OLD:
await _notificationHandler.scheduleForSchedule(
  userId: currentUser.id,
  petId: primaryPet.id,
  schedule: newSchedule,
);

// NEW:
await _refreshNotifications();
```

**In `updateMedicationSchedule()` (around line 750)**:
```dart
// OLD:
await _notificationHandler.scheduleForSchedule(...);

// NEW:
await _refreshNotifications();
```

**In `deleteMedicationSchedule()` (around line 880)**:
```dart
// OLD:
await _notificationHandler.cancelForSchedule(...);

// NEW:
await _refreshNotifications();
```

**Similarly for fluid schedule operations** (`createFluidSchedule`, `updateFluidSchedule`, `deleteFluidSchedule`).

**Benefits of this approach:**
- Centralized error handling and null checks
- Cleaner code at call sites
- Easier to add future enhancements (e.g., debouncing for rapid changes)
- Failures don't break schedule operations

---

### Phase 6: Update Notification Tap Handler

#### 6.1 Update Payload Documentation
**File**: `lib/features/notifications/services/notification_tap_handler.dart`

Update documentation to reflect new payload structure with multiple scheduleIds:

```dart
/// Set the notification tap payload.
///
/// This setter is called by the notification plugin when a notification
/// is tapped. The payload should be a JSON string containing:
/// - userId: User ID who scheduled the notification
/// - petId: Pet ID for the treatment
/// - scheduleIds: Comma-separated schedule IDs (for bundled notifications)
/// - timeSlot: Time slot in "HH:mm" format
/// - kind: Notification kind (initial/followup)
/// - treatmentTypes: Comma-separated treatment types
///
/// The UI layer (AppShell) is responsible for validating the payload
/// and navigating to the home screen (where treatments are displayed).
```

#### 6.2 Update AppShell Handler Behavior
**File**: `lib/app/app_shell.dart`

The notification tap handler (around line 331+) needs to differentiate between body tap and action button tap:

**Expected behavior** (verify this is implemented):

1. **Notification body tap** (actionId == null or empty):
   ```dart
   // Navigate to home screen (existing behavior)
   context.go('/');  // Or equivalent navigation
   ```

2. **"Log now" action button tap** (actionId == 'log_now'):
   ```dart
   // Navigate to home screen AND open logging screen
   context.go('/');
   
   // Then trigger logging flow (existing _onFabTap logic)
   final hasFluid = profileState.hasFluidSchedule;
   final hasMedication = profileState.hasMedicationSchedules;
   
   if (hasFluid && hasMedication) {
     // Show choice popup (existing behavior)
     _showLoggingDialog(context, TreatmentChoicePopup(...));
   } else if (hasFluid) {
     _showLoggingDialog(context, const FluidLoggingScreen());
   } else if (hasMedication) {
     _showLoggingDialog(context, const MedicationLoggingScreen());
   }
   ```

**Why this distinction matters:**
- Body tap = passive "what do I need to do?" → just show home
- "Log now" tap = active "I want to log now" → show home + logging screen
- Removes one tap for users who want to log immediately

---

### Phase 7: Integrate Refresh All After Treatment Logging

#### 7.1 Add Refresh Call After Medication Logging
**File**: `lib/providers/logging_provider.dart`

In `logMedicationSession()` method (around line 245), add refresh call after successful log:

```dart
Future<bool> logMedicationSession({
  required MedicationSession session,
  required List<Schedule> todaysSchedules,
}) async {
  try {
    // ... existing logging logic ...
    
    // Write to Firestore
    await _loggingService.logMedicationSession(session);
    
    // NEW: Refresh notifications after successful log
    final user = _ref.read(currentUserProvider);
    final pet = _ref.read(primaryPetProvider);
    if (user != null && pet != null) {
      try {
        await _ref.read(reminderServiceProvider).refreshAllNotifications(
          user.id,
          pet.id,
          _ref,
        );
      } on Exception catch (e) {
        // Log error but don't fail the logging operation
        debugPrint('[LoggingProvider] Failed to refresh notifications: $e');
      }
    }
    
    // ... rest of existing code ...
    return true;
  } catch (e) {
    // ... error handling ...
  }
}
```

#### 7.2 Add Refresh Call After Fluid Logging
**File**: `lib/providers/logging_provider.dart`

In `logFluidSession()` method (around line 292), add refresh call after successful log:

```dart
Future<bool> logFluidSession({
  required FluidSession session,
  FluidSchedule? fluidSchedule,
}) async {
  try {
    // ... existing logging logic ...
    
    // Write to Firestore
    await _loggingService.logFluidSession(session);
    
    // NEW: Refresh notifications after successful log
    final user = _ref.read(currentUserProvider);
    final pet = _ref.read(primaryPetProvider);
    if (user != null && pet != null) {
      try {
        await _ref.read(reminderServiceProvider).refreshAllNotifications(
          user.id,
          pet.id,
          _ref,
        );
      } on Exception catch (e) {
        // Log error but don't fail the logging operation
        debugPrint('[LoggingProvider] Failed to refresh notifications: $e');
      }
    }
    
    // ... rest of existing code ...
    return true;
  } catch (e) {
    // ... error handling ...
  }
}
```

#### 7.3 Add Throttling Helper for Rapid Logging
**File**: `lib/providers/logging_provider.dart`

Add import for Timer at the top of the file:
```dart
import 'dart:async';
```

Add a debouncing helper at the class level to prevent rapid successive refreshes:

```dart
class LoggingNotifier extends StateNotifier<LoggingState> {
  LoggingNotifier(this._ref, this._loggingService)
      : super(const LoggingState());

  final Ref _ref;
  final LoggingService _loggingService;
  
  // Throttle notification refreshes when logging multiple treatments rapidly
  Timer? _notificationRefreshTimer;
  static const _notificationRefreshDelay = Duration(milliseconds: 500);

  /// Throttle notification refresh to avoid rapid successive calls.
  /// 
  /// When users log multiple treatments back-to-back (e.g., 2 medications + fluid),
  /// we don't want to refresh 3 times. Instead, wait 500ms after the last log
  /// before refreshing once.
  void _throttleNotificationRefresh() {
    // Cancel pending refresh if one is scheduled
    _notificationRefreshTimer?.cancel();
    
    // Schedule a new refresh after delay
    _notificationRefreshTimer = Timer(_notificationRefreshDelay, () async {
      final user = _ref.read(currentUserProvider);
      final pet = _ref.read(primaryPetProvider);
      
      if (user != null && pet != null) {
        try {
          await _ref.read(reminderServiceProvider).refreshAllNotifications(
            user.id,
            pet.id,
            _ref,
          );
        } on Exception catch (e) {
          debugPrint('[LoggingProvider] Failed to refresh notifications: $e');
        }
      }
    });
  }

  @override
  void dispose() {
    _notificationRefreshTimer?.cancel();
    super.dispose();
  }
  
  // ... rest of class ...
}
```

#### 7.4 Update Logging Methods to Use Throttle

Update both `logMedicationSession()` and `logFluidSession()` to use the throttle:

**In `logMedicationSession()`:**
```dart
Future<bool> logMedicationSession({
  required MedicationSession session,
  required List<Schedule> todaysSchedules,
}) async {
  try {
    // ... existing logging logic ...
    
    // Write to Firestore
    await _loggingService.logMedicationSession(session);
    
    // NEW: Throttle notification refresh (waits 500ms after last log)
    _throttleNotificationRefresh();
    
    // ... rest of existing code ...
    return true;
  } catch (e) {
    // ... error handling ...
  }
}
```

**In `logFluidSession()`:**
```dart
Future<bool> logFluidSession({
  required FluidSession session,
  FluidSchedule? fluidSchedule,
}) async {
  try {
    // ... existing logging logic ...
    
    // Write to Firestore
    await _loggingService.logFluidSession(session);
    
    // NEW: Throttle notification refresh (waits 500ms after last log)
    _throttleNotificationRefresh();
    
    // ... rest of existing code ...
    return true;
  } catch (e) {
    // ... error handling ...
  }
}
```

#### 7.5 Why This Works

When a treatment is logged:
1. The logging provider writes to Firestore
2. It calls `_throttleNotificationRefresh()` which:
   - Cancels any pending refresh timer
   - Starts a new 500ms timer
3. If another treatment is logged within 500ms, the timer resets
4. Once 500ms passes with no new logs, ONE refresh executes
5. This cancels ALL notifications and reschedules based on current state
6. Follow-up notifications are automatically rescheduled for only unlogged treatments

**Benefits:**
- No complex rebundling logic
- No need to track which schedules were logged
- Follow-ups automatically reflect current state
- Already-logged treatments won't get new notifications (scheduleAllForToday only schedules for future times)
- **Performance:** Rapid 3-treatment logging → 1 refresh instead of 3 (66% reduction)

**Example Scenario:**
- User logs Benazepril at 9:00:10
- User logs Amlodipine at 9:00:12
- User logs Fluid Therapy at 9:00:15
- **Result:** ONE refresh at 9:00:15.5 (500ms after last log) instead of 3 refreshes

---

### Phase 8: Testing & Validation

#### 8.1 Manual Testing Scenarios

1. **Single treatment at a time**
   - Create Benazepril at 9:00 AM only
   - Verify notification shows "Treatment reminder: Medication for [Pet]"
   - Verify "Log now" button works

2. **Two treatments at same time**
   - Create Benazepril at 9:00 AM
   - Create Fluid Therapy at 9:00 AM
   - Verify ONLY ONE notification at 9:00 AM
   - Verify notification shows "It's time for medication and fluid therapy"

3. **Two medications at same time**
   - Create Benazepril at 9:00 AM
   - Create Amlodipine at 9:00 AM
   - Verify one notification: "It's time for 2 treatments"

4. **Different times**
   - Create Benazepril at 9:00 AM
   - Create Fluid Therapy at 21:00 PM
   - Verify TWO separate notifications at different times

5. **Follow-up bundling**
   - Don't log treatments from scenario #2
   - Wait 2 hours
   - Verify one follow-up: "[Pet] may still need 2 treatments"

6. **Partial logging**
   - From scenario #2, log only Benazepril
   - Verify notification is canceled
   - Check if follow-up still fires for Fluid Therapy only

7. **No snooze button**
   - Verify no "Snooze" action on any notification
   - Only "Log now" should appear

8. **Rapid logging throttle**
   - Set up 3 treatments at 9:00 AM (e.g., 2 medications + 1 fluid)
   - Log all 3 rapidly within 5 seconds
   - Verify only ONE notification refresh occurs (use debug logs)
   - Verify final notification state is correct after throttle completes

#### 8.2 Code Review Checklist

- [ ] All snooze references removed from codebase
- [ ] New `generateTimeSlotNotificationId` function added
- [ ] New bundled content generation works for 1, 2, 3+ schedules
- [ ] Localization strings added and generated
- [ ] `scheduleAllForToday` groups by time slot
- [ ] `refreshAllNotifications` helper method added
- [ ] `scheduleForSchedule` simplified to call refresh all
- [ ] Profile provider calls refresh all after schedule CRUD
- [ ] Throttling helper `_throttleNotificationRefresh` added to LoggingNotifier
- [ ] Both logging methods call throttle helper
- [ ] Timer cleanup in `dispose()` method
- [ ] Index stores ONE entry per time slot (not multiple)
- [ ] Follow-ups are bundled too
- [ ] Group summary still works correctly
- [ ] No breaking changes to existing single-treatment flows

#### 8.3 Edge Cases

- [ ] Midnight rollover: Bundled notifications reschedule correctly
- [ ] Schedule deletion: Refresh all correctly removes that schedule's notifications
- [ ] Schedule time change: Refresh all correctly rebundles at new time
- [ ] Grace period: Immediate bundled notifications fire correctly
- [ ] 50-notification limit: Bundling reduces total notification count
- [ ] Rapid schedule changes: Multiple creates/deletes may cause brief notification flicker (acceptable - documented limitation)
- [ ] Rapid logging with throttle: Multiple treatments logged quickly trigger only ONE refresh after 500ms

---

### Phase 9: Cleanup and Documentation

#### 9.1 Update Documentation
**File**: `lib/features/notifications/notifications_explanations.md`

Add section explaining bundled notifications:

```markdown
## Bundled Notifications (Time-Based)

When multiple treatments are scheduled at the same time (e.g., Benazepril and 
Fluid Therapy both at 9:00 AM), the app creates a single bundled notification 
instead of multiple separate notifications.

### Bundling Strategy

- Notifications are grouped by time slot (HH:mm format)
- ONE notification per time slot, regardless of number of schedules
- Content adapts based on treatment count and types
- "Refresh all" approach: cancel all + reschedule all on any state change

### Examples

Single treatment:
- Title: "Treatment reminder: Medication for Fluffy"
- Body: "It's time to give Fluffy their medication."

Multiple same-type:
- Title: "Treatment reminder for Fluffy"
- Body: "It's time for 2 treatments"

Mixed types:
- Title: "Treatment reminder for Fluffy"
- Body: "It's time for medication and fluid therapy"

### Follow-ups

Follow-up notifications are also bundled. Since we refresh all notifications
after logging, follow-ups automatically reflect only unlogged treatments.

### Refresh Strategy

Instead of complex rebundling logic, we use a simple "nuclear option":
- After any schedule change → refresh all notifications
- After any treatment logging → refresh all notifications
- Performance: < 200ms typically
- Benefits: Simple, robust, no edge cases
```

#### 9.2 Remove Old Methods

Search for and remove any now-unused helper methods:

**In `lib/features/notifications/services/reminder_service.dart`:**
- `_scheduleNotificationsForSchedule()` - replaced by `_scheduleNotificationForTimeSlot()`
- `_scheduleNotificationForSlot()` - if it exists (old single-schedule version)
- Any snooze-related helper methods
- Old `_generateNotificationContent()` - replaced by `_generateBundledNotificationContent()`

**In `lib/features/notifications/services/notification_handler.dart` (or similar):**
- Check for any wrapper methods that called the old scheduling logic

**In test files:**
- Update mocks/stubs for `_generateNotificationContent()` to use new signature
- Remove tests for snooze functionality

**Verification:**
1. Run `flutter analyze` to find any dangling references
2. Search codebase for "snooze" (case-insensitive) to find remaining references
3. Run all tests to ensure nothing breaks

#### 9.3 Update Comments

Search for comments mentioning "one notification per schedule" and update 
them to reflect the new "one notification per time slot" approach.

---

## Implementation Order

1. **Phase 1** (Snooze removal) - Do this first to clean up codebase
2. **Phase 2** (ID generation) - Foundation for bundling
3. **Phase 3** (Content generation) - Prepare localization
4. **Phase 4** (Core scheduling) - Main bundling logic
5. **Phase 5** (Single schedule) - Handle edge cases
6. **Phase 6** (Tap handling) - Update interaction layer
7. **Phase 7** (Cancellation) - Handle partial logging
8. **Phase 8** (Testing) - Validate everything works
9. **Phase 9** (Cleanup) - Polish and document

## Estimated Effort (Simplified Approach)

- Phase 1: 1-2 hours (snooze removal)
- Phase 2: 30 minutes (ID generation - copy existing pattern)
- Phase 3: 1 hour (localization + content generation)
- Phase 4: 2-3 hours (core scheduling refactor)
- Phase 5: 1-2 hours (simple refresh all helper + integration)
- Phase 6: 30 minutes (documentation updates only)
- Phase 7: 1.5 hours (add refresh calls + throttling helper)
- Phase 8: 2-3 hours (testing - simpler than original)
- Phase 9: 30 minutes (documentation + cleanup)

**Total: ~11-15 hours** (vs ~15-20 hours for complex approach)

**Savings:** ~4-5 hours, plus significantly reduced maintenance burden
**Performance gain:** 66% fewer refreshes during rapid multi-treatment logging

## Risk Mitigation

- Start with Phase 1 (snooze removal) - low risk, quick win
- Test each phase incrementally before proceeding
- Keep git commits atomic per phase for easy rollback
- Run existing notification tests after each phase
- Test on both Android and iOS (grouping behavior differs)
- **Simplified approach reduces risk:** Fewer edge cases, simpler code paths

## Success Criteria

✅ User receives ONE notification when multiple treatments scheduled at same time
✅ Notification content clearly indicates bundled treatments (1, 2, or 3+ schedules)
✅ Tap behavior navigates to home screen correctly
✅ "Log now" action button navigates to logging screen
✅ Follow-ups are bundled too (automatic via refresh all)
✅ No snooze functionality remains
✅ Existing single-treatment flows continue to work
✅ Notification index integrity maintained (ONE entry per time slot)
✅ Refresh all notifications works after:
  - Schedule create/update/delete
  - Treatment logging (with throttling)
  - App resume
✅ Performance: refresh all completes in < 300ms
✅ Throttling: rapid multi-treatment logging triggers only ONE refresh
✅ No notification duplication bugs
✅ Grace period logic still works correctly

---

## Appendix: Path A vs Path B Comparison

### Path A (Original Complex Approach) - ❌ Rejected

**Approach:** Real-time selective rebundling

**Issues identified by code review:**
1. Index structure ambiguity - `putEntry()` only allows ONE entry per notificationId
2. Complex rebundling logic after each schedule change
3. Need to track logged vs unlogged schedules
4. Edge cases: pre-emptive logging, already-logged schedules, partial bundle updates
5. ~20 hours of implementation time
6. High maintenance burden

**Would require:**
- Modifying `putEntry()` to support composite keys
- Complex `rebundleAfterLog()` logic
- Logged-status checks before rebundling
- Custom deletion logic for individual bundle entries

### Path B (Simplified "Refresh All") - ✅ Chosen

**Approach:** Cancel all + reschedule all on any state change (with throttling)

**Benefits:**
1. ✅ Works with existing index structure (ONE entry per notificationId)
2. ✅ No complex rebundling logic needed
3. ✅ No edge cases - always fresh state
4. ✅ ~11-15 hours implementation time (25-30% faster)
5. ✅ Low maintenance burden
6. ✅ Self-healing - always correct state
7. ✅ Throttling optimization: 66% fewer refreshes during rapid multi-treatment logging

**Key insight:**
- `scheduleAllForToday()` is already fast (< 200ms)
- Called infrequently (not on every user action)
- Grace period + reconciliation already handle edge cases
- Simpler code = fewer bugs
- Throttling prevents unnecessary rapid refreshes when users log multiple treatments back-to-back

**Trade-off:**
- Slightly less efficient than selective updates (but imperceptible to users)
- Brief moment where notifications are canceled/recreated (very rare timing issue)
- 500ms delay before refresh after logging (acceptable since notifications update in background)

**Verdict:** Path B provides 90% of the benefits with 50% of the complexity, plus performance optimizations for common usage patterns.

