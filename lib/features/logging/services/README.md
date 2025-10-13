# Logging Services Architecture

## Overview

The logging feature uses a hybrid validation architecture that balances simplicity, maintainability, and separation of concerns. This document explains the validation patterns, service responsibilities, and integration guidelines.

## How Logging Works: Step-by-Step

This section explains exactly what happens when you log treatments, where data is stored, and when we read or write to local storage vs Firestore.

### 🔹 Long Press (Quick-Log All Treatments)

**What it does:** Logs all scheduled treatments for today at once (both medications and fluids).

**Steps:**
1. **Check local cache** (SharedPreferences)
   - 📖 **READ** from local storage: "Have any treatments been logged today?"
   - ❌ If yes → Stop and show error "Already logged today"
   - ✅ If no → Continue

2. **Get schedules from memory**
   - 📖 **READ** from memory (already cached): Get today's medication and fluid schedules
   - Count how many reminder times each schedule has for today

3. **Create all sessions**
   - Create one session for each reminder time
   - Example: Medication at 8am and 6pm = 2 sessions

4. **Write to Firestore** (1 batch operation)
   - ✍️ **WRITE** all sessions to Firestore
   - ✍️ **WRITE** daily summary (total counts, volumes, doses)
   - ✍️ **WRITE** weekly summary (aggregated data)
   - ✍️ **WRITE** monthly summary (aggregated data)
   - All 4+ writes happen atomically (all succeed or all fail)

5. **Update local cache** (optimistic - no Firestore read!)
   - Calculate totals from the schedules we just logged
   - ✍️ **WRITE** to local storage: Save counts, volumes, doses
   - **Cost: 0 Firestore reads** (we already know what we logged!)

6. **Show success popup**
   - Display: "X treatments logged for [pet name]"

**Firestore Cost:** 4+ writes, 0 reads

---

### 🔹 Normal Press → Medication Logging

**What it does:** Logs a single medication session with user input.

**Steps:**
1. **Show logging screen**
   - 📖 **READ** from local cache: "How many doses already logged today?"
   - Display in UI if any doses already given

2. **User fills form**
   - Medication name, dosage, time, completion status
   - User taps "Log Treatment"

3. **Check for duplicates**
   - 📖 **READ** local cache: "Has this medication been logged today?"
   - If **not in cache** → Skip Firestore check (0 reads) ✅
   - If **in cache** → 📖 **READ** Firestore for exact times (1-10 reads)
   - Check if same medication within ±15 minutes

4. **Write to Firestore** (1 batch operation)
   - ✍️ **WRITE** medication session to Firestore
   - ✍️ **WRITE** daily summary (increment counts)
   - ✍️ **WRITE** weekly summary (increment counts)
   - ✍️ **WRITE** monthly summary (increment counts)
   - All 4 writes happen atomically

5. **Update local cache**
   - ✍️ **WRITE** to local storage: Add this medication to cache
   - Increment: medication count, total doses given

6. **Show success**
   - Green banner: "Medication logged successfully"

**Firestore Cost:** 
- Best case: 4 writes, 0 reads (first time logging this medication today)
- Worst case: 4 writes, 10 reads (duplicate check for frequently logged medication)

---

### 🔹 Normal Press → Fluid Logging

**What it does:** Logs a single fluid therapy session with user input.

**Steps:**
1. **Show logging screen**
   - 📖 **READ** from local cache: "How much fluid already logged today?"
   - Display in UI: "XmL already logged today"

2. **User fills form**
   - Volume in mL, injection site, stress level, notes
   - User taps "Log Treatment"

3. **No duplicate detection**
   - Fluids don't check for duplicates (partial sessions are valid)
   - Multiple fluid sessions per day are normal

4. **Write to Firestore** (1 batch operation)
   - ✍️ **WRITE** fluid session to Firestore
   - ✍️ **WRITE** daily summary (increment volume)
   - ✍️ **WRITE** weekly summary (increment volume)
   - ✍️ **WRITE** monthly summary (increment volume)
   - All 4 writes happen atomically

5. **Update local cache**
   - ✍️ **WRITE** to local storage: Add this fluid session to cache
   - Increment: fluid session count, total volume given

6. **Show success**
   - Green banner: "Fluid session logged successfully"

**Firestore Cost:** 4 writes, 0 reads (always)

---

## Key Differences Summary

| Feature | Quick-Log (Long Press) | Medication (Normal Press) | Fluid (Normal Press) |
|---------|----------------------|---------------------------|---------------------|
| **Duplicate Check** | None (all-or-nothing) | Yes (±15 min window) | No |
| **Firestore Reads** | 0 | 0-10 (only if duplicate possible) | 0 |
| **Firestore Writes** | 4+ (all sessions + summaries) | 4 | 4 |
| **Cache Update** | Optimistic (calculated) | Incremental (add 1 session) | Incremental (add 1 session) |
| **Sessions Created** | Multiple (all reminders) | 1 | 1 |

---

## Local Storage vs Firestore

### SharedPreferences (Local Storage)
**What's stored:**
- Today's session counts (medications, fluids)
- Today's totals (doses given, volume given)
- Medication names logged today
- Date of the cache (expires at midnight)

**Purpose:**
- Fast duplicate detection (0 Firestore reads for first-time medications)
- Show "already logged today" information in UI
- Quick-log validation (reject if already logged)

**Cost:** Free (stored on device)

### Firestore (Cloud Database)
**What's stored:**
- All individual sessions (full history)
- Daily summaries (one per day)
- Weekly summaries (one per week)
- Monthly summaries (one per month)

**Purpose:**
- Permanent record of all treatments
- Multi-device sync
- Historical analytics and charts
- Adherence tracking

**Cost:** $0.06 per 100,000 reads, $0.18 per 100,000 writes

---

## Validation Architecture

### Hybrid Approach

The logging system uses a three-tier validation strategy:

```
┌─────────────────────────────────────────────────┐
│  Tier 1: Model-Level Validation (Structural)   │
│  - Required fields, type safety                │
│  - Data format and range checks                │
│  - Simple, fast, no external dependencies      │
└─────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────┐
│  Tier 2: Service-Level Validation (Business)   │
│  - Duplicate detection                          │
│  - Schedule consistency                         │
│  - Domain-specific medical rules                │
└─────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────┐
│  Tier 3: UI-Level Validation (Real-time)       │
│  - Immediate user feedback                      │
│  - Character limits, formatting                 │
│  - Input masking and suggestions                │
└─────────────────────────────────────────────────┘
```

### When to Use Each Tier

#### Model-Level (`session.validate()`)
**Use for:**
- Structural integrity checks (IDs not empty, required fields)
- Type constraints (dosage > 0, volume range)
- Format validation (valid timestamps, enum values)

**Example:**
```dart
// MedicationSession model
List<String> validate() {
  final errors = <String>[];
  if (dosageGiven < 0) errors.add('Dosage cannot be negative');
  if (dateTime.isAfter(DateTime.now())) {
    errors.add('Treatment time cannot be in the future');
  }
  return errors;
}
```

**Characteristics:**
- ✅ Fast (no I/O, no async)
- ✅ Pure functions (no side effects)
- ✅ Easy to test
- ❌ Can't access external data (cache, database)

#### Service-Level (`LoggingValidationService`)
**Use for:**
- Duplicate detection (requires recent sessions data)
- Cross-field validation (dosage vs schedule comparison)
- Medical domain rules (CKD-appropriate volumes)
- Schedule consistency checks

**Example:**
```dart
// LoggingValidationService
// Find duplicate session
final duplicate = validationService.findDuplicateSession(
  newSession: session,
  recentSessions: recentSessions,
);

if (duplicate != null) {
  throw DuplicateSessionException(
    sessionType: 'medication',
    conflictingTime: duplicate.dateTime,
    medicationName: duplicate.medicationName,
  );
}
```

**Characteristics:**
- ✅ Access to context data (cache, recent sessions)
- ✅ Rich validation results (errors + warnings)
- ✅ Medical domain expertise
- ⚠️ Requires data to be passed in (stateless)

#### UI-Level (Inline in screens)
**Use for:**
- Real-time feedback as user types
- Character counters and limits
- Input formatting (phone numbers, dates)
- Field-specific hints and suggestions

**Example:**
```dart
// FluidLoggingScreen
void _validateVolume() {
  setState(() {
    _volumeError = _volumeController.text.isEmpty 
      ? 'Volume is required'
      : double.tryParse(_volumeController.text) == null
        ? 'Please enter a valid number'
        : null;
  });
}
```

**Characteristics:**
- ✅ Immediate visual feedback
- ✅ Prevents form submission with invalid data
- ❌ Tied to UI state and lifecycle

## Service Responsibilities

### LoggingService
**Purpose:** Core business logic for treatment logging

**Responsibilities:**
- Create medication and fluid sessions
- Update existing sessions with delta calculation
- Quick-log all treatments atomically
- Match sessions to schedules
- Execute 4-write batch operations (session + 3 summaries)
- Coordinate with validation service
- Return accurate session counts for optimistic cache updates

**Integration with Validation:**
```dart
// Before logging
if (_validationService != null) {
  final result = _validationService.validateMedicationSession(session);
  if (!result.isValid) {
    throw SessionValidationException(result.errors);
  }
  
  final duplicate = _validationService.findDuplicateSession(
    newSession: session,
    recentSessions: recentSessions,
  );
  if (duplicate != null) {
    throw DuplicateSessionException(
      sessionType: 'medication',
      conflictingTime: duplicate.dateTime,
      medicationName: duplicate.medicationName,
    );
  }
}
```

### LoggingValidationService
**Purpose:** Complex business validation of logging sessions

**Responsibilities:**
- Duplicate detection for medication sessions
- Session-level validation (structural + business rules)
- Domain-specific medical validation (volume/dosage ranges)
- Schedule consistency validation
- Convert ValidationResult to LoggingException

**Key Methods:**
```dart
// Duplicate detection
ValidationResult validateForDuplicates({
  required MedicationSession newSession,
  required List<MedicationSession> recentSessions,
  Duration timeWindow = const Duration(minutes: 15),
});

// Session validation
ValidationResult validateMedicationSession(MedicationSession session);
ValidationResult validateFluidSession(FluidSession session);

// Domain-specific
ValidationResult validateFluidVolume({
  required double volumeGiven,
  double? scheduledVolume,
});

ValidationResult validateMedicationDosage({
  required double dosageGiven,
  required double dosageScheduled,
  required String medicationUnit,
});

// Schedule consistency
ValidationResult validateScheduleConsistency({
  required DateTime sessionTime,
  required DateTime? scheduledTime,
  Duration maxDrift = const Duration(hours: 2),
});

// Exception conversion
LoggingException toLoggingException(ValidationResult result);
```

### SummaryCacheService
**Purpose:** Local cache management for today's summary

**Responsibilities:**
- Store/retrieve today's summary in SharedPreferences
- Update cache incrementally after each log
- Update cache optimistically after quick-log (0 Firestore reads)
- Clear expired caches (midnight boundary)
- Multi-pet support via cache keys

### SummaryService
**Purpose:** Firestore summary reads with cache-first strategy

**Responsibilities:**
- Fetch daily/weekly/monthly summaries from Firestore
- Check cache before hitting Firestore (cost optimization)
- Document ID generation for time-based collections

### OfflineLoggingService
**Purpose:** Queue management for offline logging

**Responsibilities:**
- Enqueue operations when offline
- Auto-sync when connectivity restored
- Exponential backoff retry logic
- TTL management (30 days)

## Cache Initialization & Lifecycle

### Async Initialization Handling

The logging system must handle a critical timing issue: **LoggingNotifier initializes before user authentication completes**.

**The Problem:**
```
1. App starts → LoggingNotifier._initialize() runs
2. Tries to load cache from SharedPreferences
3. user = null (auth still in progress)
4. pet = null (profile not loaded yet)
5. Cache load silently fails
6. User authenticates successfully
7. ❌ Cache is never loaded!
```

**The Solution:**
`LoggingNotifier` uses **reactive cache loading** that watches for auth/profile changes:

```dart
// Set up during initialization
void _setupCacheReloadListeners() {
  // Watch for user authentication
  _ref.listen(currentUserProvider, (previous, next) {
    if (_previousUserId == null && next != null) {
      // User just authenticated - reload cache if pet also available
      if (_ref.read(primaryPetProvider) != null) {
        loadTodaysCache();
      }
    }
  });
  
  // Watch for pet profile loading
  _ref.listen(primaryPetProvider, (previous, next) {
    if (_previousPetId == null && next != null) {
      // Pet just loaded - reload cache if user also available
      if (_ref.read(currentUserProvider) != null) {
        loadTodaysCache();
      }
    }
  });
}
```

**Why This Matters:**

1. **Cost Optimization**: Without cache, duplicate detection requires Firestore reads
   - With cache: 0 reads for first-time medications ✅
   - Without cache: 1-10 reads per duplicate check ❌
   
2. **Data Integrity**: Cache prevents duplicate logging
   - With cache: Duplicate detection works correctly ✅
   - Without cache: Allows duplicate sessions ❌

3. **Aligns with Firebase CRUD Rules**: "Avoid unnecessary re-reads"

**Cache Lifecycle Events:**

| Event | Trigger | Action |
|-------|---------|--------|
| **App Startup** | `_initialize()` | Try to load cache (may fail if auth incomplete) |
| **User Auth** | `currentUserProvider` changes | Reload cache if pet available |
| **Pet Loaded** | `primaryPetProvider` changes | Reload cache if user available |
| **App Resume** | `AppLifecycleState.resumed` | Clear expired caches, reload today's cache |
| **After Logging** | Successful log operation | Update cache incrementally |
| **After Quick-Log** | Successful batch log | Update cache optimistically (0 reads) |

### Hot Restart Behavior

**Before Fix:**
```
1. Hot restart → LoggingNotifier initializes
2. user/pet are null → cache not loaded
3. User authenticates → cache still not loaded
4. Try to log medication → thinks nothing logged yet
5. Allows duplicate logging ❌
```

**After Fix:**
```
1. Hot restart → LoggingNotifier initializes
2. user/pet are null → cache not loaded (expected)
3. User authenticates → reactive listener triggered
4. Cache automatically reloaded ✅
5. Try to log medication → detects duplicate correctly ✅
```

## Integration Patterns

### Pattern 1: Manual Logging (with validation)
```dart
// In LoggingProvider
Future<bool> logMedicationSession({
  required MedicationSession session,
  required List<Schedule> todaysSchedules,
}) async {
  try {
    // Get cache and recent sessions for validation context
    final cache = await _cacheService.getTodaySummary(userId, petId);
    final recentSessions = cache?.hasMedicationLogged(session.medicationName)
      ? await _loggingService.getTodaysMedicationSessions(...)
      : [];
    
    // Service handles validation internally
    await _loggingService.logMedicationSession(
      session: session,
      todaysSchedules: todaysSchedules,
      recentSessions: recentSessions,
    );
    
    // Update cache after successful log
    await _cacheService.updateCacheWithMedicationSession(...);
    
    return true;
  } on DuplicateSessionException catch (e) {
    // Show update dialog to user
  } on SessionValidationException catch (e) {
    // Show validation errors
  }
}
```

### Pattern 2: Quick-Log (optimistic cache update)
```dart
// In LoggingProvider
Future<int> quickLogAllTreatments() async {
  // Pre-validate: check if any sessions already logged
  final cache = await _cacheService.getTodaySummary(userId, petId);
  if (cache?.hasAnySessions ?? false) {
    throw const LoggingException('Treatments already logged today');
  }
  
  // Service creates and validates all sessions
  final count = await _loggingService.quickLogAllTreatments(
    todaysSchedules: schedules,
  );
  
  // Update cache optimistically (0 Firestore reads - cost optimization)
  // Calculate totals from schedules since we know what was logged
  int totalMedicationSessions = 0;
  int totalFluidSessions = 0;
  double totalMedicationDoses = 0;
  double totalFluidVolume = 0;
  final medicationNames = <String>[];
  
  for (final schedule in schedules) {
    final todaysReminderCount = schedule.reminderTimes
      .where((time) => isSameDay(time, DateTime.now()))
      .length;
    
    if (schedule.isMedication) {
      totalMedicationSessions += todaysReminderCount;
      totalMedicationDoses += schedule.targetDosage * todaysReminderCount;
      medicationNames.add(schedule.medicationName);
    } else {
      totalFluidSessions += todaysReminderCount;
      totalFluidVolume += schedule.targetVolume * todaysReminderCount;
    }
  }
  
  // Update cache directly without Firestore read
  await _cacheService.updateCacheAfterQuickLog(
    userId: userId,
    petId: petId,
    medicationSessionCount: totalMedicationSessions,
    fluidSessionCount: totalFluidSessions,
    medicationNames: medicationNames,
    totalMedicationDoses: totalMedicationDoses,
    totalFluidVolume: totalFluidVolume,
  );
  
  // Reload state from SharedPreferences
  await loadTodaysCache();
  
  return count;
}
```

### Pattern 3: Session Update (with delta validation)
```dart
// In LoggingProvider (future implementation)
Future<void> updateSession({
  required MedicationSession oldSession,
  required MedicationSession newSession,
}) async {
  // Service validates and calculates deltas
  await _loggingService.updateMedicationSession(
    oldSession: oldSession,
    newSession: newSession,
  );
  
  // Update cache with delta
  await _cacheService.updateCacheWithSessionDelta(...);
}
```

## Design Decisions

### Why Hybrid Validation?
1. **Pragmatic**: Existing model validation works well - no need to refactor
2. **Focused**: Service handles complex cases requiring external data
3. **Maintainable**: Clear separation between structural and business validation
4. **Testable**: Stateless service with pure functions

### Why ValidationResult Pattern?
1. **Consistency**: Already used by ProfileValidationService
2. **Rich Context**: Supports errors, warnings, field names, types
3. **Flexible**: Can add new error types without breaking changes
4. **Flutter Standard**: Common pattern in Flutter/Dart ecosystem

### Why Optional in LoggingService?
1. **Backward Compatibility**: Service works with or without validation service
2. **Gradual Migration**: Can test in isolation before full integration
3. **Zero Breaking Changes**: Existing tests continue to pass

### Why Stateless Validation Service?
1. **Testability**: Easy to test with mock data
2. **Predictability**: No hidden state or side effects
3. **Performance**: No initialization overhead
4. **Thread Safety**: Safe to use across isolates

### Why Optimistic Cache Update for Quick-Log?
1. **Cost Optimization**: Eliminates 1 Firestore read per quick-log (100% savings)
2. **Performance**: No network round-trip for cache refresh
3. **Accuracy**: Uses same schedule data that was just logged atomically
4. **Safety**: Firebase batch writes are atomic - cache reflects reality
5. **Aligns with Firebase CRUD Rules**: "Avoid unnecessary re-reads - Cache data in local storage"

**Trade-offs:**
- ✅ Zero Firestore reads after successful batch write
- ✅ Faster user experience (no network latency)
- ✅ Consistent with Firebase cost optimization guidelines
- ⚠️ Cache could drift if batch write partially fails (extremely rare)
- ⚠️ Requires calculating totals from schedules (minimal CPU cost)

## Error Handling Flow

```
┌────────────────────────────────────────────────┐
│  User Action (log session)                    │
└────────────────────────────────────────────────┘
                    ↓
┌────────────────────────────────────────────────┐
│  LoggingProvider (UI → Service bridge)         │
└────────────────────────────────────────────────┘
                    ↓
┌────────────────────────────────────────────────┐
│  LoggingService                                │
│  ├─ Calls validation service                   │
│  ├─ Matches to schedule                        │
│  └─ Executes batch write                       │
└────────────────────────────────────────────────┘
                    ↓
┌────────────────────────────────────────────────┐
│  Error Handling (catch specific exceptions)   │
│  ├─ DuplicateSessionException → Update dialog │
│  ├─ SessionValidationException → Error banner │
│  ├─ BatchWriteException → Offline queue       │
│  └─ Generic LoggingException → Generic error  │
└────────────────────────────────────────────────┘
                    ↓
┌────────────────────────────────────────────────┐
│  LoggingErrorHandler (display to user)        │
│  ├─ showLoggingError (red banner)             │
│  ├─ showLoggingSuccess (green banner)         │
│  └─ showSyncRetry (yellow with retry button)  │
└────────────────────────────────────────────────┘
```

## Testing Strategy

### Unit Tests (Model-Level)
```dart
test('validates dosage range', () {
  final session = MedicationSession.create(
    dosageGiven: -1.0, // Invalid
    ...
  );
  
  final errors = session.validate();
  expect(errors, contains('Dosage cannot be negative'));
});
```

### Unit Tests (Service-Level)
```dart
test('detects duplicate within time window', () {
  final result = validationService.validateForDuplicates(
    newSession: newSession,
    recentSessions: [existingSession],
  );
  
  expect(result.isValid, false);
  expect(result.errors.first.type, ValidationErrorType.duplicate);
});
```

### Integration Tests (End-to-End)
```dart
testWidgets('logs medication with validation', (tester) async {
  // Navigate to logging screen
  // Enter session data
  // Tap log button
  // Verify success message or validation error
});
```

## Future Enhancements

### Planned
- Medical interaction warnings (e.g., conflicting medications)
- Maximum daily dosage limits (safety checks)
- Adherence pattern analysis (unusual deviations)
- Enhanced duplicate dialog with session comparison

### Under Consideration
- Machine learning for anomaly detection
- Veterinary prescription validation
- Multi-language medical terminology
- Batch edit validation for historical corrections

## Migration Path

For teams adopting this pattern:

1. **Phase 1**: Keep existing validation (backward compatible)
2. **Phase 2**: Introduce validation service alongside existing code
3. **Phase 3**: Update high-priority flows to use service
4. **Phase 4**: Gradually migrate remaining flows
5. **Phase 5**: Deprecate old validation methods (optional)

No breaking changes required - validation service is fully optional!

## Related Documentation

- [Logging Plan](../../../../~PLANNING/logging_plan.md) - Complete feature plan
- [Firestore Schema](../../../../.cursor/rules/firestore_schema.md) - Database structure
- [Firebase CRUD Rules](../../../../.cursor/rules/firebase_CRUDrules.md) - Cost optimization
- [Validation Models](../../../core/validation/models/validation_result.dart) - ValidationResult class

---

*Last updated: October 10, 2025 - Added cache initialization & lifecycle documentation*
*Author: HydraCat Development Team*
