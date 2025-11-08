import 'package:flutter/foundation.dart';

/// Sentinel value for copyWith methods to distinguish between
/// "not provided" and "explicitly set to null"
const _undefined = Object();

/// Laboratory values for CKD monitoring
@immutable
class LabValues {
  /// Creates a [LabValues] instance
  const LabValues({
    this.bloodworkDate,
    this.creatinineMgDl,
    this.bunMgDl,
    this.sdmaMcgDl,
  });

  /// Creates a [LabValues] from JSON data
  factory LabValues.fromJson(Map<String, dynamic> json) {
    return LabValues(
      bloodworkDate: json['bloodworkDate'] != null
          ? DateTime.parse(json['bloodworkDate'] as String)
          : null,
      creatinineMgDl: json['creatinineMgDl'] != null
          ? (json['creatinineMgDl'] as num).toDouble()
          : null,
      bunMgDl: json['bunMgDl'] != null
          ? (json['bunMgDl'] as num).toDouble()
          : null,
      sdmaMcgDl: json['sdmaMcgDl'] != null
          ? (json['sdmaMcgDl'] as num).toDouble()
          : null,
    );
  }

  /// Date when the bloodwork was performed
  final DateTime? bloodworkDate;

  /// Creatinine level in mg/dL
  final double? creatinineMgDl;

  /// Blood Urea Nitrogen (BUN) level in mg/dL
  final double? bunMgDl;

  /// Symmetric Dimethylarginine (SDMA) level in μg/dL
  final double? sdmaMcgDl;

  /// Whether any lab values are present
  bool get hasValues =>
      creatinineMgDl != null || bunMgDl != null || sdmaMcgDl != null;

  /// Whether bloodwork date is provided with lab values
  bool get hasCompleteData =>
      hasValues && bloodworkDate != null;

  /// Converts [LabValues] to JSON data
  Map<String, dynamic> toJson() {
    return {
      'bloodworkDate': bloodworkDate?.toIso8601String(),
      'creatinineMgDl': creatinineMgDl,
      'bunMgDl': bunMgDl,
      'sdmaMcgDl': sdmaMcgDl,
    };
  }

  /// Creates a copy of this [LabValues] with the given fields replaced
  LabValues copyWith({
    Object? bloodworkDate = _undefined,
    Object? creatinineMgDl = _undefined,
    Object? bunMgDl = _undefined,
    Object? sdmaMcgDl = _undefined,
  }) {
    return LabValues(
      bloodworkDate: bloodworkDate == _undefined 
          ? this.bloodworkDate 
          : bloodworkDate as DateTime?,
      creatinineMgDl: creatinineMgDl == _undefined 
          ? this.creatinineMgDl 
          : creatinineMgDl as double?,
      bunMgDl: bunMgDl == _undefined ? this.bunMgDl : bunMgDl as double?,
      sdmaMcgDl: sdmaMcgDl == _undefined 
          ? this.sdmaMcgDl 
          : sdmaMcgDl as double?,
    );
  }

  /// Validates lab values for consistency
  List<String> validate() {
    final errors = <String>[];

    // Bloodwork date validation
    if (bloodworkDate != null && bloodworkDate!.isAfter(DateTime.now())) {
      errors.add('Bloodwork date cannot be in the future');
    }

    // If any lab values are provided, bloodwork date should be provided
    if (hasValues && bloodworkDate == null) {
      errors.add('Bloodwork date is required when lab values are provided');
    }

    // Validate creatinine range (structural only)
    if (creatinineMgDl != null && creatinineMgDl! <= 0) {
      errors.add('Creatinine must be a positive number');
    }

    // Validate BUN range (structural only)
    if (bunMgDl != null && bunMgDl! <= 0) {
      errors.add('BUN must be a positive number');
    }

    // Validate SDMA range (structural only)
    if (sdmaMcgDl != null && sdmaMcgDl! <= 0) {
      errors.add('SDMA must be a positive number');
    }

    return errors;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LabValues &&
        other.bloodworkDate == bloodworkDate &&
        other.creatinineMgDl == creatinineMgDl &&
        other.bunMgDl == bunMgDl &&
        other.sdmaMcgDl == sdmaMcgDl;
  }

  @override
  int get hashCode {
    return Object.hash(
      bloodworkDate,
      creatinineMgDl,
      bunMgDl,
      sdmaMcgDl,
    );
  }

  @override
  String toString() {
    return 'LabValues('
        'bloodworkDate: $bloodworkDate, '
        'creatinineMgDl: $creatinineMgDl, '
        'bunMgDl: $bunMgDl, '
        'sdmaMcgDl: $sdmaMcgDl'
        ')';
  }
}

/// IRIS (International Renal Interest Society) staging for CKD
enum IrisStage {
  /// Stage 1: Normal kidney function with some kidney damage
  stage1,

  /// Stage 2: Mild decrease in kidney function
  stage2,

  /// Stage 3: Moderate decrease in kidney function
  stage3,

  /// Stage 4: Severe decrease in kidney function
  stage4;

  /// User-friendly display name for the IRIS stage
  String get displayName => switch (this) {
        IrisStage.stage1 => 'IRIS Stage 1',
        IrisStage.stage2 => 'IRIS Stage 2',
        IrisStage.stage3 => 'IRIS Stage 3',
        IrisStage.stage4 => 'IRIS Stage 4',
      };

  /// Detailed description of the IRIS stage
  String get description => switch (this) {
        IrisStage.stage1 => 'Normal kidney function with some kidney damage',
        IrisStage.stage2 => 'Mild decrease in kidney function',
        IrisStage.stage3 => 'Moderate decrease in kidney function',
        IrisStage.stage4 => 'Severe decrease in kidney function',
      };

  /// Numeric value of the stage (1-4)
  int get stageNumber => switch (this) {
        IrisStage.stage1 => 1,
        IrisStage.stage2 => 2,
        IrisStage.stage3 => 3,
        IrisStage.stage4 => 4,
      };

  /// Creates an IrisStage from a string value
  static IrisStage? fromString(String value) {
    return IrisStage.values.where((stage) => stage.name == value).firstOrNull;
  }

  /// Creates an IrisStage from a numeric stage (1-4)
  static IrisStage? fromStageNumber(int stage) {
    return switch (stage) {
      1 => IrisStage.stage1,
      2 => IrisStage.stage2,
      3 => IrisStage.stage3,
      4 => IrisStage.stage4,
      _ => null,
    };
  }
}

/// Medical information specific to CKD management
@immutable
class MedicalInfo {
  /// Creates a [MedicalInfo] instance
  const MedicalInfo({
    this.ckdDiagnosisDate,
    this.irisStage,
    this.lastCheckupDate,
    this.notes,
    this.labValues,
  });

  /// Creates a [MedicalInfo] from JSON data
  factory MedicalInfo.fromJson(Map<String, dynamic> json) {
    return MedicalInfo(
      ckdDiagnosisDate: json['ckdDiagnosisDate'] != null
          ? DateTime.parse(json['ckdDiagnosisDate'] as String)
          : null,
      irisStage: json['irisStage'] != null
          ? IrisStage.fromString(json['irisStage'] as String)
          : null,
      lastCheckupDate: json['lastCheckupDate'] != null
          ? DateTime.parse(json['lastCheckupDate'] as String)
          : null,
      notes: json['notes'] as String?,
      labValues: json['labValues'] != null
          ? LabValues.fromJson(json['labValues'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Date when CKD was first diagnosed
  final DateTime? ckdDiagnosisDate;

  /// Current IRIS stage of the pet's CKD
  final IrisStage? irisStage;

  /// Date of the last veterinary checkup
  final DateTime? lastCheckupDate;

  /// Additional medical notes
  final String? notes;

  /// Laboratory values from bloodwork
  final LabValues? labValues;

  /// Converts [MedicalInfo] to JSON data
  Map<String, dynamic> toJson() {
    return {
      'ckdDiagnosisDate': ckdDiagnosisDate?.toIso8601String(),
      'irisStage': irisStage?.name,
      'lastCheckupDate': lastCheckupDate?.toIso8601String(),
      'notes': notes,
      'labValues': labValues?.toJson(),
    };
  }

  /// Creates a copy of this [MedicalInfo] with the given fields replaced
  MedicalInfo copyWith({
    Object? ckdDiagnosisDate = _undefined,
    Object? irisStage = _undefined,
    Object? lastCheckupDate = _undefined,
    Object? notes = _undefined,
    LabValues? labValues,
  }) {
    return MedicalInfo(
      ckdDiagnosisDate: ckdDiagnosisDate == _undefined 
          ? this.ckdDiagnosisDate 
          : ckdDiagnosisDate as DateTime?,
      irisStage: irisStage == _undefined 
          ? this.irisStage 
          : irisStage as IrisStage?,
      lastCheckupDate: lastCheckupDate == _undefined 
          ? this.lastCheckupDate 
          : lastCheckupDate as DateTime?,
      notes: notes == _undefined ? this.notes : notes as String?,
      labValues: labValues ?? this.labValues,
    );
  }

  /// Validates the medical information for consistency
  List<String> validate() {
    final errors = <String>[];

    // CKD diagnosis date should not be in the future
    if (ckdDiagnosisDate != null && ckdDiagnosisDate!.isAfter(DateTime.now())) {
      errors.add('CKD diagnosis date cannot be in the future');
    }

    // Last checkup date should not be in the future
    if (lastCheckupDate != null && lastCheckupDate!.isAfter(DateTime.now())) {
      errors.add('Last checkup date cannot be in the future');
    }

    // Last checkup should be after diagnosis
    if (ckdDiagnosisDate != null &&
        lastCheckupDate != null &&
        lastCheckupDate!.isBefore(ckdDiagnosisDate!)) {
      errors.add('Last checkup date should be after diagnosis date');
    }

    // Validate lab values if present
    if (labValues != null) {
      errors.addAll(labValues!.validate());
    }

    return errors;
  }

  /// Whether this medical info contains any data
  bool get hasData =>
      ckdDiagnosisDate != null ||
      irisStage != null ||
      lastCheckupDate != null ||
      (notes != null && notes!.isNotEmpty) ||
      (labValues != null && labValues!.hasValues);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MedicalInfo &&
        other.ckdDiagnosisDate == ckdDiagnosisDate &&
        other.irisStage == irisStage &&
        other.lastCheckupDate == lastCheckupDate &&
        other.notes == notes &&
        other.labValues == labValues;
  }

  @override
  int get hashCode {
    return Object.hash(
      ckdDiagnosisDate,
      irisStage,
      lastCheckupDate,
      notes,
      labValues,
    );
  }

  @override
  String toString() {
    return 'MedicalInfo('
        'ckdDiagnosisDate: $ckdDiagnosisDate, '
        'irisStage: $irisStage, '
        'lastCheckupDate: $lastCheckupDate, '
        'notes: $notes, '
        'labValues: $labValues'
        ')';
  }
}
