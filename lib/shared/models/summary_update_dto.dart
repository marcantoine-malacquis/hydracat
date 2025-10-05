import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hydracat/features/logging/models/fluid_session.dart';
import 'package:hydracat/features/logging/models/medication_session.dart';

/// Data Transfer Object for treatment summary updates
///
/// Uses delta-based updates (increments/decrements) instead of absolute values
/// to work seamlessly with Firestore's `FieldValue.increment()` API.
///
/// This enables atomic batch operations without race conditions:
/// - Multiple devices can update simultaneously
/// - No read-modify-write cycles needed
/// - Firestore server handles the arithmetic
///
/// Example usage:
/// ```dart
/// // Create DTO from new session
/// final dto = SummaryUpdateDto.fromMedicationSession(session);
///
/// // Create DTO for session update (calculates deltas)
/// final dto = SummaryUpdateDto.forSessionUpdate(
///   oldSession: oldSession,
///   newSession: newSession,
/// );
///
/// // Convert to Firestore update map
/// final updateMap = dto.toFirestoreUpdate();
/// // { 'medicationTotalDoses': FieldValue.increment(1), ... }
/// ```
@immutable
class SummaryUpdateDto {
  /// Creates a [SummaryUpdateDto] instance
  const SummaryUpdateDto({
    this.medicationDosesDelta,
    this.medicationScheduledDelta,
    this.medicationMissedDelta,
    this.fluidVolumeDelta,
    this.fluidSessionDelta,
    this.overallStreakDelta,
    this.fluidTreatmentDone,
    this.overallTreatmentDone,
  });

  /// Factory constructor to create DTO from a medication session
  ///
  /// For new sessions (not updates):
  /// - `medicationScheduledDelta` is always +1 (one more session logged)
  /// - `medicationDosesDelta` is +1 if completed, 0 if missed
  /// - `medicationMissedDelta` is +1 if missed, 0 if completed
  ///
  /// Example:
  /// ```dart
  /// final session = MedicationSession.create(
  ///   completed: true,
  ///   // ... other fields
  /// );
  /// final dto = SummaryUpdateDto.fromMedicationSession(session);
  /// // dto.medicationDosesDelta = 1
  /// // dto.medicationScheduledDelta = 1
  /// // dto.medicationMissedDelta = 0
  /// ```
  factory SummaryUpdateDto.fromMedicationSession(
    MedicationSession session, {
    bool isUpdate = false,
  }) {
    // For new sessions, always increment scheduled count
    // For updates, don't change scheduled count (already counted)
    final scheduledDelta = isUpdate ? 0 : 1;

    return SummaryUpdateDto(
      medicationDosesDelta: session.completed ? 1 : 0,
      medicationScheduledDelta: scheduledDelta,
      medicationMissedDelta: session.completed ? 0 : 1,
    );
  }

  /// Factory constructor to create DTO from a fluid session
  ///
  /// For new sessions (not updates):
  /// - `fluidVolumeDelta` is the volume given
  /// - `fluidSessionDelta` is always +1 (one more session logged)
  /// - `fluidTreatmentDone` is set to true
  ///
  /// Example:
  /// ```dart
  /// final session = FluidSession.create(
  ///   volumeGiven: 150.0,
  ///   // ... other fields
  /// );
  /// final dto = SummaryUpdateDto.fromFluidSession(session);
  /// // dto.fluidVolumeDelta = 150.0
  /// // dto.fluidSessionDelta = 1
  /// // dto.fluidTreatmentDone = true
  /// ```
  factory SummaryUpdateDto.fromFluidSession(
    FluidSession session, {
    bool isUpdate = false,
  }) {
    // For new sessions, increment session count
    // For updates, don't increment (already counted)
    final sessionDelta = isUpdate ? 0 : 1;

    return SummaryUpdateDto(
      fluidVolumeDelta: session.volumeGiven,
      fluidSessionDelta: sessionDelta,
      fluidTreatmentDone: true,
    );
  }

  /// Factory constructor for medication session updates
  ///
  /// Calculates deltas by comparing old and new session values.
  /// Only includes fields that changed to minimize Firestore write payload.
  ///
  /// Example:
  /// ```dart
  /// // Old session: completed = false (missed)
  /// // New session: completed = true (completed)
  /// final dto = SummaryUpdateDto.forMedicationSessionUpdate(
  ///   oldSession: oldSession,
  ///   newSession: newSession,
  /// );
  /// // dto.medicationDosesDelta = +1 (was 0, now 1)
  /// // dto.medicationMissedDelta = -1 (was 1, now 0)
  /// // dto.medicationScheduledDelta = null (unchanged)
  /// ```
  factory SummaryUpdateDto.forMedicationSessionUpdate({
    required MedicationSession oldSession,
    required MedicationSession newSession,
  }) {
    // Calculate delta for completed doses
    final oldCompleted = oldSession.completed ? 1 : 0;
    final newCompleted = newSession.completed ? 1 : 0;
    final dosesDelta = newCompleted - oldCompleted;

    // Calculate delta for missed doses
    final oldMissed = oldSession.completed ? 0 : 1;
    final newMissed = newSession.completed ? 0 : 1;
    final missedDelta = newMissed - oldMissed;

    return SummaryUpdateDto(
      // Only include deltas that are non-zero
      medicationDosesDelta: dosesDelta != 0 ? dosesDelta : null,
      medicationMissedDelta: missedDelta != 0 ? missedDelta : null,
      // Scheduled count doesn't change on updates (omit null for brevity)
    );
  }

  /// Factory constructor for fluid session updates
  ///
  /// Calculates volume delta by comparing old and new session values.
  /// Session count doesn't change on updates (already logged).
  ///
  /// Example:
  /// ```dart
  /// // Old session: volumeGiven = 100.0ml
  /// // New session: volumeGiven = 150.0ml
  /// final dto = SummaryUpdateDto.forFluidSessionUpdate(
  ///   oldSession: oldSession,
  ///   newSession: newSession,
  /// );
  /// // dto.fluidVolumeDelta = +50.0 (150.0 - 100.0)
  /// // dto.fluidSessionDelta = null (count unchanged)
  /// ```
  factory SummaryUpdateDto.forFluidSessionUpdate({
    required FluidSession oldSession,
    required FluidSession newSession,
  }) {
    // Calculate volume delta
    final volumeDelta = newSession.volumeGiven - oldSession.volumeGiven;

    return SummaryUpdateDto(
      // Only include delta if volume changed
      fluidVolumeDelta: volumeDelta != 0 ? volumeDelta : null,
      // Session count and treatment status don't change on updates
      // (omit null for brevity)
    );
  }

  // Medication Deltas

  /// Change in completed medication doses (+1, -1, or null)
  ///
  /// - +1: Session marked as completed (was missed or new)
  /// - -1: Session marked as missed (was completed)
  /// - null: No change
  final int? medicationDosesDelta;

  /// Change in scheduled medication doses (+1 for new sessions, null for
  /// updates)
  ///
  /// Only incremented when a new session is created, not when updating.
  final int? medicationScheduledDelta;

  /// Change in missed medication doses (+1, -1, or null)
  ///
  /// - +1: Session marked as missed (was completed or new)
  /// - -1: Session marked as completed (was missed)
  /// - null: No change
  final int? medicationMissedDelta;

  // Fluid Deltas

  /// Change in total fluid volume (can be positive or negative)
  ///
  /// - Positive: New session or volume increased
  /// - Negative: Volume decreased on update
  /// - null: No change
  final double? fluidVolumeDelta;

  /// Change in fluid session count (+1 for new sessions, null for updates)
  ///
  /// Only incremented when a new session is created, not when updating.
  final int? fluidSessionDelta;

  // Overall Deltas

  /// Change in overall adherence streak
  ///
  /// - +1: Extended current streak
  /// - Negative: Streak broken
  /// - null: No change
  final int? overallStreakDelta;

  // Boolean Updates (not deltas)

  /// New fluid treatment status (true = at least one session exists)
  ///
  /// Set to true when first fluid session is logged.
  /// Not a delta - this is the new absolute value.
  final bool? fluidTreatmentDone;

  /// New overall treatment status (true = primary treatments completed)
  ///
  /// Set based on user's persona and treatment completion.
  /// Not a delta - this is the new absolute value.
  final bool? overallTreatmentDone;

  // Methods

  /// Converts DTO to Firestore update map with FieldValue.increment()
  ///
  /// Returns a map ready for Firestore batch operations.
  /// Only includes fields with non-null values to minimize payload.
  ///
  /// Example output:
  /// ```dart
  /// {
  ///   'medicationTotalDoses': FieldValue.increment(1),
  ///   'fluidTotalVolume': FieldValue.increment(150.0),
  ///   'fluidTreatmentDone': true,
  ///   'updatedAt': FieldValue.serverTimestamp(),
  /// }
  /// ```
  Map<String, dynamic> toFirestoreUpdate() {
    final update = <String, dynamic>{};

    // Medication deltas
    if (medicationDosesDelta != null) {
      update['medicationTotalDoses'] =
          FieldValue.increment(medicationDosesDelta!);
    }
    if (medicationScheduledDelta != null) {
      update['medicationScheduledDoses'] =
          FieldValue.increment(medicationScheduledDelta!);
    }
    if (medicationMissedDelta != null) {
      update['medicationMissedCount'] =
          FieldValue.increment(medicationMissedDelta!);
    }

    // Fluid deltas
    if (fluidVolumeDelta != null) {
      update['fluidTotalVolume'] = FieldValue.increment(fluidVolumeDelta!);
    }
    if (fluidSessionDelta != null) {
      update['fluidSessionCount'] = FieldValue.increment(fluidSessionDelta!);
    }

    // Overall deltas
    if (overallStreakDelta != null) {
      update['overallStreak'] = FieldValue.increment(overallStreakDelta!);
    }

    // Boolean updates (not deltas)
    if (fluidTreatmentDone != null) {
      update['fluidTreatmentDone'] = fluidTreatmentDone;
    }
    if (overallTreatmentDone != null) {
      update['overallTreatmentDone'] = overallTreatmentDone;
    }

    // Always update timestamp
    update['updatedAt'] = FieldValue.serverTimestamp();

    return update;
  }

  /// Whether this DTO contains any updates
  ///
  /// Returns false if all fields are null (no changes to apply).
  bool get hasUpdates =>
      medicationDosesDelta != null ||
      medicationScheduledDelta != null ||
      medicationMissedDelta != null ||
      fluidVolumeDelta != null ||
      fluidSessionDelta != null ||
      overallStreakDelta != null ||
      fluidTreatmentDone != null ||
      overallTreatmentDone != null;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SummaryUpdateDto &&
        other.medicationDosesDelta == medicationDosesDelta &&
        other.medicationScheduledDelta == medicationScheduledDelta &&
        other.medicationMissedDelta == medicationMissedDelta &&
        other.fluidVolumeDelta == fluidVolumeDelta &&
        other.fluidSessionDelta == fluidSessionDelta &&
        other.overallStreakDelta == overallStreakDelta &&
        other.fluidTreatmentDone == fluidTreatmentDone &&
        other.overallTreatmentDone == overallTreatmentDone;
  }

  @override
  int get hashCode {
    return Object.hash(
      medicationDosesDelta,
      medicationScheduledDelta,
      medicationMissedDelta,
      fluidVolumeDelta,
      fluidSessionDelta,
      overallStreakDelta,
      fluidTreatmentDone,
      overallTreatmentDone,
    );
  }

  @override
  String toString() {
    return 'SummaryUpdateDto('
        'medicationDosesDelta: $medicationDosesDelta, '
        'medicationScheduledDelta: $medicationScheduledDelta, '
        'medicationMissedDelta: $medicationMissedDelta, '
        'fluidVolumeDelta: $fluidVolumeDelta, '
        'fluidSessionDelta: $fluidSessionDelta, '
        'overallStreakDelta: $overallStreakDelta, '
        'fluidTreatmentDone: $fluidTreatmentDone, '
        'overallTreatmentDone: $overallTreatmentDone'
        ')';
  }
}
