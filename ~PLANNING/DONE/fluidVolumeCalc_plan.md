# Fluid Volume Calculator - Weight-Based Feature

## ✅ IMPLEMENTATION COMPLETED

**Status**: Fully implemented and production-ready
**Completion Date**: November 2025

---

## Overview

Allows users to calculate administered fluid volume by weighing the fluid system (bag + giving set) before and after fluid therapy, instead of manual volume estimation.

**Core Formula**: Volume (mL) ≈ Initial Weight (g) - Final Weight (g)
**Assumption**: Ringer-Lactate density ≈ 1g/mL

---

## Implemented Architecture

### UI Implementation: Inline Calculator with Slide Animation

The calculator was implemented as an **inline view within the logging popup** using AnimatedSwitcher, rather than a separate dialog. This approach:
- Eliminates popup layering issues (no z-index conflicts)
- Keeps user in context with smooth transitions
- Provides cleaner UX without modal interruption
- Enables future reusability across multiple entry points

**View Modes:**
```dart
enum _FluidInputMode {
  standard,    // Normal logging form
  calculator,  // Weight calculator view
}
```

**UI Flow:**
1. User clicks "Calculate from weight" button in standard form
2. AnimatedSwitcher transitions to calculator view (250ms fade + slide)
3. User enters weights, sees live calculation
4. User clicks "Use This Volume" or back button
5. Returns to standard form with volume populated

### Key UI/UX Features

**Dynamic Context:**
- Popup title changes: "Log Fluid Session" → "Calculate Fluid Volume from Weight"
- Back button appears in popup header (calculator mode only)
- Daily summary banner and log button hidden in calculator mode
- Clean separation of concerns

**Animation:**
- 250ms duration with fade + subtle slide (0.03 offset)
- Respects reduce motion accessibility settings
- Matches existing ProgressDayDetailPopup pattern

**Calculator Form:**
- "Continue from same bag" banner (if data exists & <14 days)
- Initial and final weight inputs with inline validation
- Live volume calculation as user types
- Educational tips section
- Haptic feedback on success

---

## Technical Implementation Details

### Architecture Components

**1. WeightCalculatorService** (`lib/features/logging/services/weight_calculator_service.dart`)
- Handles validation, calculation, and SharedPreferences persistence
- Contains all data models (LastBagWeight, WeightValidationResult, WeightCalculatorResult)
- User+pet scoped keys: `last_bag_weight_v1_{userId}_{petId}`
- 14-day expiry for stored weights

**2. WeightCalculatorForm** (`lib/features/logging/widgets/weight_calculator_form.dart`)
- Reusable stateful widget with all calculator UI
- Accepts callbacks: `onVolumeCalculated()`, `onCancel()`
- Can be used inline or in dialogs
- Future-proof for multiple entry points

**3. WeightCalculatorDialog** (`lib/features/logging/widgets/weight_calculator_dialog.dart`)
- Lightweight wrapper around WeightCalculatorForm
- Maintains backward compatibility for dialog-based use cases
- Can be used elsewhere in the app if needed

**4. FluidLoggingScreen Integration** (`lib/features/logging/screens/fluid_logging_screen.dart`)
- View mode switching with AnimatedSwitcher
- Pending result pattern (only persist on successful save)
- Dynamic popup title based on mode
- Conditional back button in header

**5. LoggingPopupWrapper Enhancement** (`lib/features/logging/widgets/logging_popup_wrapper.dart`)
- Added optional `leading` widget parameter
- Follows Flutter's AppBar pattern
- Enables contextual header widgets (back button, etc.)

### Data Flow

```
User Input → WeightCalculatorService.validate()
          → WeightCalculatorService.calculateVolumeMl()
          → WeightCalculatorResult (via callback)
          → FluidLoggingScreen (populate volume, store pending result)
          → FluidSession.create() (include weight data)
          → Save to Firestore
          → WeightCalculatorService.saveLastBagWeight() (persist for next time)
```

### Weight Input Validation

| Rule | Value | Implementation |
|------|-------|----------------|
| **Minimum weight** | 10g | Hard-coded bounds in service |
| **Maximum weight** | 10,000g | Hard-coded bounds in service |
| **Decimal precision** | 1 decimal place | `RegExp(r'^\d*[.,]?\d{0,1}')` |
| **Negative difference** | final > initial | Validation + helpful error message |
| **Volume range** | 1-500 mL | Aligns with FluidSession model |

### Data Storage

**SharedPreferences (Device-Local):**
```json
{
  "last_bag_weight_v1_userId123_petIdAbc": {
    "finalWeightG": 850.0,
    "lastUsedDate": "2025-10-15T14:30:00Z",
    "usedWeightCalculator": true
  }
}
```

**FluidSession Model (Optional Fields):**
```dart
final bool? calculatedFromWeight;
final double? initialBagWeightG;  // grams
final double? finalBagWeightG;    // grams
```

### Riverpod Provider

Provider added to `lib/providers/logging_provider.dart`:
```dart
final weightCalculatorServiceProvider = Provider<WeightCalculatorService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return WeightCalculatorService(prefs);
});
```

---

## Production Quality Features

### Implemented Features
- ✅ **Inline calculator**: Smooth slide animation, no layering issues
- ✅ **Dynamic UI**: Title and back button change based on mode
- ✅ **Clean separation**: Logging context hidden in calculator mode
- ✅ **Localized**: All strings in l10n files (15 new strings)
- ✅ **Haptic feedback**: `HapticFeedback.mediumImpact()` on success
- ✅ **Smart validation**: Aligns with FluidSession model (1-500 mL)
- ✅ **Focus management**: Auto-clear keyboard on weight auto-fill
- ✅ **Live calculation**: Real-time volume display as user types
- ✅ **Disabled state**: Button disabled if validation fails
- ✅ **Accessibility**: Respects reduce motion settings

### Data Architecture
- ✅ **User+pet scoped keys**: Prevents cross-account clashes
- ✅ **Versioned schema**: v1 prefix for future migrations
- ✅ **Explicit units**: Field names use `G` suffix (grams)
- ✅ **No service changes**: LoggingService automatically handles new fields
- ✅ **Pending result pattern**: Only persist on successful save
- ✅ **Reusable components**: WeightCalculatorForm can be used anywhere

### DI & Testing
- ✅ **Existing provider reuse**: Uses `sharedPreferencesProvider`
- ✅ **Constructor injection**: Testable service design
- ✅ **Comprehensive validation**: Bounds, negative diff, volume range

---

## Actual File Structure

```
lib/features/logging/
├── models/
│   └── fluid_session.dart (MODIFIED - added 3 optional weight fields)
│
├── services/
│   ├── logging_service.dart (NO CHANGES - already handles all fields)
│   └── weight_calculator_service.dart (NEW - includes all data models)
│
├── widgets/
│   ├── weight_calculator_form.dart (NEW - reusable form widget)
│   ├── weight_calculator_dialog.dart (NEW - dialog wrapper for form)
│   └── logging_popup_wrapper.dart (MODIFIED - added leading parameter)
│
└── screens/
    └── fluid_logging_screen.dart (MODIFIED - inline calculator with AnimatedSwitcher)

lib/providers/
└── logging_provider.dart (MODIFIED - added weightCalculatorServiceProvider)

lib/l10n/
└── app_en.arb (MODIFIED - added 15 calculator strings)
```

**Note**: Data models (LastBagWeight, WeightValidationResult, WeightCalculatorResult) are defined inline within `weight_calculator_service.dart` rather than separate files, following the pattern of keeping related code together.

---

## Firebase Cost Optimization Compliance

✅ **No extra reads**: Last bag weight stored in SharedPreferences
✅ **No queries**: 14-day check done locally
✅ **No listeners**: Calculator is on-demand only
✅ **Batch writes**: Weight fields saved with existing session write
✅ **Optional fields**: Doesn't bloat documents for users not using feature
✅ **Offline-first**: SharedPreferences works offline

**Estimated Cost Impact**: Zero additional reads, zero additional writes (fields added to existing write operation)

---

## Localization Strings Added

All strings added to `lib/l10n/app_en.arb`:

```json
{
  "calculateFromWeight": "Calculate from weight",
  "weightCalculatorTitle": "Calculate Fluid Volume from Weight",
  "continueFromSameBag": "Continue from same bag?",
  "useThisWeight": "Use This Weight",
  "beforeFluidTherapy": "Before fluid therapy:",
  "initialWeightLabel": "Initial weight",
  "afterFluidTherapy": "After fluid therapy:",
  "finalWeightLabel": "Final weight",
  "fluidAdministered": "Fluid administered: ~{volume} mL",
  "ringersDensityNote": "(1g Ringer's ≈ 1mL)",
  "importantTipsTitle": "⚠️ Important tips:",
  "weightTip1": "Weigh same components both times",
  "weightTip2": "Use stable surface & calibrate scale",
  "useThisVolume": "Use This Volume",
  "remainingWeight": "{weight}g remaining",
  "lastUsedDate": "Last used {date}"
}
```

---

## Known Limitations & Trade-offs

1. **Multi-device behavior**: "Continue from same bag" is device-specific
   - Acceptable: This is a convenience feature, not critical data
   - Alternative would require Firestore query (not worth cost)

2. **Single active bag assumption**: Assumes one bag per pet at a time
   - Acceptable: Matches real-world usage patterns
   - User can always start fresh with new initial weight

3. **Fluid type assumption**: Hardcoded to Ringer-Lactate (1g ≈ 1mL)
   - Acceptable: Specified in requirements
   - Could be made configurable in future if needed

---

## Success Criteria (All Completed)

- ✅ User can calculate fluid volume from weights
- ✅ Calculator accessible from logging screen (inline)
- ✅ Previous bag weight auto-fills when available (<14 days)
- ✅ Input validation catches common errors
- ✅ Weight data optionally saved with session
- ✅ Zero additional Firestore reads
- ✅ UI/UX smooth and intuitive with slide animation
- ✅ Popup layering issue resolved (inline implementation)
- ✅ Dynamic title and contextual back button
- ✅ Clean separation of logging vs calculator context

---

## Future Enhancements

The architecture supports these future improvements:

1. **Multiple Entry Points**
   - WeightCalculatorForm can be used in Profile/Settings for education
   - Can be embedded in help screens or tutorials
   - Dialog wrapper still available for modal contexts

2. **Additional Validations**
   - Could add warnings for unusual weight differences
   - Could track accuracy over time for user feedback

3. **Enhanced Analytics**
   - Weight data is stored in FluidSession for future analysis
   - Could compare weight-based vs manual volume estimates
   - Could identify patterns or inconsistencies

4. **Multi-fluid Support**
   - Currently assumes Ringer-Lactate (1g ≈ 1mL)
   - Could add dropdown for different fluid types with different densities
   - Would require minor service updates

---

## Implementation Notes

**Total Implementation Time**: ~6 hours (including refactoring to inline approach)

**Key Decisions:**
1. **Inline vs Dialog**: Chose inline implementation to solve popup layering issues and provide better UX
2. **AnimatedSwitcher**: Used existing pattern from ProgressDayDetailPopup for consistency
3. **Single File for Models**: Kept data models in service file rather than separate files (simpler, related code together)
4. **Dynamic Title**: Made popup title context-aware for better user clarity
5. **Leading Parameter**: Enhanced LoggingPopupWrapper to support contextual header widgets (reusable pattern)

**Challenges Solved:**
- Popup layering (z-index conflicts) → Inline implementation
- Duplicate headers → Moved back button to popup header via leading parameter
- Context mixing → Clean separation with conditional rendering based on mode
- Layout overflow → Used Expanded widget for title text
- Accessibility → Respects reduce motion settings via AppAnimations.getDuration()

---

## Testing Recommendations

While the feature is production-ready, these tests would further strengthen it:

**Unit Tests (Future):**
- WeightCalculatorService validation logic
- 14-day expiry calculation
- Volume calculation edge cases

**Widget Tests (Future):**
- WeightCalculatorForm state management
- Live calculation updates
- Button enable/disable logic

**Integration Tests (Future):**
- Full flow: calculate → populate → save → persist
- SharedPreferences persistence
- Firestore data verification

**Manual Testing (Completed):**
- ✅ Calculator opens with smooth animation
- ✅ "Continue from same bag" shows when applicable
- ✅ Live calculation works as user types
- ✅ Validation catches all error cases
- ✅ Volume populates correctly in standard form
- ✅ Weight data persists in Firestore
- ✅ Last bag weight saved for next session
- ✅ No layering issues or visual glitches
- ✅ Accessibility (reduce motion) works correctly
