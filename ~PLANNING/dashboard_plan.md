# HydraCat Home Screen Dashboard - Today's Treatment Overview
## Implementation Plan

## Overview
Implement the "Today's Treatment Overview" section of the home screen dashboard to answer the critical user question: **"How is my cat doing today, and what do I need to do?"**

This feature provides an action-oriented, clear visual list of pending treatments with one-tap confirmation or skip functionality, immediate visual feedback, and zero-cost Firestore reads through client-side aggregation.

## Design Philosophy
- **Action-First**: Prioritize logging treatments over consuming information
- **Minimal Cognitive Load**: Users understand status in <3 seconds
- **Compassionate UX**: Gentle visual cues for overdue treatments (golden highlight, not red)
- **Zero-Read Architecture**: Leverage existing `DailySummaryCache` for instant status checks
- **Offline-First**: Optimistic updates with automatic sync queue

---

## User Experience Requirements

### Core User Flow
1. **User opens home screen** � Sees list of pending treatments for today
2. **User taps treatment card** � Popup appears with treatment summary
3. **User confirms/skips** � Treatment immediately updates with animation
4. **Visual feedback** � Success animation, card disappears or updates

### Treatment Display Logic

#### Medications (Individual Reminder Times)
- **Display**: One card per scheduled reminder time
- **Format**: "Amlodipine 1 pill at 8:00 AM"
- **Granularity**: If medication scheduled 2x/day (8am, 8pm) � Show 2 separate cards
- **Completion Detection**: Use �2h window matching (same as `LoggingService`)
  - If scheduled 8am and logged 7:30am � Mark as complete
  - Cache check: `medicationNames.contains(medicationName)` for today

#### Fluids (Aggregated Volume)
- **Display**: Single card showing remaining volume for today
- **Format**: "Fluid Therapy: 200mL remaining"
- **Aggregation**: `totalScheduledVolume - totalLoggedVolume`
- **Example**: Scheduled 100mL 2x/day, logged 80mL � Show "120mL remaining"

### Visual States

#### Pending Treatment Card
- **Background**: White card with subtle shadow
- **Icon**: Medication icon (pills) or fluid icon (water drop)
- **Text**:
  - Primary: Medication name + dosage OR "Fluid Therapy"
  - Secondary: Time (medications) or Volume remaining (fluids)
- **Color**: Default `AppColors.textPrimary`

#### Overdue Treatment Card
- **Background**: Subtle golden tint using `AppColors.successLight.withOpacity(0.1)`
- **Border**: Golden accent `AppColors.success` (1px left border)
- **Icon**: Golden tint overlay
- **Text**: Same as pending, with golden time text
- **Definition**: Scheduled time is >2 hours in the past AND not completed

#### Completed Treatment
- **Display**: Card disappears from list (do NOT show grayed out)
- **Reason**: Focus on actions needed, not past accomplishments

### Confirmation Popup Design

#### Visual Structure
- **Overlay**: Full-screen blur using `OverlayService.slideUp`
- **Background Blur**: 10.0 sigma (matches FAB logging popups)
- **Card**: White rounded card sliding up from bottom
- **Layout**: Similar to `TreatmentChoicePopup` pattern

#### Content Sections

**1. Header Section**
- Icon: Medication or fluid icon
- Title: Medication name OR "Fluid Therapy"
- Close button (X) in top-right corner

**2. Summary Section** (Read-only information)
- **For Medications**:
  - Medication name (bold)
  - Strength: "2.5 mg" (if available from schedule)
  - Dosage: "1 pill" (using `DosageTextUtils.formatDosageWithUnit`)
  - Scheduled time: "8:00 AM"

- **For Fluids**:
  - Title: "Fluid Therapy"
  - Volume remaining: "200mL remaining today"
  - Scheduled times: "9:00 AM, 9:00 PM" (list of reminder times)

**3. Action Buttons**
- **Skip Button** (Medications only):
  - Style: Outlined button with `AppColors.textSecondary` border
  - Label: "Skip"
  - Action: Create `MedicationSession` with `completed: false`, `dosageGiven: 0`

- **Confirm Button**:
  - Style: Filled button with `AppColors.primary`
  - Label: "Confirm Treatment"
  - Action: Create session with scheduled values, show success animation
  - **For Medications**: Log with `dosageGiven = schedule.targetDosage`, `completed: true`
  - **For Fluids**: Log with `volumeGiven = remainingVolume` (or scheduled volume for that slot)

**Note**: Fluids do NOT have a skip button (cumulative volume makes skipping non-actionable)

---

## Technical Architecture

### Data Flow

#### 1. Client-Side Aggregation (Zero Firestore Reads)
```
ProfileProvider (schedules) + DailySummaryCache (logged sessions)
                    �
        DashboardProvider (NEW)
                    �
    Calculates pending treatments
                    �
        HomeScreen displays cards
```

#### 2. Schedule Matching Logic

**Medications** (Name + Time Window):
```dart
bool isMedicationCompleted(Schedule schedule, DateTime reminderTime, DailySummaryCache cache) {
  // Step 1: Check if medication name is in today's cache
  if (!cache.medicationNames.contains(schedule.medicationName)) {
    return false; // Not logged today
  }

  // Step 2: Check time window (�2 hours, same as LoggingService)
  // Use cache.medicationRecentTimes[medicationName] for time-based check
  // If any logged session within �2h of reminderTime, mark complete

  return hasSessionWithin2Hours(cache, schedule.medicationName, reminderTime);
}
```

**Fluids** (Volume Aggregation):
```dart
double calculateRemainingFluidVolume(
  Schedule schedule,
  DailySummaryCache cache,
  DateTime now,
) {
  // Step 1: Count only today's planned sessions
  final today = DateTime(now.year, now.month, now.day);
  final sessionsToday = schedule.reminderTimes.where((t) =>
    DateTime(t.year, t.month, t.day).isAtSameMomentAs(today),
  ).length;

  // Step 2: Calculate total scheduled volume for today
  final perSession = schedule.targetVolume ?? 0.0;
  final totalScheduled = perSession * sessionsToday;

  // Step 3: Get total logged volume from cache
  final totalLogged = cache.totalFluidVolumeGiven;

  // Step 4: Calculate remaining
  final remaining = totalScheduled - totalLogged;

  return remaining > 0 ? remaining : 0;
}
```
Note: The sessions-today counting mirrors the helper used in `fluid_schedule_screen.dart`. Keep this logic provider-side and independent of any UI editing state.

#### 3. Overdue Detection
```dart
bool isOverdue(DateTime scheduledTime, DateTime now) {
  final difference = now.difference(scheduledTime);
  return difference.inHours > 2; // More than 2 hours past scheduled time
}
```

### State Management

#### New Provider: `dashboardProvider`
**Location**: `lib/providers/dashboard_provider.dart`

**Purpose**: Aggregate schedules + cache � pending treatments

**State Model**: `DashboardState`
```dart
@immutable
class DashboardState {
  final List<PendingTreatment> pendingMedications;
  final PendingFluidTreatment? pendingFluid;
  final bool isLoading;
  final String? errorMessage;
}
```

**Data Models**:
```dart
@immutable
class PendingTreatment {
  final Schedule schedule;
  final DateTime scheduledTime;
  final bool isOverdue;

  // Computed getters for display
  String get displayName => schedule.medicationName!;
  String get displayDosage => DosageTextUtils.formatDosageWithUnit(...);
  String get displayTime => formatTime(scheduledTime);
  String? get displayStrength => schedule.formattedStrength;
}

@immutable
class PendingFluidTreatment {
  final Schedule schedule;
  final double remainingVolume;
  final List<DateTime> scheduledTimes;
  final bool hasOverdueTimes;

  String get displayVolume => '${remainingVolume.toInt()}mL remaining';
  String get displayTimes => scheduledTimes.map(formatTime).join(', ');
}
```

#### Provider Logic
```dart
@riverpod
class DashboardNotifier extends _$DashboardNotifier {
  @override
  DashboardState build() {
    // Watch dependencies
    final schedules = ref.watch(profileProvider).schedules;
    final cache = ref.watch(dailyCacheProvider);
    final now = DateTime.now();

    // Filter today's schedules
    final todaysSchedules = schedules.where((s) =>
      s.isActive && s.hasReminderTimeToday(now)
    ).toList();

    // Calculate pending medications
    final pendingMeds = <PendingTreatment>[];
    for (final schedule in todaysSchedules.where((s) => s.isMedication)) {
      for (final reminderTime in schedule.reminderTimes) {
        if (!_isMedicationCompleted(schedule, reminderTime, cache)) {
          pendingMeds.add(PendingTreatment(
            schedule: schedule,
            scheduledTime: reminderTime,
            isOverdue: _isOverdue(reminderTime, now),
          ));
        }
      }
    }

    // Calculate pending fluid
    PendingFluidTreatment? pendingFluid;
    final fluidSchedule = todaysSchedules.firstWhereOrNull((s) => s.isFluidTherapy);
    if (fluidSchedule != null) {
      final remaining = _calculateRemainingVolume(fluidSchedule, cache);
      if (remaining > 0) {
        pendingFluid = PendingFluidTreatment(
          schedule: fluidSchedule,
          remainingVolume: remaining,
          scheduledTimes: fluidSchedule.reminderTimes,
          hasOverdueTimes: fluidSchedule.reminderTimes.any((t) => _isOverdue(t, now)),
        );
      }
    }

    return DashboardState(
      pendingMedications: pendingMeds,
      pendingFluid: pendingFluid,
      isLoading: false,
    );
  }

  // Helper methods: _isMedicationCompleted, _calculateRemainingVolume, _isOverdue
}
```

### Optimistic Updates

When user confirms/skips:
1. **Immediately update local state** (remove from pending list)
2. **Queue operation** via `LoggingNotifier` (existing offline queue)
3. **Show success animation** (no waiting for Firestore)
4. **Sync when online** (automatic via existing `OfflineLoggingService`)

---

## Implementation Phases

### Phase 1: Data Layer & Provider (Foundation)

#### Step 1.1: Create Dashboard Models
**Location**: `lib/features/home/models/`

**Files to Create**:
- `pending_treatment.dart` - Model for pending medication treatment
- `pending_fluid_treatment.dart` - Model for pending fluid treatment
- `dashboard_state.dart` - State model for dashboard provider

**Key Implementation**:
```dart
// pending_treatment.dart
@immutable
class PendingTreatment {
  const PendingTreatment({
    required this.schedule,
    required this.scheduledTime,
    required this.isOverdue,
  });

  final Schedule schedule;
  final DateTime scheduledTime;
  final bool isOverdue;

  // Display helpers
  String get displayName => schedule.medicationName!;

  String get displayDosage {
    return DosageTextUtils.formatDosageWithUnit(
      schedule.targetDosage!,
      _getShortForm(schedule.medicationUnit!),
    );
  }

  String get displayTime => AppDateUtils.formatTime(scheduledTime);

  String? get displayStrength => schedule.formattedStrength;

  String _getShortForm(String unit) {
    // Reuse logic from Schedule model
    return switch (unit) {
      'pills' => 'pill',
      'capsules' => 'capsule',
      // ... etc
      _ => unit,
    };
  }

  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is PendingTreatment &&
    other.schedule.id == schedule.id &&
    other.scheduledTime == scheduledTime;

  @override
  int get hashCode => Object.hash(schedule.id, scheduledTime);
}

// pending_fluid_treatment.dart
@immutable
class PendingFluidTreatment {
  const PendingFluidTreatment({
    required this.schedule,
    required this.remainingVolume,
    required this.scheduledTimes,
    required this.hasOverdueTimes,
  });

  final Schedule schedule;
  final double remainingVolume;
  final List<DateTime> scheduledTimes;
  final bool hasOverdueTimes;

  String get displayVolume => '${remainingVolume.toInt()}mL remaining';

  String get displayTimes => scheduledTimes
    .map(AppDateUtils.formatTime)
    .join(', ');

  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is PendingFluidTreatment &&
    other.schedule.id == schedule.id &&
    other.remainingVolume == remainingVolume;

  @override
  int get hashCode => Object.hash(schedule.id, remainingVolume);
}

// dashboard_state.dart
@immutable
class DashboardState {
  const DashboardState({
    required this.pendingMedications,
    this.pendingFluid,
    this.isLoading = false,
    this.errorMessage,
  });

  final List<PendingTreatment> pendingMedications;
  final PendingFluidTreatment? pendingFluid;
  final bool isLoading;
  final String? errorMessage;

  bool get hasPendingTreatments =>
    pendingMedications.isNotEmpty || pendingFluid != null;

  int get totalPendingCount =>
    pendingMedications.length + (pendingFluid != null ? 1 : 0);

  DashboardState copyWith({
    List<PendingTreatment>? pendingMedications,
    PendingFluidTreatment? pendingFluid,
    bool? isLoading,
    String? errorMessage,
  }) {
    return DashboardState(
      pendingMedications: pendingMedications ?? this.pendingMedications,
      pendingFluid: pendingFluid ?? this.pendingFluid,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is DashboardState &&
    listEquals(other.pendingMedications, pendingMedications) &&
    other.pendingFluid == pendingFluid &&
    other.isLoading == isLoading &&
    other.errorMessage == errorMessage;

  @override
  int get hashCode => Object.hash(
    Object.hashAll(pendingMedications),
    pendingFluid,
    isLoading,
    errorMessage,
  );
}
```

#### Step 1.2: Extend DailySummaryCache with Time-Based Matching
**Location**: `lib/features/logging/models/daily_summary_cache.dart`

**Add Method**:
```dart
/// Check if medication has been logged within time window of scheduled time
///
/// Used for dashboard completion detection with �2h window.
/// Returns true if any session for this medication exists within �2h
/// of the target scheduled time.
bool hasMedicationLoggedNear(String medicationName, DateTime scheduledTime) {
  // Check if medication logged today at all
  if (!medicationNames.contains(medicationName)) {
    return false;
  }

  // Check recent times for this medication
  final recentTimes = medicationRecentTimes[medicationName];
  if (recentTimes == null || recentTimes.isEmpty) {
    return false;
  }

  // Check if any logged time is within �2 hours of scheduled time
  const timeWindow = Duration(hours: 2);

  for (final timeStr in recentTimes) {
    final loggedTime = DateTime.parse(timeStr);
    final difference = loggedTime.difference(scheduledTime).abs();

    if (difference <= timeWindow) {
      return true;
    }
  }

  return false;
}
```

**Update SummaryCacheService to populate medicationRecentTimes**:
```dart
// In _updateCacheAfterMedicationLog method
final updatedRecentTimes = Map<String, List<String>>.from(
  currentCache.medicationRecentTimes,
);

final medicationTimes = List<String>.from(
  updatedRecentTimes[medicationName] ?? [],
);

// Add new time (keep last 10 times per medication for memory efficiency)
medicationTimes.add(loggedAt.toIso8601String());
if (medicationTimes.length > 10) {
  medicationTimes.removeAt(0); // Remove oldest
}

updatedRecentTimes[medicationName] = medicationTimes;

// Include in copyWith
final updatedCache = currentCache.copyWith(
  // ... existing fields
  medicationRecentTimes: updatedRecentTimes,
);
```

#### Step 1.3: Create Dashboard Provider
**Location**: `lib/providers/dashboard_provider.dart`

See detailed implementation in Technical Architecture section above.

---

### Phase 2: UI Components

#### Step 2.1: Create Treatment Card Widget
**Location**: `lib/features/home/widgets/pending_treatment_card.dart`

See implementation in plan above - displays medication with golden highlight for overdue.

#### Step 2.2: Create Fluid Treatment Card Widget
**Location**: `lib/features/home/widgets/pending_fluid_card.dart`

See implementation in plan above - displays aggregated fluid volume.

#### Step 2.3: Create Treatment Confirmation Popup
**Location**: `lib/features/home/widgets/treatment_confirmation_popup.dart`

See implementation in plan above - popup with confirm/skip buttons.

---

### Phase 3: Integration with Home Screen

#### Step 3.1: Add Dashboard Section to HomeScreen
**Location**: `lib/features/home/screens/home_screen.dart`

Replace placeholder cards with actual dashboard implementation - see detailed code in plan above.

---

## Testing Strategy

### Unit Tests
**Location**: `test/features/home/`

1. **Provider Logic Tests** (`dashboard_provider_test.dart`):
   - Pending medication calculation
   - Pending fluid aggregation
   - Overdue detection
   - Time window matching (�2h)

2. **Model Tests** (`models/pending_treatment_test.dart`):
   - Display helper formatting
   - Equality comparisons
   - Edge cases (null strength, multiple doses)

### Widget Tests
**Location**: `test/features/home/widgets/`

1. **Card Rendering** (`pending_treatment_card_test.dart`):
   - Normal state rendering
   - Overdue state rendering (golden highlight)
   - Tap interaction

2. **Popup Tests** (`treatment_confirmation_popup_test.dart`):
   - Medication popup with skip button
   - Fluid popup without skip button
   - Button callbacks

### Integration Tests
**Location**: `integration_test/`

1. **End-to-End Flow** (`dashboard_flow_test.dart`):
   - Create schedule � View pending � Confirm � Verify disappears
   - Create schedule � View pending � Skip � Verify logged as skipped
   - Multiple medications � Verify correct ordering
   - Fluid + meds � Verify both sections display

---

## Error Handling

### Offline Scenarios
- **No Connection**: All operations queue via `OfflineLoggingService`
- **Sync Failure**: Retry with exponential backoff (existing behavior)
- **User Feedback**: Connection status widget (already implemented)

### Edge Cases
1. **No Schedules**: Show progressive disclosure CTAs (existing behavior)
2. **All Completed**: Show success empty state
3. **Cache Expired**: Invalidate at midnight, rebuild from Firestore summary
4. **Multi-Device Sync**: Last write wins (existing conflict resolution)

---

## Performance Optimizations

### Zero-Read Architecture
- **Dashboard Load**: 0 Firestore reads (all from cache)
- **Confirmation**: 4 writes (session + 3 summaries via existing batch logic)
- **Cost per Treatment**: $0.0000072 (same as current logging)

### Memory Efficiency
- **Cache Size**: Store max 10 recent times per medication in `medicationRecentTimes`
- **Auto-Pruning**: Clear expired data at midnight
- **Selective Rebuild**: Provider only rebuilds when schedules or cache change

---

## Analytics Events

Add tracking for user engagement:

```dart
// In _confirmMedication
analytics.logEvent(
  'dashboard_treatment_confirmed',
  parameters: {
    'treatment_type': 'medication',
    'is_overdue': treatment.isOverdue,
    'scheduled_hour': treatment.scheduledTime.hour,
  },
);

// In _skipMedication
analytics.logEvent(
  'dashboard_treatment_skipped',
  parameters: {
    'treatment_type': 'medication',
    'is_overdue': treatment.isOverdue,
  },
);

// In _confirmFluid
analytics.logEvent(
  'dashboard_treatment_confirmed',
  parameters: {
    'treatment_type': 'fluid',
    'volume': fluidTreatment.remainingVolume,
  },
);
```

---

## Future Enhancements (Post-MVP)

1. **Quick Edit**: Long-press card to adjust dosage before confirming
2. **Batch Confirm**: Button to confirm all pending treatments at once
3. **Custom Reminders**: Per-treatment reminder customization
4. **Streak Display**: Show current streak on dashboard header
5. **Smart Sorting**: ML-based ordering based on user habits
6. **Voice Logging**: "Hey Siri, log Amlodipine" integration

---

## Implementation Checklist

### Phase 1: Data Layer 
- [ ] Create `PendingTreatment` model
- [ ] Create `PendingFluidTreatment` model
- [ ] Create `DashboardState` model
- [ ] Extend `DailySummaryCache` with `hasMedicationLoggedNear()`
- [ ] Update `SummaryCacheService` to populate `medicationRecentTimes`
- [ ] Create `DashboardProvider` with zero-read logic
- [ ] Run `dart run build_runner build`
- [ ] Unit test provider logic

### Phase 2: UI Components 
- [ ] Create `PendingTreatmentCard` widget
- [ ] Create `PendingFluidCard` widget
- [ ] Create `TreatmentConfirmationPopup` widget
- [ ] Widget tests for all components

### Phase 3: Integration 
- [ ] Update `HomeScreen` with dashboard section
- [ ] Add handler methods for tap interactions
- [ ] Implement confirm/skip operations
- [ ] Add success animation feedback
- [ ] Integration tests for full flow

### Phase 4: Polish & Testing 
- [ ] Manual testing on development flavor
- [ ] Verify offline queue integration
- [ ] Test overdue visual states
- [ ] Verify cache invalidation at midnight
- [ ] Analytics event tracking
- [ ] Code review and cleanup

---

## Success Metrics

**User Engagement**:
- Dashboard view rate: >80% of daily active users
- Treatment confirmation rate: >70% via dashboard (vs FAB)
- Time to first action: <5 seconds from app open

**Technical Performance**:
- Dashboard load time: <100ms (zero reads)
- Confirmation success rate: >99% (offline queue)
- Cache hit rate: >95% for pending status checks

---

## Completion Criteria

This feature is complete when:
1.  Users see pending treatments immediately on home screen
2.  Overdue treatments have golden visual highlight (not red)
3.  One-tap confirmation logs treatment with scheduled values
4.  Skip button (medications only) logs as skipped
5.  All operations work offline with auto-sync
6.  Zero Firestore reads for dashboard display
7.  Success animation provides immediate feedback
8.  Unit tests cover all provider logic
9.  Integration tests verify complete flow

---

**Document Status**: Ready for Implementation
**Estimated Development Time**: 6-8 hours
**Dependencies**: Existing logging system, profile provider, cache service
**Risk Level**: Low (extends existing patterns, no schema changes)
