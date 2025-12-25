/// Migration utilities for transitioning from OnboardingStepType enum to
/// step IDs
///
/// Provides backward compatibility for existing checkpoint data that uses
/// the old enum-based step identification system.
library;

// This file provides migration utilities for the deprecated OnboardingStepType
// and intentionally uses it for backward compatibility with saved data.
// ignore_for_file: deprecated_member_use_from_same_package

import 'package:hydracat/features/onboarding/models/onboarding_step.dart';
import 'package:hydracat/features/onboarding/models/onboarding_step_id.dart';

/// Migrates old OnboardingStepType enum to new step IDs
///
/// This class provides utilities for converting between the legacy enum-based
/// step identification system and the new sealed class-based system.
class StepTypeMigration {
  // Private constructor to prevent instantiation
  const StepTypeMigration._();

  /// Converts legacy enum to step ID
  ///
  /// Maps each OnboardingStepType enum value to its corresponding
  /// OnboardingStepId instance.
  static OnboardingStepId migrateStepType(OnboardingStepType oldType) {
    return switch (oldType) {
      OnboardingStepType.welcome => OnboardingSteps.welcome,
      OnboardingStepType.petBasics => OnboardingSteps.petBasics,
      OnboardingStepType.ckdMedicalInfo => OnboardingSteps.medicalInfo,
      OnboardingStepType.completion => OnboardingSteps.completion,
    };
  }

  /// Converts step ID back to legacy enum (for compatibility)
  ///
  /// This is used for maintaining backward compatibility with code
  /// that still expects the old enum format.
  ///
  /// Returns null if the step ID doesn't map to a legacy enum value.
  static OnboardingStepType? migrateToLegacyType(OnboardingStepId stepId) {
    if (stepId == OnboardingSteps.welcome) return OnboardingStepType.welcome;
    if (stepId == OnboardingSteps.petBasics) {
      return OnboardingStepType.petBasics;
    }
    if (stepId == OnboardingSteps.medicalInfo) {
      return OnboardingStepType.ckdMedicalInfo;
    }
    if (stepId == OnboardingSteps.completion) {
      return OnboardingStepType.completion;
    }
    return null;
  }

  /// Parses a step ID from a string representation
  ///
  /// Handles both old enum names and new step ID strings.
  /// Returns the default (welcome) step if the string doesn't match any
  /// known step.
  static OnboardingStepId parseStepId(String idString) {
    return switch (idString) {
      'welcome' => OnboardingSteps.welcome,
      'petBasics' || 'pet_basics' => OnboardingSteps.petBasics,
      'ckdMedicalInfo' || 'medical_info' => OnboardingSteps.medicalInfo,
      'completion' => OnboardingSteps.completion,
      _ => OnboardingSteps.welcome, // Fallback to welcome
    };
  }
}
