/// Validator for onboarding completion step
///
/// Ensures that all required data for completing onboarding and
/// creating a pet profile is present and valid.
library;

import 'package:hydracat/core/validation/models/validation_result.dart';
import 'package:hydracat/features/onboarding/flow/step_validator.dart';
import 'package:hydracat/features/onboarding/models/onboarding_data.dart';

/// Validates that all required data is complete before finishing
///
/// This validator checks that all required fields from all previous steps
/// are present and valid, ensuring we can successfully create a pet profile.
class CompletionValidator extends BaseStepValidator {
  /// Creates a [CompletionValidator]
  const CompletionValidator();

  @override
  List<String> getMissingFields(OnboardingData data) {
    // Use the existing comprehensive validation from OnboardingData
    return data.getMissingRequiredFields();
  }

  @override
  ValidationResult validate(OnboardingData data) {
    if (data.isComplete) {
      return const ValidationResult.success();
    }

    final missing = getMissingFields(data);
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
}
