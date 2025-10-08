/// Riverpod providers for treatment logging feature
///
/// This file contains all providers for the logging feature including:
/// - Service providers (LoggingService, SummaryService, SummaryCacheService)
/// - State management (LoggingNotifier)
/// - Optimized selectors for UI consumption
/// - Integration with auth, profile, and analytics providers
library;

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/core/utils/date_utils.dart';
import 'package:hydracat/features/logging/exceptions/logging_exceptions.dart';
import 'package:hydracat/features/logging/models/daily_summary_cache.dart';
import 'package:hydracat/features/logging/models/fluid_session.dart';
import 'package:hydracat/features/logging/models/logging_mode.dart';
import 'package:hydracat/features/logging/models/logging_operation.dart';
import 'package:hydracat/features/logging/models/logging_state.dart';
import 'package:hydracat/features/logging/models/medication_session.dart';
import 'package:hydracat/features/logging/models/treatment_choice.dart';
import 'package:hydracat/features/logging/services/logging_service.dart';
import 'package:hydracat/features/logging/services/summary_cache_service.dart';
import 'package:hydracat/features/logging/services/summary_service.dart';
import 'package:hydracat/features/profile/models/schedule.dart';
import 'package:hydracat/providers/analytics_provider.dart';
import 'package:hydracat/providers/auth_provider.dart';
import 'package:hydracat/providers/connectivity_provider.dart';
import 'package:hydracat/providers/logging_queue_provider.dart';
import 'package:hydracat/providers/profile_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

// ============================================
// Service Providers (Foundation Layer)
// ============================================

/// Provider for SharedPreferences instance
///
/// This provider must be overridden in main.dart with the actual
/// SharedPreferences instance initialized at app startup.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in main.dart',
  );
});

/// Provider for LoggingService instance
final loggingServiceProvider = Provider<LoggingService>((ref) {
  final cacheService = ref.watch(summaryCacheServiceProvider);
  return LoggingService(cacheService);
});

/// Provider for SummaryCacheService instance
final summaryCacheServiceProvider = Provider<SummaryCacheService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final analytics = ref.read(analyticsServiceDirectProvider);
  return SummaryCacheService(prefs, analytics);
});

/// Provider for SummaryService instance
final summaryServiceProvider = Provider<SummaryService>((ref) {
  final firestore = FirebaseFirestore.instance;
  final cacheService = ref.read(summaryCacheServiceProvider);
  return SummaryService(firestore, cacheService);
});

// ============================================
// State Management - LoggingNotifier
// ============================================

/// Notifier class for managing logging state and operations
///
/// Handles:
/// - Cache lifecycle (load on startup, clear on resume)
/// - Quick-log all treatments
/// - Manual medication/fluid logging
/// - State management (mode, treatment choice, errors)
/// - Integration with existing providers (auth, profile, analytics)
class LoggingNotifier extends StateNotifier<LoggingState> {
  /// Creates a [LoggingNotifier] with required dependencies
  LoggingNotifier(
    this._loggingService,
    this._cacheService,
    this._ref,
  ) : super(const LoggingState.initial()) {
    _initialize();
  }

  final LoggingService _loggingService;
  final SummaryCacheService _cacheService;
  final Ref _ref;

  // ============================================
  // Initialization & Cache Lifecycle
  // ============================================

  /// Initialize on app startup
  ///
  /// - Clears expired caches from previous days
  /// - Loads today's cache if it exists
  /// - Warms cache from Firestore for accuracy
  Future<void> _initialize() async {
    try {
      // STEP 1: Clear any expired caches from previous days
      await clearExpiredCaches();

      // STEP 2: Load today's cache from SharedPreferences
      await loadTodaysCache();

      // STEP 3: Warm cache from Firestore on cold start
      await _warmCacheFromFirestore();

      if (kDebugMode) {
        debugPrint('[LoggingNotifier] Initialization complete');
      }
    } on Exception catch (e) {
      if (kDebugMode) {
        debugPrint('[LoggingNotifier] Initialization error: $e');
      }

      // Track analytics for initialization failures
      try {
        final analyticsService = _ref.read(analyticsServiceDirectProvider);
        await analyticsService.trackError(
          errorType: 'cache_initialization_failure',
          errorContext: e.toString(),
        );
      } on Exception {
        // Silent failure on analytics tracking - don't compound errors
      }

      // Don't block app startup on cache errors
    }
  }

  /// Load today's cached summary
  ///
  /// Called on:
  /// - App startup (via _initialize)
  /// - App resume from background
  /// - After successful logging operation
  Future<void> loadTodaysCache() async {
    try {
      final user = _ref.read(currentUserProvider);
      final pet = _ref.read(primaryPetProvider);

      if (user == null || pet == null) {
        if (kDebugMode) {
          debugPrint(
            '[LoggingNotifier] Cannot load cache: user or pet is null',
          );
        }
        return;
      }

      final cache = await _cacheService.getTodaySummary(user.id, pet.id);

      if (cache != null) {
        state = state.withCache(cache);
        if (kDebugMode) {
          debugPrint('[LoggingNotifier] Cache loaded: ${cache.date}');
        }
      } else {
        // No cache exists - this is normal for first log of the day
        if (kDebugMode) {
          debugPrint('[LoggingNotifier] No cache found for today');
        }
      }
    } on Exception catch (e) {
      if (kDebugMode) {
        debugPrint('[LoggingNotifier] Error loading cache: $e');
      }
      // Don't fail on cache errors - logging can still work
    }
  }

  /// Clear expired caches
  ///
  /// Called on:
  /// - App startup
  /// - App resume from background (when day changes)
  ///
  /// This ensures we don't accumulate stale cache entries from previous days.
  Future<void> clearExpiredCaches() async {
    try {
      await _cacheService.clearExpiredCaches();

      if (kDebugMode) {
        debugPrint('[LoggingNotifier] Expired caches cleared');
      }
    } on Exception catch (e) {
      if (kDebugMode) {
        debugPrint('[LoggingNotifier] Error clearing expired caches: $e');
      }
      // Don't fail on cache cleanup errors
    }
  }

  /// Called when app resumes from background
  ///
  /// This should be called by app_shell.dart when AppLifecycleState.resumed
  /// is detected. It ensures cache is refreshed after day changes.
  Future<void> onAppResumed() async {
    if (kDebugMode) {
      debugPrint('[LoggingNotifier] App resumed - refreshing cache');
    }

    // Clear any caches from previous days
    await clearExpiredCaches();

    // Reload today's cache
    await loadTodaysCache();
  }

  /// Get recent sessions for duplicate detection (cache-first)
  ///
  /// Two-tier approach:
  /// 1. Check cache: if medication not logged, return empty list (0 reads)
  /// 2. Query Firestore: if cache shows medication logged (1-10 reads)
  ///
  /// Cost savings: ~80-90% reduction in duplicate detection queries
  Future<List<MedicationSession>> _getRecentSessionsForDuplicateCheck({
    required String userId,
    required String petId,
    required String medicationName,
  }) async {
    // TIER 1: Cache check
    final cache = state.dailyCache;

    if (cache == null || !cache.hasMedicationLogged(medicationName)) {
      if (kDebugMode) {
        debugPrint(
          '[LoggingNotifier] Cache indicates $medicationName not logged yet '
          '- skipping Firestore query',
        );
      }

      // Track cache hit
      final analyticsService = _ref.read(analyticsServiceDirectProvider);
      await analyticsService.trackFeatureUsed(
        featureName: AnalyticsEvents.duplicateCheckCacheHit,
        additionalParams: {
          'medication_name': medicationName,
          'had_cache': cache != null,
        },
      );

      return []; // No Firestore query needed
    }

    // TIER 2: Firestore query (cache indicates medication was logged)
    if (kDebugMode) {
      debugPrint(
        '[LoggingNotifier] Cache shows $medicationName logged - '
        'querying Firestore for exact times',
      );
    }

    // Track cache miss
    final analyticsService = _ref.read(analyticsServiceDirectProvider);
    await analyticsService.trackFeatureUsed(
      featureName: AnalyticsEvents.duplicateCheckCacheMiss,
      additionalParams: {
        'medication_name': medicationName,
      },
    );

    try {
      final sessions = await _loggingService.getTodaysMedicationSessions(
        userId: userId,
        petId: petId,
        medicationName: medicationName,
      );

      if (kDebugMode) {
        debugPrint(
          '[LoggingNotifier] Found ${sessions.length} recent sessions '
          'for $medicationName',
        );
      }

      return sessions;
    } on FirebaseException catch (e) {
      // Gracefully handle missing index or other Firebase errors
      if (kDebugMode) {
        debugPrint(
          '[LoggingNotifier] Firestore query failed: ${e.message}',
        );
      }

      // Track error
      await analyticsService.trackError(
        errorType: AnalyticsErrorTypes.duplicateCheckQueryFailed,
        errorContext: 'medicationName: $medicationName, error: ${e.message}',
      );

      // Return empty list - allow logging to continue without
      // duplicate detection
      return [];
    }
  }

  /// Warm cache from Firestore on app startup
  ///
  /// Fetches today's summary from Firestore and updates SharedPreferences
  /// cache to ensure accuracy. This prevents stale cache issues and ensures
  /// the cache reflects sessions logged on other devices.
  ///
  /// Field mapping from DailySummary to DailySummaryCache:
  /// - medicationSessionCount: Uses medicationScheduledDoses (proxy)
  /// - medicationNames: Empty list (not tracked in DailySummary)
  /// - totalMedicationDosesGiven: Uses medicationTotalDoses (completed doses)
  /// - totalFluidVolumeGiven: Maps to fluidTotalVolume
  ///
  /// Note: medicationNames will be populated incrementally as sessions are
  /// logged. This is acceptable since duplicate detection also queries
  /// Firestore for exact session matches.
  ///
  /// Cost: 1 Firestore read per cold start (acceptable for cache accuracy)
  Future<void> _warmCacheFromFirestore() async {
    try {
      final user = _ref.read(currentUserProvider);
      final pet = _ref.read(primaryPetProvider);

      if (user == null || pet == null) {
        if (kDebugMode) {
          debugPrint(
            '[LoggingNotifier] Cannot warm cache: user or pet is null',
          );
        }
        return;
      }

      // Fetch today's summary from Firestore
      final summaryService = _ref.read(summaryServiceProvider);
      final summary = await summaryService.getTodaySummary(
        userId: user.id,
        petId: pet.id,
      );

      if (summary != null) {
        // Convert DailySummary to DailySummaryCache
        // Note: DailySummary doesn't track medicationNames, so we use
        // empty list. This is acceptable since duplicate detection queries
        // Firestore directly
        final dateStr = AppDateUtils.formatDateForSummary(summary.date);
        final cache = DailySummaryCache(
          date: dateStr,
          medicationSessionCount: summary.medicationScheduledDoses,
          fluidSessionCount: summary.fluidSessionCount,
          medicationNames: const [], // Not tracked in DailySummary
          totalMedicationDosesGiven: summary.medicationTotalDoses.toDouble(),
          totalFluidVolumeGiven: summary.fluidTotalVolume,
        );

        // Write to SharedPreferences
        final cacheKey = 'daily_summary_${user.id}_${pet.id}_$dateStr';
        final prefs = _ref.read(sharedPreferencesProvider);
        await prefs.setString(cacheKey, jsonEncode(cache.toJson()));

        // Update state
        state = state.withCache(cache);

        if (kDebugMode) {
          debugPrint(
            '[LoggingNotifier] Cache warmed from Firestore: $dateStr',
          );
        }

        // Track analytics
        final analyticsService = _ref.read(analyticsServiceDirectProvider);
        await analyticsService.trackFeatureUsed(
          featureName: AnalyticsEvents.cacheWarmedOnStartup,
          additionalParams: {
            AnalyticsParams.medicationSessionCount:
                summary.medicationScheduledDoses,
            AnalyticsParams.fluidSessionCount: summary.fluidSessionCount,
          },
        );
      } else {
        if (kDebugMode) {
          debugPrint('[LoggingNotifier] No Firestore summary exists for today');
        }
        // This is normal for first log of the day - cache will be created on
        // first log
      }
    } on Exception catch (e) {
      if (kDebugMode) {
        debugPrint('[LoggingNotifier] Error warming cache from Firestore: $e');
      }

      // Track analytics for warming failures
      try {
        final analyticsService = _ref.read(analyticsServiceDirectProvider);
        await analyticsService.trackError(
          errorType: AnalyticsErrorTypes.cacheWarmingFailure,
          errorContext: e.toString(),
        );
      } on Exception {
        // Silent failure on analytics tracking - don't compound errors
      }

      // Don't fail initialization on warming errors - cache will be updated
      // on next log
    }
  }

  // ============================================
  // Quick-Log Implementation
  // ============================================

  /// Quick-log all scheduled treatments for today
  ///
  /// Process:
  /// 1. Check cache - if any sessions logged today, reject
  /// 2. Get today's schedules from ProfileProvider
  /// 3. Call LoggingService.quickLogAllTreatments() (to be implemented)
  /// 4. Update cache and analytics
  ///
  /// Returns:
  /// - true if successful
  /// - false if failed (error in state.error)
  Future<bool> quickLogAllTreatments() async {
    state = state.withLoading(loading: true);

    try {
      // STEP 1: Get current user and pet
      final user = _ref.read(currentUserProvider);
      final pet = _ref.read(primaryPetProvider);
      final cache = state.dailyCache;

      if (user == null || pet == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'User or pet not found. Please try again.',
        );
        return false;
      }

      // STEP 2: Check if already logged today (from cache)
      if (cache?.hasAnySessions ?? false) {
        state = state.copyWith(
          isLoading: false,
          error: 'Already logged treatments today',
        );

        if (kDebugMode) {
          debugPrint(
            '[LoggingNotifier] Quick-log rejected: '
            'sessions already logged today',
          );
        }

        return false;
      }

      // STEP 3: Get today's schedules from ProfileProvider
      final medicationSchedules = _ref.read(medicationSchedulesProvider) ?? [];
      final fluidSchedule = _ref.read(fluidScheduleProvider);

      final allSchedules = [
        ...medicationSchedules,
        if (fluidSchedule != null) fluidSchedule,
      ];

      if (allSchedules.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          error: 'No schedules found. Please set up your treatment schedule.',
        );

        if (kDebugMode) {
          debugPrint('[LoggingNotifier] Quick-log rejected: no schedules');
        }

        return false;
      }

      if (kDebugMode) {
        debugPrint(
          '[LoggingNotifier] Quick-log starting: '
          '${allSchedules.length} schedules',
        );
      }

      // STEP 4: Check connectivity
      final isOnline = _ref.read(isConnectedProvider);

      if (!isOnline) {
        // Offline: Queue operation for later sync
        if (kDebugMode) {
          debugPrint(
            '[LoggingNotifier] Offline - queueing quick-log operation',
          );
        }

        final operation = QuickLogAllOperation(
          id: const Uuid().v4(),
          userId: user.id,
          petId: pet.id,
          createdAt: DateTime.now(),
          todaysSchedules: allSchedules,
        );

        final offlineService = _ref.read(offlineLoggingServiceProvider);
        final queued = await offlineService.enqueueOperation(operation);

        if (queued) {
          // Note: Can't update cache optimistically for quick-log
          // since we don't know exact session count until sync
          state = state.copyWith(isLoading: false);

          if (kDebugMode) {
            debugPrint('[LoggingNotifier] Quick-log queued for sync');
          }

          return true;
        } else {
          state = state.copyWith(
            isLoading: false,
            error: 'Queue full. Please connect to internet.',
          );
          return false;
        }
      }

      // STEP 5: Online - Call LoggingService.quickLogAllTreatments()
      final sessionCount = await _loggingService.quickLogAllTreatments(
        userId: user.id,
        petId: pet.id,
        todaysSchedules: allSchedules,
      );

      // STEP 6: Reload cache from Firestore after success
      // The batch write updated Firestore summaries, so reload cache
      await loadTodaysCache();

      // STEP 7: Track analytics
      final analyticsService = _ref.read(analyticsServiceDirectProvider);

      // Count medication vs fluid sessions
      final medicationCount = allSchedules.where((s) => s.isMedication).length;
      final fluidCount = allSchedules.where((s) => !s.isMedication).length;

      await analyticsService.trackQuickLogUsed(
        sessionCount: sessionCount,
        medicationCount: medicationCount,
        fluidCount: fluidCount,
      );

      if (kDebugMode) {
        debugPrint(
          '[LoggingNotifier] Quick-log complete: '
          '$sessionCount sessions logged',
        );
      }

      state = state.copyWith(isLoading: false);
      return true;
    } on Exception catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _handleError(e),
      );

      // Track analytics failure
      final analyticsService = _ref.read(analyticsServiceDirectProvider);
      await analyticsService.trackError(
        errorType: AnalyticsErrorTypes.quickLogFailure,
        errorContext: e.toString(),
      );

      if (kDebugMode) {
        debugPrint('[LoggingNotifier] Quick-log error: $e');
      }

      return false;
    }
  }

  // ============================================
  // Manual Logging Methods
  // ============================================

  /// Log a medication session
  ///
  /// Process:
  /// 1. Validate user and pet
  /// 2. Get recent sessions from cache (for duplicate detection)
  /// 3. Call LoggingService.logMedicationSession()
  /// 4. Update cache and analytics
  ///
  /// Parameters:
  /// - session: MedicationSession to log
  /// - todaysSchedules: Active medication schedules for today (for matching)
  ///
  /// Returns:
  /// - true if successful
  /// - false if failed (error in state.error)
  Future<bool> logMedicationSession({
    required MedicationSession session,
    required List<Schedule> todaysSchedules,
  }) async {
    state = state.withLoading(loading: true);

    try {
      // STEP 1: Get current user and pet
      final user = _ref.read(currentUserProvider);
      final pet = _ref.read(primaryPetProvider);

      if (user == null || pet == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'User or pet not found. Please try again.',
        );
        return false;
      }

      // STEP 2: Check connectivity
      final isOnline = _ref.read(isConnectedProvider);

      if (!isOnline) {
        // Offline: Queue operation for later sync
        if (kDebugMode) {
          debugPrint('[LoggingNotifier] Offline - queueing medication session');
        }

        final operation = CreateMedicationOperation(
          id: const Uuid().v4(),
          userId: user.id,
          petId: pet.id,
          createdAt: DateTime.now(),
          session: session,
          todaysSchedules: todaysSchedules,
          recentSessions: const [], // Intentionally empty - offline operations
          // skip duplicate detection (user intent
          // is explicit)
        );

        final offlineService = _ref.read(offlineLoggingServiceProvider);
        final queued = await offlineService.enqueueOperation(operation);

        if (queued) {
          // Update local cache immediately (optimistic UI)
          await _cacheService.updateCacheWithMedicationSession(
            userId: user.id,
            petId: pet.id,
            medicationName: session.medicationName,
            dosageGiven: session.dosageGiven,
          );

          await loadTodaysCache();

          state = state.copyWith(isLoading: false);

          if (kDebugMode) {
            debugPrint('[LoggingNotifier] Medication queued for sync');
          }

          return true;
        } else {
          state = state.copyWith(
            isLoading: false,
            error: 'Queue full. Please connect to internet.',
          );
          return false;
        }
      }

      // STEP 3: Get recent sessions (cache-first for cost optimization)
      final recentSessions = await _getRecentSessionsForDuplicateCheck(
        userId: user.id,
        petId: pet.id,
        medicationName: session.medicationName,
      );

      if (kDebugMode) {
        debugPrint(
          '[LoggingNotifier] Logging medication: '
          '${session.medicationName} at ${session.dateTime}',
        );
      }

      // STEP 4: Call LoggingService
      final sessionId = await _loggingService.logMedicationSession(
        userId: user.id,
        petId: pet.id,
        session: session,
        todaysSchedules: todaysSchedules,
        recentSessions: recentSessions,
      );

      // STEP 5: Update cache
      await _cacheService.updateCacheWithMedicationSession(
        userId: user.id,
        petId: pet.id,
        medicationName: session.medicationName,
        dosageGiven: session.dosageGiven,
      );

      // Reload cache to get fresh data
      await loadTodaysCache();

      // STEP 6: Track analytics
      final analyticsService = _ref.read(analyticsServiceDirectProvider);
      await analyticsService.trackSessionLogged(
        treatmentType: 'medication',
        sessionCount: 1,
        isQuickLog: false,
        adherenceStatus: session.completed ? 'complete' : 'partial',
        medicationName: session.medicationName,
      );

      if (kDebugMode) {
        debugPrint(
          '[LoggingNotifier] Medication logged successfully: $sessionId',
        );
      }

      state = state.copyWith(isLoading: false);
      return true;
    } on DuplicateSessionException catch (e) {
      // Special handling for duplicates - expose to UI for user decision
      final errorMsg =
          'You already logged ${e.medicationName} at ${e.conflictingTime}. '
          'Would you like to update it?';

      state = state.copyWith(
        isLoading: false,
        error: errorMsg,
      );

      // Track duplicate detection
      final analyticsService = _ref.read(analyticsServiceDirectProvider);
      await analyticsService.trackFeatureUsed(
        featureName: AnalyticsEvents.duplicateDetected,
        additionalParams: {
          'medication_name': e.medicationName ?? 'unknown',
          'time_difference_minutes': e.existingSession != null
              ? session.dateTime
                    .difference(
                      (e.existingSession as MedicationSession).dateTime,
                    )
                    .inMinutes
                    .abs()
              : 0,
        },
      );

      if (kDebugMode) {
        debugPrint('[LoggingNotifier] Duplicate medication: $errorMsg');
      }

      return false;
    } on Exception catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _handleError(e),
      );

      // Track analytics failure
      final analyticsService = _ref.read(analyticsServiceDirectProvider);
      await analyticsService.trackError(
        errorType: AnalyticsErrorTypes.logMedicationFailure,
        errorContext: e.toString(),
      );

      if (kDebugMode) {
        debugPrint('[LoggingNotifier] Medication logging error: $e');
      }

      return false;
    }
  }

  /// Log a fluid therapy session
  ///
  /// Process:
  /// 1. Validate user and pet
  /// 2. Call LoggingService.logFluidSession()
  /// 3. Update cache and analytics
  ///
  /// Parameters:
  /// - session: FluidSession to log
  /// - fluidSchedule: Active fluid schedule (for matching, optional)
  ///
  /// Returns:
  /// - true if successful
  /// - false if failed (error in state.error)
  ///
  /// Note: Fluid sessions do NOT have duplicate detection (multiple partial
  /// sessions per day are valid)
  Future<bool> logFluidSession({
    required FluidSession session,
    Schedule? fluidSchedule,
  }) async {
    state = state.withLoading(loading: true);

    try {
      // STEP 1: Get current user and pet
      final user = _ref.read(currentUserProvider);
      final pet = _ref.read(primaryPetProvider);

      if (user == null || pet == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'User or pet not found. Please try again.',
        );
        return false;
      }

      // STEP 2: Check connectivity
      final isOnline = _ref.read(isConnectedProvider);

      if (!isOnline) {
        // Offline: Queue operation for later sync
        if (kDebugMode) {
          debugPrint('[LoggingNotifier] Offline - queueing fluid session');
        }

        final operation = CreateFluidOperation(
          id: const Uuid().v4(),
          userId: user.id,
          petId: pet.id,
          createdAt: DateTime.now(),
          session: session,
          todaysSchedule: fluidSchedule,
        );

        final offlineService = _ref.read(offlineLoggingServiceProvider);
        final queued = await offlineService.enqueueOperation(operation);

        if (queued) {
          // Update local cache immediately (optimistic UI)
          await _cacheService.updateCacheWithFluidSession(
            userId: user.id,
            petId: pet.id,
            volumeGiven: session.volumeGiven,
          );

          await loadTodaysCache();

          state = state.copyWith(isLoading: false);

          if (kDebugMode) {
            debugPrint('[LoggingNotifier] Fluid session queued for sync');
          }

          return true;
        } else {
          state = state.copyWith(
            isLoading: false,
            error: 'Queue full. Please connect to internet.',
          );
          return false;
        }
      }

      // STEP 3: Online - Log directly
      if (kDebugMode) {
        debugPrint(
          '[LoggingNotifier] Logging fluid: '
          '${session.volumeGiven}ml at ${session.dateTime}',
        );
      }

      final sessionId = await _loggingService.logFluidSession(
        userId: user.id,
        petId: pet.id,
        session: session,
        todaysSchedules: fluidSchedule != null ? [fluidSchedule] : [],
        recentSessions: [], // Fluids don't need duplicate detection
      );

      // STEP 4: Update cache
      await _cacheService.updateCacheWithFluidSession(
        userId: user.id,
        petId: pet.id,
        volumeGiven: session.volumeGiven,
      );

      // Reload cache to get fresh data
      await loadTodaysCache();

      // STEP 5: Track analytics
      final analyticsService = _ref.read(analyticsServiceDirectProvider);
      await analyticsService.trackSessionLogged(
        treatmentType: 'fluid',
        sessionCount: 1,
        isQuickLog: false,
        adherenceStatus: 'complete',
        volumeGiven: session.volumeGiven,
      );

      if (kDebugMode) {
        debugPrint('[LoggingNotifier] Fluid logged successfully: $sessionId');
      }

      state = state.copyWith(isLoading: false);
      return true;
    } on Exception catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _handleError(e),
      );

      // Track analytics failure
      final analyticsService = _ref.read(analyticsServiceDirectProvider);
      await analyticsService.trackError(
        errorType: AnalyticsErrorTypes.logFluidFailure,
        errorContext: e.toString(),
      );

      if (kDebugMode) {
        debugPrint('[LoggingNotifier] Fluid logging error: $e');
      }

      return false;
    }
  }

  // ============================================
  // State Management Helpers
  // ============================================

  /// Set logging mode (manual or quick-log)
  void setLoggingMode(LoggingMode mode) {
    state = state.withMode(mode);

    if (kDebugMode) {
      debugPrint('[LoggingNotifier] Logging mode set: ${mode.name}');
    }
  }

  /// Set treatment choice (medication or fluid)
  ///
  /// Only relevant for combined treatment personas who need to choose
  /// between medication and fluid logging.
  void setTreatmentChoice(TreatmentChoice choice) {
    state = state.withTreatmentChoice(choice);

    if (kDebugMode) {
      debugPrint('[LoggingNotifier] Treatment choice set: ${choice.name}');
    }
  }

  /// Clear current error
  void clearError() {
    state = state.clearError();

    if (kDebugMode) {
      debugPrint('[LoggingNotifier] Error cleared');
    }
  }

  /// Reset state to initial
  ///
  /// Call this after:
  /// - Successful logging completion
  /// - User dismisses logging popup
  /// - Navigation away from logging flow
  ///
  /// Note: Preserves dailyCache across resets
  void reset() {
    state = state.reset();

    if (kDebugMode) {
      debugPrint('[LoggingNotifier] State reset (cache preserved)');
    }
  }

  /// Convert exceptions to user-friendly error messages
  ///
  /// Maps technical exceptions to user-facing strings that:
  /// - Are empathetic and helpful
  /// - Don't expose technical details
  /// - Suggest next actions when appropriate
  String _handleError(Object error) {
    if (error is SessionValidationException) {
      return 'Invalid session data: ${error.message}. '
          'Please check your input and try again.';
    } else if (error is DuplicateSessionException) {
      return 'You already logged ${error.medicationName ?? "this treatment"} '
          'today. Would you like to update it instead?';
    } else if (error is BatchWriteException) {
      return 'Failed to save session. Please check your connection '
          'and try again.';
    } else if (error is LoggingException) {
      return error.message;
    } else if (error is UnimplementedError) {
      // During development - expose implementation status
      return kDebugMode
          ? error.message ?? 'Feature not yet implemented'
          : 'This feature is coming soon!';
    }

    // Unexpected error - generic message
    return 'An unexpected error occurred. Please try again.';
  }
}

// ============================================
// Primary Provider
// ============================================

/// Provider for logging state management
///
/// This is the main provider for the logging feature. It integrates with:
/// - LoggingService: For session writes and batch operations
/// - SummaryCacheService: For local cache management
/// - Auth/Profile/Analytics: For user context and tracking
final loggingProvider = StateNotifierProvider<LoggingNotifier, LoggingState>((
  ref,
) {
  final loggingService = ref.read(loggingServiceProvider);
  final cacheService = ref.read(summaryCacheServiceProvider);

  return LoggingNotifier(loggingService, cacheService, ref);
});

// ============================================
// Optimized Selector Providers
// ============================================

/// Is logging operation in progress
///
/// Use this to show loading indicators during:
/// - Quick-log execution
/// - Manual session logging
/// - Cache updates
final isLoggingProvider = Provider<bool>((ref) {
  return ref.watch(loggingProvider.select((state) => state.isLoading));
});

/// Current error message (null if no error)
final loggingErrorProvider = Provider<String?>((ref) {
  return ref.watch(loggingProvider.select((state) => state.error));
});

/// Has error (boolean convenience)
final hasLoggingErrorProvider = Provider<bool>((ref) {
  return ref.watch(loggingProvider.select((state) => state.hasError));
});

/// Today's cache data (null if not loaded)
final dailyCacheProvider = Provider<DailySummaryCache?>((ref) {
  return ref.watch(loggingProvider.select((state) => state.dailyCache));
});

/// Current logging mode (null if not set)
final loggingModeProvider = Provider<LoggingMode?>((ref) {
  return ref.watch(loggingProvider.select((state) => state.loggingMode));
});

/// Current treatment choice (null if not set)
final treatmentChoiceProvider = Provider<TreatmentChoice?>((ref) {
  return ref.watch(loggingProvider.select((state) => state.treatmentChoice));
});

/// Is ready for logging (mode selected, not loading, no errors)
final isReadyForLoggingProvider = Provider<bool>((ref) {
  return ref.watch(
    loggingProvider.select((state) => state.isReadyForLogging),
  );
});

// ============================================
// Computed Providers (Cache-based)
// ============================================

/// Has logged any sessions today
///
/// Use this for:
/// - FAB state (disable quick-log if already logged)
/// - Home screen status indicators
/// - Reminder notifications
final hasLoggedTodayProvider = Provider<bool>((ref) {
  final cache = ref.watch(dailyCacheProvider);
  return cache?.hasAnySessions ?? false;
});

/// Can use quick-log (has schedules AND no sessions today)
///
/// Quick-log is available when:
/// - User has at least one active schedule (medication or fluid)
/// - No sessions logged today (prevents duplicate quick-logs)
final canQuickLogProvider = Provider<bool>((ref) {
  final hasSchedules =
      ref.watch(hasMedicationSchedulesProvider) ||
      ref.watch(hasFluidScheduleProvider);
  final hasLogged = ref.watch(hasLoggedTodayProvider);

  return hasSchedules && !hasLogged;
});

/// Today's medication session count (for UI badges)
final todaysMedicationCountProvider = Provider<int>((ref) {
  final cache = ref.watch(dailyCacheProvider);
  return cache?.medicationSessionCount ?? 0;
});

/// Today's fluid session count
final todaysFluidCountProvider = Provider<int>((ref) {
  final cache = ref.watch(dailyCacheProvider);
  return cache?.fluidSessionCount ?? 0;
});

/// Today's total session count
final todaysSessionCountProvider = Provider<int>((ref) {
  final medCount = ref.watch(todaysMedicationCountProvider);
  final fluidCount = ref.watch(todaysFluidCountProvider);
  return medCount + fluidCount;
});

/// Today's total medication doses given
final todaysMedicationDosesProvider = Provider<double>((ref) {
  final cache = ref.watch(dailyCacheProvider);
  return cache?.totalMedicationDosesGiven ?? 0.0;
});

/// Today's total fluid volume given
final todaysFluidVolumeProvider = Provider<double>((ref) {
  final cache = ref.watch(dailyCacheProvider);
  return cache?.totalFluidVolumeGiven ?? 0.0;
});

// ============================================
// Schedule Filtering Providers
// ============================================

/// Today's medication schedules (filtered by today's reminder times)
///
/// Returns only medication schedules that have at least one reminder
/// time for today. Used for:
/// - Pre-filling medication logging form
/// - Quick-log medication creation
final todaysMedicationSchedulesProvider = Provider<List<Schedule>>((ref) {
  final allSchedules = ref.watch(medicationSchedulesProvider) ?? [];
  final now = DateTime.now();

  // Filter schedules that have reminder times for today
  // Uses the ScheduleDateHelpers extension from Schedule model
  return allSchedules.where((schedule) {
    return schedule.hasReminderTimeToday(now);
  }).toList();
});

/// Today's fluid schedule (if has reminder time for today)
///
/// Returns fluid schedule only if it has at least one reminder time
/// for today. Used for:
/// - Pre-filling fluid logging form
/// - Quick-log fluid creation
final todaysFluidScheduleProvider = Provider<Schedule?>((ref) {
  final fluidSchedule = ref.watch(fluidScheduleProvider);
  final now = DateTime.now();

  if (fluidSchedule == null) return null;

  // Uses the ScheduleDateHelpers extension from Schedule model
  return fluidSchedule.hasReminderTimeToday(now) ? fluidSchedule : null;
});
