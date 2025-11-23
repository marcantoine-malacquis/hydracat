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
import 'package:hydracat/features/notifications/services/notification_error_handler.dart';
import 'package:hydracat/features/notifications/services/notification_tap_handler.dart';
import 'package:hydracat/features/notifications/services/permission_prompt_service.dart';
import 'package:hydracat/features/notifications/widgets/permission_preprompt.dart';
import 'package:hydracat/l10n/app_localizations.dart';
import 'package:hydracat/providers/analytics_provider.dart';
import 'package:hydracat/providers/auth_provider.dart';
import 'package:hydracat/providers/dashboard_provider.dart';
import 'package:hydracat/providers/logging_provider.dart';
import 'package:hydracat/providers/logging_queue_provider.dart';
import 'package:hydracat/providers/profile_provider.dart';
import 'package:hydracat/shared/services/firebase_service.dart';
import 'package:hydracat/shared/widgets/dialogs/no_schedules_dialog.dart';
import 'package:hydracat/shared/widgets/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

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

  // Track whether notifications have been scheduled this session
  bool _hasScheduledNotifications = false;

  // Step 6.3 state: last scheduler run date and tz offset persistence
  DateTime? _lastSchedulerRunDate; // date-only
  int? _lastTzOffsetMinutes;

  // Guards and timers
  bool _isRescheduling = false;
  Timer? _rescheduleDebounce;
  Timer? _nextMidnightTimer;
  Timer? _retryPreconditionsTimer;

  // Track whether pet profile auto-loading has been attempted
  bool _hasAttemptedPetLoad = false;

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

  int get _currentIndex {
    final currentLocation = GoRouterState.of(context).uri.path;

    // Check for special routes that should not highlight any tab
    if (currentLocation == '/logging' ||
        currentLocation.startsWith('/onboarding')) {
      return -1;
    }

    // Check nested routes using prefix matching (order matters)
    if (currentLocation.startsWith('/progress')) {
      return 1;
    }
    if (currentLocation.startsWith('/profile')) {
      return 3;
    }
    if (currentLocation.startsWith('/learn')) {
      return 2;
    }

    // Home route (exact match)
    if (currentLocation == '/') {
      return 0;
    }

    // Default fallback
    return 0;
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

    // Initialize Step 6.3 lifecycle management
    unawaited(_initSchedulerLifecycle());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    OverlayService.isShowingNotifier.removeListener(_overlayListener);
    NotificationTapHandler.pendingTapPayload.removeListener(
      _notificationTapListener,
    );
    _rescheduleDebounce?.cancel();
    _nextMidnightTimer?.cancel();
    _retryPreconditionsTimer?.cancel();
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

      // Step 6.3: check for date/tz change and handle
      _maybeHandleDateOrTzChange(trigger: 'resume');
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
      showHydraDialog<void>(
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
    _devLog(
      '📅 Scheduling _processNotificationPayload via '
      'addPostFrameCallback',
    );
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

      // Step 0: Check notification type
      _devLog('');
      _devLog('Step 0: Detecting notification type...');
      final type = payloadMap['type'] as String?;

      if (type == 'weekly_summary') {
        _devLog('✅ Detected weekly summary notification');
        await _processWeeklySummaryTap(payloadMap);
        return;
      }
      _devLog('✅ Detected treatment reminder notification (legacy path)');

      // Extract and validate required fields for treatment reminders
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
    ref
        .read(analyticsServiceDirectProvider)
        .trackReminderTapped(
          treatmentType: treatmentType,
          kind: kind,
          scheduleId: scheduleId,
          result: 'success',
        );
  }

  /// Track failed notification tap with analytics.
  void _trackNotificationTapFailure(String reason) {
    ref
        .read(analyticsServiceDirectProvider)
        .trackReminderTapped(
          treatmentType: 'unknown',
          kind: 'unknown',
          scheduleId: 'unknown',
          result: reason,
        );
  }

  /// Process weekly summary notification tap.
  ///
  /// Validates authentication/onboarding state and navigates to /progress.
  ///
  /// Algorithm:
  /// 1. Check authentication (redirect to /login if not authenticated)
  /// 2. Check onboarding completion (redirect to onboarding if incomplete)
  /// 3. Navigate to /progress using context.push('/progress')
  /// 4. Track analytics event (notification_tap with type: weekly_summary)
  /// 5. Log success
  Future<void> _processWeeklySummaryTap(Map<String, dynamic> payloadMap) async {
    _devLog('');
    _devLog('═══════════════════════════════════════════════════════');
    _devLog('📊 PROCESSING WEEKLY SUMMARY TAP');
    _devLog('═══════════════════════════════════════════════════════');
    _devLog('Timestamp: ${DateTime.now().toIso8601String()}');
    _devLog('Payload: $payloadMap');
    _devLog('');

    try {
      // Step 1: Check authentication
      _devLog('Step 1: Checking authentication...');
      final isAuthenticated = ref.read(isAuthenticatedProvider);
      _devLog('  isAuthenticated: $isAuthenticated');

      if (!isAuthenticated) {
        _devLog('❌ FAILED: User not authenticated, redirecting to login');
        _devLog('═══════════════════════════════════════════════════════');

        if (mounted) {
          context.go('/login');
          // Show contextual message after navigation
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              final l10n = AppLocalizations.of(context);
              if (l10n != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Please log in to view your weekly summary',
                    ),
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            }
          });
        }
        return;
      }
      _devLog('✅ User authenticated');

      // Step 2: Check onboarding completion
      _devLog('');
      _devLog('Step 2: Checking onboarding completion...');
      final hasCompletedOnboarding = ref.read(hasCompletedOnboardingProvider);
      _devLog('  hasCompletedOnboarding: $hasCompletedOnboarding');

      if (!hasCompletedOnboarding) {
        _devLog(
          '❌ FAILED: Onboarding not completed, redirecting to onboarding',
        );
        _devLog('═══════════════════════════════════════════════════════');

        if (mounted) {
          context.go('/onboarding/pet');
          // Show contextual message after navigation
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              final l10n = AppLocalizations.of(context);
              if (l10n != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Please complete onboarding to view your weekly summary',
                    ),
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            }
          });
        }
        return;
      }
      _devLog('✅ Onboarding completed');

      // Step 3: Navigate to /progress
      _devLog('');
      _devLog('Step 3: Navigating to /progress...');

      if (mounted) {
        unawaited(context.push('/progress'));
        _devLog('✅ Navigation initiated to /progress');
      } else {
        _devLog('❌ Context not mounted, navigation skipped');
      }

      // Step 4: Track analytics event
      _devLog('');
      _devLog('Step 4: Tracking analytics event...');
      try {
        final analyticsService = ref.read(analyticsServiceDirectProvider);
        // Track using existing method with special values for weekly summary
        await analyticsService.trackReminderTapped(
          treatmentType: 'weekly_summary',
          kind: 'notification',
          scheduleId: 'weekly',
          result: 'navigated_to_progress',
        );
        _devLog('✅ Analytics event tracked successfully');
      } on Exception catch (e) {
        _devLog('⚠️ Failed to track analytics event: $e');
        // Don't fail navigation if analytics fails
      }

      _devLog('');
      _devLog('✅ WEEKLY SUMMARY TAP PROCESSING COMPLETE');
      _devLog('═══════════════════════════════════════════════════════');
      _devLog('');
    } on Exception catch (e, stackTrace) {
      _devLog('');
      _devLog('❌ ERROR processing weekly summary tap: $e');
      _devLog('Stack trace: $stackTrace');
      _devLog('═══════════════════════════════════════════════════════');
      _devLog('');

      // Log to Crashlytics in production
      if (!FlavorConfig.isDevelopment) {
        unawaited(
          FirebaseService().crashlytics.recordError(
            Exception('Weekly summary tap processing failed: $e'),
            stackTrace,
          ),
        );
      }
    }
  }

  /// Shows the permission pre-prompt dialog proactively after onboarding.
  ///
  /// This is called once per user installation after onboarding completion.
  /// The dialog educates users about notification benefits before requesting
  /// system permission, which significantly increases acceptance rates.
  ///
  /// Marks the prompt as shown immediately (before displaying) to prevent
  /// duplicate displays if the user closes the app or navigates away during
  /// the prompt.
  Future<void> _showPermissionPreprompt() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    debugPrint(
      '[AppShell] Showing permission pre-prompt for user ${currentUser.id}',
    );

    // Mark as shown immediately to prevent duplicate displays
    await PermissionPromptService.markPromptAsShown(currentUser.id);

    // Show dialog
    if (mounted) {
      await showDialog<void>(
        context: context,
        builder: (context) => const NotificationPermissionPreprompt(),
      );
    }
  }

  /// Log messages only in development flavor.
  void _devLog(String message) {
    if (FlavorConfig.isDevelopment) {
      debugPrint('[AppShell Notifications] $message');
    }
  }

  /// Handles notification permission revocation cleanup.
  ///
  /// When permission is revoked after being granted:
  /// - Cancels all pending notifications
  /// - Clears today's notification index
  /// - Tracks analytics event
  /// - Shows user-facing dialog explaining the situation
  Future<void> _handlePermissionRevocation(String userId, String petId) async {
    _devLog('Notification permission revoked, clearing notifications');

    try {
      final plugin = ref.read(reminderPluginProvider);
      final indexStore = ref.read(notificationIndexStoreProvider);

      // Clear all pending notifications
      await plugin.cancelAll();

      // Clear today's index
      await indexStore.clearForDate(userId, petId, DateTime.now());

      // Track analytics
      final analyticsService = ref.read(analyticsServiceDirectProvider);
      await analyticsService.trackNotificationError(
        errorType: AnalyticsEvents.notificationPermissionRevoked,
        operation: 'permission_revoked_cleanup',
        userId: userId,
        petId: petId,
      );

      // Show dialog if mounted and in foreground
      if (mounted &&
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            NotificationErrorHandler.showPermissionRevokedDialog(context);
          }
        });
      }
    } on Exception catch (e) {
      await NotificationErrorHandler.reportToCrashlytics(
        operation: 'permission_revocation_cleanup',
        error: e,
        userId: userId,
        petId: petId,
      );
    }
  }

  // ===== Step 6.3: Lifecycle helpers =====

  Future<void> _initSchedulerLifecycle() async {
    await _loadSchedulerState();

    // Cold-start catch-up: if date or tz offset changed since last run
    _maybeHandleDateOrTzChange(trigger: 'startup');

    // Schedule next midnight timer
    _scheduleNextMidnightTimer();
  }

  Future<void> _loadSchedulerState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastDateStr = prefs.getString('notif_last_scheduler_run_date');
      final lastOffset = prefs.getInt('notif_last_tz_offset_minutes');

      if (lastDateStr != null) {
        // Parse yyyy-MM-dd
        final parts = lastDateStr.split('-');
        if (parts.length == 3) {
          final y = int.tryParse(parts[0]);
          final m = int.tryParse(parts[1]);
          final d = int.tryParse(parts[2]);
          if (y != null && m != null && d != null) {
            _lastSchedulerRunDate = DateTime(y, m, d);
          }
        }
      }
      if (lastOffset != null) {
        _lastTzOffsetMinutes = lastOffset;
      }
    } on Exception catch (e) {
      debugPrint('[AppShell] Failed to load scheduler state: $e');
    }
  }

  Future<void> _saveSchedulerState({
    required DateTime dateOnly,
    required int tzOffsetMinutes,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dateStr =
          '${dateOnly.year.toString().padLeft(4, '0')}-'
          '${dateOnly.month.toString().padLeft(2, '0')}-'
          '${dateOnly.day.toString().padLeft(2, '0')}';
      await prefs.setString('notif_last_scheduler_run_date', dateStr);
      await prefs.setInt('notif_last_tz_offset_minutes', tzOffsetMinutes);
      _lastSchedulerRunDate = DateTime(
        dateOnly.year,
        dateOnly.month,
        dateOnly.day,
      );
      _lastTzOffsetMinutes = tzOffsetMinutes;
    } on Exception catch (e) {
      debugPrint('[AppShell] Failed to save scheduler state: $e');
    }
  }

  int _currentTzOffsetMinutes() {
    try {
      final nowTz = tz.TZDateTime.now(tz.local);
      return nowTz.timeZoneOffset.inMinutes;
    } on Exception catch (_) {
      // Fallback to Dart DateTime if tz not available
      return DateTime.now().timeZoneOffset.inMinutes;
    }
  }

  void _maybeHandleDateOrTzChange({required String trigger}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final currentOffset = _currentTzOffsetMinutes();

    final lastDate = _lastSchedulerRunDate;
    final lastOffset = _lastTzOffsetMinutes;

    final dateChanged =
        lastDate == null ||
        lastDate.year != today.year ||
        lastDate.month != today.month ||
        lastDate.day != today.day;
    final tzChanged = lastOffset == null || lastOffset != currentOffset;

    if (!dateChanged && !tzChanged) {
      _devLog('No date/tz change detected on $trigger');
      return;
    }

    _devLog(
      'Date/TZ change detected on $trigger (dateChanged=$dateChanged, tzChanged=$tzChanged)',
    );

    // Always clear yesterday indexes (safe, local-only)
    unawaited(ref.read(notificationIndexStoreProvider).clearAllForYesterday());

    // Preconditions for reschedule
    final isAuthenticated = ref.read(isAuthenticatedProvider);
    final hasCompletedOnboarding = ref.read(hasCompletedOnboardingProvider);
    final currentUser = ref.read(currentUserProvider);
    final primaryPet = ref.read(primaryPetProvider);

    if (isAuthenticated &&
        hasCompletedOnboarding &&
        currentUser != null &&
        primaryPet != null) {
      // Check permission revocation before rescheduling
      final permissionStatusAsync = ref.read(
        notificationPermissionStatusProvider,
      );
      final settings = ref.read(notificationSettingsProvider(currentUser.id));

      permissionStatusAsync.whenData((permissionStatus) {
        if (settings.enableNotifications &&
            permissionStatus != NotificationPermissionStatus.granted) {
          // Permission was revoked - handle cleanup
          unawaited(_handlePermissionRevocation(currentUser.id, primaryPet.id));
        }
      });

      _debouncedReschedule(
        userId: currentUser.id,
        petId: primaryPet.id,
        reason: trigger,
      );
    } else {
      // Retry once shortly if not ready
      _devLog('Preconditions not ready; retrying reschedule shortly');
      _retryPreconditionsTimer?.cancel();
      _retryPreconditionsTimer = Timer(const Duration(seconds: 3), () {
        if (!mounted) return;
        final auth2 = ref.read(isAuthenticatedProvider);
        final onboard2 = ref.read(hasCompletedOnboardingProvider);
        final user2 = ref.read(currentUserProvider);
        final pet2 = ref.read(primaryPetProvider);
        if (auth2 && onboard2 && user2 != null && pet2 != null) {
          _debouncedReschedule(
            userId: user2.id,
            petId: pet2.id,
            reason: '$trigger-retry',
          );
        } else {
          _devLog(
            'Preconditions still not ready; will rely on next lifecycle event',
          );
        }
      });
    }
  }

  void _debouncedReschedule({
    required String userId,
    required String petId,
    required String reason,
  }) {
    _rescheduleDebounce?.cancel();
    _rescheduleDebounce = Timer(const Duration(milliseconds: 350), () {
      _runRescheduleFlow(userId: userId, petId: petId, reason: reason);
    });
  }

  Future<void> _runRescheduleFlow({
    required String userId,
    required String petId,
    required String reason,
  }) async {
    if (_isRescheduling) {
      _devLog('Reschedule already in progress; skipping ($reason)');
      return;
    }
    _isRescheduling = true;
    try {
      _devLog('Running rescheduleAll() due to $reason');
      final result = await ref
          .read(notificationCoordinatorProvider)
          .rescheduleAll();
      _devLog('Reschedule result: $result');

      // Persist new state
      final today = DateTime.now();
      await _saveSchedulerState(
        dateOnly: DateTime(today.year, today.month, today.day),
        tzOffsetMinutes: _currentTzOffsetMinutes(),
      );
    } on Exception catch (e) {
      _devLog('RescheduleAll failed: $e');
      // Single small retry
      await Future<void>.delayed(const Duration(seconds: 3));
      try {
        _devLog('Retrying rescheduleAll()');
        final result = await ref
            .read(notificationCoordinatorProvider)
            .rescheduleAll();
        _devLog('Reschedule retry result: $result');
        final today = DateTime.now();
        await _saveSchedulerState(
          dateOnly: DateTime(today.year, today.month, today.day),
          tzOffsetMinutes: _currentTzOffsetMinutes(),
        );
      } on Exception catch (e2, st2) {
        _devLog('Reschedule retry failed: $e2');
        if (!FlavorConfig.isDevelopment) {
          unawaited(FirebaseService().crashlytics.recordError(e2, st2));
        }
      }
    } finally {
      _isRescheduling = false;
    }
  }

  void _scheduleNextMidnightTimer() {
    try {
      _nextMidnightTimer?.cancel();

      tz.TZDateTime now;
      try {
        now = tz.TZDateTime.now(tz.local);
      } on Exception catch (_) {
        final n = DateTime.now();
        // Best-effort fallback: schedule for Dart DateTime midnight
        final fallbackMidnight = DateTime(
          n.year,
          n.month,
          n.day,
        ).add(const Duration(days: 1));
        final duration = fallbackMidnight.difference(n);
        _nextMidnightTimer = Timer(duration, _onMidnightTimerFired);
        _devLog('Scheduled fallback midnight timer in ${duration.inSeconds}s');
        return;
      }

      final nextMidnight = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
      ).add(const Duration(days: 1));
      final duration = nextMidnight.difference(now);
      _nextMidnightTimer = Timer(duration, _onMidnightTimerFired);
      _devLog('Scheduled midnight timer in ${duration.inSeconds}s');
    } on Exception catch (e) {
      _devLog('Failed to schedule midnight timer: $e');
    }
  }

  Future<void> _onMidnightTimerFired() async {
    _devLog('Midnight timer fired');

    // Always clear yesterday indexes
    await ref.read(notificationIndexStoreProvider).clearAllForYesterday();

    // If ready, reschedule all
    final isAuthenticated = ref.read(isAuthenticatedProvider);
    final hasCompletedOnboarding = ref.read(hasCompletedOnboardingProvider);
    final currentUser = ref.read(currentUserProvider);
    final primaryPet = ref.read(primaryPetProvider);

    if (isAuthenticated &&
        hasCompletedOnboarding &&
        currentUser != null &&
        primaryPet != null) {
      await _runRescheduleFlow(
        userId: currentUser.id,
        petId: primaryPet.id,
        reason: 'midnight',
      );
    } else {
      _devLog(
        'Midnight: preconditions not ready; will rely on resume/startup catch-up',
      );
    }

    // Schedule next midnight again
    _scheduleNextMidnightTimer();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authIsLoadingProvider);
    final currentUser = ref.watch(currentUserProvider);
    final isVerified = currentUser?.emailVerified ?? false;
    final currentLocation = GoRouterState.of(context).uri.path;
    final isInOnboardingFlow = currentLocation.startsWith('/onboarding');
    final isOverlayVisible = OverlayService.isShowingNotifier.value;
    final shouldHideNavBar = [
      '/profile/settings',
      '/profile/settings/notifications',
      '/profile/ckd',
      '/profile/fluid',
      '/profile/fluid/create',
      '/profile/medication',
      '/profile/weight',
    ].contains(currentLocation);

    // Load pet profile if authenticated and onboarding completed
    final hasCompletedOnboarding = ref.watch(hasCompletedOnboardingProvider);
    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    final primaryPet = ref.watch(primaryPetProvider);
    final profileIsLoading = ref.watch(profileIsLoadingProvider);

    // Trigger profile loading when conditions are met (only once)
    if (hasCompletedOnboarding &&
        isAuthenticated &&
        primaryPet == null &&
        !profileIsLoading &&
        !isLoading &&
        !_hasAttemptedPetLoad) {
      _hasAttemptedPetLoad = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          debugPrint('[AppShell] Auto-loading pet profile');
          ref.read(profileProvider.notifier).loadPrimaryPet();
        }
      });
    }

    // Reset the flag if pet is loaded (allow retry if pet becomes null again)
    if (primaryPet != null && _hasAttemptedPetLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _hasAttemptedPetLoad = false;
          });
        }
      });
    }

    // Schedule notifications on app startup (once per session)
    if (hasCompletedOnboarding &&
        isAuthenticated &&
        currentUser != null &&
        primaryPet != null &&
        !_hasScheduledNotifications) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        // Double-check flag in case multiple rebuilds happened
        if (_hasScheduledNotifications) return;

        // Mark as scheduled immediately to prevent duplicate scheduling
        setState(() {
          _hasScheduledNotifications = true;
        });

        debugPrint('[AppShell] Scheduling notifications for today');
        final coordinator = ref.read(notificationCoordinatorProvider);

        // Schedule treatment reminders for today (medication + fluid)
        await coordinator.scheduleAllForToday();

        // Schedule weekly summary notification
        debugPrint('[AppShell] Scheduling weekly summary notification');
        await coordinator.scheduleWeeklySummary();

        debugPrint('[AppShell] Notification scheduling complete');
      });
    }

    // Show permission pre-prompt proactively after onboarding completion
    if (hasCompletedOnboarding && isAuthenticated && currentUser != null) {
      // Use AsyncValue.whenData to safely extract the boolean
      ref.watch(shouldShowPermissionPromptProvider(currentUser.id)).whenData((
        shouldShow,
      ) {
        if (shouldShow) {
          // Post-frame callback to ensure stable context
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _showPermissionPreprompt();
            }
          });
        }
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
      // Hide bottom navigation during onboarding flow, on full-screen
      // profile/settings screens, and when overlay is visible
      bottomNavigationBar:
          (isInOnboardingFlow || shouldHideNavBar || isOverlayVisible)
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
