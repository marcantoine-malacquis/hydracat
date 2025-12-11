# Platform-Specific Widgets to Refactor

This document lists all Material Design and Cupertino widgets used directly in the codebase that should be refactored into platform-adaptive wrappers (similar to `HydraSlider`).

## Implementation Pattern

For each widget listed below, create a `Hydra*` wrapper in `lib/shared/widgets/` that:
1. Detects platform via `Theme.of(context).platform` or `defaultTargetPlatform`
2. Returns Material widget on Android/other platforms
3. Returns Cupertino widget on iOS/macOS
4. Mirrors the core API of the Material widget (since that's what's currently used)
5. Handles API differences between Material and Cupertino gracefully

### Performance Optimization

**Important**: To minimize performance overhead, cache the platform detection result in `build()` and pass it down to helper methods:

```dart
@override
Widget build(BuildContext context) {
  final platform = Theme.of(context).platform;
  final isCupertino = platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;
  
  // Pass isCupertino to helper methods instead of calling Theme.of() again
  return _buildContent(context, isCupertino);
}
```

This avoids multiple `Theme.of(context)` lookups during the same build cycle, which can impact performance especially in widgets with many helper methods or frequent rebuilds.

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
  - **Automatic bottom breathing room**: All bottom sheets automatically include safe area spacing plus a minimum breathing room constant (see `AppSpacing.bottomSheetInset`) to ensure content and primary actions have comfortable clearance from the system home indicator on all platforms
  - **Used in**: 
    - `notification_settings_screen.dart` (migrated to use `showHydraBottomSheet`)
    - `permission_preprompt.dart` (migrated to use `showHydraBottomSheet`)
    - `debug_panel.dart` (migrated to use `showHydraBottomSheet`)
    - Logging screens (fluid, medication, weight, symptoms)
    - Progress day detail popup
  - **API Differences**: 
    - Material: `showModalBottomSheet()` with full Material API support (`isScrollControlled`, `enableDrag`, `shape`, etc.)
    - Cupertino: `showCupertinoModalPopup()` with simplified API; Material-specific options are gracefully ignored
  - **Note**: The `useSafeArea` parameter in `showHydraBottomSheet()` defaults to `false` because `HydraBottomSheet` handles safe area spacing internally. Setting it to `true` may result in double-padding.

- **`HydraTextField`** (`lib/shared/widgets/inputs/hydra_text_field.dart`) - ✅ Done
  - Wraps `TextField` (Material) / `CupertinoTextField` (iOS)
  - Mirrors the core `TextField` API used in the app
  - **Material**: `TextField` widget with full `InputDecoration` support
  - **Cupertino**: `CupertinoTextField` widget with mapped decoration properties
  - **Used in**: 
    - `symptoms_entry_dialog.dart` (notes field)
    - `weight_entry_dialog.dart` (weight input, notes)
    - `fluid_logging_screen.dart`
    - `volume_input_adjuster.dart` (internal)
    - `progress_day_detail_popup.dart` (notes)
    - `weight_calculator_form.dart`
    - `medication_dosage_input.dart`
    - `medication_logging_screen.dart`
  - **API Differences**: 
    - Material: Full `InputDecoration` support including `errorText`, `counter`, `labelText`, `hintText`, `suffixText`, etc.
    - Cupertino: `placeholder` from `decoration?.hintText`, `prefix`/`suffix` from `decoration?.prefixIcon`/`suffixIcon` or `suffixText`. Error text and counter are shown separately below the field on iOS.

- **`HydraDropdown`** (`lib/shared/widgets/inputs/hydra_dropdown.dart`) - ✅ Done
  - Wraps `CustomDropdown` (Material) / `CupertinoButton` + bottom sheet (iOS/macOS)
  - Platform-adaptive dropdown with native-feeling iOS bottom sheet selector
  - Mirrors the core `CustomDropdown` API used in the app
  - **Material**: `CustomDropdown` widget with overlay-based dropdown menu
  - **Cupertino**: `CupertinoButton` that opens a modal bottom sheet with `CupertinoListTile` options, matching iOS native patterns
  - **Used in**: 
    - `symptoms_screen.dart` (symptom selector)
    - `add_medication_screen.dart` (medication unit and strength unit selectors)
  - **API Differences**: 
    - Material: Uses `CustomDropdown` with overlay positioning, scrollable menu, checkmarks for selected items
    - Cupertino: Uses `CupertinoButton` styled as form field, opens `showHydraBottomSheet` with `HydraBottomSheet` containing scrollable list of `CupertinoListTile` options with trailing checkmarks

- **`HydraTimePicker`** (`lib/shared/widgets/pickers/hydra_time_picker.dart`) - ✅ Done
  - Wraps `showTimePicker()` (Material) / `CupertinoDatePicker` with custom bottom sheet (iOS/macOS)
  - Includes `show()` static method
  - **Material**: `showTimePicker()` function with Material time picker dialog
  - **Cupertino**: `showCupertinoModalPopup()` with custom wheel picker and digital display
  - **Used in**: 
    - `time_picker_group.dart` (onboarding)
    - `fluid_schedule_screen.dart` (profile)
  - **API Differences**: 
    - Material: `showTimePicker()` with standard Material time picker dialog
    - Cupertino: Custom bottom sheet with `CupertinoDatePicker` wheel, Cancel/Done buttons, and digital time display

- **`HydraSnackBar`** (`lib/shared/widgets/feedback/hydra_snack_bar.dart`) - ✅ Done
  - Wraps `SnackBar` (Material) / custom toast overlay (iOS/macOS)
  - **Material**: `SnackBar` widget + `ScaffoldMessenger.of(context).showSnackBar()`
  - **Cupertino**: Custom toast overlay positioned above bottom navigation bar
  - **API**: 
    - `HydraSnackBar.showSuccess(context, message, {duration})` - Success messages (teal)
    - `HydraSnackBar.showError(context, message, {duration})` - Error messages (red)
    - `HydraSnackBar.showInfo(context, message, {duration})` - Info messages (neutral)
    - `HydraSnackBar.show(context, message, {type, actionLabel, onAction, duration})` - Low-level with actions
  - **Platform Behavior**: 
    - **Material**: Uses `SnackBar` with floating behavior and rounded corners
    - **iOS/macOS**: Custom capsule-shaped toast with fade/slide animations, positioned above nav bar
  - **API Differences**: 
    - Material: Full `SnackBar` API with `action`, `duration`, `backgroundColor`, etc.
    - Cupertino: Custom toast overlay; actions rendered as tappable text within toast
  - **Used in**: All existing SnackBar usages have been migrated across the app

- **`HydraSlidingSegmentedControl`** (`lib/shared/widgets/inputs/hydra_sliding_segmented_control.dart`) - ✅ Done
  - Wraps `SegmentedButton` / custom segmented control (Material) / `CupertinoSlidingSegmentedControl` (iOS/macOS)
  - Platform-adaptive segmented control with a sliding selection pill
  - Supports 2+ segments (e.g. Week/Month, Week/Month/Year)
  - Provides a simple, generic API mapping to both Material and Cupertino variants
  - **Material**: Custom Material-styled segmented control with animated sliding pill
  - **Cupertino**: `CupertinoSlidingSegmentedControl` widget
  - **Used in**: 
    - `progress_week_calendar.dart` (replaced `_SlidingSegmentedControl`)
    - `weight_screen.dart` (replaced `SegmentedButton` granularity selector)

- **`HydraList`** (`lib/shared/widgets/lists/hydra_list.dart`) - ✅ Done
  - Wraps `ListView/ListTile` (Material) / `CupertinoListSection/CupertinoListTile` (iOS/macOS)
  - Supports header/footer, inset grouped styling, optional dividers, and per-item destructive/chevron flags
  - Provides `HydraListItem` data model and `HydraListTile` widget for standalone use

- **`HydraButton`** (`lib/shared/widgets/buttons/hydra_button.dart`) - ✅ Done
  - Wraps `ElevatedButton` (Material) / `CupertinoButton` (iOS/macOS)
  - Platform-adaptive button with variants (primary, secondary, text) and sizing support
  - Mirrors the core Material button API used in the app
  - **Material**: `ElevatedButton` widget with custom styling for variants
  - **Cupertino**: `CupertinoButton.filled` (primary), `CupertinoButton` with border decoration (secondary), plain `CupertinoButton` (text)
  - **Used in**: 
    - Used throughout the app via `HydraButton` (25+ usages)
    - `login_screen.dart`, `register_screen.dart`, `forgot_password_screen.dart`
    - `onboarding_screen_wrapper.dart`, `welcome_screen.dart`, `pet_basics_screen.dart`
    - `treatment_confirmation_popup.dart`, `component_demo_screen.dart`
    - And many more screens
  - **API Differences**: 
    - Material: Full `ElevatedButton` API with `ButtonStyle`, `elevation`, `side` (for secondary)
    - Cupertino: `CupertinoButton` / `CupertinoButton.filled` with `color`, `disabledColor`, `borderRadius`; secondary variant uses `Container` with border decoration
  - **Variant Mapping**:
    - `primary`: Material → `ElevatedButton` with teal background; Cupertino → `CupertinoButton.filled` with teal color
    - `secondary`: Material → `ElevatedButton` with transparent background and border; Cupertino → `CupertinoButton` with border decoration
    - `text`: Material → `ElevatedButton` with transparent background; Cupertino → plain `CupertinoButton` with transparent background

- **`HydraFab`** (`lib/shared/widgets/buttons/hydra_fab.dart`) - ✅ Done
  - Wraps `FloatingActionButton` (Material) / custom circular button (iOS/macOS)
  - Platform-adaptive floating action button with droplet design
  - **Material**: `FloatingActionButton` widget with Material styling and ink ripple effects. Tooltips are supported.
  - **Cupertino**: Custom circular button using `GestureDetector` with Cupertino styling. Tooltips are not supported (tooltip parameter is ignored).
  - **Used in**: 
    - `hydra_navigation_bar.dart` (uses `HydraFab` with `onPressed`, `onLongPress`, `icon`, `isLoading`)
  - **API Differences**: 
    - Material: Full `FloatingActionButton` API with `tooltip`, `elevation`, Material ink ripple
    - Cupertino: Custom implementation; tooltips are ignored, no ink ripple, uses `GestureDetector` for interactions

- **`HydraExtendedFab`** (`lib/shared/widgets/buttons/hydra_fab.dart`) - ✅ Done
  - Wraps `FloatingActionButton.extended` (Material) / custom pill button (iOS/macOS)
  - Platform-adaptive extended floating action button with label support
  - **Material**: `FloatingActionButton.extended` widget with Material styling and ink ripple effects. Supports glass morphism effect via custom `BackdropFilter` implementation.
  - **Cupertino**: Custom pill-shaped button using `GestureDetector` or `CupertinoButton` with Cupertino styling. Glass morphism effect is supported on both platforms.
  - **Used in**: 
    - `symptoms_screen.dart` (uses `HydraExtendedFab` with glass effect)
    - `weight_screen.dart` (uses `HydraExtendedFab` with glass effect)
  - **API Differences**: 
    - Material: Full `FloatingActionButton.extended` API with `elevation`, Material ink ripple
    - Cupertino: Custom implementation; no ink ripple, uses `GestureDetector` or `CupertinoButton` for interactions

- **`HydraProgressIndicator`** (`lib/shared/widgets/feedback/hydra_progress_indicator.dart`) - ✅ Done
  - Wraps `CircularProgressIndicator`, `LinearProgressIndicator` (Material) / `CupertinoActivityIndicator`, `CupertinoLinearActivityIndicator` (iOS/macOS)
  - Platform-adaptive progress indicator with support for circular and linear types
  - **Material**: `CircularProgressIndicator` or `LinearProgressIndicator` depending on `type` parameter
  - **Cupertino**: 
    - Circular type: `CupertinoActivityIndicator` (indeterminate only; `value` is ignored)
    - Linear type with determinate `value`: `CupertinoLinearActivityIndicator` (supports `value`, `color`, `minHeight` → `height`)
    - Linear type without `value`: falls back to `CupertinoActivityIndicator` (indeterminate)
  - **Used in**: 
    - `notification_settings_screen.dart` (migrated)
    - `loading_overlay.dart` (migrated)
    - `fluid_daily_summary_card.dart` (migrated - linear type)
    - `hydra_button.dart` (migrated)
    - `hydra_fab.dart` (migrated)
    - `app_shell.dart` (migrated)
    - `selection_card.dart` (migrated)
    - `water_drop_progress_card.dart` (migrated)
    - `app.dart` (migrated)
    - `social_signin_buttons.dart` (migrated)
    - `email_verification_screen.dart` (migrated)
    - `weight_screen.dart` (migrated)
    - `treatment_popup_wrapper.dart` (migrated)
    - `medication_summary_card.dart` (migrated)
    - And other loading states throughout the app
  - **API Differences**: 
    - Material: `CircularProgressIndicator`, `LinearProgressIndicator` with `value`, `backgroundColor`, `color`, `strokeWidth` (circular), `minHeight` (linear)
    - Cupertino: 
      - Circular: `CupertinoActivityIndicator` (indeterminate only; `value`, `backgroundColor`, `strokeWidth` are ignored)
      - Linear (determinate): `CupertinoLinearActivityIndicator` with `progress` (from `value`), `color`, `height` (from `minHeight`, defaults to 4.5); `backgroundColor` is ignored
      - Linear (indeterminate): falls back to `CupertinoActivityIndicator`

- **`HydraRefreshIndicator`** (`lib/shared/widgets/feedback/hydra_refresh_indicator.dart`) - ✅ Done
  - Wraps `RefreshIndicator` (Material) / `CupertinoSliverRefreshControl` (iOS/macOS)
  - Platform-adaptive refresh indicator for pull-to-refresh functionality
  - **Material**: `RefreshIndicator` widget that wraps scrollable widgets
  - **Cupertino**: `CupertinoSliverRefreshControl` within `CustomScrollView` (automatically converts `SingleChildScrollView` and other scrollables to `CustomScrollView`)
  - **Used in**: 
    - `progress_screen.dart` (migrated)
    - `profile_screen.dart` (migrated)
    - `fluid_schedule_screen.dart` (migrated)
    - `ckd_profile_screen.dart` (migrated)
    - `medication_schedule_screen.dart` (migrated)
  - **API Differences**: 
    - Material: `RefreshIndicator` with full API support (`onRefresh`, `color`, `backgroundColor`, `displacement`, `edgeOffset`, `strokeWidth`, `triggerMode`)
    - Cupertino: `CupertinoSliverRefreshControl` within `CustomScrollView`; automatically handles conversion of `SingleChildScrollView` and other scrollables to `CustomScrollView` with slivers. Material-specific options like `color`, `backgroundColor`, `displacement`, `edgeOffset`, `strokeWidth`, and `triggerMode` are ignored on iOS/macOS.

- **`HydraAppBar`** (`lib/shared/widgets/navigation/hydra_app_bar.dart`) - ✅ Done
  - Wraps `AppBar` (Material) / `CupertinoNavigationBar` (iOS/macOS)
  - Platform-adaptive app bar with support for title, actions, leading, and styling
  - **Material**: `AppBar` widget with full Material API support
  - **Cupertino**: `CupertinoNavigationBar` widget with mapped properties
  - **Used in**:
    - `home_screen.dart` (migrated)
    - `profile_screen.dart` (migrated)
    - `progress_screen.dart` (migrated)
    - `medication_schedule_screen.dart` (migrated)
    - `fluid_schedule_screen.dart` (migrated)
    - `ckd_profile_screen.dart` (migrated)
    - `weight_screen.dart` (migrated)
    - `symptoms_screen.dart` (migrated)
    - `settings_screen.dart` (migrated)
    - `notification_settings_screen.dart` (migrated)
    - `login_screen.dart` (migrated)
    - `register_screen.dart` (migrated)
    - `forgot_password_screen.dart` (migrated)
    - `email_verification_screen.dart` (migrated)
    - `create_fluid_schedule_screen.dart` (migrated)
    - `onboarding_screen_wrapper.dart` (migrated)
    - `discover_screen.dart` (migrated)
    - `schedule_screen.dart` (migrated)
    - `injection_sites_analytics_screen.dart` (migrated)
    - `component_demo_screen.dart` (migrated)
  - **API Differences**: 
    - Material: Full `AppBar` API with `title`, `actions`, `leading`, `backgroundColor`, `foregroundColor`, `elevation`, `centerTitle`, `automaticallyImplyLeading`, `toolbarHeight`
    - Cupertino: `title` maps to `middle`, `actions` maps to `trailing` (wrapped in `Row` if multiple), `leading` maps directly. `backgroundColor` is applied where supported. `elevation` is ignored (Cupertino doesn't use elevation). `foregroundColor` affects text color. `centerTitle` controls title alignment. `automaticallyImplyLeading` is ignored (Cupertino doesn't auto-show back button). Transparent `backgroundColor` removes the border for a cleaner look.

- **`HydraNavigationBar`** (`lib/shared/widgets/navigation/hydra_navigation_bar.dart`) - ✅ Done
  - Custom bottom navigation bar with platform-adaptive styling and animations
  - Features: 4 navigation items (Home, Schedule, Progress, Profile) with centered FAB, top selection indicators, accessibility support
  - **Material**: Custom container with elevation/shadow, 160ms animations, 26px icons, w600 font weight for selected items
  - **Cupertino**: Custom container with border-only separator (no shadow), 120ms animations, 24px icons, w500 font weight for selected items, uses `CupertinoColors.separator` for border
  - **Used in**: 
    - `app_shell.dart` (main app navigation)
  - **API Differences**: 
    - Material: Uses elevation/shadow for depth, standard Material motion (160ms), larger icons (26px), heavier font weight (w600)
    - Cupertino: Flat design with border-only separator (0.5px hairline), lighter animations (120ms), smaller icons (24px), lighter font weight (w500), uses `Curves.easeOut` for snappier feel vs Material's `Curves.easeInOut`

- **`HydraBackButton`** (`lib/shared/widgets/hydra_back_button.dart`) - ✅ Done
  - Wraps `IconButton` (Material) / `CupertinoNavigationBarBackButton` (iOS/macOS)
  - Platform-adaptive back button with consistent styling and behavior
  - **Material**: `IconButton` widget with iOS-style chevron icon (Icons.arrow_back_ios), 20px icon size, textSecondary color (#636E72), and tooltip support
  - **Cupertino**: `CupertinoNavigationBarBackButton` widget with native iOS styling and behavior. Tooltips are not supported on Cupertino (tooltip parameter is ignored).
  - **Used in**: 
    - `settings_screen.dart` (migrated)
    - `weight_screen.dart` (migrated)
    - `symptoms_screen.dart` (migrated)
    - `medication_schedule_screen.dart` (migrated)
    - `ckd_profile_screen.dart` (migrated)
    - `fluid_schedule_screen.dart` (migrated)
    - `notification_settings_screen.dart` (migrated)
    - `progress_day_detail_popup.dart` (migrated)
    - `fluid_logging_screen.dart` (migrated)
  - **API Differences**: 
    - Material: Full `IconButton` API with `tooltip`, `color`, `iconSize`, etc.
    - Cupertino: `CupertinoNavigationBarBackButton` with `onPressed`; `tooltip` is ignored, color is controlled via `CupertinoTheme` override to match `AppColors.textSecondary`

---

## 🔴 High Priority (Frequently Used, High Visual Impact)

---

## 🟡 Medium Priority (Moderately Used, Moderate Visual Impact)

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

### 16. **IconButton** → `HydraIconButton`
- **Material**: `IconButton`
- **Cupertino**: `CupertinoButton` with icon (no direct `IconButton` equivalent)
- **Current Usage**: 
  - Used throughout the app (AppBar leading buttons, etc.)
- **Priority**: Low - Often wrapped in custom widgets, less critical

### 18. **Scaffold** → `HydraScaffold`
- **Material**: `Scaffold` widget
- **Cupertino**: `CupertinoPageScaffold` widget
- **Current Usage**: 
  - Used in all screens via `Scaffold`
- **API Differences**: 
  - Material: `Scaffold` with `appBar`, `body`, `bottomNavigationBar`, `floatingActionButton`, `drawer`
  - Cupertino: `CupertinoPageScaffold` with `navigationBar`, `child`, different structure
- **Priority**: Low - Core layout component, would require extensive refactoring

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
   - ✅ Platform-adaptive implementation complete
   - Uses Material `showTimePicker()` on Android, Cupertino wheel picker on iOS/macOS

3. **Custom Wrappers**
   - `HydraButton`, `HydraFAB`, `HydraBackButton`, `HydraNavigationBar` already exist
   - Need to verify if they branch on platform or always use Material

### Implementation Order Recommendation

1. **Phase 1 (High Priority)**: ✅ Switch, ✅ Date Picker, ✅ Alert Dialog, ✅ Dialog, Bottom Sheet
2. **Phase 2 (Medium Priority)**: ✅ TextField, ✅ Time Picker, ✅ SnackBar, ✅ Sliding Segmented Control, verify existing buttons
3. **Phase 3 (Low Priority)**: ✅ Progress indicators, refresh indicator, AppBar, Scaffold (if needed)

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

