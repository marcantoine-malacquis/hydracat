import 'package:flutter/foundation.dart';

/// Sentinel value for [LoginAttemptData.copyWith] to distinguish between
/// "not provided" and "explicitly set to null"
const _undefined = Object();

/// Model for tracking login attempts and lockout state
@immutable
class LoginAttemptData {
  /// Creates a [LoginAttemptData] instance
  const LoginAttemptData({
    required this.email,
    required this.failedAttempts,
    this.firstFailureTime,
    this.lockoutUntil,
  });

  /// Creates a [LoginAttemptData] from JSON map
  factory LoginAttemptData.fromJson(Map<String, dynamic> json) {
    return LoginAttemptData(
      email: json['email'] as String,
      failedAttempts: json['failedAttempts'] as int,
      firstFailureTime: json['firstFailureTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['firstFailureTime'] as int)
          : null,
      lockoutUntil: json['lockoutUntil'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['lockoutUntil'] as int)
          : null,
    );
  }

  /// Email address associated with the attempts
  final String email;

  /// Number of consecutive failed attempts
  final int failedAttempts;

  /// Timestamp of the first failed attempt in the current window
  final DateTime? firstFailureTime;

  /// Timestamp when the account lockout expires (null if not locked out)
  final DateTime? lockoutUntil;

  /// Whether this account is currently locked out
  bool get isLockedOut {
    if (lockoutUntil == null) return false;
    return DateTime.now().isBefore(lockoutUntil!);
  }

  /// Time remaining until lockout expires
  Duration? get timeUntilUnlock {
    if (!isLockedOut) return null;
    return lockoutUntil!.difference(DateTime.now());
  }

  /// Whether this attempt data has expired (older than 24 hours)
  bool get hasExpired {
    if (firstFailureTime == null) return true;
    final elapsed = DateTime.now().difference(firstFailureTime!);
    return elapsed.inHours >= 24;
  }

  /// Converts the model to JSON map
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'failedAttempts': failedAttempts,
      'firstFailureTime': firstFailureTime?.millisecondsSinceEpoch,
      'lockoutUntil': lockoutUntil?.millisecondsSinceEpoch,
    };
  }

  /// Creates a copy with updated values
  LoginAttemptData copyWith({
    String? email,
    int? failedAttempts,
    Object? firstFailureTime = _undefined,
    Object? lockoutUntil = _undefined,
  }) {
    return LoginAttemptData(
      email: email ?? this.email,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      firstFailureTime: firstFailureTime == _undefined 
          ? this.firstFailureTime 
          : firstFailureTime as DateTime?,
      lockoutUntil: lockoutUntil == _undefined 
          ? this.lockoutUntil 
          : lockoutUntil as DateTime?,
    );
  }

  /// Creates a new instance with incremented failed attempts
  LoginAttemptData incrementAttempts({DateTime? lockoutUntil}) {
    return copyWith(
      failedAttempts: failedAttempts + 1,
      firstFailureTime: firstFailureTime ?? DateTime.now(),
      lockoutUntil: lockoutUntil,
    );
  }

  /// Creates a fresh instance for the same email (resets attempts)
  LoginAttemptData reset() {
    return LoginAttemptData(
      email: email,
      failedAttempts: 0,
    );
  }

  @override
  String toString() {
    return 'LoginAttemptData('
        'email: $email, '
        'failedAttempts: $failedAttempts, '
        'firstFailureTime: $firstFailureTime, '
        'lockoutUntil: $lockoutUntil, '
        'isLockedOut: $isLockedOut)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LoginAttemptData &&
        other.email == email &&
        other.failedAttempts == failedAttempts &&
        other.firstFailureTime == firstFailureTime &&
        other.lockoutUntil == lockoutUntil;
  }

  @override
  int get hashCode {
    return Object.hash(email, failedAttempts, firstFailureTime, lockoutUntil);
  }
}
