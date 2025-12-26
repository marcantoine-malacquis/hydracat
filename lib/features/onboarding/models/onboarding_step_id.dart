/// Type-safe step identification system for onboarding flow
///
/// Uses sealed classes to provide compile-time safety while allowing
/// extension for new steps without modifying enums.
library;

import 'package:flutter/foundation.dart';

/// Sealed class for type-safe step identification
///
/// Each step in the onboarding flow has a unique ID that extends this class.
/// This allows for type-safe step identification while avoiding the
/// limitations of enums (can't add new values without modifying the enum).
@immutable
sealed class OnboardingStepId {
  /// Creates an [OnboardingStepId] with the given [id] string
  const OnboardingStepId(this.id);

  /// Unique identifier string for this step
  final String id;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OnboardingStepId && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => id;
}

/// Welcome step - entry point with skip option
class WelcomeStepId extends OnboardingStepId {
  /// Creates a [WelcomeStepId]
  const WelcomeStepId() : super('welcome');
}

/// Pet basics step - name, age, gender, weight
class PetBasicsStepId extends OnboardingStepId {
  /// Creates a [PetBasicsStepId]
  const PetBasicsStepId() : super('pet_basics');
}

/// Medical info step - IRIS stage and lab values
class MedicalInfoStepId extends OnboardingStepId {
  /// Creates a [MedicalInfoStepId]
  const MedicalInfoStepId() : super('medical_info');
}

/// Pet name and gender step - basic identity information
class PetNameGenderStepId extends OnboardingStepId {
  /// Creates a [PetNameGenderStepId]
  const PetNameGenderStepId() : super('pet_name_gender');
}

/// Pet date of birth step - age information
class PetDateOfBirthStepId extends OnboardingStepId {
  /// Creates a [PetDateOfBirthStepId]
  const PetDateOfBirthStepId() : super('pet_date_of_birth');
}

/// Pet breed step - breed information (optional)
class PetBreedStepId extends OnboardingStepId {
  /// Creates a [PetBreedStepId]
  const PetBreedStepId() : super('pet_breed');
}

/// Pet weight step - weight information (optional)
class PetWeightStepId extends OnboardingStepId {
  /// Creates a [PetWeightStepId]
  const PetWeightStepId() : super('pet_weight');
}

/// Completion step - success and next steps
class CompletionStepId extends OnboardingStepId {
  /// Creates a [CompletionStepId]
  const CompletionStepId() : super('completion');
}

/// Step ID constants for easy access throughout the app
class OnboardingSteps {
  /// Private constructor to prevent instantiation
  const OnboardingSteps._();

  /// Welcome step ID
  static const welcome = WelcomeStepId();

  /// Pet basics step ID (deprecated - replaced by split steps)
  @Deprecated('Use petNameGender, petDateOfBirth, petBreed, petWeight instead')
  static const petBasics = PetBasicsStepId();

  /// Pet name and gender step ID
  static const petNameGender = PetNameGenderStepId();

  /// Pet date of birth step ID
  static const petDateOfBirth = PetDateOfBirthStepId();

  /// Pet breed step ID
  static const petBreed = PetBreedStepId();

  /// Pet weight step ID
  static const petWeight = PetWeightStepId();

  /// Medical info step ID
  static const medicalInfo = MedicalInfoStepId();

  /// Completion step ID
  static const completion = CompletionStepId();

  /// All steps in default order
  static const List<OnboardingStepId> all = [
    welcome,
    petNameGender,
    petDateOfBirth,
    petBreed,
    petWeight,
    medicalInfo,
    completion,
  ];
}
