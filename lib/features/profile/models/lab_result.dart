import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hydracat/features/profile/models/lab_measurement.dart';
import 'package:hydracat/features/profile/models/medical_info.dart';
import 'package:uuid/uuid.dart';

/// Sentinel value for copyWith methods to distinguish between
/// "not provided" and "explicitly set to null"
const _undefined = Object();

/// Metadata for a lab result
@immutable
class LabResultMetadata {
  /// Creates a [LabResultMetadata] instance
  const LabResultMetadata({
    this.panelType,
    this.enteredBy,
    this.source,
    this.irisStage,
    this.vetNotes,
  });

  /// Creates a [LabResultMetadata] from JSON data
  factory LabResultMetadata.fromJson(Map<String, dynamic> json) {
    return LabResultMetadata(
      panelType: json['panelType'] as String?,
      enteredBy: json['enteredBy'] as String?,
      source: json['source'] as String?,
      irisStage: json['irisStage'] != null
          ? IrisStage.fromString(json['irisStage'] as String)
          : null,
      vetNotes: json['vetNotes'] as String?,
    );
  }

  /// Type of lab panel (e.g., "fullPanel", "miniPanel", "seniorPanel")
  final String? panelType;

  /// User ID or device ID who entered the data
  final String? enteredBy;

  /// Source of the data (e.g., "manual", "import", "vetUpload")
  final String? source;

  /// IRIS stage if provided with the panel
  final IrisStage? irisStage;

  /// Free-form vet comments/notes
  final String? vetNotes;

  /// Converts [LabResultMetadata] to JSON data
  Map<String, dynamic> toJson() {
    return {
      if (panelType != null) 'panelType': panelType,
      if (enteredBy != null) 'enteredBy': enteredBy,
      if (source != null) 'source': source,
      if (irisStage != null) 'irisStage': irisStage!.name,
      if (vetNotes != null) 'vetNotes': vetNotes,
    };
  }

  /// Creates a copy of this [LabResultMetadata] with the given fields replaced
  LabResultMetadata copyWith({
    Object? panelType = _undefined,
    Object? enteredBy = _undefined,
    Object? source = _undefined,
    Object? irisStage = _undefined,
    Object? vetNotes = _undefined,
  }) {
    return LabResultMetadata(
      panelType:
          panelType == _undefined ? this.panelType : panelType as String?,
      enteredBy:
          enteredBy == _undefined ? this.enteredBy : enteredBy as String?,
      source: source == _undefined ? this.source : source as String?,
      irisStage:
          irisStage == _undefined ? this.irisStage : irisStage as IrisStage?,
      vetNotes: vetNotes == _undefined ? this.vetNotes : vetNotes as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LabResultMetadata &&
        other.panelType == panelType &&
        other.enteredBy == enteredBy &&
        other.source == source &&
        other.irisStage == irisStage &&
        other.vetNotes == vetNotes;
  }

  @override
  int get hashCode {
    return Object.hash(
      panelType,
      enteredBy,
      source,
      irisStage,
      vetNotes,
    );
  }

  @override
  String toString() {
    return 'LabResultMetadata('
        'panelType: $panelType, '
        'enteredBy: $enteredBy, '
        'source: $source, '
        'irisStage: $irisStage, '
        'vetNotes: $vetNotes'
        ')';
  }
}

/// Blood pressure measurement
@immutable
class BloodPressure {
  /// Creates a [BloodPressure] instance
  const BloodPressure({
    required this.systolic,
    required this.diastolic,
  });

  /// Creates a [BloodPressure] from JSON data
  factory BloodPressure.fromJson(Map<String, dynamic> json) {
    return BloodPressure(
      systolic: (json['systolic'] as num).toDouble(),
      diastolic: (json['diastolic'] as num).toDouble(),
    );
  }

  /// Systolic pressure (mmHg)
  final double systolic;

  /// Diastolic pressure (mmHg)
  final double diastolic;

  /// Validates blood pressure values
  List<String> validate() {
    final errors = <String>[];

    if (systolic < 0) {
      errors.add('Systolic pressure must be non-negative');
    }
    if (diastolic < 0) {
      errors.add('Diastolic pressure must be non-negative');
    }
    if (systolic < diastolic) {
      errors.add('Systolic pressure should be higher than diastolic');
    }

    return errors;
  }

  /// Converts [BloodPressure] to JSON data
  Map<String, dynamic> toJson() {
    return {
      'systolic': systolic,
      'diastolic': diastolic,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is BloodPressure &&
        other.systolic == systolic &&
        other.diastolic == diastolic;
  }

  @override
  int get hashCode => Object.hash(systolic, diastolic);

  @override
  String toString() {
    return 'BloodPressure(systolic: $systolic, diastolic: $diastolic)';
  }
}

/// Urine specific gravity measurement
@immutable
class UrineSpecificGravity {
  /// Creates a [UrineSpecificGravity] instance
  const UrineSpecificGravity({
    required this.value,
    this.unit,
  });

  /// Creates a [UrineSpecificGravity] from JSON data
  factory UrineSpecificGravity.fromJson(Map<String, dynamic> json) {
    return UrineSpecificGravity(
      value: (json['value'] as num).toDouble(),
      unit: json['unit'] as String?,
    );
  }

  /// The USG value (e.g., 1.030)
  final double value;

  /// Optional unit (typically dimensionless or "g/mL")
  final String? unit;

  /// Converts [UrineSpecificGravity] to JSON data
  Map<String, dynamic> toJson() {
    return {
      'value': value,
      if (unit != null) 'unit': unit,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UrineSpecificGravity &&
        other.value == value &&
        other.unit == unit;
  }

  @override
  int get hashCode => Object.hash(value, unit);

  @override
  String toString() {
    return 'UrineSpecificGravity(value: $value, unit: $unit)';
  }
}

/// Complete lab result from bloodwork
///
/// Stores multiple analytes in a flexible map structure with optional
/// metadata, blood pressure, and urine specific gravity. Designed for
/// append-only storage in Firestore with immutable key fields.
///
/// Canonical analyte keys include:
/// - creatinine: Primary kidney function marker
/// - bun: Blood urea nitrogen
/// - sdma: Symmetric dimethylarginine
/// - phosphorus: Phosphate levels
/// - potassium, calcium, etc. (extensible)
@immutable
class LabResult {
  /// Creates a [LabResult] instance
  const LabResult({
    required this.id,
    required this.petId,
    required this.testDate,
    required this.values,
    required this.createdAt,
    this.metadata,
    this.bloodPressure,
    this.urineSpecificGravity,
    this.updatedAt,
  });

  /// Factory constructor to create a new lab result
  ///
  /// Generates a UUID for the result ID and sets createdAt to current time.
  /// Use this when creating a new lab result from user input.
  factory LabResult.create({
    required String petId,
    required DateTime testDate,
    required Map<String, LabMeasurement> values,
    LabResultMetadata? metadata,
    BloodPressure? bloodPressure,
    UrineSpecificGravity? urineSpecificGravity,
  }) {
    const uuid = Uuid();
    return LabResult(
      id: uuid.v4(),
      petId: petId,
      testDate: testDate,
      values: values,
      metadata: metadata,
      bloodPressure: bloodPressure,
      urineSpecificGravity: urineSpecificGravity,
      createdAt: DateTime.now(),
    );
  }

  /// Creates a [LabResult] from JSON data
  ///
  /// Handles Firestore Timestamp conversion for DateTime fields and
  /// parses the values map into LabMeasurement objects.
  factory LabResult.fromJson(Map<String, dynamic> json) {
    // Parse values map
    final valuesJson = json['values'] as Map<String, dynamic>? ?? {};
    final values = <String, LabMeasurement>{};
    for (final entry in valuesJson.entries) {
      values[entry.key] =
          LabMeasurement.fromJson(entry.value as Map<String, dynamic>);
    }

    return LabResult(
      id: json['id'] as String,
      petId: json['petId'] as String,
      testDate: _parseDateTime(json['testDate']),
      values: values,
      metadata: json['metadata'] != null
          ? LabResultMetadata.fromJson(
              json['metadata'] as Map<String, dynamic>,
            )
          : null,
      bloodPressure: json['bloodPressure'] != null
          ? BloodPressure.fromJson(
              json['bloodPressure'] as Map<String, dynamic>,
            )
          : null,
      urineSpecificGravity: json['urineSpecificGravity'] != null
          ? UrineSpecificGravity.fromJson(
              json['urineSpecificGravity'] as Map<String, dynamic>,
            )
          : null,
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: json['updatedAt'] != null
          ? _parseDateTime(json['updatedAt'])
          : null,
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

  /// Unique identifier for the lab result (UUID)
  final String id;

  /// ID of the pet this lab result belongs to
  final String petId;

  /// Date when the bloodwork was performed (IMMUTABLE after creation)
  final DateTime testDate;

  /// Map of analyte measurements
  ///
  /// Keys are canonical analyte names (e.g., "creatinine", "bun", "sdma").
  /// Values are LabMeasurement objects with value, unit, and optional
  /// conversions.
  final Map<String, LabMeasurement> values;

  /// Optional metadata for context
  final LabResultMetadata? metadata;

  /// Optional blood pressure reading
  final BloodPressure? bloodPressure;

  /// Optional urine specific gravity measurement
  final UrineSpecificGravity? urineSpecificGravity;

  /// When this record was created (IMMUTABLE)
  final DateTime createdAt;

  /// Last modification time
  final DateTime? updatedAt;

  // Convenience getters for common analytes

  /// Creatinine measurement if present
  LabMeasurement? get creatinine => values['creatinine'];

  /// BUN measurement if present
  LabMeasurement? get bun => values['bun'];

  /// SDMA measurement if present
  LabMeasurement? get sdma => values['sdma'];

  /// Phosphorus measurement if present
  LabMeasurement? get phosphorus => values['phosphorus'];

  /// Whether this lab result has any analyte values
  bool get hasValues => values.isNotEmpty;

  /// Whether this lab result has been modified after creation
  bool get wasModified => updatedAt != null && updatedAt!.isAfter(createdAt);

  /// Validates the lab result data
  ///
  /// Returns a list of validation error messages. Empty list means valid.
  List<String> validate() {
    final errors = <String>[];

    // Required fields
    if (id.isEmpty) {
      errors.add('Lab result ID is required');
    }
    if (petId.isEmpty) {
      errors.add('Pet ID is required');
    }

    // Must have at least one analyte
    if (values.isEmpty) {
      errors.add('At least one analyte measurement is required');
    }

    // Test date validation (cannot be in future)
    if (testDate.isAfter(DateTime.now())) {
      errors.add('Test date cannot be in the future');
    }

    // Validate all measurements
    for (final entry in values.entries) {
      final measurementErrors = entry.value.validate();
      if (measurementErrors.isNotEmpty) {
        errors.add('${entry.key}: ${measurementErrors.join(", ")}');
      }
    }

    // Validate blood pressure if present
    if (bloodPressure != null) {
      errors.addAll(bloodPressure!.validate());
    }

    return errors;
  }

  /// Whether this lab result has valid data
  bool get isValid => validate().isEmpty;

  /// Converts [LabResult] to JSON for Firestore
  Map<String, dynamic> toJson() {
    // Convert values map to JSON
    final valuesJson = <String, dynamic>{};
    for (final entry in values.entries) {
      valuesJson[entry.key] = entry.value.toJson();
    }

    return {
      'id': id,
      'petId': petId,
      'testDate': Timestamp.fromDate(testDate),
      'values': valuesJson,
      if (metadata != null) 'metadata': metadata!.toJson(),
      if (bloodPressure != null) 'bloodPressure': bloodPressure!.toJson(),
      if (urineSpecificGravity != null)
        'urineSpecificGravity': urineSpecificGravity!.toJson(),
      'createdAt': Timestamp.fromDate(createdAt),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }

  /// Creates a copy of this [LabResult] with the given fields replaced
  LabResult copyWith({
    String? id,
    String? petId,
    DateTime? testDate,
    Map<String, LabMeasurement>? values,
    Object? metadata = _undefined,
    Object? bloodPressure = _undefined,
    Object? urineSpecificGravity = _undefined,
    DateTime? createdAt,
    Object? updatedAt = _undefined,
  }) {
    return LabResult(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      testDate: testDate ?? this.testDate,
      values: values ?? this.values,
      metadata: metadata == _undefined
          ? this.metadata
          : metadata as LabResultMetadata?,
      bloodPressure: bloodPressure == _undefined
          ? this.bloodPressure
          : bloodPressure as BloodPressure?,
      urineSpecificGravity: urineSpecificGravity == _undefined
          ? this.urineSpecificGravity
          : urineSpecificGravity as UrineSpecificGravity?,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt == _undefined
          ? this.updatedAt
          : updatedAt as DateTime?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LabResult &&
        other.id == id &&
        other.petId == petId &&
        other.testDate == testDate &&
        mapEquals(other.values, values) &&
        other.metadata == metadata &&
        other.bloodPressure == bloodPressure &&
        other.urineSpecificGravity == urineSpecificGravity &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      petId,
      testDate,
      Object.hashAll(values.entries.map((e) => Object.hash(e.key, e.value))),
      metadata,
      bloodPressure,
      urineSpecificGravity,
      createdAt,
      updatedAt,
    );
  }

  @override
  String toString() {
    return 'LabResult('
        'id: $id, '
        'petId: $petId, '
        'testDate: $testDate, '
        'values: $values, '
        'metadata: $metadata, '
        'bloodPressure: $bloodPressure, '
        'urineSpecificGravity: $urineSpecificGravity, '
        'createdAt: $createdAt, '
        'updatedAt: $updatedAt'
        ')';
  }
}
