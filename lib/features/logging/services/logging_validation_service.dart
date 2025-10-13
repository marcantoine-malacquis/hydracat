/// Service for complex business validation of logging sessions
library;

import 'package:hydracat/core/validation/models/validation_result.dart';
import 'package:hydracat/features/logging/exceptions/logging_exceptions.dart';
import 'package:hydracat/features/logging/models/fluid_session.dart';
import 'package:hydracat/features/logging/models/medication_session.dart';

/// Service for complex business validation of logging sessions
///
/// Complements model-level structural validation with:
/// - Duplicate detection (medication sessions only)
/// - Cross-field validation (schedule consistency)
/// - Domain-specific medical rules (CKD-appropriate volumes/dosages)
/// - Time-based validation (reasonable administration windows)
///
/// Stateless design: all context passed as parameters for testability.
///
/// Usage:
/// ```dart
/// const validationService = LoggingValidationService();
///
/// // Validate for duplicates
/// final duplicateResult = validationService.validateForDuplicates(
///   newSession: medicationSession,
///   recentSessions: todaysSessions,
/// );
///
/// // Validate fluid volume with schedule context
/// final volumeResult = validationService.validateFluidVolume(
///   volumeGiven: 100,
///   scheduledVolume: 120,
/// );
/// ```
class LoggingValidationService {
  /// Creates a [LoggingValidationService] instance
  const LoggingValidationService();

  // ============================================
  // DUPLICATE DETECTION
  // ============================================

  /// Validates medication session for duplicates
  ///
  /// Duplicate criteria:
  /// - Same medication name (case-sensitive exact match)
  /// - Within specified time window (default ±15 minutes)
  ///
  /// Returns ValidationResult with:
  /// - Success: No duplicate found
  /// - Failure: Duplicate exists with ValidationError of type duplicate
  ///
  /// Example:
  /// ```dart
  /// final result = validationService.validateForDuplicates(
  ///   newSession: medicationSession,
  ///   recentSessions: todaysSessions,
  ///   timeWindow: Duration(minutes: 15),
  /// );
  ///
  /// if (!result.isValid) {
  ///   // Duplicate detected - show update dialog
  /// }
  /// ```
  ValidationResult validateForDuplicates({
    required MedicationSession newSession,
    required List<MedicationSession> recentSessions,
    Duration timeWindow = const Duration(minutes: 15),
  }) {
    final duplicate = findDuplicateSession(
      newSession: newSession,
      recentSessions: recentSessions,
      timeWindow: timeWindow,
    );

    if (duplicate != null) {
      return ValidationResult.failure([
        ValidationError(
          message:
              "You've already logged ${newSession.medicationName} today. "
              'Would you like to update it instead?',
          fieldName: 'medication',
          type: ValidationErrorType.duplicate,
        ),
      ]);
    }

    return const ValidationResult.success();
  }

  /// Finds duplicate medication session if one exists
  ///
  /// Returns the existing session that conflicts with the new session,
  /// or null if no duplicate found.
  ///
  /// Duplicate criteria:
  /// - Same medication name (case-sensitive exact match)
  /// - Within specified time window (default ±15 minutes)
  ///
  /// Example:
  /// ```dart
  /// final duplicate = validationService.findDuplicateSession(
  ///   newSession: medicationSession,
  ///   recentSessions: todaysSessions,
  /// );
  ///
  /// if (duplicate != null) {
  ///   // Handle duplicate - show update dialog
  /// }
  /// ```
  MedicationSession? findDuplicateSession({
    required MedicationSession newSession,
    required List<MedicationSession> recentSessions,
    Duration timeWindow = const Duration(minutes: 15),
  }) {
    for (final existing in recentSessions) {
      // Same medication name (case-sensitive exact match)
      if (existing.medicationName != newSession.medicationName) continue;

      // Within time window
      final timeDiff = existing.dateTime.difference(newSession.dateTime).abs();
      if (timeDiff <= timeWindow) {
        return existing; // Duplicate found
      }
    }

    return null; // No duplicate
  }

  // ============================================
  // SESSION VALIDATION
  // ============================================

  /// Validates medication session (structural + business rules)
  ///
  /// Two-layer validation:
  /// 1. Model validation: session.validate() for structural checks
  /// 2. Business validation: service-specific rules
  ///
  /// Returns ValidationResult with:
  /// - Success: Session is valid
  /// - Failure: Contains list of validation errors
  ///
  /// Example:
  /// ```dart
  /// final result = validationService.validateMedicationSession(session);
  /// if (!result.isValid) {
  ///   // Show error: result.errorMessage
  /// }
  /// ```
  ValidationResult validateMedicationSession(MedicationSession session) {
    final errors = <ValidationError>[];

    // Layer 1: Model structural validation
    final modelErrors = session.validate();
    errors.addAll(
      modelErrors.map(
        (msg) => ValidationError(
          message: msg,
          fieldName: 'session',
          type: ValidationErrorType.invalid,
        ),
      ),
    );

    // Layer 2: Business rules validation
    if (session.medicationName.trim().length < 2) {
      errors.add(
        const ValidationError(
          message: 'Medication name must be at least 2 characters',
          fieldName: 'medicationName',
          type: ValidationErrorType.invalid,
        ),
      );
    }

    if (session.dateTime.isAfter(DateTime.now())) {
      errors.add(
        const ValidationError(
          message: 'Cannot log medication for future time',
          fieldName: 'dateTime',
          type: ValidationErrorType.invalid,
        ),
      );
    }

    if (errors.isNotEmpty) {
      return ValidationResult.failure(errors);
    }

    return const ValidationResult.success();
  }

  /// Validates fluid session (structural + business rules)
  ///
  /// Two-layer validation:
  /// 1. Model validation: session.validate() for structural checks
  /// 2. Business validation: service-specific rules
  ///
  /// Returns ValidationResult with:
  /// - Success: Session is valid
  /// - Failure: Contains list of validation errors
  ///
  /// Example:
  /// ```dart
  /// final result = validationService.validateFluidSession(session);
  /// if (!result.isValid) {
  ///   // Show error: result.errorMessage
  /// }
  /// ```
  ValidationResult validateFluidSession(FluidSession session) {
    final errors = <ValidationError>[];

    // Layer 1: Model structural validation
    final modelErrors = session.validate();
    errors.addAll(
      modelErrors.map(
        (msg) => ValidationError(
          message: msg,
          fieldName: 'session',
          type: ValidationErrorType.invalid,
        ),
      ),
    );

    // Layer 2: Business rules validation
    if (session.dateTime.isAfter(DateTime.now())) {
      errors.add(
        const ValidationError(
          message: 'Cannot log fluid therapy for future time',
          fieldName: 'dateTime',
          type: ValidationErrorType.invalid,
        ),
      );
    }

    if (errors.isNotEmpty) {
      return ValidationResult.failure(errors);
    }

    return const ValidationResult.success();
  }

  // ============================================
  // DOMAIN-SPECIFIC VALIDATION
  // ============================================

  /// Validates fluid volume with medical context
  ///
  /// Checks:
  /// - Range: 1-500ml (current standard for cats)
  /// - Warning: < 50ml or > 300ml unusual for cats
  /// - Context: Compare with schedule targetVolume for consistency
  ///
  /// Returns ValidationResult with:
  /// - Success: Volume is valid (may include warnings)
  /// - Failure: Volume is out of acceptable range
  ///
  /// Example:
  /// ```dart
  /// final result = validationService.validateFluidVolume(
  ///   volumeGiven: 100,
  ///   scheduledVolume: 120,
  /// );
  ///
  /// if (!result.isValid) {
  ///   // Show error
  /// } else if (result.hasWarnings) {
  ///   // Show warning banner
  /// }
  /// ```
  ValidationResult validateFluidVolume({
    required double volumeGiven,
    double? scheduledVolume,
  }) {
    final errors = <ValidationError>[];
    final warnings = <String>[];

    // Basic range validation (1-500ml for cats)
    if (volumeGiven < 1 || volumeGiven > 500) {
      errors.add(
        const ValidationError(
          message:
              'Please enter a volume between 1-500ml to keep your '
              "cat's data accurate",
          fieldName: 'volume',
          type: ValidationErrorType.invalid,
        ),
      );
    }

    // Medical warnings (non-blocking)
    if (volumeGiven > 0 && volumeGiven < 50) {
      warnings.add('Volume under 50ml is quite low. Is this correct?');
    } else if (volumeGiven > 300) {
      warnings.add('Volume over 300ml is high. Please verify this amount.');
    }

    // Schedule consistency check
    if (scheduledVolume != null && scheduledVolume > 0) {
      final diff = (volumeGiven - scheduledVolume).abs();
      if (diff > scheduledVolume * 0.5) {
        // More than 50% difference
        warnings.add(
          'Volume differs significantly from scheduled '
          '${scheduledVolume.toInt()}ml. This is fine if intentional.',
        );
      }
    }

    if (errors.isNotEmpty) {
      return ValidationResult.failure(errors);
    }

    if (warnings.isNotEmpty) {
      return ValidationResult.withWarnings(warnings);
    }

    return const ValidationResult.success();
  }

  /// Validates medication dosage with schedule context
  ///
  /// Checks:
  /// - Range: Must be positive, reasonable range (0-100 units)
  /// - Warning: Significant deviation from schedule
  /// - Context: Compare with scheduled dosage
  ///
  /// Returns ValidationResult with:
  /// - Success: Dosage is valid (may include warnings)
  /// - Failure: Dosage is invalid
  ///
  /// Example:
  /// ```dart
  /// final result = validationService.validateMedicationDosage(
  ///   dosageGiven: 1.0,
  ///   dosageScheduled: 1.5,
  ///   medicationUnit: 'pills',
  /// );
  /// ```
  ValidationResult validateMedicationDosage({
    required double dosageGiven,
    required double dosageScheduled,
    required String medicationUnit,
  }) {
    final errors = <ValidationError>[];
    final warnings = <String>[];

    // Basic range validation
    if (dosageGiven < 0) {
      errors.add(
        const ValidationError(
          message: 'Dosage cannot be negative',
          fieldName: 'dosage',
          type: ValidationErrorType.invalid,
        ),
      );
    }

    if (dosageGiven > 100) {
      errors.add(
        ValidationError(
          message:
              'Dosage of $dosageGiven $medicationUnit seems '
              'unrealistically high. Please verify this amount.',
          fieldName: 'dosage',
          type: ValidationErrorType.invalid,
        ),
      );
    }

    // Schedule consistency check
    if (dosageScheduled > 0) {
      final diff = (dosageGiven - dosageScheduled).abs();
      if (diff > dosageScheduled * 0.5) {
        // More than 50% difference
        warnings.add(
          'Dosage differs significantly from scheduled '
          '$dosageScheduled $medicationUnit. This is fine if intentional.',
        );
      }
    }

    // Zero dosage warning (marked as given but no amount)
    if (dosageGiven == 0) {
      warnings.add(
        'Dosage is 0 - consider marking this treatment as missed instead.',
      );
    }

    if (errors.isNotEmpty) {
      return ValidationResult.failure(errors);
    }

    if (warnings.isNotEmpty) {
      return ValidationResult.withWarnings(warnings);
    }

    return const ValidationResult.success();
  }

  /// Validates session timing matches schedule expectations
  ///
  /// Checks if session time is within reasonable window of scheduled time.
  /// Large time drifts may indicate user error or intentional rescheduling.
  ///
  /// Returns ValidationResult with:
  /// - Success: Time is reasonable (may include warnings for drift)
  /// - Warnings: Significant time drift from schedule
  ///
  /// Example:
  /// ```dart
  /// final result = validationService.validateScheduleConsistency(
  ///   sessionTime: DateTime.now(),
  ///   scheduledTime: scheduledDateTime,
  /// );
  ///
  /// if (result.hasWarnings) {
  ///   // Show time drift warning
  /// }
  /// ```
  ValidationResult validateScheduleConsistency({
    required DateTime sessionTime,
    required DateTime? scheduledTime,
    Duration maxDrift = const Duration(hours: 2),
  }) {
    if (scheduledTime == null) {
      return const ValidationResult.success(); // Manual log, no schedule
    }

    final drift = sessionTime.difference(scheduledTime).abs();
    final warnings = <String>[];

    if (drift > maxDrift) {
      final hours = drift.inHours;
      warnings.add(
        'Treatment time is ${hours}h different from scheduled. '
        'This may affect adherence tracking.',
      );
    }

    if (warnings.isNotEmpty) {
      return ValidationResult.withWarnings(warnings);
    }

    return const ValidationResult.success();
  }

  // ============================================
  // EXCEPTION CONVERSION
  // ============================================

  /// Converts ValidationResult to LoggingException
  ///
  /// Use at service layer when validation fails to throw appropriate
  /// exception.
  ///
  /// Handles conversion from ValidationResult errors to specific
  /// LoggingException subclasses based on error type.
  ///
  /// Parameters:
  /// - [result]: The validation result to convert
  /// - [duplicateSession]: Optional duplicate session for context
  ///  (when converting duplicate errors)
  ///
  /// Example:
  /// ```dart
  /// final result = validationService.validateForDuplicates(...);
  /// if (!result.isValid) {
  ///   final duplicate = validationService.findDuplicateSession(...);
  ///   throw validationService.toLoggingException(
  ///     result,
  ///     duplicateSession: duplicate,
  ///   );
  /// }
  /// ```
  ///
  /// Throws:
  /// - [ArgumentError]: If called with valid ValidationResult
  /// - [DuplicateSessionException]: If duplicate error detected
  /// - [SessionValidationException]: For general validation failures
  LoggingException toLoggingException(
    ValidationResult result, {
    MedicationSession? duplicateSession,
  }) {
    if (result.isValid) {
      throw ArgumentError('Cannot create exception from valid result');
    }

    // Check if any errors are duplicates
    final duplicateErrors = result.getErrorsByType(
      ValidationErrorType.duplicate,
    );
    if (duplicateErrors.isNotEmpty) {
      return DuplicateSessionException(
        sessionType: 'medication',
        conflictingTime: duplicateSession?.dateTime ?? DateTime.now(),
        medicationName: duplicateSession?.medicationName,
      );
    }

    // Convert to generic SessionValidationException
    final errorMessages = result.errors.map((e) => e.message).toList();
    return SessionValidationException(errorMessages);
  }
}
