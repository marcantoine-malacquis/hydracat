import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/features/health/models/symptom_type.dart';
import 'package:hydracat/providers/symptoms_chart_provider.dart';
import 'package:hydracat/shared/models/monthly_summary.dart';

void main() {
  group('buildYearlySymptomBuckets', () {
    // Use 2024 (past year) to ensure all 12 months are included
    final testYearStart = DateTime(2024); // January 2024

    test('should return buckets for empty year (all null summaries)', () {
      final summaries = <DateTime, MonthlySummary?>{
        for (var month = 1; month <= 12; month++) DateTime(2024, month): null,
      };

      final buckets = buildYearlySymptomBuckets(
        yearStart: testYearStart,
        monthlySummaries: summaries,
      );

      // Should have 12 buckets (one per month)
      expect(buckets.length, 12);

      for (var i = 0; i < buckets.length; i++) {
        final bucket = buckets[i];
        expect(bucket.daysWithSymptom, isEmpty);
        expect(bucket.daysWithAnySymptoms, 0);
        expect(bucket.totalSymptomDays, 0);
        // Verify bucket dates correspond to correct month
        expect(bucket.start.month, i + 1);
        expect(bucket.end.month, i + 1);
        expect(bucket.start.year, 2024);
        expect(bucket.end.year, 2024);
      }
    });

    test('should create correct buckets for single-month symptoms', () {
      final janSummary = MonthlySummary.empty(DateTime(2024, 1, 15)).copyWith(
        daysWithVomiting: 3,
        daysWithEnergy: 2,
        daysWithAnySymptoms: 5,
      );
      final marSummary = MonthlySummary.empty(DateTime(2024, 3, 15)).copyWith(
        daysWithDiarrhea: 1,
        daysWithAnySymptoms: 1,
      );

      final summaries = <DateTime, MonthlySummary?>{
        for (var month = 1; month <= 12; month++) DateTime(2024, month): null,
        DateTime(2024): janSummary,
        DateTime(2024, 3): marSummary,
      };

      final buckets = buildYearlySymptomBuckets(
        yearStart: testYearStart,
        monthlySummaries: summaries,
      );

      expect(buckets.length, 12);

      // January bucket (index 0)
      final janBucket = buckets[0];
      expect(janBucket.daysWithSymptom[SymptomType.vomiting], 3);
      expect(janBucket.daysWithSymptom[SymptomType.energy], 2);
      expect(janBucket.daysWithSymptom.length, 2);
      expect(janBucket.daysWithAnySymptoms, 5);
      expect(janBucket.totalSymptomDays, 5);

      // February bucket (index 1) should be empty
      final febBucket = buckets[1];
      expect(febBucket.daysWithSymptom, isEmpty);
      expect(febBucket.daysWithAnySymptoms, 0);

      // March bucket (index 2)
      final marBucket = buckets[2];
      expect(marBucket.daysWithSymptom[SymptomType.diarrhea], 1);
      expect(marBucket.daysWithSymptom.length, 1);
      expect(marBucket.daysWithAnySymptoms, 1);
      expect(marBucket.totalSymptomDays, 1);
    });

    test('should handle multiple months with various symptom combinations', () {
      final janSummary = MonthlySummary.empty(DateTime(2024, 1, 15)).copyWith(
        daysWithVomiting: 2,
        daysWithEnergy: 1,
        daysWithAnySymptoms: 3,
      );
      final aprSummary = MonthlySummary.empty(DateTime(2024, 4, 15)).copyWith(
        daysWithDiarrhea: 3,
        daysWithConstipation: 1,
        daysWithAnySymptoms: 4,
      );
      final julSummary = MonthlySummary.empty(DateTime(2024, 7, 15)).copyWith(
        daysWithSuppressedAppetite: 5,
        daysWithInjectionSiteReaction: 2,
        daysWithAnySymptoms: 7,
      );
      final decSummary = MonthlySummary.empty(DateTime(2024, 12, 15)).copyWith(
        daysWithVomiting: 1,
        daysWithEnergy: 2,
        daysWithDiarrhea: 1,
        daysWithAnySymptoms: 4,
      );

      final summaries = <DateTime, MonthlySummary?>{
        for (var month = 1; month <= 12; month++) DateTime(2024, month): null,
        DateTime(2024): janSummary,
        DateTime(2024, 4): aprSummary,
        DateTime(2024, 7): julSummary,
        DateTime(2024, 12): decSummary,
      };

      final buckets = buildYearlySymptomBuckets(
        yearStart: testYearStart,
        monthlySummaries: summaries,
      );

      expect(buckets.length, 12);

      // Verify symptom counts across all buckets
      var totalVomiting = 0;
      var totalEnergy = 0;
      var totalDiarrhea = 0;
      var totalSuppressedAppetite = 0;

      for (final bucket in buckets) {
        totalVomiting += bucket.daysWithSymptom[SymptomType.vomiting] ?? 0;
        totalEnergy += bucket.daysWithSymptom[SymptomType.energy] ?? 0;
        totalDiarrhea += bucket.daysWithSymptom[SymptomType.diarrhea] ?? 0;
        totalSuppressedAppetite +=
            bucket.daysWithSymptom[SymptomType.suppressedAppetite] ?? 0;
      }

      expect(totalVomiting, 3); // Jan: 2, Dec: 1
      expect(totalEnergy, 3); // Jan: 1, Dec: 2
      expect(totalDiarrhea, 4); // Apr: 3, Dec: 1
      expect(totalSuppressedAppetite, 5); // Jul: 5
    });

    test('should stop at current month if year includes future months', () {
      // Use a year that includes the current month
      final now = DateTime.now();
      final currentYear = now.year;
      final currentMonth = now.month;
      final yearStart = DateTime(currentYear);

      final summaries = <DateTime, MonthlySummary?>{
        for (var month = 1; month <= 12; month++)
          DateTime(currentYear, month): null,
      };

      final buckets = buildYearlySymptomBuckets(
        yearStart: yearStart,
        monthlySummaries: summaries,
      );

      // Should only have buckets up to current month
      expect(buckets.length, currentMonth);

      // All buckets should be in the current year
      for (final bucket in buckets) {
        expect(bucket.start.year, currentYear);
        expect(bucket.end.year, currentYear);
      }

      // Last bucket should be the current month
      final lastBucket = buckets.last;
      expect(lastBucket.start.month, currentMonth);
      expect(lastBucket.end.month, currentMonth);
    });

    test(
      'should handle missing summaries (some months null, some with data)',
      () {
        final febSummary = MonthlySummary.empty(DateTime(2024, 2, 15)).copyWith(
          daysWithVomiting: 1,
          daysWithAnySymptoms: 1,
        );
        final junSummary = MonthlySummary.empty(DateTime(2024, 6, 15)).copyWith(
          daysWithEnergy: 2,
          daysWithAnySymptoms: 2,
        );

        final summaries = <DateTime, MonthlySummary?>{
          for (var month = 1; month <= 12; month++) DateTime(2024, month): null,
          DateTime(2024, 2): febSummary,
          DateTime(2024, 6): junSummary,
        };

        final buckets = buildYearlySymptomBuckets(
          yearStart: testYearStart,
          monthlySummaries: summaries,
        );

        expect(buckets.length, 12);

        // February bucket (index 1) should have symptoms
        final febBucket = buckets[1];
        expect(febBucket.daysWithSymptom[SymptomType.vomiting], 1);
        expect(febBucket.daysWithAnySymptoms, 1);

        // March bucket (index 2) should be empty (null summary)
        final marBucket = buckets[2];
        expect(marBucket.daysWithSymptom, isEmpty);
        expect(marBucket.daysWithAnySymptoms, 0);

        // June bucket (index 5) should have symptoms
        final junBucket = buckets[5];
        expect(junBucket.daysWithSymptom[SymptomType.energy], 2);
        expect(junBucket.daysWithAnySymptoms, 2);
      },
    );

    test('should use summary startDate and endDate for bucket dates', () {
      final janSummary = MonthlySummary.empty(DateTime(2024, 1, 15));
      final febSummary = MonthlySummary.empty(DateTime(2024, 2, 15)).copyWith(
        daysWithVomiting: 1,
        daysWithAnySymptoms: 1,
      );

      final summaries = <DateTime, MonthlySummary?>{
        for (var month = 1; month <= 12; month++) DateTime(2024, month): null,
        DateTime(2024): janSummary,
        DateTime(2024, 2): febSummary,
      };

      final buckets = buildYearlySymptomBuckets(
        yearStart: testYearStart,
        monthlySummaries: summaries,
      );

      // January bucket should use summary's startDate and endDate
      final janBucket = buckets[0];
      expect(janBucket.start, janSummary.startDate);
      expect(janBucket.end, janSummary.endDate);

      // February bucket should use summary's startDate and endDate
      final febBucket = buckets[1];
      expect(febBucket.start, febSummary.startDate);
      expect(febBucket.end, febSummary.endDate);
    });

    test('should only include symptoms with count > 0 in map', () {
      final summary = MonthlySummary.empty(DateTime(2024, 3, 15)).copyWith(
        daysWithVomiting: 3,
        daysWithDiarrhea: 0, // Should not be in map
        daysWithConstipation: 0, // Should not be in map
        daysWithEnergy: 2,
        daysWithSuppressedAppetite: 0, // Should not be in map
        daysWithInjectionSiteReaction: 1,
        daysWithAnySymptoms: 6,
      );

      final summaries = <DateTime, MonthlySummary?>{
        for (var month = 1; month <= 12; month++) DateTime(2024, month): null,
        DateTime(2024, 3): summary,
      };

      final buckets = buildYearlySymptomBuckets(
        yearStart: testYearStart,
        monthlySummaries: summaries,
      );

      final marBucket = buckets[2];
      // Should only have 3 symptoms (vomiting, energy, injectionSiteReaction)
      expect(marBucket.daysWithSymptom.length, 3);
      expect(marBucket.daysWithSymptom[SymptomType.vomiting], 3);
      expect(marBucket.daysWithSymptom[SymptomType.energy], 2);
      expect(marBucket.daysWithSymptom[SymptomType.injectionSiteReaction], 1);
      expect(marBucket.daysWithSymptom[SymptomType.diarrhea], isNull);
      expect(marBucket.daysWithSymptom[SymptomType.constipation], isNull);
      expect(marBucket.daysWithSymptom[SymptomType.suppressedAppetite], isNull);
    });

    test('should sort buckets by start date ascending', () {
      final summaries = <DateTime, MonthlySummary?>{
        for (var month = 1; month <= 12; month++) DateTime(2024, month): null,
      };

      final buckets = buildYearlySymptomBuckets(
        yearStart: testYearStart,
        monthlySummaries: summaries,
      );

      for (var i = 0; i < buckets.length - 1; i++) {
        expect(
          buckets[i].start.isBefore(buckets[i + 1].start) ||
              buckets[i].start.isAtSameMomentAs(buckets[i + 1].start),
          isTrue,
        );
      }
    });

    test('should normalize yearStart to first day of year', () {
      // Use a yearStart with time components
      final yearStartWithTime = DateTime(2024, 6, 15, 14, 30, 45);

      final summaries = <DateTime, MonthlySummary?>{
        for (var month = 1; month <= 12; month++) DateTime(2024, month): null,
      };

      final buckets = buildYearlySymptomBuckets(
        yearStart: yearStartWithTime,
        monthlySummaries: summaries,
      );

      expect(buckets.length, 12);
      // All buckets should be in 2024
      for (final bucket in buckets) {
        expect(bucket.start.year, 2024);
        expect(bucket.end.year, 2024);
      }
      // First bucket should be January
      expect(buckets.first.start.month, 1);
    });

    test('should handle leap year February correctly', () {
      // 2024 is a leap year
      final leapYearStart = DateTime(2024);
      final febSummary = MonthlySummary.empty(DateTime(2024, 2, 15)).copyWith(
        daysWithVomiting: 1,
        daysWithAnySymptoms: 1,
      );

      final summaries = <DateTime, MonthlySummary?>{
        for (var month = 1; month <= 12; month++) DateTime(2024, month): null,
        DateTime(2024, 2): febSummary,
      };

      final buckets = buildYearlySymptomBuckets(
        yearStart: leapYearStart,
        monthlySummaries: summaries,
      );

      expect(buckets.length, 12);

      // February bucket should have correct end date (Feb 29, 2024)
      final febBucket = buckets[1];
      expect(febBucket.start.month, 2);
      expect(febBucket.end.month, 2);
      expect(febBucket.end.day, 29); // Leap year
      expect(febBucket.end.year, 2024);
    });

    test('should handle all 6 symptom types', () {
      final summary = MonthlySummary.empty(DateTime(2024, 5, 15)).copyWith(
        daysWithVomiting: 1,
        daysWithDiarrhea: 2,
        daysWithConstipation: 3,
        daysWithEnergy: 4,
        daysWithSuppressedAppetite: 5,
        daysWithInjectionSiteReaction: 6,
        daysWithAnySymptoms: 21,
      );

      final summaries = <DateTime, MonthlySummary?>{
        for (var month = 1; month <= 12; month++) DateTime(2024, month): null,
        DateTime(2024, 5): summary,
      };

      final buckets = buildYearlySymptomBuckets(
        yearStart: testYearStart,
        monthlySummaries: summaries,
      );

      final mayBucket = buckets[4];
      expect(mayBucket.daysWithSymptom[SymptomType.vomiting], 1);
      expect(mayBucket.daysWithSymptom[SymptomType.diarrhea], 2);
      expect(mayBucket.daysWithSymptom[SymptomType.constipation], 3);
      expect(mayBucket.daysWithSymptom[SymptomType.energy], 4);
      expect(mayBucket.daysWithSymptom[SymptomType.suppressedAppetite], 5);
      expect(mayBucket.daysWithSymptom[SymptomType.injectionSiteReaction], 6);
      expect(mayBucket.daysWithSymptom.length, 6);
      expect(mayBucket.daysWithAnySymptoms, 21);
      expect(mayBucket.totalSymptomDays, 21);
    });
  });
}
