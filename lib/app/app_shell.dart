import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hydracat/core/config/flavor_config.dart';
import 'package:hydracat/core/constants/app_icons.dart';
import 'package:hydracat/features/logging/exceptions/logging_error_handler.dart';
import 'package:hydracat/features/logging/screens/fluid_logging_screen.dart';
import 'package:hydracat/features/logging/screens/medication_logging_screen.dart';
import 'package:hydracat/features/logging/services/overlay_service.dart';
import 'package:hydracat/features/logging/widgets/quick_log_success_popup.dart';
import 'package:hydracat/features/logging/widgets/treatment_choice_popup.dart';
import 'package:hydracat/features/notifications/providers/notification_provider.dart';
import 'package:hydracat/features/notifications/services/notification_tap_handler.dart';
import 'package:hydracat/l10n/app_localizations.dart';
import 'package:hydracat/providers/analytics_provider.dart';
import 'package:hydracat/providers/auth_provider.dart';
import 'package:hydracat/providers/dashboard_provider.dart';
import 'package:hydracat/providers/logging_provider.dart';
import 'package:hydracat/providers/logging_queue_provider.dart';
import 'package:hydracat/providers/profile_provider.dart';
import 'package:hydracat/shared/services/firebase_service.dart';
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
  late final VoidCallback _notificationTapListener;
  late final VoidCallback _notificationSnoozeListener;
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

    // Listen for notification taps
    _notificationTapListener = _handleNotificationTap;
    NotificationTapHandler.pendingTapPayload.addListener(
      _notificationTapListener,
    );

    // Listen for notification snooze actions
    _notificationSnoozeListener = _handleNotificationSnooze;
    NotificationTapHandler.pendingSnoozePayload.addListener(
      _notificationSnoozeListener,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    OverlayService.isShowingNotifier.removeListener(_overlayListener);
    NotificationTapHandler.pendingTapPayload.removeListener(
      _notificationTapListener,
    );
    NotificationTapHandler.pendingSnoozePayload.removeListener(
      _notificationSnoozeListener,
    );
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

      // Refresh dashboard cache (NEW)
      ref.read(dashboardProvider.notifier).onAppResumed();
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

  /// Handle notification tap from NotificationTapHandler.
  ///
  /// This is triggered when the user taps a notification. The payload is
  /// validated and processed to deep-link to the appropriate logging screen.
  void _handleNotificationTap() {
    _devLog('');
    _devLog('═══════════════════════════════════════════════════════');
    _devLog('👂 APPSHELL LISTENER TRIGGERED');
    _devLog('═══════════════════════════════════════════════════════');
    _devLog('Timestamp: ${DateTime.now().toIso8601String()}');

    final payload = NotificationTapHandler.pendingTapPayload.value;

    _devLog('Payload from NotificationTapHandler: $payload');

    // Ignore if no payload
    if (payload == null || payload.isEmpty) {
      _devLog('❌ Payload is null or empty, ignoring');
      _devLog('═══════════════════════════════════════════════════════');
      return;
    }

    _devLog('✅ Valid payload detected, clearing and scheduling processing');

    // Clear immediately to avoid re-triggering
    NotificationTapHandler.clearPendingTap();

    // Schedule handling after current frame
    _devLog('📅 Scheduling _processNotificationPayload via '
        'addPostFrameCallback');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _processNotificationPayload(payload);
    });
    _devLog('═══════════════════════════════════════════════════════');
    _devLog('');
  }

  /// Process and validate notification payload for deep-linking.
  ///
  /// Validates all required fields, checks authentication and onboarding
  /// state, and navigates to the appropriate logging screen with auto-
  /// selection of the treatment from the notification.
  Future<void> _processNotificationPayload(String payload) async {
    _devLog('');
    _devLog('═══════════════════════════════════════════════════════');
    _devLog('🔍 PROCESSING NOTIFICATION PAYLOAD');
    _devLog('═══════════════════════════════════════════════════════');
    _devLog('Timestamp: ${DateTime.now().toIso8601String()}');
    _devLog('Raw payload: $payload');
    _devLog('');

    try {
      // Parse JSON payload
      _devLog('Step 1: Parsing JSON payload...');
      final payloadMap = json.decode(payload) as Map<String, dynamic>;
      _devLog('✅ JSON parsed successfully');
      _devLog('Payload map: $payloadMap');

      // Extract and validate required fields
      _devLog('');
      _devLog('Step 2: Extracting required fields...');
      final userId = payloadMap['userId'] as String?;
      final petId = payloadMap['petId'] as String?;
      final scheduleId = payloadMap['scheduleId'] as String?;
      final timeSlot = payloadMap['timeSlot'] as String?;
      final kind = payloadMap['kind'] as String?;
      final treatmentType = payloadMap['treatmentType'] as String?;

      _devLog('  userId: $userId');
      _devLog('  petId: $petId');
      _devLog('  scheduleId: $scheduleId');
      _devLog('  timeSlot: $timeSlot');
      _devLog('  kind: $kind');
      _devLog('  treatmentType: $treatmentType');

      // Validate all required fields present
      _devLog('');
      _devLog('Step 3: Validating required fields...');
      if (userId == null ||
          petId == null ||
          scheduleId == null ||
          timeSlot == null ||
          kind == null ||
          treatmentType == null) {
        _devLog(
          '❌ FAILED: Invalid notification payload: missing required fields',
        );
        _devLog('═══════════════════════════════════════════════════════');
        _trackNotificationTapFailure('invalid_payload');
        return;
      }
      _devLog('✅ All required fields present');

      // Validate treatmentType
      _devLog('');
      _devLog('Step 4: Validating treatmentType...');
      if (treatmentType != 'medication' && treatmentType != 'fluid') {
        _devLog('❌ FAILED: Invalid treatmentType in payload: $treatmentType');
        _devLog('═══════════════════════════════════════════════════════');
        _trackNotificationTapFailure('invalid_treatment_type');
        return;
      }
      _devLog('✅ Treatment type is valid: $treatmentType');

      // Check authentication
      _devLog('');
      _devLog('Step 5: Checking authentication...');
      final isAuthenticated = ref.read(isAuthenticatedProvider);
      _devLog('  isAuthenticated: $isAuthenticated');

      if (!isAuthenticated) {
        _devLog('❌ FAILED: User not authenticated, redirecting to login');
        _devLog('═══════════════════════════════════════════════════════');
        _trackNotificationTapFailure('user_not_authenticated');

        if (mounted) {
          context.go('/login');
          // Show contextual message after navigation
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              final l10n = AppLocalizations.of(context);
              if (l10n != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.notificationAuthRequired),
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            }
          });
        }
        return;
      }
      _devLog('✅ User is authenticated');

      // Check onboarding completed
      _devLog('');
      _devLog('Step 6: Checking onboarding status...');
      final hasCompletedOnboarding = ref.read(hasCompletedOnboardingProvider);
      _devLog('  hasCompletedOnboarding: $hasCompletedOnboarding');

      if (!hasCompletedOnboarding) {
        _devLog(
          '❌ FAILED: Onboarding not completed, redirecting to onboarding',
        );
        _devLog('═══════════════════════════════════════════════════════');
        _trackNotificationTapFailure('onboarding_not_completed');

        if (mounted) {
          context.go('/onboarding/welcome');
        }
        return;
      }
      _devLog('✅ Onboarding completed');

      // Check pet loaded
      _devLog('');
      _devLog('Step 7: Checking if primary pet is loaded...');
      final primaryPet = ref.read(primaryPetProvider);
      _devLog('  primaryPet: ${primaryPet?.name ?? "null"}');

      if (primaryPet == null) {
        _devLog('❌ FAILED: Primary pet not loaded, cannot show logging screen');
        _devLog('═══════════════════════════════════════════════════════');
        _trackNotificationTapFailure('pet_not_loaded');
        return;
      }
      _devLog('✅ Primary pet loaded: ${primaryPet.name}');

      // Validate schedule exists
      _devLog('');
      _devLog('Step 8: Validating schedule exists...');
      var scheduleExists = false;
      if (treatmentType == 'medication') {
        final medicationSchedules = ref.read(todaysMedicationSchedulesProvider);
        _devLog(
          '  Medication schedules count: ${medicationSchedules.length}',
        );
        scheduleExists = medicationSchedules.any((s) => s.id == scheduleId);
      } else {
        final fluidSchedule = ref.read(fluidScheduleProvider);
        _devLog('  Fluid schedule: ${fluidSchedule?.id ?? "null"}');
        scheduleExists = fluidSchedule?.id == scheduleId;
      }
      _devLog('  scheduleExists: $scheduleExists');

      // Track analytics
      if (scheduleExists) {
        _devLog('✅ Schedule found, tracking success');
        _trackNotificationTapSuccess(treatmentType, kind, scheduleId);
      } else {
        _devLog('⚠️ Schedule $scheduleId not found, tracking failure');
        _trackNotificationTapFailure('schedule_not_found');
      }

      // Always navigate to /home, then show overlay
      _devLog('');
      _devLog('Step 9: Navigation and overlay...');
      if (!mounted) {
        _devLog('❌ Widget not mounted, cannot navigate');
        _devLog('═══════════════════════════════════════════════════════');
        return;
      }

      // Navigate to home first
      _devLog('  Navigating to /home...');
      context.go('/home');

      // Show logging screen overlay after navigation completes
      _devLog('  Scheduling overlay display via addPostFrameCallback...');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          _devLog('  ❌ Widget not mounted for overlay display');
          return;
        }

        _devLog('  Showing overlay for $treatmentType...');

        // Show appropriate logging screen with auto-selection
        if (treatmentType == 'medication') {
          _devLog(
            '  Opening MedicationLoggingScreen with '
            'initialScheduleId: ${scheduleExists ? scheduleId : "null"}',
          );
          OverlayService.showFullScreenPopup(
            context: context,
            child: MedicationLoggingScreen(
              initialScheduleId: scheduleExists ? scheduleId : null,
            ),
          );
        } else {
          _devLog(
            '  Opening FluidLoggingScreen with '
            'initialScheduleId: ${scheduleExists ? scheduleId : "null"}',
          );
          OverlayService.showFullScreenPopup(
            context: context,
            child: FluidLoggingScreen(
              initialScheduleId: scheduleExists ? scheduleId : null,
            ),
          );
        }

        _devLog('  ✅ Overlay displayed successfully');

        // Show toast if schedule not found
        if (!scheduleExists) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              final l10n = AppLocalizations.of(context);
              if (l10n != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.notificationScheduleNotFound),
                  ),
                );
              }
            }
          });
        }
      });

      _devLog('');
      _devLog('✅ NOTIFICATION PROCESSING COMPLETED SUCCESSFULLY');
      _devLog('═══════════════════════════════════════════════════════');
      _devLog('');
    } on Exception catch (e, stackTrace) {
      _devLog('');
      _devLog('❌ ERROR processing notification payload: $e');
      _devLog('Stack trace: $stackTrace');
      _devLog('═══════════════════════════════════════════════════════');
      _devLog('');
      _trackNotificationTapFailure('processing_error');

      // Log to Crashlytics in production
      if (!FlavorConfig.isDevelopment) {
        unawaited(
          FirebaseService().crashlytics.recordError(
            Exception('Notification tap processing failed: $e'),
            stackTrace,
          ),
        );
      }
    }
  }

  /// Track successful notification tap with analytics.
  void _trackNotificationTapSuccess(
    String treatmentType,
    String kind,
    String scheduleId,
  ) {
    ref.read(analyticsServiceDirectProvider).trackReminderTapped(
          treatmentType: treatmentType,
          kind: kind,
          scheduleId: scheduleId,
          result: 'success',
        );
  }

  /// Track failed notification tap with analytics.
  void _trackNotificationTapFailure(String reason) {
    ref.read(analyticsServiceDirectProvider).trackReminderTapped(
          treatmentType: 'unknown',
          kind: 'unknown',
          scheduleId: 'unknown',
          result: reason,
        );
  }

  /// Handle notification snooze action from NotificationTapHandler.
  ///
  /// This is triggered when the user taps the "Snooze 15 min" action button
  /// on a notification. The payload is processed and passed to
  /// ReminderService.snoozeCurrent() to schedule a new notification 15 minutes
  /// from now.
  ///
  /// The snooze operation is silent (no UI feedback) and non-blocking.
  /// Failures are logged but don't interrupt the user experience.
  void _handleNotificationSnooze() {
    _devLog('');
    _devLog('═══════════════════════════════════════════════════════');
    _devLog('👂 APPSHELL SNOOZE LISTENER TRIGGERED');
    _devLog('═══════════════════════════════════════════════════════');
    _devLog('Timestamp: ${DateTime.now().toIso8601String()}');

    final payload = NotificationTapHandler.pendingSnoozePayload.value;

    _devLog('Payload from NotificationTapHandler: $payload');

    // Ignore if no payload
    if (payload == null || payload.isEmpty) {
      _devLog('❌ Payload is null or empty, ignoring');
      _devLog('═══════════════════════════════════════════════════════');
      return;
    }

    _devLog('✅ Valid payload detected, clearing and scheduling processing');

    // Clear immediately to avoid re-triggering
    NotificationTapHandler.clearPendingSnooze();

    // Schedule handling after current frame
    _devLog('📅 Scheduling _processNotificationSnooze via '
        'addPostFrameCallback');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _processNotificationSnooze(payload);
    });
    _devLog('═══════════════════════════════════════════════════════');
    _devLog('');
  }

  /// Process notification snooze action.
  ///
  /// Calls ReminderService.snoozeCurrent() to handle the snooze operation.
  /// This is a silent operation - no navigation or UI changes occur.
  Future<void> _processNotificationSnooze(String payload) async {
    _devLog('');
    _devLog('═══════════════════════════════════════════════════════');
    _devLog('⏰ PROCESSING NOTIFICATION SNOOZE');
    _devLog('═══════════════════════════════════════════════════════');
    _devLog('Timestamp: ${DateTime.now().toIso8601String()}');
    _devLog('Raw payload: $payload');
    _devLog('');

    try {
      final reminderService = ref.read(reminderServiceProvider);

      _devLog('Calling ReminderService.snoozeCurrent()...');
      final result = await reminderService.snoozeCurrent(
        payload,
        ref as Ref,
      );

      _devLog('');
      _devLog('Snooze result: $result');

      if (result['success'] == true) {
        _devLog('✅ SNOOZE SUCCESSFUL');
        _devLog('  Snoozed until: ${result['snoozedUntil']}');
        _devLog('  Snooze notification ID: ${result['snoozeId']}');
      } else {
        _devLog('❌ SNOOZE FAILED');
        _devLog('  Reason: ${result['reason']}');
        // Silent failure - no user-facing error message
        // User can always tap notification again or use "Log now" action
      }

      _devLog('═══════════════════════════════════════════════════════');
      _devLog('');
    } on Exception catch (e, stackTrace) {
      _devLog('');
      _devLog('❌ ERROR processing notification snooze: $e');
      _devLog('Stack trace: $stackTrace');
      _devLog('═══════════════════════════════════════════════════════');
      _devLog('');

      // Log to Crashlytics in production
      if (!FlavorConfig.isDevelopment) {
        unawaited(
          FirebaseService().crashlytics.recordError(
            Exception('Notification snooze processing failed: $e'),
            stackTrace,
          ),
        );
      }
    }
  }

  /// Log messages only in development flavor.
  void _devLog(String message) {
    if (FlavorConfig.isDevelopment) {
      debugPrint('[AppShell Notifications] $message');
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
