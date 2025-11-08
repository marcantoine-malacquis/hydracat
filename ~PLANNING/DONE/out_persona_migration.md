# Migration Plan: Remove Persona System

## Executive Summary

**Goal**: Remove the `UserPersona` enum system and replace persona-based conditionals with data-existence checks throughout the app.

**Rationale**: 
- Simplifies codebase by removing ~10-15 conditional checks
- Makes treatment evolution seamless (medication → fluids, or adding second treatment type)
- Reduces onboarding friction
- Aligns with "Progressive Caregiver" user type mentioned in PRD (line 33)
- Uses actual behavioral data instead of declared intent

**Scope**: 14 files with `treatmentApproach` references + related validation/routing logic

**Firebase Cost Impact**: ✅ POSITIVE - No additional reads/writes; actually removes one field from writes

**Backward Compatibility**: ❌ NOT NEEDED - Database will be reset for testing

---

## Quick Reference: New User Flow

```
BEFORE (7 screens):
Welcome → Pet Basics → [Persona Selection] → CKD Info → [Medication Setup] → [Fluid Setup] → Completion

AFTER (4 screens):
Welcome → Pet Basics → CKD Info → Completion Screen
                                        ↓
                                  [Finish Button]
                            (validates & saves to Firestore)
                                        ↓
                                   HOME SCREEN
                                        ↓
                              [Empty State Discovery]
                                   [SelectionCards]
                                   /              \
                      Track Medications      Track Fluid Therapy
                             ↓                      ↓
              /profile/medication        /profile/fluid/create
              (existing screen)         (moved from onboarding)
```

**Key UX Decision**: Completion screen stays simple and final (no SelectionCards).
Feature discovery happens naturally on home screen after onboarding completes.

---

## Final Implementation Strategy (2025-01-09)

### Key Decisions:
1. **Onboarding Flow**: Remove treatment setup entirely → Welcome → Pet Basics → CKD Info → Completion (stays simple)
2. **Code Reuse**: Move `treatment_fluid_screen.dart` to profile feature as `create_fluid_schedule_screen.dart`
3. **Generic Widget**: Extract `PersonaSelectionCard` → generic `SelectionCard` for reuse across app
4. **Feature Discovery**: Home screen shows SelectionCard CTAs when no schedules exist → navigate to creation screens
5. **Screen Separation**: Clean create vs edit screen pattern
6. **Completion Logic**: Keep existing "Finish" button functionality (validation + Firestore save + navigate home)

### What Gets Deleted:
- `user_persona.dart` (enum)
- `user_persona_screen.dart` (selection screen)
- `persona_selection_card.dart` (replaced by generic SelectionCard)
- `treatment_medication_screen.dart` (redundant with profile screen)

### What Gets Moved:
- `treatment_fluid_screen.dart` → `profile/screens/create_fluid_schedule_screen.dart` (refactored)

### What Gets Created:
- `shared/widgets/selection_card.dart` (generic widget)
- `shared/widgets/dialogs/no_schedules_dialog.dart` (FAB empty state)

### What Gets Kept:
- `medication_schedule_screen.dart` (already handles empty state)
- `add_medication_screen.dart` (reusable modal)
- `treatment_choice.dart` (for users with both schedules)

### Benefits:
- ✅ 4 screen onboarding instead of 7 (43% faster)
- ✅ Maximum code reuse (90% of treatment screens reused)
- ✅ Clean create/edit separation
- ✅ Consistent SelectionCard pattern throughout app
- ✅ Progressive feature discovery via empty states
- ✅ Completion screen stays simple and final (no breaking changes to critical logic)

### Progress System Impact:
**Current**: `OnboardingStepType.totalSteps` calculated from enum length (7 steps)
**After**: Enum shrinks from 7 to 4 values, `totalSteps` auto-updates to 4
**Progress indicators**: Will automatically show "Step X of 4" correctly
**No manual changes needed**: Progress calculation is dynamic based on enum

```dart
// Before:
welcome (0/7) → userPersona (1/7) → petBasics (2/7) → ckdInfo (3/7) 
→ treatmentMed (4/7) → treatmentFluid (5/7) → completion (6/7)

// After:
welcome (0/4) → petBasics (1/4) → ckdInfo (2/4) → completion (3/4)
```

✅ **No progress bar issues** - updates automatically when enum is modified

### UX Rationale: Why Completion Screen Stays Simple

**Problem with adding SelectionCards to completion screen**:
1. ❌ Breaks the "completion" feeling - user thinks there's more to do
2. ❌ User hasn't seen home screen yet, still feels like onboarding
3. ❌ Confusing: "I clicked Finish but there's more setup?"
4. ❌ Risks breaking existing critical logic (validation, Firestore save, navigation)

**Better approach - Home screen discovery**:
1. ✅ Onboarding feels truly complete when "Finish" is clicked
2. ✅ User arrives at home screen, sees clean empty state
3. ✅ Natural moment to discover features: "Now what can I do?"
4. ✅ No pressure - user can explore app or set up schedules
5. ✅ Preserves completion screen's existing robust logic

**User mental model**:
```
Onboarding = Setup my cat's profile ✅
    ↓
[Finish] = Complete setup, save everything ✅
    ↓
Home Screen = Discover what I can do with the app ✅
    ↓
[Add first treatment] = Start using features ✅
```

This creates clear mental checkpoints and natural feature discovery.

---

## Phase 1: Analysis & Preparation

### Step 1.1: Document Current Persona Usage ✅
**Files affected**: 14 files (already identified via grep)

Current persona logic locations:
1. `lib/features/profile/models/user_persona.dart` - Enum definition
2. `lib/features/profile/models/cat_profile.dart` - treatmentApproach field
3. `lib/features/onboarding/screens/user_persona_screen.dart` - Selection screen
4. `lib/features/onboarding/widgets/persona_selection_card.dart` - UI component
5. `lib/features/onboarding/models/onboarding_data.dart` - Onboarding data model
6. `lib/features/onboarding/services/onboarding_service.dart` - Schedule creation logic
7. `lib/features/onboarding/services/onboarding_validation_service.dart` - Validation logic
8. `lib/features/profile/screens/profile_screen.dart` - Conditional sections
9. `lib/app/app_shell.dart` - FAB routing logic
10. `lib/features/logging/models/treatment_choice.dart` - Treatment selection (keep this)
11. `lib/providers/analytics_provider.dart` - Analytics tracking
12. Planning docs and tests

**Key methods to replace**:
- `includesMedication` → check `hasMedicationSchedules`
- `includesFluidTherapy` → check `hasFluidSchedule`
- `treatmentApproach` field → remove entirely

### Step 1.2: Identify Data Sources for Replacement Logic
**Existing providers with data-existence checks** (no new code needed):

From `lib/providers/profile_provider.dart` (lines 120-134):
```dart
bool get hasFluidSchedule => fluidSchedule != null;
bool get hasMedicationSchedules => 
    medicationSchedules != null && medicationSchedules!.isNotEmpty;
int get medicationScheduleCount => medicationSchedules?.length ?? 0;
```

✅ These already exist and are cached in ProfileState - zero Firebase cost

### Step 1.3: Review PRD Alignment
**PRD User Personas (lines 28-33)** are about understanding target markets, NOT technical constraints:
- "Fluid Therapy Specialist" ✅ Can still serve - show fluid features when schedule exists
- "Medication Manager" ✅ Can still serve - show medication features when schedules exist
- "Progressive Caregiver" ✅ **BETTER SERVED** - seamless transition from medication to fluids

**PRD Onboarding Flow (lines 59-79)**: Currently prescriptive, we'll make flexible:
- Current: "If Fluid Therapy = Yes" → show fluid setup
- New: Show both fluid and medication setup screens, make both skippable
- User chooses what to set up by actually setting it up (or skipping)

**PRD Home Screen (lines 89-98)**: Already describes data-based adaptation:
- "Adaptive Content Based on Treatment Type" ✅ We'll just use actual data for adaptation

✅ **No PRD conflicts** - Migration actually better aligns with "Progressive Caregiver" persona

### Step 1.4: Review Firebase CRUD Rules Alignment
**Current persona system**:
- Writes `treatmentApproach` field on every pet document write
- Uses it for validation (zero reads - good)
- Stored in memory after initial pet load (good)

**After migration**:
- Remove `treatmentApproach` field → **SAVES 1 write per pet update**
- Check schedules in memory via ProfileState → **ZERO additional reads**
- Schedules already cached (lines 75-79 of profile_provider.dart)

✅ **Firebase cost impact: POSITIVE** - One less field to write, no additional reads

---

## Phase 2: Code Migration Strategy

### Step 2.1: Update Data Models

#### 2.1.1 Remove UserPersona enum
**File**: `lib/features/profile/models/user_persona.dart`
**Action**: DELETE entire file

#### 2.1.2 Remove treatmentApproach from CatProfile
**File**: `lib/features/profile/models/cat_profile.dart`
**Changes**:
- Remove `treatmentApproach` field (line 15, 65)
- Remove from constructor (line 15)
- Remove from `fromJson` (lines 35-37)
- Remove from `toJson` (line 106)
- Remove from `copyWith` (lines 122, 136)
- Remove from `==` operator (line 213)
- Remove from `hashCode` (line 230)
- Remove from `toString` (line 248)

**ProfileState getter removal**:
- Remove `treatmentApproach` getter from ProfileState (line 118 in profile_provider.dart)

#### 2.1.3 Update OnboardingData model
**File**: `lib/features/onboarding/models/onboarding_data.dart`
**Changes**:
- Remove `treatmentApproach` field
- Remove from constructor
- Remove from `fromJson`/`toJson`
- Remove from `copyWith`
- Update `isComplete()` validation (lines 247-260) → remove persona-based requirements
- Update `getMissingFields()` (line 619-625) → remove persona checks

**New logic**: 
```dart
// Allow both to be empty - user can skip and add later
bool get isComplete =>
    petBasics != null &&
    petBasics!.isComplete;

List<String> getMissingFields() {
  final missing = <String>[];
  if (petBasics == null || !petBasics!.isComplete) {
    missing.add('Pet basic information');
  }
  // Medication and fluid therapy are now optional
  return missing;
}
```

### Step 2.2: Update Onboarding Flow

#### 2.2.1 Remove UserPersona selection screen and create generic SelectionCard
**Files to modify**:
- `lib/features/onboarding/screens/user_persona_screen.dart` → DELETE
- `lib/features/onboarding/widgets/persona_selection_card.dart` → EXTRACT to generic widget
- `lib/features/onboarding/models/onboarding_step.dart` → Remove `userPersona` step from enum

**New widget to create**:
- `lib/shared/widgets/selection_card.dart` → Extract animation/styling from PersonaSelectionCard
  - Keep: 3D press effects, loading overlay, square/rectangle layouts
  - Remove: Persona-specific logic
  - Make generic: Accept IconData, title, subtitle, onTap

**Router changes**:
- `lib/app/router.dart` → Remove route for `/onboarding/user-persona`

#### 2.2.2 Update onboarding step flow
**File**: `lib/features/onboarding/models/onboarding_step.dart`

**Current flow**:
1. Welcome
2. Pet Basics
3. **User Persona** ← REMOVE
4. CKD Medical Info
5. Treatment Medication (conditional) ← MOVE to profile feature
6. Treatment Fluid (conditional) ← MOVE to profile feature
7. Completion

**New flow** (FINAL DECISION):
1. Welcome
2. Pet Basics
3. CKD Medical Info
4. Completion (stays simple and final)

**Completion Screen** (NO CHANGES NEEDED):
- ✅ Keep existing celebratory message and "Finish" button
- ✅ Keep existing validation and Firestore save logic
- ✅ Navigates to home screen on success
- ❌ DO NOT add SelectionCards here (breaks "completion" feeling)

**Home Screen Empty State** (NEW):
- Shows SelectionCard widgets when no schedules exist
- Natural feature discovery after onboarding completes
- User can explore app first or set up schedules immediately

#### 2.2.3 Move treatment setup screens to profile feature (FINAL DECISION)
**Strategy**: Reuse onboarding screens by moving them to profile feature for clean create/edit separation

**Files to MOVE and REFACTOR**:

1. **Medication Creation** (already exists in profile):
   - ✅ `lib/features/profile/screens/medication_schedule_screen.dart` - Already handles empty state
   - ✅ `lib/features/onboarding/screens/add_medication_screen.dart` - Keep as is (already reusable)
   - ❌ `lib/features/onboarding/screens/treatment_medication_screen.dart` - DELETE (not needed)

2. **Fluid Therapy Creation** (needs to be moved):
   - **MOVE**: `lib/features/onboarding/screens/treatment_fluid_screen.dart`
   - **TO**: `lib/features/profile/screens/create_fluid_schedule_screen.dart`
   - **Refactor**: Remove OnboardingScreenWrapper, use standard Scaffold
   - **Keep**: All form logic, validation, and save functionality
   - **Result**: Standalone creation screen accessible from anywhere

**Benefits of this approach**:
- ✅ Maximum code reuse (onboarding screens already work)
- ✅ Clean separation: create screens vs edit screens
- ✅ Consistent pattern for both treatment types
- ✅ Can be called from completion screen, FAB dialog, or home screen CTAs
- ✅ Less refactoring needed

#### 2.2.4 Simplify OnboardingService (schedules now created outside onboarding)
**File**: `lib/features/onboarding/services/onboarding_service.dart`

**Changes needed**:
- Remove medication schedule creation logic (now happens in profile feature)
- Remove fluid schedule creation logic (now happens in profile feature)
- Onboarding only creates pet profile with basic info + CKD data
- Treatment schedules created separately when user visits creation screens

**Rationale**: Since treatment setup moved out of onboarding flow, OnboardingService should only handle:
1. Pet basic information
2. CKD medical information
3. Initial profile creation

Schedules are created when user taps SelectionCards on completion screen or adds them later from home/profile.

#### 2.2.5 Simplify onboarding validation (remove treatment validation)
**File**: `lib/features/onboarding/services/onboarding_validation_service.dart`

**Remove all persona-based treatment validation**:
```dart
// DELETE: Persona checks for medications
if (persona?.includesMedication ?? false) {
  if (data.medications == null || data.medications!.isEmpty) {
    errors.add(...);
  }
}

// DELETE: Persona checks for fluid therapy
if (persona?.includesFluidTherapy ?? false) {
  if (data.fluidTherapy == null) {
    errors.add(...);
  }
}
```

**New validation logic**: Only validate pet basics and CKD info are complete
- Medication and fluid data removed from OnboardingData model
- Validation becomes much simpler
- No treatment-related validation in onboarding

### Step 2.3: Update FAB Logic

#### 2.3.1 Replace persona-based routing with schedule-based routing
**File**: `lib/app/app_shell.dart` (lines 154-198)

**Current logic**:
```dart
switch (treatmentApproach) {
  case UserPersona.medicationOnly:
    _showLoggingDialog(context, const MedicationLoggingScreen());
  case UserPersona.fluidTherapyOnly:
    _showLoggingDialog(context, const FluidLoggingScreen());
  case UserPersona.medicationAndFluidTherapy:
    // Show choice popup
}
```

**New logic**:
```dart
// Get schedule data from ProfileState (already cached - zero reads)
final profileState = ref.read(profileProvider);
final hasFluid = profileState.hasFluidSchedule;
final hasMedication = profileState.hasMedicationSchedules;

// Route based on actual data
if (hasFluid && hasMedication) {
  // Both exist - show choice popup
  _showLoggingDialog(context, TreatmentChoicePopup(...));
} else if (hasFluid) {
  // Only fluid - go direct
  _showLoggingDialog(context, const FluidLoggingScreen());
} else if (hasMedication) {
  // Only medication - go direct
  _showLoggingDialog(context, const MedicationLoggingScreen());
} else {
  // No schedules yet - show onboarding CTA or choice popup
  _showNoSchedulesDialog(context);
}
```

#### 2.3.2 Create "No Schedules" dialog
**New widget**: `lib/shared/widgets/dialogs/no_schedules_dialog.dart`

Shows when user taps FAB but has no schedules set up yet:
```dart
"Get Started"
- SelectionCard: "Set up medication tracking" 
  → navigate to /profile/medication (existing screen with empty state)
- SelectionCard: "Set up fluid therapy tracking" 
  → navigate to /profile/fluid/create (moved creation screen)
- TextButton: "I'll do this later" → dismiss
```

**Note**: Reuse the generic SelectionCard widget created from PersonaSelectionCard

### Step 2.4: Update Quick-Log Logic

**File**: `lib/app/app_shell.dart` (line 253-255)

Quick-log already uses actual schedule data (via `canQuickLogProvider`), but verify it doesn't check persona.

**File**: `lib/providers/logging_provider.dart` - search for persona references and remove.

The quick-log should just:
1. Get all schedules (fluid + medication) from ProfileState
2. Log each one that exists and hasn't been logged today
3. No persona checks needed

### Step 2.5: Update Profile Screen

#### 2.5.1 Replace persona checks with data checks
**File**: `lib/features/profile/screens/profile_screen.dart` (lines 715-730)

**Current**:
```dart
if (primaryPet?.treatmentApproach.includesFluidTherapy ?? false) {
  ProfileNavigationTile(title: "$petName's Fluid Schedule", ...);
}

if (primaryPet?.treatmentApproach.includesMedication ?? false) {
  ProfileNavigationTile(title: "$petName's Medication Schedule", ...);
}
```

**New**:
```dart
final profileState = ref.watch(profileProvider);

if (profileState.hasFluidSchedule) {
  ProfileNavigationTile(title: "$petName's Fluid Schedule", ...);
}

if (profileState.hasMedicationSchedules) {
  ProfileNavigationTile(title: "$petName's Medication Schedule", ...);
}
```

✅ Zero additional Firebase reads - ProfileState already cached

#### 2.5.2 Add "Add Treatment" buttons for missing schedules
If no fluid schedule:
```dart
if (!profileState.hasFluidSchedule) {
  ProfileActionButton(
    title: "Set up fluid therapy tracking",
    icon: AppIcons.fluidTherapy,
    onTap: () => context.push('/profile/fluid/create'), // Navigate to creation screen
  );
}
```

If no medication schedules:
```dart
if (!profileState.hasMedicationSchedules) {
  ProfileActionButton(
    title: "Set up medication tracking",
    icon: AppIcons.medication,
    onTap: () => context.push('/profile/medication'), // Existing screen handles empty state
  );
}
```

### Step 2.6: Update Home Screen Empty States

**File**: `lib/features/home/screens/home_screen.dart`

Add progressive disclosure widgets using the new generic SelectionCard:

**If no schedules at all**:
```dart
EmptyStateWidget(
  title: "Let's get started!",
  subtitle: "Set up your treatment tracking",
  children: [
    SelectionCard(
      icon: Icons.medication_outlined,
      title: "Track Medications",
      subtitle: "Set up medication schedules",
      layout: CardLayout.rectangle,
      onTap: () => context.push('/profile/medication'),
    ),
    SizedBox(height: AppSpacing.md),
    SelectionCard(
      icon: Icons.water_drop_outlined,
      title: "Track Fluid Therapy",
      subtitle: "Set up subcutaneous fluid tracking",
      layout: CardLayout.rectangle,
      onTap: () => context.push('/profile/fluid/create'),
    ),
  ],
)
```

**If only medication exists**:
- Show medication widgets prominently
- Small CTA: "You can also track fluid therapy →" navigates to `/profile/fluid/create`

**If only fluid exists**:
- Show fluid widgets prominently
- Small CTA: "You can also track medications →" navigates to `/profile/medication`

**If both exist**:
- Show both types of widgets
- No CTAs needed

### Step 2.7: Update Analytics

**File**: `lib/providers/analytics_provider.dart`

**Replace persona tracking with behavioral tracking**:

**Remove**:
```dart
trackEvent('persona_selected', {
  'persona': persona.name,
});
```

**Add**:
```dart
// Track when schedules are created
trackEvent('first_schedule_created', {
  'schedule_type': 'medication' | 'fluid',
  'days_since_signup': daysSinceSignup,
  'schedules_count': totalScheduleCount,
});

// Track treatment patterns over time
trackEvent('treatment_pattern_detected', {
  'has_medication': true/false,
  'has_fluid': true/false,
  'medication_count': count,
  'days_active': daysActive,
});
```

This gives better insights into actual usage vs declared intent.

### Step 2.8: Update Firestore Schema

**File**: `.cursor/rules/firestore_schema.md`

**Remove from pets document**:
```
treatmentApproach: string  // DELETE THIS LINE
```

**Note in schema doc**:
```markdown
## Migration Note (2025-01)
Removed `treatmentApproach` field from pet documents. 
UI now adapts based on existence of schedules (fluidSchedule, medicationSchedules).
```

### Step 2.9: Clean Up Unused Files

**Delete these files**:
1. `lib/features/profile/models/user_persona.dart` - Persona enum no longer needed
2. `lib/features/onboarding/screens/user_persona_screen.dart` - Persona selection removed from flow
3. `lib/features/onboarding/widgets/persona_selection_card.dart` - Replaced by generic SelectionCard
4. `lib/features/onboarding/screens/treatment_medication_screen.dart` - Not needed (medication screen already exists in profile)

**Move these files** (code reuse):
1. `lib/features/onboarding/screens/treatment_fluid_screen.dart` 
   → MOVE TO `lib/features/profile/screens/create_fluid_schedule_screen.dart`
   - Refactor to remove OnboardingScreenWrapper
   - Use standard Scaffold with AppBar
   - Keep all form logic and save functionality

**Keep these files** (still needed):
1. `lib/features/logging/models/treatment_choice.dart` - Used when user with both schedules needs to choose which to log
2. `lib/features/onboarding/screens/add_medication_screen.dart` - Reusable modal for adding/editing medications
3. `lib/features/profile/screens/medication_schedule_screen.dart` - Handles both viewing and creating medications

**Create new files**:
1. `lib/shared/widgets/selection_card.dart` - Generic version extracted from PersonaSelectionCard
2. `lib/shared/widgets/dialogs/no_schedules_dialog.dart` - Dialog when FAB tapped with no schedules

### Step 2.10: Update Tests

**Files to update**:
- `test/features/*/` - Remove persona-related tests
- Update tests to check for schedule existence instead of persona
- Add new tests for progressive disclosure logic

**Test scenarios to add**:
1. User with no schedules → sees CTAs for both
2. User with medication only → sees medication widgets + fluid CTA
3. User with fluid only → sees fluid widgets + medication CTA
4. User with both → sees both widgets, no CTAs
5. FAB routing with different schedule combinations
6. Adding first schedule updates home screen
7. Onboarding completion with/without schedules

---

## Phase 3: Implementation Order (UPDATED WITH FINAL DECISIONS)

### Batch 1: Create Reusable Components (Low Risk)
1. ✅ Create migration plan document (this file)
2. **Create generic SelectionCard widget**
   - Extract from `PersonaSelectionCard`
   - Location: `lib/shared/widgets/selection_card.dart`
   - Keep: animations, loading overlay, layouts
   - Make generic: accept icon, title, subtitle, onTap
3. Run `flutter analyze` on new widget

### Batch 2: Move Treatment Creation Screens (Low Risk)
4. **Move fluid creation screen to profile feature**
   - FROM: `lib/features/onboarding/screens/treatment_fluid_screen.dart`
   - TO: `lib/features/profile/screens/create_fluid_schedule_screen.dart`
   - Refactor: Remove OnboardingScreenWrapper, use Scaffold
   - Keep: All form logic and save functionality
5. **Add route** for `/profile/fluid/create` in router
6. Test fluid creation screen standalone

### Batch 3: Data Models (Low Risk)
7. Remove `UserPersona` enum (`lib/features/profile/models/user_persona.dart`)
8. Update `CatProfile` model (remove `treatmentApproach` field)
9. Update `OnboardingData` model (remove `treatmentApproach`, medications, fluidTherapy)
10. Run `flutter analyze` - fix any immediate type errors

### Batch 4: Onboarding Flow (Medium Risk)
11. Delete user persona screen (`user_persona_screen.dart`)
12. Delete persona selection card widget (`persona_selection_card.dart`)
13. Delete onboarding medication screen (`treatment_medication_screen.dart`)
14. Update `OnboardingStep` enum (remove userPersona, treatmentMedication, treatmentFluid)
15. Update router (remove persona route, add fluid/create route)
16. ✅ **Completion screen stays unchanged** (existing logic preserved)
17. Simplify onboarding service (remove schedule creation)
18. Simplify onboarding validation service (remove treatment validation)
19. Test onboarding flow manually (should be 4 steps with progress showing correctly)

### Batch 5: UI Logic (Medium Risk)
20. Update FAB logic in `app_shell.dart`
21. Create "No Schedules" dialog using SelectionCard
22. Update profile screen sections (remove persona checks, use schedule checks)
23. Add "Add Treatment" buttons to profile for missing schedules
24. Test FAB routing with different schedule states

### Batch 6: Home Screen (CRITICAL - Primary Feature Discovery)
25. **Update home screen empty states with SelectionCard widgets** (main feature discovery point)
26. Add progressive disclosure CTAs for users with only one treatment type
27. Test home screen with different schedule combinations:
    - No schedules → Shows prominent SelectionCard widgets for both options
    - Only medication → Shows medication widgets + subtle fluid CTA
    - Only fluid → Shows fluid widgets + subtle medication CTA
    - Both → Shows both widgets, no CTAs

### Batch 7: Cleanup & Polish (Low Risk)
28. Update analytics tracking (remove persona events, add behavioral events)
29. Update Firestore schema documentation
30. Delete unused files (listed in Step 2.9)
31. Update tests (remove persona tests, add schedule-based tests)
32. Run full `flutter analyze`
33. Manual testing of all flows from Phase 4 checklist

---

## Phase 4: Testing Checklist

### Onboarding Scenarios
- [ ] New user completes onboarding without setting up any schedules
- [ ] New user sets up only medication during onboarding
- [ ] New user sets up only fluid therapy during onboarding
- [ ] New user sets up both during onboarding
- [ ] Can skip all treatment setup screens if implemented

### Home Screen Scenarios
- [ ] User with no schedules sees both CTAs
- [ ] User with medication only sees medication widgets + subtle fluid CTA
- [ ] User with fluid only sees fluid widgets + subtle medication CTA
- [ ] User with both sees both widgets, no CTAs
- [ ] Adding first schedule updates home screen immediately

### FAB Scenarios
- [ ] No schedules → shows "Get Started" dialog with both options
- [ ] Medication only → goes directly to medication logging
- [ ] Fluid only → goes directly to fluid logging
- [ ] Both schedules → shows treatment choice popup
- [ ] Quick-log (long press) works with any combination

### Profile Screen Scenarios
- [ ] Fluid schedule section only shows if schedule exists
- [ ] Medication schedule section only shows if schedules exist
- [ ] "Add fluid therapy" button shows if no fluid schedule
- [ ] "Add medication" button shows if no medication schedules
- [ ] Can add second treatment type after having one

### Progressive Disclosure
- [ ] User can discover features organically
- [ ] CTAs are subtle when user has one treatment type
- [ ] No "wrong choice" or "locked out" feeling
- [ ] Can add/remove treatment types freely

### Analytics
- [ ] First schedule creation tracked with correct type
- [ ] Treatment patterns tracked over time
- [ ] No more persona selection events

---

## Phase 5: Implementation Workflow

Since the app is in early/mid development with no users or production deployment yet, the workflow is straightforward:

### Development Workflow
1. ✅ Review migration plan (this document)
2. Answer the 4 questions at the end of this document
3. Implement all batches sequentially (Batch 1 → Batch 5)
4. Run `flutter analyze` after each batch
5. Fix any linting errors immediately
6. Manual testing after each batch
7. Reset Firebase database once complete (you do this regularly anyway)
8. Full manual testing of all scenarios from Phase 4 checklist
9. Continue with normal development

### Simple Testing Approach
- Test locally after each batch
- No need for staging/production environments yet
- Reset database and test fresh onboarding flow
- Verify all FAB/profile/home screen scenarios work correctly

### Post-Migration
1. Update this document with any learnings or edge cases discovered
2. Note any follow-up improvements needed
3. Continue development with cleaner codebase

---

## Risk Assessment

### Low Risk ✅
- Data model changes (straightforward removal)
- Analytics updates (additive)
- Documentation updates
- Firebase cost reduction

### Medium Risk ⚠️
- Onboarding flow changes (affects first-time user experience)
- FAB routing logic (critical user journey)
- Profile screen sections (frequently used feature)

**Mitigation**: Thorough manual testing, keep treatment choice popup for combined schedules

### High Risk ❌
None identified. No data migration needed, no backward compatibility required.

---

## Success Metrics

### Technical Metrics
- ✅ Zero additional Firebase reads (using cached ProfileState)
- ✅ One less field in pet document writes
- ✅ ~10-15 conditional checks removed
- ✅ 3 files deleted
- ✅ Zero linting errors after migration

### User Experience Metrics
- ⏱️ Faster onboarding completion time (fewer steps)
- 🔍 Better feature discovery (progressive disclosure)
- 🔄 Seamless treatment type transitions
- 📈 Higher percentage of users trying both treatment types over time

### Code Quality Metrics
- 📉 Reduced cyclomatic complexity
- 🧪 Simpler test scenarios
- 📚 More maintainable codebase
- 🔧 Easier to add new treatment types in future

---

## Future Enhancements (Post-Migration)

### Phase 6: Smart Recommendations (Future)
Based on actual usage patterns:
- "We noticed you haven't tracked fluid therapy yet. Many users at IRIS Stage 3 benefit from it."
- "Your medication adherence is great! Consider setting up fluid therapy for additional hydration."

### Phase 7: Treatment Evolution Tracking (Future)
Automatically detect and celebrate milestones:
- "You've been tracking medications for 30 days! 🎉"
- "First fluid therapy session logged - well done!"
- "You're now using both treatment types - comprehensive care!"

### Phase 8: Veterinary Integration (Future)
If adding vet portal:
- Vet prescribes treatment → creates schedule directly
- No persona needed, just creates the schedule
- User sees it in their app, guided through first session

---

## Notes & Considerations

### Why Keep TreatmentChoice Enum?
The `TreatmentChoice` enum is UI-level only (for the popup when user has both schedules). It's not persisted, not part of data model, and serves a clear UX purpose. Keep it.

### Why This Approach is Better
1. **Simpler mental model**: User doesn't need to "declare" what they do - they just do it
2. **Flexible**: Treatment can evolve without changing settings
3. **Discoverable**: Users find features when they need them
4. **Honest data**: Analytics show actual usage, not intent
5. **Less code**: Fewer conditionals, fewer files, simpler logic

### Alignment with PRD
The PRD's "Progressive Caregiver" persona (line 33) explicitly mentions users who "may advance to fluid therapy as disease progresses." The current persona system makes this harder. This migration makes it seamless. ✅

### Firebase Cost Analysis
- **Writes**: -1 field per pet update = cost reduction
- **Reads**: Zero additional reads (using cached ProfileState)
- **Storage**: Negligible reduction (one string field)
- **Net impact**: Slight cost reduction ✅

---

## Design Decisions (FINALIZED)

### Q1: Onboarding Flow ✅ ANSWERED
**Decision**: Remove treatment setup from onboarding entirely
- New flow: Welcome → Pet Basics → CKD Info → Completion (stays simple and final)
- Treatment screens moved to profile feature
- Users set up schedules after onboarding via **home screen empty states**
- Completion screen preserves existing "Finish" logic (validation + save + navigate)
- Faster onboarding, better feature discovery

### Q2: Empty State Strategy ✅ ANSWERED
**Decision**: Two separate SelectionCard widgets (rectangle layout)
- Clear, scannable, equal prominence for both options
- Used on: **Home screen empty state** (primary), FAB "No Schedules" dialog (secondary)
- NOT used on completion screen (stays simple and final)
- Consistent pattern throughout app

### Q3: Profile Screen "Add Treatment" Placement ✅ ANSWERED
**Decision**: Show "+ Add [Treatment]" buttons in main profile list
- Discoverable but not intrusive
- Navigate to creation screens when tapped
- Only show if that treatment type doesn't exist

### Q4: Analytics Migration ✅ ANSWERED
**Decision**: Update all analytics calls to new behavioral approach
- Clean break, better data going forward
- Track schedule creation events instead of persona selection
- Track actual usage patterns over time

### Q5: Code Reuse Strategy ✅ DECIDED
**Decision**: Reuse onboarding treatment screens by moving them to profile feature
- Move `treatment_fluid_screen.dart` → `create_fluid_schedule_screen.dart` in profile
- Keep `medication_schedule_screen.dart` (already handles empty state)
- Delete `treatment_medication_screen.dart` (redundant)
- Extract `PersonaSelectionCard` → generic `SelectionCard` widget
- Clean create/edit screen separation

---

## Implementation Checklist

**Plan Created**: 2025-01-08
**Plan Finalized**: 2025-01-09
**Status**: ✅ READY TO IMPLEMENT

### Design Decisions Confirmed:
- [x] Q1: Remove treatment setup from onboarding - use completion screen CTAs
- [x] Q2: Two separate SelectionCard widgets (rectangle layout)
- [x] Q3: Show "+ Add [Treatment]" buttons in profile list
- [x] Q4: Update all analytics to behavioral approach
- [x] Q5: Reuse onboarding screens by moving to profile feature

### Implementation Ready:
- [x] All design decisions finalized
- [x] Code reuse strategy defined (move screens, extract SelectionCard)
- [x] Navigation flows documented
- [x] File operations mapped (move, delete, create)
- [x] Testing checklist prepared
- [ ] Begin with Batch 1: Create SelectionCard widget

### Key Implementation Points:
1. **Start with Batch 1**: Create generic SelectionCard widget first
2. **Then Batch 2**: Move fluid creation screen to profile feature
3. **Then Batch 3-7**: Follow sequential order in Phase 3
4. **Test after each batch**: Ensure no breaking changes
5. **Final testing**: Complete Phase 4 checklist before closing migration

### Notes & Decisions:
- Maximum code reuse approach selected
- Clean create/edit screen separation
- Consistent SelectionCard pattern throughout app
- Faster onboarding flow (4 screens instead of 7)
- Progressive feature discovery via home screen empty states
- **CRITICAL**: Completion screen stays unchanged (preserves existing validation & save logic)
- **CRITICAL**: Progress system updates automatically (no manual changes needed)
- Feature discovery happens AFTER onboarding completes (better UX)
