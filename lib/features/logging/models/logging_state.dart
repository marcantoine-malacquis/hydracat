// Required for withMode() and reset() methods where null values are
// explicitly passed to clear existing data
// ignore_for_file: avoid_redundant_argument_values

import 'package:flutter/foundation.dart';
import 'package:hydracat/features/logging/models/daily_summary_cache.dart';
import 'package:hydracat/features/logging/models/logging_mode.dart';
import 'package:hydracat/features/logging/models/treatment_choice.dart';

/// Sentinel value for [LoggingState.copyWith] to distinguish between
/// "not provided" and "explicitly set to null"
const _undefined = Object();

/// Immutable state for the logging feature
///
/// Manages the state of the logging flow including current mode, treatment
/// choice, cached daily summary, loading state, and errors. This will be
/// used by LoggingNotifier (StateNotifier) in Phase 2.
///
/// Follows the same pattern as OnboardingState with immutable data,
/// copyWith methods, and factory constructors for common states.
@immutable
class LoggingState {
  /// Creates a [LoggingState] instance
  const LoggingState({
    this.loggingMode,
    this.treatmentChoice,
    this.dailyCache,
    this.isLoading = false,
    this.error,
  });

  /// Creates initial empty state
  ///
  /// Use this when initializing the logging feature before any user
  /// interaction has occurred.
  const LoggingState.initial()
      : loggingMode = null,
        treatmentChoice = null,
        dailyCache = null,
        isLoading = false,
        error = null;

  /// Creates loading state
  ///
  /// Use this when performing async operations like fetching schedules,
  /// saving sessions, or loading cache data.
  const LoggingState.loading()
      : loggingMode = null,
        treatmentChoice = null,
        dailyCache = null,
        isLoading = true,
        error = null;

  /// Current logging mode (manual or quick-log)
  ///
  /// Determines UI presentation, field requirements, and navigation flow.
  /// Set when user enters the logging flow.
  final LoggingMode? loggingMode;

  /// Current treatment choice (medication or fluid)
  ///
  /// Only relevant for users with combined treatment personas. Set when
  /// user selects which type of treatment to log. Null for single-treatment
  /// personas who skip this selection.
  final TreatmentChoice? treatmentChoice;

  /// Cached daily summary for today
  ///
  /// Provides instant access to today's logging activity without Firestore
  /// reads. Updated automatically when sessions are logged. Null if cache
  /// hasn't been loaded yet or if it's expired.
  final DailySummaryCache? dailyCache;

  /// Whether an async operation is in progress
  ///
  /// Set to true during operations like:
  /// - Loading cache from SharedPreferences
  /// - Fetching schedule data from Firestore
  /// - Saving session to Firestore
  /// - Updating cache after successful save
  final bool isLoading;

  /// Current error message if any
  ///
  /// Populated when operations fail (e.g., network error, validation error,
  /// save failure). Null when no error exists.
  final String? error;

  // Computed properties

  /// Whether logging mode has been selected
  bool get hasModeSelected => loggingMode != null;

  /// Whether treatment choice has been made (for combined personas)
  bool get hasTreatmentChoice => treatmentChoice != null;

  /// Whether there's an error
  bool get hasError => error != null;

  /// Whether the state is ready for logging (mode selected, no loading/errors)
  bool get isReadyForLogging =>
      hasModeSelected && !isLoading && !hasError;

  /// Whether quick-log mode is active
  bool get isQuickLogMode => loggingMode == LoggingMode.quickLog;

  /// Whether manual mode is active
  bool get isManualMode => loggingMode == LoggingMode.manual;

  /// Whether user chose medication logging
  bool get isMedicationLogging => treatmentChoice == TreatmentChoice.medication;

  /// Whether user chose fluid logging
  bool get isFluidLogging => treatmentChoice == TreatmentChoice.fluid;

  /// Whether cache is available and valid
  bool get hasCacheData => dailyCache != null;

  // State mutation methods

  /// Creates a copy of this [LoggingState] with the given fields replaced
  LoggingState copyWith({
    Object? loggingMode = _undefined,
    Object? treatmentChoice = _undefined,
    Object? dailyCache = _undefined,
    bool? isLoading,
    Object? error = _undefined,
  }) {
    return LoggingState(
      loggingMode: loggingMode == _undefined 
          ? this.loggingMode 
          : loggingMode as LoggingMode?,
      treatmentChoice: treatmentChoice == _undefined 
          ? this.treatmentChoice 
          : treatmentChoice as TreatmentChoice?,
      dailyCache: dailyCache == _undefined 
          ? this.dailyCache 
          : dailyCache as DailySummaryCache?,
      isLoading: isLoading ?? this.isLoading,
      error: error == _undefined ? this.error : error as String?,
    );
  }

  /// Creates a copy with error cleared
  LoggingState clearError() {
    return copyWith(error: null);
  }

  /// Creates a copy with loading state updated
  LoggingState withLoading({required bool loading}) {
    return copyWith(isLoading: loading);
  }

  /// Creates a copy with mode set and other fields reset
  ///
  /// Use this when user enters the logging flow and selects a mode.
  /// Clears treatment choice and errors to start fresh.
  LoggingState withMode(LoggingMode mode) {
    return LoggingState(
      loggingMode: mode,
      treatmentChoice: null, // Reset choice when mode changes
      dailyCache: dailyCache, // Preserve cache
      isLoading: false,
      error: null,
    );
  }

  /// Creates a copy with treatment choice set
  ///
  /// Use this when user selects medication vs fluid for combined personas.
  LoggingState withTreatmentChoice(TreatmentChoice choice) {
    return copyWith(
      treatmentChoice: choice,
      error: null, // Clear any previous errors
    );
  }

  /// Creates a copy with updated cache
  ///
  /// Use this after successfully logging a session to update the cache.
  LoggingState withCache(DailySummaryCache cache) {
    return copyWith(
      dailyCache: cache,
      error: null, // Clear errors on successful cache update
    );
  }

  /// Resets to initial state
  ///
  /// Use this when exiting the logging flow or completing a session.
  LoggingState reset() {
    return LoggingState(
      loggingMode: null,
      treatmentChoice: null,
      dailyCache: dailyCache, // Preserve cache across resets
      isLoading: false,
      error: null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LoggingState &&
        other.loggingMode == loggingMode &&
        other.treatmentChoice == treatmentChoice &&
        other.dailyCache == dailyCache &&
        other.isLoading == isLoading &&
        other.error == error;
  }

  @override
  int get hashCode {
    return Object.hash(
      loggingMode,
      treatmentChoice,
      dailyCache,
      isLoading,
      error,
    );
  }

  @override
  String toString() {
    return 'LoggingState('
        'loggingMode: $loggingMode, '
        'treatmentChoice: $treatmentChoice, '
        'dailyCache: $dailyCache, '
        'isLoading: $isLoading, '
        'error: $error'
        ')';
  }
}
