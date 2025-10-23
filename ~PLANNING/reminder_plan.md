## HydraCat Notification & Reminder System – Implementation Plan

### Overview
Implement an offline-first, timezone-accurate reminder system driven by local schedules, with empathetic, medically appropriate content. Use flutter_local_notifications for on-device scheduling, Firebase Messaging only for token registration (no push re-engagement in V1), and SharedPreferences for a minimal local index of scheduled notifications. Integrate with existing Riverpod providers, OverlayService-based logging popups, and Firestore cost-optimization rules.

---

## Phase 0: Platform & Foundation Setup

### ✅ Step 0.1: Initialize notification stack (tz + plugin) — COMPLETED
Files to modify/create:
- `lib/app/main.dart` (or `main.dart` entry): initialize tz and ReminderPlugin.
- `lib/features/notifications/services/reminder_plugin.dart` (NEW): thin wrapper around `flutter_local_notifications` for DI/mocking.

Implementation details:
1) Add `timezone` package (already transitively used by plugin) and call:
   - `tz.initializeTimeZones()` once on app startup
   - `tz.setLocalLocation(tz.getLocation(await nativeTimeZoneName))` using `DateTime.now()` or platform-native.
2) Create `ReminderPlugin` singleton with:
   - `initialize()` → instantiate `FlutterLocalNotificationsPlugin`, configure initialization settings for Android and iOS, wire `onDidReceiveNotificationResponse` callback.
   - `showZoned(id, details)` / `cancel(id)` / `pendingNotificationRequests()` methods.
3) Inject provider:
   - `final reminderPluginProvider = Provider<ReminderPlugin>((ref) => ReminderPlugin());`

**Implementation Summary:**
- ✅ Added `timezone: ^0.10.1` to pubspec.yaml
- ✅ Created `lib/features/notifications/services/reminder_plugin.dart` (221 lines)
  - Singleton pattern with factory constructor
  - Methods: `initialize()`, `showZoned()`, `cancel()`, `cancelAll()`, `pendingNotificationRequests()`
  - Placeholder `onDidReceiveNotificationResponse` callback (logs in dev mode)
  - Comprehensive error handling with graceful degradation
  - Dev-mode logging throughout
- ✅ Created `lib/features/notifications/providers/notification_provider.dart` (16 lines)
  - Simple Riverpod provider for ReminderPlugin singleton
  - Feature-based organization (new pattern for project)
- ✅ Modified `lib/main.dart` (+97 lines)
  - Timezone initialization using `tz.local` (auto-detects device timezone)
  - ReminderPlugin initialization with error handling
  - Production error logging to Crashlytics
  - Graceful degradation if initialization fails
  - Provider overrides for `reminderPluginProvider`
- ✅ Zero linting errors (`flutter analyze` passes)
- ✅ Tested on iOS simulator - app starts successfully
- ✅ Handles platform-specific initialization behavior (iOS returns false/null, expected behavior)

**Notes:**
- iOS simulators typically show "UTC" timezone and return `false` from plugin initialization (expected behavior)
- Physical devices will show actual timezone and notifications will work correctly
- Full notification tap handling (deep-linking) will be implemented in Phase 3 (Step 3.1)
- Detailed platform configuration (channels, exact alarms, APNs) deferred to Steps 0.2-0.4 as planned

### ⚠️ Step 0.2: iOS APNs configuration (resolve APNS token warning) — PARTIALLY COMPLETED
**Status**: Code and configuration complete; Apple Developer account required to finish

**✅ Completed (without Apple Developer account)**:
1) ✅ Info.plist configured:
   - `UIBackgroundModes` array with `remote-notification` added (lines 48-51 in Info.plist)
2) ✅ Code implementation in `lib/shared/services/firebase_service.dart`:
   - Added `dart:io` import for platform detection
   - Implemented `setForegroundNotificationPresentationOptions(alert: true, sound: true)` for iOS
   - Implemented APNs token retrieval with graceful null handling
   - Enhanced FCM token error handling with context-aware messaging
   - Added comprehensive dev logging explaining APNs token status
3) ✅ Error handling:
   - App gracefully handles missing APNs token (expected without Apple Developer account)
   - Clear log messages explain why APNs token is null and what's required
   - No app crashes or initialization failures
4) ✅ Testing verified:
   - App runs successfully on iOS simulator and physical device
   - Local notifications (flutter_local_notifications) fully functional
   - Firebase Messaging initializes successfully
   - Permissions granted correctly
5) ✅ FirebaseAppDelegateProxyEnabled: Defaults to `true` (correct), no changes needed

**❌ Pending (requires Apple Developer Program enrollment - see APPENDIX)**:
1) ❌ Xcode capability: Push Notifications (requires paid Developer Team)
   - Currently blocked: "Push Notifications" doesn't appear in Xcode's + Capability menu with Personal Team
   - Will unlock once signed in with Developer account in Xcode
2) ❌ Apple Developer Portal: Create APNs Authentication Key (.p8) or certificates
3) ❌ Firebase Console: Upload APNs key to both projects (hydracattest + myckdapp)
4) ❌ Testing: Verify APNs token non-null on physical device after configuration

**Current Behavior**:
- APNs token: `null` (expected - requires Apple Developer account)
- FCM token: `null` (expected - iOS requires APNs token first)
- Log message: "FCM Token unavailable (APNs token required on iOS). This is expected without Apple Developer account setup."
- Local notifications: ✅ Working perfectly
- Remote push notifications: ❌ Will work after Apple Developer setup

**Next Steps**: See APPENDIX at end of this document for complete setup instructions when Apple Developer Program is enrolled.

### Step 0.3: Android configuration
Steps:
1) Add `POST_NOTIFICATIONS` permission in `android/app/src/main/AndroidManifest.xml` for Android 13+.
2) Add `SCHEDULE_EXACT_ALARM` permission for medical-grade timing accuracy:
   - `<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>`
   - Check permission status with `plugin.canScheduleExactNotifications()`
   - If denied, fallback to inexact alarms but warn user in settings UI
   - **Rationale**: Standard alarms can be delayed by 10-15 minutes due to battery optimization; critical for medical reminders.
3) Provide proper small icon in `android/app/src/main/res/drawable/ic_stat_notification.xml` and set accent color in `AndroidInitializationSettings`.
4) Create channels at plugin initialization (one-time):
   - `medication_reminders` (IMPORTANCE_HIGH, vibration on)
   - `fluid_reminders` (IMPORTANCE_HIGH, vibration on)
   - `weekly_summaries` (IMPORTANCE_DEFAULT, vibration off)
5) Use exact alarms for critical treatment reminders when permission granted.

### Step 0.4: Device token registration (no push in V1)
Files:
- `lib/shared/services/firebase_service.dart` (extend)
- `lib/features/notifications/services/device_token_service.dart` (NEW)

Implementation details:
1) Persist stable `deviceId` in `flutter_secure_storage` (create or read once per install).
2) On sign-in and on `onTokenRefresh`, upsert `devices/{deviceId}` with: `userId, fcmToken, platform, lastUsedAt, createdAt`.
3) Throttle `lastUsedAt` updates to once per session/day (follow CRUD rules). Skip if token unchanged.

### Step 0.5: Battery optimization handling
Files:
- `lib/features/notifications/services/battery_optimization_service.dart` (NEW)
- `lib/providers/notification_provider.dart` (extend)

Implementation details:
1) Detect if app is battery-optimized (Android):
   - Use `permission_handler` package or custom platform channel
   - Check `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` permission status
2) Create educational prompt explaining impact on medical reminders:
   - "Battery optimization may delay critical treatment reminders. For best reliability, please disable battery optimization for HydraCat."
   - Show battery level impact is minimal for notification-only app
3) Link to settings: `Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)`
4) Track in analytics: `battery_optimization_status`, `battery_optimization_prompt_shown`, `battery_optimization_granted`
5) Show status in Notification Settings screen with actionable guidance
6) **Critical**: Test on Xiaomi, Oppo, Samsung devices with aggressive battery management

---

## Phase 1: Models, Storage & Providers

### Step 1.1: Notification settings model and persistence
Files:
- `lib/features/notifications/models/notification_settings.dart` (NEW)
- `lib/providers/notification_provider.dart` (NEW)

Implementation details:
1) Model fields: `enableNotifications: bool`, `weeklySummaryEnabled: bool`, `snoozeEnabled: bool`, `endOfDayEnabled: bool`, `endOfDayTime: String ("22:00")`, `showSensitiveOnLockScreen: bool (false)`.
2) Store settings locally in SharedPreferences under key `notif_settings_{userId}`. Optionally mirror to Firestore later.
3) Providers:
   - `notificationSettingsProvider` (StateNotifier with load/save)
   - `notificationPermissionStatusProvider` (derived): queries platform permission via plugin/FirebaseMessaging
   - `isNotificationEnabledProvider` (derived): true only if permission granted AND `enableNotifications` true.

### Step 1.2: Scheduled notification index (for idempotency)
Files:
- `lib/features/notifications/models/scheduled_index.dart` (NEW)
- `lib/features/notifications/services/index_store.dart` (NEW)

Implementation details:
1) Index entry shape: `{ notificationId: int, scheduleId: String, treatmentType: String (medication|fluid), timeSlotISO: String (HH:mm), kind: String (initial|followup|snooze) }`.
2) Store per-day per-pet per-user under key `notif_index_v2_{userId}_{petId}_{YYYY-MM-DD}` in SharedPreferences.
   - **Versioned schema** (`v2`) allows future migrations
3) Data integrity:
   - Add CRC/checksum to detect corruption
   - Validate on read; if corrupt, trigger reconciliation
4) APIs: `getForToday()`, `putEntry(entry)`, `removeEntryBy(scheduleId, timeSlotISO, kind)`, `clearAllForYesterday()`, `reconcile()`
5) Reconciliation strategy (run on app start and after corruption detection):
   - If index missing but plugin has scheduled notifications: rebuild index from plugin's `pendingNotificationRequests()`
   - If index exists but plugin notifications missing: reschedule from index
   - If mismatch: plugin state is source of truth; update index to match
   - Report reconciliation events to analytics with delta counts
6) Optional (V2): Backup critical index data to Firestore (write-once per day, read on reinstall).

### Step 1.3: Deterministic notification IDs
Files:
- `lib/features/notifications/utils/notification_id.dart` (NEW)

Implementation details:
1) Compute a stable 31-bit int from: `'$userId|$petId|$scheduleId|$hhmm|$kind'` using FNV-1a or a small DJB2 hash.
2) Reserve kind suffix space by including `kind` in the string (no bit math required). Ensure no collisions in unit tests.

### Step 1.4: Multi-device sync preparation (Optional V2)
Files:
- `lib/features/notifications/services/cross_device_sync_service.dart` (NEW, V2)
- Firestore collection: `treatmentEvents/{userId}/events/{eventId}` (V2)

Implementation details:
1) When logging treatment, optionally write minimal event to Firestore:
   ```
   {
     treatmentLoggedAt: timestamp,
     scheduleId: string,
     timeSlot: string,
     deviceId: string,
     petId: string
   }
   ```
2) Keep writes minimal (only on actual logging, not scheduling) to respect Firestore cost rules
3) On app resume, check for recent logs from other devices (last 24h):
   - Query: `where('petId', '==', petId).where('treatmentLoggedAt', '>', yesterday)`
   - If treatment already logged from another device, cancel pending notifications for that slot
4) TTL: Auto-delete events older than 7 days using Firestore TTL or scheduled cleanup
5) Enable via feature flag for gradual rollout

---

## Phase 2: Scheduling Engine

### Step 2.1: ReminderService (core orchestrator)
Files:
- `lib/features/notifications/services/reminder_service.dart` (NEW)
- `lib/providers/notification_provider.dart` (extend)

Public API:
- `Future<void> scheduleAllForToday(String userId, String petId)`
- `Future<void> scheduleForSchedule(String userId, String petId, Schedule schedule)`
- `Future<void> cancelForSchedule(String userId, String petId, String scheduleId)`
- `Future<void> cancelSlot(String userId, String petId, String scheduleId, String hhmm)`
- `Future<void> rescheduleAll(String userId, String petId)`

Internal logic:
1) Read today's schedules from `profileProvider` cache (no Firestore reads).
2) For each reminder time today:
   - Build payload `{userId, petId, scheduleId, treatmentType, timeSlotISO, kind: 'initial'}`
   - Title/body via l10n:
     - Medication: "It's time for {medicationName} for {petName}"
     - Fluid: "Fluid therapy {volume} mL for {petName}"
   - Channel by treatment type.
   - Schedule zoned notification at local time.
   - Record entry in index.
3) Follow-up notification logic:
   - Default: schedule +2h after initial reminder
   - If initial + 2h > 23:59, schedule follow-up for next morning (08:00)
   - Add user preference for follow-up timing (2h, 4h, next-day, off) in settings
   - For critical medications, consider multiple follow-ups (e.g., +2h, +4h) - make configurable per schedule type
   - Always respect user's notification quiet hours if implemented

### Step 2.2: tz scheduling helper with grace period
Add helper `zonedDateTimeForToday(hhmm)` to map "HH:mm" to a `tz.TZDateTime` today accounting for DST.

Grace period logic:
1) If reminder time is past but within grace period (30 minutes), schedule immediate notification
2) For older missed reminders (>30 min past), don't schedule but:
   - Show in-app "You missed" banner/card in home screen
   - Include in end-of-day summary
   - Track `missed_reminder` events in analytics with time delta
3) Grace period configurable in settings (default: 30 min)

### Step 2.3: Idempotent rescheduling
`rescheduleAll()`:
1) Fetch current index for today and all pending plugin notifications.
2) Cancel unknown pending or orphaned entries; re-issue missing ones using deterministic IDs.

### Step 2.4: Index maintenance
On every schedule/cancel, update the index atomically (write after plugin call succeeds). On midnight, purge yesterday's indexes.

### Step 2.5: Notification grouping and limits
Files:
- `reminder_service.dart` (extend scheduling logic)

Implementation details:
1) Android notification grouping:
   - Group all notifications by pet using `setGroup("pet_{petId}")`
   - Create summary notification for each group showing total pending reminders
   - Use `setGroupSummary(true)` for the group summary notification
2) Notification limits:
   - Android limits pending notifications (~500 system-wide)
   - Limit scheduled notifications per pet to 50 at any time
   - If limit reached, schedule only next 24 hours, then reschedule daily
3) Priority handling:
   - Schedule initial reminders first, then follow-ups
   - If approaching limit, prioritize medication over fluid reminders
4) Monitoring:
   - Track `notification_limit_reached` events in analytics
   - Log warning when approaching 80% of per-pet limit

---

## Phase 3: Delivery UX (Tap, Deep Link, Snooze)

### Step 3.1: Tap handling and deep-link
Files:
- `lib/features/notifications/services/reminder_plugin.dart` (extend init callback)
- `lib/app/app_shell.dart` (wire handler to OverlayService)

Implementation details:
1) In plugin `onDidReceiveNotificationResponse`, parse payload → `NotificationTapData`.
2) If app not running: use plugin’s launch details at startup to route.
3) Handler behavior:
   - Ensure user authenticated and pet loaded
   - `context.go('/home')` then immediately open Overlay logging popup by treatment type using existing popups: MedicationLoggingScreen or FluidLoggingScreen.
   - Pre-fill using `todaysMedicationSchedulesProvider`/`todaysFluidScheduleProvider` and `scheduleId`.

### Step 3.2: Single action – “Log now”
Files:
- Configure Android action intent and iOS category (UNNotificationCategory) with the same payload; route through the same tap handler.
Note: No direct data writes from notification actions in V1.

### Step 3.3: Snooze 15 minutes (toggle-controlled)
Files:
- `reminder_service.dart` (add `snoozeCurrent(payload)`)

Implementation details:
1) If `snoozeEnabled` AND current notification is `initial` or `followup`: cancel it and schedule a new notification at now+15m with `kind: 'snooze'` (same channel/title/body), update index.

---

## Phase 4: Weekly & End‑of‑Day Summaries

### Step 4.1: Weekly summary (Monday 09:00)
Files:
- `reminder_service.dart` (add `scheduleWeeklySummary()`; `cancelWeeklySummary()`)

Implementation details:
1) Compute next Monday 09:00 (tz-aware) and schedule repeating weekly notification with deterministic ID `summary_weekly_{userId}_{petId}`.
2) Build message client-side using `SummaryCacheService.getTodaySummary()` and, if needed, a single Firestore fetch via `SummaryService.getWeeklySummary()` (cache-first).
3) Deep-link to Progress screen (route `/progress`), keep lock-screen body neutral.

### Step 4.2: End‑of‑Day (22:00) outstanding summary (opt‑in)
Files:
- `reminder_service.dart` (add `scheduleEndOfDaySummary()`; `cancelEndOfDaySummary()`)
- iOS: Notification Service Extension (for dynamic content at delivery time)
- Android: Foreground service or scheduled worker (for dynamic content)

Implementation details:
1) Schedule EOD notification for user's configured time (default: 22:00) immediately when feature enabled
2) At delivery time (22:00), compute content dynamically:
   - **iOS**: Use Notification Service Extension to modify content before display
   - **Android**: Use scheduled WorkManager job or foreground service to check and update notification
3) Content computation (at delivery time):
   - Read from cached schedules and `dailyCacheProvider` (no Firestore read if cache warm)
   - Detect outstanding treatments (treatments scheduled but not logged)
   - If no outstanding treatments, cancel the notification before display
   - If outstanding treatments exist, show notification with counts: "You have 2 medications and 1 fluid therapy pending"
4) Deep link to logging/home screen
5) Fallback: If dynamic content not possible, schedule fixed notification and accept some false positives
6) User settings: configurable time (default 22:00) and enable/disable toggle

**Rationale**: App may not be running at 21:59; notification extensions/workers run reliably at delivery time.

---

## Phase 5: Permission Flow & Settings UI

### Step 5.1: Permission flow
Files:
- `lib/features/notifications/widgets/permission_preprompt.dart` (NEW)
- `notification_provider.dart` (extend)

Implementation details:
1) Pre-prompt explains benefits and empathy; if accepted, request system permission:
   - iOS: `FirebaseMessaging.requestPermission()` (alert/sound enabled)
   - Android 13+: request POST_NOTIFICATIONS via plugin helper
2) If denied, show in-app banner with “Enable in Settings” (opens settings intent).

### Step 5.2: Home app bar “barred clock” icon
Files:
- `lib/app/app_shell.dart` (toolbar action)
- `notification_provider.dart` (derived provider `notificationsEffectivelyDisabledProvider`)

Implementation details:
1) Show icon only when permission denied OR in-app toggle disabled.
2) Tap shows pre‑prompt or opens OS settings.

### Step 5.3: Notification Settings screen
Files:
- `lib/features/settings/screens/notification_settings_screen.dart` (NEW)

Implementation details:
1) Toggles: enable notifications, weekly summary, snooze, end-of-day.
2) Show permission status and a button to open OS settings.
3) "Reschedule all reminders" button calls `ReminderService.rescheduleAll()` and weekly/EOD reschedulers.
4) Display battery optimization status with actionable guidance (link to Step 0.5)
5) Show exact alarm permission status (Android) with explanation
6) Privacy settings (link to Step 5.4)

### Step 5.4: Privacy and compliance enhancements
Files:
- `notification_settings.dart` (extend model)
- `notification_settings_screen.dart` (extend UI)
- `reminder_service.dart` (respect privacy settings)

Implementation details:
1) Default `showSensitiveOnLockScreen` to `false` for medical privacy
2) Lock-screen content modes:
   - **Generic mode** (default): "Treatment reminder for [PetName]" - no medication/fluid details
   - **Detailed mode** (opt-in): Full details including medication name and dosage
3) Notification content strategy:
   - Lock screen (device locked): Use generic or detailed based on setting
   - Notification center (device unlocked): Always show full details
   - Configure via notification privacy level in plugin initialization
4) Privacy notice in permission pre-prompt:
   - Explain what information appears in notifications
   - Clarify that notification data is stored locally only
   - Link to privacy policy section on notification data handling
5) Data retention:
   - Auto-delete notification index older than 7 days (implement in index maintenance)
   - Clear all notification data on logout
   - Provide "Clear notification data" option in settings
6) Compliance documentation:
   - Update privacy policy to mention notification data handling
   - Clarify no medical data transmitted via push notifications
   - Document local storage and retention policies

---

## Phase 6: Integration with Existing Providers

### Step 6.1: Cancel follow-ups on successful logging
Files:
- `lib/providers/logging_provider.dart` (modify after success branches)
- `reminder_service.dart`

Implementation details:
1) After a session is logged, compute the matched slot time using existing schedule matching (±2h window used in logging). Call `cancelSlot(userId, petId, scheduleId, hhmm)`.
2) Cancel any pending `followup`/`snooze` entries for that slot and update index.

### Step 6.2: React to schedule CRUD
Files:
- `lib/providers/profile_provider.dart` (after schedule create/update/delete)

Implementation details:
1) On create/update: `ReminderService.scheduleForSchedule(userId, petId, schedule)`
2) On delete: `ReminderService.cancelForSchedule(userId, petId, scheduleId)`
3) Keep operations idempotent; rely on deterministic IDs and index.

### Step 6.3: Lifecycle & midnight rollover
Files:
- `lib/app/app_shell.dart`

Implementation details:
1) On app start: `ReminderService.scheduleAllForToday(userId, petId)` and schedule weekly/EOD if enabled.
2) On app resume with date change: `ReminderService.rescheduleAll()` and re-evaluate weekly/EOD timers.
3) At midnight, clear yesterday’s indexes (handled by provider or a lightweight once-per-day timer similar to existing cache invalidations).

---

## Phase 7: Analytics & Error Handling

### Step 7.1: Analytics
Files:
- `lib/providers/analytics_provider.dart` (extend constants + helper methods)
- Integrations across services

Events:
- **Scheduling**: `reminders_scheduled` (params: count, treatmentType)
- **Delivery**: `notification_delivered` (if measurable via delivery callback)
- **User interaction**:
  - `reminder_tapped` (params: treatmentType, kind: initial/followup/snooze)
  - `reminder_dismissed` (vs tapped)
  - `reminder_snoozed` (if enabled)
- **Summaries**: `weekly_summary_fired`, `eod_summary_fired`
- **Lifecycle**: `reminder_cancelled_on_log`, `reminders_cleared_on_logout`
- **Permissions**:
  - `permission_prompt_shown`, `permission_granted`, `permission_denied`
  - `battery_optimization_prompt_shown`, `battery_optimization_granted`
  - `exact_alarm_permission_checked` (params: granted: bool)
- **Reliability**:
  - `missed_reminder_count` (daily aggregate with time delta)
  - `index_reconciliation_performed` (params: added, removed, repaired counts)
  - `index_corruption_detected`
  - `notification_limit_reached`
- **Failures**:
  - `reminder_schedule_failed` (params: scheduleId, error)
  - `reminder_cancel_failed` (params: scheduleId, error)
  - `plugin_initialization_failed`

### Step 7.2: Error handling
Implementation details:
1) Wrap schedule/cancel in try/catch; report to Crashlytics with context (userId, petId, scheduleId).
2) On app start, reconcile plugin pending vs local index and repair inconsistencies.
3) Specific error scenarios and recovery strategies:
   - **Plugin initialization failure**:
     - Retry with exponential backoff (max 3 attempts)
     - If all retries fail, disable notification features and show user-friendly error
     - Report to Crashlytics with device info
   - **Timezone data unavailable**:
     - Fallback to device default timezone
     - Log error with warning level
     - Continue with best-effort scheduling
   - **Index corruption**:
     - Rebuild index from plugin's `pendingNotificationRequests()`
     - If rebuild fails, clear corrupted data and reschedule from cached schedules
     - Report corruption event to Crashlytics and analytics
   - **Schedule with invalid time format**:
     - Skip invalid schedule
     - Log error with scheduleId for debugging
     - Continue processing remaining schedules
   - **Permission denied after scheduling**:
     - Clear all pending notifications
     - Update UI to reflect permission loss
     - Show re-permission prompt on next app start
   - **User logged out between schedule and delivery**:
     - Notification tap handler checks auth state
     - If not authenticated, show login screen instead of deep link
     - Clear all scheduled notifications on explicit logout
   - **Schedule deleted between schedule time and delivery**:
     - Tap handler verifies schedule still exists
     - If deleted, show generic home screen instead of logging popup
     - Gracefully handle missing data without crashes
   - **Notification limit exceeded**:
     - Log warning and switch to rolling 24h window strategy
     - Notify user via in-app message
     - Track in analytics for monitoring

---

## Phase 8: Testing

### Step 8.1: Unit tests
Files:
- `test/features/notifications/notification_id_test.dart`
- `test/features/notifications/schedule_mapper_test.dart`
- `test/features/notifications/index_store_test.dart`

Targets:
1) ID generator stability and collision resistance.
2) Mapping schedules → today’s slots (+2h follow-up), including DST boundary.
3) Index add/remove/lookup semantics and midnight purge.

### Step 8.2: Widget tests
Files:
- `test/features/notifications/notification_settings_screen_test.dart`
- `test/app/home_app_bar_icon_test.dart`

Targets:
1) Settings toggles persistence and reschedule button behavior.
2) App bar icon visibility based on permission + toggle state.

### Step 8.3: Integration tests (mocked plugin)
Files:
- `test/features/notifications/reminder_service_test.dart`

Targets:
1) Schedule/cancel calls on plugin mocked layer.
2) Cancel-on-log path; reschedule-on-date-change path.

### Step 8.4: Critical scenario testing
Files:
- `test/features/notifications/critical_scenarios_test.dart` (integration tests)
- Manual QA test plan document

**Automated integration tests** (with real plugin on device):
1) Timezone boundary tests:
   - DST transition day (spring forward and fall back)
   - Midnight rollover
   - User timezone change mid-day
2) Notification delivery after app states:
   - App killed + device restarted → notifications still fire
   - App in background for 24h+ → notifications fire
   - App reinstalled → no stale notifications persist

**Manual QA scenarios**:
1) **Battery optimization impact**:
   - Enable battery saver mode → observe notification timing (may be delayed)
   - Test on Xiaomi, Oppo, Samsung devices with aggressive battery management
   - Verify battery optimization prompt shows and links work
2) **Permission flows**:
   - Notification permission revoked after scheduling → UI reflects state, clear notifications
   - Exact alarm permission denied → fallback to inexact, show warning
   - Re-grant permission → notifications resume
3) **Multi-schedule complexity**:
   - Multiple pets with overlapping schedules → correct deep links and grouping
   - 10+ reminders per day → no performance issues
   - Approaching notification limit (45+ scheduled) → rolling window kicks in
4) **Lifecycle edge cases**:
   - Schedule deleted between schedule and delivery → tap handler graceful
   - User logged out between schedule and delivery → shows login screen
   - Treatment logged on device A → pending notifications on device B handled (V2 multi-device sync)
5) **Grace period and missed reminders**:
   - Open app 20 min after reminder time → immediate notification fires
   - Open app 2h after reminder time → shows "missed" banner, no notification
6) **Follow-up logic**:
   - Reminder at 22:30 → follow-up at next morning 08:00 (not past midnight)
   - Log treatment before follow-up time → follow-up cancelled
7) **Privacy modes**:
   - Lock screen shows generic content (default) vs detailed (opt-in)
   - Device unlocked shows full details in notification center
8) **Index reconciliation**:
   - Clear SharedPreferences manually → app start rebuilds index from plugin
   - Corrupt index data → reconciliation detects and repairs
   - Orphaned plugin notifications → reconciliation cleans up

**Performance testing**:
1) Cold start with 50 pending notifications → no ANR/lag
2) Schedule 50 reminders → completes under 2s
3) Midnight rollover with active app → smooth transition, no UI freeze

**Reliability monitoring** (post-launch):
1) Track `reminder_schedule_failed` rate → alert if >1%
2) Track `missed_reminder_count` → investigate patterns
3) Track `index_reconciliation_performed` → monitor frequency

---

## Phase 9: Performance & Reliability

### Step 9.1: Idempotency
Implementation details:
1) Deterministic IDs + index reconciliation make repeated scheduling safe.

### Step 9.2: Minimal Firestore usage
Implementation details:
1) Use only cached schedules; no reads for reminders.
2) Token writes throttled; no Cloud Functions in V1.

### Step 9.3: Localization & content
Implementation details:
1) All strings in l10n ARB; lock-screen text neutral; include pet name and treatment specifics in non-sensitive contexts.

---

## Phase 10: Rollout & QA

### Step 10.1: Feature flag
Implementation details:
1) Gate behind `FlavorConfig.isDevelopment` or a local `kEnableReminders` flag during development.

### Step 10.2: QA scenarios
Scenarios:
1) Multi-reminder per day per medication; follow-up cancels upon logging.
2) Snooze (if enabled) reschedules in 15m with correct payload.
3) DST transition day behaves as expected.
4) Weekly and EOD summaries fire only when enabled and conditions met.

### Step 10.3: Gradual rollout strategy
Implementation details:
1) **Internal testing** (1 week):
   - Deploy to team devices (iOS and Android)
   - Test on diverse OS versions and manufacturers
   - **Critical**: Include Xiaomi, Oppo, Samsung devices for battery optimization testing
   - Verify all analytics events firing correctly
2) **Beta testing** (2 weeks):
   - TestFlight (iOS) / Internal testing track (Android)
   - Recruit 20-50 beta users with real CKD pets
   - Diverse device matrix: Android 10-14, iOS 15-17
   - Collect feedback via in-app feedback form
   - Monitor crash-free rate (target: >99.5%)
3) **Staged production rollout** (2 weeks):
   - **Week 1**: 10% of users → monitor for 3-4 days
   - **Week 1**: 50% of users → monitor for 3-4 days
   - **Week 2**: 100% of users
   - Pause rollout if:
     - `reminder_schedule_failed` rate >2%
     - Crash rate >0.5%
     - User reports of missed critical reminders
4) **Monitoring and alerts**:
   - Set up Firebase Performance Monitoring for notification scheduling latency
   - Crashlytics alert for notification-related crashes
   - Analytics dashboard for:
     - Daily active notification users
     - Reminder delivery rate (estimated from taps + dismissals)
     - Permission grant rate
     - Battery optimization opt-in rate
5) **Kill switch**:
   - Implement feature flag via Firebase Remote Config: `enable_notifications`
   - If critical issue discovered, remotely disable for all users
   - Graceful degradation: show maintenance message in notification settings
6) **Communication**:
   - In-app announcement: "New feature: Smart Reminders!"
   - Email to active users explaining benefits
   - Help docs and FAQ ready before launch

---

## Phase 11: Accessibility

### Step 11.1: Notification content accessibility
Files:
- `reminder_service.dart` (notification text generation)
- `l10n/*.arb` (localization files)

Implementation details:
1) Notification content requirements:
   - Clear, concise, screen-reader friendly text
   - No abbreviations or jargon (e.g., "milliliters" not "mL" for screen readers)
   - Proper sentence structure for TalkBack/VoiceOver
2) Title format: "Treatment reminder: [Type] for [Pet Name]"
3) Body format: Full sentence structure, e.g., "It's time to give Fluffy their Fortekor medication"
4) Avoid emojis or special characters that may not read well with screen readers

### Step 11.2: Notification actions accessibility
Files:
- `reminder_plugin.dart` (action button configuration)

Implementation details:
1) Action buttons labeled with clear, descriptive text:
   - "Log Treatment Now" (not just "Log")
   - "Snooze for 15 Minutes" (not just "Snooze")
2) Semantic labels for VoiceOver/TalkBack:
   - Set `accessibilityLabel` / `contentDescription` on iOS/Android
3) Test with VoiceOver (iOS) and TalkBack (Android):
   - Ensure action buttons are announced correctly
   - Verify reading order is logical

### Step 11.3: Settings screen accessibility
Files:
- `notification_settings_screen.dart` (UI widgets)

Implementation details:
1) Semantic labels and hints for all interactive elements:
   - Toggle switches: "Enable notifications, currently on/off"
   - Buttons: Clear action labels, e.g., "Open system notification settings"
2) Logical focus order for keyboard/screen reader navigation
3) Group related settings with semantic headers
4) Sufficient touch target sizes (minimum 48x48 dp)
5) Color contrast ratios meet WCAG AA standards:
   - Text: 4.5:1 for normal text, 3:1 for large text
   - Icons: 3:1 against background

### Step 11.4: Visual accessibility
Files:
- `app_shell.dart` (notification icon in app bar)
- `notification_settings_screen.dart` (UI components)

Implementation details:
1) High-contrast mode support:
   - Notification icons visible in all theme modes (light/dark/high-contrast)
   - Test with platform high-contrast settings enabled
2) Font scaling:
   - All notification text respects system text size settings
   - Test with system text size at 200%
   - Ensure no text truncation or UI overflow
3) Icon clarity:
   - App bar notification icon clearly distinguishable
   - Use solid shapes with good contrast, not thin lines

### Step 11.5: Testing and validation
Implementation details:
1) Manual testing with assistive technologies:
   - iOS: VoiceOver enabled → navigate settings, trigger notification, use actions
   - Android: TalkBack enabled → same flow
   - Test with screen off (screen reader only)
2) Automated accessibility testing:
   - Use Flutter's `Semantics` widget testing utilities
   - Verify semantic tree structure
3) Font scaling testing:
   - Test at 100%, 150%, 200% system font size
   - Verify layouts don't break
4) Color contrast validation:
   - Use accessibility inspector tools
   - Verify all text meets WCAG AA standards

---

## Notes on Coherence & Best Practices

### Alignment with Requirements
1) Aligns with PRD (reminders, follow-ups, empathetic copy, deep links) and existing architecture (overlay popups, cached schedules, summary cache).
2) Respects Firebase CRUD rules: zero additional reads for reminders; device tokens updated sparsely; summaries used only for weekly/EOD with cache-first logic.
3) `devices` collection is industry standard; stable `deviceId` and `onTokenRefresh` handling cover rotation/multi-device.
4) APNs token warning addressed via proper capabilities, APNs setup in Firebase, and `getAPNSToken()` once permission granted on device.
5) Deterministic IDs + local index guarantee idempotent scheduling, safe cancellation on logging, and robust recovery on restart.

### Medical App Reliability Standards
6) **Exact alarm scheduling** (`SCHEDULE_EXACT_ALARM`) ensures medical-grade timing accuracy, critical for CKD treatment adherence.
7) **Battery optimization handling** educates users and guides them to disable optimization, preventing notification delays on aggressive OEMs.
8) **Grace period logic** catches late app opens, ensuring users within 30 minutes of reminder time still get notified.
9) **Notification grouping and limits** prevent system overload while maintaining reliability for high-frequency treatment schedules.
10) **Index corruption recovery** with reconciliation ensures notifications persist through app reinstalls, OS updates, and data corruption.

### Privacy & Compliance
11) **Privacy-first defaults**: Lock-screen content is generic by default (no medication details visible), respecting medical data sensitivity.
12) **Data retention policies**: Auto-delete notification index older than 7 days, clear on logout, comply with minimal data retention principles.
13) **Compliance documentation**: Privacy policy updated to cover notification data handling, local storage, and retention.

### User Experience Excellence
14) **Smart follow-up logic**: Handles edge cases like late-night reminders (follows up next morning), respects user preferences, and supports multiple follow-ups for critical medications.
15) **End-of-day summary**: Uses delivery-time computation (notification extensions/workers) to avoid false positives when app not running.
16) **Missed reminder visibility**: In-app banners and EOD summaries ensure users aware of missed treatments without intrusive notifications.
17) **Multi-device sync preparation**: V2 feature ready for users managing treatments across phone/tablet.

### Robustness & Error Handling
18) **Comprehensive error scenarios**: Covers plugin failures, timezone issues, index corruption, permission changes, logout/schedule deletion edge cases.
19) **Exponential backoff retry**: Plugin initialization failures handled gracefully with retries and user-friendly fallback.
20) **Graceful degradation**: System continues functioning with best effort when permissions denied or limits reached.

### Testing & Quality Assurance
21) **Critical scenario coverage**: DST transitions, device restarts, permission changes, multi-schedule complexity, lifecycle edge cases.
22) **Manufacturer-specific testing**: Xiaomi, Oppo, Samsung devices with aggressive battery management explicitly tested.
23) **Accessibility validation**: Screen readers, font scaling, high-contrast modes tested to ensure inclusive design.

### Rollout & Monitoring
24) **Gradual rollout with kill switch**: 10% → 50% → 100% over 2 weeks with Firebase Remote Config kill switch for emergency rollback.
25) **Comprehensive analytics**: 25+ events tracking permissions, delivery, failures, reconciliation, and user behavior.
26) **Reliability monitoring**: Alert thresholds for schedule failures (>2%), crashes (>0.5%), and missed reminders.

### Industry Best Practices
27) **Offline-first architecture**: No Firestore reads for scheduling; all operations use cached data.
28) **Idempotent operations**: Deterministic IDs and index reconciliation make all operations safe to retry.
29) **Notification channels**: Proper Android channels with appropriate importance levels and user control.
30) **Timezone-aware scheduling**: Full DST support with `timezone` package and `tz.TZDateTime`.
31) **Accessibility compliance**: WCAG AA standards for color contrast, screen reader support, touch target sizes.
32) **Medical app empathy**: Content avoids clinical jargon, respects user stress, provides actionable guidance over technical details.

---

## APPENDIX: Apple Developer Program Requirements

### Tasks Requiring Paid Apple Developer Account ($99/year)

The following features are currently blocked and require Apple Developer Program enrollment:

---

### 1. Complete Step 0.2: iOS APNs Configuration for Push Notifications

**Status**: Partially complete - code ready, needs Apple Developer account setup

**Current State**:
- ✅ Code implemented in `lib/shared/services/firebase_service.dart`
- ✅ Info.plist configured with `UIBackgroundModes` for remote notifications
- ✅ Graceful error handling for missing APNs token
- ✅ Local notifications (flutter_local_notifications) fully functional
- ❌ APNs token unavailable (returns null)
- ❌ Remote push notifications non-functional

**What to Do Once Enrolled**:

#### A. Xcode Configuration

1. **Sign in to Xcode with Developer Account**:
   - Xcode → Settings → Accounts
   - Add Apple ID associated with Developer Program
   - Download provisioning profiles

2. **Update Team in Project**:
   - Open `ios/Runner.xcworkspace` in Xcode
   - Select Runner project → Runner target
   - Signing & Capabilities tab
   - Change Team from "Personal Team" to your Developer Team

3. **Add Push Notifications Capability**:
   - Still in Signing & Capabilities tab
   - Click **+ Capability**
   - Add **"Push Notifications"** (will now appear in list)
   - This creates `Runner.entitlements` file automatically

4. **Verify Background Modes**:
   - Confirm "Remote notifications" is still checked (already configured)

5. **Update Bundle Identifiers** (if needed):
   - Ensure Development and Production schemes use correct bundle IDs:
     - Development: `com.example.hydracatTest`
     - Production: `com.example.hydracat`

#### B. Apple Developer Portal Configuration

**Option 1: APNs Authentication Key (Recommended)**

1. Go to https://developer.apple.com/account
2. Navigate to **Certificates, Identifiers & Profiles**
3. Click **Keys** in sidebar
4. Click **+** to create new key
5. Name: "HydraCat APNs Key"
6. Check **Apple Push Notifications service (APNs)**
7. Click **Continue**, then **Register**
8. **Download the .p8 file** (IMPORTANT: Can only download once!)
9. Note the **Key ID** (10 characters, e.g., "AB12CD34EF")
10. Note your **Team ID** (found in top right of portal, e.g., "XYZ1234567")

**Option 2: APNs Certificates** (Alternative)

1. Create APNs certificates for each App ID:
   - Development certificate for `com.example.hydracatTest`
   - Production certificate for `com.example.hydracat`
2. Download and install certificates in Keychain
3. Export as .p12 files with password

#### C. Firebase Console Configuration

**For BOTH Firebase Projects** (hydracattest + myckdapp):

1. **Development Project (hydracattest)**:
   - Go to https://console.firebase.google.com
   - Select **hydracattest** project
   - Click gear icon ⚙️ → **Project Settings**
   - Select **Cloud Messaging** tab
   - Scroll to **Apple app configuration** section

   **If using .p8 key**:
   - Under **APNs Authentication Key**, click **Upload**
   - Upload the .p8 file downloaded earlier
   - Enter **Key ID** (10 characters)
   - Enter **Team ID** (10 characters)
   - Click **Upload**

   **If using .p12 certificates**:
   - Under **APNs Certificates**, upload development .p12
   - Enter password

2. **Production Project (myckdapp)**:
   - Repeat same steps for `myckdapp` project
   - Can use the same .p8 key (one key works for all apps)
   - Or upload production .p12 certificate

#### D. Testing & Verification

1. **Build and Run on Physical Device** (APNs not available on simulator):
   ```bash
   flutter run --flavor development -t lib/main_development.dart
   ```

2. **Check Logs for Success**:
   ```
   [Firebase Dev] iOS foreground notification options configured
   [Firebase Dev] User granted notification permission
   [Firebase Dev] APNs Token obtained: <first 20 chars>...
   [Firebase Dev] FCM Token: <first 20 chars>...
   [Firebase Dev] Firebase Messaging configured successfully
   ```

3. **Verify No Errors**:
   - Should NOT see "APNs Token: null"
   - Should NOT see "FCM Token unavailable"

4. **Test Both Flavors**:
   - Test development: `flutter run --flavor development -t lib/main_development.dart`
   - Test production: `flutter run --flavor production -t lib/main_production.dart`

5. **Test Remote Notifications** (optional, for future):
   - Send test notification from Firebase Console
   - Cloud Messaging → Send test message
   - Enter FCM token from logs
   - Verify notification received on device

#### E. Expected Behavior After Setup

- ✅ APNs token available (non-null)
- ✅ FCM token available
- ✅ No warning/error messages in logs
- ✅ Remote push notifications functional
- ✅ Local notifications still working
- ✅ Step 0.2 fully complete

---

### 2. Enable Apple Sign-In Authentication

**Status**: Not implemented - requires Apple Developer account

**Current State**:
- ✅ Package installed: `sign_in_with_apple: ^6.1.4`
- ✅ Code infrastructure ready in authentication feature
- ❌ Apple Sign-In capability not enabled
- ❌ Service ID not configured
- ❌ Feature disabled/hidden in UI

**What to Do Once Enrolled**:

#### A. Xcode Configuration

1. **Add Sign In with Apple Capability**:
   - Open `ios/Runner.xcworkspace` in Xcode
   - Select Runner project → Runner target
   - Signing & Capabilities tab
   - Click **+ Capability**
   - Add **"Sign In with Apple"**

#### B. Apple Developer Portal Configuration

1. **Enable App ID Capability**:
   - Go to https://developer.apple.com/account
   - Certificates, Identifiers & Profiles → **Identifiers**
   - Select your App ID (`com.example.hydracat` and `com.example.hydracatTest`)
   - Check **Sign In with Apple**
   - Click **Edit** to configure
   - Choose "Enable as a primary App ID"
   - Click **Save**

2. **Create Service ID** (for web/Android support):
   - Identifiers → Click **+**
   - Select **Services IDs**, click **Continue**
   - Description: "HydraCat Sign In with Apple"
   - Identifier: `com.example.hydracat.signin` (reverse domain format)
   - Click **Continue**, then **Register**

   - Click on the Service ID you just created
   - Check **Sign In with Apple**
   - Click **Configure**:
     - Primary App ID: Select your app's bundle ID
     - Domains and Subdomains: Add your domains (if web app)
     - Return URLs: Add OAuth redirect URLs (if web app)
   - Click **Save**, then **Continue**, then **Save**

#### C. Firebase Console Configuration

1. **Enable Apple Sign-In Provider**:
   - Firebase Console → Authentication → Sign-in method
   - Click **Apple**
   - Toggle **Enable**
   - Enter Service ID (if using): `com.example.hydracat.signin`
   - Upload OAuth code flow configuration (if needed for web)
   - Click **Save**

2. **Do for both projects**:
   - Repeat for `hydracattest` (development)
   - Repeat for `myckdapp` (production)

#### D. Code Implementation

**Files to modify**:
- `lib/features/auth/services/auth_service.dart`
- `lib/features/auth/screens/auth_screen.dart`

**Implementation**:

1. **Add Apple Sign-In Method**:
   ```dart
   // In auth_service.dart
   Future<User?> signInWithApple() async {
     try {
       final appleCredential = await SignInWithApple.getAppleIDCredential(
         scopes: [
           AppleIDAuthorizationScopes.email,
           AppleIDAuthorizationScopes.fullName,
         ],
       );

       final oauthCredential = OAuthProvider("apple.com").credential(
         idToken: appleCredential.identityToken,
         accessToken: appleCredential.authorizationCode,
       );

       final userCredential = await _auth.signInWithCredential(oauthCredential);
       return userCredential.user;
     } catch (e) {
       // Handle errors
       rethrow;
     }
   }
   ```

2. **Add Apple Sign-In Button to UI**:
   ```dart
   // In auth_screen.dart
   SignInWithAppleButton(
     onPressed: () async {
       await ref.read(authServiceProvider).signInWithApple();
     },
   )
   ```

3. **Platform Check**:
   - Only show Apple Sign-In button on iOS 13+ and macOS
   - Use `Platform.isIOS` and check iOS version if needed

#### E. Testing

1. **Build and Run**:
   ```bash
   flutter run --flavor development -t lib/main_development.dart
   ```

2. **Test Sign-In Flow**:
   - Tap "Sign In with Apple" button
   - Authenticate with Face ID/Touch ID/Password
   - Verify user created in Firebase Authentication
   - Verify email/name populated correctly

3. **Test on Physical Device**:
   - Simulator may show limited functionality
   - Test on real iPhone for full experience

4. **Test Both Flavors**:
   - Development and Production configurations

---

### Summary Checklist

**When you enroll in Apple Developer Program, complete in this order**:

- [ ] **1. Xcode Setup**
  - [ ] Sign in with Developer account
  - [ ] Change Team from Personal to Developer Team
  - [ ] Add Push Notifications capability
  - [ ] Add Sign In with Apple capability

- [ ] **2. Apple Developer Portal**
  - [ ] Create APNs Authentication Key (.p8) and note Key ID + Team ID
  - [ ] Enable Sign In with Apple for App IDs
  - [ ] Create Service ID for Sign In with Apple

- [ ] **3. Firebase Console - Development (hydracattest)**
  - [ ] Upload APNs key to Cloud Messaging
  - [ ] Enable Apple Sign-In provider in Authentication

- [ ] **4. Firebase Console - Production (myckdapp)**
  - [ ] Upload APNs key to Cloud Messaging
  - [ ] Enable Apple Sign-In provider in Authentication

- [ ] **5. Code Updates**
  - [ ] Implement `signInWithApple()` method in AuthService
  - [ ] Add Apple Sign-In button to AuthScreen
  - [ ] Add platform checks (iOS 13+)

- [ ] **6. Testing**
  - [ ] Test APNs token appears in logs (physical device)
  - [ ] Test FCM token appears in logs
  - [ ] Test Apple Sign-In flow (physical device)
  - [ ] Test both development and production flavors
  - [ ] Verify no errors in Firebase Console

- [ ] **7. Documentation**
  - [ ] Update CLAUDE.md with Apple Sign-In usage
  - [ ] Mark Step 0.2 as fully complete in reminder_plan.md
  - [ ] Update auth_implementation_plan.md with Apple Sign-In completion

---

### Cost & Timeline

- **Apple Developer Program**: $99/year (required for both features)
- **Setup Time**: 1-2 hours (one-time setup)
- **Testing Time**: 30 minutes per feature
- **Maintenance**: Certificates renew automatically with .p8 keys

### Important Notes

1. **APNs Keys vs Certificates**:
   - **Keys (.p8)**: Recommended, never expire, one key for all apps
   - **Certificates (.p12)**: Expire annually, need separate dev/prod certs

2. **Simulator Limitations**:
   - APNs tokens NOT available on iOS Simulator
   - Apple Sign-In works on Simulator but limited
   - Always test on physical device for production validation

3. **Bundle IDs**:
   - Development: `com.example.hydracatTest` (hydracattest Firebase project)
   - Production: `com.example.hydracat` (myckdapp Firebase project)

4. **Security**:
   - Store .p8 key securely (cannot be re-downloaded)
   - Add to .gitignore if storing locally
   - Consider using CI/CD secrets for production builds

5. **Firebase Projects**:
   - Both projects need APNs configuration
   - Both projects need Apple Sign-In enabled
   - Use same .p8 key for both (Team ID is the same)


