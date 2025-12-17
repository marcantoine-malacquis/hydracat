import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/features/qol/models/qol_domain.dart';

void main() {
  group('QolDomain', () {
    group('constants', () {
      test('should define all 5 domain constants', () {
        expect(QolDomain.vitality, 'vitality');
        expect(QolDomain.comfort, 'comfort');
        expect(QolDomain.emotional, 'emotional');
        expect(QolDomain.appetite, 'appetite');
        expect(QolDomain.treatmentBurden, 'treatmentBurden');
      });

      test('should have all domains in canonical order', () {
        expect(QolDomain.all.length, 5);
        expect(QolDomain.all, [
          'vitality',
          'comfort',
          'emotional',
          'appetite',
          'treatmentBurden',
        ]);
      });
    });

    group('displayNameKeys', () {
      test('should map all domains to display name keys', () {
        expect(QolDomain.displayNameKeys.length, 5);
        expect(QolDomain.displayNameKeys[QolDomain.vitality],
            'qolDomainVitality');
        expect(
            QolDomain.displayNameKeys[QolDomain.comfort], 'qolDomainComfort');
        expect(QolDomain.displayNameKeys[QolDomain.emotional],
            'qolDomainEmotional');
        expect(QolDomain.displayNameKeys[QolDomain.appetite],
            'qolDomainAppetite');
        expect(QolDomain.displayNameKeys[QolDomain.treatmentBurden],
            'qolDomainTreatmentBurden');
      });
    });

    group('descriptionKeys', () {
      test('should map all domains to description keys', () {
        expect(QolDomain.descriptionKeys.length, 5);
        expect(QolDomain.descriptionKeys[QolDomain.vitality],
            'qolDomainVitalityDesc');
        expect(QolDomain.descriptionKeys[QolDomain.comfort],
            'qolDomainComfortDesc');
        expect(QolDomain.descriptionKeys[QolDomain.emotional],
            'qolDomainEmotionalDesc');
        expect(QolDomain.descriptionKeys[QolDomain.appetite],
            'qolDomainAppetiteDesc');
        expect(QolDomain.descriptionKeys[QolDomain.treatmentBurden],
            'qolDomainTreatmentBurdenDesc');
      });
    });

    group('questionCounts', () {
      test('should define correct question counts for all domains', () {
        expect(QolDomain.questionCounts.length, 5);
        expect(QolDomain.questionCounts[QolDomain.vitality], 3);
        expect(QolDomain.questionCounts[QolDomain.comfort], 3);
        expect(QolDomain.questionCounts[QolDomain.emotional], 3);
        expect(QolDomain.questionCounts[QolDomain.appetite], 3);
        expect(QolDomain.questionCounts[QolDomain.treatmentBurden], 2);
      });

      test('should total 14 questions across all domains', () {
        final totalQuestions = QolDomain.questionCounts.values
            .fold<int>(0, (sum, count) => sum + count);
        expect(totalQuestions, 14);
      });
    });

    group('isValid', () {
      test('should return true for valid domains', () {
        expect(QolDomain.isValid(QolDomain.vitality), isTrue);
        expect(QolDomain.isValid(QolDomain.comfort), isTrue);
        expect(QolDomain.isValid(QolDomain.emotional), isTrue);
        expect(QolDomain.isValid(QolDomain.appetite), isTrue);
        expect(QolDomain.isValid(QolDomain.treatmentBurden), isTrue);
      });

      test('should return false for invalid domains', () {
        expect(QolDomain.isValid('invalid'), isFalse);
        expect(QolDomain.isValid(''), isFalse);
        expect(QolDomain.isValid('Vitality'), isFalse); // case-sensitive
      });

      test('should return false for null', () {
        expect(QolDomain.isValid(null), isFalse);
      });
    });

    group('getDisplayNameKey', () {
      test('should return correct display name key for valid domains', () {
        expect(QolDomain.getDisplayNameKey(QolDomain.vitality),
            'qolDomainVitality');
        expect(QolDomain.getDisplayNameKey(QolDomain.comfort),
            'qolDomainComfort');
        expect(QolDomain.getDisplayNameKey(QolDomain.emotional),
            'qolDomainEmotional');
      });

      test('should return null for invalid domains', () {
        expect(QolDomain.getDisplayNameKey('invalid'), isNull);
        expect(QolDomain.getDisplayNameKey(null), isNull);
      });
    });

    group('getDescriptionKey', () {
      test('should return correct description key for valid domains', () {
        expect(QolDomain.getDescriptionKey(QolDomain.vitality),
            'qolDomainVitalityDesc');
        expect(QolDomain.getDescriptionKey(QolDomain.comfort),
            'qolDomainComfortDesc');
        expect(QolDomain.getDescriptionKey(QolDomain.emotional),
            'qolDomainEmotionalDesc');
      });

      test('should return null for invalid domains', () {
        expect(QolDomain.getDescriptionKey('invalid'), isNull);
        expect(QolDomain.getDescriptionKey(null), isNull);
      });
    });

    group('getQuestionCount', () {
      test('should return correct question count for valid domains', () {
        expect(QolDomain.getQuestionCount(QolDomain.vitality), 3);
        expect(QolDomain.getQuestionCount(QolDomain.comfort), 3);
        expect(QolDomain.getQuestionCount(QolDomain.emotional), 3);
        expect(QolDomain.getQuestionCount(QolDomain.appetite), 3);
        expect(QolDomain.getQuestionCount(QolDomain.treatmentBurden), 2);
      });

      test('should return 0 for invalid domains', () {
        expect(QolDomain.getQuestionCount('invalid'), 0);
        expect(QolDomain.getQuestionCount(''), 0);
      });
    });
  });
}
