import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/features/health/models/symptom_type.dart';
import 'package:hydracat/providers/symptoms_chart_provider.dart';
import 'package:hydracat/shared/models/daily_summary.dart';

void main() {
  group('buildMonthlySymptomBuckets', () {
    final testMonthStart = DateTime(2025, 10); // October 2025

    test('should return buckets for empty month (all null summaries)', () {
      // October 2025 has 31 days
      final summaries = <DateTime, DailySummary?>{
        for (var i = 0; i < 31; i++)
          testMonthStart.add(Duration(days: i)): null,
      };

      final buckets = buildMonthlySymptomBuckets(
        monthStart: testMonthStart,
        dailySummaries: summaries,
      );

      // October 2025 starts on Wednesday, ends on Friday
      // Week segments can be 4-6 depending on how weeks fall in the month
      expect(buckets.length, greaterThanOrEqualTo(4));
      expect(buckets.length, lessThanOrEqualTo(6));

      for (final bucket in buckets) {
        expect(bucket.daysWithSymptom, isEmpty);
        expect(bucket.daysWithAnySymptoms, 0);
        expect(bucket.totalSymptomDays, 0);
        // Verify bucket dates are within the month
        expect(bucket.start.month, 10);
        expect(bucket.end.month, 10);
      }
    });

    test('should create correct buckets for single-day symptoms', () {
      final oct5 = DateTime(2025, 10, 5); // Sunday
      final oct15 = DateTime(2025, 10, 15); // Wednesday

      final summaries = <DateTime, DailySummary?>{
        for (var i = 0; i < 31; i++)
          testMonthStart.add(Duration(days: i)): null,
        oct5: DailySummary.empty(oct5).copyWith(
          hadVomiting: true,
          hadLethargy: true,
          hasSymptoms: true,
        ),
        oct15: DailySummary.empty(oct15).copyWith(
          hadDiarrhea: true,
          hasSymptoms: true,
        ),
      };

      final buckets = buildMonthlySymptomBuckets(
        monthStart: testMonthStart,
        dailySummaries: summaries,
      );

      // Find buckets containing Oct 5 and Oct 15
      // A bucket contains a date if the date is between start
      // and end (inclusive)
      final oct5Bucket = buckets.firstWhere(
        (b) =>
            (b.start.isBefore(oct5) || b.start.isAtSameMomentAs(oct5)) &&
            (b.end.isAfter(oct5) || b.end.isAtSameMomentAs(oct5)),
        orElse: () => throw StateError('Oct 5 bucket not found'),
      );
      final oct15Bucket = buckets.firstWhere(
        (b) =>
            (b.start.isBefore(oct15) || b.start.isAtSameMomentAs(oct15)) &&
            (b.end.isAfter(oct15) || b.end.isAtSameMomentAs(oct15)),
        orElse: () => throw StateError('Oct 15 bucket not found'),
      );

      // Oct 5 bucket should have symptoms
      expect(oct5Bucket.daysWithSymptom[SymptomType.vomiting], 1);
      expect(oct5Bucket.daysWithSymptom[SymptomType.lethargy], 1);
      expect(oct5Bucket.daysWithSymptom.length, 2);
      expect(oct5Bucket.daysWithAnySymptoms, 1);
      expect(oct5Bucket.totalSymptomDays, 2);

      // Oct 15 bucket should have diarrhea
      expect(oct15Bucket.daysWithSymptom[SymptomType.diarrhea], 1);
      expect(oct15Bucket.daysWithSymptom.length, 1);
      expect(oct15Bucket.daysWithAnySymptoms, 1);
      expect(oct15Bucket.totalSymptomDays, 1);
    });

    test('should accumulate multiple days in same week segment', () {
      // Oct 6-12 is a full week (Mon-Sun)
      final oct6 = DateTime(2025, 10, 6); // Monday
      final oct8 = DateTime(2025, 10, 8); // Wednesday
      final oct10 = DateTime(2025, 10, 10); // Friday

      final summaries = <DateTime, DailySummary?>{
        for (var i = 0; i < 31; i++)
          testMonthStart.add(Duration(days: i)): null,
        oct6: DailySummary.empty(oct6).copyWith(
          hadVomiting: true,
          hasSymptoms: true,
        ),
        oct8: DailySummary.empty(oct8).copyWith(
          hadVomiting: true,
          hadLethargy: true,
          hasSymptoms: true,
        ),
        oct10: DailySummary.empty(oct10).copyWith(
          hadDiarrhea: true,
          hasSymptoms: true,
        ),
      };

      final buckets = buildMonthlySymptomBuckets(
        monthStart: testMonthStart,
        dailySummaries: summaries,
      );

      // Find the bucket for Oct 6-12 week
      // A bucket contains a date if the date is between
      // start and end (inclusive)
      final weekBucket = buckets.firstWhere(
        (b) =>
            (b.start.isBefore(oct6) || b.start.isAtSameMomentAs(oct6)) &&
            (b.end.isAfter(oct6) || b.end.isAtSameMomentAs(oct6)),
        orElse: () => throw StateError('Week bucket not found'),
      );

      // Should accumulate counts from all three days
      expect(weekBucket.daysWithSymptom[SymptomType.vomiting], 2); // Oct 6,
      // Oct 8
      expect(weekBucket.daysWithSymptom[SymptomType.lethargy], 1); // Oct 8
      expect(weekBucket.daysWithSymptom[SymptomType.diarrhea], 1); // Oct 10
      expect(weekBucket.daysWithSymptom.length, 3);
      expect(weekBucket.daysWithAnySymptoms, 3); // 3 days with symptoms
      expect(weekBucket.totalSymptomDays, 4); // 2 + 1 + 1
    });

    test('should handle weeks spanning two months correctly', () {
      // September 2025 - last week includes days from October
      final septStart = DateTime(2025, 9);
      final sept30 = DateTime(2025, 9, 30); // Tuesday
      final oct1 = DateTime(2025, 10); // Wednesday

      final summaries = <DateTime, DailySummary?>{
        for (var i = 0; i < 30; i++) septStart.add(Duration(days: i)): null,
        sept30: DailySummary.empty(sept30).copyWith(
          hadVomiting: true,
          hasSymptoms: true,
        ),
        oct1: DailySummary.empty(oct1).copyWith(
          hadDiarrhea: true,
          hasSymptoms: true,
        ),
      };

      final buckets = buildMonthlySymptomBuckets(
        monthStart: septStart,
        dailySummaries: summaries,
      );

      // September buckets should only include September days
      // Sept 30 is in a week that starts Sept 29 (Mon), but we only count
      // Sept days
      final lastSeptBucket = buckets.last;
      expect(lastSeptBucket.end.month, 9);
      expect(lastSeptBucket.end.day, 30);

      // Sept 30 should be in the last bucket
      expect(
        lastSeptBucket.daysWithSymptom[SymptomType.vomiting],
        1,
      );
      // Oct 1 should NOT be in any September bucket
      expect(
        lastSeptBucket.daysWithSymptom[SymptomType.diarrhea],
        isNull,
      );
    });

    test('should handle months with different day counts', () {
      // Test February (28 days in non-leap year)
      final feb2025 = DateTime(2025, 2);
      final summaries = <DateTime, DailySummary?>{
        for (var i = 0; i < 28; i++) feb2025.add(Duration(days: i)): null,
      };

      final buckets = buildMonthlySymptomBuckets(
        monthStart: feb2025,
        dailySummaries: summaries,
      );

      expect(buckets.length, greaterThanOrEqualTo(4));
      expect(buckets.length, lessThanOrEqualTo(6));

      // All buckets should be in February
      for (final bucket in buckets) {
        expect(bucket.start.month, 2);
        expect(bucket.end.month, 2);
      }

      // Test April (30 days)
      final apr2025 = DateTime(2025, 4);
      final aprSummaries = <DateTime, DailySummary?>{
        for (var i = 0; i < 30; i++) apr2025.add(Duration(days: i)): null,
      };

      final aprBuckets = buildMonthlySymptomBuckets(
        monthStart: apr2025,
        dailySummaries: aprSummaries,
      );

      expect(aprBuckets.length, greaterThanOrEqualTo(4));
      expect(aprBuckets.length, lessThanOrEqualTo(5));
    });

    test('should handle day with hasSymptoms=false (no symptoms present)', () {
      final oct10 = DateTime(2025, 10, 10);

      final summaries = <DateTime, DailySummary?>{
        for (var i = 0; i < 31; i++)
          testMonthStart.add(Duration(days: i)): null,
        oct10: DailySummary.empty(oct10).copyWith(
          hadVomiting: false,
          hadDiarrhea: false,
          hasSymptoms: false,
        ),
      };

      final buckets = buildMonthlySymptomBuckets(
        monthStart: testMonthStart,
        dailySummaries: summaries,
      );

      // Find bucket containing Oct 10
      // A bucket contains a date if the date is between start
      // and end (inclusive)
      final oct10Bucket = buckets.firstWhere(
        (b) =>
            (b.start.isBefore(oct10) || b.start.isAtSameMomentAs(oct10)) &&
            (b.end.isAfter(oct10) || b.end.isAtSameMomentAs(oct10)),
        orElse: () => throw StateError('Oct 10 bucket not found'),
      );

      // Bucket should not have symptoms from this day
      expect(oct10Bucket.daysWithSymptom[SymptomType.vomiting], isNull);
      expect(oct10Bucket.daysWithAnySymptoms, 0);
    });

    test('should sort buckets by start date ascending', () {
      final summaries = <DateTime, DailySummary?>{
        for (var i = 0; i < 31; i++)
          testMonthStart.add(Duration(days: i)): null,
      };

      final buckets = buildMonthlySymptomBuckets(
        monthStart: testMonthStart,
        dailySummaries: summaries,
      );

      for (var i = 0; i < buckets.length - 1; i++) {
        expect(
          buckets[i].start.isBefore(buckets[i + 1].start) ||
              buckets[i].start.isAtSameMomentAs(buckets[i + 1].start),
          isTrue,
        );
      }
    });

    test('should normalize monthStart to start-of-day', () {
      // Use a monthStart with time components
      final monthStartWithTime = DateTime(2025, 10, 14, 30, 45);

      final summaries = <DateTime, DailySummary?>{
        for (var i = 0; i < 31; i++)
          DateTime(2025, 10).add(Duration(days: i)): null,
      };

      final buckets = buildMonthlySymptomBuckets(
        monthStart: monthStartWithTime,
        dailySummaries: summaries,
      );

      expect(buckets.length, greaterThan(0));
      // All buckets should have normalized dates (00:00:00)
      for (final bucket in buckets) {
        expect(bucket.start.hour, 0);
        expect(bucket.start.minute, 0);
        expect(bucket.start.second, 0);
      }
    });

    test('should handle mixed month with various symptom combinations', () {
      final oct3 = DateTime(2025, 10, 3);
      final oct7 = DateTime(2025, 10, 7); // Tuesday
      final oct14 = DateTime(2025, 10, 14); // Tuesday
      final oct20 = DateTime(2025, 10, 20); // Monday
      final oct25 = DateTime(2025, 10, 25); // Saturday

      final summaries = <DateTime, DailySummary?>{
        for (var i = 0; i < 31; i++)
          testMonthStart.add(Duration(days: i)): null,
        oct3: DailySummary.empty(oct3).copyWith(
          hadVomiting: true,
          hasSymptoms: true,
        ),
        oct7: DailySummary.empty(oct7).copyWith(
          hadDiarrhea: true,
          hadLethargy: true,
          hasSymptoms: true,
        ),
        oct14: DailySummary.empty(oct14).copyWith(
          hadConstipation: true,
          hasSymptoms: true,
        ),
        oct20: DailySummary.empty(oct20).copyWith(
          hadSuppressedAppetite: true,
          hadInjectionSiteReaction: true,
          hasSymptoms: true,
        ),
        oct25: DailySummary.empty(oct25).copyWith(
          hadVomiting: true,
          hadLethargy: true,
          hasSymptoms: true,
        ),
      };

      final buckets = buildMonthlySymptomBuckets(
        monthStart: testMonthStart,
        dailySummaries: summaries,
      );

      // Verify we have multiple buckets
      expect(buckets.length, greaterThanOrEqualTo(4));

      // Verify symptom counts are correct across buckets
      var totalVomiting = 0;
      var totalLethargy = 0;
      var totalDiarrhea = 0;

      for (final bucket in buckets) {
        totalVomiting += bucket.daysWithSymptom[SymptomType.vomiting] ?? 0;
        totalLethargy += bucket.daysWithSymptom[SymptomType.lethargy] ?? 0;
        totalDiarrhea += bucket.daysWithSymptom[SymptomType.diarrhea] ?? 0;
      }

      expect(totalVomiting, 2); // Oct 3, Oct 25
      expect(totalLethargy, 2); // Oct 7, Oct 25
      expect(totalDiarrhea, 1); // Oct 7
    });
  });
}
