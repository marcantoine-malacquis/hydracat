/// Lab reference ranges for veterinary bloodwork values.
///
/// Contains reference range definitions and constants for common lab values
/// used in chronic kidney disease (CKD) monitoring in cats.
///
/// All reference ranges are based on standard feline veterinary values.
library;

/// Represents a reference range for a laboratory value.
///
/// A reference range defines the normal (healthy) range for a lab measurement,
/// with a minimum and maximum value. Values outside this range may indicate
/// a health concern.
class LabReferenceRange {
  /// Creates a lab reference range.
  ///
  /// [min] is the minimum normal value (inclusive).
  /// [max] is the maximum normal value (inclusive).
  /// [unit] is the unit of measurement (e.g., "mg/dL", "µg/dL").
  const LabReferenceRange({
    required this.min,
    required this.max,
    required this.unit,
  });

  /// Minimum normal value (inclusive).
  final double min;

  /// Maximum normal value (inclusive).
  final double max;

  /// Unit of measurement.
  final String unit;

  /// Checks if a value falls within the normal reference range.
  ///
  /// Returns `true` if [value] is within [min] and [max] (inclusive),
  /// `false` otherwise.
  bool isInRange(double value) {
    return value >= min && value <= max;
  }

  /// Returns a formatted display string of the reference range.
  ///
  /// Format: "min - max unit"
  /// Example: "0.6 - 1.6 mg/dL"
  String getDisplayRange() {
    return '$min - $max $unit';
  }
}

// =============================================================================
// Lab Value Reference Ranges
// =============================================================================

/// Creatinine reference range for cats.
///
/// **Normal Range**: 0.6 - 1.6 mg/dL
///
/// **Clinical Significance**: Creatinine is a waste product filtered by the
/// kidneys. Elevated creatinine levels indicate reduced kidney function.
/// This is one of the primary markers for chronic kidney disease (CKD).
///
/// - Values < 0.6: Unusual in cats, may indicate muscle wasting
/// - Values 0.6 - 1.6: Normal kidney function
/// - Values 1.6 - 2.8: IRIS Stage 1 CKD (borderline or early)
/// - Values 2.9 - 5.0: IRIS Stage 2 CKD (mild kidney disease)
/// - Values > 5.0: IRIS Stage 3+ CKD (moderate to severe kidney disease)
const creatinineRange = LabReferenceRange(
  min: 0.6,
  max: 1.6,
  unit: 'mg/dL',
);

/// Blood Urea Nitrogen (BUN) reference range for cats.
///
/// **Normal Range**: 16 - 33 mg/dL
///
/// **Clinical Significance**: BUN measures the amount of nitrogen in the blood
/// that comes from urea, a waste product of protein metabolism. Elevated BUN
/// can indicate kidney disease, but can also be affected by diet, hydration,
/// and other factors.
///
/// - Values < 16: May indicate liver disease or overhydration
/// - Values 16 - 33: Normal kidney function
/// - Values > 33: May indicate kidney disease, dehydration, or high
///   protein diet
///
/// **Note**: BUN is less specific than creatinine and should be interpreted
/// alongside creatinine and SDMA values.
const bunRange = LabReferenceRange(
  min: 16,
  max: 33,
  unit: 'mg/dL',
);

/// Symmetric Dimethylarginine (SDMA) reference range for cats.
///
/// **Normal Range**: 0 - 14 µg/dL
///
/// **Clinical Significance**: SDMA is a newer biomarker for kidney function
/// that is more sensitive than creatinine. It can detect kidney disease
/// earlier, often before creatinine levels rise. SDMA is less affected by
/// muscle mass than creatinine.
///
/// - Values 0 - 14: Normal kidney function
/// - Values 15 - 17: Borderline, recheck recommended
/// - Values 18 - 25: IRIS Stage 2 CKD (mild kidney disease)
/// - Values 26 - 38: IRIS Stage 3 CKD (moderate kidney disease)
/// - Values > 38: IRIS Stage 4 CKD (severe kidney disease)
///
/// **Note**: SDMA ≥ 15 µg/dL suggests a decrease of 25% or more in kidney
/// function, even if creatinine is still within normal range.
const sdmaRange = LabReferenceRange(
  min: 0,
  max: 14,
  unit: 'µg/dL',
);

// =============================================================================
// SI Unit Reference Ranges
// =============================================================================

/// Creatinine reference range for cats (SI units).
///
/// **Normal Range**: 53 - 141 µmol/L
///
/// **Conversion**: 1 mg/dL = 88.4 µmol/L
/// **Clinical Significance**: Same as US units, but reported in µmol/L
/// in countries using SI units (Europe, Australia, etc.).
const creatinineRangeSi = LabReferenceRange(
  min: 53,
  max: 141,
  unit: 'µmol/L',
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
/// - Creatinine: mg/dL (US) or µmol/L (SI)
/// - BUN: mg/dL (US) or mmol/L (SI)
/// - SDMA: µg/dL (universal, no unit variants)
///
/// Throws [ArgumentError] if analyte or unit is not supported.
///
/// Example:
/// ```dart
/// final range = getLabReferenceRange('creatinine', 'µmol/L');
/// print(range.getDisplayRange()); // "53 - 141 µmol/L"
/// ```
LabReferenceRange getLabReferenceRange(String analyte, String unit) {
  switch (analyte.toLowerCase()) {
    case 'creatinine':
      switch (unit) {
        case 'mg/dL':
          return creatinineRange;
        case 'µmol/L':
          return creatinineRangeSi;
        default:
          throw ArgumentError(
            'Unsupported unit "$unit" for creatinine. '
            'Expected "mg/dL" or "µmol/L".',
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
      if (unit != 'µg/dL') {
        throw ArgumentError(
          'Unsupported unit "$unit" for SDMA. '
          'Only "µg/dL" is supported.',
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
/// SDMA always returns 'µg/dL' regardless of unit system.
///
/// Example:
/// ```dart
/// final unit = getDefaultUnit('creatinine', 'si'); // 'µmol/L'
/// final unit2 = getDefaultUnit('bun', 'us'); // 'mg/dL'
/// ```
String getDefaultUnit(String analyte, String unitSystem) {
  switch (analyte.toLowerCase()) {
    case 'creatinine':
      return unitSystem == 'si' ? 'µmol/L' : 'mg/dL';
    case 'bun':
      return unitSystem == 'si' ? 'mmol/L' : 'mg/dL';
    case 'sdma':
      return 'µg/dL'; // Universal unit
    default:
      throw ArgumentError('Unsupported analyte: "$analyte"');
  }
}
