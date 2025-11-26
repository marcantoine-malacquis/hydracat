import 'package:flutter/foundation.dart';
import 'package:hydracat/core/utils/date_utils.dart';
import 'package:hydracat/shared/models/treatment_summary_base.dart';

/// Sentinel value for [MonthlySummary.copyWith] to distinguish between
/// "not provided" and "explicitly set to null"
const _undefined = Object();

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
    required super.fluidScheduledSessions,
    required super.overallTreatmentDone,
    required super.createdAt,
    this.startDate,
    this.endDate,
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
    this.daysWithVomiting = 0,
    this.daysWithDiarrhea = 0,
    this.daysWithConstipation = 0,
    this.daysWithLethargy = 0,
    this.daysWithSuppressedAppetite = 0,
    this.daysWithInjectionSiteReaction = 0,
    this.daysWithAnySymptoms = 0,
    this.symptomScoreTotal,
    this.symptomScoreAverage,
    this.symptomScoreMax,
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
      fluidScheduledSessions: 0,
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
      fluidScheduledSessions:
          (json['fluidScheduledSessions'] as num?)?.toInt() ?? 0,
      overallTreatmentDone: asBool(json['overallTreatmentDone']),
      createdAt:
          TreatmentSummaryBase.parseDateTimeNullable(json['createdAt']) ??
          DateTime.now(),
      startDate: TreatmentSummaryBase.parseDateTimeNullable(json['startDate']),
      endDate: TreatmentSummaryBase.parseDateTimeNullable(json['endDate']),
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
      daysWithVomiting: (json['daysWithVomiting'] as num?)?.toInt() ?? 0,
      daysWithDiarrhea: (json['daysWithDiarrhea'] as num?)?.toInt() ?? 0,
      daysWithConstipation:
          (json['daysWithConstipation'] as num?)?.toInt() ?? 0,
      daysWithLethargy: (json['daysWithLethargy'] as num?)?.toInt() ?? 0,
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

  /// First day of the month (00:00:00)
  ///
  /// Nullable for backward compatibility with legacy data that may not have
  /// this field. New summaries should always include start and end dates.
  final DateTime? startDate;

  /// Last day of the month (23:59:59)
  ///
  /// Nullable for backward compatibility with legacy data that may not have
  /// this field. New summaries should always include start and end dates.
  final DateTime? endDate;

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

  // Symptom tracking fields

  /// Number of days with vomiting present (score > 0)
  final int daysWithVomiting;

  /// Number of days with diarrhea present (score > 0)
  final int daysWithDiarrhea;

  /// Number of days with constipation present (score > 0)
  final int daysWithConstipation;

  /// Number of days with lethargy present (score > 0)
  final int daysWithLethargy;

  /// Number of days with suppressed appetite present (score > 0)
  final int daysWithSuppressedAppetite;

  /// Number of days with injection site reaction present (score > 0)
  final int daysWithInjectionSiteReaction;

  /// Number of days with any symptoms present (hasSymptoms == true)
  final int daysWithAnySymptoms;

  /// Sum of daily symptomScoreTotal over the month (0-1860 for 31 days with
  /// max 60 each)
  final int? symptomScoreTotal;

  /// Average daily symptom score across days with any symptoms (0-10)
  final double? symptomScoreAverage;

  /// Maximum daily symptomScoreTotal in the month (0-60)
  final int? symptomScoreMax;

  @override
  String get documentId =>
      AppDateUtils.formatMonthForSummary(startDate ?? DateTime.now());

  /// Whether this month is the current month
  bool get isCurrentMonth {
    if (startDate == null) return false;
    final now = DateTime.now();
    return now.year == startDate!.year && now.month == startDate!.month;
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
    if (endDate == null) return 30; // Default fallback
    return endDate!.day; // Last day of month = number of days
  }

  /// Whether any symptoms were logged this month
  bool get hadSymptomsThisMonth => daysWithAnySymptoms > 0;

  @override
  Map<String, dynamic> toJson() {
    return {
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
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
      'fluidScheduledSessions': fluidScheduledSessions,
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
      'daysWithVomiting': daysWithVomiting,
      'daysWithDiarrhea': daysWithDiarrhea,
      'daysWithConstipation': daysWithConstipation,
      'daysWithLethargy': daysWithLethargy,
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

    // Date validation
    if (startDate == null || endDate == null) {
      errors.add('Start date and end date are required');
      return errors; // Skip further date validation if dates are missing
    }

    if (endDate!.isBefore(startDate!)) {
      errors.add('End date must be after start date');
    }

    // Month validation (both dates must be in same month)
    if (startDate!.year != endDate!.year ||
        startDate!.month != endDate!.month) {
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
    int? fluidScheduledSessions,
    bool? overallTreatmentDone,
    DateTime? createdAt,
    Object? updatedAt = _undefined,
    int? weightEntriesCount,
    Object? weightLatest = _undefined,
    Object? weightLatestDate = _undefined,
    Object? weightFirst = _undefined,
    Object? weightFirstDate = _undefined,
    Object? weightAverage = _undefined,
    Object? weightChange = _undefined,
    Object? weightChangePercent = _undefined,
    Object? weightTrend = _undefined,
    int? daysWithVomiting,
    int? daysWithDiarrhea,
    int? daysWithConstipation,
    int? daysWithLethargy,
    int? daysWithSuppressedAppetite,
    int? daysWithInjectionSiteReaction,
    int? daysWithAnySymptoms,
    Object? symptomScoreTotal = _undefined,
    Object? symptomScoreAverage = _undefined,
    Object? symptomScoreMax = _undefined,
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
      fluidScheduledSessions:
          fluidScheduledSessions ?? this.fluidScheduledSessions,
      overallTreatmentDone: overallTreatmentDone ?? this.overallTreatmentDone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt == _undefined
          ? this.updatedAt
          : updatedAt as DateTime?,
      weightEntriesCount: weightEntriesCount ?? this.weightEntriesCount,
      weightLatest: weightLatest == _undefined
          ? this.weightLatest
          : weightLatest as double?,
      weightLatestDate: weightLatestDate == _undefined
          ? this.weightLatestDate
          : weightLatestDate as DateTime?,
      weightFirst: weightFirst == _undefined
          ? this.weightFirst
          : weightFirst as double?,
      weightFirstDate: weightFirstDate == _undefined
          ? this.weightFirstDate
          : weightFirstDate as DateTime?,
      weightAverage: weightAverage == _undefined
          ? this.weightAverage
          : weightAverage as double?,
      weightChange: weightChange == _undefined
          ? this.weightChange
          : weightChange as double?,
      weightChangePercent: weightChangePercent == _undefined
          ? this.weightChangePercent
          : weightChangePercent as double?,
      weightTrend: weightTrend == _undefined
          ? this.weightTrend
          : weightTrend as String?,
      daysWithVomiting: daysWithVomiting ?? this.daysWithVomiting,
      daysWithDiarrhea: daysWithDiarrhea ?? this.daysWithDiarrhea,
      daysWithConstipation: daysWithConstipation ?? this.daysWithConstipation,
      daysWithLethargy: daysWithLethargy ?? this.daysWithLethargy,
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
        other.daysWithVomiting == daysWithVomiting &&
        other.daysWithDiarrhea == daysWithDiarrhea &&
        other.daysWithConstipation == daysWithConstipation &&
        other.daysWithLethargy == daysWithLethargy &&
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
      daysWithVomiting,
      daysWithDiarrhea,
      daysWithConstipation,
      daysWithLethargy,
      daysWithSuppressedAppetite,
      daysWithInjectionSiteReaction,
      daysWithAnySymptoms,
      symptomScoreTotal,
      symptomScoreAverage,
      symptomScoreMax,
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
        'weightTrend: $weightTrend, '
        'daysWithVomiting: $daysWithVomiting, '
        'daysWithDiarrhea: $daysWithDiarrhea, '
        'daysWithConstipation: $daysWithConstipation, '
        'daysWithLethargy: $daysWithLethargy, '
        'daysWithSuppressedAppetite: $daysWithSuppressedAppetite, '
        'daysWithInjectionSiteReaction: $daysWithInjectionSiteReaction, '
        'daysWithAnySymptoms: $daysWithAnySymptoms, '
        'symptomScoreTotal: $symptomScoreTotal, '
        'symptomScoreAverage: $symptomScoreAverage, '
        'symptomScoreMax: $symptomScoreMax'
        ')';
  }
}
