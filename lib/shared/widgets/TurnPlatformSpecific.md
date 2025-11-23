# Platform-Specific Widgets to Refactor

This document lists all Material Design and Cupertino widgets used directly in the codebase that should be refactored into platform-adaptive wrappers (similar to `HydraSlider`).

## Implementation Pattern

For each widget listed below, create a `Hydra*` wrapper in `lib/shared/widgets/` that:
1. Detects platform via `Theme.of(context).platform` or `defaultTargetPlatform`
2. Returns Material widget on Android/other platforms
3. Returns Cupertino widget on iOS/macOS
4. Mirrors the core API of the Material widget (since that's what's currently used)
5. Handles API differences between Material and Cupertino gracefully

---

## ✅ Already Implemented

- **`HydraSlider`** (`lib/shared/widgets/inputs/hydra_slider.dart`) - ✅ Done
  - Wraps `Slider` (Material) / `CupertinoSlider` (iOS)
  - Used in: `symptoms_entry_dialog.dart`

- **`HydraSwitch`** (`lib/shared/widgets/inputs/hydra_switch.dart`) - ✅ Done
  - Wraps `Switch` (Material) / `CupertinoSwitch` (iOS)
  - Used in: `notification_settings_screen.dart`

- **`HydraDatePicker`** (`lib/shared/widgets/pickers/hydra_date_picker.dart`) - ✅ Done
  - Wraps `showDatePicker()` (Material) / `CupertinoDatePicker` (iOS)
  - Used in: `symptoms_entry_dialog.dart`, `weight_entry_dialog.dart`, `progress_week_calendar.dart`, `pet_basics_screen.dart`, `ckd_medical_info_screen.dart`, `ckd_profile_screen.dart`, `lab_values_input.dart`

- **`HydraAlertDialog`** (`lib/shared/widgets/dialogs/hydra_alert_dialog.dart`) - ✅ Done
  - Wraps `AlertDialog` (Material) / `CupertinoAlertDialog` (iOS)
  - Includes `showHydraAlertDialog()` helper function
  - Automatically converts Material buttons to CupertinoDialogAction
  - **Material**: `AlertDialog` widget + `showDialog()`
  - **Cupertino**: `CupertinoAlertDialog` widget + `showCupertinoDialog()`
  - **Used in**: 
    - `settings_screen.dart` (clear cache confirmation)
    - `lockout_dialog.dart`
    - `weight_calculator_dialog.dart`
    - `session_update_dialog.dart`
    - `treatment_popup_wrapper.dart`
    - `permission_preprompt.dart`
    - `notification_error_handler.dart`
    - `debug_panel.dart`
    - `ckd_medical_info_screen.dart`
    - `verification_gate.dart`
    - `validation_error_display.dart`
    - `weight_entry_dialog.dart`
    - `notification_settings_screen.dart`
  - **API Differences**: 
    - Material: `actions` (list of buttons), `title`, `content`
    - Cupertino: `actions` (list of `CupertinoDialogAction`), `title`, `content`

- **`HydraDialog`** (`lib/shared/widgets/dialogs/hydra_dialog.dart`) - ✅ Done
  - Wraps `Dialog` (Material) / `CupertinoPopupSurface` (iOS)
  - Includes `showHydraDialog()` helper function
  - **Material**: `Dialog` widget + `showDialog()`
  - **Cupertino**: `CupertinoPopupSurface` widget + `showCupertinoDialog()`
  - **Used in**: 
    - `no_schedules_dialog.dart` (migrated to use `HydraDialog`)
    - `treatment_popup_wrapper.dart` (migrated to use `HydraDialog`)
  - **API Differences**: 
    - Material: `Dialog` with `shape`, `backgroundColor`, `insetPadding`, `clipBehavior`, `elevation`
    - Cupertino: `CupertinoPopupSurface` with `insetPadding` support; `shape`, `backgroundColor`, `elevation`, `clipBehavior` are ignored

- **`HydraBottomSheet`** (`lib/shared/widgets/bottom_sheets/hydra_bottom_sheet.dart`) - ✅ Done
  - Wraps `showModalBottomSheet()` (Material) / `showCupertinoModalPopup()` (iOS)
  - Includes `showHydraBottomSheet()` helper function
  - **Material**: `showModalBottomSheet()` function with Material bottom sheet styling
  - **Cupertino**: `showCupertinoModalPopup()` with Cupertino-style bottom sheet
  - **Used in**: 
    - `notification_settings_screen.dart` (migrated to use `showHydraBottomSheet`)
    - `permission_preprompt.dart` (migrated to use `showHydraBottomSheet`)
    - `debug_panel.dart` (migrated to use `showHydraBottomSheet`)
  - **API Differences**: 
    - Material: `showModalBottomSheet()` with full Material API support (`isScrollControlled`, `enableDrag`, `shape`, etc.)
    - Cupertino: `showCupertinoModalPopup()` with simplified API; Material-specific options are gracefully ignored

---

## 🔴 High Priority (Frequently Used, High Visual Impact)

---

## 🟡 Medium Priority (Moderately Used, Moderate Visual Impact)

### 6. **TextField** → `HydraTextField`
- **Material**: `TextField` widget
- **Cupertino**: `CupertinoTextField` widget
- **Current Usage**: 
  - `symptoms_entry_dialog.dart` (notes field)
  - `weight_entry_dialog.dart` (weight input, notes)
  - `fluid_logging_screen.dart`
  - `volume_input_adjuster.dart` (internal)
  - `progress_day_detail_popup.dart` (notes)
  - `weight_calculator_form.dart`
  - `medication_dosage_input.dart`
  - `medication_logging_screen.dart`
- **API Differences**: 
  - Material: `decoration` (InputDecoration), `controller`, `focusNode`, etc.
  - Cupertino: `placeholder`, `prefix`, `suffix`, `padding`, simpler styling API
- **Priority**: Medium - Used in 8+ locations, but often wrapped in custom widgets

### 7. **Time Picker** → `HydraTimePicker` (Already exists but iOS-only)
- **Current**: `HydraTimePicker` in `lib/shared/widgets/pickers/hydra_time_picker.dart`
- **Issue**: Currently always uses `CupertinoDatePicker` (iOS-style) on all platforms
- **Should**: Use `showTimePicker()` (Material) on Android, `CupertinoDatePicker` on iOS
- **Current Usage**: 
  - Used for time selection in schedules
- **Priority**: Medium - Already exists but needs platform branching

### 8. **SnackBar** → `HydraSnackBar`
- **Material**: `SnackBar` widget + `ScaffoldMessenger.of(context).showSnackBar()`
- **Cupertino**: No direct equivalent, typically uses custom overlay or `CupertinoAlertDialog`
- **Current Usage**: 
  - `symptoms_entry_dialog.dart` (success message)
  - `weight_screen.dart`
  - `progress_day_detail_popup.dart`
  - `create_fluid_schedule_screen.dart`
  - `app_shell.dart`
  - `notification_settings_screen.dart`
  - `welcome_screen.dart`
  - `pet_basics_screen.dart`
  - `ckd_medical_info_screen.dart`
  - `add_medication_screen.dart`
- **API Differences**: 
  - Material: `SnackBar` with `action`, `duration`, `backgroundColor`, etc.
  - Cupertino: No built-in equivalent, need custom implementation or use alert dialog
- **Priority**: Medium - Used in 10+ locations for user feedback

### 9. **Button Variants** → `HydraButton` (Partially exists)
- **Material**: `ElevatedButton`, `FilledButton`, `OutlinedButton`, `TextButton`
- **Cupertino**: `CupertinoButton`, `CupertinoButton.filled`
- **Current**: `HydraButton` exists in `lib/shared/widgets/buttons/hydra_button.dart`
- **Issue**: Need to verify if it branches on platform or always uses Material
- **Current Usage**: 
  - Used throughout the app via `HydraButton`
  - Direct usage: `unsaved_changes_dialog.dart` (uses `ElevatedButton`, `OutlinedButton`)
  - `settings_screen.dart` (uses `ElevatedButton`, `TextButton`)
- **Priority**: Medium - Core component, but may already be handled

### 10. **FloatingActionButton** → `HydraFAB` (Partially exists)
- **Material**: `FloatingActionButton`
- **Cupertino**: No direct equivalent, typically uses `CupertinoButton` with custom styling
- **Current**: `HydraExtendedFab` exists in `lib/shared/widgets/buttons/hydra_fab.dart`
- **Issue**: Need to verify if it branches on platform
- **Current Usage**: 
  - `symptoms_screen.dart` (uses `HydraExtendedFab`)
  - `home_screen.dart` (uses `HydraExtendedFab`)
- **Priority**: Medium - Core component, but may already be handled

---

## 🟢 Low Priority (Less Frequently Used or Lower Visual Impact)

### 11. **Checkbox** → `HydraCheckbox`
- **Material**: `Checkbox`
- **Cupertino**: No direct equivalent (iOS uses switches or list selections)
- **Current Usage**: None found (0 instances)
- **Priority**: Low - Not currently used

### 12. **Radio** → `HydraRadio`
- **Material**: `Radio`, `RadioListTile`
- **Cupertino**: No direct equivalent (iOS uses segmented controls or list selections)
- **Current Usage**: None found (0 instances)
- **Priority**: Low - Not currently used

### 13. **Progress Indicators** → `HydraProgressIndicator`
- **Material**: `CircularProgressIndicator`, `LinearProgressIndicator`
- **Cupertino**: `CupertinoActivityIndicator` (circular only, no linear)
- **Current Usage**: 
  - `notification_settings_screen.dart` (uses `CircularProgressIndicator`)
  - Various loading states
- **API Differences**: 
  - Material: `CircularProgressIndicator`, `LinearProgressIndicator` with `value`, `backgroundColor`, `color`
  - Cupertino: `CupertinoActivityIndicator` (only circular, no value/linear support)
- **Priority**: Low - Used but less critical for platform feel

### 14. **Refresh Indicator** → `HydraRefreshIndicator`
- **Material**: `RefreshIndicator`
- **Cupertino**: `CupertinoSliverRefreshControl` (works with `CustomScrollView`)
- **Current Usage**: 
  - May be used in scrollable lists
- **API Differences**: 
  - Material: Wraps scrollable widget
  - Cupertino: Must be used within `CustomScrollView` as a sliver
- **Priority**: Low - Less frequently used

### 15. **Back Button** → `HydraBackButton` (Already exists)
- **Current**: `HydraBackButton` exists in `lib/shared/widgets/hydra_back_button.dart`
- **Issue**: Need to verify if it branches on platform or always uses Material `BackButton`
- **Priority**: Low - Already exists, just needs verification

### 16. **IconButton** → `HydraIconButton`
- **Material**: `IconButton`
- **Cupertino**: `CupertinoButton` with icon (no direct `IconButton` equivalent)
- **Current Usage**: 
  - Used throughout the app (AppBar leading buttons, etc.)
- **Priority**: Low - Often wrapped in custom widgets, less critical

### 17. **AppBar** → `HydraAppBar`
- **Material**: `AppBar` widget
- **Cupertino**: `CupertinoNavigationBar` widget
- **Current Usage**: 
  - Used in most screens via `AppBar`
- **API Differences**: 
  - Material: `AppBar` with `title`, `actions`, `leading`, `backgroundColor`, etc.
  - Cupertino: `CupertinoNavigationBar` with `middle`, `leading`, `trailing`, different styling
- **Priority**: Low - High visual impact but would require significant refactoring

### 18. **Scaffold** → `HydraScaffold`
- **Material**: `Scaffold` widget
- **Cupertino**: `CupertinoPageScaffold` widget
- **Current Usage**: 
  - Used in all screens via `Scaffold`
- **API Differences**: 
  - Material: `Scaffold` with `appBar`, `body`, `bottomNavigationBar`, `floatingActionButton`, `drawer`
  - Cupertino: `CupertinoPageScaffold` with `navigationBar`, `child`, different structure
- **Priority**: Low - Core layout component, would require extensive refactoring

### 19. **Bottom Navigation Bar** → `HydraNavigationBar` (Already exists)
- **Current**: `HydraNavigationBar` exists in `lib/shared/widgets/navigation/hydra_navigation_bar.dart`
- **Issue**: Need to verify if it branches on platform
- **Priority**: Low - Already exists, just needs verification

### 20. **TabBar** → `HydraTabBar`
- **Material**: `TabBar` widget
- **Cupertino**: `CupertinoTabBar` widget (but used differently, typically with `CupertinoTabScaffold`)
- **Current Usage**: 
  - May be used in some screens
- **Priority**: Low - Less frequently used

---

## 📝 Notes

### Widgets That May Not Need Refactoring

1. **`RotatingWheelPicker`** (`lib/features/onboarding/widgets/rotating_wheel_picker.dart`)
   - Already wraps `CupertinoPicker`
   - Used specifically for iOS-style wheel pickers
   - May be intentionally iOS-only for onboarding UX
   - **Decision**: Keep as-is or make platform-adaptive if Android users need it

2. **`HydraTimePicker`** (`lib/shared/widgets/pickers/hydra_time_picker.dart`)
   - Currently always uses `CupertinoDatePicker` (iOS-style)
   - Should be made platform-adaptive to use Material `showTimePicker()` on Android

3. **Custom Wrappers**
   - `HydraButton`, `HydraFAB`, `HydraBackButton`, `HydraNavigationBar` already exist
   - Need to verify if they branch on platform or always use Material

### Implementation Order Recommendation

1. **Phase 1 (High Priority)**: ✅ Switch, ✅ Date Picker, ✅ Alert Dialog, ✅ Dialog, Bottom Sheet
2. **Phase 2 (Medium Priority)**: TextField, Time Picker (fix existing), SnackBar, verify existing buttons
3. **Phase 3 (Low Priority)**: Progress indicators, refresh indicator, AppBar, Scaffold (if needed)

### Testing Strategy

For each new `Hydra*` widget:
1. Test on Android device/emulator (should use Material widgets)
2. Test on iOS device/simulator (should use Cupertino widgets)
3. Verify API compatibility (all existing usages should work without changes)
4. Check visual consistency with platform design guidelines

---

## 🔍 Verification Checklist

Before marking a widget as "done", verify:
- [ ] Platform detection works correctly (`Theme.of(context).platform`)
- [ ] Material version works on Android
- [ ] Cupertino version works on iOS
- [ ] API mirrors Material widget (for backward compatibility)
- [ ] Handles API differences gracefully (Cupertino limitations)
- [ ] Exported from `lib/shared/widgets/widgets.dart`
- [ ] All existing usages updated to use new `Hydra*` widget
- [ ] No linter errors
- [ ] Manual QA on both platforms

