/// Validator for pet weight onboarding step
///
/// Weight is optional, so this validator always passes.
library;

import 'package:hydracat/features/onboarding/flow/step_validator.dart';
import 'package:hydracat/features/onboarding/models/onboarding_data.dart';

/// Validates pet weight step (optional field, always valid)
class PetWeightValidator extends BaseStepValidator {
  /// Creates a [PetWeightValidator]
  const PetWeightValidator();

  @override
  List<String> getMissingFields(OnboardingData data) {
    // Weight is optional, no required fields
    return [];
  }
}
