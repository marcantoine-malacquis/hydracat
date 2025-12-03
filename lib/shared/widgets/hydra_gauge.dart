import 'package:flutter/material.dart';
import 'package:hydracat/core/constants/constants.dart';

/// A visual gauge widget for displaying numeric values within a reference
/// range.
///
/// The gauge provides an at-a-glance visualization of whether a value falls
/// within normal reference ranges, similar to veterinary bloodwork reports.
///
/// **Features**:
/// - Color-coded indicator: dark teal for in-range, red for out-of-range
/// - Extends gauge by up to 20% to show moderately out-of-range values
/// - Shows ">>" indicator for extreme outliers beyond the extended range
/// - Subtle threshold markers at min/max reference points
///
/// **Example**:
/// ```dart
/// HydraGauge(
///   value: 4.8,
///   min: 0.6,
///   max: 1.6,
///   unit: 'mg/dL',
/// )
/// ```
///
/// This would display a gauge showing creatinine at 4.8 mg/dL, which is well
/// above the normal range (0.6-1.6), with a red indicator.
class HydraGauge extends StatelessWidget {
  /// Creates a gauge widget.
  ///
  /// The [value] is the measured value to display.
  /// [min] and [max] define the normal reference range.
  /// [unit] is optional and used for accessibility labels.
  /// [height] defaults to 24 pixels.
  /// [width] defaults to available space if not specified.
  const HydraGauge({
    required this.value,
    required this.min,
    required this.max,
    this.unit,
    this.height = 24.0,
    this.width,
    super.key,
  });

  /// The measured value to display on the gauge.
  final double value;

  /// Minimum of the reference range (inclusive).
  final double min;

  /// Maximum of the reference range (inclusive).
  final double max;

  /// Unit of measurement (e.g., "mg/dL", "µg/dL").
  /// Used for accessibility labels.
  final String? unit;

  /// Height of the gauge. Defaults to 24.0 pixels.
  final double height;

  /// Width of the gauge. If null, uses available space.
  final double? width;

  // ==========================================================================
  // Helper Methods
  // ==========================================================================

  /// Checks if the value is within the normal reference range.
  bool _isValueInRange() {
    return value >= min && value <= max;
  }

  /// Returns the indicator color based on whether value is in range.
  Color _getIndicatorColor() {
    return _isValueInRange() ? AppColors.primaryDark : AppColors.error;
  }

  /// Calculates the extended minimum (20% below min).
  double _getExtendedMin() {
    final range = max - min;
    return min - (range * 0.2);
  }

  /// Calculates the extended maximum (20% above max).
  double _getExtendedMax() {
    final range = max - min;
    return max + (range * 0.2);
  }

  /// Checks if the value is an extreme outlier beyond the extended range.
  bool _shouldShowOutlierIndicator() {
    return value > _getExtendedMax() || value < _getExtendedMin();
  }

  /// Calculates the indicator position as a fraction (0.0 to 1.0) of gauge
  /// width.
  ///
  /// Returns a value between 0.0 (far left) and 1.0 (far right).
  /// Values beyond the extended range are capped at the edges.
  double _calculateIndicatorPosition() {
    final extendedMin = _getExtendedMin();
    final extendedMax = _getExtendedMax();
    final extendedRange = extendedMax - extendedMin;

    if (extendedRange == 0) {
      return 0.5; // Center if no range
    }

    // Clamp value to extended range
    final clampedValue = value.clamp(extendedMin, extendedMax);

    // Calculate position as fraction of extended range
    final position = (clampedValue - extendedMin) / extendedRange;

    return position.clamp(0.0, 1.0);
  }

  /// Calculates the position of the min threshold marker (0.0 to 1.0).
  double _getMinThresholdPosition() {
    final extendedMin = _getExtendedMin();
    final extendedMax = _getExtendedMax();
    final extendedRange = extendedMax - extendedMin;

    if (extendedRange == 0) {
      return 0.25;
    }

    return (min - extendedMin) / extendedRange;
  }

  /// Calculates the position of the max threshold marker (0.0 to 1.0).
  double _getMaxThresholdPosition() {
    final extendedMin = _getExtendedMin();
    final extendedMax = _getExtendedMax();
    final extendedRange = extendedMax - extendedMin;

    if (extendedRange == 0) {
      return 0.75;
    }

    return (max - extendedMin) / extendedRange;
  }

  /// Builds the accessibility label for the gauge.
  String _buildSemanticLabel() {
    final unitLabel = unit ?? '';
    final rangeStatus = _isValueInRange()
        ? 'within normal range'
        : 'outside normal range';
    return 'Value: $value $unitLabel, $rangeStatus. '
        'Reference range: $min to $max $unitLabel.';
  }

  @override
  Widget build(BuildContext context) {
    final indicatorColor = _getIndicatorColor();
    final showOutlier = _shouldShowOutlierIndicator();

    return Semantics(
      label: _buildSemanticLabel(),
      readOnly: true,
      child: SizedBox(
        height: height,
        width: width,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final gaugeWidth = width ?? constraints.maxWidth;
            final indicatorPosition = _calculateIndicatorPosition();
            final minThresholdPosition = _getMinThresholdPosition();
            final maxThresholdPosition = _getMaxThresholdPosition();

            return Stack(
              alignment: Alignment.centerLeft,
              children: [
                // Background bar
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),

                // Min threshold marker
                Positioned(
                  left: minThresholdPosition * gaugeWidth,
                  child: Container(
                    width: 1,
                    height: height,
                    color: AppColors.primaryDark.withValues(alpha: 0.4),
                  ),
                ),

                // Max threshold marker
                Positioned(
                  left: maxThresholdPosition * gaugeWidth,
                  child: Container(
                    width: 1,
                    height: height,
                    color: AppColors.primaryDark.withValues(alpha: 0.4),
                  ),
                ),

                // Value indicator (vertical bar)
                Positioned(
                  // Center the 3px bar
                  left: (indicatorPosition * gaugeWidth) - 1.5,
                  child: Container(
                    width: 3,
                    height: height,
                    decoration: BoxDecoration(
                      color: indicatorColor,
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  ),
                ),

                // Outlier indicator (">>" or "<<")
                if (showOutlier)
                  Positioned(
                    left: value > _getExtendedMax()
                        ? gaugeWidth - 20 // Right side for high values
                        : 4, // Left side for low values
                    child: Text(
                      value > _getExtendedMax() ? '>>' : '<<',
                      style: TextStyle(
                        fontSize: 10,
                        color: indicatorColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
