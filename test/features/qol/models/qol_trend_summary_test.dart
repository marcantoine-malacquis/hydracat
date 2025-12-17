import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/features/qol/models/qol_domain.dart';
import 'package:hydracat/features/qol/models/qol_trend_summary.dart';

void main() {
  group('QolTrendSummary', () {
    final testDate = DateTime(2025, 1, 15);

    group('constructor', () {
      test('should create summary with all fields', () {
        final summary = QolTrendSummary(
          date: testDate,
          domainScores: const {
            QolDomain.vitality: 75,
            QolDomain.comfort: 80,
          },
          overallScore: 77.5,
          assessmentId: 'test-id',
        );

        expect(summary.date, testDate);
        expect(summary.domainScores.length, 2);
        expect(summary.domainScores[QolDomain.vitality], 75);
        expect(summary.overallScore, 77.5);
        expect(summary.assessmentId, 'test-id');
      });

      test('should allow null assessmentId', () {
        final summary = QolTrendSummary(
          date: testDate,
          domainScores: const {},
          overallScore: 50,
        );

        expect(summary.assessmentId, isNull);
      });

      test('should allow empty domain scores map', () {
        final summary = QolTrendSummary(
          date: testDate,
          domainScores: const {},
          overallScore: 50,
        );

        expect(summary.domainScores, isEmpty);
      });
    });

    group('deltaOverall', () {
      test('should calculate positive difference when score increased', () {
        final earlier = QolTrendSummary(
          date: DateTime(2025),
          domainScores: const {},
          overallScore: 60,
        );
        final later = QolTrendSummary(
          date: DateTime(2025, 1, 15),
          domainScores: const {},
          overallScore: 75,
        );

        final delta = later.deltaOverall(earlier);
        expect(delta, 15);
      });

      test('should calculate negative difference when score decreased', () {
        final earlier = QolTrendSummary(
          date: DateTime(2025),
          domainScores: const {},
          overallScore: 80,
        );
        final later = QolTrendSummary(
          date: DateTime(2025, 1, 15),
          domainScores: const {},
          overallScore: 65,
        );

        final delta = later.deltaOverall(earlier);
        expect(delta, -15.0);
      });

      test('should return zero when scores are equal', () {
        final summary1 = QolTrendSummary(
          date: DateTime(2025),
          domainScores: const {},
          overallScore: 70,
        );
        final summary2 = QolTrendSummary(
          date: DateTime(2025, 1, 15),
          domainScores: const {},
          overallScore: 70,
        );

        final delta = summary1.deltaOverall(summary2);
        expect(delta, 0);
      });

      test('should handle large differences', () {
        final earlier = QolTrendSummary(
          date: DateTime(2025),
          domainScores: const {},
          overallScore: 0,
        );
        final later = QolTrendSummary(
          date: DateTime(2025, 1, 15),
          domainScores: const {},
          overallScore: 100,
        );

        final delta = later.deltaOverall(earlier);
        expect(delta, 100);
      });
    });

    group('deltaDomain', () {
      test('should calculate positive difference for specific domain', () {
        final earlier = QolTrendSummary(
          date: DateTime(2025),
          domainScores: const {
            QolDomain.vitality: 60,
            QolDomain.comfort: 70,
          },
          overallScore: 65,
        );
        final later = QolTrendSummary(
          date: DateTime(2025, 1, 15),
          domainScores: const {
            QolDomain.vitality: 80,
            QolDomain.comfort: 70,
          },
          overallScore: 75,
        );

        final delta = later.deltaDomain(QolDomain.vitality, earlier);
        expect(delta, 20);
      });

      test('should calculate negative difference for specific domain', () {
        final earlier = QolTrendSummary(
          date: DateTime(2025),
          domainScores: const {
            QolDomain.comfort: 85,
          },
          overallScore: 85,
        );
        final later = QolTrendSummary(
          date: DateTime(2025, 1, 15),
          domainScores: const {
            QolDomain.comfort: 65,
          },
          overallScore: 65,
        );

        final delta = later.deltaDomain(QolDomain.comfort, earlier);
        expect(delta, -20.0);
      });

      test('should return null if domain missing in this summary', () {
        final earlier = QolTrendSummary(
          date: DateTime(2025),
          domainScores: const {
            QolDomain.vitality: 70,
          },
          overallScore: 70,
        );
        final later = QolTrendSummary(
          date: DateTime(2025, 1, 15),
          domainScores: const {
            QolDomain.comfort: 70,
          },
          overallScore: 70,
        );

        final delta = later.deltaDomain(QolDomain.vitality, earlier);
        expect(delta, isNull);
      });

      test('should return null if domain missing in other summary', () {
        final earlier = QolTrendSummary(
          date: DateTime(2025),
          domainScores: const {
            QolDomain.comfort: 70,
          },
          overallScore: 70,
        );
        final later = QolTrendSummary(
          date: DateTime(2025, 1, 15),
          domainScores: const {
            QolDomain.vitality: 80,
          },
          overallScore: 80,
        );

        final delta = later.deltaDomain(QolDomain.vitality, earlier);
        expect(delta, isNull);
      });

      test('should return null if domain missing in both summaries', () {
        final earlier = QolTrendSummary(
          date: DateTime(2025),
          domainScores: const {
            QolDomain.comfort: 70,
          },
          overallScore: 70,
        );
        final later = QolTrendSummary(
          date: DateTime(2025, 1, 15),
          domainScores: const {
            QolDomain.comfort: 80,
          },
          overallScore: 80,
        );

        final delta = later.deltaDomain(QolDomain.vitality, earlier);
        expect(delta, isNull);
      });

      test('should return zero when domain scores are equal', () {
        final summary1 = QolTrendSummary(
          date: DateTime(2025),
          domainScores: const {
            QolDomain.emotional: 75,
          },
          overallScore: 75,
        );
        final summary2 = QolTrendSummary(
          date: DateTime(2025, 1, 15),
          domainScores: const {
            QolDomain.emotional: 75,
          },
          overallScore: 75,
        );

        final delta = summary1.deltaDomain(QolDomain.emotional, summary2);
        expect(delta, 0);
      });
    });

    group('equality', () {
      test('should be equal for same values', () {
        final summary1 = QolTrendSummary(
          date: testDate,
          domainScores: const {
            QolDomain.vitality: 75,
            QolDomain.comfort: 80,
          },
          overallScore: 77.5,
          assessmentId: 'test-id',
        );
        final summary2 = QolTrendSummary(
          date: testDate,
          domainScores: const {
            QolDomain.vitality: 75,
            QolDomain.comfort: 80,
          },
          overallScore: 77.5,
          assessmentId: 'test-id',
        );

        expect(summary1, equals(summary2));
        expect(summary1.hashCode, equals(summary2.hashCode));
      });

      test('should not be equal for different dates', () {
        final summary1 = QolTrendSummary(
          date: DateTime(2025),
          domainScores: const {},
          overallScore: 75,
        );
        final summary2 = QolTrendSummary(
          date: DateTime(2025, 1, 2),
          domainScores: const {},
          overallScore: 75,
        );

        expect(summary1, isNot(equals(summary2)));
      });

      test('should not be equal for different overall scores', () {
        final summary1 = QolTrendSummary(
          date: testDate,
          domainScores: const {},
          overallScore: 75,
        );
        final summary2 = QolTrendSummary(
          date: testDate,
          domainScores: const {},
          overallScore: 80,
        );

        expect(summary1, isNot(equals(summary2)));
      });

      test('should not be equal for different domain scores', () {
        final summary1 = QolTrendSummary(
          date: testDate,
          domainScores: const {
            QolDomain.vitality: 75,
          },
          overallScore: 75,
        );
        final summary2 = QolTrendSummary(
          date: testDate,
          domainScores: const {
            QolDomain.vitality: 80,
          },
          overallScore: 75,
        );

        expect(summary1, isNot(equals(summary2)));
      });

      test('should not be equal for different number of domains', () {
        final summary1 = QolTrendSummary(
          date: testDate,
          domainScores: const {
            QolDomain.vitality: 75,
          },
          overallScore: 75,
        );
        final summary2 = QolTrendSummary(
          date: testDate,
          domainScores: const {
            QolDomain.vitality: 75,
            QolDomain.comfort: 75,
          },
          overallScore: 75,
        );

        expect(summary1, isNot(equals(summary2)));
      });

      test('should not be equal for different assessment IDs', () {
        final summary1 = QolTrendSummary(
          date: testDate,
          domainScores: const {},
          overallScore: 75,
          assessmentId: 'id1',
        );
        final summary2 = QolTrendSummary(
          date: testDate,
          domainScores: const {},
          overallScore: 75,
          assessmentId: 'id2',
        );

        expect(summary1, isNot(equals(summary2)));
      });

      test('should be equal when both have null assessment IDs', () {
        final summary1 = QolTrendSummary(
          date: testDate,
          domainScores: const {},
          overallScore: 75,
        );
        final summary2 = QolTrendSummary(
          date: testDate,
          domainScores: const {},
          overallScore: 75,
        );

        expect(summary1, equals(summary2));
        expect(summary1.hashCode, equals(summary2.hashCode));
      });
    });

    group('toString', () {
      test('should return readable string', () {
        final summary = QolTrendSummary(
          date: testDate,
          domainScores: const {
            QolDomain.vitality: 75,
            QolDomain.comfort: 80,
          },
          overallScore: 77.5,
        );

        final str = summary.toString();
        expect(str, contains('2025-01-15'));
        expect(str, contains('77.5'));
        expect(str, contains('2')); // 2 domains
      });
    });

    group('edge cases', () {
      test('should handle zero scores', () {
        final summary = QolTrendSummary(
          date: testDate,
          domainScores: const {
            QolDomain.vitality: 0,
          },
          overallScore: 0,
        );

        expect(summary.overallScore, 0);
        expect(summary.domainScores[QolDomain.vitality], 0);
      });

      test('should handle perfect scores', () {
        final summary = QolTrendSummary(
          date: testDate,
          domainScores: const {
            QolDomain.vitality: 100,
            QolDomain.comfort: 100,
          },
          overallScore: 100,
        );

        expect(summary.overallScore, 100);
        expect(summary.domainScores[QolDomain.vitality], 100);
      });

      test('should handle fractional scores', () {
        final summary = QolTrendSummary(
          date: testDate,
          domainScores: const {
            QolDomain.vitality: 75.5,
          },
          overallScore: 77.25,
        );

        expect(summary.overallScore, 77.25);
        expect(summary.domainScores[QolDomain.vitality], 75.5);
      });
    });
  });
}
