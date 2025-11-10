import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Abstract base class for treatment summary models
///
/// Provides shared fields and logic for daily, weekly, and monthly summaries.
/// Cannot be instantiated directly - use DailySummary, WeeklySummary,
/// or MonthlySummary subclasses instead.
///
/// All summaries track:
/// - Medication adherence (doses given vs scheduled)
/// - Fluid therapy volume and sessions
/// - Overall treatment completion status
@immutable
abstract class TreatmentSummaryBase {
  /// Creates a [TreatmentSummaryBase] instance
  const TreatmentSummaryBase({
    required this.medicationTotalDoses,
    required this.medicationScheduledDoses,
    required this.medicationMissedCount,
    required this.fluidTotalVolume,
    required this.fluidTreatmentDone,
    required this.fluidSessionCount,
    required this.fluidScheduledSessions,
    required this.overallTreatmentDone,
    required this.createdAt,
    this.updatedAt,
  });

  // Medication Fields

  /// Total number of completed medication doses
  ///
  /// Incremented when `MedicationSession.completed == true`.
  /// Used for adherence calculations.
  final int medicationTotalDoses;

  /// Total number of scheduled medication doses
  ///
  /// Incremented for every medication session logged, regardless of
  /// completion status. Used as denominator for adherence percentage.
  final int medicationScheduledDoses;

  /// Count of missed medication doses
  ///
  /// Incremented when `MedicationSession.completed == false`.
  /// Used for adherence analytics.
  final int medicationMissedCount;

  // Fluid Therapy Fields

  /// Total volume of fluids administered in milliliters
  ///
  /// Sum of all `FluidSession.volumeGiven` values for this period.
  final double fluidTotalVolume;

  /// Whether any fluid therapy was administered
  ///
  /// Set to `true` when at least one fluid session is logged.
  /// Used for quick status checks.
  final bool fluidTreatmentDone;

  /// Number of fluid therapy sessions logged
  ///
  /// Incremented for each `FluidSession` logged in this period.
  final int fluidSessionCount;

  /// Number of fluid therapy sessions scheduled
  ///
  /// Represents total planned fluid sessions for this period based on
  /// schedules.
  /// Used as denominator for fluid adherence calculations.
  final int fluidScheduledSessions;

  // Overall Treatment Fields

  /// Whether primary treatments were completed
  ///
  /// Set to `true` when both medication and fluid therapy (if applicable)
  /// have been logged. Definition varies by user's persona.
  final bool overallTreatmentDone;

  // Metadata

  /// When this summary was first created
  ///
  /// Client-side timestamp. Set when first session of the period is logged.
  final DateTime createdAt;

  /// When this summary was last updated
  ///
  /// Server timestamp. Updated on every session log or modification.
  final DateTime? updatedAt;

  // Abstract Methods (implemented by subclasses)

  /// Document ID for Firestore storage
  ///
  /// Format varies by period:
  /// - Daily: YYYY-MM-DD (e.g., "2025-10-05")
  /// - Weekly: YYYY-Www (e.g., "2025-W40")
  /// - Monthly: YYYY-MM (e.g., "2025-10")
  String get documentId;

  /// Convert to JSON for Firestore storage
  ///
  /// Each subclass implements period-specific serialization.
  Map<String, dynamic> toJson();

  /// Validate the summary data
  ///
  /// Returns a list of validation error messages. Empty list means valid.
  /// Each subclass adds period-specific validation.
  List<String> validate();

  // Computed Properties

  /// Medication adherence percentage (0.0 to 1.0)
  ///
  /// Calculated as `medicationTotalDoses / medicationScheduledDoses`.
  /// Returns 0.0 if no doses were scheduled (avoid division by zero).
  double get medicationAdherence {
    if (medicationScheduledDoses == 0) return 0;
    return medicationTotalDoses / medicationScheduledDoses;
  }

  /// Medication adherence as percentage (0 to 100)
  ///
  /// User-friendly percentage format. Example: 0.875 → 87.5
  double get medicationAdherencePercentage => medicationAdherence * 100;

  /// Whether all scheduled medications were completed
  ///
  /// True when `medicationMissedCount == 0` and at least one dose scheduled.
  bool get hasCompletedAllMedications =>
      medicationScheduledDoses > 0 && medicationMissedCount == 0;

  /// Whether any medications were missed
  ///
  /// True when `medicationMissedCount > 0`.
  bool get hasMissedMedications => medicationMissedCount > 0;

  /// Whether any fluid therapy was administered
  ///
  /// Alias for `fluidTreatmentDone` for semantic clarity.
  bool get hasFluidTherapy => fluidTreatmentDone;

  /// Whether any sessions were logged in this period
  ///
  /// True if at least one medication or fluid session exists.
  bool get hasAnySessions =>
      medicationScheduledDoses > 0 || fluidSessionCount > 0;

  /// Average fluid volume per session
  ///
  /// Returns 0.0 if no sessions logged.
  double get averageFluidVolumePerSession {
    if (fluidSessionCount == 0) return 0;
    return fluidTotalVolume / fluidSessionCount;
  }

  // Shared Validation

  /// Validates shared fields across all summary types
  ///
  /// Checks:
  /// - All counts are non-negative
  /// - Adherence is within valid range
  /// - No future timestamps
  ///
  /// Subclasses call this and add period-specific validation.
  List<String> validateBase() {
    final errors = <String>[];

    // Count validation
    if (medicationTotalDoses < 0) {
      errors.add('Medication total doses cannot be negative');
    }
    if (medicationScheduledDoses < 0) {
      errors.add('Medication scheduled doses cannot be negative');
    }
    if (medicationMissedCount < 0) {
      errors.add('Medication missed count cannot be negative');
    }
    if (fluidSessionCount < 0) {
      errors.add('Fluid session count cannot be negative');
    }

    // Volume validation
    if (fluidTotalVolume < 0) {
      errors.add('Fluid total volume cannot be negative');
    }

    // Logical consistency
    if (medicationTotalDoses > medicationScheduledDoses) {
      errors.add(
        'Medication total doses cannot exceed scheduled doses',
      );
    }
    if (medicationTotalDoses + medicationMissedCount >
        medicationScheduledDoses) {
      errors.add(
        'Total + missed doses cannot exceed scheduled doses',
      );
    }

    // Timestamp validation
    if (createdAt.isAfter(DateTime.now())) {
      errors.add('Created timestamp cannot be in the future');
    }
    if (updatedAt != null && updatedAt!.isBefore(createdAt)) {
      errors.add('Updated timestamp cannot be before created timestamp');
    }

    return errors;
  }

  // JSON Helpers

  /// Helper method to parse DateTime from various formats
  ///
  /// Handles both Firestore Timestamp objects and ISO 8601 strings.
  /// Used by subclasses in `fromJson` constructors.
  static DateTime parseDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      return DateTime.parse(value);
    } else if (value is DateTime) {
      return value;
    } else {
      throw ArgumentError(
        'Invalid DateTime format: expected Timestamp, String, or DateTime, '
        'got ${value.runtimeType}',
      );
    }
  }

  /// Null-tolerant DateTime parser
  ///
  /// Returns null if input is null; otherwise delegates to parseDateTime.
  static DateTime? parseDateTimeNullable(dynamic value) {
    if (value == null) return null;
    return parseDateTime(value);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TreatmentSummaryBase &&
        other.medicationTotalDoses == medicationTotalDoses &&
        other.medicationScheduledDoses == medicationScheduledDoses &&
        other.medicationMissedCount == medicationMissedCount &&
        other.fluidTotalVolume == fluidTotalVolume &&
        other.fluidTreatmentDone == fluidTreatmentDone &&
        other.fluidSessionCount == fluidSessionCount &&
        other.fluidScheduledSessions == fluidScheduledSessions &&
        other.overallTreatmentDone == overallTreatmentDone &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      medicationTotalDoses,
      medicationScheduledDoses,
      medicationMissedCount,
      fluidTotalVolume,
      fluidTreatmentDone,
      fluidSessionCount,
      fluidScheduledSessions,
      overallTreatmentDone,
      createdAt,
      updatedAt,
    );
  }
}
