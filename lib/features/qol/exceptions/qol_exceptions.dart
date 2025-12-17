/// Base exception for QoL-related operations.
class QolException implements Exception {
  /// Creates a [QolException] with a message.
  const QolException(this.message);

  /// Human-readable error message.
  final String message;

  @override
  String toString() => 'QolException: $message';
}

/// Exception for QoL validation failures.
///
/// Thrown when a QoL assessment fails validation, such as:
/// - Future dates
/// - Invalid scores (outside 0-4 range)
/// - Invalid question IDs
/// - Duplicate question responses
class QolValidationException extends QolException {
  /// Creates a [QolValidationException] with a message.
  const QolValidationException(super.message);

  @override
  String toString() => 'QolValidationException: $message';
}

/// Exception for QoL service operations.
///
/// Thrown when Firestore operations fail, such as:
/// - Save failures
/// - Read failures
/// - Delete failures
/// - Batch write failures
class QolServiceException extends QolException {
  /// Creates a [QolServiceException] with a message.
  const QolServiceException(super.message);

  @override
  String toString() => 'QolServiceException: $message';
}
