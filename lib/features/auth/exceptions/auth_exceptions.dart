import 'package:firebase_auth/firebase_auth.dart';

/// Base class for authentication exceptions with empathetic messaging
abstract class AuthException implements Exception {
  /// Creates an [AuthException] with user-friendly message
  const AuthException(this.message, [this.code]);

  /// User-friendly error message with medical caregiver empathy
  final String message;

  /// Optional Firebase error code for debugging
  final String? code;

  @override
  String toString() => 'AuthException: $message';
}

/// Exception for invalid email format
class InvalidEmailException extends AuthException {
  /// Creates an [InvalidEmailException]
  const InvalidEmailException([String? code])
    : super("We need a valid email to keep your pet's data safe", code);
}

/// Exception for weak password
class WeakPasswordException extends AuthException {
  /// Creates a [WeakPasswordException]
  const WeakPasswordException([String? code])
    : super('Please choose a stronger password', code);
}

/// Exception for email already in use
class EmailAlreadyInUseException extends AuthException {
  /// Creates an [EmailAlreadyInUseException]
  const EmailAlreadyInUseException([String? code])
    : super(
        'This email already has an account. '
        'Try signing in instead',
        code,
      );
}

/// Exception for user not found
class UserNotFoundException extends AuthException {
  /// Creates a [UserNotFoundException]
  const UserNotFoundException([String? code])
    : super('No account found with this email', code);
}

/// Exception for wrong password
class WrongPasswordException extends AuthException {
  /// Creates a [WrongPasswordException]
  const WrongPasswordException([String? code])
    : super("Password doesn't match. Please try again", code);
}

/// Exception for disabled user account
class UserDisabledException extends AuthException {
  /// Creates a [UserDisabledException]
  const UserDisabledException([String? code])
    : super('This account has been temporarily disabled', code);
}

/// Exception for too many requests
class TooManyRequestsException extends AuthException {
  /// Creates a [TooManyRequestsException]
  const TooManyRequestsException([String? code])
    : super('Too many attempts. Please wait a moment and try again', code);
}

/// Exception for network connection issues
class NetworkException extends AuthException {
  /// Creates a [NetworkException]
  const NetworkException([String? code])
    : super('Connection issue. Please check your internet and try again', code);
}

/// Exception for account creation failures
class AccountCreationException extends AuthException {
  /// Creates an [AccountCreationException]
  const AccountCreationException([String? code])
    : super('Unable to create account. Please try again', code);
}

/// Exception for sign in failures
class SignInException extends AuthException {
  /// Creates a [SignInException]
  const SignInException([String? code])
    : super('Unable to sign in. Please check your details', code);
}

/// Exception for email verification failures
class EmailVerificationException extends AuthException {
  /// Creates an [EmailVerificationException]
  const EmailVerificationException([String? code])
    : super('Unable to send verification email. Please try again', code);
}

/// Exception for password reset failures
class PasswordResetException extends AuthException {
  /// Creates a [PasswordResetException]
  const PasswordResetException([String? code])
    : super('Unable to send reset email. Please try again', code);
}

/// Exception for general authentication errors
class GeneralAuthException extends AuthException {
  /// Creates a [GeneralAuthException]
  const GeneralAuthException([String? code])
    : super('Authentication error occurred. Please try again', code);
}

/// Utility class for mapping Firebase Auth exceptions to custom exceptions
class AuthExceptionMapper {
  /// Maps Firebase Auth exceptions to user-friendly custom exceptions
  static AuthException mapFirebaseException(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return InvalidEmailException(e.code);
      case 'weak-password':
        return WeakPasswordException(e.code);
      case 'email-already-in-use':
        return EmailAlreadyInUseException(e.code);
      case 'user-not-found':
        return UserNotFoundException(e.code);
      case 'wrong-password':
        return WrongPasswordException(e.code);
      case 'user-disabled':
        return UserDisabledException(e.code);
      case 'too-many-requests':
        return TooManyRequestsException(e.code);
      case 'network-request-failed':
        return NetworkException(e.code);
      default:
        return GeneralAuthException(e.code);
    }
  }

  /// Maps generic exceptions to general auth exceptions
  static AuthException mapGenericException(Exception e) {
    return const GeneralAuthException();
  }
}
