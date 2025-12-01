/// Debug-only helper for non-destructive onboarding replay
///
/// Allows testing the onboarding UI/UX flow without modifying Firestore
/// or affecting the current developer account data.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hydracat/app/router.dart';
import 'package:hydracat/features/onboarding/models/onboarding_step.dart';
import 'package:hydracat/providers/auth_provider.dart';
import 'package:hydracat/providers/onboarding_provider.dart';

/// Provider that tracks whether debug onboarding replay mode is active
///
/// When true, onboarding flow bypasses Firestore writes and
/// existing pet checks.
/// Only available in debug mode.
final debugOnboardingReplayProvider = StateProvider<bool>((ref) {
  if (!kDebugMode) return false;
  return false;
});

/// Static flag for OnboardingService to check
/// (since it doesn't have ref access)
///
/// This is updated whenever the provider changes via a listener.
bool _isDebugReplayActive = false;

/// Checks if debug onboarding replay mode is currently active
///
/// This can be called from anywhere, including OnboardingService singleton.
/// Returns false in production builds.
bool isDebugOnboardingReplayActive() {
  if (!kDebugMode) return false;
  return _isDebugReplayActive;
}

/// Starts a non-destructive onboarding replay session
///
/// This function:
/// - Clears local onboarding checkpoints (doesn't touch Firestore)
/// - Sets onboarding flags to false in-memory only
/// - Activates debug replay mode
/// - Navigates to onboarding welcome screen
///
/// **Safe to use**: Does not modify Firestore data.
Future<void> startOnboardingReplay(
  WidgetRef ref,
  BuildContext context,
) async {
  if (!kDebugMode) {
    debugPrint(
      '[DebugOnboardingReplay] startOnboardingReplay called in production',
    );
    return;
  }

  try {
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) {
      debugPrint(
        '[DebugOnboardingReplay] Cannot start replay: no authenticated user',
      );
      return;
    }

    debugPrint('[DebugOnboardingReplay] Starting non-destructive replay...');

    // Step 1: Clear local onboarding checkpoints (doesn't touch Firestore)
    await ref.read(onboardingProvider.notifier).clearOnboardingData(userId);

    // Step 2: Set onboarding flags to false in-memory only (no Firestore write)
    await ref
        .read(authProvider.notifier)
        .debugSetOnboardingFlagsInMemory(
          hasCompletedOnboarding: false,
          hasSkippedOnboarding: false,
        );

    // Step 3: Activate debug replay mode
    ref.read(debugOnboardingReplayProvider.notifier).state = true;
    _isDebugReplayActive = true;

    // Step 4: Refresh router to update guards
    ref.read(routerRefreshStreamProvider).refresh();

    // Step 5: Navigate to onboarding welcome screen
    if (context.mounted) {
      context.go(OnboardingStepType.welcome.routeName);
    }

    debugPrint(
      '[DebugOnboardingReplay] Replay mode activated successfully',
    );
  } catch (e) {
    debugPrint(
      '[DebugOnboardingReplay] ERROR: Failed to start replay: $e',
    );
    rethrow;
  }
}

/// Exits the onboarding replay session and returns to normal app state
///
/// This function:
/// - Deactivates debug replay mode
/// - Refreshes router to restore normal routing
/// - Navigates back to home screen
Future<void> exitOnboardingReplay(
  WidgetRef ref,
  BuildContext context,
) async {
  if (!kDebugMode) {
    debugPrint(
      '[DebugOnboardingReplay] exitOnboardingReplay called in production',
    );
    return;
  }

  try {
    debugPrint('[DebugOnboardingReplay] Exiting replay mode...');

    // Step 1: Deactivate debug replay mode
    ref.read(debugOnboardingReplayProvider.notifier).state = false;
    _isDebugReplayActive = false;

    // Step 2: Refresh router to restore normal routing
    ref.read(routerRefreshStreamProvider).refresh();

    // Step 3: Navigate to home screen
    if (context.mounted) {
      context.go('/');
    }

    debugPrint('[DebugOnboardingReplay] Replay mode exited successfully');
  } catch (e) {
    debugPrint(
      '[DebugOnboardingReplay] ERROR: Failed to exit replay: $e',
    );
    rethrow;
  }
}

/// Initialize listener to keep static flag in sync with provider
///
/// This should be called once during app startup to ensure the static flag
/// stays synchronized with the provider state.
void initializeDebugReplayListener(WidgetRef ref) {
  if (!kDebugMode) return;

  ref.listen(debugOnboardingReplayProvider, (previous, next) {
    _isDebugReplayActive = next;
    debugPrint(
      '[DebugOnboardingReplay] Static flag updated: $_isDebugReplayActive',
    );
  });
}
