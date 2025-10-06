/// Exceptions for treatment logging operations
library;

/// Base exception for all logging operations
///
/// Provides common interface for all logging-related errors with optional
/// error codes for programmatic error handling.
class LoggingException implements Exception {
  /// Creates a [LoggingException] with a message and optional error code
  const LoggingException(this.message, {this.code});

  /// Human-readable error message
  final String message;

  /// Optional error code for programmatic handling
  final String? code;

  @override
  String toString() =>
      'LoggingException: $message${code != null ? ' (code: $code)' : ''}';
}

/// Thrown when a duplicate session is detected
///
/// Indicates that a session matching the same criteria (medication name + time
/// window) already exists. UI should present user with option to update
/// existing session or cancel.
///
/// Example:
/// ```dart
/// throw DuplicateSessionException(
///   sessionType: 'medication',
///   conflictingTime: existingSession.dateTime,
///   medicationName: 'Amlodipine',
/// );
/// ```
class DuplicateSessionException extends LoggingException {
  /// Creates a [DuplicateSessionException]
  const DuplicateSessionException({
    required this.sessionType,
    required this.conflictingTime,
    this.medicationName,
  }) : super('Duplicate session detected');

  /// Type of session that was duplicated ('medication' or 'fluid')
  final String sessionType;

  /// DateTime of the existing conflicting session
  final DateTime conflictingTime;

  /// Medication name for medication duplicates (null for fluid sessions)
  final String? medicationName;

  @override
  String toString() {
    final timeStr = conflictingTime.toString().substring(0, 16);
    final nameStr = medicationName != null ? ' ($medicationName)' : '';
    return 'DuplicateSessionException: $sessionType session$nameStr '
        'already logged at $timeStr';
  }
}

/// Thrown when session validation fails
///
/// Contains list of validation error messages from both model validation
/// (structural) and service validation (business rules).
///
/// Example:
/// ```dart
/// throw SessionValidationException([
///   'Dosage given cannot be negative',
///   'Medication name is required',
/// ]);
/// ```
class SessionValidationException extends LoggingException {
  /// Creates a [SessionValidationException] with validation errors
  const SessionValidationException(this.validationErrors)
      : super('Session validation failed');

  /// List of validation error messages
  final List<String> validationErrors;

  @override
  String toString() {
    return 'SessionValidationException: ${validationErrors.join(', ')}';
  }
}

/// Thrown when schedule matching encounters a critical error
///
/// This is different from "no schedule found" (which is valid for manual logs).
/// This indicates a systemic issue with schedule data or matching logic.
///
/// Example:
/// ```dart
/// throw ScheduleMatchException('Schedule has no reminder times defined');
/// ```
class ScheduleMatchException extends LoggingException {
  /// Creates a [ScheduleMatchException] with error message
  const ScheduleMatchException(super.message);
}

/// Thrown when Firestore batch write operation fails
///
/// Wraps Firebase exceptions with context about which logging operation failed.
/// UI should handle this by queueing operation for offline retry.
///
/// Example:
/// ```dart
/// throw BatchWriteException(
///   'logMedicationSession',
///   'Permission denied: Missing required permission',
/// );
/// ```
class BatchWriteException extends LoggingException {
  /// Creates a [BatchWriteException]
  const BatchWriteException(this.operation, String message)
      : super('Batch write failed during $operation: $message');

  /// The logging operation that failed (e.g., 'logMedicationSession')
  final String operation;

  @override
  String toString() => message;
}
