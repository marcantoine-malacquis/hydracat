/// Riverpod providers for Quality of Life feature.
///
/// This file contains all providers for the QoL feature including:
/// - Service providers (QolService, QolScoringService)
/// - State management (QolNotifier)
/// - Optimized selectors for UI consumption
/// - Cache-first strategy with 5-minute TTL
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/features/qol/exceptions/qol_exceptions.dart';
import 'package:hydracat/features/qol/models/qol_assessment.dart';
import 'package:hydracat/features/qol/models/qol_state.dart';
import 'package:hydracat/features/qol/models/qol_trend_summary.dart';
import 'package:hydracat/features/qol/services/qol_scoring_service.dart';
import 'package:hydracat/features/qol/services/qol_service.dart';
import 'package:hydracat/providers/analytics_provider.dart';
import 'package:hydracat/providers/auth_provider.dart';
import 'package:hydracat/providers/profile_provider.dart';

// ============================================
// Service Providers (Foundation Layer)
// ============================================

/// Provider for QolScoringService instance.
///
/// Pure business logic service for QoL scoring and trend calculations.
/// No Firebase dependencies.
final qolScoringServiceProvider = Provider<QolScoringService>((ref) {
  return const QolScoringService();
});

/// Provider for QolService instance.
///
/// Handles Firebase CRUD operations for QoL assessments.
/// Uses batch writes for cost optimization.
final qolServiceProvider = Provider<QolService>((ref) {
  final firestore = FirebaseFirestore.instance;
  final analytics = ref.read(analyticsServiceDirectProvider);
  return QolService(
    firestore: firestore,
    analyticsService: analytics,
  );
});

// ============================================
// State Management - QolNotifier
// ============================================

/// Notifier class for managing QoL state and operations.
///
/// Handles:
/// - Cache lifecycle (load on startup, 5-minute TTL)
/// - CRUD operations for assessments
/// - Optimistic updates for better UX
/// - Trend data computation
class QolNotifier extends StateNotifier<QolState> {
  /// Creates a [QolNotifier] with required dependencies.
  QolNotifier(
    this._service,
    this._ref,
  ) : super(const QolState.initial()) {
    _initialize();
  }

  /// Testing-only constructor that skips initialization.
  @visibleForTesting
  QolNotifier.test(
    this._service,
    this._ref,
  ) : super(const QolState.initial());

  final QolService _service;
  final Ref _ref;

  // ============================================
  // Initialization
  // ============================================

  /// Initialize on app startup.
  ///
  /// Loads recent assessments into cache for instant home screen display.
  Future<void> _initialize() async {
    await loadRecentAssessments();
  }

  // ============================================
  // Data Loading
  // ============================================

  /// Loads recent assessments from Firestore with cache-first strategy.
  ///
  /// Cache freshness: 5 minutes
  /// Page size: 20 assessments (cost optimization)
  ///
  /// Set [forceRefresh] to true to bypass cache (e.g., pull-to-refresh).
  ///
  /// Updates state with:
  /// - recentAssessments: Last 20 assessments
  /// - currentAssessment: Most recent assessment
  /// - lastFetchTime: Cache timestamp
  Future<void> loadRecentAssessments({bool forceRefresh = false}) async {
    // Check cache freshness
    if (!forceRefresh && state.isCacheFresh) {
      if (kDebugMode) {
        debugPrint('[QolNotifier] Using cached data (fresh)');
      }
      return;
    }

    // Get user and pet context
    final user = _ref.read(currentUserProvider);
    final pet = _ref.read(primaryPetProvider);

    if (user == null || pet == null) {
      if (kDebugMode) {
        debugPrint('[QolNotifier] User or pet null, skipping load');
      }
      state = state.copyWith(
        isLoading: false,
        error: 'User or pet not found',
      );
      return;
    }

    try {
      state = state.withLoading(loading: true);

      if (kDebugMode) {
        debugPrint(
          '[QolNotifier] Loading recent assessments '
          '(userId: ${user.id}, petId: ${pet.id})',
        );
      }

      // Fetch from Firestore (limit 20 for cost optimization)
      final assessments = await _service.getRecentAssessments(
        user.id,
        pet.id,
      );

      if (kDebugMode) {
        debugPrint(
          '[QolNotifier] Loaded ${assessments.length} assessments',
        );
      }

      // Update state
      state = state.copyWith(
        recentAssessments: assessments,
        currentAssessment: assessments.isNotEmpty ? assessments.first : null,
        isLoading: false,
        lastFetchTime: DateTime.now(),
        error: null,
      );
    } on QolServiceException catch (e) {
      if (kDebugMode) {
        debugPrint('[QolNotifier] Load error: $e');
      }
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
    } on Exception catch (e) {
      if (kDebugMode) {
        debugPrint('[QolNotifier] Unexpected load error: $e');
      }
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load assessments',
      );
    }
  }

  // ============================================
  // CRUD Operations
  // ============================================

  /// Saves a new QoL assessment.
  ///
  /// Uses optimistic update for instant UI feedback:
  /// 1. Update local state immediately
  /// 2. Write to Firestore (batch operation)
  /// 3. On error: revert and show error
  ///
  /// Automatically updates:
  /// - Assessment document
  /// - Daily summary (denormalized scores)
  /// - Weekly/monthly summaries (timestamps)
  Future<void> saveAssessment(QolAssessment assessment) async {
    try {
      state = state.withSaving(saving: true);

      if (kDebugMode) {
        debugPrint(
          '[QolNotifier] Saving assessment for ${assessment.documentId}',
        );
      }

      // Optimistic update: Add to local state immediately
      final updatedAssessments = [assessment, ...state.recentAssessments];

      state = state.copyWith(
        recentAssessments: updatedAssessments,
        currentAssessment: assessment,
        error: null,
      );

      // Save to Firestore
      await _service.saveAssessment(assessment);

      if (kDebugMode) {
        debugPrint('[QolNotifier] Assessment saved successfully');
      }

      state = state.withSaving(saving: false);
    } on QolValidationException catch (e) {
      if (kDebugMode) {
        debugPrint('[QolNotifier] Validation error: $e');
      }

      // Revert optimistic update
      await loadRecentAssessments(forceRefresh: true);

      state = state.copyWith(
        isSaving: false,
        error: e.message,
      );
      rethrow;
    } on QolServiceException catch (e) {
      if (kDebugMode) {
        debugPrint('[QolNotifier] Save error: $e');
      }

      // Revert optimistic update
      await loadRecentAssessments(forceRefresh: true);

      state = state.copyWith(
        isSaving: false,
        error: e.message,
      );
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[QolNotifier] Unexpected save error: $e');
      }

      // Revert optimistic update
      await loadRecentAssessments(forceRefresh: true);

      state = state.copyWith(
        isSaving: false,
        error: 'Failed to save assessment',
      );
      rethrow;
    }
  }

  /// Updates an existing QoL assessment.
  ///
  /// Uses optimistic update pattern:
  /// 1. Update local state immediately
  /// 2. Write to Firestore (batch operation)
  /// 3. On error: revert and show error
  ///
  /// Sets updatedAt timestamp and clears completionDurationSeconds.
  Future<void> updateAssessment(QolAssessment assessment) async {
    try {
      state = state.withSaving(saving: true);

      if (kDebugMode) {
        debugPrint(
          '[QolNotifier] Updating assessment ${assessment.documentId}',
        );
      }

      // Optimistic update: Replace in local state
      final updatedAssessments = state.recentAssessments.map((a) {
        return a.documentId == assessment.documentId ? assessment : a;
      }).toList();

      state = state.copyWith(
        recentAssessments: updatedAssessments,
        currentAssessment: state.currentAssessment?.documentId ==
                assessment.documentId
            ? assessment
            : state.currentAssessment,
        error: null,
      );

      // Update in Firestore
      await _service.updateAssessment(assessment);

      if (kDebugMode) {
        debugPrint('[QolNotifier] Assessment updated successfully');
      }

      state = state.withSaving(saving: false);
    } on QolValidationException catch (e) {
      if (kDebugMode) {
        debugPrint('[QolNotifier] Validation error: $e');
      }

      // Revert optimistic update
      await loadRecentAssessments(forceRefresh: true);

      state = state.copyWith(
        isSaving: false,
        error: e.message,
      );
      rethrow;
    } on QolServiceException catch (e) {
      if (kDebugMode) {
        debugPrint('[QolNotifier] Update error: $e');
      }

      // Revert optimistic update
      await loadRecentAssessments(forceRefresh: true);

      state = state.copyWith(
        isSaving: false,
        error: e.message,
      );
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[QolNotifier] Unexpected update error: $e');
      }

      // Revert optimistic update
      await loadRecentAssessments(forceRefresh: true);

      state = state.copyWith(
        isSaving: false,
        error: 'Failed to update assessment',
      );
      rethrow;
    }
  }

  /// Deletes a QoL assessment by document ID.
  ///
  /// Document ID format: YYYY-MM-DD
  ///
  /// Uses optimistic update:
  /// 1. Remove from local state immediately
  /// 2. Delete from Firestore (batch operation)
  /// 3. On error: revert and show error
  ///
  /// Also clears QoL fields in daily summary.
  Future<void> deleteAssessment(String documentId) async {
    try {
      state = state.withSaving(saving: true);

      if (kDebugMode) {
        debugPrint('[QolNotifier] Deleting assessment $documentId');
      }

      // Find assessment to delete (for user/pet context)
      final assessmentToDelete = state.recentAssessments.firstWhere(
        (a) => a.documentId == documentId,
        orElse: () => throw QolServiceException(
          'Assessment not found: $documentId',
        ),
      );

      // Optimistic update: Remove from local state
      final updatedAssessments = state.recentAssessments
          .where((a) => a.documentId != documentId)
          .toList();

      final newCurrentAssessment = state.currentAssessment?.documentId ==
              documentId
          ? (updatedAssessments.isNotEmpty ? updatedAssessments.first : null)
          : state.currentAssessment;

      state = state.copyWith(
        recentAssessments: updatedAssessments,
        currentAssessment: newCurrentAssessment,
        error: null,
      );

      // Delete from Firestore
      await _service.deleteAssessment(
        assessmentToDelete.userId,
        assessmentToDelete.petId,
        assessmentToDelete.date,
      );

      if (kDebugMode) {
        debugPrint('[QolNotifier] Assessment deleted successfully');
      }

      state = state.withSaving(saving: false);
    } on QolServiceException catch (e) {
      if (kDebugMode) {
        debugPrint('[QolNotifier] Delete error: $e');
      }

      // Revert optimistic update
      await loadRecentAssessments(forceRefresh: true);

      state = state.copyWith(
        isSaving: false,
        error: e.message,
      );
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[QolNotifier] Unexpected delete error: $e');
      }

      // Revert optimistic update
      await loadRecentAssessments(forceRefresh: true);

      state = state.copyWith(
        isSaving: false,
        error: 'Failed to delete assessment',
      );
      rethrow;
    }
  }

  // ============================================
  // Trend Data Computation
  // ============================================

  /// Gets trend data for chart display.
  ///
  /// Returns up to [limit] most recent assessments with valid overall scores.
  /// Filters out assessments with low confidence (missing domain scores).
  ///
  /// Default limit: 12 assessments (~3 months of weekly tracking)
  List<QolTrendSummary> getTrendData({int limit = 12}) {
    return state.recentAssessments
        .where((assessment) => assessment.overallScore != null)
        .take(limit)
        .map((assessment) {
      // Filter domain scores to only include valid ones (non-null)
      final validDomainScores = <String, double>{};
      assessment.domainScores.forEach((domain, score) {
        if (score != null) {
          validDomainScores[domain] = score;
        }
      });

      return QolTrendSummary(
        date: assessment.date,
        domainScores: validDomainScores,
        overallScore: assessment.overallScore!,
        assessmentId: assessment.documentId,
      );
    }).toList();
  }

  // ============================================
  // Error Management
  // ============================================

  /// Clears the current error message.
  void clearError() {
    state = state.clearError();
  }
}

// ============================================
// Main Provider
// ============================================

/// Main provider for QoL state management.
///
/// Depends on:
/// - QolService: For Firebase CRUD operations
/// - Auth/Profile providers: For user context
final qolProvider = StateNotifierProvider<QolNotifier, QolState>((ref) {
  final service = ref.read(qolServiceProvider);
  return QolNotifier(service, ref);
});

// ============================================
// Optimized Selector Providers
// ============================================

/// Whether initial load is in progress.
final isLoadingQolProvider = Provider<bool>((ref) {
  return ref.watch(qolProvider.select((state) => state.isLoading));
});

/// Whether save/update operation is in progress.
final isSavingQolProvider = Provider<bool>((ref) {
  return ref.watch(qolProvider.select((state) => state.isSaving));
});

/// Current error message (null if no error).
final qolErrorProvider = Provider<String?>((ref) {
  return ref.watch(qolProvider.select((state) => state.error));
});

/// Has error (boolean convenience).
final hasQolErrorProvider = Provider<bool>((ref) {
  return ref.watch(qolProvider.select((state) => state.hasError));
});

/// Latest QoL assessment (null if none exist).
///
/// Used by home screen card for instant display without additional reads.
final currentQolAssessmentProvider = Provider<QolAssessment?>((ref) {
  return ref.watch(qolProvider.select((state) => state.currentAssessment));
});

/// Recent QoL assessments list (up to 20, cached).
///
/// Ordered by date descending. Used by history screen.
final recentQolAssessmentsProvider = Provider<List<QolAssessment>>((ref) {
  return ref.watch(qolProvider.select((state) => state.recentAssessments));
});

/// Trend data for chart visualization (up to 12 assessments).
///
/// Filters to assessments with valid overall scores.
/// Computed on-demand from cached assessments.
final qolTrendDataProvider = Provider<List<QolTrendSummary>>((ref) {
  final notifier = ref.read(qolProvider.notifier);
  return notifier.getTrendData();
});

/// Whether any assessments exist.
final hasQolAssessmentsProvider = Provider<bool>((ref) {
  return ref.watch(qolProvider.select((state) => state.hasAssessments));
});

/// Whether cache is fresh (<5 minutes old).
final isQolCacheFreshProvider = Provider<bool>((ref) {
  return ref.watch(qolProvider.select((state) => state.isCacheFresh));
});

/// Whether state is ready for display (not loading, no error).
final isQolReadyProvider = Provider<bool>((ref) {
  return ref.watch(qolProvider.select((state) => state.isReady));
});
