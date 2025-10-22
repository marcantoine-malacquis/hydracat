/// Service for reading treatment summaries from Firestore
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hydracat/core/utils/date_utils.dart';
import 'package:hydracat/shared/models/daily_summary.dart';
import 'package:hydracat/shared/models/monthly_summary.dart';
import 'package:hydracat/shared/models/weekly_summary.dart';

/// Service for reading treatment summaries with cache-first strategy
///
/// Provides optimized reads for treatment summaries:
/// - Today's summary: Cache-first (0 Firestore reads when cached)
/// - Historical summaries: Direct Firestore reads
/// - Weekly/monthly summaries: Direct Firestore reads for analytics
///
/// Cost optimization:
/// - Cache eliminates duplicate detection reads (~90% savings)
/// - Single read per day for today's summary (cold start only)
/// - Historical reads on-demand (analytics use case)
///
/// Usage:
/// ```dart
/// final summaryService = SummaryService(firestore, cacheService);
///
/// // Get today's summary (cache-first)
/// final today = await summaryService.getTodaySummary(
///   userId: currentUser.id,
///   petId: currentPet.id,
/// );
///
/// // Get specific date summary (direct Firestore)
/// final lastWeek = await summaryService.getDailySummary(
///   userId: currentUser.id,
///   petId: currentPet.id,
///   date: DateTime.now().subtract(Duration(days: 7)),
/// );
///
/// // Get weekly summary for analytics
/// final thisWeek = await summaryService.getWeeklySummary(
///   userId: currentUser.id,
///   petId: currentPet.id,
///   date: DateTime.now(),
/// );
/// ```
class SummaryService {
  /// Creates a [SummaryService] instance
  SummaryService(this._firestore);

  /// Firestore instance
  final FirebaseFirestore _firestore;

  // ============================================
  // In-memory TTL caches for analytics views
  // ============================================

  // Daily/weekly/monthly TTLs (active views only)
  static const Duration _dailyTtl = Duration(minutes: 5);
  static const Duration _weeklyTtl = Duration(minutes: 15);
  static const Duration _monthlyTtl = Duration(minutes: 15);

  final Map<String, (_CacheClock, DailySummary?)> _dailyMemCache = {};
  final Map<String, (_CacheClock, WeeklySummary?)> _weeklyMemCache = {};
  final Map<String, (_CacheClock, MonthlySummary?)> _monthlyMemCache = {};

  bool _isValid(_CacheClock clock, Duration ttl) =>
      DateTime.now().isBefore(clock.cachedAt.add(ttl));

  String _dailyKey(String userId, String petId, DateTime date) =>
      'u:$userId|p:$petId|d:${AppDateUtils.formatDateForSummary(date)}';
  String _weeklyKey(String userId, String petId, DateTime date) =>
      'u:$userId|p:$petId|w:${AppDateUtils.formatWeekForSummary(date)}';
  String _monthlyKey(String userId, String petId, DateTime date) =>
      'u:$userId|p:$petId|m:${AppDateUtils.formatMonthForSummary(date)}';

  // ============================================
  // PUBLIC API - Daily Summary Reads
  // ============================================

  /// Get today's summary (cache-first, Firestore fallback)
  ///
  /// Strategy:
  /// 1. Check cache first (0 reads)
  /// 2. If cache miss, fetch from Firestore (1 read)
  /// 3. Return null if no summary exists
  ///
  /// Returns null if:
  /// - No sessions logged today
  /// - Firestore read fails
  ///
  /// Cost: 0 reads (cache hit) or 1 read (cache miss)
  Future<DailySummary?> getTodaySummary({
    required String userId,
    required String petId,
    bool lightweight = false,
  }) async {
    try {
      // IMPORTANT FIX: Always fetch from Firestore for today to ensure
      // real-time accuracy. The lightweight cache can become stale after
      // logging operations, causing the calendar dot and session counts
      // to display incorrect data.
      // Cost: 1 Firestore read per call, but ensures UI accuracy.
      if (kDebugMode) {
        debugPrint(
          "[SummaryService] Fetching today's summary from Firestore "
          '(lightweight mode disabled for today)',
        );
      }

      final today = DateTime.now();
      final summary = await getDailySummary(
        userId: userId,
        petId: petId,
        date: today,
      );

      if (kDebugMode && summary != null) {
        debugPrint(
          "[SummaryService] Today's summary: "
          'medDoses=${summary.medicationTotalDoses}, '
          'medScheduled=${summary.medicationScheduledDoses}, '
          'fluidSessions=${summary.fluidSessionCount}, '
          'fluidVolume=${summary.fluidTotalVolume}',
        );
      }

      return summary;
    } on Exception catch (e) {
      // Silent fallback - log error, return null
      if (kDebugMode) {
        debugPrint('[SummaryService] Error in getTodaySummary: $e');
      }
      return null;
    }
  }

  /// Get daily summary for specific date (direct Firestore read)
  ///
  /// Returns [DailySummary] if summary exists for the given date.
  /// Returns null if:
  /// - No summary document exists for that date
  /// - Firestore read fails
  ///
  /// Cost: 1 Firestore read
  Future<DailySummary?> getDailySummary({
    required String userId,
    required String petId,
    required DateTime date,
  }) async {
    try {
      // In-memory cache (TTL) for active views
      final key = _dailyKey(userId, petId, date);
      final cached = _dailyMemCache[key];
      if (cached != null && _isValid(cached.$1, _dailyTtl)) {
        return cached.$2;
      }

      final docRef = _getDailySummaryRef(userId, petId, date);
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        if (kDebugMode) {
          final dateStr = AppDateUtils.formatDateForSummary(date);
          debugPrint('[SummaryService] No daily summary for $dateStr');
        }
        return null;
      }

      final data = docSnapshot.data();
      if (data == null) {
        if (kDebugMode) {
          debugPrint('[SummaryService] Daily summary data is null');
        }
        return null;
      }

      final summary = DailySummary.fromJson(data as Map<String, dynamic>);
      _dailyMemCache[key] = (_CacheClock(DateTime.now()), summary);
      return summary;
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[SummaryService] Firebase error fetching daily summary: '
          '${e.message}',
        );
      }
      return null;
    } on Exception catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[SummaryService] Unexpected error fetching daily summary: $e',
        );
      }
      return null;
    }
  }

  // ============================================
  // PUBLIC API - Weekly Summary Reads
  // ============================================

  /// Get weekly summary for date's week (direct Firestore read)
  ///
  /// Returns [WeeklySummary] for the ISO 8601 week containing the given date.
  /// Week runs Monday-Sunday.
  ///
  /// Returns null if:
  /// - No summary document exists for that week
  /// - Firestore read fails
  ///
  /// Example:
  /// ```dart
  /// // Get summary for week containing Oct 5, 2025 (Week 40)
  /// final summary = await service.getWeeklySummary(
  ///   userId: userId,
  ///   petId: petId,
  ///   date: DateTime(2025, 10, 5),
  /// );
  /// // Queries document: '2025-W40'
  /// ```
  ///
  /// Cost: 1 Firestore read
  Future<WeeklySummary?> getWeeklySummary({
    required String userId,
    required String petId,
    required DateTime date,
  }) async {
    try {
      // In-memory cache (TTL)
      final key = _weeklyKey(userId, petId, date);
      final cached = _weeklyMemCache[key];
      if (cached != null && _isValid(cached.$1, _weeklyTtl)) {
        return cached.$2;
      }

      final docRef = _getWeeklySummaryRef(userId, petId, date);
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        if (kDebugMode) {
          final weekStr = AppDateUtils.formatWeekForSummary(date);
          debugPrint('[SummaryService] No weekly summary for $weekStr');
        }
        return null;
      }

      final data = docSnapshot.data();
      if (data == null) {
        if (kDebugMode) {
          debugPrint('[SummaryService] Weekly summary data is null');
        }
        return null;
      }

      final summary = WeeklySummary.fromJson(data as Map<String, dynamic>);
      _weeklyMemCache[key] = (_CacheClock(DateTime.now()), summary);
      return summary;
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[SummaryService] Firebase error fetching weekly summary: '
          '${e.message}',
        );
      }
      return null;
    } on Exception catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[SummaryService] Unexpected error fetching weekly summary: $e',
        );
      }
      return null;
    }
  }

  // ============================================
  // PUBLIC API - Monthly Summary Reads
  // ============================================

  /// Get monthly summary for date's month (direct Firestore read)
  ///
  /// Returns [MonthlySummary] for the month containing the given date.
  ///
  /// Returns null if:
  /// - No summary document exists for that month
  /// - Firestore read fails
  ///
  /// Example:
  /// ```dart
  /// // Get summary for October 2025
  /// final summary = await service.getMonthlySummary(
  ///   userId: userId,
  ///   petId: petId,
  ///   date: DateTime(2025, 10, 15),
  /// );
  /// // Queries document: '2025-10'
  /// ```
  ///
  /// Cost: 1 Firestore read
  Future<MonthlySummary?> getMonthlySummary({
    required String userId,
    required String petId,
    required DateTime date,
  }) async {
    try {
      // In-memory cache (TTL)
      final key = _monthlyKey(userId, petId, date);
      final cached = _monthlyMemCache[key];
      if (cached != null && _isValid(cached.$1, _monthlyTtl)) {
        return cached.$2;
      }

      final docRef = _getMonthlySummaryRef(userId, petId, date);
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        if (kDebugMode) {
          final monthStr = AppDateUtils.formatMonthForSummary(date);
          debugPrint('[SummaryService] No monthly summary for $monthStr');
        }
        return null;
      }

      final data = docSnapshot.data();
      if (data == null) {
        if (kDebugMode) {
          debugPrint('[SummaryService] Monthly summary data is null');
        }
        return null;
      }

      final summary = MonthlySummary.fromJson(data as Map<String, dynamic>);
      _monthlyMemCache[key] = (_CacheClock(DateTime.now()), summary);
      return summary;
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[SummaryService] Firebase error fetching monthly summary: '
          '${e.message}',
        );
      }
      return null;
    } on Exception catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[SummaryService] Unexpected error fetching monthly summary: $e',
        );
      }
      return null;
    }
  }

  // ============================================
  // PUBLIC API - Cache Management
  // ============================================

  /// Invalidate in-memory TTL cache for today's summary
  ///
  /// Call this after logging operations to ensure the progress calendar
  /// displays up-to-date completion status immediately.
  ///
  /// This fixes the issue where the calendar dot stays orange after logging
  /// all treatments because the 5-minute TTL cache contains stale data.
  ///
  /// Cost: 0 Firestore reads (only clears in-memory cache)
  ///
  /// Usage:
  /// ```dart
  /// // After logging a session
  /// await loggingService.logMedicationSession(...);
  /// summaryService.invalidateTodaysCache(userId, petId);
  /// ```
  void invalidateTodaysCache(String userId, String petId) {
    final today = DateTime.now();
    final key = _dailyKey(userId, petId, today);
    _dailyMemCache.remove(key);

    if (kDebugMode) {
      debugPrint(
        "[SummaryService] Invalidated today's cache for "
        'user:$userId pet:$petId',
      );
    }
  }

  /// Invalidate in-memory TTL cache for a specific date
  ///
  /// Use this when updating historical data (e.g., editing past sessions).
  ///
  /// Cost: 0 Firestore reads (only clears in-memory cache)
  void invalidateCacheForDate(String userId, String petId, DateTime date) {
    final key = _dailyKey(userId, petId, date);
    _dailyMemCache.remove(key);

    if (kDebugMode) {
      final dateStr = AppDateUtils.formatDateForSummary(date);
      debugPrint(
        '[SummaryService] Invalidated cache for $dateStr '
        'user:$userId pet:$petId',
      );
    }
  }

  /// Clear all in-memory TTL caches
  ///
  /// Use this for:
  /// - User logout
  /// - Pet switching
  /// - Testing/debugging
  ///
  /// Cost: 0 Firestore reads (only clears in-memory cache)
  void clearAllCaches() {
    _dailyMemCache.clear();
    _weeklyMemCache.clear();
    _monthlyMemCache.clear();

    if (kDebugMode) {
      debugPrint('[SummaryService] Cleared all in-memory caches');
    }
  }

  // ============================================
  // PRIVATE HELPERS - Firestore Paths
  // ============================================

  /// Get daily summary document reference
  ///
  /// Path: users/{userId}/pets/{petId}/treatmentSummaries/daily/summaries/{YYYY-MM-DD}
  ///
  /// Document ID format: "2025-10-05"
  DocumentReference _getDailySummaryRef(
    String userId,
    String petId,
    DateTime date,
  ) {
    final docId = AppDateUtils.formatDateForSummary(date);
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('pets')
        .doc(petId)
        .collection('treatmentSummaries')
        .doc('daily')
        .collection('summaries')
        .doc(docId);
  }

  /// Get weekly summary document reference
  ///
  /// Path: users/{userId}/pets/{petId}/treatmentSummaries/weekly/summaries/{YYYY-Www}
  ///
  /// Document ID format: "2025-W40" (ISO 8601 week number)
  DocumentReference _getWeeklySummaryRef(
    String userId,
    String petId,
    DateTime date,
  ) {
    final docId = AppDateUtils.formatWeekForSummary(date);
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('pets')
        .doc(petId)
        .collection('treatmentSummaries')
        .doc('weekly')
        .collection('summaries')
        .doc(docId);
  }

  /// Get monthly summary document reference
  ///
  /// Path: users/{userId}/pets/{petId}/treatmentSummaries/monthly/summaries/{YYYY-MM}
  ///
  /// Document ID format: "2025-10"
  DocumentReference _getMonthlySummaryRef(
    String userId,
    String petId,
    DateTime date,
  ) {
    final docId = AppDateUtils.formatMonthForSummary(date);
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('pets')
        .doc(petId)
        .collection('treatmentSummaries')
        .doc('monthly')
        .collection('summaries')
        .doc(docId);
  }
}

/// Simple clock wrapper so we can extend easily later
class _CacheClock {
  const _CacheClock(this.cachedAt);
  final DateTime cachedAt;
}
