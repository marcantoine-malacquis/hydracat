/// Riverpod providers for treatment logging feature
///
/// This file contains all providers for the logging feature including:
/// - Service providers (LoggingService, SummaryService, SummaryCacheService)
/// - State management (LoggingNotifier)
/// - Optimized selectors for UI consumption
/// - Integration with auth, profile, and analytics providers
library;

import 'dart:async';
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
import 'package:hydracat/features/logging/services/logging_validation_service.dart';
import 'package:hydracat/features/logging/services/summary_cache_service.dart';
import 'package:hydracat/features/logging/services/summary_service.dart';
import 'package:hydracat/features/logging/services/weight_calculator_service.dart';
import 'package:hydracat/features/notifications/providers/notification_provider.dart';
import 'package:hydracat/features/notifications/utils/time_slot_formatter.dart';
import 'package:hydracat/features/profile/models/schedule.dart';
import 'package:hydracat/features/progress/providers/injection_sites_provider.dart';
import 'package:hydracat/providers/analytics_provider.dart';
import 'package:hydracat/providers/auth_provider.dart';
import 'package:hydracat/providers/connectivity_provider.dart';
import 'package:hydracat/providers/logging_queue_provider.dart';
import 'package:hydracat/providers/profile_provider.dart';
// progress_provider.dart intentionally not imported to avoid
// manual invalidations
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

/// Provider for LoggingValidationService instance
final loggingValidationServiceProvider = Provider<LoggingValidationService>(
  (ref) => const LoggingValidationService(),
);

/// Provider for LoggingService instance
final loggingServiceProvider = Provider<LoggingService>((ref) {
  final cacheService = ref.watch(summaryCacheServiceProvider);
  final analytics = ref.read(analyticsServiceDirectProvider);
  final validationService = ref.watch(loggingValidationServiceProvider);
  return LoggingService(cacheService, analytics, validationService);
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
  return SummaryService(firestore);
});

/// Provider for WeightCalculatorService instance
///
/// Uses existing sharedPreferencesProvider for dependency injection.
/// Enables weight-based fluid volume calculation feature.
final weightCalculatorServiceProvider = Provider<WeightCalculatorService>((
  ref,
) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return WeightCalculatorService(prefs);
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

  // Track previous auth/profile state to detect transitions
  String? _previousUserId;
  String? _previousPetId;

  // Prevent duplicate startup warming; ensures we only warm once
  bool _startupPreparationDone = false;

  // Throttle notification refreshes when logging multiple treatments rapidly
  Timer? _notificationRefreshTimer;
  static const _notificationRefreshDelay = Duration(milliseconds: 500);

  // ============================================
  // Initialization & Cache Lifecycle
  // ============================================

  /// Initialize on app startup
  ///
  /// - Clears expired caches from previous days
  /// - Loads today's cache if it exists
  /// - Warms cache from Firestore for accuracy
  /// - Sets up reactive listeners for auth/profile changes
  Future<void> _initialize() async {
    try {
      // STEP 1: Clear any expired caches from previous days
      await clearExpiredCaches();

      // STEP 2: Set up reactive cache loading when user/pet becomes available
      _setupCacheReloadListeners();

      // STEP 3: If user & pet are already available, prepare cache now
      final user = _ref.read(currentUserProvider);
      final pet = _ref.read(primaryPetProvider);
      if (user != null && pet != null) {
        await loadTodaysCache();
        await _warmCacheFromFirestore();
        _startupPreparationDone = true;
      }

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

  /// Set up listeners to reload cache when auth/profile data becomes available
  ///
  /// This fixes the hot-restart issue where:
  /// 1. LoggingNotifier initializes before user auth completes
  /// 2. loadTodaysCache() fails because user/pet are null
  /// 3. Cache is never loaded even after successful auth
  ///
  /// Solution: Watch for changes in user/pet and retry loading cache
  void _setupCacheReloadListeners() {
    // Listen to both user and pet changes
    _ref
      ..listen(
        currentUserProvider,
        (previous, next) {
          final user = next;
          final pet = _ref.read(primaryPetProvider);

          // Check if we transitioned from null → available
          final userJustBecameAvailable =
              _previousUserId == null && user != null;
          final bothAvailable = user != null && pet != null;

          if (userJustBecameAvailable && bothAvailable) {
            if (kDebugMode) {
              debugPrint(
                '[LoggingNotifier] User authenticated - reloading cache',
              );
            }
            loadTodaysCache();

            // Also warm cache on first availability after startup
            if (!_startupPreparationDone) {
              _warmCacheFromFirestore();
              _startupPreparationDone = true;
            }
          }

          _previousUserId = user?.id;
        },
        fireImmediately: false,
      )
      ..listen(
        primaryPetProvider,
        (previous, next) {
          final pet = next;
          final user = _ref.read(currentUserProvider);

          // Check if we transitioned from null → available
          final petJustBecameAvailable = _previousPetId == null && pet != null;
          final bothAvailable = user != null && pet != null;

          if (petJustBecameAvailable && bothAvailable) {
            if (kDebugMode) {
              debugPrint(
                '[LoggingNotifier] Pet loaded - reloading cache',
              );
            }
            loadTodaysCache();

            // Also warm cache on first availability after startup
            if (!_startupPreparationDone) {
              _warmCacheFromFirestore();
              _startupPreparationDone = true;
            }
          }

          _previousPetId = pet?.id;
        },
        fireImmediately: false,
      );
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

    // If no cache exists, fall back to bounded Firestore query for safety
    if (cache == null) {
      if (kDebugMode) {
        debugPrint(
          '[LoggingNotifier] No cache — querying Firestore for duplicates',
        );
      }

      final sessions = await _loggingService.getTodaysMedicationSessions(
        userId: userId,
        petId: petId,
        medicationName: medicationName,
      );
      return sessions;
    }

    // If cache exists but shows other meds today (count>0) and not this med,
    // query Firestore by name to be resilient to prior cache warming gaps.
    if (!cache.hasMedicationLogged(medicationName) &&
        (cache.medicationSessionCount > 0)) {
      if (kDebugMode) {
        debugPrint(
          '[LoggingNotifier] Cache incomplete for $medicationName — '
          'querying Firestore',
        );
      }

      final sessions = await _loggingService.getTodaysMedicationSessions(
        userId: userId,
        petId: petId,
        medicationName: medicationName,
      );
      return sessions;
    }

    // If cache shows no meds at all today and does not include this med,
    // we can safely skip querying (zero-read path).
    if (!cache.hasMedicationLogged(medicationName) &&
        cache.medicationSessionCount == 0) {
      if (kDebugMode) {
        debugPrint('[LoggingNotifier] Cache shows no meds today — zero-read');
      }

      final analyticsService = _ref.read(analyticsServiceDirectProvider);
      await analyticsService.trackFeatureUsed(
        featureName: AnalyticsEvents.duplicateCheckCacheHit,
        additionalParams: {
          'medication_name': medicationName,
          'had_cache': true,
        },
      );
      return [];
    }

    // TIER 2: zero-read cache window check
    try {
      final cacheService = _ref.read(summaryCacheServiceProvider);
      final now = DateTime.now();
      final isDup = await cacheService.isLikelyDuplicate(
        userId: userId,
        petId: petId,
        medicationName: medicationName,
        candidateTime: now,
      );

      if (isDup) {
        if (kDebugMode) {
          debugPrint(
            '[LoggingNotifier] Cache indicates duplicate within window '
            'for $medicationName — zero-read path',
          );
        }

        // Synthesize a minimal session at the nearest cached time to fit
        // existing duplicate comparison logic
        final times = await cacheService.getRecentTimesForMedication(
          userId,
          petId,
          medicationName,
        );
        if (times.isNotEmpty) {
          // Pick the closest time to now
          times.sort(
            (a, b) =>
                a.difference(now).abs().compareTo(b.difference(now).abs()),
          );
          final synthetic = MedicationSession.syntheticForDuplicate(
            petId: petId,
            userId: userId,
            dateTime: times.first,
            medicationName: medicationName,
          );
          return [synthetic];
        }
      }

      // Fallback to Firestore when cache cannot decide
      if (kDebugMode) {
        debugPrint(
          '[LoggingNotifier] Cache shows med logged but no window match — '
          'querying Firestore',
        );
      }

      final analyticsService = _ref.read(analyticsServiceDirectProvider);
      await analyticsService.trackFeatureUsed(
        featureName: AnalyticsEvents.duplicateCheckCacheMiss,
        additionalParams: {
          'medication_name': medicationName,
        },
      );

      final sessions = await _loggingService.getTodaysMedicationSessions(
        userId: userId,
        petId: petId,
        medicationName: medicationName,
      );
      return sessions;
    } on Exception catch (e) {
      // Conservative fallback on any error: return empty list
      if (kDebugMode) {
        debugPrint('[LoggingNotifier] Duplicate cache path error: $e');
      }
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
  /// Cache time maps:
  /// - medicationRecentTimes: Includes all recent sessions (completed or not)
  ///   for duplicate detection. Used by duplicate detection logic.
  /// - medicationCompletedTimes: Includes only completed sessions
  ///   (completed == true)
  ///   and is the source of truth for home dashboard completion detection.
  ///   Used by DashboardNotifier._isMedicationCompleted().
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
        // Preserve existing cache data (names/times) when available
        final existing = await _cacheService.getTodaySummary(user.id, pet.id);
        final dateStr = AppDateUtils.formatDateForSummary(summary.date);

        // If existing cache lacks names/times but summary shows meds today,
        // rebuild minimal structures from a bounded Firestore query
        var medicationRecentTimes = Map<String, List<String>>.from(
          existing?.medicationRecentTimes ?? const {},
        );
        var medicationCompletedTimes = Map<String, List<String>>.from(
          existing?.medicationCompletedTimes ?? const {},
        );
        var medicationNames = List<String>.from(
          existing?.medicationNames ?? const [],
        );

        final summaryCompletedCount = summary.medicationTotalDoses;
        final currentCompletedCount =
            existing?.completedMedicationDoseCount ?? 0;
        final hasCompletionMismatch =
            currentCompletedCount != summaryCompletedCount;

        final shouldHydrateMedicationTimes = summaryCompletedCount > 0
            ? medicationNames.isEmpty ||
                medicationCompletedTimes.isEmpty ||
                hasCompletionMismatch
            : hasCompletionMismatch;

        if (shouldHydrateMedicationTimes) {
          final sessions = await _loggingService.getTodaysMedicationSessionsAll(
            userId: user.id,
            petId: pet.id,
          );

          if (sessions.isNotEmpty) {
            // Derive names
            final nameSet = <String>{};
            for (final s in sessions) {
              nameSet.add(s.medicationName);
            }
            medicationNames = nameSet.toList();

            // Derive recent times per name (keep latest 8)
            final tmp = <String, List<DateTime>>{};
            for (final s in sessions) {
              // Prefer scheduledTime to make dashboard window matching reliable
              final t = s.scheduledTime ?? s.dateTime;
              tmp.putIfAbsent(s.medicationName, () => []).add(t);
            }
            medicationRecentTimes = tmp.map((name, list) {
              list.sort((a, b) => a.compareTo(b));
              final trimmed = list.length <= 8
                  ? list
                  : list.sublist(list.length - 8, list.length);
              return MapEntry(
                name,
                trimmed.map((t) => t.toIso8601String()).toList(),
              );
            });

            // Derive completed times per name (keep latest 8)
            // Only include sessions where completed == true for accurate
            // dashboard filtering
            final completedTmp = <String, List<DateTime>>{};
            for (final s in sessions) {
              if (s.completed) {
                // Prefer scheduledTime for consistent window matching
                final t = s.scheduledTime ?? s.dateTime;
                completedTmp.putIfAbsent(s.medicationName, () => []).add(t);
              }
            }
            medicationCompletedTimes = completedTmp.map((name, list) {
              list.sort((a, b) => a.compareTo(b));
              final trimmed = list.length <= 8
                  ? list
                  : list.sublist(list.length - 8, list.length);
              return MapEntry(
                name,
                trimmed.map((t) => t.toIso8601String()).toList(),
              );
            });
          } else if (summaryCompletedCount == 0 && hasCompletionMismatch) {
            // Summary reports no doses today but cache still has entries -
            // clear them to avoid showing stale completions.
            medicationNames = const <String>[];
            medicationRecentTimes = const <String, List<String>>{};
            medicationCompletedTimes = const <String, List<String>>{};
          }
        }

        // Build warmed cache preserving derived data
        final cache = DailySummaryCache(
          date: dateStr,
          medicationSessionCount: summary.medicationScheduledDoses,
          fluidSessionCount: summary.fluidSessionCount,
          medicationNames: medicationNames,
          totalMedicationDosesGiven: summary.medicationTotalDoses.toDouble(),
          totalFluidVolumeGiven: summary.fluidTotalVolume,
          medicationRecentTimes: medicationRecentTimes,
          medicationCompletedTimes: medicationCompletedTimes,
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
  /// - Session count if successful (number of sessions logged)
  /// - 0 if failed (error in state.error)
  Future<int> quickLogAllTreatments() async {
    if (kDebugMode) {
      debugPrint('[LoggingNotifier] Quick-log starting...');
    }

    state = state.withLoading(loading: true);

    try {
      // STEP 1: Get current user and pet
      final user = _ref.read(currentUserProvider);
      final pet = _ref.read(primaryPetProvider);
      final cache = state.dailyCache;

      if (kDebugMode) {
        debugPrint('[LoggingNotifier] User: ${user?.id}, Pet: ${pet?.id}');
        debugPrint(
          '[LoggingNotifier] Cache has sessions: ${cache?.hasAnySessions}',
        );
      }

      if (user == null || pet == null) {
        if (kDebugMode) {
          debugPrint('[LoggingNotifier] User or pet is null');
        }
        state = state.copyWith(
          isLoading: false,
          error: 'User or pet not found. Please try again.',
        );
        return 0;
      }

      // STEP 2: Get today's schedules from ProfileProvider
      final medicationSchedules = _ref.read(medicationSchedulesProvider) ?? [];
      final fluidSchedule = _ref.read(fluidScheduleProvider);

      // STEP 3: Check if there are remaining treatments to log (smart check)
      if (cache != null) {
        final hasRemainingMeds = _hasRemainingMedications(
          cache,
          medicationSchedules,
        );
        final hasRemainingFluid = _hasRemainingFluid(cache, fluidSchedule);

        if (!hasRemainingMeds && !hasRemainingFluid) {
          state = state.copyWith(
            isLoading: false,
            error: 'All scheduled treatments logged today',
          );

          if (kDebugMode) {
            debugPrint(
              '[LoggingNotifier] Quick-log rejected: '
              'all treatments already logged',
            );
          }

          return 0;
        }

        if (kDebugMode) {
          debugPrint(
            '[LoggingNotifier] Partial completion detected - '
            'hasRemainingMeds: $hasRemainingMeds, '
            'hasRemainingFluid: $hasRemainingFluid',
          );
        }
      }

      if (kDebugMode) {
        debugPrint(
          '[LoggingNotifier] Medication schedules: '
          '${medicationSchedules.length}',
        );
        debugPrint(
          '[LoggingNotifier] Fluid schedule exists: '
          '${fluidSchedule != null}',
        );
      }

      final allSchedules = [
        ...medicationSchedules,
        if (fluidSchedule != null) fluidSchedule,
      ];

      if (allSchedules.isEmpty) {
        if (kDebugMode) {
          debugPrint(
            '[LoggingNotifier] Quick-log rejected: no schedules found',
          );
        }
        state = state.copyWith(
          isLoading: false,
          error: 'No schedules found. Please set up your treatment schedule.',
        );

        return 0;
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

        try {
          await offlineService.enqueueOperation(operation);

          // Successfully queued
          // Note: Can't update cache optimistically for quick-log
          // since we don't know exact session count until sync
          state = state.copyWith(isLoading: false);

          if (kDebugMode) {
            debugPrint('[LoggingNotifier] Quick-log queued for sync');
          }

          // Can't determine exact count when queued offline
          return 0;
        } on QueueWarningException catch (e) {
          // Operation succeeded but queue is getting full - show warning
          state = state.copyWith(isLoading: false, error: e.userMessage);

          if (kDebugMode) {
            debugPrint(
              '[LoggingNotifier] Quick-log queued with warning: '
              '${e.userMessage}',
            );
          }

          // Can't determine exact count when queued offline
          return 0; // Operation succeeded, just warn user
        } on QueueFullException catch (e) {
          // Queue is full - cannot queue
          state = state.copyWith(isLoading: false, error: e.userMessage);

          if (kDebugMode) {
            debugPrint('[LoggingNotifier] Quick-log failed: ${e.userMessage}');
          }

          return 0;
        }
      }

      // STEP 5: Online - Call LoggingService.quickLogAllTreatments()
      if (kDebugMode) {
        debugPrint(
          '[LoggingNotifier] Calling LoggingService.quickLogAllTreatments '
          'with ${allSchedules.length} schedules',
        );
      }

      final quickLogStart = DateTime.now();
      final result = await _loggingService.quickLogAllTreatments(
        userId: user.id,
        petId: pet.id,
        todaysSchedules: allSchedules,
      );

      if (kDebugMode) {
        debugPrint(
          '[LoggingNotifier] LoggingService returned sessionCount: '
          '${result.sessionCount}',
        );
      }

      // STEP 6: Incrementally update cache with what was actually logged
      // This avoids race condition with Firestore and uses known values
      if (cache != null) {
        // Merge new data with existing cache
        final updatedMedicationNames = <String>{
          ...cache.medicationNames,
          ...result.medicationNames,
        }.toList();

        // Merge medicationRecentTimes (all sessions for duplicate detection)
        final updatedMedicationRecentTimes = Map<String, List<String>>.from(
          cache.medicationRecentTimes,
        );
        result.medicationRecentTimes.forEach((name, times) {
          updatedMedicationRecentTimes
              .putIfAbsent(name, () => [])
              .addAll(times);
        });

        // Merge medicationCompletedTimes
        // (only completed sessions for dashboard)
        // This is critical for home dashboard to correctly detect completed
        // doses
        final updatedMedicationCompletedTimes = Map<String, List<String>>.from(
          cache.medicationCompletedTimes,
        );
        result.medicationCompletedTimes.forEach((name, times) {
          updatedMedicationCompletedTimes
              .putIfAbsent(name, () => [])
              .addAll(times);
        });

        final updatedCache = cache.copyWith(
          medicationSessionCount:
              cache.medicationSessionCount + result.medicationSessionCount,
          fluidSessionCount: cache.fluidSessionCount + result.fluidSessionCount,
          medicationNames: updatedMedicationNames,
          totalMedicationDosesGiven:
              cache.totalMedicationDosesGiven + result.totalMedicationDoses,
          totalFluidVolumeGiven:
              cache.totalFluidVolumeGiven + result.totalFluidVolume,
          medicationRecentTimes: updatedMedicationRecentTimes,
          medicationCompletedTimes: updatedMedicationCompletedTimes,
        );

        // Save to SharedPreferences
        final today = AppDateUtils.formatDateForSummary(DateTime.now());
        final cacheKey = 'daily_summary_${user.id}_${pet.id}_$today';
        final prefs = _ref.read(sharedPreferencesProvider);
        await prefs.setString(cacheKey, jsonEncode(updatedCache.toJson()));

        // Update state
        state = state.withCache(updatedCache);
      } else {
        // No existing cache - create new one from results
        final today = AppDateUtils.formatDateForSummary(DateTime.now());
        final newCache = DailySummaryCache(
          date: today,
          medicationSessionCount: result.medicationSessionCount,
          fluidSessionCount: result.fluidSessionCount,
          medicationNames: result.medicationNames,
          totalMedicationDosesGiven: result.totalMedicationDoses,
          totalFluidVolumeGiven: result.totalFluidVolume,
          medicationRecentTimes: result.medicationRecentTimes,
          medicationCompletedTimes: result.medicationCompletedTimes,
        );

        // Save to SharedPreferences
        final cacheKey = 'daily_summary_${user.id}_${pet.id}_$today';
        final prefs = _ref.read(sharedPreferencesProvider);
        await prefs.setString(cacheKey, jsonEncode(newCache.toJson()));

        // Update state
        state = state.withCache(newCache);
      }

      // Invalidate in-memory TTL cache to ensure calendar updates immediately
      _ref.read(summaryServiceProvider).clearAllCaches();

      // Refresh pet profile if fluid sessions were logged
      // (updates lastFluidInjectionSite)
      if (result.fluidSessionCount > 0) {
        await _ref.read(profileProvider.notifier).refreshPrimaryPet();

        // Invalidate injection sites stats (fluid sessions logged)
        _ref.invalidate(injectionSitesStatsProvider);
      }

      // No manual invalidation: progress providers rebuild
      // via dailyCacheProvider

      if (kDebugMode) {
        debugPrint(
          '[LoggingNotifier] Invalidated week providers '
          'for immediate UI update',
        );
      }

      // STEP 6.5: Cancel notifications for logged sessions (non-blocking)
      // Use medicationRecentTimes map to iterate through logged medications
      // and cancel their notifications
      var totalCanceled = 0;
      var cancelErrors = 0;

      // Cancel medication notifications
      for (final entry in result.medicationRecentTimes.entries) {
        final medicationName = entry.key;
        final times = entry.value; // List<String> in ISO8601 format

        // Find matching schedule for this medication
        final matchingSchedule = allSchedules.firstWhere(
          (s) =>
              s.treatmentType == TreatmentType.medication &&
              s.medicationName == medicationName,
          orElse: () => allSchedules.first, // Placeholder, won't be used
        );

        // Skip if no matching schedule found
        if (matchingSchedule.treatmentType != TreatmentType.medication ||
            matchingSchedule.medicationName != medicationName) {
          continue;
        }

        // Cancel notifications for each logged time
        for (final timeStr in times) {
          try {
            final loggedTime = DateTime.parse(timeStr);
            final timeSlot = formatTimeSlotFromDateTime(loggedTime);

            // Access providers directly
            final plugin = _ref.read(reminderPluginProvider);
            final indexStore = _ref.read(notificationIndexStoreProvider);

            // Get entries for this slot
            final entries = await indexStore.getForToday(user.id, pet.id);
            final slotEntries = entries.where((e) {
              return e.scheduleId == matchingSchedule.id &&
                  e.timeSlotISO == timeSlot;
            }).toList();

            // Cancel each notification
            for (final entry in slotEntries) {
              try {
                await plugin.cancel(entry.notificationId);
                await indexStore.removeEntryBy(
                  user.id,
                  pet.id,
                  matchingSchedule.id,
                  timeSlot,
                  entry.kind,
                );
                totalCanceled++;
              } on Exception {
                // Continue with other notifications
              }
            }
          } on Exception {
            cancelErrors++;
            // Continue with other times
          }
        }
      }

      // Cancel fluid notifications if any were logged
      if (result.fluidSessionCount > 0) {
        final fluidSchedule = allSchedules.firstWhere(
          (s) => s.treatmentType == TreatmentType.fluid,
          orElse: () => allSchedules.first, // Placeholder
        );

        if (fluidSchedule.treatmentType == TreatmentType.fluid) {
          // Use the todaysReminderTimes to cancel all fluid reminders
          // (quick-log logs one catch-up session, but we cancel all reminders)
          final today = DateTime.now();
          for (final reminderTime in fluidSchedule.todaysReminderTimes(today)) {
            try {
              final timeSlot =
                  '${reminderTime.hour.toString().padLeft(2, '0')}:'
                  '${reminderTime.minute.toString().padLeft(2, '0')}';

              final plugin = _ref.read(reminderPluginProvider);
              final indexStore = _ref.read(notificationIndexStoreProvider);

              final entries = await indexStore.getForToday(user.id, pet.id);
              final slotEntries = entries.where((e) {
                return e.scheduleId == fluidSchedule.id &&
                    e.timeSlotISO == timeSlot;
              }).toList();

              for (final entry in slotEntries) {
                try {
                  await plugin.cancel(entry.notificationId);
                  await indexStore.removeEntryBy(
                    user.id,
                    pet.id,
                    fluidSchedule.id,
                    timeSlot,
                    entry.kind,
                  );
                  totalCanceled++;
                } on Exception {
                  // Continue
                }
              }
            } on Exception {
              cancelErrors++;
            }
          }
        }
      }

      // Track aggregated analytics for quick-log cancellations
      if (totalCanceled > 0 || cancelErrors > 0) {
        try {
          final analyticsService = _ref.read(analyticsServiceDirectProvider);
          await analyticsService.trackReminderCanceledOnLog(
            treatmentType: 'quick_log', // Special type for batch cancellation
            scheduleId: 'multiple', // Multiple schedules
            timeSlot: 'multiple', // Multiple time slots
            canceledCount: totalCanceled,
            result: cancelErrors > 0 ? 'partial_success' : 'success',
          );
        } on Exception {
          // Silent failure on analytics
        }
      }

      if (kDebugMode && totalCanceled > 0) {
        debugPrint(
          '[LoggingNotifier] Quick-log: Canceled $totalCanceled '
          'notification(s) with $cancelErrors error(s)',
        );
      }

      // STEP 7: Track analytics
      final analyticsService = _ref.read(analyticsServiceDirectProvider);

      // Count medication vs fluid sessions
      final medicationCount = result.medicationSessionCount;
      final fluidCount = result.fluidSessionCount;

      await analyticsService.trackQuickLogUsed(
        sessionCount: result.sessionCount,
        medicationCount: medicationCount,
        fluidCount: fluidCount,
        durationMs: DateTime.now().difference(quickLogStart).inMilliseconds,
      );

      if (kDebugMode) {
        debugPrint(
          '[LoggingNotifier] Quick-log complete: '
          '${result.sessionCount} sessions logged',
        );
      }

      state = state.copyWith(isLoading: false);
      return result.sessionCount;
    } on Exception catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _handleError(e),
      );

      // Error analytics tracked in service to avoid double-counting

      if (kDebugMode) {
        debugPrint('[LoggingNotifier] Quick-log error: $e');
      }

      return 0;
    }
  }

  // ============================================
  // Notification Refresh Throttling
  // ============================================

  /// Throttle notification refresh to avoid rapid successive calls.
  ///
  /// When users log multiple treatments back-to-back (e.g., 2 medications +
  /// fluid), we don't want to refresh 3 times. Instead, wait 500ms after the
  /// last log before refreshing once.
  void _throttleNotificationRefresh() {
    // Cancel pending refresh if one is scheduled
    _notificationRefreshTimer?.cancel();

    // Schedule a new refresh after delay
    _notificationRefreshTimer = Timer(_notificationRefreshDelay, () async {
      try {
        await _ref.read(notificationCoordinatorProvider).refreshAll();
        if (kDebugMode) {
          debugPrint('[LoggingProvider] Notifications refreshed successfully');
        }
      } on Exception catch (e) {
        if (kDebugMode) {
          debugPrint('[LoggingProvider] Notification refresh failed: $e');
        }
      }
    });
  }

  @override
  void dispose() {
    _notificationRefreshTimer?.cancel();
    super.dispose();
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

        try {
          await offlineService.enqueueOperation(operation);

          // Successfully queued - update local cache immediately
          // (optimistic UI)
          await _cacheService.updateCacheWithMedicationSession(
            userId: user.id,
            petId: pet.id,
            medicationName: session.medicationName,
            dosageGiven: session.dosageGiven,
            completed: session.completed,
            // Use scheduledTime when available so dashboard window matching
            // works
            dateTime: session.scheduledTime ?? session.dateTime,
          );

          await loadTodaysCache();

          state = state.copyWith(isLoading: false);

          if (kDebugMode) {
            debugPrint('[LoggingNotifier] Medication queued for sync');
          }

          return true;
        } on QueueWarningException catch (e) {
          // Operation succeeded but queue is getting full - show warning
          await _cacheService.updateCacheWithMedicationSession(
            userId: user.id,
            petId: pet.id,
            medicationName: session.medicationName,
            dosageGiven: session.dosageGiven,
            completed: session.completed,
            // Use scheduledTime when available so dashboard window matching
            // works
            dateTime: session.scheduledTime ?? session.dateTime,
          );

          await loadTodaysCache();

          state = state.copyWith(isLoading: false, error: e.userMessage);

          if (kDebugMode) {
            debugPrint(
              '[LoggingNotifier] Medication queued with warning: '
              '${e.userMessage}',
            );
          }

          return true; // Operation succeeded, just warn user
        } on QueueFullException catch (e) {
          // Queue is full - cannot queue
          state = state.copyWith(isLoading: false, error: e.userMessage);

          if (kDebugMode) {
            debugPrint(
              '[LoggingNotifier] Medication queueing failed: '
              '${e.userMessage}',
            );
          }

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

      // STEP 4: Call LoggingService (handles schedule matching)
      final sessionId = await _loggingService.logMedicationSession(
        userId: user.id,
        petId: pet.id,
        session: session,
        todaysSchedules: todaysSchedules,
        recentSessions: recentSessions,
      );

      // STEP 4.5: Throttle notification refresh (waits 500ms after last log)
      _throttleNotificationRefresh();

      // STEP 5: Update cache
      await _cacheService.updateCacheWithMedicationSession(
        userId: user.id,
        petId: pet.id,
        medicationName: session.medicationName,
        dosageGiven: session.dosageGiven,
        completed: session.completed,
        // Use scheduledTime when available so dashboard window matching works
        dateTime: session.scheduledTime ?? session.dateTime,
      );

      // Reload cache to get fresh data
      await loadTodaysCache();

      // Invalidate in-memory TTL cache to ensure calendar updates immediately
      _ref.read(summaryServiceProvider).clearAllCaches();

      // No manual invalidation: progress providers rebuild
      // via dailyCacheProvider

      if (kDebugMode) {
        debugPrint(
          '[LoggingNotifier] Invalidated week providers '
          'for immediate UI update',
        );
      }

      // STEP 5.5: Cancel notifications for matched schedule (non-blocking)
      // Note: LoggingService performs schedule matching internally and writes
      // the matched scheduleId/scheduledTime to Firestore, but doesn't return
      // them. We need to match the schedule again here to get those values.
      // This is acceptable since it's a simple in-memory operation.
      if (todaysSchedules.isNotEmpty) {
        // Find matching schedules by medication name
        final matchingSchedules = todaysSchedules.where((s) {
          return s.treatmentType == TreatmentType.medication &&
              s.medicationName == session.medicationName;
        }).toList();

        if (matchingSchedules.isNotEmpty) {
          // Find closest reminder time within ±2 hours (same logic as
          // LoggingService)
          DateTime? closestTime;
          String? matchedScheduleId;
          Duration? smallestDifference;

          for (final schedule in matchingSchedules) {
            for (final reminder in schedule.reminderTimes) {
              final reminderDateTime = DateTime(
                session.dateTime.year,
                session.dateTime.month,
                session.dateTime.day,
                reminder.hour,
                reminder.minute,
              );
              final difference = session.dateTime
                  .difference(reminderDateTime)
                  .abs();

              if (difference <= const Duration(hours: 2) &&
                  (smallestDifference == null ||
                      difference < smallestDifference)) {
                smallestDifference = difference;
                closestTime = reminderDateTime;
                matchedScheduleId = schedule.id;
              }
            }
          }

          // If matched, cancel notifications (non-blocking)
          if (matchedScheduleId != null && closestTime != null) {
            await _cancelNotificationsForSession(
              scheduleId: matchedScheduleId,
              scheduledTime: closestTime,
              treatmentType: 'medication',
              userId: user.id,
              petId: pet.id,
            );
          }
        }
      }

      // STEP 6: Track analytics
      final medStart = DateTime.now();
      final analyticsService = _ref.read(analyticsServiceDirectProvider);
      await analyticsService.trackSessionLogged(
        treatmentType: 'medication',
        sessionCount: 1,
        isQuickLog: false,
        adherenceStatus: session.completed ? 'complete' : 'partial',
        medicationName: session.medicationName,
        source: 'manual',
        durationMs: DateTime.now().difference(medStart).inMilliseconds,
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

      // Error analytics tracked in service to avoid double-counting

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

        try {
          await offlineService.enqueueOperation(operation);

          // Successfully queued - update local cache immediately (optimistic)
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
        } on QueueWarningException catch (e) {
          // Operation succeeded but queue is getting full - show warning
          await _cacheService.updateCacheWithFluidSession(
            userId: user.id,
            petId: pet.id,
            volumeGiven: session.volumeGiven,
          );

          await loadTodaysCache();

          state = state.copyWith(isLoading: false, error: e.userMessage);

          if (kDebugMode) {
            debugPrint(
              '[LoggingNotifier] Fluid queued with warning: '
              '${e.userMessage}',
            );
          }

          return true; // Operation succeeded, just warn user
        } on QueueFullException catch (e) {
          // Queue is full - cannot queue
          state = state.copyWith(isLoading: false, error: e.userMessage);

          if (kDebugMode) {
            debugPrint(
              '[LoggingNotifier] Fluid queueing failed: '
              '${e.userMessage}',
            );
          }

          return false;
        }
      }

      // STEP 3: Online - Log directly (handles schedule matching)
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

      // STEP 3.5: Throttle notification refresh (waits 500ms after last log)
      _throttleNotificationRefresh();

      // STEP 4: Update cache first (before invalidating providers)
      await _cacheService.updateCacheWithFluidSession(
        userId: user.id,
        petId: pet.id,
        volumeGiven: session.volumeGiven,
      );

      // Reload cache to get fresh data
      await loadTodaysCache();

      // Invalidate in-memory TTL cache to ensure calendar updates immediately
      _ref.read(summaryServiceProvider).clearAllCaches();

      // Refresh pet profile to update lastFluidInjectionSite in UI
      await _ref.read(profileProvider.notifier).refreshPrimaryPet();

      // No manual invalidation: progress providers rebuild
      // via dailyCacheProvider

      // Invalidate injection sites stats (new fluid session added)
      _ref.invalidate(injectionSitesStatsProvider);

      if (kDebugMode) {
        debugPrint(
          '[LoggingNotifier] Invalidated week providers '
          'for immediate UI update',
        );
      }

      // STEP 4.5: Cancel notifications for matched schedule (non-blocking)
      // Note: LoggingService performs schedule matching internally. For fluids,
      // we match to any fluid schedule within ±2 hours.
      if (fluidSchedule != null) {
        // Find closest reminder time within ±2 hours
        DateTime? closestTime;
        Duration? smallestDifference;

        for (final reminder in fluidSchedule.reminderTimes) {
          final reminderDateTime = DateTime(
            session.dateTime.year,
            session.dateTime.month,
            session.dateTime.day,
            reminder.hour,
            reminder.minute,
          );
          final difference = session.dateTime
              .difference(reminderDateTime)
              .abs();

          if (difference <= const Duration(hours: 2) &&
              (smallestDifference == null || difference < smallestDifference)) {
            smallestDifference = difference;
            closestTime = reminderDateTime;
          }
        }

        // If matched, cancel notifications (non-blocking)
        if (closestTime != null) {
          await _cancelNotificationsForSession(
            scheduleId: fluidSchedule.id,
            scheduledTime: closestTime,
            treatmentType: 'fluid',
            userId: user.id,
            petId: pet.id,
          );
        }
      }

      // STEP 5: Track analytics
      final fluidStart = DateTime.now();
      final analyticsService = _ref.read(analyticsServiceDirectProvider);
      await analyticsService.trackSessionLogged(
        treatmentType: 'fluid',
        sessionCount: 1,
        isQuickLog: false,
        adherenceStatus: 'complete',
        volumeGiven: session.volumeGiven,
        source: 'manual',
        durationMs: DateTime.now().difference(fluidStart).inMilliseconds,
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

      // Error analytics tracked in service to avoid double-counting

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

  // ============================================
  // Quick-Log Helper Methods
  // ============================================

  /// Check if there are remaining medications to log
  ///
  /// Compares the cache with active medication schedules to determine
  /// if any scheduled medication doses have not been logged yet today.
  ///
  /// For multi-dose schedules (e.g., twice-daily), checks each reminder time
  /// individually to see if a completed dose exists within the ±2h window.
  ///
  /// Returns true if at least one scheduled reminder time does not have a
  /// completed dose logged yet.
  bool _hasRemainingMedications(
    DailySummaryCache cache,
    List<Schedule> schedules,
  ) {
    final now = DateTime.now();
    for (final schedule in schedules) {
      if (!schedule.isActive) continue;
      if (!schedule.hasReminderTimeToday(now)) continue;

      final medicationName = schedule.medicationName;
      if (medicationName == null) continue;

      // Check each reminder time individually for multi-dose schedules
      final todaysReminders = schedule.todaysReminderTimes(now).toList();
      for (final reminderTime in todaysReminders) {
        // If this reminder time doesn't have a completed dose within ±2h,
        // we have remaining work
        if (!cache.hasMedicationCompletedNear(medicationName, reminderTime)) {
          return true;
        }
      }
    }
    return false;
  }

  /// Check if there is remaining fluid volume to log
  ///
  /// Compares the cache's logged fluid volume with the daily goal
  /// from the active fluid schedule.
  ///
  /// Returns true if logged volume < daily goal.
  bool _hasRemainingFluid(
    DailySummaryCache cache,
    Schedule? fluidSchedule,
  ) {
    if (fluidSchedule == null) return false;
    if (!fluidSchedule.isActive) return false;

    final now = DateTime.now();
    if (!fluidSchedule.hasReminderTimeToday(now)) return false;

    final dailyGoal = _calculateDailyFluidGoal(fluidSchedule, now);
    if (dailyGoal == null) return false;

    final alreadyLogged = cache.totalFluidVolumeGiven;
    return alreadyLogged < dailyGoal;
  }

  /// Calculate daily fluid goal from schedule
  ///
  /// Formula: targetVolume × number of reminders on the given date
  ///
  /// Returns null if schedule has no target volume or no reminders for date.
  double? _calculateDailyFluidGoal(Schedule schedule, DateTime date) {
    final targetVolume = schedule.targetVolume;
    if (targetVolume == null || targetVolume <= 0) return null;

    final reminderCount = schedule.reminderTimesOnDate(date).length;
    if (reminderCount == 0) return null;

    return targetVolume * reminderCount;
  }

  /// Cancel notifications for a successfully logged session
  ///
  /// Called after a session is successfully logged to cancel any pending
  /// notifications (initial, follow-up, snooze) for the matched time slot.
  ///
  /// This method:
  /// 1. Validates that the session matched a schedule (has scheduleId and
  ///    scheduledTime)
  /// 2. Converts scheduledTime to "HH:mm" format
  /// 3. Calls ReminderService.cancelSlot() to cancel notifications
  /// 4. Tracks analytics (success or error)
  /// 5. Logs errors silently without throwing (non-blocking)
  ///
  /// Error handling: All exceptions are caught and logged with analytics.
  /// The method never throws, ensuring that successful logging operations
  /// are not blocked by notification cancellation failures.
  ///
  /// Parameters:
  /// - [scheduleId]: Schedule ID that the session matched to (from
  ///   LoggingService)
  /// - [scheduledTime]: Scheduled time that was matched (from LoggingService)
  /// - [treatmentType]: Type of treatment ('medication' or 'fluid')
  /// - [userId]: Current user ID
  /// - [petId]: Current pet ID
  ///
  /// Returns: void (errors logged silently)
  Future<void> _cancelNotificationsForSession({
    required String scheduleId,
    required DateTime scheduledTime,
    required String treatmentType,
    required String userId,
    required String petId,
  }) async {
    try {
      final timeSlot = formatTimeSlotFromDateTime(scheduledTime);

      if (kDebugMode) {
        debugPrint(
          '[LoggingNotifier] Canceling notifications for '
          '$treatmentType at $timeSlot (schedule: $scheduleId)',
        );
      }

      // Access plugin and indexStore directly to avoid WidgetRef type issue
      final plugin = _ref.read(reminderPluginProvider);
      final indexStore = _ref.read(notificationIndexStoreProvider);

      // Get all index entries for this schedule + timeSlot
      final entries = await indexStore.getForToday(userId, petId);
      final slotEntries = entries.where((e) {
        return e.scheduleId == scheduleId && e.timeSlotISO == timeSlot;
      }).toList();

      var canceledCount = 0;

      // Cancel all kinds (initial, followup, snooze)
      for (final entry in slotEntries) {
        try {
          await plugin.cancel(entry.notificationId);
          await indexStore.removeEntryBy(
            userId,
            petId,
            scheduleId,
            timeSlot,
            entry.kind,
          );
          canceledCount++;
        } on Exception catch (e) {
          if (kDebugMode) {
            debugPrint(
              '[LoggingNotifier] Error canceling notification '
              '${entry.notificationId}: $e',
            );
          }
          // Continue canceling other notifications
        }
      }

      // Track analytics
      final analyticsService = _ref.read(analyticsServiceDirectProvider);
      await analyticsService.trackReminderCanceledOnLog(
        treatmentType: treatmentType,
        scheduleId: scheduleId,
        timeSlot: timeSlot,
        canceledCount: canceledCount,
        result: canceledCount > 0 ? 'success' : 'none_found',
      );

      if (kDebugMode) {
        debugPrint(
          '[LoggingNotifier] Canceled $canceledCount notification(s) '
          'for $timeSlot',
        );
      }
    } on Exception catch (e) {
      // Silent error logging - don't block successful logging operation
      if (kDebugMode) {
        debugPrint(
          '[LoggingNotifier] Error canceling notifications: $e',
        );
      }

      // Track error in analytics
      try {
        final analyticsService = _ref.read(analyticsServiceDirectProvider);
        await analyticsService.trackReminderCanceledOnLog(
          treatmentType: treatmentType,
          scheduleId: scheduleId,
          timeSlot: formatTimeSlotFromDateTime(scheduledTime),
          canceledCount: 0,
          result: 'error',
        );
      } on Exception {
        // Silent failure on analytics - don't compound errors
      }
    }
  }

  /// Convert exceptions to user-friendly error messages
  ///
  /// Maps technical exceptions to user-facing strings that:
  /// - Are empathetic and helpful
  /// - Don't expose technical details
  /// - Suggest next actions when appropriate
  String _handleError(Object error) {
    // Use userMessage getter from LoggingException subclasses
    if (error is LoggingException) {
      return error.userMessage;
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
