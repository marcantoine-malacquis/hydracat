import 'package:flutter/material.dart';

/// Utility methods for chart configuration
class ChartUtils {
  // Private constructor to prevent instantiation
  ChartUtils._();

  /// Calculates optimal reserved size for Y-axis labels
  ///
  /// Measures the widest label text and adds padding for proper spacing.
  /// Falls back to [fallbackSize] if measurement fails.
  ///
  /// Parameters:
  /// - [labels]: List of label strings to measure
  ///   (e.g., ["5.10", "10.20"])
  /// - [textStyle]: Text style used for labels
  ///   (typically AppTextStyles.caption)
  /// - [rightPadding]: Padding between label and chart area
  ///   (default: 8px)
  /// - [fallbackSize]: Fallback if measurement fails (default: 40px)
  ///
  /// Returns the calculated reserved size, clamped between 20px and 60px
  static double calculateYAxisReservedSize({
    required List<String> labels,
    required TextStyle textStyle,
    double rightPadding = 8,
    double fallbackSize = 40,
  }) {
    if (labels.isEmpty) return fallbackSize;

    try {
      var maxWidth = 0.0;

      for (final label in labels) {
        final textPainter = TextPainter(
          text: TextSpan(text: label, style: textStyle),
          textDirection: TextDirection.ltr,
          maxLines: 1,
        )..layout();

        maxWidth = maxWidth > textPainter.width ? maxWidth : textPainter.width;
      }

      // Add right padding + 4px buffer for safety
      final calculatedSize = maxWidth + rightPadding + 4;

      // Enforce minimum of 20px, maximum of 60px for sanity
      return calculatedSize.clamp(20.0, 60.0);
    } on Exception {
      // Fallback on any error
      return fallbackSize;
    }
  }

  /// Generates Y-axis label strings for preview/measurement
  ///
  /// Used to measure labels before chart renders. Generates labels
  /// based on min/max values and interval.
  ///
  /// Parameters:
  /// - [minY]: Minimum Y-axis value
  /// - [maxY]: Maximum Y-axis value
  /// - [interval]: Interval between labels
  /// - [decimalPlaces]: Number of decimal places to format (default: 2)
  ///
  /// Returns a list of formatted label strings
  static List<String> generateYAxisLabels({
    required double minY,
    required double maxY,
    required double interval,
    int decimalPlaces = 2,
  }) {
    final labels = <String>[];
    var current = minY;

    while (current <= maxY) {
      labels.add(current.toStringAsFixed(decimalPlaces));
      current += interval;
    }

    return labels;
  }
}
