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

#### 2.2.1 Remove UserPersona selection screen
**Files to modify**:
- `lib/features/onboarding/screens/user_persona_screen.dart` → DELETE
- `lib/features/onboarding/widgets/persona_selection_card.dart` → DELETE
- `lib/features/onboarding/models/onboarding_step.dart` → Remove `userPersona` step from enum

**Router changes**:
- `lib/app/router.dart` → Remove route for `/onboarding/user-persona`

#### 2.2.2 Update onboarding step flow
**File**: `lib/features/onboarding/models/onboarding_step.dart`

**Current flow**:
1. Welcome
2. Pet Basics
3. **User Persona** ← REMOVE
4. CKD Medical Info
5. Treatment Medication (conditional)
6. Treatment Fluid (conditional)
7. Completion

**New flow**:
1. Welcome
2. Pet Basics
3. CKD Medical Info
4. Treatment Setup (combined screen showing both options)
5. Completion

**Alternative new flow** (recommended - simpler):
1. Welcome
2. Pet Basics
3. CKD Medical Info
4. Completion (with empty state CTAs to add treatments)

**Recommendation**: Use second flow - get users to app faster, let them discover features organically

#### 2.2.3 Update treatment setup screens
**Option A** (if keeping treatment screens in onboarding):
**File**: Create new `lib/features/onboarding/screens/treatment_setup_screen.dart`
- Show both medication and fluid options
- Both sections skippable
- Copy: "You can set up your treatment tracking now, or add it later from the Profile screen"
- Save button enabled even if both empty

**Option B** (recommended):
- Remove treatment setup from onboarding entirely
- Show empty states on home screen with "Get Started" CTAs
- Simpler, faster onboarding
- Better feature discovery

#### 2.2.4 Update OnboardingService
**File**: `lib/features/onboarding/services/onboarding_service.dart`

**Line 433-440**: Update schedule creation logic
```dart
// Current (persona-based)
if (_currentData!.fluidTherapy != null &&
    _currentData!.treatmentApproach!.includesFluidTherapy) {
  // Create fluid schedule
}

// New (data-based)
if (_currentData!.fluidTherapy != null) {
  // Create fluid schedule - if user provided data, create it
}
```

**Similar update for medication schedules** - just check if data exists

#### 2.2.5 Remove onboarding validation based on persona
**File**: `lib/features/onboarding/services/onboarding_validation_service.dart`

**Lines 168-174 & 208-211**: Remove persona checks
```dart
// Remove this entire block - medications always optional
if (persona?.includesMedication ?? false) {
  if (data.medications == null || data.medications!.isEmpty) {
    errors.add(...);
  }
}

// Remove this entire block - fluid therapy always optional
if (persona?.includesFluidTherapy ?? false) {
  if (data.fluidTherapy == null) {
    errors.add(...);
  }
}
```

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
- "Set up medication tracking" → navigate to medication setup
- "Set up fluid therapy tracking" → navigate to fluid setup
- "I'll do this later" → dismiss
```

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
  ProfileSectionItem(title: "$petName's Fluid Schedule", ...);
}

if (primaryPet?.treatmentApproach.includesMedication ?? false) {
  ProfileSectionItem(title: "$petName's Medication Schedule", ...);
}
```

**New**:
```dart
final profileState = ref.watch(profileProvider);

if (profileState.hasFluidSchedule) {
  ProfileSectionItem(title: "$petName's Fluid Schedule", ...);
}

if (profileState.hasMedicationSchedules) {
  ProfileSectionItem(title: "$petName's Medication Schedule", ...);
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
    onTap: () => context.push('/profile/fluid'),
  );
}
```

Similar for medications if none exist.

### Step 2.6: Update Home Screen Empty States

**File**: `lib/features/home/screens/home_screen.dart`

Add progressive disclosure widgets:

**If no schedules at all**:
```dart
EmptyStateWidget(
  title: "Let's get started!",
  subtitle: "Set up your treatment tracking",
  actions: [
    PrimaryButton(
      text: "Add medication schedule",
      onTap: () => context.push('/profile/medication'),
    ),
    SecondaryButton(
      text: "Add fluid therapy schedule",
      onTap: () => context.push('/profile/fluid'),
    ),
  ],
)
```

**If only medication exists**:
- Show medication widgets prominently
- Small CTA: "You can also track fluid therapy →"

**If only fluid exists**:
- Show fluid widgets prominently
- Small CTA: "You can also track medications →"

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
1. `lib/features/profile/models/user_persona.dart`
2. `lib/features/onboarding/screens/user_persona_screen.dart`
3. `lib/features/onboarding/widgets/persona_selection_card.dart`

**Keep this file** (still needed for combined-persona users):
- `lib/features/logging/models/treatment_choice.dart` - Used when user with both schedules needs to choose which to log

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

## Phase 3: Implementation Order

### Batch 1: Data Models (Low Risk)
1. ✅ Create migration plan document (this file)
2. Remove `UserPersona` enum
3. Update `CatProfile` model
4. Update `OnboardingData` model
5. Run `flutter analyze` - fix any immediate type errors

### Batch 2: Onboarding Flow (Medium Risk)
6. Remove user persona screen and widget files
7. Update `OnboardingStep` enum
8. Update router to remove persona route
9. Update onboarding service to remove persona-based schedule creation
10. Update onboarding validation service
11. Test onboarding flow manually

### Batch 3: UI Logic (Medium Risk)
12. Update FAB logic in `app_shell.dart`
13. Create "No Schedules" dialog
14. Update profile screen sections
15. Add "Add Treatment" buttons to profile
16. Test FAB routing with different schedule states

### Batch 4: Home Screen (Low Risk)
17. Update home screen empty states
18. Add progressive disclosure CTAs
19. Test home screen with different schedule combinations

### Batch 5: Cleanup & Polish (Low Risk)
20. Update analytics tracking
21. Update Firestore schema documentation
22. Delete unused files
23. Update tests
24. Run full `flutter analyze`
25. Manual testing of all flows

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

## Questions Before Implementation

### Q1: Onboarding Flow Preference
**Option A**: Keep treatment setup in onboarding, make both sections skippable
**Option B**: Remove treatment setup from onboarding entirely, show empty state CTAs on home screen

**Recommendation**: Option B - simpler, faster, better discovery
**Your preference?**: _____________

### Q2: Empty State Strategy
When user has no schedules on home screen, show:
**Option A**: Single "Get Started" card with both options inside
**Option B**: Two separate cards side-by-side (medication / fluid)
**Option C**: Vertical list of both options with descriptions

**Recommendation**: Option B - clear, scannable, equal prominence
**Your preference?**: _____________

### Q3: Profile Screen "Add Treatment" Placement
When user doesn't have a treatment type:
**Option A**: Show empty section with "Add Fluid Therapy" button
**Option B**: Show "+ Add Fluid Therapy" button in main profile list
**Option C**: Don't show anything, let user discover from home screen

**Recommendation**: Option B - discoverable but not intrusive
**Your preference?**: _____________

### Q4: Analytics Migration
**Option A**: Keep historical persona analytics, add new behavioral analytics
**Option B**: Update all analytics calls to new behavioral approach
**Option C**: Hybrid - track both during transition period

**Recommendation**: Option B - clean break, better data going forward
**Your preference?**: _____________

---

## Implementation Checklist

**Plan Created**: 2025-01-08
**Status**: ⏳ Pending your decisions on Q1-Q4 below

### Before Starting Implementation:
- [ ] Answer Q1: Onboarding flow preference
- [ ] Answer Q2: Empty state strategy  
- [ ] Answer Q3: Profile "Add Treatment" placement
- [ ] Answer Q4: Analytics migration approach
- [ ] Review full plan one more time
- [ ] Begin with Batch 1

### Notes & Decisions:
