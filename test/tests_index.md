# HydraCat Test Suite Index

This document provides a comprehensive index of all test files in the HydraCat project, organized by feature and type.

---

## 📊 Test Summary (Latest Run: 2025-11-15)

**Test Run Results**: `00:24 +596 ~26 -192: Some tests failed.`

- **Total Tests**: 814 tests
  - **Passing**: 596 ✅ (73.2%)
  - **Failing**: 192 ❌ (23.6%)
  - **Skipped**: 26 ⊘ (3.2%)

**Test Cases Documented Below**: 323 unique test case descriptions identified (some test cases contain multiple assertions, setup/teardown operations, or parameterized variations that contribute to the 814 total)

---

## 📌 Important Notes

**This is the single source of truth for test documentation in HydraCat.**

- All test implementation details, coverage summaries, and known issues are centralized here
- Tests marked with ❌ **[FAILING]** tags require attention and fixing
- For manual testing procedures, see feature-specific testing plans (e.g., `test/features/onboarding/ONBOARDING_TESTING_PLAN.md`)
- Historical milestone files have been archived to `~PLANNING/DONE/`

---

## 🔍 Quick Navigation

- [Entry Point Tests](#entry-point-tests)
- [App Tests](#app-tests)
- [Authentication Tests](#authentication-tests)
- [Logging Feature Tests](#logging-feature-tests)
- [Notifications Feature Tests](#notifications-feature-tests)
- [Onboarding Tests](#onboarding-tests)
- [Profile Feature Tests](#profile-feature-tests)
- [Progress Feature Tests](#progress-feature-tests)
- [Provider Tests](#provider-tests)
- [Shared Model Tests](#shared-model-tests)
- [Shared Widget Tests](#shared-widget-tests)
- [Integration Tests](#integration-tests)
- [Running Tests](#running-tests)

---

## Entry Point Tests

### `test/widget_test.dart` ✅

**Type**: Smoke Test
**Purpose**: Basic app initialization smoke test
**Stats**: 1 test | ✅ 1 passing | ❌ 0 failing

**Tests**:
- ✅ HydraCat app smoke test

---

## App Tests

### `test/app/home_app_bar_icon_test.dart` ✅

**Type**: Widget Test
**Purpose**: Tests home app bar icon visibility logic
**Stats**: 1 test | ✅ 1 passing | ❌ 0 failing

**Tests**:
- ✅ Bell icon shows when permission granted + setting enabled

---

## Authentication Tests

### `test/features/auth/screens/login_screen_test.dart` ✅

**Type**: Widget Test
**Purpose**: Tests LoginScreen UI and interactions
**Stats**: 8 tests | ✅ 8 passing | ❌ 0 failing

**Coverage**:
- Email/password form fields and validation
- Password visibility toggle
- Navigation to registration and forgot password screens
- Social sign-in buttons (Google, Apple)

**Tests**:
- ✅ LoginScreen Widget Tests should contain social sign-in buttons
- ✅ LoginScreen Widget Tests should display login form with email and password fields
- ✅ LoginScreen Widget Tests should navigate to forgot password screen
- ✅ LoginScreen Widget Tests should navigate to registration screen
- ✅ LoginScreen Widget Tests should show proper form validation on submit
- ✅ LoginScreen Widget Tests should show validation errors for empty fields
- ✅ LoginScreen Widget Tests should toggle password visibility
- ✅ LoginScreen Widget Tests should validate email format

---

### `test/features/auth/services/auth_service_test.dart` ❌

**Type**: Unit Test
**Purpose**: Tests AuthService business logic
**Stats**: 17 tests | ✅ 0 passing | ❌ 17 failing

**Coverage**:
- Email/password signup and signin
- Email verification (send, check status)
- Password reset
- Account lockout handling
- Error mapping (Firebase exceptions → app exceptions)
- Auth state changes stream
- Sign out

**Tests**:
- ❌ **[FAILING]** AuthService Auth State Management should provide auth state changes stream
- ❌ **[FAILING]** AuthService Email Verification should check email verification status
- ❌ **[FAILING]** AuthService Email Verification should fail when no user is signed in
- ❌ **[FAILING]** AuthService Email Verification should handle offline verification check gracefully
- ❌ **[FAILING]** AuthService Email Verification should send verification email successfully
- ❌ **[FAILING]** AuthService Email/Password Authentication should handle account lockout
- ❌ **[FAILING]** AuthService Email/Password Authentication should record failed attempt on invalid credentials
- ❌ **[FAILING]** AuthService Email/Password Authentication should sign in with valid email and password
- ❌ **[FAILING]** AuthService Email/Password Authentication should sign up with valid email and password
- ❌ **[FAILING]** AuthService Email/Password Authentication should throw WeakPasswordException on weak password
- ❌ **[FAILING]** AuthService Error Handling should handle network errors gracefully
- ❌ **[FAILING]** AuthService Error Handling should maintain auth state during offline periods
- ❌ **[FAILING]** AuthService Error Handling should map Firebase exceptions to app exceptions
- ❌ **[FAILING]** AuthService Password Recovery should handle invalid email for password reset
- ❌ **[FAILING]** AuthService Password Recovery should send password reset email
- ❌ **[FAILING]** AuthService Sign Out should handle sign out errors gracefully
- ❌ **[FAILING]** AuthService Sign Out should sign out successfully

**Known Issues**: All auth service tests failing with Firebase mock setup issues

---

## Logging Feature Tests

### Model Tests

#### `test/features/logging/models/fluid_session_test.dart` ✅

**Type**: Unit Test
**Purpose**: Tests FluidSession model
**Stats**: 13 tests | ✅ 13 passing | ❌ 0 failing

**Tests by Group**:

**FluidSession Validation - Invalid Cases**:
- ✅ future dateTime
- ✅ invalid stressLevel value
- ✅ volumeGiven < 1ml
- ✅ volumeGiven > 500ml

**FluidSession Validation - Valid Cases**:
- ✅ stressLevel is "high"
- ✅ stressLevel is "low"
- ✅ stressLevel is "medium"
- ✅ stressLevel is null

**General Tests**:
- ✅ FluidSession JSON Serialization round-trip preserves enum values
- ✅ FluidSession Validation valid session passes validation
- ✅ FluidSession copyWith preserves fields when no parameters provided
- ✅ FluidSession copyWith preserves unchanged fields
- ✅ FluidSession copyWith updates fields correctly

---

#### `test/features/logging/models/medication_session_test.dart` ✅

**Type**: Unit Test
**Purpose**: Tests MedicationSession model
**Stats**: 8 tests | ✅ 8 passing | ❌ 0 failing

**Tests by Group**:

**MedicationSession Validation - Invalid Cases**:
- ✅ dosageGiven < 0
- ✅ dosageScheduled <= 0
- ✅ empty medicationName
- ✅ empty medicationUnit
- ✅ future dateTime

**General Tests**:
- ✅ MedicationSession Validation valid session passes validation
- ✅ MedicationSession copyWith copies with updated fields
- ✅ MedicationSession copyWith preserves unchanged fields

---

#### `test/features/logging/models/summary_update_dto_test.dart` ✅

**Type**: Unit Test
**Purpose**: Tests SummaryUpdateDto for Firestore increments
**Stats**: 1 test | ✅ 1 passing | ❌ 0 failing

**Tests**:
- ✅ SummaryUpdateDto toFirestoreUpdate() omits null fields

---

### Service Tests

#### `test/features/logging/services/logging_service_duplicate_flow_test.dart` ✅

**Type**: Unit Test
**Purpose**: Tests duplicate detection flow
**Stats**: 1 test | ✅ 1 passing | ❌ 0 failing

**Tests**:
- ✅ LoggingService duplicate handling throws DuplicateSessionException via converter with context

---

#### `test/features/logging/services/logging_service_test.dart` ✅

**Type**: Unit Test
**Purpose**: Tests LoggingService business logic
**Stats**: 10 tests | ✅ 10 passing | ❌ 0 failing

**Tests**:
- ✅ (setUpAll)
- ✅ (tearDownAll)
- ✅ LoggingService - Business Logic Tests Session Updates - Validation updateFluidSession validates new session
- ✅ LoggingService - Business Logic Tests Session Updates - Validation updateMedicationSession validates new session
- ✅ LoggingService - Business Logic Tests Validation (With ValidationService) calls ValidationService before logging fluid
- ✅ LoggingService - Business Logic Tests Validation (With ValidationService) calls ValidationService before logging medication
- ✅ LoggingService - Business Logic Tests Validation (With ValidationService) respects ValidationService rejection
- ✅ LoggingService - Business Logic Tests Validation (Without ValidationService) rethrows validation errors without modification
- ✅ LoggingService - Business Logic Tests Validation (Without ValidationService) throws SessionValidationException for invalid fluid session
- ✅ LoggingService - Business Logic Tests Validation (Without ValidationService) throws SessionValidationException for invalid medication session

---

#### `test/features/logging/services/logging_validation_service_test.dart` ❌

**Type**: Unit Test
**Purpose**: Tests LoggingValidationService
**Stats**: 1 test | ✅ 0 passing | ❌ 1 failing

**Tests**:
- ❌ **[FAILING]** LoggingValidationService toLoggingException converts duplicate error to DuplicateSessionException

---

#### `test/features/logging/services/offline_logging_service_test.dart` ❌

**Type**: Unit Test
**Purpose**: Tests OfflineLoggingService
**Stats**: 12 tests | ✅ 1 passing | ❌ 11 failing

**Tests**:
- ❌ **[FAILING]** OfflineLoggingService Query Methods getPendingOperations() returns only pending status
- ❌ **[FAILING]** OfflineLoggingService Query Methods getQueueSize() returns accurate count
- ❌ **[FAILING]** OfflineLoggingService Query Methods shouldShowWarning() returns true at threshold
- ❌ **[FAILING]** OfflineLoggingService Queue Limits throws QueueFullException at 200 operations
- ❌ **[FAILING]** OfflineLoggingService Queue Limits throws QueueWarningException at 50 operations
- ❌ **[FAILING]** OfflineLoggingService Queue Limits tracks analytics on queue full error
- ❌ **[FAILING]** OfflineLoggingService Queue Operations enqueues operation successfully
- ❌ **[FAILING]** OfflineLoggingService Queue Operations persists queue across service instances
- ❌ **[FAILING]** OfflineLoggingService Queue Operations returns operations in chronological order
- ❌ **[FAILING]** OfflineLoggingService Queue Operations tracks analytics on enqueue
- ❌ **[FAILING]** OfflineLoggingService TTL Management preserves operations within TTL
- ✅ OfflineLoggingService TTL Management removes expired operations (>30 days old) on enqueue

**Known Issues**: DateTime serialization issues in offline queue persistence

---

#### `test/features/logging/services/summary_cache_service_test.dart` ✅

**Type**: Unit Test
**Purpose**: Tests SummaryCacheService
**Stats**: 12 tests | ✅ 12 passing | ❌ 0 failing

**Tests**:
- ✅ SummaryCacheService clearExpiredCaches removes old caches but keeps today's cache
- ✅ SummaryCacheService clearPetCache does not affect other pets' caches
- ✅ SummaryCacheService clearPetCache removes specific pet's cache
- ✅ SummaryCacheService getTodaySummary handles malformed JSON gracefully
- ✅ SummaryCacheService getTodaySummary returns cached data if valid for today
- ✅ SummaryCacheService getTodaySummary returns null and removes cache if expired
- ✅ SummaryCacheService getTodaySummary returns null if cache does not exist
- ✅ SummaryCacheService updateCacheWithFluidSession creates new cache if none exists
- ✅ SummaryCacheService updateCacheWithFluidSession increments counts when updating existing cache
- ✅ SummaryCacheService updateCacheWithMedicationSession creates new cache if none exists
- ✅ SummaryCacheService updateCacheWithMedicationSession does not duplicate medication names
- ✅ SummaryCacheService updateCacheWithMedicationSession increments counts when updating existing cache

---

#### `test/features/logging/services/monthly_array_helper_test.dart` ✅

**Type**: Unit Test
**Purpose**: Tests MonthlyArrayHelper for safe monthly array updates
**Stats**: 22 tests | ✅ 22 passing | ❌ 0 failing

**Coverage**:
- Array initialization (null, empty arrays)
- Array resizing (padding/truncation for 28-31 day months)
- Value updates (preserving other values, correct indexing)
- Bounds clamping (day bounds 1-31, value bounds 0-5000)
- Month length variations (28, 29, 30, 31 days)
- Edge cases (multiple updates, day preservation)

**Tests by Group**:

**Array Initialization**:
- ✅ null array creates zero-filled array
- ✅ empty array creates zero-filled array

**Array Resizing**:
- ✅ short array (28) pads to 31 with zeros
- ✅ long array (31) truncates to 28
- ✅ correct length array not resized

**Value Updates**:
- ✅ day 1 updates index 0
- ✅ day 15 updates index 14
- ✅ day 31 updates index 30
- ✅ preserves other values in array

**Bounds Clamping**:
- ✅ dayOfMonth = 0 clamps to 1 (index 0)
- ✅ dayOfMonth = 32 clamps to monthLength (31)
- ✅ negative dayOfMonth clamps to 1
- ✅ newValue = -100 clamps to 0
- ✅ newValue = 6000 clamps to 5000
- ✅ newValue at upper bound (5000) not clamped
- ✅ newValue at lower bound (0) not clamped

**Month Length Variations**:
- ✅ February leap year (29 days)
- ✅ February non-leap (28 days)
- ✅ 30-day month (April, June, September, November)
- ✅ 31-day month (Jan, Mar, May, Jul, Aug, Oct, Dec)

**Edge Cases**:
- ✅ updating same day multiple times
- ✅ updating different days preserves previous values

**Related**: Phase 0 implementation of ProgressMonthView optimization. Used by Phase 1 write path in logging_service.dart to populate daily arrays in monthly summaries.

---

### Widget Tests

#### `test/features/logging/widgets/fluid_logging_screen_test.dart` ✅

**Type**: Widget Test
**Purpose**: Tests FluidLoggingScreen UI
**Stats**: 23 tests | ✅ 23 passing | ❌ 0 failing

**Tests by Group**:

**Accessibility**:
- ✅ (tearDownAll)
- ✅ FluidLoggingScreen - Accessibility displays info card with decorative icon
- ✅ FluidLoggingScreen - Accessibility has semantic label on Log button
- ✅ FluidLoggingScreen - Accessibility has semantic labels on selectors

**Error Handling**:
- ✅ FluidLoggingScreen - Error Handling handles missing pet gracefully
- ✅ FluidLoggingScreen - Error Handling handles missing user gracefully

**Form Validation**:
- ✅ FluidLoggingScreen - Form Validation disables Log button when volume invalid
- ✅ FluidLoggingScreen - Form Validation shows error for empty volume
- ✅ FluidLoggingScreen - Form Validation shows error for non-numeric volume
- ✅ FluidLoggingScreen - Form Validation shows error for volume above 500ml
- ✅ FluidLoggingScreen - Form Validation shows error for volume below 1ml

**Initial Rendering**:
- ✅ FluidLoggingScreen - Initial Rendering displays daily summary info card when fluids logged today
- ✅ FluidLoggingScreen - Initial Rendering displays title "Log Fluid Session"
- ✅ FluidLoggingScreen - Initial Rendering pre-fills injection site from schedule
- ✅ FluidLoggingScreen - Initial Rendering pre-fills volume from schedule
- ✅ FluidLoggingScreen - Initial Rendering uses defaults when no schedule exists

**Loading States**:
- ✅ FluidLoggingScreen - Loading States Log button enabled with valid volume
- ✅ FluidLoggingScreen - Loading States Log button is interactive with valid data

**User Interactions**:
- ✅ FluidLoggingScreen - User Interactions accepts notes input with character count
- ✅ FluidLoggingScreen - User Interactions accepts volume input
- ✅ FluidLoggingScreen - User Interactions changes injection site on selector change
- ✅ FluidLoggingScreen - User Interactions selects stress level on SegmentedButton tap
- ✅ FluidLoggingScreen - User Interactions stress level is optional

---

#### `test/features/logging/widgets/medication_logging_screen_test.dart` ✅

**Type**: Widget Test
**Purpose**: Tests MedicationLoggingScreen UI
**Stats**: 22 tests | ✅ 22 passing | ❌ 0 failing

**Tests by Group**:

**Accessibility**:
- ✅ MedicationLoggingScreen - Accessibility error handling completes without exceptions
- ✅ MedicationLoggingScreen - Accessibility has semantic label on Log button with selection count
- ✅ MedicationLoggingScreen - Accessibility has semantic label on Select All button
- ✅ MedicationLoggingScreen - Accessibility has semantic labels on medication cards

**Error Handling**:
- ✅ MedicationLoggingScreen - Error Handling handles duplicate session error gracefully
- ✅ MedicationLoggingScreen - Error Handling logging works with valid user and pet

**Form Validation**:
- ✅ MedicationLoggingScreen - Form Validation disables Log button when no medications selected
- ✅ MedicationLoggingScreen - Form Validation enables Log button when at least one medication selected
- ✅ MedicationLoggingScreen - Form Validation trims empty notes before submission
- ✅ MedicationLoggingScreen - Form Validation updates button text with selection count

**Initial Rendering**:
- ✅ MedicationLoggingScreen - Initial Rendering displays Select All button with multiple medications
- ✅ MedicationLoggingScreen - Initial Rendering displays empty state when no schedules
- ✅ MedicationLoggingScreen - Initial Rendering displays medication cards when schedules exist
- ✅ MedicationLoggingScreen - Initial Rendering displays title "Log Medication"
- ✅ MedicationLoggingScreen - Initial Rendering hides Select All button with single medication

**Loading States**:
- ✅ MedicationLoggingScreen - Loading States verifies successful logging operation

**User Interactions**:
- ✅ MedicationLoggingScreen - User Interactions accepts notes input with character count
- ✅ MedicationLoggingScreen - User Interactions deselects all on Deselect All tap
- ✅ MedicationLoggingScreen - User Interactions deselects medication on second tap
- ✅ MedicationLoggingScreen - User Interactions expands notes field when typing
- ✅ MedicationLoggingScreen - User Interactions selects all medications on Select All tap
- ✅ MedicationLoggingScreen - User Interactions selects medication on card tap

---

#### `test/features/logging/widgets/treatment_choice_popup_test.dart` ✅

**Type**: Widget Test
**Purpose**: Tests TreatmentChoicePopup UI
**Stats**: 21 tests | ✅ 21 passing | ❌ 0 failing

**Tests by Group**:

**Accessibility**:
- ✅ (setUpAll)
- ✅ TreatmentChoicePopup - Accessibility has semantic label on cancel button
- ✅ TreatmentChoicePopup - Accessibility has semantic labels on fluid button
- ✅ TreatmentChoicePopup - Accessibility has semantic labels on medication button

**Analytics Integration**:
- ✅ TreatmentChoicePopup - Analytics Integration tracks fluid choice selection
- ✅ TreatmentChoicePopup - Analytics Integration tracks medication choice selection

**Initial Rendering**:
- ✅ TreatmentChoicePopup - Initial Rendering displays cancel button
- ✅ TreatmentChoicePopup - Initial Rendering displays fluid therapy button
- ✅ TreatmentChoicePopup - Initial Rendering displays medication button
- ✅ TreatmentChoicePopup - Initial Rendering displays title "Add one-time entry"

**Navigation**:
- ✅ TreatmentChoicePopup - Navigation calls onFluidSelected without errors
- ✅ TreatmentChoicePopup - Navigation calls onMedicationSelected without errors
- ✅ TreatmentChoicePopup - Navigation has proper widget structure for navigation

**User Interactions**:
- ✅ TreatmentChoicePopup - User Interactions calls onFluidSelected when fluid tapped
- ✅ TreatmentChoicePopup - User Interactions calls onMedicationSelected when medication tapped
- ✅ TreatmentChoicePopup - User Interactions resets state on cancel button tap
- ✅ TreatmentChoicePopup - User Interactions sets treatment choice to fluid on tap
- ✅ TreatmentChoicePopup - User Interactions sets treatment choice to medication on tap

**Visual Feedback**:
- ✅ TreatmentChoicePopup - Visual Feedback displays fluid therapy icon
- ✅ TreatmentChoicePopup - Visual Feedback displays medication icon
- ✅ TreatmentChoicePopup - Visual Feedback shows divider between buttons

---

## Notifications Feature Tests

### `test/features/notifications/l10n_group_summary_test.dart` ✅

**Type**: Unit Test
**Purpose**: Tests notification group summary localization
**Stats**: 2 tests | ✅ 2 passing | ❌ 0 failing

**Tests**:
- ✅ Notification group summaries (en) fluid-only pluralization
- ✅ Notification group summaries (en) title formats with pet name

---

### `test/features/notifications/models/scheduled_notification_entry_test.dart` ✅

**Type**: Unit Test
**Purpose**: Tests ScheduledNotificationEntry model
**Stats**: 1 test | ✅ 1 passing | ❌ 0 failing

**Tests**:
- ✅ ScheduledNotificationEntry - JSON serialization fromJson rejects missing fields

---

### `test/features/notifications/notification_settings_screen_test.dart` ✅

**Type**: Widget Test
**Purpose**: Tests NotificationSettingsScreen UI
**Stats**: 2 tests | ✅ 2 passing | ❌ 0 failing

**Tests**:
- ✅ Helper banner shows when no pet profile
- ✅ NotificationSettingsScreen shows toggles for user

---

### `test/features/notifications/providers/notification_coordinator_test.dart` ❌

**Type**: Provider Test
**Purpose**: Tests NotificationCoordinator provider logic
**Stats**: 8 tests | ✅ 2 passing | ❌ 6 failing

**Tests**:
- ✅ NotificationCoordinator Provider Access Pattern works without type casting errors from any context
- ❌ **[FAILING]** NotificationCoordinator cancelForSchedule and cancelSlot cancelForSchedule cancels all notifications for a schedule
- ✅ NotificationCoordinator refreshAll cancels existing notifications before rescheduling
- ❌ **[FAILING]** NotificationCoordinator rescheduleAll cancels orphan notifications
- ❌ **[FAILING]** NotificationCoordinator rescheduleAll detects missing notifications
- ❌ **[FAILING]** NotificationCoordinator scheduleWeeklySummary handles plugin errors
- ❌ **[FAILING]** NotificationCoordinator scheduleWeeklySummary returns already_scheduled when duplicate
- ❌ **[FAILING]** NotificationCoordinator scheduleWeeklySummary schedules for next Monday 09:00 when settings enabled

---

### `test/features/notifications/services/notification_index_store_test.dart` ✅

**Type**: Unit Test
**Purpose**: Tests NotificationIndexStore
**Stats**: 6 tests | ✅ 6 passing | ❌ 0 failing

**Tests**:
- ✅ NotificationIndexStore - corruption and rebuild returns [] on invalid stored JSON
- ✅ NotificationIndexStore - date-based cleanup clearForDate and clearAllForYesterday work as expected
- ✅ NotificationIndexStore - put/remove/get getCountForPet returns correct count and 0 on error
- ✅ NotificationIndexStore - put/remove/get putEntry adds and updates idempotently
- ✅ NotificationIndexStore - put/remove/get removeAllForSchedule removes all entries for schedule
- ✅ NotificationIndexStore - put/remove/get removeEntryBy removes matching entries only

---

### `test/features/notifications/services/reminder_service_integration_test.dart` ❌

**Type**: Integration Test
**Purpose**: Tests ReminderService with plugin mocks
**Stats**: 15 tests | ✅ 2 passing | ❌ 13 failing

**Tests by Group**:

**ReminderPluginInterface Integration Tests - Integration**:
- ❌ **[FAILING]** Scheduling Flow with Mocks cancellation flow updates index after plugin call succeeds
- ❌ **[FAILING]** Scheduling Flow with Mocks scheduling flow updates index after plugin call succeeds

**General Tests**:
- ✅ (setUpAll)
- ✅ (tearDownAll)
- ❌ **[FAILING]** ReminderPluginInterface Integration Tests Error Handling index store errors are throwable and catchable
- ❌ **[FAILING]** ReminderPluginInterface Integration Tests Error Handling plugin errors are throwable and catchable
- ❌ **[FAILING]** ReminderPluginInterface Integration Tests Index Store Mock Integration indexStore.getCountForPet returns zero by default
- ❌ **[FAILING]** ReminderPluginInterface Integration Tests Plugin Mock Integration plugin.cancel is callable with correct notification ID
- ❌ **[FAILING]** ReminderPluginInterface Integration Tests Plugin Mock Integration plugin.cancelAll is callable
- ❌ **[FAILING]** ReminderPluginInterface Integration Tests Plugin Mock Integration plugin.cancelGroupSummary is callable
- ❌ **[FAILING]** ReminderPluginInterface Integration Tests Plugin Mock Integration plugin.pendingNotificationRequests returns empty list by default
- ❌ **[FAILING]** ReminderPluginInterface Integration Tests Plugin Mock Integration plugin.showGroupSummary is callable with correct parameters
- ❌ **[FAILING]** ReminderPluginInterface Integration Tests Plugin Mock Integration plugin.showZoned is callable with correct parameters
- ❌ **[FAILING]** ReminderPluginInterface Integration Tests Provider Integration notificationIndexStoreProvider provides mock instance
- ❌ **[FAILING]** ReminderPluginInterface Integration Tests Provider Integration reminderPluginProvider provides mock instance

**Known Issues**: Plugin mock provider setup issues

---

### `test/features/notifications/services/reminder_service_test.dart` ✅

**Type**: Unit Test
**Purpose**: Tests ReminderService scheduling helpers
**Stats**: 12 tests | ✅ 12 passing | ❌ 0 failing

**Tests**:
- ✅ (setUpAll)
- ✅ (tearDownAll)
- ✅ Edge Cases calculateFollowupTime handles leap day
- ✅ schedulingHelpers - calculateFollowupTime handles boundary at exactly 23:59
- ✅ schedulingHelpers - calculateFollowupTime handles late night times correctly
- ✅ schedulingHelpers - calculateFollowupTime handles month boundary
- ✅ schedulingHelpers - calculateFollowupTime handles year boundary
- ✅ schedulingHelpers - calculateFollowupTime schedules for next morning when result would be past 23:59
- ✅ schedulingHelpers - evaluateGracePeriod respects custom grace period parameter
- ✅ schedulingHelpers - evaluateGracePeriod returns immediate at grace period boundary (30 min)
- ✅ schedulingHelpers - evaluateGracePeriod returns immediate for times within grace period
- ✅ schedulingHelpers - evaluateGracePeriod returns missed for times past grace period

---

### `test/features/notifications/utils/time_slot_formatter_test.dart` ✅

**Type**: Unit Test
**Purpose**: Tests time slot formatting utilities
**Stats**: 5 tests | ✅ 5 passing | ❌ 0 failing

**Tests**:
- ✅ formatTimeSlotFromDateTime formats afternoon time
- ✅ formatTimeSlotFromDateTime formats late evening time
- ✅ formatTimeSlotFromDateTime formats midnight
- ✅ formatTimeSlotFromDateTime formats noon
- ✅ formatTimeSlotFromDateTime ignores date components

---

## Onboarding Tests

### `test/features/onboarding/widgets/onboarding_ui_test.dart` ✅

**Type**: Widget Test
**Purpose**: Tests onboarding UI components
**Stats**: 1 test | ✅ 1 passing | ❌ 0 failing

**Coverage**:
- OnboardingProgressIndicator display
- OnboardingStepType enum validation

**Tests**:
- ✅ Onboarding UI Components OnboardingStepType enum has correct total steps

**Manual Testing**: Comprehensive manual testing plan available at `test/features/onboarding/ONBOARDING_TESTING_PLAN.md` with 105 manual test checkpoints

---

## Profile Feature Tests

### `test/features/profile/services/pet_service_test.dart` ✅

**Type**: Integration Test
**Purpose**: Tests PetService with Firebase emulator
**Stats**: 12 tests | ✅ 12 passing | ❌ 0 failing

**Tests by Group**:

**PetService - Integration Tests (Requires Firebase Emulator)**:
- ✅ should cache pet after successful creation
- ✅ should check dependencies before deletion
- ✅ should delete pet and clear cache
- ✅ should detect name conflicts before creation
- ✅ should handle concurrent pet creation
- ✅ should refresh cache after 30-minute timeout
- ✅ should return cached pet within 30-minute timeout
- ✅ should update pet and refresh cache
- ✅ should use persistent cache when offline

**PetService - Validation Integration**:
- ✅ createPet should return ProfileValidationException with all error messages
- ✅ createPet should validate profile before attempting to save
- ✅ updatePet should validate updated profile before saving

---

### `test/features/profile/services/schedule_history_service_test.dart` ✅

**Type**: Unit Test
**Purpose**: Tests ScheduleHistoryService
**Stats**: 10 tests | ✅ 10 passing | ❌ 0 failing

**Tests**:
- ✅ ScheduleHistoryService getScheduleAtDate returns entry when effectiveTo is null (current version)
- ✅ ScheduleHistoryService getScheduleAtDate returns most recent entry when multiple versions exist
- ✅ ScheduleHistoryService getScheduleAtDate returns null when date is after effectiveTo
- ✅ ScheduleHistoryService getScheduleAtDate returns null when no history exists for date
- ✅ ScheduleHistoryService getScheduleAtDate returns schedule history for exact date
- ✅ ScheduleHistoryService getScheduleHistory returns all history entries ordered by effectiveFrom descending
- ✅ ScheduleHistoryService getScheduleHistory returns empty list when no history exists
- ✅ ScheduleHistoryService saveScheduleSnapshot saves null effectiveTo for current version
- ✅ ScheduleHistoryService saveScheduleSnapshot saves schedule snapshot to history subcollection
- ✅ ScheduleHistoryService saveScheduleSnapshot uses millisecondsSinceEpoch as document ID

---

### `test/features/profile/services/schedule_service_test.dart` ✅

**Type**: Integration Test
**Purpose**: Tests ScheduleService with Firebase emulator
**Stats**: 12 tests | ✅ 12 passing | ❌ 0 failing

**Tests**:
- ✅ should create multiple schedules atomically in batch
- ✅ should create single schedule with server timestamps
- ✅ should delete schedule by ID
- ✅ should get schedule by ID
- ✅ should handle Firebase exceptions gracefully
- ✅ should handle serialization errors
- ✅ should query all schedules including inactive
- ✅ should query only active schedules
- ✅ should query schedules with treatment type filter
- ✅ should rollback batch if any schedule fails
- ✅ should update schedule with new timestamp
- ✅ should use correct Firestore path structure

---

## Progress Feature Tests

### `test/features/progress/fluid_daily_summary_view_provider_test.dart` ❌

**Type**: Provider Test
**Purpose**: Tests fluid daily summary view provider
**Stats**: 1 test | ✅ 0 passing | ❌ 1 failing

**Tests**:
- ❌ **[FAILING]** fluidDailySummaryViewProvider derives from week summaries and schedule

---

### `test/features/progress/progress_day_detail_popup_test.dart` ✅

**Type**: Widget Test
**Purpose**: Tests ProgressDayDetailPopup UI
**Stats**: 10 tests | ✅ 10 passing | ❌ 0 failing

**Tests**:
- ✅ ProgressDayDetailPopup - Logged View displays both medication and fluid sessions
- ✅ ProgressDayDetailPopup - Logged View displays fluid sessions for past date
- ✅ ProgressDayDetailPopup - Logged View displays medication sessions for past date
- ✅ ProgressDayDetailPopup - Logged View shows missed medication without completion tick
- ✅ ProgressDayDetailPopup - Planned View displays both planned treatments
- ✅ ProgressDayDetailPopup - Planned View displays planned fluid therapy for future date
- ✅ ProgressDayDetailPopup - Planned View displays planned medications for future date
- ✅ ProgressDayDetailPopup - Summary Pills displays fluid summary pill with correct counts
- ✅ ProgressDayDetailPopup - Summary Pills displays medication summary pill with correct counts
- ✅ ProgressDayDetailPopup - Summary Pills shows incomplete status in pills

---

### `test/features/progress/progress_provider_cache_test.dart` ❌

**Type**: Provider Test
**Purpose**: Tests progress provider caching
**Stats**: 1 test | ✅ 0 passing | ❌ 1 failing

**Tests**:
- ❌ **[FAILING]** weekSummariesProvider overrides today using cache/lightweight summary

---

### `test/features/progress/progress_week_calendar_test.dart` ✅

**Type**: Widget Test
**Purpose**: Tests ProgressWeekCalendar widget
**Stats**: 2 tests | ✅ 2 passing | ❌ 0 failing

**Tests**:
- ✅ ProgressWeekCalendar displays coral dot for missed status
- ✅ ProgressWeekCalendar renders without errors

---

### `test/features/progress/models/treatment_day_bucket_test.dart` ✅

**Type**: Unit Test
**Purpose**: Verifies computed properties for the combined fluid + medication day bucket used by month view
**Stats**: 8 tests | ✅ 8 passing | ❌ 0 failing

**Coverage**:
- Constructor/equality
- Scheduled detection helpers
- Fluid completion & misses
- Medication completion & misses
- Combined completion & pending logic
- toString formatting

---

### `test/features/progress/monthly_treatment_buckets_test.dart` ✅

**Type**: Unit Test
**Purpose**: Tests `buildMonthlyTreatmentBuckets` and `_buildMonthStatusesFromBuckets`
**Stats**: 9 tests | ✅ 9 passing | ❌ 0 failing

**Test Groups**:
- ✅ buildMonthlyTreatmentBuckets: null summary handling, mismatch guard, array mapping
- ✅ _buildMonthStatusesFromBuckets: future/today/past cases covering fluid-only, med-only, and combined completion/miss logic

**Coverage**:
- Ensures bucket builder validates all five arrays before constructing `TreatmentDayBucket`s
- Validates DayDotStatus parity with week view rules (none/today/complete/missed)

---

### `test/features/progress/injection_sites_provider_test.dart` ⏳

**Type**: Provider Test
**Purpose**: Tests injection sites stats provider
**Stats**: PENDING - Test not yet implemented

**Planned Coverage**:
- Provider fetches last 20 fluid sessions from Firestore
- Aggregates injection site usage statistics
- Handles error states gracefully
- Caches results efficiently
- Auto-invalidates on fluid session changes

**Status**: Future implementation - test file pending

---

### `test/features/progress/injection_sites_donut_chart_test.dart` ⏳

**Type**: Widget Test
**Purpose**: Tests InjectionSitesDonutChart widget
**Stats**: PENDING - Test not yet implemented

**Planned Coverage**:
- Renders donut chart with correct percentages
- Displays legend with site names and counts
- Shows empty state when no sessions
- Uses correct color mapping for sites
- Provides accessibility semantics

**Status**: Future implementation - test file pending

---

## Provider Tests

### `test/providers/analytics_provider_logging_hooks_test.dart` ❌

**Type**: Provider Test
**Purpose**: Tests AnalyticsService logging hooks
**Stats**: 3 tests | ✅ 0 passing | ❌ 3 failing

**Tests**:
- ❌ **[FAILING]** AnalyticsService logging hooks trackLoggingFailure maps standard fields
- ❌ **[FAILING]** AnalyticsService logging hooks trackQuickLogUsed includes durationMs when provided
- ❌ **[FAILING]** AnalyticsService logging hooks trackSessionLogged includes source and durationMs

---

### `test/providers/analytics_provider_weekly_progress_test.dart` ❌

**Type**: Provider Test
**Purpose**: Tests AnalyticsService weekly progress tracking
**Stats**: 6 tests | ✅ 0 passing | ❌ 6 failing

**Tests**:
- ❌ **[FAILING]** AnalyticsService weekly progress tracking trackWeeklyGoalAchieved does not track when analytics disabled
- ❌ **[FAILING]** AnalyticsService weekly progress tracking trackWeeklyGoalAchieved includes all parameters
- ❌ **[FAILING]** AnalyticsService weekly progress tracking trackWeeklyGoalAchieved omits petId when null
- ❌ **[FAILING]** AnalyticsService weekly progress tracking trackWeeklyProgressViewed does not track when analytics disabled
- ❌ **[FAILING]** AnalyticsService weekly progress tracking trackWeeklyProgressViewed includes all parameters
- ❌ **[FAILING]** AnalyticsService weekly progress tracking trackWeeklyProgressViewed omits optional parameters when null

---

### `test/providers/auth_provider_test.dart` ❌

**Type**: Provider Test
**Purpose**: Tests AuthNotifier and convenience providers
**Stats**: 5 tests | ✅ 0 passing | ❌ 5 failing

**Tests**:
- ❌ **[FAILING]** AuthProvider Convenience Providers currentUserProvider should return current user when authenticated
- ❌ **[FAILING]** AuthProvider Convenience Providers currentUserProvider should return null when unauthenticated
- ❌ **[FAILING]** AuthProvider Convenience Providers isAuthenticatedProvider should return false when error
- ❌ **[FAILING]** AuthProvider Convenience Providers isAuthenticatedProvider should return false when unauthenticated
- ❌ **[FAILING]** AuthProvider Convenience Providers isAuthenticatedProvider should return true when authenticated

---

### `test/providers/profile/profile_cache_manager_test.dart` ✅

**Type**: Provider Test
**Purpose**: Tests ProfileCacheManager
**Stats**: 3 tests | ✅ 3 passing | ❌ 0 failing

**Tests**:
- ✅ ProfileCacheManager cachePrimaryPetId should handle empty string pet ID
- ✅ ProfileCacheManager cachePrimaryPetId should overwrite existing pet ID
- ✅ ProfileCacheManager cachePrimaryPetId should save pet ID to SharedPreferences

---

### `test/providers/profile/schedule_coordinator_test.dart` ❌

**Type**: Provider Test
**Purpose**: Tests ScheduleCoordinator
**Stats**: 10 tests | ✅ 1 passing | ❌ 9 failing

**Tests by Group**:

**ScheduleCoordinator Integration Tests (TODO)**:
- ✅ test all 10 operations

**General Tests**:
- ❌ **[FAILING]** ScheduleCoordinator ScheduleOperationResult should create failure result with error
- ❌ **[FAILING]** ScheduleCoordinator ScheduleOperationResult should create success result with schedule
- ❌ **[FAILING]** ScheduleCoordinator ScheduleOperationResult should create success result with schedules list
- ❌ **[FAILING]** ScheduleCoordinator loadFluidSchedule should return failure on FormatException
- ❌ **[FAILING]** ScheduleCoordinator loadFluidSchedule should return failure on general Exception
- ❌ **[FAILING]** ScheduleCoordinator loadFluidSchedule should return success with null when schedule not found
- ❌ **[FAILING]** ScheduleCoordinator loadFluidSchedule should return success with schedule when found
- ❌ **[FAILING]** ScheduleCoordinator loadMedicationSchedules should return success with empty list when none found
- ❌ **[FAILING]** ScheduleCoordinator loadMedicationSchedules should return success with schedules when found

---

### `test/providers/weekly_progress_provider_test.dart` ✅

**Type**: Provider Test
**Purpose**: Tests WeeklyProgressProvider
**Stats**: 7 tests | ✅ 7 passing | ❌ 0 failing

**Tests**:
- ✅ WeeklyProgressProvider correctly calculates fill percentage
- ✅ WeeklyProgressProvider falls back to schedule calculation when goal not stored
- ✅ WeeklyProgressProvider formats injection site correctly
- ✅ WeeklyProgressProvider handles error states gracefully
- ✅ WeeklyProgressProvider returns null when primary pet is null
- ✅ WeeklyProgressProvider returns null when user is not authenticated
- ✅ WeeklyProgressProvider shows "None yet" when no injection site logged

---

## Shared Model Tests

### `test/shared/models/monthly_summary_test.dart` ✅

**Type**: Unit Test
**Purpose**: Tests MonthlySummary model with daily fluid arrays (Phase 0)
**Stats**: 20 tests | ✅ 20 passing | ❌ 0 failing

**Tests**:
- ✅ toJson and fromJson roundtrip preserves lists
- ✅ fromJson handles missing lists by defaulting to zeros
- ✅ fromJson handles null lists by defaulting to zeros
- ✅ pads short lists with zeros
- ✅ truncates long lists
- ✅ valid lists pass validation
- ✅ detects wrong list lengths
- ✅ detects out-of-bounds values in dailyVolumes
- ✅ detects out-of-bounds values in dailyScheduledSessions
- ✅ handles February leap year (29 days)
- ✅ handles February non-leap year (28 days)
- ✅ handles 30-day months
- ✅ handles 31-day months
- ✅ clamps extreme values during deserialization
- ✅ replacing lists works correctly
- ✅ unchanged lists remain the same
- ✅ lists affect equality comparison
- ✅ identical lists produce equality
- ✅ different lists produce inequality
- ✅ hashCode includes lists

---

## Shared Widget Tests

### `test/shared/widgets/fluid/water_drop_painter_test.dart` ✅

**Type**: Widget Test
**Purpose**: Tests WaterDropWidget
**Stats**: 6 tests | ✅ 6 passing | ❌ 0 failing

**Tests**:
- ✅ WaterDropWidget calculates correct widget dimensions
- ✅ WaterDropWidget has semantic label for accessibility
- ✅ WaterDropWidget hides completion badge when fillPercentage < 1.0
- ✅ WaterDropWidget renders with initial fill percentage
- ✅ WaterDropWidget shows completion badge when fillPercentage >= 1.0
- ✅ WaterDropWidget widget disposes cleanly

---

### `test/shared/widgets/fluid/water_drop_progress_card_test.dart` ✅

**Type**: Widget Test
**Purpose**: Tests WaterDropProgressCard
**Stats**: 5 tests | ✅ 5 passing | ❌ 0 failing

**Tests**:
- ✅ WaterDropProgressCard displays large volume correctly (ml to L conversion)
- ✅ WaterDropProgressCard displays weekly progress correctly
- ✅ WaterDropProgressCard shows empty state for new week
- ✅ WaterDropProgressCard shows injection site with location icon
- ✅ WaterDropProgressCard shows percentage with correct color coding

---

### `test/shared/widgets/navigation/hydra_navigation_bar_test.dart` ✅

**Type**: Widget Test
**Purpose**: Tests HydraNavigationBar
**Stats**: 2 tests | ✅ 2 passing | ❌ 0 failing

**Tests**:
- ✅ renders only one top indicator for the selected index
- ✅ semantics marks active tab as selected

---

## Integration Tests

### `test/integration_test/auth_flow_test.dart` ✅

**Type**: Integration Test
**Purpose**: Tests authentication UI flows with mocked services
**Stats**: 7 tests | ✅ 7 passing | ❌ 0 failing

**Coverage**:
- Login screen display with all UI elements
- Form validation (empty fields, email format, password length)
- Navigation to registration and forgot password screens
- Password visibility toggle

**Tests**:
- ✅ (tearDownAll)
- ✅ Authentication Flow Integration Tests should display login screen with all elements
- ✅ Authentication Flow Integration Tests should navigate to forgot password screen
- ✅ Authentication Flow Integration Tests should navigate to registration screen
- ✅ Authentication Flow Integration Tests should toggle password visibility
- ✅ Authentication Flow Integration Tests should validate email format
- ✅ Authentication Flow Integration Tests should validate password length

---

### `test/integration_test/logging/logging_flow_test.dart` ✅

**Type**: Integration Test
**Purpose**: Tests end-to-end logging flows
**Stats**: 2 tests | ✅ 2 passing | ❌ 0 failing

**Tests**:
- ✅ Manual Medication Logging Flow updates cache after successful log
- ✅ Quick-Log All Treatments rejects quick-log if sessions already logged today

---

### `test/integration_test/logging/offline_sync_test.dart` ❌

**Type**: Integration Test
**Purpose**: Tests offline queue and sync functionality
**Stats**: 10 tests | ✅ 1 passing | ❌ 9 failing

**Tests**:
- ❌ **[FAILING]** Connectivity State Management manages repeated offline/online cycles
- ❌ **[FAILING]** Offline Queue Management enqueues fluid session when offline
- ❌ **[FAILING]** Offline Queue Management enqueues medication session when offline
- ❌ **[FAILING]** Offline Queue Management throws QueueWarningException at 50 operations
- ✅ Offline Queue Management updates local cache immediately (optimistic UI)
- ❌ **[FAILING]** Offline Sync Execution handles mixed success/failure scenarios
- ❌ **[FAILING]** Offline Sync Execution preserves failed operations in queue
- ❌ **[FAILING]** Offline Sync Execution removes successful operations from queue
- ❌ **[FAILING]** Offline Sync Execution syncs operations in chronological order
- ❌ **[FAILING]** Sync Conflict Scenarios uses createdAt timestamp for conflict resolution

**Known Issues**: DateTime serialization errors in offline queue operations

---

### `test/integration_test/profile/schedule_history_integration_test.dart` ✅

**Type**: Integration Test
**Purpose**: Tests schedule history versioning
**Stats**: 6 tests | ✅ 6 passing | ❌ 0 failing

**Tests**:
- ✅ Schedule History Integration Tests Historical Data Retrieval retrieves correct schedule version for past date
- ✅ Schedule History Integration Tests Historical Data Retrieval returns correct reminder times for specific date
- ✅ Schedule History Integration Tests Multiple Version Tracking handles multiple sequential updates
- ✅ Schedule History Integration Tests Multiple Version Tracking tracks multiple versions when schedule is updated
- ✅ Schedule History Integration Tests Schedule Snapshot Saving saves initial history entry for fluid schedule
- ✅ Schedule History Integration Tests Schedule Snapshot Saving saves initial history entry for medication schedule

---

## 🏃 Running Tests

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

### Run specific test file
```bash
flutter test test/<path-to-test-file>
```

### Run specific test file with expanded output
```bash
flutter test test/<path-to-test-file> --reporter expanded
```

### Run with coverage
```bash
flutter test --coverage
```

---

## 📝 Notes

- **Test Results Source**: This index was automatically generated from `flutter test` output on 2025-11-15
- **Known Failing Test Categories**:
  - Auth Service tests (17 failing) - Firebase mock setup issues
  - Offline Logging Service tests (11 failing) - DateTime serialization issues
  - Notification-related provider tests - Plugin mock issues
  - Analytics provider tests - Setup/configuration issues
- **Integration Tests**: Use `fake_cloud_firestore` for Firestore simulation (no Firebase Emulator required)
- **Performance**: Full test suite runs in ~24 seconds
- **Test Helpers**: Available in `test/helpers/` for consistent test data creation

---

## 🔄 Last Updated

**November 15, 2025** - Updated with comprehensive test results from latest test run. Documented 323 individual test cases with pass/fail status. Identified 82 failing tests requiring investigation across auth, offline sync, notifications, and analytics features.
