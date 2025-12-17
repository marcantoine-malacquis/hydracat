import 'package:flutter/foundation.dart';
import 'package:hydracat/features/qol/models/qol_assessment.dart';

/// Sentinel value for [QolState.copyWith] to distinguish between
/// "not provided" and "explicitly set to null"
const _undefined = Object();

/// Immutable state for the QoL feature.
///
/// Manages:
/// - Current assessment (latest)
/// - Recent assessments list (cached)
/// - Loading/saving states
/// - Error handling
/// - Cache TTL tracking
@immutable
class QolState {
  /// Creates a [QolState] instance.
  const QolState({
    this.currentAssessment,
    this.recentAssessments = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.lastFetchTime,
  });

  /// Creates initial loading state.
  const QolState.initial()
      : currentAssessment = null,
        recentAssessments = const [],
        isLoading = true,
        isSaving = false,
        error = null,
        lastFetchTime = null;

  /// Latest QoL assessment (most recent).
  ///
  /// Used by home screen card for quick display without additional reads.
  /// Null if no assessments exist yet.
  final QolAssessment? currentAssessment;

  /// Recent assessments list (up to 20, cached).
  ///
  /// Ordered by date descending (newest first).
  /// Used by history screen and trend charts.
  final List<QolAssessment> recentAssessments;

  /// Whether initial data load is in progress.
  final bool isLoading;

  /// Whether save/update operation is in progress.
  final bool isSaving;

  /// Current error message if any.
  final String? error;

  /// Timestamp of last successful fetch from Firestore.
  ///
  /// Used for cache TTL (5-minute freshness window).
  /// Null if never fetched.
  final DateTime? lastFetchTime;

  // Computed properties

  /// Whether there's an error.
  bool get hasError => error != null;

  /// Whether any assessments exist.
  bool get hasAssessments => recentAssessments.isNotEmpty;

  /// Whether cache is fresh (< 5 minutes old).
  bool get isCacheFresh {
    if (lastFetchTime == null) return false;
    final age = DateTime.now().difference(lastFetchTime!);
    return age.inMinutes < 5;
  }

  /// Whether ready to display data (not loading, no error).
  bool get isReady => !isLoading && !hasError;

  // State mutation methods

  /// Creates a copy of this state with given fields replaced.
  QolState copyWith({
    Object? currentAssessment = _undefined,
    List<QolAssessment>? recentAssessments,
    bool? isLoading,
    bool? isSaving,
    Object? error = _undefined,
    Object? lastFetchTime = _undefined,
  }) {
    return QolState(
      currentAssessment: currentAssessment == _undefined
          ? this.currentAssessment
          : currentAssessment as QolAssessment?,
      recentAssessments: recentAssessments ?? this.recentAssessments,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: error == _undefined ? this.error : error as String?,
      lastFetchTime: lastFetchTime == _undefined
          ? this.lastFetchTime
          : lastFetchTime as DateTime?,
    );
  }

  /// Creates a copy with error cleared.
  QolState clearError() {
    return copyWith(error: null);
  }

  /// Creates a copy with loading state updated.
  QolState withLoading({required bool loading}) {
    return copyWith(isLoading: loading);
  }

  /// Creates a copy with saving state updated.
  QolState withSaving({required bool saving}) {
    return copyWith(isSaving: saving);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is QolState &&
        other.currentAssessment == currentAssessment &&
        _listEquals(other.recentAssessments, recentAssessments) &&
        other.isLoading == isLoading &&
        other.isSaving == isSaving &&
        other.error == error &&
        other.lastFetchTime == lastFetchTime;
  }

  @override
  int get hashCode {
    return Object.hash(
      currentAssessment,
      Object.hashAll(recentAssessments),
      isLoading,
      isSaving,
      error,
      lastFetchTime,
    );
  }

  @override
  String toString() {
    return 'QolState('
        'currentAssessment: ${currentAssessment?.documentId}, '
        'recentCount: ${recentAssessments.length}, '
        'isLoading: $isLoading, '
        'isSaving: $isSaving, '
        'error: $error, '
        'lastFetchTime: $lastFetchTime'
        ')';
  }

  // Helper for list equality
  bool _listEquals(List<QolAssessment> a, List<QolAssessment> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
