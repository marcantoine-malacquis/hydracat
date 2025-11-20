import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/core/validation/models/validation_result.dart';
import 'package:hydracat/features/logging/exceptions/logging_exceptions.dart';
import 'package:hydracat/features/logging/models/fluid_session.dart';
import 'package:hydracat/features/logging/models/medication_session.dart';
import 'package:hydracat/features/logging/services/logging_validation_service.dart';
import 'package:hydracat/features/onboarding/models/treatment_data.dart';

void main() {
  group('LoggingValidationService', () {
    late LoggingValidationService service;

    setUp(() {
      service = const LoggingValidationService();
    });

    group('validateForDuplicates', () {
      test('returns success when no duplicates exist (empty list)', () {
        final session = MedicationSession.create(
          petId: 'pet-123',
          userId: 'user-456',
          dateTime: DateTime(2024, 1, 15, 8),
          medicationName: 'Amlodipine',
          dosageGiven: 1,
          dosageScheduled: 1,
          medicationUnit: 'pills',
          completed: true,
        );

        final result = service.validateForDuplicates(
          newSession: session,
          recentSessions: [],
        );

        expect(result.isValid, true);
        expect(result.hasErrors, false);
      });

      test(
        'returns success when no duplicates exist (different medication)',
        () {
          final newSession = MedicationSession.create(
            petId: 'pet-123',
            userId: 'user-456',
            dateTime: DateTime(2024, 1, 15, 8),
            medicationName: 'Amlodipine',
            dosageGiven: 1,
            dosageScheduled: 1,
            medicationUnit: 'pills',
            completed: true,
          );

          final existingSession = MedicationSession.create(
            petId: 'pet-123',
            userId: 'user-456',
            dateTime: DateTime(2024, 1, 15, 8),
            medicationName: 'Benazepril', // Different medication
            dosageGiven: 1,
            dosageScheduled: 1,
            medicationUnit: 'pills',
            completed: true,
          );

          final result = service.validateForDuplicates(
            newSession: newSession,
            recentSessions: [existingSession],
          );

          expect(result.isValid, true);
          expect(result.hasErrors, false);
        },
      );

      test('returns success when same medication outside time window', () {
        final newSession = MedicationSession.create(
          petId: 'pet-123',
          userId: 'user-456',
          dateTime: DateTime(2024, 1, 15, 8),
          medicationName: 'Amlodipine',
          dosageGiven: 1,
          dosageScheduled: 1,
          medicationUnit: 'pills',
          completed: true,
        );

        // Existing session 20 minutes earlier
        // (outside default 15-minute window)
        final existingSession = MedicationSession.create(
          petId: 'pet-123',
          userId: 'user-456',
          dateTime: DateTime(2024, 1, 15, 7, 40), // 20 minutes before
          medicationName: 'Amlodipine',
          dosageGiven: 1,
          dosageScheduled: 1,
          medicationUnit: 'pills',
          completed: true,
        );

        final result = service.validateForDuplicates(
          newSession: newSession,
          recentSessions: [existingSession],
        );

        expect(result.isValid, true);
        expect(result.hasErrors, false);
      });

      test('returns failure when duplicate within 15 minutes', () {
        final newSession = MedicationSession.create(
          petId: 'pet-123',
          userId: 'user-456',
          dateTime: DateTime(2024, 1, 15, 8),
          medicationName: 'Amlodipine',
          dosageGiven: 1,
          dosageScheduled: 1,
          medicationUnit: 'pills',
          completed: true,
        );

        // Existing session 10 minutes earlier (within window)
        final existingSession = MedicationSession.create(
          petId: 'pet-123',
          userId: 'user-456',
          dateTime: DateTime(2024, 1, 15, 7, 50), // 10 minutes before
          medicationName: 'Amlodipine',
          dosageGiven: 1,
          dosageScheduled: 1,
          medicationUnit: 'pills',
          completed: true,
        );

        final result = service.validateForDuplicates(
          newSession: newSession,
          recentSessions: [existingSession],
        );

        expect(result.isValid, false);
        expect(result.hasErrors, true);
        expect(result.errors.length, 1);
        expect(result.errors.first.type, ValidationErrorType.duplicate);
        expect(result.errors.first.message, contains('Amlodipine'));
        expect(result.errors.first.message, contains('already logged'));
      });

      test('respects custom time window parameter', () {
        final newSession = MedicationSession.create(
          petId: 'pet-123',
          userId: 'user-456',
          dateTime: DateTime(2024, 1, 15, 8),
          medicationName: 'Amlodipine',
          dosageGiven: 1,
          dosageScheduled: 1,
          medicationUnit: 'pills',
          completed: true,
        );

        // Existing session 25 minutes earlier
        final existingSession = MedicationSession.create(
          petId: 'pet-123',
          userId: 'user-456',
          dateTime: DateTime(2024, 1, 15, 7, 35),
          medicationName: 'Amlodipine',
          dosageGiven: 1,
          dosageScheduled: 1,
          medicationUnit: 'pills',
          completed: true,
        );

        // With custom 30-minute window, this should be a duplicate
        final result = service.validateForDuplicates(
          newSession: newSession,
          recentSessions: [existingSession],
          timeWindow: const Duration(minutes: 30),
        );

        expect(result.isValid, false);
        expect(result.hasErrors, true);
      });

      test('is case-sensitive for medication names', () {
        final newSession = MedicationSession.create(
          petId: 'pet-123',
          userId: 'user-456',
          dateTime: DateTime(2024, 1, 15, 8),
          medicationName: 'amlodipine', // lowercase
          dosageGiven: 1,
          dosageScheduled: 1,
          medicationUnit: 'pills',
          completed: true,
        );

        final existingSession = MedicationSession.create(
          petId: 'pet-123',
          userId: 'user-456',
          dateTime: DateTime(2024, 1, 15, 8),
          medicationName: 'Amlodipine', // Capitalized
          dosageGiven: 1,
          dosageScheduled: 1,
          medicationUnit: 'pills',
          completed: true,
        );

        final result = service.validateForDuplicates(
          newSession: newSession,
          recentSessions: [existingSession],
        );

        // Should NOT be a duplicate (case-sensitive)
        expect(result.isValid, true);
      });
    });

    group('validateMedicationSession', () {
      test('returns success for valid session', () {
        final session = MedicationSession.create(
          petId: 'pet-123',
          userId: 'user-456',
          dateTime: DateTime.now().subtract(const Duration(hours: 1)),
          medicationName: 'Amlodipine',
          dosageGiven: 1,
          dosageScheduled: 1,
          medicationUnit: 'pills',
          completed: true,
        );

        final result = service.validateMedicationSession(session);

        expect(result.isValid, true);
        expect(result.hasErrors, false);
      });

      test('returns failure for medication name too short', () {
        final session = MedicationSession.create(
          petId: 'pet-123',
          userId: 'user-456',
          dateTime: DateTime.now(),
          medicationName: 'A', // Only 1 character
          dosageGiven: 1,
          dosageScheduled: 1,
          medicationUnit: 'pills',
          completed: true,
        );

        final result = service.validateMedicationSession(session);

        expect(result.isValid, false);
        expect(result.hasErrors, true);
        expect(
          result.errorMessage,
          contains('at least 2 characters'),
        );
      });

      test('returns failure for future date', () {
        final session = MedicationSession.create(
          petId: 'pet-123',
          userId: 'user-456',
          dateTime: DateTime.now().add(const Duration(hours: 1)), // Future
          medicationName: 'Amlodipine',
          dosageGiven: 1,
          dosageScheduled: 1,
          medicationUnit: 'pills',
          completed: true,
        );

        final result = service.validateMedicationSession(session);

        expect(result.isValid, false);
        expect(result.hasErrors, true);
        expect(result.errorMessage, contains('future'));
      });

      test('calls model validation and includes those errors', () {
        // Create session with negative dosage (invalid in model)
        final session = MedicationSession.create(
          petId: 'pet-123',
          userId: 'user-456',
          dateTime: DateTime.now(),
          medicationName: 'Amlodipine',
          dosageGiven: -1, // Invalid
          dosageScheduled: 1,
          medicationUnit: 'pills',
          completed: true,
        );

        final result = service.validateMedicationSession(session);

        expect(result.isValid, false);
        expect(result.hasErrors, true);
        expect(result.errorMessage, contains('negative'));
      });
    });

    group('validateFluidSession', () {
      test('returns success for valid session', () {
        final session = FluidSession.create(
          petId: 'pet-123',
          userId: 'user-456',
          dateTime: DateTime.now().subtract(const Duration(hours: 1)),
          volumeGiven: 100,
          injectionSite: FluidLocation.shoulderBladeLeft,
        );

        final result = service.validateFluidSession(session);

        expect(result.isValid, true);
        expect(result.hasErrors, false);
      });

      test('returns failure for future date', () {
        final session = FluidSession.create(
          petId: 'pet-123',
          userId: 'user-456',
          dateTime: DateTime.now().add(const Duration(hours: 1)), // Future
          volumeGiven: 100,
          injectionSite: FluidLocation.shoulderBladeLeft,
        );

        final result = service.validateFluidSession(session);

        expect(result.isValid, false);
        expect(result.hasErrors, true);
        expect(result.errorMessage, contains('future'));
      });

      test('calls model validation and includes those errors', () {
        // Create session with invalid volume (0ml - invalid in model)
        final session = FluidSession.create(
          petId: 'pet-123',
          userId: 'user-456',
          dateTime: DateTime.now(),
          volumeGiven: 0, // Invalid
          injectionSite: FluidLocation.shoulderBladeLeft,
        );

        final result = service.validateFluidSession(session);

        expect(result.isValid, false);
        expect(result.hasErrors, true);
      });
    });

    group('validateFluidVolume', () {
      test('validates range 1-500ml - valid values', () {
        expect(service.validateFluidVolume(volumeGiven: 1).isValid, true);
        expect(service.validateFluidVolume(volumeGiven: 100).isValid, true);
        expect(service.validateFluidVolume(volumeGiven: 250).isValid, true);
        expect(service.validateFluidVolume(volumeGiven: 500).isValid, true);
      });

      test('validates range 1-500ml - invalid values', () {
        expect(service.validateFluidVolume(volumeGiven: 0).isValid, false);
        expect(service.validateFluidVolume(volumeGiven: -10).isValid, false);
        expect(service.validateFluidVolume(volumeGiven: 600).isValid, false);
      });

      test('provides warnings for unusually low volumes', () {
        final result = service.validateFluidVolume(volumeGiven: 40);

        expect(result.isValid, true);
        expect(result.hasWarnings, true);
        expect(result.warningMessage, contains('quite low'));
      });

      test('provides warnings for unusually high volumes', () {
        final result = service.validateFluidVolume(volumeGiven: 350);

        expect(result.isValid, true);
        expect(result.hasWarnings, true);
        expect(result.warningMessage, contains('high'));
      });

      test('validates consistency with scheduled volume - close match', () {
        final result = service.validateFluidVolume(
          volumeGiven: 100,
          scheduledVolume: 120, // Within 50%
        );

        expect(result.isValid, true);
        expect(result.hasWarnings, false);
      });

      test(
        'validates consistency with scheduled volume - large difference',
        () {
          final result = service.validateFluidVolume(
            volumeGiven: 50,
            scheduledVolume: 200, // More than 50% different
          );

          expect(result.isValid, true);
          expect(result.hasWarnings, true);
          expect(result.warningMessage, contains('differs significantly'));
          expect(result.warningMessage, contains('200'));
        },
      );

      test('no consistency check when scheduledVolume is null', () {
        final result = service.validateFluidVolume(
          volumeGiven: 100,
        );

        expect(result.isValid, true);
        expect(result.hasWarnings, false);
      });
    });

    group('validateMedicationDosage', () {
      test('validates positive dosages', () {
        expect(
          service
              .validateMedicationDosage(
                dosageGiven: 1,
                dosageScheduled: 1,
                medicationUnit: 'pills',
              )
              .isValid,
          true,
        );
        expect(
          service
              .validateMedicationDosage(
                dosageGiven: 0.5,
                dosageScheduled: 1,
                medicationUnit: 'pills',
              )
              .isValid,
          true,
        );
      });

      test('rejects negative dosages', () {
        final result = service.validateMedicationDosage(
          dosageGiven: -1,
          dosageScheduled: 1,
          medicationUnit: 'pills',
        );

        expect(result.isValid, false);
        expect(result.errorMessage, contains('negative'));
      });

      test('rejects unrealistically high dosages', () {
        final result = service.validateMedicationDosage(
          dosageGiven: 150,
          dosageScheduled: 1,
          medicationUnit: 'pills',
        );

        expect(result.isValid, false);
        expect(result.errorMessage, contains('unrealistically high'));
      });

      test('provides warning for zero dosage', () {
        final result = service.validateMedicationDosage(
          dosageGiven: 0,
          dosageScheduled: 1,
          medicationUnit: 'pills',
        );

        expect(result.isValid, true);
        expect(result.hasWarnings, true);
        expect(result.warningMessage, contains('missed'));
      });

      test('provides warning for large deviation from schedule', () {
        final result = service.validateMedicationDosage(
          dosageGiven: 0.3,
          dosageScheduled: 1, // 70% difference
          medicationUnit: 'pills',
        );

        expect(result.isValid, true);
        expect(result.hasWarnings, true);
        expect(result.warningMessage, contains('differs significantly'));
      });
    });

    group('validateScheduleConsistency', () {
      test('returns success when no scheduled time (manual log)', () {
        final result = service.validateScheduleConsistency(
          sessionTime: DateTime.now(),
          scheduledTime: null,
        );

        expect(result.isValid, true);
        expect(result.hasWarnings, false);
      });

      test('returns success for session within 2 hour window', () {
        final scheduledTime = DateTime(2024, 1, 15, 8);
        final sessionTime = DateTime(2024, 1, 15, 9, 30); // 1.5 hours later

        final result = service.validateScheduleConsistency(
          sessionTime: sessionTime,
          scheduledTime: scheduledTime,
        );

        expect(result.isValid, true);
        expect(result.hasWarnings, false);
      });

      test('provides warning for large time drift', () {
        final scheduledTime = DateTime(2024, 1, 15, 8);
        final sessionTime = DateTime(2024, 1, 15, 12); // 4 hours later

        final result = service.validateScheduleConsistency(
          sessionTime: sessionTime,
          scheduledTime: scheduledTime,
        );

        expect(result.isValid, true);
        expect(result.hasWarnings, true);
        expect(result.warningMessage, contains('4h different'));
        expect(result.warningMessage, contains('adherence tracking'));
      });

      test('respects custom maxDrift parameter', () {
        final scheduledTime = DateTime(2024, 1, 15, 8);
        final sessionTime = DateTime(2024, 1, 15, 9, 30); // 1.5 hours later

        // With 1 hour max drift, this should trigger a warning
        final result = service.validateScheduleConsistency(
          sessionTime: sessionTime,
          scheduledTime: scheduledTime,
          maxDrift: const Duration(hours: 1),
        );

        expect(result.isValid, true);
        expect(result.hasWarnings, true);
      });
    });

    group('toLoggingException', () {
      test('throws ArgumentError for valid ValidationResult', () {
        const validResult = ValidationResult.success();

        expect(
          () => service.toLoggingException(validResult),
          throwsArgumentError,
        );
      });

      test('converts duplicate error to DuplicateSessionException', () {
        final duplicateResult = ValidationResult.failure(const [
          ValidationError(
            message:
                "You've already logged Amlodipine today. "
                'Would you like to update it instead?',
            fieldName: 'medication',
            type: ValidationErrorType.duplicate,
          ),
        ]);

        final exception = service.toLoggingException(duplicateResult);

        expect(exception, isA<DuplicateSessionException>());
        final duplicateException = exception as DuplicateSessionException;
        expect(duplicateException.medicationName, 'Amlodipine');
      });

      test('converts general errors to SessionValidationException', () {
        final errorResult = ValidationResult.failure(const [
          ValidationError(
            message: 'Dosage cannot be negative',
            fieldName: 'dosage',
            type: ValidationErrorType.invalid,
          ),
          ValidationError(
            message: 'Medication name is required',
            fieldName: 'medicationName',
          ),
        ]);

        final exception = service.toLoggingException(errorResult);

        expect(exception, isA<SessionValidationException>());
        final validationException = exception as SessionValidationException;
        expect(validationException.validationErrors.length, 2);
        expect(
          validationException.validationErrors.first,
          contains('Dosage cannot be negative'),
        );
      });
    });
  });
}
