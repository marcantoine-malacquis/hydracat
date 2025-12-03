import 'package:flutter/foundation.dart';

/// Sentinel value for copyWith methods to distinguish between
/// "not provided" and "explicitly set to null"
const _undefined = Object();

/// A single analyte measurement with unit information
///
/// Supports flexible unit storage with optional canonical conversions
/// for SI and US unit systems. Used within lab results to store individual
/// analyte values like creatinine, BUN, SDMA, etc.
@immutable
class LabMeasurement {
  /// Creates a [LabMeasurement] instance
  const LabMeasurement({
    required this.value,
    required this.unit,
    this.valueSi,
    this.valueUs,
  });

  /// Creates a [LabMeasurement] from JSON data
  factory LabMeasurement.fromJson(Map<String, dynamic> json) {
    return LabMeasurement(
      value: (json['value'] as num).toDouble(),
      unit: json['unit'] as String,
      valueSi: json['valueSi'] != null
          ? (json['valueSi'] as num).toDouble()
          : null,
      valueUs: json['valueUs'] != null
          ? (json['valueUs'] as num).toDouble()
          : null,
    );
  }

  /// The measured value as entered by the user
  final double value;

  /// The unit as entered by the user (e.g., "mg/dL", "µmol/L", "µg/dL")
  final String unit;

  /// Optional canonical SI unit conversion (e.g., µmol/L for creatinine)
  final double? valueSi;

  /// Optional canonical US unit conversion (e.g., mg/dL for creatinine)
  final double? valueUs;

  /// Validates the measurement
  ///
  /// Returns a list of validation error messages. Empty list means valid.
  List<String> validate() {
    final errors = <String>[];

    if (value < 0) {
      errors.add('Measurement value must be non-negative');
    }

    if (unit.isEmpty) {
      errors.add('Unit is required');
    }

    if (valueSi != null && valueSi! < 0) {
      errors.add('SI value must be non-negative');
    }

    if (valueUs != null && valueUs! < 0) {
      errors.add('US value must be non-negative');
    }

    return errors;
  }

  /// Whether this measurement has valid data
  bool get isValid => validate().isEmpty;

  /// Converts [LabMeasurement] to JSON data
  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'unit': unit,
      if (valueSi != null) 'valueSi': valueSi,
      if (valueUs != null) 'valueUs': valueUs,
    };
  }

  /// Creates a copy of this [LabMeasurement] with the given fields replaced
  LabMeasurement copyWith({
    double? value,
    String? unit,
    Object? valueSi = _undefined,
    Object? valueUs = _undefined,
  }) {
    return LabMeasurement(
      value: value ?? this.value,
      unit: unit ?? this.unit,
      valueSi: valueSi == _undefined ? this.valueSi : valueSi as double?,
      valueUs: valueUs == _undefined ? this.valueUs : valueUs as double?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LabMeasurement &&
        other.value == value &&
        other.unit == unit &&
        other.valueSi == valueSi &&
        other.valueUs == valueUs;
  }

  @override
  int get hashCode {
    return Object.hash(
      value,
      unit,
      valueSi,
      valueUs,
    );
  }

  @override
  String toString() {
    return 'LabMeasurement('
        'value: $value, '
        'unit: $unit, '
        'valueSi: $valueSi, '
        'valueUs: $valueUs'
        ')';
  }
}
