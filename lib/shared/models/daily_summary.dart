import 'package:flutter/foundation.dart';
import 'package:hydracat/core/utils/date_utils.dart';
import 'package:hydracat/shared/models/treatment_summary_base.dart';

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
    required super.overallTreatmentDone,
    required super.createdAt,
    super.updatedAt,
    this.fluidDailyGoalMl,
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
      overallTreatmentDone: asBool(json['overallTreatmentDone']),
      createdAt:
          TreatmentSummaryBase.parseDateTimeNullable(json['createdAt']) ??
          DateTime.now(),
      updatedAt: TreatmentSummaryBase.parseDateTimeNullable(json['updatedAt']),
      fluidDailyGoalMl: (json['fluidDailyGoalMl'] as num?)?.toInt(),
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
      'overallTreatmentDone': overallTreatmentDone,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'fluidDailyGoalMl': fluidDailyGoalMl,
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
    bool? overallTreatmentDone,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? fluidDailyGoalMl,
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
      overallTreatmentDone: overallTreatmentDone ?? this.overallTreatmentDone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      fluidDailyGoalMl: fluidDailyGoalMl ?? this.fluidDailyGoalMl,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DailySummary &&
        other.date == date &&
        other.overallStreak == overallStreak &&
        other.fluidDailyGoalMl == fluidDailyGoalMl &&
        super == other;
  }

  @override
  int get hashCode {
    return Object.hash(
      super.hashCode,
      date,
      overallStreak,
      fluidDailyGoalMl,
    );
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
        'fluidDailyGoalMl: $fluidDailyGoalMl'
        ')';
  }
}
