/// Utility class for weight conversions and formatting.
///
/// Provides centralized weight conversion between kg and lbs,
/// as well as formatting utilities for consistent display across the app.
class WeightUtils {
  /// Conversion factor from kilograms to pounds
  static const double kKgToLbsConversionFactor = 2.20462;

  /// Converts weight from kilograms to pounds
  ///
  /// Example:
  /// ```dart
  /// final lbs = WeightUtils.convertKgToLbs(4.5); // 9.92 lbs
  /// ```
  static double convertKgToLbs(double kg) {
    return kg * kKgToLbsConversionFactor;
  }

  /// Converts weight from pounds to kilograms
  ///
  /// Example:
  /// ```dart
  /// final kg = WeightUtils.convertLbsToKg(10.0); // 4.54 kg
  /// ```
  static double convertLbsToKg(double lbs) {
    return lbs / kKgToLbsConversionFactor;
  }

  /// Formats weight with proper unit conversion and decimal places
  ///
  /// - [weightKg]: Weight value in kilograms (can be null)
  /// - [unit]: Target unit ('kg' or 'lbs')
  /// - [decimals]: Number of decimal places (default: 2)
  ///
  /// Returns 'Unknown' if weightKg is null.
  ///
  /// Example:
  /// ```dart
  /// final formatted = WeightUtils.formatWeight(4.5, 'lbs'); // "9.92 lbs"
  /// final formatted2 = WeightUtils.formatWeight(4.5, 'kg'); // "4.50 kg"
  /// final unknown = WeightUtils.formatWeight(null, 'kg'); // "Unknown"
  /// ```
  static String formatWeight(
    double? weightKg,
    String unit, {
    int decimals = 2,
  }) {
    if (weightKg == null) {
      return 'Unknown';
    }

    if (unit == 'lbs') {
      final weightLbs = convertKgToLbs(weightKg);
      return '${weightLbs.toStringAsFixed(decimals)} lbs';
    } else {
      return '${weightKg.toStringAsFixed(decimals)} kg';
    }
  }
}
