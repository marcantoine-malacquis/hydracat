import 'package:flutter/foundation.dart';
import 'package:hydracat/core/utils/date_utils.dart';
import 'package:hydracat/features/onboarding/models/treatment_data.dart';
import 'package:hydracat/features/profile/models/schedule.dart';

/// Historical snapshot of a schedule's state at a specific point in time
///
/// Used to track schedule changes over time, enabling accurate display of
/// historical reminder times and treatment details in the calendar.
@immutable
class ScheduleHistoryEntry {
  /// Creates a [ScheduleHistoryEntry]
  const ScheduleHistoryEntry({
    required this.scheduleId,
    required this.effectiveFrom,
    required this.treatmentType,
    required this.frequency,
    required this.reminderTimesIso,
    this.effectiveTo,
    this.medicationName,
    this.targetDosage,
    this.medicationUnit,
    this.medicationStrengthAmount,
    this.medicationStrengthUnit,
    this.customMedicationStrengthUnit,
    this.targetVolume,
    this.preferredLocation,
    this.needleGauge,
  });

  /// Creates a [ScheduleHistoryEntry] from a [Schedule]
  factory ScheduleHistoryEntry.fromSchedule(
    Schedule schedule, {
    required DateTime effectiveFrom,
    DateTime? effectiveTo,
  }) {
    return ScheduleHistoryEntry(
      scheduleId: schedule.id,
      effectiveFrom: effectiveFrom,
      effectiveTo: effectiveTo,
      treatmentType: schedule.treatmentType,
      frequency: schedule.frequency,
      reminderTimesIso: schedule.reminderTimes
          .map(
            (dt) =>
                '${dt.hour.toString().padLeft(2, '0')}:'
                '${dt.minute.toString().padLeft(2, '0')}:00',
          )
          .toList(),
      medicationName: schedule.medicationName,
      targetDosage: schedule.targetDosage,
      medicationUnit: schedule.medicationUnit,
      medicationStrengthAmount: schedule.medicationStrengthAmount,
      medicationStrengthUnit: schedule.medicationStrengthUnit,
      customMedicationStrengthUnit: schedule.customMedicationStrengthUnit,
      targetVolume: schedule.targetVolume,
      preferredLocation: schedule.preferredLocation?.name,
      needleGauge: schedule.needleGauge,
    );
  }

  /// Creates a [ScheduleHistoryEntry] from JSON
  factory ScheduleHistoryEntry.fromJson(Map<String, dynamic> json) {
    return ScheduleHistoryEntry(
      scheduleId: json['scheduleId'] as String,
      effectiveFrom: DateTime.parse(json['effectiveFrom'] as String),
      effectiveTo: json['effectiveTo'] != null
          ? DateTime.parse(json['effectiveTo'] as String)
          : null,
      treatmentType: TreatmentType.fromString(json['treatmentType'] as String)!,
      frequency: TreatmentFrequency.fromString(json['frequency'] as String)!,
      reminderTimesIso: List<String>.from(json['reminderTimesIso'] as List),
      medicationName: json['medicationName'] as String?,
      targetDosage: (json['targetDosage'] as num?)?.toDouble(),
      medicationUnit: json['medicationUnit'] as String?,
      medicationStrengthAmount: json['medicationStrengthAmount'] as String?,
      medicationStrengthUnit: json['medicationStrengthUnit'] as String?,
      customMedicationStrengthUnit:
          json['customMedicationStrengthUnit'] as String?,
      targetVolume: (json['targetVolume'] as num?)?.toDouble(),
      preferredLocation: json['preferredLocation'] as String?,
      needleGauge: json['needleGauge'] as String?,
    );
  }

  /// ID of the parent schedule document
  final String scheduleId;

  /// When this version became active (inclusive)
  final DateTime effectiveFrom;

  /// When this version stopped being active (exclusive), null if current
  final DateTime? effectiveTo;

  /// Type of treatment
  final TreatmentType treatmentType;

  /// Treatment frequency
  final TreatmentFrequency frequency;

  /// Reminder times as ISO time strings (e.g., ["09:00:00", "21:00:00"])
  /// Stored as strings to avoid timezone complications
  final List<String> reminderTimesIso;

  // Medication-specific fields
  /// Medication name for medication schedules
  final String? medicationName;

  /// Target dosage for medication schedules
  final double? targetDosage;

  /// Medication unit for medication schedules
  final String? medicationUnit;

  /// Medication strength amount
  final String? medicationStrengthAmount;

  /// Medication strength unit
  final String? medicationStrengthUnit;

  /// Custom medication strength unit
  final String? customMedicationStrengthUnit;

  // Fluid-specific fields
  /// Target volume for fluid therapy (in ml)
  final double? targetVolume;

  /// Preferred location for fluid administration
  final String? preferredLocation;

  /// Needle gauge for fluid therapy
  final String? needleGauge;

  /// Converts this entry to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'scheduleId': scheduleId,
      'effectiveFrom': effectiveFrom.toIso8601String(),
      'effectiveTo': effectiveTo?.toIso8601String(),
      'treatmentType': treatmentType.name,
      'frequency': frequency.name,
      'reminderTimesIso': reminderTimesIso,
      'medicationName': medicationName,
      'targetDosage': targetDosage,
      'medicationUnit': medicationUnit,
      'medicationStrengthAmount': medicationStrengthAmount,
      'medicationStrengthUnit': medicationStrengthUnit,
      'customMedicationStrengthUnit': customMedicationStrengthUnit,
      'targetVolume': targetVolume,
      'preferredLocation': preferredLocation,
      'needleGauge': needleGauge,
    };
  }

  /// Parse reminder time ISO strings for a specific date
  ///
  /// Converts the stored ISO time strings (e.g., "09:00:00") to full DateTime
  /// objects for the given [date].
  List<DateTime> getReminderTimesForDate(DateTime date) {
    final normalized = AppDateUtils.startOfDay(date);
    return reminderTimesIso.map((isoTime) {
      final parts = isoTime.split(':');
      return DateTime(
        normalized.year,
        normalized.month,
        normalized.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
    }).toList();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ScheduleHistoryEntry &&
        other.scheduleId == scheduleId &&
        other.effectiveFrom == effectiveFrom &&
        other.effectiveTo == effectiveTo &&
        other.treatmentType == treatmentType &&
        other.frequency == frequency &&
        listEquals(other.reminderTimesIso, reminderTimesIso) &&
        other.medicationName == medicationName &&
        other.targetDosage == targetDosage &&
        other.medicationUnit == medicationUnit &&
        other.medicationStrengthAmount == medicationStrengthAmount &&
        other.medicationStrengthUnit == medicationStrengthUnit &&
        other.customMedicationStrengthUnit == customMedicationStrengthUnit &&
        other.targetVolume == targetVolume &&
        other.preferredLocation == preferredLocation &&
        other.needleGauge == needleGauge;
  }

  @override
  int get hashCode {
    return Object.hash(
      scheduleId,
      effectiveFrom,
      effectiveTo,
      treatmentType,
      frequency,
      Object.hashAll(reminderTimesIso),
      medicationName,
      targetDosage,
      medicationUnit,
      medicationStrengthAmount,
      medicationStrengthUnit,
      customMedicationStrengthUnit,
      targetVolume,
      preferredLocation,
      needleGauge,
    );
  }

  @override
  String toString() {
    return 'ScheduleHistoryEntry('
        'scheduleId: $scheduleId, '
        'effectiveFrom: $effectiveFrom, '
        'effectiveTo: $effectiveTo, '
        'treatmentType: $treatmentType, '
        'frequency: $frequency, '
        'reminderTimesIso: $reminderTimesIso'
        ')';
  }
}
