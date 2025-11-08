import 'package:flutter/foundation.dart';
import 'package:hydracat/features/auth/models/app_user.dart';

/// Sentinel value for copyWith methods to distinguish between
/// "not provided" and "explicitly set to null"
const _undefined = Object();

/// Base class representing the authentication state of the application
sealed class AuthState {
  /// Creates an [AuthState] instance
  const AuthState();

  /// Creates an [AuthState] from JSON data
  factory AuthState.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;

    switch (type) {
      case 'loading':
        return const AuthStateLoading();
      case 'unauthenticated':
        return const AuthStateUnauthenticated();
      case 'authenticated':
        final userData = json['user'] as Map<String, dynamic>;
        return AuthStateAuthenticated(user: AppUser.fromJson(userData));
      case 'error':
        return AuthStateError(
          message: json['message'] as String,
          code: json['code'] as String?,
          details: json['details'],
        );
      default:
        throw ArgumentError('Unknown AuthState type: $type');
    }
  }

  /// Converts [AuthState] to JSON data
  Map<String, dynamic> toJson();
}

/// Loading state - checking authentication status
@immutable
class AuthStateLoading extends AuthState {
  /// Creates an [AuthStateLoading] instance
  const AuthStateLoading();

  @override
  Map<String, dynamic> toJson() {
    return {'type': 'loading'};
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) || other is AuthStateLoading;
  }

  @override
  int get hashCode => 'loading'.hashCode;

  @override
  String toString() => 'AuthState.loading()';
}

/// Unauthenticated state - user is not logged in
@immutable
class AuthStateUnauthenticated extends AuthState {
  /// Creates an [AuthStateUnauthenticated] instance
  const AuthStateUnauthenticated();

  @override
  Map<String, dynamic> toJson() {
    return {'type': 'unauthenticated'};
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) || other is AuthStateUnauthenticated;
  }

  @override
  int get hashCode => 'unauthenticated'.hashCode;

  @override
  String toString() => 'AuthState.unauthenticated()';
}

/// Authenticated state - user is logged in
@immutable
class AuthStateAuthenticated extends AuthState {
  /// Creates an [AuthStateAuthenticated] instance
  const AuthStateAuthenticated({required this.user});

  /// The authenticated user
  final AppUser user;

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'authenticated',
      'user': user.toJson(),
    };
  }

  /// Creates a copy of this [AuthStateAuthenticated]
  /// with the given fields replaced
  AuthStateAuthenticated copyWith({AppUser? user}) {
    return AuthStateAuthenticated(user: user ?? this.user);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is AuthStateAuthenticated && other.user == user);
  }

  @override
  int get hashCode => Object.hash('authenticated', user);

  @override
  String toString() => 'AuthState.authenticated(user: $user)';
}

/// Error state - authentication error occurred
@immutable
class AuthStateError extends AuthState {
  /// Creates an [AuthStateError] instance
  const AuthStateError({
    required this.message,
    this.code,
    this.details,
  });

  /// The error message
  final String message;

  /// Optional error code
  final String? code;

  /// Additional error details
  final dynamic details;

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'error',
      'message': message,
      'code': code,
      'details': details,
    };
  }

  /// Creates a copy of this [AuthStateError] with the given fields replaced
  AuthStateError copyWith({
    String? message,
    Object? code = _undefined,
    Object? details = _undefined,
  }) {
    return AuthStateError(
      message: message ?? this.message,
      code: code == _undefined ? this.code : code as String?,
      details: details == _undefined ? this.details : details,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is AuthStateError &&
            other.message == message &&
            other.code == code &&
            other.details == details);
  }

  @override
  int get hashCode => Object.hash('error', message, code, details);

  @override
  String toString() {
    return 'AuthState.error(message: $message, code: $code, details: $details)';
  }
}

/// Extension on [AuthState] for convenient state checking
extension AuthStateX on AuthState {
  /// Returns true if the user is authenticated
  bool get isAuthenticated => this is AuthStateAuthenticated;

  /// Returns true if the authentication state is loading
  bool get isLoading => this is AuthStateLoading;

  /// Returns true if the user is unauthenticated
  bool get isUnauthenticated => this is AuthStateUnauthenticated;

  /// Returns true if there's an authentication error
  bool get hasError => this is AuthStateError;

  /// Returns the authenticated user or null if not authenticated
  AppUser? get user {
    if (this is AuthStateAuthenticated) {
      return (this as AuthStateAuthenticated).user;
    }
    return null;
  }

  /// Returns the error message or null if no error
  String? get errorMessage {
    if (this is AuthStateError) {
      return (this as AuthStateError).message;
    }
    return null;
  }

  /// Returns the error code or null if no error
  String? get errorCode {
    if (this is AuthStateError) {
      return (this as AuthStateError).code;
    }
    return null;
  }

  /// Pattern matching method for handling different auth states
  T when<T>({
    required T Function() loading,
    required T Function() unauthenticated,
    required T Function(AppUser user) authenticated,
    required T Function(String message, String? code, dynamic details) error,
  }) {
    if (this is AuthStateLoading) {
      return loading();
    } else if (this is AuthStateUnauthenticated) {
      return unauthenticated();
    } else if (this is AuthStateAuthenticated) {
      return authenticated((this as AuthStateAuthenticated).user);
    } else if (this is AuthStateError) {
      final errorState = this as AuthStateError;
      return error(errorState.message, errorState.code, errorState.details);
    }
    throw StateError('Unknown AuthState type: $runtimeType');
  }

  /// Pattern matching method with optional cases
  T maybeWhen<T>({
    required T Function() orElse,
    T Function()? loading,
    T Function()? unauthenticated,
    T Function(AppUser user)? authenticated,
    T Function(String message, String? code, dynamic details)? error,
  }) {
    if (this is AuthStateLoading && loading != null) {
      return loading();
    } else if (this is AuthStateUnauthenticated && unauthenticated != null) {
      return unauthenticated();
    } else if (this is AuthStateAuthenticated && authenticated != null) {
      return authenticated((this as AuthStateAuthenticated).user);
    } else if (this is AuthStateError && error != null) {
      final errorState = this as AuthStateError;
      return error(errorState.message, errorState.code, errorState.details);
    }
    return orElse();
  }
}
