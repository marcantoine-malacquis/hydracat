import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/features/auth/models/auth_state.dart';
import 'package:hydracat/providers/auth_provider.dart';
import 'package:hydracat/shared/services/firebase_service.dart';

/// Analytics event names
class AnalyticsEvents {
  /// Login event name
  static const String login = 'login';

  /// Sign up event name
  static const String signUp = 'sign_up';

  /// Email verification sent event name
  static const String emailVerificationSent = 'email_verification_sent';

  /// Email verified event name
  static const String emailVerified = 'email_verified';

  /// Password reset event name
  static const String passwordReset = 'password_reset';

  /// Social sign in event name
  static const String socialSignIn = 'social_sign_in';

  /// Sign out event name
  static const String signOut = 'sign_out';

  /// Feature used event name
  static const String featureUsed = 'feature_used';

  /// Screen view event name
  static const String screenView = 'screen_view';

  /// Error event name
  static const String error = 'app_error';

  /// Onboarding started event name
  static const String onboardingStarted = 'onboarding_started';

  /// Onboarding step completed event name
  static const String onboardingStepCompleted = 'onboarding_step_completed';

  /// Onboarding completed event name
  static const String onboardingCompleted = 'onboarding_completed';

  /// Onboarding abandoned event name
  static const String onboardingAbandoned = 'onboarding_abandoned';
}

/// Analytics parameters
class AnalyticsParams {
  /// Method parameter name
  static const String method = 'method';

  /// Provider parameter name
  static const String provider = 'provider';

  /// Screen name parameter name
  static const String screenName = 'screen_name';

  /// Feature name parameter name
  static const String featureName = 'feature_name';

  /// Error type parameter name
  static const String errorType = 'error_type';

  /// User verified parameter name
  static const String userVerified = 'user_verified';

  /// User type parameter name
  static const String userType = 'user_type';

  /// Onboarding step parameter name
  static const String step = 'step';

  /// Next step parameter name
  static const String nextStep = 'next_step';

  /// Progress percentage parameter name
  static const String progressPercentage = 'progress_percentage';

  /// User persona parameter name
  static const String userPersona = 'user_persona';

  /// Pet ID parameter name
  static const String petId = 'pet_id';

  /// Treatment approach parameter name
  static const String treatmentApproach = 'treatment_approach';

  /// Duration parameter name
  static const String duration = 'duration_seconds';

  /// Completion rate parameter name
  static const String completionRate = 'completion_rate';
}

/// User types for analytics
enum UserType {
  /// Anonymous user type
  anonymous,

  /// Unverified user type
  unverified,

  /// Verified user type
  verified,
}

/// Analytics service that integrates with authentication
class AnalyticsService {
  /// Creates an [AnalyticsService] with Firebase Analytics
  AnalyticsService(this._analytics);

  final FirebaseAnalytics _analytics;
  bool _isEnabled = true;

  /// Enable or disable analytics tracking
  void setEnabled({required bool enabled}) {
    _isEnabled = enabled;
    _analytics.setAnalyticsCollectionEnabled(enabled);
  }

  /// Check if analytics is enabled
  bool get isEnabled => _isEnabled;

  /// Set user ID for analytics tracking
  Future<void> setUserId(String? userId) async {
    if (!_isEnabled) return;

    await _analytics.setUserId(id: userId);
  }

  /// Set user properties based on auth state
  Future<void> setUserProperties({
    required UserType userType,
    String? provider,
  }) async {
    if (!_isEnabled) return;

    await _analytics.setUserProperty(
      name: AnalyticsParams.userType,
      value: userType.name,
    );

    if (provider != null) {
      await _analytics.setUserProperty(
        name: AnalyticsParams.provider,
        value: provider,
      );
    }
  }

  /// Track login events
  Future<void> trackLogin({
    required String method,
    bool success = true,
  }) async {
    if (!_isEnabled) return;

    await _analytics.logEvent(
      name: AnalyticsEvents.login,
      parameters: {
        AnalyticsParams.method: method,
        'success': success,
      },
    );
  }

  /// Track sign up events
  Future<void> trackSignUp({
    required String method,
    bool success = true,
  }) async {
    if (!_isEnabled) return;

    await _analytics.logEvent(
      name: AnalyticsEvents.signUp,
      parameters: {
        AnalyticsParams.method: method,
        'success': success,
      },
    );
  }

  /// Track email verification sent
  Future<void> trackEmailVerificationSent() async {
    if (!_isEnabled) return;

    await _analytics.logEvent(
      name: AnalyticsEvents.emailVerificationSent,
    );
  }

  /// Track email verification completed
  Future<void> trackEmailVerified() async {
    if (!_isEnabled) return;

    await _analytics.logEvent(
      name: AnalyticsEvents.emailVerified,
    );
  }

  /// Track password reset
  Future<void> trackPasswordReset() async {
    if (!_isEnabled) return;

    await _analytics.logEvent(
      name: AnalyticsEvents.passwordReset,
    );
  }

  /// Track social sign-in
  Future<void> trackSocialSignIn({
    required String provider,
    bool success = true,
  }) async {
    if (!_isEnabled) return;

    await _analytics.logEvent(
      name: AnalyticsEvents.socialSignIn,
      parameters: {
        AnalyticsParams.provider: provider,
        'success': success,
      },
    );
  }

  /// Track sign out
  Future<void> trackSignOut() async {
    if (!_isEnabled) return;

    await _analytics.logEvent(
      name: AnalyticsEvents.signOut,
    );
  }

  /// Track feature usage
  Future<void> trackFeatureUsed({
    required String featureName,
    bool isVerifiedUser = false,
    Map<String, dynamic>? additionalParams,
  }) async {
    if (!_isEnabled) return;

    final params = <String, dynamic>{
      AnalyticsParams.featureName: featureName,
      AnalyticsParams.userVerified: isVerifiedUser,
    };

    if (additionalParams != null) {
      params.addAll(additionalParams);
    }

    await _analytics.logEvent(
      name: AnalyticsEvents.featureUsed,
      parameters: Map<String, Object>.from(params),
    );
  }

  /// Track screen views
  Future<void> trackScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    if (!_isEnabled) return;

    await _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenClass,
    );
  }

  /// Track errors (non-sensitive only)
  Future<void> trackError({
    required String errorType,
    String? errorContext,
  }) async {
    if (!_isEnabled) return;

    await _analytics.logEvent(
      name: AnalyticsEvents.error,
      parameters: {
        AnalyticsParams.errorType: errorType,
        if (errorContext != null) 'context': errorContext,
      },
    );
  }

  /// Clear user data (on sign out)
  Future<void> clearUserData() async {
    if (!_isEnabled) return;

    await _analytics.setUserId();
    await _analytics.resetAnalyticsData();
  }

  /// Track onboarding started
  Future<void> trackOnboardingStarted({
    required String userId,
    String? timestamp,
  }) async {
    if (!_isEnabled) return;

    await _analytics.logEvent(
      name: AnalyticsEvents.onboardingStarted,
      parameters: {
        'user_id': userId,
        if (timestamp != null) 'timestamp': timestamp,
      },
    );
  }

  /// Track onboarding step completed
  Future<void> trackOnboardingStepCompleted({
    required String userId,
    required String step,
    required String nextStep,
    required double progressPercentage,
  }) async {
    if (!_isEnabled) return;

    await _analytics.logEvent(
      name: AnalyticsEvents.onboardingStepCompleted,
      parameters: {
        'user_id': userId,
        AnalyticsParams.step: step,
        AnalyticsParams.nextStep: nextStep,
        AnalyticsParams.progressPercentage: progressPercentage,
      },
    );
  }

  /// Track onboarding completed
  Future<void> trackOnboardingCompleted({
    required String userId,
    required String petId,
    required String treatmentApproach,
    int? durationSeconds,
    double completionRate = 1.0,
  }) async {
    if (!_isEnabled) return;

    await _analytics.logEvent(
      name: AnalyticsEvents.onboardingCompleted,
      parameters: {
        'user_id': userId,
        AnalyticsParams.petId: petId,
        AnalyticsParams.treatmentApproach: treatmentApproach,
        if (durationSeconds != null) AnalyticsParams.duration: durationSeconds,
        AnalyticsParams.completionRate: completionRate,
      },
    );
  }

  /// Track onboarding abandoned
  Future<void> trackOnboardingAbandoned({
    required String userId,
    required String lastStep,
    required double progressPercentage,
    int? timeSpentSeconds,
  }) async {
    if (!_isEnabled) return;

    await _analytics.logEvent(
      name: AnalyticsEvents.onboardingAbandoned,
      parameters: {
        'user_id': userId,
        AnalyticsParams.step: lastStep,
        AnalyticsParams.progressPercentage: progressPercentage,
        if (timeSpentSeconds != null) 'time_spent_seconds': timeSpentSeconds,
      },
    );
  }
}

/// Notifier class for managing analytics with authentication integration
class AnalyticsNotifier extends StateNotifier<bool> {
  /// Creates an [AnalyticsNotifier] with the provided dependencies
  AnalyticsNotifier(this._ref, this._analyticsService) : super(true) {
    _listenToAuthChanges();
    // Enable analytics by default in production, disable in debug
    _analyticsService.setEnabled(enabled: !kDebugMode);
  }

  final Ref _ref;
  final AnalyticsService _analyticsService;

  /// Listen to authentication state changes
  void _listenToAuthChanges() {
    _ref.listen(
      authProvider,
      _handleAuthStateChange,
    );
  }

  /// Handle authentication state changes
  void _handleAuthStateChange(AuthState? previous, AuthState current) {
    switch (current) {
      case AuthStateAuthenticated(user: final user):
        _handleUserAuthenticated(
          user.id,
          user.emailVerified,
          user.provider.name,
        );
      case AuthStateUnauthenticated():
        _handleUserSignedOut();
      case AuthStateLoading():
        // No action needed during loading
        break;
      case AuthStateError():
        // No action needed for auth errors
        break;
    }

    // Track authentication state changes
    _trackAuthStateChange(previous, current);
  }

  /// Handle authenticated user
  void _handleUserAuthenticated(
    String userId,
    bool emailVerified,
    String provider,
  ) {
    // Set user ID for analytics
    _analyticsService.setUserId(userId);

    // Set user properties
    final userType = emailVerified ? UserType.verified : UserType.unverified;
    _analyticsService.setUserProperties(
      userType: userType,
      provider: provider,
    );
  }

  /// Handle user signed out
  void _handleUserSignedOut() {
    // Clear analytics user data and set anonymous user properties
    _analyticsService
      ..clearUserData()
      ..setUserProperties(
        userType: UserType.anonymous,
      );
  }

  /// Track authentication state changes
  void _trackAuthStateChange(AuthState? previous, AuthState current) {
    // Track login success
    if (previous is! AuthStateAuthenticated &&
        current is AuthStateAuthenticated) {
      _analyticsService.trackLogin(
        method: current.user.provider.name,
      );
    }

    // Track sign out
    if (previous is AuthStateAuthenticated &&
        current is AuthStateUnauthenticated) {
      _analyticsService.trackSignOut();
    }

    // Track login errors
    if (current is AuthStateError) {
      _analyticsService.trackError(
        errorType: 'auth_error',
        errorContext: current.code ?? 'unknown',
      );
    }
  }

  /// Enable or disable analytics
  void setEnabled({required bool enabled}) {
    state = enabled;
    _analyticsService.setEnabled(enabled: enabled);
  }

  /// Get analytics service for direct usage
  AnalyticsService get service => _analyticsService;
}

/// Provider for Firebase Analytics service
final firebaseAnalyticsProvider = Provider<FirebaseAnalytics>((ref) {
  return FirebaseService().analytics;
});

/// Provider for analytics service
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  final analytics = ref.read(firebaseAnalyticsProvider);
  return AnalyticsService(analytics);
});

/// Provider for analytics state management
final analyticsProvider = StateNotifierProvider<AnalyticsNotifier, bool>((ref) {
  final analyticsService = ref.read(analyticsServiceProvider);
  return AnalyticsNotifier(ref, analyticsService);
});

/// Convenience provider to check if analytics is enabled
final isAnalyticsEnabledProvider = Provider<bool>((ref) {
  return ref.watch(analyticsProvider);
});

/// Convenience provider to get analytics service directly
final analyticsServiceDirectProvider = Provider<AnalyticsService>((ref) {
  final notifier = ref.read(analyticsProvider.notifier);
  return notifier.service;
});
