import 'package:flutter/widgets.dart';
import 'package:hydracat/core/utils/date_utils.dart';
import 'package:hydracat/core/utils/dosage_text_utils.dart';
import 'package:hydracat/core/utils/medication_unit_utils.dart';
import 'package:hydracat/features/profile/models/schedule.dart';
import 'package:hydracat/l10n/app_localizations.dart';

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

  /// Display dosage with human-friendly unit short form (legacy fallback).
  ///
  /// For localized display, prefer [getLocalizedDosage] which uses ICU
  /// plural format.
  String get displayDosage => DosageTextUtils.formatDosageWithUnit(
    schedule.targetDosage!,
    MedicationUnitUtils.shortForm(schedule.medicationUnit!),
  );

  /// Returns localized dosage text with proper pluralization.
  ///
  /// Uses ICU message format for internationalization:
  /// - 1 + "sachets" → "1 Sachet"
  /// - 2 + "sachets" → "2 Sachets"
  /// - 0.5 + "pills" → "0.5 pills"
  ///
  /// Example:
  /// ```dart
  /// final dosage = treatment.getLocalizedDosage(context);
  /// ```
  String getLocalizedDosage(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DosageTextUtils.formatDosageWithUnit(
      schedule.targetDosage!,
      MedicationUnitUtils.shortForm(schedule.medicationUnit!),
      l10n: l10n,
    );
  }

  /// Whether this is a flexible medication (no specific reminder time)
  ///
  /// Flexible medications appear in the pending list but without a specific
  /// time, allowing users to log them whenever needed throughout the day.
  bool get isFlexible => schedule.reminderTimes.isEmpty;

  /// Display time (HH:mm by default, or null for flexible medications)
  ///
  /// Returns null for flexible medications (those with no reminder times).
  /// UI should display localized "No time set" text when null.
  String? get displayTime {
    if (isFlexible) {
      return null; // UI will show localized "No time set"
    }
    return AppDateUtils.formatTime(scheduledTime);
  }

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
