import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/features/health/models/symptom_bucket.dart';
import 'package:hydracat/features/health/models/symptom_type.dart';

void main() {
  group('SymptomBucket', () {
    final testDate = DateTime(2025, 10, 5);
    final testStart = DateTime(2025, 10);
    final testEnd = DateTime(2025, 10, 7);

    group('Constructor', () {
      test('should create bucket with required fields', () {
        final bucket = SymptomBucket(
          start: testStart,
          end: testEnd,
          daysWithSymptom: const {
            SymptomType.vomiting: 2,
            SymptomType.diarrhea: 1,
          },
          daysWithAnySymptoms: 3,
        );

        expect(bucket.start, testStart);
        expect(bucket.end, testEnd);
        expect(bucket.daysWithSymptom[SymptomType.vomiting], 2);
        expect(bucket.daysWithSymptom[SymptomType.diarrhea], 1);
        expect(bucket.daysWithAnySymptoms, 3);
      });

      test('should create single-day bucket with start == end', () {
        final bucket = SymptomBucket(
          start: testDate,
          end: testDate,
          daysWithSymptom: const {SymptomType.lethargy: 1},
          daysWithAnySymptoms: 1,
        );

        expect(bucket.start, bucket.end);
        expect(bucket.start, testDate);
      });

      test('should make daysWithSymptom map unmodifiable', () {
        final bucket = SymptomBucket(
          start: testStart,
          end: testEnd,
          daysWithSymptom: const {SymptomType.vomiting: 2},
          daysWithAnySymptoms: 2,
        );

        expect(
          () => bucket.daysWithSymptom[SymptomType.diarrhea] = 1,
          throwsA(isA<UnsupportedError>()),
        );
      });
    });

    group('totalSymptomDays', () {
      test('should return 0 for empty map', () {
        final bucket = SymptomBucket(
          start: testStart,
          end: testEnd,
          daysWithSymptom: const {},
          daysWithAnySymptoms: 0,
        );

        expect(bucket.totalSymptomDays, 0);
      });

      test('should sum all values in daysWithSymptom', () {
        final bucket = SymptomBucket(
          start: testStart,
          end: testEnd,
          daysWithSymptom: const {
            SymptomType.vomiting: 3,
            SymptomType.diarrhea: 2,
            SymptomType.lethargy: 1,
          },
          daysWithAnySymptoms: 4,
        );

        expect(bucket.totalSymptomDays, 6);
      });

      test('should handle single symptom', () {
        final bucket = SymptomBucket(
          start: testStart,
          end: testEnd,
          daysWithSymptom: const {SymptomType.constipation: 5},
          daysWithAnySymptoms: 5,
        );

        expect(bucket.totalSymptomDays, 5);
      });
    });

    group('empty factory constructor', () {
      test('should create empty single-day bucket', () {
        final bucket = SymptomBucket.empty(testDate);

        expect(bucket.start, bucket.end);
        expect(bucket.start, DateTime(2025, 10, 5));
        expect(bucket.daysWithSymptom, isEmpty);
        expect(bucket.daysWithAnySymptoms, 0);
        expect(bucket.totalSymptomDays, 0);
      });

      test('should normalize date to start of day', () {
        final dateWithTime = DateTime(2025, 10, 5, 14, 30, 45);
        final bucket = SymptomBucket.empty(dateWithTime);

        expect(bucket.start, DateTime(2025, 10, 5));
        expect(bucket.end, DateTime(2025, 10, 5));
      });
    });

    group('forRange factory constructor', () {
      test('should create empty multi-day bucket', () {
        final bucket = SymptomBucket.forRange(
          start: testStart,
          end: testEnd,
        );

        expect(bucket.start, DateTime(2025, 10));
        expect(bucket.end, DateTime(2025, 10, 7));
        expect(bucket.daysWithSymptom, isEmpty);
        expect(bucket.daysWithAnySymptoms, 0);
        expect(bucket.totalSymptomDays, 0);
      });

      test('should normalize dates to start of day', () {
        final startWithTime = DateTime(2025, 10, 1, 10, 15, 30);
        final endWithTime = DateTime(2025, 10, 7, 20, 45);
        final bucket = SymptomBucket.forRange(
          start: startWithTime,
          end: endWithTime,
        );

        expect(bucket.start, DateTime(2025, 10));
        expect(bucket.end, DateTime(2025, 10, 7));
      });
    });

    group('copyWith', () {
      test('should create new bucket with updated start', () {
        final original = SymptomBucket(
          start: testStart,
          end: testEnd,
          daysWithSymptom: const {SymptomType.vomiting: 2},
          daysWithAnySymptoms: 2,
        );

        final updated = original.copyWith(
          start: DateTime(2025, 10, 2),
        );

        expect(updated.start, DateTime(2025, 10, 2));
        expect(updated.end, testEnd);
        expect(updated.daysWithSymptom, original.daysWithSymptom);
        expect(updated.daysWithAnySymptoms, original.daysWithAnySymptoms);
      });

      test('should create new bucket with updated end', () {
        final original = SymptomBucket(
          start: testStart,
          end: testEnd,
          daysWithSymptom: const {SymptomType.vomiting: 2},
          daysWithAnySymptoms: 2,
        );

        final updated = original.copyWith(
          end: DateTime(2025, 10, 8),
        );

        expect(updated.start, testStart);
        expect(updated.end, DateTime(2025, 10, 8));
        expect(updated.daysWithSymptom, original.daysWithSymptom);
        expect(updated.daysWithAnySymptoms, original.daysWithAnySymptoms);
      });

      test('should create new bucket with updated daysWithSymptom', () {
        final original = SymptomBucket(
          start: testStart,
          end: testEnd,
          daysWithSymptom: const {SymptomType.vomiting: 2},
          daysWithAnySymptoms: 2,
        );

        final updated = original.copyWith(
          daysWithSymptom: {
            SymptomType.vomiting: 3,
            SymptomType.diarrhea: 1,
          },
        );

        expect(updated.start, testStart);
        expect(updated.end, testEnd);
        expect(updated.daysWithSymptom[SymptomType.vomiting], 3);
        expect(updated.daysWithSymptom[SymptomType.diarrhea], 1);
        expect(updated.daysWithAnySymptoms, original.daysWithAnySymptoms);
      });

      test('should create new bucket with updated daysWithAnySymptoms', () {
        final original = SymptomBucket(
          start: testStart,
          end: testEnd,
          daysWithSymptom: const {SymptomType.vomiting: 2},
          daysWithAnySymptoms: 2,
        );

        final updated = original.copyWith(
          daysWithAnySymptoms: 3,
        );

        expect(updated.start, testStart);
        expect(updated.end, testEnd);
        expect(updated.daysWithSymptom, original.daysWithSymptom);
        expect(updated.daysWithAnySymptoms, 3);
      });

      test('should create new bucket with multiple updated fields', () {
        final original = SymptomBucket(
          start: testStart,
          end: testEnd,
          daysWithSymptom: const {SymptomType.vomiting: 2},
          daysWithAnySymptoms: 2,
        );

        final updated = original.copyWith(
          start: DateTime(2025, 10, 2),
          daysWithSymptom: {SymptomType.lethargy: 1},
          daysWithAnySymptoms: 1,
        );

        expect(updated.start, DateTime(2025, 10, 2));
        expect(updated.end, testEnd);
        expect(updated.daysWithSymptom[SymptomType.lethargy], 1);
        expect(updated.daysWithAnySymptoms, 1);
      });

      test('should preserve original when no fields updated', () {
        final original = SymptomBucket(
          start: testStart,
          end: testEnd,
          daysWithSymptom: const {SymptomType.vomiting: 2},
          daysWithAnySymptoms: 2,
        );

        final copied = original.copyWith();

        expect(copied.start, original.start);
        expect(copied.end, original.end);
        expect(copied.daysWithSymptom, original.daysWithSymptom);
        expect(copied.daysWithAnySymptoms, original.daysWithAnySymptoms);
      });
    });

    group('Equality and hashCode', () {
      test('should be equal when all fields match', () {
        final bucket1 = SymptomBucket(
          start: testStart,
          end: testEnd,
          daysWithSymptom: const {
            SymptomType.vomiting: 2,
            SymptomType.diarrhea: 1,
          },
          daysWithAnySymptoms: 3,
        );

        final bucket2 = SymptomBucket(
          start: testStart,
          end: testEnd,
          daysWithSymptom: const {
            SymptomType.vomiting: 2,
            SymptomType.diarrhea: 1,
          },
          daysWithAnySymptoms: 3,
        );

        expect(bucket1, equals(bucket2));
        expect(bucket1.hashCode, equals(bucket2.hashCode));
      });

      test('should not be equal when start differs', () {
        final bucket1 = SymptomBucket(
          start: testStart,
          end: testEnd,
          daysWithSymptom: const {SymptomType.vomiting: 2},
          daysWithAnySymptoms: 2,
        );

        final bucket2 = SymptomBucket(
          start: DateTime(2025, 10, 2),
          end: testEnd,
          daysWithSymptom: const {SymptomType.vomiting: 2},
          daysWithAnySymptoms: 2,
        );

        expect(bucket1, isNot(equals(bucket2)));
      });

      test('should not be equal when end differs', () {
        final bucket1 = SymptomBucket(
          start: testStart,
          end: testEnd,
          daysWithSymptom: const {SymptomType.vomiting: 2},
          daysWithAnySymptoms: 2,
        );

        final bucket2 = SymptomBucket(
          start: testStart,
          end: DateTime(2025, 10, 8),
          daysWithSymptom: const {SymptomType.vomiting: 2},
          daysWithAnySymptoms: 2,
        );

        expect(bucket1, isNot(equals(bucket2)));
      });

      test('should not be equal when daysWithSymptom differs', () {
        final bucket1 = SymptomBucket(
          start: testStart,
          end: testEnd,
          daysWithSymptom: const {SymptomType.vomiting: 2},
          daysWithAnySymptoms: 2,
        );

        final bucket2 = SymptomBucket(
          start: testStart,
          end: testEnd,
          daysWithSymptom: const {SymptomType.vomiting: 3},
          daysWithAnySymptoms: 2,
        );

        expect(bucket1, isNot(equals(bucket2)));
      });

      test('should not be equal when daysWithAnySymptoms differs', () {
        final bucket1 = SymptomBucket(
          start: testStart,
          end: testEnd,
          daysWithSymptom: const {SymptomType.vomiting: 2},
          daysWithAnySymptoms: 2,
        );

        final bucket2 = SymptomBucket(
          start: testStart,
          end: testEnd,
          daysWithSymptom: const {SymptomType.vomiting: 2},
          daysWithAnySymptoms: 3,
        );

        expect(bucket1, isNot(equals(bucket2)));
      });

      test('should handle map equality correctly', () {
        final bucket1 = SymptomBucket(
          start: testStart,
          end: testEnd,
          daysWithSymptom: const {
            SymptomType.vomiting: 2,
            SymptomType.diarrhea: 1,
          },
          daysWithAnySymptoms: 3,
        );

        final bucket2 = SymptomBucket(
          start: testStart,
          end: testEnd,
          daysWithSymptom: const {
            SymptomType.diarrhea: 1,
            SymptomType.vomiting: 2,
          },
          daysWithAnySymptoms: 3,
        );

        // Maps with same key-value pairs should be equal regardless
        // of insertion order
        expect(bucket1, equals(bucket2));
      });

      test('should handle empty maps correctly', () {
        final bucket1 = SymptomBucket(
          start: testStart,
          end: testEnd,
          daysWithSymptom: const {},
          daysWithAnySymptoms: 0,
        );

        final bucket2 = SymptomBucket(
          start: testStart,
          end: testEnd,
          daysWithSymptom: const {},
          daysWithAnySymptoms: 0,
        );

        expect(bucket1, equals(bucket2));
      });
    });

    group('toString', () {
      test('should include all fields in string representation', () {
        final bucket = SymptomBucket(
          start: testStart,
          end: testEnd,
          daysWithSymptom: const {
            SymptomType.vomiting: 2,
            SymptomType.diarrhea: 1,
          },
          daysWithAnySymptoms: 3,
        );

        final str = bucket.toString();
        expect(str, contains('SymptomBucket'));
        expect(str, contains('start:'));
        expect(str, contains('end:'));
        expect(str, contains('daysWithSymptom:'));
        expect(str, contains('daysWithAnySymptoms:'));
      });
    });
  });
}
