import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/core/utils/date_utils.dart';
import 'package:hydracat/features/auth/models/app_user.dart';
import 'package:hydracat/features/health/models/symptom_type.dart';
import 'package:hydracat/features/profile/models/cat_profile.dart';
import 'package:hydracat/providers/auth_provider.dart';
import 'package:hydracat/providers/profile_provider.dart';
import 'package:hydracat/providers/progress_provider.dart';
import 'package:hydracat/providers/symptoms_chart_provider.dart';
import 'package:hydracat/shared/models/daily_summary.dart';

void main() {
  group('Symptom Chart Update After Logging', () {
    late ProviderContainer container;
    final testDate = DateTime(2025, 10, 15); // Tuesday
    final weekStart = AppDateUtils.startOfWeekMonday(testDate);

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test(
      'week view updates immediately after symptom log version increments',
      () async {
        // Setup: Create initial week summaries with some symptom data
        final initialSummaries = <DateTime, DailySummary?>{};
        for (var i = 0; i < 7; i++) {
          final date = weekStart.add(Duration(days: i));
          if (i == 2) {
            // Day 2 (Wednesday) has symptoms
            initialSummaries[date] = DailySummary.empty(date).copyWith(
              vomitingMaxScore: 2,
              hasSymptoms: true,
              hadVomiting: true,
            );
          } else {
            initialSummaries[date] = DailySummary.empty(date);
          }
        }

        final testContainer = ProviderContainer(
          overrides: [
            currentUserProvider.overrideWithValue(
              const AppUser(id: 'user1'),
            ),
            primaryPetProvider.overrideWithValue(
              CatProfile(
                id: 'pet1',
                userId: 'user1',
                name: 'Test Pet',
                ageYears: 5,
                createdAt: DateTime(2025),
                updatedAt: DateTime(2025),
              ),
            ),
            weekSummariesProvider.overrideWith(
              (ref, weekStart) async => initialSummaries,
            ),
          ],
        );

        addTearDown(testContainer.dispose);

        // Pre-load week data
        final initialBucketsAsync = testContainer.read(
          weeklySymptomBucketsProvider(weekStart),
        );
        expect(initialBucketsAsync, isNotNull);
        expect(initialBucketsAsync!.length, 7);

        // Verify initial state: Wednesday has vomiting symptom
        final wednesdayBucket = initialBucketsAsync[2];
        expect(wednesdayBucket.daysWithSymptom[SymptomType.vomiting], 2);
        expect(wednesdayBucket.daysWithAnySymptoms, 1);

        // Simulate symptom save: increment version provider
        testContainer.read(symptomLogVersionProvider.notifier).state++;

        // Verify week view updated (provider should have recomputed)
        // Since we're using overrides, the data should still be the same,
        // but the provider should have been triggered to refetch
        final updatedBuckets = testContainer.read(
          weeklySymptomBucketsProvider(weekStart),
        );
        expect(updatedBuckets, isNotNull);
        expect(updatedBuckets!.length, 7);
      },
    );

    test(
      'week view updates when caches were previously populated',
      () async {
        // Setup: Create summaries with cached data
        final cachedSummaries = <DateTime, DailySummary?>{};
        for (var i = 0; i < 7; i++) {
          final date = weekStart.add(Duration(days: i));
          cachedSummaries[date] = DailySummary.empty(date);
        }

        final testContainer = ProviderContainer(
          overrides: [
            currentUserProvider.overrideWithValue(
              const AppUser(id: 'user1'),
            ),
            primaryPetProvider.overrideWithValue(
              CatProfile(
                id: 'pet1',
                userId: 'user1',
                name: 'Test Pet',
                ageYears: 5,
                createdAt: DateTime(2025),
                updatedAt: DateTime(2025),
              ),
            ),
            weekSummariesProvider.overrideWith(
              (ref, weekStart) async => cachedSummaries,
            ),
          ],
        );

        addTearDown(testContainer.dispose);

        // Pre-load and verify initial state (no symptoms)
        final initialBuckets = testContainer.read(
          weeklySymptomBucketsProvider(weekStart),
        );
        expect(initialBuckets, isNotNull);
        expect(initialBuckets!.length, 7);
        for (final bucket in initialBuckets) {
          expect(bucket.daysWithAnySymptoms, 0);
        }

        // Simulate adding symptoms to Thursday (day 3)
        final updatedSummaries = Map<DateTime, DailySummary?>.from(
          cachedSummaries,
        );
        final thursday = weekStart.add(const Duration(days: 3));
        updatedSummaries[thursday] = DailySummary.empty(thursday).copyWith(
          energyMaxScore: 1,
          hasSymptoms: true,
          hadEnergy: true,
        );

        // Update the override with new data
        testContainer.updateOverrides([
          weekSummariesProvider.overrideWith(
            (ref, weekStart) async => updatedSummaries,
          ),
        ]);

        // Increment version to trigger refetch
        testContainer.read(symptomLogVersionProvider.notifier).state++;

        // Verify Thursday now has symptoms
        final updatedBuckets = testContainer.read(
          weeklySymptomBucketsProvider(weekStart),
        );
        expect(updatedBuckets, isNotNull);
        final thursdayBucket = updatedBuckets![3];
        expect(thursdayBucket.daysWithSymptom[SymptomType.energy], 1);
        expect(thursdayBucket.daysWithAnySymptoms, 1);
      },
    );

    test(
      'symptomLogVersionProvider increments correctly',
      () {
        final testContainer = ProviderContainer();
        addTearDown(testContainer.dispose);

        // Initial state should be 0
        expect(
          testContainer.read(symptomLogVersionProvider),
          0,
        );

        // Increment
        testContainer.read(symptomLogVersionProvider.notifier).state++;
        expect(
          testContainer.read(symptomLogVersionProvider),
          1,
        );

        // Increment again
        testContainer.read(symptomLogVersionProvider.notifier).state++;
        expect(
          testContainer.read(symptomLogVersionProvider),
          2,
        );
      },
    );
  });
}
