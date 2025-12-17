/// Unit tests for QoL provider state management.
///
/// Tests:
/// - Cache lifecycle (TTL, force refresh)
/// - Optimistic updates (save/update/delete)
/// - State transitions during loading/saving
/// - Error handling
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/features/auth/models/app_user.dart';
import 'package:hydracat/features/profile/models/cat_profile.dart';
import 'package:hydracat/features/qol/exceptions/qol_exceptions.dart';
import 'package:hydracat/features/qol/models/qol_assessment.dart';
import 'package:hydracat/features/qol/models/qol_response.dart';
import 'package:hydracat/features/qol/models/qol_state.dart';
import 'package:hydracat/features/qol/services/qol_service.dart';
import 'package:hydracat/providers/auth_provider.dart';
import 'package:hydracat/providers/profile_provider.dart';
import 'package:hydracat/providers/qol_provider.dart';
import 'package:mocktail/mocktail.dart';

class MockQolService extends Mock implements QolService {}

void main() {
  group('QolProvider', () {
    late MockQolService mockService;
    late AppUser testUser;
    late CatProfile testPet;

    const testUserId = 'user123';
    const testPetId = 'pet456';
    final testDate = DateTime(2025, 1, 15);

    setUp(() {
      mockService = MockQolService();

      testUser = const AppUser(
        id: testUserId,
        email: 'test@example.com',
      );

      testPet = CatProfile(
        id: testPetId,
        name: 'Test Cat',
        userId: testUserId,
        ageYears: 10,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    // Helper to create a complete assessment
    QolAssessment createCompleteAssessment({
      DateTime? date,
      int? completionDurationSeconds,
    }) {
      final responses = [
        // Vitality (3 questions)
        const QolResponse(questionId: 'vitality_1', score: 4),
        const QolResponse(questionId: 'vitality_2', score: 3),
        const QolResponse(questionId: 'vitality_3', score: 3),
        // Comfort (3 questions)
        const QolResponse(questionId: 'comfort_1', score: 4),
        const QolResponse(questionId: 'comfort_2', score: 4),
        const QolResponse(questionId: 'comfort_3', score: 3),
        // Emotional (3 questions)
        const QolResponse(questionId: 'emotional_1', score: 3),
        const QolResponse(questionId: 'emotional_2', score: 3),
        const QolResponse(questionId: 'emotional_3', score: 2),
        // Appetite (3 questions)
        const QolResponse(questionId: 'appetite_1', score: 4),
        const QolResponse(questionId: 'appetite_2', score: 3),
        const QolResponse(questionId: 'appetite_3', score: 3),
        // Treatment (2 questions)
        const QolResponse(questionId: 'treatment_1', score: 4),
        const QolResponse(questionId: 'treatment_2', score: 3),
      ];

      return QolAssessment(
        id: 'test-assessment-id',
        userId: testUserId,
        petId: testPetId,
        date: date ?? testDate,
        responses: responses,
        createdAt: DateTime.now(),
        completionDurationSeconds: completionDurationSeconds,
      );
    }

    ProviderContainer buildContainer({bool useTestConstructor = false}) {
      return ProviderContainer(
        overrides: [
          qolServiceProvider.overrideWithValue(mockService),
          currentUserProvider.overrideWithValue(testUser),
          primaryPetProvider.overrideWithValue(testPet),
          if (useTestConstructor)
            qolProvider.overrideWith(
              (ref) => QolNotifier.test(
                mockService,
                ref,
              ),
            ),
        ],
      );
    }

    group('loadRecentAssessments', () {
      test('should load assessments and update state', () async {
        final assessment1 = createCompleteAssessment(
          date: DateTime(2025, 1, 15),
        );
        final assessment2 = createCompleteAssessment(
          date: DateTime(2025, 1, 20),
        );

        when(
          () => mockService.getRecentAssessments(
            testUserId,
            testPetId,
          ),
        ).thenAnswer((_) async => [assessment2, assessment1]);

        final container = buildContainer();
        addTearDown(container.dispose);

        final notifier = container.read(qolProvider.notifier);
        await notifier.loadRecentAssessments();

        final state = container.read(qolProvider);
        expect(state.recentAssessments.length, 2);
        expect(state.currentAssessment, assessment2); // Most recent
        expect(state.isLoading, isFalse);
        expect(state.error, isNull);
        expect(state.lastFetchTime, isNotNull);
      });

      test('should use cached data if fresh (<5 minutes)', () async {
        final assessment = createCompleteAssessment();

        when(
          () => mockService.getRecentAssessments(
            testUserId,
            testPetId,
          ),
        ).thenAnswer((_) async => [assessment]);

        final container = buildContainer(useTestConstructor: true);
        addTearDown(container.dispose);

        final notifier = container.read(qolProvider.notifier);

        // First load
        await notifier.loadRecentAssessments();
        final firstLoadTime = container.read(qolProvider).lastFetchTime;

        // Second load (should use cache)
        await notifier.loadRecentAssessments();
        final secondLoadTime = container.read(qolProvider).lastFetchTime;

        // Should only call service once (first load)
        verify(
          () => mockService.getRecentAssessments(testUserId, testPetId),
        ).called(1);

        // lastFetchTime should be unchanged
        expect(secondLoadTime, firstLoadTime);
      });

      test('should force refresh when forceRefresh=true', () async {
        final assessment = createCompleteAssessment();

        when(
          () => mockService.getRecentAssessments(
            testUserId,
            testPetId,
          ),
        ).thenAnswer((_) async => [assessment]);

        final container = buildContainer(useTestConstructor: true);
        addTearDown(container.dispose);

        final notifier = container.read(qolProvider.notifier);

        // First load
        await notifier.loadRecentAssessments();

        // Force refresh
        await notifier.loadRecentAssessments(forceRefresh: true);

        // Should call service twice (first load + force refresh)
        verify(
          () => mockService.getRecentAssessments(testUserId, testPetId),
        ).called(2);
      });

      test('should handle error and set error state', () async {
        when(
          () => mockService.getRecentAssessments(
            testUserId,
            testPetId,
          ),
        ).thenThrow(const QolServiceException('Network error'));

        final container = buildContainer();
        addTearDown(container.dispose);

        final notifier = container.read(qolProvider.notifier);
        await notifier.loadRecentAssessments();

        final state = container.read(qolProvider);
        expect(state.isLoading, isFalse);
        expect(state.error, 'Network error');
      });

      test('should return early if user or pet is null', () async {
        final container = ProviderContainer(
          overrides: [
            qolServiceProvider.overrideWithValue(mockService),
            currentUserProvider.overrideWithValue(null),
            primaryPetProvider.overrideWithValue(testPet),
          ],
        );
        addTearDown(container.dispose);

        final notifier = container.read(qolProvider.notifier);
        await notifier.loadRecentAssessments();

        // Should not call service
        verifyNever(
          () => mockService.getRecentAssessments(any(), any()),
        );

        final state = container.read(qolProvider);
        expect(state.error, 'User or pet not found');
      });
    });

    group('saveAssessment', () {
      test('should optimistically update state before saving', () async {
        final assessment = createCompleteAssessment();

        when(
          () => mockService.getRecentAssessments(
            testUserId,
            testPetId,
          ),
        ).thenAnswer((_) async => []);

        when(
          () => mockService.saveAssessment(assessment),
        ).thenAnswer((_) async {});

        final container = buildContainer(useTestConstructor: true);
        addTearDown(container.dispose);

        final notifier = container.read(qolProvider.notifier);

        // Pre-populate with existing assessments
        await notifier.loadRecentAssessments();

        await notifier.saveAssessment(assessment);

        final state = container.read(qolProvider);
        expect(state.recentAssessments.first, assessment);
        expect(state.currentAssessment, assessment);
        expect(state.isSaving, isFalse);
        expect(state.error, isNull);
      });

      test('should revert optimistic update on error', () async {
        final existingAssessment = createCompleteAssessment(
          date: DateTime(2025, 1, 10),
        );
        final newAssessment = createCompleteAssessment(
          date: DateTime(2025, 1, 15),
        );

        when(
          () => mockService.getRecentAssessments(
            testUserId,
            testPetId,
          ),
        ).thenAnswer((_) async => [existingAssessment]);

        when(
          () => mockService.saveAssessment(newAssessment),
        ).thenThrow(const QolServiceException('Save failed'));

        final container = buildContainer();
        addTearDown(container.dispose);

        final notifier = container.read(qolProvider.notifier);

        // Pre-populate
        await notifier.loadRecentAssessments();

        // Attempt save (should fail)
        await expectLater(
          notifier.saveAssessment(newAssessment),
          throwsA(isA<QolServiceException>()),
        );

        // Should revert to original state
        final state = container.read(qolProvider);
        expect(state.recentAssessments.length, 1);
        expect(state.recentAssessments.first, existingAssessment);
        expect(state.error, 'Save failed');
      });

      test('should handle validation errors', () async {
        final invalidAssessment = createCompleteAssessment().copyWith(
          date: DateTime.now().add(const Duration(days: 1)),
        );

        when(
          () => mockService.getRecentAssessments(
            testUserId,
            testPetId,
          ),
        ).thenAnswer((_) async => []);

        when(
          () => mockService.saveAssessment(invalidAssessment),
        ).thenThrow(const QolValidationException('Future date not allowed'));

        final container = buildContainer(useTestConstructor: true);
        addTearDown(container.dispose);

        final notifier = container.read(qolProvider.notifier);

        await expectLater(
          notifier.saveAssessment(invalidAssessment),
          throwsA(isA<QolValidationException>()),
        );

        final state = container.read(qolProvider);
        expect(state.error, 'Future date not allowed');
      });
    });

    group('updateAssessment', () {
      test('should optimistically update state before updating', () async {
        final original = createCompleteAssessment(
          date: DateTime(2025, 1, 15),
        );
        final updated = original.copyWith(
          responses: [
            ...original.responses.take(13),
            const QolResponse(questionId: 'treatment_2', score: 4),
          ],
        );

        when(
          () => mockService.getRecentAssessments(
            testUserId,
            testPetId,
          ),
        ).thenAnswer((_) async => [original]);

        when(
          () => mockService.updateAssessment(updated),
        ).thenAnswer((_) async {});

        final container = buildContainer();
        addTearDown(container.dispose);

        final notifier = container.read(qolProvider.notifier);

        // Pre-populate
        await notifier.loadRecentAssessments();

        await notifier.updateAssessment(updated);

        final state = container.read(qolProvider);
        expect(state.recentAssessments.first, updated);
        expect(state.currentAssessment, updated);
        expect(state.isSaving, isFalse);
      });

      test('should revert optimistic update on error', () async {
        final original = createCompleteAssessment(
          date: DateTime(2025, 1, 15),
        );
        final updated = original.copyWith(
          responses: [
            ...original.responses.take(13),
            const QolResponse(questionId: 'treatment_2', score: 4),
          ],
        );

        when(
          () => mockService.getRecentAssessments(
            testUserId,
            testPetId,
          ),
        ).thenAnswer((_) async => [original]);

        when(
          () => mockService.updateAssessment(updated),
        ).thenThrow(const QolServiceException('Update failed'));

        final container = buildContainer();
        addTearDown(container.dispose);

        final notifier = container.read(qolProvider.notifier);

        // Pre-populate
        await notifier.loadRecentAssessments();

        await expectLater(
          notifier.updateAssessment(updated),
          throwsA(isA<QolServiceException>()),
        );

        // Should revert
        final state = container.read(qolProvider);
        expect(state.recentAssessments.first, original);
        expect(state.error, 'Update failed');
      });
    });

    group('deleteAssessment', () {
      test('should optimistically remove assessment from state', () async {
        final assessment1 = createCompleteAssessment(
          date: DateTime(2025, 1, 15),
        );
        final assessment2 = createCompleteAssessment(
          date: DateTime(2025, 1, 20),
        );

        when(
          () => mockService.getRecentAssessments(
            testUserId,
            testPetId,
          ),
        ).thenAnswer((_) async => [assessment2, assessment1]);

        when(
          () => mockService.deleteAssessment(
            testUserId,
            testPetId,
            assessment1.date,
          ),
        ).thenAnswer((_) async {});

        final container = buildContainer();
        addTearDown(container.dispose);

        final notifier = container.read(qolProvider.notifier);

        // Pre-populate
        await notifier.loadRecentAssessments();

        await notifier.deleteAssessment(assessment1.documentId);

        final state = container.read(qolProvider);
        expect(state.recentAssessments.length, 1);
        expect(state.recentAssessments.first, assessment2);
        expect(state.currentAssessment, assessment2);
        expect(state.isSaving, isFalse);
      });

      test(
        'should set currentAssessment to null if deleting last assessment',
        () async {
          final assessment = createCompleteAssessment();

          when(
            () => mockService.getRecentAssessments(
              testUserId,
              testPetId,
            ),
          ).thenAnswer((_) async => [assessment]);

          when(
            () => mockService.deleteAssessment(
              testUserId,
              testPetId,
              assessment.date,
            ),
          ).thenAnswer((_) async {});

          final container = buildContainer();
          addTearDown(container.dispose);

          final notifier = container.read(qolProvider.notifier);

          // Pre-populate
          await notifier.loadRecentAssessments();

          await notifier.deleteAssessment(assessment.documentId);

          final state = container.read(qolProvider);
          expect(state.recentAssessments, isEmpty);
          expect(state.currentAssessment, isNull);
        },
      );

      test('should revert optimistic update on error', () async {
        final assessment = createCompleteAssessment();

        when(
          () => mockService.getRecentAssessments(
            testUserId,
            testPetId,
          ),
        ).thenAnswer((_) async => [assessment]);

        when(
          () => mockService.deleteAssessment(
            testUserId,
            testPetId,
            assessment.date,
          ),
        ).thenThrow(const QolServiceException('Delete failed'));

        final container = buildContainer();
        addTearDown(container.dispose);

        final notifier = container.read(qolProvider.notifier);

        // Pre-populate
        await notifier.loadRecentAssessments();

        await expectLater(
          notifier.deleteAssessment(assessment.documentId),
          throwsA(isA<QolServiceException>()),
        );

        // Should revert
        final state = container.read(qolProvider);
        expect(state.recentAssessments.length, 1);
        expect(state.recentAssessments.first, assessment);
        expect(state.error, 'Delete failed');
      });
    });

    group('getTrendData', () {
      test('should return trend summaries for valid assessments', () {
        final assessment1 = createCompleteAssessment(
          date: DateTime(2025, 1, 15),
        );
        final assessment2 = createCompleteAssessment(
          date: DateTime(2025, 1, 20),
        );

        final container = buildContainer(useTestConstructor: true);
        addTearDown(container.dispose);

        final notifier = container.read(qolProvider.notifier)
          // Set state directly for testing
          ..state = QolState(
            recentAssessments: [assessment2, assessment1],
            currentAssessment: assessment2,
          );

        final trends = notifier.getTrendData();

        expect(trends.length, 2);
        expect(trends[0].date, assessment2.date);
        expect(trends[1].date, assessment1.date);
        expect(trends[0].overallScore, isNotNull);
        expect(trends[0].domainScores, isNotEmpty);
      });

      test('should filter out assessments with null overall scores', () {
        final validAssessment = createCompleteAssessment();
        final invalidAssessment = QolAssessment(
          id: 'invalid-id',
          userId: testUserId,
          petId: testPetId,
          date: DateTime(2025, 1, 10),
          responses: const [
            QolResponse(questionId: 'vitality_1', score: 4),
            // Only 1 question answered, not enough for domain score
          ],
          createdAt: DateTime.now(),
        );

        final container = buildContainer(useTestConstructor: true);
        addTearDown(container.dispose);

        final notifier = container.read(qolProvider.notifier)
          ..state = QolState(
            recentAssessments: [validAssessment, invalidAssessment],
          );

        final trends = notifier.getTrendData();

        expect(trends.length, 1);
        expect(trends[0].date, validAssessment.date);
      });

      test('should respect limit parameter', () {
        final assessments = List.generate(
          15,
          (i) => createCompleteAssessment(
            date: DateTime(2025, 1, 15 + i),
          ),
        );

        final container = buildContainer(useTestConstructor: true);
        addTearDown(container.dispose);

        final notifier = container.read(qolProvider.notifier)
          ..state = QolState(
            recentAssessments: assessments,
          );

        final trends = notifier.getTrendData();

        expect(trends.length, 12);
      });
    });

    group('clearError', () {
      test('should clear error from state', () {
        final container = buildContainer(useTestConstructor: true);
        addTearDown(container.dispose);

        // Set error state and clear it
        container.read(qolProvider.notifier)
          ..state = const QolState(error: 'Test error')
          ..clearError();

        final state = container.read(qolProvider);
        expect(state.error, isNull);
      });
    });

    group('state computed properties', () {
      test('isCacheFresh should return true when <5 minutes old', () {
        final container = buildContainer(useTestConstructor: true);
        addTearDown(container.dispose);

        final notifier = container.read(qolProvider.notifier)
          ..state = QolState(
            lastFetchTime: DateTime.now().subtract(const Duration(minutes: 3)),
          );

        expect(notifier.state.isCacheFresh, isTrue);
      });

      test('isCacheFresh should return false when >5 minutes old', () {
        final container = buildContainer(useTestConstructor: true);
        addTearDown(container.dispose);

        final notifier = container.read(qolProvider.notifier)
          ..state = QolState(
            lastFetchTime: DateTime.now().subtract(const Duration(minutes: 6)),
          );

        expect(notifier.state.isCacheFresh, isFalse);
      });

      test('hasAssessments should return true when assessments exist', () {
        final container = buildContainer(useTestConstructor: true);
        addTearDown(container.dispose);

        final notifier = container.read(qolProvider.notifier)
          ..state = QolState(
            recentAssessments: [createCompleteAssessment()],
          );

        expect(notifier.state.hasAssessments, isTrue);
      });

      test('isReady should return true when not loading and no error', () {
        final container = buildContainer(useTestConstructor: true);
        addTearDown(container.dispose);

        final notifier = container.read(qolProvider.notifier)
          ..state = const QolState();

        expect(notifier.state.isReady, isTrue);
      });
    });
  });
}
