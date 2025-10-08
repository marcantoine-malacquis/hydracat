# HydraCat Treatment Logging Implementation Plan

## Overview
Implement a comprehensive, persona-aware treatment logging system with offline-first architecture, cost-optimized Firebase writes, and immediate visual feedback. The system supports flexible logging (actual vs scheduled amounts), multi-medication selection, quick-log via long-press FAB, and provides foundation for detailed adherence analytics.

## Key Logging Requirements Summary

### Core Logging Features
- **Persona-Aware UI**: Different logging popups based on treatment approach (medication only, fluid only, or both)
- **Quick Access**: FAB button in navigation bar for instant logging
- **Pre-filled Data**: Target values automatically loaded from user's treatment schedules
- **Flexible Logging**: Track actual administered amounts vs scheduled targets for adherence analysis
- **Multi-Session Support**: Allow multiple partial logs per day (e.g., 80mL + 20mL = 100mL total)

### User Experience Flow
- **Single Treatment Logging**: FAB press � Persona-specific popup � Adjust values � Log button
- **Combined Treatment Choice**: FAB press � Small popup with "Log Medication" / "Log Fluid" buttons � Specific popup
- **Long-Press Quick-Log**: FAB long-press � Auto-log all scheduled treatments for today � Success popup
- **Background Blur**: Popup overlay with blurred background, unblurred navigation bar
- **No Scrolling**: All fields visible without scrolling in popup layout

### Data Capture Strategy
- **Medication Sessions**: Name, dosage given/scheduled, completion status, administration method, notes, schedule link
- **Fluid Sessions**: Volume given, stress level, injection site, notes, schedule link
- **Timestamp Tracking**: Actual treatment time + scheduled time + creation time for sync conflicts
- **Schedule Linking**: Each session links to reminder time via `scheduleId` for adherence tracking

### Firebase Cost Optimization (4-Write Batch Strategy)
- **Write Pattern**: Session document + daily summary + weekly summary + monthly summary
- **Batch Operations**: All writes in single atomic batch (4 writes per log = $0.0000072)
- **Local Caching**: Today's summary cached to avoid reads when checking logged status
- **Read Savings**: 87% cost reduction vs session-only approach (1 summary read vs 90+ session reads)
- **Update Strategy**: UPDATE existing sessions (1 write) vs DELETE + CREATE (2 writes)

### Offline Support & Sync
- **Offline-First**: Complete local storage with automatic sync when reconnected
- **Conflict Resolution**: Last session logged (by `createdAt`) wins for same time slot
- **Sync Queue**: Queued operations execute in chronological order when online
- **Local Cache**: Today's summary + recent sessions available offline

### Validation & Error Handling
- **Volume Range**: 1-500mL for fluid therapy
- **Duplicate Detection**: Warn user when logging same treatment/time, allow update
- **Required Fields**: Volume for fluids, medication name + dosage for medications
- **Optional Fields**: Notes (expandable), stress level, injection site

### Adherence Analytics Foundation
- **Session Comparison**: dosageGiven vs dosageScheduled, volumeGiven vs targetVolume
- **Completion Tracking**: Boolean `completed` field for medications
- **Schedule Linking**: `scheduleId` connects sessions to reminder times
- **Time-Range Queries**: Support 30-day, 90-day, yearly adherence reports
- **Per-Medication Analytics**: Track adherence by medication name (e.g., "Amlodipine 2.5mg: 87% adherence")

---

## =
 Codebase Integration Audit Results

** INTEGRATION ASSESSMENT COMPLETE - ALL SYSTEMS READY**

### Current Data Model Foundation
- **Status**: Excellent onboarding foundation to build upon
- **Files**: `lib/features/onboarding/models/treatment_data.dart`, `lib/features/profile/models/schedule.dart`
- **Current Structure**: `MedicationData`, `FluidTherapyData` with JSON serialization
- **Integration**: Session models will mirror onboarding structure with added session-specific fields
- **Compatibility**: Full backwards compatibility with existing treatment setup

### Existing Firestore Schema
- **Status**: Perfect alignment with logging requirements
- **Schema Location**: `.cursor/rules/firestore_schema.md`
- **Collections**: `medicationSessions/{sessionId}` and `fluidSessions/{sessionId}` already defined
- **Summary Structure**: `treatmentSummaryDaily`, `treatmentSummaryWeekly`, `treatmentSummaryMonthly` pre-designed
- **Integration**: Zero schema conflicts - logging models map directly to existing structure

### Schedule Service Integration
- **Status**: Production-ready schedule management
- **Current System**: Complete `ScheduleService` with CRUD operations
- **Files**: `lib/features/profile/services/schedule_service.dart`, `lib/shared/models/schedule_dto.dart`
- **Extension Needed**: Add methods to fetch today's schedules for pre-filling
- **Ready For**: Schedule-to-session linking, adherence comparison

### UI Components Available
- **Status**: Reusable onboarding components ready
- **Available Components**: `TreatmentPopupWrapper`, `RotatingWheelPicker`, `MedicationSummaryCard`
- **Files**: `lib/features/onboarding/widgets/`
- **Blur Support**: Flutter's `BackdropFilter` with `ImageFilter.blur()` for popup backgrounds
- **Consistency**: iOS-style pickers and popup flows already established

### Analytics Provider Ready
- **Status**: Firebase Analytics fully integrated
- **Current System**: `AnalyticsService` with event tracking
- **Extension Needed**: Add logging-specific events (session_logged, quick_log_used, etc.)
- **Ready For**: Logging funnel tracking, adherence metrics, user behavior analysis

### Offline Capabilities Assessment
- **Status**: Comprehensive offline-first architecture in place
- **Infrastructure**: `SyncProvider` with queue management, `ConnectivityService` monitoring
- **Firestore**: Persistence enabled with cache configuration
- **Logging Support**: Full offline logging with automatic sync when reconnected
- **Conflict Resolution**: `createdAt` timestamp comparison for multi-device scenarios

### Integration Confidence: 100%
All six critical integration points are optimally designed for logging implementation. No architectural changes required - only clean extensions to existing systems.

---

## Phase 1: Foundation Models & Data Structure

### Step 1.1: Create Core Session Models ✅ COMPLETED
**Location:** `lib/features/logging/models/`

**Files Created:**
- ✅ `medication_session.dart` - Medication logging session model
- ✅ `fluid_session.dart` - Fluid therapy logging session model
- ✅ `logging_result.dart` - Sealed class for operation results (Success/Failure)

**Preparatory Updates Completed:**
- ✅ Added `uuid: ^4.5.1` package to `pubspec.yaml`
- ✅ Created `DosageUtils` helper class (`lib/core/utils/dosage_utils.dart`)
  - Parses dosage strings: "1/2" → 0.5, "2.5" → 2.5, "1 1/4" → 1.25
  - Validates dosage inputs with user-friendly error messages
  - Formats dosages for display
- ✅ Updated `Schedule` model to use `double` for `targetDosage` (was `String`)
- ✅ Updated `ScheduleDto` to use `double` for `targetDosage`
- ✅ Updated `MedicationData` to use `double` for `dosage`
- ✅ Updated medication input screens to convert string input → double with validation

**Key Implementation Details:**

**Enhanced Timestamp Schema (4 timestamps):**
```
medicationSessions/{sessionId}
  ├── dateTime: Timestamp       // Medical: when treatment occurred
  ├── createdAt: Timestamp      // Audit: when user logged it (client-side)
  ├── syncedAt: Timestamp       // Sync: server confirmation (optional)
  └── updatedAt: Timestamp      // Modification: last edit time (optional)
```

**MedicationSession Features:**
- UUID-based session IDs (client-side generation)
- Factory constructors: `create()` and `fromSchedule()`
- Adherence helpers: `adherencePercentage`, `isFullDose`, `isPartialDose`, `isMissed`
- Sync helpers: `isSynced`, `wasModified`, `isPendingSync`
- Structural validation following `ProfileValidationService` pattern
- Conditional JSON serialization (only includes `customMedicationStrengthUnit` if non-null)
- Firestore Timestamp parsing support

**FluidSession Features:**
- UUID-based session IDs (client-side generation)
- Factory constructors: `create()` and `fromSchedule()`
- Type-safe `FluidLocation` enum for injection sites (not string!)
- Sync helpers: `isSynced`, `wasModified`, `isPendingSync`
- Volume validation: 1-500ml range
- Stress level validation: "low", "medium", "high"
- Enum ↔ string conversion in JSON serialization

**LoggingResult Pattern:**
- Sealed class with `LoggingSuccess<T>` and `LoggingFailure<T>` subclasses
- Pattern matching with `when()` method for clean error handling
- Type-safe result handling for all logging operations
- All classes marked `@immutable`

**Data Model Structure:**

```dart
@immutable
class MedicationSession {
  final String id;                    // UUID (client-side)
  final String petId;
  final String userId;
  final DateTime dateTime;            // Medical: when treatment occurred
  final String medicationName;
  final double dosageGiven;           // Actual amount administered
  final double dosageScheduled;       // Target from schedule
  final String medicationUnit;        // "pills", "ml", "mg", etc.
  final String? medicationStrengthAmount;     // e.g., "2.5", "10"
  final String? medicationStrengthUnit;       // e.g., "mg", "mgPerMl"
  final String? customMedicationStrengthUnit; // Only when strengthUnit is "other"
  final bool completed;               // For adherence tracking
  final String? notes;                // User notes
  final String? scheduleId;           // Link to reminder schedule
  final DateTime? scheduledTime;      // Original scheduled time
  final DateTime createdAt;           // Audit: client logging time
  final DateTime? syncedAt;           // Sync: server confirmation
  final DateTime? updatedAt;          // Modification: last edit time

  // Factory constructors, validation, adherence helpers, JSON methods...
}

@immutable
class FluidSession {
  final String id;                    // UUID (client-side)
  final String petId;
  final String userId;
  final DateTime dateTime;            // Medical: when treatment occurred
  final double volumeGiven;           // Actual volume (ml)
  final FluidLocation? injectionSite; // Type-safe enum!
  final String? stressLevel;          // "low", "medium", "high"
  final String? notes;                // User notes
  final String? scheduleId;           // Link to reminder schedule
  final DateTime? scheduledTime;      // Original scheduled time
  final DateTime createdAt;           // Audit: client logging time
  final DateTime? syncedAt;           // Sync: server confirmation
  final DateTime? updatedAt;          // Modification: last edit time

  // Factory constructors, validation, sync helpers, JSON methods...
}
```

**Design Decisions:**
1. **Dosage Storage**: Changed from `String` to `double` for easier adherence calculations
2. **Dosage Input**: String → double conversion at widget level with `DosageUtils`
3. **Strength Fields**: Stored in sessions for complete historical records
4. **Custom Strength Unit**: Only serialized to JSON when non-null (optimization)
5. **Injection Site**: `FluidLocation` enum (type-safe) with string conversion in JSON
6. **Session IDs**: UUID v4 generated client-side via factory constructors
7. **Notes Field**: Simply `notes` (not `notesOrComments`) for clarity
8. **Timestamps**: 4-timestamp system with client-side `createdAt` and optional server timestamps
9. **Validation**: Hybrid approach - structural validation in models, business logic in services

**Testing Checkpoint:**
- Dosage conversion: Test "1/2", "2.5", "1 1/4" inputs
- Session creation: Verify UUID generation and timestamp initialization
- JSON serialization: Test Firestore Timestamp handling
- Validation: Test volume ranges, dosage validation, required fields

**Learning Goal:** Understand session data structure for adherence analytics with complete audit trail

### Step 1.2: Create Logging State Models ✅ COMPLETED
**Location:** `lib/features/logging/models/`

**Files Created:**
- ✅ `daily_summary_cache.dart` - Local cache model for today's summary with hybrid approach
- ✅ `logging_mode.dart` - Enum for logging mode (manual, quickLog)
- ✅ `treatment_choice.dart` - Enum for combined persona choice (medication, fluid)
- ✅ `logging_state.dart` - Immutable state for logging feature (Riverpod integration)

**Key Implementation Details:**

**DailySummaryCache Features:**
- **Hybrid Model**: Pure validation in model, time-aware logic in service layer
- **6 Fields**: `date`, `medicationSessionCount`, `fluidSessionCount`, `medicationNames`, `totalMedicationDosesGiven`, `totalFluidVolumeGiven`
- **Pure Validation**: `isValidFor(targetDate)` method for cache expiration checking
- **Domain Queries**: `hasAnySessions`, `hasMedicationLogged()`, `hasFluidSession`, `hasMedicationSession`
- **Immutability**: `copyWith()` and `copyWithSession()` for incremental updates
- **Factory Constructor**: `DailySummaryCache.empty(date)` for new day initialization
- **JSON Serialization**: For SharedPreferences persistence (Phase 2)
- **Equality Operators**: Full `==`, `hashCode`, `toString()` for Riverpod state comparison

**Cache Structure:**
```dart
@immutable
class DailySummaryCache {
  final String date;                          // YYYY-MM-DD format
  final int medicationSessionCount;           // Count for logged status
  final int fluidSessionCount;                // Count for logged status
  final List<String> medicationNames;         // Unique list for duplicate detection
  final double totalMedicationDosesGiven;     // Sum for adherence display
  final double totalFluidVolumeGiven;         // Sum for adherence display

  // Pure validation - testable, no side effects
  bool isValidFor(String targetDate) => date == targetDate;

  // Domain queries
  bool get hasAnySessions => medicationSessionCount > 0 || fluidSessionCount > 0;
  bool hasMedicationLogged(String name) => medicationNames.contains(name);
  bool get hasFluidSession => fluidSessionCount > 0;
  bool get hasMedicationSession => medicationSessionCount > 0;

  // Immutability support
  DailySummaryCache copyWithSession({
    String? medicationName,
    double? dosageGiven,
    double? volumeGiven,
  }) { /* incremental updates */ }

  // JSON serialization
  Map<String, dynamic> toJson() { /* ... */ }
  factory DailySummaryCache.fromJson(Map<String, dynamic> json) { /* ... */ }
}
```

**Service Layer (Phase 2):**
```dart
class DailyCacheService {
  final SharedPreferences _prefs;

  /// Get cached summary if valid for today, null otherwise
  Future<DailySummaryCache?> getTodaySummary(String userId, String petId) async {
    // ✅ Uses model's pure validation with current date
    final today = AppDateUtils.formatDateForSummary(DateTime.now());
    if (!cache.isValidFor(today)) {
      await _prefs.remove(key); // Cache expired, clean up
      return null;
    }
    return cache;
  }

  /// Clear all caches that are not for today (run on app startup)
  Future<void> clearExpiredCaches() async { /* ... */ }

  /// Update cache with new session data
  Future<void> updateCache({...}) async { /* ... */ }
}
```

**LoggingMode Enum:**
```dart
enum LoggingMode {
  manual,      // Full form with all fields and time adjustment
  quickLog;    // Streamlined one-tap logging with defaults

  String get displayName;
  String get description;
  bool get allowsTimeAdjustment;
  bool get showsOptionalFields;
  bool get requiresSchedule;
  static LoggingMode? fromString(String value);
}
```

**TreatmentChoice Enum:**
```dart
enum TreatmentChoice {
  medication,  // Log medication session
  fluid;       // Log fluid therapy session

  String get displayName;
  String get iconName;
  String get description;
  static TreatmentChoice? fromString(String value);
}
```

**LoggingState Class:**
```dart
@immutable
class LoggingState {
  final LoggingMode? loggingMode;
  final TreatmentChoice? treatmentChoice;
  final DailySummaryCache? dailyCache;
  final bool isLoading;
  final String? error;

  // Factory constructors
  const LoggingState.initial();
  const LoggingState.loading();

  // Computed properties (11 helper getters)
  bool get hasModeSelected;
  bool get isReadyForLogging;
  bool get isQuickLogMode;
  // ... etc

  // State mutations
  LoggingState copyWith({...});
  LoggingState withMode(LoggingMode mode);
  LoggingState withTreatmentChoice(TreatmentChoice choice);
  LoggingState withCache(DailySummaryCache cache);
  LoggingState reset();
}
```

**Design Decisions:**
1. **Hybrid Approach**: Model contains pure validation, service handles time-aware operations
2. **No lastUpdatedAt**: Redundant with date field, adds complexity
3. **Cache Mirrors Firestore**: Exact structure match for easy Phase 3 migration
4. **SharedPreferences Storage**: Non-sensitive temporary data, faster than SecurePreferences
5. **UI-Level Enums**: `TreatmentChoice` doesn't persist, only for immediate UI flow
6. **No Update Mode**: Handled separately in Progress screen (future implementation)
7. **Ignore Redundant Args**: Explicit `null` values in `withMode()` and `reset()` for clarity

**Learning Goal:** Hybrid model architecture with pure validation and service-layer time logic

### Step 1.3: Extend Firestore Schema Models ✅ COMPLETED
**Location:** `lib/shared/models/` + `lib/core/utils/date_utils.dart`

**Files Created:**
- ✅ `treatment_summary_base.dart` - Abstract base class with shared fields
- ✅ `daily_summary.dart` - Daily summary (date + overallStreak)
- ✅ `weekly_summary.dart` - Weekly summary (treatment/missed days + avg adherence)
- ✅ `monthly_summary.dart` - Monthly summary (streaks + monthly adherence)
- ✅ `summary_update_dto.dart` - Delta-based update DTO for batch writes
- ✅ Updated `date_utils.dart` - Added document ID generation methods

**Key Implementation Details:**

**Architecture: Base Class + 3 Subclasses**
- Type-safe: `getDailySummary()` returns `DailySummary` (not generic)
- Period-specific fields: Monthly has streaks, daily doesn't
- Matches Firestore structure: Different collections per period

**Document IDs (via AppDateUtils):**
- Daily: `formatDateForSummary()` → "2025-10-05"
- Weekly: `formatWeekForSummary()` → "2025-W40" (ISO 8601 week number)
- Monthly: `formatMonthForSummary()` → "2025-10"

**Delta-Based Updates (SummaryUpdateDto):**
- Factory constructors:
  - `fromMedicationSession()` / `fromFluidSession()` - New sessions
  - `forMedicationSessionUpdate()` / `forFluidSessionUpdate()` - Calculate deltas
- `toFirestoreUpdate()` → Map with `FieldValue.increment(delta)`
- Only includes non-null fields (minimal payload)

**Important for Phase 2 Services:**
- Use `SummaryUpdateDto.fromXxxSession()` for new sessions
- Use `SummaryUpdateDto.forXxxSessionUpdate()` for session modifications
- Document IDs: Call `AppDateUtils.formatXxxForSummary(session.dateTime)`
- Week/month boundaries: Use `AppDateUtils.getWeekStartEnd()` / `getMonthStartEnd()`
- ISO 8601 weeks: Monday = first day, Week 1 = first Thursday of year
- All summaries track: medication (doses/scheduled/missed), fluid (volume/sessions), overall (treatment done/adherence)
- No denormalized fields yet (petId, petName) - add in Phase 4+ when analytics needs them

**Validation Rules:**
- Base: All counts ≥0, adherence 0.0-1.0, no future timestamps
- Daily: Date not in future, streak=0 if treatment not done
- Weekly: 7-day span (Mon-Sun), day counts ≤7, endDate > startDate
- Monthly: Same month for start/end, day counts ≤31, current streak ≤ longest streak

**Learning Goal:** Pre-aggregated summary architecture for cost optimization

**< MILESTONE:** Data models ready for logging flow implementation!

---

## Phase 2: Core Services & Business Logic

### Step 2.1: Create Logging Service ✅ COMPLETED
**Location:** `lib/features/logging/services/` + `lib/features/logging/exceptions/`

**Files Created:**
- ✅ `logging_exceptions.dart` - 5 exception types (base, duplicate, validation, schedule, batch)
- ✅ `logging_service.dart` - Consolidated service (883 lines, all logic internal)

**Critical Implementation Details:**

**8-Write Batch (NOT 4):** Session + (daily set+update) + (weekly set+update) + (monthly set+update) = 8 writes/log
- **Why**: `FieldValue.increment()` fails on non-existent fields; must init with concrete 0s first
- **Cost**: $0.0000144/log (~$0.04/month for 3000 logs) - negligible vs reliability gain
- **Pattern**: `batch..set({counters: 0}, merge:true)..update({counters: increment(delta)})`

**Schedule Matching:** Meds filter by name → closest time ±2h; Fluids closest time ±2h only

**Duplicate Detection:** Meds only (same name + ±15min) → throws exception; Fluids NONE (partial sessions valid)

**Validation:** Hybrid - model `.validate()` + service business rules → `SessionValidationException`

**Update Pattern:** Service has separate methods - caller decides create vs update (no auto-detection)

**Streak Calculation:** Deferred to Phase 7 (always 0 in summaries) - needs yesterday's data, better as daily job

**Offline Support:** Deferred to Phase 6 - service assumes online, Phase 6 adds queue layer

**For Phase 2.3 Provider:**
- Provider fetches schedules + caches today's sessions (passes to service for duplicate detection)
- Provider calls `loggingService.logXxxSession(schedules, recentSessions)` - service matches internally
- Provider handles exceptions: duplicate dialog, validation snackbar, offline queue (Phase 6)

### Step 2.2: Create Summary Service ✅ COMPLETED
**Location:** `lib/features/logging/services/`

**Files Created:**
- ✅ `summary_service.dart` - Firestore summary reads (cache-first strategy)
- ✅ `summary_cache_service.dart` - SharedPreferences cache management
- ✅ `test/features/logging/services/summary_cache_service_test.dart` - 10 unit tests
- ✅ `test/features/logging/services/summary_service_test.dart` - Architecture tests

**Critical Implementation Details:**

**SummaryCacheService:**
- Cache key format: `daily_summary_{userId}_{petId}_{YYYY-MM-DD}`
- Methods: `getTodaySummary()`, `updateCacheWithMedicationSession()`, `updateCacheWithFluidSession()`, `clearExpiredCaches()`, `clearPetCache()`
- Uses background isolates (`compute`) for JSON parsing/encoding
- Silent error handling (cache failures don't break functionality)
- Multi-pet support via cache keys

**SummaryService:**
- Methods: `getTodaySummary()` (cache-first), `getDailySummary()`, `getWeeklySummary()`, `getMonthlySummary()`
- **Important**: `getTodaySummary()` checks cache but still fetches from Firestore (DailySummaryCache has fewer fields than DailySummary)
- Direct Firestore reads for historical summaries
- Document path helpers reuse LoggingService pattern

**For Phase 2.3 Provider:**
- Call `cacheService.clearExpiredCaches()` on app startup AND resume from background (`AppLifecycleState.resumed`)
- After logging, update cache: `await cacheService.updateCacheWithXxxSession(...)`
- Provider uses cache for quick checks: `cache.hasAnySessions`, `cache.hasMedicationLogged(name)`
- Full summary data from Firestore: `await summaryService.getTodaySummary(userId, petId)`

**Cost Impact:**
- Before: 3-5 Firestore reads per duplicate detection
- After: 0 reads (cache) or 1 read (cold start)
- Savings: ~90% read reduction

**Learning Goal:** Cache-first architecture for cost optimization

### Step 2.3: Create Logging Providers ✅ COMPLETED
**Location:** `lib/providers/logging_provider.dart` (single file, 813 lines)

**Files Created:**
- ✅ `logging_provider.dart` - All providers in one file (follows AuthProvider pattern)
- ✅ `main.dart` - Updated to initialize SharedPreferences
- ✅ `schedule.dart` - Added `hasReminderTimeToday()` extension method

**Architecture:**
- **Single File Pattern**: All 20+ providers in `logging_provider.dart` (not split into 3 files)
- **Service Providers**: LoggingService, SummaryService, SummaryCacheService, SharedPreferences
- **LoggingNotifier**: State management + cache lifecycle + quick-log + manual logging
- **17 Selector Providers**: Optimized for minimal UI rebuilds

**Critical Implementation Details:**

**Cache Lifecycle:**
- Initialized on app startup via `_initialize()`
- Cleared on app resume via `onAppResumed()` (MUST be called from app_shell.dart)
- Today's cache loaded automatically

**Quick-Log:**
- Method: `quickLogAllTreatments()` - checks cache, validates, calls service
- TODO: `LoggingService.quickLogAllTreatments()` not yet implemented (Phase 2.4/5)
- Uses `canQuickLogProvider` for FAB state

**Manual Logging:**
- `logMedicationSession()` - updates cache, tracks analytics
- `logFluidSession()` - updates cache, tracks analytics
- Both handle DuplicateSessionException separately

**Schedule Filtering:**
- `todaysMedicationSchedulesProvider` - filters by `hasReminderTimeToday()`
- `todaysFluidScheduleProvider` - returns schedule only if has today's reminder
- Extension method added to Schedule model

**For Phase 3 UI Integration:**
1. Call `ref.read(loggingProvider.notifier).onAppResumed()` in app_shell.dart on AppLifecycleState.resumed
2. Watch `canQuickLogProvider` for FAB quick-log button state
3. Watch `isLoggingProvider` for loading indicators
4. Watch `loggingErrorProvider` for error messages
5. Use `todaysMedicationSchedulesProvider`/`todaysFluidScheduleProvider` for pre-filling forms

**Learning Goal:** Single-file provider architecture with lifecycle management

**<� MILESTONE:** Providers ready for UI integration!

---

## Phase 3: Logging UI Screens & Popups

### Step 3.1: Create Popup Infrastructure ✅ COMPLETED
**Location:** `lib/features/logging/widgets/`, `lib/features/logging/screens/`, `lib/features/logging/services/`, `lib/app/`

**Files Created:**
- ✅ `overlay_service.dart` - **NEW**: Full-screen overlay service with configurable animations
- ✅ `logging_popup_wrapper.dart` - **UPDATED**: Removed BlurredBackground, uses overlay service
- ✅ `treatment_choice_popup.dart` - **UPDATED**: Added cancel button, removed BlurredBackground
- ✅ `medication_logging_screen.dart` - Placeholder for Phase 3.2
- ✅ `fluid_logging_screen.dart` - Placeholder for Phase 3.3

**Files Modified:**
- ✅ `app_shell.dart` - **UPDATED**: Uses OverlayService instead of showGeneralDialog
- ✅ `router.dart` - **NO LONGER NEEDED**: Routes removed (using overlay system)
- ✅ `app_icons.dart` - Added `medication` and `fluidTherapy` icons

**Key Implementation Notes - UPDATED:**
- **Overlay System**: Uses Flutter's built-in `Overlay` widget for true full-screen coverage
- **Animation Types**: `OverlayAnimationType.slideUp`, `slideFromRight`, `slideFromLeft`
- **Animation Durations**: 200ms for slide-up, 250ms for side slides
- **Full-Screen Blur**: Covers entire screen including system UI (status bar, navigation bar)
- **Dismissal**: `OverlayService.hide()` with proper animation cleanup
- **Cancel Button**: Added elegant cancel button with subtle background styling
- **Optimized Padding**: Asymmetric padding to reduce unused space
- **CatProfile Field**: Use `pet.treatmentApproach`, NOT `pet.persona`
- **Sizing**: `maxHeight: mediaQuery.size.height * 0.8`, baseline 640px (iPhone SE)

**Animation Flow:**
1. **FAB Press** → `slideUp` (200ms) → Treatment Choice Popup
2. **Medication Selected** → `slideFromRight` (250ms) → Medication Logging Screen  
3. **Fluid Selected** → `slideFromRight` (250ms) → Fluid Logging Screen

**For Phase 3.2/3.3:**
- Replace placeholder screens with actual forms
- Use `LoggingPopupWrapper` as container (no BlurredBackground needed)
- Call `onDismiss: () => ref.read(loggingProvider.notifier).reset()`
- Pre-fill values from `todaysMedicationSchedulesProvider` / `todaysFluidScheduleProvider`
- **NEW**: All popups use `OverlayService.showFullScreenPopup()` with appropriate animation types

### Step 3.2: Create Medication Logging Popup ✅ COMPLETED
**Location:** `lib/features/logging/screens/`, `lib/features/logging/widgets/`

**Files Created:**
- ✅ `medication_logging_screen.dart` - Multi-select confirmation popup with fixed dosages (420 lines)
- ✅ `medication_selection_card.dart` - Single-line horizontal card layout (197 lines)
- ✅ `success_indicator.dart` - Success animation widget (new, not in original plan)
- ⚠️ `medication_dosage_input.dart` - Created but **NOT USED** (reserved for future edit/update flow)

**Key Implementation Differences from Original Plan:**

**1. Fixed Dosage Confirmation Flow (NOT Adjustable)**
- **Current**: Users select medications → Add notes → Log all at once with **fixed schedule dosages**
- **Original Plan**: Users select medications → Adjust individual dosages → Log
- **Reality**: More streamlined - dosage locked to `schedule.targetDosage` (lines 124-125 in medication_logging_screen.dart:124-125)
- **Benefit**: Faster logging flow, prioritizes speed over granular control

**2. "Select All" Button (Enhancement)**
- **Current**: ✅ Implemented (lines 67-83, 278-309)
- **Original Plan**: Not mentioned
- **Feature**: Convenient batch selection for users with multiple medications
- **Behavior**: Toggles between "Select All" and "Deselect All" based on current state

**3. Single-Line Horizontal Card Layout (NOT Two-Line)**
- **Current**: `[Icon] Name, Strength | Dosage [Checkmark]` - all on one line
- **Original Plan**: Two-line vertical layout (name on line 1, strength on line 2)
- **Reality**: More compact, fits better in popup without scrolling
- **Design**: Left side shows icon + name + strength, right side shows dosage + selection indicator

**4. Success Animation with Haptic Feedback (Enhancement)**
- **Current**: ✅ Full success indicator with overlay + haptic feedback (lines 162-176)
- **Original Plan**: Loading state only
- **Addition**: `SuccessIndicator` widget with 500ms display + auto-dismiss
- **UX**: `HapticFeedback.lightImpact()` + visual checkmark animation

**5. Notes Field Enhancement**
- **Current**: Expands from 1 to 5 lines dynamically based on content
- **Behavior**: `minLines: _notesController.text.isNotEmpty ? 3 : 1`
- **Max Length**: 500 characters with counter

**6. Dynamic Button Text**
- **Current**: Shows "Log Medication" or "Log N Medications" based on selection count
- **UX**: Clear feedback on how many items will be logged

**7. Duplicate Detection Dialog**
- **Current**: Shows dialog when medication already logged today (±15min window)
- **Actions**: "Update" (coming soon), "Create New" (coming soon), "Cancel"
- **Reality**: Both actions show "Coming Soon" snackbar (lines 206-228)

**Layout (Current Implementation)**:
```
┌─────────────────────────────────────┐
│         Log Medication              │
├─────────────────────────────────────┤
│                                     │
│  [Select All / Deselect All]        │  ← NEW: Convenience button
│                                     │
│  Select Medications:                │
│  [✓] ⚕️ Amlodipine, 2.5mg    1 pill │  ← Single-line horizontal
│  [ ] ⚕️ Benazepril, 5mg      1 pill │
│  [ ] ⚕️ Calcitriol, 0.25mcg  1 pill │
│                                     │
│  Notes (optional): [         ]      │  ← Expands to 5 lines when focused
│                                     │
│  [     Log 1 Medication      ]      │  ← Dynamic text
└─────────────────────────────────────┘
```

**Card Layout Details (medication_selection_card.dart:69-141)**:
```
┌──────────────────────────────────────────────────┐
│ [Icon] Name, Strength          Dosage  [Check]  │
│ [⚕️  ] Amlodipine, 2.5mg      1 pill   [ ✓ ]   │
└──────────────────────────────────────────────────┘
```

**Visual Feedback:**
- **Unselected**: Gray border (1px), white background, unchecked circle icon
- **Selected**: Primary border (2px), primary tint background (10% opacity), checkmark icon
- **Animation**: 200ms easeInOut transition on selection change
- **Icon**: Medication-unit-aware (pills → medication, drops → water_drop, etc.)

**Validation:**
- **Required**: At least one medication selected
- **Dosage**: Always uses `schedule.targetDosage` (no user input validation needed)
- **Button State**: Disabled until `_isFormValid` returns true

**Loading States:**
- **During Batch Write**: Full-screen overlay with spinner, content at 30% opacity (lines 252-261)
- **Success State**: Overlay with `SuccessIndicator` + 500ms delay + auto-dismiss

**File Status:**
- `medication_dosage_input.dart`: Created with full validation logic but NOT integrated into current flow
- **Future Use**: Reserved for update/edit flow where users need to adjust dosages after initial logging
- **Validation**: Supports decimal input, realistic range checking (0-100), inline error display

**Learning Goal:** Multi-select confirmation UI with fixed values (not dynamic input fields)

### Step 3.3: Create Fluid Logging Popup ✅ COMPLETED
**Location:** `lib/features/logging/screens/`, `lib/features/logging/widgets/`

**Files Created:**
- ✅ `fluid_logging_screen.dart` - Fluid therapy logging screen (415 lines)
- ✅ `stress_level_selector.dart` - Material 3 SegmentedButton stress selector (130 lines)
- ✅ `injection_site_selector.dart` - Dropdown injection site selector (90 lines)

**Key Implementation Details:**

**Fluid Logging Screen Features:**
- **Volume Input**: Pre-filled from schedule's `targetVolume` or defaults to 100ml
- **Validation**: 1-500ml range with inline error messages
- **Daily Summary Display**: Info card shows "XmL already logged today" (Option C implementation)
- **Injection Site**: Custom dropdown with LayerLink overlay, pre-filled from `preferredLocation` or defaults to `shoulderBladeLeft`
- **Stress Level**: Material 3 SegmentedButton with icons (low/medium/high), optional, full-width
- **Notes Field**: Shows character counter (0/500) only when focused, expandable 1→3 lines
- **Loading States**: Full-screen overlay with CircularProgressIndicator
- **Success Animation**: SuccessIndicator widget + haptic feedback + 500ms auto-dismiss
- **Error Handling**: ScaffoldMessenger for errors, no duplicate detection for fluids
- **Rounded Corners**: All four corners rounded (16px) for polished appearance

**Stress Level Selector:**
- Material 3 `SegmentedButton<String>` with single selection
- Icons: HydraIcon with AppIcons (stressLow, stressMedium, stressHigh)
- Haptic feedback on selection
- Empty selection allowed (optional field)
- Full accessibility support with semantic labels
- **Full-width**: Wrapped in `SizedBox(width: double.infinity)` for better layout

**Injection Site Selector:**
- **Custom Dropdown Implementation**: Uses `LayerLink` + `CompositedTransformFollower` pattern
- **Why Custom**: Standard `DropdownButton` had z-index conflicts with overlay popups
- **Features**:
  - Floating label ("Injection Site") in border via `InputDecorator`
  - Dropdown menu appears below field with proper positioning
  - All FluidLocation enum values with display names
  - Selected item shows checkmark (✓) indicator
  - Tap outside to dismiss
  - Arrow icon rotates: ▼ (closed) ↔ ▲ (open)
- **Overlay Management**: Custom `OverlayEntry` in same context as popup (correct z-index)
- **StatefulWidget**: Manages dropdown state without `setState()` in dispose (prevents lifecycle errors)

**Layout Implementation**:
```
┌─────────────────────────────────────┐
│         Log Fluid Session           │
├─────────────────────────────────────┤
│                                     │
│  ┌────────────────────────────────┐ │  ← Info card (conditional)
│  │ ℹ️  40mL already logged today  │ │
│  └────────────────────────────────┘ │
│                                     │
│  Volume (ml): [100]                 │  ← TextField (numeric)
│  ✗ Must be between 1-500ml         │  ← Error (if invalid)
│                                     │
│  Injection Site:                    │
│  [Shoulder blade - left     ▼]     │  ← Dropdown
│                                     │
│  Stress Level (optional):           │
│  [😊 Low] [😐 Medium] [😟 High]    │  ← SegmentedButton
│                                     │
│  Notes (optional): [         ]      │  ← TextField (expandable)
│                                     │
│  [     Log Fluid Session     ]      │  ← FilledButton (disabled if invalid)
└─────────────────────────────────────┘
```

**Pattern Consistency:**
- ✅ Matches medication screen architecture (ConsumerStatefulWidget)
- ✅ Same LoggingPopupWrapper usage
- ✅ Same Stack + Opacity pattern for loading states
- ✅ Same SuccessIndicator + haptic feedback
- ✅ Same error handling via ScaffoldMessenger
- ✅ Same notes field expansion behavior
- ✅ Same provider integration patterns

**Firebase CRUD Compliance:**
- ✅ Uses cached data (`dailyCacheProvider`) - 0 extra reads
- ✅ Single batch write operation (8 writes via LoggingService)
- ✅ No duplicate detection queries (fluids allow multiple sessions)
- ✅ Schedule matching done in LoggingService (no extra reads)

**Pre-fill Logic:**
- **With Schedule**: Volume from `targetVolume`, injection site from `preferredLocation`
- **Without Schedule**: Volume defaults to 100ml, injection site to `shoulderBladeLeft`
- **Schedule Linking**: `scheduleId` populated if schedule exists, null for manual logs

**Validation:**
- Volume: Required, 1-500ml range, numeric only
- Injection site: Always has value (pre-filled or default)
- Stress level: Optional (can be null)
- Notes: Optional, 500 char max
- Button: Disabled until volume is valid

**UI Polish & Bug Fixes:**
- ✅ Character counter shows only when notes field is focused (cleaner UI)
- ✅ Stress level selector fills full width (no unused space)
- ✅ All popup corners rounded (top + bottom for modern look)
- ✅ Fixed injection site dropdown z-index issue with custom overlay implementation
- ✅ Fixed setState() in dispose() lifecycle error
- ✅ Fixed "Medium" text wrapping in stress selector (font size + padding adjustments)


**Technical Challenges Solved:**
1. **Z-Index Problem**: `showMenu()` and `showModalBottomSheet()` rendered behind `OverlayEntry`
   - **Solution**: Custom dropdown using `LayerLink` in same overlay context
2. **DropdownButton Assertion**: `_dropdownRoute == null` error on widget rebuilds
   - **Solution**: Avoided DropdownButton entirely, built custom solution
3. **Lifecycle Management**: setState() called during dispose
   - **Solution**: Removed setState from `_removeOverlay()`, direct state assignment

**Learning Goal:** Form validation, optional field handling, Material 3 widgets, state management patterns, custom overlay widgets, z-index debugging

### Step 3.4: Create Quick-Log Success Popup ✅ COMPLETED
**Location:** `lib/features/logging/widgets/`, `lib/features/logging/services/`, `lib/app/`, `lib/shared/widgets/`

**Files Created:**
- ✅ `quick_log_success_popup.dart` - Success popup: "{count} treatments logged for {petName} ✓"

**Files Modified:**
- ✅ `overlay_service.dart` - Added `OverlayAnimationType.scaleIn` (300ms, `Curves.easeOutBack`)
- ✅ `hydra_fab.dart` - Added `onLongPress` parameter with `GestureDetector`
- ✅ `hydra_navigation_bar.dart` - Added `onFabLongPress` callback
- ✅ `app_shell.dart` - Added `_onFabLongPress()` handler + popup display

**Key Details:**
- Positioning: Bottom-center, 80px above nav bar
- Data: `todaysSessionCountProvider` + `primaryPetProvider` (zero Firebase reads)
- Haptic: `HapticFeedback.lightImpact()` on show
- Accessibility: `Semantics(liveRegion: true)` + "Tap to dismiss" hint
- Timing: 2.5s auto-dismiss OR tap to dismiss immediately
- Shows ONLY when `quickLogAllTreatments()` returns `true`

**Reusable for Future:**
- `OverlayAnimationType.scaleIn` available for other success animations
- FAB long-press pattern established for quick actions
- Success popup pattern: scaleIn + timer + haptic + accessibility

**Learning Goal:** Scale animations, auto-dismiss timers, FAB gesture detection, live region accessibility

### Step 3.5: Create Update Warning Dialog ✅ COMPLETED
**Location:** `lib/features/logging/widgets/`

**Files Created:**
- ✅ `session_update_dialog.dart` - Duplicate session comparison dialog (302 lines)

**Key Implementation Details:**

**Smart Comparison Display:**
- Shows **only changed fields** when values differ (dosage, status, notes)
- Shows **all fields** if no changes detected
- Uses side-by-side card layout: "Current Session" vs "Your New Entry"
- Changed values highlighted with primary color + edit icon
- Timestamp shown for existing session: "Logged at 8:30 AM"

**Conditional Summary Warning:**
- Warning box appears **only if** dosage or completion status changed
- Hidden for notes-only changes (doesn't affect summaries)
- Uses info icon + primary container background
- Message: "Your treatment records will be updated to reflect the new values."

**Actions (Currently Stubbed):**
- **Cancel**: Closes dialog, no action
- **Create New**: Shows "Coming soon" snackbar (future: allow intentional duplicates)
- **Update**: Shows "Coming soon" snackbar (future: calls LoggingService.updateXxxSession)

**Dialog Invocation Pattern:**
```dart
await showDialog<void>(
  context: navigatorContext, // Uses saved navigator context (overlay-safe)
  builder: (context) => SessionUpdateDialog(
    existingSession: existingSession, // From DuplicateSessionException
    newSession: newSession,            // Constructed from current form
  ),
);
```

**Important for Future:**
- Dialog called **after** popup dismissal (uses saved `navigatorContext`, not widget context)
- Currently uses **mock existing session** (Phase 5: get real session from exception)
- Update/Create actions **not wired** yet (Phase 5: integrate with LoggingService methods)
- Comparison logic: `_dosageChanged`, `_completedChanged`, `_notesChanged` properties
- Summary affected check: `_summaryAffected = _dosageChanged || _completedChanged`

**Learning Goal:** Conditional UI rendering, session comparison, overlay-safe dialog context

**<� MILESTONE:** Complete logging UI flow implemented!

---

## Phase 4: FAB Integration & Navigation

### Step 4.1: Implement FAB Logic ✅ COMPLETED
**Location:** `lib/app/app_shell.dart`, `lib/shared/widgets/navigation/hydra_navigation_bar.dart`

**Implementation Complete:**

**Short Press (lines 111-177 in app_shell.dart):**
- ✅ Persona-aware routing based on `pet.treatmentApproach`
- ✅ `medicationOnly`: Direct to medication logging popup
- ✅ `fluidTherapyOnly`: Direct to fluid logging popup
- ✅ `medicationAndFluidTherapy`: Show treatment choice popup first
- ✅ Onboarding completion check with fallback

**Long Press (lines 196-261 in app_shell.dart):**
- ✅ Haptic feedback (`HapticFeedback.mediumImpact()`) on press detection
- ✅ Check `canQuickLogProvider` (uses cached summary - 0 Firebase reads)
- ✅ Execute `quickLogAllTreatments()` via provider
- ✅ Show success popup with session count
- ✅ Show error snackbar if already logged or no schedules

**Loading State:**
- ✅ FAB disabled during auth loading
- ✅ FAB disabled during logging operations (`isLoggingProvider`)
- ✅ FAB shows spinner during batch writes
- ✅ Prevents overlapping operations

**App Lifecycle Management (lines 81-102 in app_shell.dart):**
- ✅ Implements `WidgetsBindingObserver` for lifecycle monitoring
- ✅ Calls `loggingProvider.notifier.onAppResumed()` on app resume
- ✅ Refreshes cache when day changes while app in background
- ✅ Proper cleanup in dispose

**Files Modified:**
1. `lib/app/app_shell.dart` - Added haptic feedback, lifecycle management, loading state
2. `lib/shared/widgets/navigation/hydra_navigation_bar.dart` - Added `isFabLoading` parameter

**Note:** Quick-log service method (`LoggingService.quickLogAllTreatments()`) deferred to Step 5.3 (Phase 5). Currently throws `UnimplementedError` as documented in `logging_provider.dart:272-279`.

**Learning Goal:** Complex gesture detection, conditional navigation, app lifecycle management

### Step 4.2: Update Router for Logging Routes ✅ NO LONGER NEEDED
**Location:** `lib/app/router.dart`

**Status:** **REMOVED** - No longer using router for popup navigation

**Reason for Removal:**
- **Overlay System**: Now using `OverlayService` instead of routes
- **Better Performance**: Direct overlay insertion without route management
- **Full-Screen Coverage**: Overlay system provides true full-screen blur
- **Simpler Architecture**: No need for custom route transitions

**Previous Implementation (Deprecated):**
- Custom routes with `CustomTransitionPage` and `SlideTransition`
- Bottom sheet style transitions
- Route-based navigation with state preservation

**Current Implementation:**
- All popup navigation handled through `OverlayService`
- Configurable animation types per popup
- Direct overlay insertion with proper lifecycle management

**Learning Goal:** Overlay-based navigation is more efficient than route-based popups

### Step 4.3: Implement Treatment Choice Popup ✅ COMPLETED
**Location:** `lib/features/logging/widgets/treatment_choice_popup.dart`, `lib/app/app_shell.dart`

**Files Implemented:**
- ✅ `treatment_choice_popup.dart` - Action-sheet-style popup with two treatment choices
- ✅ `app_shell.dart` - Integration with FAB for combined persona routing (lines 152-177)
- ✅ `treatment_choice.dart` - Enum with display names and icons
- ✅ `app_icons.dart` - Added `medication` and `fluidTherapy` icons

**Key Implementation Details:**

**Positioning & Layout:**
- Uses `Align(alignment: Alignment.bottomCenter)` with proper bottom margin
- Optimized asymmetric padding (reduced bottom padding from lg to sm)
- Container with rounded corners (16px) and shadow effect
- Full-width treatment buttons with `minTouchTarget` constraints (48x48)

**Treatment Buttons:**
- Two `_TreatmentChoiceButton` widgets with icons and labels
- Left: Icon + Label, Right: Chevron indicator
- `InkWell` for touch feedback with proper touch targets
- Divider between buttons for visual separation

**Navigation Flow:**
- Medication button → Sets `TreatmentChoice.medication` → Calls `onMedicationSelected` callback
- Fluid button → Sets `TreatmentChoice.fluid` → Calls `onFluidSelected` callback
- Both callbacks hide popup and show appropriate logging screen with `slideFromRight` animation

**Additional Features (Beyond Requirements):**
- ✅ Cancel button with subtle background styling
- ✅ `PopScope` integration to reset logging state on dismissal
- ✅ Title: "Add one-time entry"
- ✅ Full accessibility support with semantic labels

**Animation:**
- **Initial appearance**: `slideUp` (200ms) when FAB pressed
- **Transition to forms**: `slideFromRight` (250ms) when treatment selected
- **Dismissal**: Immediate via `OverlayService.hide()`

**Layout (Implemented)**:
```
┌─────────────────────────────────────┐
│      Add one-time entry             │
├─────────────────────────────────────┤
│ [💊] Medication              [>]    │
│ ───────────────────────────────────  │
│ [💧] Fluid Therapy           [>]    │
│                                     │
│ [          Cancel          ]        │
└─────────────────────────────────────┘
```

**Integration with FAB (app_shell.dart:152-177):**
```dart
case UserPersona.medicationAndFluidTherapy:
  _showLoggingDialog(
    context,
    TreatmentChoicePopup(
      onMedicationSelected: () {
        OverlayService.hide();
        _showLoggingDialog(context, MedicationLoggingScreen(),
          animationType: OverlayAnimationType.slideFromRight);
      },
      onFluidSelected: () {
        OverlayService.hide();
        _showLoggingDialog(context, FluidLoggingScreen(),
          animationType: OverlayAnimationType.slideFromRight);
      },
    ),
  );
```

**State Management:**
- Sets treatment choice in provider: `ref.read(loggingProvider.notifier).setTreatmentChoice()`
- Resets state on dismissal or cancel: `ref.read(loggingProvider.notifier).reset()`

**Accessibility:**
- Semantic label: "Choose treatment type to log"
- Minimum touch targets: 48x48 (Material Design guidelines)
- Clear visual hierarchy with icons, labels, and chevrons

**Learning Goal:** Action-sheet-style popup UI, persona-aware navigation, state management integration

**<� MILESTONE:** FAB fully integrated with persona-aware logging!

---

## Phase 5: Batch Write Operations & Summary Updates

### Step 5.1: Implement 4-Write Batch Strategy
**Location:** `lib/features/logging/services/logging_service.dart`
**Implementation:**

**Single Session Log (4 writes):**
```dart
Future<LoggingResult> logMedicationSession({
  required MedicationSession session,
  required String petId,
  required String userId,
}) async {
  final batch = FirebaseFirestore.instance.batch();

  try {
    // Generate date strings for summaries
    final dateStr = _formatDate(session.dateTime);        // "2025-10-15"
    final weekStr = _formatWeek(session.dateTime);        // "2025-W42"
    final monthStr = _formatMonth(session.dateTime);      // "2025-10"

    // 1. Write session document
    final sessionRef = _firestore
        .collection('users').doc(userId)
        .collection('pets').doc(petId)
        .collection('medicationSessions').doc(session.id);

    batch.set(sessionRef, session.toJson());

    // 2. Update daily summary
    final dailyRef = _firestore
        .collection('users').doc(userId)
        .collection('pets').doc(petId)
        .collection('treatmentSummaryDaily').doc(dateStr);

    batch.set(dailyRef, {
      'date': Timestamp.fromDate(session.dateTime),
      'medicationTotalDoses': session.completed ? FieldValue.increment(1) : 0,
      'medicationScheduledDoses': FieldValue.increment(1),
      'medicationMissedCount': session.completed ? 0 : FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // 3. Update weekly summary
    final weeklyRef = _firestore
        .collection('users').doc(userId)
        .collection('pets').doc(petId)
        .collection('treatmentSummaryWeekly').doc(weekStr);

    final weekDates = _getWeekStartEnd(session.dateTime);
    batch.set(weeklyRef, {
      'startDate': Timestamp.fromDate(weekDates['start']!),
      'endDate': Timestamp.fromDate(weekDates['end']!),
      'medicationTotalDoses': session.completed ? FieldValue.increment(1) : 0,
      'medicationScheduledDoses': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // 4. Update monthly summary
    final monthlyRef = _firestore
        .collection('users').doc(userId)
        .collection('pets').doc(petId)
        .collection('treatmentSummaryMonthly').doc(monthStr);

    final monthDates = _getMonthStartEnd(session.dateTime);
    batch.set(monthlyRef, {
      'startDate': Timestamp.fromDate(monthDates['start']!),
      'endDate': Timestamp.fromDate(monthDates['end']!),
      'medicationTotalDoses': session.completed ? FieldValue.increment(1) : 0,
      'medicationScheduledDoses': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Atomic commit: All 4 writes or none
    await batch.commit();

    // Update local cache
    await _updateLocalCache(dateStr, petId, userId);

    return LoggingResult.success(session);
  } catch (e) {
    return LoggingResult.failure(e.toString());
  }
}
```

**Learning Goal:** Firebase batch operations for atomic multi-document writes

### Step 5.2: Implement Update with Delta Calculation
**Location:** `lib/features/logging/services/logging_service.dart`
**Implementation:**

```dart
Future<LoggingResult> updateMedicationSession({
  required MedicationSession oldSession,
  required MedicationSession newSession,
  required String petId,
  required String userId,
}) async {
  final batch = FirebaseFirestore.instance.batch();

  try {
    // Calculate deltas
    final dosageDelta = newSession.completed && !oldSession.completed
        ? 1
        : !newSession.completed && oldSession.completed
            ? -1
            : 0;

    final missedDelta = !newSession.completed && oldSession.completed
        ? 1
        : newSession.completed && !oldSession.completed
            ? -1
            : 0;

    // 1. Update session document
    final sessionRef = _firestore
        .collection('users').doc(userId)
        .collection('pets').doc(petId)
        .collection('medicationSessions').doc(newSession.id);

    batch.update(sessionRef, {
      ...newSession.toJson(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // 2-4. Update summaries with deltas
    final dateStr = _formatDate(newSession.dateTime);
    final weekStr = _formatWeek(newSession.dateTime);
    final monthStr = _formatMonth(newSession.dateTime);

    // Daily summary delta update
    final dailyRef = _firestore
        .collection('users').doc(userId)
        .collection('pets').doc(petId)
        .collection('treatmentSummaryDaily').doc(dateStr);

    batch.update(dailyRef, {
      if (dosageDelta != 0)
        'medicationTotalDoses': FieldValue.increment(dosageDelta),
      if (missedDelta != 0)
        'medicationMissedCount': FieldValue.increment(missedDelta),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Weekly and monthly delta updates (similar pattern)...

    await batch.commit();
    await _updateLocalCache(dateStr, petId, userId);

    return LoggingResult.success(newSession);
  } catch (e) {
    return LoggingResult.failure(e.toString());
  }
}
```

**Learning Goal:** Delta-based summary updates for data consistency

### Step 5.3: Implement Quick-Log Batch Write
**Location:** `lib/features/logging/services/logging_service.dart`
**Implementation:**

```dart
Future<LoggingResult> quickLogAllTreatments({
  required String petId,
  required String userId,
  required List<Schedule> todaySchedules,
}) async {
  final batch = FirebaseFirestore.instance.batch();

  try {
    // Check if any sessions already logged today
    final todaySummary = await _getCachedTodaySummary(petId, userId);
    if (todaySummary != null && todaySummary.hasAnySessions) {
      return LoggingResult.failure('Sessions already logged today');
    }

    // Generate all sessions from schedules
    final medicationSessions = <MedicationSession>[];
    final fluidSessions = <FluidSession>[];

    for (final schedule in todaySchedules) {
      if (schedule.treatmentType == TreatmentType.medication) {
        // Create session for each reminder time
        // Note: MedicationSession.fromSchedule should include strength fields:
        // - medicationStrengthAmount
        // - medicationStrengthUnit
        // - customMedicationStrengthUnit
        for (final reminderTime in schedule.reminderTimes) {
          medicationSessions.add(
            MedicationSession.fromSchedule(
              schedule: schedule,
              scheduledTime: reminderTime,
              petId: petId,
              userId: userId,
            ),
          );
        }
      } else if (schedule.treatmentType == TreatmentType.fluid) {
        for (final reminderTime in schedule.reminderTimes) {
          fluidSessions.add(
            FluidSession.fromSchedule(
              schedule: schedule,
              scheduledTime: reminderTime,
              petId: petId,
              userId: userId,
            ),
          );
        }
      }
    }

    // Batch write all sessions + summaries
    for (final session in medicationSessions) {
      await _addMedicationSessionToBatch(batch, session, petId, userId);
    }

    for (final session in fluidSessions) {
      await _addFluidSessionToBatch(batch, session, petId, userId);
    }

    // Single atomic commit for all sessions
    await batch.commit();

    // Update local cache
    await _updateLocalCache(_formatDate(DateTime.now()), petId, userId);

    return LoggingResult.success(null);
  } catch (e) {
    return LoggingResult.failure(e.toString());
  }
}
```

**Cost**: ~10-20 writes for full day (rare operation, acceptable cost)

**Learning Goal:** Batch operations for multiple related documents

**<� MILESTONE:** Firebase cost-optimized batch write system complete!

---

## Phase 6: Offline Support & Sync

### Step 6.1: Implement Offline Logging Queue
**Location:** `lib/features/logging/services/offline_logging_service.dart`
**Files to create:**
- `offline_logging_service.dart` - Queue management for offline operations
- `logging_operation.dart` - Sealed class for queued operations (Create/Update/Delete)

**Key Implementation:**
- **Local Storage**: Use `SecurePreferencesService` for encrypted operation queue
- **Queue Structure**: JSON array of operations with metadata
- **Operation Types**: Create session, Update session, Quick-log
- **Timestamp Tracking**: `createdAt` for conflict resolution
- **Auto-Sync**: Listen to connectivity changes, sync when online

**Queue Entry Structure:**
```dart
{
  'id': 'operation-uuid',
  'type': 'create_medication_session',
  'createdAt': '2025-10-15T08:30:00Z',
  'data': {
    'session': {...},
    'petId': 'pet-123',
    'userId': 'user-456',
  },
}
```

**Learning Goal:** Offline-first data persistence patterns

### Step 6.2: Implement Sync Service
**Location:** `lib/features/logging/services/logging_sync_service.dart`
**Files to create:**
- `logging_sync_service.dart` - Sync queued operations to Firestore
- `conflict_resolver.dart` - Resolve multi-device conflicts by `createdAt`

**Key Implementation:**
- **Sync Trigger**: Automatic on connectivity restored
- **Conflict Resolution**: Compare `createdAt` timestamps, keep most recent
- **Batch Sync**: Execute queued operations in chronological order
- **Error Handling**: Retry failed operations, log persistent failures
- **Queue Cleanup**: Remove successful operations from local storage

**Conflict Resolution Logic:**
```dart
Future<void> resolveConflict({
  required MedicationSession localSession,
  required MedicationSession remoteSession,
}) async {
  // Compare createdAt timestamps
  if (localSession.createdAt.isAfter(remoteSession.createdAt)) {
    // Local session is newer, update remote
    await updateRemoteSession(localSession);
  } else {
    // Remote session is newer, update local cache
    await updateLocalCache(remoteSession);
  }
}
```

**Learning Goal:** Multi-device sync and conflict resolution strategies

### Step 6.3: Integrate with Connectivity Provider
**Location:** `lib/providers/logging_provider.dart`
**Files to modify:**
- Update `LoggingNotifier` to listen to connectivity changes
- Auto-trigger sync when connection restored
- Update UI state during sync operations

**Key Implementation:**
- **Connectivity Listener**: Watch `connectivityProvider` for online/offline transitions
- **Sync State**: Add `isSyncing` to `LoggingState`
- **UI Feedback**: Show "Syncing..." indicator during background sync
- **Error Display**: Toast notification for sync failures

**Learning Goal:** Reactive sync with connectivity monitoring

**<� MILESTONE:** Complete offline support with automatic sync!

---

## Phase 7: Local Cache & Performance Optimization

### Step 7.1: Implement Today's Summary Cache
**Location:** `lib/features/logging/services/summary_cache_service.dart`
**Files to create:**
- `summary_cache_service.dart` - Local cache for today's summary
- `cache_invalidation_service.dart` - Midnight cache refresh logic

**Key Implementation:**
- **Cache Storage**: Store today's summary in `SharedPreferences`
- **Cache Key**: `treatment_summary_${userId}_${petId}_${dateStr}`
- **Auto-Refresh**: Clear cache at midnight (new day transition)
- **Update Strategy**: Update cache on every successful log
- **Read Strategy**: Check cache first, fallback to Firestore if missing

**Cache Benefits:**
- **Cost Savings**: 0 reads for duplicate detection and status checks
- **Performance**: Instant UI updates without Firestore round-trip
- **Offline**: Works completely offline with cached data

**Learning Goal:** Client-side caching for Firebase cost reduction

### Step 7.2: Implement Schedule Pre-loading
**Location:** `lib/providers/schedule_provider.dart`
**Files to create:**
- `today_schedules_provider.dart` - Provider for today's active schedules

**Key Implementation:**
- **Load Strategy**: Fetch today's schedules when app starts or when day changes
- **Cache Duration**: Cache schedules for current day only
- **Query Optimization**: Single query with `where('isActive', isEqualTo: true)`
- **Pre-fill Support**: Use cached schedules to pre-fill logging forms

**Query Pattern:**
```dart
final todaySchedules = await _firestore
    .collection('users').doc(userId)
    .collection('pets').doc(petId)
    .collection('schedules')
    .where('isActive', isEqualTo: true)
    .get();

// Cache result for day
await _cacheSchedules(todaySchedules.docs, DateTime.now());
```

**Cost**: 1 read per day (vs 1 read per logging popup open)

**Learning Goal:** Proactive data loading for better UX

### Step 7.3: Optimize Duplicate Detection
**Location:** `lib/features/logging/services/logging_service.dart`
**Implementation:**

**Current (Expensive):**
```dart
// Query all sessions for today (N reads)
final todaySessions = await _firestore
    .collection('users').doc(userId)
    .collection('pets').doc(petId)
    .collection('medicationSessions')
    .where('dateTime', isGreaterThan: startOfDay)
    .get();

// Check for duplicates
final hasDuplicate = todaySessions.docs.any((doc) =>
    doc.data()['medicationName'] == newSession.medicationName &&
    doc.data()['scheduledTime'] == newSession.scheduledTime
);
```

**Optimized (Cached):**
```dart
// Read from cached summary (0 reads)
final todaySummary = await _getCachedTodaySummary(petId, userId);

// Check session count from summary
final medicationCount = todaySummary?.medicationSessionCount ?? 0;
final fluidCount = todaySummary?.fluidSessionCount ?? 0;

// Only query Firestore if summary indicates existing sessions
if (medicationCount > 0) {
  // Fetch specific sessions for comparison (minimal reads)
  final sessions = await _getMedicationSessionsForToday(petId, userId);
  // Check for duplicates...
}
```

**Learning Goal:** Cache-first architecture for performance and cost optimization

**<� MILESTONE:** Production-ready performance optimization complete!

---

## Phase 8: Analytics & Error Handling

### Step 8.1: Implement Logging Analytics
**Location:** `lib/providers/analytics_provider.dart`
**Files to modify:**
- Add logging-specific events to `AnalyticsEvents` class
- Add logging parameters to `AnalyticsParams` class

**Events to Track:**
```dart
class AnalyticsEvents {
  // ... existing events ...

  // Logging events
  static const sessionLogged = 'session_logged';
  static const quickLogUsed = 'quick_log_used';
  static const sessionUpdated = 'session_updated';
  static const loggingError = 'logging_error';
  static const duplicateWarningShown = 'duplicate_warning_shown';
  static const offlineLoggingQueued = 'offline_logging_queued';
  static const syncCompleted = 'sync_completed';
}

class AnalyticsParams {
  // ... existing params ...

  // Logging params
  static const treatmentType = 'treatment_type';        // 'medication' or 'fluid'
  static const sessionCount = 'session_count';          // Number of sessions logged
  static const isQuickLog = 'is_quick_log';            // Boolean
  static const loggingMode = 'logging_mode';            // 'manual' or 'quick'
  static const volumeGiven = 'volume_given';            // Fluid volume
  static const adherenceStatus = 'adherence_status';    // 'complete' or 'partial'
  static const errorType = 'error_type';                // Error category
}
```

**Usage Example:**
```dart
await _analyticsService.logEvent(
  AnalyticsEvents.sessionLogged,
  parameters: {
    AnalyticsParams.treatmentType: 'medication',
    AnalyticsParams.sessionCount: 1,
    AnalyticsParams.isQuickLog: false,
    AnalyticsParams.adherenceStatus: 'complete',
  },
);
```

**Learning Goal:** Business metrics for logging feature optimization

### Step 8.2: Implement Comprehensive Error Handling
**Location:** `lib/features/logging/exceptions/`
**Files to create:**
- `logging_exceptions.dart` - Logging-specific exception classes
- `logging_error_handler.dart` - Centralized error handling with user-friendly messages

**Exception Types:**
```dart
// Base exception
sealed class LoggingException implements Exception {
  const LoggingException(this.message);
  final String message;

  String get userMessage; // User-friendly error message
}

// Specific exceptions
class InvalidVolumeException extends LoggingException {
  const InvalidVolumeException(super.message);

  @override
  String get userMessage =>
      'Please enter a volume between 1-500ml to keep your cat's data accurate.';
}

class DuplicateSessionException extends LoggingException {
  const DuplicateSessionException(super.message, this.existingSession);
  final dynamic existingSession;

  @override
  String get userMessage =>
      'You already logged this treatment. Would you like to update it?';
}

class OfflineLoggingException extends LoggingException {
  const OfflineLoggingException(super.message);

  @override
  String get userMessage =>
      'Your session has been saved and will sync when you\'re back online.';
}

class SyncConflictException extends LoggingException {
  const SyncConflictException(super.message, this.localSession, this.remoteSession);
  final dynamic localSession;
  final dynamic remoteSession;

  @override
  String get userMessage =>
      'This session was updated on another device. Using the most recent version.';
}
```

**Error Handling Pattern:**
```dart
try {
  final result = await _loggingService.logMedicationSession(...);

  result.when(
    success: (session) {
      // Show success message
      _showSuccessSnackbar('Session logged successfully');
    },
    failure: (error) {
      // Handle error with user-friendly message
      final exception = LoggingException.fromString(error);
      _showErrorDialog(exception.userMessage);

      // Log to analytics
      _analyticsService.logEvent(
        AnalyticsEvents.loggingError,
        parameters: {
          AnalyticsParams.errorType: exception.runtimeType.toString(),
        },
      );
    },
  );
} catch (e) {
  // Unexpected error - log to Crashlytics
  _crashlyticsService.recordError(e, stackTrace);
  _showErrorDialog('Something went wrong. Please try again.');
}
```

**Learning Goal:** Production-quality error handling with empathetic messaging

### Step 8.3: Implement Validation Service
**Location:** `lib/features/logging/services/validation_service.dart`
**Files to create:**
- `logging_validation_service.dart` - Centralized validation logic

**Validation Rules:**
```dart
class LoggingValidationService {
  // Fluid volume validation
  ValidationResult validateFluidVolume(double? volume) {
    if (volume == null) {
      return ValidationResult.error('Volume is required');
    }
    if (volume < 1 || volume > 500) {
      return ValidationResult.error('Volume must be between 1-500ml');
    }
    return ValidationResult.success();
  }

  // Medication dosage validation
  ValidationResult validateMedicationDosage(double? dosage, String? unit) {
    if (dosage == null) {
      return ValidationResult.error('Dosage is required');
    }
    if (dosage <= 0) {
      return ValidationResult.error('Dosage must be greater than 0');
    }
    if (unit == null || unit.isEmpty) {
      return ValidationResult.error('Unit is required');
    }
    return ValidationResult.success();
  }

  // Duplicate detection validation
  Future<ValidationResult> validateDuplicateSession({
    required String treatmentType,
    required DateTime dateTime,
    String? medicationName,
    required String petId,
    required String userId,
  }) async {
    final todaySummary = await _getCachedTodaySummary(petId, userId);

    // Check if similar session exists within �1 hour
    final existingSession = await _findSimilarSession(
      treatmentType: treatmentType,
      dateTime: dateTime,
      medicationName: medicationName,
      petId: petId,
      userId: userId,
    );

    if (existingSession != null) {
      return ValidationResult.duplicate(existingSession);
    }

    return ValidationResult.success();
  }
}

// Validation result
sealed class ValidationResult {
  const ValidationResult();

  factory ValidationResult.success() = ValidationSuccess;
  factory ValidationResult.error(String message) = ValidationError;
  factory ValidationResult.duplicate(dynamic existingSession) = ValidationDuplicate;
}
```

**Learning Goal:** Centralized validation for consistency and maintainability

**<� MILESTONE:** Production-ready analytics and error handling complete!

---

## Phase 9: UI Polish & Accessibility

### Step 9.1: Implement Loading States
**Location:** All logging screens
**Implementation:**

**Button Loading States:**
```dart
ElevatedButton(
  onPressed: _isLogging ? null : _onLogPressed,
  child: _isLoading
      ? SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(Colors.white),
          ),
        )
      : Text('Log Session'),
)
```

**Popup Loading Overlay:**
```dart
Stack(
  children: [
    // Popup content
    LoggingFormContent(),

    // Loading overlay
    if (_isLogging)
      Container(
        color: Colors.black.withOpacity(0.3),
        child: Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Logging session...'),
                ],
              ),
            ),
          ),
        ),
      ),
  ],
)
```

**Learning Goal:** User feedback during asynchronous operations

### Step 9.2: Implement Accessibility Features
**Location:** All logging widgets
**Implementation:**

**Semantic Labels:**
```dart
Semantics(
  label: 'Log medication session',
  hint: 'Double tap to log the selected medications',
  child: ElevatedButton(
    onPressed: _onLogPressed,
    child: Text('Log Medications'),
  ),
)

Semantics(
  label: 'Fluid volume input',
  hint: 'Enter volume in milliliters between 1 and 500',
  child: TextField(
    decoration: InputDecoration(labelText: 'Volume (ml)'),
    keyboardType: TextInputType.number,
  ),
)
```

**Touch Target Sizes:**
```dart
// Ensure minimum 48x48 touch targets (Material Design guidelines)
InkWell(
  onTap: _onMedicationSelected,
  child: Container(
    constraints: BoxConstraints(minHeight: 48, minWidth: 48),
    child: MedicationSelectionCard(...),
  ),
)
```

**Screen Reader Support:**
```dart
// Announce success to screen readers
Semantics(
  liveRegion: true,
  child: _showSuccess
      ? Text('Session logged successfully')
      : SizedBox.shrink(),
)
```

**Learning Goal:** Inclusive design for all users

### Step 9.3: Implement Animations & Transitions
**Location:** `lib/features/logging/widgets/`
**Files to create:**
- `animated_selection_card.dart` - Animated medication selection feedback
- `slide_up_transition.dart` - Popup entrance animation

**Selection Animation:**
```dart
class AnimatedSelectionCard extends StatefulWidget {
  final bool isSelected;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
        color: isSelected
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surface,
      ),
      child: child,
    );
  }
}
```

**Popup Slide Animation:**
```dart
class SlideUpTransition extends StatelessWidget {
  final Widget child;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: Offset(0, 1),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        ),
      ),
      child: child,
    );
  }
}
```

**Learning Goal:** Polished UI with smooth transitions

**< MILESTONE:** Production-ready UI polish and accessibility!

---

## Phase 10: Testing & Documentation

### Step 10.1: Create Unit Tests
**Location:** `test/features/logging/`
**Files to create:**
- `services/logging_service_test.dart` - Test logging business logic
- `services/summary_calculation_service_test.dart` - Test summary calculations
- `services/validation_service_test.dart` - Test validation rules
- `models/medication_session_test.dart` - Test session models

**Test Coverage:**
```dart
group('LoggingService', () {
  test('logs medication session with 4-write batch', () async {
    // Arrange
    final session = MedicationSession(...);

    // Act
    final result = await loggingService.logMedicationSession(
      session: session,
      petId: 'pet-123',
      userId: 'user-456',
    );

    // Assert
    expect(result, isA<LoggingSuccess>());
    verify(mockFirestore.batch()).called(1);
    verify(mockBatch.commit()).called(1);
  });

  test('updates session with delta calculation', () async {
    // Test update logic with summary deltas
  });

  test('detects duplicate sessions', () async {
    // Test duplicate detection logic
  });

  test('handles offline logging queue', () async {
    // Test offline queue persistence
  });
});

group('SummaryCalculationService', () {
  test('calculates daily summary correctly', () {
    // Test daily aggregation
  });

  test('calculates delta for updates', () {
    // Test delta calculation logic
  });

  test('generates correct date strings', () {
    // Test date formatting (YYYY-MM-DD, YYYY-Www, YYYY-MM)
  });
});

group('ValidationService', () {
  test('validates fluid volume range', () {
    // Test 1-500ml validation
  });

  test('rejects invalid medication dosage', () {
    // Test dosage validation
  });

  test('finds duplicate sessions within time window', () {
    // Test duplicate detection
  });
});
```

**Learning Goal:** Testing Firebase batch operations and business logic

### Step 10.2: Create Widget Tests
**Location:** `test/features/logging/widgets/`
**Files to create:**
- `medication_logging_screen_test.dart` - Test medication logging UI
- `fluid_logging_screen_test.dart` - Test fluid logging UI
- `treatment_choice_popup_test.dart` - Test treatment choice popup

**Widget Test Examples:**
```dart
testWidgets('medication logging popup shows medication list', (tester) async {
  // Arrange
  final schedules = [
    Schedule(...medicationName: 'Amlodipine'),
    Schedule(...medicationName: 'Benazepril'),
  ];

  // Act
  await tester.pumpWidget(
    MaterialApp(
      home: MedicationLoggingScreen(schedules: schedules),
    ),
  );

  // Assert
  expect(find.text('Amlodipine'), findsOneWidget);
  expect(find.text('Benazepril'), findsOneWidget);
});

testWidgets('fluid logging validates volume range', (tester) async {
  // Test validation error display
});

testWidgets('quick-log shows success popup', (tester) async {
  // Test success popup animation and auto-dismiss
});
```

**Learning Goal:** Testing complex UI interactions and state

### Step 10.3: Integration Testing
**Location:** `integration_test/`
**Files to create:**
- `logging_flow_test.dart` - End-to-end logging flow test
- `offline_sync_test.dart` - Offline logging and sync test

**Integration Test Example:**
```dart
testWidgets('complete medication logging flow', (tester) async {
  // 1. Open app
  await tester.pumpWidget(MyApp());

  // 2. Press FAB
  await tester.tap(find.byType(HydraFab));
  await tester.pumpAndSettle();

  // 3. Select medication
  await tester.tap(find.text('Amlodipine 2.5mg'));
  await tester.pumpAndSettle();

  // 4. Enter dosage
  await tester.enterText(find.byType(TextField), '1.0');

  // 5. Press Log button
  await tester.tap(find.text('Log Medication'));
  await tester.pumpAndSettle();

  // 6. Verify success
  expect(find.text('Session logged successfully'), findsOneWidget);

  // 7. Verify Firestore batch write
  verify(mockFirestore.batch().commit()).called(1);
});
```

**Learning Goal:** End-to-end testing of complete user flows

**< FINAL MILESTONE:** Complete, tested, production-ready logging system!

---

## Success Criteria

### Phase-by-Phase Goals
- **Phase 1:** Session and summary models support complete logging flow
- **Phase 2:** Services handle 4-write batch operations with delta updates
- **Phase 3:** Persona-aware logging popups with no-scroll layouts
- **Phase 4:** FAB integration with short-press and long-press (quick-log)
- **Phase 5:** Cost-optimized batch writes (session + 3 summaries)
- **Phase 6:** Offline-first logging with automatic sync
- **Phase 7:** Local caching for 0-read duplicate detection
- **Phase 8:** Production-ready analytics and error handling
- **Phase 9:** Polished UI with accessibility support
- **Phase 10:** Comprehensive testing coverage

### Overall Success
-  Users can log medications and fluid therapy via persona-aware popups
-  Quick-log feature (FAB long-press) logs all scheduled treatments instantly
-  4-write batch strategy: Session + daily + weekly + monthly summaries
-  87% Firebase cost reduction vs session-only approach
-  Today's summary cached locally for 0-read duplicate detection
-  Complete offline support with automatic sync when reconnected
-  Multi-device conflict resolution by `createdAt` timestamp
-  Session updates use delta calculation for summary accuracy
-  Foundation ready for adherence analytics (dosageGiven vs dosageScheduled)
-  Accessible UI with proper semantic labels and touch targets
-  Comprehensive test coverage (unit, widget, integration)

---

## Technical Architecture Benefits

### Firebase Cost Optimization
- **4-Write Strategy**: Session + 3 summaries = $0.0000072 per log
- **87% Savings**: vs session-only approach over time
- **Read Reduction**: 1 summary read vs 90+ session reads for analytics
- **Batch Operations**: Atomic writes ensure data consistency
- **Local Caching**: 0 reads for duplicate detection and status checks

### Offline-First Architecture
- **Queue Management**: All operations queued locally when offline
- **Auto-Sync**: Automatic sync when connectivity restored
- **Conflict Resolution**: `createdAt` timestamp comparison for multi-device
- **Data Integrity**: No data loss, offline operations synced correctly
- **User Experience**: Seamless offline/online transitions

### Adherence Analytics Foundation
- **Actual vs Scheduled**: dosageGiven vs dosageScheduled comparison
- **Completion Tracking**: Boolean flags for medication adherence
- **Schedule Linking**: `scheduleId` connects sessions to reminders
- **Time-Range Queries**: Daily/weekly/monthly summaries support analytics
- **Per-Medication Reports**: Track adherence by medication name

### Persona-Driven Experience
- **Adaptive UI**: Different popups based on treatment approach
- **Smart Routing**: FAB routes to correct logging screen automatically
- **Treatment Choice**: Combined persona users choose medication or fluid
- **Pre-filled Data**: Target values loaded from schedules
- **Flexible Logging**: Track deviations from scheduled amounts

---

## Why This Approach Works for Medical Apps

**Cost Efficiency:** 4-write batch strategy saves 87% on Firebase costs at scale
**Offline Reliability:** Medical data always logged, syncs automatically when online
**Adherence Tracking:** Foundation for detailed adherence reports and insights
**User Experience:** Quick-log feature makes daily logging effortless
**Data Accuracy:** Track actual vs scheduled amounts for clinical analysis
**Multi-Device Support:** Conflict resolution ensures data consistency across devices
**Scalability:** Pre-aggregated summaries support premium analytics features

**Key Benefit:** By Phase 5, you'll have a complete, cost-optimized logging system. Each phase builds understanding while maintaining focus on medical data accuracy and user efficiency!

---

## Implementation Notes

### Date/Time Utilities Needed
```dart
// Add to lib/core/utils/date_utils.dart
class AppDateUtils {
  // ... existing methods ...

  /// Format date for daily summary document ID (YYYY-MM-DD)
  static String formatDateForSummary(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Format date for weekly summary document ID (YYYY-Www)
  static String formatWeekForSummary(DateTime date) {
    final weekNumber = _getIso8601WeekNumber(date);
    return '${date.year}-W${weekNumber.toString().padLeft(2, '0')}';
  }

  /// Format date for monthly summary document ID (YYYY-MM)
  static String formatMonthForSummary(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  /// Get ISO 8601 week number (Monday as first day of week)
  static int _getIso8601WeekNumber(DateTime date) {
    final thursday = date.add(Duration(days: 3 - (date.weekday)));
    final firstThursday = DateTime(thursday.year, 1, 4);
    final diff = thursday.difference(firstThursday).inDays;
    return 1 + (diff / 7).floor();
  }

  /// Get week start and end dates (Monday-Sunday)
  static Map<String, DateTime> getWeekStartEnd(DateTime date) {
    final weekDay = date.weekday;
    final startOfWeek = date.subtract(Duration(days: weekDay - 1));
    final endOfWeek = startOfWeek.add(Duration(days: 6));

    return {
      'start': DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day),
      'end': DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day, 23, 59, 59),
    };
  }

  /// Get month start and end dates
  static Map<String, DateTime> getMonthStartEnd(DateTime date) {
    final startOfMonth = DateTime(date.year, date.month, 1);
    final endOfMonth = DateTime(date.year, date.month + 1, 0, 23, 59, 59);

    return {
      'start': startOfMonth,
      'end': endOfMonth,
    };
  }

  /// Find nearest scheduled time within �2 hours
  static DateTime? findNearestScheduledTime(
    DateTime actualTime,
    List<DateTime> scheduledTimes,
  ) {
    const maxDifference = Duration(hours: 2);

    DateTime? nearest;
    Duration? minDifference;

    for (final scheduledTime in scheduledTimes) {
      final difference = (actualTime.difference(scheduledTime)).abs();

      if (difference <= maxDifference &&
          (minDifference == null || difference < minDifference)) {
        nearest = scheduledTime;
        minDifference = difference;
      }
    }

    return nearest;
  }
}
```

### Analytics Events Summary
```dart
// Logging-specific analytics events
- session_logged (treatmentType, sessionCount, isQuickLog)
- quick_log_used (sessionCount, treatmentTypes)
- session_updated (treatmentType, updateReason)
- logging_error (errorType, treatmentType)
- duplicate_warning_shown (treatmentType)
- offline_logging_queued (operationCount)
- sync_completed (operationCount, syncDuration)
- logging_popup_opened (persona, treatmentType)
- treatment_choice_selected (choice)
```

### Performance Targets
- **Popup Load Time**: < 300ms (cached schedules)
- **Log Button Response**: < 500ms (batch write + UI update)
- **Quick-Log Execution**: < 2s (10-20 batch writes)
- **Offline Queue Sync**: < 5s for 10 operations
- **Duplicate Detection**: < 100ms (cached summary)

### Security Considerations
- **Validation**: All user inputs validated before Firestore write
- **Permissions**: Firestore rules enforce user can only log to their own pets
- **Data Integrity**: Batch writes ensure atomic operations (all or nothing)
- **Offline Storage**: Encrypted local storage for queued operations
- **Conflict Resolution**: Server timestamps (`createdAt`) prevent client-side manipulation

---

## 🎯 **RECENT UPDATES - Overlay System Implementation**

### ✅ **Completed Changes (Current Session)**

**1. Full-Screen Blur System**
- **Problem**: Blurred background didn't cover entire screen (status bar, navigation bar)
- **Solution**: Replaced `showGeneralDialog` with custom `OverlayService` using Flutter's `Overlay` widget
- **Result**: True full-screen blur coverage including system UI areas

**2. OverlayService Implementation**
- **File**: `lib/features/logging/services/overlay_service.dart`
- **Features**:
  - `OverlayAnimationType` enum: `slideUp`, `slideFromRight`, `slideFromLeft`
  - Configurable animation durations: 200ms (slide-up), 250ms (side slides)
  - Full-screen `BackdropFilter` with customizable blur and background
  - Proper animation cleanup and lifecycle management

**3. Treatment Choice Popup Enhancements**
- **File**: `lib/features/logging/widgets/treatment_choice_popup.dart`
- **Added**: Elegant cancel button with subtle background styling
- **Optimized**: Asymmetric padding to reduce unused space at bottom
- **Fixed**: Linter warning (removed redundant `width: 1` from `Border.all()`)

**4. Animation Flow Implementation**
- **FAB Press**: `slideUp` (200ms) → Treatment Choice Popup
- **Medication Selection**: `slideFromRight` (250ms) → Medication Logging Screen
- **Fluid Selection**: `slideFromRight` (250ms) → Fluid Logging Screen
- **Consistency**: Both medication and fluid slide from same direction for coherence

**5. Architecture Changes**
- **Removed**: Router-based popup navigation (Step 4.2 no longer needed)
- **Updated**: `app_shell.dart` to use `OverlayService` instead of `showGeneralDialog`
- **Simplified**: Direct overlay insertion without route management overhead

### 🔧 **Technical Implementation Details**

**OverlayService API:**
```dart
OverlayService.showFullScreenPopup({
  required BuildContext context,
  required Widget child,
  VoidCallback? onDismiss,
  OverlayAnimationType animationType = OverlayAnimationType.slideUp,
  double blurSigma = 10.0,
  Color backgroundColor = const Color(0x4D000000),
  bool dismissible = true,
});
```

**Animation Types:**
- `slideUp`: `Offset(0, 1)` → `Offset.zero` (200ms)
- `slideFromRight`: `Offset(1, 0)` → `Offset.zero` (250ms)  
- `slideFromLeft`: `Offset(-1, 0)` → `Offset.zero` (250ms)

**Benefits:**
- ✅ True full-screen blur coverage
- ✅ Configurable animations per popup
- ✅ Better performance (no route management)
- ✅ Cleaner architecture
- ✅ Consistent animation directions
