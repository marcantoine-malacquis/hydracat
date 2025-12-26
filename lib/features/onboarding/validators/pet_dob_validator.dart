/// Validator for pet date of birth onboarding step
///
/// Ensures that a valid date of birth is provided.
library;

import 'package:hydracat/core/validation/models/validation_result.dart';
import 'package:hydracat/features/onboarding/flow/step_validator.dart';
import 'package:hydracat/features/onboarding/models/onboarding_data.dart';

/// Validates pet date of birth step requirements
///
/// Required fields:
/// - Date of birth (must be in the past, pet age < 30 years)
class PetDobValidator extends BaseStepValidator {
  /// Creates a [PetDobValidator]
  const PetDobValidator();

  @override
  List<String> getMissingFields(OnboardingData data) {
    final missing = <String>[];

    // Date of birth is required
    if (data.petDateOfBirth == null) {
      missing.add('Date of birth');
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

    // Additional validation rules
    final errors = <ValidationError>[];

    if (data.petDateOfBirth != null) {
      final now = DateTime.now();

      // Check if date is in the future
      if (data.petDateOfBirth!.isAfter(now)) {
        errors.add(
          const ValidationError(
            message: 'Date of birth cannot be in the future',
            fieldName: 'Date of birth',
            type: ValidationErrorType.invalid,
          ),
        );
      }

      // Check if pet age is unreasonably high (> 30 years)
      final age = now.difference(data.petDateOfBirth!).inDays ~/ 365;
      if (age > 30) {
        errors.add(
          const ValidationError(
            message: 'Pet age seems unusually high. Please verify.',
            fieldName: 'Date of birth',
            type: ValidationErrorType.invalid,
          ),
        );
      }
    }

    if (errors.isNotEmpty) {
      return ValidationResult.failure(errors);
    }

    return const ValidationResult.success();
  }
}
