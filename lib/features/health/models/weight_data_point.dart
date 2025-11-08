import 'package:flutter/foundation.dart';

import 'package:hydracat/core/utils/weight_utils.dart';

/// Data point for weight graph visualization
///
/// Represents a single point on the weight trend line graph.
/// Can represent either a single weight entry or a monthly average.
@immutable
class WeightDataPoint {
  /// Creates a [WeightDataPoint]
  const WeightDataPoint({
    required this.date,
    required this.weightKg,
    this.isAverage = false,
  });

  /// Date of this weight measurement
  final DateTime date;

  /// Weight value in kilograms
  final double weightKg;

  /// Whether this is an average value (from monthly summary)
  /// or a single entry (from healthParameters)
  final bool isAverage;

  /// Weight in pounds (for display)
  double get weightLbs => WeightUtils.convertKgToLbs(weightKg);

  @override
  String toString() =>
      'WeightDataPoint(date: $date, kg: $weightKg, avg: $isAverage)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeightDataPoint &&
          other.date == date &&
          other.weightKg == weightKg &&
          other.isAverage == isAverage;

  @override
  int get hashCode => Object.hash(date, weightKg, isAverage);
}
