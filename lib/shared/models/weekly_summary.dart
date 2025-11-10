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
    required this.startDate,
    required this.endDate,
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
    super.updatedAt,
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
      startDate: weekDates['start']!,
      endDate: weekDates['end']!,
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
      startDate: TreatmentSummaryBase.parseDateTime(json['startDate']),
      endDate: TreatmentSummaryBase.parseDateTime(json['endDate']),
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
      updatedAt: TreatmentSummaryBase.parseDateTimeNullable(json['updatedAt']),
    );
  }

  /// First day of the week (Monday 00:00:00)
  final DateTime startDate;

  /// Last day of the week (Sunday 23:59:59)
  final DateTime endDate;

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

  @override
  String get documentId => AppDateUtils.formatWeekForSummary(startDate);

  /// Whether this week is the current week
  bool get isCurrentWeek {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
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
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'fluidTreatmentDays': fluidTreatmentDays,
      'fluidMissedDays': fluidMissedDays,
      'medicationAvgAdherence': medicationAvgAdherence,
      'overallTreatmentDays': overallTreatmentDays,
      'overallMissedDays': overallMissedDays,
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
    };
  }

  @override
  List<String> validate() {
    final errors = validateBase();

    // Date validation
    if (endDate.isBefore(startDate)) {
      errors.add('End date must be after start date');
    }

    // Week span validation (should be exactly 7 days)
    final daysDifference = endDate.difference(startDate).inDays;
    if (daysDifference != 6) {
      // 6 because we count inclusive (Mon-Sun = 7 days but diff = 6)
      errors.add('Week span must be exactly 7 days (Monday-Sunday)');
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
    DateTime? startDate,
    DateTime? endDate,
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
    Object? updatedAt = _undefined,
  }) {
    return WeeklySummary(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
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
      updatedAt: updatedAt == _undefined 
          ? this.updatedAt 
          : updatedAt as DateTime?,
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
        'medicationTotalDoses: $medicationTotalDoses, '
        'medicationScheduledDoses: $medicationScheduledDoses, '
        'medicationMissedCount: $medicationMissedCount, '
        'fluidTotalVolume: $fluidTotalVolume, '
        'fluidTreatmentDone: $fluidTreatmentDone, '
        'fluidSessionCount: $fluidSessionCount, '
        'overallTreatmentDone: $overallTreatmentDone, '
        'createdAt: $createdAt, '
        'updatedAt: $updatedAt'
        ')';
  }
}
