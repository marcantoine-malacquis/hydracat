/// Validator for pet breed onboarding step
///
/// Breed is optional, so this validator always passes.
library;

import 'package:hydracat/features/onboarding/flow/step_validator.dart';
import 'package:hydracat/features/onboarding/models/onboarding_data.dart';

/// Validates pet breed step (optional field, always valid)
class PetBreedValidator extends BaseStepValidator {
  /// Creates a [PetBreedValidator]
  const PetBreedValidator();

  @override
  List<String> getMissingFields(OnboardingData data) {
    // Breed is optional, no required fields
    return [];
  }
}
