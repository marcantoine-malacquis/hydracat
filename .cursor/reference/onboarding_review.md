## Onboarding Feature Review Log

Date: 2025-09-29

### 1) Inventory and Architecture Map
- Directories: `lib/features/onboarding/{models,services,widgets,screens,exceptions}`
- Key files:
  - Models: `onboarding_data.dart`, `onboarding_progress.dart`, `onboarding_step.dart`, `treatment_data.dart`
  - Service: `onboarding_service.dart`
  - Screens: `welcome_screen.dart`, `user_persona_screen.dart`, `pet_basics_screen.dart`, `ckd_medical_info_screen.dart`, `treatment_setup_screen.dart`, `treatment_fluid_screen.dart`, `treatment_medication_screen.dart`, `add_medication_screen.dart`, `onboarding_completion_screen.dart`
  - Widgets: `onboarding_screen_wrapper.dart`, `onboarding_progress_indicator.dart`, `time_picker_group.dart`, `rotating_wheel_picker.dart`, `gender_selector.dart`, `iris_stage_selector.dart`, `lab_values_input.dart`, `medication_summary_card.dart`, `persona_selection_card.dart`, `treatment_popup_wrapper.dart`, `weight_unit_selector.dart`
  - Exceptions: `onboarding_exceptions.dart`

Assessment:
- Architecture follows feature-first structure; models are immutable with JSON support; service orchestrates flow, analytics, and integration with `PetService`/`ScheduleService`.

### 2) Duplicate Patterns / Inconsistencies
- Time selection: two paradigms present
  - Custom wheel-based `TimePicker` via `CupertinoPicker` (`rotating_wheel_picker.dart` + `time_picker_group.dart`).
  - Platform dialog `showTimePicker` in `CompactTimePicker` (`time_picker_group.dart`).
  - Recommendation: Standardize on a single UX. Prefer `showTimePicker` for platform consistency unless the wheel is a deliberate brand requirement; then remove dialog variants for coherence.
- Default reminder times:
  - `TimePickerGroup` provides defaults by frequency (8:00/14:00/20:00 etc.).
  - `FluidTherapyData.toSchedule()` hardcodes 09:00.
  - `AddMedicationScreen._generateDefaultTimes()` duplicates a similar default-time map.
  - Recommendation: Centralize default time generation (e.g., `core/utils/date_utils.dart`) to avoid drift.

### 3) Built-in vs Custom
- `RotatingWheelPicker<T>` wraps `CupertinoPicker` with minimal added value.
  - If kept for styling consistency, limit usage to where truly needed; otherwise replace with direct `CupertinoPicker` or standard material/`showTimePicker` dialog.
- `OnboardingScreenWrapper` provides consistent layout + analytics; appropriate custom wrapper.

Fix/Optimization suggestions:
- Prefer platform `showTimePicker` for time selection to align with user expectations and reduce maintenance. If you want the wheel aesthetic, use `CupertinoPicker` directly and drop the extra wrapper.
- If keeping `RotatingWheelPicker`, add an optional `IndexedWidgetBuilder itemBuilder` to render custom rows and remove the separate `PickerItem` class.
- Avoid duplicating date/time defaults in multiple places; extract to `core/utils/date_utils.dart`.

### 4) Firebase CRUD Rules Compliance
- Onboarding uses local `SecurePreferencesService` for checkpoints; Firestore writes deferred to `PetService`/`ScheduleService` at completion.
- Multiple medication schedules are created sequentially in `OnboardingService.completeOnboarding()` using `ScheduleService.createSchedule()`.
  - Recommendation: Add a batch API to `ScheduleService` (e.g., `createSchedulesBatch`) using `WriteBatch` to create multiple docs and set their IDs in one round trip. This aligns with firebase_CRUDrules (batch operations) and reduces writes/latency.
- In `ScheduleService.createSchedule()`, document is created via `.add()` then updated to set its own `id`, resulting in two writes.
  - Recommendation: Generate an ID client-side (`docRef = collection.doc()`), `set({...,'id': docRef.id})` in a single write to avoid the extra update.
- Timestamp usage is inconsistent: create uses client `DateTime.now()` in schedule maps; updates use `FieldValue.serverTimestamp()`.
  - Recommendation: Standardize on server timestamps for `createdAt`/`updatedAt` to ensure consistency across devices/timezones.
- No real-time listeners in onboarding; compliant. If any onboarding previews add listeners in future, restrict to most recent docs and `.limit()` results.

### 5) PRD Alignment
- Step flow matches PRD: welcome → persona → basics → medical → treatment → completion.
- Optional/required logic appears aligned: medical info optional in fluid-only; treatment gating consistent with personas.
- Fluid specialization beyond setup is out-of-scope here (Phase 1), consistent with PRD.

Fix/Optimization suggestions:
- Ensure the treatment approach prompt explicitly follows PRD wording and maps directly to `UserPersona` values.
- In `onboarding_completion_screen.dart`, route users to the most relevant next surface based on persona (fluids → fluid schedule overview; meds → medication list) to reinforce PRD onboarding goals.
- Add optional, privacy-safe analytics for step retries or backtracks to support the PRD goal of reducing caregiver stress (aggregate only, no PII).

### 6) Core vs Feature Boundaries
- Exceptions are feature-scoped.
- Wrapper/visual components reuse tokens from `core/theme` and `core/constants`; good separation.
- Potential shared schedule DTOs could live in `shared`/`core` to avoid divergent map structures between medication and fluid schedule builders.

Fix/Optimization suggestions:
- Move default reminder time generation to `core/utils/date_utils.dart` as a single helper (e.g., `generateDefaultReminderTimes(TreatmentFrequency)`) and reuse in `TimePickerGroup`, `AddMedicationScreen`, and `FluidTherapyData.toSchedule()`.
- Introduce a shared `ScheduleDto` in `shared/models/` or `core/models/` with factory helpers for `medication` and `fluid` to enforce a consistent payload (`id`, `treatmentType`, `reminderTimes`, timestamps). Update `ScheduleService` and onboarding schedule builders to use it.
- Keep `rotating_wheel_picker.dart` inside onboarding if it is strictly used by onboarding; if adopted elsewhere, relocate to `shared/widgets/inputs/` and add an optional `itemBuilder` to avoid the `PickerItem` helper.
- Ensure strings shown across onboarding screens (labels like “Reminder Times”, “Administration Frequency”) come from `core/constants/app_strings.dart` to centralize copy.

### 7) Industry Standards / Code Quality
- Strong immutability, `copyWith`, typed enums, and clear validation.
- Consistent Result types (`OnboardingResult`) mirroring Auth.
- Consider unifying more navigation/analytics via a single source of truth if screens reimplement similar patterns (to be validated as we scan screens).

### 8) State Management Patterns
- Provider design: `onboardingProvider` exposes a focused `OnboardingState` and optimized `select`-based read-only providers (`onboardingDataProvider`, `currentOnboardingStepProvider`, etc.). This is efficient and idiomatic Riverpod.
- Service orchestration: `OnboardingNotifier` delegates to `OnboardingService` and mirrors result types; consistent with Auth pattern.
- Progress stream: `OnboardingService.progressStream` feeds notifier; state flags (`isActive`, `isLoading`, `error`) are clear.

Fix/Optimization suggestions:
- Centralize analytics triggers: screens use `OnboardingScreenWrapper` timing, while `OnboardingService` tracks step events. Prefer one source of truth (service) for step analytics; wrapper should report only generic screen view unless you wire it to `OnboardingStep.analyticsEventName`.
- Expose a single `goNext()` helper in notifier that validates via service and returns navigation target (route), reducing per-screen navigation logic duplication.
- Consider de-duplicating default time logic by providing it from a provider (wrapping the `date_utils` helper) for testability.

### 9) Routing Coherence
- Router guards: `lib/app/router.dart` correctly redirects unauthenticated users, enforces email verification, and routes to onboarding for verified users that haven't completed and haven't skipped.
- Onboarding screens navigate to completion via `context.go('/onboarding/completion')`; alignment with router’s `/onboarding/*` paths.

Fix/Optimization suggestions:
- Use `OnboardingStep.routeName` (or remove it) to drive navigation routes from a single enum source; add a small mapper if needed.
- After completion, ensure router redirects away from `/onboarding/*` (already present), and that `authProvider.markOnboardingComplete` updates flags used by router. Consider debouncing redirect logs in debug.
- Add a helper in notifier: `navigateToCurrentStep(BuildContext)` to centralize step-to-route mapping.

### 11) Exceptions and Result Patterns
- Consistent `OnboardingResult` (Success/Failure) mirrors Auth. Exceptions in `onboarding_exceptions.dart` are specific and user-friendly.

Fix/Optimization suggestions:
- Surface validation errors: when `OnboardingValidationException` occurs from `updateData`, display `detailedMessage` in screens that handle form submissions.
- Ensure `OnboardingService` never throws raw exceptions outward (already caught); keep failures mapped to `OnboardingFailure`.
- Consider adding a lightweight `Result<T, E>` generic in `core` if multiple features replicate the Success/Failure pattern, to avoid duplicate sealed classes.

### 12) UI/UX Adherence
- Uses `core/theme` tokens and `HydraButton`. `OnboardingScreenWrapper` applies consistent layout and progress.

Fix/Optimization suggestions:
- Centralize strings to `core/constants/app_strings.dart` for: “Reminder Times”, “Administration Frequency”, “Set Dosage”, etc.
- Verify touch targets for chips and pickers meet 44px minimum; increase padding where needed (e.g., gauge chips).
- Ensure contrast for subdued texts uses tokens that meet 4.5:1; avoid low alpha values for critical info.

### 13) Dependency Audit (Onboarding Scope)
- Uses Flutter Material/Cupertino, Firebase core libs, Riverpod; no extra onboarding-only packages detected.

Fix/Optimization suggestions:
- None required; prefer built-ins as already suggested (time picker, CupertinoPicker direct use).

### 14) Testing Gaps and Coverage Plan
- Existing integration tests target auth; onboarding lacks dedicated tests.

Recommendations:
- Widget tests: for `AddMedicationScreen` steps (validation, time generation), `TreatmentFluidScreen` validation and state updates, and `OnboardingScreenWrapper` analytics timing hook (mock provider).
- Provider tests: `OnboardingNotifier` happy/error paths for `start`, `resume`, `updateData`, step transitions, and `completeOnboarding` with mocked `PetService`/`ScheduleService`.
- Golden tests: key onboarding screens to lock layout and progress header.

### 15) Prioritized Change List (Quick Wins → Higher Effort)
1. Standardize time picker approach across onboarding; remove the alternative.
2. Extract default reminder time helper to `core/utils/date_utils.dart`; update all call sites.
3. Remove `PickerItem` or add `itemBuilder` to `RotatingWheelPicker` and delete `PickerItem`.
4. Switch `ScheduleService.createSchedule()` to single-write `doc().set({...,'id': id})`.
5. Add `createSchedulesBatch` using `WriteBatch` and use in onboarding completion for medications.
6. Standardize timestamps to server timestamps for schedules.
7. Centralize strings into `app_strings.dart` for onboarding labels.
8. Wire or remove `OnboardingStep.routeName`/`analyticsEventName`; consider notifier helper for step routing.
9. Add targeted widget/provider tests as outlined.
### 10) Potential Dead Code / Unused APIs (to verify)
- `PickerItem` in `rotating_wheel_picker.dart` is not referenced outside its file and not used by the pickers.
- `OnboardingStep.analyticsEventName` and `routeName` getters are not referenced elsewhere.

Fix/Optimization suggestions:
- Remove `PickerItem` if no immediate plan to adopt it for custom items. If you want stylized entries, refactor `RotatingWheelPicker` to accept an optional `itemBuilder` and delete `PickerItem`.
- Either remove `analyticsEventName`/`routeName` getters from `OnboardingStep` or wire them:
  - Wire: use `routeName` in router/navigation helpers; use `analyticsEventName` in `OnboardingScreenWrapper._trackScreenView()` so events are sourced from the enum. Otherwise, delete to reduce API surface.

### 11) Action Items (Running List)
- Decide on a single time-picking approach; remove the other or gate by platform.
- Extract default reminder time generation to `core/utils/date_utils.dart` and reuse.
- Review `ScheduleService` for batching and align schedule payload shapes via a common DTO.
- Verify and remove unused `PickerItem` if not used.
- Verify usages of `OnboardingStep.analyticsEventName`/`routeName`; remove if dead or wire into router/analytics if intended.

— End of current findings snapshot —


