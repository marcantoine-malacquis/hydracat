import 'package:flutter/foundation.dart';
import 'package:hydracat/core/utils/date_utils.dart';
import 'package:hydracat/shared/models/treatment_summary_base.dart';

/// Sentinel value for [WeeklySummary.copyWith] to distinguish between
/// "not provided" and "explicitly set to null"
const _undefined = Object();

/// Weekly treatment summary model
///
/// Tracks medication and fluid therapy data for a calendar week
/// (Monday-Sunday).
/// Used for:
/// - Weekly progress analytics
/// - Trend visualization
/// - Foundation for monthly aggregations
///
/// Document ID format: YYYY-Www (e.g., "2025-W40")
/// Stored in Firestore: `treatmentSummaryWeekly/{YYYY-Www}`
@immutable
class WeeklySummary extends TreatmentSummaryBase {
  /// Creates a [WeeklySummary] instance
  const WeeklySummary({
    required this.fluidTreatmentDays,
    required this.fluidMissedDays,
    required this.medicationAvgAdherence,
    required this.overallTreatmentDays,
    required this.overallMissedDays,
    required super.medicationTotalDoses,
    required super.medicationScheduledDoses,
    required super.medicationMissedCount,
    required super.fluidTotalVolume,
    required super.fluidTreatmentDone,
    required super.fluidSessionCount,
    required super.fluidScheduledSessions,
    required super.overallTreatmentDone,
    required super.createdAt,
    this.startDate,
    this.endDate,
    super.updatedAt,
    this.fluidScheduledVolume,
    this.daysWithVomiting = 0,
    this.daysWithDiarrhea = 0,
    this.daysWithConstipation = 0,
    this.daysWithEnergy = 0,
    this.daysWithSuppressedAppetite = 0,
    this.daysWithInjectionSiteReaction = 0,
    this.daysWithAnySymptoms = 0,
    this.symptomScoreTotal,
    this.symptomScoreAverage,
    this.symptomScoreMax,
  });

  /// Factory constructor to create an empty weekly summary
  ///
  /// Calculates week start (Monday) and end (Sunday) from any date in the
  /// week. All counters start at 0, all booleans start at false.
  ///
  /// Example:
  /// ```dart
  /// final summary = WeeklySummary.empty(DateTime(2025, 10, 5)); // Sunday
  /// // startDate = Monday, September 29, 2025
  /// // endDate = Sunday, October 5, 2025
  /// ```
  factory WeeklySummary.empty(DateTime weekDate) {
    final weekDates = AppDateUtils.getWeekStartEnd(weekDate);
    final now = DateTime.now();

    return WeeklySummary(
      fluidTreatmentDays: 0,
      fluidMissedDays: 0,
      medicationAvgAdherence: 0,
      overallTreatmentDays: 0,
      overallMissedDays: 0,
      medicationTotalDoses: 0,
      medicationScheduledDoses: 0,
      medicationMissedCount: 0,
      fluidTotalVolume: 0,
      fluidTreatmentDone: false,
      fluidSessionCount: 0,
      fluidScheduledSessions: 0,
      overallTreatmentDone: false,
      createdAt: now,
      startDate: weekDates['start'],
      endDate: weekDates['end'],
    );
  }

  /// Creates a [WeeklySummary] from JSON data
  ///
  /// Handles Firestore Timestamp conversion for all DateTime fields.
  factory WeeklySummary.fromJson(Map<String, dynamic> json) {
    bool asBool(dynamic value) {
      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) {
        final v = value.toLowerCase();
        if (v == 'true' || v == '1') return true;
        if (v == 'false' || v == '0') return false;
      }
      return false;
    }

    return WeeklySummary(
      fluidTreatmentDays: (json['fluidTreatmentDays'] as num?)?.toInt() ?? 0,
      fluidMissedDays: (json['fluidMissedDays'] as num?)?.toInt() ?? 0,
      medicationAvgAdherence:
          (json['medicationAvgAdherence'] as num?)?.toDouble() ?? 0.0,
      overallTreatmentDays:
          (json['overallTreatmentDays'] as num?)?.toInt() ?? 0,
      overallMissedDays: (json['overallMissedDays'] as num?)?.toInt() ?? 0,
      medicationTotalDoses:
          (json['medicationTotalDoses'] as num?)?.toInt() ?? 0,
      medicationScheduledDoses:
          (json['medicationScheduledDoses'] as num?)?.toInt() ?? 0,
      medicationMissedCount:
          (json['medicationMissedCount'] as num?)?.toInt() ?? 0,
      fluidTotalVolume: (json['fluidTotalVolume'] as num?)?.toDouble() ?? 0.0,
      fluidTreatmentDone: asBool(json['fluidTreatmentDone']),
      fluidSessionCount: (json['fluidSessionCount'] as num?)?.toInt() ?? 0,
      fluidScheduledSessions:
          (json['fluidScheduledSessions'] as num?)?.toInt() ?? 0,
      overallTreatmentDone: asBool(json['overallTreatmentDone']),
      createdAt:
          TreatmentSummaryBase.parseDateTimeNullable(json['createdAt']) ??
          DateTime.now(),
      startDate: TreatmentSummaryBase.parseDateTimeNullable(json['startDate']),
      endDate: TreatmentSummaryBase.parseDateTimeNullable(json['endDate']),
      updatedAt: TreatmentSummaryBase.parseDateTimeNullable(json['updatedAt']),
      fluidScheduledVolume: (json['fluidScheduledVolume'] as num?)?.toInt(),
      daysWithVomiting: (json['daysWithVomiting'] as num?)?.toInt() ?? 0,
      daysWithDiarrhea: (json['daysWithDiarrhea'] as num?)?.toInt() ?? 0,
      daysWithConstipation:
          (json['daysWithConstipation'] as num?)?.toInt() ?? 0,
      daysWithEnergy: (json['daysWithEnergy'] as num?)?.toInt() ?? 0,
      daysWithSuppressedAppetite:
          (json['daysWithSuppressedAppetite'] as num?)?.toInt() ?? 0,
      daysWithInjectionSiteReaction:
          (json['daysWithInjectionSiteReaction'] as num?)?.toInt() ?? 0,
      daysWithAnySymptoms: (json['daysWithAnySymptoms'] as num?)?.toInt() ?? 0,
      symptomScoreTotal: (json['symptomScoreTotal'] as num?)?.toInt(),
      symptomScoreAverage: (json['symptomScoreAverage'] as num?)?.toDouble(),
      symptomScoreMax: (json['symptomScoreMax'] as num?)?.toInt(),
    );
  }

  /// First day of the week (Monday 00:00:00)
  ///
  /// Nullable for backward compatibility with legacy data that may not have
  /// this field. New summaries should always include start and end dates.
  final DateTime? startDate;

  /// Last day of the week (Sunday 23:59:59)
  ///
  /// Nullable for backward compatibility with legacy data that may not have
  /// this field. New summaries should always include start and end dates.
  final DateTime? endDate;

  /// Number of days with at least one fluid session
  ///
  /// Incremented from daily summaries where `fluidTreatmentDone == true`.
  final int fluidTreatmentDays;

  /// Number of days without any fluid sessions
  ///
  /// Incremented from daily summaries where `fluidTreatmentDone == false`.
  final int fluidMissedDays;

  /// Average medication adherence for the week (0.0-1.0)
  ///
  /// Calculated as sum of daily adherence values divided by number of days
  /// with medication scheduled.
  final double medicationAvgAdherence;

  /// Number of days with at least one treatment (medication or fluid)
  ///
  /// Incremented from daily summaries where `overallTreatmentDone == true`.
  final int overallTreatmentDays;

  /// Number of days without any treatment
  ///
  /// Incremented from daily summaries where `overallTreatmentDone == false`.
  final int overallMissedDays;

  /// Weekly scheduled fluid volume in ml
  ///
  /// Calculated from active schedules at the time of first session in the week.
  /// Stores the weekly goal for historical accuracy when schedules change.
  /// Null if no sessions have been logged this week yet.
  final int? fluidScheduledVolume;

  // Symptom tracking fields

  /// Number of days with vomiting present (score > 0)
  final int daysWithVomiting;

  /// Number of days with diarrhea present (score > 0)
  final int daysWithDiarrhea;

  /// Number of days with constipation present (score > 0)
  final int daysWithConstipation;

  /// Number of days with energy present (score > 0)
  final int daysWithEnergy;

  /// Number of days with suppressed appetite present (score > 0)
  final int daysWithSuppressedAppetite;

  /// Number of days with injection site reaction present (score > 0)
  final int daysWithInjectionSiteReaction;

  /// Number of days with any symptoms present (hasSymptoms == true)
  final int daysWithAnySymptoms;

  /// Sum of daily symptomScoreTotal over the week
  /// (0-420 for 7 days with max 60 each)
  final int? symptomScoreTotal;

  /// Average daily symptom score across days with any symptoms (0-10)
  final double? symptomScoreAverage;

  /// Maximum daily symptomScoreTotal in the week (0-60)
  final int? symptomScoreMax;

  @override
  String get documentId =>
      AppDateUtils.formatWeekForSummary(startDate ?? DateTime.now());

  /// Whether this week is the current week
  bool get isCurrentWeek {
    if (startDate == null || endDate == null) return false;
    final now = DateTime.now();
    return now.isAfter(startDate!) && now.isBefore(endDate!);
  }

  /// Average medication adherence as percentage (0-100)
  double get medicationAvgAdherencePercentage => medicationAvgAdherence * 100;

  /// Overall adherence percentage for the week (0.0-1.0)
  ///
  /// Calculated as `overallTreatmentDays / (overallTreatmentDays +
  /// overallMissedDays)`.
  double get overallAdherence {
    final totalDays = overallTreatmentDays + overallMissedDays;
    if (totalDays == 0) return 0;
    return overallTreatmentDays / totalDays;
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'fluidTreatmentDays': fluidTreatmentDays,
      'fluidMissedDays': fluidMissedDays,
      'medicationAvgAdherence': medicationAvgAdherence,
      'overallTreatmentDays': overallTreatmentDays,
      'overallMissedDays': overallMissedDays,
      'fluidScheduledVolume': fluidScheduledVolume,
      'medicationTotalDoses': medicationTotalDoses,
      'medicationScheduledDoses': medicationScheduledDoses,
      'medicationMissedCount': medicationMissedCount,
      'fluidTotalVolume': fluidTotalVolume,
      'fluidTreatmentDone': fluidTreatmentDone,
      'fluidSessionCount': fluidSessionCount,
      'fluidScheduledSessions': fluidScheduledSessions,
      'overallTreatmentDone': overallTreatmentDone,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'daysWithVomiting': daysWithVomiting,
      'daysWithDiarrhea': daysWithDiarrhea,
      'daysWithConstipation': daysWithConstipation,
      'daysWithEnergy': daysWithEnergy,
      'daysWithSuppressedAppetite': daysWithSuppressedAppetite,
      'daysWithInjectionSiteReaction': daysWithInjectionSiteReaction,
      'daysWithAnySymptoms': daysWithAnySymptoms,
      if (symptomScoreTotal != null) 'symptomScoreTotal': symptomScoreTotal,
      if (symptomScoreAverage != null)
        'symptomScoreAverage': symptomScoreAverage,
      if (symptomScoreMax != null) 'symptomScoreMax': symptomScoreMax,
    };
  }

  @override
  List<String> validate() {
    final errors = validateBase();

    // Date validation (only if both dates present)
    if (startDate != null && endDate != null) {
      if (endDate!.isBefore(startDate!)) {
        errors.add('End date must be after start date');
      }

      // Week span validation (should be exactly 7 days)
      final daysDifference = endDate!.difference(startDate!).inDays;
      if (daysDifference != 6) {
        // 6 because we count inclusive (Mon-Sun = 7 days but diff = 6)
        errors.add('Week span must be exactly 7 days (Monday-Sunday)');
      }
    }

    // Day counts validation
    if (fluidTreatmentDays < 0) {
      errors.add('Fluid treatment days cannot be negative');
    }
    if (fluidMissedDays < 0) {
      errors.add('Fluid missed days cannot be negative');
    }
    if (overallTreatmentDays < 0) {
      errors.add('Overall treatment days cannot be negative');
    }
    if (overallMissedDays < 0) {
      errors.add('Overall missed days cannot be negative');
    }

    // Week bounds validation (max 7 days)
    if (fluidTreatmentDays + fluidMissedDays > 7) {
      errors.add('Fluid days (treatment + missed) cannot exceed 7');
    }
    if (overallTreatmentDays + overallMissedDays > 7) {
      errors.add('Overall days (treatment + missed) cannot exceed 7');
    }

    // Adherence validation
    if (medicationAvgAdherence < 0.0 || medicationAvgAdherence > 1.0) {
      errors.add('Medication average adherence must be between 0.0 and 1.0');
    }

    return errors;
  }

  /// Creates a copy of this [WeeklySummary] with the given fields replaced
  WeeklySummary copyWith({
    int? fluidTreatmentDays,
    int? fluidMissedDays,
    double? medicationAvgAdherence,
    int? overallTreatmentDays,
    int? overallMissedDays,
    int? medicationTotalDoses,
    int? medicationScheduledDoses,
    int? medicationMissedCount,
    double? fluidTotalVolume,
    bool? fluidTreatmentDone,
    int? fluidSessionCount,
    int? fluidScheduledSessions,
    bool? overallTreatmentDone,
    DateTime? createdAt,
    Object? startDate = _undefined,
    Object? endDate = _undefined,
    Object? updatedAt = _undefined,
    Object? fluidScheduledVolume = _undefined,
    int? daysWithVomiting,
    int? daysWithDiarrhea,
    int? daysWithConstipation,
    int? daysWithEnergy,
    int? daysWithSuppressedAppetite,
    int? daysWithInjectionSiteReaction,
    int? daysWithAnySymptoms,
    Object? symptomScoreTotal = _undefined,
    Object? symptomScoreAverage = _undefined,
    Object? symptomScoreMax = _undefined,
  }) {
    return WeeklySummary(
      fluidTreatmentDays: fluidTreatmentDays ?? this.fluidTreatmentDays,
      fluidMissedDays: fluidMissedDays ?? this.fluidMissedDays,
      medicationAvgAdherence:
          medicationAvgAdherence ?? this.medicationAvgAdherence,
      overallTreatmentDays: overallTreatmentDays ?? this.overallTreatmentDays,
      overallMissedDays: overallMissedDays ?? this.overallMissedDays,
      medicationTotalDoses: medicationTotalDoses ?? this.medicationTotalDoses,
      medicationScheduledDoses:
          medicationScheduledDoses ?? this.medicationScheduledDoses,
      medicationMissedCount:
          medicationMissedCount ?? this.medicationMissedCount,
      fluidTotalVolume: fluidTotalVolume ?? this.fluidTotalVolume,
      fluidTreatmentDone: fluidTreatmentDone ?? this.fluidTreatmentDone,
      fluidSessionCount: fluidSessionCount ?? this.fluidSessionCount,
      fluidScheduledSessions:
          fluidScheduledSessions ?? this.fluidScheduledSessions,
      overallTreatmentDone: overallTreatmentDone ?? this.overallTreatmentDone,
      createdAt: createdAt ?? this.createdAt,
      startDate: startDate == _undefined
          ? this.startDate
          : startDate as DateTime?,
      endDate: endDate == _undefined ? this.endDate : endDate as DateTime?,
      updatedAt: updatedAt == _undefined
          ? this.updatedAt
          : updatedAt as DateTime?,
      fluidScheduledVolume: fluidScheduledVolume == _undefined
          ? this.fluidScheduledVolume
          : fluidScheduledVolume as int?,
      daysWithVomiting: daysWithVomiting ?? this.daysWithVomiting,
      daysWithDiarrhea: daysWithDiarrhea ?? this.daysWithDiarrhea,
      daysWithConstipation: daysWithConstipation ?? this.daysWithConstipation,
      daysWithEnergy: daysWithEnergy ?? this.daysWithEnergy,
      daysWithSuppressedAppetite:
          daysWithSuppressedAppetite ?? this.daysWithSuppressedAppetite,
      daysWithInjectionSiteReaction:
          daysWithInjectionSiteReaction ?? this.daysWithInjectionSiteReaction,
      daysWithAnySymptoms: daysWithAnySymptoms ?? this.daysWithAnySymptoms,
      symptomScoreTotal: symptomScoreTotal == _undefined
          ? this.symptomScoreTotal
          : symptomScoreTotal as int?,
      symptomScoreAverage: symptomScoreAverage == _undefined
          ? this.symptomScoreAverage
          : symptomScoreAverage as double?,
      symptomScoreMax: symptomScoreMax == _undefined
          ? this.symptomScoreMax
          : symptomScoreMax as int?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is WeeklySummary &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.fluidTreatmentDays == fluidTreatmentDays &&
        other.fluidMissedDays == fluidMissedDays &&
        other.medicationAvgAdherence == medicationAvgAdherence &&
        other.overallTreatmentDays == overallTreatmentDays &&
        other.overallMissedDays == overallMissedDays &&
        other.fluidScheduledVolume == fluidScheduledVolume &&
        other.daysWithVomiting == daysWithVomiting &&
        other.daysWithDiarrhea == daysWithDiarrhea &&
        other.daysWithConstipation == daysWithConstipation &&
        other.daysWithEnergy == daysWithEnergy &&
        other.daysWithSuppressedAppetite == daysWithSuppressedAppetite &&
        other.daysWithInjectionSiteReaction == daysWithInjectionSiteReaction &&
        other.daysWithAnySymptoms == daysWithAnySymptoms &&
        other.symptomScoreTotal == symptomScoreTotal &&
        other.symptomScoreAverage == symptomScoreAverage &&
        other.symptomScoreMax == symptomScoreMax &&
        super == other;
  }

  @override
  int get hashCode {
    return Object.hash(
      super.hashCode,
      startDate,
      endDate,
      fluidTreatmentDays,
      fluidMissedDays,
      medicationAvgAdherence,
      overallTreatmentDays,
      overallMissedDays,
      fluidScheduledVolume,
      daysWithVomiting,
      daysWithDiarrhea,
      daysWithConstipation,
      daysWithEnergy,
      daysWithSuppressedAppetite,
      daysWithInjectionSiteReaction,
      daysWithAnySymptoms,
      symptomScoreTotal,
      symptomScoreAverage,
      symptomScoreMax,
    );
  }

  @override
  String toString() {
    return 'WeeklySummary('
        'startDate: $startDate, '
        'endDate: $endDate, '
        'fluidTreatmentDays: $fluidTreatmentDays, '
        'fluidMissedDays: $fluidMissedDays, '
        'medicationAvgAdherence: $medicationAvgAdherence, '
        'overallTreatmentDays: $overallTreatmentDays, '
        'overallMissedDays: $overallMissedDays, '
        'fluidScheduledVolume: $fluidScheduledVolume, '
        'medicationTotalDoses: $medicationTotalDoses, '
        'medicationScheduledDoses: $medicationScheduledDoses, '
        'medicationMissedCount: $medicationMissedCount, '
        'fluidTotalVolume: $fluidTotalVolume, '
        'fluidTreatmentDone: $fluidTreatmentDone, '
        'fluidSessionCount: $fluidSessionCount, '
        'overallTreatmentDone: $overallTreatmentDone, '
        'createdAt: $createdAt, '
        'updatedAt: $updatedAt, '
        'daysWithVomiting: $daysWithVomiting, '
        'daysWithDiarrhea: $daysWithDiarrhea, '
        'daysWithConstipation: $daysWithConstipation, '
        'daysWithEnergy: $daysWithEnergy, '
        'daysWithSuppressedAppetite: $daysWithSuppressedAppetite, '
        'daysWithInjectionSiteReaction: $daysWithInjectionSiteReaction, '
        'daysWithAnySymptoms: $daysWithAnySymptoms, '
        'symptomScoreTotal: $symptomScoreTotal, '
        'symptomScoreAverage: $symptomScoreAverage, '
        'symptomScoreMax: $symptomScoreMax'
        ')';
  }
}
