/// Riverpod providers for editing treatment sessions from progress calendar
///
/// This file contains providers for:
/// - Progress edit state management (ProgressEditNotifier)
/// - Session update operations with optimistic updates
/// - Cache invalidation for weekSessionsProvider and dailyCacheProvider
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/core/utils/date_utils.dart';
import 'package:hydracat/features/logging/models/fluid_session.dart';
import 'package:hydracat/features/logging/models/logging_operation.dart';
import 'package:hydracat/features/logging/models/medication_session.dart';
import 'package:hydracat/features/progress/providers/injection_sites_provider.dart';
import 'package:hydracat/providers/auth_provider.dart';
import 'package:hydracat/providers/connectivity_provider.dart';
import 'package:hydracat/providers/logging_provider.dart';
import 'package:hydracat/providers/logging_queue_provider.dart';
import 'package:hydracat/providers/profile_provider.dart';
import 'package:hydracat/providers/progress_provider.dart';
import 'package:uuid/uuid.dart';

// ============================================
// Progress Edit State
// ============================================

/// State for progress edit operations
class ProgressEditState {
  /// Creates a [ProgressEditState]
  const ProgressEditState({
    this.isLoading = false,
    this.error,
  });

  /// Whether an edit operation is in progress
  final bool isLoading;

  /// Error message if edit failed
  final String? error;

  /// Copy with new values
  ProgressEditState copyWith({
    bool? isLoading,
    String? error,
  }) {
    return ProgressEditState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Clear error
  ProgressEditState clearError() {
    return ProgressEditState(
      isLoading: isLoading,
    );
  }
}

/// Provider for progress edit state
final progressEditProvider =
    StateNotifierProvider<ProgressEditNotifier, ProgressEditState>((ref) {
  return ProgressEditNotifier(ref);
});

/// Notifier for managing progress edit operations
///
/// Handles:
/// - Session updates with optimistic UI patterns
/// - Offline queuing via OfflineLoggingService
/// - Cache invalidation for calendar and summaries
/// - Error state management
class ProgressEditNotifier extends StateNotifier<ProgressEditState> {
  /// Creates a [ProgressEditNotifier]
  ProgressEditNotifier(this._ref) : super(const ProgressEditState());

  final Ref _ref;

  /// Update a medication session
  ///
  /// Uses optimistic update pattern: update cache immediately, then sync to
  /// Firestore. Shows error message on failure.
  ///
  /// Returns true if successful, false otherwise.
  Future<bool> updateMedicationSession({
    required MedicationSession oldSession,
    required MedicationSession newSession,
  }) async {
    state = state.copyWith(isLoading: true);

    try {
      final user = _ref.read(currentUserProvider);
      final pet = _ref.read(primaryPetProvider);
      if (user == null || pet == null) {
        throw Exception('User or pet not found');
      }

      // Check connectivity
      final isOnline = _ref.read(isConnectedProvider);

      if (!isOnline) {
        // Offline: queue operation
        if (kDebugMode) {
          debugPrint('[ProgressEdit] Offline - queueing medication update');
        }
        await _queueMedicationUpdate(
          user.id,
          pet.id,
          oldSession,
          newSession,
        );
      } else {
        // Online: direct update
        if (kDebugMode) {
          debugPrint('[ProgressEdit] Online - updating medication session');
        }
        await _ref.read(loggingServiceProvider).updateMedicationSession(
              userId: user.id,
              petId: pet.id,
              oldSession: oldSession,
              newSession: newSession,
            );
      }

      // Invalidate caches to trigger UI refresh
      _invalidateCaches(oldSession.dateTime);

      state = state.copyWith(isLoading: false);
      return true;
    } on Exception catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('[ProgressEdit] Error updating medication: $e');
        debugPrint('Stack trace: $stackTrace');
      }

      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update medication: $e',
      );
      return false;
    }
  }

  /// Update a fluid session
  ///
  /// Uses optimistic update pattern: update cache immediately, then sync to
  /// Firestore. Shows error message on failure.
  ///
  /// Returns true if successful, false otherwise.
  Future<bool> updateFluidSession({
    required FluidSession oldSession,
    required FluidSession newSession,
  }) async {
    state = state.copyWith(isLoading: true);

    try {
      final user = _ref.read(currentUserProvider);
      final pet = _ref.read(primaryPetProvider);
      if (user == null || pet == null) {
        throw Exception('User or pet not found');
      }

      // Check connectivity
      final isOnline = _ref.read(isConnectedProvider);

      if (!isOnline) {
        // Offline: queue operation
        if (kDebugMode) {
          debugPrint('[ProgressEdit] Offline - queueing fluid update');
        }
        await _queueFluidUpdate(
          user.id,
          pet.id,
          oldSession,
          newSession,
        );
      } else {
        // Online: direct update
        if (kDebugMode) {
          debugPrint('[ProgressEdit] Online - updating fluid session');
        }
        await _ref.read(loggingServiceProvider).updateFluidSession(
              userId: user.id,
              petId: pet.id,
              oldSession: oldSession,
              newSession: newSession,
            );
      }

      // Invalidate caches to trigger UI refresh
      _invalidateCaches(oldSession.dateTime);

      state = state.copyWith(isLoading: false);
      return true;
    } on Exception catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('[ProgressEdit] Error updating fluid: $e');
        debugPrint('Stack trace: $stackTrace');
      }

      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update fluid therapy: $e',
      );
      return false;
    }
  }

  /// Queue medication update for offline sync
  Future<void> _queueMedicationUpdate(
    String userId,
    String petId,
    MedicationSession oldSession,
    MedicationSession newSession,
  ) async {
    final operation = UpdateMedicationOperation(
      id: const Uuid().v4(),
      userId: userId,
      petId: petId,
      createdAt: DateTime.now(),
      oldSession: oldSession,
      newSession: newSession,
    );

    await _ref
        .read(offlineLoggingServiceProvider)
        .enqueueOperation(operation);
  }

  /// Queue fluid update for offline sync
  Future<void> _queueFluidUpdate(
    String userId,
    String petId,
    FluidSession oldSession,
    FluidSession newSession,
  ) async {
    final operation = UpdateFluidOperation(
      id: const Uuid().v4(),
      userId: userId,
      petId: petId,
      createdAt: DateTime.now(),
      oldSession: oldSession,
      newSession: newSession,
    );

    await _ref
        .read(offlineLoggingServiceProvider)
        .enqueueOperation(operation);
  }

  /// Invalidate relevant caches to trigger UI refresh
  ///
  /// Invalidates:
  /// - SummaryService internal memory cache (for fresh Firestore reads)
  /// - dailyCacheProvider (for today's summary on dashboard/calendar)
  /// - weekSessionsProvider (for the week containing the edited session)
  /// - weekSummariesProvider (for progress bars and daily summaries)
  void _invalidateCaches(DateTime sessionDate) {
    if (kDebugMode) {
      debugPrint('[ProgressEdit] Invalidating caches for $sessionDate');
    }

    // CRITICAL: Clear SummaryService internal TTL cache first
    // This ensures Firestore is queried for fresh data on next provider read
    _ref.read(summaryServiceProvider).clearMemoryCache();

    // Invalidate daily cache (triggers cascade refresh of summaries)
    _ref.invalidate(dailyCacheProvider);

    // Invalidate week sessions and summaries for the week containing this date
    final weekStart = AppDateUtils.startOfWeekMonday(sessionDate);
    _ref
      ..invalidate(weekSessionsProvider(weekStart))
      ..invalidate(weekSummariesProvider(weekStart))
      ..invalidate(injectionSitesStatsProvider);

    if (kDebugMode) {
      debugPrint('[ProgressEdit] Cache invalidation complete');
    }
  }

  /// Clear error state
  void clearError() {
    state = state.clearError();
  }
}
