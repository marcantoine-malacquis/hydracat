/// Service for managing local SharedPreferences cache of daily summaries
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hydracat/core/utils/date_utils.dart';
import 'package:hydracat/features/logging/models/daily_summary_cache.dart';
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
  const SummaryCacheService(this._prefs);

  /// SharedPreferences instance for cache storage
  final SharedPreferences _prefs;

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

      // Parse cached JSON
      final cacheData = Map<String, dynamic>.from(
        // Ignore: Using compute for JSON parsing to avoid blocking main thread
        // ignore: inference_failure_on_untyped_parameter, avoid_dynamic_calls
        (await compute(_parseJson, cacheJson)) as Map,
      );
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

      // Write to SharedPreferences
      final cacheJson = await compute(_encodeJson, updatedCache.toJson());
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
    }
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
      final cacheJson = await compute(_encodeJson, updatedCache.toJson());
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

/// Isolate function for JSON parsing
///
/// Runs in background isolate to avoid blocking main thread.
Map<String, dynamic> _parseJson(String jsonString) {
  final json = jsonDecode(jsonString) as Map<String, dynamic>;
  return json;
}

/// Isolate function for JSON encoding
///
/// Runs in background isolate to avoid blocking main thread.
String _encodeJson(Map<String, dynamic> json) {
  return jsonEncode(json);
}
