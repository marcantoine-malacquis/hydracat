import 'package:flutter/foundation.dart';

/// Lightweight view model for a day's medication summary
@immutable
class MedicationDailySummaryView {
  /// Creates a view model for a day's medication doses and goal.
  const MedicationDailySummaryView({
    required this.completedDoses,
    required this.scheduledDoses,
    required this.isToday,
  });

  /// Number of medication doses completed that day
  final int completedDoses;

  /// Number of medication doses scheduled for that day
  final int scheduledDoses;

  /// Whether the represented day is today (affects status semantics)
  final bool isToday;

  /// Whether goal has been reached (all scheduled doses completed)
  bool get hasReachedGoal =>
      scheduledDoses > 0 && completedDoses >= scheduledDoses;

  /// Number of doses remaining (positive when not yet reached)
  int get remainingDoses => scheduledDoses - completedDoses;

  /// Number of doses missed (for past days only)
  int get missedDoses =>
      scheduledDoses > 0 && !isToday && !hasReachedGoal ? remainingDoses : 0;
}
