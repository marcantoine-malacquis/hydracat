import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/features/onboarding/debug_onboarding_replay.dart';
import 'package:hydracat/features/onboarding/exceptions/onboarding_exceptions.dart';
import 'package:hydracat/features/onboarding/flow/onboarding_flow.dart';
import 'package:hydracat/features/onboarding/models/onboarding_data.dart';
import 'package:hydracat/features/onboarding/models/onboarding_progress.dart';
import 'package:hydracat/features/onboarding/models/onboarding_step_id.dart';
import 'package:hydracat/features/onboarding/services/onboarding_service.dart';
import 'package:hydracat/providers/auth_provider.dart';

/// Sentinel value for [OnboardingState.copyWith] to distinguish between
/// "not provided" and "explicitly set to null"
const _undefined = Object();

/// Onboarding state that holds current progress and data
@immutable
class OnboardingState {
  /// Creates an [OnboardingState] instance
  const OnboardingState({
    this.progress,
    this.data,
    this.isLoading = false,
    this.error,
    this.isActive = false,
  });

  /// Creates initial empty state
  const OnboardingState.initial()
    : progress = null,
      data = null,
      isLoading = false,
      error = null,
      isActive = false;

  /// Creates loading state
  const OnboardingState.loading()
    : progress = null,
      data = null,
      isLoading = true,
      error = null,
      isActive = false;

  /// Current onboarding progress
  final OnboardingProgress? progress;

  /// Current onboarding data
  final OnboardingData? data;

  /// Whether an operation is in progress
  final bool isLoading;

  /// Current error if any
  final OnboardingException? error;

  /// Whether onboarding is currently active
  final bool isActive;

  /// Whether onboarding is complete
  bool get isComplete => progress?.isComplete ?? false;

  /// Current step ID if onboarding is active
  OnboardingStepId? get currentStepId => progress?.currentStepId;

  /// Whether can progress from current step
  bool get canProgressFromCurrentStep =>
      progress?.canProgressFromCurrentStep ?? false;

  /// Progress percentage (0.0 to 1.0)
  double get progressPercentage => progress?.progressPercentage ?? 0.0;

  /// Number of completed steps
  int get completedStepsCount => progress?.completedStepsCount ?? 0;

  /// Whether there's an error
  bool get hasError => error != null;

  /// Creates a copy of this [OnboardingState] with the given fields replaced
  OnboardingState copyWith({
    Object? progress = _undefined,
    Object? data = _undefined,
    bool? isLoading,
    Object? error = _undefined,
    bool? isActive,
  }) {
    return OnboardingState(
      progress: progress == _undefined
          ? this.progress
          : progress as OnboardingProgress?,
      data: data == _undefined ? this.data : data as OnboardingData?,
      isLoading: isLoading ?? this.isLoading,
      error: error == _undefined ? this.error : error as OnboardingException?,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Creates a copy with error cleared
  OnboardingState clearError() {
    return copyWith(error: null);
  }

  /// Creates a copy with loading state
  OnboardingState withLoading({required bool loading}) {
    return copyWith(isLoading: loading);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is OnboardingState &&
        other.progress == progress &&
        other.data == data &&
        other.isLoading == isLoading &&
        other.error == error &&
        other.isActive == isActive;
  }

  @override
  int get hashCode {
    return Object.hash(
      progress,
      data,
      isLoading,
      error,
      isActive,
    );
  }

  @override
  String toString() {
    return 'OnboardingState('
        'progress: $progress, '
        'data: $data, '
        'isLoading: $isLoading, '
        'error: $error, '
        'isActive: $isActive'
        ')';
  }
}

/// Notifier class for managing onboarding state
class OnboardingNotifier extends StateNotifier<OnboardingState> {
  /// Creates an [OnboardingNotifier] with the provided dependencies
  OnboardingNotifier(this._onboardingService, this._ref)
    : super(const OnboardingState.initial()) {
    _listenToProgressStream();
  }

  final OnboardingService _onboardingService;
  final Ref _ref;
  StreamSubscription<OnboardingProgress?>? _progressSubscription;

  /// Listen to onboarding progress stream for real-time updates
  void _listenToProgressStream() {
    _progressSubscription = _onboardingService.progressStream.listen(
      (progress) {
        // Update state with new progress
        state = state.copyWith(
          progress: progress,
          isActive: progress != null && !progress.isComplete,
        );
      },
      onError: (Object error) {
        // Handle stream errors
        if (error is OnboardingException) {
          state = state.copyWith(
            isLoading: false,
            error: error,
          );
        } else {
          state = state.copyWith(
            isLoading: false,
            error: OnboardingServiceException('Unexpected error: $error'),
          );
        }
      },
    );
  }

  /// Start a new onboarding session
  Future<bool> startOnboarding(String userId) async {
    state = state.withLoading(loading: true);

    final result = await _onboardingService.startOnboarding(userId);

    switch (result) {
      case OnboardingSuccess():
        // Get current progress and data directly from service
        // (stream update might not have fired yet)
        final progress = _onboardingService.currentProgress;
        final onboardingData = _onboardingService.currentData;

        state = state.copyWith(
          progress: progress,
          data: onboardingData,
          isLoading: false,
          isActive: true,
        );
        return true;

      case OnboardingFailure(exception: final exception):
        state = state.copyWith(
          isLoading: false,
          error: exception,
          isActive: false,
        );
        return false;
    }
  }

  /// Resume an existing onboarding session
  Future<bool> resumeOnboarding(String userId) async {
    state = state.withLoading(loading: true);

    final result = await _onboardingService.resumeOnboarding(userId);

    switch (result) {
      case OnboardingSuccess(data: final data):
        // Get current progress directly from service
        // (stream update might not have fired yet)
        final progress = _onboardingService.currentProgress;

        state = state.copyWith(
          data: data as OnboardingData?,
          progress: progress,
          isLoading: false,
          isActive: true,
        );
        return true;

      case OnboardingFailure(exception: final exception):
        state = state.copyWith(
          isLoading: false,
          error: exception,
          isActive: false,
        );
        return false;
    }
  }

  /// Update onboarding data
  Future<bool> updateData(OnboardingData newData) async {
    state = state.withLoading(loading: true);

    final result = await _onboardingService.updateData(newData);

    switch (result) {
      case OnboardingSuccess():
        // Get updated progress directly from service to ensure validation
        // state is synchronized before subsequent operations like
        // navigateNext()
        final updatedProgress = _onboardingService.currentProgress;

        state = state.copyWith(
          data: newData,
          progress: updatedProgress,
          isLoading: false,
        );
        return true;

      case OnboardingFailure(exception: final exception):
        state = state.copyWith(
          isLoading: false,
          error: exception,
        );
        return false;
    }
  }

  /// Move to the next step in the onboarding flow
  Future<bool> moveToNextStep() async {
    state = state.withLoading(loading: true);

    final result = await _onboardingService.moveToNextStep();

    switch (result) {
      case OnboardingSuccess():
        state = state.copyWith(
          isLoading: false,
        );
        return true;

      case OnboardingFailure(exception: final exception):
        state = state.copyWith(
          isLoading: false,
          error: exception,
        );
        return false;
    }
  }

  /// Move to the previous step in the onboarding flow
  Future<bool> moveToPreviousStep() async {
    state = state.withLoading(loading: true);

    final result = await _onboardingService.moveToPreviousStep();

    switch (result) {
      case OnboardingSuccess():
        state = state.copyWith(
          isLoading: false,
        );
        return true;

      case OnboardingFailure(exception: final exception):
        state = state.copyWith(
          isLoading: false,
          error: exception,
        );
        return false;
    }
  }

  /// Set the current step in the onboarding flow (for fixing mismatches)
  Future<bool> setCurrentStep(OnboardingStepId stepId) async {
    state = state.withLoading(loading: true);

    final result = await _onboardingService.setCurrentStep(stepId);

    switch (result) {
      case OnboardingSuccess():
        state = state.copyWith(
          isLoading: false,
        );
        return true;

      case OnboardingFailure(exception: final exception):
        state = state.copyWith(
          isLoading: false,
          error: exception,
        );
        return false;
    }
  }

  /// Complete the onboarding flow
  Future<bool> completeOnboarding() async {
    state = state.withLoading(loading: true);

    final result = await _onboardingService.completeOnboarding();

    switch (result) {
      case OnboardingSuccess(data: final petProfile):
        // Check if debug replay mode is active
        final isDebugReplay = _ref.read(debugOnboardingReplayProvider);

        if (isDebugReplay && kDebugMode) {
          // In replay mode: skip Firestore writes, just update local state
          debugPrint(
            '[OnboardingNotifier] Debug replay mode - skipping Firestore write '
            'for onboarding completion',
          );

          // Update local state to show completion (no Firestore write)
          state = state.copyWith(
            isLoading: false,
            isActive: false,
          );
          return true;
        } else {
          // Normal mode: Mark onboarding as complete in auth
          // (writes to Firestore)
          final authNotifier = _ref.read(authProvider.notifier);
          final success = await authNotifier.markOnboardingComplete(
            (petProfile as dynamic).id as String,
          );

          if (success) {
            state = state.copyWith(
              isLoading: false,
              isActive: false,
            );
            return true;
          } else {
            state = state.copyWith(
              isLoading: false,
              error: const OnboardingServiceException(
                'Failed to update user onboarding status',
              ),
            );
            return false;
          }
        }

      case OnboardingFailure(exception: final exception):
        state = state.copyWith(
          isLoading: false,
          error: exception,
        );
        return false;
    }
  }

  /// Clear the current error
  void clearError() {
    state = state.clearError();
  }

  /// Get the next route in the onboarding flow
  ///
  /// Returns the next step's route if progression is possible, null otherwise.
  /// This is a read-only operation that doesn't change state.
  String? getNextRoute() {
    if (kDebugMode) {
      debugPrint('[OnboardingNotifier] getNextRoute() called');
    }

    if (state.progress == null || state.data == null) {
      if (kDebugMode) {
        debugPrint(
          '[OnboardingNotifier] Progress or data is null - returning null',
        );
        debugPrint('[OnboardingNotifier] Progress: ${state.progress}');
        debugPrint('[OnboardingNotifier] Data: ${state.data}');
      }
      return null;
    }

    final currentStepId = state.progress!.currentStepId;
    final flow = _ref.read(onboardingFlowProvider);
    final nextStepId = flow.navigationResolver.getNextStep(
      currentStepId,
      state.data ?? const OnboardingData.empty(),
    );

    if (kDebugMode) {
      debugPrint('[OnboardingNotifier] Current step: $currentStepId');
      debugPrint('[OnboardingNotifier] Next step: $nextStepId');
    }

    if (nextStepId == null) {
      if (kDebugMode) {
        debugPrint(
          '[OnboardingNotifier] No next step available - returning null',
        );
      }
      return null; // At completion, no next step
    }

    // Check if can progress from current step
    final canProgress = state.progress!.canProgressFromCurrentStep;
    if (kDebugMode) {
      debugPrint(
        '[OnboardingNotifier] Can progress from current step: $canProgress',
      );
      debugPrint(
        '[OnboardingNotifier] Current step details: '
        '${state.progress!.currentStepDetails}',
      );
    }

    if (!canProgress) {
      if (kDebugMode) {
        debugPrint('[OnboardingNotifier] Cannot progress - returning null');
      }
      return null;
    }

    // Get route for next step
    final route = flow.navigationResolver.getRoute(nextStepId);
    if (kDebugMode) {
      debugPrint('[OnboardingNotifier] Returning route: $route');
    }
    return route;
  }

  /// Get the previous route in the onboarding flow
  ///
  /// Returns the previous step's route if backward navigation is allowed,
  /// null otherwise. This is a read-only operation that doesn't change state.
  String? getPreviousRoute() {
    if (state.progress == null || state.data == null) {
      return null;
    }

    final flow = _ref.read(onboardingFlowProvider);
    final previousStepId = flow.navigationResolver.getPreviousStep(
      state.progress!.currentStepId,
      state.data!,
    );

    if (previousStepId == null) {
      return null; // At welcome, no previous step or can't go back
    }

    // Get route for previous step
    return flow.navigationResolver.getRoute(previousStepId);
  }

  /// Navigate to the next step with validation
  ///
  /// Validates current step, moves to next step in the onboarding service,
  /// and returns the target route. Returns null if navigation fails or
  /// is not possible.
  ///
  /// Use this in screens instead of manually calling moveToNextStep()
  /// and determining the route.
  Future<String?> navigateNext() async {
    if (kDebugMode) {
      debugPrint('[OnboardingNotifier] navigateNext() called');
      debugPrint('[OnboardingNotifier] Current state: ${state.currentStepId}');
      debugPrint('[OnboardingNotifier] Progress: ${state.progress}');
      debugPrint(
        '[OnboardingNotifier] Data: ${state.data != null ? "present" : "null"}',
      );
      debugPrint(
        '[OnboardingNotifier] Can progress: '
        '${state.canProgressFromCurrentStep}',
      );
    }

    // Get the next route BEFORE moving (while still on current step)
    final nextRoute = getNextRoute();

    if (kDebugMode) {
      debugPrint('[OnboardingNotifier] Next route determined: $nextRoute');
    }

    if (nextRoute == null) {
      if (kDebugMode) {
        debugPrint(
          '[OnboardingNotifier] Cannot get next route - returning null',
        );
      }
      return null; // Can't progress from current step
    }

    // Now move to the next step
    if (kDebugMode) {
      debugPrint('[OnboardingNotifier] Calling moveToNextStep()...');
    }
    final success = await moveToNextStep();

    if (kDebugMode) {
      debugPrint('[OnboardingNotifier] moveToNextStep() result: $success');
    }

    if (!success) {
      if (kDebugMode) {
        debugPrint(
          '[OnboardingNotifier] Move to next step failed - returning null',
        );
      }
      return null;
    }

    // Return the route we determined before moving
    if (kDebugMode) {
      debugPrint('[OnboardingNotifier] Returning next route: $nextRoute');
    }
    return nextRoute;
  }

  /// Navigate to the previous step with validation
  ///
  /// Validates backward navigation is allowed, moves to previous step,
  /// and returns the target route. Returns null if navigation fails or
  /// is not possible.
  ///
  /// Use this in screens instead of manually calling moveToPreviousStep()
  /// and determining the route.
  Future<String?> navigatePrevious() async {
    // Get the previous route BEFORE moving (while still on current step)
    final previousRoute = getPreviousRoute();

    if (previousRoute == null) {
      return null; // Can't go back from current step
    }

    // Now move to the previous step
    final success = await moveToPreviousStep();

    if (!success) {
      return null;
    }

    // Return the route we determined before moving
    return previousRoute;
  }

  /// Extract user-friendly error message from any exception
  ///
  /// Provides detailed validation errors for [OnboardingValidationException],
  /// user-friendly messages for other [OnboardingException] types,
  /// and generic fallback for unexpected errors.
  String getErrorMessage(Object error) {
    if (error is OnboardingValidationException) {
      // Use detailed message with bullet-point list of validation errors
      return error.detailedMessage;
    } else if (error is OnboardingException) {
      // Use the exception's user-friendly message
      return error.message;
    } else {
      // Fallback for unexpected errors
      return 'An unexpected error occurred. Please try again.';
    }
  }

  /// Check if user has incomplete onboarding data
  Future<bool> hasIncompleteOnboarding(String userId) async {
    return _onboardingService.hasIncompleteOnboarding(userId);
  }

  /// Clear all onboarding data for a user
  Future<void> clearOnboardingData(String userId) async {
    await _onboardingService.clearOnboardingData(userId);

    // Reset state if clearing current user's data
    final currentUserId = _ref.read(currentUserProvider)?.id;
    if (currentUserId == userId) {
      state = const OnboardingState.initial();
    }
  }

  @override
  void dispose() {
    _progressSubscription?.cancel();
    _onboardingService.dispose();
    super.dispose();
  }
}

/// Provider for the onboarding flow configuration
final onboardingFlowProvider = Provider<OnboardingFlow>((ref) {
  return getOnboardingFlow();
});

/// Provider for the OnboardingService instance
final onboardingServiceProvider = Provider<OnboardingService>((ref) {
  final flow = ref.read(onboardingFlowProvider);
  return OnboardingService(flow: flow);
});

/// Provider for the onboarding state notifier
final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
      final service = ref.read(onboardingServiceProvider);
      return OnboardingNotifier(service, ref);
    });

/// Optimized provider to get current onboarding progress
final onboardingProgressProvider = Provider<OnboardingProgress?>((ref) {
  return ref.watch(onboardingProvider.select((state) => state.progress));
});

/// Optimized provider to get current onboarding data
final onboardingDataProvider = Provider<OnboardingData?>((ref) {
  return ref.watch(onboardingProvider.select((state) => state.data));
});

/// Optimized provider to check if onboarding is active
final isOnboardingActiveProvider = Provider<bool>((ref) {
  return ref.watch(onboardingProvider.select((state) => state.isActive));
});

/// Optimized provider to check if onboarding is loading
final onboardingIsLoadingProvider = Provider<bool>((ref) {
  return ref.watch(onboardingProvider.select((state) => state.isLoading));
});

/// Optimized provider to get current onboarding error
final onboardingErrorProvider = Provider<OnboardingException?>((ref) {
  return ref.watch(onboardingProvider.select((state) => state.error));
});

/// Optimized provider to get current onboarding step ID
final currentOnboardingStepIdProvider = Provider<OnboardingStepId?>((ref) {
  return ref.watch(onboardingProvider.select((state) => state.currentStepId));
});

/// Optimized provider to check if can progress from current step
final canProgressFromCurrentStepProvider = Provider<bool>((ref) {
  return ref.watch(
    onboardingProvider.select(
      (state) => state.canProgressFromCurrentStep,
    ),
  );
});

/// Optimized provider to get onboarding progress percentage
final onboardingProgressPercentageProvider = Provider<double>((ref) {
  return ref.watch(
    onboardingProvider.select(
      (state) => state.progressPercentage,
    ),
  );
});

/// Optimized provider to get completed steps count
final completedStepsCountProvider = Provider<int>((ref) {
  return ref.watch(
    onboardingProvider.select(
      (state) => state.completedStepsCount,
    ),
  );
});

/// Optimized provider to check if onboarding is complete
final isOnboardingCompleteProvider = Provider<bool>((ref) {
  return ref.watch(onboardingProvider.select((state) => state.isComplete));
});

/// Optimized provider to check if onboarding has an error
final onboardingHasErrorProvider = Provider<bool>((ref) {
  return ref.watch(onboardingProvider.select((state) => state.hasError));
});
