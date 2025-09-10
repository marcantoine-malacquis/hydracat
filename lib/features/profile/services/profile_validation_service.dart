/// Medical data validation service for pet profiles
///
/// Provides comprehensive validation for CKD-specific medical data
/// with veterinary-appropriate rules and user-friendly error messages.
library;

import 'package:hydracat/features/profile/exceptions/profile_exceptions.dart';
import 'package:hydracat/features/profile/models/cat_profile.dart';
import 'package:hydracat/features/profile/models/medical_info.dart';

/// Result of a validation operation
class ValidationResult {
  /// Creates a [ValidationResult]
  const ValidationResult({
    required this.isValid,
    this.errors = const [],
    this.warnings = const [],
  });

  /// Creates a successful validation result
  const ValidationResult.success()
    : isValid = true,
      errors = const [],
      warnings = const [];

  /// Creates a failed validation result with errors
  const ValidationResult.failure(this.errors)
    : isValid = false,
      warnings = const [];

  /// Creates a validation result with warnings but no errors
  const ValidationResult.withWarnings(this.warnings)
    : isValid = true,
      errors = const [];

  /// Whether the validation passed
  final bool isValid;

  /// List of validation error messages
  final List<String> errors;

  /// List of validation warning messages (non-blocking)
  final List<String> warnings;

  /// Whether there are any warnings
  bool get hasWarnings => warnings.isNotEmpty;

  /// Combined error message for display
  String get errorMessage => errors.isEmpty ? '' : errors.join('\n');

  /// Combined warning message for display
  String get warningMessage => warnings.isEmpty ? '' : warnings.join('\n');
}

/// Service for validating pet profile and medical data
class ProfileValidationService {
  /// Creates a [ProfileValidationService] instance
  const ProfileValidationService();

  /// Validates a complete pet profile
  ValidationResult validateProfile(CatProfile profile) {
    final errors = <String>[];
    final warnings = <String>[];

    // Validate basic pet information
    final nameResult = validatePetName(profile.name);
    if (!nameResult.isValid) errors.addAll(nameResult.errors);
    warnings.addAll(nameResult.warnings);

    final ageResult = validateAge(profile.ageYears);
    if (!ageResult.isValid) errors.addAll(ageResult.errors);
    warnings.addAll(ageResult.warnings);

    final weightResult = validateWeight(profile.weightKg);
    if (!weightResult.isValid) errors.addAll(weightResult.errors);
    warnings.addAll(weightResult.warnings);

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
    final errors = <String>[];
    final warnings = <String>[];

    // Required field validation
    if (name.trim().isEmpty) {
      errors.add('Pet name is required');
      return ValidationResult.failure(errors);
    }

    final trimmedName = name.trim();

    // Length validation
    if (trimmedName.length < 2) {
      errors.add('Pet name must be at least 2 characters long');
    } else if (trimmedName.length > 50) {
      errors.add('Pet name must be 50 characters or less');
    }

    // Character validation
    final nameRegex = RegExp(r"^[a-zA-Z0-9\s\-'.,]+$");
    if (!nameRegex.hasMatch(trimmedName)) {
      errors.add(
        'Pet name contains invalid characters. '
        'Only letters, numbers, spaces, hyphens, apostrophes, '
        'periods, and commas are allowed',
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
    final errors = <String>[];
    final warnings = <String>[];

    // Basic range validation
    if (ageYears < 0) {
      errors.add('Age cannot be negative');
    } else if (ageYears > 30) {
      errors.add(
        'Age of $ageYears years exceeds typical cat lifespan. '
        'Please double-check this value',
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
    final errors = <String>[];
    final warnings = <String>[];

    // Basic range validation
    if (weightKg <= 0) {
      errors.add('Weight must be greater than 0');
    } else if (weightKg > 15) {
      errors.add(
        'Weight of ${weightKg.toStringAsFixed(1)}kg is extremely '
        'high for a cat. Please verify this is correct',
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
    final errors = <String>[];
    final warnings = <String>[];

    // Use the built-in validation from the model
    final modelErrors = medicalInfo.validate();
    errors.addAll(modelErrors);

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
    final errors = <String>[];
    final warnings = <String>[];

    final now = DateTime.now();

    // Future date validation
    if (diagnosisDate.isAfter(now)) {
      errors.add('CKD diagnosis date cannot be in the future');
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
    final errors = <String>[];
    final warnings = <String>[];

    // Age vs diagnosis date consistency
    if (profile.medicalInfo.ckdDiagnosisDate != null) {
      final diagnosisDate = profile.medicalInfo.ckdDiagnosisDate!;
      final yearsSinceDiagnosis =
          DateTime.now().difference(diagnosisDate).inDays / 365.25;

      if (yearsSinceDiagnosis > profile.ageYears) {
        errors.add(
          'CKD diagnosis date suggests your pet was diagnosed '
          'before they were born. Please check the age or diagnosis date',
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
    if (profile.ageYears < 1 && profile.weightKg > 6) {
      warnings.add('Weight seems high for a kitten under 1 year old');
    } else if (profile.ageYears > 15 && profile.weightKg < 2.0) {
      warnings.add(
        'Weight seems low for a senior cat. '
        'Consider monitoring nutrition closely',
      );
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
      final weightKg = weight / 2.20462;
      return validateWeight(weightKg);
    } else if (unit.toLowerCase() == 'kg' ||
        unit.toLowerCase() == 'kilograms') {
      return validateWeight(weight);
    } else {
      return ValidationResult.failure([
        'Unsupported weight unit: $unit. Please use kg or lbs',
      ]);
    }
  }

  /// Creates a ProfileValidationException from validation results
  ProfileValidationException createValidationException(
    ValidationResult result,
  ) {
    if (result.isValid) {
      throw ArgumentError('Cannot create exception from valid result');
    }
    return ProfileValidationException(result.errors);
  }
}
