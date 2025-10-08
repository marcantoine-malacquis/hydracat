# Logging Services Architecture

## Overview

The logging feature uses a hybrid validation architecture that balances simplicity, maintainability, and separation of concerns. This document explains the validation patterns, service responsibilities, and integration guidelines.

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
ValidationResult validateForDuplicates({
  required MedicationSession newSession,
  required List<MedicationSession> recentSessions,
}) {
  // Compare against existing sessions
  // Return ValidationResult with duplicate error type
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

**Integration with Validation:**
```dart
// Before logging
if (_validationService != null) {
  final result = _validationService.validateMedicationSession(session);
  if (!result.isValid) {
    throw SessionValidationException(result.errors);
  }
  
  final duplicateResult = _validationService.validateForDuplicates(
    newSession: session,
    recentSessions: recentSessions,
  );
  if (!duplicateResult.isValid) {
    throw DuplicateSessionException(...);
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

### Pattern 2: Quick-Log (batch validation)
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
  
  // Reload cache after batch
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

*Last updated: Step 8.3 completion*
*Author: HydraCat Development Team*
