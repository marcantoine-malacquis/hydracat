import 'package:flutter/services.dart';

/// Utility class for decimal number input handling
///
/// This utility provides a simple, reliable approach to handling decimal input
/// that accepts both comma and period as decimal separators.
/// It normalizes input by converting commas to periods for consistent parsing.
class NumberInputUtils {
  NumberInputUtils._();

  /// Returns input formatters for decimal number input
  ///
  /// Allows digits, commas, and periods to support various input methods.
  /// The parsing logic will normalize commas to periods.
  static List<TextInputFormatter> getDecimalFormatters() {
    return [
      FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
    ];
  }

  /// Parses a decimal number string with comma/period normalization
  ///
  /// Returns null if the string cannot be parsed or is empty.
  /// Converts commas to periods before parsing to handle international input.
  ///
  /// Examples:
  /// - "3,14" -> 3.14
  /// - "3.14" -> 3.14
  /// - "" -> null
  /// - "abc" -> null
  static double? parseDecimal(String value) {
    if (value.isEmpty) return null;

    // Normalize comma to period for consistent parsing
    final normalizedValue = value.replaceAll(',', '.');
    return double.tryParse(normalizedValue);
  }

  /// Formats a decimal number for input display
  ///
  /// Returns an empty string if the value is null.
  /// Uses standard decimal notation with periods.
  static String formatForInput(double? value) {
    if (value == null) return '';

    // Only show decimal places if they're not zero
    if (value == value.truncate()) {
      return value.truncate().toString();
    } else {
      return value.toString();
    }
  }

  /// Formats a decimal number with a specific number of decimal places
  ///
  /// Useful for displaying values like weight with consistent precision.
  static String formatWithPrecision(
    double? value, {
    int decimalPlaces = 2,
  }) {
    if (value == null) return '';

    return value.toStringAsFixed(decimalPlaces);
  }
}
