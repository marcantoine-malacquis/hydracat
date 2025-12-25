/// Step validation interface and base implementations
///
/// Provides a consistent validation strategy across all onboarding steps
/// with customizable validation logic per step.
library;

import 'package:hydracat/core/validation/models/validation_result.dart';
import 'package:hydracat/features/onboarding/models/onboarding_data.dart';

/// Interface for step-specific validation
///
/// Each onboarding step can have its own validator that implements this
/// interface to define what data is required for that step.
abstract class StepValidator {
  /// Validates the data for this step
  ///
  /// Returns [ValidationResult.valid()] if data is valid,
  /// or [ValidationResult.invalid()] with error messages if not.
  ValidationResult validate(OnboardingData data);

  /// Gets list of missing required fields for user-friendly error messages
  ///
  /// Returns a list of human-readable field names that are required but
  /// missing. Used to generate specific error messages for the user.
  List<String> getMissingFields(OnboardingData data);

  /// Quick check if step data is valid (for progress indicators)
  ///
  /// This is a convenience method that returns true if validate() returns
  /// a valid result. Can be overridden for performance if validation is
  /// expensive.
  bool isValid(OnboardingData data) => validate(data).isValid;
}

/// Base validator with common helpers
///
/// Provides a default implementation of [validate] that converts
/// missing fields into a [ValidationResult]. Most validators can extend
/// this class and only implement [getMissingFields].
abstract class BaseStepValidator implements StepValidator {
  /// Creates a [BaseStepValidator]
  const BaseStepValidator();

  @override
  ValidationResult validate(OnboardingData data) {
    final missing = getMissingFields(data);

    if (missing.isEmpty) {
      return const ValidationResult.success();
    }

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

  @override
  bool isValid(OnboardingData data) => validate(data).isValid;
}

/// Validator for steps with no required data (always valid)
///
/// Use this for optional steps that don't require any specific data
/// to be present before moving to the next step.
class AlwaysValidValidator extends BaseStepValidator {
  /// Creates an [AlwaysValidValidator]
  const AlwaysValidValidator();

  @override
  List<String> getMissingFields(OnboardingData data) => [];
}
