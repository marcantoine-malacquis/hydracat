import 'package:flutter/foundation.dart';

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

  /// Converts [MedicalInfo] to JSON data
  Map<String, dynamic> toJson() {
    return {
      'ckdDiagnosisDate': ckdDiagnosisDate?.toIso8601String(),
      'irisStage': irisStage?.name,
      'lastCheckupDate': lastCheckupDate?.toIso8601String(),
      'notes': notes,
    };
  }

  /// Creates a copy of this [MedicalInfo] with the given fields replaced
  MedicalInfo copyWith({
    DateTime? ckdDiagnosisDate,
    IrisStage? irisStage,
    DateTime? lastCheckupDate,
    String? notes,
  }) {
    return MedicalInfo(
      ckdDiagnosisDate: ckdDiagnosisDate ?? this.ckdDiagnosisDate,
      irisStage: irisStage ?? this.irisStage,
      lastCheckupDate: lastCheckupDate ?? this.lastCheckupDate,
      notes: notes ?? this.notes,
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

    return errors;
  }

  /// Whether this medical info contains any data
  bool get hasData =>
      ckdDiagnosisDate != null ||
      irisStage != null ||
      lastCheckupDate != null ||
      (notes != null && notes!.isNotEmpty);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MedicalInfo &&
        other.ckdDiagnosisDate == ckdDiagnosisDate &&
        other.irisStage == irisStage &&
        other.lastCheckupDate == lastCheckupDate &&
        other.notes == notes;
  }

  @override
  int get hashCode {
    return Object.hash(
      ckdDiagnosisDate,
      irisStage,
      lastCheckupDate,
      notes,
    );
  }

  @override
  String toString() {
    return 'MedicalInfo('
        'ckdDiagnosisDate: $ckdDiagnosisDate, '
        'irisStage: $irisStage, '
        'lastCheckupDate: $lastCheckupDate, '
        'notes: $notes'
        ')';
  }
}
