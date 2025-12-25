/// Validator for pet basics onboarding step
///
/// Ensures that required pet information (name, age/DOB, gender) is
/// provided before allowing progression to the next step.
library;

import 'package:hydracat/core/validation/models/validation_result.dart';
import 'package:hydracat/features/onboarding/flow/step_validator.dart';
import 'package:hydracat/features/onboarding/models/onboarding_data.dart';

/// Validates pet basics step requirements
///
/// Required fields:
/// - Pet name (non-empty, max 50 characters)
/// - Pet age OR date of birth (age must be positive if provided)
/// - Gender (non-empty)
///
/// Optional fields:
/// - Breed
/// - Weight
class PetBasicsValidator extends BaseStepValidator {
  /// Creates a [PetBasicsValidator]
  const PetBasicsValidator();

  @override
  List<String> getMissingFields(OnboardingData data) {
    final missing = <String>[];

    // Pet name is required
    if (data.petName == null || data.petName!.trim().isEmpty) {
      missing.add('Pet name');
    }

    // Age OR date of birth is required
    if ((data.petAge == null || data.petAge! <= 0) &&
        data.petDateOfBirth == null) {
      missing.add('Pet age or date of birth');
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

    if (data.petAge != null && data.petAge! > 30) {
      errors.add(
        const ValidationError(
          message: 'Pet age seems unusually high. Please verify.',
          fieldName: 'Pet age',
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
