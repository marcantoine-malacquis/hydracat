/// Base exception for health-related operations
class HealthException implements Exception {
  /// Creates a [HealthException] with a message
  const HealthException(this.message);

  /// Human-readable error message
  final String message;

  @override
  String toString() => 'HealthException: $message';
}

/// Exception for weight validation failures
class WeightValidationException extends HealthException {
  /// Creates a [WeightValidationException] with a message
  const WeightValidationException(super.message);
}

/// Exception for weight service operations
class WeightServiceException extends HealthException {
  /// Creates a [WeightServiceException] with a message
  const WeightServiceException(super.message);
}
