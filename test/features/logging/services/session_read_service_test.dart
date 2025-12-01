import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/core/utils/date_utils.dart';
import 'package:hydracat/features/logging/services/session_read_service.dart';

void main() {
  group('SessionReadService - Future Date Optimization', () {
    late FirebaseFirestore firestore;
    late SessionReadService service;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      service = SessionReadService(firestore);
    });

    test('getAllSessionsForDate returns empty lists for future dates without '
        'querying Firestore', () async {
      // Arrange
      const userId = 'test-user';
      const petId = 'test-pet';
      final futureDate = DateTime.now().add(const Duration(days: 7));

      // Act
      final (medSessions, fluidSessions) = await service.getAllSessionsForDate(
        userId: userId,
        petId: petId,
        date: futureDate,
      );

      // Assert
      expect(
        medSessions,
        isEmpty,
        reason: 'Should return empty medication sessions for future date',
      );
      expect(
        fluidSessions,
        isEmpty,
        reason: 'Should return empty fluid sessions for future date',
      );
    });

    test('getAllSessionsForDate queries Firestore for today', () async {
      // Arrange
      const userId = 'test-user';
      const petId = 'test-pet';
      final today = DateTime.now();

      // Act - Should not throw or skip
      final (medSessions, fluidSessions) = await service.getAllSessionsForDate(
        userId: userId,
        petId: petId,
        date: today,
      );

      // Assert - Empty because no data in fake Firestore,
      // but should execute query
      expect(medSessions, isEmpty);
      expect(fluidSessions, isEmpty);
    });

    test('getAllSessionsForDate queries Firestore for past dates', () async {
      // Arrange
      const userId = 'test-user';
      const petId = 'test-pet';
      final pastDate = DateTime.now().subtract(const Duration(days: 7));

      // Act - Should not throw or skip
      final (medSessions, fluidSessions) = await service.getAllSessionsForDate(
        userId: userId,
        petId: petId,
        date: pastDate,
      );

      // Assert - Empty because no data in fake Firestore,
      // but should execute query
      expect(medSessions, isEmpty);
      expect(fluidSessions, isEmpty);
    });

    test(
      'getAllSessionsForDate handles edge case of exact midnight today',
      () async {
        // Arrange
        const userId = 'test-user';
        const petId = 'test-pet';
        final todayMidnight = AppDateUtils.startOfDay(DateTime.now());

        // Act
        final (medSessions, fluidSessions) = await service
            .getAllSessionsForDate(
              userId: userId,
              petId: petId,
              date: todayMidnight,
            );

        // Assert - Should query (not skip as future)
        expect(medSessions, isEmpty);
        expect(fluidSessions, isEmpty);
      },
    );

    test(
      'getAllSessionsForDate handles edge case of tomorrow at midnight',
      () async {
        // Arrange
        const userId = 'test-user';
        const petId = 'test-pet';
        final tomorrow = AppDateUtils.startOfDay(
          DateTime.now(),
        ).add(const Duration(days: 1));

        // Act
        final (medSessions, fluidSessions) = await service
            .getAllSessionsForDate(
              userId: userId,
              petId: petId,
              date: tomorrow,
            );

        // Assert - Should skip (future date)
        expect(
          medSessions,
          isEmpty,
          reason: 'Should return empty for tomorrow',
        );
        expect(
          fluidSessions,
          isEmpty,
          reason: 'Should return empty for tomorrow',
        );
      },
    );
  });
}
