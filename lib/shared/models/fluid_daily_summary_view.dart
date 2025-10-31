import 'package:flutter/foundation.dart';

/// Lightweight view model for a day's fluid summary
@immutable
class FluidDailySummaryView {
  /// Creates a view model for a day's fluid totals and goal.
  const FluidDailySummaryView({
    required this.givenMl,
    required this.goalMl,
    required this.isToday,
  });

  /// Total fluid given that day (in ml)
  final int givenMl;

  /// Goal volume for that day (in ml)
  final int goalMl;

  /// Whether the represented day is today (affects status semantics)
  final bool isToday;

  /// Whether goal has been reached or exceeded
  bool get hasReachedGoal => givenMl >= goalMl && goalMl > 0;

  /// Difference: positive when goal not yet reached (ml left),
  /// negative when exceeded (ml over)
  int get deltaMl => goalMl - givenMl;
}
