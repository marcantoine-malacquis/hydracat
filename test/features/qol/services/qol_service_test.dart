/// Unit tests for QolService Firebase CRUD operations.
///
/// Tests:
/// - Batch writes include all 4 documents (assessment + 3 summaries)
/// - Error handling throws QolServiceException
/// - Analytics events fired at correct times
/// - Validation errors propagate correctly
library;

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/features/qol/exceptions/qol_exceptions.dart';
import 'package:hydracat/features/qol/models/qol_assessment.dart';
import 'package:hydracat/features/qol/models/qol_response.dart';
import 'package:hydracat/features/qol/services/qol_service.dart';
import 'package:hydracat/providers/analytics_provider.dart';
import 'package:mocktail/mocktail.dart';

class MockAnalyticsService extends Mock implements AnalyticsService {}

void main() {
  group('QolService', () {
    late FakeFirebaseFirestore fakeFirestore;
    late MockAnalyticsService mockAnalytics;
    late QolService service;

    const testUserId = 'user123';
    const testPetId = 'pet456';
    final testDate = DateTime(2025, 1, 15);

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      mockAnalytics = MockAnalyticsService();

      // Default analytics mocks
      when(
        () => mockAnalytics.trackQolAssessmentCompleted(
          overallScore: any(named: 'overallScore'),
          completionDurationSeconds: any(named: 'completionDurationSeconds'),
          answeredCount: any(named: 'answeredCount'),
          hasLowConfidenceDomain: any(named: 'hasLowConfidenceDomain'),
          petId: any(named: 'petId'),
        ),
      ).thenAnswer((_) async {});

      when(
        () => mockAnalytics.trackQolAssessmentUpdated(
          assessmentDate: any(named: 'assessmentDate'),
          petId: any(named: 'petId'),
        ),
      ).thenAnswer((_) async {});

      when(
        () => mockAnalytics.trackQolAssessmentDeleted(
          assessmentDate: any(named: 'assessmentDate'),
          petId: any(named: 'petId'),
        ),
      ).thenAnswer((_) async {});

      service = QolService(
        firestore: fakeFirestore,
        analyticsService: mockAnalytics,
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

    group('saveAssessment', () {
      test('should write assessment document to Firestore', () async {
        final assessment = createCompleteAssessment();

        await service.saveAssessment(assessment);

        final doc = await fakeFirestore
            .collection('users')
            .doc(testUserId)
            .collection('pets')
            .doc(testPetId)
            .collection('qolAssessments')
            .doc('2025-01-15')
            .get();

        expect(doc.exists, isTrue);
        expect(doc.data()!['id'], 'test-assessment-id');
        expect(doc.data()!['userId'], testUserId);
        expect(doc.data()!['petId'], testPetId);
      });

      test('should update daily summary with denormalized scores', () async {
        final assessment = createCompleteAssessment();

        await service.saveAssessment(assessment);

        final dailyDoc = await fakeFirestore
            .collection('users')
            .doc(testUserId)
            .collection('pets')
            .doc(testPetId)
            .collection('treatmentSummaries')
            .doc('daily')
            .collection('summaries')
            .doc('2025-01-15')
            .get();

        expect(dailyDoc.exists, isTrue);
        expect(dailyDoc.data()!['hasQolAssessment'], isTrue);
        expect(dailyDoc.data()!['qolOverallScore'], isNotNull);
        expect(dailyDoc.data()!['qolVitalityScore'], isNotNull);
        expect(dailyDoc.data()!['qolComfortScore'], isNotNull);
        expect(dailyDoc.data()!['qolEmotionalScore'], isNotNull);
        expect(dailyDoc.data()!['qolAppetiteScore'], isNotNull);
        expect(dailyDoc.data()!['qolTreatmentBurdenScore'], isNotNull);
      });

      test('should update weekly summary with timestamp', () async {
        final assessment = createCompleteAssessment();

        await service.saveAssessment(assessment);

        // Get all weekly summaries to find the one created
        final weeklySummaries = await fakeFirestore
            .collection('users')
            .doc(testUserId)
            .collection('pets')
            .doc(testPetId)
            .collection('treatmentSummaries')
            .doc('weekly')
            .collection('summaries')
            .get();

        expect(weeklySummaries.docs.length, greaterThan(0));
        final weeklyDoc = weeklySummaries.docs.first;
        expect(weeklyDoc.data()['updatedAt'], isNotNull);
      });

      test('should update monthly summary with timestamp', () async {
        final assessment = createCompleteAssessment();

        await service.saveAssessment(assessment);

        final monthlyDoc = await fakeFirestore
            .collection('users')
            .doc(testUserId)
            .collection('pets')
            .doc(testPetId)
            .collection('treatmentSummaries')
            .doc('monthly')
            .collection('summaries')
            .doc('2025-01')
            .get();

        expect(monthlyDoc.exists, isTrue);
        expect(monthlyDoc.data()!['updatedAt'], isNotNull);
      });

      test('should track analytics event on completion', () async {
        final assessment = createCompleteAssessment(
          completionDurationSeconds: 180,
        );

        await service.saveAssessment(assessment);

        verify(
          () => mockAnalytics.trackQolAssessmentCompleted(
            overallScore: any(named: 'overallScore'),
            completionDurationSeconds: 180,
            answeredCount: 14,
            hasLowConfidenceDomain: false,
            petId: testPetId,
          ),
        ).called(1);
      });

      test(
        'should throw QolValidationException for invalid assessment',
        () async {
          final invalidAssessment = QolAssessment(
            id: 'test-id',
            userId: testUserId,
            petId: testPetId,
            date: DateTime.now().add(const Duration(days: 1)), // Future date
            responses: const [],
            createdAt: DateTime.now(),
          );

          await expectLater(
            service.saveAssessment(invalidAssessment),
            throwsA(isA<QolValidationException>()),
          );
        },
      );

      // Note: Firestore error testing is deferred to integration tests
      // as fake_cloud_firestore doesn't support terminate()
      // for error simulation
    });

    group('getAssessment', () {
      test('should return assessment when exists', () async {
        final assessment = createCompleteAssessment();

        // Pre-populate Firestore
        await fakeFirestore
            .collection('users')
            .doc(testUserId)
            .collection('pets')
            .doc(testPetId)
            .collection('qolAssessments')
            .doc('2025-01-15')
            .set(assessment.toJson());

        final result = await service.getAssessment(
          testUserId,
          testPetId,
          testDate,
        );

        expect(result, isNotNull);
        expect(result!.id, assessment.id);
        expect(result.userId, testUserId);
        expect(result.responses.length, 14);
      });

      test('should return null when assessment does not exist', () async {
        final result = await service.getAssessment(
          testUserId,
          testPetId,
          testDate,
        );

        expect(result, isNull);
      });

      // Note: Firestore error testing is deferred to integration tests
      // as fake_cloud_firestore doesn't support terminate()
      // for error simulation
    });

    group('getRecentAssessments', () {
      test('should return assessments ordered by date descending', () async {
        final assessment1 = createCompleteAssessment(
          date: DateTime(2025, 1, 15),
        );
        final assessment2 = createCompleteAssessment(
          date: DateTime(2025, 1, 20),
        );
        final assessment3 = createCompleteAssessment(
          date: DateTime(2025, 1, 10),
        );

        // Pre-populate Firestore
        await fakeFirestore
            .collection('users')
            .doc(testUserId)
            .collection('pets')
            .doc(testPetId)
            .collection('qolAssessments')
            .doc('2025-01-15')
            .set(assessment1.toJson());
        await fakeFirestore
            .collection('users')
            .doc(testUserId)
            .collection('pets')
            .doc(testPetId)
            .collection('qolAssessments')
            .doc('2025-01-20')
            .set(assessment2.toJson());
        await fakeFirestore
            .collection('users')
            .doc(testUserId)
            .collection('pets')
            .doc(testPetId)
            .collection('qolAssessments')
            .doc('2025-01-10')
            .set(assessment3.toJson());

        final results = await service.getRecentAssessments(
          testUserId,
          testPetId,
          limit: 10,
        );

        expect(results.length, 3);
        // Should be ordered descending (newest first)
        expect(results[0].date, DateTime(2025, 1, 20));
        expect(results[1].date, DateTime(2025, 1, 15));
        expect(results[2].date, DateTime(2025, 1, 10));
      });

      test('should respect limit parameter', () async {
        // Create 5 assessments
        for (var i = 0; i < 5; i++) {
          final assessment = createCompleteAssessment(
            date: DateTime(2025, 1, 15 + i),
          );
          await fakeFirestore
              .collection('users')
              .doc(testUserId)
              .collection('pets')
              .doc(testPetId)
              .collection('qolAssessments')
              .doc('2025-01-${15 + i}')
              .set(assessment.toJson());
        }

        final results = await service.getRecentAssessments(
          testUserId,
          testPetId,
          limit: 3,
        );

        expect(results.length, 3);
      });

      test('should support pagination with startAfter', () async {
        // Create 3 assessments
        for (var i = 0; i < 3; i++) {
          final assessment = createCompleteAssessment(
            date: DateTime(2025, 1, 15 + i),
          );
          await fakeFirestore
              .collection('users')
              .doc(testUserId)
              .collection('pets')
              .doc(testPetId)
              .collection('qolAssessments')
              .doc('2025-01-${15 + i}')
              .set(assessment.toJson());
        }

        // First page
        final firstPage = await service.getRecentAssessments(
          testUserId,
          testPetId,
          limit: 2,
        );

        expect(firstPage.length, 2);
        expect(firstPage[0].date, DateTime(2025, 1, 17)); // Most recent
        expect(firstPage[1].date, DateTime(2025, 1, 16));

        // Second page - use the last date from first page
        final secondPage = await service.getRecentAssessments(
          testUserId,
          testPetId,
          limit: 2,
          startAfter: firstPage.last.date,
        );

        expect(secondPage.length, greaterThanOrEqualTo(1));
        // Should get the remaining assessment(s)
        expect(secondPage.any((a) => a.date == DateTime(2025, 1, 15)), isTrue);
      });

      // Note: Firestore error testing is deferred to integration tests
      // as fake_cloud_firestore doesn't support terminate()
      // for error simulation
    });

    group('updateAssessment', () {
      test('should update assessment document', () async {
        final original = createCompleteAssessment();
        await service.saveAssessment(original);

        final updated = original.copyWith(
          responses: [
            ...original.responses.take(13),
            const QolResponse(questionId: 'treatment_2', score: 4),
          ],
        );

        await service.updateAssessment(updated);

        final doc = await fakeFirestore
            .collection('users')
            .doc(testUserId)
            .collection('pets')
            .doc(testPetId)
            .collection('qolAssessments')
            .doc('2025-01-15')
            .get();

        expect(doc.exists, isTrue);
        expect(doc.data()!['updatedAt'], isNotNull);
      });

      test('should update daily summary with new scores', () async {
        final original = createCompleteAssessment();
        await service.saveAssessment(original);

        final updated = original.copyWith(
          responses: [
            ...original.responses.take(13),
            const QolResponse(questionId: 'treatment_2', score: 4),
          ],
        );

        await service.updateAssessment(updated);

        final dailyDoc = await fakeFirestore
            .collection('users')
            .doc(testUserId)
            .collection('pets')
            .doc(testPetId)
            .collection('treatmentSummaries')
            .doc('daily')
            .collection('summaries')
            .doc('2025-01-15')
            .get();

        expect(dailyDoc.exists, isTrue);
        expect(dailyDoc.data()!['hasQolAssessment'], isTrue);
      });

      test('should set completionDurationSeconds to null', () async {
        final original = createCompleteAssessment(
          completionDurationSeconds: 180,
        );
        await service.saveAssessment(original);

        final updated = original.copyWith(
          responses: [
            ...original.responses.take(13),
            const QolResponse(questionId: 'treatment_2', score: 4),
          ],
        );

        await service.updateAssessment(updated);

        final doc = await fakeFirestore
            .collection('users')
            .doc(testUserId)
            .collection('pets')
            .doc(testPetId)
            .collection('qolAssessments')
            .doc('2025-01-15')
            .get();

        // Edited assessments lose duration
        expect(doc.data()!['completionDurationSeconds'], isNull);
      });

      test('should track analytics event on update', () async {
        final original = createCompleteAssessment();
        await service.saveAssessment(original);

        final updated = original.copyWith(
          responses: [
            ...original.responses.take(13),
            const QolResponse(questionId: 'treatment_2', score: 4),
          ],
        );

        await service.updateAssessment(updated);

        verify(
          () => mockAnalytics.trackQolAssessmentUpdated(
            assessmentDate: '2025-01-15',
            petId: testPetId,
          ),
        ).called(1);
      });

      test(
        'should throw QolValidationException for invalid assessment',
        () async {
          final invalidAssessment = createCompleteAssessment().copyWith(
            date: DateTime.now().add(const Duration(days: 1)),
          );

          await expectLater(
            service.updateAssessment(invalidAssessment),
            throwsA(isA<QolValidationException>()),
          );
        },
      );
    });

    group('deleteAssessment', () {
      test('should delete assessment document', () async {
        final assessment = createCompleteAssessment();
        await service.saveAssessment(assessment);

        await service.deleteAssessment(testUserId, testPetId, testDate);

        final doc = await fakeFirestore
            .collection('users')
            .doc(testUserId)
            .collection('pets')
            .doc(testPetId)
            .collection('qolAssessments')
            .doc('2025-01-15')
            .get();

        expect(doc.exists, isFalse);
      });

      test('should clear QoL fields in daily summary', () async {
        final assessment = createCompleteAssessment();
        await service.saveAssessment(assessment);

        await service.deleteAssessment(testUserId, testPetId, testDate);

        final dailyDoc = await fakeFirestore
            .collection('users')
            .doc(testUserId)
            .collection('pets')
            .doc(testPetId)
            .collection('treatmentSummaries')
            .doc('daily')
            .collection('summaries')
            .doc('2025-01-15')
            .get();

        expect(dailyDoc.exists, isTrue);
        expect(dailyDoc.data()!['hasQolAssessment'], isFalse);
        expect(dailyDoc.data()!['qolOverallScore'], isNull);
        expect(dailyDoc.data()!['qolVitalityScore'], isNull);
        expect(dailyDoc.data()!['qolComfortScore'], isNull);
        expect(dailyDoc.data()!['qolEmotionalScore'], isNull);
        expect(dailyDoc.data()!['qolAppetiteScore'], isNull);
        expect(dailyDoc.data()!['qolTreatmentBurdenScore'], isNull);
      });

      test('should track analytics event on delete', () async {
        final assessment = createCompleteAssessment();
        await service.saveAssessment(assessment);

        await service.deleteAssessment(testUserId, testPetId, testDate);

        verify(
          () => mockAnalytics.trackQolAssessmentDeleted(
            assessmentDate: '2025-01-15',
            petId: testPetId,
          ),
        ).called(1);
      });

      // Note: Firestore error testing is deferred to integration tests
      // as fake_cloud_firestore doesn't support terminate()
      // for error simulation
    });

    group('watchLatestAssessment', () {
      test('should return stream of latest assessment', () async {
        final assessment = createCompleteAssessment();

        // Pre-populate Firestore
        await fakeFirestore
            .collection('users')
            .doc(testUserId)
            .collection('pets')
            .doc(testPetId)
            .collection('qolAssessments')
            .doc('2025-01-15')
            .set(assessment.toJson());

        final stream = service.watchLatestAssessment(testUserId, testPetId);

        final result = await stream.first;

        expect(result, isNotNull);
        expect(result!.id, assessment.id);
      });

      test('should return null stream when no assessments exist', () async {
        final stream = service.watchLatestAssessment(testUserId, testPetId);

        final result = await stream.first;

        expect(result, isNull);
      });
    });
  });
}
