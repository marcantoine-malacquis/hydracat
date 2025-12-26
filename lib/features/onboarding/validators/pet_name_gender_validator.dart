/// Validator for pet name and gender onboarding step
///
/// Ensures that pet name and gender are provided before allowing
/// progression to the next step.
library;

import 'package:hydracat/core/validation/models/validation_result.dart';
import 'package:hydracat/features/onboarding/flow/step_validator.dart';
import 'package:hydracat/features/onboarding/models/onboarding_data.dart';

/// Validates pet name and gender step requirements
///
/// Required fields:
/// - Pet name (non-empty, max 50 characters)
/// - Gender (non-empty)
class PetNameGenderValidator extends BaseStepValidator {
  /// Creates a [PetNameGenderValidator]
  const PetNameGenderValidator();

  @override
  List<String> getMissingFields(OnboardingData data) {
    final missing = <String>[];

    // Pet name is required
    if (data.petName == null || data.petName!.trim().isEmpty) {
      missing.add('Pet name');
    }

    // Gender is required
    if (data.petGender == null || data.petGender!.isEmpty) {
      missing.add('Gender');
    }

    return missing;
  }

  @override
  ValidationResult validate(OnboardingData data) {
    final missing = getMissingFields(data);

    if (missing.isNotEmpty) {
      return ValidationResult.failure(
        missing
            .map(
              (field) => ValidationError(
                message: '$field is required',
                fieldName: field,
              ),
            )
            .toList(),
      );
    }

    // Additional validation rules beyond missing fields
    final errors = <ValidationError>[];

    if (data.petName != null && data.petName!.length > 50) {
      errors.add(
        const ValidationError(
          message: 'Pet name must be 50 characters or less',
          fieldName: 'Pet name',
          type: ValidationErrorType.invalid,
        ),
      );
    }

    if (errors.isNotEmpty) {
      return ValidationResult.failure(errors);
    }

    return const ValidationResult.success();
  }
}
