import 'package:hydracat/shared/models/login_attempt_data.dart';
import 'package:hydracat/shared/services/secure_preferences_service.dart';

/// Configuration for brute force protection
class BruteForceConfig {
  /// Maximum number of failed attempts before lockout
  static const int maxAttempts = 5;

  /// Progressive lockout durations
  static const List<Duration> lockoutDurations = [
    Duration(minutes: 5), // 1st lockout
    Duration(minutes: 15), // 2nd lockout
    Duration(hours: 1), // 3rd lockout
    Duration(hours: 24), // 4th+ lockouts
  ];

  /// Time window for tracking attempts (24 hours)
  static const Duration attemptWindow = Duration(hours: 24);

  /// Data retention period (7 days)
  static const Duration dataRetention = Duration(days: 7);
}

/// Service for tracking login attempts and managing brute force protection
///
/// Provides secure, encrypted storage of failed login attempts per email
/// address with progressive lockout periods and automatic cleanup.
class LoginAttemptService {
  /// Creates a [LoginAttemptService] instance
  LoginAttemptService({SecurePreferencesService? secureStorage})
    : _secureStorage = secureStorage ?? SecurePreferencesService();

  final SecurePreferencesService _secureStorage;
  static const String _storagePrefix = 'login_attempts_';

  /// Checks if the given email address is currently locked out
  ///
  /// Returns true if the account is locked out, false otherwise.
  Future<bool> isAccountLockedOut(String email) async {
    final attemptData = await _getAttemptData(email);
    if (attemptData == null) return false;

    // Clean up expired data
    if (attemptData.hasExpired) {
      await _removeAttemptData(email);
      return false;
    }

    return attemptData.isLockedOut;
  }

  /// Gets the time remaining until the account lockout expires
  ///
  /// Returns null if the account is not locked out.
  Future<Duration?> getTimeUntilUnlock(String email) async {
    final attemptData = await _getAttemptData(email);
    return attemptData?.timeUntilUnlock;
  }

  /// Gets the number of failed attempts for the given email
  ///
  /// Returns 0 if no attempts are recorded or data has expired.
  Future<int> getFailedAttemptCount(String email) async {
    final attemptData = await _getAttemptData(email);
    if (attemptData == null || attemptData.hasExpired) {
      return 0;
    }
    return attemptData.failedAttempts;
  }

  /// Records a failed login attempt for the given email
  ///
  /// Increments the attempt counter and applies lockout if threshold exceeded.
  /// Returns the updated attempt data with lockout information.
  Future<LoginAttemptData> recordFailedAttempt(String email) async {
    var attemptData = await _getAttemptData(email);

    // If no existing data or expired, create fresh data
    if (attemptData == null || attemptData.hasExpired) {
      attemptData = LoginAttemptData(
        email: email,
        failedAttempts: 0,
      );
    }

    // Increment attempts
    final newAttemptCount = attemptData.failedAttempts + 1;

    // Calculate lockout if threshold exceeded
    DateTime? lockoutUntil;
    if (newAttemptCount >= BruteForceConfig.maxAttempts) {
      lockoutUntil = _calculateLockoutEnd(newAttemptCount);
    }

    // Update attempt data
    final updatedData = attemptData.incrementAttempts(
      lockoutUntil: lockoutUntil,
    );

    // Store the updated data
    await _storeAttemptData(updatedData);

    return updatedData;
  }

  /// Records a successful login for the given email
  ///
  /// Clears all failed attempt data for the email address.
  Future<void> recordSuccessfulLogin(String email) async {
    await _removeAttemptData(email);
  }

  /// Gets a warning message for the user based on attempt count
  ///
  /// Returns null if no warning is needed.
  Future<String?> getWarningMessage(String email) async {
    final attemptData = await _getAttemptData(email);
    if (attemptData == null || attemptData.hasExpired) return null;

    final attemptsLeft =
        BruteForceConfig.maxAttempts - attemptData.failedAttempts;

    if (attemptsLeft <= 2 && attemptsLeft > 0) {
      return "Only $attemptsLeft attempt${attemptsLeft == 1 ? '' : 's'} left "
          'before temporary lockout';
    }

    return null;
  }

  /// Resets all attempt data for the given email (development only)
  ///
  /// Completely clears failed attempts and lockout status for testing.
  Future<void> resetAttemptData(String email) async {
    await _removeAttemptData(email);
  }

  /// Cleans up expired attempt data
  ///
  /// Should be called periodically to maintain storage efficiency.
  Future<void> cleanupExpiredData() async {
    // This is a simplified cleanup - in a real app you'd iterate through
    // all stored attempts and remove expired ones
    // For now, cleanup happens automatically when data is accessed
  }

  /// Gets attempt data for the given email
  Future<LoginAttemptData?> _getAttemptData(String email) async {
    final storageKey = _getStorageKey(email);
    final attemptData = await _secureStorage.getSecureData(storageKey);

    if (attemptData == null) return null;

    try {
      return LoginAttemptData.fromJson(attemptData);
    } on Exception {
      // If data is corrupted, remove it
      await _removeAttemptData(email);
      return null;
    }
  }

  /// Stores attempt data for the given email
  Future<void> _storeAttemptData(LoginAttemptData data) async {
    final storageKey = _getStorageKey(data.email);
    await _secureStorage.setSecureData(storageKey, data.toJson());
  }

  /// Removes attempt data for the given email
  Future<void> _removeAttemptData(String email) async {
    final storageKey = _getStorageKey(email);
    await _secureStorage.removeSecureData(storageKey);
  }

  /// Calculates when the lockout should end based on attempt count
  DateTime _calculateLockoutEnd(int attemptCount) {
    // Determine which lockout duration to use
    final lockoutIndex = (attemptCount - BruteForceConfig.maxAttempts).clamp(
      0,
      BruteForceConfig.lockoutDurations.length - 1,
    );

    final lockoutDuration = BruteForceConfig.lockoutDurations[lockoutIndex];

    return DateTime.now().add(lockoutDuration);
  }

  /// Generates storage key for the given email
  String _getStorageKey(String email) {
    return '$_storagePrefix${email.toLowerCase().trim()}';
  }
}
