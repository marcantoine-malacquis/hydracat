# Hydracat Analytics Implementation Reference

**Last Updated:** 2025-11-19
**Status:**  Verified and Documented

---

## Table of Contents

1. [Overview](#overview)
2. [Analytics Architecture](#analytics-architecture)
3. [Event Categories](#event-categories)
4. [Complete Event Reference](#complete-event-reference)
5. [User Properties](#user-properties)
6. [Implementation Quality Assessment](#implementation-quality-assessment)
7. [Usage Patterns](#usage-patterns)

---

## Overview

This document provides a comprehensive reference for all Google Analytics (Firebase Analytics) tracking implemented in the Hydracat Flutter application. All analytics are centrally managed through a single service located at `lib/providers/analytics_provider.dart`.

### Key Metrics

- **Total Event Types:** 53
- **Total User Properties:** 2
- **Total Parameters:** 30+
- **Files with Analytics Calls:** 13
- **Implementation Status:**  Production-ready

---

## Analytics Architecture

### Service Structure

**Location:** `lib/providers/analytics_provider.dart`

#### Core Components

1. **AnalyticsService** - Main service class wrapping Firebase Analytics
   - Manages tracking enable/disable toggle
   - Provides user ID and property management
   - All methods check `_isEnabled` before tracking
   - Non-blocking: Uses `async/await` without waiting for completion

2. **AnalyticsNotifier** - State management with auth integration
   - Listens to auth state changes
   - Auto-sets user properties (user ID, user type, auth provider)
   - Auto-enables in production, disables in debug mode
   - Tracks login/logout events automatically

3. **Provider Access Points:**
   ```dart
   firebaseAnalyticsProvider      // Firebase Analytics instance
   analyticsServiceProvider        // Service wrapper
   analyticsProvider              // StateNotifier for auth integration
   analyticsServiceDirectProvider // Direct service access (most common)
   ```

### Configuration

- **Development:** Disabled by default (`!kDebugMode`)
- **Production:** Enabled by default
- **Firebase Projects:**
  - Development flavor: `hydracattest`
  - Production flavor: `myckdapp`
- **Runtime Control:** Can be toggled via `setEnabled()`

---

## Event Categories

### 1. Authentication & User Lifecycle (8 events)

Events related to user authentication, account management, and session lifecycle.

### 2. Onboarding & User Journey (4 events)

Events tracking new user onboarding flow and completion.

### 3. Treatment Logging (13 events)

Events tracking medication and fluid treatment logging operations.

### 4. Notifications & Reminders (21 events)

Events tracking notification permissions, scheduling, and user interactions.

### 5. Weekly Progress Tracking (2 events)

Events for weekly fluid therapy goal tracking and achievements.

### 6. Caching & Performance (5 events)

Events monitoring cache performance and optimization.

---

## Complete Event Reference

### 1. Authentication & User Lifecycle

#### `login`
**Trigger:** User successfully logs into the app
**Auto-tracked:** Yes (by AnalyticsNotifier on auth state change)
**Parameters:**
- `method` (string): Authentication method - `'email'`, `'google'`, `'apple'`
- `success` (bool): Whether login succeeded

**Implementation:** `analytics_provider.dart:1614-1617`

---

#### `sign_up`
**Trigger:** New user completes registration
**Auto-tracked:** No (manual)
**Parameters:**
- `method` (string): Registration method - `'email'`, `'google'`, `'apple'`
- `success` (bool): Whether signup succeeded

**Implementation:** `analytics_provider.dart:493-506`

---

#### `email_verification_sent`
**Trigger:** Verification email sent to new user
**Parameters:** None
**Implementation:** `analytics_provider.dart:509-515`

---

#### `email_verified`
**Trigger:** User completes email verification
**Parameters:** None
**Implementation:** `analytics_provider.dart:518-524`

---

#### `password_reset`
**Trigger:** User initiates password reset flow
**Parameters:** None
**Implementation:** `analytics_provider.dart:527-533`

---

#### `social_sign_in`
**Trigger:** User signs in with social provider
**Parameters:**
- `provider` (string): Social provider - `'google'`, `'apple'`
- `success` (bool): Whether signin succeeded

**Implementation:** `analytics_provider.dart:536-549`

---

#### `sign_out`
**Trigger:** User signs out of the app
**Auto-tracked:** Yes (by AnalyticsNotifier on auth state change)
**Parameters:** None
**Implementation:** `analytics_provider.dart:1619-1623`

---

#### `app_error`
**Trigger:** Generic application error (non-sensitive only)
**Parameters:**
- `error_type` (string): Error classification (see AnalyticsErrorTypes)
- `context` (string): Error context/location

**Implementation:** `analytics_provider.dart:597-610`
**Usage:** `logging_provider.dart:169`, `logging_provider.dart:610`

---

### 2. Onboarding & User Journey

#### `onboarding_started`
**Trigger:** User taps "Get Started" on welcome screen
**Parameters:**
- `user_id` (string): User identifier
- `timestamp` (string): ISO-8601 timestamp

**Implementation:** `analytics_provider.dart:648-662`
**Usage:** `welcome_screen.dart:139-146`

---

#### `onboarding_step_completed`
**Trigger:** User completes an onboarding step
**Parameters:**
- `user_id` (string): User identifier
- `step` (string): Completed step name
- `next_step` (string): Next step name
- `progress_percentage` (double): Completion progress (0.0 to 1.0)

**Implementation:** `analytics_provider.dart:664-682`
**Note:** Currently defined but not actively tracked in codebase

---

#### `onboarding_completed`
**Trigger:** User completes entire onboarding flow
**Parameters:**
- `user_id` (string): User identifier
- `pet_id` (string): Created pet identifier
- `duration_seconds` (int): Time to complete (optional)
- `completion_rate` (double): Completion rate (default 1.0)

**Implementation:** `analytics_provider.dart:684-702`
**Note:** Currently defined but not actively tracked in codebase

---

#### `onboarding_abandoned`
**Trigger:** User taps "Skip" on welcome screen
**Parameters:**
- `user_id` (string): User identifier
- `last_step` (string): Last step viewed
- `progress_percentage` (double): How far they got (0.0 to 1.0)
- `time_spent_seconds` (int): Time spent (optional)

**Implementation:** `analytics_provider.dart:742-760`
**Usage:** `welcome_screen.dart:222-231`

---

### 3. Treatment Logging

#### `session_logged`
**Trigger:** User successfully logs a medication or fluid treatment
**Parameters:**
- `treatment_type` (string): `'medication'` or `'fluid'`
- `session_count` (int): Total sessions logged for this pet
- `is_quick_log` (bool): Whether logged via quick-log feature
- `adherence_status` (string): `'complete'` or `'partial'`
- `medication_name` (string): Medication name (optional)
- `volume_given` (double): Volume in ml (optional)
- `source` (string): `'manual'`, `'quick_log'`, or `'update'`
- `duration_ms` (int): Operation duration (optional)

**Implementation:** `analytics_provider.dart:762-788`
**Usage:**
- `logging_provider.dart:1339-1349` (medication)
- `logging_provider.dart:1599-1610` (fluid)

---

#### `quick_log_used`
**Trigger:** User completes a quick-log session (multi-treatment shortcut)
**Parameters:**
- `session_count` (int): Total sessions in quick-log
- `medication_count` (int): Medication sessions logged
- `fluid_count` (int): Fluid sessions logged
- `duration_ms` (int): Total operation time (optional)

**Implementation:** `analytics_provider.dart:790-808`
**Usage:** `logging_provider.dart:1041-1046`

---

#### `session_updated`
**Trigger:** User edits a previously logged treatment
**Parameters:**
- `treatment_type` (string): `'medication'` or `'fluid'`
- `update_reason` (string): Reason for update
- `source` (string): Where update was initiated
- `duration_ms` (int): Operation duration (optional)

**Implementation:** `analytics_provider.dart:810-828`
**Note:** Future-ready, not currently used

---

#### `logging_popup_opened`
**Trigger:** User opens a treatment logging popup
**Parameters:**
- `popup_type` (string): `'medication'`, `'fluid'`, or `'choice'`

**Implementation:** `analytics_provider.dart:830-842`
**Usage:** `treatment_confirmation_popup.dart:56`

---

#### `treatment_choice_selected`
**Trigger:** User selects treatment type from choice popup
**Parameters:**
- `choice` (string): Selected treatment type

**Implementation:** `analytics_provider.dart:844-856`
**Note:** Currently defined but not actively tracked

---

#### `offline_logging_queued`
**Trigger:** Treatment session queued for later sync (offline mode)
**Parameters:**
- `queue_size` (int): Current offline queue size

**Implementation:** Event name defined but tracking method not implemented
**Note:** Offline mode not yet implemented

---

#### `sync_completed`
**Trigger:** Offline queue sync completed
**Parameters:**
- `queue_size` (int): Original queue size
- `success_count` (int): Successfully synced
- `failure_count` (int): Failed to sync
- `sync_duration_ms` (int): Sync duration

**Implementation:** `analytics_provider.dart:1162-1180`
**Note:** Offline mode not yet implemented

---

#### `session_log_failed`
**Trigger:** Treatment logging operation failed
**Parameters:**
- `error_type` (string): Error classification
- `treatment_type` (string): `'medication'` or `'fluid'`
- `source` (string): Operation source
- `error_code` (string): Backend error code (optional)
- `exception` (string): Exception type (optional)

**Implementation:** Via `trackLoggingFailure()` `analytics_provider.dart:612-638`
**Usage:**
- `logging_service.dart:238-245` (batch write failure)
- `logging_service.dart:257-262` (unexpected error)

---

#### `session_update_failed`
**Trigger:** Treatment update operation failed
**Parameters:** Same as `session_log_failed`

**Implementation:** Via `trackLoggingFailure()`
**Usage:**
- `logging_service.dart:400-407`
- `logging_service.dart:419-424`
- `logging_service.dart:757-766`
- `logging_service.dart:777-783`

---

#### `quick_log_failed`
**Trigger:** Quick-log operation failed
**Parameters:** Same as `session_log_failed`

**Implementation:** Via `trackLoggingFailure()`
**Note:** Currently defined, not actively used

---

#### `validation_failed`
**Trigger:** Treatment data validation failed
**Parameters:**
- `error_type` (string): Validation error type

**Implementation:** Event name defined, not actively tracked

---

#### `duplicate_prevented`
**Trigger:** Duplicate treatment logging attempt blocked
**Parameters:** Not specified

**Implementation:** Event name defined, not actively tracked
**Note:** See `duplicate_detected` for active tracking

---

#### `duplicate_detected`
**Trigger:** Duplicate treatment session detected (within 5 minutes)
**Parameters:**
- `medication_name` (string): Medication name
- `time_difference_minutes` (int): Minutes since last log

**Implementation:** Via `trackFeatureUsed()` with feature name `'duplicateDetected'`
**Usage:** `logging_provider.dart:1372-1385`

---

### 4. Notifications & Reminders

#### `reminder_tapped`
**Trigger:** User taps a notification to open the app
**Parameters:**
- `treatment_type` (string): `'medication'` or `'fluid'`
- `kind` (string): `'initial'`, `'followup'`, or `'snooze'`
- `schedule_id` (string): Schedule identifier
- `result` (string): Operation outcome

**Result values:**
- `'success'` - Schedule found, logging screen shown
- `'schedule_not_found'` - Schedule deleted since notification sent
- `'user_not_authenticated'` - User logged out
- `'onboarding_not_completed'` - User hasn't finished onboarding
- `'pet_not_loaded'` - Pet profile not loaded
- `'invalid_payload'` - Malformed notification data
- `'invalid_treatment_type'` - Unknown treatment type
- `'processing_error'` - Exception during processing

**Implementation:** `analytics_provider.dart:873-890`
**Usage:**
- `app_shell.dart:630` (success)
- `app_shell.dart:642` (failure)
- `app_shell.dart:754` (processing error)

---

#### `reminder_snoozed`
**Trigger:** User taps "Snooze 15 min" action on notification
**Parameters:**
- `treatment_type` (string): `'medication'` or `'fluid'`
- `kind` (string): Original notification kind (`'initial'` or `'followup'`)
- `schedule_id` (string): Schedule identifier
- `time_slot` (string): Original time in "HH:mm" format
- `result` (string): Snooze outcome

**Result values:**
- `'success'` - Snooze scheduled successfully
- `'invalid_payload'` - Malformed notification data
- `'invalid_kind'` - Attempted to snooze a snooze notification
- `'scheduling_failed'` - Plugin error
- `'unknown_error'` - Unexpected error

**Implementation:** `analytics_provider.dart:911-930`
**Note:** Currently defined but not actively used

---

#### `reminder_canceled_on_log`
**Trigger:** Notifications auto-canceled after user logs treatment
**Parameters:**
- `treatment_type` (string): `'medication'` or `'fluid'`
- `schedule_id` (string): Schedule identifier
- `time_slot` (string): Time slot in "HH:mm" format
- `canceled_count` (int): Number of notifications canceled
- `result` (string): Cancellation outcome

**Result values:**
- `'success'` - At least one notification canceled
- `'none_found'` - No notifications scheduled for this slot
- `'error'` - Exception occurred during cancellation

**Implementation:** `analytics_provider.dart:964-983`
**Usage:**
- `logging_provider.dart:1015-1021` (medication)
- `logging_provider.dart:1832-1838` (fluid)
- `logging_provider.dart:1857-1863` (error case)

---

#### `notification_icon_tapped`
**Trigger:** User taps bell icon in home screen app bar
**Parameters:**
- `permission_status` (string): Current permission state
- `action_taken` (string): What happened next

**Permission status values:**
- `'enabled'` - Permission granted and app setting enabled
- `'denied'` - Permission denied (can request again)
- `'permanentlyDenied'` - Permission permanently denied (Android)
- `'notDetermined'` - Permission not yet requested
- `'setting_disabled'` - Permission granted but app setting disabled

**Action taken values:**
- `'navigated_to_app_settings'` - Went to notification settings
- `'opened_permission_dialog'` - Showed permission request
- `'dismissed'` - User dismissed without action

**Implementation:** `analytics_provider.dart:1001-1014`
**Usage:**
- `notification_status_widget.dart:179`
- `notification_status_widget.dart:197`
- `notification_status_widget.dart:209`

---

#### `notification_permission_requested`
**Trigger:** App requests system notification permission
**Parameters:**
- `previous_status` (string): Permission status before request
- `new_status` (string): Permission status after request
- `granted` (bool): Whether permission was granted

**Implementation:** `analytics_provider.dart:1026-1041`
**Usage:** `permission_preprompt.dart:268`

---

#### `notification_permission_dialog_shown`
**Trigger:** Educational permission pre-prompt displayed
**Parameters:**
- `reason` (string): Why notifications are disabled
- `permission_status` (string): Current platform permission status

**Reason values:**
- `'permission'` - Permission not granted
- `'setting'` - App setting disabled
- `'both'` - Both permission and setting issues

**Implementation:** `analytics_provider.dart:1051-1064`
**Usage:** `permission_preprompt.dart:62`

---

#### `weekly_summary_toggled`
**Trigger:** User enables/disables weekly summary notifications
**Parameters:**
- `enabled` (bool): New state
- `result` (string): `'success'` or `'error'`
- `error_message` (string): Error details if failed (optional)

**Implementation:** `analytics_provider.dart:1076-1091`
**Usage:**
- `notification_settings_screen.dart:620`
- `notification_settings_screen.dart:643`
- `notification_settings_screen.dart:664`

---

#### `notification_privacy_learn_more`
**Trigger:** User taps "Learn More" about notification privacy
**Parameters:**
- `source` (string): `'preprompt'` or `'settings'`

**Implementation:** `analytics_provider.dart:1107-1118`
**Usage:**
- `notification_settings_screen.dart:710`
- `permission_preprompt.dart:229`

---

#### `notification_data_cleared`
**Trigger:** User clears all notification data
**Parameters:**
- `result` (string): `'success'` or `'error'`
- `canceled_count` (int): Number of notifications canceled
- `error_message` (string): Error details if failed (optional)

**Implementation:** `analytics_provider.dart:1145-1160`
**Usage:**
- `notification_settings_screen.dart:794`
- `notification_settings_screen.dart:819`

---

#### `index_corruption_detected`
**Trigger:** Notification index checksum validation failed
**Parameters:**
- `user_id` (string): User identifier
- `pet_id` (string): Pet identifier
- `date` (string): Date of corruption

**Purpose:** Tracks SharedPreferences data corruption

**Implementation:** `analytics_provider.dart:1186-1201`
**Usage:**
- `notification_index_store.dart:236`
- `notification_index_store.dart:264`

---

#### `index_reconciliation_performed`
**Trigger:** Notification index rebuilt from source of truth
**Parameters:**
- `user_id` (string): User identifier
- `pet_id` (string): Pet identifier
- `added_count` (int): Notifications added during reconciliation
- `removed_count` (int): Notifications removed during reconciliation

**Implementation:** `analytics_provider.dart:1203-1221`
**Note:** Currently defined but not actively used

---

#### `notification_limit_reached`
**Trigger:** Notification count reached 50 per pet (platform limit)
**Parameters:**
- `pet_id` (string): Pet identifier
- `current_count` (int): Current notification count (50)
- `schedule_id` (string): Schedule that triggered limit

**Implementation:** `analytics_provider.dart:1223-1239`
**Note:** Currently defined but not actively used

---

#### `notification_limit_warning`
**Trigger:** Notification count reached 80% threshold (40 of 50)
**Parameters:**
- `pet_id` (string): Pet identifier
- `current_count` (int): Current notification count (e40)

**Implementation:** `analytics_provider.dart:1241-1255`
**Note:** Currently defined but not actively used

---

#### Schedule CRUD Notification Events

These four events track notification lifecycle tied to schedule operations:

#### `schedule_created_reminders_scheduled`
**Trigger:** Notifications scheduled after new schedule created
**Parameters:**
- `treatment_type` (string): `'medication'` or `'fluid'`
- `schedule_id` (string): Schedule identifier
- `reminder_count` (int): Number of notifications scheduled
- `result` (string): `'success'` or `'error'`

**Implementation:** `analytics_provider.dart:1257-1275`
**Usage:**
- `schedule_notification_handler.dart:77` (success)
- `schedule_notification_handler.dart:120` (error)

---

#### `schedule_updated_reminders_rescheduled`
**Trigger:** Notifications rescheduled after schedule update
**Parameters:** Same as `schedule_created_reminders_scheduled`

**Implementation:** `analytics_provider.dart:1277-1295`
**Usage:** `schedule_notification_handler.dart:84`

---

#### `schedule_deleted_reminders_canceled`
**Trigger:** Notifications canceled after schedule deletion
**Parameters:**
- `treatment_type` (string): `'medication'` or `'fluid'`
- `schedule_id` (string): Schedule identifier
- `canceled_count` (int): Number of notifications canceled
- `result` (string): `'success'` or `'error'`

**Implementation:** `analytics_provider.dart:1297-1315`
**Usage:**
- `schedule_notification_handler.dart:199`
- `schedule_notification_handler.dart:242`

---

#### `schedule_deactivated_reminders_canceled`
**Trigger:** Notifications canceled after schedule deactivation
**Parameters:** Same as `schedule_deleted_reminders_canceled`

**Implementation:** `analytics_provider.dart:1317-1335`
**Usage:** `schedule_notification_handler.dart` (inferred)

---

#### Notification Error Events

Generic error tracking for notification operations:

#### `notification_plugin_init_failed`
**Trigger:** Notification plugin initialization failed
**Parameters:** (via `trackNotificationError()`)
- `operation` (string): Operation that failed
- `user_id` (string): User identifier
- `pet_id` (string): Pet identifier (optional)
- `schedule_id` (string): Schedule identifier (optional)
- `error_message` (string): Error details (optional)
- `additionalContext` (object): Additional debug data (optional)

**Implementation:** Via `trackNotificationError()` `analytics_provider.dart:1354-1390`

---

#### `notification_permission_revoked`
**Trigger:** Notification permission was revoked
**Parameters:** Same as `notification_plugin_init_failed`

**Implementation:** Via `trackNotificationError()`

---

#### `notification_scheduling_failed`
**Trigger:** Failed to schedule a notification
**Parameters:** Same as `notification_plugin_init_failed`

**Implementation:** Via `trackNotificationError()`

---

#### `notification_cancellation_failed`
**Trigger:** Failed to cancel a notification
**Parameters:** Same as `notification_plugin_init_failed`

**Implementation:** Via `trackNotificationError()`

---

#### `notification_reconciliation_failed`
**Trigger:** Notification reconciliation operation failed
**Parameters:** Same as `notification_plugin_init_failed`

**Implementation:** Via `trackNotificationError()`

---

#### `notification_index_rebuild_success`
**Trigger:** Notification index rebuild succeeded
**Parameters:** Same as `notification_plugin_init_failed`

**Implementation:** Via `trackNotificationError()`

---

#### `notification_index_rebuild_failed`
**Trigger:** Notification index rebuild failed
**Parameters:** Same as `notification_plugin_init_failed`

**Implementation:** Via `trackNotificationError()`

---

### 5. Weekly Progress Tracking

#### `weekly_progress_viewed`
**Trigger:** Weekly progress card displayed on home screen
**Parameters:**
- `weekly_fill_percentage` (double): Progress (0.0 to 2.0, where 1.0 = 100%)
- `weekly_current_volume` (double): Volume given this week (ml)
- `weekly_goal_volume` (int): Weekly goal volume (ml)
- `days_remaining_in_week` (int): Days left in week (0-6)
- `last_injection_site` (string): Last injection site used (optional)
- `pet_id` (string): Pet identifier (optional)

**Note:** Tracked once per card lifecycle using `_hasTrackedView` flag

**Implementation:** `analytics_provider.dart:1469-1497`
**Usage:** `water_drop_progress_card.dart:72`

---

#### `weekly_goal_achieved`
**Trigger:** User completes weekly fluid therapy goal (e100%)
**Parameters:**
- `weekly_current_volume` (double): Final volume when achieved (ml)
- `weekly_goal_volume` (int): Weekly goal volume (ml)
- `days_remaining_in_week` (int): Days left when achieved (0-6)
- `achieved_early` (bool): Whether completed before Sunday
- `pet_id` (string): Pet identifier (optional)

**Note:** Fires once when fill percentage crosses 1.0 threshold

**Implementation:** `analytics_provider.dart:1511-1536`
**Usage:** `water_drop_progress_card.dart:100` (via onGoalAchieved callback)

---

#### `weekly_card_tapped`
**Trigger:** User taps weekly progress card
**Parameters:** Not defined
**Status:** Future enhancement, not implemented

---

### 6. Caching & Performance

#### `schedules_preloaded`
**Trigger:** Treatment schedules preloaded for performance
**Parameters:**
- `pet_id` (string): Pet identifier

**Implementation:** Event name defined but not actively tracked

---

#### `schedules_cache_hit`
**Trigger:** Schedule data served from cache
**Parameters:**
- `pet_id` (string): Pet identifier

**Implementation:** Event name defined but not actively tracked

---

#### `duplicate_check_cache_hit`
**Trigger:** Duplicate detection used cached query result
**Parameters:**
- `medication_name` (string): Medication name
- `had_cache` (bool): Cache status

**Implementation:** Via `trackFeatureUsed()` with feature name `'duplicateCheckCacheHit'`
**Usage:** `logging_provider.dart:391-397`

---

#### `duplicate_check_cache_miss`
**Trigger:** Duplicate detection required Firestore query
**Parameters:**
- `medication_name` (string): Medication name

**Implementation:** Via `trackFeatureUsed()` with feature name `'duplicateCheckCacheMiss'`
**Usage:** `logging_provider.dart:451-457`

---

#### `cache_warmed_on_startup`
**Trigger:** Treatment session cache warmed from Firestore on app start
**Parameters:**
- `medication_session_count` (int): Medication sessions loaded
- `fluid_session_count` (int): Fluid sessions loaded

**Implementation:** Via `trackFeatureUsed()` with feature name `'cacheWarmedOnStartup'`
**Usage:** `logging_provider.dart:586-594`

---

### 7. Generic Events

#### `feature_used`
**Trigger:** Generic feature usage tracking
**Parameters:**
- `feature_name` (string): Feature identifier
- `user_verified` (bool): Whether user is email-verified
- Additional custom parameters (varies by feature)

**Purpose:** Catch-all for features without dedicated events

**Implementation:** `analytics_provider.dart:560-581`
**Usage:** Throughout codebase for weight tracking, cache operations, etc.

---

#### `screen_view`
**Trigger:** Screen navigation (uses Firebase's trackScreenView)
**Parameters:**
- `screen_name` (string): Screen identifier
- `screen_class` (string): Screen class name (optional)

**Implementation:** `analytics_provider.dart:583-594`

**Active Usages:**

##### `injection_sites_analytics`
**When:** User navigates to injection sites analytics screen
**Purpose:** Track usage of injection site rotation insights
**Location:** `lib/features/progress/screens/injection_sites_analytics_screen.dart:29-32`
**Parameters:**
- `screen_name`: `'injection_sites_analytics'`

---

## User Properties

User properties are persistent attributes set at the user level (vs. per-event parameters).

### `user_type`
**Values:** `'anonymous'`, `'unverified'`, `'verified'`
**Set when:**
- User logs in � `'unverified'` or `'verified'` (based on email verification)
- User logs out � `'anonymous'`

**Implementation:** `analytics_provider.dart:1592-1606`

---

### `provider`
**Values:** `'email'`, `'google'`, `'apple'`
**Set when:** User authenticates with a provider
**Cleared when:** User logs out

**Implementation:** `analytics_provider.dart:1592-1596`

---

## Implementation Quality Assessment

###  Strengths

1. **Centralized Architecture**
   - Single source of truth (`analytics_provider.dart`)
   - Consistent API across the app
   - Easy to maintain and update

2. **Non-Blocking Design**
   - All analytics calls use `unawaited()` or `Future.microtask()`
   - Analytics failures never block UI
   - Errors caught and logged silently

3. **Error Handling**
   - Comprehensive try-catch blocks
   - Silent failure in production
   - Debug logging in development
   - Never throws exceptions to calling code

4. **Auth Integration**
   - Automatic user property management
   - Auto-tracking of login/logout
   - User ID synced with Firebase Auth

5. **Privacy Conscious**
   - Only non-sensitive data tracked
   - No PII in event parameters
   - Medication names sanitized
   - Disabled by default in debug mode

6. **Well-Documented**
   - Extensive dartdoc comments
   - Event purpose clearly explained
   - Parameter definitions documented
   - Result value enums documented

7. **Type Safety**
   - Constants for event names (`AnalyticsEvents`)
   - Constants for parameter names (`AnalyticsParams`)
   - Constants for error types (`AnalyticsErrorTypes`)
   - Reduces typos and improves maintainability

### � Areas for Improvement

1. **Incomplete Event Usage**
   - Several events defined but not actively used:
     - `onboarding_step_completed`
     - `onboarding_completed`
     - `treatment_choice_selected`
     - `session_updated`
     - `reminder_snoozed`
     - `schedules_preloaded`
     - `schedules_cache_hit`
     - And others
   - Consider: Remove unused events or implement tracking

2. **Missing Screen View Tracking**
   - `screen_view` event defined but not used
   - No automatic screen tracking implemented
   - Consider: Add router middleware for automatic screen tracking

3. **Inconsistent Parameter Naming**
   - Some events use `user_id` (string literal)
   - Others use `AnalyticsParams.petId` (constant)
   - Consider: Standardize all parameters to use constants

4. **Offline Mode Not Implemented**
   - `offline_logging_queued` and `sync_completed` events defined
   - Offline queue tracking infrastructure missing
   - Consider: Implement or remove these events

5. **Limited Error Context**
   - Some error events could benefit from more context
   - Stack traces not included (by design for privacy)
   - Consider: Add non-sensitive debug context

### =' Recommendations

1. **Audit Unused Events**
   - Review all events with "Note: Currently defined but not actively used"
   - Either implement tracking or remove event definitions
   - Document intentional future-ready events

2. **Implement Screen Tracking**
   - Add GoRouter observer for automatic screen views
   - Track route transitions
   - Capture user navigation patterns

3. **Standardize Parameter Usage**
   - Migrate all string literal parameters to constants
   - Update dartdoc to reference parameter constants
   - Add lint rule to prevent raw string parameters

4. **Add Integration Tests**
   - Verify events fire on key user actions
   - Test event parameters contain expected values
   - Mock Firebase Analytics for testing

5. **Create Analytics Dashboard Guide**
   - Document which events to monitor
   - Define key metrics and KPIs
   - Create funnel analysis guides

---

## Usage Patterns

### Accessing Analytics Service

```dart
// Most common pattern (direct access)
final analytics = ref.read(analyticsServiceDirectProvider);
await analytics.trackFeatureUsed(featureName: 'example');

// Via notifier (less common)
final notifier = ref.read(analyticsProvider.notifier);
await notifier.service.trackFeatureUsed(featureName: 'example');
```

### Non-Blocking Calls

```dart
// Using unawaited (recommended)
import 'dart:async' show unawaited;

unawaited(
  ref.read(analyticsServiceDirectProvider).trackSessionLogged(
    treatmentType: 'medication',
    sessionCount: 1,
    isQuickLog: false,
    adherenceStatus: 'complete',
  ),
);

// Using Future.microtask (alternative)
Future.microtask(() async {
  await ref.read(analyticsServiceDirectProvider).trackFeatureUsed(
    featureName: 'example',
  );
});
```

### Error Handling

```dart
// Error handling is internal to AnalyticsService
// Calling code doesn't need try-catch
try {
  await _analytics.logEvent(
    name: eventName,
    parameters: parameters,
  );
} on Exception catch (e) {
  if (kDebugMode) {
    debugPrint('[Analytics] Failed to track event: $e');
  }
  // Never throw - analytics failure shouldn't break functionality
}
```

### Conditional Tracking

```dart
// Service automatically checks _isEnabled
Future<void> trackEvent() async {
  if (!_isEnabled) return;  // Early return if disabled

  await _analytics.logEvent(...);
}
```

---

## Files with Analytics Tracking

| File | Events Tracked | Lines |
|------|----------------|-------|
| `analytics_provider.dart` | All event definitions | 1-1671 |
| `welcome_screen.dart` | Onboarding start/abandon | 142, 225 |
| `logging_service.dart` | Logging failures | 239, 257, 401, 419, 760, 778 |
| `logging_provider.dart` | Session logged, cache tracking | Multiple |
| `app_shell.dart` | Reminder tapped | 630, 642, 754 |
| `notification_settings_screen.dart` | Settings changes | 620, 643, 664, 710, 794, 819 |
| `notification_status_widget.dart` | Notification icon tap | 179, 197, 209 |
| `permission_preprompt.dart` | Permission dialogs | 62, 229, 268 |
| `notification_index_store.dart` | Index corruption | 236, 264 |
| `schedule_notification_handler.dart` | Schedule CRUD notifications | Multiple |
| `water_drop_progress_card.dart` | Weekly progress | 72, 100 |
| `treatment_confirmation_popup.dart` | Popup opened | 56 |
| `weight_provider.dart` | Weight features | 280, 339, 409, 493, 564, 622 |
| `injection_sites_analytics_screen.dart` | Screen view | 29-32 |

---

## Summary

The Hydracat app has a **comprehensive and well-architected analytics implementation** that covers all major user flows and features. The implementation follows Flutter and Firebase best practices with non-blocking calls, proper error handling, and privacy-conscious tracking.

**Key strengths:**
- Centralized, maintainable architecture
- Excellent error handling and resilience
- Auth-aware user property management
- Type-safe constants for events and parameters

**Opportunities:**
- Implement or remove unused event definitions
- Add automatic screen view tracking
- Standardize parameter naming
- Add analytics integration tests

**Overall Grade: A-**

The analytics implementation is production-ready and provides comprehensive insights into user behavior, treatment logging, and notification reliability. Minor improvements would elevate it to an A+ implementation.
