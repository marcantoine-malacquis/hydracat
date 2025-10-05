import 'package:flutter/foundation.dart';
import 'package:hydracat/core/utils/date_utils.dart';
import 'package:hydracat/shared/models/treatment_summary_base.dart';

/// Monthly treatment summary model
///
/// Tracks medication and fluid therapy data for a calendar month.
/// Used for:
/// - Long-term trend analytics
/// - Adherence streak tracking
/// - Monthly reports and insights
///
/// Document ID format: YYYY-MM (e.g., "2025-10")
/// Stored in Firestore: `treatmentSummaryMonthly/{YYYY-MM}`
@immutable
class MonthlySummary extends TreatmentSummaryBase {
  /// Creates a [MonthlySummary] instance
  const MonthlySummary({
    required this.startDate,
    required this.endDate,
    required this.fluidTreatmentDays,
    required this.fluidMissedDays,
    required this.fluidLongestStreak,
    required this.fluidCurrentStreak,
    required this.medicationMonthlyAdherence,
    required this.medicationLongestStreak,
    required this.medicationCurrentStreak,
    required this.overallTreatmentDays,
    required this.overallMissedDays,
    required this.overallLongestStreak,
    required this.overallCurrentStreak,
    required super.medicationTotalDoses,
    required super.medicationScheduledDoses,
    required super.medicationMissedCount,
    required super.fluidTotalVolume,
    required super.fluidTreatmentDone,
    required super.fluidSessionCount,
    required super.overallTreatmentDone,
    required super.createdAt,
    super.updatedAt,
  });

  /// Factory constructor to create an empty monthly summary
  ///
  /// Calculates month start (first day) and end (last day) from any date in
  /// the month. All counters start at 0, all booleans start at false.
  ///
  /// Example:
  /// ```dart
  /// final summary = MonthlySummary.empty(DateTime(2025, 10, 15));
  /// // startDate = October 1, 2025 00:00:00
  /// // endDate = October 31, 2025 23:59:59
  /// ```
  factory MonthlySummary.empty(DateTime monthDate) {
    final monthDates = AppDateUtils.getMonthStartEnd(monthDate);
    final now = DateTime.now();

    return MonthlySummary(
      startDate: monthDates['start']!,
      endDate: monthDates['end']!,
      fluidTreatmentDays: 0,
      fluidMissedDays: 0,
      fluidLongestStreak: 0,
      fluidCurrentStreak: 0,
      medicationMonthlyAdherence: 0,
      medicationLongestStreak: 0,
      medicationCurrentStreak: 0,
      overallTreatmentDays: 0,
      overallMissedDays: 0,
      overallLongestStreak: 0,
      overallCurrentStreak: 0,
      medicationTotalDoses: 0,
      medicationScheduledDoses: 0,
      medicationMissedCount: 0,
      fluidTotalVolume: 0,
      fluidTreatmentDone: false,
      fluidSessionCount: 0,
      overallTreatmentDone: false,
      createdAt: now,
    );
  }

  /// Creates a [MonthlySummary] from JSON data
  ///
  /// Handles Firestore Timestamp conversion for all DateTime fields.
  factory MonthlySummary.fromJson(Map<String, dynamic> json) {
    return MonthlySummary(
      startDate: TreatmentSummaryBase.parseDateTime(json['startDate']),
      endDate: TreatmentSummaryBase.parseDateTime(json['endDate']),
      fluidTreatmentDays: json['fluidTreatmentDays'] as int,
      fluidMissedDays: json['fluidMissedDays'] as int,
      fluidLongestStreak: json['fluidLongestStreak'] as int,
      fluidCurrentStreak: json['fluidCurrentStreak'] as int,
      medicationMonthlyAdherence:
          (json['medicationMonthlyAdherence'] as num).toDouble(),
      medicationLongestStreak: json['medicationLongestStreak'] as int,
      medicationCurrentStreak: json['medicationCurrentStreak'] as int,
      overallTreatmentDays: json['overallTreatmentDays'] as int,
      overallMissedDays: json['overallMissedDays'] as int,
      overallLongestStreak: json['overallLongestStreak'] as int,
      overallCurrentStreak: json['overallCurrentStreak'] as int,
      medicationTotalDoses: json['medicationTotalDoses'] as int,
      medicationScheduledDoses: json['medicationScheduledDoses'] as int,
      medicationMissedCount: json['medicationMissedCount'] as int,
      fluidTotalVolume: (json['fluidTotalVolume'] as num).toDouble(),
      fluidTreatmentDone: json['fluidTreatmentDone'] as bool,
      fluidSessionCount: json['fluidSessionCount'] as int,
      overallTreatmentDone: json['overallTreatmentDone'] as bool,
      createdAt: TreatmentSummaryBase.parseDateTime(json['createdAt']),
      updatedAt: json['updatedAt'] != null
          ? TreatmentSummaryBase.parseDateTime(json['updatedAt'])
          : null,
    );
  }

  /// First day of the month (00:00:00)
  final DateTime startDate;

  /// Last day of the month (23:59:59)
  final DateTime endDate;

  /// Number of days with at least one fluid session
  ///
  /// Aggregated from daily summaries where `fluidTreatmentDone == true`.
  final int fluidTreatmentDays;

  /// Number of days without any fluid sessions
  ///
  /// Aggregated from daily summaries where `fluidTreatmentDone == false`.
  final int fluidMissedDays;

  /// Longest consecutive days with fluid therapy this month
  ///
  /// Calculated from daily summaries by tracking consecutive
  /// `fluidTreatmentDone == true` days.
  final int fluidLongestStreak;

  /// Current consecutive days with fluid therapy (as of last update)
  ///
  /// Reset to 0 when a day without fluid therapy occurs.
  final int fluidCurrentStreak;

  /// Overall medication adherence for the month (0.0-1.0)
  ///
  /// Calculated as `medicationTotalDoses / medicationScheduledDoses` for the
  /// entire month.
  final double medicationMonthlyAdherence;

  /// Longest consecutive days with medication adherence this month
  ///
  /// Calculated from daily summaries by tracking consecutive days with
  /// all medications completed.
  final int medicationLongestStreak;

  /// Current consecutive days with medication adherence (as of last update)
  ///
  /// Reset to 0 when a medication dose is missed.
  final int medicationCurrentStreak;

  /// Number of days with at least one treatment (medication or fluid)
  ///
  /// Aggregated from daily summaries where `overallTreatmentDone == true`.
  final int overallTreatmentDays;

  /// Number of days without any treatment
  ///
  /// Aggregated from daily summaries where `overallTreatmentDone == false`.
  final int overallMissedDays;

  /// Longest consecutive days with overall treatment adherence this month
  ///
  /// Calculated from daily summaries by tracking consecutive
  /// `overallTreatmentDone == true` days.
  final int overallLongestStreak;

  /// Current consecutive days with overall treatment adherence
  ///
  /// Reset to 0 when a day without treatment occurs.
  final int overallCurrentStreak;

  @override
  String get documentId => AppDateUtils.formatMonthForSummary(startDate);

  /// Whether this month is the current month
  bool get isCurrentMonth {
    final now = DateTime.now();
    return now.year == startDate.year && now.month == startDate.month;
  }

  /// Medication adherence as percentage (0-100)
  double get medicationMonthlyAdherencePercentage =>
      medicationMonthlyAdherence * 100;

  /// Overall adherence percentage for the month (0.0-1.0)
  ///
  /// Calculated as `overallTreatmentDays / (overallTreatmentDays +
  /// overallMissedDays)`.
  double get overallMonthlyAdherence {
    final totalDays = overallTreatmentDays + overallMissedDays;
    if (totalDays == 0) return 0;
    return overallTreatmentDays / totalDays;
  }

  /// Number of days in this month (28-31)
  int get daysInMonth {
    return endDate.day; // Last day of month = number of days
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'fluidTreatmentDays': fluidTreatmentDays,
      'fluidMissedDays': fluidMissedDays,
      'fluidLongestStreak': fluidLongestStreak,
      'fluidCurrentStreak': fluidCurrentStreak,
      'medicationMonthlyAdherence': medicationMonthlyAdherence,
      'medicationLongestStreak': medicationLongestStreak,
      'medicationCurrentStreak': medicationCurrentStreak,
      'overallTreatmentDays': overallTreatmentDays,
      'overallMissedDays': overallMissedDays,
      'overallLongestStreak': overallLongestStreak,
      'overallCurrentStreak': overallCurrentStreak,
      'medicationTotalDoses': medicationTotalDoses,
      'medicationScheduledDoses': medicationScheduledDoses,
      'medicationMissedCount': medicationMissedCount,
      'fluidTotalVolume': fluidTotalVolume,
      'fluidTreatmentDone': fluidTreatmentDone,
      'fluidSessionCount': fluidSessionCount,
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

    // Month validation (both dates must be in same month)
    if (startDate.year != endDate.year ||
        startDate.month != endDate.month) {
      errors.add('Start and end dates must be in the same month');
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

    // Month bounds validation (max 31 days)
    if (fluidTreatmentDays + fluidMissedDays > 31) {
      errors.add('Fluid days (treatment + missed) cannot exceed 31');
    }
    if (overallTreatmentDays + overallMissedDays > 31) {
      errors.add('Overall days (treatment + missed) cannot exceed 31');
    }

    // Streak validation
    if (fluidLongestStreak < 0) {
      errors.add('Fluid longest streak cannot be negative');
    }
    if (fluidCurrentStreak < 0) {
      errors.add('Fluid current streak cannot be negative');
    }
    if (medicationLongestStreak < 0) {
      errors.add('Medication longest streak cannot be negative');
    }
    if (medicationCurrentStreak < 0) {
      errors.add('Medication current streak cannot be negative');
    }
    if (overallLongestStreak < 0) {
      errors.add('Overall longest streak cannot be negative');
    }
    if (overallCurrentStreak < 0) {
      errors.add('Overall current streak cannot be negative');
    }

    // Streak logical consistency
    if (fluidCurrentStreak > fluidLongestStreak) {
      errors.add('Fluid current streak cannot exceed longest streak');
    }
    if (medicationCurrentStreak > medicationLongestStreak) {
      errors.add('Medication current streak cannot exceed longest streak');
    }
    if (overallCurrentStreak > overallLongestStreak) {
      errors.add('Overall current streak cannot exceed longest streak');
    }

    // Adherence validation
    if (medicationMonthlyAdherence < 0.0 ||
        medicationMonthlyAdherence > 1.0) {
      errors.add(
        'Medication monthly adherence must be between 0.0 and 1.0',
      );
    }

    return errors;
  }

  /// Creates a copy of this [MonthlySummary] with the given fields replaced
  MonthlySummary copyWith({
    DateTime? startDate,
    DateTime? endDate,
    int? fluidTreatmentDays,
    int? fluidMissedDays,
    int? fluidLongestStreak,
    int? fluidCurrentStreak,
    double? medicationMonthlyAdherence,
    int? medicationLongestStreak,
    int? medicationCurrentStreak,
    int? overallTreatmentDays,
    int? overallMissedDays,
    int? overallLongestStreak,
    int? overallCurrentStreak,
    int? medicationTotalDoses,
    int? medicationScheduledDoses,
    int? medicationMissedCount,
    double? fluidTotalVolume,
    bool? fluidTreatmentDone,
    int? fluidSessionCount,
    bool? overallTreatmentDone,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MonthlySummary(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      fluidTreatmentDays: fluidTreatmentDays ?? this.fluidTreatmentDays,
      fluidMissedDays: fluidMissedDays ?? this.fluidMissedDays,
      fluidLongestStreak: fluidLongestStreak ?? this.fluidLongestStreak,
      fluidCurrentStreak: fluidCurrentStreak ?? this.fluidCurrentStreak,
      medicationMonthlyAdherence:
          medicationMonthlyAdherence ?? this.medicationMonthlyAdherence,
      medicationLongestStreak:
          medicationLongestStreak ?? this.medicationLongestStreak,
      medicationCurrentStreak:
          medicationCurrentStreak ?? this.medicationCurrentStreak,
      overallTreatmentDays:
          overallTreatmentDays ?? this.overallTreatmentDays,
      overallMissedDays: overallMissedDays ?? this.overallMissedDays,
      overallLongestStreak:
          overallLongestStreak ?? this.overallLongestStreak,
      overallCurrentStreak:
          overallCurrentStreak ?? this.overallCurrentStreak,
      medicationTotalDoses:
          medicationTotalDoses ?? this.medicationTotalDoses,
      medicationScheduledDoses:
          medicationScheduledDoses ?? this.medicationScheduledDoses,
      medicationMissedCount:
          medicationMissedCount ?? this.medicationMissedCount,
      fluidTotalVolume: fluidTotalVolume ?? this.fluidTotalVolume,
      fluidTreatmentDone: fluidTreatmentDone ?? this.fluidTreatmentDone,
      fluidSessionCount: fluidSessionCount ?? this.fluidSessionCount,
      overallTreatmentDone:
          overallTreatmentDone ?? this.overallTreatmentDone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MonthlySummary &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.fluidTreatmentDays == fluidTreatmentDays &&
        other.fluidMissedDays == fluidMissedDays &&
        other.fluidLongestStreak == fluidLongestStreak &&
        other.fluidCurrentStreak == fluidCurrentStreak &&
        other.medicationMonthlyAdherence == medicationMonthlyAdherence &&
        other.medicationLongestStreak == medicationLongestStreak &&
        other.medicationCurrentStreak == medicationCurrentStreak &&
        other.overallTreatmentDays == overallTreatmentDays &&
        other.overallMissedDays == overallMissedDays &&
        other.overallLongestStreak == overallLongestStreak &&
        other.overallCurrentStreak == overallCurrentStreak &&
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
      fluidLongestStreak,
      fluidCurrentStreak,
      medicationMonthlyAdherence,
      medicationLongestStreak,
      medicationCurrentStreak,
      overallTreatmentDays,
      overallMissedDays,
      overallLongestStreak,
      overallCurrentStreak,
    );
  }

  @override
  String toString() {
    return 'MonthlySummary('
        'startDate: $startDate, '
        'endDate: $endDate, '
        'fluidTreatmentDays: $fluidTreatmentDays, '
        'fluidMissedDays: $fluidMissedDays, '
        'fluidLongestStreak: $fluidLongestStreak, '
        'fluidCurrentStreak: $fluidCurrentStreak, '
        'medicationMonthlyAdherence: $medicationMonthlyAdherence, '
        'medicationLongestStreak: $medicationLongestStreak, '
        'medicationCurrentStreak: $medicationCurrentStreak, '
        'overallTreatmentDays: $overallTreatmentDays, '
        'overallMissedDays: $overallMissedDays, '
        'overallLongestStreak: $overallLongestStreak, '
        'overallCurrentStreak: $overallCurrentStreak, '
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
