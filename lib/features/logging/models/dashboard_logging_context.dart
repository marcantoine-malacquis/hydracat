import 'package:flutter/foundation.dart';

/// Context data for opening medication logging from the dashboard.
///
/// Contains the schedule ID and scheduled time for a specific pending
/// medication treatment, allowing the logging screen to pre-select the
/// medication and use the correct scheduled time.
@immutable
class DashboardMedicationContext {
  /// Creates a [DashboardMedicationContext].
  const DashboardMedicationContext({
    required this.scheduleId,
    required this.scheduledTime,
  });

  /// The schedule ID of the medication to pre-select
  final String scheduleId;

  /// The specific scheduled time for this reminder occurrence
  final DateTime scheduledTime;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DashboardMedicationContext &&
        other.scheduleId == scheduleId &&
        other.scheduledTime == scheduledTime;
  }

  @override
  int get hashCode => Object.hash(scheduleId, scheduledTime);
}

/// Context data for opening fluid logging from the dashboard.
///
/// Contains the schedule ID and remaining volume for today, allowing the
/// logging screen to pre-fill the volume input with the remaining amount.
@immutable
class DashboardFluidContext {
  /// Creates a [DashboardFluidContext].
  const DashboardFluidContext({
    required this.scheduleId,
    required this.remainingVolume,
  });

  /// The schedule ID of the fluid schedule
  final String scheduleId;

  /// The remaining volume for today (in mL)
  final double remainingVolume;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DashboardFluidContext &&
        other.scheduleId == scheduleId &&
        other.remainingVolume == remainingVolume;
  }

  @override
  int get hashCode => Object.hash(scheduleId, remainingVolume);
}
