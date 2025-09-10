/// Profile-specific exceptions for error handling
///
/// Provides specialized exceptions for pet profile operations with
/// user-friendly error messages suitable for veterinary app users.
library;

/// Base class for all profile-related exceptions
abstract class ProfileException implements Exception {
  /// Creates a [ProfileException] with a user-friendly message
  const ProfileException(this.message, [this.code]);

  /// User-friendly error message
  final String message;

  /// Optional error code for programmatic handling
  final String? code;

  @override
  String toString() => 'ProfileException: $message';
}

/// Exception thrown when a pet profile is not found
class PetNotFoundException extends ProfileException {
  /// Creates a [PetNotFoundException]
  const PetNotFoundException([String? petId])
    : super(
        petId != null
            ? 'Pet profile not found (ID: $petId)'
            : 'Pet profile not found',
        'pet-not-found',
      );
}

/// Exception thrown when a pet name conflicts with existing pets
class PetNameConflictException extends ProfileException {
  /// Creates a [PetNameConflictException] with suggested alternatives
  const PetNameConflictException(String name, [this.suggestions = const []])
    : super(
        'A pet named "$name" already exists. Please choose a different name.',
        'pet-name-conflict',
      );

  /// Suggested alternative names
  final List<String> suggestions;

  /// User-friendly message with suggestions
  String get messageWithSuggestions {
    if (suggestions.isEmpty) return message;

    final suggestionText = suggestions.length == 1
        ? 'Try "${suggestions.first}" instead.'
        : 'Try one of these: ${suggestions.join(", ")}.';

    return '$message $suggestionText';
  }
}

/// Exception thrown when pet profile validation fails
class ProfileValidationException extends ProfileException {
  /// Creates a [ProfileValidationException] with validation errors
  const ProfileValidationException(this.validationErrors)
    : super(
        'Pet profile contains invalid information. '
            'Please review and correct the highlighted fields.',
        'validation-failed',
      );

  /// List of specific validation error messages
  final List<String> validationErrors;

  /// Combined validation message
  String get detailedMessage {
    if (validationErrors.isEmpty) return message;
    return '$message\n\nIssues found:\n'
        '${validationErrors.map((e) => '• $e').join('\n')}';
  }
}

/// Exception thrown when pet service operations fail
class PetServiceException extends ProfileException {
  /// Creates a [PetServiceException]
  const PetServiceException(super.message, [super.code]);

  /// Creates a [PetServiceException] for network-related failures
  const PetServiceException.network()
    : super(
        'Unable to sync pet data. Please check your internet connection '
            'and try again.',
        'network-error',
      );

  /// Creates a [PetServiceException] for permission-related failures
  const PetServiceException.permission()
    : super(
        "You don't have permission to perform this action.",
        'permission-denied',
      );

  /// Creates a [PetServiceException] for quota/limit failures
  const PetServiceException.quota()
    : super(
        "You've reached the maximum number of pets allowed.",
        'quota-exceeded',
      );

  /// Creates a [PetServiceException] for general data corruption
  const PetServiceException.dataCorruption()
    : super(
        'Pet data appears to be corrupted. Please contact support if this '
            'persists.',
        'data-corruption',
      );
}

/// Exception thrown when trying to delete a pet with dependencies
class PetHasDependenciesException extends ProfileException {
  /// Creates a [PetHasDependenciesException]
  const PetHasDependenciesException(String petName, this.dependencyTypes)
    : super(
        'Cannot delete $petName because they have existing records. '
            'Please review their treatment history first.',
        'pet-has-dependencies',
      );

  /// Types of dependencies preventing deletion
  /// (e.g., 'fluid sessions', 'medications')
  final List<String> dependencyTypes;

  /// Detailed message explaining dependencies
  String get detailedMessage {
    if (dependencyTypes.isEmpty) return message;

    final deps = dependencyTypes.join(', ');
    return '$message\n\nExisting records: $deps';
  }
}

/// Exception thrown when pet weight validation fails
class InvalidWeightException extends ProfileException {
  /// Creates an [InvalidWeightException]
  const InvalidWeightException(double weight, String unit)
    : super(
        'Weight of $weight $unit seems unrealistic for a cat. '
            'Please double-check the value and unit.',
        'invalid-weight',
      );
}

/// Exception thrown when pet age validation fails
class InvalidAgeException extends ProfileException {
  /// Creates an [InvalidAgeException]
  const InvalidAgeException(int age)
    : super(
        'Age of $age years seems unrealistic. '
            'Cat ages typically range from 0 to 25 years.',
        'invalid-age',
      );
}

/// Exception thrown when CKD diagnosis date is inconsistent
class InvalidDiagnosisDateException extends ProfileException {
  /// Creates an [InvalidDiagnosisDateException]
  const InvalidDiagnosisDateException(String reason)
    : super(
        'CKD diagnosis date is invalid: $reason',
        'invalid-diagnosis-date',
      );

  /// Creates exception for future diagnosis dates
  const InvalidDiagnosisDateException.futureDate()
    : super(
        'CKD diagnosis date cannot be in the future.',
        'diagnosis-date-future',
      );

  /// Creates exception for diagnosis date older than pet
  const InvalidDiagnosisDateException.olderThanPet()
    : super(
        'CKD diagnosis date suggests your pet was diagnosed before they were '
            "born. Please check the pet's age or diagnosis date.",
        'diagnosis-date-older-than-pet',
      );
}

/// Utility class for mapping generic exceptions to profile exceptions
class ProfileExceptionMapper {
  /// Maps Firestore exceptions to user-friendly profile exceptions
  static ProfileException mapFirestoreException(Object exception) {
    final message = exception.toString().toLowerCase();

    if (message.contains('permission-denied')) {
      return const PetServiceException.permission();
    } else if (message.contains('not-found')) {
      return const PetNotFoundException();
    } else if (message.contains('network') || message.contains('unavailable')) {
      return const PetServiceException.network();
    } else if (message.contains('quota') ||
        message.contains('resource-exhausted')) {
      return const PetServiceException.quota();
    }

    return const PetServiceException(
      'An unexpected error occurred while managing pet data. Please try again.',
      'unknown-error',
    );
  }

  /// Maps generic exceptions to profile exceptions
  static ProfileException mapGenericException(Object exception) {
    return PetServiceException(
      'An unexpected error occurred: $exception',
      'generic-error',
    );
  }
}
