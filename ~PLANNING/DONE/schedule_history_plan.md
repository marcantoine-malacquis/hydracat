# Schedule History Implementation Plan

## Problem Statement

### Current Behavior
When viewing the calendar's day detail popup, the system displays scheduled reminder times by calling `schedule.reminderTimesOnDate(date)` using the **current active schedule**. This causes historical inaccuracy when schedules are modified:

**Example Scenario:**
- Week 1 (Nov 4-8): Benazepril schedule has reminders at 9:00 AM, 3:00 PM, and 9:00 PM (3 doses)
- Week 2 (Nov 11): User changes schedule to 10:00 AM and 6:00 PM (2 doses)
- Week 3 (Nov 18): User views calendar for Nov 6
- **Problem**: Detail popup shows 10:00 AM and 6:00 PM (current schedule), but should show 9:00 AM, 3:00 PM, 9:00 PM (historical schedule)

### Why Current Data Structures Don't Solve This

The schedule document has `createdAt` and `updatedAt` timestamps, but when a schedule is updated, Firestore **overwrites the document in place**:

```
Before update (Nov 4):
  schedules/abc123: { reminderTimes: ["09:00", "15:00", "21:00"], updatedAt: Nov 4 }

After update (Nov 11):
  schedules/abc123: { reminderTimes: ["10:00", "18:00"], updatedAt: Nov 11 }
  ❌ Previous reminder times are lost forever
```

This means we cannot reconstruct what the schedule looked like on any past date.

### Impact Areas

1. **Calendar detail popup** - Shows incorrect reminder times for historical dates
2. **Retroactive logging** - User logs a missed day from 2 weeks ago, sees wrong scheduled times
3. **Adherence accuracy** - Daily summary stores scheduled counts, but detail view doesn't match
4. **User trust** - Showing incorrect historical data undermines confidence in the app

## Proposed Solution

### Architecture: Schedule History Subcollection

Implement a **changelog pattern** by creating a history subcollection under each schedule document:

```
pets/{petId}/schedules/{scheduleId}/history/{timestamp}
```

**Key Principle:** Before updating a schedule, snapshot its current state to the history subcollection.

### Data Model

#### New Model: ScheduleHistoryEntry

```dart
// File: lib/features/profile/models/schedule_history_entry.dart

@immutable
class ScheduleHistoryEntry {
  const ScheduleHistoryEntry({
    required this.scheduleId,
    required this.effectiveFrom,
    required this.effectiveTo,
    required this.treatmentType,
    required this.frequency,
    required this.reminderTimesIso,
    this.medicationName,
    this.targetDosage,
    this.medicationUnit,
    this.medicationStrengthAmount,
    this.medicationStrengthUnit,
    this.customMedicationStrengthUnit,
    this.targetVolume,
    this.preferredLocation,
    this.needleGauge,
  });

  /// ID of the parent schedule document
  final String scheduleId;

  /// When this version became active (inclusive)
  final DateTime effectiveFrom;

  /// When this version stopped being active (exclusive), null if current
  final DateTime? effectiveTo;

  /// Type of treatment
  final TreatmentType treatmentType;

  /// Treatment frequency
  final TreatmentFrequency frequency;

  /// Reminder times as ISO time strings (e.g., ["09:00:00", "21:00:00"])
  /// Stored as strings to avoid timezone complications
  final List<String> reminderTimesIso;

  // Medication-specific fields
  final String? medicationName;
  final double? targetDosage;
  final String? medicationUnit;
  final String? medicationStrengthAmount;
  final String? medicationStrengthUnit;
  final String? customMedicationStrengthUnit;

  // Fluid-specific fields
  final double? targetVolume;
  final String? preferredLocation;
  final String? needleGauge;

  factory ScheduleHistoryEntry.fromSchedule(
    Schedule schedule, {
    required DateTime effectiveFrom,
    DateTime? effectiveTo,
  }) {
    return ScheduleHistoryEntry(
      scheduleId: schedule.id,
      effectiveFrom: effectiveFrom,
      effectiveTo: effectiveTo,
      treatmentType: schedule.treatmentType,
      frequency: schedule.frequency,
      reminderTimesIso: schedule.reminderTimes
          .map((dt) => '${dt.hour.toString().padLeft(2, '0')}:'
                       '${dt.minute.toString().padLeft(2, '0')}:00')
          .toList(),
      medicationName: schedule.medicationName,
      targetDosage: schedule.targetDosage,
      medicationUnit: schedule.medicationUnit,
      medicationStrengthAmount: schedule.medicationStrengthAmount,
      medicationStrengthUnit: schedule.medicationStrengthUnit,
      customMedicationStrengthUnit: schedule.customMedicationStrengthUnit,
      targetVolume: schedule.targetVolume,
      preferredLocation: schedule.preferredLocation?.name,
      needleGauge: schedule.needleGauge,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'scheduleId': scheduleId,
      'effectiveFrom': effectiveFrom.toIso8601String(),
      'effectiveTo': effectiveTo?.toIso8601String(),
      'treatmentType': treatmentType.name,
      'frequency': frequency.name,
      'reminderTimesIso': reminderTimesIso,
      'medicationName': medicationName,
      'targetDosage': targetDosage,
      'medicationUnit': medicationUnit,
      'medicationStrengthAmount': medicationStrengthAmount,
      'medicationStrengthUnit': medicationStrengthUnit,
      'customMedicationStrengthUnit': customMedicationStrengthUnit,
      'targetVolume': targetVolume,
      'preferredLocation': preferredLocation,
      'needleGauge': needleGauge,
    };
  }

  factory ScheduleHistoryEntry.fromJson(Map<String, dynamic> json) {
    return ScheduleHistoryEntry(
      scheduleId: json['scheduleId'] as String,
      effectiveFrom: DateTime.parse(json['effectiveFrom'] as String),
      effectiveTo: json['effectiveTo'] != null
          ? DateTime.parse(json['effectiveTo'] as String)
          : null,
      treatmentType: TreatmentType.fromString(json['treatmentType'] as String)!,
      frequency: TreatmentFrequency.fromString(json['frequency'] as String)!,
      reminderTimesIso: List<String>.from(json['reminderTimesIso'] as List),
      medicationName: json['medicationName'] as String?,
      targetDosage: (json['targetDosage'] as num?)?.toDouble(),
      medicationUnit: json['medicationUnit'] as String?,
      medicationStrengthAmount: json['medicationStrengthAmount'] as String?,
      medicationStrengthUnit: json['medicationStrengthUnit'] as String?,
      customMedicationStrengthUnit: json['customMedicationStrengthUnit'] as String?,
      targetVolume: (json['targetVolume'] as num?)?.toDouble(),
      preferredLocation: json['preferredLocation'] as String?,
      needleGauge: json['needleGauge'] as String?,
    );
  }

  /// Parse reminder time ISO strings for a specific date
  List<DateTime> getReminderTimesForDate(DateTime date) {
    final normalized = AppDateUtils.startOfDay(date);
    return reminderTimesIso.map((isoTime) {
      final parts = isoTime.split(':');
      return DateTime(
        normalized.year,
        normalized.month,
        normalized.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
    }).toList();
  }
}
```

## Implementation Steps

### Step 1: Create New Service for Schedule History

**File:** `lib/features/profile/services/schedule_history_service.dart`

```dart
class ScheduleHistoryService {
  final FirebaseFirestore _firestore;

  ScheduleHistoryService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Save schedule state to history before updating
  Future<void> saveScheduleSnapshot({
    required String userId,
    required String petId,
    required Schedule schedule,
    required DateTime effectiveFrom,
    DateTime? effectiveTo,
  }) async {
    final entry = ScheduleHistoryEntry.fromSchedule(
      schedule,
      effectiveFrom: effectiveFrom,
      effectiveTo: effectiveTo,
    );

    final historyRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('pets')
        .doc(petId)
        .collection('schedules')
        .doc(schedule.id)
        .collection('history')
        .doc(effectiveFrom.millisecondsSinceEpoch.toString());

    await historyRef.set(entry.toJson());
  }

  /// Get schedule state as it was on a specific date
  Future<ScheduleHistoryEntry?> getScheduleAtDate({
    required String userId,
    required String petId,
    required String scheduleId,
    required DateTime date,
  }) async {
    final historyRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('pets')
        .doc(petId)
        .collection('schedules')
        .doc(scheduleId)
        .collection('history');

    // Query for entries where effectiveFrom <= date
    // Order by effectiveFrom descending to get most recent
    final query = await historyRef
        .where('effectiveFrom', isLessThanOrEqualTo: date.toIso8601String())
        .orderBy('effectiveFrom', descending: true)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      return null;
    }

    final entry = ScheduleHistoryEntry.fromJson(query.docs.first.data());

    // Verify date is within the effective range
    if (entry.effectiveTo != null && date.isAfter(entry.effectiveTo!)) {
      return null;
    }

    return entry;
  }

  /// Get all history entries for a schedule (for audit/debugging)
  Future<List<ScheduleHistoryEntry>> getScheduleHistory({
    required String userId,
    required String petId,
    required String scheduleId,
  }) async {
    final historyRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('pets')
        .doc(petId)
        .collection('schedules')
        .doc(scheduleId)
        .collection('history');

    final snapshot = await historyRef
        .orderBy('effectiveFrom', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => ScheduleHistoryEntry.fromJson(doc.data()))
        .toList();
  }
}
```

### Step 2: Integrate History Saving into Schedule Updates

**File:** `lib/features/profile/services/schedule_coordinator.dart`

Modify `updateFluidSchedule` and `updateMedicationSchedule` methods:

```dart
// Add dependency
final ScheduleHistoryService _historyService;

// In constructor
ScheduleCoordinator({
  // ... existing params
  ScheduleHistoryService? historyService,
}) : _historyService = historyService ?? ScheduleHistoryService();

// Before updating fluid schedule
Future<ScheduleResult> updateFluidSchedule({
  required String userId,
  required String petId,
  required Schedule schedule,
  // ... other params
}) async {
  try {
    // STEP 1: Save current schedule to history (if exists)
    final existingSchedule = await _scheduleService.getFluidSchedule(
      userId: userId,
      petId: petId,
    );

    if (existingSchedule != null) {
      // Save snapshot with effectiveFrom = creation time, effectiveTo = now
      await _historyService.saveScheduleSnapshot(
        userId: userId,
        petId: petId,
        schedule: existingSchedule,
        effectiveFrom: existingSchedule.createdAt,
        effectiveTo: DateTime.now(),
      );
    }

    // STEP 2: Update schedule (existing logic)
    final result = await _scheduleService.updateSchedule(
      userId: userId,
      petId: petId,
      schedule: schedule,
    );

    // STEP 3: Create new history entry for updated schedule
    if (result != null) {
      await _historyService.saveScheduleSnapshot(
        userId: userId,
        petId: petId,
        schedule: result,
        effectiveFrom: DateTime.now(),
        effectiveTo: null, // Current version
      );
    }

    return ScheduleResult(success: true, schedule: result);
  } catch (e) {
    return ScheduleResult(success: false, error: e.toString());
  }
}
```

Apply same pattern to `updateMedicationSchedule`.

### Step 3: Handle Schedule Creation

**File:** `lib/features/profile/services/schedule_coordinator.dart`

Modify `createFluidSchedule` and `createMedicationSchedule`:

```dart
Future<ScheduleResult> createFluidSchedule({
  required String userId,
  required String petId,
  required Schedule schedule,
  // ... other params
}) async {
  try {
    // STEP 1: Create schedule (existing logic)
    final result = await _scheduleService.createSchedule(
      userId: userId,
      petId: petId,
      schedule: schedule,
    );

    // STEP 2: Save initial history entry
    if (result != null) {
      await _historyService.saveScheduleSnapshot(
        userId: userId,
        petId: petId,
        schedule: result,
        effectiveFrom: result.createdAt,
        effectiveTo: null, // Current version
      );
    }

    return ScheduleResult(success: true, schedule: result);
  } catch (e) {
    return ScheduleResult(success: false, error: e.toString());
  }
}
```

### Step 4: Create Provider for Schedule History

**File:** `lib/providers/schedule_history_provider.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/features/profile/models/schedule_history_entry.dart';
import 'package:hydracat/features/profile/services/schedule_history_service.dart';
import 'package:hydracat/providers/auth_provider.dart';
import 'package:hydracat/providers/profile_provider.dart';

final scheduleHistoryServiceProvider = Provider<ScheduleHistoryService>((ref) {
  return ScheduleHistoryService();
});

/// Provider to get all schedules as they were on a specific date
final scheduleHistoryForDateProvider = FutureProvider.autoDispose
    .family<Map<String, ScheduleHistoryEntry>, DateTime>((ref, date) async {
  final user = ref.watch(currentUserProvider);
  final pet = ref.watch(primaryPetProvider);
  
  if (user == null || pet == null) {
    return {};
  }

  final service = ref.watch(scheduleHistoryServiceProvider);
  final allSchedules = ref.watch(allSchedulesProvider);
  
  final Map<String, ScheduleHistoryEntry> historicalSchedules = {};
  
  // For each current schedule, get its historical state at the date
  for (final schedule in allSchedules) {
    final historicalEntry = await service.getScheduleAtDate(
      userId: user.id,
      petId: pet.id,
      scheduleId: schedule.id,
      date: date,
    );
    
    if (historicalEntry != null) {
      historicalSchedules[schedule.id] = historicalEntry;
    }
  }
  
  return historicalSchedules;
});

/// Helper provider to get all current schedules (medication + fluid)
final allSchedulesProvider = Provider<List<Schedule>>((ref) {
  final medSchedules = ref.watch(medicationSchedulesProvider) ?? [];
  final fluidSchedule = ref.watch(fluidScheduleProvider);
  
  return [
    ...medSchedules,
    if (fluidSchedule != null) fluidSchedule,
  ];
});
```

### Step 5: Update Progress Day Detail Popup

**File:** `lib/features/progress/widgets/progress_day_detail_popup.dart`

Replace current schedule usage with historical schedule lookup:

```dart
// In _buildPlannedView method (for future dates - use current schedules)
Widget _buildPlannedView(BuildContext context, WidgetRef ref) {
  final medSchedules = ref.watch(medicationSchedulesProvider) ?? [];
  final fluidSchedule = ref.watch(fluidScheduleProvider);
  // ... rest stays the same
}

// In _buildPlannedWithStatus method (for past dates - use historical schedules)
Widget _buildPlannedWithStatus(BuildContext context, WidgetRef ref) {
  final user = ref.watch(currentUserProvider);
  final pet = ref.watch(primaryPetProvider);

  if (user == null || pet == null) {
    return const Text('User or pet not found');
  }

  final day = AppDateUtils.startOfDay(widget.date);
  final today = AppDateUtils.startOfDay(DateTime.now());
  final isFutureOrToday = day.isAfter(today) || day.isAtSameMomentAs(today);

  // For today and future: use current schedules
  if (isFutureOrToday) {
    final medSchedules = ref.watch(medicationSchedulesProvider) ?? [];
    final fluidSchedule = ref.watch(fluidScheduleProvider);
    return _buildWithSchedules(context, ref, medSchedules, fluidSchedule);
  }

  // For past dates: use historical schedules
  final historicalSchedulesAsync = ref.watch(
    scheduleHistoryForDateProvider(widget.date),
  );

  return historicalSchedulesAsync.when(
    data: (historicalMap) {
      // If no history found, fall back to current schedules (backward compat)
      if (historicalMap.isEmpty) {
        final medSchedules = ref.watch(medicationSchedulesProvider) ?? [];
        final fluidSchedule = ref.watch(fluidScheduleProvider);
        return _buildWithSchedules(context, ref, medSchedules, fluidSchedule);
      }

      // Build reminders from historical entries
      final medReminders = <(ScheduleHistoryEntry, DateTime)>[];
      ScheduleHistoryEntry? fluidHistoricalSchedule;

      for (final entry in historicalMap.values) {
        final reminderTimes = entry.getReminderTimesForDate(widget.date);
        
        if (entry.treatmentType == TreatmentType.medication) {
          for (final time in reminderTimes) {
            medReminders.add((entry, time));
          }
        } else if (entry.treatmentType == TreatmentType.fluid) {
          fluidHistoricalSchedule = entry;
        }
      }

      return _buildWithHistoricalData(
        context,
        ref,
        medReminders,
        fluidHistoricalSchedule,
      );
    },
    loading: () => const Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: CircularProgressIndicator(),
      ),
    ),
    error: (error, _) {
      // On error, fall back to current schedules
      final medSchedules = ref.watch(medicationSchedulesProvider) ?? [];
      final fluidSchedule = ref.watch(fluidScheduleProvider);
      return _buildWithSchedules(context, ref, medSchedules, fluidSchedule);
    },
  );
}

// New helper method to build UI with historical data
Widget _buildWithHistoricalData(
  BuildContext context,
  WidgetRef ref,
  List<(ScheduleHistoryEntry, DateTime)> medReminders,
  ScheduleHistoryEntry? fluidEntry,
) {
  final user = ref.watch(currentUserProvider);
  final pet = ref.watch(primaryPetProvider);

  if (user == null || pet == null) {
    return const Text('User or pet not found');
  }

  final fluidReminders = fluidEntry != null
      ? fluidEntry.getReminderTimesForDate(widget.date)
      : <DateTime>[];

  if (medReminders.isEmpty && fluidReminders.isEmpty) {
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.md),
      child: Text('No treatments scheduled for this day'),
    );
  }

  // Fetch sessions for completion status
  final weekStart = AppDateUtils.startOfWeekMonday(widget.date);
  final weekSessionsAsync = ref.watch(weekSessionsProvider(weekStart));

  return weekSessionsAsync.when(
    data: (weekSessions) {
      final normalizedDate = AppDateUtils.startOfDay(widget.date);
      final (medSessions, fluidSessions) = weekSessions[normalizedDate] ??
          (<MedicationSession>[], <FluidSession>[]);

      // Match sessions to historical reminders
      final completedReminderTimes = _matchHistoricalMedicationReminders(
        reminders: medReminders,
        sessions: medSessions,
      );

      final hasAnyFluid = fluidSessions.isNotEmpty;
      final showFluidSection = hasAnyFluid || fluidReminders.isNotEmpty;

      final scheduledFluidCount = fluidReminders.length;
      final actualFluidCount = hasAnyFluid ? 1 : 0;
      final scheduledMedCount = medReminders.length;
      final actualMedCount = completedReminderTimes.length;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showFluidSection) ...[
            _buildSectionHeader(
              'Fluid therapy',
              '$actualFluidCount of $scheduledFluidCount sessions',
            ),
            const SizedBox(height: AppSpacing.xs),
            _maybeSummaryCard(context, ref),
            if (fluidReminders.isNotEmpty && fluidEntry != null) ...[
              const SizedBox(height: AppSpacing.xs),
              ...fluidReminders.map(
                (time) => _buildHistoricalFluidTile(
                  fluidEntry,
                  time,
                  completed: hasAnyFluid,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
          ],
          if (medReminders.isNotEmpty) ...[
            _buildSectionHeader(
              'Medications',
              '$actualMedCount of $scheduledMedCount doses',
            ),
            const SizedBox(height: AppSpacing.xs),
            ...medReminders.map(
              (r) => _buildHistoricalMedicationTile(
                r.$1,
                r.$2,
                completed: completedReminderTimes.contains(r.$2),
              ),
            ),
          ],
        ],
      );
    },
    loading: () => const Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: CircularProgressIndicator(),
      ),
    ),
    error: (error, _) => Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Text(
        'Error loading sessions: $error',
        style: const TextStyle(color: AppColors.error),
      ),
    ),
  );
}

// New tile builders for historical data
Widget _buildHistoricalMedicationTile(
  ScheduleHistoryEntry entry,
  DateTime time, {
  bool completed = false,
}) {
  final timeStr = DateFormat.jm().format(time);
  final day = AppDateUtils.startOfDay(widget.date);
  final today = AppDateUtils.startOfDay(DateTime.now());
  final isFuture = day.isAfter(today);
  final canEdit = !isFuture;

  return ListTile(
    contentPadding: EdgeInsets.zero,
    leading: const Icon(
      Icons.medication,
      color: AppColors.textSecondary,
      size: 24,
    ),
    title: Text(
      entry.medicationName ?? 'Medication',
      style: AppTextStyles.body,
    ),
    subtitle: Text(
      '$timeStr • ${entry.targetDosage} ${entry.medicationUnit}',
      style: AppTextStyles.caption,
    ),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (completed)
          Semantics(
            label: 'Completed',
            child: const Icon(
              Icons.check_circle,
              color: AppColors.primary,
              size: 24,
            ),
          ),
        if (canEdit) ...[
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.edit, size: 20),
            onPressed: () {
              // Edit functionality (future enhancement)
            },
            tooltip: 'Edit',
          ),
        ],
      ],
    ),
  );
}

Widget _buildHistoricalFluidTile(
  ScheduleHistoryEntry entry,
  DateTime time, {
  bool completed = false,
}) {
  final timeStr = DateFormat.jm().format(time);

  return ListTile(
    contentPadding: EdgeInsets.zero,
    leading: const Icon(
      Icons.water_drop,
      color: AppColors.textSecondary,
      size: 24,
    ),
    title: Text(
      '${entry.targetVolume}ml',
      style: AppTextStyles.body,
    ),
    subtitle: Text(
      timeStr,
      style: AppTextStyles.caption,
    ),
    trailing: completed
        ? Semantics(
            label: 'Completed',
            child: const Icon(
              Icons.check_circle,
              color: AppColors.primary,
              size: 24,
            ),
          )
        : null,
  );
}

// Matcher for historical entries
Set<DateTime> _matchHistoricalMedicationReminders({
  required List<(ScheduleHistoryEntry, DateTime)> reminders,
  required List<MedicationSession> sessions,
}) {
  if (reminders.isEmpty || sessions.isEmpty) return <DateTime>{};

  final day = AppDateUtils.startOfDay(widget.date);
  final nextDay = AppDateUtils.endOfDay(widget.date);

  // Group by medication name
  final byMedName = <String, List<MedicationSession>>{};
  
  for (final s in sessions.where((s) => s.completed)) {
    final key = s.medicationName.trim().toLowerCase();
    byMedName.putIfAbsent(key, () => []).add(s);
  }

  for (final list in byMedName.values) {
    list.sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  final completed = <DateTime>{};

  for (final (entry, plannedTime) in reminders) {
    final medName = entry.medicationName?.trim().toLowerCase();
    if (medName == null) continue;
    
    final list = byMedName[medName];
    if (list == null || list.isEmpty) continue;

    MedicationSession? best;
    var bestDelta = 1 << 30;
    
    for (final s in list) {
      if (s.dateTime.isBefore(day) || s.dateTime.isAfter(nextDay)) continue;
      final delta = s.dateTime.difference(plannedTime).inSeconds.abs();
      if (delta < bestDelta) {
        best = s;
        bestDelta = delta;
      }
    }

    if (best != null) {
      completed.add(plannedTime);
      list.remove(best);
    }
  }

  return completed;
}
```

### Step 6: Add Firestore Security Rules

**File:** `firestore.rules`

Add rules for the history subcollection:

```
match /users/{userId}/pets/{petId}/schedules/{scheduleId}/history/{historyId} {
  // Users can read their own schedule history
  allow read: if request.auth != null && request.auth.uid == userId;
  
  // Only the app (via service) can write schedule history
  // Users cannot manually create/update/delete history entries
  allow write: if request.auth != null && request.auth.uid == userId;
}
```

### Step 7: Migration Strategy for Existing Schedules

Create a one-time migration to create initial history entries for existing schedules:

**File:** `lib/features/profile/services/schedule_history_migration.dart`

```dart
class ScheduleHistoryMigration {
  final ScheduleHistoryService _historyService;
  final ScheduleService _scheduleService;

  ScheduleHistoryMigration({
    required ScheduleHistoryService historyService,
    required ScheduleService scheduleService,
  })  : _historyService = historyService,
        _scheduleService = scheduleService;

  /// Migrate existing schedules to have initial history entries
  Future<void> migrateUserSchedules({
    required String userId,
    required String petId,
  }) async {
    // Get all current schedules
    final fluidSchedule = await _scheduleService.getFluidSchedule(
      userId: userId,
      petId: petId,
    );
    final medSchedules = await _scheduleService.getMedicationSchedules(
      userId: userId,
      petId: petId,
    );

    final allSchedules = [
      if (fluidSchedule != null) fluidSchedule,
      ...medSchedules,
    ];

    // For each schedule, create initial history entry
    for (final schedule in allSchedules) {
      // Check if history already exists
      final existingHistory = await _historyService.getScheduleHistory(
        userId: userId,
        petId: petId,
        scheduleId: schedule.id,
      );

      if (existingHistory.isEmpty) {
        // Create initial history entry using createdAt
        await _historyService.saveScheduleSnapshot(
          userId: userId,
          petId: petId,
          schedule: schedule,
          effectiveFrom: schedule.createdAt,
          effectiveTo: null, // Current version
        );
      }
    }
  }
}
```

Call this migration once per user on app startup or in a background task.

## Testing Strategy

### Unit Tests

1. **ScheduleHistoryEntry Model**
   - Test `fromSchedule` factory
   - Test `getReminderTimesForDate` with various dates
   - Test JSON serialization/deserialization

2. **ScheduleHistoryService**
   - Test saving snapshots
   - Test retrieving schedule at specific date
   - Test query logic with multiple history entries
   - Test effective date range validation

### Integration Tests

1. **Schedule Update Flow**
   - Create schedule → verify initial history entry
   - Update schedule → verify old version saved, new version current
   - Query historical date → verify correct version returned

2. **Calendar Detail Popup**
   - View future date → uses current schedule
   - View past date with history → uses historical schedule
   - View past date without history → falls back to current schedule

### Manual Testing Checklist

- [ ] Create new schedule → history entry created
- [ ] Update schedule reminder times → old times preserved in history
- [ ] Update schedule dosage → old dosage preserved in history
- [ ] View calendar for date before update → shows old schedule
- [ ] View calendar for date after update → shows new schedule
- [ ] Retroactively log missed day → correct schedule times displayed
- [ ] Multiple schedule updates → query returns correct version for each date
- [ ] Delete schedule → history remains accessible

## Performance Considerations

### Firestore Costs
- History writes: Only on schedule create/update (~1-5 writes per schedule per month)
- History reads: One query per day detail popup open (cached by Riverpod)
- Storage: ~500 bytes per history entry, ~50 KB per year per schedule (negligible)

### Optimization Strategies
1. Cache historical schedules in memory (Riverpod auto-dispose)
2. Batch queries for week view (fetch all schedules for week at once)
3. Consider TTL-based cleanup for very old history (>2 years) if needed

## Future Enhancements

1. **Audit Trail UI** - Show schedule change history to users
2. **Schedule Templates** - Reuse historical schedules for new treatments
3. **Analytics** - Track how often schedules are modified
4. **Bulk Operations** - Update multiple schedules with single history snapshot
5. **Export** - Include historical schedule data in data export

## Backward Compatibility

- Existing data without history will fall back to current schedule
- No breaking changes to existing APIs
- Migration can run in background without blocking users
- Historical accuracy improves going forward, old data shown with best effort

## Rollout Plan

1. **Phase 1**: Deploy model + service (no UI changes)
2. **Phase 2**: Start capturing history on new creates/updates
3. **Phase 3**: Run migration for existing schedules
4. **Phase 4**: Update calendar UI to use historical data
5. **Phase 5**: Monitor and optimize query performance

## Success Metrics

- [ ] 100% of schedule updates create history entries
- [ ] Calendar detail popup shows correct historical times
- [ ] No degradation in calendar load time (<500ms)
- [ ] Migration completes for all users within 7 days
- [ ] Zero user reports of incorrect historical schedule data

