/// Utility class for converting numeric dosages to natural language text.
///
/// Provides user-friendly display of medication dosages, converting values
/// like 0.5 to "half a pill" instead of "0.5 pills".
class DosageTextUtils {
  /// Private constructor to prevent instantiation
  const DosageTextUtils._();

  /// Formats a dosage value with its unit in natural language.
  ///
  /// Converts numeric dosages to user-friendly text:
  /// - 0.5 + "pill" → "half a pill"
  /// - 1.5 + "pill" → "one and a half pills"
  /// - 0.25 + "capsule" → "quarter of a capsule"
  /// - 2 + "pill" → "2 pills"
  ///
  /// Example:
  /// ```dart
  /// DosageTextUtils.formatDosageWithUnit(0.5, "pill");
  /// // Returns: "half a pill"
  ///
  /// DosageTextUtils.formatDosageWithUnit(1.5, "pill");
  /// // Returns: "one and a half pills"
  /// ```
  static String formatDosageWithUnit(double dosage, String unitShortForm) {
    // 1. Try common fractions (0.25, 0.33, 0.5, 0.67, 0.75)
    final fractionText = _tryGetFractionText(dosage, unitShortForm);
    if (fractionText != null) return fractionText;

    // 2. Try mixed numbers (1.5, 2.25, 1.33, etc.)
    final mixedText = _tryGetMixedNumberText(dosage, unitShortForm);
    if (mixedText != null) return mixedText;

    // 3. Handle whole numbers (1, 2, 3, etc.)
    if (dosage == dosage.roundToDouble()) {
      return _getWholeNumberText(dosage.round(), unitShortForm);
    }

    // 4. Fallback to numeric format for uncommon decimals
    final formatted = dosage
        .toStringAsFixed(2)
        .replaceAll(
          // The library directive may trigger deprecated_member_use warnings
          // in some Dart versions.
          // ignore: deprecated_member_use
          RegExp(r'\.?0*$'),
          '',
        );
    return '$formatted ${_getPluralUnit(unitShortForm)}';
  }

  /// Tries to convert simple fractions to text (0.25, 0.33, 0.5, 0.67, 0.75)
  static String? _tryGetFractionText(double dosage, String unitShortForm) {
    const tolerance = 0.02; // Tolerance for floating-point comparison

    // Common fractions under 1
    if ((dosage - 0.25).abs() < tolerance) {
      return 'quarter of a ${_getSingularUnit(unitShortForm)}';
    }
    if ((dosage - 0.33).abs() < tolerance) {
      return 'third of a ${_getSingularUnit(unitShortForm)}';
    }
    if ((dosage - 0.5).abs() < tolerance) {
      return 'half a ${_getSingularUnit(unitShortForm)}';
    }
    if ((dosage - 0.67).abs() < tolerance) {
      return 'two thirds of a ${_getSingularUnit(unitShortForm)}';
    }
    if ((dosage - 0.75).abs() < tolerance) {
      return 'three quarters of a ${_getSingularUnit(unitShortForm)}';
    }

    return null;
  }

  /// Tries to convert mixed numbers to text (1.5, 2.25, 1.33, etc.)
  static String? _tryGetMixedNumberText(double dosage, String unitShortForm) {
    if (dosage < 1) return null;

    const tolerance = 0.02;
    final wholePart = dosage.floor();
    final fractionalPart = dosage - wholePart;

    String? fractionWord;

    // Check common fractions
    if ((fractionalPart - 0.25).abs() < tolerance) {
      fractionWord = 'quarter';
    } else if ((fractionalPart - 0.33).abs() < tolerance) {
      fractionWord = 'third';
    } else if ((fractionalPart - 0.5).abs() < tolerance) {
      fractionWord = 'half';
    } else if ((fractionalPart - 0.67).abs() < tolerance) {
      fractionWord = 'two thirds';
    } else if ((fractionalPart - 0.75).abs() < tolerance) {
      fractionWord = 'three quarters';
    }

    if (fractionWord != null) {
      final wholeWord = _getWholeNumberWord(wholePart);
      return '$wholeWord and a $fractionWord ${_getPluralUnit(unitShortForm)}';
    }

    return null;
  }

  /// Formats whole numbers with proper singular/plural unit
  static String _getWholeNumberText(int count, String unitShortForm) {
    if (count == 1) {
      return '1 ${_getSingularUnit(unitShortForm)}';
    } else {
      return '$count ${_getPluralUnit(unitShortForm)}';
    }
  }

  /// Converts whole numbers to words for mixed numbers (1 → "one", 2 → "two")
  static String _getWholeNumberWord(int number) {
    return switch (number) {
      1 => 'one',
      2 => 'two',
      3 => 'three',
      4 => 'four',
      5 => 'five',
      6 => 'six',
      7 => 'seven',
      8 => 'eight',
      9 => 'nine',
      10 => 'ten',
      _ => number.toString(), // Fallback to numeric for 11+
    };
  }

  /// Returns the singular form of a unit (handles special cases)
  static String _getSingularUnit(String unitShortForm) {
    // Most units are already singular in shortForm
    return unitShortForm;
  }

  /// Returns the plural form of a unit
  static String _getPluralUnit(String unitShortForm) {
    // Countable units that get pluralized
    return switch (unitShortForm) {
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
