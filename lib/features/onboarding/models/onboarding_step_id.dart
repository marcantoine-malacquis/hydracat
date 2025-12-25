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

  /// Pet basics step ID
  static const petBasics = PetBasicsStepId();

  /// Medical info step ID
  static const medicalInfo = MedicalInfoStepId();

  /// Completion step ID
  static const completion = CompletionStepId();

  /// All steps in default order
  static const List<OnboardingStepId> all = [
    welcome,
    petBasics,
    medicalInfo,
    completion,
  ];
}
