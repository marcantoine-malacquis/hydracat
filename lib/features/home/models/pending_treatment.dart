import 'package:flutter/foundation.dart';
import 'package:hydracat/core/utils/date_utils.dart';
import 'package:hydracat/core/utils/dosage_text_utils.dart';
import 'package:hydracat/core/utils/medication_unit_utils.dart';
import 'package:hydracat/features/profile/models/schedule.dart';

/// Value object representing a single scheduled medication occurrence
/// pending for today on the dashboard.
@immutable
class PendingTreatment {
  /// Creates a [PendingTreatment]
  const PendingTreatment({
    required this.schedule,
    required this.scheduledTime,
    required this.isOverdue,
  });

  /// Medication schedule reference (must be a medication schedule)
  final Schedule schedule;

  /// The specific reminder time represented by this pending treatment
  final DateTime scheduledTime;

  /// Whether this scheduled time is overdue per dashboard rules
  final bool isOverdue;

  /// Display name for UI (medication name)
  String get displayName => schedule.medicationName!;

  /// Display dosage with human-friendly unit short form
  String get displayDosage => DosageTextUtils.formatDosageWithUnit(
    schedule.targetDosage!,
    MedicationUnitUtils.shortForm(schedule.medicationUnit!),
  );

  /// Display time (HH:mm by default)
  String get displayTime => AppDateUtils.formatTime(scheduledTime);

  /// Optional medication strength text (e.g., "2.5 mg")
  String? get displayStrength => schedule.formattedStrength;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PendingTreatment &&
            other.schedule.id == schedule.id &&
            other.scheduledTime == scheduledTime);
  }

  @override
  int get hashCode => Object.hash(schedule.id, scheduledTime);
}
