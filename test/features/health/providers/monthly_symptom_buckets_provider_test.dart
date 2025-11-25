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

      // Should have exactly one bucket per day
      expect(buckets.length, 31);

      for (final bucket in buckets) {
        expect(bucket.daysWithSymptom, isEmpty);
        expect(bucket.daysWithAnySymptoms, 0);
        expect(bucket.totalSymptomDays, 0);
        // Verify bucket dates are within the month
        expect(bucket.start.month, 10);
        expect(bucket.end.month, 10);
        // Each bucket represents a single day
        expect(bucket.start.isAtSameMomentAs(bucket.end), isTrue);
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

      // Should have exactly one bucket per day
      expect(buckets.length, 31);

      // Find buckets for Oct 5 and Oct 15 (each bucket represents a single day)
      final oct5Bucket = buckets.firstWhere(
        (b) => b.start.isAtSameMomentAs(oct5),
        orElse: () => throw StateError('Oct 5 bucket not found'),
      );
      final oct15Bucket = buckets.firstWhere(
        (b) => b.start.isAtSameMomentAs(oct15),
        orElse: () => throw StateError('Oct 15 bucket not found'),
      );

      // Oct 5 bucket should have symptoms
      expect(oct5Bucket.daysWithSymptom[SymptomType.vomiting], 1);
      expect(oct5Bucket.daysWithSymptom[SymptomType.lethargy], 1);
      expect(oct5Bucket.daysWithSymptom.length, 2);
      expect(oct5Bucket.daysWithAnySymptoms, 1);
      expect(oct5Bucket.totalSymptomDays, 2);
      expect(oct5Bucket.start.isAtSameMomentAs(oct5Bucket.end), isTrue);

      // Oct 15 bucket should have diarrhea
      expect(oct15Bucket.daysWithSymptom[SymptomType.diarrhea], 1);
      expect(oct15Bucket.daysWithSymptom.length, 1);
      expect(oct15Bucket.daysWithAnySymptoms, 1);
      expect(oct15Bucket.totalSymptomDays, 1);
      expect(oct15Bucket.start.isAtSameMomentAs(oct15Bucket.end), isTrue);
    });

    test('should create separate buckets for each day', () {
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

      // Should have exactly one bucket per day
      expect(buckets.length, 31);

      // Find individual day buckets
      final oct6Bucket = buckets.firstWhere(
        (b) => b.start.isAtSameMomentAs(oct6),
        orElse: () => throw StateError('Oct 6 bucket not found'),
      );
      final oct8Bucket = buckets.firstWhere(
        (b) => b.start.isAtSameMomentAs(oct8),
        orElse: () => throw StateError('Oct 8 bucket not found'),
      );
      final oct10Bucket = buckets.firstWhere(
        (b) => b.start.isAtSameMomentAs(oct10),
        orElse: () => throw StateError('Oct 10 bucket not found'),
      );

      // Each day should have its own bucket with correct counts
      expect(oct6Bucket.daysWithSymptom[SymptomType.vomiting], 1);
      expect(oct6Bucket.daysWithAnySymptoms, 1);
      expect(oct6Bucket.totalSymptomDays, 1);

      expect(oct8Bucket.daysWithSymptom[SymptomType.vomiting], 1);
      expect(oct8Bucket.daysWithSymptom[SymptomType.lethargy], 1);
      expect(oct8Bucket.daysWithAnySymptoms, 1);
      expect(oct8Bucket.totalSymptomDays, 2);

      expect(oct10Bucket.daysWithSymptom[SymptomType.diarrhea], 1);
      expect(oct10Bucket.daysWithAnySymptoms, 1);
      expect(oct10Bucket.totalSymptomDays, 1);
    });

    test(
      'should handle months correctly without including adjacent months',
      () {
        // September 2025 - last day is Sept 30
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

        // September should have exactly 30 buckets (one per day)
        expect(buckets.length, 30);

        // All buckets should be in September
        for (final bucket in buckets) {
          expect(bucket.start.month, 9);
          expect(bucket.end.month, 9);
          expect(bucket.start.isAtSameMomentAs(bucket.end), isTrue);
        }

        // Sept 30 should have its own bucket with vomiting
        final sept30Bucket = buckets.firstWhere(
          (b) => b.start.isAtSameMomentAs(sept30),
          orElse: () => throw StateError('Sept 30 bucket not found'),
        );
        expect(sept30Bucket.daysWithSymptom[SymptomType.vomiting], 1);
        // Oct 1 should NOT be in any September bucket
        expect(sept30Bucket.daysWithSymptom[SymptomType.diarrhea], isNull);
      },
    );

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

      // Should have exactly one bucket per day
      expect(buckets.length, 28);

      // All buckets should be in February
      for (final bucket in buckets) {
        expect(bucket.start.month, 2);
        expect(bucket.end.month, 2);
        expect(bucket.start.isAtSameMomentAs(bucket.end), isTrue);
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

      // Should have exactly one bucket per day
      expect(aprBuckets.length, 30);
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

      // Should have exactly one bucket per day
      expect(buckets.length, 31);

      // Find bucket for Oct 10 (each bucket represents a single day)
      final oct10Bucket = buckets.firstWhere(
        (b) => b.start.isAtSameMomentAs(oct10),
        orElse: () => throw StateError('Oct 10 bucket not found'),
      );

      // Bucket should not have symptoms from this day
      expect(oct10Bucket.daysWithSymptom[SymptomType.vomiting], isNull);
      expect(oct10Bucket.daysWithAnySymptoms, 0);
      expect(oct10Bucket.start.isAtSameMomentAs(oct10Bucket.end), isTrue);
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

      // Should have exactly one bucket per day
      expect(buckets.length, 31);

      // Verify symptom counts are correct across buckets
      var totalVomiting = 0;
      var totalLethargy = 0;
      var totalDiarrhea = 0;

      for (final bucket in buckets) {
        totalVomiting += bucket.daysWithSymptom[SymptomType.vomiting] ?? 0;
        totalLethargy += bucket.daysWithSymptom[SymptomType.lethargy] ?? 0;
        totalDiarrhea += bucket.daysWithSymptom[SymptomType.diarrhea] ?? 0;
        // Each bucket represents a single day
        expect(bucket.start.isAtSameMomentAs(bucket.end), isTrue);
      }

      expect(totalVomiting, 2); // Oct 3, Oct 25
      expect(totalLethargy, 2); // Oct 7, Oct 25
      expect(totalDiarrhea, 1); // Oct 7
    });
  });
}
