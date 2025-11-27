import 'package:flutter/foundation.dart';
import 'package:hydracat/core/utils/date_utils.dart';
import 'package:hydracat/shared/models/treatment_summary_base.dart';

/// Sentinel value for [DailySummary.copyWith] to distinguish between
/// "not provided" and "explicitly set to null"
const _undefined = Object();

/// Daily treatment summary model
///
/// Tracks medication and fluid therapy data for a single day.
/// Used for:
/// - Home screen adherence display
/// - Daily progress tracking
/// - Foundation for weekly/monthly aggregations
///
/// Document ID format: YYYY-MM-DD (e.g., "2025-10-05")
/// Stored in Firestore: `treatmentSummaryDaily/{YYYY-MM-DD}`
@immutable
class DailySummary extends TreatmentSummaryBase {
  /// Creates a [DailySummary] instance
  const DailySummary({
    required this.date,
    required this.overallStreak,
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
    this.fluidDailyGoalMl,
    this.hadVomiting = false,
    this.hadDiarrhea = false,
    this.hadConstipation = false,
    this.hadEnergy = false,
    this.hadSuppressedAppetite = false,
    this.hadInjectionSiteReaction = false,
    this.vomitingMaxScore,
    this.diarrheaMaxScore,
    this.constipationMaxScore,
    this.energyMaxScore,
    this.suppressedAppetiteMaxScore,
    this.injectionSiteReactionMaxScore,
    this.vomitingRawValue,
    this.diarrheaRawValue,
    this.constipationRawValue,
    this.energyRawValue,
    this.suppressedAppetiteRawValue,
    this.injectionSiteReactionRawValue,
    this.symptomScoreTotal,
    this.symptomScoreAverage,
    this.hasSymptoms = false,
  });

  /// Factory constructor to create an empty daily summary
  ///
  /// Use this when initializing a new day's summary with zero sessions.
  /// All counters start at 0, all booleans start at false.
  ///
  /// Example:
  /// ```dart
  /// final summary = DailySummary.empty(DateTime(2025, 10, 5));
  /// // All counts = 0, all booleans = false
  /// ```
  factory DailySummary.empty(DateTime date) {
    final now = DateTime.now();
    return DailySummary(
      date: DateTime(date.year, date.month, date.day),
      overallStreak: 0,
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

  /// Creates a [DailySummary] from JSON data
  ///
  /// Handles Firestore Timestamp conversion for all DateTime fields.
  factory DailySummary.fromJson(Map<String, dynamic> json) {
    // Null-safe parsing with sensible defaults for robustness against
    // partially populated Firestore documents
    final date = json['date'] != null
        ? TreatmentSummaryBase.parseDateTime(json['date'])
        : DateTime.now();

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

    return DailySummary(
      date: date,
      overallStreak: (json['overallStreak'] as num?)?.toInt() ?? 0,
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
      fluidDailyGoalMl: (json['fluidDailyGoalMl'] as num?)?.toInt(),
      hadVomiting: asBool(json['hadVomiting']),
      hadDiarrhea: asBool(json['hadDiarrhea']),
      hadConstipation: asBool(json['hadConstipation']),
      hadEnergy: asBool(json['hadEnergy']),
      hadSuppressedAppetite: asBool(json['hadSuppressedAppetite']),
      hadInjectionSiteReaction: asBool(json['hadInjectionSiteReaction']),
      vomitingMaxScore: (json['vomitingMaxScore'] as num?)?.toInt(),
      diarrheaMaxScore: (json['diarrheaMaxScore'] as num?)?.toInt(),
      constipationMaxScore: (json['constipationMaxScore'] as num?)?.toInt(),
      energyMaxScore: (json['energyMaxScore'] as num?)?.toInt(),
      suppressedAppetiteMaxScore: (json['suppressedAppetiteMaxScore'] as num?)
          ?.toInt(),
      injectionSiteReactionMaxScore:
          (json['injectionSiteReactionMaxScore'] as num?)?.toInt(),
      vomitingRawValue: (json['vomitingRawValue'] as num?)?.toInt(),
      diarrheaRawValue: json['diarrheaRawValue'] as String?,
      constipationRawValue: json['constipationRawValue'] as String?,
      energyRawValue: json['energyRawValue'] as String?,
      suppressedAppetiteRawValue: json['suppressedAppetiteRawValue'] as String?,
      injectionSiteReactionRawValue:
          json['injectionSiteReactionRawValue'] as String?,
      symptomScoreTotal: (json['symptomScoreTotal'] as num?)?.toInt(),
      symptomScoreAverage: (json['symptomScoreAverage'] as num?)?.toDouble(),
      hasSymptoms: asBool(json['hasSymptoms']),
    );
  }

  /// The specific day this summary represents (normalized to midnight)
  ///
  /// Always normalized to 00:00:00 time for consistent comparisons.
  /// Example: DateTime(2025, 10, 5, 0, 0, 0)
  final DateTime date;

  /// Consecutive days of treatment adherence
  ///
  /// Incremented when `overallTreatmentDone == true` and yesterday's
  /// summary also had `overallTreatmentDone == true`.
  /// Reset to 0 when a day is missed.
  final int overallStreak;

  /// Daily fluid goal (in ml) that was active on this date
  ///
  /// Stores the point-in-time daily fluid goal to ensure historical accuracy
  /// when schedules change. Nullable for backward compatibility with old data.
  final int? fluidDailyGoalMl;

  // Symptom tracking fields

  /// Whether vomiting was present (score > 0)
  final bool hadVomiting;

  /// Whether diarrhea was present (score > 0)
  final bool hadDiarrhea;

  /// Whether constipation was present (score > 0)
  final bool hadConstipation;

  /// Whether energy was present (score > 0)
  final bool hadEnergy;

  /// Whether suppressed appetite was present (score > 0)
  final bool hadSuppressedAppetite;

  /// Whether injection site reaction was present (score > 0)
  final bool hadInjectionSiteReaction;

  /// Maximum vomiting score for the day (0-10)
  final int? vomitingMaxScore;

  /// Maximum diarrhea score for the day (0-10)
  final int? diarrheaMaxScore;

  /// Maximum constipation score for the day (0-10)
  final int? constipationMaxScore;

  /// Maximum energy score for the day (0-10)
  final int? energyMaxScore;

  /// Maximum suppressed appetite score for the day (0-10)
  final int? suppressedAppetiteMaxScore;

  /// Maximum injection site reaction score for the day (0-10)
  final int? injectionSiteReactionMaxScore;

  /// Raw value for vomiting (episode count, 0-10+)
  ///
  /// Stores the actual number of vomiting episodes for tooltip display.
  /// Used to show "2 episodes" instead of "Severity 2" in charts.
  final int? vomitingRawValue;

  /// Raw value for diarrhea (enum name: "normal", "soft", "loose", "watery")
  ///
  /// Stores the enum name for tooltip display.
  /// Used to show "Soft" instead of "Severity 1" in charts.
  final String? diarrheaRawValue;

  /// Raw value for constipation (enum name)
  ///
  /// Stores the enum name for tooltip display
  /// (e.g., "mildStraining", "painful").
  final String? constipationRawValue;

  /// Raw value for energy (enum name)
  ///
  /// Stores the enum name for tooltip display (e.g., "slightlyReduced", "low").
  final String? energyRawValue;

  /// Raw value for suppressed appetite (enum name)
  ///
  /// Stores the enum name for tooltip display (e.g., "half", "quarter").
  final String? suppressedAppetiteRawValue;

  /// Raw value for injection site reaction (enum name)
  ///
  /// Stores the enum name for tooltip display
  /// (e.g., "mildSwelling", "redPainful").
  final String? injectionSiteReactionRawValue;

  /// Sum of all present symptom scores (0-60)
  final int? symptomScoreTotal;

  /// Average of present symptom scores (0-10)
  final double? symptomScoreAverage;

  /// Whether any symptom score > 0
  final bool hasSymptoms;

  @override
  String get documentId => AppDateUtils.formatDateForSummary(date);

  /// Whether this summary is for today
  bool get isToday => AppDateUtils.isToday(date);

  /// Whether this summary is for yesterday
  bool get isYesterday => AppDateUtils.isYesterday(date);

  @override
  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'overallStreak': overallStreak,
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
      'fluidDailyGoalMl': fluidDailyGoalMl,
      'hadVomiting': hadVomiting,
      'hadDiarrhea': hadDiarrhea,
      'hadConstipation': hadConstipation,
      'hadEnergy': hadEnergy,
      'hadSuppressedAppetite': hadSuppressedAppetite,
      'hadInjectionSiteReaction': hadInjectionSiteReaction,
      if (vomitingMaxScore != null) 'vomitingMaxScore': vomitingMaxScore,
      if (diarrheaMaxScore != null) 'diarrheaMaxScore': diarrheaMaxScore,
      if (constipationMaxScore != null)
        'constipationMaxScore': constipationMaxScore,
      if (energyMaxScore != null) 'energyMaxScore': energyMaxScore,
      if (suppressedAppetiteMaxScore != null)
        'suppressedAppetiteMaxScore': suppressedAppetiteMaxScore,
      if (injectionSiteReactionMaxScore != null)
        'injectionSiteReactionMaxScore': injectionSiteReactionMaxScore,
      if (vomitingRawValue != null) 'vomitingRawValue': vomitingRawValue,
      if (diarrheaRawValue != null) 'diarrheaRawValue': diarrheaRawValue,
      if (constipationRawValue != null)
        'constipationRawValue': constipationRawValue,
      if (energyRawValue != null) 'energyRawValue': energyRawValue,
      if (suppressedAppetiteRawValue != null)
        'suppressedAppetiteRawValue': suppressedAppetiteRawValue,
      if (injectionSiteReactionRawValue != null)
        'injectionSiteReactionRawValue': injectionSiteReactionRawValue,
      if (symptomScoreTotal != null) 'symptomScoreTotal': symptomScoreTotal,
      if (symptomScoreAverage != null)
        'symptomScoreAverage': symptomScoreAverage,
      'hasSymptoms': hasSymptoms,
    };
  }

  @override
  List<String> validate() {
    final errors = validateBase();

    // Date validation
    if (date.isAfter(DateTime.now())) {
      errors.add('Summary date cannot be in the future');
    }

    // Streak validation
    if (overallStreak < 0) {
      errors.add('Overall streak cannot be negative');
    }

    // Logical consistency
    if (!overallTreatmentDone && overallStreak > 0) {
      errors.add(
        'Streak must be 0 when overall treatment not done',
      );
    }

    return errors;
  }

  /// Creates a copy of this [DailySummary] with the given fields replaced
  DailySummary copyWith({
    DateTime? date,
    int? overallStreak,
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
    Object? fluidDailyGoalMl = _undefined,
    bool? hadVomiting,
    bool? hadDiarrhea,
    bool? hadConstipation,
    bool? hadEnergy,
    bool? hadSuppressedAppetite,
    bool? hadInjectionSiteReaction,
    Object? vomitingMaxScore = _undefined,
    Object? diarrheaMaxScore = _undefined,
    Object? constipationMaxScore = _undefined,
    Object? energyMaxScore = _undefined,
    Object? suppressedAppetiteMaxScore = _undefined,
    Object? injectionSiteReactionMaxScore = _undefined,
    Object? vomitingRawValue = _undefined,
    Object? diarrheaRawValue = _undefined,
    Object? constipationRawValue = _undefined,
    Object? energyRawValue = _undefined,
    Object? suppressedAppetiteRawValue = _undefined,
    Object? injectionSiteReactionRawValue = _undefined,
    Object? symptomScoreTotal = _undefined,
    Object? symptomScoreAverage = _undefined,
    bool? hasSymptoms,
  }) {
    return DailySummary(
      date: date ?? this.date,
      overallStreak: overallStreak ?? this.overallStreak,
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
      fluidDailyGoalMl: fluidDailyGoalMl == _undefined
          ? this.fluidDailyGoalMl
          : fluidDailyGoalMl as int?,
      hadVomiting: hadVomiting ?? this.hadVomiting,
      hadDiarrhea: hadDiarrhea ?? this.hadDiarrhea,
      hadConstipation: hadConstipation ?? this.hadConstipation,
      hadEnergy: hadEnergy ?? this.hadEnergy,
      hadSuppressedAppetite:
          hadSuppressedAppetite ?? this.hadSuppressedAppetite,
      hadInjectionSiteReaction:
          hadInjectionSiteReaction ?? this.hadInjectionSiteReaction,
      vomitingMaxScore: vomitingMaxScore == _undefined
          ? this.vomitingMaxScore
          : vomitingMaxScore as int?,
      diarrheaMaxScore: diarrheaMaxScore == _undefined
          ? this.diarrheaMaxScore
          : diarrheaMaxScore as int?,
      constipationMaxScore: constipationMaxScore == _undefined
          ? this.constipationMaxScore
          : constipationMaxScore as int?,
      energyMaxScore: energyMaxScore == _undefined
          ? this.energyMaxScore
          : energyMaxScore as int?,
      suppressedAppetiteMaxScore: suppressedAppetiteMaxScore == _undefined
          ? this.suppressedAppetiteMaxScore
          : suppressedAppetiteMaxScore as int?,
      injectionSiteReactionMaxScore: injectionSiteReactionMaxScore == _undefined
          ? this.injectionSiteReactionMaxScore
          : injectionSiteReactionMaxScore as int?,
      vomitingRawValue: vomitingRawValue == _undefined
          ? this.vomitingRawValue
          : vomitingRawValue as int?,
      diarrheaRawValue: diarrheaRawValue == _undefined
          ? this.diarrheaRawValue
          : diarrheaRawValue as String?,
      constipationRawValue: constipationRawValue == _undefined
          ? this.constipationRawValue
          : constipationRawValue as String?,
      energyRawValue: energyRawValue == _undefined
          ? this.energyRawValue
          : energyRawValue as String?,
      suppressedAppetiteRawValue: suppressedAppetiteRawValue == _undefined
          ? this.suppressedAppetiteRawValue
          : suppressedAppetiteRawValue as String?,
      injectionSiteReactionRawValue: injectionSiteReactionRawValue == _undefined
          ? this.injectionSiteReactionRawValue
          : injectionSiteReactionRawValue as String?,
      symptomScoreTotal: symptomScoreTotal == _undefined
          ? this.symptomScoreTotal
          : symptomScoreTotal as int?,
      symptomScoreAverage: symptomScoreAverage == _undefined
          ? this.symptomScoreAverage
          : symptomScoreAverage as double?,
      hasSymptoms: hasSymptoms ?? this.hasSymptoms,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DailySummary &&
        other.date == date &&
        other.overallStreak == overallStreak &&
        other.fluidDailyGoalMl == fluidDailyGoalMl &&
        other.hadVomiting == hadVomiting &&
        other.hadDiarrhea == hadDiarrhea &&
        other.hadConstipation == hadConstipation &&
        other.hadEnergy == hadEnergy &&
        other.hadSuppressedAppetite == hadSuppressedAppetite &&
        other.hadInjectionSiteReaction == hadInjectionSiteReaction &&
        other.vomitingMaxScore == vomitingMaxScore &&
        other.diarrheaMaxScore == diarrheaMaxScore &&
        other.constipationMaxScore == constipationMaxScore &&
        other.energyMaxScore == energyMaxScore &&
        other.suppressedAppetiteMaxScore == suppressedAppetiteMaxScore &&
        other.injectionSiteReactionMaxScore == injectionSiteReactionMaxScore &&
        other.vomitingRawValue == vomitingRawValue &&
        other.diarrheaRawValue == diarrheaRawValue &&
        other.constipationRawValue == constipationRawValue &&
        other.energyRawValue == energyRawValue &&
        other.suppressedAppetiteRawValue == suppressedAppetiteRawValue &&
        other.injectionSiteReactionRawValue == injectionSiteReactionRawValue &&
        other.symptomScoreTotal == symptomScoreTotal &&
        other.symptomScoreAverage == symptomScoreAverage &&
        other.hasSymptoms == hasSymptoms &&
        super == other;
  }

  @override
  int get hashCode {
    return Object.hashAll([
      super.hashCode,
      date,
      overallStreak,
      fluidDailyGoalMl,
      hadVomiting,
      hadDiarrhea,
      hadConstipation,
      hadEnergy,
      hadSuppressedAppetite,
      hadInjectionSiteReaction,
      vomitingMaxScore,
      diarrheaMaxScore,
      constipationMaxScore,
      energyMaxScore,
      suppressedAppetiteMaxScore,
      injectionSiteReactionMaxScore,
      vomitingRawValue,
      diarrheaRawValue,
      constipationRawValue,
      energyRawValue,
      suppressedAppetiteRawValue,
      injectionSiteReactionRawValue,
      symptomScoreTotal,
      symptomScoreAverage,
      hasSymptoms,
    ]);
  }

  @override
  String toString() {
    return 'DailySummary('
        'date: $date, '
        'overallStreak: $overallStreak, '
        'medicationTotalDoses: $medicationTotalDoses, '
        'medicationScheduledDoses: $medicationScheduledDoses, '
        'medicationMissedCount: $medicationMissedCount, '
        'fluidTotalVolume: $fluidTotalVolume, '
        'fluidTreatmentDone: $fluidTreatmentDone, '
        'fluidSessionCount: $fluidSessionCount, '
        'overallTreatmentDone: $overallTreatmentDone, '
        'createdAt: $createdAt, '
        'updatedAt: $updatedAt, '
        'fluidDailyGoalMl: $fluidDailyGoalMl, '
        'hadVomiting: $hadVomiting, '
        'hadDiarrhea: $hadDiarrhea, '
        'hadConstipation: $hadConstipation, '
        'hadEnergy: $hadEnergy, '
        'hadSuppressedAppetite: $hadSuppressedAppetite, '
        'hadInjectionSiteReaction: $hadInjectionSiteReaction, '
        'vomitingMaxScore: $vomitingMaxScore, '
        'diarrheaMaxScore: $diarrheaMaxScore, '
        'constipationMaxScore: $constipationMaxScore, '
        'energyMaxScore: $energyMaxScore, '
        'suppressedAppetiteMaxScore: $suppressedAppetiteMaxScore, '
        'injectionSiteReactionMaxScore: $injectionSiteReactionMaxScore, '
        'vomitingRawValue: $vomitingRawValue, '
        'diarrheaRawValue: $diarrheaRawValue, '
        'constipationRawValue: $constipationRawValue, '
        'energyRawValue: $energyRawValue, '
        'suppressedAppetiteRawValue: $suppressedAppetiteRawValue, '
        'injectionSiteReactionRawValue: $injectionSiteReactionRawValue, '
        'symptomScoreTotal: $symptomScoreTotal, '
        'symptomScoreAverage: $symptomScoreAverage, '
        'hasSymptoms: $hasSymptoms'
        ')';
  }
}
