import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Sentinel value for copyWith methods to distinguish between
/// "not provided" and "explicitly set to null"
const _undefined = Object();

/// Denormalized snapshot of the most recent lab result
///
/// Stored in `medicalInfo.latestLabResult` on the pet document for
/// instant UI access without querying the labResults subcollection.
/// Contains canonical values in a consistent unit system for quick display.
@immutable
class LatestLabSummary {
  /// Creates a [LatestLabSummary] instance
  const LatestLabSummary({
    required this.testDate,
    required this.labResultId,
    this.creatinine,
    this.bun,
    this.sdma,
    this.phosphorus,
    this.preferredUnitSystem,
  });

  /// Creates a [LatestLabSummary] from JSON data
  factory LatestLabSummary.fromJson(Map<String, dynamic> json) {
    return LatestLabSummary(
      testDate: _parseDateTime(json['testDate']),
      labResultId: json['labResultId'] as String,
      creatinine: json['creatinine'] != null
          ? (json['creatinine'] as num).toDouble()
          : null,
      bun: json['bun'] != null ? (json['bun'] as num).toDouble() : null,
      sdma: json['sdma'] != null ? (json['sdma'] as num).toDouble() : null,
      phosphorus: json['phosphorus'] != null
          ? (json['phosphorus'] as num).toDouble()
          : null,
      preferredUnitSystem: json['preferredUnitSystem'] as String?,
    );
  }

  /// Helper method to parse DateTime from various formats
  ///
  /// Handles both Firestore Timestamp objects and ISO 8601 strings.
  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      return DateTime.parse(value);
    } else if (value is DateTime) {
      return value;
    } else {
      throw ArgumentError(
        'Invalid DateTime format: expected Timestamp, String, or DateTime, '
        'got ${value.runtimeType}',
      );
    }
  }

  /// Date of the most recent bloodwork
  final DateTime testDate;

  /// Reference to the source document in labResults subcollection
  final String labResultId;

  /// Creatinine value in canonical unit (mg/dL for US)
  final double? creatinine;

  /// BUN value in canonical unit (mg/dL for US)
  final double? bun;

  /// SDMA value in canonical unit (µg/dL)
  final double? sdma;

  /// Phosphorus value in canonical unit (mg/dL for US)
  final double? phosphorus;

  /// Preferred unit system for display ("us" or "si")
  final String? preferredUnitSystem;

  /// Whether any lab values are present
  bool get hasValues =>
      creatinine != null || bun != null || sdma != null || phosphorus != null;

  /// Validates the summary
  ///
  /// Returns a list of validation error messages. Empty list means valid.
  List<String> validate() {
    final errors = <String>[];

    if (labResultId.isEmpty) {
      errors.add('Lab result ID reference is required');
    }

    if (testDate.isAfter(DateTime.now())) {
      errors.add('Test date cannot be in the future');
    }

    // Validate value ranges if present
    if (creatinine != null && creatinine! < 0) {
      errors.add('Creatinine must be non-negative');
    }
    if (bun != null && bun! < 0) {
      errors.add('BUN must be non-negative');
    }
    if (sdma != null && sdma! < 0) {
      errors.add('SDMA must be non-negative');
    }
    if (phosphorus != null && phosphorus! < 0) {
      errors.add('Phosphorus must be non-negative');
    }

    // Validate unit system if provided
    if (preferredUnitSystem != null &&
        !['us', 'si'].contains(preferredUnitSystem)) {
      errors.add('Preferred unit system must be "us" or "si"');
    }

    return errors;
  }

  /// Whether this summary has valid data
  bool get isValid => validate().isEmpty;

  /// Converts [LatestLabSummary] to JSON data
  Map<String, dynamic> toJson() {
    return {
      'testDate': Timestamp.fromDate(testDate),
      'labResultId': labResultId,
      if (creatinine != null) 'creatinine': creatinine,
      if (bun != null) 'bun': bun,
      if (sdma != null) 'sdma': sdma,
      if (phosphorus != null) 'phosphorus': phosphorus,
      if (preferredUnitSystem != null)
        'preferredUnitSystem': preferredUnitSystem,
    };
  }

  /// Creates a copy of this [LatestLabSummary] with the given fields replaced
  LatestLabSummary copyWith({
    DateTime? testDate,
    String? labResultId,
    Object? creatinine = _undefined,
    Object? bun = _undefined,
    Object? sdma = _undefined,
    Object? phosphorus = _undefined,
    Object? preferredUnitSystem = _undefined,
  }) {
    return LatestLabSummary(
      testDate: testDate ?? this.testDate,
      labResultId: labResultId ?? this.labResultId,
      creatinine:
          creatinine == _undefined ? this.creatinine : creatinine as double?,
      bun: bun == _undefined ? this.bun : bun as double?,
      sdma: sdma == _undefined ? this.sdma : sdma as double?,
      phosphorus:
          phosphorus == _undefined ? this.phosphorus : phosphorus as double?,
      preferredUnitSystem: preferredUnitSystem == _undefined
          ? this.preferredUnitSystem
          : preferredUnitSystem as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LatestLabSummary &&
        other.testDate == testDate &&
        other.labResultId == labResultId &&
        other.creatinine == creatinine &&
        other.bun == bun &&
        other.sdma == sdma &&
        other.phosphorus == phosphorus &&
        other.preferredUnitSystem == preferredUnitSystem;
  }

  @override
  int get hashCode {
    return Object.hash(
      testDate,
      labResultId,
      creatinine,
      bun,
      sdma,
      phosphorus,
      preferredUnitSystem,
    );
  }

  @override
  String toString() {
    return 'LatestLabSummary('
        'testDate: $testDate, '
        'labResultId: $labResultId, '
        'creatinine: $creatinine, '
        'bun: $bun, '
        'sdma: $sdma, '
        'phosphorus: $phosphorus, '
        'preferredUnitSystem: $preferredUnitSystem'
        ')';
  }
}
