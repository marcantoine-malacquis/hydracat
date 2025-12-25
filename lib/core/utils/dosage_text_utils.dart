/// Utility class for converting numeric dosages to natural language text.
///
/// Provides user-friendly display of medication dosages, converting values
/// like 0.5 to "half a pill" instead of "0.5 pills".
class DosageTextUtils {
  /// Private constructor to prevent instantiation
  const DosageTextUtils._();

  /// Formats a dosage value with its unit in numeric format.
  ///
  /// Displays dosages with decimal precision:
  /// - 0.5 + "pill" → "0.5 pills"
  /// - 1.5 + "pill" → "1.5 pills"
  /// - 0.25 + "capsule" → "0.25 capsules"
  /// - 2 + "pill" → "2 pills"
  ///
  /// Example:
  /// ```dart
  /// DosageTextUtils.formatDosageWithUnit(0.5, "pill");
  /// // Returns: "0.5 pills"
  ///
  /// DosageTextUtils.formatDosageWithUnit(1.25, "pill");
  /// // Returns: "1.25 pills"
  /// ```
  static String formatDosageWithUnit(double dosage, String unitShortForm) {
    // Format the numeric value, removing trailing zeros
    final formatted = dosage
        .toStringAsFixed(2)
        .replaceAll(
          // The library directive may trigger deprecated_member_use warnings
          // in some Dart versions.
          // ignore: deprecated_member_use
          RegExp(r'\.?0*$'),
          '',
        );

    // Use singular unit for 1, plural for all other values
    final unit = dosage == 1.0
        ? _getSingularUnit(unitShortForm)
        : _getPluralUnit(unitShortForm);

    return '$formatted $unit';
  }

  /// Returns the singular form of a unit (handles special cases)
  static String _getSingularUnit(String unitShortForm) {
    // Most units are already singular in shortForm
    return unitShortForm;
  }

  /// Returns the plural form of a unit
  static String _getPluralUnit(String unitShortForm) {
    // Countable units that get pluralized
    return switch (unitShortForm.toLowerCase()) {
      'pill' => 'pills',
      'capsule' => 'capsules',
      'drop' => 'drops',
      'ampoule' => 'ampoules',
      'injection' => 'injections',
      'portion' => 'portions',
      'sachet' => 'sachets',
      // Non-countable units don't change
      'mcg' || 'mg' || 'ml' || 'tbsp' || 'tsp' => unitShortForm,
      // Default: assume it's already plural or doesn't need pluralization
      _ => unitShortForm,
    };
  }
}
