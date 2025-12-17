import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/features/qol/models/qol_response.dart';

void main() {
  group('QolResponse', () {
    group('constructor', () {
      test('should create response with score', () {
        const response = QolResponse(
          questionId: 'vitality_1',
          score: 3,
        );

        expect(response.questionId, 'vitality_1');
        expect(response.score, 3);
        expect(response.isAnswered, isTrue);
      });

      test('should create response with null score (Not sure)', () {
        const response = QolResponse(
          questionId: 'vitality_1',
        );

        expect(response.questionId, 'vitality_1');
        expect(response.score, isNull);
        expect(response.isAnswered, isFalse);
      });

      test('should create response with score 0', () {
        const response = QolResponse(
          questionId: 'comfort_1',
          score: 0,
        );

        expect(response.questionId, 'comfort_1');
        expect(response.score, 0);
        expect(response.isAnswered, isTrue);
      });

      test('should create response with score 4', () {
        const response = QolResponse(
          questionId: 'appetite_1',
          score: 4,
        );

        expect(response.questionId, 'appetite_1');
        expect(response.score, 4);
        expect(response.isAnswered, isTrue);
      });
    });

    group('isAnswered', () {
      test('should return true when score is 0', () {
        const response = QolResponse(questionId: 'test', score: 0);
        expect(response.isAnswered, isTrue);
      });

      test('should return true when score is between 1-4', () {
        for (var i = 1; i <= 4; i++) {
          final response = QolResponse(questionId: 'test', score: i);
          expect(response.isAnswered, isTrue,
              reason: 'Score $i should be considered answered');
        }
      });

      test('should return false when score is null', () {
        const response = QolResponse(questionId: 'test');
        expect(response.isAnswered, isFalse);
      });
    });

    group('toJson', () {
      test('should serialize response with score', () {
        const response = QolResponse(
          questionId: 'vitality_1',
          score: 3,
        );

        final json = response.toJson();

        expect(json, {
          'questionId': 'vitality_1',
          'score': 3,
        });
      });

      test('should serialize response with null score', () {
        const response = QolResponse(
          questionId: 'vitality_1',
        );

        final json = response.toJson();

        expect(json, {
          'questionId': 'vitality_1',
          'score': null,
        });
      });

      test('should serialize response with score 0', () {
        const response = QolResponse(
          questionId: 'comfort_1',
          score: 0,
        );

        final json = response.toJson();

        expect(json['score'], 0);
        expect(json['score'], isNotNull);
      });
    });

    group('fromJson', () {
      test('should deserialize response with score', () {
        final json = {
          'questionId': 'vitality_1',
          'score': 3,
        };

        final response = QolResponse.fromJson(json);

        expect(response.questionId, 'vitality_1');
        expect(response.score, 3);
        expect(response.isAnswered, isTrue);
      });

      test('should deserialize response with null score', () {
        final json = {
          'questionId': 'vitality_1',
          'score': null,
        };

        final response = QolResponse.fromJson(json);

        expect(response.questionId, 'vitality_1');
        expect(response.score, isNull);
        expect(response.isAnswered, isFalse);
      });

      test('should deserialize response with score 0', () {
        final json = {
          'questionId': 'comfort_1',
          'score': 0,
        };

        final response = QolResponse.fromJson(json);

        expect(response.questionId, 'comfort_1');
        expect(response.score, 0);
        expect(response.isAnswered, isTrue);
      });
    });

    group('serialization round-trip', () {
      test('should preserve all values through toJson -> fromJson', () {
        const original = QolResponse(
          questionId: 'emotional_2',
          score: 2,
        );

        final json = original.toJson();
        final deserialized = QolResponse.fromJson(json);

        expect(deserialized, equals(original));
        expect(deserialized.questionId, original.questionId);
        expect(deserialized.score, original.score);
      });

      test('should preserve null score through round-trip', () {
        const original = QolResponse(
          questionId: 'appetite_3',
        );

        final json = original.toJson();
        final deserialized = QolResponse.fromJson(json);

        expect(deserialized, equals(original));
        expect(deserialized.score, isNull);
      });
    });

    group('copyWith', () {
      test('should create copy with updated score', () {
        const original = QolResponse(
          questionId: 'vitality_1',
          score: 2,
        );

        final updated = original.copyWith(score: 4);

        expect(updated.questionId, 'vitality_1');
        expect(updated.score, 4);
        expect(original.score, 2); // Original unchanged
      });

      test('should create copy with updated questionId', () {
        const original = QolResponse(
          questionId: 'vitality_1',
          score: 2,
        );

        final updated = original.copyWith(questionId: 'vitality_2');

        expect(updated.questionId, 'vitality_2');
        expect(updated.score, 2);
        expect(original.questionId, 'vitality_1'); // Original unchanged
      });

      test('should keep original values when no parameters provided', () {
        const original = QolResponse(
          questionId: 'comfort_1',
          score: 3,
        );

        final copy = original.copyWith();

        expect(copy.questionId, original.questionId);
        expect(copy.score, original.score);
      });
    });

    group('equality', () {
      test('should be equal for same values', () {
        const response1 = QolResponse(questionId: 'vitality_1', score: 3);
        const response2 = QolResponse(questionId: 'vitality_1', score: 3);

        expect(response1, equals(response2));
        expect(response1.hashCode, equals(response2.hashCode));
      });

      test('should be equal when both have null score', () {
        const response1 = QolResponse(questionId: 'vitality_1');
        const response2 = QolResponse(questionId: 'vitality_1');

        expect(response1, equals(response2));
        expect(response1.hashCode, equals(response2.hashCode));
      });

      test('should not be equal for different questionIds', () {
        const response1 = QolResponse(questionId: 'vitality_1', score: 3);
        const response2 = QolResponse(questionId: 'vitality_2', score: 3);

        expect(response1, isNot(equals(response2)));
      });

      test('should not be equal for different scores', () {
        const response1 = QolResponse(questionId: 'vitality_1', score: 3);
        const response2 = QolResponse(questionId: 'vitality_1', score: 2);

        expect(response1, isNot(equals(response2)));
      });

      test('should not be equal when one has null score', () {
        const response1 = QolResponse(questionId: 'vitality_1', score: 3);
        const response2 = QolResponse(questionId: 'vitality_1');

        expect(response1, isNot(equals(response2)));
      });
    });

    group('toString', () {
      test('should return readable string with score', () {
        const response = QolResponse(questionId: 'vitality_1', score: 3);
        final str = response.toString();

        expect(str, contains('vitality_1'));
        expect(str, contains('3'));
        expect(str, contains('true')); // isAnswered
      });

      test('should return readable string with null score', () {
        const response = QolResponse(questionId: 'vitality_1');
        final str = response.toString();

        expect(str, contains('vitality_1'));
        expect(str, contains('null'));
        expect(str, contains('false')); // isAnswered
      });
    });
  });
}
