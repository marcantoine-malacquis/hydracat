import 'package:flutter/foundation.dart';
import 'package:hydracat/features/health/models/weight_data_point.dart';
import 'package:hydracat/features/health/models/weight_granularity.dart';

/// In-memory cache for weight graph data
///
/// Reduces Firebase reads by caching graph data per period.
/// Cache is invalidated when:
/// - User logs new weight
/// - User edits existing weight
/// - User deletes weight entry
/// - Cache expires (30 minutes)
class WeightCacheService {
  WeightCacheService._();

  static final Map<String, _CachedPeriodData> _caches = {};
  static const _cacheDuration = Duration(minutes: 30);

  /// Generates cache key for period-specific caching
  static String _getCacheKey({
    required String userId,
    required String petId,
    required WeightGranularity granularity,
    required DateTime periodStart,
  }) {
    return '$userId|$petId|${granularity.name}|'
        '${periodStart.toIso8601String()}';
  }

  /// Gets cached graph data or returns null if cache miss
  ///
  /// Cache is valid if:
  /// - Cache exists for this specific period
  /// - Cache is less than 30 minutes old
  static List<WeightDataPoint>? getCachedGraphData({
    required String userId,
    required String petId,
    required WeightGranularity granularity,
    required DateTime periodStart,
  }) {
    final key = _getCacheKey(
      userId: userId,
      petId: petId,
      granularity: granularity,
      periodStart: periodStart,
    );

    final cached = _caches[key];
    if (cached == null) {
      if (kDebugMode) {
        debugPrint('[WeightCache] Cache miss - no cache for period');
      }
      return null;
    }

    // Check if cache is still fresh
    final age = DateTime.now().difference(cached.timestamp);
    if (age >= _cacheDuration) {
      if (kDebugMode) {
        debugPrint(
          '[WeightCache] Cache miss - expired (age: ${age.inMinutes}m)',
        );
      }
      _caches.remove(key);
      return null;
    }

    if (kDebugMode) {
      debugPrint(
        '[WeightCache] Cache hit - age: ${age.inMinutes}m, '
        'period: ${granularity.label}',
      );
    }
    return cached.dataPoints;
  }

  /// Stores graph data in cache for specific period
  static void setCachedGraphData({
    required String userId,
    required String petId,
    required WeightGranularity granularity,
    required DateTime periodStart,
    required List<WeightDataPoint> dataPoints,
  }) {
    final key = _getCacheKey(
      userId: userId,
      petId: petId,
      granularity: granularity,
      periodStart: periodStart,
    );

    _caches[key] = _CachedPeriodData(
      dataPoints: dataPoints,
      timestamp: DateTime.now(),
    );

    if (kDebugMode) {
      debugPrint(
        '[WeightCache] Cached ${dataPoints.length} data points '
        'for ${granularity.label}',
      );
    }
  }

  /// Invalidates all cached data
  ///
  /// Call this after:
  /// - Adding new weight
  /// - Updating existing weight
  /// - Deleting weight entry
  static void invalidateCache() {
    if (_caches.isNotEmpty) {
      if (kDebugMode) {
        debugPrint(
          '[WeightCache] Cache invalidated (${_caches.length} periods)',
        );
      }
      _caches.clear();
    }
  }
}

/// Internal cache container for period data
class _CachedPeriodData {
  const _CachedPeriodData({
    required this.dataPoints,
    required this.timestamp,
  });

  final List<WeightDataPoint> dataPoints;
  final DateTime timestamp;
}
