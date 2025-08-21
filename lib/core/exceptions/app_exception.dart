/// Base exception class for HydraCat app
abstract class AppException implements Exception {
  /// Creates an AppException with the given message and optional code and
  /// details
  const AppException(this.message, {this.code, this.details});

  /// The error message describing the exception
  final String message;

  /// Optional error code for the exception
  final String? code;

  /// Additional details about the exception
  final dynamic details;

  @override
  String toString() {
    if (code != null) {
      return 'AppException: $message (Code: $code)';
    }
    return 'AppException: $message';
  }
}

/// Exception thrown when Firebase operations fail
class FirebaseException extends AppException {
  /// Creates a FirebaseException with the given message and optional code and
  /// details
  const FirebaseException(super.message, {super.code, super.details});
}

/// Exception thrown when authentication fails
class AuthenticationException extends AppException {
  /// Creates an AuthenticationException with the given message and optional
  /// code and details
  const AuthenticationException(super.message, {super.code, super.details});
}

/// Exception thrown when data validation fails
class ValidationException extends AppException {
  /// Creates a ValidationException with the given message and optional code
  /// and details
  const ValidationException(super.message, {super.code, super.details});
}

/// Exception thrown when network operations fail
class NetworkException extends AppException {
  /// Creates a NetworkException with the given message and optional code
  /// and details
  const NetworkException(super.message, {super.code, super.details});
}

/// Exception thrown when data is not found
class NotFoundException extends AppException {
  /// Creates a NotFoundException with the given message and optional code
  /// and details
  const NotFoundException(super.message, {super.code, super.details});
}
