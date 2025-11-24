import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/core/utils/date_utils.dart';
import 'package:hydracat/features/health/models/symptom_type.dart';
import 'package:hydracat/providers/symptoms_chart_provider.dart';
import 'package:hydracat/shared/models/daily_summary.dart';

void main() {
  group('buildWeeklySymptomBuckets', () {
    final testWeekStart = AppDateUtils.startOfWeekMonday(
      DateTime(2025, 10, 6), // Monday, Oct 6, 2025
    );

    test('should return 7 buckets for empty week (all null summaries)', () {
      final summaries = <DateTime, DailySummary?>{
        for (var i = 0; i < 7; i++) testWeekStart.add(Duration(days: i)): null,
      };

      final buckets = buildWeeklySymptomBuckets(
        weekStart: testWeekStart,
        summaries: summaries,
      );

      expect(buckets.length, 7);
      for (final bucket in buckets) {
        expect(bucket.daysWithSymptom, isEmpty);
        expect(bucket.daysWithAnySymptoms, 0);
        expect(bucket.start, bucket.end);
        expect(bucket.totalSymptomDays, 0);
      }
    });

    test('should create correct bucket for single-day symptoms', () {
      final wednesday = testWeekStart.add(const Duration(days: 2));
      final summaries = <DateTime, DailySummary?>{
        for (var i = 0; i < 7; i++) testWeekStart.add(Duration(days: i)): null,
        wednesday: DailySummary.empty(wednesday).copyWith(
          hadVomiting: true,
          hadLethargy: true,
          hasSymptoms: true,
        ),
      };

      final buckets = buildWeeklySymptomBuckets(
        weekStart: testWeekStart,
        summaries: summaries,
      );

      expect(buckets.length, 7);

      // Check Wednesday (index 2) has symptoms
      final wednesdayBucket = buckets[2];
      expect(wednesdayBucket.start, wednesdayBucket.end);
      expect(wednesdayBucket.start, wednesday);
      expect(wednesdayBucket.daysWithSymptom[SymptomType.vomiting], 1);
      expect(wednesdayBucket.daysWithSymptom[SymptomType.lethargy], 1);
      expect(wednesdayBucket.daysWithSymptom.length, 2);
      expect(wednesdayBucket.daysWithAnySymptoms, 1);
      expect(wednesdayBucket.totalSymptomDays, 2);

      // Check other days are empty
      for (var i = 0; i < 7; i++) {
        if (i != 2) {
          expect(buckets[i].daysWithSymptom, isEmpty);
          expect(buckets[i].daysWithAnySymptoms, 0);
        }
      }
    });

    test('should handle multiple symptoms on same day', () {
      final friday = testWeekStart.add(const Duration(days: 4));
      final summaries = <DateTime, DailySummary?>{
        for (var i = 0; i < 7; i++) testWeekStart.add(Duration(days: i)): null,
        friday: DailySummary.empty(friday).copyWith(
          hadVomiting: true,
          hadDiarrhea: true,
          hadConstipation: true,
          hadLethargy: true,
          hadSuppressedAppetite: true,
          hadInjectionSiteReaction: true,
          hasSymptoms: true,
        ),
      };

      final buckets = buildWeeklySymptomBuckets(
        weekStart: testWeekStart,
        summaries: summaries,
      );

      final fridayBucket = buckets[4];
      expect(fridayBucket.daysWithSymptom.length, 6);
      expect(fridayBucket.daysWithSymptom[SymptomType.vomiting], 1);
      expect(fridayBucket.daysWithSymptom[SymptomType.diarrhea], 1);
      expect(fridayBucket.daysWithSymptom[SymptomType.constipation], 1);
      expect(fridayBucket.daysWithSymptom[SymptomType.lethargy], 1);
      expect(fridayBucket.daysWithSymptom[SymptomType.suppressedAppetite], 1);
      expect(
        fridayBucket.daysWithSymptom[SymptomType.injectionSiteReaction],
        1,
      );
      expect(fridayBucket.totalSymptomDays, 6);
      expect(fridayBucket.daysWithAnySymptoms, 1);
    });

    test('should handle mixed week with different symptom combinations', () {
      final monday = testWeekStart;
      final tuesday = testWeekStart.add(const Duration(days: 1));
      final thursday = testWeekStart.add(const Duration(days: 3));
      final saturday = testWeekStart.add(const Duration(days: 5));

      final summaries = <DateTime, DailySummary?>{
        for (var i = 0; i < 7; i++) testWeekStart.add(Duration(days: i)): null,
        monday: DailySummary.empty(monday).copyWith(
          hadVomiting: true,
          hasSymptoms: true,
        ),
        tuesday: DailySummary.empty(tuesday).copyWith(
          hadDiarrhea: true,
          hadLethargy: true,
          hasSymptoms: true,
        ),
        thursday: DailySummary.empty(thursday).copyWith(
          hadConstipation: true,
          hasSymptoms: true,
        ),
        saturday: DailySummary.empty(saturday).copyWith(
          hadSuppressedAppetite: true,
          hadInjectionSiteReaction: true,
          hasSymptoms: true,
        ),
      };

      final buckets = buildWeeklySymptomBuckets(
        weekStart: testWeekStart,
        summaries: summaries,
      );

      expect(buckets.length, 7);

      // Monday (index 0)
      expect(buckets[0].daysWithSymptom[SymptomType.vomiting], 1);
      expect(buckets[0].daysWithSymptom.length, 1);
      expect(buckets[0].daysWithAnySymptoms, 1);

      // Tuesday (index 1)
      expect(buckets[1].daysWithSymptom[SymptomType.diarrhea], 1);
      expect(buckets[1].daysWithSymptom[SymptomType.lethargy], 1);
      expect(buckets[1].daysWithSymptom.length, 2);
      expect(buckets[1].daysWithAnySymptoms, 1);

      // Wednesday (index 2) - empty
      expect(buckets[2].daysWithSymptom, isEmpty);
      expect(buckets[2].daysWithAnySymptoms, 0);

      // Thursday (index 3)
      expect(buckets[3].daysWithSymptom[SymptomType.constipation], 1);
      expect(buckets[3].daysWithSymptom.length, 1);
      expect(buckets[3].daysWithAnySymptoms, 1);

      // Friday (index 4) - empty
      expect(buckets[4].daysWithSymptom, isEmpty);
      expect(buckets[4].daysWithAnySymptoms, 0);

      // Saturday (index 5)
      expect(buckets[5].daysWithSymptom[SymptomType.suppressedAppetite], 1);
      expect(
        buckets[5].daysWithSymptom[SymptomType.injectionSiteReaction],
        1,
      );
      expect(buckets[5].daysWithSymptom.length, 2);
      expect(buckets[5].daysWithAnySymptoms, 1);

      // Sunday (index 6) - empty
      expect(buckets[6].daysWithSymptom, isEmpty);
      expect(buckets[6].daysWithAnySymptoms, 0);
    });

    test('should handle day with hasSymptoms=false (no symptoms present)', () {
      final monday = testWeekStart;
      final summaries = <DateTime, DailySummary?>{
        for (var i = 0; i < 7; i++) testWeekStart.add(Duration(days: i)): null,
        monday: DailySummary.empty(monday).copyWith(
          hadVomiting: false,
          hadDiarrhea: false,
          hasSymptoms: false,
        ),
      };

      final buckets = buildWeeklySymptomBuckets(
        weekStart: testWeekStart,
        summaries: summaries,
      );

      final mondayBucket = buckets[0];
      expect(mondayBucket.daysWithSymptom, isEmpty);
      expect(mondayBucket.daysWithAnySymptoms, 0);
      expect(mondayBucket.totalSymptomDays, 0);
    });

    test('should maintain correct ordering (Monday to Sunday)', () {
      final summaries = <DateTime, DailySummary?>{
        for (var i = 0; i < 7; i++) testWeekStart.add(Duration(days: i)): null,
      };

      final buckets = buildWeeklySymptomBuckets(
        weekStart: testWeekStart,
        summaries: summaries,
      );

      for (var i = 0; i < 7; i++) {
        final expectedDate = testWeekStart.add(Duration(days: i));
        expect(buckets[i].start, expectedDate);
        expect(buckets[i].end, expectedDate);
      }
    });

    test('should normalize weekStart to start-of-day', () {
      // Use a weekStart with time components
      final weekStartWithTime = DateTime(2025, 10, 6, 14, 30, 45);
      final normalizedWeekStart = AppDateUtils.startOfWeekMonday(
        AppDateUtils.startOfDay(weekStartWithTime),
      );

      final summaries = <DateTime, DailySummary?>{
        for (var i = 0; i < 7; i++)
          normalizedWeekStart.add(Duration(days: i)): null,
      };

      final buckets = buildWeeklySymptomBuckets(
        weekStart: weekStartWithTime,
        summaries: summaries,
      );

      expect(buckets.length, 7);
      // All buckets should have normalized dates (00:00:00)
      for (final bucket in buckets) {
        expect(bucket.start.hour, 0);
        expect(bucket.start.minute, 0);
        expect(bucket.start.second, 0);
      }
    });
  });
}
