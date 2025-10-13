import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/features/logging/exceptions/logging_exceptions.dart';
import 'package:hydracat/features/logging/services/logging_service.dart';
import 'package:hydracat/features/logging/services/logging_validation_service.dart';
import 'package:hydracat/features/logging/services/summary_cache_service.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/test_data_builders.dart';

void main() {
  group('LoggingService duplicate handling', () {
    test(
      'throws DuplicateSessionException via converter with context',
      () async {
        final mockCache = _MockSummaryCacheService();
        const validation = LoggingValidationService();
        final service = LoggingService(mockCache, null, validation);

        final baseTime = DateTime(2025, 1, 1, 10);
        final existing = MedicationSessionBuilder()
            .withMedicationName('Amlodipine')
            .withDateTime(baseTime)
            .build();
        final newSession = MedicationSessionBuilder()
            .withMedicationName('Amlodipine')
            .withDateTime(baseTime.add(const Duration(minutes: 10)))
            .build();

        // Pretend todays recent sessions include the existing one
        final recent = [existing];

        await expectLater(
          service.logMedicationSession(
            userId: newSession.userId,
            petId: newSession.petId,
            session: newSession,
            todaysSchedules: const [],
            recentSessions: recent,
          ),
          throwsA(isA<DuplicateSessionException>()),
        );
      },
    );
  });
}

class _MockSummaryCacheService extends Mock implements SummaryCacheService {}
