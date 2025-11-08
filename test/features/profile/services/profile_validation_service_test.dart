/// Unit tests for ProfileValidationService
///
/// Tests all validation rules for pet profiles including:
/// - Pet name validation
/// - Age validation
/// - Weight validation
/// - Medical information validation
/// - Lab values validation
/// - IRIS stage validation
/// - Cross-field consistency validation
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/features/profile/models/medical_info.dart';
import 'package:hydracat/features/profile/services/profile_validation_service.dart';

import '../../../helpers/profile_test_data_builders.dart';

void main() {
  group('ProfileValidationService', () {
    const service = ProfileValidationService();

    group('validatePetName', () {
      test('should accept valid pet name', () {
        final result = service.validatePetName('Fluffy');
        
        expect(result.isValid, isTrue);
        expect(result.errors, isEmpty);
      });

      test('should reject empty name', () {
        final result = service.validatePetName('');
        
        expect(result.isValid, isFalse);
        expect(result.errors, hasLength(1));
        expect(result.errors.first.message, contains('Pet name is required'));
        expect(result.errors.first.fieldName, equals('petName'));
      });

      test('should reject name with only whitespace', () {
        final result = service.validatePetName('   ');
        
        expect(result.isValid, isFalse);
        expect(result.errors.first.message, contains('Pet name is required'));
      });

      test('should reject name shorter than 2 characters', () {
        final result = service.validatePetName('F');
        
        expect(result.isValid, isFalse);
        expect(result.errors.first.message, 
            contains('Pet name must be at least 2 characters long'));
      });

      test('should reject name longer than 50 characters', () {
        final result = service.validatePetName('A' * 51);
        
        expect(result.isValid, isFalse);
        expect(
          result.errors.first.message, 
          contains('Pet name must be 50 characters or less'),
        );
      });

      test('should accept name exactly 50 characters', () {
        final result = service.validatePetName('A' * 50);
        
        expect(result.isValid, isTrue);
      });

      test('should trim whitespace from name', () {
        // The validation should work with trimmed names
        final result = service.validatePetName('  Fluffy  ');
        
        expect(result.isValid, isTrue);
      });
    });

    group('validateAge', () {
      test('should accept valid age', () {
        final result = service.validateAge(8);
        
        expect(result.isValid, isTrue);
        expect(result.errors, isEmpty);
      });

      test('should accept age 0 (kitten)', () {
        final result = service.validateAge(0);
        
        expect(result.isValid, isTrue);
      });

      test('should reject negative age', () {
        final result = service.validateAge(-1);
        
        expect(result.isValid, isFalse);
        expect(result.errors.first.message, contains('cannot be negative'));
      });

      test('should reject age over 30 years', () {
        final result = service.validateAge(31);
        
        expect(result.isValid, isFalse);
        expect(result.errors.first.message, contains('exceeds typical'));
      });

      test('should accept age exactly 30', () {
        final result = service.validateAge(30);
        
        expect(result.isValid, isTrue);
      });
    });

    group('validateWeight', () {
      test('should accept valid weight in normal range', () {
        final result = service.validateWeight(4.5); // kg (can be decimal)
        
        expect(result.isValid, isTrue);
        expect(result.errors, isEmpty);
      });

      test('should accept minimum weight (1.5 kg)', () {
        final result = service.validateWeight(1.5);
        
        expect(result.isValid, isTrue);
      });

      test('should accept maximum weight (15 kg)', () {
        final result = service.validateWeight(15);
        
        expect(result.isValid, isTrue);
      });

      test('should warn for low weight (<1.5 kg)', () {
        final result = service.validateWeight(1.4);
        
        expect(result.isValid, isTrue);
        expect(result.warnings, hasLength(1));
        expect(result.warnings.first, contains('quite low'));
      });

      test('should reject weight above maximum (>15 kg)', () {
        final result = service.validateWeight(16);
        
        expect(result.isValid, isFalse);
        expect(result.errors.first.message, contains('extremely high'));
      });

      test('should reject zero weight', () {
        final result = service.validateWeight(0);
        
        expect(result.isValid, isFalse);
        expect(result.errors.first.message, contains('greater than 0'));
      });

      test('should reject negative weight', () {
        final result = service.validateWeight(-1);
        
        expect(result.isValid, isFalse);
        expect(result.errors.first.message, contains('greater than 0'));
      });

      test('should warn for underweight cat (<1.5 kg)', () {
        final result = service.validateWeight(1);
        
        expect(result.isValid, isTrue);
        expect(result.warnings, hasLength(1));
        expect(result.warnings.first, contains('quite low'));
      });

      test('should warn for very heavy cat (>10 kg)', () {
        final result = service.validateWeight(11);
        
        expect(result.isValid, isTrue);
        expect(result.warnings, hasLength(1));
        expect(result.warnings.first, contains('very high'));
      });
    });

    group('validateLabValues', () {
      test('should accept complete valid lab values', () {
        final result = service.validateLabValues(
          creatinine: 2,
          bun: 30,
          sdma: 16,
          bloodworkDate: DateTime(2024, 1, 10),
        );
        
        expect(result.isValid, isTrue);
        expect(result.errors, isEmpty);
      });

      test('should require bloodwork date when lab values provided', () {
        final result = service.validateLabValues(
          creatinine: 2,
          bun: 30,
          sdma: 16,
        );
        
        expect(result.isValid, isFalse);
        expect(result.errors.first.message, 
            contains('Bloodwork date is required'));
      });

      test('should reject future bloodwork date', () {
        final futureDate = DateTime.now().add(const Duration(days: 1));
        final result = service.validateLabValues(
          creatinine: 2,
          bloodworkDate: futureDate,
        );
        
        expect(result.isValid, isFalse);
        expect(result.errors.first.message, 
            contains('Bloodwork date cannot be in the future'));
      });

      test('should reject negative creatinine', () {
        final result = service.validateLabValues(
          creatinine: -1,
          bloodworkDate: DateTime(2024, 1, 10),
        );
        
        expect(result.isValid, isFalse);
        expect(result.errors.first.message, 
            contains('Creatinine must be a positive number'));
      });

      test('should reject zero creatinine', () {
        final result = service.validateLabValues(
          creatinine: 0,
          bloodworkDate: DateTime(2024, 1, 10),
        );
        
        expect(result.isValid, isFalse);
      });

      test('should reject negative BUN', () {
        final result = service.validateLabValues(
          bun: -1,
          bloodworkDate: DateTime(2024, 1, 10),
        );
        
        expect(result.isValid, isFalse);
        expect(result.errors.first.message, 
            contains('BUN must be a positive number'));
      });

      test('should reject negative SDMA', () {
        final result = service.validateLabValues(
          sdma: -1,
          bloodworkDate: DateTime(2024, 1, 10),
        );
        
        expect(result.isValid, isFalse);
        expect(result.errors.first.message, 
            contains('SDMA must be a positive number'));
      });

      test('should accept null values (optional fields)', () {
        final result = service.validateLabValues();
        
        expect(result.isValid, isTrue);
      });

      test('should accept partial lab values with date', () {
        final result = service.validateLabValues(
          creatinine: 2,
          bloodworkDate: DateTime(2024, 1, 10),
        );
        
        expect(result.isValid, isTrue);
      });
    });

    group('validateIrisStage', () {
      test('should accept all valid IRIS stages', () {
        for (final stage in IrisStage.values) {
          final result = service.validateIrisStage(stage);
          expect(result.isValid, isTrue,
              reason: 'Stage $stage should be valid');
        }
      });

      test('should accept null IRIS stage (optional)', () {
        final result = service.validateIrisStage(null);
        
        expect(result.isValid, isTrue);
      });

      test('should warn for Stage 4 (severe)', () {
        final result = service.validateIrisStage(IrisStage.stage4);
        
        expect(result.isValid, isTrue);
        expect(result.warnings, isNotEmpty);
        expect(result.warnings.first, contains('IRIS Stage 4'));
      });
    });

    group('validateMedicalInfo', () {
      test('should accept valid complete medical info', () {
        final medicalInfo = MedicalInfoBuilder.complete().build();
        
        final result = service.validateMedicalInfo(medicalInfo);
        
        expect(result.isValid, isTrue);
      });

      test('should accept minimal medical info', () {
        const medicalInfo = MedicalInfo();
        
        final result = service.validateMedicalInfo(medicalInfo);
        
        expect(result.isValid, isTrue);
      });

      test('should reject future diagnosis date', () {
        final futureDate = DateTime.now().add(const Duration(days: 1));
        final medicalInfo = MedicalInfoBuilder()
            .withCkdDiagnosisDate(futureDate)
            .build();
        
        final result = service.validateMedicalInfo(medicalInfo);
        
        expect(result.isValid, isFalse);
        expect(result.errors.first.message, 
            contains('cannot be in the future'));
      });

      test('should validate lab values within medical info', () {
        final medicalInfo = MedicalInfoBuilder()
            .withLabValues(
              LabValuesBuilder()
                  .withCreatinine(-1) // Invalid
                  .withBloodworkDate(DateTime(2024, 1, 10))
                  .build(),
            )
            .build();
        
        final result = service.validateMedicalInfo(medicalInfo);
        
        expect(result.isValid, isFalse);
        expect(result.errors.first.message, 
            contains('Creatinine must be a positive number'));
      });
    });

    group('validateProfileConsistency', () {
      test('should accept consistent profile', () {
        final profile = CatProfileBuilder()
            .withAge(10)
            .withMedicalInfo(
              MedicalInfoBuilder()
                  .withCkdDiagnosisDate(DateTime(2022, 6, 15))
                  .build(),
            )
            .build();
        
        final result = service.validateProfileConsistency(profile);
        
        expect(result.isValid, isTrue);
      });

      test('should reject diagnosis date older than pet age', () {
        final profile = CatProfileBuilder()
            .withAge(5)
            .withMedicalInfo(
              MedicalInfoBuilder()
                  // ignore: avoid_redundant_argument_values - explicit day for clarity
                  .withCkdDiagnosisDate(DateTime(2010, 1, 1)) // 15 years ago
                  .build(),
            )
            .build();
        
        final result = service.validateProfileConsistency(profile);
        
        expect(result.isValid, isFalse);
        expect(
          result.errors.first.message, 
          contains('diagnosed before they were born'),
        );
      });

      test('should warn for very young CKD diagnosis', () {
        // Cat must be under 1 year old at diagnosis for warning
        final profile = CatProfileBuilder()
            .withAge(1)
            .withMedicalInfo(
              MedicalInfoBuilder()
                  .withCkdDiagnosisDate(
                    DateTime.now().subtract(
                      const Duration(days: 180), // ~6 months ago
                    ),
                  )
                  .build(),
            )
            .build();
        
        final result = service.validateProfileConsistency(profile);
        
        expect(result.isValid, isTrue);
        expect(result.warnings, isNotEmpty);
        expect(
          result.warnings.any((w) => w.contains('very young')),
          isTrue,
        );
      });

      test('should warn for low weight in senior cat', () {
        final profile = CatProfileBuilder()
            .withAge(16)
            .withWeight(1.8) // Below 2 kg threshold
            .build();
        
        final result = service.validateProfileConsistency(profile);
        
        expect(result.isValid, isTrue);
        expect(result.warnings, isNotEmpty);
        expect(
          result.warnings.any((w) => w.contains('senior')),
          isTrue,
        );
      });

      test('should warn for high weight in kitten', () {
        // Must be age < 1 (0 years) and weight > 6 kg for warning
        final profile = CatProfileBuilder()
            .withAge(0)
            .withWeight(6.5) // High for kitten under 1 year
            .build();
        
        final result = service.validateProfileConsistency(profile);
        
        // Should have warning about weight AND medical info incomplete
        expect(result.isValid, isTrue);
        expect(result.warnings, isNotEmpty);
        expect(
          result.warnings.any((w) => w.contains('high')),
          isTrue,
        );
      });

      test('should warn if medical info is incomplete', () {
        final profile = CatProfileBuilder()
            .withAge(10)
            .withMedicalInfo(const MedicalInfo()) // No diagnosis date or stage
            .build();
        
        final result = service.validateProfileConsistency(profile);
        
        expect(result.isValid, isTrue);
        expect(result.warnings, isNotEmpty);
        expect(result.warnings.any((w) => w.contains('diagnosis')), isTrue);
      });
    });

    group('validateProfile', () {
      test('should accept completely valid profile', () {
        final profile = CatProfileBuilder.valid().build();
        
        final result = service.validateProfile(profile);
        
        expect(result.isValid, isTrue);
        expect(result.errors, isEmpty);
      });

      test('should collect errors from all validation methods', () {
        final profile = CatProfileBuilder()
            .withName('') // Invalid name
            .withAge(-1) // Invalid age (negative)
            .withWeight(-1) // Invalid weight
            .build();
        
        final result = service.validateProfile(profile);
        
        expect(result.isValid, isFalse);
        // Should have at least 2 errors
        expect(result.errors.length, greaterThanOrEqualTo(2));
      });

      test('should collect warnings from all validation methods', () {
        final profile = CatProfileBuilder()
            .withAge(20) // Valid age
            .withWeight(1) // Low weight (warning)
            .withMedicalInfo(const MedicalInfo()) // Incomplete (warning)
            .build();
        
        final result = service.validateProfile(profile);
        
        expect(result.isValid, isTrue);
        expect(result.warnings.length, greaterThanOrEqualTo(1)); // Warnings
      });

      test('should validate cross-field consistency', () {
        final profile = CatProfileBuilder()
            .withAge(5)
            .withMedicalInfo(
              MedicalInfoBuilder()
                  // ignore: avoid_redundant_argument_values - explicit day for clarity
                  .withCkdDiagnosisDate(DateTime(2010, 1, 1)) // Before birth
                  .build(),
            )
            .build();
        
        final result = service.validateProfile(profile);
        
        expect(result.isValid, isFalse);
        expect(
          result.errors.any((e) => e.message.contains('born')),
          isTrue,
        );
      });

      test('should return success for profile with optional fields missing',
          () {
        final profile = CatProfileBuilder()
            .withName('Fluffy')
            .withAge(8)
            .withWeight(null) // Optional
            .withMedicalInfo(const MedicalInfo()) // Optional details
            .build();
        
        final result = service.validateProfile(profile);
        
        expect(result.isValid, isTrue);
      });
    });

    group('Edge Cases', () {
      test('should handle profile with boundary values', () {
        final profile = CatProfileBuilder()
            .withName('AB') // Minimum length
            .withAge(1) // Minimum age
            .withWeight(1.5) // Minimum weight
            .build();
        
        final result = service.validateProfile(profile);
        
        expect(result.isValid, isTrue);
      });

      test('should handle profile with maximum boundary values', () {
        final profile = CatProfileBuilder()
            .withName('A' * 50) // Maximum length
            .withAge(30) // Maximum age
            .withWeight(15) // Maximum weight
            .build();
        
        final result = service.validateProfile(profile);
        
        // May have warnings for long name or high weight
        expect(result.isValid, isTrue);
      });

      test('should handle profile with null optional fields', () {
        final profile = CatProfileBuilder()
            .withWeight(null)
            .withPhotoUrl(null)
            .withBreed(null)
            .withGender(null)
            .build();
        
        final result = service.validateProfile(profile);
        
        expect(result.isValid, isTrue);
      });
    });
  });
}
