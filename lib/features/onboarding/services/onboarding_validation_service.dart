import 'package:hydracat/core/utils/date_utils.dart';
import 'package:hydracat/core/validation/models/validation_result.dart';
import 'package:hydracat/features/onboarding/models/onboarding_data.dart';
import 'package:hydracat/features/onboarding/models/onboarding_step.dart';
import 'package:hydracat/features/profile/models/user_persona.dart';

/// Centralized validation service for onboarding flow
///
/// Provides consistent validation logic across all onboarding screens
/// with persona-aware validation rules and actionable error messages.
class OnboardingValidationService {
  /// Private constructor to prevent instantiation
  OnboardingValidationService._();

  /// Validates the current onboarding step and returns actionable errors
  ///
  /// [data] - Current onboarding data
  /// [currentStep] - The step being validated
  /// [persona] - User's selected treatment persona (for persona-aware
  /// validation)
  static ValidationResult validateCurrentStep(
    OnboardingData data,
    OnboardingStepType currentStep,
    UserPersona? persona,
  ) {
    final errors = <ValidationError>[];

    switch (currentStep) {
      case OnboardingStepType.welcome:
      // No validation required for welcome step

      case OnboardingStepType.userPersona:
        errors.addAll(_validatePersonaSelection(data));

      case OnboardingStepType.petBasics:
        errors.addAll(_validatePetBasics(data));

      case OnboardingStepType.ckdMedicalInfo:
      // Medical info is optional, no validation required

      case OnboardingStepType.treatmentMedication:
        errors.addAll(_validateTreatmentMedication(data, persona));

      case OnboardingStepType.treatmentFluid:
        errors.addAll(_validateTreatmentFluid(data, persona));

      case OnboardingStepType.completion:
        errors.addAll(_validateCompletion(data, persona));
    }

    return errors.isEmpty
        ? const ValidationResult.success()
        : ValidationResult.failure(errors);
  }

  /// Validates persona selection step
  static List<ValidationError> _validatePersonaSelection(OnboardingData data) {
    final errors = <ValidationError>[];

    if (data.treatmentApproach == null) {
      errors.add(
        const ValidationError(
          message: 'Please select your treatment approach to continue',
          fieldName: 'treatmentApproach',
          suggestedAction: 'Select Treatment Approach',
        ),
      );
    }

    return errors;
  }

  /// Validates pet basics step
  static List<ValidationError> _validatePetBasics(OnboardingData data) {
    final errors = <ValidationError>[];

    // Pet name validation
    if (data.petName == null || data.petName!.isEmpty) {
      errors.add(
        const ValidationError(
          message: 'Pet name is required',
          fieldName: 'petName',
        ),
      );
    } else if (data.petName!.length > 50) {
      errors.add(
        const ValidationError(
          message: 'Pet name must be 50 characters or less',
          fieldName: 'petName',
          type: ValidationErrorType.invalid,
        ),
      );
    }

    // Pet age validation
    if (data.petAge == null) {
      errors.add(
        const ValidationError(
          message: 'Pet age is required',
          fieldName: 'petAge',
        ),
      );
    } else if (data.petAge! <= 0) {
      errors.add(
        const ValidationError(
          message: 'Pet age must be greater than 0',
          fieldName: 'petAge',
          type: ValidationErrorType.invalid,
        ),
      );
    } else if (data.petAge! > 25) {
      errors.add(
        const ValidationError(
          message: 'Pet age seems unrealistic (over 25 years)',
          fieldName: 'petAge',
          type: ValidationErrorType.invalid,
        ),
      );
    }

    // Weight validation (optional but must be valid if provided)
    if (data.petWeightKg != null) {
      if (data.petWeightKg! <= 0) {
        errors.add(
          const ValidationError(
            message: 'Weight must be greater than 0',
            fieldName: 'petWeightKg',
            type: ValidationErrorType.invalid,
          ),
        );
      } else if (data.petWeightKg! > 15) {
        errors.add(
          const ValidationError(
            message: 'Weight seems unrealistic (over 15kg for a cat)',
            fieldName: 'petWeightKg',
            type: ValidationErrorType.invalid,
          ),
        );
      }
    }

    // Date consistency validation - use same calculation method as screen
    if (data.petAge != null &&
        data.petDateOfBirth != null &&
        data.petAge! > 0) {
      final calculatedAge = AppDateUtils.calculateAge(data.petDateOfBirth!);
      if (calculatedAge != data.petAge!) {
        errors.add(
          const ValidationError(
            message:
                'Date of birth and age do not match. '
                'Please check your date selection.',
            fieldName: 'petDateOfBirth',
            type: ValidationErrorType.inconsistent,
          ),
        );
      }
    }

    return errors;
  }

  /// Validates treatment medication step based on persona
  static List<ValidationError> _validateTreatmentMedication(
    OnboardingData data,
    UserPersona? persona,
  ) {
    final errors = <ValidationError>[];

    // Only require medications for medication-based personas
    if (persona?.includesMedication ?? false) {
      if (data.medications == null || data.medications!.isEmpty) {
        errors.add(
          const ValidationError(
            message: 'At least one medication is required',
            fieldName: 'medications',
            type: ValidationErrorType.incomplete,
          ),
        );
      } else {
        // Validate each medication
        for (var i = 0; i < data.medications!.length; i++) {
          final medication = data.medications![i];
          if (!medication.isValid) {
            errors.add(
              ValidationError(
                message: 'Medication ${i + 1} has invalid data',
                fieldName: 'medications[$i]',
                type: ValidationErrorType.invalid,
              ),
            );
          }
        }
      }
    }

    return errors;
  }

  /// Validates treatment fluid step based on persona
  static List<ValidationError> _validateTreatmentFluid(
    OnboardingData data,
    UserPersona? persona,
  ) {
    final errors = <ValidationError>[];

    // Only require fluid therapy for fluid-based personas
    if (persona?.includesFluidTherapy ?? false) {
      if (data.fluidTherapy == null) {
        errors.add(
          const ValidationError(
            message: 'Fluid therapy setup is required',
            fieldName: 'fluidTherapy',
            type: ValidationErrorType.incomplete,
          ),
        );
      } else if (!data.fluidTherapy!.isValid) {
        errors.add(
          const ValidationError(
            message: 'Fluid therapy has invalid data',
            fieldName: 'fluidTherapy',
            type: ValidationErrorType.invalid,
          ),
        );
      }
    }

    return errors;
  }

  /// Validates completion step with comprehensive checks
  static List<ValidationError> _validateCompletion(
    OnboardingData data,
    UserPersona? persona,
  ) {
    final errors = <ValidationError>[
      ..._validatePersonaSelection(data),
      ..._validatePetBasics(data),
    ];

    // Validate treatment requirements based on persona
    if (persona != null) {
      switch (persona) {
        case UserPersona.medicationOnly:
          errors.addAll(_validateTreatmentMedication(data, persona));

        case UserPersona.fluidTherapyOnly:
          errors.addAll(_validateTreatmentFluid(data, persona));

        case UserPersona.medicationAndFluidTherapy:
          errors.addAll(_validateTreatmentMedication(data, persona));
          errors.addAll(_validateTreatmentFluid(data, persona));
      }
    }

    // Validate medical info consistency
    if (data.bloodworkDate != null &&
        data.bloodworkDate!.isAfter(DateTime.now())) {
      errors.add(
        const ValidationError(
          message: 'Bloodwork date cannot be in the future',
          fieldName: 'bloodworkDate',
          type: ValidationErrorType.invalid,
        ),
      );
    }

    if (data.ckdDiagnosisDate != null &&
        data.ckdDiagnosisDate!.isAfter(DateTime.now())) {
      errors.add(
        const ValidationError(
          message: 'CKD diagnosis date cannot be in the future',
          fieldName: 'ckdDiagnosisDate',
          type: ValidationErrorType.invalid,
        ),
      );
    }

    // Validate lab values consistency
    final hasLabValues =
        data.creatinineMgDl != null ||
        data.bunMgDl != null ||
        data.sdmaMcgDl != null;

    if (hasLabValues && data.bloodworkDate == null) {
      errors.add(
        const ValidationError(
          message: 'Bloodwork date is required when lab values are provided',
          fieldName: 'bloodworkDate',
          type: ValidationErrorType.incomplete,
        ),
      );
    }

    return errors;
  }

  /// Gets user-friendly error messages for display
  ///
  /// Combines validation errors into actionable messages suitable for
  /// UI display.
  static List<String> getUserFriendlyErrorMessages(
    List<ValidationError> errors,
  ) {
    return errors.map((error) => error.message).toList();
  }

  /// Gets actionable errors that can be fixed by navigation
  static List<ValidationError> getActionableErrors(
    List<ValidationError> errors,
  ) {
    return errors.where((error) => error.hasAction).toList();
  }

  /// Gets the primary error message for display (first error or summary)
  static String getPrimaryErrorMessage(List<ValidationError> errors) {
    if (errors.isEmpty) return '';

    if (errors.length == 1) {
      return errors.first.message;
    }

    return 'Please complete ${errors.length} required fields to continue';
  }
}
