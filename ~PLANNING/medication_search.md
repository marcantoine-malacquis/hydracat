# Medication Database Autocomplete - Implementation Plan

---

## Overview

Implement a smart autocomplete system for medication entry that leverages the pre-populated CKD medication database (`assets/medication_db/ckd_medications_eu_us.json`) to streamline medication addition while maintaining flexibility for custom entries.

**Key Characteristics:**
- 332 CKD-specific medications (EU/US regions combined)
- Single-line compact dropdown with name, strength, and form
- Fuzzy contains matching (case-insensitive)
- Auto-fill name, strength, and unit on selection
- Hybrid approach: database suggestions + manual entry always allowed
- No regional filtering in V1 (show all medications)
- Zero additional Firebase reads (local JSON asset)

**User Flow:**
1. User types in medication name field (e.g., "Bena")
2. Dropdown appears with matching medications: "Benazepril 5mg tablet"
3. User taps suggestion → Name="Benazepril", Strength="5", Unit="mg" auto-filled
4. User can still edit any field (not locked)
5. If no match, user continues with manual entry (no special UI)

---

## 0. Coherence & Constraints

### Database Structure
The existing JSON file (`assets/medication_db/ckd_medications_eu_us.json`) contains 332 medications with structure:
```json
{
  "region": "EU" | "US",
  "name": "Benazepril",
  "form": "tablet" | "powder" | "liquid" | "capsule" | "oral_solution" | "gel" | "transdermal",
  "strength": "5" | "variable",
  "unit": "mg" | "ml" | "g" | "mg/mL" | "mcg",
  "route": "oral" | "transdermal",
  "category": "phosphate_binder" | "antihypertensive" | "ACE_inhibitor" | "antiemetic" | "appetite_stimulant" | "GI_protectant" | "electrolyte_support" | "supplement",
  "brand_names": "Fortekor"
}
```

### PRD Alignment
- Supports "Treatment Management" pillar from PRD
- Reduces friction in medication entry workflow
- Veterinary-appropriate medication database (no human medications)
- No diagnostic claims - purely data entry assistance

### Firebase & CRUD Rules
- **Zero Firestore operations**: Database is local JSON asset bundled with app
- **No network dependency**: Works offline by design
- **Cost optimization**: No reads/writes for autocomplete feature
- **Asset loading**: JSON loaded once on service initialization, cached in memory

### Architecture Fit
- Follows existing service pattern (`WeightUnitService`, `ThemeService`)
- Leverages Riverpod for state management and dependency injection
- Uses Flutter's RawAutocomplete widget (built-in, accessible, proven)
- Integrates seamlessly with existing `AddMedicationBottomSheet`
- No breaking changes to existing `MedicationData` model

### UI Guidelines Alignment
- **Typography**: Inter font for medication names (clinical data)
- **Colors**: Primary teal for selected state, textSecondary for unselected
- **Border radius**: 8px for dropdown items (follows input field radius)
- **Spacing**: AppSpacing.sm (8px) between dropdown items
- **Touch targets**: Minimum 44px height for each dropdown option
- **Platform adaptation**: Material overlay on Android, Cupertino on iOS

### Design Decisions from Clarifying Questions
1. **Service architecture**: Stateful singleton with Riverpod provider (cached database in memory)
2. **Autocomplete widget**: RawAutocomplete with custom builders (Flutter built-in)
3. **Auto-fill behavior**: Fields remain editable after selection (no locking)
4. **Search algorithm**: Contains matching, case-insensitive (e.g., "nia" matches "Cerenia")
5. **Dropdown display**: Single-line compact format: "Benazepril 5mg tablet"
6. **Empty state**: Empty dropdown when no matches (no special message)
7. **Debouncing**: None (local search is instant, <1ms for 332 items)
8. **Localization**: Medication names stay in English, UI labels localized
9. **Source tracking**: Don't track if medication came from database vs manual entry
10. **Field mapping**: "form" → MedicationUnit (dosage), "unit" → MedicationStrengthUnit

---

## 1. Data Model Design

### Phase 1.1: Medication Database Entry Model (Day 1)

**Goal**: Create immutable model for JSON database entries with validation.

#### Step 1.1.1: Create Medication Database Entry Model

**File**: `lib/features/onboarding/models/medication_database_entry.dart` (new)

**Implementation**:
- Create immutable `MedicationDatabaseEntry` class with fields:
  - `region` (String) - "EU" or "US"
  - `name` (String) - Generic medication name
  - `form` (String) - "tablet", "powder", "liquid", "capsule", "oral_solution", "gel", "transdermal"
  - `strength` (String) - Numeric value or "variable"
  - `unit` (String) - "mg", "ml", "g", "mg/mL", "mcg", "mg/g", "mcg/mL", "IU", "IU/mL", "%", etc.
  - `route` (String) - "oral" or "transdermal"
  - `category` (String) - Medication category
  - `brandNames` (String) - Comma-separated brand names
- Add computed getters:
  - `displayName` - Returns formatted string: "Benazepril 5mg tablet"
  - `searchableText` - Returns lowercase concatenation of name + brand names for matching
  - `hasVariableStrength` - Returns true if strength == "variable"
- Add factory constructor:
  - `MedicationDatabaseEntry.fromJson(Map<String, dynamic> json)`
- Add validation method returning List<String> of errors:
  - Region is "EU" or "US"
  - Name is not empty
  - Form is valid value
  - Strength is numeric or "variable"
  - Unit is not empty
- Override `==`, `hashCode`, `toString` for all fields

**Example usage**:
```dart
final entry = MedicationDatabaseEntry(
  region: 'EU',
  name: 'Benazepril',
  form: 'tablet',
  strength: '5',
  unit: 'mg',
  route: 'oral',
  category: 'ACE_inhibitor',
  brandNames: 'Fortekor',
);

print(entry.displayName); // "Benazepril 5mg tablet"
print(entry.searchableText); // "benazepril fortekor"
```

**Testing**: Unit tests for JSON parsing, validation, computed getters, equality.

---

### Phase 1.2: Field Mapping Utilities (Day 1)

**Goal**: Create mapping functions to convert database fields to app enums.

#### Step 1.2.1: Create Medication Form Mapper

**File**: `lib/core/utils/medication_form_mapper.dart` (new)

**Implementation**:
- Create static class `MedicationFormMapper`
- Implement method `mapFormToUnit(String form)` returns `MedicationUnit?`:
  ```dart
  static MedicationUnit? mapFormToUnit(String form) {
    return switch (form.toLowerCase()) {
      'tablet' => MedicationUnit.pills,
      'capsule' => MedicationUnit.capsules,
      'powder' => MedicationUnit.portions,
      'liquid' => MedicationUnit.milliliters,
      'oral_solution' => MedicationUnit.milliliters,
      'gel' => MedicationUnit.portions,
      'transdermal' => MedicationUnit.portions,
      _ => null, // Unknown form, let user select
    };
  }
  ```
- Implement method `mapUnitToStrengthUnit(String unit)` returns `MedicationStrengthUnit?`:
  ```dart
  static MedicationStrengthUnit? mapUnitToStrengthUnit(String unit) {
    return switch (unit.toLowerCase()) {
      'mg' => MedicationStrengthUnit.mg,
      'ml' => MedicationStrengthUnit.mg, // Note: ml in JSON means the form is liquid, use mg for strength
      'g' => MedicationStrengthUnit.g,
      'mg/ml' => MedicationStrengthUnit.mgPerMl,
      'mcg' => MedicationStrengthUnit.mcg,
      'mcg/ml' => MedicationStrengthUnit.mcgPerMl,
      'mg/g' => MedicationStrengthUnit.mgPerG,
      'mcg/g' => MedicationStrengthUnit.mcgPerG,
      'iu' => MedicationStrengthUnit.iu,
      'iu/ml' => MedicationStrengthUnit.iuPerMl,
      '%' => MedicationStrengthUnit.percent,
      _ => null, // Unknown unit, let user select or type custom
    };
  }
  ```
- Add documentation comments explaining mapping decisions
- Handle edge cases (null, empty string, unknown values)

**Mapping Rationale**:
- **tablet/capsule → pills/capsules**: Direct semantic match
- **powder/gel/transdermal → portions**: Measured by application amount
- **liquid/oral_solution → milliliters**: Measured by volume
- **Unknown forms**: Return null, user selects manually (graceful degradation)

**Testing**: Unit tests for all form/unit combinations, edge cases, unknown values.

---

## 2. Service Layer Implementation

### Phase 2.1: Medication Database Service (Day 1-2)

**Goal**: Create singleton service to load, cache, and search medication database.

#### Step 2.1.1: Create Medication Database Service

**File**: `lib/shared/services/medication_database_service.dart` (new)

**Implementation**:
- Create `MedicationDatabaseService` class (singleton pattern)
- Constructor accepts optional parameters for testing:
  - `AssetBundle? assetBundle` - Defaults to `rootBundle`
- Private fields:
  - `_medications` (List<MedicationDatabaseEntry>?) - Cached medication list
  - `_isInitialized` (bool) - Initialization state flag
  - `_assetBundle` (AssetBundle) - Asset bundle reference
- Implement initialization method:
  ```dart
  Future<void> initialize() async {
    if (_isInitialized) return; // Already loaded

    try {
      final jsonString = await _assetBundle.loadString(
        'assets/medication_db/ckd_medications_eu_us.json',
      );

      final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;

      _medications = jsonList
          .map((json) => MedicationDatabaseEntry.fromJson(json as Map<String, dynamic>))
          .where((entry) => entry.validate().isEmpty) // Filter out invalid entries
          .toList();

      _isInitialized = true;
    } catch (e) {
      // Log error but don't throw - graceful degradation
      // App continues to work with manual entry only
      debugPrint('Failed to load medication database: $e');
      _medications = [];
      _isInitialized = true; // Mark as initialized to prevent retry loops
    }
  }
  ```
- Implement search method:
  ```dart
  List<MedicationDatabaseEntry> searchMedications(String query) {
    if (!_isInitialized || query.trim().isEmpty) {
      return [];
    }

    final normalizedQuery = query.toLowerCase().trim();

    // Contains matching on name and brand names
    final matches = _medications!.where((medication) {
      return medication.searchableText.contains(normalizedQuery);
    }).toList();

    // Sort by relevance:
    // 1. Name starts with query (highest priority)
    // 2. Name contains query
    // 3. Brand name contains query
    matches.sort((a, b) {
      final aNameStarts = a.name.toLowerCase().startsWith(normalizedQuery);
      final bNameStarts = b.name.toLowerCase().startsWith(normalizedQuery);

      if (aNameStarts && !bNameStarts) return -1;
      if (!aNameStarts && bNameStarts) return 1;

      final aNameContains = a.name.toLowerCase().contains(normalizedQuery);
      final bNameContains = b.name.toLowerCase().contains(normalizedQuery);

      if (aNameContains && !bNameContains) return -1;
      if (!aNameContains && bNameContains) return 1;

      // Alphabetical if equal relevance
      return a.name.compareTo(b.name);
    });

    return matches.take(10).toList(); // Limit to 10 results to keep dropdown manageable
  }
  ```
- Add getter methods:
  - `isInitialized` - Returns initialization state
  - `medicationCount` - Returns total count of loaded medications
- Add helper method:
  ```dart
  MedicationDatabaseEntry? getMedicationByName(String name) {
    if (!_isInitialized) return null;

    try {
      return _medications!.firstWhere(
        (med) => med.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (_) {
      return null; // Not found
    }
  }
  ```

**Performance Optimization**:
- Load database once on first access
- Cache in memory for app lifetime (small footprint: ~50KB JSON)
- Contains search on 332 items is <1ms on modern devices
- Limit results to 10 to keep dropdown responsive

**Error Handling**:
- Graceful degradation if JSON fails to load
- App continues to work with manual entry only
- Log errors for debugging but don't crash

**Testing**:
- Unit tests with mocked AssetBundle
- Test successful load, parse errors, search algorithm
- Test relevance sorting (prefix matches, contains matches)
- Test empty query, unknown medications

---

### Phase 2.2: Provider Integration (Day 2)

**Goal**: Create Riverpod provider for medication database service.

#### Step 2.2.1: Create Medication Database Provider

**File**: `lib/providers/medication_database_provider.dart` (new)

**Implementation**:
- Define service provider:
  ```dart
  final medicationDatabaseServiceProvider = Provider<MedicationDatabaseService>((ref) {
    final service = MedicationDatabaseService();
    // Initialize service asynchronously (don't block provider creation)
    service.initialize();
    return service;
  });
  ```
- Define initialization state provider:
  ```dart
  final medicationDatabaseInitializedProvider = Provider<bool>((ref) {
    final service = ref.watch(medicationDatabaseServiceProvider);
    return service.isInitialized;
  });
  ```
- Define search provider with caching:
  ```dart
  final medicationSearchProvider = Provider.family<List<MedicationDatabaseEntry>, String>(
    (ref, query) {
      final service = ref.watch(medicationDatabaseServiceProvider);

      if (!service.isInitialized) {
        return []; // Not ready yet
      }

      return service.searchMedications(query);
    },
  );
  ```

**Usage in UI**:
```dart
// In widget
final searchResults = ref.watch(medicationSearchProvider(query));
```

**Testing**: Provider unit tests with mocked service.

---

## 3. UI/UX Implementation

### Phase 3.1: Autocomplete Field Widget (Day 2-3)

**Goal**: Create reusable autocomplete text field using Flutter's RawAutocomplete.

#### Step 3.1.1: Create Medication Autocomplete Field

**File**: `lib/features/onboarding/widgets/medication_autocomplete_field.dart` (new)

**Implementation**:
- Create `MedicationAutocompleteField extends ConsumerStatefulWidget`
- Constructor parameters:
  - `controller` (TextEditingController) - Required, controls the text field
  - `onMedicationSelected` (ValueChanged<MedicationDatabaseEntry>?) - Callback when selection made
  - `decoration` (InputDecoration?) - Custom decoration
  - `focusNode` (FocusNode?) - Optional focus node
- State class `_MedicationAutocompleteFieldState`:
  - Private field `_query` (String) - Current search query
  - Override `build()` method:
    ```dart
    @override
    Widget build(BuildContext context) {
      final searchResults = ref.watch(medicationSearchProvider(_query));

      return RawAutocomplete<MedicationDatabaseEntry>(
        textEditingController: widget.controller,
        focusNode: widget.focusNode ?? FocusNode(),
        optionsBuilder: (TextEditingValue textEditingValue) {
          setState(() {
            _query = textEditingValue.text;
          });
          return searchResults;
        },
        displayStringForOption: (MedicationDatabaseEntry option) {
          return option.name; // Display only name in text field after selection
        },
        onSelected: (MedicationDatabaseEntry selection) {
          widget.onMedicationSelected?.call(selection);
        },
        fieldViewBuilder: (
          BuildContext context,
          TextEditingController textEditingController,
          FocusNode focusNode,
          VoidCallback onFieldSubmitted,
        ) {
          return HydraTextFormField(
            controller: textEditingController,
            focusNode: focusNode,
            decoration: widget.decoration ?? InputDecoration(
              hintText: context.l10n.medicationNameHint,
              contentPadding: const EdgeInsets.symmetric(
                vertical: AppSpacing.md,
                horizontal: AppSpacing.md,
              ),
              prefixIconConstraints: const BoxConstraints(),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(
                  left: AppSpacing.md,
                  right: AppSpacing.sm,
                ),
                child: Text(
                  'Name',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            textCapitalization: TextCapitalization.words,
            onChanged: (value) {
              setState(() {
                _query = value;
              });
            },
          );
        },
        optionsViewBuilder: (
          BuildContext context,
          AutocompleteOnSelected<MedicationDatabaseEntry> onSelected,
          Iterable<MedicationDatabaseEntry> options,
        ) {
          return _buildOptionsOverlay(context, onSelected, options);
        },
      );
    }
    ```
  - Implement `_buildOptionsOverlay()` method:
    ```dart
    Widget _buildOptionsOverlay(
      BuildContext context,
      AutocompleteOnSelected<MedicationDatabaseEntry> onSelected,
      Iterable<MedicationDatabaseEntry> options,
    ) {
      return Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation: 0,
          borderRadius: BorderRadius.circular(AppBorderRadius.input),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: 200, // Max 4.5 items visible
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppBorderRadius.input),
              border: Border.all(
                color: AppColors.border,
                width: 1,
              ),
              boxShadow: [AppShadows.cardPopup],
            ),
            child: options.isEmpty
                ? const SizedBox.shrink() // Empty state: hide dropdown
                : ListView.separated(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      thickness: 1,
                      color: AppColors.border,
                    ),
                    itemBuilder: (BuildContext context, int index) {
                      final option = options.elementAt(index);
                      return _buildOptionTile(context, option, onSelected);
                    },
                  ),
          ),
        ),
      );
    }
    ```
  - Implement `_buildOptionTile()` method:
    ```dart
    Widget _buildOptionTile(
      BuildContext context,
      MedicationDatabaseEntry option,
      AutocompleteOnSelected<MedicationDatabaseEntry> onSelected,
    ) {
      return InkWell(
        onTap: () => onSelected(option),
        child: Container(
          constraints: BoxConstraints(
            minHeight: AppAccessibility.minTouchTarget, // 44px minimum
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              option.displayName, // "Benazepril 5mg tablet"
              style: AppTextStyles.body.copyWith(
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      );
    }
    ```

**UI Behavior**:
- Dropdown appears below text field when query length >= 1
- Dropdown dismisses when:
  - User selects an option
  - User taps outside dropdown
  - Field loses focus
  - No results match query (empty dropdown)
- Selected medication triggers callback with full database entry
- Text field shows only medication name after selection

**Platform Adaptation**:
- Material: InkWell ripple effect on tap
- Cupertino: GestureDetector with opacity change

**Testing**: Widget tests for rendering, selection, keyboard navigation, accessibility.

---

### Phase 3.2: Integration into Add Medication Flow (Day 3)

**Goal**: Replace plain text field with autocomplete in AddMedicationBottomSheet.

#### Step 3.2.1: Modify Add Medication Bottom Sheet

**File**: `lib/features/onboarding/screens/add_medication_bottom_sheet.dart` (modify)

**Changes**:
1. **Import new widgets and services**:
   ```dart
   import 'package:hydracat/features/onboarding/widgets/medication_autocomplete_field.dart';
   import 'package:hydracat/features/onboarding/models/medication_database_entry.dart';
   import 'package:hydracat/core/utils/medication_form_mapper.dart';
   ```

2. **In `_buildNameAndStrengthStep()` method** (around line 365):

   **Replace this** (lines 386-415):
   ```dart
   HydraTextFormField(
     controller: _nameController,
     decoration: InputDecoration(
       hintText: l10n.medicationNameHint,
       // ... existing decoration
     ),
     textCapitalization: TextCapitalization.words,
     onChanged: (value) {
       setState(() {
         _medicationName = value.trim();
         _hasUnsavedChanges = true;
       });
     },
   ),
   ```

   **With this**:
   ```dart
   MedicationAutocompleteField(
     controller: _nameController,
     decoration: InputDecoration(
       hintText: l10n.medicationNameHint,
       contentPadding: const EdgeInsets.symmetric(
         vertical: AppSpacing.md,
         horizontal: AppSpacing.md,
       ),
       prefixIconConstraints: const BoxConstraints(),
       prefixIcon: Padding(
         padding: const EdgeInsets.only(
           left: AppSpacing.md,
           right: AppSpacing.sm,
         ),
         child: Text(
           'Name',
           style: AppTextStyles.body.copyWith(
             color: AppColors.textSecondary,
           ),
         ),
       ),
     ),
     onMedicationSelected: (MedicationDatabaseEntry medication) {
       setState(() {
         // Update name (already set by autocomplete, but ensure state updates)
         _medicationName = medication.name;

         // Auto-fill strength if not variable
         if (!medication.hasVariableStrength) {
           _strengthAmount = medication.strength;
           _strengthAmountController.text = medication.strength;
         }

         // Auto-fill strength unit
         final mappedStrengthUnit = MedicationFormMapper.mapUnitToStrengthUnit(
           medication.unit,
         );
         if (mappedStrengthUnit != null) {
           _strengthUnit = mappedStrengthUnit;
         }

         // Auto-fill dosage unit (from form field)
         final mappedDosageUnit = MedicationFormMapper.mapFormToUnit(
           medication.form,
         );
         if (mappedDosageUnit != null) {
           _selectedUnit = mappedDosageUnit;
         }

         _hasUnsavedChanges = true;
       });
     },
   ),
   ```

3. **Keep manual entry capability**:
   - User can still type freely without selecting from dropdown
   - All fields remain editable after selection
   - No special UI for "database vs manual" entry

**User Experience Flow**:
1. User starts typing "Bena"
2. Dropdown shows: "Benazepril 5mg tablet"
3. User taps suggestion
4. Name field: "Benazepril" (user can still edit)
5. Strength field: "5" (user can still edit)
6. Strength unit: "mg" selected in dropdown (user can change)
7. Dosage unit: "pills" selected (from "tablet" form, user can change)
8. User continues to next step as normal

**Edge Cases Handled**:
- Variable strength medications: Don't auto-fill strength field
- Unknown form/unit mappings: Don't auto-fill, user selects manually
- User clears name field: Dropdown reappears on typing
- User types custom medication not in database: No dropdown, manual entry continues

**Testing**: Manual testing of complete medication addition flow with autocomplete.

---

## 4. Localization

### Phase 4.1: Add Localization Keys (Day 3)

**Goal**: Add UI label keys (medication names stay in English per design decision).

**File**: `lib/l10n/app_en.arb` (modify)

**Implementation**:
- Add keys (only ~5 new keys needed):

```json
{
  "@_MEDICATION_AUTOCOMPLETE": {},
  "medicationSearchPlaceholder": "Search medications...",
  "@medicationSearchPlaceholder": {
    "description": "Placeholder for medication search field"
  },

  "medicationNotInDatabase": "Medication not found? You can still add it manually.",
  "@medicationNotInDatabase": {
    "description": "Info message when medication not in database"
  },

  "medicationSuggestionsTitle": "Suggested Medications",
  "@medicationSuggestionsTitle": {
    "description": "Title for medication suggestions dropdown"
  },

  "medicationDatabaseLoadError": "Could not load medication database. Manual entry is still available.",
  "@medicationDatabaseLoadError": {
    "description": "Error message when database fails to load"
  },

  "medicationAutocompleteHint": "Start typing to see suggestions",
  "@medicationAutocompleteHint": {
    "description": "Hint text for autocomplete field"
  }
}
```

**Note**: Medication names, strengths, and forms remain in English (international medical standard). Only UI chrome is localized.

**Testing**: Generate localization files (`dart run build_runner build`), verify no missing keys.

---

## 5. Analytics Integration

### Phase 5.1: Update Analytics Documentation (Day 3)

**Goal**: Document autocomplete usage events for tracking.

**File**: `.cursor/reference/analytics_list.md` (modify)

**Implementation**:
- Add new section: "Medication Autocomplete Events"
- Document events:
  ```markdown
  ## Medication Autocomplete Events

  - `medication_autocomplete_search` - fired when user types in search field
    - `query_length` (int) - length of search query
    - `results_count` (int) - number of results returned

  - `medication_autocomplete_selected` - fired when user selects suggestion
    - `medication_name` (string) - selected medication name
    - `has_variable_strength` (bool) - whether strength is "variable"
    - `category` (string) - medication category

  - `medication_manual_entry` - fired when user proceeds without selecting suggestion
    - `query_text` (string?) - what user typed (first 3 chars only for privacy)

  - `medication_database_load_success` - fired when database loads successfully
    - `medication_count` (int) - total medications loaded

  - `medication_database_load_failure` - fired when database fails to load
    - `error_type` (string) - error category
  ```

**Privacy Considerations**:
- Don't log full custom medication names (may contain sensitive info)
- Log only first 3 characters of manual entries for gap analysis
- Log selected medications from database (they're public knowledge)

**Testing**: None (documentation only).

---

## 6. Testing

### Phase 6.1: Unit Tests (Day 4)

**Goal**: Test models, services, and utilities.

**Files to create**:
- `test/features/onboarding/models/medication_database_entry_test.dart`
- `test/shared/services/medication_database_service_test.dart`
- `test/core/utils/medication_form_mapper_test.dart`
- `test/providers/medication_database_provider_test.dart`

**Key test cases**:

**MedicationDatabaseEntry**:
- JSON parsing with all fields
- JSON parsing with missing optional fields
- Validation (invalid region, empty name, invalid form)
- displayName formatting ("Benazepril 5mg tablet")
- searchableText includes name and brand names
- hasVariableStrength detection
- Equality and hashCode

**MedicationDatabaseService**:
- Successful database load and parse
- Graceful degradation on load failure
- Search with empty query (returns empty list)
- Search with no matches (returns empty list)
- Search with contains matching ("nia" matches "Cerenia", "Benazepril")
- Search with case-insensitivity ("BENA" matches "Benazepril")
- Search result sorting (prefix matches first, then contains matches)
- Search result limit (max 10 results)
- getMedicationByName exact match

**MedicationFormMapper**:
- mapFormToUnit for all known forms (tablet, capsule, powder, liquid, etc.)
- mapFormToUnit for unknown form (returns null)
- mapUnitToStrengthUnit for all known units (mg, ml, g, mg/ml, etc.)
- mapUnitToStrengthUnit for unknown unit (returns null)
- Edge cases (null, empty string, case variations)

**Testing**: Run `flutter test` to verify all pass, achieve >80% coverage.

---

### Phase 6.2: Widget Tests (Day 4)

**Goal**: Test autocomplete field UI component.

**File**: `test/features/onboarding/widgets/medication_autocomplete_field_test.dart` (new)

**Key test cases**:
- Renders text field with hint text
- Shows dropdown when user types
- Dropdown displays search results correctly
- Tapping result updates text field
- Tapping result triggers onMedicationSelected callback
- Empty search query shows no dropdown
- No results shows empty dropdown (hidden)
- Dropdown dismisses when field loses focus
- Keyboard navigation through results (up/down arrows)
- Accessibility labels and semantic nodes

**Testing**: Run `flutter test` for widget tests.

---

### Phase 6.3: Integration Tests (Day 4)

**Goal**: Test complete medication addition flow with autocomplete.

**File**: `test/features/onboarding/integration/medication_autocomplete_flow_test.dart` (new)

**Test scenarios**:
1. User types medication name, selects from dropdown, fields auto-fill, completes addition
2. User types medication name, ignores dropdown, continues with manual entry
3. User selects medication with variable strength, only name auto-fills
4. User types unknown medication, no dropdown appears, manual entry works
5. Database load failure, autocomplete disabled, manual entry still works

**Testing**: Run integration tests with test asset bundle.

---

### Phase 6.4: Update Test Index (Day 4)

**File**: `test/tests_index.md` (modify)

**Implementation**:
- Add new section: "Medication Autocomplete Tests"
- List all 5 new test files with brief descriptions
- Document test coverage percentage

**Testing**: None (documentation only).

---

## 7. Documentation & Launch

### Phase 7.1: Asset Bundle Configuration (Day 5)

**Goal**: Ensure JSON asset is included in app bundle.

**File**: `pubspec.yaml` (verify)

**Implementation**:
- Verify assets section includes:
  ```yaml
  assets:
    - assets/medication_db/ckd_medications_eu_us.json
  ```
- If not present, add it to assets section
- Run `flutter pub get` to refresh

**Testing**: Build app, verify asset loads successfully.

---

### Phase 7.2: Final Documentation Updates (Day 5)

**Files to update**:
- `~PLANNING/medication_search.md` - Mark as DONE, move to `~PLANNING/DONE/`
- `.cursor/reference/analytics_list.md` - Already updated in Phase 5.1
- `test/tests_index.md` - Already updated in Phase 6.4
- `.cursor/rules/firestore_schema.md` - No changes (no Firestore operations)

**Testing**: None (documentation only).

---

### Phase 7.3: Pre-Launch Checklist (Day 5)

**Manual QA**:
- [ ] Run `flutter analyze` - zero errors
- [ ] Run `flutter test` - all tests pass
- [ ] Test on iOS device - autocomplete works, dropdown renders correctly
- [ ] Test on Android device - autocomplete works, Material styling correct
- [ ] Verify asset loads - check medication count in debug logs
- [ ] Test autocomplete with 1 character query - shows results
- [ ] Test autocomplete with 3+ character query - shows refined results
- [ ] Test selection - fields auto-fill correctly
- [ ] Test manual entry - works without selecting from dropdown
- [ ] Test editing after selection - all fields remain editable
- [ ] Test variable strength medications - strength field stays empty
- [ ] Test unknown form/unit - graceful fallback to manual selection
- [ ] Test database load failure - app works with manual entry only
- [ ] Test keyboard navigation - up/down arrows navigate dropdown
- [ ] Test accessibility - VoiceOver/TalkBack announce options correctly
- [ ] Test performance - search feels instant (<50ms perceived latency)

**Accessibility**:
- [ ] Dropdown options meet minimum 44px touch target
- [ ] Focus indicator visible on keyboard navigation
- [ ] Screen reader announces "X results available" when dropdown appears
- [ ] Screen reader announces selected medication name

**Edge Cases**:
- [ ] User types rapidly - search keeps up without lag
- [ ] User types, selects, clears, types again - works correctly
- [ ] User types medication not in database - manual entry proceeds
- [ ] Database fails to load - app shows error, allows manual entry
- [ ] User on slow device - search still feels responsive

---

### Phase 7.4: Launch (Day 5)

**Steps**:
1. Merge feature branch to main
2. Tag release version (e.g., `v1.6.0-medication-autocomplete`)
3. Monitor app performance for first 24 hours:
   - Check Crashlytics for errors related to autocomplete
   - Verify analytics events appearing
   - Monitor user feedback for autocomplete feature
4. Prepare user-facing announcement (optional):
   - In-app tooltip on first medication addition: "Tap to search from 300+ CKD medications"
   - Release notes mention: "Faster medication entry with smart suggestions"

---

## 8. Future Iterations (Deferred)

### Phase 8.1: Regional Filtering (Future)

**Scope**: Filter medications by user's region (EU/US).

**Implementation**:
- Detect user region from locale or pet profile
- Add `region` parameter to `searchMedications()`
- Filter results by region before returning
- Show toggle in settings: "Show medications for: EU | US | Both"

**Estimated Effort**: 1-2 days (requires user preference system).

---

### Phase 8.2: Category-Based Filtering (Future)

**Scope**: Allow users to filter by medication category (e.g., "Show only phosphate binders").

**Implementation**:
- Add filter chips above search field
- Categories: Phosphate Binder, ACE Inhibitor, Antiemetic, Appetite Stimulant, etc.
- Filter search results by selected categories
- Persist category preference per session

**Estimated Effort**: 2-3 days (UI + state management).

---

### Phase 8.3: Brand Name Search (Future Enhancement)

**Scope**: Enhance search to prioritize brand name matches.

**Current State**: Brand names are searchable but not prioritized in sorting.

**Enhancement**:
- Add separate relevance score for brand name exact matches
- Display brand name in dropdown: "Benazepril (Fortekor) 5mg tablet"
- Sort brand name exact matches above generic name contains matches

**Estimated Effort**: 1 day (minor algorithm update).

---

### Phase 8.4: Recent/Frequent Medications (Future)

**Scope**: Show recently added or frequently used medications at top of dropdown.

**Implementation**:
- Track medication addition history (local storage)
- Show "Recent Medications" section above search results
- Limit to 3-5 most recent
- Privacy: Store only medication names, no dosages or schedules

**Estimated Effort**: 2-3 days (local storage + UI).

---

### Phase 8.5: Medication Image Database (Future)

**Scope**: Add images of common medications for visual confirmation.

**Implementation**:
- Curate medication images (pill/bottle photos)
- Store in assets or CDN
- Display thumbnail in dropdown
- Requires legal review for image rights

**Estimated Effort**: 2-4 weeks (image curation + legal review).

---

## 9. Implementation Timeline Summary

**Day 1: Data Models & Utilities**
- MedicationDatabaseEntry model
- MedicationFormMapper utility
- MedicationDatabaseService core logic

**Day 2: Service & Provider Layer**
- MedicationDatabaseService search implementation
- Riverpod provider setup
- MedicationAutocompleteField widget (start)

**Day 3: UI Integration**
- MedicationAutocompleteField widget (complete)
- Integration into AddMedicationBottomSheet
- Localization keys
- Analytics documentation

**Day 4: Testing**
- Unit tests (models, services, utilities)
- Widget tests (autocomplete field)
- Integration tests (complete flow)
- Test index update

**Day 5: Documentation & Launch**
- Asset bundle verification
- Pre-launch QA checklist
- Documentation updates
- Launch

**Total Estimated Timeline**: 5 days (1 senior developer, full-time)

---

## 10. Success Metrics

**Adoption Metrics** (Track in Firebase Analytics):
- % of medication additions that use autocomplete (target: 60%+)
- % of autocomplete searches that result in selection (target: 70%+)
- Average time to add medication (baseline vs post-launch, expect 20-30% reduction)

**Engagement Metrics**:
- Average search query length (target: 3-5 characters before selection)
- Most frequently selected medications (identify popular meds)
- Search queries with no results (identify database gaps)

**Data Quality Metrics**:
- % of medications with auto-filled strength (target: 80%+)
- % of medications with auto-filled unit (target: 90%+)
- Manual entry rate after failed autocomplete (lower is better)

**Technical Metrics**:
- Database load success rate (target: 99%+)
- Search performance (target: <50ms perceived latency)
- Dropdown render time (target: <100ms)

---

## 11. Risk Mitigation

**Technical Risks**:
- **Database file size growth**: Mitigation - Current 332 meds = ~50KB, room to grow to 1000+ meds without performance impact
- **JSON parse errors**: Mitigation - Graceful degradation, validation on load, app continues with manual entry
- **Platform differences in autocomplete behavior**: Mitigation - Use RawAutocomplete (Flutter built-in), test on both platforms

**UX Risks**:
- **User confusion with auto-fill**: Mitigation - Fields remain editable, no visual lock indicator, clear that selection is optional
- **Dropdown obscures other fields**: Mitigation - Limit dropdown height to 200px (~4.5 items), scrollable
- **Search too broad (too many results)**: Mitigation - Limit to 10 results, sort by relevance

**Data Risks**:
- **Database outdated**: Mitigation - Plan for periodic updates (GitHub issues for new meds), version JSON file for updates
- **Medication name typos in database**: Mitigation - Validation on load, community feedback for corrections

---

## 12. Database Maintenance Plan

### Database Updates
**Process for adding new medications**:
1. User reports missing medication via in-app feedback or GitHub issue
2. Verify medication is CKD-appropriate (consult veterinary resources)
3. Add entry to JSON file with complete fields (region, name, form, strength, unit, category, brand names)
4. Validate JSON format (run through parser)
5. Increment database version in JSON header (future: add version field)
6. Include in next app release

**Quality Assurance**:
- Maintain list of sources (veterinary formularies, manufacturer data)
- Cross-reference brand names with official databases
- Document any medications excluded (e.g., human-only formulations)
- Periodic review of outdated medications (discontinued products)

**Community Contributions**:
- Accept pull requests for database additions
- Require verification from veterinary source
- Template for new medication entries (GitHub issue template)

---

## Appendix A: File Checklist

**New Files to Create** (8 files):

**Models (1)**:
- `lib/features/onboarding/models/medication_database_entry.dart`

**Services (1)**:
- `lib/shared/services/medication_database_service.dart`

**Utilities (1)**:
- `lib/core/utils/medication_form_mapper.dart`

**Widgets (1)**:
- `lib/features/onboarding/widgets/medication_autocomplete_field.dart`

**Providers (1)**:
- `lib/providers/medication_database_provider.dart`

**Tests (3)**:
- `test/features/onboarding/models/medication_database_entry_test.dart`
- `test/shared/services/medication_database_service_test.dart`
- `test/core/utils/medication_form_mapper_test.dart`
- `test/providers/medication_database_provider_test.dart`
- `test/features/onboarding/widgets/medication_autocomplete_field_test.dart`
- `test/features/onboarding/integration/medication_autocomplete_flow_test.dart`

---

**Modified Files** (4 files):

- `lib/features/onboarding/screens/add_medication_bottom_sheet.dart` - Replace text field with autocomplete
- `lib/l10n/app_en.arb` - Add ~5 localization keys
- `.cursor/reference/analytics_list.md` - Add autocomplete analytics events
- `test/tests_index.md` - Add autocomplete test files
- `pubspec.yaml` - Verify asset inclusion (may not need changes)

---

## Appendix B: JSON Database Structure Reference

**Example Entry**:
```json
{
  "region": "EU",
  "name": "Benazepril",
  "form": "tablet",
  "strength": "5",
  "unit": "mg",
  "route": "oral",
  "category": "ACE_inhibitor",
  "brand_names": "Fortekor"
}
```

**Field Definitions**:
- `region`: "EU" or "US" (veterinary product availability)
- `name`: Generic medication name (INN - International Nonproprietary Name)
- `form`: Medication form (tablet, powder, liquid, capsule, oral_solution, gel, transdermal)
- `strength`: Numeric value or "variable" for variable-strength products
- `unit`: Measurement unit (mg, ml, g, mg/mL, mcg, mg/g, mcg/mL, IU, IU/mL, %)
- `route`: Administration route (oral, transdermal)
- `category`: Medication category (phosphate_binder, ACE_inhibitor, antiemetic, etc.)
- `brand_names`: Comma-separated list of brand names

**Categories in Database**:
1. `phosphate_binder` - Controls phosphorus levels (Aluminum hydroxide, Lanthanum carbonate, Epakitin, Pronefra)
2. `antihypertensive` - Manages blood pressure (Amlodipine, Telmisartan)
3. `ACE_inhibitor` - Reduces proteinuria (Benazepril)
4. `antiemetic` - Controls nausea/vomiting (Maropitant, Ondansetron)
5. `appetite_stimulant` - Increases appetite (Mirtazapine)
6. `GI_protectant` - Protects stomach lining (Omeprazole, Famotidine, Sucralfate)
7. `electrolyte_support` - Manages electrolytes (Potassium gluconate)
8. `supplement` - Nutritional support (Omega-3, B-complex)

---

## Appendix C: Form-to-Unit Mapping Reference

**Mapping Table**:

| Database Form | Maps To | MedicationUnit Enum | Rationale |
|---------------|---------|---------------------|-----------|
| `tablet` | → | `pills` | Solid oral dosage, counted by pill |
| `capsule` | → | `capsules` | Direct semantic match |
| `powder` | → | `portions` | Measured by scoop/portion |
| `liquid` | → | `milliliters` | Measured by volume |
| `oral_solution` | → | `milliliters` | Measured by volume |
| `gel` | → | `portions` | Measured by application amount |
| `transdermal` | → | `portions` | Measured by application amount |

**Unit-to-StrengthUnit Mapping Table**:

| Database Unit | Maps To | MedicationStrengthUnit Enum |
|---------------|---------|------------------------------|
| `mg` | → | `mg` |
| `ml` | → | `mg` | Note: ml indicates liquid form, strength still in mg |
| `g` | → | `g` |
| `mg/mL` | → | `mgPerMl` |
| `mcg` | → | `mcg` |
| `mcg/mL` | → | `mcgPerMl` |
| `mg/g` | → | `mgPerG` |
| `mcg/g` | → | `mcgPerG` |
| `IU` | → | `iu` |
| `IU/mL` | → | `iuPerMl` |
| `%` | → | `percent` |

**Unknown/Unmapped Values**:
- Return `null` from mapping functions
- UI falls back to manual selection
- User chooses appropriate unit from dropdown
- No crash or error, graceful degradation

---

**End of Implementation Plan**
