import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/features/health/models/symptom_granularity.dart';

void main() {
  group('SymptomGranularity', () {
    test('should have three enum values: week, month, year', () {
      expect(SymptomGranularity.values.length, 3);
      expect(SymptomGranularity.values, contains(SymptomGranularity.week));
      expect(SymptomGranularity.values, contains(SymptomGranularity.month));
      expect(SymptomGranularity.values, contains(SymptomGranularity.year));
    });

    group('label getter', () {
      test('should return "Week" for week granularity', () {
        expect(SymptomGranularity.week.label, 'Week');
      });

      test('should return "Month" for month granularity', () {
        expect(SymptomGranularity.month.label, 'Month');
      });

      test('should return "Year" for year granularity', () {
        expect(SymptomGranularity.year.label, 'Year');
      });
    });
  });
}
