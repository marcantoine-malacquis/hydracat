import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/core/utils/date_utils.dart';
import 'package:hydracat/features/logging/models/daily_summary_cache.dart';
import 'package:hydracat/features/logging/services/summary_cache_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SummaryCacheService', () {
    late SummaryCacheService cacheService;
    late SharedPreferences prefs;

    const testUserId = 'user123';
    const testPetId = 'pet456';

    setUp(() async {
      // Initialize SharedPreferences with empty data
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      cacheService = SummaryCacheService(prefs);
    });

    group('getTodaySummary', () {
      test('returns cached data if valid for today', () async {
        // Arrange: Store today's cache
        final today = AppDateUtils.formatDateForSummary(DateTime.now());
        final cache = DailySummaryCache.empty(today);
        final cacheKey = 'daily_summary_${testUserId}_${testPetId}_$today';
        await prefs.setString(cacheKey, cache.toJson().toString());

        // Note: This test will fail because we're storing malformed JSON
        // We need to properly encode the JSON
        await prefs.setString(
          cacheKey,
          '{"date":"$today","medicationSessionCount":0,"fluidSessionCount":0,'
          '"medicationNames":[],"totalMedicationDosesGiven":0.0,'
          '"totalFluidVolumeGiven":0.0}',
        );

        // Act
        final result = await cacheService.getTodaySummary(
          testUserId,
          testPetId,
        );

        // Assert
        expect(result, isNotNull);
        expect(result?.date, today);
        expect(result?.medicationSessionCount, 0);
        expect(result?.fluidSessionCount, 0);
      });

      test('returns null if cache does not exist', () async {
        // Arrange: No cache stored

        // Act
        final result = await cacheService.getTodaySummary(
          testUserId,
          testPetId,
        );

        // Assert
        expect(result, isNull);
      });

      test('returns null and removes cache if expired', () async {
        // Arrange: Store yesterday's cache
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        final yesterdayStr = AppDateUtils.formatDateForSummary(yesterday);
        final cacheKey = 'daily_summary_${testUserId}_${testPetId}_'
            '${AppDateUtils.formatDateForSummary(DateTime.now())}';

        await prefs.setString(
          cacheKey,
          '{"date":"$yesterdayStr","medicationSessionCount":1,'
          '"fluidSessionCount":1,"medicationNames":["Amlodipine"],'
          '"totalMedicationDosesGiven":2.5,"totalFluidVolumeGiven":100.0}',
        );

        // Act
        final result = await cacheService.getTodaySummary(
          testUserId,
          testPetId,
        );

        // Assert
        expect(result, isNull);
        expect(prefs.getString(cacheKey), isNull); // Cache should be removed
      });

      test('handles malformed JSON gracefully', () async {
        // Arrange: Store invalid JSON
        final today = AppDateUtils.formatDateForSummary(DateTime.now());
        final cacheKey = 'daily_summary_${testUserId}_${testPetId}_$today';
        await prefs.setString(cacheKey, 'invalid json');

        // Act
        final result = await cacheService.getTodaySummary(
          testUserId,
          testPetId,
        );

        // Assert
        expect(result, isNull); // Should fail silently
      });
    });

    group('updateCacheWithMedicationSession', () {
      test('creates new cache if none exists', () async {
        // Arrange: No existing cache
        const medicationName = 'Amlodipine';
        const dosageGiven = 2.5;

        // Act
        await cacheService.updateCacheWithMedicationSession(
          userId: testUserId,
          petId: testPetId,
          medicationName: medicationName,
          dosageGiven: dosageGiven,
        );

        // Assert: Cache should be created
        final result = await cacheService.getTodaySummary(
          testUserId,
          testPetId,
        );
        expect(result, isNotNull);
        expect(result?.medicationSessionCount, 1);
        expect(result?.medicationNames, contains(medicationName));
        expect(result?.totalMedicationDosesGiven, dosageGiven);
      });

      test('increments counts when updating existing cache', () async {
        // Arrange: Existing cache with 1 medication
        const firstMed = 'Amlodipine';
        const firstDosage = 2.5;
        await cacheService.updateCacheWithMedicationSession(
          userId: testUserId,
          petId: testPetId,
          medicationName: firstMed,
          dosageGiven: firstDosage,
        );

        // Act: Add second medication
        const secondMed = 'Benazepril';
        const secondDosage = 5.0;
        await cacheService.updateCacheWithMedicationSession(
          userId: testUserId,
          petId: testPetId,
          medicationName: secondMed,
          dosageGiven: secondDosage,
        );

        // Assert: Cache should have 2 medications
        final result = await cacheService.getTodaySummary(
          testUserId,
          testPetId,
        );
        expect(result?.medicationSessionCount, 2);
        expect(result?.medicationNames, containsAll([firstMed, secondMed]));
        expect(
          result?.totalMedicationDosesGiven,
          firstDosage + secondDosage,
        );
      });

      test('does not duplicate medication names', () async {
        // Arrange & Act: Log same medication twice
        const medicationName = 'Amlodipine';
        await cacheService.updateCacheWithMedicationSession(
          userId: testUserId,
          petId: testPetId,
          medicationName: medicationName,
          dosageGiven: 2.5,
        );
        await cacheService.updateCacheWithMedicationSession(
          userId: testUserId,
          petId: testPetId,
          medicationName: medicationName,
          dosageGiven: 2.5,
        );

        // Assert: Medication name should appear only once
        final result = await cacheService.getTodaySummary(
          testUserId,
          testPetId,
        );
        expect(result?.medicationSessionCount, 2);
        expect(
          result?.medicationNames
              .where((name) => name == medicationName)
              .length,
          1,
        ); // Only once in list
      });
    });

    group('updateCacheWithFluidSession', () {
      test('creates new cache if none exists', () async {
        // Arrange: No existing cache
        const volumeGiven = 100.0;

        // Act
        await cacheService.updateCacheWithFluidSession(
          userId: testUserId,
          petId: testPetId,
          volumeGiven: volumeGiven,
        );

        // Assert: Cache should be created
        final result = await cacheService.getTodaySummary(
          testUserId,
          testPetId,
        );
        expect(result, isNotNull);
        expect(result?.fluidSessionCount, 1);
        expect(result?.totalFluidVolumeGiven, volumeGiven);
      });

      test('increments counts when updating existing cache', () async {
        // Arrange: Existing cache with 1 fluid session
        const firstVolume = 80.0;
        await cacheService.updateCacheWithFluidSession(
          userId: testUserId,
          petId: testPetId,
          volumeGiven: firstVolume,
        );

        // Act: Add second fluid session
        const secondVolume = 20.0;
        await cacheService.updateCacheWithFluidSession(
          userId: testUserId,
          petId: testPetId,
          volumeGiven: secondVolume,
        );

        // Assert: Cache should have 2 sessions
        final result = await cacheService.getTodaySummary(
          testUserId,
          testPetId,
        );
        expect(result?.fluidSessionCount, 2);
        expect(result?.totalFluidVolumeGiven, firstVolume + secondVolume);
      });
    });

    group('clearExpiredCaches', () {
      test("removes old caches but keeps today's cache", () async {
        // Arrange: Create caches for today, yesterday, last week
        final today = DateTime.now();
        final yesterday = today.subtract(const Duration(days: 1));
        final lastWeek = today.subtract(const Duration(days: 7));

        final todayStr = AppDateUtils.formatDateForSummary(today);
        final yesterdayStr = AppDateUtils.formatDateForSummary(yesterday);
        final lastWeekStr = AppDateUtils.formatDateForSummary(lastWeek);

        await prefs.setString(
          'daily_summary_${testUserId}_${testPetId}_$todayStr',
          '{"date":"$todayStr","medicationSessionCount":1,'
          '"fluidSessionCount":0,"medicationNames":["Amlodipine"],'
          '"totalMedicationDosesGiven":2.5,"totalFluidVolumeGiven":0.0}',
        );

        await prefs.setString(
          'daily_summary_${testUserId}_${testPetId}_$yesterdayStr',
          '{"date":"$yesterdayStr","medicationSessionCount":1,'
          '"fluidSessionCount":0,"medicationNames":["Amlodipine"],'
          '"totalMedicationDosesGiven":2.5,"totalFluidVolumeGiven":0.0}',
        );

        await prefs.setString(
          'daily_summary_${testUserId}_${testPetId}_$lastWeekStr',
          '{"date":"$lastWeekStr","medicationSessionCount":1,'
          '"fluidSessionCount":0,"medicationNames":["Amlodipine"],'
          '"totalMedicationDosesGiven":2.5,"totalFluidVolumeGiven":0.0}',
        );

        // Act
        await cacheService.clearExpiredCaches();

        // Assert: Only today's cache should remain
        expect(
          prefs.getString('daily_summary_${testUserId}_${testPetId}_$todayStr'),
          isNotNull,
        );
        expect(
          prefs.getString(
            'daily_summary_${testUserId}_${testPetId}_$yesterdayStr',
          ),
          isNull,
        );
        expect(
          prefs.getString(
            'daily_summary_${testUserId}_${testPetId}_$lastWeekStr',
          ),
          isNull,
        );
      });

      test('does not remove non-cache keys', () async {
        // Arrange: Store some other preferences
        await prefs.setString('user_preference_theme', 'dark');
        await prefs.setString('user_preference_language', 'en');

        // Act
        await cacheService.clearExpiredCaches();

        // Assert: Other preferences should remain
        expect(prefs.getString('user_preference_theme'), 'dark');
        expect(prefs.getString('user_preference_language'), 'en');
      });
    });

    group('clearPetCache', () {
      test("removes specific pet's cache", () async {
        // Arrange: Create cache for test pet
        final today = AppDateUtils.formatDateForSummary(DateTime.now());
        final cacheKey = 'daily_summary_${testUserId}_${testPetId}_$today';
        await prefs.setString(
          cacheKey,
          '{"date":"$today","medicationSessionCount":1,'
          '"fluidSessionCount":0,"medicationNames":["Amlodipine"],'
          '"totalMedicationDosesGiven":2.5,"totalFluidVolumeGiven":0.0}',
        );

        // Act
        await cacheService.clearPetCache(testUserId, testPetId);

        // Assert: Cache should be removed
        expect(prefs.getString(cacheKey), isNull);
      });

      test("does not affect other pets' caches", () async {
        // Arrange: Create caches for two pets
        final today = AppDateUtils.formatDateForSummary(DateTime.now());
        const pet1Id = 'pet1';
        const pet2Id = 'pet2';

        final cache1Key = 'daily_summary_${testUserId}_${pet1Id}_$today';
        final cache2Key = 'daily_summary_${testUserId}_${pet2Id}_$today';

        await prefs.setString(
          cache1Key,
          '{"date":"$today","medicationSessionCount":1,'
          '"fluidSessionCount":0,"medicationNames":["Amlodipine"],'
          '"totalMedicationDosesGiven":2.5,"totalFluidVolumeGiven":0.0}',
        );

        await prefs.setString(
          cache2Key,
          '{"date":"$today","medicationSessionCount":1,'
          '"fluidSessionCount":0,"medicationNames":["Benazepril"],'
          '"totalMedicationDosesGiven":5.0,"totalFluidVolumeGiven":0.0}',
        );

        // Act: Clear pet1's cache
        await cacheService.clearPetCache(testUserId, pet1Id);

        // Assert: pet1 cache removed, pet2 cache remains
        expect(prefs.getString(cache1Key), isNull);
        expect(prefs.getString(cache2Key), isNotNull);
      });
    });
  });
}
