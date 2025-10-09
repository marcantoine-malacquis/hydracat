# HydraCat Test Suite Index

This document provides a comprehensive index of all test files in the HydraCat project, organized by feature and type.

---

## 📊 Test Summary

- **Total Test Files**: 28
- **Unit Tests**: 18 files (150+ tests)
- **Widget Tests**: 5 files (75+ tests) 
- **Integration Tests**: 4 files (54 tests)
- **Provider Tests**: 1 file
- **Helper Files**: 3 files
- **Overall Pass Rate**: ~90% (350/383 tests passing, 33 known auth/onboarding failures)

---

## 📌 Important Notes

**This is the single source of truth for test documentation in HydraCat.**

- All test implementation details, coverage summaries, and known issues are centralized here
- For manual testing procedures, see feature-specific testing plans (e.g., `test/features/onboarding/ONBOARDING_TESTING_PLAN.md`)
- Historical milestone files have been archived to `~PLANNING/DONE/`

---

## 🔍 Quick Navigation

- [Entry Point Tests](#entry-point-tests)
- [Authentication Tests](#authentication-tests)
- [Logging Feature Tests](#logging-feature-tests)
- [Onboarding Tests](#onboarding-tests)
- [Provider Tests](#provider-tests)
- [Shared/Common Tests](#shared-tests)
- [Integration Tests](#integration-tests)
- [Test Helpers](#test-helpers)
- [Feature-Specific Testing Notes](#feature-specific-testing-notes)
- [Running Tests](#running-tests)

---

## Entry Point Tests

### `test/widget_test.dart`
**Type**: Smoke Test  
**Purpose**: Basic app initialization smoke test  
**Tests**: Verifies that HydraCat app initializes and shows loading state

---

## Authentication Tests

### `test/features/auth/models/auth_models_test.dart`
**Type**: Unit Test  
**Purpose**: Tests authentication models (`AppUser`, `AuthState`)  
**Coverage**:
- AppUser creation, JSON serialization, copyWith, equality
- AuthState variants (Loading, Unauthenticated, Authenticated, Error)
- Pattern matching with `when` and `maybeWhen`
- DateTime serialization

### `test/features/auth/screens/login_screen_test.dart`
**Type**: Widget Test  
**Purpose**: Tests LoginScreen UI and interactions  
**Coverage**:
- Email/password form fields and validation
- Password visibility toggle
- Social sign-in buttons (Google, Apple)
- Loading states
- Navigation to registration and forgot password screens

### `test/features/auth/services/auth_service_test.dart`
**Type**: Unit Test  
**Purpose**: Tests AuthService business logic  
**Coverage**:
- Email/password signup and signin
- Email verification (send, check status)
- Password reset
- Account lockout handling
- Error mapping (Firebase exceptions → app exceptions)
- Auth state changes stream
- Sign out

---

## Logging Feature Tests

### Model Tests

#### `test/features/logging/models/fluid_session_test.dart`
**Type**: Unit Test  
**Purpose**: Tests FluidSession model  
**Coverage**:
- Factory constructors (`create()`, `fromSchedule()`)
- Validation rules (volume 1-500ml, stress level, future dates)
- Sync helpers (`isSynced`, `isPendingSync`, `wasModified`)
- JSON serialization with FluidLocation enum
- `copyWith` functionality

#### `test/features/logging/models/medication_session_test.dart`
**Type**: Unit Test  
**Purpose**: Tests MedicationSession model  
**Coverage**:
- Factory constructors with schedule integration
- Validation (dosage, medication name, unit, future dates)
- Adherence helpers (`adherencePercentage`, `isFullDose`, `isPartialDose`, `isMissed`)
- Sync helpers
- JSON serialization

#### `test/features/logging/models/summary_update_dto_test.dart`
**Type**: Unit Test  
**Purpose**: Tests SummaryUpdateDto for Firestore increments  
**Coverage**:
- Creating DTOs from new sessions (medication and fluid)
- Calculating deltas for session updates
- Firestore FieldValue.increment() conversions
- Handling missed/completed/partial medication doses

### Service Tests

#### `test/features/logging/services/logging_service_test.dart`
**Type**: Unit Test  
**Purpose**: Tests LoggingService business logic (without Firebase)  
**Coverage**:
- Session validation with and without ValidationService
- Duplicate detection for medications
- Error handling and exceptions
- Note: Firebase-dependent tests (batch writes, FieldValue.increment) deferred to integration tests

#### `test/features/logging/services/logging_validation_service_test.dart`
**Type**: Unit Test  
**Purpose**: Tests LoggingValidationService  
**Coverage**:
- Duplicate detection (15-minute window, medication name matching)
- Medication session validation (name length, dosage, future dates)
- Fluid session validation (volume range, future dates)
- Volume warnings (unusually low/high, scheduled vs actual)
- Dosage validation (negative, unrealistically high, partial doses)
- Schedule consistency checks (time drift)
- Exception conversion

#### `test/features/logging/services/offline_logging_service_test.dart`
**Type**: Unit Test  
**Purpose**: Tests OfflineLoggingService  
**Coverage**:
- Queue operations (enqueue, persistence across instances)
- Queue limits (warning at 50, full at 200)
- TTL management (30-day expiration)
- Query methods (pending, failed operations, queue size)
- Analytics tracking

#### `test/features/logging/services/summary_cache_service_test.dart`
**Type**: Unit Test  
**Purpose**: Tests SummaryCacheService  
**Coverage**:
- Getting today's summary from SharedPreferences
- Cache expiration and cleanup
- Updating cache with medication sessions (deduplicating names)
- Updating cache with fluid sessions
- Clearing expired caches and pet-specific caches

#### `test/features/logging/services/summary_service_test.dart`
**Type**: Unit Test  
**Purpose**: Tests SummaryService architecture  
**Coverage**:
- Service dependency mocking
- Cache service integration
- Note: Full Firestore tests deferred to integration tests

### Widget Tests

#### `test/features/logging/widgets/fluid_logging_screen_test.dart`
**Type**: Widget Test  
**Purpose**: Tests FluidLoggingScreen UI  
**Coverage**:
- Pre-filling from schedule (volume, injection site)
- Default values when no schedule
- Volume validation (1-500ml, non-numeric)
- Injection site and stress level selectors
- Notes input with character count
- Daily summary info card
- Loading states and error handling
- Accessibility (semantic labels)

#### `test/features/logging/widgets/medication_logging_screen_test.dart`
**Type**: Widget Test  
**Purpose**: Tests MedicationLoggingScreen UI  
**Coverage**:
- Medication selection cards
- Select All/Deselect All functionality
- Notes input with character count and expanding field
- Log button state (enabled/disabled based on selection)
- Button text updates with selection count
- Loading states and threshold timing (120ms)
- Error handling (duplicate sessions)
- Accessibility (semantic labels)

#### `test/features/logging/widgets/treatment_choice_popup_test.dart`
**Type**: Widget Test  
**Purpose**: Tests TreatmentChoicePopup UI  
**Coverage**:
- Medication and Fluid Therapy buttons
- Cancel button
- Treatment choice selection
- Analytics tracking
- Visual feedback (icons, divider)
- Accessibility (semantic labels)

---

## Onboarding Tests

### `test/features/onboarding/widgets/onboarding_ui_test.dart`
**Type**: Widget Test  
**Purpose**: Tests onboarding UI components  
**Coverage**:
- OnboardingProgressIndicator dot display
- OnboardingStepType enum validation (6 steps)
- Progress indicator animations between steps

---

## Provider Tests

### `test/providers/auth_provider_test.dart`
**Type**: Provider Test  
**Purpose**: Tests AuthNotifier and convenience providers  
**Coverage**:
- Sign up (success and failure cases)
- Sign in (success and failure cases)
- Google sign in
- Sign out (success and failure)
- Email verification
- Password reset email
- Convenience providers (`currentUserProvider`, `isAuthenticatedProvider`)

---

## Shared Tests

### Service Tests

#### `test/shared/services/feature_gate_service_test.dart`
**Type**: Unit Test  
**Purpose**: Tests FeatureGateService  
**Coverage**:
- Free features list (fluid_logging, reminders, basic_streak_tracking, etc.)
- Premium features list (pdf_export, advanced_analytics, detailed_reports, etc.)
- No overlap between free and premium features
- Feature categorization logic

#### `test/shared/services/login_attempt_service_test.dart`
**Type**: Unit Test  
**Purpose**: Tests LoginAttemptService for brute-force protection  
**Coverage**:
- Account lockout detection
- Recording failed attempts (incrementing, applying lockout at max)
- Recording successful login (clearing attempts)
- Warning messages when close to threshold
- Data expiration (24-hour TTL)
- Email trimming consistency

### Widget Tests

#### `test/shared/widgets/accessibility/hydra_touch_target_test.dart`
**Type**: Widget Test  
**Purpose**: Tests HydraTouchTarget accessibility wrapper  
**Coverage**:
- Minimum width/height constraints (48dp)
- Custom minimum size support
- Alignment property
- Semantic labels and button marking
- Excluding child semantics
- Actual rendered size validation

#### `test/shared/widgets/accessibility/touch_target_icon_button_test.dart`
**Type**: Widget Test  
**Purpose**: Tests TouchTargetIconButton  
**Coverage**:
- Icon rendering and onPressed callback
- Minimum touch target constraints (48dp)
- Tooltip and semantic labels
- Icon color and size customization
- Disabled state (onPressed null)
- Visual density and padding
- Splash radius

#### `test/shared/widgets/loading/loading_overlay_test.dart`
**Type**: Widget Test  
**Purpose**: Tests LoadingOverlay states  
**Coverage**:
- None state (shows content)
- Loading state (shows spinner)
- Success state (shows success indicator)
- Accessibility semantics for loading/success
- Custom content opacity
- Default loading message

---

## Integration Tests

Integration tests verify end-to-end functionality with mocked Firebase services using `fake_cloud_firestore` and `mocktail`. All 54 integration tests are passing.

### `test/integration_test/auth_flow_test.dart`
**Type**: Integration Test (7 tests)  
**Purpose**: Tests authentication UI flows with mocked services  
**Coverage**:
- Login screen display with all UI elements
- Form validation (empty fields, email format, password length)
- Navigation to registration and forgot password screens
- Password visibility toggle
- Mocked `AuthService` with stubbed methods
- GoRouter navigation testing with `MaterialApp.router`

**Key Features**:
- Uses `ProviderScope` overrides for Riverpod testing
- Custom `SimpleAuthNotifier` for isolated testing
- Proper widget testing with `ensureVisible()` for off-screen elements
- No Firebase dependencies (fully mocked)

### `test/integration_test/logging/logging_flow_test.dart`
**Type**: Integration Test (15 tests)  
**Purpose**: Tests end-to-end logging flows with mocked Firestore  
**Coverage**:
- **Manual Medication Logging**: Schedule pre-filling, duplicate detection (±15 min window), validation, cache updates
- **Manual Fluid Logging**: Schedule matching, multiple sessions per day, volume validation
- **Quick-Log All Treatments**: Batch logging, already-logged detection, empty schedule handling
- **Edge Cases**: Multiple medications with same name, schedule matching, composite index queries

**Key Features**:
- Uses `FakeFirebaseFirestore` for Firestore simulation
- Integration with `SummaryCacheService` via `SharedPreferences` mocks
- Schedule-to-session conversion testing
- Time-based duplicate detection logic

### `test/integration_test/logging/offline_sync_test.dart`
**Type**: Integration Test (16 tests)  
**Purpose**: Tests offline queue and sync functionality  
**Coverage**:
- **Offline Queue Management**: Enqueue operations (medication/fluid), local cache updates (optimistic UI), queue warnings (50 ops), queue limits (200 ops)
- **Offline Sync Execution**: Chronological sync order, successful operation removal, failed operation preservation, mixed success/failure scenarios
- **Connectivity State Management**: Repeated offline/online cycles, queue persistence
- **Sync Conflict Scenarios**: `createdAt` timestamp conflict resolution, queue expiration (30-day TTL)

**Key Features**:
- `OfflineLoggingService` with `SharedPreferences` persistence
- Network connectivity simulation
- Operation queue TTL management
- Firestore DateTime/Timestamp handling

### `test/integration_test/logging/batch_write_test.dart`
**Type**: Integration Test (16 tests)  
**Purpose**: Tests 4-write batch strategy for Firestore writes  
**Coverage**:
- **Medication Session Batch**: Session document structure, daily/weekly/monthly summary creation with `FieldValue.increment()`, schedule matching (name + time), no matching schedule handling
- **Fluid Session Batch**: Injection site enum serialization, fluid-specific summary fields, schedule matching (time only), multiple sessions per day, stress level/injection site optionality, volume validation (1-500ml)
- **Multi-Session Aggregation**: Aggregating 5 medication sessions, mixed medication/fluid sessions, session update delta calculations, accuracy across week boundaries

**Key Features**:
- Tests Firestore batch writes (1 session + 3 summaries)
- `FieldValue.increment()` validation with `FakeFirebaseFirestore`
- Schedule matching algorithms
- Summary aggregation accuracy

---

## Test Helpers

### `test/helpers/test_data_builders.dart`
**Type**: Helper  
**Purpose**: Builder pattern classes for creating test data  
**Provides**:
- `FluidSessionBuilder` - creates test FluidSession instances
- `MedicationSessionBuilder` - creates test MedicationSession instances
- `ScheduleBuilder` - creates test Schedule instances
- `DailySummaryCache` helpers
- Pre-configured builders (`.completed()`, `.missed()`, `.partial()`)
- Integration test extensions (`fromSchedule()`, `withTodaysReminder()`, etc.)
- Global ID counter to prevent ID collisions in rapid test execution

### `test/helpers/integration_test_helpers.dart`
**Type**: Helper  
**Purpose**: Helper functions for integration tests  
**Provides**:
- `createFakeFirestore()` - creates pre-configured `FakeFirebaseFirestore` instance
- Assertion helpers (`assertSessionExists()`, `assertFluidSessionExists()`, `assertSummaryExists()`)
- Document counting with where conditions (`countDocuments()`)
- Schedule-to-session conversion helpers
- Firestore query helpers for integration tests

### `test/helpers/widget_test_helpers.dart`
**Type**: Helper  
**Purpose**: Helper functions for widget tests  
**Provides**:
- Mock setup functions (`MockLoggingNotifier`, `MockAnalyticsService`, etc.)
- Widget pump functions (`pumpFluidLoggingScreen`, `pumpMedicationLoggingScreen`, etc.)
- Test data creators (`createTestFluidSchedule`, `createTestMedicationSchedule`, etc.)
- `registerFallbackValues()` for mocktail

---

## 🔬 Feature-Specific Testing Notes

### Logging Feature

**Test Status**: ✅ Complete (150 unit + 67 widget + 54 integration tests) - **All Passing**

**Pass Rates**:
- Unit Tests: 150/150 (100%) ✅
- Widget Tests: 67/67 (100%) ✅  
- Integration Tests: 54/54 (100%) ✅

**Previously Resolved Issues**:
- **Timer Cleanup**: Previously problematic medication logging screen tests now pass using `tester.runAsync()` for proper async/timer handling. All 24 tests passing.

**Integration Test Details**:
- Uses `fake_cloud_firestore` for Firestore simulation (no Firebase Emulator required)
- 4-write batch strategy tested: 1 session + 3 summaries (daily/weekly/monthly)
- `FieldValue.increment()` behavior verified with fake Firestore
- Schedule matching algorithms tested with time-based queries
- Offline sync tested with connectivity state mocking

**Performance**:
- Unit tests: ~3 seconds
- Widget tests: ~5 seconds
- Integration tests: ~25 seconds
- **Total suite**: < 30 seconds

**Firebase Cost Optimization**:
- Zero reads during duplicate detection (cache-first approach)
- Single write per session (batch write with summaries)
- All integration tests use mocks (zero production Firebase costs)

### Onboarding Feature

**Test Status**: ⚠️ Partial (widget tests with 1 failure, integration tests pending)

**Pass Rates**:
- Onboarding UI Widget Tests: 2/3 (1 failure) ⚠️

**Known Issues**:
- `OnboardingStepType enum has correct total steps` test failing

**Manual Testing**:
- Comprehensive manual testing plan available at `test/features/onboarding/ONBOARDING_TESTING_PLAN.md`
- 105 manual test checkpoints covering all 6 onboarding screens
- Includes persona-adaptive routing, offline functionality, and error recovery testing

**Automated Coverage**:
- Widget tests: OnboardingProgressIndicator, OnboardingStepType enum
- Integration tests: Not yet implemented (TBD)

### Authentication Feature

**Test Status**: ⚠️ Partial (models complete, services/widgets have failures)

**Pass Rates**:
- Auth Models: 100% ✅
- Auth Service: ~50% (16 failures) ⚠️
- Login Screen Widget: ~40% (9 failures) ⚠️
- Auth Provider: ~40% (6 failures) ⚠️
- Auth Flow Integration: Passing ✅

**Known Issues**:
- Auth service tests failing with Firebase mock setup issues
- Login screen widget tests failing with provider/dependency errors
- Auth provider convenience provider tests failing

**Security Testing**:
- Account lockout tested in `login_attempt_service_test.dart` ✅
- Brute-force protection with 24-hour TTL ✅

### Shared Components

**Test Status**: ✅ Complete (accessibility + services) - **All Passing**

**Pass Rates**:
- Accessibility Tests: 100% ✅
- Service Tests: 100% ✅
- Loading Overlay Tests: 8/8 (100%) ✅

**Highlights**:
- Touch target accessibility testing (48dp minimum constraints) ✅
- Feature gate service (free vs premium features) ✅
- Login attempt service (security) ✅
- Loading overlay with AnimatedOpacity state transitions ✅

**Recently Fixed**:
- **LoadingOverlay Widget Tests**: Updated tests to match current implementation which uses AnimatedOpacity to control visibility of both loading and success indicators simultaneously (instead of conditionally rendering them).

---

## 🏃‍♂️ Running Tests

### Run all tests (including integration tests)
```bash
flutter test
```

### Run only unit and widget tests (exclude integration tests)
```bash
flutter test --exclude-tags=integration
```

### Run only integration tests
```bash
flutter test test/integration_test/
```

### Run specific integration test file
```bash
flutter test test/integration_test/auth_flow_test.dart
flutter test test/integration_test/logging/batch_write_test.dart
```

### Run specific test file
```bash
flutter test test/features/auth/services/auth_service_test.dart
```

### Run tests in a directory
```bash
flutter test test/features/logging/
```

### Run with coverage
```bash
flutter test --coverage
```

### Run integration tests with verbose output
```bash
flutter test test/integration_test/ --reporter expanded
```

---

## 📝 Notes

- **Integration Tests**: All Firebase-dependent functionality (batch writes, `FieldValue.increment()`, schedule matching, offline sync) is thoroughly tested in the `test/integration_test/` directory using `fake_cloud_firestore`. All 54 integration tests are passing.

- **Test Data Builders**: Use the builders in `test_data_builders.dart` for consistent test data creation. Integration test extensions like `fromSchedule()` and `withTodaysReminder()` are specifically designed for integration testing scenarios.

- **Integration Test Helpers**: Use helper functions in `integration_test_helpers.dart` for Firestore-related assertions and test setup. These helpers work with `FakeFirebaseFirestore` to simulate real Firestore behavior.

- **Widget Test Helpers**: Use helper functions in `widget_test_helpers.dart` for consistent widget testing setup.

- **Mock Services**: Integration tests use `mocktail` for service mocking and `fake_cloud_firestore` for Firestore simulation, eliminating the need for Firebase Emulator while maintaining realistic test scenarios.

---

## 🔄 Last Updated

**October 9, 2025** - Centralized all test documentation as single source of truth. Removed redundant reference files and archived historical milestones to `~PLANNING/DONE/`. Verified all logging tests (271 tests) passing - timer issues resolved. **Fixed LoadingOverlay widget tests (8/8 passing)** to match AnimatedOpacity implementation. Documented 33 pre-existing auth/onboarding test failures requiring investigation.

