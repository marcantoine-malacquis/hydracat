# Fluid Volume Calculator - Weight-Based Feature

## Overview
Allow users to calculate administered fluid volume by weighing the fluid system (bag + giving set) before and after fluid therapy, instead of manual volume estimation.

**Core Formula**: Volume (mL) ≈ Initial Weight (g) - Final Weight (g)
**Assumption**: Ringer-Lactate density ≈ 1g/mL

---

## User Experience

### UI Location
Integrated into existing logging flow as a secondary option:

```
┌─────────────────────────────────────────┐
│ Volume per session (mL): [___150___]    │
│              [📊 Calculate from weight] │
└─────────────────────────────────────────┘
```

### Weight Calculator Dialog

**Opening Dialog:**
```
┌──────────────────────────────────────────┐
│   Calculate Fluid Volume from Weight    │
├──────────────────────────────────────────┤
│                                          │
│ Continue from same bag?                  │
│ ┌────────────────────────────────────┐  │
│ │ 850g remaining (last used Oct 15)  │  │
│ │         [Use This Weight]          │  │
│ └────────────────────────────────────┘  │
│                                          │
│ Before fluid therapy:                    │
│ Initial weight: [_______] g              │
│                                          │
│ After fluid therapy:                     │
│ Final weight: [_______] g                │
│                                          │
│ ─────────────────────────────────────   │
│ Fluid administered: ~XX mL               │
│ (1g Ringer's ≈ 1mL)                     │
│                                          │
│ ⚠️ Important tips:                       │
│ • Weigh same components both times      │
│ • Use stable surface & calibrate scale  │
│                                          │
│     [Cancel]      [Use This Volume]     │
└──────────────────────────────────────────┘
```

**Continue from Same Bag Feature:**
- Shows banner ONLY if:
  - Last session for this pet used weight calculator
  - Last session was within 14 days
  - Data stored locally in SharedPreferences
- "Use This Weight" button fills initial weight field
- User can always override and enter different weight

**Live Calculation:**
- Show calculated volume as soon as final weight is entered
- Update in real-time as user types

---

## Technical Specifications

### Weight Input Validation

| Rule | Value | Error Message |
|------|-------|---------------|
| **Minimum weight** | 10g | "Please enter a weight between 10g and 10,000g" |
| **Maximum weight** | 10,000g | "Please enter a weight between 10g and 10,000g" |
| **Decimal precision** | 1 decimal place | Auto-format (e.g., 850.5g) |
| **Negative difference** | final > initial | "Final weight cannot be greater than initial weight. Did you swap the measurements?" |
| **Volume range** | 1-500 mL | "Calculated volume must be between 1 and 500 mL" |

**Reasonable bounds rationale**: Medical fluid bags typically range from small syringes (10-50g) to large IV bags (1000-5000g). Catches typo errors.

**Volume validation alignment**: The 1-500 mL constraint matches the existing `FluidSession` model validation. The "Use This Volume" button is disabled if the calculated volume falls outside this range, preventing invalid data from being returned.

### Data Storage Strategy

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

**Key Format:** `last_bag_weight_v1_{userId}_{petId}`
- **Versioned (v1)**: Allows painless future schema changes
- **User-scoped**: Prevents cross-account clashes on shared devices
- **Pet-specific**: Each pet tracks its own bag weight
- **Explicit units**: Field names use `G` suffix (grams) to avoid ambiguity

**Why SharedPreferences?**
- Zero Firestore reads (complies with firebase_CRUDrules.md)
- Fast local access
- Acceptable limitation: feature is device-specific (not critical for multi-device sync)

**FluidSession Model (Optional Fields):**
```dart
class FluidSession {
  // ... existing fields ...

  // New optional fields (all weights in grams for clarity)
  final bool? calculatedFromWeight;
  final double? initialBagWeightG;  // Explicitly grams
  final double? finalBagWeightG;    // Explicitly grams
}
```

**Firestore Impact:**
- Adds 3 optional fields to session documents
- No extra reads required
- No queries needed (14-day check done locally)
- Fields written in same batch as session save

---

## Key Implementation Highlights

### Production Quality Features
- ✅ **Localized**: All strings in l10n files (no hardcoded text)
- ✅ **Haptic feedback**: `HapticFeedback.mediumImpact()` on success
- ✅ **Smart validation**: Aligns with FluidSession model (1-500 mL)
- ✅ **Focus management**: Auto-clear keyboard on weight auto-fill
- ✅ **Live calculation**: Real-time volume display as user types
- ✅ **Disabled state**: Button disabled if validation fails

### Data Architecture
- ✅ **User+pet scoped keys**: `last_bag_weight_v1_{userId}_{petId}`
- ✅ **Versioned schema**: v1 prefix for future migrations
- ✅ **Explicit units**: Field names use `G` suffix (grams)
- ✅ **No service changes**: LoggingService automatically handles new fields
- ✅ **Pending result pattern**: Only persist on successful save

### DI & Testing
- ✅ **Existing provider reuse**: Uses `sharedPreferencesProvider`
- ✅ **Constructor injection**: Testable service design
- ✅ **Comprehensive validation**: Bounds, negative diff, volume range

---

## Implementation Plan

### Phase 1: Foundation & Service Layer

**1.1 Create WeightCalculatorService**
- Location: `lib/features/logging/services/weight_calculator_service.dart`
- Dependencies: SharedPreferences

**Implementation:**
```dart
class WeightCalculatorService {
  WeightCalculatorService(this._prefs);
  final SharedPreferences _prefs;

  // Generate versioned, user+pet-scoped key
  String _key(String userId, String petId) =>
    'last_bag_weight_v1_${userId}_$petId';

  // Save last bag weight (user+pet scoped)
  Future<void> saveLastBagWeight({
    required String userId,
    required String petId,
    required double finalWeightG,
  }) async {
    final data = LastBagWeight(
      finalWeightG: finalWeightG,
      lastUsedDate: DateTime.now(),
      usedWeightCalculator: true,
    );
    await _prefs.setString(_key(userId, petId), jsonEncode(data.toJson()));
  }

  // Get last bag weight (returns null if >14 days or doesn't exist)
  LastBagWeight? getLastBagWeight({
    required String userId,
    required String petId,
  }) {
    final raw = _prefs.getString(_key(userId, petId));
    if (raw == null) return null;

    final data = LastBagWeight.fromJson(
      jsonDecode(raw) as Map<String, dynamic>
    );
    if (data == null) return null;

    // Check 14-day expiry
    if (DateTime.now().difference(data.lastUsedDate).inDays > 14) {
      return null;
    }
    return data;
  }

  // Calculate volume (clamped to non-negative)
  double calculateVolumeMl(double initialG, double finalG) =>
    (initialG - finalG).clamp(0, double.infinity);

  // Validate weights and enforce session constraints
  WeightValidationResult validate({
    required double? initialG,
    required double? finalG,
  }) {
    const min = 10.0, max = 10000.0;

    if (initialG == null || finalG == null) {
      return const WeightValidationResult(
        false,
        'Please enter both weights'
      );
    }

    if (initialG < min || initialG > max || finalG < min || finalG > max) {
      return const WeightValidationResult(
        false,
        'Please enter a weight between 10g and 10,000g'
      );
    }

    if (finalG > initialG) {
      return const WeightValidationResult(
        false,
        'Final weight cannot be greater than initial weight. Did you swap the measurements?'
      );
    }

    final vol = initialG - finalG;
    if (vol < 1 || vol > 500) {
      return const WeightValidationResult(
        false,
        'Calculated volume must be between 1 and 500 mL'
      );
    }

    return const WeightValidationResult(true);
  }
}
```

**Key Design Decisions:**
- Constructor injection of `SharedPreferences` (testable)
- User+pet scoped keys prevent cross-account issues
- Versioned keys (v1) for future schema evolution
- Explicit grams suffix (`G`) for clarity
- Validates against FluidSession constraints (1-500 mL)

**1.2 Create Data Models**
- Location: `lib/features/logging/models/`

```dart
// last_bag_weight.dart
class LastBagWeight {
  final double finalWeightG;
  final DateTime lastUsedDate;
  final bool usedWeightCalculator;

  const LastBagWeight({
    required this.finalWeightG,
    required this.lastUsedDate,
    required this.usedWeightCalculator,
  });

  Map<String, dynamic> toJson() => {
    'finalWeightG': finalWeightG,
    'lastUsedDate': lastUsedDate.toIso8601String(),
    'usedWeightCalculator': usedWeightCalculator,
  };

  static LastBagWeight? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    return LastBagWeight(
      finalWeightG: (json['finalWeightG'] as num).toDouble(),
      lastUsedDate: DateTime.parse(json['lastUsedDate'] as String),
      usedWeightCalculator: json['usedWeightCalculator'] == true,
    );
  }
}

// weight_validation_result.dart
class WeightValidationResult {
  final bool isValid;
  final String? errorMessage;

  const WeightValidationResult(this.isValid, [this.errorMessage]);
}

// weight_calculator_result.dart
class WeightCalculatorResult {
  final double volumeMl;
  final double initialWeightG;
  final double finalWeightG;

  const WeightCalculatorResult({
    required this.volumeMl,
    required this.initialWeightG,
    required this.finalWeightG,
  });
}
```

**1.3 Update FluidSession Model**
- Add 3 optional nullable fields with explicit grams suffix
- Update `toJson()`, `fromJson()`, `copyWith()`, `==`, `hashCode`, and `toString()` methods
- No migration needed (fields are optional)

**Files to modify:**
- `lib/features/logging/models/fluid_session.dart`

**Field additions:**
```dart
// Add to class properties:
final bool? calculatedFromWeight;
final double? initialBagWeightG;  // grams
final double? finalBagWeightG;    // grams

// Add to toJson():
'calculatedFromWeight': calculatedFromWeight,
'initialBagWeightG': initialBagWeightG,
'finalBagWeightG': finalBagWeightG,

// Add to fromJson():
calculatedFromWeight: json['calculatedFromWeight'] as bool?,
initialBagWeightG: (json['initialBagWeightG'] as num?)?.toDouble(),
finalBagWeightG: (json['finalBagWeightG'] as num?)?.toDouble(),

// Add to copyWith():
bool? calculatedFromWeight,
double? initialBagWeightG,
double? finalBagWeightG,
```

**1.4 Create Riverpod Provider**
```dart
// lib/features/logging/providers/weight_calculator_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/features/logging/services/weight_calculator_service.dart';
import 'package:hydracat/providers/logging_provider.dart'; // or wherever sharedPreferencesProvider lives

final weightCalculatorServiceProvider = Provider<WeightCalculatorService>((ref) {
  final prefs = ref.read(sharedPreferencesProvider);
  return WeightCalculatorService(prefs);
});
```

**Important:** Use the existing `sharedPreferencesProvider` from your DI setup. This allows tests to inject mock preferences and follows your established patterns.

---

### Phase 2: UI Components

**2.1 Input Formatting**
- Use inline decimal formatter (avoid creating new file for simplicity)
- Allow digits with max 1 decimal place
- Show unit suffix inline: "Initial weight: [___] g"

**Simple inline formatter example:**
```dart
TextInputFormatter _decimalFormatter() {
  return FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}'));
}
```

**2.2 Create WeightCalculatorDialog**
- Location: `lib/features/logging/widgets/weight_calculator_dialog.dart`
- StatefulWidget with form validation
- Constructor parameters: `userId`, `petId`

**Key Components:**
- Conditional "Continue from same bag?" banner (only if data exists & <14 days)
- Two TextFormField widgets with unit suffix: "Initial weight: [___] g"
- Live calculation display (updates as user types)
- Educational tips section
- Cancel & "Use This Volume" buttons

**UX Enhancements:**
- **Haptic feedback:** Trigger `HapticFeedback.mediumImpact()` on successful "Use This Volume" press
- **Focus management:** Clear keyboard focus when "Use This Weight" button is pressed
- **Button state:** Disable "Use This Volume" if validation fails (volume out of 1-500 mL range)
- **Inline units:** Show "g" suffix next to input fields for clarity
- **Live validation:** Show calculated volume in real-time as user types final weight
- **Localization:** All strings from l10n files (no hardcoded text)

**State Management:**
- Local state for weight inputs
- Use `WeightCalculatorService` for validation & calculation
- Return `WeightCalculatorResult` to parent via `Navigator.pop()`

**2.3 Add Button to Logging UI**
- Location: `lib/features/logging/screens/fluid_logging_screen.dart`
- Add button below "Volume per session" input field
- Style: Secondary/text button with icon
- Action: Open WeightCalculatorDialog

**Integration code:**
```dart
// Add state variable to track pending weight result
WeightCalculatorResult? _pendingWeightResult;

// Button placement (under volume TextField)
TextButton.icon(
  icon: const Icon(Icons.calculate),
  label: Text(l10n.calculateFromWeight), // Localized string
  onPressed: () async {
    final result = await showDialog<WeightCalculatorResult>(
      context: context,
      builder: (_) => WeightCalculatorDialog(
        userId: ref.read(currentUserProvider)!.id,
        petId: ref.read(primaryPetProvider)!.id,
      ),
    );

    if (result != null) {
      // Populate volume field
      _volumeController.text = result.volumeMl.toStringAsFixed(0);

      // Store result to persist after successful save
      setState(() {
        _pendingWeightResult = result;
      });
    }
  },
)
```

**Important:** Don't persist the weight data immediately. Store it in `_pendingWeightResult` and only persist after successful session save (see Phase 3.2).

---

### Phase 3: Integration & Data Persistence

**3.1 Update FluidSession Creation Logic**
- Location: `lib/features/logging/screens/fluid_logging_screen.dart` (or wherever session is created)
- When creating `FluidSession` object, check if `_pendingWeightResult` exists
- If yes, include weight data in the session object
- `LoggingService` will automatically save these fields to Firestore (no service changes needed)

**Example:**
```dart
final session = FluidSession(
  // ... existing fields ...
  volumeGiven: double.parse(_volumeController.text),

  // Add weight data if calculator was used
  calculatedFromWeight: _pendingWeightResult != null,
  initialBagWeightG: _pendingWeightResult?.initialWeightG,
  finalBagWeightG: _pendingWeightResult?.finalWeightG,
);
```

**3.2 Save Last Bag Weight (After Successful Save)**
- After successful session save (in the success callback)
- Call `weightCalculatorService.saveLastBagWeight()` to persist final weight
- Clear pending result

**Example:**
```dart
// After successful log in _logFluidSession()
if (success) {
  // Persist last bag weight for next session
  if (_pendingWeightResult != null) {
    final weightCalc = ref.read(weightCalculatorServiceProvider);
    final user = ref.read(currentUserProvider)!;
    final pet = ref.read(primaryPetProvider)!;

    await weightCalc.saveLastBagWeight(
      userId: user.id,
      petId: pet.id,
      finalWeightG: _pendingWeightResult!.finalWeightG,
    );

    setState(() {
      _pendingWeightResult = null;
    });
  }

  // ... show success UI ...
}
```

**Why this pattern?**
- Only persist if save succeeds (avoid stale data on failed saves)
- Session data includes weight metadata for analytics
- SharedPreferences stores last weight for next session's convenience
- No service changes needed - `LoggingService.saveFluidSession()` already handles all fields

**3.3 Localization (l10n)**
- Add all calculator strings to l10n files
- Location: `lib/l10n/app_en.arb` (and other language files)

**Required strings:**
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
  "errorBothWeights": "Please enter both weights",
  "errorWeightRange": "Please enter a weight between 10g and 10,000g",
  "errorFinalGreaterThanInitial": "Final weight cannot be greater than initial weight. Did you swap the measurements?",
  "errorVolumeRange": "Calculated volume must be between 1 and 500 mL",
  "lastUsedDate": "Last used {date}",
  "remainingWeight": "{weight}g remaining"
}
```

---

### Phase 4: Testing & Polish

**4.1 Unit Tests**
- `weight_calculator_service_test.dart`
  - Test volume calculation
  - Test weight validation (bounds, negative difference)
  - Test 14-day expiry logic
  - Test SharedPreferences read/write

**4.2 Widget Tests**
- `weight_calculator_dialog_test.dart`
  - Test input validation
  - Test live calculation display
  - Test "Continue from same bag" banner visibility
  - Test button interactions

**4.3 Integration Testing**
- Test full flow: open dialog → enter weights → use volume → save session
- Verify SharedPreferences persistence
- Verify Firestore data includes weight fields

**4.4 Edge Cases to Test**
- Zero weight difference
- Very small difference (< 1g)
- Maximum weight bounds
- Minimum weight bounds
- Swapped measurements (final > initial)
- No previous bag data
- Previous bag data > 14 days old

**4.5 UI/UX Polish**
- ✅ Ensure proper keyboard type (decimal number pad) - `keyboardType: TextInputType.numberWithOptions(decimal: true)`
- ✅ Auto-focus on initial weight field when dialog opens
- ✅ Clear keyboard focus on "Use This Weight" button press - `FocusScope.of(context).unfocus()`
- ✅ Haptic feedback on successful "Use This Volume" - `HapticFeedback.mediumImpact()`
- ✅ Disable "Use This Volume" button if validation fails
- ✅ Show inline unit suffixes ("g") next to input fields
- ✅ Live calculation display updates as user types
- ✅ All strings from l10n (no hardcoded text)
- Smooth transitions and animations
- Proper error message styling

---

## File Structure Summary

```
lib/features/logging/
├── models/
│   ├── fluid_session.dart (MODIFY - add 3 optional weight fields: calculatedFromWeight, initialBagWeightG, finalBagWeightG)
│   ├── last_bag_weight.dart (NEW - with toJson/fromJson)
│   ├── weight_validation_result.dart (NEW)
│   └── weight_calculator_result.dart (NEW - return type for dialog)
│
├── services/
│   ├── logging_service.dart (NO CHANGES - already handles all FluidSession fields)
│   └── weight_calculator_service.dart (NEW - handles validation, calculation, SharedPreferences)
│
├── providers/
│   └── weight_calculator_provider.dart (NEW - wires up sharedPreferencesProvider)
│
├── widgets/
│   ├── weight_calculator_dialog.dart (NEW - with haptic feedback, focus management, live validation)
│   └── [other existing widgets...]
│
└── screens/
    ├── fluid_logging_screen.dart (MODIFY - add calculator button + pending result handling)
    └── [other existing screens...]

lib/l10n/
└── app_en.arb (MODIFY - add ~15 calculator strings)

test/features/logging/
├── services/
│   └── weight_calculator_service_test.dart (NEW)
└── widgets/
    └── weight_calculator_dialog_test.dart (NEW)
```

---

## Firebase Cost Optimization Compliance

✅ **No extra reads**: Last bag weight stored in SharedPreferences
✅ **No queries**: 14-day check done locally
✅ **No listeners**: Dialog is on-demand only
✅ **Batch writes**: Weight fields saved with existing session write
✅ **Optional fields**: Doesn't bloat documents for users not using feature
✅ **Offline-first**: SharedPreferences works offline

**Estimated Cost Impact**: Zero additional reads, zero additional writes (fields added to existing write operation)

---

## Known Limitations & Trade-offs

1. **Multi-device behavior**: "Continue from same bag" is device-specific
   - Acceptable: This is a convenience feature, not critical data
   - Alternative would require Firestore query (not worth cost)

2. **Single active bag assumption**: Plan assumes one bag per pet at a time
   - Acceptable: Matches real-world usage patterns
   - User can always start fresh with new initial weight

3. **Fluid type assumption**: Hardcoded to Ringer-Lactate (1g ≈ 1mL)
   - Acceptable: Specified in requirements
   - Could be made configurable in future if needed

---

## Success Criteria

- [ ] User can calculate fluid volume from weights
- [ ] Calculator accessible from logging dialog
- [ ] Previous bag weight auto-fills when available (<14 days)
- [ ] Input validation catches common errors
- [ ] Weight data optionally saved with session
- [ ] Zero additional Firestore reads
- [ ] All tests passing
- [ ] UI/UX smooth and intuitive

---

## Estimated Implementation Time

- Phase 1 (Foundation): 1.5 hours
- Phase 2 (UI): 1.5 hours
- Phase 3 (Integration): 0.5 hours
- Phase 4 (Testing & Polish): 1 hour

**Total: 4-5 hours**
