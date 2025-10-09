# Onboarding Flow Manual Testing Plan

## Overview
This manual testing plan covers the complete onboarding flow implementation through Phase 4, including all UI screens, navigation, data persistence, and router integration.

## Prerequisites
- App running in development mode: `flutter run --flavor development -t lib/main_development.dart`
- Firebase connected (hydracattest project for development)
- Clean test account or ability to create new accounts

## Test Environment Setup
1. **Clean State**: Use a fresh user account or reset onboarding state
2. **Network**: Test with both stable internet and offline conditions
3. **Device**: Test on different screen sizes if possible
4. **Debug Mode**: Enable Flutter inspector for widget tree analysis

---

## Phase 1: Authentication & Router Integration

### Test 1.1: Initial App Launch (Unauthenticated)
**Expected Behavior**: Redirect to login screen
- [x] Launch app
- [ ] Verify redirected to `/login` route
- [ ] Verify bottom navigation is hidden
- [ ] Verify no onboarding elements visible

### Test 1.2: User Registration/Login
**Expected Behavior**: Standard auth flow
- [ ] Create new account or login with existing
- [ ] Complete email verification if required
- [ ] Verify successful authentication

### Test 1.3: Post-Authentication Redirect
**Expected Behavior**: Authenticated user without onboarding completion should redirect to onboarding
- [ ] After successful login/registration
- [ ] Verify automatic redirect to `/onboarding/welcome`
- [ ] Verify bottom navigation remains hidden
- [ ] Verify app shell shows onboarding state

---

## Phase 2: Onboarding Flow - Core Navigation

### Test 2.1: Welcome Screen (`/onboarding/welcome`)
**Expected Elements**:
- [ ] **Progress Indicator**: 6 dots, first dot active (larger, teal color)
- [ ] **Title**: CKD-focused welcome message
- [ ] **Content**: Value proposition and benefits
- [ ] **Skip Button**: "Skip for now" option
- [ ] **Get Started Button**: Primary action button

**Navigation Tests**:
- [ ] Tap "Get Started" → Navigate to `/onboarding/persona`
- [ ] Tap "Skip" → Should show skip confirmation dialog
- [ ] Skip confirmation → Set skip state and navigate to home
- [ ] Back button → No back navigation (should be disabled)

**Analytics Tests**:
- [ ] Screen view tracked correctly
- [ ] Screen timing captured (check dev console/analytics dashboard)

### Test 2.2: User Persona Screen (`/onboarding/persona`)
**Expected Elements**:
- [ ] **Progress Indicator**: 6 dots, second dot active
- [ ] **Title**: Treatment approach selection
- [ ] **Three Cards**: 
  - Medication Only (square, top-left)
  - Fluid Therapy Only (square, top-right) 
  - Medication & Fluid Therapy (rectangle, full width below)
- [ ] **3D Effects**: Cards should animate on press (elevation 2px → 8px)
- [ ] **Loading State**: Selected card shows spinner during processing
- [ ] **Footer Message**: "You can change this anytime in Profile"

**Persona Selection Tests**:
- [ ] Tap "Medication Only" → Loading state → Navigate to pet basics
- [ ] **Go back** → Tap "Fluid Therapy Only" → Loading state → Navigate to pet basics  
- [ ] **Go back** → Tap "Medication & Fluid Therapy" → Loading state → Navigate to pet basics

**Navigation Tests**:
- [ ] Back button → Navigate to `/onboarding/welcome`
- [ ] Back preserves previous screen state
- [ ] Forward navigation includes slide animations

**Data Persistence Tests**:
- [ ] Selected persona is stored locally
- [ ] App restart preserves persona selection
- [ ] Changing persona preserves other onboarding data

### Test 2.3: Pet Basics Screen (`/onboarding/basics`)
**Expected Elements**:
- [ ] **Progress Indicator**: 6 dots, third dot active
- [ ] **Required Fields**:
  - Pet name (text input)
  - Date of birth (date picker)
  - Gender (toggle: male/female)
- [ ] **Optional Fields**:
  - Weight with kg/lbs selector
  - Breed (text input)
- [ ] **Age Display**: Auto-calculated from date of birth (years + months)
- [ ] **Next Button**: Enabled only when required fields complete

**Form Validation Tests**:
- [ ] Empty name → Next button disabled
- [ ] No date of birth → Next button disabled
- [ ] No gender selected → Next button disabled
- [ ] All required fields → Next button enabled
- [ ] Weight conversion: Enter in lbs, verify kg storage
- [ ] Date picker: Select past date, verify age calculation accuracy

**Navigation Tests**:
- [ ] Back button → Navigate to `/onboarding/persona`
- [ ] Next button (valid form) → Navigate to `/onboarding/medical`
- [ ] Form data persists on back/forward navigation

**Data Validation Tests**:
- [ ] Age calculation: Test various dates (1 year old, 15 years, 6 months, etc.)
- [ ] Weight validation: Test range limits (0-15kg equivalent)
- [ ] Name validation: Special characters, length limits
- [ ] No Firebase operations during screen interaction (cost optimization)

### Test 2.4: CKD Medical Info Screen (`/onboarding/medical`)
**Expected Elements**:
- [ ] **Progress Indicator**: 6 dots, fourth dot active
- [ ] **Empathetic Introduction**: Heart icon with understanding message
- [ ] **IRIS Stage Selector**: 5 horizontal buttons (Stage 1, 2, 3, 4, "Unknown")
- [ ] **Lab Values Section**:
  - Creatinine (mg/dL)
  - BUN (mg/dL) 
  - SDMA (μg/dL)
- [ ] **Date Pickers**:
  - Bloodwork date (required if lab values entered)
  - Last checkup date (optional)
- [ ] **Skip Option**: Skip dialog with empathetic messaging
- [ ] **Next Button**: Always enabled (all fields optional)

**Medical Data Tests**:
- [ ] IRIS stage selection: Visual feedback for each stage
- [ ] Lab values: Decimal input validation (2 decimal places)
- [ ] Required bloodwork date when lab values present
- [ ] Optional fields remain optional
- [ ] Skip dialog: Empathetic messaging about adding info later

**Navigation Tests**:
- [ ] Back button → Navigate to `/onboarding/basics`
- [ ] Next button → Navigate to `/onboarding/treatment`
- [ ] Skip dialog → Navigate to `/onboarding/treatment`
- [ ] All data persists on navigation

**Data Validation Tests**:
- [ ] Lab values: Valid decimal ranges
- [ ] Date validation: Bloodwork date not in future
- [ ] Form submission with partial data
- [ ] Form submission with no medical data (skip scenario)

### Test 2.5: Treatment Setup Screen (`/onboarding/treatment`)
**Expected Behavior**: Persona-adaptive routing
- [ ] **Progress Indicator**: 6 dots, fifth dot active

**Routing Tests by Persona**:

#### Medication Only Persona:
- [ ] Navigate directly to medication setup screen
- [ ] Complete medication setup → Navigate to `/onboarding/completion`

#### Fluid Therapy Only Persona:  
- [ ] Navigate directly to fluid therapy setup screen
- [ ] Complete fluid setup → Navigate to `/onboarding/completion`

#### Combined Persona:
- [ ] Navigate to medication setup screen first
- [ ] Complete medication setup → Navigate to fluid therapy screen
- [ ] Complete fluid setup → Navigate to `/onboarding/completion`

**Navigation Tests**:
- [ ] Back button behavior appropriate for persona flow
- [ ] Forward navigation follows persona logic
- [ ] Data preservation across treatment screens

---

## Phase 3: Treatment Setup Detailed Testing

### Test 3.1: Medication Setup Screen (Medication Only & Combined Personas)
**Expected Elements**:
- [ ] **Add Medication Button**: "+" button prominently displayed
- [ ] **Medication List**: Shows added medications with professional summaries
- [ ] **Next Button**: Enabled when at least one medication added
- [ ] **Footer Message**: "You can update your schedules anytime in the Profile section"

**Medication Management Tests**:
- [ ] Tap "+" → Opens add medication popup
- [ ] Add medication → Returns to list with medication displayed
- [ ] Medication summary format: "1 pill twice daily", "2 drops once daily"
- [ ] Delete medication functionality
- [ ] Edit existing medication

**Add Medication Popup Flow**:

#### Step 1: Name & Unit Selection
- [ ] **Medication Name**: Text input field
- [ ] **Unit Selection**: iOS-style rotating wheel picker
- [ ] **Available Units**: ampoules, capsules, drops, injections, micrograms, milligrams, milliliters, pills, portions, sachets, tablespoon, teaspoon
- [ ] **Next Button**: Enabled when both name and unit selected

#### Step 2: Frequency Selection  
- [ ] **Frequency Options**: onceDaily, twiceDaily, thriceDaily, everyOtherDay, every3Days
- [ ] **Visual Selection**: Clear option selection with feedback
- [ ] **Next Button**: Enabled when frequency selected

#### Step 3: Reminder Times
- [ ] **Time Pickers**: Number matches frequency (1 for once daily, 2 for twice daily, etc.)
- [ ] **Time Labels**: "First intake", "Second intake", "Third intake"
- [ ] **Save Button**: Stores medication and returns to main screen

**Data Tests**:
- [ ] All medication data stored locally
- [ ] Multiple medications supported
- [ ] Professional summary generation accurate
- [ ] Data persists through popup flow

### Test 3.2: Fluid Therapy Setup Screen (Fluid Only & Combined Personas)
**Expected Elements**:
- [ ] **Frequency Selection**: Rotating wheel picker
- [ ] **Volume Input**: Numeric input with ml unit label
- [ ] **Location Selection**: Rotating wheel with options:
  - Shoulder Blade - Left
  - Shoulder Blade - Right  
  - Hip Bones - Left
  - Hip Bones - Right
- [ ] **Needle Gauge Selection**: Rotating wheel picker
- [ ] **Next Button**: Enabled when all fields completed

**Form Validation Tests**:
- [ ] All fields required for form completion
- [ ] Volume validation: Realistic ranges
- [ ] Frequency selection required
- [ ] Location selection required
- [ ] Needle gauge selection required

**Navigation Tests**:
- [ ] Back button appropriate for persona (medication screen for combined, persona screen for fluid-only)
- [ ] Next button → Navigate to completion screen
- [ ] Data preservation on navigation

---

## Phase 4: Completion & App Integration

### Test 4.1: Completion Screen (`/onboarding/completion`)
**Expected Elements**:
- [ ] **Progress Indicator**: 6 dots, sixth dot active (all completed)
- [ ] **Celebration Message**: Personalized with pet name
- [ ] **Finish Button**: Primary action button
- [ ] **Loading State**: Spinner during Firebase operation
- [ ] **Loading Text**: "Finishing setup..." during processing

**Firebase Integration Tests**:
- [ ] Tap "Finish" → Loading spinner appears
- [ ] Firebase write operation completes (1-3 seconds)
- [ ] Success → Auto-navigate to home screen
- [ ] Error handling → Remain on screen with retry option
- [ ] Data preservation on error (no data loss)

**Data Persistence Tests**:
- [ ] Single Firebase write contains all onboarding data
- [ ] Auth state updated: `hasCompletedOnboarding = true`
- [ ] Primary pet ID set correctly
- [ ] All local onboarding data cleared after successful completion

### Test 4.2: Post-Completion App Experience
**Expected Behavior**: Full app access with bottom navigation
- [ ] **Navigation Bar**: Bottom navigation visible and functional
- [ ] **Home Screen**: Personalized content based on persona
- [ ] **Profile Screen**: Shows pet information from onboarding
- [ ] **All Screens**: No empty state onboarding CTAs
- [ ] **FAB Behavior**: Redirects to logging (not onboarding)

**Router Integration Tests**:
- [ ] Try accessing `/onboarding/*` routes → Redirect to home
- [ ] App restart → Stay on home screen (no onboarding redirect)
- [ ] Navigation to all main app sections works correctly

---

## Phase 5: Edge Cases & Error Handling

### Test 5.1: Network Conditions
**Offline Testing**:
- [ ] Complete entire onboarding flow offline
- [ ] All screens function normally
- [ ] Data stored locally throughout flow
- [ ] Completion screen: Error handling when offline
- [ ] Return online → Retry completion successfully

**Network Interruption**:
- [ ] Start onboarding online
- [ ] Go offline mid-flow
- [ ] Continue onboarding → Should work normally
- [ ] Reach completion screen → Handle network error gracefully

### Test 5.2: Data Persistence & Recovery
**App Termination**:
- [ ] Start onboarding, complete 2-3 screens
- [ ] Force close app
- [ ] Relaunch → Resume from appropriate step (not restart)
- [ ] All previously entered data preserved

**Navigation Edge Cases**:
- [ ] Rapid back/forward navigation
- [ ] Deep linking to onboarding screens
- [ ] Browser refresh (if web version)
- [ ] Route parameter validation

### Test 5.3: Skip Flow Testing
**Skip Functionality**:
- [ ] From welcome screen → Skip confirmation dialog
- [ ] Confirm skip → Navigate to home with limited access
- [ ] **Home Screen**: Shows onboarding CTA empty state
- [ ] **Profile Screen**: Shows onboarding CTA 
- [ ] **Progress Screen**: Shows onboarding CTA
- [ ] **FAB**: Redirects to onboarding welcome
- [ ] **Bottom Nav**: Visible but with limited content

**Re-engagement Testing**:
- [ ] After skipping, tap FAB → Return to onboarding welcome
- [ ] After skipping, tap profile CTA → Return to onboarding welcome
- [ ] Complete onboarding after skip → Full app access restored

---

## Phase 6: Performance & User Experience

### Test 6.1: Animation & Transitions
- [ ] **Progress Dots**: Smooth size transitions (12px → 16px)
- [ ] **Screen Transitions**: Right-to-left slide animations
- [ ] **Back Navigation**: Left-to-right slide animations
- [ ] **Card Press Effects**: 3D elevation animation (2px → 8px)
- [ ] **Loading States**: Spinner overlays without layout shift

### Test 6.2: Form Validation & Feedback
- [ ] **Real-time Feedback**: Button states change appropriately
- [ ] **Error Messages**: Clear, user-friendly validation errors
- [ ] **Success States**: Visual confirmation of successful actions
- [ ] **Accessibility**: Screen reader compatible elements

### Test 6.3: Performance Metrics
- [ ] **Screen Loading**: < 1 second between screens
- [ ] **Data Entry**: Responsive input without lag
- [ ] **Memory Usage**: No significant memory leaks during flow
- [ ] **Firebase Operations**: Only single write on completion

---

## Critical Success Criteria

### Must Pass:
- [ ] **Complete Flow**: All 6 screens accessible and functional
- [ ] **Data Persistence**: All entered data preserved throughout flow
- [ ] **Router Integration**: Proper redirects based on auth/onboarding state
- [ ] **Persona Adaptation**: Treatment setup adapts to selected persona
- [ ] **Firebase Cost Optimization**: Zero reads, single write on completion
- [ ] **Offline Functionality**: Complete flow works without internet
- [ ] **Error Recovery**: No data loss on errors or app termination

### Nice to Have:
- [ ] **Smooth Animations**: All transitions feel polished
- [ ] **Loading States**: Professional loading indicators
- [ ] **Analytics**: All events tracked correctly
- [ ] **Accessibility**: Screen reader compatible

---

## Bug Report Template

When you find issues, please report with:

1. **Screen/Step**: Which onboarding screen
2. **Device/Platform**: iOS/Android, screen size
3. **Persona**: Which treatment approach selected
4. **Expected Behavior**: What should happen
5. **Actual Behavior**: What actually happened
6. **Reproduction Steps**: How to reproduce the issue
7. **Data State**: What data was entered before the issue
8. **Network State**: Online/offline when issue occurred

---

## Testing Completion Checklist

- [ ] Phase 1: Authentication & Router (15 tests)
- [ ] Phase 2: Core Navigation (20 tests)  
- [ ] Phase 3: Treatment Setup (25 tests)
- [ ] Phase 4: Completion & Integration (15 tests)
- [ ] Phase 5: Edge Cases (20 tests)
- [ ] Phase 6: Performance (10 tests)

**Total: 105 test points across complete onboarding implementation**

---

## Bug Fixes & Issues Resolved

### Issue #1: "Get Started" Button Navigation Failure

**Date Resolved**: 2025-01-13  
**Screen**: Welcome Screen (`/onboarding/welcome`)  
**Severity**: Critical - Prevented onboarding flow progression

#### Problem Description
The "Get Started" button on the welcome screen showed visual feedback (button press animation) but failed to navigate to the persona selection screen. Users remained stuck on the welcome screen despite successful button interactions.

#### Root Cause Analysis
The issue was caused by an incorrect redirect condition in the parent `/onboarding` route configuration in `lib/app/router.dart`. The parent route's redirect function was using `state.matchedLocation` instead of `state.fullPath`, causing it to incorrectly match nested routes like `/onboarding/persona` and redirect them back to `/onboarding/welcome`.

**Problematic Code**:
```dart
redirect: (context, state) {
  final loc = state.matchedLocation; // ← This was the bug
  if (loc == '/onboarding') {
    return '/onboarding/welcome';
  }
  return null;
}
```

**Debug Analysis**:
- Navigation to `/onboarding/persona` succeeded initially
- Parent route redirect incorrectly triggered, detecting `/onboarding` match
- Automatic redirect back to `/onboarding/welcome` occurred
- UserPersonaScreen never initialized or rendered

#### Solution Implemented
Changed the parent route redirect condition to use `state.fullPath` instead of `state.matchedLocation` to ensure exact path matching:

```dart
redirect: (context, state) {
  final fullPath = state.fullPath; // ← Fixed implementation
  if (fullPath == '/onboarding') {
    return '/onboarding/welcome';
  }
  return null;
}
```

#### Verification
- ✅ "Get Started" button now successfully navigates to persona screen
- ✅ Parent route redirect only triggers for exact `/onboarding` path
- ✅ Nested onboarding routes (`/onboarding/persona`, `/onboarding/basics`, etc.) function correctly
- ✅ No impact on other navigation flows

#### Prevention
This issue highlights the importance of precise route matching conditions in nested route structures. Future route configurations should:
- Use `state.fullPath` for exact path matching
- Test nested route navigation thoroughly
- Include debug logging during route development to catch redirect loops

---

*This testing plan ensures comprehensive coverage of the onboarding flow through Phase 4, validating both happy path and edge case scenarios while maintaining focus on the medical app context and user experience.*