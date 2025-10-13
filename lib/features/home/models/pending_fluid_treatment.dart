import 'package:flutter/foundation.dart';
import 'package:hydracat/core/utils/date_utils.dart';
import 'package:hydracat/features/profile/models/schedule.dart';

/// Value object representing today's aggregated fluid therapy status
/// and remaining volume for the dashboard.
@immutable
class PendingFluidTreatment {
  /// Creates a [PendingFluidTreatment]
  const PendingFluidTreatment({
    required this.schedule,
    required this.remainingVolume,
    required this.scheduledTimes,
    required this.hasOverdueTimes,
  });

  /// Fluid schedule reference
  final Schedule schedule;

  /// Remaining volume to be administered today (ml)
  final double remainingVolume;

  /// All reminder times for today
  final List<DateTime> scheduledTimes;

  /// Whether any of the scheduled times are overdue
  final bool hasOverdueTimes;

  /// Display text for remaining volume (e.g., "200mL remaining")
  String get displayVolume => '${remainingVolume.toInt()}mL remaining';

  /// Display text for times (e.g., "08:00, 20:00")
  String get displayTimes =>
      scheduledTimes.map(AppDateUtils.formatTime).join(', ');

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PendingFluidTreatment &&
            other.schedule.id == schedule.id &&
            other.remainingVolume == remainingVolume);
  }

  @override
  int get hashCode => Object.hash(schedule.id, remainingVolume);
}
