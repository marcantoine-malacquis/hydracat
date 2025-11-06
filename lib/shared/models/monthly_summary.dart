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
    this.weightEntriesCount = 0,
    this.weightLatest,
    this.weightLatestDate,
    this.weightFirst,
    this.weightFirstDate,
    this.weightAverage,
    this.weightChange,
    this.weightChangePercent,
    this.weightTrend,
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

    return MonthlySummary(
      startDate: TreatmentSummaryBase.parseDateTime(json['startDate']),
      endDate: TreatmentSummaryBase.parseDateTime(json['endDate']),
      fluidTreatmentDays: (json['fluidTreatmentDays'] as num?)?.toInt() ?? 0,
      fluidMissedDays: (json['fluidMissedDays'] as num?)?.toInt() ?? 0,
      fluidLongestStreak: (json['fluidLongestStreak'] as num?)?.toInt() ?? 0,
      fluidCurrentStreak: (json['fluidCurrentStreak'] as num?)?.toInt() ?? 0,
      medicationMonthlyAdherence:
          (json['medicationMonthlyAdherence'] as num?)?.toDouble() ?? 0.0,
      medicationLongestStreak:
          (json['medicationLongestStreak'] as num?)?.toInt() ?? 0,
      medicationCurrentStreak:
          (json['medicationCurrentStreak'] as num?)?.toInt() ?? 0,
      overallTreatmentDays:
          (json['overallTreatmentDays'] as num?)?.toInt() ?? 0,
      overallMissedDays: (json['overallMissedDays'] as num?)?.toInt() ?? 0,
      overallLongestStreak:
          (json['overallLongestStreak'] as num?)?.toInt() ?? 0,
      overallCurrentStreak:
          (json['overallCurrentStreak'] as num?)?.toInt() ?? 0,
      medicationTotalDoses:
          (json['medicationTotalDoses'] as num?)?.toInt() ?? 0,
      medicationScheduledDoses:
          (json['medicationScheduledDoses'] as num?)?.toInt() ?? 0,
      medicationMissedCount:
          (json['medicationMissedCount'] as num?)?.toInt() ?? 0,
      fluidTotalVolume: (json['fluidTotalVolume'] as num?)?.toDouble() ?? 0.0,
      fluidTreatmentDone: asBool(json['fluidTreatmentDone']),
      fluidSessionCount: (json['fluidSessionCount'] as num?)?.toInt() ?? 0,
      overallTreatmentDone: asBool(json['overallTreatmentDone']),
      createdAt:
          TreatmentSummaryBase.parseDateTimeNullable(json['createdAt']) ??
          DateTime.now(),
      updatedAt: TreatmentSummaryBase.parseDateTimeNullable(json['updatedAt']),
      weightEntriesCount: (json['weightEntriesCount'] as num?)?.toInt() ?? 0,
      weightLatest: (json['weightLatest'] as num?)?.toDouble(),
      weightLatestDate: TreatmentSummaryBase.parseDateTimeNullable(
        json['weightLatestDate'],
      ),
      weightFirst: (json['weightFirst'] as num?)?.toDouble(),
      weightFirstDate: TreatmentSummaryBase.parseDateTimeNullable(
        json['weightFirstDate'],
      ),
      weightAverage: (json['weightAverage'] as num?)?.toDouble(),
      weightChange: (json['weightChange'] as num?)?.toDouble(),
      weightChangePercent: (json['weightChangePercent'] as num?)?.toDouble(),
      weightTrend: json['weightTrend'] as String?,
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

  /// Number of weight entries logged this month
  final int weightEntriesCount;

  /// Most recent weight value (kg)
  final double? weightLatest;

  /// Date when latest weight was recorded
  final DateTime? weightLatestDate;

  /// First weight of the month (kg)
  final double? weightFirst;

  /// Date of first weight entry this month
  final DateTime? weightFirstDate;

  /// Average weight for the month (kg)
  final double? weightAverage;

  /// Change from previous month (kg)
  /// Positive = gained, negative = lost
  final double? weightChange;

  /// Percentage change from previous month
  final double? weightChangePercent;

  /// Trend indicator: "increasing", "stable", "decreasing"
  final String? weightTrend;

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
      'weightEntriesCount': weightEntriesCount,
      if (weightLatest != null) 'weightLatest': weightLatest,
      if (weightLatestDate != null)
        'weightLatestDate': weightLatestDate!.toIso8601String(),
      if (weightFirst != null) 'weightFirst': weightFirst,
      if (weightFirstDate != null)
        'weightFirstDate': weightFirstDate!.toIso8601String(),
      if (weightAverage != null) 'weightAverage': weightAverage,
      if (weightChange != null) 'weightChange': weightChange,
      if (weightChangePercent != null)
        'weightChangePercent': weightChangePercent,
      if (weightTrend != null) 'weightTrend': weightTrend,
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
    if (startDate.year != endDate.year || startDate.month != endDate.month) {
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
    if (medicationMonthlyAdherence < 0.0 || medicationMonthlyAdherence > 1.0) {
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
    int? weightEntriesCount,
    double? weightLatest,
    DateTime? weightLatestDate,
    double? weightFirst,
    DateTime? weightFirstDate,
    double? weightAverage,
    double? weightChange,
    double? weightChangePercent,
    String? weightTrend,
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
      overallTreatmentDays: overallTreatmentDays ?? this.overallTreatmentDays,
      overallMissedDays: overallMissedDays ?? this.overallMissedDays,
      overallLongestStreak: overallLongestStreak ?? this.overallLongestStreak,
      overallCurrentStreak: overallCurrentStreak ?? this.overallCurrentStreak,
      medicationTotalDoses: medicationTotalDoses ?? this.medicationTotalDoses,
      medicationScheduledDoses:
          medicationScheduledDoses ?? this.medicationScheduledDoses,
      medicationMissedCount:
          medicationMissedCount ?? this.medicationMissedCount,
      fluidTotalVolume: fluidTotalVolume ?? this.fluidTotalVolume,
      fluidTreatmentDone: fluidTreatmentDone ?? this.fluidTreatmentDone,
      fluidSessionCount: fluidSessionCount ?? this.fluidSessionCount,
      overallTreatmentDone: overallTreatmentDone ?? this.overallTreatmentDone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      weightEntriesCount: weightEntriesCount ?? this.weightEntriesCount,
      weightLatest: weightLatest ?? this.weightLatest,
      weightLatestDate: weightLatestDate ?? this.weightLatestDate,
      weightFirst: weightFirst ?? this.weightFirst,
      weightFirstDate: weightFirstDate ?? this.weightFirstDate,
      weightAverage: weightAverage ?? this.weightAverage,
      weightChange: weightChange ?? this.weightChange,
      weightChangePercent: weightChangePercent ?? this.weightChangePercent,
      weightTrend: weightTrend ?? this.weightTrend,
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
        other.weightEntriesCount == weightEntriesCount &&
        other.weightLatest == weightLatest &&
        other.weightLatestDate == weightLatestDate &&
        other.weightFirst == weightFirst &&
        other.weightFirstDate == weightFirstDate &&
        other.weightAverage == weightAverage &&
        other.weightChange == weightChange &&
        other.weightChangePercent == weightChangePercent &&
        other.weightTrend == weightTrend &&
        super == other;
  }

  @override
  int get hashCode {
    return Object.hashAll([
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
      weightEntriesCount,
      weightLatest,
      weightLatestDate,
      weightFirst,
      weightFirstDate,
      weightAverage,
      weightChange,
      weightChangePercent,
      weightTrend,
    ]);
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
        'updatedAt: $updatedAt, '
        'weightEntriesCount: $weightEntriesCount, '
        'weightLatest: $weightLatest, '
        'weightLatestDate: $weightLatestDate, '
        'weightFirst: $weightFirst, '
        'weightFirstDate: $weightFirstDate, '
        'weightAverage: $weightAverage, '
        'weightChange: $weightChange, '
        'weightChangePercent: $weightChangePercent, '
        'weightTrend: $weightTrend'
        ')';
  }
}
