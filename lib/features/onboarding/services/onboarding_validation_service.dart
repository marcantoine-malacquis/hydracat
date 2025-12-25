import 'package:hydracat/core/utils/date_utils.dart';
import 'package:hydracat/core/validation/models/validation_result.dart';
import 'package:hydracat/features/onboarding/models/onboarding_data.dart';
import 'package:hydracat/features/onboarding/models/onboarding_step_id.dart';

/// Centralized validation service for onboarding flow
///
/// Provides consistent validation logic across all onboarding screens
/// with actionable error messages.
///
/// Simplified to only validate pet basics and CKD medical information.
/// Treatment setup validation happens in separate profile screens.
class OnboardingValidationService {
  /// Private constructor to prevent instantiation
  OnboardingValidationService._();

  /// Validates the current onboarding step and returns actionable errors
  ///
  /// [data] - Current onboarding data
  /// [currentStep] - The step being validated
  static ValidationResult validateCurrentStep(
    OnboardingData data,
    OnboardingStepId currentStep,
  ) {
    final errors = <ValidationError>[];

    // Use runtime type checking instead of switch
    if (currentStep == OnboardingSteps.welcome) {
      // No validation required for welcome step
    } else if (currentStep == OnboardingSteps.petBasics) {
      errors.addAll(_validatePetBasics(data));
    } else if (currentStep == OnboardingSteps.medicalInfo) {
      // Medical info is optional, no validation required
    } else if (currentStep == OnboardingSteps.completion) {
      errors.addAll(_validateCompletion(data));
    }

    return errors.isEmpty
        ? const ValidationResult.success()
        : ValidationResult.failure(errors);
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

    // Gender validation (required)
    if (data.petGender == null || data.petGender!.isEmpty) {
      errors.add(
        const ValidationError(
          message: "Please select your cat's gender",
          fieldName: 'petGender',
        ),
      );
    } else if (data.petGender != 'male' && data.petGender != 'female') {
      errors.add(
        const ValidationError(
          message: 'Gender must be either male or female',
          fieldName: 'petGender',
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

  /// Validates completion step with comprehensive checks
  static List<ValidationError> _validateCompletion(OnboardingData data) {
    final errors = <ValidationError>[
      ..._validatePetBasics(data),
    ];

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
