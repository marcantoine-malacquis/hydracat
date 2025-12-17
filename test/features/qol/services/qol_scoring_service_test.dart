import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/features/qol/models/qol_assessment.dart';
import 'package:hydracat/features/qol/models/qol_domain.dart';
import 'package:hydracat/features/qol/models/qol_response.dart';
import 'package:hydracat/features/qol/models/qol_trend_summary.dart';
import 'package:hydracat/features/qol/services/qol_scoring_service.dart';

void main() {
  group('QolScoringService', () {
    const service = QolScoringService();

    group('calculateDomainScore', () {
      test('should return null for invalid domain', () {
        final score = service.calculateDomainScore('invalid', []);
        expect(score, isNull);
      });

      test('should return null when <50% of questions answered', () {
        // Vitality domain has 3 questions, need at least 2 answered (50%)
        final responses = [
          const QolResponse(questionId: 'vitality_1', score: 4),
          // Only 1 of 3 answered = 33%
        ];

        final score = service.calculateDomainScore(
          QolDomain.vitality,
          responses,
        );

        expect(score, isNull);
      });

      test('should return score when exactly 50% answered', () {
        // Vitality has 3 questions, 50% = 1.5, so 2 questions needed
        final responses = [
          const QolResponse(questionId: 'vitality_1', score: 4),
          const QolResponse(questionId: 'vitality_2', score: 2),
        ];

        final score = service.calculateDomainScore(
          QolDomain.vitality,
          responses,
        );

        expect(score, isNotNull);
        // (4 + 2) / 2 = 3.0, 3.0 / 4.0 * 100 = 75.0
        expect(score, 75);
      });

      test('should calculate correct score with 100% answered', () {
        final responses = [
          const QolResponse(questionId: 'vitality_1', score: 4),
          const QolResponse(questionId: 'vitality_2', score: 3),
          const QolResponse(questionId: 'vitality_3', score: 2),
        ];

        final score = service.calculateDomainScore(
          QolDomain.vitality,
          responses,
        );

        // (4 + 3 + 2) / 3 = 3.0, 3.0 / 4.0 * 100 = 75.0
        expect(score, 75);
      });

      test('should handle score 0 correctly', () {
        final responses = [
          const QolResponse(questionId: 'comfort_1', score: 0),
          const QolResponse(questionId: 'comfort_2', score: 0),
        ];

        final score = service.calculateDomainScore(
          QolDomain.comfort,
          responses,
        );

        // (0 + 0) / 2 = 0.0, 0.0 / 4.0 * 100 = 0.0
        expect(score, 0);
      });

      test('should handle perfect score', () {
        final responses = [
          const QolResponse(questionId: 'appetite_1', score: 4),
          const QolResponse(questionId: 'appetite_2', score: 4),
          const QolResponse(questionId: 'appetite_3', score: 4),
        ];

        final score = service.calculateDomainScore(
          QolDomain.appetite,
          responses,
        );

        // (4 + 4 + 4) / 3 = 4.0, 4.0 / 4.0 * 100 = 100.0
        expect(score, 100);
      });

      test('should ignore null scores in calculation', () {
        final responses = [
          const QolResponse(questionId: 'emotional_1', score: 4),
          const QolResponse(questionId: 'emotional_2'),
          const QolResponse(questionId: 'emotional_3', score: 2),
        ];

        final score = service.calculateDomainScore(
          QolDomain.emotional,
          responses,
        );

        // (4 + 2) / 2 = 3.0, 3.0 / 4.0 * 100 = 75.0
        expect(score, 75);
      });

      test('should ignore responses from other domains', () {
        final responses = [
          const QolResponse(questionId: 'vitality_1', score: 4),
          const QolResponse(questionId: 'vitality_2', score: 4),
          // Different domain
          const QolResponse(questionId: 'comfort_1', score: 0),
        ];

        final score = service.calculateDomainScore(
          QolDomain.vitality,
          responses,
        );

        // Only vitality scores: (4 + 4) / 2 = 4.0, 100.0
        expect(score, 100);
      });
    });

    group('calculateOverallScore', () {
      QolAssessment createAssessmentWithScores(Map<String, double?> scores) {
        final responses = <QolResponse>[];

        // Create responses that will produce the desired scores
        if (scores[QolDomain.vitality] != null) {
          final targetScore =
              (scores[QolDomain.vitality]! / 100.0 * 4.0).round();
          responses.addAll([
            QolResponse(questionId: 'vitality_1', score: targetScore),
            QolResponse(questionId: 'vitality_2', score: targetScore),
            QolResponse(questionId: 'vitality_3', score: targetScore),
          ]);
        }

        if (scores[QolDomain.comfort] != null) {
          final targetScore =
              (scores[QolDomain.comfort]! / 100.0 * 4.0).round();
          responses.addAll([
            QolResponse(questionId: 'comfort_1', score: targetScore),
            QolResponse(questionId: 'comfort_2', score: targetScore),
            QolResponse(questionId: 'comfort_3', score: targetScore),
          ]);
        }

        if (scores[QolDomain.emotional] != null) {
          final targetScore =
              (scores[QolDomain.emotional]! / 100.0 * 4.0).round();
          responses.addAll([
            QolResponse(questionId: 'emotional_1', score: targetScore),
            QolResponse(questionId: 'emotional_2', score: targetScore),
            QolResponse(questionId: 'emotional_3', score: targetScore),
          ]);
        }

        if (scores[QolDomain.appetite] != null) {
          final targetScore =
              (scores[QolDomain.appetite]! / 100.0 * 4.0).round();
          responses.addAll([
            QolResponse(questionId: 'appetite_1', score: targetScore),
            QolResponse(questionId: 'appetite_2', score: targetScore),
            QolResponse(questionId: 'appetite_3', score: targetScore),
          ]);
        }

        if (scores[QolDomain.treatmentBurden] != null) {
          final targetScore =
              (scores[QolDomain.treatmentBurden]! / 100.0 * 4.0).round();
          responses.addAll([
            QolResponse(questionId: 'treatment_1', score: targetScore),
            QolResponse(questionId: 'treatment_2', score: targetScore),
          ]);
        }

        return QolAssessment(
          id: 'test-id',
          userId: 'user123',
          petId: 'pet456',
          date: DateTime(2025, 1, 15),
          responses: responses,
          createdAt: DateTime.now(),
        );
      }

      test('should return null if any domain has null score', () {
        // Only vitality complete
        final assessment = createAssessmentWithScores({
          QolDomain.vitality: 100,
        });

        final score = service.calculateOverallScore(assessment);
        expect(score, isNull);
      });

      test('should calculate mean of all domain scores', () {
        final assessment = createAssessmentWithScores({
          QolDomain.vitality: 100,
          QolDomain.comfort: 100,
          QolDomain.emotional: 100,
          QolDomain.appetite: 100,
          QolDomain.treatmentBurden: 100,
        });

        final score = service.calculateOverallScore(assessment);
        expect(score, 100);
      });

      test('should handle mixed domain scores', () {
        final assessment = createAssessmentWithScores({
          QolDomain.vitality: 0,
          QolDomain.comfort: 100,
          QolDomain.emotional: 50,
          QolDomain.appetite: 50,
          QolDomain.treatmentBurden: 100,
        });

        final score = service.calculateOverallScore(assessment);
        // (0 + 100 + 50 + 50 + 100) / 5 = 60.0
        expect(score, 60);
      });
    });

    group('calculateTrendStability', () {
      test('should return stable for less than 3 trend points', () {
        final trends = [
          QolTrendSummary(
            date: DateTime(2025),
            domainScores: const {},
            overallScore: 75,
          ),
        ];

        final stability = service.calculateTrendStability(trends);
        expect(stability, TrendStability.stable);
      });

      test('should detect improving trend', () {
        final trends = [
          QolTrendSummary(
            date: DateTime(2025),
            domainScores: const {},
            overallScore: 50,
          ),
          QolTrendSummary(
            date: DateTime(2025, 1, 15),
            domainScores: const {},
            overallScore: 60,
          ),
          QolTrendSummary(
            date: DateTime(2025, 1, 30),
            domainScores: const {},
            overallScore: 70,
          ),
        ];

        final stability = service.calculateTrendStability(trends);
        // Slope: ~20 points over 30 days = ~20 points/month > 5
        expect(stability, TrendStability.improving);
      });

      test('should detect declining trend', () {
        final trends = [
          QolTrendSummary(
            date: DateTime(2025),
            domainScores: const {},
            overallScore: 80,
          ),
          QolTrendSummary(
            date: DateTime(2025, 1, 15),
            domainScores: const {},
            overallScore: 70,
          ),
          QolTrendSummary(
            date: DateTime(2025, 1, 30),
            domainScores: const {},
            overallScore: 60,
          ),
        ];

        final stability = service.calculateTrendStability(trends);
        // Slope: ~-20 points over 30 days = ~-20 points/month < -5
        expect(stability, TrendStability.declining);
      });

      test('should detect stable trend', () {
        final trends = [
          QolTrendSummary(
            date: DateTime(2025),
            domainScores: const {},
            overallScore: 75,
          ),
          QolTrendSummary(
            date: DateTime(2025, 1, 15),
            domainScores: const {},
            overallScore: 76,
          ),
          QolTrendSummary(
            date: DateTime(2025, 1, 30),
            domainScores: const {},
            overallScore: 74,
          ),
        ];

        final stability = service.calculateTrendStability(trends);
        // Slope: ~-1 point over 30 days = ~-1 point/month (between -5 and +5)
        expect(stability, TrendStability.stable);
      });
    });

    group('hasNotableChange', () {
      test('should return false when less than 3 trend points', () {
        final trends = [
          QolTrendSummary(
            date: DateTime(2025),
            domainScores: const {QolDomain.vitality: 80.0},
            overallScore: 80,
          ),
        ];

        final hasChange = service.hasNotableChange(
          trends,
          QolDomain.vitality,
        );

        expect(hasChange, isFalse);
      });

      test('should detect sustained drop (≥15 points)', () {
        final trends = [
          QolTrendSummary(
            date: DateTime(2025, 1, 30),
            domainScores: const {QolDomain.comfort: 60.0},
            overallScore: 60,
          ),
          QolTrendSummary(
            date: DateTime(2025, 1, 15),
            domainScores: const {QolDomain.comfort: 76.0},
            overallScore: 76,
          ),
          QolTrendSummary(
            date: DateTime(2025),
            domainScores: const {QolDomain.comfort: 80.0},
            overallScore: 80,
          ),
        ];

        final hasChange = service.hasNotableChange(
          trends,
          QolDomain.comfort,
        );

        // Drop from 80 → 76 (4 points) then 76 → 60 (16 points)
        // The 16-point drop is notable
        expect(hasChange, isTrue);
      });

      test('should not detect small drops', () {
        final trends = [
          QolTrendSummary(
            date: DateTime(2025, 1, 30),
            domainScores: const {QolDomain.comfort: 75.0},
            overallScore: 75,
          ),
          QolTrendSummary(
            date: DateTime(2025, 1, 15),
            domainScores: const {QolDomain.comfort: 78.0},
            overallScore: 78,
          ),
          QolTrendSummary(
            date: DateTime(2025),
            domainScores: const {QolDomain.comfort: 80.0},
            overallScore: 80,
          ),
        ];

        final hasChange = service.hasNotableChange(
          trends,
          QolDomain.comfort,
        );

        // Drop from 80 → 78 (2 points) then 78 → 75 (3 points)
        // Not notable (< 15 points)
        expect(hasChange, isFalse);
      });

      test('should return false when domain missing from trends', () {
        final trends = [
          QolTrendSummary(
            date: DateTime(2025, 1, 30),
            domainScores: const {QolDomain.vitality: 60.0},
            overallScore: 60,
          ),
          QolTrendSummary(
            date: DateTime(2025, 1, 15),
            domainScores: const {QolDomain.vitality: 75.0},
            overallScore: 75,
          ),
          QolTrendSummary(
            date: DateTime(2025),
            domainScores: const {QolDomain.vitality: 80.0},
            overallScore: 80,
          ),
        ];

        final hasChange = service.hasNotableChange(
          trends,
          QolDomain.comfort, // Different domain not in data
        );

        expect(hasChange, isFalse);
      });
    });

    group('generateInterpretationMessage', () {
      test('should return null for first assessment', () {
        final current = QolTrendSummary(
          date: DateTime(2025, 1, 15),
          domainScores: const {},
          overallScore: 75,
        );

        final message = service.generateInterpretationMessage(current, null);
        expect(message, isNull);
      });

      test('should detect notable comfort drop', () {
        final current = QolTrendSummary(
          date: DateTime(2025, 1, 15),
          domainScores: const {QolDomain.comfort: 60.0},
          overallScore: 60,
        );

        final previous = QolTrendSummary(
          date: DateTime(2025),
          domainScores: const {QolDomain.comfort: 80.0},
          overallScore: 80,
        );

        final message = service.generateInterpretationMessage(
          current,
          previous,
        );

        expect(message, 'qolInterpretationNotableDropComfort');
      });

      test('should detect notable appetite drop', () {
        final current = QolTrendSummary(
          date: DateTime(2025, 1, 15),
          domainScores: const {QolDomain.appetite: 55.0},
          overallScore: 55,
        );

        final previous = QolTrendSummary(
          date: DateTime(2025),
          domainScores: const {QolDomain.appetite: 75.0},
          overallScore: 75,
        );

        final message = service.generateInterpretationMessage(
          current,
          previous,
        );

        expect(message, 'qolInterpretationNotableDropAppetite');
      });

      test('should detect improving trend', () {
        final current = QolTrendSummary(
          date: DateTime(2025, 1, 15),
          domainScores: const {},
          overallScore: 80,
        );

        final previous = QolTrendSummary(
          date: DateTime(2025),
          domainScores: const {},
          overallScore: 65,
        );

        final message = service.generateInterpretationMessage(
          current,
          previous,
        );

        // Delta = 15 points > 10
        expect(message, 'qolInterpretationImproving');
      });

      test('should detect declining trend', () {
        final current = QolTrendSummary(
          date: DateTime(2025, 1, 15),
          domainScores: const {},
          overallScore: 60,
        );

        final previous = QolTrendSummary(
          date: DateTime(2025),
          domainScores: const {},
          overallScore: 75,
        );

        final message = service.generateInterpretationMessage(
          current,
          previous,
        );

        // Delta = -15 points < -10
        expect(message, 'qolInterpretationDeclining');
      });

      test('should detect stable trend', () {
        final current = QolTrendSummary(
          date: DateTime(2025, 1, 15),
          domainScores: const {},
          overallScore: 75,
        );

        final previous = QolTrendSummary(
          date: DateTime(2025),
          domainScores: const {},
          overallScore: 73,
        );

        final message = service.generateInterpretationMessage(
          current,
          previous,
        );

        // Delta = 2 points (between -10 and +10)
        expect(message, 'qolInterpretationStable');
      });
    });
  });
}
