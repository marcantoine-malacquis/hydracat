# Lab Values Gauge Implementation Plan

## Implementation Progress

**Overall Status**: 🔄 In Progress (50% complete - Phase 3 Step 3.1 done)

- ✅ **Phase 1**: Constants & Configuration - COMPLETED (2025-12-03)
- ✅ **Phase 2**: Reusable Gauge Widget - COMPLETED (2025-12-03)
- 🔄 **Phase 3**: Lab Value Display Components - IN PROGRESS
  - ✅ Step 3.1: Create Lab Value Display Widget with Gauge - COMPLETED (2025-12-03)
  - ⏳ Step 3.2: Update CKD Profile Screen to Use Gauges - PENDING
- ⏳ **Phase 4**: Testing & Refinement - PENDING
- ⏳ **Phase 5**: Documentation & Cleanup - PENDING

---

## Overview
Add visual gauge indicators to lab values in the CKD Profile screen, similar to veterinary bloodwork reports. The gauge provides an at-a-glance visualization of whether values fall within normal reference ranges.

## Requirements Summary
- Create reusable `HydraGauge` widget for displaying value ranges
- Add lab reference ranges as constants
- Modify lab value display to show inline gauges (name, value, reference, gauge)
- Only show gauges in display mode when values exist
- Use color-coded indicators: dark teal (in-range), red (out-of-range)
- No Firebase/data model changes required

---

## ✅ Phase 1: Constants & Configuration - COMPLETED

**Status**: ✅ Complete
**Completed**: 2025-12-03

**Summary**: Successfully created lab reference ranges constants and integrated into the app.

**Files Created**:
- ✅ `lib/core/constants/lab_reference_ranges.dart` - Complete with all ranges and documentation

**Files Modified**:
- ✅ `lib/core/constants/constants.dart` - Export added (line 9)

**Verification**:
- ✅ `LabReferenceRange` class with `min`, `max`, `unit`, `isInRange()`, `getDisplayRange()`
- ✅ `creatinineRange` constant (0.6 - 1.6 mg/dL)
- ✅ `bunRange` constant (16 - 33 mg/dL)
- ✅ `sdmaRange` constant (0 - 14 µg/dL)
- ✅ Full clinical significance documentation

---

### Step 1.1: Create Lab Reference Ranges Constants
**File**: `lib/core/constants/lab_reference_ranges.dart`

**Tasks**:
1. Create new constants file for veterinary lab value reference ranges
2. Define `LabReferenceRange` class with:
   - `min` (double) - minimum normal value
   - `max` (double) - maximum normal value
   - `unit` (String) - unit of measurement
   - Helper methods:
     - `isInRange(double value)` - check if value is within normal range
     - `getDisplayRange()` - formatted string (e.g., "0.6 - 1.6 mg/dL")
3. Define constants for:
   - `creatinineRange` (0.6 - 1.6 mg/dL)
   - `bunRange` (16 - 33 mg/dL)
   - `sdmaRange` (0 - 14 µg/dL)
4. Add documentation explaining the clinical significance of ranges

**Files to create**:
- `lib/core/constants/lab_reference_ranges.dart`

**Files to modify**:
- `lib/core/constants/constants.dart` (add export)

---

## ✅ Phase 2: Reusable Gauge Widget - COMPLETED

**Status**: ✅ Complete
**Completed**: 2025-12-03

**Summary**: Successfully created the HydraGauge reusable widget with full gauge rendering logic, helper methods, and accessibility support.

**Files Created**:
- ✅ `lib/shared/widgets/hydra_gauge.dart` - Complete gauge widget with all features

**Files Modified**:
- ✅ `lib/shared/widgets/widgets.dart` - Export added (line 11)

**Verification**:
- ✅ `HydraGauge` widget with parameters: `value`, `min`, `max`, `unit`, `height`, `width`
- ✅ Gauge rendering with background bar, threshold markers, value indicator
- ✅ Color-coding: `AppColors.primaryDark` (in-range), `AppColors.error` (out-of-range)
- ✅ Extended range support (20% beyond min/max)
- ✅ Extreme outlier indicator (">>" or "<<")
- ✅ All helper methods implemented:
  - `_isValueInRange()`
  - `_getIndicatorColor()`
  - `_getExtendedMin()` / `_getExtendedMax()`
  - `_shouldShowOutlierIndicator()`
  - `_calculateIndicatorPosition()`
  - `_getMinThresholdPosition()` / `_getMaxThresholdPosition()`
- ✅ Semantic labels for accessibility
- ✅ Full documentation with usage examples

---

### Step 2.1: Create HydraGauge Widget
**File**: `lib/shared/widgets/hydra_gauge.dart`

**Tasks**:
1. Create stateless widget `HydraGauge` with parameters:
   - `value` (double) - the actual measured value
   - `min` (double) - minimum of reference range
   - `max` (double) - maximum of reference range
   - `unit` (String) - unit label (optional, for display)
   - `height` (double, default: 24) - gauge height
   - `width` (double, optional) - gauge width (defaults to available space)

2. Implement gauge rendering logic:
   - Calculate position of indicator within range
   - Handle values outside range (extend gauge by 20% max)
   - Handle extreme outliers (cap at edge + ">>" indicator)

3. Visual components:
   - Background bar (light teal, `AppColors.primaryLight` with alpha)
   - Threshold markers at min/max points (subtle vertical lines)
   - Value indicator (vertical bar):
     - `AppColors.primaryDark` if in range
     - `AppColors.error` if out of range
   - ">>" text indicator for extreme outliers

4. Add semantic labels for accessibility

5. Document widget usage with examples

**Files to create**:
- `lib/shared/widgets/hydra_gauge.dart`

**Files to modify**:
- `lib/shared/widgets/widgets.dart` (add export)

---

### Step 2.2: Create Gauge Helper Logic
**File**: `lib/shared/widgets/hydra_gauge.dart` (same file, internal helper)

**Tasks**:
1. Add private helper methods in `HydraGauge`:
   - `_calculateIndicatorPosition()` - converts value to pixel position
   - `_shouldShowOutlierIndicator()` - checks if value is extreme outlier
   - `_isValueInRange()` - checks if value is within normal range
   - `_getIndicatorColor()` - returns appropriate color based on range
   - `_getExtendedMax()` - calculates extended maximum (20% beyond)
   - `_getExtendedMin()` - calculates extended minimum (20% below)

2. Add position calculation logic:
   ```dart
   // If value is within extendable range (min-20% to max+20%)
   // Calculate proportional position
   // If value is extreme outlier, cap at edge
   ```

3. Handle edge cases:
   - Value exactly at min/max (should show as in-range)
   - Value is 0 or negative (for some lab values)
   - Min and max are very close (ensure gauge is still readable)

---

## Phase 3: Lab Value Display Components

**Status**: 🔄 In Progress (Step 3.1 complete)

**Summary**: Successfully created the `LabValueDisplayWithGauge` widget that displays lab values with visual gauges matching veterinary bloodwork reports.

**Files Created**:
- ✅ `lib/features/profile/widgets/lab_value_display_with_gauge.dart` - Complete lab value display with gauge

**Verification**:
- ✅ Widget matches existing `EditableMedicalField` styling
- ✅ Layout includes icon, label, reference range, value, gauge, and edit button
- ✅ Handles null values by showing "No information" without gauge
- ✅ Uses `HydraGauge` widget for visual representation
- ✅ Passes `flutter analyze` with zero issues
- ✅ Full documentation with usage examples

---

### Step 3.1: Create Lab Value Display Widget with Gauge
**File**: `lib/features/profile/widgets/lab_value_display_with_gauge.dart`

**Tasks**:
1. Create new widget `LabValueDisplayWithGauge` that matches veterinary bloodwork layout:

   **Layout structure** (all in one compact container):
   ```
   [Icon] [Label]  [Value]  [Reference Range]  [Gauge PPPjPPP]
   ```

2. Widget parameters:
   - `label` (String) - lab value name (e.g., "Creatinine")
   - `value` (double?) - measured value (nullable)
   - `referenceRange` (LabReferenceRange) - reference range object
   - `icon` (IconData, optional) - icon for the lab value
   - `onEdit` (VoidCallback) - edit button callback

3. Implement layout:
   - Container with card styling (matching existing `EditableMedicalField`)
   - Row layout with:
     - Leading icon (32x32, optional, matching existing style)
     - Label column (vertical layout):
       - Lab name (e.g., "Creatinine")
       - Reference range text (e.g., "0.6 - 1.6 mg/dL") in caption style
     - Spacer
     - Value display (e.g., "4.8" with unit, body text style)
     - Gauge (fixed width, e.g., 100-120px)
     - Edit button (matching existing 36x36 style)

4. Handle null values:
   - When `value` is null, show "No information" (no gauge)
   - Layout should match existing `EditableLabValueField`

5. Styling:
   - Match existing card styling from `EditableMedicalField`
   - Use `AppTextStyles` for typography
   - Use `AppSpacing` for consistent padding
   - Ensure touch targets meet minimum 44px requirement

**Files to create**:
- `lib/features/profile/widgets/lab_value_display_with_gauge.dart`

---

### Step 3.2: Update CKD Profile Screen to Use Gauges
**File**: `lib/features/profile/screens/ckd_profile_screen.dart`

**Tasks**:
1. Import new widgets:
   ```dart
   import 'package:hydracat/core/constants/lab_reference_ranges.dart';
   import 'package:hydracat/features/profile/widgets/lab_value_display_with_gauge.dart';
   ```

2. Replace `EditableLabValueField` with `LabValueDisplayWithGauge` in `_buildLabValuesSection()`:
   - Lines 422-432: Creatinine field � use `LabValueDisplayWithGauge` with `creatinineRange`
   - Lines 434-444: BUN field � use `LabValueDisplayWithGauge` with `bunRange`
   - Lines 446-456: SDMA field � use `LabValueDisplayWithGauge` with `sdmaRange`

3. Keep existing layout structure:
   - Only replace in display mode (when `!_isEditingLabValues`)
   - Keep edit mode unchanged (existing `LabValuesInput` widget)
   - Keep bloodwork date field unchanged (existing `EditableDateField`)

4. Pass correct parameters:
   - `label`: "Creatinine", "BUN", "SDMA"
   - `value`: from `_editingLabValues`
   - `referenceRange`: appropriate constant from `LabReferenceRanges`
   - `icon`: `Icons.science` (existing)
   - `onEdit`: trigger edit mode callback (existing)

**Files to modify**:
- `lib/features/profile/screens/ckd_profile_screen.dart`

---

## Phase 4: Testing & Refinement

### Step 4.1: Create Unit Tests for Gauge Logic
**File**: `test/shared/widgets/hydra_gauge_test.dart`

**Tasks**:
1. Test gauge calculations:
   - Value within normal range � correct position, dark teal color
   - Value above range (moderate) � extended position, red color
   - Value above range (extreme) � capped position with ">>", red color
   - Value below range (moderate) � extended position, red color
   - Value below range (extreme) � capped position with ">>", red color
   - Value exactly at min/max � in-range color

2. Test edge cases:
   - Value is 0
   - Value is negative (if applicable)
   - Min equals max
   - Very large numbers

3. Test widget rendering:
   - Gauge renders without errors
   - Accessibility labels are present
   - Colors are correct based on range

**Files to create**:
- `test/shared/widgets/hydra_gauge_test.dart`

**Files to modify**:
- `test/tests_index.md` (document new test file)

---

### Step 4.2: Create Unit Tests for Reference Ranges
**File**: `test/core/constants/lab_reference_ranges_test.dart`

**Tasks**:
1. Test `LabReferenceRange` class:
   - `isInRange()` correctly identifies in-range values
   - `isInRange()` correctly identifies out-of-range values
   - `getDisplayRange()` formats correctly
   - Edge cases (value at boundaries)

2. Verify constants are correct:
   - Creatinine: 0.6 - 1.6 mg/dL
   - BUN: 16 - 33 mg/dL
   - SDMA: 0 - 14 �g/dL

**Files to create**:
- `test/core/constants/lab_reference_ranges_test.dart`

**Files to modify**:
- `test/tests_index.md` (document new test file)

---

### Step 4.3: Manual Testing Checklist

**Tasks**:
1. Visual verification:
   - [ ] Gauge appears only when lab value exists
   - [ ] Gauge does not appear for null values
   - [ ] Layout matches veterinary bloodwork style
   - [ ] Colors are correct (dark teal for in-range, red for out-of-range)
   - [ ] Threshold markers are visible and subtle
   - [ ] ">>" indicator appears for extreme outliers
   - [ ] Text is readable at all sizes
   - [ ] Edit button still works

2. Test with different values:
   - [ ] Normal creatinine (e.g., 1.2) � green indicator in middle
   - [ ] High creatinine (e.g., 4.8 from screenshot) � red indicator, extended
   - [ ] Very high creatinine (e.g., 8.0) � red indicator at edge with ">>"
   - [ ] Low creatinine (e.g., 0.3) � red indicator, extended
   - [ ] Values at exact boundaries (0.6, 1.6) � green indicator

3. Test transitions:
   - [ ] Switch from display mode to edit mode � gauge disappears
   - [ ] Switch from edit mode to display mode � gauge appears
   - [ ] Update value and save � gauge updates correctly

4. Test edge cases:
   - [ ] No lab values entered � "No information" text, no gauge
   - [ ] Only some lab values entered � gauges only for entered values
   - [ ] Bloodwork date without values � no gauges

5. Accessibility:
   - [ ] Screen reader announces gauge information
   - [ ] Touch targets are adequate (44px minimum)
   - [ ] Text contrast meets WCAG standards

---

### Step 4.4: Run Flutter Analyze
**Tasks**:
1. Run `flutter analyze` to check for linting issues
2. Fix any issues found:
   - Unused imports
   - Missing documentation
   - Type safety issues
   - Accessibility warnings
3. Ensure all files pass analysis with no warnings

**Command**: `flutter analyze`

---

## Phase 5: Documentation & Cleanup

### Step 5.1: Update Test Index
**File**: `test/tests_index.md`

**Tasks**:
1. Add new test files to the index:
   - `test/shared/widgets/hydra_gauge_test.dart` - HydraGauge widget tests
   - `test/core/constants/lab_reference_ranges_test.dart` - Lab reference range tests

2. Add brief description of what each test covers

**Files to modify**:
- `test/tests_index.md`

---

### Step 5.2: Final Verification

**Tasks**:
1. Verify all new files follow project structure:
   - [ ] Constants in `lib/core/constants/`
   - [ ] Shared widgets in `lib/shared/widgets/`
   - [ ] Feature-specific widgets in `lib/features/profile/widgets/`
   - [ ] Tests mirror source structure

2. Verify all imports use absolute paths (not relative)

3. Verify all files have proper documentation:
   - [ ] Class-level documentation
   - [ ] Public method documentation
   - [ ] Complex logic has inline comments

4. Verify adherence to naming conventions:
   - [ ] File names are snake_case
   - [ ] Class names are PascalCase
   - [ ] Variables are camelCase
   - [ ] Constants are camelCase (static const)
   - [ ] Private members start with underscore

5. Final `flutter analyze` run with zero issues

---

## Implementation Summary

### Files to Create (5 new files):
1. `lib/core/constants/lab_reference_ranges.dart` - Reference range constants
2. `lib/shared/widgets/hydra_gauge.dart` - Reusable gauge widget
3. `lib/features/profile/widgets/lab_value_display_with_gauge.dart` - Lab value display component
4. `test/shared/widgets/hydra_gauge_test.dart` - Gauge widget tests
5. `test/core/constants/lab_reference_ranges_test.dart` - Reference range tests

### Files to Modify (4 existing files):
1. `lib/core/constants/constants.dart` - Add export for lab_reference_ranges
2. `lib/shared/widgets/widgets.dart` - Add export for hydra_gauge
3. `lib/features/profile/screens/ckd_profile_screen.dart` - Use new gauge widgets
4. `test/tests_index.md` - Document new tests

### Zero Firebase Impact:
- No data model changes
- No Firestore reads/writes added
- Pure UI enhancement
- Reference ranges are hardcoded constants

---

## Testing Plan

### User Testing Steps:
1. **Run the app**: `flutter run --flavor development -t lib/main_development.dart`
2. **Navigate to CKD Profile**: Home � Profile � CKD Profile
3. **Verify display mode**:
   - Check gauges appear for existing lab values
   - Check colors match expectations
   - Check layout matches veterinary reports
4. **Test edit mode**:
   - Tap edit on a lab value
   - Verify gauge disappears
   - Enter new value and save
   - Verify gauge reappears with correct position
5. **Test null states**:
   - Delete a lab value
   - Save
   - Verify gauge doesn't appear, shows "No information"

### Automated Testing:
- Run `flutter test` to verify all unit tests pass
- Run `flutter analyze` to verify no linting issues

---

## Expected Outcome

After implementation:
- Lab values display with inline gauges matching veterinary bloodwork reports
- Visual at-a-glance indication of whether values are in normal range
- Color-coded indicators (dark teal for normal, red for abnormal)
- Subtle, non-alarming design that doesn't scare users
- Fully accessible with screen reader support
- Zero impact on Firebase usage or costs
- Reusable `HydraGauge` widget for potential future use

---

## Notes

- The gauge design follows medical industry standards for lab value visualization
- Reference ranges are based on standard feline veterinary values
- The implementation prioritizes clarity and reduces anxiety (only indicator is colored)
- All changes are UI-only, no business logic or data model changes
- The widget is reusable and could be extended for other numeric range visualizations
- Accessibility is maintained throughout with proper semantic labels

---

## Questions for Future Consideration

1. Should we add tooltips or info icons explaining what the reference ranges mean?
2. Should we track changes in lab values over time (e.g., trend arrows)?
3. Should we add the ability to customize reference ranges per cat (e.g., for special cases)?
4. Should we add export functionality for lab values (PDF report with gauges)?

These are **not** part of this implementation but could be considered in future iterations.
