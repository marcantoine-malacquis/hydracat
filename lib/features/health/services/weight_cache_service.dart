import 'package:flutter/foundation.dart';
import 'package:hydracat/features/health/models/weight_data_point.dart';

/// In-memory cache for weight graph data
///
/// Reduces Firebase reads by caching graph data for 1 hour.
/// Cache is invalidated when:
/// - User logs new weight
/// - User edits existing weight
/// - User deletes weight entry
/// - Cache expires (1 hour)
class WeightCacheService {
  WeightCacheService._();

  static WeightGraphCache? _graphCache;
  static DateTime? _graphCacheTimestamp;
  static const _cacheDuration = Duration(hours: 1);

  /// Gets cached graph data or returns null if cache miss
  ///
  /// Cache is valid if:
  /// - Cache exists
  /// - Cache is for same user and pet
  /// - Cache is less than 1 hour old
  static List<WeightDataPoint>? getCachedGraphData({
    required String userId,
    required String petId,
  }) {
    // Check if cache exists and is valid
    if (_graphCache == null || _graphCacheTimestamp == null) {
      if (kDebugMode) {
        debugPrint('[WeightCache] Cache miss - no cache exists');
      }
      return null;
    }

    // Check if cache is for same user/pet
    if (_graphCache!.userId != userId || _graphCache!.petId != petId) {
      if (kDebugMode) {
        debugPrint('[WeightCache] Cache miss - different user/pet');
      }
      return null;
    }

    // Check if cache is still fresh
    final age = DateTime.now().difference(_graphCacheTimestamp!);
    if (age >= _cacheDuration) {
      if (kDebugMode) {
        debugPrint(
          '[WeightCache] Cache miss - expired (age: ${age.inMinutes}m)',
        );
      }
      return null;
    }

    if (kDebugMode) {
      debugPrint('[WeightCache] Cache hit - age: ${age.inMinutes}m');
    }
    return _graphCache!.dataPoints;
  }

  /// Stores graph data in cache
  static void setCachedGraphData({
    required String userId,
    required String petId,
    required List<WeightDataPoint> dataPoints,
  }) {
    _graphCache = WeightGraphCache(
      userId: userId,
      petId: petId,
      dataPoints: dataPoints,
    );
    _graphCacheTimestamp = DateTime.now();

    if (kDebugMode) {
      debugPrint('[WeightCache] Cached ${dataPoints.length} data points');
    }
  }

  /// Invalidates the cache
  ///
  /// Call this after:
  /// - Adding new weight
  /// - Updating existing weight
  /// - Deleting weight entry
  static void invalidateCache() {
    if (_graphCache != null) {
      if (kDebugMode) {
        debugPrint('[WeightCache] Cache invalidated');
      }
    }
    _graphCache = null;
    _graphCacheTimestamp = null;
  }

  /// Checks if cache exists and is valid
  static bool hasCachedData({
    required String userId,
    required String petId,
  }) {
    return getCachedGraphData(userId: userId, petId: petId) != null;
  }

  /// Gets cache age in minutes (returns null if no cache)
  static int? getCacheAgeMinutes() {
    if (_graphCacheTimestamp == null) return null;
    return DateTime.now().difference(_graphCacheTimestamp!).inMinutes;
  }
}

/// Cache container for weight graph data
@immutable
class WeightGraphCache {
  /// Creates a [WeightGraphCache]
  const WeightGraphCache({
    required this.userId,
    required this.petId,
    required this.dataPoints,
  });

  /// User ID this cache belongs to
  final String userId;

  /// Pet ID this cache belongs to
  final String petId;

  /// Cached weight data points
  final List<WeightDataPoint> dataPoints;
}
