/// Medical data validation service for pet profiles
///
/// Provides comprehensive validation for CKD-specific medical data
/// with veterinary-appropriate rules and user-friendly error messages.
library;

import 'package:hydracat/core/utils/weight_utils.dart';
import 'package:hydracat/core/validation/models/validation_result.dart';
import 'package:hydracat/features/profile/exceptions/profile_exceptions.dart';
import 'package:hydracat/features/profile/models/cat_profile.dart';
import 'package:hydracat/features/profile/models/medical_info.dart';

/// Service for validating pet profile and medical data
class ProfileValidationService {
  /// Creates a [ProfileValidationService] instance
  const ProfileValidationService();

  /// Validates a complete pet profile
  ValidationResult validateProfile(CatProfile profile) {
    final errors = <ValidationError>[];
    final warnings = <String>[];

    // Validate basic pet information
    final nameResult = validatePetName(profile.name);
    if (!nameResult.isValid) errors.addAll(nameResult.errors);
    warnings.addAll(nameResult.warnings);

    final ageResult = validateAge(profile.ageYears);
    if (!ageResult.isValid) errors.addAll(ageResult.errors);
    warnings.addAll(ageResult.warnings);

    if (profile.weightKg != null) {
      final weightResult = validateWeight(profile.weightKg!);
      if (!weightResult.isValid) errors.addAll(weightResult.errors);
      warnings.addAll(weightResult.warnings);
    }

    // Validate medical information
    final medicalResult = validateMedicalInfo(profile.medicalInfo);
    if (!medicalResult.isValid) errors.addAll(medicalResult.errors);
    warnings.addAll(medicalResult.warnings);

    // Cross-validation between fields
    final crossResult = validateProfileConsistency(profile);
    if (!crossResult.isValid) errors.addAll(crossResult.errors);
    warnings.addAll(crossResult.warnings);

    if (errors.isNotEmpty) {
      return ValidationResult.failure(errors);
    } else if (warnings.isNotEmpty) {
      return ValidationResult.withWarnings(warnings);
    }

    return const ValidationResult.success();
  }

  /// Validates pet name
  ValidationResult validatePetName(String name) {
    final errors = <ValidationError>[];
    final warnings = <String>[];

    // Required field validation
    if (name.trim().isEmpty) {
      errors.add(
        const ValidationError(
          message: 'Pet name is required',
          fieldName: 'petName',
        ),
      );
      return ValidationResult.failure(errors);
    }

    final trimmedName = name.trim();

    // Length validation
    if (trimmedName.length < 2) {
      errors.add(
        const ValidationError(
          message: 'Pet name must be at least 2 characters long',
          fieldName: 'petName',
          type: ValidationErrorType.invalid,
        ),
      );
    } else if (trimmedName.length > 50) {
      errors.add(
        const ValidationError(
          message: 'Pet name must be 50 characters or less',
          fieldName: 'petName',
          type: ValidationErrorType.invalid,
        ),
      );
    }

    // Character validation
    final nameRegex = RegExp(r"^[a-zA-Z0-9\s\-'.,]+$");
    if (!nameRegex.hasMatch(trimmedName)) {
      errors.add(
        const ValidationError(
          message: 'Pet name contains invalid characters. '
              'Only letters, numbers, spaces, hyphens, apostrophes, '
              'periods, and commas are allowed',
          fieldName: 'petName',
          type: ValidationErrorType.invalid,
        ),
      );
    }

    // Warning for very long names
    if (trimmedName.length > 30) {
      warnings.add('Long names may not display well in some areas of the app');
    }

    // Warning for numbers in names (unusual but allowed)
    if (trimmedName.contains(RegExp(r'\d'))) {
      warnings.add('Names with numbers are unusual for pets');
    }

    if (errors.isNotEmpty) {
      return ValidationResult.failure(errors);
    } else if (warnings.isNotEmpty) {
      return ValidationResult.withWarnings(warnings);
    }

    return const ValidationResult.success();
  }

  /// Validates pet age in years
  ValidationResult validateAge(int ageYears) {
    final errors = <ValidationError>[];
    final warnings = <String>[];

    // Basic range validation
    if (ageYears < 0) {
      errors.add(
        const ValidationError(
          message: 'Age cannot be negative',
          fieldName: 'age',
          type: ValidationErrorType.invalid,
        ),
      );
    } else if (ageYears > 30) {
      errors.add(
        ValidationError(
          message: 'Age of $ageYears years exceeds typical cat lifespan. '
              'Please double-check this value',
          fieldName: 'age',
          type: ValidationErrorType.invalid,
        ),
      );
    }

    if (errors.isNotEmpty) {
      return ValidationResult.failure(errors);
    } else if (warnings.isNotEmpty) {
      return ValidationResult.withWarnings(warnings);
    }

    return const ValidationResult.success();
  }

  /// Validates pet weight in kilograms
  ValidationResult validateWeight(double weightKg) {
    final errors = <ValidationError>[];
    final warnings = <String>[];

    // Basic range validation
    if (weightKg <= 0) {
      errors.add(
        const ValidationError(
          message: 'Weight must be greater than 0',
          fieldName: 'weight',
          type: ValidationErrorType.invalid,
        ),
      );
    } else if (weightKg > 15) {
      errors.add(
        ValidationError(
          message: 'Weight of ${weightKg.toStringAsFixed(1)}kg is extremely '
              'high for a cat. Please verify this is correct',
          fieldName: 'weight',
          type: ValidationErrorType.invalid,
        ),
      );
    }

    // Weight concern ranges
    if (weightKg > 0 && weightKg < 1.5) {
      warnings.add(
        'Weight of ${weightKg.toStringAsFixed(1)}kg is quite low. '
        'Consider monitoring weight closely',
      );
    } else if (weightKg > 10) {
      warnings.add(
        'Weight of ${weightKg.toStringAsFixed(1)}kg is very high. '
        'Consider discussing weight management with your vet',
      );
    }

    // Precision warnings
    if (weightKg.toString().split('.').length > 1 &&
        weightKg.toString().split('.')[1].length > 2) {
      warnings.add('Weight precision beyond 0.01kg is typically unnecessary');
    }

    if (errors.isNotEmpty) {
      return ValidationResult.failure(errors);
    } else if (warnings.isNotEmpty) {
      return ValidationResult.withWarnings(warnings);
    }

    return const ValidationResult.success();
  }

  /// Validates medical information
  ValidationResult validateMedicalInfo(MedicalInfo medicalInfo) {
    final errors = <ValidationError>[];
    final warnings = <String>[];

    // Use the built-in validation from the model
    final modelErrors = medicalInfo.validate();
    // Convert string errors to ValidationError objects
    errors.addAll(
      modelErrors.map(
        (error) => ValidationError(
          message: error,
          fieldName: 'medicalInfo',
          type: ValidationErrorType.invalid,
        ),
      ),
    );

    // Additional CKD-specific validation
    if (medicalInfo.ckdDiagnosisDate != null) {
      final diagnosisResult = validateDiagnosisDate(
        medicalInfo.ckdDiagnosisDate!,
      );
      if (!diagnosisResult.isValid) errors.addAll(diagnosisResult.errors);
      warnings.addAll(diagnosisResult.warnings);
    }

    // IRIS stage warnings
    if (medicalInfo.irisStage != null) {
      final stage = medicalInfo.irisStage!;
      if (stage.stageNumber >= 3) {
        warnings.add(
          'IRIS Stage ${stage.stageNumber} indicates moderate to '
          'severe kidney disease. Close monitoring is important',
        );
      }
    }

    if (errors.isNotEmpty) {
      return ValidationResult.failure(errors);
    } else if (warnings.isNotEmpty) {
      return ValidationResult.withWarnings(warnings);
    }

    return const ValidationResult.success();
  }

  /// Validates CKD diagnosis date
  ValidationResult validateDiagnosisDate(DateTime diagnosisDate) {
    final errors = <ValidationError>[];
    final warnings = <String>[];

    final now = DateTime.now();

    // Future date validation
    if (diagnosisDate.isAfter(now)) {
      errors.add(
        const ValidationError(
          message: 'CKD diagnosis date cannot be in the future',
          fieldName: 'ckdDiagnosisDate',
          type: ValidationErrorType.invalid,
        ),
      );
    }

    // Very old diagnosis warning
    final yearsSinceDiagnosis = now.difference(diagnosisDate).inDays / 365.25;
    if (yearsSinceDiagnosis > 10) {
      warnings.add(
        'Diagnosis was over ${yearsSinceDiagnosis.round()} years '
        'ago. Consider if this date is correct',
      );
    }

    // Very recent diagnosis info
    if (yearsSinceDiagnosis < 0.1) {
      // Less than ~5 weeks
      warnings.add(
        'Recent CKD diagnosis. Your veterinarian may recommend '
        'frequent monitoring during this period',
      );
    }

    if (errors.isNotEmpty) {
      return ValidationResult.failure(errors);
    } else if (warnings.isNotEmpty) {
      return ValidationResult.withWarnings(warnings);
    }

    return const ValidationResult.success();
  }

  /// Validates consistency between different profile fields
  ValidationResult validateProfileConsistency(CatProfile profile) {
    final errors = <ValidationError>[];
    final warnings = <String>[];

    // Age vs diagnosis date consistency
    if (profile.medicalInfo.ckdDiagnosisDate != null) {
      final diagnosisDate = profile.medicalInfo.ckdDiagnosisDate!;
      final yearsSinceDiagnosis =
          DateTime.now().difference(diagnosisDate).inDays / 365.25;

      if (yearsSinceDiagnosis > profile.ageYears) {
        errors.add(
          const ValidationError(
            message: 'CKD diagnosis date suggests your pet was diagnosed '
                'before they were born. Please check the age or diagnosis date',
            fieldName: 'ckdDiagnosisDate',
            type: ValidationErrorType.inconsistent,
          ),
        );
      }

      // Warning if diagnosed very young
      final diagnosisAge = profile.ageYears - yearsSinceDiagnosis;
      if (diagnosisAge < 1) {
        warnings.add(
          'CKD diagnosis in very young cats is uncommon. '
          'Please confirm these dates with your veterinarian',
        );
      }
    }

    // Treatment approach vs medical completeness
    final hasDetailedMedical =
        profile.medicalInfo.ckdDiagnosisDate != null ||
        profile.medicalInfo.irisStage != null;

    if (!hasDetailedMedical) {
      warnings.add(
        'Adding diagnosis date and IRIS stage will help '
        'personalize treatment recommendations',
      );
    }

    // Weight vs age consistency warnings
    if (profile.weightKg != null) {
      if (profile.ageYears < 1 && profile.weightKg! > 6) {
        warnings.add('Weight seems high for a kitten under 1 year old');
      } else if (profile.ageYears > 15 && profile.weightKg! < 2.0) {
        warnings.add(
          'Weight seems low for a senior cat. '
          'Consider monitoring nutrition closely',
        );
      }
    }

    if (errors.isNotEmpty) {
      return ValidationResult.failure(errors);
    } else if (warnings.isNotEmpty) {
      return ValidationResult.withWarnings(warnings);
    }

    return const ValidationResult.success();
  }

  /// Validates weight conversion between units
  ValidationResult validateWeightConversion(
    double weight,
    String unit,
  ) {
    if (unit.toLowerCase() == 'lbs' || unit.toLowerCase() == 'pounds') {
      // Convert to kg for validation
      final weightKg = WeightUtils.convertLbsToKg(weight);
      return validateWeight(weightKg);
    } else if (unit.toLowerCase() == 'kg' ||
        unit.toLowerCase() == 'kilograms') {
      return validateWeight(weight);
    } else {
      return ValidationResult.failure([
        ValidationError(
          message: 'Unsupported weight unit: $unit. Please use kg or lbs',
          fieldName: 'weightUnit',
          type: ValidationErrorType.invalid,
        ),
      ]);
    }
  }

  /// Validates lab values input
  ValidationResult validateLabValues({
    double? creatinine,
    double? bun,
    double? sdma,
    DateTime? bloodworkDate,
  }) {
    final errors = <ValidationError>[];
    final warnings = <String>[];

    final hasValues = creatinine != null || bun != null || sdma != null;

    // If any lab values are provided, bloodwork date should be provided
    if (hasValues && bloodworkDate == null) {
      errors.add(
        const ValidationError(
          message: 'Bloodwork date is required when lab values are provided',
          fieldName: 'bloodworkDate',
        ),
      );
    }

    // Validate bloodwork date
    if (bloodworkDate != null && bloodworkDate.isAfter(DateTime.now())) {
      errors.add(
        const ValidationError(
          message: 'Bloodwork date cannot be in the future',
          fieldName: 'bloodworkDate',
          type: ValidationErrorType.invalid,
        ),
      );
    }

    // Validate creatinine (structural only)
    if (creatinine != null && creatinine <= 0) {
      errors.add(
        const ValidationError(
          message: 'Creatinine must be a positive number',
          fieldName: 'creatinine',
          type: ValidationErrorType.invalid,
        ),
      );
    }

    // Validate BUN (structural only)
    if (bun != null && bun <= 0) {
      errors.add(
        const ValidationError(
          message: 'BUN must be a positive number',
          fieldName: 'bun',
          type: ValidationErrorType.invalid,
        ),
      );
    }

    // Validate SDMA (structural only)
    if (sdma != null && sdma <= 0) {
      errors.add(
        const ValidationError(
          message: 'SDMA must be a positive number',
          fieldName: 'sdma',
          type: ValidationErrorType.invalid,
        ),
      );
    }

    if (errors.isNotEmpty) {
      return ValidationResult.failure(errors);
    } else if (warnings.isNotEmpty) {
      return ValidationResult.withWarnings(warnings);
    }

    return const ValidationResult.success();
  }

  /// Validates IRIS stage selection
  ValidationResult validateIrisStage(IrisStage? stage) {
    final warnings = <String>[];

    // No errors - IRIS stage is optional in most contexts
    if (stage != null && stage.stageNumber >= 3) {
      warnings.add(
        'IRIS Stage ${stage.stageNumber} indicates moderate to severe '
        'kidney disease. Close monitoring with your veterinarian is '
        'important',
      );
    }

    if (warnings.isNotEmpty) {
      return ValidationResult.withWarnings(warnings);
    }

    return const ValidationResult.success();
  }

  /// Validates checkup date
  ValidationResult validateCheckupDate(DateTime? checkupDate) {
    final errors = <ValidationError>[];
    final warnings = <String>[];

    if (checkupDate != null) {
      final now = DateTime.now();

      // Date cannot be in the future
      if (checkupDate.isAfter(now)) {
        errors.add(
          const ValidationError(
            message: 'Checkup date cannot be in the future',
            fieldName: 'checkupDate',
            type: ValidationErrorType.invalid,
          ),
        );
      }

      // Warning if checkup was very long ago
      final daysSinceCheckup = now.difference(checkupDate).inDays;
      if (daysSinceCheckup > 365) {
        warnings.add(
          'Last checkup was over a year ago. Regular checkups are '
          'important for CKD management',
        );
      }
    }

    if (errors.isNotEmpty) {
      return ValidationResult.failure(errors);
    } else if (warnings.isNotEmpty) {
      return ValidationResult.withWarnings(warnings);
    }

    return const ValidationResult.success();
  }

  /// Validates medical notes (basic length and content check)
  ValidationResult validateMedicalNotes(String? notes) {
    final warnings = <String>[];

    if (notes != null && notes.trim().isNotEmpty) {
      final trimmedNotes = notes.trim();

      // Warning for very long notes (might be better split up)
      if (trimmedNotes.length > 1000) {
        warnings.add(
          'Very long notes might be better organized in separate sections',
        );
      }
    }

    if (warnings.isNotEmpty) {
      return ValidationResult.withWarnings(warnings);
    }

    return const ValidationResult.success();
  }

  /// Creates a ProfileValidationException from validation results
  ProfileValidationException createValidationException(
    ValidationResult result,
  ) {
    if (result.isValid) {
      throw ArgumentError('Cannot create exception from valid result');
    }
    // Extract error messages from ValidationError objects
    final errorMessages = result.errors.map((e) => e.message).toList();
    return ProfileValidationException(errorMessages);
  }
}
