/// Utility class for parsing and formatting medication dosage values.
///
/// Handles conversion between string representations (like "1/2", "2.5", "1 1/4")
/// and double values for storage and calculations.
library;
// The library directive may trigger deprecated_member_use warnings
// in some Dart versions.
// ignore_for_file: deprecated_member_use

/// Utility class for parsing and formatting medication dosage values.
class DosageUtils {
  /// Private constructor to prevent instantiation
  const DosageUtils._();

  /// Parses a dosage string and returns the numeric value as a double.
  ///
  /// Supports multiple formats:
  /// - Whole numbers: "1", "2", "10" → 1.0, 2.0, 10.0
  /// - Decimals: "0.5", "2.5", "1.25" → 0.5, 2.5, 1.25
  /// - Fractions: "1/2", "1/4", "3/4" → 0.5, 0.25, 0.75
  /// - Mixed fractions: "1 1/2", "2 1/4" → 1.5, 2.25
  ///
  /// Returns null if the input cannot be parsed.
  ///
  /// Example:
  /// ```dart
  /// DosageUtils.parseDosageString("1/2"); // Returns 0.5
  /// DosageUtils.parseDosageString("2.5"); // Returns 2.5
  /// DosageUtils.parseDosageString("1 1/4"); // Returns 1.25
  /// DosageUtils.parseDosageString("invalid"); // Returns null
  /// ```
  static double? parseDosageString(String input) {
    if (input.trim().isEmpty) {
      return null;
    }

    final trimmed = input.trim();

    // Try parsing as a simple decimal first
    final simpleDecimal = double.tryParse(trimmed);
    if (simpleDecimal != null) {
      return simpleDecimal;
    }

    // Check for fraction pattern: "1/2", "3/4", etc.
    final fractionPattern = RegExp(r'^(\d+)/(\d+)$');
    final fractionMatch = fractionPattern.firstMatch(trimmed);
    if (fractionMatch != null) {
      final numerator = int.tryParse(fractionMatch.group(1)!);
      final denominator = int.tryParse(fractionMatch.group(2)!);
      if (numerator != null && denominator != null && denominator != 0) {
        return numerator / denominator;
      }
      return null;
    }

    // Check for mixed fraction pattern: "1 1/2", "2 3/4", etc.
    final mixedFractionPattern = RegExp(r'^(\d+)\s+(\d+)/(\d+)$');
    final mixedMatch = mixedFractionPattern.firstMatch(trimmed);
    if (mixedMatch != null) {
      final whole = int.tryParse(mixedMatch.group(1)!);
      final numerator = int.tryParse(mixedMatch.group(2)!);
      final denominator = int.tryParse(mixedMatch.group(3)!);
      if (whole != null &&
          numerator != null &&
          denominator != null &&
          denominator != 0) {
        return whole + (numerator / denominator);
      }
      return null;
    }

    // Unable to parse
    return null;
  }

  /// Validates a dosage string before parsing.
  ///
  /// Returns an error message if the dosage is invalid, or null if valid.
  ///
  /// Validation rules:
  /// - Must be parseable (whole number, decimal, fraction, or mixed fraction)
  /// - Must be positive (greater than 0)
  /// - Must be within reasonable range (0.01 to 100)
  ///
  /// Example:
  /// ```dart
  /// DosageUtils.validateDosageString("1/2"); // Returns null (valid)
  /// DosageUtils.validateDosageString("-1"); // Returns error message
  /// DosageUtils.validateDosageString("abc"); // Returns error message
  /// ```
  static String? validateDosageString(String input) {
    if (input.trim().isEmpty) {
      return 'Dosage is required';
    }

    final parsed = parseDosageString(input);
    if (parsed == null) {
      return 'Invalid dosage format. Use whole numbers (1), decimals (2.5), '
          'or fractions (1/2)';
    }

    if (parsed <= 0) {
      return 'Dosage must be greater than 0';
    }

    if (parsed < 0.01) {
      return 'Dosage must be at least 0.01';
    }

    if (parsed > 100) {
      return 'Dosage must be 100 or less';
    }

    return null; // Valid
  }

  /// Formats a dosage value for display.
  ///
  /// Returns a string representation of the dosage with appropriate precision:
  /// - Whole numbers: "1.0" → "1"
  /// - Decimals: "2.5" → "2.5", "1.25" → "1.25"
  /// - Very small values: Shows up to 2 decimal places
  ///
  /// Example:
  /// ```dart
  /// DosageUtils.formatDosageForDisplay(1.0); // Returns "1"
  /// DosageUtils.formatDosageForDisplay(2.5); // Returns "2.5"
  /// DosageUtils.formatDosageForDisplay(0.5); // Returns "0.5"
  /// ```
  static String formatDosageForDisplay(double dosage) {
    // If it's a whole number, show without decimal places
    if (dosage == dosage.roundToDouble()) {
      return dosage.round().toString();
    }

    // Otherwise, show with up to 2 decimal places, removing trailing zeros
    final formatted = dosage.toStringAsFixed(2);

    // Remove trailing zeros and decimal point if not needed
    return formatted.replaceAll(RegExp(r'\.?0*$'), '');
  }

  /// Suggests common dosage fractions based on a decimal value.
  ///
  /// Useful for displaying friendly suggestions in the UI.
  /// Returns the common fraction representation if applicable, otherwise null.
  ///
  /// Common fractions:
  /// - 0.5 → "1/2"
  /// - 0.25 → "1/4"
  /// - 0.75 → "3/4"
  /// - 0.33 → "1/3"
  /// - 0.67 → "2/3"
  ///
  /// Example:
  /// ```dart
  /// DosageUtils.suggestFractionDisplay(0.5); // Returns "1/2"
  /// DosageUtils.suggestFractionDisplay(0.25); // Returns "1/4"
  /// DosageUtils.suggestFractionDisplay(2.5); // Returns null
  /// ```
  static String? suggestFractionDisplay(double dosage) {
    // Only suggest fractions for values less than 1
    if (dosage >= 1.0) {
      return null;
    }

    const tolerance = 0.01; // Small tolerance for floating-point comparison

    // Common fractions
    if ((dosage - 0.5).abs() < tolerance) return '1/2';
    if ((dosage - 0.25).abs() < tolerance) return '1/4';
    if ((dosage - 0.75).abs() < tolerance) return '3/4';
    if ((dosage - 0.33).abs() < tolerance) return '1/3';
    if ((dosage - 0.67).abs() < tolerance) return '2/3';

    return null;
  }
}
