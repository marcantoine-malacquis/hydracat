# HydraCat Fluid Inventory Tracking Feature
## Implementation Plan

## Overview
Implement comprehensive fluid inventory tracking where users can monitor their fluid supply, estimate remaining sessions, receive low-inventory alerts, and manage refills through an intuitive interface. This feature answers the critical user question: **"How much fluid do I have left, and when will I need to reorder?"**

This feature provides automatic inventory deduction during logging, transparent volume tracking with manual adjustments, smart threshold-based reminders, and seamless integration with the existing treatment logging system.

## Design Philosophy
- **Automatic & Seamless**: Inventory updates happen transparently during fluid logging
- **Transparent Tracking**: Show actual values including negative inventory (logged while empty)
- **User Control**: Simple tap-to-edit for manual adjustments without complex audit trails
- **Practical Calculations**: Conservative estimates using floor() for real-world accuracy
- **Optional Activation**: Progressive disclosure - users discover and activate when needed
- **Cost-Optimized**: Single document stream + batch writes during logging operations. Refills perform one transaction read for correctness; logging/delete operations still use cached provider data to avoid extra reads.
- **Race-Condition Safe**: Refills use Firestore transactions to read fresh data atomically, preventing inventory corruption from concurrent operations.

---

## 0. Coherence & Constraints

### Coherence with Existing Architecture
- **Firestore Schema**: Follows existing patterns (users/{userId}/subcollection/{docId})
- **State Management**: Uses Riverpod providers with StreamProvider for real-time updates
- **Service Layer**: Mirrors `WeightService` and `LoggingService` patterns
- **UI Components**: Uses existing `HydraBottomSheet`, `NavigationCard`, `HydraCard` components
- **Batch Writes**: Extends existing 4-write fluid logging to 5-write (adds inventory update)

### CRUD Rules Compliance
- **Zero additional reads (for logging/delete)**: Inventory uses StreamProvider (single real-time listener). Logging/delete operations use cached `inventoryEnabledAt` from provider instead of fetching inventory document. Refills intentionally issue one transaction read to avoid race conditions. This still saves ~90+ reads/month per active user (3 logs/day × 30 days).
- **Batch writes**: Inventory update included in existing fluid logging batch (5 writes total)
- **No full-history queries**: Refills subcollection queried with `.limit(20)` when needed
- **Cache-friendly**: Inventory state cached in StreamProvider, calculations recomputed only when data changes

### Critical Dependencies
- **Session Deletion**: MUST implement before inventory (Phase 0 prerequisite)
- **Existing Providers**: `currentUserProvider`, `primaryPetProvider`, `profileProvider`
- **Existing Services**: `LoggingService`, `SummaryService`, `NotificationCoordinator`
- **Existing Models**: `FluidSession`, `Schedule`, `DailySummary`, `WeeklySummary`, `MonthlySummary`

---

## User Experience Requirements

### Core User Flow
1. **User discovers feature** → Profile screen shows "Inventory" card
2. **User taps card** → Empty state explains feature, shows "+ Refill" button
3. **User adds initial refill** → Enters fluid bags/bottles, sets reminder threshold
4. **User logs fluid sessions** → Inventory automatically deducts volume
5. **User views inventory** → Progress bar, sessions left, estimated end date
6. **Inventory reaches threshold** → One-time notification fires
7. **User refills supply** → Updates inventory, resets threshold tracking

### Inventory Display (Main Screen)

#### Progress Bar Section
- **Visual**: Horizontal progress bar (0-100%)
- **Color**:
  - Green gradient when > 50%
  - Orange when 25-50%
  - Red when < 25%
- **Text Above Bar**: "2,350 mL remaining (47%)"
- **Text Below Bar**:
  - "~15 sessions left"
  - "Est. empty on Dec 18, 2024"
  - OR "Unable to estimate (no active schedules)" if no schedules

#### Last Refill Section
- **Text**: "Last refill: Dec 1, 2024"
- **Tappable**: Shows refill history in bottom sheet (future enhancement)

#### Manual Adjustment
- **Tap on volume number** → Opens text input dialog
- **Dialog**:
  - Title: "Adjust Inventory"
  - Input: Number field with "mL" suffix
  - Helper text: "Correct for leaks, spills, or tracking errors"
  - Buttons: Cancel / Save
- **Feedback**: Snackbar shows "Inventory updated: 2,350 mL"

### Refill Popup (Bottom Sheet)

#### Header Section
- **Title**: "Refill Inventory"
- **Close button**: X in top-right corner

#### Bag/Bottle Selection
- **Quick Select Chips**: 500mL, 1000mL buttons
- **Custom Input**: Number field for other volumes
- **Quantity Selector**: "How many?" with +/- buttons (default: 1)

#### Live Preview
- **Current**: "Current: 350 mL"
- **Adding**: "+1,000 mL"
- **New Total**: "New inventory: 1,350 mL" (large, bold)

#### Reset Toggle
- **Checkbox**: "Reset inventory (ignore current amount)"
- **When checked**: New total = entered amount (ignores current)
- **When unchecked**: New total = current + entered amount (default)

#### Reminder Threshold Slider
- **Label**: "Remind me when low"
- **Slider**: 1-20 sessions left (default: 10)
- **Live Display**: "Remind at ~1,170 mL"
  - Calculation: `sessions × avgVolumePerSession`

#### Action Button
- **Label**: "Save" (top-right corner of popup)
- **Style**: Primary button color
- **Action**:
  - Write to `fluidInventory/main` document
  - Create entry in `refills` subcollection
  - Store `reminderSessionsLeft` (user intent)
  - Clear `lastThresholdNotificationSentAt`
  - **Note**: thresholdVolume is NOT stored - computed dynamically on each check

### Negative Inventory Handling

When `remainingVolume` goes negative (logged while empty):

#### Visual Display
- **Progress Bar**: Shows 0% (not negative percentage)
- **Volume Text**: "0 mL (0%)"
- **Warning Text**: "You have logged 200mL while inventory was empty"
- **Color**: Red border on progress bar
- **Calculations**: Metrics clamp remainingVolume to 0 for sessions/days left; warning text still uses the raw negative amount so overdraw is visible

#### Refill Behavior
- **Additive Mode**: -200 + 1000 = 800mL ✅
- **Reset Mode**: Ignores -200, sets to 1000mL ✅

### Profile Screen Integration

#### Navigation Card
- **Title**: "Inventory"
- **Icon**: `Icons.inventory_2` or `Icons.water_drop`
- **Metadata**:
  - If active: "2,350 mL remaining (~15 sessions)"
  - If not active: "Track your fluid supply"
- **onTap**: Navigate to `/profile/inventory`

---

## Technical Architecture

### Firestore Schema

#### Main Inventory Document
```
users/{userId}/fluidInventory/main
  ├── id: string                              # "main"
  ├── remainingVolume: number                 # current volume in mL (can be negative)
  ├── initialVolume: number                   # volume at last refill/reset
  ├── reminderSessionsLeft: number            # user setting (1-20, default 10) - intent only
  ├── lastRefillDate: Timestamp               # for UI display
  ├── refillCount: number                     # lifetime counter
  ├── inventoryEnabledAt: Timestamp           # when user first activated inventory
  ├── lastThresholdNotificationSentAt: Timestamp?  # to avoid duplicate notifications
  ├── createdAt: Timestamp
  └── updatedAt: Timestamp

Note: thresholdVolume is NOT stored - it's computed dynamically in checkThresholdAndNotify()
      using current schedules to ensure accuracy when schedules change.
```

#### Refills Subcollection
```
users/{userId}/fluidInventory/main/refills/{refillId}
  ├── id: string                    # auto-generated document ID
  ├── volumeAdded: number           # mL added (always positive)
  ├── totalAfterRefill: number      # snapshot of remainingVolume after refill
  ├── isReset: boolean              # whether "reset inventory" toggle was used
  ├── reminderSessionsLeft: number  # threshold setting at time of refill
  ├── refillDate: Timestamp         # when refill was performed
  ├── createdAt: Timestamp
  └── updatedAt: Timestamp
```

### Calculation Formulas

#### Sessions Left
```dart
// Gather all active fluid schedules across all user's pets
List<Schedule> fluidSchedules = getAllActiveFluidSchedules();

// Calculate total daily volume and sessions
double totalDailyVolume = 0;
int totalSessionsPerDay = 0;

for (final schedule in fluidSchedules) {
  final sessionsPerDay = schedule.reminderTimes.length;
  final volumePerDay = schedule.targetVolume * sessionsPerDay;

  totalDailyVolume += volumePerDay;
  totalSessionsPerDay += sessionsPerDay;
}

// Calculate average per session
double averageVolumePerSession = totalSessionsPerDay > 0
    ? totalDailyVolume / totalSessionsPerDay
    : 0;

// Clamp negative inventory for calculations (UI warning still uses raw negative)
final safeRemaining = max(0, remainingVolume);

// Calculate sessions left (floor for conservative estimate)
int sessionsLeft = averageVolumePerSession > 0
    ? (safeRemaining / averageVolumePerSession).floor()
    : 0;

// Example:
// Pet A: 100mL twice daily (2 sessions, 200mL/day)
// Pet B: 150mL once daily (1 session, 150mL/day)
// Total: 3 sessions/day, 350mL/day
// Average per session: 350 ÷ 3 ≈ 117mL
// Remaining: 800mL → 800 ÷ 117 = 6.84 → floor() = 6 sessions ✅
```

#### Threshold Volume (for notifications)
```dart
// Computed dynamically in checkThresholdAndNotify() using CURRENT schedules
double thresholdVolume = reminderSessionsLeft * averageVolumePerSession;

// Example:
// If user sets "remind at 10 sessions left"
// With current schedules averaging 117mL/session:
//   Threshold = 10 × 117 = 1,170mL
// If user later changes schedules to average 100mL/session:
//   Threshold = 10 × 100 = 1,000mL (automatically recalculated!)
// Notification fires when remainingVolume drops below computed threshold

// IMPORTANT: Threshold is NOT persisted - always computed from current schedules
//            to ensure accuracy when schedules change without refilling.
```

#### Estimated End Date
```dart
// Calculate days remaining (conservative floor)
int daysRemaining = totalDailyVolume > 0
    ? (safeRemaining / totalDailyVolume).floor()
    : 0;

DateTime estimatedEndDate = DateTime.now().add(Duration(days: daysRemaining));

// Example:
// Remaining: 800mL
// Daily need: 350mL
// Days: 800 ÷ 350 = 2.29 → floor() = 2 days
// Display: "Est. empty on [date 2 days from now]"
```

---

## Implementation Phases

### Phase 0: Session Deletion (Prerequisite) ⬜

**CRITICAL DEPENDENCY**: Must implement session deletion before inventory to support retroactive adjustments.

#### Step 0.1: Add DeleteFluidSession to SummaryUpdateDto ⬜

**Goal**: Add factory constructor for computing negative deltas when deleting fluid sessions.

**Location**: `lib/shared/models/summary_update_dto.dart`

**Implementation**:

```dart
// Add after existing factory constructors

/// Creates a DTO for fluid session deletion (negative deltas)
///
/// Used when deleting a fluid session to update summaries:
/// - Decrements volume and session count
/// - No medication fields affected
factory SummaryUpdateDto.forFluidSessionDelete({
  required FluidSession session,
}) {
  return SummaryUpdateDto(
    // Fluid fields (negative to decrement)
    fluidVolumeDelta: -session.volumeGiven,
    fluidSessionCountDelta: -1,

    // No medication deltas
    medicationDosesDelta: null,
    medicationMissedCountDelta: null,
  );
}
```

**Validation**:
- ✅ Follows existing factory pattern (`forFluidSessionUpdate`, `forMedicationSessionUpdate`)
- ✅ Uses negative values for decrements (consistent with update logic)
- ✅ Only affects fluid-related fields

---

#### Step 0.2: Add DeleteFluidSession Method to LoggingService ⬜

**Goal**: Implement complete delete operation with batch writes to session + summaries + inventory.

**Location**: `lib/features/logging/services/logging_service.dart`

**Implementation**:

Add to public API section (after `updateFluidSession` method):

```dart
// ============================================
// PUBLIC API - Fluid Session Deletion
// ============================================

/// Deletes a fluid session with summary updates and optional inventory adjustment
///
/// Process:
/// 1. Validates session exists
/// 2. Calculates delta for summary decrements
/// 3. If inventory enabled: adds volume back to inventory
/// 4. Creates batch: delete session + update summaries + update inventory
/// 5. Commits atomically to Firestore
///
/// Parameters:
/// - `userId`: Current authenticated user ID
/// - `petId`: Target pet ID
/// - `session`: Fluid session to delete (UI has full session object)
/// - `updateInventory`: Whether to adjust inventory (default: false)
/// - `inventoryEnabledAt`: When inventory was activated (passed from provider to avoid extra read)
///
/// Returns: void
///
/// Throws:
/// - [BatchWriteException]: Firestore write failed
/// - [LoggingException]: Unexpected error
Future<void> deleteFluidSession({
  required String userId,
  required String petId,
  required FluidSession session,
  bool updateInventory = false,
  DateTime? inventoryEnabledAt,
}) async {
  try {
    if (kDebugMode) {
      debugPrint(
        '[LoggingService] Deleting fluid session: ${session.id}',
      );
    }

    final date = AppDateUtils.startOfDay(session.dateTime);

    // STEP 1: Build DTO for summary decrements (negative deltas)
    final dto = SummaryUpdateDto.forFluidSessionDelete(session: session);

    // STEP 2: Fetch current monthly arrays (needed for array updates)
    final monthlyArrays = await _fetchMonthlyArrays(
      userId: userId,
      petId: petId,
      date: date,
    );

    // STEP 3: Fetch daily summary to compute accurate deltas
    final dailyRef = _getDailySummaryRef(userId, petId, date);
    final dailySnap = await dailyRef.get();
    final currentDailyVolume = dailySnap.exists
        ? (dailySnap.data()?['fluidTotalVolume'] as num?)?.toDouble() ?? 0.0
        : 0.0;
    final newDailyVolume = currentDailyVolume - session.volumeGiven;

    // STEP 4: Check if inventory should be adjusted (no extra read - uses cached timestamp)
    bool shouldUpdateInventory = false;
    if (updateInventory && inventoryEnabledAt != null) {
      // Only restore inventory if session was logged after inventory activation
      shouldUpdateInventory = session.dateTime.isAfter(inventoryEnabledAt) ||
          session.dateTime.isAtSameMomentAs(inventoryEnabledAt);
    }

    // STEP 5: Build batch
    final batch = _firestore.batch();

    // Operation 1: Delete session
    final sessionRef = _getFluidSessionRef(userId, petId, session.id);
    batch.delete(sessionRef);

    // Operation 2: Daily summary (decrement)
    batch.set(
      dailyRef,
      _buildDailySummaryWithIncrements(date, dto),
      SetOptions(merge: true),
    );

    // Operation 3: Weekly summary (decrement)
    final weeklyRef = _getWeeklySummaryRef(userId, petId, date);
    batch.set(
      weeklyRef,
      _buildWeeklySummaryWithIncrements(date, dto),
      SetOptions(merge: true),
    );

    // Operation 4: Monthly summary (decrement + array update)
    final monthlyRef = _getMonthlySummaryRef(userId, petId, date);
    batch.set(
      monthlyRef,
      _buildMonthlySummaryWithIncrements(
        date,
        dto,
        dayFluidVolume: newDailyVolume,
        dayGoalMl: session.dailyGoalMl ?? 0,
        currentDailyVolumes: monthlyArrays.dailyVolumes,
        currentDailyGoals: monthlyArrays.dailyGoals,
        currentDailyScheduledSessions: monthlyArrays.dailyScheduledSessions,
      ),
      SetOptions(merge: true),
    );

    // Operation 5 (conditional): Inventory adjustment
    if (shouldUpdateInventory) {
      final inventoryRef = _getInventoryRef(userId);
      batch.update(inventoryRef, {
        'remainingVolume': FieldValue.increment(session.volumeGiven),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        debugPrint(
          '[LoggingService] Inventory will be updated: +${session.volumeGiven}mL restored',
        );
      }
    }

    // STEP 6: Commit batch
    await _executeBatchWrite(
      batch: batch,
      operation: 'deleteFluidSession',
    );

    // STEP 7: Re-arm threshold if volume was restored above threshold
    // (pass current schedules or invoke checkThresholdAndNotify with fresh snapshot)
    // Implementation should mirror logging flow to avoid stale lastThresholdNotificationSentAt
    // Example: await checkThresholdAndNotify(userId: userId, inventory: restoredInventory, schedules: currentSchedules);

    if (kDebugMode) {
      debugPrint(
        '[LoggingService] Successfully deleted fluid session ${session.id}',
      );
    }
  } on FirebaseException catch (e) {
    if (kDebugMode) {
      debugPrint('[LoggingService] Firebase error: ${e.message}');
    }

    await _analyticsService?.trackLoggingFailure(
      errorType: 'batch_write_failure',
      treatmentType: 'fluid',
      source: 'delete',
      errorCode: e.code,
      exception: 'FirebaseException',
    );

    throw BatchWriteException(
      'deleteFluidSession',
      e.message ?? 'Unknown Firebase error',
    );
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[LoggingService] Unexpected error: $e');
    }

    await _analyticsService?.trackLoggingFailure(
      errorType: 'unexpected_logging_error',
      treatmentType: 'fluid',
      source: 'delete',
      exception: e.runtimeType.toString(),
    );

    throw LoggingException('Unexpected error deleting fluid session: $e');
  }
}

// Add helper method to private section
DocumentReference _getInventoryRef(String userId) {
  return _firestore
      .collection('users')
      .doc(userId)
      .collection('fluidInventory')
      .doc('main');
}
```

**Implementation Notes**:
- Uses existing `_fetchMonthlyArrays()` helper for array updates
- Checks `inventoryEnabledAt` timestamp to only restore inventory for relevant sessions
- Uses `FieldValue.increment()` for atomic inventory update
- Follows same pattern as `updateFluidSession()` for consistency
- Analytics tracking mirrors existing logging operations
- **Zero extra reads**: Timestamp passed from provider (cached from StreamProvider)

**Validation**:
- ✅ Batch size: 4-5 writes (within limits)
- ✅ Error handling matches existing patterns
- ✅ Debug logging for troubleshooting
- ✅ Inventory check prevents restoring for sessions before activation
- ✅ No extra Firestore reads (uses cached timestamp from provider)

---

#### Step 0.3: Add DeleteFluidSession to LoggingProvider ⬜

**Goal**: Expose delete operation to UI with proper error handling and cache updates.

**Location**: `lib/providers/logging_provider.dart`

**Implementation**:

Add after existing public methods:

```dart
/// Deletes a fluid session with inventory adjustment
///
/// Called from UI (ProgressDayDetailPopup) when user confirms deletion.
/// Handles cache invalidation and analytics tracking.
Future<void> deleteFluidSession({
  required FluidSession session,
}) async {
  final user = _ref.read(currentUserProvider);
  final pet = _ref.read(primaryPetProvider);

  if (user == null || pet == null) {
    throw LoggingException('User or pet not found');
  }

  // Check if inventory is enabled and get activation timestamp (no extra read!)
  final inventoryEnabled = _ref.read(inventoryEnabledProvider);
  final inventoryEnabledAt = inventoryEnabled
      ? _ref.read(inventoryProvider).valueOrNull?.inventory.inventoryEnabledAt
      : null;

  if (kDebugMode) {
    debugPrint(
      '[LoggingProvider] Deleting session ${session.id}, '
      'inventoryEnabled: $inventoryEnabled',
    );
  }

  try {
    // Delete via service (pass cached timestamp to avoid extra read)
    await _ref.read(loggingServiceProvider).deleteFluidSession(
      userId: user.id,
      petId: pet.id,
      session: session,
      updateInventory: inventoryEnabled,
      inventoryEnabledAt: inventoryEnabledAt,
    );

    // Update cache (remove from daily cache)
    await _ref.read(summaryCacheServiceProvider).removeCachedFluidSession(
      session: session,
    );

    // Re-arm/check threshold after restore, using fresh snapshot if available
    if (inventoryEnabled) {
      // Prefer a fresh provider value; if absent, await the stream once
      final inventoryState =
          _ref.read(inventoryProvider).valueOrNull ??
          await _ref.read(inventoryProvider.future);

      if (inventoryState != null) {
        await _checkInventoryThreshold(postLogInventory: inventoryState.inventory);
      }
    }

    // Track analytics
    await _ref.read(analyticsServiceDirectProvider).trackSessionDeletion(
      treatmentType: 'fluid',
      volume: session.volumeGiven,
      inventoryAdjusted: inventoryEnabled,
    );

    if (kDebugMode) {
      debugPrint('[LoggingProvider] Session deleted successfully');
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[LoggingProvider] Delete failed: $e');
    }
    rethrow;
  }
}
```

**Cache Service Extension** (also needed):

**Location**: `lib/features/logging/services/summary_cache_service.dart`

Add method:

```dart
/// Removes a fluid session from today's cache
///
/// Called after deleting a session to keep cache in sync.
Future<void> removeCachedFluidSession({
  required FluidSession session,
}) async {
  final today = AppDateUtils.formatDateForCache(DateTime.now());
  final sessionDate = AppDateUtils.formatDateForCache(session.dateTime);

  // Only update cache if deleting today's session
  if (today != sessionDate) {
    return;
  }

  final currentCache = await _getCachedSummary();
  if (currentCache == null) {
    return; // No cache to update
  }

  // Compute new totals
  final newTotalVolume = currentCache.totalFluidVolumeGiven - session.volumeGiven;
  final newSessionCount = currentCache.fluidSessionCount - 1;

  // Update cache
  final updatedCache = currentCache.copyWith(
    totalFluidVolumeGiven: newTotalVolume,
    fluidSessionCount: newSessionCount,
  );

  await _saveCachedSummary(updatedCache);
}
```

**Validation**:
- ✅ Checks inventory enabled state before calling service
- ✅ Handles cache invalidation for correct UI updates
- ✅ Analytics tracking for monitoring feature usage
- ✅ Error handling with rethrow for UI to display
- ✅ Zero extra reads (passes cached timestamp from provider)

---

#### Step 0.4: Add Delete UI to Progress Day Detail Popup ⬜

**Goal**: Add delete button with confirmation dialog to fluid session list items.

**Location**: `lib/features/progress/widgets/progress_day_detail_popup.dart`

**Implementation**:

Find the section where fluid sessions are displayed (in `_buildFluidSessions` method). Add delete button next to edit icon:

```dart
// In _buildFluidSessionItem method, modify the trailing row

Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    // Existing edit button
    IconButton(
      icon: const Icon(Icons.edit, size: 20),
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(),
      onPressed: () => _editFluidSession(context, ref, session),
      tooltip: 'Edit session',
    ),

    // NEW: Delete button
    IconButton(
      icon: const Icon(Icons.delete_outline, size: 20),
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(),
      color: AppColors.error,
      onPressed: () => _confirmDeleteFluidSession(context, ref, session),
      tooltip: 'Delete session',
    ),
  ],
)

// Add confirmation dialog method
Future<void> _confirmDeleteFluidSession(
  BuildContext context,
  WidgetRef ref,
  FluidSession session,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete Session?'),
      content: Text(
        'Are you sure you want to delete this ${session.volumeGiven.toInt()}mL session?'
        '\n\nThis action cannot be undone.',
        style: AppTextStyles.body,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(foregroundColor: AppColors.error),
          child: const Text('Delete'),
        ),
      ],
    ),
  );

  if (confirmed == true && context.mounted) {
    await _deleteFluidSession(context, ref, session);
  }
}

// Add delete handler method
Future<void> _deleteFluidSession(
  BuildContext context,
  WidgetRef ref,
  FluidSession session,
) async {
  try {
    // Check if inventory is enabled (for snackbar message)
    final inventoryEnabled = ref.read(inventoryEnabledProvider);

    // Delete session via provider
    await ref.read(loggingProvider.notifier).deleteFluidSession(
      session: session,
    );

    if (context.mounted) {
      // Show success message
      String message = 'Session deleted';
      if (inventoryEnabled) {
        message += ' • ${session.volumeGiven.toInt()}mL restored to inventory';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success,
        ),
      );

      // Refresh data to update UI
      ref.invalidate(dayDetailProvider);
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete session: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
```

**Implementation Notes**:
- Delete icon uses `Icons.delete_outline` for consistency
- Error color (`AppColors.error`) indicates destructive action
- Confirmation dialog prevents accidental deletion
- Success message includes inventory restoration info when applicable
- Provider invalidation triggers UI refresh

**Validation**:
- ✅ Matches existing edit button styling
- ✅ Confirmation dialog prevents accidents
- ✅ Clear feedback on success/error
- ✅ Inventory restoration communicated to user

---

#### Step 0.5: Add Analytics Event for Session Deletion ⬜

**Goal**: Track session deletions for monitoring feature usage.

**Location**: `lib/providers/analytics_provider.dart`

**Implementation**:

Add method to `AnalyticsService` class:

```dart
/// Track session deletion with inventory restore info
Future<void> trackSessionDeletion({
  required String treatmentType,
  required double volume,
  required bool inventoryAdjusted,
}) async {
  await _analytics.logEvent(
    name: 'session_deleted',
    parameters: {
      'treatment_type': treatmentType,
      'volume': volume.toInt(),
      'inventory_adjusted': inventoryAdjusted,
      'timestamp': DateTime.now().toIso8601String(),
    },
  );
}
```

Update analytics documentation:

**Location**: `.cursor/reference/analytics_list.md`

Add to end of file:

```markdown
## Session Management

### session_deleted
**When**: User deletes fluid session from progress popup
**Parameters**:
- `treatment_type` (string): "fluid"
- `volume` (int): Volume that was deleted
- `inventory_adjusted` (bool): Whether inventory was restored
- `timestamp` (string): ISO 8601 timestamp
```

**Validation**:
- ✅ Follows existing analytics pattern
- ✅ Privacy-safe (no PII)
- ✅ Useful for feature monitoring

---

### Phase 1: Data Layer - Models & Service ⬜

#### Step 1.1: Create FluidInventory Model ⬜

**Goal**: Create main inventory data model with JSON serialization.

**Location**: `lib/features/inventory/models/fluid_inventory.dart` (NEW FILE)

**Complete Implementation**:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Main fluid inventory document model
///
/// Tracks current fluid supply, refill history, and threshold settings.
/// Single document per user at path: users/{userId}/fluidInventory/main
@immutable
class FluidInventory {
  const FluidInventory({
    required this.id,
    required this.remainingVolume,
    required this.initialVolume,
    required this.reminderSessionsLeft,
    required this.lastRefillDate,
    required this.refillCount,
    required this.inventoryEnabledAt,
    this.lastThresholdNotificationSentAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Document ID (always "main")
  final String id;

  /// Current volume in mL (can be negative if logged while empty)
  final double remainingVolume;

  /// Volume at last refill/reset (used for percentage calculation)
  final double initialVolume;

  /// User setting: notify when X sessions left (1-20, default 10)
  /// Note: Threshold volume is computed dynamically, not stored
  final int reminderSessionsLeft;

  /// Last refill date (for UI display)
  final DateTime lastRefillDate;

  /// Lifetime refill counter
  final int refillCount;

  /// When user first activated inventory tracking
  final DateTime inventoryEnabledAt;

  /// When threshold notification was last sent (null if not sent yet)
  final DateTime? lastThresholdNotificationSentAt;

  /// Document creation timestamp
  final DateTime createdAt;

  /// Last update timestamp
  final DateTime updatedAt;

  /// Create from Firestore document
  factory FluidInventory.fromJson(Map<String, dynamic> json) {
    return FluidInventory(
      id: json['id'] as String,
      remainingVolume: (json['remainingVolume'] as num).toDouble(),
      initialVolume: (json['initialVolume'] as num).toDouble(),
      reminderSessionsLeft: json['reminderSessionsLeft'] as int,
      lastRefillDate: (json['lastRefillDate'] as Timestamp).toDate(),
      refillCount: json['refillCount'] as int,
      inventoryEnabledAt: (json['inventoryEnabledAt'] as Timestamp).toDate(),
      lastThresholdNotificationSentAt: json['lastThresholdNotificationSentAt'] != null
          ? (json['lastThresholdNotificationSentAt'] as Timestamp).toDate()
          : null,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'remainingVolume': remainingVolume,
      'initialVolume': initialVolume,
      'reminderSessionsLeft': reminderSessionsLeft,
      'lastRefillDate': Timestamp.fromDate(lastRefillDate),
      'refillCount': refillCount,
      'inventoryEnabledAt': Timestamp.fromDate(inventoryEnabledAt),
      if (lastThresholdNotificationSentAt != null)
        'lastThresholdNotificationSentAt': Timestamp.fromDate(lastThresholdNotificationSentAt!),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create copy with updated fields
  FluidInventory copyWith({
    String? id,
    double? remainingVolume,
    double? initialVolume,
    int? reminderSessionsLeft,
    DateTime? lastRefillDate,
    int? refillCount,
    DateTime? inventoryEnabledAt,
    DateTime? lastThresholdNotificationSentAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FluidInventory(
      id: id ?? this.id,
      remainingVolume: remainingVolume ?? this.remainingVolume,
      initialVolume: initialVolume ?? this.initialVolume,
      reminderSessionsLeft: reminderSessionsLeft ?? this.reminderSessionsLeft,
      lastRefillDate: lastRefillDate ?? this.lastRefillDate,
      refillCount: refillCount ?? this.refillCount,
      inventoryEnabledAt: inventoryEnabledAt ?? this.inventoryEnabledAt,
      lastThresholdNotificationSentAt: lastThresholdNotificationSentAt ?? this.lastThresholdNotificationSentAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FluidInventory &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          remainingVolume == other.remainingVolume &&
          initialVolume == other.initialVolume &&
          reminderSessionsLeft == other.reminderSessionsLeft &&
          lastRefillDate == other.lastRefillDate &&
          refillCount == other.refillCount &&
          inventoryEnabledAt == other.inventoryEnabledAt &&
          lastThresholdNotificationSentAt == other.lastThresholdNotificationSentAt &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
        id,
        remainingVolume,
        initialVolume,
        reminderSessionsLeft,
        lastRefillDate,
        refillCount,
        inventoryEnabledAt,
        lastThresholdNotificationSentAt,
        createdAt,
        updatedAt,
      );

  @override
  String toString() {
    return 'FluidInventory('
        'id: $id, '
        'remainingVolume: $remainingVolume, '
        'initialVolume: $initialVolume, '
        'reminderSessionsLeft: $reminderSessionsLeft, '
        'lastRefillDate: $lastRefillDate, '
        'refillCount: $refillCount, '
        'inventoryEnabledAt: $inventoryEnabledAt, '
        'lastThresholdNotificationSentAt: $lastThresholdNotificationSentAt, '
        'createdAt: $createdAt, '
        'updatedAt: $updatedAt'
        ')';
  }
}
```

**Validation**:
- ✅ Immutable with `@immutable` annotation
- ✅ Timestamp conversion handled correctly
- ✅ Nullable `lastThresholdNotificationSentAt` handled
- ✅ Complete equality and hashCode implementation
- ✅ Follows existing model patterns (HealthParameter, DailySummary)

---

#### Step 1.2: Create InventoryState Model ⬜

**Goal**: Create UI state model with computed display values for inventory screen.

**Location**: `lib/features/inventory/models/inventory_state.dart` (NEW FILE)

**Key Fields**:
- `inventory: FluidInventory` - Raw inventory document
- `sessionsLeft: int` - Computed from calculateMetrics()
- `estimatedEndDate: DateTime?` - Computed end date or null
- `displayVolume: double` - max(0, remainingVolume) for UI
- `displayPercentage: double` - max(0%, percentage) for UI
- `isNegative: bool` - Whether remainingVolume < 0
- `overageVolume: double` - abs(remainingVolume) when negative

**Computed Getters**:
- `displayVolumeText: String` - "2,350 mL" formatted
- `displayPercentageText: String` - "47%" formatted
- `sessionsLeftText: String` - "15 sessions" with pluralization
- `estimatedEndDateText: String?` - "Est. empty on Dec 18" or null
- `overageText: String?` - "You have logged XmL while inventory was empty" or null

**Implementation Notes**:
- Immutable model with `@immutable` annotation
- All display logic encapsulated (no formatting in widgets)
- Uses `AppDateUtils.formatDate()` for date formatting
- Handles edge cases (no schedules, negative volume)

**Validation**:
- ✅ Follows existing state model patterns
- ✅ Proper null handling for optional fields
- ✅ Complete equality and hashCode
- ✅ Meaningful toString() for debugging

---

#### Step 1.3: Create InventoryCalculations Model ⬜

**Goal**: Create model for calculation results (sessions left, end date, etc.).

**Location**: `lib/features/inventory/models/inventory_calculations.dart` (NEW FILE)

**Key Fields**:
- `sessionsLeft: int` - Computed sessions remaining
- `estimatedEndDate: DateTime?` - Computed end date or null if no schedules
- `averageVolumePerSession: double` - Used for threshold calculation
- `totalDailyVolume: double` - Sum of all daily fluid needs

**Implementation Notes**:
- Returned by `InventoryService.calculateMetrics()`
- Immutable data class
- All fields computed from inventory + schedules
- No UI formatting (pure data)

**Validation**:
- ✅ Simple data class (no business logic)
- ✅ Clear field names match formulas
- ✅ Nullable estimatedEndDate for edge cases

---

#### Step 1.4: Create RefillEntry Model ⬜

**Goal**: Create model for refill history entries.

**Location**: `lib/features/inventory/models/refill_entry.dart` (NEW FILE)

**Key Fields**:
- `id: String` - Auto-generated document ID
- `volumeAdded: double` - mL added (always positive)
- `totalAfterRefill: double` - Snapshot of remainingVolume after refill
- `isReset: bool` - Whether "reset inventory" was used
- `reminderSessionsLeft: int` - Threshold setting at refill time
- `refillDate: DateTime` - When refill occurred
- `createdAt: DateTime`
- `updatedAt: DateTime`

**Implementation Notes**:
- Similar structure to FluidSession model
- Firestore converters (fromJson/toJson with Timestamp handling)
- Used for future refill history feature
- Immutable with complete equality

**Validation**:
- ✅ Follows existing model patterns
- ✅ Timestamp conversion
- ✅ Required for refills subcollection writes

---

#### Step 1.5: Create InventoryService ⬜

**Goal**: Implement complete service layer for all inventory operations.

**Location**: `lib/features/inventory/services/inventory_service.dart` (NEW FILE)

**Class Structure**:

**Constructor**:
- Optional `FirebaseFirestore` parameter (for testing)
- Stores `_firestore` instance

**Path Helpers** (private methods):
- `_getInventoryRef(String userId)` - Returns DocumentReference for main inventory doc
- `_getRefillsCollectionRef(String userId)` - Returns CollectionReference for refills

**Public Methods**:

1. **`Stream<FluidInventory?> watchInventory(String userId)`**
   - Returns real-time stream of inventory document
   - Maps snapshots to FluidInventory or null if doesn't exist
   - Single source of truth for UI updates

2. **`Future<void> createInventory({required userId, required volumeAdded, required reminderSessionsLeft, bool isReset})`**
   - Creates initial inventory document (first refill)
   - Uses **Firestore transaction** to create both main doc + first refill entry atomically
   - Sets `inventoryEnabledAt` to now
   - Sets `refillCount = 1`, `lastRefillDate = now`
   - **No thresholdVolume parameter** - not persisted
   - **No currentVolume parameter** - reads fresh value in transaction (first refill is always 0)

3. **`Future<void> addRefill({required userId, required volumeAdded, required reminderSessionsLeft, required bool isReset})`**
   - Adds refill to existing inventory
   - **Uses Firestore transaction** (not batch) to prevent race conditions
   - **Reads current remainingVolume atomically** from Firestore (ignores stale UI state)
   - Calculates `newTotal = isReset ? volumeAdded : freshCurrentVolume + volumeAdded`
   - Atomically updates main doc + creates refill entry in transaction
   - Clears `lastThresholdNotificationSentAt` to allow new notification
   - Increments `refillCount`
   - **CRITICAL**: No currentVolume parameter - always reads fresh from Firestore to avoid race conditions
   - **No thresholdVolume parameter** - not persisted

4. **`Future<void> updateVolume({required userId, required double newVolume})`**
   - Manual adjustment (tap-to-edit)
   - Single write: updates `remainingVolume` and `updatedAt`
   - **Also updates `initialVolume` = max(current initialVolume, newVolume)** to keep percentage denominator aligned with the highest known fill level and avoid >100% bars
   - **Requires threshold context**: accept `List<Schedule> schedules` (or a precomputed `thresholdVolume` / `averageVolumePerSession`) so the service can determine if `remainingVolume` is back above the threshold
   - If, with that provided threshold context, `remainingVolume` rises back above the computed threshold, clear `lastThresholdNotificationSentAt` to re-arm notifications (not just on refills)
   - If threshold context is not provided, the caller (provider/UI) must perform a follow-up `checkThresholdAndNotify` using current schedules after the adjustment
   - No refill entry created (simple correction)

5. **`Future<void> checkThresholdAndNotify({required userId, required FluidInventory inventory, required List<Schedule> schedules})`**
   - **Computes threshold dynamically** using `calculateMetrics()` with current schedules
   - Calculates `thresholdVolume = inventory.reminderSessionsLeft × averageVolumePerSession`
   - Checks if `remainingVolume < thresholdVolume` (computed)
   - If already notified (`lastThresholdNotificationSentAt != null`) and `remainingVolume >= thresholdVolume`, clear the flag to re-arm notifications on the next crossing
   - Returns early if still below threshold with a sent flag
   - Fetches pet name for notification
   - Calls `_scheduleInventoryNotification()` (placeholder for Phase 4)
   - Updates `lastThresholdNotificationSentAt` to prevent duplicates
   - **CRITICAL**: Always uses current schedules so threshold adapts to schedule changes

6. **`InventoryCalculations calculateMetrics({required FluidInventory inventory, required List<Schedule> schedules})`**
   - Filters active fluid schedules
   - Computes `totalDailyVolume`, `totalSessionsPerDay`, `averageVolumePerSession`
   - **Clamps negative inventory for calculations**: `safeRemaining = max(0, inventory.remainingVolume)`
   - Computes `sessionsLeft = floor(safeRemaining / averageVolumePerSession)`
   - Computes `daysRemaining = floor(safeRemaining / totalDailyVolume)`
   - Computes `estimatedEndDate = now + Duration(days: daysRemaining)`
   - Warning banner derives from raw negative amount (UI shows overdrawn volume)
   - Returns `InventoryCalculations` with all values
   - Handles edge case: no schedules → returns zeroes with null date

**Private Helper Methods**:
- `_scheduleInventoryNotification()` - Placeholder for notification (implements in Phase 4)

**Transaction Implementation Example**:

```dart
/// Add refill with transaction to prevent race conditions
Future<void> addRefill({
  required String userId,
  required double volumeAdded,
  required int reminderSessionsLeft,
  required bool isReset,
}) async {
  try {
    final inventoryRef = _getInventoryRef(userId);
    final refillRef = _getRefillsCollectionRef(userId).doc();

    await _firestore.runTransaction((transaction) async {
      // STEP 1: Read current inventory atomically (always fresh, never stale)
      final inventorySnap = await transaction.get(inventoryRef);

      if (!inventorySnap.exists) {
        throw Exception('Inventory not found');
      }

      final currentVolume = (inventorySnap.data()!['remainingVolume'] as num).toDouble();

      // STEP 2: Compute new total with fresh data
      final newTotal = isReset ? volumeAdded : currentVolume + volumeAdded;

      // STEP 3: Update inventory document
      transaction.update(inventoryRef, {
        'remainingVolume': newTotal,
        'initialVolume': newTotal,
        'reminderSessionsLeft': reminderSessionsLeft,
        'lastRefillDate': FieldValue.serverTimestamp(),
        'refillCount': FieldValue.increment(1),
        'lastThresholdNotificationSentAt': null, // Clear to allow new notification
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // STEP 4: Create refill history entry
      transaction.set(refillRef, {
        'id': refillRef.id,
        'volumeAdded': volumeAdded,
        'totalAfterRefill': newTotal, // Accurate because we just computed it
        'isReset': isReset,
        'reminderSessionsLeft': reminderSessionsLeft,
        'refillDate': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    if (kDebugMode) {
      debugPrint('[InventoryService] Refill completed: +${volumeAdded}mL');
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[InventoryService] Refill error: $e');
    }
    rethrow;
  }
}
```

**Error Handling**:
- Try-catch blocks with meaningful error messages
- Firebase exceptions logged and rethrown
- Debug logging with `kDebugMode` checks

**Implementation Notes**:
- Mirrors `WeightService` structure for consistency
- All Firestore operations use proper error handling
- **Transactions for refills** (not batch writes) to prevent race conditions with concurrent logging
- Batch writes still used for logging operations (inventory deduction is idempotent)
- Floor() used for conservative estimates

**Validation**:
- ✅ Follows existing service patterns
- ✅ Proper error handling
- ✅ Debug logging
- ✅ Atomic transactions prevent race conditions
- ✅ Never uses stale UI state for refills

---

#### Step 1.6: Create InventoryProvider ⬜

**Goal**: Create Riverpod providers for inventory state management.

**Location**: `lib/providers/inventory_provider.dart` (NEW FILE)

**Providers to Create**:

1. **`inventoryServiceProvider`** (Provider)
   - Returns singleton `InventoryService()` instance
   - Used by other providers to access service methods

2. **`inventoryProvider`** (StreamProvider.autoDispose<InventoryState?>)
   - NOT a family provider - derives userId from `currentUserProvider` internally
   - Watches `currentUserProvider` for userId
   - Returns `Stream.value(null)` if no user logged in
   - Calls `inventoryService.watchInventory(userId)` for real-time stream
   - Maps `FluidInventory?` to `InventoryState?`:
     - If null: returns null (inventory not enabled)
     - If exists: calls `calculateMetrics()` with schedules from `profileProvider`
     - Computes display values (displayVolume, displayPercentage, isNegative, etc.)
     - Returns complete `InventoryState` with all computed fields
   - Auto-disposes when no longer watched

3. **`inventoryEnabledProvider`** (Provider.autoDispose)
   - Derived from `inventoryProvider`
   - Returns `ref.watch(inventoryProvider).valueOrNull != null`
   - Simple boolean check for UI conditionals

**Implementation Example**:

```dart
// Service provider
final inventoryServiceProvider = Provider<InventoryService>((ref) {
  return InventoryService();
});

// Main inventory provider (NOT family - derives userId internally)
final inventoryProvider = StreamProvider.autoDispose<InventoryState?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(null);

  final inventoryService = ref.watch(inventoryServiceProvider);
  final profileAsync = ref.watch(profileProvider);
  final schedules = profileAsync.valueOrNull?.schedules ?? [];

  return inventoryService.watchInventory(user.id).map((inventory) {
    if (inventory == null) return null;

    // Calculate metrics (clamps remainingVolume to >= 0 for computations)
    final calculations = inventoryService.calculateMetrics(
      inventory: inventory,
      schedules: schedules,
    );

    // Build state with computed values
    return InventoryState(
      inventory: inventory,
      sessionsLeft: calculations.sessionsLeft,
      estimatedEndDate: calculations.estimatedEndDate,
      displayVolume: max(0.0, inventory.remainingVolume),
      // Clamp to avoid >100% when manual adjustments raise remainingVolume above initialVolume
      displayPercentage: min(
        1.0,
        max(0.0, inventory.remainingVolume / inventory.initialVolume),
      ),
      isNegative: inventory.remainingVolume < 0,
      overageVolume: inventory.remainingVolume < 0 ? inventory.remainingVolume.abs() : 0,
    );
  });
});

// Simple boolean helper provider
final inventoryEnabledProvider = Provider.autoDispose<bool>((ref) {
  return ref.watch(inventoryProvider).valueOrNull != null;
});
```

**Implementation Notes**:
- Uses StreamProvider for real-time updates (no polling)
- Automatic disposal when screen unmounted
- Calculation happens in provider (not UI)
- Schedules fetched from existing `profileProvider`
- NOT a family provider - simpler usage throughout the app
- User ID derived from `currentUserProvider` (single source of truth)

**Validation**:
- ✅ Follows existing provider patterns (profileProvider, progressProvider)
- ✅ Proper disposal (autoDispose)
- ✅ Efficient (single stream, no redundant queries)
- ✅ Clear separation: service (data), provider (state), UI (display)
- ✅ No family parameter needed - works in all contexts (UI, services, background)

---

### Phase 2: LoggingService Integration ⬜

#### Step 2.1: Modify logFluidSession Method ⬜

**Goal**: Add inventory deduction to existing fluid logging batch.

**Location**: `lib/features/logging/services/logging_service.dart`

**Changes Required**:

1. **Add Parameters**:
   - Add `bool updateInventory = false` to method signature
   - Add `DateTime? inventoryEnabledAt` to method signature
   - Called by LoggingProvider with cached values (no extra reads!)

2. **Inventory Check Logic** (before batch commit):
   - If `updateInventory == true && inventoryEnabledAt != null`:
     - Prefer comparing `session.loggedAt` (or creation timestamp) with `inventoryEnabledAt` so backfilled sessions logged after enable still adjust inventory, and future-dated sessions don’t deduct early
     - Only proceed if the logged-at timestamp is after activation (or same moment); if `loggedAt` absent, fall back to `DateTime.now()` at log time
   - Alternatively: if the inventory document exists (feature enabled), allow adjustment without date comparison to ensure backfills are counted
   - **No Firestore read needed** - timestamp passed from provider

3. **Add 5th Batch Operation** (inventory update):
   - If check passes:
     - Add to batch: `batch.update(inventoryRef, { 'remainingVolume': FieldValue.increment(-session.volumeGiven), 'updatedAt': FieldValue.serverTimestamp() })`
     - Debug log: "Inventory will be updated: -XmL"
   - Batch now has 5 operations: session + 3 summaries + inventory

4. **No Changes to Existing Logic**:
   - Schedule matching unchanged
   - Summary updates unchanged
   - Validation unchanged
   - Only adds conditional inventory update at end

**Implementation Notes**:
- Uses existing `_getInventoryRef()` helper (added in Phase 0)
- Atomic update via `FieldValue.increment()` (race-condition safe)
- **Zero extra reads** - timestamp passed from provider's cached StreamProvider data
- Follows same pattern as monthly array updates

**Validation**:
- ✅ Batch size: 4-5 writes (within limits)
- ✅ Backward compatible (updateInventory defaults to false)
- ✅ Atomic operation (no partial updates)
- ✅ Timestamp check prevents retroactive deductions
- ✅ No extra Firestore reads (uses cached timestamp from provider)

---

#### Step 2.2: Update LoggingProvider to Check Inventory ⬜

**Goal**: Pass inventory enabled flag to LoggingService.

**Location**: `lib/providers/logging_provider.dart`

**Changes Required**:

1. **In `logFluidSession()` Method**:
   - Add before service call: `final inventoryEnabled = _ref.read(inventoryEnabledProvider);`
   - Pass to service: `updateInventory: inventoryEnabled`
   - Debug log inventory status

2. **Add Threshold Check After Successful Logging**:
   - Add after cache update: `if (inventoryEnabled) { await _checkInventoryThreshold(postLogInventory: updatedInventory); }`
   - New private method: `_checkInventoryThreshold()`

3. **Implement `_checkInventoryThreshold()` Method**:
   - Prefer using the known post-log inventory snapshot (from the log operation) to avoid stale provider data
   - Fallback: read latest from `inventoryProvider` if not provided
   - Returns early if null (shouldn't happen but safe)
   - Calls `inventoryService.checkThresholdAndNotify()`, which will also clear `lastThresholdNotificationSentAt` when volume is back above threshold (re-arming notifications regardless of action source)
   - Wrapped in try-catch (non-critical, don't fail logging)
   - Debug logging

**Implementation Example**:

```dart
// In logFluidSession() method
Future<void> logFluidSession({...}) async {
  // Check if inventory is enabled and get activation timestamp (no extra read!)
  final inventoryEnabled = _ref.read(inventoryEnabledProvider);
  final inventoryEnabledAt = inventoryEnabled
      ? _ref.read(inventoryProvider).valueOrNull?.inventory.inventoryEnabledAt
      : null;

  if (kDebugMode) {
    debugPrint('[LoggingProvider] Logging session, inventory enabled: $inventoryEnabled');
  }

  // ... existing validation and logging logic ...

  // Call service with inventory flag and cached timestamp
  await _ref.read(loggingServiceProvider).logFluidSession(
    // ... existing parameters ...
    updateInventory: inventoryEnabled,
    inventoryEnabledAt: inventoryEnabledAt, // ✅ Cached from provider - no extra read
  );

  // ... existing cache update logic ...

  // Check threshold after successful logging using fresh post-deduction inventory
  if (inventoryEnabled) {
    // Build a minimal fresh snapshot using the known new remainingVolume
    final currentInventoryState = _ref.read(inventoryProvider).valueOrNull;
    if (currentInventoryState == null) {
      if (kDebugMode) {
        debugPrint('[LoggingProvider] Inventory state unavailable, skipping immediate threshold check');
      }
    } else {
      final freshInventory = currentInventoryState.inventory.copyWith(
        remainingVolume: currentInventoryState.inventory.remainingVolume - session.volumeGiven,
        updatedAt: DateTime.now(),
      );
      await _checkInventoryThreshold(postLogInventory: freshInventory);
    }
  }
}

// New private method
Future<void> _checkInventoryThreshold({
  FluidInventory? postLogInventory, // prefer fresh snapshot right after log
}) async {
  try {
    // Prefer the freshly computed post-log inventory to avoid stale provider data
    final providedInventory = postLogInventory;

    // Fallback to provider if none provided
    final inventoryState = providedInventory != null
        ? InventoryState(
            inventory: providedInventory,
            sessionsLeft: 0, // will be recalculated inside checkThreshold
            estimatedEndDate: null,
            displayVolume: max(0.0, providedInventory.remainingVolume),
            displayPercentage: 0,
            isNegative: providedInventory.remainingVolume < 0,
            overageVolume: providedInventory.remainingVolume < 0
                ? providedInventory.remainingVolume.abs()
                : 0,
          )
        : await _ref.read(inventoryProvider.future);

    if (inventoryState == null) {
      if (kDebugMode) {
        debugPrint('[LoggingProvider] Inventory state null, skipping threshold check');
      }
      return;
    }

    final user = _ref.read(currentUserProvider);
    if (user == null) return;

    // Get current schedules from profile provider
    final profileState = await _ref.read(profileProvider.future);
    final schedules = profileState?.schedules ?? [];

    // Pass current schedules so threshold is computed dynamically
    await _ref.read(inventoryServiceProvider).checkThresholdAndNotify(
      userId: user.id,
      inventory: inventoryState.inventory,
      schedules: schedules, // ✅ Current schedules for accurate threshold
    );
  } catch (e) {
    // Non-critical - don't fail logging if threshold check fails
    if (kDebugMode) {
      debugPrint('[LoggingProvider] Threshold check error: $e');
    }
  }
}
```

**Implementation Notes**:
- Minimal changes to existing flow
- Threshold check non-blocking (don't await)
- Error in threshold check doesn't affect logging success
- Clear debug trail for troubleshooting
- **Zero extra reads** - timestamp cached from StreamProvider

**Validation**:
- ✅ Single source of truth (inventoryEnabledProvider)
- ✅ Zero Firestore reads (timestamp from cached StreamProvider data)
- ✅ Graceful error handling
- ✅ Logging succeeds even if threshold check fails

---

### Phase 3: UI Components ⬜

#### Step 3.1: Create InventoryScreen ⬜

**Goal**: Build main inventory screen with progress bar, estimates, and manual adjustment.

**Location**: `lib/features/inventory/screens/inventory_screen.dart` (NEW FILE)

**Screen Structure**:

**Scaffold**:
- AppBar: Title "Inventory", actions: [IconButton "Add" (+ icon) opens refill popup if inventory exists]
- Body: `_buildBody()` method switches between empty state and content
- backgroundColor: `AppColors.background`

**Empty State** (`_buildEmptyState()` method):
- Center-aligned Column with:
  - Large icon: `Icons.inventory_2_outlined` (size 80, tertiary color)
  - Title: "Track Your Fluid Inventory" (h2 style)
  - Description: Multi-line explanation text (body style, secondary color)
  - Spacer (xl)
  - HydraButton: "Start Tracking" opens refill popup with null currentInventory

**Content State** (`_buildInventoryContent()` method):
- SingleChildScrollView with padding (lg)
- Column with sections separated by SizedBox(xl):

1. **Progress Section** (`_buildProgressSection()`):
   - HydraCard with contentPadding
   - Tappable volume header (InkWell) opens adjustment dialog:
     - Label "Current Inventory" (caption, secondary)
     - Large volume text with color based on percentage
     - Edit icon (20px, tertiary)
   - Progress bar (LinearProgressIndicator):
     - Height 24px, rounded corners (8px)
     - Color based on percentage (>50%: green, 25-50%: orange, <25%: red)
     - Background: surfaceVariant
   - Percentage text (caption, right-aligned)
   - Negative inventory warning (if isNegative):
     - Container with red background (10% opacity), red border
     - Warning icon + overageText
     - Only shown when remainingVolume < 0

2. **Estimates Section** (`_buildEstimatesSection()`):
   - HydraCard with contentPadding
   - Title "Estimates" (h3)
   - Two estimate rows (`_buildEstimateRow()` helper):
     - Sessions remaining: Icon + label + value
     - Estimated end date: Icon + label + value
     - Value shows "Unable to estimate" if no schedules

3. **Last Refill Section** (`_buildLastRefillSection()`):
   - HydraCard with contentPadding
   - Row with label/value and refill count
   - Label: "Last Refill"
   - Value: Formatted date from inventory.lastRefillDate
   - Right side: "X total refills" (caption, secondary)

**Helper Methods**:

- `_getColorForPercentage(double percentage)`: Returns green/orange/red based on thresholds
- `_buildEstimateRow()`: Reusable row widget for estimates section
- `_showRefillPopup()`: Calls showHydraBottomSheet with RefillPopup
- `_showVolumeAdjustmentDialog()`: Shows AlertDialog with TextField (implementation in Step 3.3)

**State Management**:
- ConsumerWidget watching `inventoryProvider`
- No local state (all from provider)
- Reactive to inventory changes

**Implementation Example**:

```dart
class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventoryAsync = ref.watch(inventoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        actions: inventoryAsync.valueOrNull != null
            ? [
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _showRefillPopup(context, ref),
                ),
              ]
            : null,
      ),
      body: inventoryAsync.when(
        data: (inventoryState) => inventoryState != null
            ? _buildInventoryContent(inventoryState)
            : _buildEmptyState(),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  // ... helper methods
}
```

**Validation**:
- ✅ Matches existing screen patterns (WeightScreen, SymptomsScreen)
- ✅ Uses existing components (HydraCard, HydraButton)
- ✅ Proper spacing and padding
- ✅ Color coding for visual feedback

---

#### Step 3.2: Create RefillPopup Widget ⬜

**Goal**: Build bottom sheet for adding refills with live preview and threshold slider.

**Location**: `lib/features/inventory/widgets/refill_popup.dart` (NEW FILE)

**Widget Type**: ConsumerStatefulWidget (needs local state for inputs)

**Local State Fields**:
- `_selectedVolume: double` - Volume per bag/bottle (0, 500, or 1000)
- `_quantity: int` - Number of bags (default 1)
- `_reminderSessionsLeft: int` - Threshold slider value (default 10)
- `_isReset: bool` - Reset toggle state (default false)
- `_customVolumeController: TextEditingController` - For custom input
- `_isSaving: bool` - Loading state during save

**Computed Properties**:
- `_totalVolumeAdded`: `_selectedVolume * _quantity`
- `_currentVolume`: From `widget.currentInventory?.inventory.remainingVolume ?? 0`
- `_newTotal`: `_isReset ? _totalVolumeAdded : _currentVolume + _totalVolumeAdded`

**Layout Structure** (Column with sections):

1. **Header** (`_buildHeader()`):
   - Row with title "Refill Inventory" and close button
   - Close button calls Navigator.pop()

2. **Quick Select** (`_buildQuickSelect()`):
   - Label "Quick Select"
   - Wrap with FilterChip for 500mL and 1000mL
   - Chips update `_selectedVolume` and clear custom input

3. **Custom Input** (`_buildCustomInput()`):
   - Label "Or Enter Custom Volume"
   - TextField with number keyboard, suffixText "mL"
   - onChanged updates `_selectedVolume` from parsed value

4. **Quantity Selector** (`_buildQuantitySelector()`):
   - Row with label "Quantity" and +/- buttons
   - IconButton (-) decrements (disabled at 1)
   - Text widget shows current quantity
   - IconButton (+) increments

5. **Reset Toggle** (`_buildResetToggle()`) - only if currentInventory != null:
   - CheckboxListTile: "Reset inventory (ignore current amount)"
   - Updates `_isReset` state

6. **Live Preview** (`_buildLivePreview()`):
   - Container with primary color background (10% opacity), primary border
   - If not reset mode and inventory exists:
     - Show "Current: X mL"
     - Show "Adding: +Y mL"
     - Divider
   - Show "New Inventory: Z mL" (large, bold)

7. **Reminder Slider** (`_buildReminderSlider()`):
   - Label "Remind me when low" + current value "X sessions left"
   - Slider (1-20, divisions 19)
   - Caption "Remind at ~X mL" (preview using current schedules)
   - **Note**: This is just a preview - actual threshold recomputed on each check

8. **Save Button** (`_buildSaveButton()`):
   - HydraButton with label "Save"
   - Disabled if `_totalVolumeAdded <= 0`
   - Shows loading indicator if `_isSaving`
   - Calls `_handleSave()` on press

**Save Handler** (`_handleSave()` method):
- Sets `_isSaving = true`
- Gets user from `currentUserProvider`
- Gets service from `inventoryServiceProvider`
- Checks if first refill (currentInventory == null):
  - Yes: calls `service.createInventory()` with `reminderSessionsLeft`
  - No: calls `service.addRefill()` with `reminderSessionsLeft` and `isReset`
- **CRITICAL**: Does NOT pass `currentVolume` - service reads fresh value in transaction
- On success:
  - Pops dialog
  - Shows success snackbar: "Inventory updated: X mL"
- On error:
  - Shows error snackbar
  - Sets `_isSaving = false`

**Implementation Example**:

```dart
Future<void> _handleSave() async {
  setState(() => _isSaving = true);

  try {
    final user = ref.read(currentUserProvider);
    if (user == null) throw Exception('No user');

    final service = ref.read(inventoryServiceProvider);

    if (widget.currentInventory == null) {
      // First refill - create inventory
      await service.createInventory(
        userId: user.id,
        volumeAdded: _totalVolumeAdded,
        reminderSessionsLeft: _reminderSessionsLeft,
      );
    } else {
      // Subsequent refill
      await service.addRefill(
        userId: user.id,
        volumeAdded: _totalVolumeAdded,
        reminderSessionsLeft: _reminderSessionsLeft,
        isReset: _isReset,
        // ✅ NO currentVolume parameter - service reads fresh in transaction
      );
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Inventory updated: ${_newTotal.toInt()} mL')),
      );
    }
  } catch (e) {
    setState(() => _isSaving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
      );
    }
  }
}
```

**Implementation Notes**:
- Follows existing bottom sheet patterns (WeightEntryDialog, SymptomsEntryDialog)
- Live preview updates on every state change (reactive)
- Threshold preview is for UI only - not persisted
- Actual threshold computed dynamically in `checkThresholdAndNotify()` using current schedules
- Proper disposal of TextEditingController
- **Race-condition safe**: Never passes currentVolume from UI - service reads fresh in transaction

**Validation**:
- ✅ Uses HydraBottomSheet for consistent styling
- ✅ Live preview for user confidence
- ✅ Clear feedback on success/error
- ✅ Input validation (quantity >= 1, volume > 0)

---

#### Step 3.3: Add Volume Adjustment Dialog to InventoryScreen ⬜

**Goal**: Implement tap-to-edit volume adjustment dialog.

**Location**: `lib/features/inventory/screens/inventory_screen.dart` (add method)

**Implementation**:

Add private method `_showVolumeAdjustmentDialog()`:
- Called when user taps on volume in progress section
- Shows AlertDialog with:
  - Title: "Adjust Inventory"
  - Content: TextField (number keyboard, suffixText "mL", helperText for guidance)
  - Pre-filled with current volume (converted to int)
  - Actions: Cancel button, Save button
- On save:
  - Parses value from TextField
  - Calls `inventoryService.updateVolume()` **with threshold context** (pass schedules/average or a precomputed threshold), or immediately follows with `_checkInventoryThreshold()` using current schedules so `lastThresholdNotificationSentAt` can be re-armed if volume is now above threshold
  - Shows snackbar: "Inventory updated: X mL"
  - Pops dialog
- On error: Shows error snackbar

**Implementation Notes**:
- Simple AlertDialog (not bottom sheet, for quick edit)
- Similar pattern to delete confirmation (Phase 0)
- Uses provider for service access
- Proper error handling

**Validation**:
- ✅ Quick interaction (minimal taps)
- ✅ Clear purpose (adjustment, not refill)
- ✅ Immediate feedback

---

### Phase 4: Notification Integration ⬜

#### Step 4.1: Complete checkThresholdAndNotify Implementation ⬜

**Goal**: Implement notification logic for low inventory alerts.

**Location**: `lib/features/inventory/services/inventory_service.dart` (update placeholder method)

**Implementation**:

Complete the `_scheduleInventoryNotification()` method:
- Called from `checkThresholdAndNotify()` when threshold crossed
- Uses existing notification infrastructure (similar to medication/fluid reminders)
- Notification content:
  - Title: "Fluid Inventory Low"
  - Body: "Only X mL left (~Y sessions) for [PetName]"
- Integration approach:
  - If NotificationCoordinator has inventory method: use it
  - Otherwise: directly use ReminderPlugin (temporary)
- Debug logging for verification

**Implementation Notes**:
- Reuses existing notification patterns
- Pet name fetched before calling this method
- No need for scheduling (fires immediately)
- One-time notification (not repeating)

**Validation**:
- ✅ Consistent with existing notifications
- ✅ Clear, actionable message
- ✅ Respects notification permissions

---

### Phase 5: Profile Screen Integration ⬜

#### Step 5.1: Add Inventory Card to Profile Screen ⬜

**Goal**: Add inventory navigation card to profile sections list.

**Location**: `lib/features/profile/screens/profile_screen.dart`

**Changes Required**:

In `_buildProfileSections()` method, after the Weight section:
- Add conditional: `if (profileState.hasFluidSchedule)`
- Add Consumer widget watching `inventoryProvider`
- Compute metadata string:
  - If inventory exists: "X mL remaining (~Y sessions)"
  - If null: "Track your fluid supply"
- Create NavigationCard with:
  - title: "Inventory"
  - icon: `Icons.inventory_2`
  - metadata: computed string
  - onTap: `context.push('/profile/inventory')`
  - margin: EdgeInsets.zero

**Implementation Example**:

```dart
// In _buildProfileSections() method
if (profileState.hasFluidSchedule)
  Consumer(
    builder: (context, ref, child) {
      final inventoryState = ref.watch(inventoryProvider).valueOrNull;

      final metadata = inventoryState != null
          ? '${inventoryState.displayVolume.toInt()} mL remaining (~${inventoryState.sessionsLeft} sessions)'
          : 'Track your fluid supply';

      return NavigationCard(
        title: 'Inventory',
        icon: Icons.inventory_2,
        metadata: metadata,
        onTap: () => context.push('/profile/inventory'),
        margin: EdgeInsets.zero,
      );
    },
  ),
```

**Implementation Notes**:
- Only shown if user has fluid schedule (inventory meaningless without)
- Uses Consumer for reactive metadata
- No userId parameter needed - provider derives it internally
- Follows existing pattern (Weight card, CKD Profile card)

**Validation**:
- ✅ Conditional rendering (only if relevant)
- ✅ Clear metadata shows value
- ✅ Consistent with other cards

---

#### Step 5.2: Add Route to Router ⬜

**Goal**: Wire up navigation to inventory screen.

**Location**: `lib/app/router.dart`

**Changes Required**:

In profile routes section, add:
- Path: `'inventory'`
- Name: `'inventory'`
- pageBuilder with `CustomTransitionPage`:
  - child: `const InventoryScreen()`
  - transitionsBuilder: `_slideTransition` (matches other profile routes)

**Validation**:
- ✅ Consistent transition animation
- ✅ Proper route naming
- ✅ Back button works correctly

---

### Phase 6: Firestore Schema & Rules ⬜

#### Step 6.1: Update Firestore Schema Documentation ⬜

**Goal**: Document inventory schema in firestore_schema.md.

**Location**: `.cursor/rules/firestore_schema.md`

**Changes Required**:

1. Update implementation status:
   - Move `fluidInventory` from "Planned" to "Fully Implemented"

2. Add detailed schema (already in plan, verify completeness):
   - Main inventory document fields
   - Refills subcollection fields
   - Query patterns
   - Cost analysis

**Validation**:
- ✅ Schema matches implementation
- ✅ Query patterns documented
- ✅ Cost estimates accurate

---

#### Step 6.2: Add Firestore Security Rules ⬜

**Goal**: Protect inventory data with proper access controls.

**Location**: `firestore.rules`

**Rules to Add**:

For `users/{userId}/fluidInventory/{inventoryId}`:
- Helper: `isOwner()` checks `request.auth.uid == userId`
- Helper: `isValidInventory(data)` validates all required fields and types
- allow read: if isOwner()
- allow create: if isOwner() && isValidInventory()
- allow update: if isOwner() && isValidInventory()
- allow delete: if false (inventory permanent once created)

For `users/{userId}/fluidInventory/{inventoryId}/refills/{refillId}`:
- Helper: `isValidRefill(data)` validates refill fields
- allow read: if isOwner()
- allow create: if isOwner() && isValidRefill() (append-only)
- allow update, delete: if false (refills immutable)

**Validation**:
- ✅ Owner-only access
- ✅ Validation on all writes
- ✅ Immutability enforced (refills, no inventory deletion)
- ✅ Follows existing rules patterns

---

#### Step 6.3: Deploy Rules ⬜

**Goal**: Deploy rules to development Firebase project.

**Command**: `firebase deploy --only firestore:rules --project hydracattest`

**Validation**:
- ✅ Deployment succeeds
- ✅ Manual test: create/read inventory works
- ✅ Manual test: unauthorized access blocked

---

### Phase 7: Analytics & Testing ⬜

#### Step 7.1: Add Inventory Analytics Events ⬜

**Goal**: Track inventory feature usage.

**Location**: `lib/providers/analytics_provider.dart`

**Events to Add**:

1. `trackInventoryActivated()` - First refill
   - Parameters: initialVolume, reminderSessionsLeft

2. `trackInventoryRefill()` - Subsequent refills
   - Parameters: volumeAdded, totalAfterRefill, isReset, refillNumber

3. `trackInventoryAdjustment()` - Manual edits
   - Parameters: oldVolume, newVolume, delta

4. `trackInventoryThresholdNotification()` - Low inventory alert
   - Parameters: remainingVolume, sessionsLeft

**Documentation**:
Update `.cursor/reference/analytics_list.md` with all event details.

**Validation**:
- ✅ Privacy-safe (no PII)
- ✅ Useful for feature monitoring
- ✅ Follows existing patterns

---

#### Step 7.2: Wire Analytics in Service & UI ⬜

**Goal**: Call analytics methods from appropriate locations.

**Locations**:

1. **InventoryService.createInventory()**: Call `trackInventoryActivated()`
2. **InventoryService.addRefill()**: Call `trackInventoryRefill()`
3. **InventoryService.updateVolume()**: Call `trackInventoryAdjustment()`
4. **InventoryService.checkThresholdAndNotify()**: Call `trackInventoryThresholdNotification()`

**Implementation Notes**:
- All calls wrapped in try-catch (analytics failures don't affect operations)
- Use `AnalyticsService?` parameter (optional dependency)
- Debug logging for verification

**Validation**:
- ✅ Non-blocking analytics
- ✅ Coverage for all key actions
- ✅ Proper error handling

---

#### Step 7.3: Manual Testing Checklist ⬜

**Critical Flows to Test**:

1. **First-Time Activation**:
   - [ ] Profile card shows "Track your fluid supply"
   - [ ] Tap card → Empty state with explanation
   - [ ] Tap "Start Tracking" → Refill popup opens
   - [ ] Enter 1000mL, set threshold to 10 sessions
   - [ ] Save succeeds → Inventory screen shows progress bar
   - [ ] Progress bar shows 100%, volume correct
   - [ ] Sessions left calculated correctly
   - [ ] Estimated end date shown (if schedules exist)

2. **Automatic Deduction**:
   - [ ] Log fluid session (100mL)
   - [ ] Inventory updates automatically (900mL remaining)
   - [ ] Progress bar updates (90%)
   - [ ] Sessions left decrements
   - [ ] No notification (above threshold)

3. **Threshold Notification**:
   - [ ] Log sessions until below threshold
   - [ ] Notification fires once
   - [ ] Notification message correct
   - [ ] Subsequent sessions: no duplicate notification

4. **Manual Adjustment**:
   - [ ] Tap volume number → Dialog opens
   - [ ] Enter new value → Save succeeds
   - [ ] Volume updates immediately
   - [ ] Snackbar shows confirmation

5. **Refill Flow**:
   - [ ] Tap "+" button → Refill popup opens
   - [ ] Quick select chips work
   - [ ] Custom input works
   - [ ] Quantity +/- buttons work
   - [ ] Live preview updates correctly
   - [ ] Reset toggle changes behavior (additive vs absolute)
   - [ ] Threshold slider updates preview
   - [ ] Save succeeds → Inventory updated
   - [ ] Notification cleared (can fire again)

6. **Session Deletion**:
   - [ ] Delete fluid session → Confirmation dialog
   - [ ] Confirm → Inventory restored
   - [ ] Snackbar shows "+XmL restored to inventory"
   - [ ] Sessions only logged after inventoryEnabledAt restored

7. **Negative Inventory**:
   - [ ] Log sessions beyond available volume
   - [ ] Progress bar shows 0%
   - [ ] Warning message displays: "You have logged XmL while inventory was empty"
   - [ ] Refill with additive mode: -200 + 1000 = 800mL ✓
   - [ ] Refill with reset mode: ignore -200, set to 1000mL ✓

8. **No Schedules Edge Case**:
   - [ ] Disable all fluid schedules
   - [ ] Inventory screen shows "Unable to estimate (no active schedules)"
   - [ ] Refill still works
   - [ ] Manual adjustment still works

**Validation**:
- ✅ All flows work end-to-end
- ✅ No crashes or errors
- ✅ UI updates properly
- ✅ Edge cases handled gracefully

---

### Phase 8: Polish & Deployment ⬜

#### Step 8.1: Run Flutter Analyze ⬜

**Command**: `flutter analyze`

**Fix All Issues**:
- Critical errors (must fix)
- Warnings (must fix)
- Info-level suggestions (fix if reasonable)
- Linting issues (must fix)

**Common Issues to Watch For**:
- Missing trailing commas
- Unused imports
- Non-const constructors that could be const
- Prefer `final` for fields
- Missing `@override` annotations

**Validation**:
- ✅ Zero issues in `flutter analyze` output
- ✅ Code formatted with `dart format`

---

#### Step 8.2: Final Manual Testing ⬜

**Full Feature Test**:
- [ ] Install fresh build on device
- [ ] Complete onboarding → set up fluid schedule
- [ ] Activate inventory → first refill
- [ ] Log multiple sessions → verify deductions
- [ ] Hit threshold → verify notification
- [ ] Refill → verify update and notification reset
- [ ] Manual adjustment → verify update
- [ ] Delete session → verify restoration
- [ ] Go negative → verify warning
- [ ] Test all edge cases from 7.3

**Performance Check**:
- [ ] Inventory screen loads < 100ms
- [ ] Refill popup opens instantly
- [ ] Progress bar updates smoothly
- [ ] No UI lag during operations

**Validation**:
- ✅ Feature works perfectly
- ✅ No performance issues
- ✅ All feedback clear and helpful

---

#### Step 8.3: Update Documentation ⬜

**Files to Update**:

1. **CLAUDE.md**: Add inventory tracking to feature list (if needed)
2. **~PLANNING/inventory_tracking.md**: Mark all steps as completed ✅
3. Move plan to **~PLANNING/DONE/** when fully implemented

**Validation**:
- ✅ Documentation reflects reality
- ✅ Future Claude has clear context

---

## Implementation Checklist

### Phase 0: Session Deletion (Prerequisite) ⬜
- [ ] Step 0.1: Add forFluidSessionDelete to SummaryUpdateDto
- [ ] Step 0.2: Add deleteFluidSession to LoggingService
- [ ] Step 0.3: Add deleteFluidSession to LoggingProvider + cache service
- [ ] Step 0.4: Add delete UI to ProgressDayDetailPopup
- [ ] Step 0.5: Add analytics event for session deletion
- [ ] Test: Delete session without inventory (summaries update correctly)
- [ ] Test: Delete session with inventory (volume restored)

### Phase 1: Data Layer ⬜
- [ ] Step 1.1: Create FluidInventory model
- [ ] Step 1.2: Create InventoryState model
- [ ] Step 1.3: Create InventoryCalculations model
- [ ] Step 1.4: Create RefillEntry model
- [ ] Step 1.5: Create InventoryService (all methods)
- [ ] Step 1.6: Create InventoryProvider (all providers)
- [ ] Test: Unit tests for models (serialization, equality)
- [ ] Test: Unit tests for calculateMetrics (various scenarios)

### Phase 2: LoggingService Integration ⬜
- [ ] Step 2.1: Add updateInventory parameter to logFluidSession
- [ ] Step 2.2: Update LoggingProvider to check inventory and call threshold
- [ ] Test: Log session with inventory enabled (5 writes)
- [ ] Test: Log session with inventory disabled (4 writes)
- [ ] Test: Inventory only deducts for sessions after inventoryEnabledAt
- [ ] Test: Threshold check fires when crossed

### Phase 3: UI Components ⬜
- [ ] Step 3.1: Create InventoryScreen (all sections)
- [ ] Step 3.2: Create RefillPopup (all sections + save logic)
- [ ] Step 3.3: Add volume adjustment dialog
- [ ] Test: Empty state displays correctly
- [ ] Test: Progress bar colors match thresholds
- [ ] Test: Refill popup live preview updates correctly
- [ ] Test: Manual adjustment updates immediately

### Phase 4: Notification Integration ⬜
- [ ] Step 4.1: Complete checkThresholdAndNotify implementation
- [ ] Test: Notification fires when threshold crossed
- [ ] Test: Notification only fires once
- [ ] Test: Notification clears on refill

### Phase 5: Profile Integration ⬜
- [ ] Step 5.1: Add inventory card to profile screen
- [ ] Step 5.2: Add route to router
- [ ] Test: Card shows correct metadata
- [ ] Test: Navigation works
- [ ] Test: Card only shows if fluid schedule exists

### Phase 6: Firestore Schema ⬜
- [ ] Step 6.1: Update firestore_schema.md
- [ ] Step 6.2: Add security rules
- [ ] Step 6.3: Deploy rules to development
- [ ] Test: Authorized access works
- [ ] Test: Unauthorized access blocked
- [ ] Test: Validation rules enforce schema

### Phase 7: Analytics & Testing ⬜
- [ ] Step 7.1: Add analytics events to service
- [ ] Step 7.2: Wire analytics in service/UI
- [ ] Step 7.3: Complete manual testing checklist
- [ ] Test: All analytics events fire
- [ ] Test: All edge cases covered

### Phase 8: Polish ⬜
- [ ] Step 8.1: Run flutter analyze (0 issues)
- [ ] Step 8.2: Final manual testing on device
- [ ] Step 8.3: Update documentation
- [ ] Move plan to ~PLANNING/DONE/

---

## Success Criteria

This feature is complete when:
1.  ✅ Users can activate inventory tracking via "+ Refill" button
2.  ✅ Inventory automatically deducts volume during fluid logging
3.  ✅ Progress bar shows volume and percentage with color coding
4.  ✅ Sessions left and end date calculations are accurate (floor rounding)
5.  ✅ Negative inventory displays warning with overage amount
6.  ✅ Tap-to-edit allows quick manual adjustments
7.  ✅ Refill popup shows live preview and threshold slider
8.  ✅ Threshold notification fires once when low
9.  ✅ Session deletion restores inventory (if after enabled date)
10. ✅ Profile screen shows inventory card (when fluid schedule exists)
11. ✅ No schedules edge case shows "Unable to estimate"
12. ✅ All linting issues resolved (`flutter analyze` passes)
13. ✅ Unit tests cover calculation logic
14. ✅ Manual testing checklist 100% complete
15. ✅ Analytics events track key actions

---

**Document Status**: Ready for Implementation
**Estimated Development Time**: 12-16 hours
**Dependencies**: Session deletion (prerequisite), existing logging system, profile provider
**Risk Level**: Low-Medium (new feature, schema changes, batch write modification)