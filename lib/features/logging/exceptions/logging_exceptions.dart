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

  /// User-friendly message for display in UI
  ///
  /// Override this in subclasses to provide context-specific messages
  /// with empathetic, caregiver tone.
  String get userMessage => 'Something went wrong. Please try again.';

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
///   existingSession: existingSession,
/// );
/// ```
class DuplicateSessionException extends LoggingException {
  /// Creates a [DuplicateSessionException]
  const DuplicateSessionException({
    required this.sessionType,
    required this.conflictingTime,
    this.medicationName,
    this.existingSession,
  }) : super('Duplicate session detected');

  /// Type of session that was duplicated ('medication' or 'fluid')
  final String sessionType;

  /// DateTime of the existing conflicting session
  final DateTime conflictingTime;

  /// Medication name for medication duplicates (null for fluid sessions)
  final String? medicationName;

  /// The existing session that conflicts with the new one
  ///
  /// Contains full session data for comparison in UI dialogs.
  /// Type is dynamic to support both MedicationSession and future
  /// session types.
  final dynamic existingSession;

  @override
  String get userMessage {
    return "You've already logged this treatment today. "
        'Would you like to update it instead?';
  }

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

  /// User-friendly message (shows first error only)
  ///
  /// Validation errors are already formatted with empathetic tone,
  /// so we return the first one directly. If list is empty, provides
  /// a generic helpful message.
  @override
  String get userMessage {
    if (validationErrors.isEmpty) {
      return 'Please check your entries and try again.';
    }
    return validationErrors.first;
  }

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

  @override
  String get userMessage =>
      "We couldn't find a matching schedule. Logging as a one-time entry.";
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
  String get userMessage {
    return 'Unable to save right now. Your data is saved offline and will '
        'sync automatically.';
  }

  @override
  String toString() => message;
}

/// Thrown when offline operation is queued successfully
class OfflineLoggingException extends LoggingException {
  /// Creates an [OfflineLoggingException]
  const OfflineLoggingException() : super('Operation queued for sync');

  @override
  String get userMessage {
    return 'Logged successfully! Will sync when you are back online.';
  }
}

/// Thrown when sync operation fails after retries
class SyncFailedException extends LoggingException {
  /// Creates a [SyncFailedException]
  const SyncFailedException(this.operationCount, [this.lastError])
    : super('Sync operation failed');

  /// Number of operations that failed to sync
  final int operationCount;

  /// Optional last error message for debugging
  final String? lastError;

  @override
  String get userMessage {
    final plural = operationCount > 1 ? 's' : '';
    return '$operationCount treatment$plural could not sync. '
        'Check your connection and tap retry.';
  }
}

/// Thrown when offline queue reaches soft warning threshold (50 items)
class QueueWarningException extends LoggingException {
  /// Creates a [QueueWarningException]
  const QueueWarningException(this.queueSize)
    : super('Offline queue approaching limit');

  /// Current size of the offline queue
  final int queueSize;

  @override
  String get userMessage {
    return 'You have $queueSize treatments waiting to sync. '
        'Connect to internet soon to avoid data loss.';
  }
}

/// Thrown when offline queue reaches hard limit (200 items)
class QueueFullException extends LoggingException {
  /// Creates a [QueueFullException]
  const QueueFullException(this.queueSize) : super('Offline queue full');

  /// Current size of the offline queue (at max capacity)
  final int queueSize;

  @override
  String get userMessage {
    return 'Too many treatments waiting to sync ($queueSize). '
        'Please connect to internet to free up space.';
  }
}
