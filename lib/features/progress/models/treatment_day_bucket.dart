import 'package:flutter/foundation.dart';

/// Represents combined fluid + medication data for a single calendar day.
///
/// Built from monthly summary arrays and used by month view providers to
/// render calendar dots and the 31-bar chart without additional reads.
@immutable
class TreatmentDayBucket {
  /// Creates a [TreatmentDayBucket].
  const TreatmentDayBucket({
    required this.date,
    required this.fluidVolumeMl,
    required this.fluidGoalMl,
    required this.fluidScheduledSessions,
    required this.medicationDoses,
    required this.medicationScheduledDoses,
  });

  /// Calendar date (normalized to start of day).
  final DateTime date;

  /// Total fluid volume logged for the day (ml).
  final int fluidVolumeMl;

  /// Fluid goal for the day (ml).
  final int fluidGoalMl;

  /// Number of scheduled fluid sessions for the day.
  final int fluidScheduledSessions;

  /// Completed medication doses for the day.
  final int medicationDoses;

  /// Scheduled medication doses for the day.
  final int medicationScheduledDoses;

  /// Whether any treatment (fluid or medication) was scheduled.
  bool get hasScheduledTreatments =>
      hasFluidScheduled || hasMedicationScheduled;

  /// Whether fluid sessions were scheduled.
  bool get hasFluidScheduled => fluidScheduledSessions > 0;

  /// Whether medication doses were scheduled.
  bool get hasMedicationScheduled => medicationScheduledDoses > 0;

  bool get _isBeforeToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return date.isBefore(today);
  }

  /// Whether fluid treatments met their goal.
  bool get isFluidComplete {
    if (!hasFluidScheduled) return true;
    if (fluidGoalMl <= 0) {
      return fluidVolumeMl > 0;
    }
    return fluidVolumeMl >= fluidGoalMl;
  }

  /// Whether medication treatments met scheduled doses.
  bool get isMedicationComplete {
    if (!hasMedicationScheduled) return true;
    return medicationDoses >= medicationScheduledDoses;
  }

  /// Whether fluid treatment was missed (past day with incomplete fluid).
  bool get isFluidMissed =>
      _isBeforeToday && hasFluidScheduled && !isFluidComplete;

  /// Whether medication treatment was missed (past day with incomplete doses).
  bool get isMedicationMissed =>
      _isBeforeToday && hasMedicationScheduled && !isMedicationComplete;

  /// Combined missed flag (either treatment missed).
  bool get isMissed => isFluidMissed || isMedicationMissed;

  /// Combined completion flag (all scheduled treatments complete).
  bool get isComplete =>
      hasScheduledTreatments && isFluidComplete && isMedicationComplete;

  /// Whether this bucket represents today.
  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Whether today still has pending treatments.
  bool get isPending => isToday && hasScheduledTreatments && !isComplete;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TreatmentDayBucket &&
          date.isAtSameMomentAs(other.date) &&
          fluidVolumeMl == other.fluidVolumeMl &&
          fluidGoalMl == other.fluidGoalMl &&
          fluidScheduledSessions == other.fluidScheduledSessions &&
          medicationDoses == other.medicationDoses &&
          medicationScheduledDoses == other.medicationScheduledDoses;

  @override
  int get hashCode => Object.hash(
        date,
        fluidVolumeMl,
        fluidGoalMl,
        fluidScheduledSessions,
        medicationDoses,
        medicationScheduledDoses,
      );

  @override
  String toString() => 'TreatmentDayBucket('
      'date: $date, '
      'fluidVolumeMl: $fluidVolumeMl, '
      'fluidGoalMl: $fluidGoalMl, '
      'fluidScheduledSessions: $fluidScheduledSessions, '
      'medicationDoses: $medicationDoses, '
      'medicationScheduledDoses: $medicationScheduledDoses'
      ')';
}
