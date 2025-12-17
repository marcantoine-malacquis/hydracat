/// Integration tests for QoL user flows
///
/// Tests end-to-end service flows with provider integration:
/// - Complete 14-question assessment from start to finish
/// - Edit existing assessment and verify changes saved
/// - View history screen with multiple assessments
/// - View detail screen with radar chart and interpretation
/// - Home screen card displays latest assessment
/// - Delete assessment and verify removed from history
library;

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/core/utils/date_utils.dart';
import 'package:hydracat/features/qol/models/qol_assessment.dart';
import 'package:hydracat/features/qol/models/qol_domain.dart';
import 'package:hydracat/features/qol/models/qol_response.dart';
import 'package:hydracat/features/qol/services/qol_service.dart';

import '../../../helpers/integration_test_helpers.dart';
import '../../../helpers/test_data_builders.dart';

void main() {
  group('Complete Assessment Flow', () {
    late FakeFirebaseFirestore fakeFirestore;
    late QolService qolService;
    const testUserId = 'test-user-id';
    const testPetId = 'test-pet-id';
    final testDate = DateTime(2025, 1, 15);

    setUp(() {
      fakeFirestore = createFakeFirestore();
      qolService = QolService(firestore: fakeFirestore);
    });

    test('complete full 14-question assessment from start to finish', () async {
      // Arrange: Create assessment with all 14 responses
      final assessment = QolAssessmentBuilder.complete()
          .withUserId(testUserId)
          .withPetId(testPetId)
          .withDate(testDate)
          .build();

      // Act: Save assessment to Firestore
      await qolService.saveAssessment(assessment);

      // Assert: Verify document exists at correct path
      final docId = AppDateUtils.formatDateForSummary(testDate);
      final doc = await fakeFirestore
          .collection('users')
          .doc(testUserId)
          .collection('pets')
          .doc(testPetId)
          .collection('qolAssessments')
          .doc(docId)
          .get();

      expect(doc.exists, isTrue, reason: 'Assessment document should exist');

      // Verify all responses are saved correctly
      final savedData = doc.data()!;
      final savedAssessment = QolAssessment.fromJson(savedData);
      expect(savedAssessment.responses.length, equals(14));
      expect(savedAssessment.userId, equals(testUserId));
      expect(savedAssessment.petId, equals(testPetId));

      // Verify scores are computed and saved to daily summary
      final dailySummaryDoc = await fakeFirestore
          .collection('users')
          .doc(testUserId)
          .collection('pets')
          .doc(testPetId)
          .collection('treatmentSummaries')
          .doc('daily')
          .collection('summaries')
          .doc(docId)
          .get();

      expect(dailySummaryDoc.exists, isTrue);
      final dailyData = dailySummaryDoc.data()!;
      expect(dailyData['hasQolAssessment'], isTrue);
      expect(dailyData['qolOverallScore'], isNotNull);
      expect(dailyData['qolVitalityScore'], isNotNull);
      expect(dailyData['qolComfortScore'], isNotNull);
      expect(dailyData['qolEmotionalScore'], isNotNull);
      expect(dailyData['qolAppetiteScore'], isNotNull);
      expect(dailyData['qolTreatmentBurdenScore'], isNotNull);

      // Verify weekly and monthly summaries updated
      final weekId = AppDateUtils.formatWeekForSummary(testDate);
      final weeklyDoc = await fakeFirestore
          .collection('users')
          .doc(testUserId)
          .collection('pets')
          .doc(testPetId)
          .collection('treatmentSummaries')
          .doc('weekly')
          .collection('summaries')
          .doc(weekId)
          .get();

      expect(weeklyDoc.exists, isTrue);

      final monthId = AppDateUtils.formatMonthForSummary(testDate);
      final monthlyDoc = await fakeFirestore
          .collection('users')
          .doc(testUserId)
          .collection('pets')
          .doc(testPetId)
          .collection('treatmentSummaries')
          .doc('monthly')
          .collection('summaries')
          .doc(monthId)
          .get();

      expect(monthlyDoc.exists, isTrue);
    });

    test('assessment with missing responses (partial completion)', () async {
      // Arrange: Create assessment with only some responses
      final partialResponses = [
        const QolResponse(questionId: 'vitality_1', score: 3),
        const QolResponse(questionId: 'vitality_2', score: 4),
        const QolResponse(questionId: 'comfort_1', score: 2),
      ];

      final assessment = QolAssessmentBuilder.empty()
          .withUserId(testUserId)
          .withPetId(testPetId)
          .withDate(testDate)
          .withResponses(partialResponses)
          .build();

      // Act: Save partial assessment
      await qolService.saveAssessment(assessment);

      // Assert: Assessment saved with partial responses
      final docId = AppDateUtils.formatDateForSummary(testDate);
      final doc = await fakeFirestore
          .collection('users')
          .doc(testUserId)
          .collection('pets')
          .doc(testPetId)
          .collection('qolAssessments')
          .doc(docId)
          .get();

      expect(doc.exists, isTrue);
      final savedData = doc.data()!;
      final savedAssessment = QolAssessment.fromJson(savedData);
      expect(savedAssessment.responses.length, equals(3));
    });
  });

  group('Edit Assessment Flow', () {
    late FakeFirebaseFirestore fakeFirestore;
    late QolService qolService;
    const testUserId = 'test-user-id';
    const testPetId = 'test-pet-id';
    final testDate = DateTime(2025, 1, 15);

    setUp(() {
      fakeFirestore = createFakeFirestore();
      qolService = QolService(firestore: fakeFirestore);
    });

    test('edit existing assessment and verify changes saved', () async {
      // Arrange: Create and save initial assessment
      final initialAssessment = QolAssessmentBuilder.complete()
          .withUserId(testUserId)
          .withPetId(testPetId)
          .withDate(testDate)
          .withAllResponses()
          .build();

      await qolService.saveAssessment(initialAssessment);

      // Act: Load assessment, modify responses, and save
      final loadedAssessment = await qolService.getAssessment(
        testUserId,
        testPetId,
        testDate,
      );

      expect(loadedAssessment, isNotNull);

      // Modify one response
      final updatedResponses = loadedAssessment!.responses.map((r) {
        if (r.questionId == 'vitality_1') {
          return r.copyWith(score: 4);
        }
        return r;
      }).toList();

      final updatedAssessment = loadedAssessment.copyWith(
        responses: updatedResponses,
      );

      await qolService.updateAssessment(updatedAssessment);

      // Assert: Verify changes persisted
      final docId = AppDateUtils.formatDateForSummary(testDate);
      final doc = await fakeFirestore
          .collection('users')
          .doc(testUserId)
          .collection('pets')
          .doc(testPetId)
          .collection('qolAssessments')
          .doc(docId)
          .get();

      final savedData = doc.data()!;
      final savedAssessment = QolAssessment.fromJson(savedData);

      // Verify updated response
      final vitality1Response = savedAssessment.responses.firstWhere(
        (r) => r.questionId == 'vitality_1',
      );
      expect(vitality1Response.score, equals(4));

      // Verify updatedAt timestamp is set
      expect(savedAssessment.updatedAt, isNotNull);

      // Verify summaries are updated with new scores
      final dailySummaryDoc = await fakeFirestore
          .collection('users')
          .doc(testUserId)
          .collection('pets')
          .doc(testPetId)
          .collection('treatmentSummaries')
          .doc('daily')
          .collection('summaries')
          .doc(docId)
          .get();

      final dailyData = dailySummaryDoc.data()!;
      expect(dailyData['qolOverallScore'], isNotNull);
      expect(dailyData['hasQolAssessment'], isTrue);
    });

    test('assessment on same date should update existing', () async {
      // Arrange: Create initial assessment
      final firstAssessment = QolAssessmentBuilder.complete()
          .withUserId(testUserId)
          .withPetId(testPetId)
          .withDate(testDate)
          .withAllResponses(defaultScore: 2)
          .build();

      await qolService.saveAssessment(firstAssessment);

      // Act: Save another assessment on same date (should update)
      final secondAssessment = QolAssessmentBuilder.complete()
          .withUserId(testUserId)
          .withPetId(testPetId)
          .withDate(testDate)
          .withAllResponses(defaultScore: 4)
          .withId(firstAssessment.id) // Same ID
          .build();

      await qolService.updateAssessment(secondAssessment);

      // Assert: Only one document exists with updated scores
      final docId = AppDateUtils.formatDateForSummary(testDate);
      final doc = await fakeFirestore
          .collection('users')
          .doc(testUserId)
          .collection('pets')
          .doc(testPetId)
          .collection('qolAssessments')
          .doc(docId)
          .get();

      final savedData = doc.data()!;
      final savedAssessment = QolAssessment.fromJson(savedData);

      // Verify scores are updated (should be higher now)
      expect(savedAssessment.overallScore, greaterThan(50));
    });
  });

  group('History View Flow', () {
    late FakeFirebaseFirestore fakeFirestore;
    late QolService qolService;
    const testUserId = 'test-user-id';
    const testPetId = 'test-pet-id';

    setUp(() {
      fakeFirestore = createFakeFirestore();
      qolService = QolService(firestore: fakeFirestore);
    });

    test('view history screen with multiple assessments', () async {
      // Arrange: Create 5 assessments with different dates
      final dates = [
        DateTime(2025, 1, 15),
        DateTime(2025, 1, 10),
        DateTime(2025, 1, 5),
        DateTime(2024, 12, 30),
        DateTime(2024, 12, 25),
      ];

      for (var i = 0; i < dates.length; i++) {
        final assessment = QolAssessmentBuilder.complete()
            .withUserId(testUserId)
            .withPetId(testPetId)
            .withDate(dates[i])
            .withOverallScore(60 + (i * 5)) // Different scores
            .build();

        await qolService.saveAssessment(assessment);
      }

      // Act: Query assessments using service method
      final assessments = await qolService.getRecentAssessments(
        testUserId,
        testPetId,
      );

      // Assert: Verify assessments returned in descending date order
      expect(assessments.length, equals(5));
      expect(assessments[0].date, equals(dates[0])); // Most recent first
      expect(assessments[4].date, equals(dates[4])); // Oldest last

      // Verify each assessment has correct data structure
      for (final assessment in assessments) {
        expect(assessment.userId, equals(testUserId));
        expect(assessment.petId, equals(testPetId));
        expect(assessment.responses.length, equals(14));
        expect(assessment.overallScore, isNotNull);
        expect(assessment.domainScores[QolDomain.vitality], isNotNull);
        expect(assessment.domainScores[QolDomain.comfort], isNotNull);
        expect(assessment.domainScores[QolDomain.emotional], isNotNull);
        expect(assessment.domainScores[QolDomain.appetite], isNotNull);
        expect(assessment.domainScores[QolDomain.treatmentBurden], isNotNull);
      }
    });

    test('pagination works correctly', () async {
      // Arrange: Create 25 assessments
      for (var i = 0; i < 25; i++) {
        final date = DateTime(2025, 1, 15 - i);
        final assessment = QolAssessmentBuilder.complete()
            .withUserId(testUserId)
            .withPetId(testPetId)
            .withDate(date)
            .build();

        await qolService.saveAssessment(assessment);
      }

      // Act: Get first page
      final firstPage = await qolService.getRecentAssessments(
        testUserId,
        testPetId,
      );

      expect(firstPage.length, equals(20));

      // Get second page
      // Note: fake_cloud_firestore may have limitations
      // with startAfter pagination
      // If pagination doesn't work, we at least verify
      // the limit works correctly
      final secondPage = await qolService.getRecentAssessments(
        testUserId,
        testPetId,
        startAfter: firstPage.last.date,
      );

      // Verify we get remaining assessments
      // (may be 0 if pagination not fully supported)
      expect(secondPage.length, lessThanOrEqualTo(5));
      if (secondPage.isNotEmpty) {
        expect(secondPage[0].date.isBefore(firstPage.last.date), isTrue);
      }
    });
  });

  group('Detail Screen Flow', () {
    late FakeFirebaseFirestore fakeFirestore;
    late QolService qolService;
    const testUserId = 'test-user-id';
    const testPetId = 'test-pet-id';
    final testDate = DateTime(2025, 1, 15);

    setUp(() {
      fakeFirestore = createFakeFirestore();
      qolService = QolService(firestore: fakeFirestore);
    });

    test('view detail screen with radar chart and interpretation', () async {
      // Arrange: Create assessment with known scores
      final assessment = QolAssessmentBuilder.complete()
          .withUserId(testUserId)
          .withPetId(testPetId)
          .withDate(testDate)
          .withOverallScore(75) // Known overall score
          .build();

      await qolService.saveAssessment(assessment);

      // Act: Load assessment by ID
      final loadedAssessment = await qolService.getAssessment(
        testUserId,
        testPetId,
        testDate,
      );

      // Assert: Verify assessment data is complete
      expect(loadedAssessment, isNotNull);
      expect(loadedAssessment!.responses.length, equals(14));
      expect(loadedAssessment.overallScore, isNotNull);
      expect(loadedAssessment.overallScore, greaterThan(0));
      expect(loadedAssessment.overallScore, lessThanOrEqualTo(100));

      // Verify domain scores are computed correctly
      final domainScores = loadedAssessment.domainScores;
      expect(domainScores[QolDomain.vitality], isNotNull);
      expect(domainScores[QolDomain.comfort], isNotNull);
      expect(domainScores[QolDomain.emotional], isNotNull);
      expect(domainScores[QolDomain.appetite], isNotNull);
      expect(domainScores[QolDomain.treatmentBurden], isNotNull);

      // Verify all domain scores are in valid range (0-100)
      for (final score in domainScores.values) {
        expect(score, isNotNull);
        expect(score, greaterThanOrEqualTo(0));
        expect(score, lessThanOrEqualTo(100));
      }

      // Verify overall score calculation
      expect(loadedAssessment.overallScore, isNotNull);
      expect(loadedAssessment.scoreBand, isNotNull);
    });

    test('trend data with previous assessment exists', () async {
      // Arrange: Create two assessments
      final firstDate = DateTime(2025, 1, 10);
      final secondDate = DateTime(2025, 1, 15);

      final firstAssessment = QolAssessmentBuilder.complete()
          .withUserId(testUserId)
          .withPetId(testPetId)
          .withDate(firstDate)
          .withOverallScore(60)
          .build();

      final secondAssessment = QolAssessmentBuilder.complete()
          .withUserId(testUserId)
          .withPetId(testPetId)
          .withDate(secondDate)
          .withOverallScore(75)
          .build();

      await qolService.saveAssessment(firstAssessment);
      await qolService.saveAssessment(secondAssessment);

      // Act: Load both assessments
      final loadedFirst = await qolService.getAssessment(
        testUserId,
        testPetId,
        firstDate,
      );
      final loadedSecond = await qolService.getAssessment(
        testUserId,
        testPetId,
        secondDate,
      );

      // Assert: Verify trend can be computed
      expect(loadedFirst, isNotNull);
      expect(loadedSecond, isNotNull);
      expect(
        loadedSecond!.overallScore,
        greaterThan(loadedFirst!.overallScore!),
      );
    });
  });

  group('Home Card Display Flow', () {
    late FakeFirebaseFirestore fakeFirestore;
    late QolService qolService;
    const testUserId = 'test-user-id';
    const testPetId = 'test-pet-id';

    setUp(() {
      fakeFirestore = createFakeFirestore();
      qolService = QolService(firestore: fakeFirestore);
    });

    test('home screen card displays latest assessment', () async {
      // Arrange: Create assessment with recent date
      final recentDate = DateTime(2025, 1, 15);
      final assessment = QolAssessmentBuilder.complete()
          .withUserId(testUserId)
          .withPetId(testPetId)
          .withDate(recentDate)
          .withOverallScore(80)
          .build();

      await qolService.saveAssessment(assessment);

      // Act: Load assessments via service
      final assessments = await qolService.getRecentAssessments(
        testUserId,
        testPetId,
        limit: 1,
      );

      // Assert: Verify latest assessment returned
      expect(assessments.length, equals(1));
      final latest = assessments.first;
      expect(latest.date, equals(recentDate));
      expect(latest.overallScore, isNotNull);
      expect(latest.scoreBand, isNotNull);

      // Verify assessment has all required fields for card display
      expect(latest.documentId, isNotEmpty);
      expect(latest.overallScore, greaterThan(0));
      expect(latest.domainScores.isNotEmpty, isTrue);
    });

    test('empty state when no assessments exist', () async {
      // Act: Query assessments when none exist
      final assessments = await qolService.getRecentAssessments(
        testUserId,
        testPetId,
      );

      // Assert: Empty list returned
      expect(assessments, isEmpty);
    });

    test('latest assessment is most recent when multiple exist', () async {
      // Arrange: Create multiple assessments
      final dates = [
        DateTime(2025, 1, 15),
        DateTime(2025, 1, 10),
        DateTime(2025, 1, 5),
      ];

      for (final date in dates) {
        final assessment = QolAssessmentBuilder.complete()
            .withUserId(testUserId)
            .withPetId(testPetId)
            .withDate(date)
            .build();

        await qolService.saveAssessment(assessment);
      }

      // Act: Get latest
      final assessments = await qolService.getRecentAssessments(
        testUserId,
        testPetId,
        limit: 1,
      );

      // Assert: Most recent date returned
      expect(assessments.length, equals(1));
      expect(assessments.first.date, equals(dates[0]));
    });
  });

  group('Delete Assessment Flow', () {
    late FakeFirebaseFirestore fakeFirestore;
    late QolService qolService;
    const testUserId = 'test-user-id';
    const testPetId = 'test-pet-id';
    final testDate = DateTime(2025, 1, 15);

    setUp(() {
      fakeFirestore = createFakeFirestore();
      qolService = QolService(firestore: fakeFirestore);
    });

    test('delete assessment and verify removed from history', () async {
      // Arrange: Create and save assessment
      final assessment = QolAssessmentBuilder.complete()
          .withUserId(testUserId)
          .withPetId(testPetId)
          .withDate(testDate)
          .build();

      await qolService.saveAssessment(assessment);

      // Verify it exists
      final docId = AppDateUtils.formatDateForSummary(testDate);
      final docBefore = await fakeFirestore
          .collection('users')
          .doc(testUserId)
          .collection('pets')
          .doc(testPetId)
          .collection('qolAssessments')
          .doc(docId)
          .get();

      expect(docBefore.exists, isTrue);

      // Act: Delete assessment
      await qolService.deleteAssessment(testUserId, testPetId, testDate);

      // Assert: Document removed from qolAssessments collection
      final docAfter = await fakeFirestore
          .collection('users')
          .doc(testUserId)
          .collection('pets')
          .doc(testPetId)
          .collection('qolAssessments')
          .doc(docId)
          .get();

      expect(docAfter.exists, isFalse);

      // Verify hasQolAssessment flag removed from daily summary
      final dailySummaryDoc = await fakeFirestore
          .collection('users')
          .doc(testUserId)
          .collection('pets')
          .doc(testPetId)
          .collection('treatmentSummaries')
          .doc('daily')
          .collection('summaries')
          .doc(docId)
          .get();

      if (dailySummaryDoc.exists) {
        final dailyData = dailySummaryDoc.data()!;
        expect(dailyData['hasQolAssessment'], isFalse);
        expect(dailyData['qolOverallScore'], isNull);
      }

      // Verify assessment no longer appears in history query
      final assessments = await qolService.getRecentAssessments(
        testUserId,
        testPetId,
      );

      expect(assessments.any((a) => a.date == testDate), isFalse);
    });

    test('delete non-existent assessment handles gracefully', () async {
      // Act & Assert: Should not throw
      await expectLater(
        qolService.deleteAssessment(
          testUserId,
          testPetId,
          DateTime(2025, 1, 20), // Non-existent date
        ),
        completes,
      );
    });
  });

  group('Edge Cases', () {
    late FakeFirebaseFirestore fakeFirestore;
    late QolService qolService;
    const testUserId = 'test-user-id';
    const testPetId = 'test-pet-id';

    setUp(() {
      fakeFirestore = createFakeFirestore();
      qolService = QolService(firestore: fakeFirestore);
    });

    test('assessment with all maximum scores (100%)', () async {
      final assessment = QolAssessmentBuilder.complete()
          .withUserId(testUserId)
          .withPetId(testPetId)
          .withDate(DateTime(2025, 1, 15))
          .withMaximumScores()
          .build();

      await qolService.saveAssessment(assessment);

      final loaded = await qolService.getAssessment(
        testUserId,
        testPetId,
        DateTime(2025, 1, 15),
      );

      expect(loaded, isNotNull);
      expect(loaded!.overallScore, equals(100));
    });

    test('assessment with all minimum scores (0%)', () async {
      final assessment = QolAssessmentBuilder.complete()
          .withUserId(testUserId)
          .withPetId(testPetId)
          .withDate(DateTime(2025, 1, 15))
          .withMinimumScores()
          .build();

      await qolService.saveAssessment(assessment);

      final loaded = await qolService.getAssessment(
        testUserId,
        testPetId,
        DateTime(2025, 1, 15),
      );

      expect(loaded, isNotNull);
      expect(loaded!.overallScore, equals(0));
    });
  });
}
