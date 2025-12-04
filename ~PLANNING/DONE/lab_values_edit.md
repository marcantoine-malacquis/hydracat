# Lab Values Edit Implementation Plan

## Overview
Implement a comprehensive lab values add/edit system in the CKD Profile screen using a bottom sheet dialog pattern. Replace the current inline editing UI with a unified card display and popup-based data entry system.

## Requirements Summary
- Single card grouping lab values (Creatinine, BUN, SDMA) with bloodwork date
- "Edit" button on card to modify latest values (pre-filled popup)
- "+ Add" button in app bar to create new bloodwork entry (empty popup)
- Unit system toggle (US/SI) for Creatinine and BUN (SDMA stays in �g/dL)
- Store exactly what user enters (no automatic conversion)
- Support dual reference ranges for gauges (US and SI units)
- Mandatory bloodwork date, at least one value required
- Optional vet notes field (500 char max)
- Append-only history (both Edit and Add create new `labResults` entries)

---

## Critical Data Storage Strategy

**No Conversion, Convention-Based Unit Derivation**

When storing lab results:
1. Store the **exact value the user entered** (no conversion to US/SI)
2. Store the user-selected **unit with each measurement** in `LabMeasurement.unit`
3. Store the **preferredUnitSystem** ('us' or 'si') in `LatestLabSummary`
4. At display time, derive the unit using `getDefaultUnit(analyte, preferredUnitSystem)`

**Why this works:**
- The unit toggle applies to ALL values at once (not per-analyte)
- We're not doing conversions (simple relationship: SI system = SI units for all)
- The existing `LatestLabSummary` model already uses this pattern

**Example:**
User selects "SI Units" toggle and enters:
- Creatinine: 120 → Stored as `{value: 120, unit: "µmol/L"}` in `LabResult`
- BUN: 8.5 → Stored as `{value: 8.5, unit: "mmol/L"}` in `LabResult`
- SDMA: 16 → Stored as `{value: 16, unit: "µg/dL"}` in `LabResult`
- `LatestLabSummary` stores: `{creatinine: 120, bun: 8.5, sdma: 16, preferredUnitSystem: "si"}`

At display time:
- Gauge reads `preferredUnitSystem: "si"` → uses `getDefaultUnit('creatinine', 'si')` → `"µmol/L"`
- Gauge gets reference range via `getLabReferenceRange('creatinine', 'µmol/L')` → SI range (53-141)
- Display shows: "120 µmol/L" with SI reference range

**Critical in PetService._createLatestLabSummary:**
```dart
// WRONG (current code - will break with SI units):
final creatinineValue = labResult.creatinine?.valueUs ?? labResult.creatinine?.value;

// CORRECT (planned implementation):
final creatinineValue = labResult.creatinine?.value;  // Always use entered value
```

---

## Phase 1: Reference Ranges Enhancement

### 1.1 Update `lib/core/constants/lab_reference_ranges.dart`

**Add SI unit reference ranges and helper functions:**

```dart
// After the existing US ranges (lines 69-118), add:

// =============================================================================
// SI Unit Reference Ranges
// =============================================================================

/// Creatinine reference range for cats (SI units).
///
/// **Normal Range**: 53 - 141 �mol/L
///
/// **Conversion**: 1 mg/dL = 88.4 �mol/L
/// **Clinical Significance**: Same as US units, but reported in �mol/L
/// in countries using SI units (Europe, Australia, etc.)
const creatinineRangeSi = LabReferenceRange(
  min: 53,
  max: 141,
  unit: '�mol/L',
);

/// Blood Urea Nitrogen (BUN) reference range for cats (SI units).
///
/// **Normal Range**: 5.7 - 11.8 mmol/L
///
/// **Conversion**: 1 mg/dL = 0.357 mmol/L
/// **Clinical Significance**: Same as US units, but reported in mmol/L
/// in SI regions. In SI contexts, this is often called "Urea" instead of BUN.
const bunRangeSi = LabReferenceRange(
  min: 5.7,
  max: 11.8,
  unit: 'mmol/L',
);

// =============================================================================
// Helper Functions
// =============================================================================

/// Gets the appropriate reference range for a lab analyte based on unit.
///
/// Supports:
/// - Creatinine: mg/dL (US) or �mol/L (SI)
/// - BUN: mg/dL (US) or mmol/L (SI)
/// - SDMA: �g/dL (universal, no unit variants)
///
/// Throws [ArgumentError] if analyte or unit is not supported.
///
/// Example:
/// ```dart
/// final range = getLabReferenceRange('creatinine', '�mol/L');
/// print(range.getDisplayRange()); // "53 - 141 �mol/L"
/// ```
LabReferenceRange getLabReferenceRange(String analyte, String unit) {
  switch (analyte.toLowerCase()) {
    case 'creatinine':
      switch (unit) {
        case 'mg/dL':
          return creatinineRange;
        case '�mol/L':
          return creatinineRangeSi;
        default:
          throw ArgumentError(
            'Unsupported unit "$unit" for creatinine. '
            'Expected "mg/dL" or "�mol/L".',
          );
      }
    case 'bun':
      switch (unit) {
        case 'mg/dL':
          return bunRange;
        case 'mmol/L':
          return bunRangeSi;
        default:
          throw ArgumentError(
            'Unsupported unit "$unit" for BUN. '
            'Expected "mg/dL" or "mmol/L".',
          );
      }
    case 'sdma':
      if (unit != '�g/dL') {
        throw ArgumentError(
          'Unsupported unit "$unit" for SDMA. '
          'Only "�g/dL" is supported.',
        );
      }
      return sdmaRange;
    default:
      throw ArgumentError('Unsupported analyte: "$analyte"');
  }
}

/// Returns the default unit for an analyte in the specified unit system.
///
/// [analyte] should be 'creatinine', 'bun', or 'sdma'.
/// [unitSystem] should be 'us' or 'si'.
///
/// SDMA always returns '�g/dL' regardless of unit system.
///
/// Example:
/// ```dart
/// final unit = getDefaultUnit('creatinine', 'si'); // '�mol/L'
/// final unit2 = getDefaultUnit('bun', 'us'); // 'mg/dL'
/// ```
String getDefaultUnit(String analyte, String unitSystem) {
  switch (analyte.toLowerCase()) {
    case 'creatinine':
      return unitSystem == 'si' ? '�mol/L' : 'mg/dL';
    case 'bun':
      return unitSystem == 'si' ? 'mmol/L' : 'mg/dL';
    case 'sdma':
      return '�g/dL'; // Universal unit
    default:
      throw ArgumentError('Unsupported analyte: "$analyte"');
  }
}
```

---

## Phase 2: Lab Values Entry Dialog

### 2.1 Create `lib/features/profile/widgets/lab_values_entry_dialog.dart`

**New file following the `WeightEntryDialog` pattern:**

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/core/constants/app_animations.dart';
import 'package:hydracat/core/constants/app_colors.dart';
import 'package:hydracat/core/constants/lab_reference_ranges.dart';
import 'package:hydracat/core/theme/app_spacing.dart';
import 'package:hydracat/core/theme/app_text_styles.dart';
import 'package:hydracat/core/utils/number_input_utils.dart';
import 'package:hydracat/features/logging/widgets/logging_popup_wrapper.dart';
import 'package:hydracat/features/profile/models/lab_result.dart';
import 'package:hydracat/shared/widgets/widgets.dart';
import 'package:intl/intl.dart';

/// Dialog for adding or editing lab values
///
/// Supports:
/// - Add mode (existingResult == null) - opens with today's date, empty values
/// - Edit mode (existingResult != null) - opens pre-filled with existing values
/// - Unit system toggle (US/SI) for Creatinine and BUN
/// - Date selection (backdate allowed up to 3 years, future dates blocked)
/// - Lab value inputs (Creatinine, BUN, SDMA) with unit-aware labels
/// - Optional vet notes field (max 500 chars, expands when focused)
/// - Validation: date required, at least one value required
class LabValuesEntryDialog extends ConsumerStatefulWidget {
  /// Creates a [LabValuesEntryDialog]
  const LabValuesEntryDialog({
    this.existingResult,
    super.key,
  });

  /// Existing lab result for edit mode (null for add mode)
  final LabResult? existingResult;

  @override
  ConsumerState<LabValuesEntryDialog> createState() =>
      _LabValuesEntryDialogState();
}

class _LabValuesEntryDialogState extends ConsumerState<LabValuesEntryDialog> {
  late final TextEditingController _creatinineController;
  late final TextEditingController _bunController;
  late final TextEditingController _sdmaController;
  late final TextEditingController _vetNotesController;
  late final FocusNode _notesFocusNode;

  late DateTime _selectedDate;
  String _unitSystem = 'us'; // 'us' or 'si'
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _selectedDate = widget.existingResult?.testDate ?? DateTime.now();
    _notesFocusNode = FocusNode();

    // Initialize controllers
    _creatinineController = TextEditingController();
    _bunController = TextEditingController();
    _sdmaController = TextEditingController();
    _vetNotesController = TextEditingController();

    // Pre-fill if editing
    if (widget.existingResult != null) {
      final result = widget.existingResult!;

      // Pre-fill creatinine
      if (result.creatinine != null) {
        _creatinineController.text = result.creatinine!.value.toString();
        // Detect unit system from stored unit
        if (result.creatinine!.unit == '�mol/L') {
          _unitSystem = 'si';
        }
      }

      // Pre-fill BUN
      if (result.bun != null) {
        _bunController.text = result.bun!.value.toString();
      }

      // Pre-fill SDMA
      if (result.sdma != null) {
        _sdmaController.text = result.sdma!.value.toString();
      }

      // Pre-fill vet notes
      if (result.metadata?.vetNotes != null) {
        _vetNotesController.text = result.metadata!.vetNotes!;
      }
    }

    _notesFocusNode.addListener(() {
      setState(() {}); // Rebuild to show/hide counter
    });
  }

  @override
  void dispose() {
    _creatinineController.dispose();
    _bunController.dispose();
    _sdmaController.dispose();
    _vetNotesController.dispose();
    _notesFocusNode.dispose();
    super.dispose();
  }

  /// Validates the form and returns lab values data (or null if invalid)
  Map<String, dynamic>? _validateAndGetData() {
    // Validate date
    if (_selectedDate.isAfter(DateTime.now())) {
      setState(() {
        _errorMessage = 'Bloodwork date cannot be in the future';
      });
      return null;
    }

    // Parse values
    final creatinineText = _creatinineController.text.trim();
    final bunText = _bunController.text.trim();
    final sdmaText = _sdmaController.text.trim();

    final creatinine = creatinineText.isNotEmpty
        ? double.tryParse(creatinineText.replaceAll(',', '.'))
        : null;
    final bun = bunText.isNotEmpty
        ? double.tryParse(bunText.replaceAll(',', '.'))
        : null;
    final sdma = sdmaText.isNotEmpty
        ? double.tryParse(sdmaText.replaceAll(',', '.'))
        : null;

    // Validate at least one value
    if (creatinine == null && bun == null && sdma == null) {
      setState(() {
        _errorMessage = 'Please enter at least one lab value';
      });
      return null;
    }

    // Validate positive values
    if (creatinine != null && creatinine <= 0) {
      setState(() {
        _errorMessage = 'Creatinine must be greater than 0';
      });
      return null;
    }
    if (bun != null && bun <= 0) {
      setState(() {
        _errorMessage = 'BUN must be greater than 0';
      });
      return null;
    }
    if (sdma != null && sdma <= 0) {
      setState(() {
        _errorMessage = 'SDMA must be greater than 0';
      });
      return null;
    }

    // Validate vet notes length
    final vetNotes = _vetNotesController.text.trim();
    if (vetNotes.length > 500) {
      setState(() {
        _errorMessage = 'Vet notes must be 500 characters or less';
      });
      return null;
    }

    // Get units based on unit system
    final creatinineUnit = getDefaultUnit('creatinine', _unitSystem);
    final bunUnit = getDefaultUnit('bun', _unitSystem);
    final sdmaUnit = getDefaultUnit('sdma', _unitSystem);

    return {
      'testDate': _selectedDate,
      'creatinine': creatinine,
      'creatinineUnit': creatinineUnit,
      'bun': bun,
      'bunUnit': bunUnit,
      'sdma': sdma,
      'sdmaUnit': sdmaUnit,
      'vetNotes': vetNotes.isEmpty ? null : vetNotes,
      'unitSystem': _unitSystem,
    };
  }

  Future<void> _selectDate() async {
    final picked = await HydraDatePicker.show(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 3)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Widget _buildDateSelector() {
    return InkWell(
      onTap: _selectDate,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Text(
              DateFormat('MMM dd, yyyy').format(_selectedDate),
              style: AppTextStyles.body,
            ),
            const Spacer(),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderDateSelector() {
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 260),
        child: _buildDateSelector(),
      ),
    );
  }

  Widget _buildHeaderAction() {
    final isCupertino =
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
    final label = isCupertino ? 'Done' : 'Save';

    return TextButton(
      onPressed: _save,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        label,
        style: AppTextStyles.buttonPrimary.copyWith(
          fontWeight: isCupertino ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
    );
  }

  void _save() {
    final data = _validateAndGetData();
    if (data == null) return;

    Navigator.of(context).pop(data);
  }

  Widget _buildUnitSystemToggle() {
    return Row(
      children: [
        Text(
          'Unit System:',
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: HydraSlidingSegmentedControl<String>(
            value: _unitSystem,
            segments: const {
              'us': Text('US Units'),
              'si': Text('SI Units'),
            },
            onChanged: (newSystem) {
              setState(() {
                _unitSystem = newSystem;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLabValueField({
    required TextEditingController controller,
    required String label,
    required String unit,
    required String hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
            children: [
              TextSpan(
                text: ' ($unit)',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        HydraTextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
          ),
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            hintText: hintText,
            suffixIcon: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.only(
                  right: AppSpacing.md,
                ),
                alignment: Alignment.centerRight,
                width: 60,
                child: Text(
                  unit,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
          ),
          inputFormatters: NumberInputUtils.getDecimalFormatters(),
          onChanged: (_) {
            if (_errorMessage != null) {
              setState(() {
                _errorMessage = null;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildErrorMessage() {
    if (_errorMessage == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.errorLight.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.errorLight),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: AppColors.error,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              _errorMessage!,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.existingResult != null;
    final theme = Theme.of(context);

    // Get units based on current unit system
    final creatinineUnit = getDefaultUnit('creatinine', _unitSystem);
    final bunUnit = getDefaultUnit('bun', _unitSystem);
    final sdmaUnit = getDefaultUnit('sdma', _unitSystem);

    return LoggingPopupWrapper(
      title: isEditMode ? 'Edit Lab Values' : 'Add Lab Values',
      headerContent: _buildHeaderDateSelector(),
      trailing: _buildHeaderAction(),
      showCloseButton: false,
      onDismiss: () {
        // No special cleanup needed
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.sm),

          // Unit system toggle
          _buildUnitSystemToggle(),

          const SizedBox(height: AppSpacing.md),

          // Info text
          Text(
            'Enter any values you have available. All fields are optional.',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Creatinine
          _buildLabValueField(
            controller: _creatinineController,
            label: 'Creatinine',
            unit: creatinineUnit,
            hintText: '0.00',
          ),

          const SizedBox(height: AppSpacing.md),

          // BUN
          _buildLabValueField(
            controller: _bunController,
            label: 'BUN (Blood Urea Nitrogen)',
            unit: bunUnit,
            hintText: '0.00',
          ),

          const SizedBox(height: AppSpacing.md),

          // SDMA
          _buildLabValueField(
            controller: _sdmaController,
            label: 'SDMA',
            unit: sdmaUnit,
            hintText: '0.00',
          ),

          const SizedBox(height: AppSpacing.md),

          // Vet notes
          Text(
            'Veterinarian Notes (Optional)',
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          HydraTextField(
            controller: _vetNotesController,
            focusNode: _notesFocusNode,
            maxLength: 500,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              hintText: 'e.g., "Vet recommends monitoring hydration levels"',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              counter: AnimatedOpacity(
                opacity: _notesFocusNode.hasFocus ? 1.0 : 0.0,
                duration: AppAnimations.getDuration(
                  context,
                  const Duration(milliseconds: 200),
                ),
                child: Text('${_vetNotesController.text.length}/500'),
              ),
            ),
            minLines: _vetNotesController.text.isNotEmpty ? 3 : 1,
            maxLines: 5,
            onChanged: (_) {
              setState(() {}); // Update counter and line count
            },
          ),

          const SizedBox(height: AppSpacing.sm),

          // Error message
          _buildErrorMessage(),
        ],
      ),
    );
  }
}
```

---

## Phase 3: Profile Screen Updates

### 3.1 Update `lib/features/profile/screens/ckd_profile_screen.dart`

**Changes needed:**

#### A. Remove old lab values editing UI (lines 381-485)

Remove the entire `_buildLabValuesSection()` method and replace with:

```dart
/// Build Lab Values section with card display
Widget _buildLabValuesSection() {
  final latestResult = primaryPet?.medicalInfo.latestLabResult;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Lab Values',
            style: AppTextStyles.h3.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextButton.icon(
            onPressed: _showAddLabValuesDialog,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.md),

      // Lab values card
      Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Bloodwork date at top
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  latestResult?.testDate != null
                      ? 'Bloodwork: ${_formatDate(latestResult!.testDate)}'
                      : 'No bloodwork recorded',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                if (latestResult != null)
                  IconButton(
                    onPressed: _showEditLabValuesDialog,
                    icon: const Icon(Icons.edit, size: 18),
                    tooltip: 'Edit',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),
            const Divider(),
            const SizedBox(height: AppSpacing.md),

            // Lab values with gauges
            LabValueDisplayWithGauge(
              label: 'Creatinine',
              value: latestResult?.creatinine,
              unit: latestResult != null
                  ? _getCreatinineUnit(latestResult)
                  : 'mg/dL',
              referenceRange: latestResult != null
                  ? getLabReferenceRange(
                      'creatinine',
                      _getCreatinineUnit(latestResult),
                    )
                  : creatinineRange,
              onEdit: latestResult != null ? _showEditLabValuesDialog : null,
            ),
            const SizedBox(height: AppSpacing.sm),
            LabValueDisplayWithGauge(
              label: 'BUN',
              value: latestResult?.bun,
              unit: latestResult != null
                  ? _getBunUnit(latestResult)
                  : 'mg/dL',
              referenceRange: latestResult != null
                  ? getLabReferenceRange('bun', _getBunUnit(latestResult))
                  : bunRange,
              onEdit: latestResult != null ? _showEditLabValuesDialog : null,
            ),
            const SizedBox(height: AppSpacing.sm),
            LabValueDisplayWithGauge(
              label: 'SDMA',
              value: latestResult?.sdma,
              unit: '�g/dL',
              referenceRange: sdmaRange,
              onEdit: latestResult != null ? _showEditLabValuesDialog : null,
            ),
          ],
        ),
      ),
    ],
  );
}

/// Get creatinine unit from latest result (with fallback)
String _getCreatinineUnit(LatestLabSummary result) {
  return result.preferredUnitSystem == 'si' ? '�mol/L' : 'mg/dL';
}

/// Get BUN unit from latest result (with fallback)
String _getBunUnit(LatestLabSummary result) {
  return result.preferredUnitSystem == 'si' ? 'mmol/L' : 'mg/dL';
}
```

#### B. Add dialog show methods (add before the `build` method):

```dart
/// Show dialog to add new lab values
Future<void> _showAddLabValuesDialog() async {
  final result = await showHydraBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: AppColors.background,
    builder: (sheetContext) => const HydraBottomSheet(
      backgroundColor: AppColors.background,
      child: LabValuesEntryDialog(),
    ),
  );

  if (result != null && mounted) {
    await _saveLabResult(result);
  }
}

/// Show dialog to edit latest lab values
Future<void> _showEditLabValuesDialog() async {
  final primaryPet = ref.read(primaryPetProvider);
  if (primaryPet == null) return;

  // Get the full latest lab result to pre-fill the dialog
  final latestSummary = primaryPet.medicalInfo.latestLabResult;
  if (latestSummary == null) return;

  // Fetch the full lab result from the subcollection
  final fullResult = await ref
      .read(profileProvider.notifier)
      .getLabResult(latestSummary.labResultId);

  if (fullResult == null) {
    if (mounted) {
      HydraSnackBar.showError(
        context,
        'Could not load lab result details',
      );
    }
    return;
  }

  if (!mounted) return;

  final result = await showHydraBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: AppColors.background,
    builder: (sheetContext) => HydraBottomSheet(
      backgroundColor: AppColors.background,
      child: LabValuesEntryDialog(existingResult: fullResult),
    ),
  );

  if (result != null && mounted) {
    await _saveLabResult(result);
  }
}

/// Save lab result from dialog data
Future<void> _saveLabResult(Map<String, dynamic> data) async {
  setState(() {
    _isSaving = true;
    _saveError = null;
  });

  try {
    final primaryPet = ref.read(primaryPetProvider);
    if (primaryPet == null) {
      throw Exception('No pet profile found');
    }

    // Build the values map with LabMeasurement objects
    final values = <String, LabMeasurement>{};

    if (data['creatinine'] != null) {
      values['creatinine'] = LabMeasurement(
        value: data['creatinine'] as double,
        unit: data['creatinineUnit'] as String,
      );
    }

    if (data['bun'] != null) {
      values['bun'] = LabMeasurement(
        value: data['bun'] as double,
        unit: data['bunUnit'] as String,
      );
    }

    if (data['sdma'] != null) {
      values['sdma'] = LabMeasurement(
        value: data['sdma'] as double,
        unit: data['sdmaUnit'] as String,
      );
    }

    // Create metadata if we have vet notes
    LabResultMetadata? metadata;
    if (data['vetNotes'] != null) {
      metadata = LabResultMetadata(
        vetNotes: data['vetNotes'] as String?,
        source: 'manual',
      );
    }

    // Create the lab result
    final labResult = LabResult.create(
      petId: primaryPet.id,
      testDate: data['testDate'] as DateTime,
      values: values,
      metadata: metadata,
    );

    // Save via provider
    final success = await ref
        .read(profileProvider.notifier)
        .createLabResult(
          labResult: labResult,
          preferredUnitSystem: data['unitSystem'] as String,
        );

    if (success && mounted) {
      HydraSnackBar.showSuccess(context, 'Lab values saved successfully');
    } else if (mounted) {
      setState(() {
        _saveError = 'Failed to save lab values';
      });
    }
  } on Exception catch (e) {
    if (mounted) {
      setState(() {
        _saveError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  } finally {
    if (mounted) {
      setState(() {
        _isSaving = false;
      });
    }
  }
}
```

#### C. Add imports at the top of the file:

```dart
import 'package:hydracat/core/constants/lab_reference_ranges.dart';
import 'package:hydracat/features/profile/models/lab_measurement.dart';
import 'package:hydracat/features/profile/models/lab_result.dart';
import 'package:hydracat/features/profile/widgets/lab_values_entry_dialog.dart';
```

#### D. Update state variables (around line 25):

Remove these lines (no longer needed):
```dart
LabValueData _editingLabValues = const LabValueData();
bool _isEditingLabValues = false;
```

Update `_initializeFromProfile()` method to remove lab values initialization:
```dart
void _initializeFromProfile() {
  final primaryPet = ref.read(primaryPetProvider);
  if (primaryPet?.medicalInfo != null) {
    final medicalInfo = primaryPet!.medicalInfo;
    setState(() {
      _editingIrisStage = medicalInfo.irisStage;
      // Remove lab values initialization - no longer using inline editing
      _editingLastCheckupDate = medicalInfo.lastCheckupDate;
      _editingNotes = medicalInfo.notes ?? '';
    });
  }
}
```

Update `_saveChanges()` method to remove lab values handling:
```dart
Future<void> _saveChanges() async {
  setState(() {
    _isSaving = true;
    _saveError = null;
  });

  try {
    final primaryPet = ref.read(primaryPetProvider);
    if (primaryPet == null) {
      throw Exception('No pet profile found');
    }

    // Create updated medical info (remove lab values update)
    final updatedMedicalInfo = primaryPet.medicalInfo.copyWith(
      irisStage: _editingIrisStage,
      // labValues removed - now using labResults subcollection
      lastCheckupDate: _editingLastCheckupDate,
      notes: _editingNotes.trim().isEmpty ? null : _editingNotes.trim(),
    );

    // Validate the updated medical info
    final validationErrors = updatedMedicalInfo.validate();
    if (validationErrors.isNotEmpty) {
      throw Exception(validationErrors.first);
    }

    // Update the profile with new medical info
    final updatedProfile = primaryPet.copyWith(
      medicalInfo: updatedMedicalInfo,
      updatedAt: DateTime.now(),
    );

    // Save to Firebase via provider
    await ref.read(profileProvider.notifier).updatePet(updatedProfile);

    // Reset change tracking
    setState(() {
      _hasChanges = false;
      _isEditingIrisStage = false;
      // Remove lab values edit mode
      _isEditingLastCheckup = false;
      _isEditingNotes = false;
    });

    // Show success feedback
    if (mounted) {
      HydraSnackBar.showSuccess(context, 'CKD profile updated successfully');
    }
  } on Exception catch (e) {
    setState(() {
      _saveError = e.toString().replaceFirst('Exception: ', '');
    });
  } finally {
    if (mounted) {
      setState(() {
        _isSaving = false;
      });
    }
  }
}
```

---

### 3.2 Update `lib/features/profile/widgets/lab_value_display_with_gauge.dart`

**Update to support unit parameter and dynamic reference ranges:**

Around line 10-30, update the constructor:

```dart
class LabValueDisplayWithGauge extends StatelessWidget {
  /// Creates a [LabValueDisplayWithGauge]
  const LabValueDisplayWithGauge({
    required this.label,
    required this.value,
    required this.referenceRange,
    this.unit, // NEW: Make unit optional but recommended
    this.onEdit,
    super.key,
  });

  /// Label for the lab value (e.g., 'Creatinine', 'BUN', 'SDMA')
  final String label;

  /// The measured value (null if not measured)
  final double? value;

  /// Reference range for the gauge display (supports different units)
  final LabReferenceRange referenceRange;

  /// Unit of measurement (e.g., 'mg/dL', '�mol/L', '�g/dL')
  /// If null, uses the unit from referenceRange
  final String? unit;

  /// Callback when edit button is tapped (null to hide edit button)
  final VoidCallback? onEdit;
```

Update the build method to use the provided unit:

```dart
@override
Widget build(BuildContext context) {
  final displayUnit = unit ?? referenceRange.unit;

  return Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      children: [
        // Gauge
        SizedBox(
          width: 48,
          height: 48,
          child: HydraGauge(
            value: value,
            min: referenceRange.min,
            max: referenceRange.max,
            showValue: false,
          ),
        ),
        const SizedBox(width: AppSpacing.md),

        // Label and value
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                value != null
                    ? '${value!.toStringAsFixed(1)} $displayUnit'
                    : 'Not measured',
                style: AppTextStyles.h3.copyWith(
                  color: value != null
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Normal: ${referenceRange.getDisplayRange()}',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),

        // Edit button (if callback provided)
        if (onEdit != null)
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit, size: 18),
            tooltip: 'Edit',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
          ),
      ],
    ),
  );
}
```

---

### 3.3 Add method to ProfileProvider

Update `lib/providers/profile_provider.dart` to add the `getLabResult` method:

```dart
/// Gets a specific lab result by ID
Future<LabResult?> getLabResult(String labResultId) async {
  final primaryPet = state.primaryPet;
  if (primaryPet == null) return null;

  return _petService.getLabResult(primaryPet.id, labResultId);
}
```

---

### 3.4 Fix PetService._createLatestLabSummary (CRITICAL)

**Location:** `lib/features/profile/services/pet_service.dart` (around line 872-897)

**Current code (BROKEN for SI units):**
```dart
LatestLabSummary _createLatestLabSummary(
  LabResult labResult,
  String? preferredUnitSystem,
) {
  // WRONG: Falls back to valueUs, assumes US conversion exists
  final creatinineValue = labResult.creatinine?.valueUs ??
      labResult.creatinine?.value;
  final bunValue = labResult.bun?.valueUs ?? labResult.bun?.value;
  final sdmaValue = labResult.sdma?.value;
  final phosphorusValue =
      labResult.phosphorus?.valueUs ?? labResult.phosphorus?.value;

  return LatestLabSummary(
    testDate: labResult.testDate,
    labResultId: labResult.id,
    creatinine: creatinineValue,
    bun: bunValue,
    sdma: sdmaValue,
    phosphorus: phosphorusValue,
    preferredUnitSystem: preferredUnitSystem ?? 'us',
  );
}
```

**Replace with (CORRECT - stores entered value):**
```dart
/// Helper to create a denormalized lab summary from a full LabResult
///
/// CRITICAL: Stores the user-entered value with the preferredUnitSystem.
/// The actual unit for each analyte is derived at display time using
/// getDefaultUnit(analyte, preferredUnitSystem).
///
/// This works because the unit toggle applies to ALL values:
/// - preferredUnitSystem='us' → creatinine in mg/dL, BUN in mg/dL
/// - preferredUnitSystem='si' → creatinine in µmol/L, BUN in mmol/L
/// - SDMA always in µg/dL regardless of system
///
/// Example:
/// If user enters Creatinine=120 in SI units:
/// - LabResult stores: {value: 120, unit: "µmol/L", valueUs: null, valueSi: null}
/// - LatestLabSummary stores: {creatinine: 120, preferredUnitSystem: "si"}
/// - Display derives: unit = getDefaultUnit('creatinine', 'si') = "µmol/L"
/// - Gauge uses: getLabReferenceRange('creatinine', 'µmol/L') = SI range (53-141)
LatestLabSummary _createLatestLabSummary(
  LabResult labResult,
  String? preferredUnitSystem,
) {
  // Extract the entered values directly (NOT valueUs/valueSi - those are null)
  final creatinineValue = labResult.creatinine?.value;
  final bunValue = labResult.bun?.value;
  final sdmaValue = labResult.sdma?.value;
  final phosphorusValue = labResult.phosphorus?.value;

  return LatestLabSummary(
    testDate: labResult.testDate,
    labResultId: labResult.id,
    creatinine: creatinineValue,
    bun: bunValue,
    sdma: sdmaValue,
    phosphorus: phosphorusValue,
    preferredUnitSystem: preferredUnitSystem ?? 'us',
  );
}
```

**Why this fix is critical:**
- The old code assumes `valueUs` exists (it doesn't - we don't do conversions)
- When user enters SI values, `valueUs` is null, so it falls back to `value`
- But then the `preferredUnitSystem` is wrong, causing gauge mismatches
- New code always uses `value` (the entered value) and trusts `preferredUnitSystem`

---

### 3.5 Onboarding Integration (Vet Notes Handling)

**Issue:** `LabValuesInput` is used in onboarding and collects vet notes, but the onboarding flow might not properly save those notes to `LabResult`.

**Location:** `lib/features/onboarding/services/onboarding_service.dart` or wherever onboarding creates the initial lab result

**Current behavior:**
- Onboarding uses `LabValuesInput` which collects `LabValueData` (includes `vetNotes`)
- When creating the pet profile, lab values might be saved to `medicalInfo.labValues` (old system)
- Vet notes might be discarded

**Required changes:**

1. **Verify onboarding creates a `LabResult` entry** (not just inline `labValues`)
   - If onboarding creates initial lab values, it should use `PetService.createLabResult()`
   - This ensures data goes into the `labResults` subcollection with proper structure

2. **Include vet notes from `LabValueData.vetNotes`** when creating the `LabResult`:
```dart
// In onboarding flow, when creating initial lab result:
if (onboardingData.labValues.hasValues &&
    onboardingData.labValues.bloodworkDate != null) {

  final values = <String, LabMeasurement>{};

  if (onboardingData.labValues.creatinine != null) {
    values['creatinine'] = LabMeasurement(
      value: onboardingData.labValues.creatinine!,
      unit: 'mg/dL',  // Onboarding currently defaults to US units
    );
  }

  // ... similar for bun, sdma ...

  // Include vet notes in metadata
  LabResultMetadata? metadata;
  if (onboardingData.labValues.vetNotes != null &&
      onboardingData.labValues.vetNotes!.isNotEmpty) {
    metadata = LabResultMetadata(
      vetNotes: onboardingData.labValues.vetNotes,
      source: 'onboarding',
    );
  }

  final labResult = LabResult.create(
    petId: newPet.id,
    testDate: onboardingData.labValues.bloodworkDate!,
    values: values,
    metadata: metadata,
  );

  await petService.createLabResult(
    petId: newPet.id,
    labResult: labResult,
    preferredUnitSystem: 'us',
  );
}
```

3. **Keep `LabValuesInput` for onboarding** (don't remove vet notes field)
   - Onboarding still uses `LabValuesInput` with vet notes
   - Profile editing uses the new `LabValuesEntryDialog`
   - No duplication or confusion

**Summary:**
- **Onboarding**: `LabValuesInput` → `LabValueData` (with vetNotes) → `LabResult` (with metadata)
- **Profile editing**: `LabValuesEntryDialog` → dialog data (with vetNotes) → `LabResult` (with metadata)
- **No more inline editing**: Remove `LabValuesInput` from CKD profile screen (Phase 3)
- **Single source of truth**: Vet notes always stored in `LabResult.metadata.vetNotes`

---

## Phase 4: Testing & Validation

### 4.1 Manual Testing Checklist

After implementation, test these scenarios:

**Add New Lab Result:**
a. Navigate to CKD Profile screen
b. Tap "+ Add" in app bar
c. Select today's date
d. Toggle to "SI Units"
e. Enter Creatinine: 120 (�mol/L)
f. Enter BUN: 8.5 (mmol/L)
g. Enter SDMA: 16 (�g/dL)
h. Enter vet notes: "Slightly elevated, monitor hydration"
i. Tap "Done"
j. Verify card shows new values with correct units
k. Verify gauges use SI reference ranges

**Edit Existing Lab Result:**
a. Tap "Edit" button on lab values card
b. Verify date is pre-filled with latest bloodwork date
c. Verify values are pre-filled with latest values
d. Verify unit system matches stored units (SI if stored in SI)
e. Change Creatinine to 115
f. Tap "Done"
g. Verify card updates with new value
h. Check Firestore: new entry created in labResults subcollection
i. Check Firestore: pet doc has updated latestLabResult

**Validation:**
a. Try to save without entering any values � Error: "Please enter at least one lab value"
b. Try to enter negative value � Error: "must be greater than 0"
c. Try to enter future date � Error: "cannot be in the future"
d. Try to enter 501 characters in vet notes � Error: "must be 500 characters or less"

**Unit System:**
a. Enter values in US units, verify stored with mg/dL
b. Enter values in SI units, verify stored with �mol/L and mmol/L
c. Verify SDMA always stored as �g/dL regardless of toggle

**Edge Cases:**
a. Add result with only Creatinine (BUN and SDMA empty) � Should save
b. Edit result but don't change anything � Should create new entry with same values
c. Rapidly tap Save button � Should only save once (no duplicates)

### 4.2 Firestore Verification

After adding/editing lab values, check Firestore:

**Lab Result Document Structure:**
```
users/{userId}/pets/{petId}/labResults/{labResultId}
{
  "id": "uuid-here",
  "petId": "pet-id-here",
  "testDate": Timestamp,
  "values": {
    "creatinine": {
      "value": 120,
      "unit": "�mol/L"
    },
    "bun": {
      "value": 8.5,
      "unit": "mmol/L"
    },
    "sdma": {
      "value": 16,
      "unit": "�g/dL"
    }
  },
  "metadata": {
    "vetNotes": "Slightly elevated, monitor hydration",
    "source": "manual"
  },
  "createdAt": Timestamp,
  "updatedAt": null
}
```

**Pet Document Update:**
```
users/{userId}/pets/{petId}
{
  ...
  "medicalInfo": {
    ...
    "latestLabResult": {
      "testDate": Timestamp,
      "labResultId": "uuid-here",
      "creatinine": 120,
      "bun": 8.5,
      "sdma": 16,
      "preferredUnitSystem": "si"
    }
  }
}
```

---

## Phase 5: Linting & Cleanup

### 5.1 Run Flutter Analyze

```bash
flutter analyze
```

### 5.2 Fix Common Linting Issues

**Expected issues and fixes:**

a. **Unused imports** - Remove any unused imports
b. **Missing documentation** - Add doc comments to public APIs
c. **Prefer const constructors** - Add const where possible
d. **Lines too long** - Break lines exceeding 80 characters
e. **Trailing commas** - Add trailing commas for better formatting

### 5.3 Code Review Checklist

- [ ] All new files follow existing naming conventions
- [ ] All widgets follow HydraCat theme/styling patterns
- [ ] No hardcoded strings (use proper error messages)
- [ ] Proper null safety handling throughout
- [ ] Follows Firebase CRUD rules (batch writes, denormalization)
- [ ] No console errors or warnings in the code
- [ ] State management follows Riverpod patterns
- [ ] Form validation matches existing patterns
- [ ] Loading states handled appropriately
- [ ] Error states handled with user-friendly messages

---

## Phase 6: Documentation Updates

### 6.1 Update Schema Documentation

Add to `.cursor/rules/firestore_schema.md`:

```markdown
### Lab Results Unit Storage

Lab values are stored with user-entered units (no automatic conversion):
- Creatinine: `mg/dL` (US) or `�mol/L` (SI)
- BUN: `mg/dL` (US) or `mmol/L` (SI)
- SDMA: `�g/dL` (universal)

Each analyte in the `values` map includes:
- `value`: Number as entered by user
- `unit`: Unit selected by user
- `valueSi`: null (not used)
- `valueUs`: null (not used)

Reference ranges are retrieved at display time based on stored unit.
```

### 6.2 Update Planning Status

Mark this plan as DONE and move to `~PLANNING/DONE/lab_values_edit.md` after successful implementation and testing.

---

## Edge Cases & Error Handling

### Data Migration Considerations

**Existing `medicalInfo.labValues` data:**
- System will prefer `latestLabResult` if available
- If only legacy `labValues` exists, display will fallback gracefully
- Migration script not needed for this phase (can be done separately)

### Offline Support

- Lab values entry cached optimistically
- On network failure, show appropriate error message
- Provider will retry on reconnection

### Concurrent Edits

- Last write wins (Firebase default behavior)
- Each edit creates new historical entry (no overwrite conflicts)
- Timestamp-based ordering ensures consistency

### Performance Optimization

- `latestLabResult` denormalized on pet doc � instant display, zero reads
- Lab history queried only when explicitly requested (e.g., history view)
- Batch write ensures atomicity (pet doc + subcollection update together)

---

## Success Criteria

 User can add new lab values via "+ Add" button in app bar
 User can edit latest lab values via "Edit" button on card
 Unit system toggle works correctly (US/SI)
 Values stored with user-selected units (no conversion)
 Gauges display with correct reference ranges for stored units
 Form validation prevents invalid data
 Both add and edit create new entries (append-only history)
 Firestore writes follow CRUD rules (batch, denormalized snapshot)
 No linting errors or warnings
 UI follows existing HydraCat patterns (LoggingPopupWrapper, etc.)

---

## Implementation Time Estimate

- Phase 1 (Reference Ranges): 15 minutes
- Phase 2 (Lab Values Entry Dialog): 45 minutes
- Phase 3 (Profile Screen Updates): 45 minutes
- Phase 4 (Testing): 30 minutes (user-performed)
- Phase 5 (Linting & Cleanup): 15 minutes
- Phase 6 (Documentation): 10 minutes

**Total: ~2.5 hours** (excluding user testing time)

---

## Notes

- Keep existing `add_lab_result_screen.dart` for potential future use cases (onboarding, etc.)
- This implementation maintains backwards compatibility with existing data models
- Future enhancement: Full lab history view with list/chart visualization
- Future enhancement: Export lab history to PDF/CSV for vet visits
