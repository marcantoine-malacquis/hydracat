/// Service for managing local SharedPreferences cache of daily summaries
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hydracat/core/utils/date_utils.dart';
import 'package:hydracat/features/logging/models/daily_summary_cache.dart';
import 'package:hydracat/features/logging/models/fluid_session.dart';
import 'package:hydracat/providers/analytics_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for local cache management of today's treatment summary
///
/// Manages SharedPreferences-based caching for daily summaries to avoid
/// repeated Firestore reads for duplicate detection and status checks.
///
/// Cache features:
/// - Date validation: Cache expires at midnight (new day transition)
/// - Multi-pet support: Separate cache per user/pet combination
/// - Incremental updates: Add session data without full replacement
/// - Startup cleanup: Remove expired caches on app launch/resume
///
/// Usage:
/// ```dart
/// final cacheService = SummaryCacheService(prefs);
///
/// // Read cache (null if expired or doesn't exist)
/// final cache = await cacheService.getTodaySummary(userId, petId);
///
/// // Update after logging medication
/// await cacheService.updateCacheWithMedicationSession(
///   userId: userId,
///   petId: petId,
///   medicationName: 'Amlodipine',
///   dosageGiven: 2.5,
/// );
///
/// // Cleanup on app startup/resume
/// await cacheService.clearExpiredCaches();
/// ```
class SummaryCacheService {
  /// Creates a [SummaryCacheService] instance
  ///
  /// [_analyticsService] is optional for testing purposes. In production,
  /// it should be provided for cache health monitoring.
  const SummaryCacheService(this._prefs, [this._analyticsService]);

  /// SharedPreferences instance for cache storage
  final SharedPreferences _prefs;

  /// Analytics service for tracking cache health (optional for testing)
  final AnalyticsService? _analyticsService;

  /// Cache key prefix for all daily summary caches
  static const String _cacheKeyPrefix = 'daily_summary';

  /// Get today's cached summary (null if expired or doesn't exist)
  ///
  /// Returns cached [DailySummaryCache] if:
  /// - Cache exists in SharedPreferences
  /// - Cache date matches today's date
  ///
  /// Returns null and removes cache if:
  /// - Cache doesn't exist
  /// - Cache date ≠ today (expired)
  ///
  /// Cost: 0 Firestore reads when cache is valid
  Future<DailySummaryCache?> getTodaySummary(
    String userId,
    String petId,
  ) async {
    try {
      final cacheKey = _getCacheKey(userId, petId);
      final cacheJson = _prefs.getString(cacheKey);

      if (cacheJson == null) {
        if (kDebugMode) {
          debugPrint('[SummaryCacheService] No cache found for $cacheKey');
        }
        return null;
      }

      // Parse cached JSON (synchronous - profiled at <100μs for ~300 bytes)
      // No isolate needed: sync is faster than isolate overhead
      final cacheData = jsonDecode(cacheJson) as Map<String, dynamic>;
      final cache = DailySummaryCache.fromJson(cacheData);

      // Validate cache date
      final today = AppDateUtils.formatDateForSummary(DateTime.now());
      if (!cache.isValidFor(today)) {
        if (kDebugMode) {
          debugPrint(
            '[SummaryCacheService] Cache expired: ${cache.date} ≠ $today',
          );
        }
        // Remove expired cache
        await _prefs.remove(cacheKey);
        return null;
      }

      if (kDebugMode) {
        debugPrint('[SummaryCacheService] Cache hit for $cacheKey');
      }
      return cache;
    } on Exception catch (e) {
      // Silent fallback - log error, return null
      if (kDebugMode) {
        debugPrint('[SummaryCacheService] Error reading cache: $e');
      }

      // Track analytics
      unawaited(
        _analyticsService?.trackError(
          errorType: AnalyticsErrorTypes.cacheReadFailure,
          errorContext: 'getTodaySummary: $e',
        ),
      );

      return null;
    }
  }

  /// Update cache with new medication session data
  ///
  /// Incrementally updates the cache by:
  /// 1. Reading existing cache (or creating empty if doesn't exist)
  /// 2. Adding session data via `cache.copyWithSession()`
  /// 3. Writing updated cache to SharedPreferences
  ///
  /// Fails silently if cache write fails (Firestore is source of truth).
  Future<void> updateCacheWithMedicationSession({
    required String userId,
    required String petId,
    required String medicationName,
    required double dosageGiven,
    required bool completed,
    DateTime? dateTime,
  }) async {
    try {
      final today = AppDateUtils.formatDateForSummary(DateTime.now());
      final cacheKey = _getCacheKey(userId, petId);

      // Read existing cache or create empty
      final existingCache = await getTodaySummary(userId, petId);
      final cache = existingCache ?? DailySummaryCache.empty(today);

      // Add medication session
      final updatedCache = cache.copyWithSession(
        medicationName: medicationName,
        dosageGiven: dosageGiven,
      );

      // Update recent times (bounded to last 8 times per medication)
      final times = Map<String, List<String>>.from(cache.medicationRecentTimes);
      final entries = List<String>.from(times[medicationName] ?? const []);
      final iso = (dateTime ?? DateTime.now()).toIso8601String();
      entries.add(iso);
      // Keep latest 8 only
      final trimmed = entries.length <= 8
          ? entries
          : entries.sublist(entries.length - 8, entries.length);
      times[medicationName] = trimmed;

      // Update completed times (only if session was completed)
      final completedTimes = Map<String, List<String>>.from(
        cache.medicationCompletedTimes,
      );
      if (completed) {
        final completedEntries = List<String>.from(
          completedTimes[medicationName] ?? const [],
        )..add(iso);
        // Keep latest 8 only
        final trimmedCompleted = completedEntries.length <= 8
            ? completedEntries
            : completedEntries.sublist(
                completedEntries.length - 8,
                completedEntries.length,
              );
        completedTimes[medicationName] = trimmedCompleted;
      }

      final updatedWithTimes = updatedCache.copyWith(
        medicationRecentTimes: times,
        medicationCompletedTimes: completedTimes,
      );

      // Write to SharedPreferences
      final cacheJson = jsonEncode(updatedWithTimes.toJson());
      await _prefs.setString(cacheKey, cacheJson);

      if (kDebugMode) {
        debugPrint(
          '[SummaryCacheService] Updated cache with medication: '
          '$medicationName ($dosageGiven)',
        );
      }
    } on Exception catch (e) {
      // Silent fallback - log error, continue
      if (kDebugMode) {
        debugPrint('[SummaryCacheService] Error updating cache: $e');
      }

      // Track analytics
      unawaited(
        _analyticsService?.trackError(
          errorType: AnalyticsErrorTypes.cacheUpdateFailure,
          errorContext: 'updateMedicationSession: $e',
        ),
      );
    }
  }

  /// Get recent log times for a medication (today only)
  Future<List<DateTime>> getRecentTimesForMedication(
    String userId,
    String petId,
    String medicationName,
  ) async {
    final cache = await getTodaySummary(userId, petId);
    if (cache == null) return const [];
    final list = cache.medicationRecentTimes[medicationName];
    if (list == null || list.isEmpty) return const [];
    return list.map(DateTime.parse).toList()..sort();
  }

  /// Quick decision helper: is the candidate time within the duplicate window
  /// of any recent cached time for the medication?
  Future<bool> isLikelyDuplicate({
    required String userId,
    required String petId,
    required String medicationName,
    required DateTime candidateTime,
    Duration window = const Duration(minutes: 15),
  }) async {
    final times = await getRecentTimesForMedication(
      userId,
      petId,
      medicationName,
    );
    for (final t in times) {
      if (t.difference(candidateTime).abs() <= window) {
        return true;
      }
    }
    return false;
  }

  /// Update cache with new fluid session data
  ///
  /// Incrementally updates the cache by:
  /// 1. Reading existing cache (or creating empty if doesn't exist)
  /// 2. Adding session data via `cache.copyWithSession()`
  /// 3. Writing updated cache to SharedPreferences
  ///
  /// Fails silently if cache write fails (Firestore is source of truth).
  Future<void> updateCacheWithFluidSession({
    required String userId,
    required String petId,
    required double volumeGiven,
  }) async {
    try {
      final today = AppDateUtils.formatDateForSummary(DateTime.now());
      final cacheKey = _getCacheKey(userId, petId);

      // Read existing cache or create empty
      final existingCache = await getTodaySummary(userId, petId);
      final cache = existingCache ?? DailySummaryCache.empty(today);

      // Add fluid session
      final updatedCache = cache.copyWithSession(
        volumeGiven: volumeGiven,
      );

      // Write to SharedPreferences
      final cacheJson = jsonEncode(updatedCache.toJson());
      await _prefs.setString(cacheKey, cacheJson);

      if (kDebugMode) {
        debugPrint(
          '[SummaryCacheService] Updated cache with fluid: ${volumeGiven}ml',
        );
      }
    } on Exception catch (e) {
      // Silent fallback - log error, continue
      if (kDebugMode) {
        debugPrint('[SummaryCacheService] Error updating cache: $e');
      }

      // Track analytics
      unawaited(
        _analyticsService?.trackError(
          errorType: AnalyticsErrorTypes.cacheUpdateFailure,
          errorContext: 'updateFluidSession: $e',
        ),
      );
    }
  }

  /// Removes a fluid session from today's cache (if applicable)
  ///
  /// Only adjusts cache when the session date is today to keep historical
  /// caches untouched. Silently no-ops if cache is missing or expired.
  Future<void> removeCachedFluidSession({
    required FluidSession session,
  }) async {
    try {
      final today = AppDateUtils.formatDateForSummary(DateTime.now());
      final sessionDate = AppDateUtils.formatDateForSummary(session.dateTime);

      // Only adjust today's cache
      if (today != sessionDate) {
        return;
      }

      final cacheKey = _getCacheKey(session.userId, session.petId);
      final existingCache = await getTodaySummary(
        session.userId,
        session.petId,
      );
      if (existingCache == null) {
        return;
      }

      final updatedCache = existingCache.copyWith(
        fluidSessionCount: (existingCache.fluidSessionCount - 1).clamp(0, 100),
        totalFluidVolumeGiven:
            (existingCache.totalFluidVolumeGiven - session.volumeGiven).clamp(
              0,
              500000,
            ),
      );

      await _prefs.setString(cacheKey, jsonEncode(updatedCache.toJson()));

      if (kDebugMode) {
        debugPrint(
          '[SummaryCacheService] Removed fluid session from cache: '
          '${session.id} (-${session.volumeGiven}ml)',
        );
      }
    } on Exception catch (e) {
      if (kDebugMode) {
        debugPrint('[SummaryCacheService] Error removing fluid cache: $e');
      }

      unawaited(
        _analyticsService?.trackError(
          errorType: AnalyticsErrorTypes.cacheUpdateFailure,
          errorContext: 'removeCachedFluidSession: $e',
        ),
      );
    }
  }

  /// Update cache after quick-log operation (optimistic update)
  ///
  /// Sets the cache directly from known session data without fetching from
  /// Firestore. This is an optimistic update that assumes the batch write
  /// succeeded and eliminates 1 Firestore read per quick-log operation.
  ///
  /// Use this after quick-log batch writes complete successfully.
  ///
  /// Parameters:
  /// - All sessions counts, names, doses, and volumes from the batch write
  ///
  /// Cost optimization: 0 Firestore reads (vs 1 read with warmCache approach)
  Future<void> updateCacheAfterQuickLog({
    required String userId,
    required String petId,
    required int medicationSessionCount,
    required int fluidSessionCount,
    required List<String> medicationNames,
    required double totalMedicationDoses,
    required double totalFluidVolume,
    required Map<String, List<String>> medicationRecentTimes,
  }) async {
    try {
      final today = AppDateUtils.formatDateForSummary(DateTime.now());
      final cacheKey = _getCacheKey(userId, petId);

      // Create fresh cache from what was just logged
      final cache = DailySummaryCache(
        date: today,
        medicationSessionCount: medicationSessionCount,
        fluidSessionCount: fluidSessionCount,
        medicationNames: medicationNames,
        totalMedicationDosesGiven: totalMedicationDoses,
        totalFluidVolumeGiven: totalFluidVolume,
        medicationRecentTimes: medicationRecentTimes,
      );

      // Write to SharedPreferences
      final cacheJson = jsonEncode(cache.toJson());
      await _prefs.setString(cacheKey, cacheJson);

      if (kDebugMode) {
        debugPrint(
          '[SummaryCacheService] Cache updated optimistically '
          'after quick-log: '
          '$medicationSessionCount med sessions, $fluidSessionCount fluid '
          'sessions',
        );
      }
    } on Exception catch (e) {
      // Silent fallback - log error, continue
      if (kDebugMode) {
        debugPrint(
          '[SummaryCacheService] Error updating cache after quick-log: $e',
        );
      }

      // Track analytics
      unawaited(
        _analyticsService?.trackError(
          errorType: AnalyticsErrorTypes.cacheUpdateFailure,
          errorContext: 'updateCacheAfterQuickLog: $e',
        ),
      );
    }
  }

  /// Clear all caches that are not for today (startup cleanup)
  ///
  /// Removes expired caches from SharedPreferences by:
  /// 1. Getting all keys starting with [_cacheKeyPrefix]
  /// 2. Parsing date suffix from each key
  /// 3. Removing keys where date ≠ today
  ///
  /// Run on:
  /// - App cold start (initialization)
  /// - App resume from background (lifecycle change)
  ///
  /// This prevents stale caches from accumulating when the app stays
  /// open across multiple days.
  Future<void> clearExpiredCaches() async {
    try {
      final today = AppDateUtils.formatDateForSummary(DateTime.now());
      final allKeys = _prefs.getKeys();

      // Filter cache keys
      final cacheKeys = allKeys.where(
        (key) => key.startsWith(_cacheKeyPrefix),
      );

      var removedCount = 0;
      for (final key in cacheKeys) {
        // Extract date from key: 'daily_summary_{userId}_{petId}_{date}'
        final parts = key.split('_');
        if (parts.length >= 4) {
          final date = parts.last; // YYYY-MM-DD

          // Remove if not today
          if (date != today) {
            await _prefs.remove(key);
            removedCount++;
          }
        }
      }

      if (kDebugMode && removedCount > 0) {
        debugPrint(
          '[SummaryCacheService] Cleared $removedCount expired cache(s)',
        );
      }
    } on Exception catch (e) {
      // Silent fallback - log error, continue
      if (kDebugMode) {
        debugPrint('[SummaryCacheService] Error clearing expired caches: $e');
      }

      // Track analytics
      unawaited(
        _analyticsService?.trackError(
          errorType: AnalyticsErrorTypes.cacheCleanupFailure,
          errorContext: '$e',
        ),
      );
    }
  }

  /// Clear specific pet's cache
  ///
  /// Removes the daily summary cache for a specific user/pet combination.
  /// Useful when switching pets or clearing data.
  Future<void> clearPetCache(String userId, String petId) async {
    try {
      final cacheKey = _getCacheKey(userId, petId);
      await _prefs.remove(cacheKey);

      if (kDebugMode) {
        debugPrint('[SummaryCacheService] Cleared cache for $cacheKey');
      }
    } on Exception catch (e) {
      // Silent fallback - log error, continue
      if (kDebugMode) {
        debugPrint('[SummaryCacheService] Error clearing pet cache: $e');
      }
    }
  }

  /// Generate cache key for user/pet combination
  ///
  /// Format: `daily_summary_{userId}_{petId}_{YYYY-MM-DD}`
  ///
  /// Example: `daily_summary_user123_pet456_2025-10-06`
  ///
  /// This ensures:
  /// - Separate cache per user (multi-user devices)
  /// - Separate cache per pet (multi-pet users)
  /// - Date-based expiration (midnight invalidation)
  String _getCacheKey(String userId, String petId) {
    final today = AppDateUtils.formatDateForSummary(DateTime.now());
    return '${_cacheKeyPrefix}_${userId}_${petId}_$today';
  }
}

/// Performance Note: JSON operations are synchronous (no isolates)
///
/// Profiling showed that for small payloads (~300 bytes):
/// - Synchronous JSON: 8-81μs (well under 16ms frame budget)
/// - compute() overhead: 600-15,000μs (20-550x slower)
///
/// Isolates are only beneficial for JSON >1MB. See CLAUDE.md for guidelines.
