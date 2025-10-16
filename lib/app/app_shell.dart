import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hydracat/core/constants/app_icons.dart';
import 'package:hydracat/features/logging/exceptions/logging_error_handler.dart';
import 'package:hydracat/features/logging/screens/fluid_logging_screen.dart';
import 'package:hydracat/features/logging/screens/medication_logging_screen.dart';
import 'package:hydracat/features/logging/services/overlay_service.dart';
import 'package:hydracat/features/logging/widgets/quick_log_success_popup.dart';
import 'package:hydracat/features/logging/widgets/treatment_choice_popup.dart';
import 'package:hydracat/providers/analytics_provider.dart';
import 'package:hydracat/providers/auth_provider.dart';
import 'package:hydracat/providers/logging_provider.dart';
import 'package:hydracat/providers/logging_queue_provider.dart';
import 'package:hydracat/providers/profile_provider.dart';
import 'package:hydracat/shared/widgets/dialogs/no_schedules_dialog.dart';
import 'package:hydracat/shared/widgets/navigation/hydra_navigation_bar.dart';

/// Main app shell that provides consistent navigation and layout.
class AppShell extends ConsumerStatefulWidget {
  /// Creates an AppShell with the specified child.
  const AppShell({
    required this.child,
    super.key,
  });

  /// The main content to display.
  final Widget child;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell>
    with WidgetsBindingObserver {
  late final VoidCallback _overlayListener;
  final List<HydraNavigationItem> _navigationItems = const [
    HydraNavigationItem(icon: AppIcons.home, label: 'Home', route: '/'),
    HydraNavigationItem(
      icon: AppIcons.progress,
      label: 'Progress',
      route: '/progress',
    ),
    HydraNavigationItem(
      icon: AppIcons.learn,
      label: 'Learn',
      route: '/learn',
    ),
    HydraNavigationItem(
      icon: AppIcons.profile,
      label: 'Profile',
      route: '/profile',
    ),
  ];

  // Pre-computed route-to-index mapping for O(1) lookup performance
  static const Map<String, int> _routeToIndexMap = {
    '/': 0,
    '/progress': 1,
    '/learn': 2,
    '/profile': 3,
  };

  int get _currentIndex {
    final currentLocation = GoRouterState.of(context).uri.path;

    // Use O(1) map lookup instead of O(n) linear search
    final index = _routeToIndexMap[currentLocation];
    if (index != null) return index;

    // If on logging screen, don't highlight any nav item
    if (currentLocation == '/logging') {
      return -1;
    }

    // If in onboarding flow, don't highlight any nav item
    if (currentLocation.startsWith('/onboarding')) {
      return -1;
    }

    return 0; // Default to home
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _overlayListener = () => setState(() {});
    OverlayService.isShowingNotifier.addListener(_overlayListener);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    OverlayService.isShowingNotifier.removeListener(_overlayListener);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      debugPrint('[AppShell] App resumed - refreshing caches');

      // Refresh logging cache (existing)
      ref.read(loggingProvider.notifier).onAppResumed();

      // Refresh schedule cache (NEW)
      ref.read(profileProvider.notifier).onAppResumed();
    }
  }

  void _onNavigationTap(int index) {
    final route = _navigationItems[index].route;
    if (route != null) {
      context.go(route);
    }
  }

  void _onFabPressed() {
    // Check if user has completed onboarding
    final hasCompletedOnboarding = ref.read(hasCompletedOnboardingProvider);

    if (!hasCompletedOnboarding) {
      context.go('/onboarding/welcome');
      return;
    }

    // Get schedule data from ProfileState (already cached - zero reads)
    final profileState = ref.read(profileProvider);
    final hasFluid = profileState.hasFluidSchedule;
    final hasMedication = profileState.hasMedicationSchedules;

    // Track popup opened
    if (hasFluid || hasMedication) {
      final analyticsService = ref.read(analyticsServiceDirectProvider);
      final popupType = hasFluid && hasMedication
          ? 'choice'
          : hasFluid
          ? 'fluid'
          : 'medication';
      analyticsService.trackLoggingPopupOpened(
        popupType: popupType,
      );
    }

    // Route based on actual schedule data
    if (hasFluid && hasMedication) {
      // Both exist - show choice popup
      _showLoggingDialog(
        context,
        TreatmentChoicePopup(
          onMedicationSelected: () {
            OverlayService.hide();
            _showLoggingDialog(
              context,
              const MedicationLoggingScreen(),
              animationType: OverlayAnimationType.slideFromRight,
            );
          },
          onFluidSelected: () {
            OverlayService.hide();
            _showLoggingDialog(
              context,
              const FluidLoggingScreen(),
              animationType: OverlayAnimationType.slideFromRight,
            );
          },
        ),
      );
    } else if (hasFluid) {
      // Only fluid - go direct
      _showLoggingDialog(context, const FluidLoggingScreen());
    } else if (hasMedication) {
      // Only medication - go direct
      _showLoggingDialog(context, const MedicationLoggingScreen());
    } else {
      // No schedules yet - show setup dialog
      showDialog<void>(
        context: context,
        builder: (context) => const NoSchedulesDialog(),
      );
    }
  }

  void _showLoggingDialog(
    BuildContext context,
    Widget child, {
    OverlayAnimationType animationType = OverlayAnimationType.slideUp,
  }) {
    OverlayService.showFullScreenPopup(
      context: context,
      child: child,
      animationType: animationType,
      onDismiss: () {
        // Handle any cleanup if needed
      },
    );
  }

  Future<void> _onFabLongPress() async {
    // Haptic feedback for immediate tactile confirmation
    unawaited(HapticFeedback.mediumImpact());

    final hasCompletedOnboarding = ref.read(hasCompletedOnboardingProvider);
    if (!hasCompletedOnboarding) {
      context.go('/onboarding/welcome');
      return;
    }

    final pet = ref.read(primaryPetProvider);
    if (pet == null) {
      context.go('/onboarding/welcome');
      return;
    }

    // Check if can quick-log (uses cache, no Firestore reads)
    final canQuickLog = ref.read(canQuickLogProvider);

    // FALLBACK: If canQuickLog is false but we have schedules, still try
    // This handles cases where the cache might be stale or providers
    // are out of sync
    if (!canQuickLog) {
      // Check if we actually have schedules (bypass the provider cache)
      final profileState = ref.read(profileProvider);
      final hasSchedules =
          profileState.hasFluidSchedule || profileState.hasMedicationSchedules;

      if (!hasSchedules) {
        LoggingErrorHandler.showLoggingError(
          context,
          'No schedules found. Please set up your treatment schedule.',
        );
        return;
      }
    }

    // Execute quick-log
    final sessionCount = await ref
        .read(loggingProvider.notifier)
        .quickLogAllTreatments();

    if (!mounted) return;

    if (sessionCount > 0) {
      // Quick-log succeeded

      // Show success popup
      OverlayService.showFullScreenPopup(
        context: context,
        child: QuickLogSuccessPopup(
          sessionCount: sessionCount,
          petName: pet.name,
        ),
        animationType: OverlayAnimationType.scaleIn,
      );
    } else {
      // Quick-log failed - show error from state
      final error = ref.read(loggingErrorProvider);
      if (error != null) {
        LoggingErrorHandler.showLoggingError(context, error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authIsLoadingProvider);
    final currentUser = ref.watch(currentUserProvider);
    final isVerified = currentUser?.emailVerified ?? false;
    final currentLocation = GoRouterState.of(context).uri.path;
    final isInOnboardingFlow = currentLocation.startsWith('/onboarding');
    final isOverlayVisible = OverlayService.isShowingNotifier.value;
    final isInProfileEditScreens = [
      '/profile/settings',
      '/profile/ckd',
      '/profile/fluid',
      '/profile/medication',
    ].contains(currentLocation);

    // Load pet profile if authenticated and onboarding completed
    final hasCompletedOnboarding = ref.watch(hasCompletedOnboardingProvider);
    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    final primaryPet = ref.watch(primaryPetProvider);
    final profileIsLoading = ref.watch(profileIsLoadingProvider);

    // Trigger profile loading when conditions are met
    if (hasCompletedOnboarding &&
        isAuthenticated &&
        primaryPet == null &&
        !profileIsLoading &&
        !isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        debugPrint('[AppShell] Auto-loading pet profile');
        ref.read(profileProvider.notifier).loadPrimaryPet();
      });
    }

    // Watch logging state to disable FAB during operations
    final isLoggingInProgress = ref.watch(isLoggingProvider);

    // Initialize auto-sync listener (watches for connectivity changes)
    ref
      ..watch(autoSyncListenerProvider)
      // Listen for sync toast notifications
      ..listen<String?>(syncToastMessageProvider, (previous, next) {
        if (next != null && mounted) {
          // Check if this is a sync failure (has retry state)
          final syncFailure = ref.read(syncFailureStateProvider);

          if (syncFailure != null) {
            // Show error with retry button
            LoggingErrorHandler.showSyncRetry(
              context,
              next,
              () async {
                // Retry sync
                try {
                  await ref
                      .read(offlineLoggingServiceProvider)
                      .syncPendingOperations();

                  // Success - clear failure state
                  ref.read(syncFailureStateProvider.notifier).state = null;
                } on Exception catch (e) {
                  // Failed again - state will be updated by provider
                  debugPrint('[AppShell] Retry sync failed: $e');
                }
              },
            );
          } else {
            // Success message
            LoggingErrorHandler.showLoggingSuccess(context, next);
          }

          // Clear message after showing
          ref.read(syncToastMessageProvider.notifier).state = null;
        }
      });

    return Scaffold(
      body: Column(
        children: [
          // Show verification banner for verified users only
          // (not during loading or onboarding)
          if (currentUser != null &&
              !currentUser.emailVerified &&
              !isInOnboardingFlow)
            _buildVerificationBanner(context, currentUser.email),
          Expanded(
            child: isLoading ? _buildLoadingContent(context) : widget.child,
          ),
        ],
      ),
      // Hide bottom navigation during onboarding flow and on profile
      // edit screens
      bottomNavigationBar:
          (isInOnboardingFlow || isInProfileEditScreens || isOverlayVisible)
          ? null
          : HydraNavigationBar(
              items: _navigationItems,
              // No selection during loading
              currentIndex: isLoading ? -1 : _currentIndex,
              // Disable navigation during loading
              onTap: isLoading ? (_) {} : _onNavigationTap,
              // Disable FAB during auth loading OR logging operations
              onFabPressed: (isLoading || isLoggingInProgress)
                  ? null
                  : _onFabPressed,
              onFabLongPress: (isLoading || isLoggingInProgress)
                  ? null
                  : _onFabLongPress,
              showVerificationBadge: !isLoading && !isVerified,
              // Pass loading state to FAB
              isFabLoading: isLoggingInProgress,
            ),
    );
  }

  /// Build loading content with skeleton UI
  Widget _buildLoadingContent(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Loading header
          Container(
            height: 24,
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 24),
            child: Row(
              children: [
                // Skeleton for greeting/title
                Container(
                  height: 20,
                  width: 120,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const Spacer(),
                // Skeleton for user avatar/icon
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),

          // Loading content cards
          Expanded(
            child: ListView.separated(
              itemCount: 3,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) => _buildLoadingSkeleton(context),
            ),
          ),

          // Loading status
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.primary.withValues(
                      alpha: 0.6,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Setting up your account...',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build a skeleton loading card
  Widget _buildLoadingSkeleton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(
            alpha: 0.2,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title skeleton
          Container(
            height: 16,
            width: double.infinity * 0.7,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 12),
          // Subtitle skeleton
          Container(
            height: 12,
            width: double.infinity * 0.5,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer.withValues(
                alpha: 0.7,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  /// Build verification status banner
  Widget _buildVerificationBanner(BuildContext context, String? email) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 20,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Verify your email to unlock all features',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          TextButton(
            onPressed: () =>
                context.go('/email-verification?email=${email ?? ''}'),
            child: Text(
              'Verify',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
