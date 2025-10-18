/// Service for managing app-wide cache clearing operations
library;

import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/providers/logging_provider.dart';
import 'package:hydracat/providers/progress_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for clearing local cache data from SharedPreferences
///
/// Provides methods to:
/// - Clear daily summary cache from SharedPreferences
/// - Invalidate Riverpod providers to trigger data refresh from Firestore
///
/// Usage:
/// ```dart
/// final service = CacheManagementService(prefs, analytics);
///
/// // Clear daily summaries
/// final count = await service.clearDailySummaries(userId, petId);
///
/// // Invalidate providers
/// await service.invalidateProviders(ref);
/// ```
class CacheManagementService {
  /// Creates a cache management service
  const CacheManagementService(
    this._prefs, [
    this._analytics,
  ]);

  /// SharedPreferences instance for cache storage
  final SharedPreferences _prefs;

  /// Optional Firebase Analytics for tracking cache operations
  final FirebaseAnalytics? _analytics;

  // ============================================
  // Public API
  // ============================================

  /// Clear daily summaries from SharedPreferences
  ///
  /// Returns the number of items cleared.
  /// This is a simplified version that only clears daily summaries,
  /// which are the only items actually cached in SharedPreferences.
  Future<int> clearDailySummaries(String userId, String petId) async {
    try {
      return await _clearDailySummaryCache(userId, petId);
    } on Exception catch (e) {
      if (kDebugMode) {
        debugPrint('[CacheManagementService] Error clearing cache: $e');
      }
      rethrow;
    }
  }

  /// Invalidate Riverpod providers after cache clearing
  ///
  /// This triggers automatic data refresh from Firestore for all affected UI.
  /// Invalidation order matters: most fundamental providers first.
  Future<void> invalidateProviders(WidgetRef ref) async {
    if (kDebugMode) {
      debugPrint('[CacheManagementService] Invalidating providers');
    }

    // Invalidate the daily cache provider as it's fundamental
    ref
      ..invalidate(dailyCacheProvider)
      // Invalidate summary-related providers
      ..invalidate(weekSummariesProvider)
      ..invalidate(weekStatusProvider);

    // Note: Dashboard providers don't need explicit invalidation
    // They automatically update when dailyCacheProvider is invalidated

    unawaited(
      _analytics?.logEvent(
        name: 'cache_cleared',
        parameters: {'method': 'simple'},
      ),
    );
  }

  // ============================================
  // Private Methods
  // ============================================

  /// Clear daily summary cache
  Future<int> _clearDailySummaryCache(String userId, String petId) async {
    final keys = _prefs.getKeys();
    var count = 0;

    // Find all keys matching pattern: daily_summary_{userId}_{petId}_*
    final pattern = 'daily_summary_${userId}_$petId';
    final keysToRemove = keys.where((key) => key.startsWith(pattern)).toList();

    for (final key in keysToRemove) {
      final removed = await _prefs.remove(key);
      if (removed) count++;
    }

    if (kDebugMode) {
      debugPrint(
        '[CacheManagementService] Cleared $count daily summary cache entries',
      );
    }

    return count;
  }
}
