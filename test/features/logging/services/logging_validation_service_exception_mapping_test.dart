import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/core/validation/models/validation_result.dart';
import 'package:hydracat/features/logging/exceptions/logging_exceptions.dart';
import 'package:hydracat/features/logging/services/logging_validation_service.dart';

import '../../../helpers/test_data_builders.dart';

void main() {
  const validationService = LoggingValidationService();

  group('LoggingValidationService.toLoggingException', () {
    test('maps duplicate error to DuplicateSessionException with context', () {
      final duplicateSession = MedicationSessionBuilder()
          .withId('dup-1')
          .withMedicationName('Amlodipine')
          .withDateTime(DateTime(2025, 1, 1, 10))
          .withCreatedAt(DateTime(2025, 1, 1, 10, 1))
          .build();

      final result = ValidationResult.failure(const [
        ValidationError(
          message: 'Duplicate',
          fieldName: 'medication',
          type: ValidationErrorType.duplicate,
        ),
      ]);

      final ex = validationService.toLoggingException(
        result,
        duplicateSession: duplicateSession,
      );

      expect(ex, isA<DuplicateSessionException>());
      final dupEx = ex as DuplicateSessionException;
      expect(dupEx.sessionType, 'medication');
      expect(dupEx.medicationName, 'Amlodipine');
      expect(dupEx.conflictingTime, duplicateSession.dateTime);
      expect(dupEx.existingSession, isNotNull);
      expect((dupEx.existingSession as dynamic).id, 'dup-1');
    });

    test('maps non-duplicate errors to SessionValidationException', () {
      final result = ValidationResult.failure(const [
        ValidationError(
          message: 'Invalid dosage',
          fieldName: 'dosage',
          type: ValidationErrorType.invalid,
        ),
      ]);

      final ex = validationService.toLoggingException(result);
      expect(ex, isA<SessionValidationException>());
      final valEx = ex as SessionValidationException;
      expect(valEx.validationErrors.first, 'Invalid dosage');
    });
  });
}
