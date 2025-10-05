import 'package:flutter/foundation.dart';

/// Sealed class representing the result of a logging operation
///
/// Uses the Result pattern to handle success and failure cases in a
/// type-safe way. Supports pattern matching with the `when` method for
/// clean error handling.
///
/// Example usage:
/// ```dart
/// final result = await loggingService.logMedicationSession(...);
///
/// result.when(
///   success: (session) => print('Logged: ${session.id}'),
///   failure: (error) => print('Error: $error'),
/// );
/// ```
@immutable
sealed class LoggingResult<T> {
  /// Creates a [LoggingResult]
  const LoggingResult();

  /// Pattern matching helper for clean result handling
  ///
  /// Provides a functional way to handle both success and failure cases
  /// without explicit type checking or casting.
  R when<R>({
    required R Function(T data) success,
    required R Function(String error) failure,
  });

  /// Whether this result represents a successful operation
  bool get isSuccess => this is LoggingSuccess<T>;

  /// Whether this result represents a failed operation
  bool get isFailure => this is LoggingFailure<T>;
}

/// Represents a successful logging operation
@immutable
class LoggingSuccess<T> extends LoggingResult<T> {
  /// Creates a [LoggingSuccess] with the result data
  const LoggingSuccess(this.data);

  /// The successful result data (e.g., the created session)
  final T data;

  @override
  R when<R>({
    required R Function(T data) success,
    required R Function(String error) failure,
  }) =>
      success(data);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LoggingSuccess<T> && other.data == data;
  }

  @override
  int get hashCode => data.hashCode;

  @override
  String toString() => 'LoggingSuccess(data: $data)';
}

/// Represents a failed logging operation
@immutable
class LoggingFailure<T> extends LoggingResult<T> {
  /// Creates a [LoggingFailure] with an error message
  const LoggingFailure(this.error);

  /// The error message describing what went wrong
  final String error;

  @override
  R when<R>({
    required R Function(T data) success,
    required R Function(String error) failure,
  }) =>
      failure(error);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LoggingFailure<T> && other.error == error;
  }

  @override
  int get hashCode => error.hashCode;

  @override
  String toString() => 'LoggingFailure(error: $error)';
}
