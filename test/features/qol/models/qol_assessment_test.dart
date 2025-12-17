import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/features/qol/models/qol_assessment.dart';
import 'package:hydracat/features/qol/models/qol_domain.dart';
import 'package:hydracat/features/qol/models/qol_response.dart';

void main() {
  group('QolAssessment', () {
    final testDate = DateTime(2025, 1, 15);
    const testUserId = 'user123';
    const testPetId = 'pet456';

    // Helper to create assessment with specific responses
    QolAssessment createAssessment({
      List<QolResponse>? responses,
      DateTime? date,
    }) {
      return QolAssessment(
        id: 'test-id',
        userId: testUserId,
        petId: testPetId,
        date: date ?? testDate,
        responses: responses ?? [],
        createdAt: DateTime(2025, 1, 15, 10),
      );
    }

    group('empty factory', () {
      test('should create empty assessment with defaults', () {
        final assessment = QolAssessment.empty(
          userId: testUserId,
          petId: testPetId,
        );

        expect(assessment.userId, testUserId);
        expect(assessment.petId, testPetId);
        expect(assessment.responses, isEmpty);
        expect(assessment.id, isNotEmpty);
      });

      test('should normalize date to midnight', () {
        final dateWithTime = DateTime(2025, 1, 15, 14, 30, 45);
        final assessment = QolAssessment.empty(
          userId: testUserId,
          petId: testPetId,
          date: dateWithTime,
        );

        expect(assessment.date.hour, 0);
        expect(assessment.date.minute, 0);
        expect(assessment.date.second, 0);
      });
    });

    group('documentId', () {
      test('should return YYYY-MM-DD format', () {
        final assessment = createAssessment(date: DateTime(2025, 1, 15));
        expect(assessment.documentId, '2025-01-15');
      });

      test('should pad month and day with zeros', () {
        final assessment = createAssessment(date: DateTime(2025, 3, 5));
        expect(assessment.documentId, '2025-03-05');
      });
    });

    group('isComplete', () {
      test('should return true when 14 questions answered', () {
        final responses = List.generate(
          14,
          (i) => QolResponse(questionId: 'q$i', score: 2),
        );
        final assessment = createAssessment(responses: responses);

        expect(assessment.isComplete, isTrue);
        expect(assessment.answeredCount, 14);
      });

      test('should return false when less than 14 answered', () {
        final responses = List.generate(
          10,
          (i) => QolResponse(questionId: 'q$i', score: 2),
        );
        final assessment = createAssessment(responses: responses);

        expect(assessment.isComplete, isFalse);
        expect(assessment.answeredCount, 10);
      });

      test('should not count null scores as answered', () {
        final responses = [
          const QolResponse(questionId: 'q1', score: 2),
          const QolResponse(questionId: 'q2'),
          const QolResponse(questionId: 'q3', score: 0),
        ];
        final assessment = createAssessment(responses: responses);

        expect(assessment.answeredCount, 2);
        expect(assessment.unansweredCount, 12);
      });
    });

    group('getDomainScore', () {
      test('should return null for invalid domain', () {
        final assessment = createAssessment();
        expect(assessment.getDomainScore('invalid'), isNull);
      });

      test('should return null when <50% of questions answered', () {
        // Vitality domain has 3 questions, need at least 2 answered (50%)
        final responses = [
          const QolResponse(questionId: 'vitality_1', score: 4),
          // Only 1 of 3 answered = 33%
        ];
        final assessment = createAssessment(responses: responses);

        expect(assessment.getDomainScore(QolDomain.vitality), isNull);
      });

      test('should return score when exactly 50% answered', () {
        // Vitality has 3 questions, 50% = 1.5, so 2 questions needed
        final responses = [
          const QolResponse(questionId: 'vitality_1', score: 4),
          const QolResponse(questionId: 'vitality_2', score: 2),
        ];
        final assessment = createAssessment(responses: responses);

        final score = assessment.getDomainScore(QolDomain.vitality);
        expect(score, isNotNull);
        // (4 + 2) / 2 = 3.0, 3.0 / 4.0 * 100 = 75.0
        expect(score, 75.0);
      });

      test('should calculate correct score with 100% answered', () {
        final responses = [
          const QolResponse(questionId: 'vitality_1', score: 4),
          const QolResponse(questionId: 'vitality_2', score: 3),
          const QolResponse(questionId: 'vitality_3', score: 2),
        ];
        final assessment = createAssessment(responses: responses);

        final score = assessment.getDomainScore(QolDomain.vitality);
        // (4 + 3 + 2) / 3 = 3.0, 3.0 / 4.0 * 100 = 75.0
        expect(score, 75.0);
      });

      test('should handle score 0 correctly', () {
        final responses = [
          const QolResponse(questionId: 'comfort_1', score: 0),
          const QolResponse(questionId: 'comfort_2', score: 0),
        ];
        final assessment = createAssessment(responses: responses);

        final score = assessment.getDomainScore(QolDomain.comfort);
        // (0 + 0) / 2 = 0.0, 0.0 / 4.0 * 100 = 0.0
        expect(score, 0.0);
      });

      test('should handle perfect score', () {
        final responses = [
          const QolResponse(questionId: 'appetite_1', score: 4),
          const QolResponse(questionId: 'appetite_2', score: 4),
          const QolResponse(questionId: 'appetite_3', score: 4),
        ];
        final assessment = createAssessment(responses: responses);

        final score = assessment.getDomainScore(QolDomain.appetite);
        // (4 + 4 + 4) / 3 = 4.0, 4.0 / 4.0 * 100 = 100.0
        expect(score, 100.0);
      });

      test('should ignore null scores in calculation', () {
        final responses = [
          const QolResponse(questionId: 'emotional_1', score: 4),
          const QolResponse(questionId: 'emotional_2'),
          const QolResponse(questionId: 'emotional_3', score: 2),
        ];
        final assessment = createAssessment(responses: responses);

        final score = assessment.getDomainScore(QolDomain.emotional);
        // (4 + 2) / 2 = 3.0, 3.0 / 4.0 * 100 = 75.0
        expect(score, 75.0);
      });
    });

    group('domainScores', () {
      test('should return map with all 5 domains', () {
        final assessment = createAssessment();
        final scores = assessment.domainScores;

        expect(scores.keys.length, 5);
        expect(scores.keys, containsAll(QolDomain.all));
      });

      test('should calculate scores for multiple domains', () {
        final responses = [
          // Vitality (2/3 = 66% answered)
          const QolResponse(questionId: 'vitality_1', score: 4),
          const QolResponse(questionId: 'vitality_2', score: 2),
          // Comfort (2/3 = 66% answered)
          const QolResponse(questionId: 'comfort_1', score: 3),
          const QolResponse(questionId: 'comfort_2', score: 3),
        ];
        final assessment = createAssessment(responses: responses);

        final scores = assessment.domainScores;
        expect(scores[QolDomain.vitality], 75.0);
        expect(scores[QolDomain.comfort], 75.0);
        expect(scores[QolDomain.emotional], isNull);
        expect(scores[QolDomain.appetite], isNull);
        expect(scores[QolDomain.treatmentBurden], isNull);
      });
    });

    group('overallScore', () {
      test('should return null if any domain has null score', () {
        final responses = [
          // Only vitality complete
          const QolResponse(questionId: 'vitality_1', score: 4),
          const QolResponse(questionId: 'vitality_2', score: 4),
          const QolResponse(questionId: 'vitality_3', score: 4),
        ];
        final assessment = createAssessment(responses: responses);

        expect(assessment.overallScore, isNull);
      });

      test('should calculate mean of all domain scores', () {
        // Create complete assessment with all domains
        final responses = [
          // Vitality: (4+4+4)/3 = 4.0 -> 100.0
          const QolResponse(questionId: 'vitality_1', score: 4),
          const QolResponse(questionId: 'vitality_2', score: 4),
          const QolResponse(questionId: 'vitality_3', score: 4),
          // Comfort: (4+4+4)/3 = 4.0 -> 100.0
          const QolResponse(questionId: 'comfort_1', score: 4),
          const QolResponse(questionId: 'comfort_2', score: 4),
          const QolResponse(questionId: 'comfort_3', score: 4),
          // Emotional: (4+4+4)/3 = 4.0 -> 100.0
          const QolResponse(questionId: 'emotional_1', score: 4),
          const QolResponse(questionId: 'emotional_2', score: 4),
          const QolResponse(questionId: 'emotional_3', score: 4),
          // Appetite: (4+4+4)/3 = 4.0 -> 100.0
          const QolResponse(questionId: 'appetite_1', score: 4),
          const QolResponse(questionId: 'appetite_2', score: 4),
          const QolResponse(questionId: 'appetite_3', score: 4),
          // Treatment: (4+4)/2 = 4.0 -> 100.0
          const QolResponse(questionId: 'treatment_1', score: 4),
          const QolResponse(questionId: 'treatment_2', score: 4),
        ];
        final assessment = createAssessment(responses: responses);

        expect(assessment.overallScore, 100.0);
      });

      test('should handle mixed domain scores', () {
        final responses = [
          // Vitality: (0+0+0)/3 = 0.0 -> 0.0
          const QolResponse(questionId: 'vitality_1', score: 0),
          const QolResponse(questionId: 'vitality_2', score: 0),
          const QolResponse(questionId: 'vitality_3', score: 0),
          // Comfort: (4+4+4)/3 = 4.0 -> 100.0
          const QolResponse(questionId: 'comfort_1', score: 4),
          const QolResponse(questionId: 'comfort_2', score: 4),
          const QolResponse(questionId: 'comfort_3', score: 4),
          // Emotional: (2+2+2)/3 = 2.0 -> 50.0
          const QolResponse(questionId: 'emotional_1', score: 2),
          const QolResponse(questionId: 'emotional_2', score: 2),
          const QolResponse(questionId: 'emotional_3', score: 2),
          // Appetite: (2+2+2)/3 = 2.0 -> 50.0
          const QolResponse(questionId: 'appetite_1', score: 2),
          const QolResponse(questionId: 'appetite_2', score: 2),
          const QolResponse(questionId: 'appetite_3', score: 2),
          // Treatment: (4+4)/2 = 4.0 -> 100.0
          const QolResponse(questionId: 'treatment_1', score: 4),
          const QolResponse(questionId: 'treatment_2', score: 4),
        ];
        final assessment = createAssessment(responses: responses);

        // (0 + 100 + 50 + 50 + 100) / 5 = 60.0
        expect(assessment.overallScore, 60.0);
      });
    });

    group('scoreBand', () {
      QolAssessment createWithOverallScore(double targetScore) {
        // Create assessment where all domains have same score
        final individualScore = (targetScore / 100.0 * 4.0).round();
        final responses = [
          QolResponse(questionId: 'vitality_1', score: individualScore),
          QolResponse(questionId: 'vitality_2', score: individualScore),
          QolResponse(questionId: 'vitality_3', score: individualScore),
          QolResponse(questionId: 'comfort_1', score: individualScore),
          QolResponse(questionId: 'comfort_2', score: individualScore),
          QolResponse(questionId: 'comfort_3', score: individualScore),
          QolResponse(questionId: 'emotional_1', score: individualScore),
          QolResponse(questionId: 'emotional_2', score: individualScore),
          QolResponse(questionId: 'emotional_3', score: individualScore),
          QolResponse(questionId: 'appetite_1', score: individualScore),
          QolResponse(questionId: 'appetite_2', score: individualScore),
          QolResponse(questionId: 'appetite_3', score: individualScore),
          QolResponse(questionId: 'treatment_1', score: individualScore),
          QolResponse(questionId: 'treatment_2', score: individualScore),
        ];
        return createAssessment(responses: responses);
      }

      test('should return null when overall score is null', () {
        final assessment = createAssessment();
        expect(assessment.scoreBand, isNull);
      });

      test('should return "veryGood" for score >= 80', () {
        final assessment = createWithOverallScore(100);
        expect(assessment.scoreBand, 'veryGood');
      });

      test('should return "good" for score >= 60 and < 80', () {
        final assessment = createWithOverallScore(75);
        expect(assessment.scoreBand, 'good');
      });

      test('should return "fair" for score >= 40 and < 60', () {
        final assessment = createWithOverallScore(50);
        expect(assessment.scoreBand, 'fair');
      });

      test('should return "low" for score < 40', () {
        final assessment = createWithOverallScore(0);
        expect(assessment.scoreBand, 'low');
      });

      test('should handle boundary at 80 (veryGood)', () {
        // Score exactly 80 should be veryGood
        final responses = List.generate(14, (i) {
          // Need score of 3.2 on 0-4 scale = 80 on 0-100 scale
          // Use mix of 3s and 4s
          final questionIds = [
            'vitality_1',
            'vitality_2',
            'vitality_3',
            'comfort_1',
            'comfort_2',
            'comfort_3',
            'emotional_1',
            'emotional_2',
            'emotional_3',
            'appetite_1',
            'appetite_2',
            'appetite_3',
            'treatment_1',
            'treatment_2'
          ];
          return QolResponse(
            questionId: questionIds[i],
            score: i < 3 ? 4 : 3,
          );
        });
        final assessment = createAssessment(responses: responses);
        final score = assessment.overallScore!;

        if (score >= 80) {
          expect(assessment.scoreBand, 'veryGood');
        } else {
          expect(assessment.scoreBand, 'good');
        }
      });
    });

    group('hasLowConfidenceDomain', () {
      test('should return true when any domain has null score', () {
        final responses = [
          const QolResponse(questionId: 'vitality_1', score: 4),
          // Only 1 vitality question, needs 2 for confidence
        ];
        final assessment = createAssessment(responses: responses);

        expect(assessment.hasLowConfidenceDomain, isTrue);
      });

      test('should return false when all domains have scores', () {
        final responses = [
          const QolResponse(questionId: 'vitality_1', score: 4),
          const QolResponse(questionId: 'vitality_2', score: 4),
          const QolResponse(questionId: 'vitality_3', score: 4),
          const QolResponse(questionId: 'comfort_1', score: 4),
          const QolResponse(questionId: 'comfort_2', score: 4),
          const QolResponse(questionId: 'comfort_3', score: 4),
          const QolResponse(questionId: 'emotional_1', score: 4),
          const QolResponse(questionId: 'emotional_2', score: 4),
          const QolResponse(questionId: 'emotional_3', score: 4),
          const QolResponse(questionId: 'appetite_1', score: 4),
          const QolResponse(questionId: 'appetite_2', score: 4),
          const QolResponse(questionId: 'appetite_3', score: 4),
          const QolResponse(questionId: 'treatment_1', score: 4),
          const QolResponse(questionId: 'treatment_2', score: 4),
        ];
        final assessment = createAssessment(responses: responses);

        expect(assessment.hasLowConfidenceDomain, isFalse);
      });
    });

    group('validate', () {
      test('should return empty list for valid assessment', () {
        final responses = [
          const QolResponse(questionId: 'vitality_1', score: 2),
        ];
        final assessment = createAssessment(responses: responses);

        expect(assessment.validate(), isEmpty);
      });

      test('should reject future dates', () {
        final futureDate = DateTime.now().add(const Duration(days: 1));
        final assessment = createAssessment(date: futureDate);

        final errors = assessment.validate();
        expect(
          errors,
          contains('Assessment date cannot be in the future'),
        );
      });

      test('should reject scores outside 0-4 range', () {
        final responses = [
          const QolResponse(questionId: 'vitality_1', score: 5),
        ];
        final assessment = createAssessment(responses: responses);

        final errors = assessment.validate();
        expect(errors.length, 1);
        expect(errors.first, contains('Invalid score 5'));
      });

      test('should reject negative scores', () {
        final responses = [
          const QolResponse(questionId: 'vitality_1', score: -1),
        ];
        final assessment = createAssessment(responses: responses);

        final errors = assessment.validate();
        expect(errors.length, 1);
        expect(errors.first, contains('Invalid score -1'));
      });

      test('should reject invalid question IDs', () {
        final responses = [
          const QolResponse(questionId: 'invalid_question', score: 2),
        ];
        final assessment = createAssessment(responses: responses);

        final errors = assessment.validate();
        expect(
          errors,
          contains('Invalid question ID: invalid_question'),
        );
      });

      test('should reject duplicate question responses', () {
        final responses = [
          const QolResponse(questionId: 'vitality_1', score: 2),
          const QolResponse(questionId: 'vitality_1', score: 3),
        ];
        final assessment = createAssessment(responses: responses);

        final errors = assessment.validate();
        expect(errors, contains('Duplicate question responses found'));
      });

      test('should accept null scores', () {
        final responses = [
          const QolResponse(questionId: 'vitality_1'),
        ];
        final assessment = createAssessment(responses: responses);

        expect(assessment.validate(), isEmpty);
      });
    });

    group('toJson and fromJson', () {
      test('should serialize all fields correctly', () {
        final responses = [
          const QolResponse(questionId: 'vitality_1', score: 3),
          const QolResponse(questionId: 'vitality_2'),
        ];
        final assessment = QolAssessment(
          id: 'test-id',
          userId: testUserId,
          petId: testPetId,
          date: testDate,
          responses: responses,
          createdAt: DateTime(2025, 1, 15, 10),
          updatedAt: DateTime(2025, 1, 15, 11),
          completionDurationSeconds: 180,
        );

        final json = assessment.toJson();

        expect(json['id'], 'test-id');
        expect(json['userId'], testUserId);
        expect(json['petId'], testPetId);
        expect(json['date'], isA<Timestamp>());
        expect(json['responses'], isA<List<dynamic>>());
        expect((json['responses'] as List<dynamic>).length, 2);
        expect(json['createdAt'], isA<Timestamp>());
        expect(json['updatedAt'], isA<Timestamp>());
        expect(json['completionDurationSeconds'], 180);
      });

      test('should omit null optional fields', () {
        final assessment = createAssessment();
        final json = assessment.toJson();

        expect(json.containsKey('updatedAt'), isFalse);
        expect(json.containsKey('completionDurationSeconds'), isFalse);
      });

      test('should round-trip through JSON', () {
        final original = QolAssessment(
          id: 'test-id',
          userId: testUserId,
          petId: testPetId,
          date: testDate,
          responses: const [
            QolResponse(questionId: 'vitality_1', score: 3),
          ],
          createdAt: DateTime(2025, 1, 15, 10),
          updatedAt: DateTime(2025, 1, 15, 11),
          completionDurationSeconds: 180,
        );

        final json = original.toJson();
        final deserialized = QolAssessment.fromJson(json);

        expect(deserialized.id, original.id);
        expect(deserialized.userId, original.userId);
        expect(deserialized.petId, original.petId);
        expect(deserialized.date, original.date);
        expect(deserialized.responses.length, original.responses.length);
        expect(deserialized.completionDurationSeconds, 180);
      });
    });

    group('copyWith', () {
      test('should create copy with updated fields', () {
        final original = createAssessment();
        final updated = original.copyWith(
          userId: 'new-user',
          completionDurationSeconds: 120,
        );

        expect(updated.userId, 'new-user');
        expect(updated.completionDurationSeconds, 120);
        expect(updated.petId, original.petId); // Unchanged
      });

      test('should handle nullable fields with sentinel', () {
        final original = createAssessment();
        final updated = original.copyWith(
          updatedAt: DateTime(2025, 1, 16),
        );

        expect(updated.updatedAt, DateTime(2025, 1, 16));
      });

      test('should keep original when no parameters provided', () {
        final original = createAssessment();
        final copy = original.copyWith();

        expect(copy.id, original.id);
        expect(copy.userId, original.userId);
      });
    });

    group('equality', () {
      test('should be equal for same values', () {
        final assessment1 = createAssessment();
        final assessment2 = createAssessment();

        expect(assessment1, equals(assessment2));
        expect(assessment1.hashCode, equals(assessment2.hashCode));
      });

      test('should not be equal for different responses', () {
        final assessment1 = createAssessment(
          responses: [const QolResponse(questionId: 'q1', score: 1)],
        );
        final assessment2 = createAssessment(
          responses: [const QolResponse(questionId: 'q1', score: 2)],
        );

        expect(assessment1, isNot(equals(assessment2)));
      });
    });

    group('toString', () {
      test('should return readable string', () {
        final assessment = createAssessment();
        final str = assessment.toString();

        expect(str, contains('test-id'));
        expect(str, contains('2025-01-15'));
      });
    });
  });
}
