import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/features/qol/models/qol_domain.dart';
import 'package:hydracat/features/qol/models/qol_question.dart';

void main() {
  group('QolQuestion', () {
    group('all', () {
      test('should define exactly 14 questions', () {
        expect(QolQuestion.all.length, 14);
      });

      test('should have all questions in sequential order (0-13)', () {
        for (var i = 0; i < QolQuestion.all.length; i++) {
          expect(QolQuestion.all[i].order, i);
        }
      });

      test('should have unique question IDs', () {
        final ids = QolQuestion.all.map((q) => q.id).toList();
        final uniqueIds = ids.toSet();
        expect(uniqueIds.length, ids.length,
            reason: 'All question IDs should be unique');
      });

      test('should have all questions belong to valid domains', () {
        for (final question in QolQuestion.all) {
          expect(QolDomain.isValid(question.domain), isTrue,
              reason: 'Question ${question.id} has invalid domain');
        }
      });

      test('should distribute questions across domains correctly', () {
        final vitalityQuestions =
            QolQuestion.all.where((q) => q.domain == QolDomain.vitality);
        final comfortQuestions =
            QolQuestion.all.where((q) => q.domain == QolDomain.comfort);
        final emotionalQuestions =
            QolQuestion.all.where((q) => q.domain == QolDomain.emotional);
        final appetiteQuestions =
            QolQuestion.all.where((q) => q.domain == QolDomain.appetite);
        final treatmentQuestions =
            QolQuestion.all.where((q) => q.domain == QolDomain.treatmentBurden);

        expect(vitalityQuestions.length, 3);
        expect(comfortQuestions.length, 3);
        expect(emotionalQuestions.length, 3);
        expect(appetiteQuestions.length, 3);
        expect(treatmentQuestions.length, 2);
      });

      test('should have exactly 5 response labels for each question', () {
        for (final question in QolQuestion.all) {
          expect(question.responseLabelKeys.length, 5,
              reason: 'Question ${question.id} should have 5 response labels');
          expect(question.responseLabelKeys.keys,
              containsAll([0, 1, 2, 3, 4]),
              reason: 'Question ${question.id} should have labels 0-4');
        }
      });

      test('should have non-empty localization keys for all questions', () {
        for (final question in QolQuestion.all) {
          expect(question.textKey.isNotEmpty, isTrue,
              reason: 'Question ${question.id} has empty textKey');

          for (var i = 0; i < 5; i++) {
            expect(question.responseLabelKeys[i]?.isNotEmpty, isTrue,
                reason:
                    'Question ${question.id} has empty label key for score $i');
          }
        }
      });
    });

    group('getById', () {
      test('should return question for valid IDs', () {
        final question = QolQuestion.getById('vitality_1');
        expect(question, isNotNull);
        expect(question!.id, 'vitality_1');
        expect(question.domain, QolDomain.vitality);
        expect(question.order, 0);
      });

      test('should return question for all valid IDs', () {
        final expectedIds = [
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
          'treatment_2',
        ];

        for (final id in expectedIds) {
          final question = QolQuestion.getById(id);
          expect(question, isNotNull, reason: 'Question $id should exist');
          expect(question!.id, id);
        }
      });

      test('should return null for invalid ID', () {
        expect(QolQuestion.getById('invalid_id'), isNull);
        expect(QolQuestion.getById('vitality_99'), isNull);
        expect(QolQuestion.getById(''), isNull);
      });
    });

    group('getByDomain', () {
      test('should return all questions for vitality domain', () {
        final questions = QolQuestion.getByDomain(QolDomain.vitality);
        expect(questions.length, 3);
        expect(questions.every((q) => q.domain == QolDomain.vitality), isTrue);
        expect(questions.map((q) => q.id),
            containsAll(['vitality_1', 'vitality_2', 'vitality_3']));
      });

      test('should return all questions for comfort domain', () {
        final questions = QolQuestion.getByDomain(QolDomain.comfort);
        expect(questions.length, 3);
        expect(questions.every((q) => q.domain == QolDomain.comfort), isTrue);
        expect(questions.map((q) => q.id),
            containsAll(['comfort_1', 'comfort_2', 'comfort_3']));
      });

      test('should return all questions for emotional domain', () {
        final questions = QolQuestion.getByDomain(QolDomain.emotional);
        expect(questions.length, 3);
        expect(questions.every((q) => q.domain == QolDomain.emotional), isTrue);
        expect(questions.map((q) => q.id),
            containsAll(['emotional_1', 'emotional_2', 'emotional_3']));
      });

      test('should return all questions for appetite domain', () {
        final questions = QolQuestion.getByDomain(QolDomain.appetite);
        expect(questions.length, 3);
        expect(questions.every((q) => q.domain == QolDomain.appetite), isTrue);
        expect(questions.map((q) => q.id),
            containsAll(['appetite_1', 'appetite_2', 'appetite_3']));
      });

      test('should return all questions for treatment burden domain', () {
        final questions = QolQuestion.getByDomain(QolDomain.treatmentBurden);
        expect(questions.length, 2);
        expect(
            questions.every((q) => q.domain == QolDomain.treatmentBurden),
            isTrue);
        expect(questions.map((q) => q.id),
            containsAll(['treatment_1', 'treatment_2']));
      });

      test('should return questions in display order', () {
        final questions = QolQuestion.getByDomain(QolDomain.vitality);
        expect(questions[0].order, lessThan(questions[1].order));
        expect(questions[1].order, lessThan(questions[2].order));
      });

      test('should return empty list for invalid domain', () {
        final questions = QolQuestion.getByDomain('invalid_domain');
        expect(questions, isEmpty);
      });
    });

    group('equality', () {
      test('should be equal for same question', () {
        final q1 = QolQuestion.getById('vitality_1');
        final q2 = QolQuestion.getById('vitality_1');
        expect(q1, equals(q2));
        expect(q1.hashCode, equals(q2.hashCode));
      });

      test('should not be equal for different questions', () {
        final q1 = QolQuestion.getById('vitality_1');
        final q2 = QolQuestion.getById('vitality_2');
        expect(q1, isNot(equals(q2)));
      });
    });

    group('toString', () {
      test('should return readable string representation', () {
        final question = QolQuestion.getById('vitality_1')!;
        final str = question.toString();
        expect(str, contains('vitality_1'));
        expect(str, contains('vitality'));
        expect(str, contains('0'));
      });
    });

    group('specific question validation', () {
      test('vitality_1 should have correct properties', () {
        final q = QolQuestion.getById('vitality_1')!;
        expect(q.domain, QolDomain.vitality);
        expect(q.textKey, 'qolQuestionVitality1');
        expect(q.order, 0);
        expect(q.responseLabelKeys[0], 'qolVitality1Label0');
        expect(q.responseLabelKeys[4], 'qolVitality1Label4');
      });

      test('treatment_2 should have correct properties (last question)', () {
        final q = QolQuestion.getById('treatment_2')!;
        expect(q.domain, QolDomain.treatmentBurden);
        expect(q.textKey, 'qolQuestionTreatment2');
        expect(q.order, 13);
        expect(q.responseLabelKeys[0], 'qolTreatment2Label0');
        expect(q.responseLabelKeys[4], 'qolTreatment2Label4');
      });
    });
  });
}
