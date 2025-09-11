/// Onboarding-specific exceptions for error handling
///
/// Provides specialized exceptions for onboarding operations with
/// user-friendly error messages suitable for CKD caregivers.
library;

/// Base class for all onboarding-related exceptions
abstract class OnboardingException implements Exception {
  /// Creates an [OnboardingException] with a user-friendly message
  const OnboardingException(this.message, [this.code]);

  /// User-friendly error message
  final String message;

  /// Optional error code for programmatic handling
  final String? code;

  @override
  String toString() => 'OnboardingException: $message';
}

/// Exception thrown when onboarding data is invalid
class OnboardingValidationException extends OnboardingException {
  /// Creates an [OnboardingValidationException] with validation errors
  const OnboardingValidationException(this.validationErrors)
    : super(
        'Please correct the following information to continue',
        'validation-failed',
      );

  /// List of specific validation errors
  final List<String> validationErrors;

  /// Combined error message with all validation issues
  String get detailedMessage {
    if (validationErrors.isEmpty) return message;
    return '$message:\n${validationErrors.map((e) => '• $e').join('\n')}';
  }
}

/// Exception thrown when trying to progress without required data
class OnboardingIncompleteDataException extends OnboardingException {
  /// Creates an [OnboardingIncompleteDataException]
  const OnboardingIncompleteDataException([String? missingField])
    : super(
        missingField != null
            ? 'Please provide $missingField to continue'
            : 'Some required information is missing. '
                  'Please complete the form.',
        'incomplete-data',
      );
}

/// Exception thrown when onboarding step navigation fails
class OnboardingNavigationException extends OnboardingException {
  /// Creates an [OnboardingNavigationException]
  const OnboardingNavigationException(String stepName)
    : super(
        'Unable to navigate to $stepName. Please try again.',
        'navigation-failed',
      );
}

/// Exception thrown when checkpoint save/load fails
class OnboardingCheckpointException extends OnboardingException {
  /// Creates an [OnboardingCheckpointException]
  const OnboardingCheckpointException([String? operation])
    : super(
        operation != null
            ? 'Failed to $operation your progress. '
                  'Your data may not be saved.'
            : 'Unable to save your progress. Please try again.',
        'checkpoint-failed',
      );
}

/// Exception thrown when onboarding data cannot be found
class OnboardingDataNotFoundException extends OnboardingException {
  /// Creates an [OnboardingDataNotFoundException]
  const OnboardingDataNotFoundException()
    : super(
        'No saved progress found. Starting fresh onboarding.',
        'data-not-found',
      );
}

/// Exception thrown when pet profile creation fails during onboarding
class OnboardingProfileCreationException extends OnboardingException {
  /// Creates an [OnboardingProfileCreationException] with underlying cause
  const OnboardingProfileCreationException([String? cause])
    : super(
        cause != null
            ? 'Unable to create your pet profile: $cause'
            : 'Unable to create your pet profile. Please try again.',
        'profile-creation-failed',
      );
}

/// Exception thrown when network operations fail during onboarding
class OnboardingNetworkException extends OnboardingException {
  /// Creates an [OnboardingNetworkException]
  const OnboardingNetworkException()
    : super(
        'Connection issue detected. Your progress is saved locally '
            'and will sync when connected.',
        'network-error',
      );
}

/// Exception thrown when onboarding service is not properly initialized
class OnboardingServiceException extends OnboardingException {
  /// Creates an [OnboardingServiceException]
  const OnboardingServiceException([String? details])
    : super(
        details != null
            ? 'Service error: $details'
            : 'Onboarding service is temporarily unavailable. '
                  'Please try again.',
        'service-error',
      );
}

/// Exception thrown when trying to start onboarding for already completed user
class OnboardingAlreadyCompletedException extends OnboardingException {
  /// Creates an [OnboardingAlreadyCompletedException]
  const OnboardingAlreadyCompletedException()
    : super(
        'Onboarding is already completed. You can update your pet '
            'profile in Settings.',
        'already-completed',
      );
}

/// Exception thrown when analytics tracking fails
class OnboardingAnalyticsException extends OnboardingException {
  /// Creates an [OnboardingAnalyticsException]
  const OnboardingAnalyticsException([String? eventName])
    : super(
        eventName != null
            ? 'Failed to track $eventName event'
            : 'Analytics tracking failed',
        'analytics-failed',
      );
}
