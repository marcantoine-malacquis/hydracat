import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hydracat/core/utils/dosage_text_utils.dart';
import 'package:hydracat/features/onboarding/models/treatment_data.dart';
import 'package:hydracat/shared/models/schedule_dto.dart';

/// Enumeration of treatment types for schedules
enum TreatmentType {
  /// Fluid therapy treatment
  fluid,

  /// Medication treatment
  medication;

  /// User-friendly display name for the treatment type
  String get displayName => switch (this) {
        TreatmentType.fluid => 'Fluid Therapy',
        TreatmentType.medication => 'Medication',
      };

  /// Creates a TreatmentType from a string value
  static TreatmentType? fromString(String value) {
    return TreatmentType.values
        .where((type) => type.name == value)
        .firstOrNull;
  }
}

/// Data class for treatment schedules
@immutable
class Schedule {
  /// Creates a [Schedule] instance
  const Schedule({
    required this.id,
    required this.treatmentType,
    required this.frequency,
    required this.reminderTimes,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.targetVolume,
    this.preferredLocation,
    this.needleGauge,
    this.medicationName,
    this.targetDosage,
    this.medicationUnit,
    this.medicationStrengthAmount,
    this.medicationStrengthUnit,
    this.customMedicationStrengthUnit,
  });

  /// Creates a [Schedule] from JSON data
  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      id: json['id'] as String,
      treatmentType:
          TreatmentType.fromString(json['treatmentType'] as String) ??
          TreatmentType.fluid,
      frequency:
          TreatmentFrequency.fromString(json['frequency'] as String) ??
          TreatmentFrequency.onceDaily,
      reminderTimes: (json['reminderTimes'] as List<dynamic>)
          .map(_parseDateTime)
          .toList(),
      isActive: json['isActive'] as bool? ?? true,
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
      targetVolume: json['targetVolume'] != null
          ? (json['targetVolume'] as num).toDouble()
          : null,
      preferredLocation: json['preferredLocation'] != null
          ? FluidLocation.fromString(json['preferredLocation'] as String)
          : null,
      needleGauge: json['needleGauge'] as String?,
      medicationName: json['medicationName'] as String?,
      targetDosage: json['targetDosage'] != null
          ? (json['targetDosage'] as num).toDouble()
          : null,
      medicationUnit: json['medicationUnit'] as String?,
      medicationStrengthAmount:
          json['medicationStrengthAmount'] as String?,
      medicationStrengthUnit: json['medicationStrengthUnit'] as String?,
      customMedicationStrengthUnit:
          json['customMedicationStrengthUnit'] as String?,
    );
  }

  /// Helper method to parse DateTime from various formats
  /// Handles both Firestore Timestamp objects and ISO 8601 strings
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

  /// Unique identifier for the schedule
  final String id;

  /// Type of treatment (fluid or medication)
  final TreatmentType treatmentType;

  /// Treatment frequency
  final TreatmentFrequency frequency;

  /// List of reminder times for the treatment
  final List<DateTime> reminderTimes;

  /// Whether this schedule is currently active
  final bool isActive;

  /// Timestamp when the schedule was created
  final DateTime createdAt;

  /// Timestamp when the schedule was last updated
  final DateTime updatedAt;

  /// Target volume for fluid therapy (in ml)
  final double? targetVolume;

  /// Preferred location for fluid administration
  final FluidLocation? preferredLocation;

  /// Needle gauge for fluid therapy
  final String? needleGauge;

  /// Medication name for medication schedules
  final String? medicationName;

  /// Target dosage for medication schedules
  final double? targetDosage;

  /// Medication unit for medication schedules
  final String? medicationUnit;

  /// Medication strength amount (e.g., "2.5", "10")
  final String? medicationStrengthAmount;

  /// Medication strength unit (e.g., "mg", "mgPerMl")
  final String? medicationStrengthUnit;

  /// Custom medication strength unit when medicationStrengthUnit is 'other'
  final String? customMedicationStrengthUnit;

  /// Whether this is a fluid therapy schedule
  bool get isFluidTherapy => treatmentType == TreatmentType.fluid;

  /// Whether this is a medication schedule
  bool get isMedication => treatmentType == TreatmentType.medication;

  /// Generate a human-readable summary of this schedule
  String get summary {
    if (isFluidTherapy && targetVolume != null) {
      return '${targetVolume!.toInt()}ml '
          '${frequency.displayName.toLowerCase()}';
    } else if (isMedication && medicationName != null) {
      final dosageText = targetDosage != null && medicationUnit != null
          ? DosageTextUtils.formatDosageWithUnit(
              targetDosage!,
              _getShortForm(medicationUnit!),
            )
          : '';
      return '$dosageText $medicationName '
          '${frequency.displayName.toLowerCase()}';
    }
    return frequency.displayName;
  }

  /// Get short form of medication unit
  String _getShortForm(String unit) {
    return switch (unit) {
      'ampoules' => 'ampoule',
      'capsules' => 'capsule',
      'drops' => 'drop',
      'injections' => 'injection',
      'micrograms' => 'mcg',
      'milligrams' => 'mg',
      'milliliters' => 'ml',
      'pills' => 'pill',
      'portions' => 'portion',
      'sachets' => 'sachet',
      'tablespoon' => 'tbsp',
      'teaspoon' => 'tsp',
      _ => unit,
    };
  }

  /// Whether this schedule has valid data
  bool get isValid {
    if (treatmentType == TreatmentType.fluid) {
      return targetVolume != null &&
          targetVolume! > 0 &&
          preferredLocation != null &&
          needleGauge != null &&
          needleGauge!.isNotEmpty &&
          reminderTimes.isNotEmpty;
    } else if (treatmentType == TreatmentType.medication) {
      return medicationName != null &&
          medicationName!.isNotEmpty &&
          targetDosage != null &&
          targetDosage! > 0 &&
          medicationUnit != null &&
          medicationUnit!.isNotEmpty &&
          reminderTimes.isNotEmpty;
    }
    return false;
  }

  /// Converts [Schedule] to a [ScheduleDto] for creating/updating schedules
  ///
  /// This is useful when you need to duplicate or update an existing schedule
  ScheduleDto toDto() {
    if (treatmentType == TreatmentType.medication) {
      return ScheduleDto.medication(
        id: id,
        medicationName: medicationName!,
        targetDosage: targetDosage!,
        medicationUnit: medicationUnit!,
        frequency: frequency,
        reminderTimes: reminderTimes,
        isActive: isActive,
        medicationStrengthAmount: medicationStrengthAmount,
        medicationStrengthUnit: medicationStrengthUnit,
        customMedicationStrengthUnit: customMedicationStrengthUnit,
      );
    } else {
      return ScheduleDto.fluid(
        id: id,
        targetVolume: targetVolume!,
        frequency: frequency,
        preferredLocation: preferredLocation!,
        needleGauge: needleGauge!,
        reminderTimes: reminderTimes,
        isActive: isActive,
      );
    }
  }

  /// Converts [Schedule] to JSON data with treatment-type-specific fields
  Map<String, dynamic> toJson() {
    final baseFields = {
      'id': id,
      'treatmentType': treatmentType.name,
      'frequency': frequency.name,
      'reminderTimes': reminderTimes.map((e) => e.toIso8601String()).toList(),
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };

    // Add treatment-specific fields based on type
    if (treatmentType == TreatmentType.medication) {
      return {
        ...baseFields,
        'medicationName': medicationName,
        'targetDosage': targetDosage,
        'medicationUnit': medicationUnit,
        'medicationStrengthAmount': medicationStrengthAmount,
        'medicationStrengthUnit': medicationStrengthUnit,
        'customMedicationStrengthUnit': customMedicationStrengthUnit,
      };
    } else if (treatmentType == TreatmentType.fluid) {
      return {
        ...baseFields,
        'targetVolume': targetVolume,
        'preferredLocation': preferredLocation?.name,
        'needleGauge': needleGauge,
      };
    }

    // Fallback - should not happen with proper validation
    return baseFields;
  }

  /// Creates a copy of this [Schedule] with the given fields replaced
  Schedule copyWith({
    String? id,
    TreatmentType? treatmentType,
    TreatmentFrequency? frequency,
    List<DateTime>? reminderTimes,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? targetVolume,
    FluidLocation? preferredLocation,
    String? needleGauge,
    String? medicationName,
    double? targetDosage,
    String? medicationUnit,
    String? medicationStrengthAmount,
    String? medicationStrengthUnit,
    String? customMedicationStrengthUnit,
  }) {
    return Schedule(
      id: id ?? this.id,
      treatmentType: treatmentType ?? this.treatmentType,
      frequency: frequency ?? this.frequency,
      reminderTimes: reminderTimes ?? this.reminderTimes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      targetVolume: targetVolume ?? this.targetVolume,
      preferredLocation: preferredLocation ?? this.preferredLocation,
      needleGauge: needleGauge ?? this.needleGauge,
      medicationName: medicationName ?? this.medicationName,
      targetDosage: targetDosage ?? this.targetDosage,
      medicationUnit: medicationUnit ?? this.medicationUnit,
      medicationStrengthAmount:
          medicationStrengthAmount ?? this.medicationStrengthAmount,
      medicationStrengthUnit:
          medicationStrengthUnit ?? this.medicationStrengthUnit,
      customMedicationStrengthUnit:
          customMedicationStrengthUnit ?? this.customMedicationStrengthUnit,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Schedule &&
        other.id == id &&
        other.treatmentType == treatmentType &&
        other.frequency == frequency &&
        listEquals(other.reminderTimes, reminderTimes) &&
        other.isActive == isActive &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.targetVolume == targetVolume &&
        other.preferredLocation == preferredLocation &&
        other.needleGauge == needleGauge &&
        other.medicationName == medicationName &&
        other.targetDosage == targetDosage &&
        other.medicationUnit == medicationUnit &&
        other.medicationStrengthAmount == medicationStrengthAmount &&
        other.medicationStrengthUnit == medicationStrengthUnit &&
        other.customMedicationStrengthUnit == customMedicationStrengthUnit;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      treatmentType,
      frequency,
      Object.hashAll(reminderTimes),
      isActive,
      createdAt,
      updatedAt,
      targetVolume,
      preferredLocation,
      needleGauge,
      medicationName,
      targetDosage,
      medicationUnit,
      medicationStrengthAmount,
      medicationStrengthUnit,
      customMedicationStrengthUnit,
    );
  }

  @override
  String toString() {
    return 'Schedule('
        'id: $id, '
        'treatmentType: $treatmentType, '
        'frequency: $frequency, '
        'reminderTimes: $reminderTimes, '
        'isActive: $isActive, '
        'targetVolume: $targetVolume, '
        'preferredLocation: $preferredLocation, '
        'needleGauge: $needleGauge, '
        'medicationName: $medicationName, '
        'targetDosage: $targetDosage, '
        'medicationUnit: $medicationUnit, '
        'medicationStrengthAmount: $medicationStrengthAmount, '
        'medicationStrengthUnit: $medicationStrengthUnit, '
        'customMedicationStrengthUnit: $customMedicationStrengthUnit'
        ')';
  }
}
