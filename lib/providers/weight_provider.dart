import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/features/auth/models/auth_state.dart';
import 'package:hydracat/features/health/exceptions/health_exceptions.dart';
import 'package:hydracat/features/health/models/health_parameter.dart';
import 'package:hydracat/features/health/models/weight_data_point.dart';
import 'package:hydracat/features/health/services/weight_cache_service.dart';
import 'package:hydracat/features/health/services/weight_service.dart';
import 'package:hydracat/providers/analytics_provider.dart';
import 'package:hydracat/providers/auth_provider.dart';
import 'package:hydracat/providers/profile_provider.dart';
import 'package:hydracat/providers/weight_unit_provider.dart';

/// Provider for WeightService instance
final weightServiceProvider = Provider<WeightService>((ref) {
  return WeightService();
});

/// State class for weight data
@immutable
class WeightState {
  /// Creates a [WeightState]
  const WeightState({
    this.graphData = const [],
    this.historyEntries = const [],
    this.latestWeight,
    this.isLoading = false,
    this.isRefreshing = false,
    this.error,
    this.hasMore = true,
    this.lastDocument,
  });

  /// Weight data points for line chart rendering (from monthly summaries)
  final List<WeightDataPoint> graphData;

  /// Paginated weight entries list for history display
  final List<HealthParameter> historyEntries;

  /// Current weight for stats card (from latest monthly summary)
  final double? latestWeight;

  /// Initial data load state
  final bool isLoading;

  /// Manual refresh state (separate from initial load)
  final bool isRefreshing;

  /// Error state with user-friendly messages
  final HealthException? error;

  /// Pagination flag - true if more entries available
  final bool hasMore;

  /// Firestore pagination cursor for loading more entries
  final DocumentSnapshot? lastDocument;

  /// Creates a copy with updated fields
  WeightState copyWith({
    List<WeightDataPoint>? graphData,
    List<HealthParameter>? historyEntries,
    double? latestWeight,
    bool? isLoading,
    bool? isRefreshing,
    HealthException? error,
    bool? hasMore,
    DocumentSnapshot? lastDocument,
    bool clearError = false,
    bool clearLatestWeight = false,
    bool clearLastDocument = false,
  }) {
    return WeightState(
      graphData: graphData ?? this.graphData,
      historyEntries: historyEntries ?? this.historyEntries,
      latestWeight: clearLatestWeight
          ? null
          : (latestWeight ?? this.latestWeight),
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      error: clearError ? null : error,
      hasMore: hasMore ?? this.hasMore,
      lastDocument: clearLastDocument
          ? null
          : (lastDocument ?? this.lastDocument),
    );
  }

  /// Helper to reset error state
  WeightState clearError() {
    return copyWith(clearError: true);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeightState &&
          runtimeType == other.runtimeType &&
          graphData == other.graphData &&
          historyEntries == other.historyEntries &&
          latestWeight == other.latestWeight &&
          isLoading == other.isLoading &&
          isRefreshing == other.isRefreshing &&
          error == other.error &&
          hasMore == other.hasMore &&
          lastDocument == other.lastDocument;

  @override
  int get hashCode => Object.hash(
        graphData,
        historyEntries,
        latestWeight,
        isLoading,
        isRefreshing,
        error,
        hasMore,
        lastDocument,
      );
}

/// Notifier for managing weight state
class WeightNotifier extends StateNotifier<WeightState> {
  /// Creates a [WeightNotifier] with service injection
  WeightNotifier(this._service, this._ref) : super(const WeightState());

  final WeightService _service;
  final Ref _ref;

  // ============================================
  // CORE DATA LOADING
  // ============================================

  /// Loads initial data (graph + latest weight + first page of history)
  ///
  /// Uses cache for graph data to minimize Firebase reads:
  /// - Check cache first for graph data
  /// - If cache hit: use cached data (0 reads)
  /// - If cache miss: fetch from Firebase and cache (12 reads)
  /// - Always fetch latest weight and history (not cached)
  Future<void> loadInitialData() async {
    final authState = _ref.read(authProvider);
    final primaryPet = _ref.read(profileProvider).primaryPet;

    if (authState is! AuthStateAuthenticated || primaryPet == null) {
      state = state.copyWith(
        error: const HealthException('No user or pet selected'),
        isLoading: false,
      );
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final userId = authState.user.id;
      final petId = primaryPet.id;

      // Try to get graph data from cache first
      final cachedGraphData = WeightCacheService.getCachedGraphData(
        userId: userId,
        petId: petId,
      );

      List<WeightDataPoint> graphData;
      if (cachedGraphData != null) {
        // Cache hit - use cached data (0 Firebase reads)
        if (kDebugMode) {
          debugPrint('[WeightProvider] Using cached graph data');
        }
        graphData = cachedGraphData;
      } else {
        // Cache miss - fetch from Firebase
        if (kDebugMode) {
          debugPrint('[WeightProvider] Fetching graph data from Firebase');
        }
        graphData = await _service.getWeightGraphData(
          userId: userId,
          petId: petId,
        );

        // Store in cache for next time (1-hour TTL)
        WeightCacheService.setCachedGraphData(
          userId: userId,
          petId: petId,
          dataPoints: graphData,
        );
      }

      // Fetch latest weight and history (not cached)
      final results = await Future.wait([
        _service.getLatestWeight(
          userId: userId,
          petId: petId,
        ),
        _service.getWeightHistory(
          userId: userId,
          petId: petId,
        ),
      ]);

      final latestWeight = results[0] as double?;
      final historyEntries = results[1]! as List<HealthParameter>;

      state = state.copyWith(
        graphData: graphData,
        latestWeight: latestWeight,
        historyEntries: historyEntries,
        hasMore: historyEntries.length == 50,
        isLoading: false,
        clearLastDocument: true,
      );

      // Track analytics event
      final analytics = _ref.read(analyticsServiceDirectProvider);
      await analytics.trackScreenView(screenName: 'weight_tracking');
    } on HealthException catch (e) {
      if (kDebugMode) {
        debugPrint('[WeightProvider] Health exception: ${e.message}');
      }
      state = state.copyWith(
        error: e,
        isLoading: false,
      );
    } on Exception catch (e) {
      if (kDebugMode) {
        debugPrint('[WeightProvider] Error loading data: $e');
      }
      state = state.copyWith(
        error: const HealthException('Failed to load weight data'),
        isLoading: false,
      );
    }
  }

  /// Refreshes all data (manual refresh)
  ///
  /// Invalidates cache and re-fetches everything.
  /// Does NOT clear existing data if refresh fails.
  Future<void> refreshData() async {
    final authState = _ref.read(authProvider);
    final primaryPet = _ref.read(profileProvider).primaryPet;

    if (authState is! AuthStateAuthenticated || primaryPet == null) {
      return;
    }

    state = state.copyWith(isRefreshing: true, clearError: true);

    try {
      // Invalidate cache to force fresh data
      WeightCacheService.invalidateCache();

      final userId = authState.user.id;
      final petId = primaryPet.id;

      // Fetch fresh graph data
      final graphData = await _service.getWeightGraphData(
        userId: userId,
        petId: petId,
      );

      // Update cache
      WeightCacheService.setCachedGraphData(
        userId: userId,
        petId: petId,
        dataPoints: graphData,
      );

      // Fetch latest weight and first page of history
      final results = await Future.wait([
        _service.getLatestWeight(
          userId: userId,
          petId: petId,
        ),
        _service.getWeightHistory(
          userId: userId,
          petId: petId,
        ),
      ]);

      final latestWeight = results[0] as double?;
      final historyEntries = results[1]! as List<HealthParameter>;

      state = state.copyWith(
        graphData: graphData,
        latestWeight: latestWeight,
        historyEntries: historyEntries,
        hasMore: historyEntries.length == 50,
        isRefreshing: false,
        clearLastDocument: true,
      );

      // Track analytics event
      final analytics = _ref.read(analyticsServiceDirectProvider);
      await analytics.trackFeatureUsed(featureName: 'weight_data_refreshed');
    } on HealthException catch (e) {
      if (kDebugMode) {
        debugPrint('[WeightProvider] Refresh failed: ${e.message}');
      }
      // Don't clear existing data on error
      state = state.copyWith(
        error: e,
        isRefreshing: false,
      );
    } on Exception catch (e) {
      if (kDebugMode) {
        debugPrint('[WeightProvider] Refresh failed: $e');
      }
      state = state.copyWith(
        error: const HealthException('Failed to refresh weight data'),
        isRefreshing: false,
      );
    }
  }

  /// Loads more history entries (pagination)
  ///
  /// Fetches next 50 entries using lastDocument cursor.
  /// Called when user taps "Load More" button.
  Future<void> loadMoreHistory() async {
    if (state.isLoading || !state.hasMore) {
      return;
    }

    final authState = _ref.read(authProvider);
    final primaryPet = _ref.read(profileProvider).primaryPet;

    if (authState is! AuthStateAuthenticated || primaryPet == null) {
      return;
    }

    if (state.historyEntries.isEmpty) {
      return;
    }

    state = state.copyWith(isLoading: true);

    try {
      final moreEntries = await _service.getWeightHistory(
        userId: authState.user.id,
        petId: primaryPet.id,
        startAfterDoc: state.lastDocument,
      );

      state = state.copyWith(
        historyEntries: [...state.historyEntries, ...moreEntries],
        hasMore: moreEntries.length == 50,
        isLoading: false,
      );

      // Track analytics event
      final analytics = _ref.read(analyticsServiceDirectProvider);
      await analytics.trackFeatureUsed(featureName: 'weight_history_paginated');
    } on HealthException catch (e) {
      if (kDebugMode) {
        debugPrint('[WeightProvider] Load more failed: ${e.message}');
      }
      state = state.copyWith(
        error: e,
        isLoading: false,
      );
    } on Exception catch (e) {
      if (kDebugMode) {
        debugPrint('[WeightProvider] Load more failed: $e');
      }
      state = state.copyWith(
        error: const HealthException('Failed to load more entries'),
        isLoading: false,
      );
    }
  }

  // ============================================
  // CRUD OPERATIONS
  // ============================================

  /// Logs a new weight entry
  ///
  /// Validates inputs, writes to Firebase, invalidates cache,
  /// and refreshes data.
  /// Returns true if successful, false if validation or write fails.
  Future<bool> logWeight({
    required DateTime date,
    required double weightKg,
    String? notes,
  }) async {
    final authState = _ref.read(authProvider);
    final primaryPet = _ref.read(profileProvider).primaryPet;

    if (authState is! AuthStateAuthenticated || primaryPet == null) {
      state = state.copyWith(
        error: const HealthException('No user or pet selected'),
      );
      return false;
    }

    try {
      await _service.logWeight(
        userId: authState.user.id,
        petId: primaryPet.id,
        date: date,
        weightKg: weightKg,
        notes: notes,
      );

      // Invalidate cache since data changed
      WeightCacheService.invalidateCache();

      // Reload data (will fetch fresh from Firebase)
      await loadInitialData();

      // Track analytics event
      final currentUnit = _ref.read(weightUnitProvider);
      final analytics = _ref.read(analyticsServiceDirectProvider);
      await analytics.trackFeatureUsed(
        featureName: 'weight_logged',
        additionalParams: {
          'unit': currentUnit,
          'has_notes': notes != null,
          'pet_id': primaryPet.id,
        },
      );

      return true;
    } on WeightValidationException catch (e) {
      if (kDebugMode) {
        debugPrint('[WeightProvider] Validation error: ${e.message}');
      }
      state = state.copyWith(error: e);
      return false;
    } on WeightServiceException catch (e) {
      if (kDebugMode) {
        debugPrint('[WeightProvider] Service error: ${e.message}');
      }
      state = state.copyWith(error: e);
      return false;
    } on Exception catch (e) {
      if (kDebugMode) {
        debugPrint('[WeightProvider] Unexpected error: $e');
      }
      state = state.copyWith(
        error: const HealthException('Failed to log weight'),
      );
      return false;
    }
  }

  /// Updates an existing weight entry
  ///
  /// Validates inputs, updates in Firebase, invalidates cache,
  /// and refreshes data.
  /// Returns true if successful, false if validation or update fails.
  Future<bool> updateWeight({
    required DateTime oldDate,
    required double oldWeightKg,
    required DateTime newDate,
    required double newWeightKg,
    String? newNotes,
  }) async {
    final authState = _ref.read(authProvider);
    final primaryPet = _ref.read(profileProvider).primaryPet;

    if (authState is! AuthStateAuthenticated || primaryPet == null) {
      state = state.copyWith(
        error: const HealthException('No user or pet selected'),
      );
      return false;
    }

    try {
      await _service.updateWeight(
        userId: authState.user.id,
        petId: primaryPet.id,
        oldDate: oldDate,
        oldWeightKg: oldWeightKg,
        newDate: newDate,
        newWeightKg: newWeightKg,
        newNotes: newNotes,
      );

      // Invalidate cache since data changed
      WeightCacheService.invalidateCache();

      // Reload data (will fetch fresh from Firebase)
      await loadInitialData();

      // Track analytics event
      final dateChanged = !oldDate.isAtSameMomentAs(newDate);
      final weightChanged = oldWeightKg != newWeightKg;
      final analytics = _ref.read(analyticsServiceDirectProvider);
      await analytics.trackFeatureUsed(
        featureName: 'weight_updated',
        additionalParams: {
          'date_changed': dateChanged,
          'weight_changed': weightChanged,
          'pet_id': primaryPet.id,
        },
      );

      return true;
    } on WeightValidationException catch (e) {
      if (kDebugMode) {
        debugPrint('[WeightProvider] Validation error: ${e.message}');
      }
      state = state.copyWith(error: e);
      return false;
    } on WeightServiceException catch (e) {
      if (kDebugMode) {
        debugPrint('[WeightProvider] Service error: ${e.message}');
      }
      state = state.copyWith(error: e);
      return false;
    } on Exception catch (e) {
      if (kDebugMode) {
        debugPrint('[WeightProvider] Unexpected error: $e');
      }
      state = state.copyWith(
        error: const HealthException('Failed to update weight'),
      );
      return false;
    }
  }

  /// Deletes a weight entry
  ///
  /// Removes from Firebase, invalidates cache, and refreshes data.
  /// Returns true if successful, false if deletion fails.
  Future<bool> deleteWeight({required DateTime date}) async {
    final authState = _ref.read(authProvider);
    final primaryPet = _ref.read(profileProvider).primaryPet;

    if (authState is! AuthStateAuthenticated || primaryPet == null) {
      state = state.copyWith(
        error: const HealthException('No user or pet selected'),
      );
      return false;
    }

    try {
      await _service.deleteWeight(
        userId: authState.user.id,
        petId: primaryPet.id,
        date: date,
      );

      // Invalidate cache since data changed
      WeightCacheService.invalidateCache();

      // Reload data (will fetch fresh from Firebase)
      await loadInitialData();

      // Track analytics event
      final analytics = _ref.read(analyticsServiceDirectProvider);
      await analytics.trackFeatureUsed(
        featureName: 'weight_deleted',
        additionalParams: {
          'pet_id': primaryPet.id,
        },
      );

      return true;
    } on WeightServiceException catch (e) {
      if (kDebugMode) {
        debugPrint('[WeightProvider] Service error: ${e.message}');
      }
      state = state.copyWith(error: e);
      return false;
    } on Exception catch (e) {
      if (kDebugMode) {
        debugPrint('[WeightProvider] Unexpected error: $e');
      }
      state = state.copyWith(
        error: const HealthException('Failed to delete weight'),
      );
      return false;
    }
  }
}

/// Provider for weight state
final weightProvider =
    StateNotifierProvider<WeightNotifier, WeightState>((ref) {
  return WeightNotifier(
    ref.watch(weightServiceProvider),
    ref,
  );
});
