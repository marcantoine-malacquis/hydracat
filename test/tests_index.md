# HydraCat Test Suite Index

This document provides a comprehensive index of all test files in the HydraCat project, organized by feature and type.

---

## 📊 Test Summary

- **Total Test Files**: 24
- **Feature Tests**: 18
- **Provider Tests**: 1
- **Shared/Utility Tests**: 5
- **Helper Files**: 2

---

## 🔍 Quick Navigation

- [Entry Point Tests](#entry-point-tests)
- [Authentication Tests](#authentication-tests)
- [Logging Feature Tests](#logging-feature-tests)
- [Onboarding Tests](#onboarding-tests)
- [Provider Tests](#provider-tests)
- [Shared/Common Tests](#shared-tests)
- [Test Helpers](#test-helpers)

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

### `test/helpers/widget_test_helpers.dart`
**Type**: Helper  
**Purpose**: Helper functions for widget tests  
**Provides**:
- Mock setup functions (`MockLoggingNotifier`, `MockAnalyticsService`, etc.)
- Widget pump functions (`pumpFluidLoggingScreen`, `pumpMedicationLoggingScreen`, etc.)
- Test data creators (`createTestFluidSchedule`, `createTestMedicationSchedule`, etc.)
- `registerFallbackValues()` for mocktail

---

## 🏃‍♂️ Running Tests

### Run all tests
```bash
flutter test
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

---

## 📝 Notes

- **Integration Tests**: Some Firebase-dependent tests (batch writes, FieldValue.increment, schedule matching) are deferred to integration tests with Firebase Emulator (see `test/features/logging/services/logging_service_test.dart` comments).

- **Test Data Builders**: Use the builders in `test_data_builders.dart` for consistent test data creation across all tests.

- **Widget Test Helpers**: Use helper functions in `widget_test_helpers.dart` for consistent widget testing setup.

- **Reference Files**: This index excludes reference/documentation files (README.md, TESTING_SUMMARY.md, etc.) but you can read them for additional context on testing strategies.

---

## 🔄 Last Updated

This index was last updated based on the test suite structure as of the documentation generation date.

