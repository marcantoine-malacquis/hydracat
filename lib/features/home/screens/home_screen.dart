import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hydracat/core/theme/theme.dart';
import 'package:hydracat/core/utils/date_utils.dart';
import 'package:hydracat/features/home/models/pending_fluid_treatment.dart';
import 'package:hydracat/features/home/models/pending_treatment.dart';
import 'package:hydracat/features/home/widgets/qol_home_card.dart';
import 'package:hydracat/features/home/widgets/widgets.dart';
import 'package:hydracat/features/logging/models/dashboard_logging_context.dart';
import 'package:hydracat/features/logging/screens/fluid_logging_screen.dart';
import 'package:hydracat/features/logging/screens/medication_logging_screen.dart';
import 'package:hydracat/features/logging/services/overlay_service.dart';
import 'package:hydracat/features/logging/widgets/logging_bottom_sheet_helper.dart';
import 'package:hydracat/features/notifications/widgets/notification_status_widget.dart';
import 'package:hydracat/features/profile/models/schedule.dart';
import 'package:hydracat/l10n/app_localizations.dart';
import 'package:hydracat/providers/analytics_provider.dart';
import 'package:hydracat/providers/auth_provider.dart';
import 'package:hydracat/providers/dashboard_provider.dart';
import 'package:hydracat/providers/profile_provider.dart';
import 'package:hydracat/shared/widgets/empty_states/onboarding_cta_empty_state.dart';
import 'package:hydracat/shared/widgets/fluid/water_drop_progress_card.dart';
import 'package:hydracat/shared/widgets/selection_card.dart';
import 'package:hydracat/shared/widgets/widgets.dart';

/// A screen that displays the main home interface for the HydraCat app.
class HomeScreen extends ConsumerWidget {
  /// Creates a home screen.
  ///
  /// If [bodyOnly] is true, returns only the body content without Scaffold.
  /// This is used by AppShell to separate AppBar from body for animations.
  const HomeScreen({super.key, this.bodyOnly = false});

  /// If true, returns only the body content without Scaffold.
  final bool bodyOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasCompletedOnboarding = ref.watch(hasCompletedOnboardingProvider);
    final body = hasCompletedOnboarding
        ? _HomeScreenContent.buildMainContent(context, ref)
        : OnboardingEmptyStates.home(
            onGetStarted: () => context.go('/onboarding/welcome'),
          );

    if (bodyOnly) {
      return body;
    }

    return DevBanner(
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: const HydraAppBar(
          actions: [
            NotificationStatusWidget(),
          ],
        ),
        body: body,
      ),
    );
  }

  /// Builds the body content for the home screen.
  /// This static method can be used by AppShell to get body-only content.
  static Widget buildBody(
    BuildContext context,
    WidgetRef ref, {
    required bool hasCompletedOnboarding,
  }) {
    return hasCompletedOnboarding
        ? _HomeScreenContent.buildMainContent(context, ref)
        : OnboardingEmptyStates.home(
            onGetStarted: () => context.go('/onboarding/welcome'),
          );
  }
}

/// Internal helper class for HomeScreen body content.
class _HomeScreenContent {
  /// Builds the main home content for users who have completed onboarding
  static Widget buildMainContent(BuildContext context, WidgetRef ref) {
    return Consumer(
      builder: (context, ref, child) {
        final profileState = ref.watch(profileProvider);
        final hasFluid = profileState.hasFluidSchedule;
        final hasMedication = profileState.hasMedicationSchedules;

        // Show loading skeleton if schedules haven't been loaded yet
        // medicationSchedules is null until first load completes
        if (profileState.medicationSchedules == null ||
            profileState.isLoading ||
            profileState.scheduleIsLoading) {
          return const _LoadingSkeleton();
        }

        // Show empty state with setup options if no schedules (after loading)
        if (!hasFluid && !hasMedication) {
          return const _EmptyState();
        }

        // Show main dashboard with progressive disclosure
        return _Dashboard(
          hasFluid: hasFluid,
          hasMedication: hasMedication,
        );
      },
    );
  }

  /// Open medication logging screen from dashboard with pre-selected medication
  static void _openMedicationLoggingFromDashboard(
    BuildContext context,
    WidgetRef ref,
    PendingTreatment treatment,
  ) {
    // Track analytics for opening from dashboard
    ref
        .read(analyticsServiceDirectProvider)
        .trackLoggingPopupOpened(
          popupType: 'dashboard_medication',
        );

    // Create dashboard context
    final dashboardContext = DashboardMedicationContext(
      scheduleId: treatment.schedule.id,
      scheduledTime: treatment.scheduledTime,
    );

    // Skip callback that handles dashboard state and shows success feedback
    Future<void> onSkip() async {
      try {
        // Capture host context before closing popup
        final hostContext = OverlayService.hostContext ?? context;

        // Perform skip action
        await ref
            .read(dashboardProvider.notifier)
            .skipMedicationTreatment(treatment);

        // Show success feedback using host context
        if (hostContext.mounted) {
          final l10n = AppLocalizations.of(hostContext)!;
          HydraSnackBar.showSuccess(
            hostContext,
            l10n.medicationLogged,
          );
        }
      } catch (e) {
        debugPrint('Error skipping treatment: $e');
        // Error handling - could show error popup here
        rethrow;
      }
    }

    // Show logging screen with dashboard context
    showLoggingBottomSheet(
      context,
      MedicationLoggingScreen(
        dashboardContext: dashboardContext,
        onSkipFromDashboard: onSkip,
      ),
    );
  }

  /// Open fluid logging screen from dashboard with pre-filled remaining volume
  static void _openFluidLoggingFromDashboard(
    BuildContext context,
    WidgetRef ref,
    PendingFluidTreatment pendingFluid,
  ) {
    // Track analytics for opening from dashboard
    ref
        .read(analyticsServiceDirectProvider)
        .trackLoggingPopupOpened(
          popupType: 'dashboard_fluid',
        );

    // Create dashboard context
    final dashboardContext = DashboardFluidContext(
      scheduleId: pendingFluid.schedule.id,
      remainingVolume: pendingFluid.remainingVolume,
    );

    // Show logging screen with dashboard context
    showLoggingBottomSheet(
      context,
      FluidLoggingScreen(
        dashboardContext: dashboardContext,
      ),
    );
  }
}

/// Loading skeleton widget for home screen
class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // "Today's Treatments" skeleton header
          Container(
            width: 150,
            height: 20,
            decoration: BoxDecoration(
              color: const Color(0xFFDDD6CE),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Treatment skeletons (2 medication + 1 fluid)
          const PendingTreatmentCardSkeleton(),
          const PendingTreatmentCardSkeleton(),
          const PendingFluidCardSkeleton(),
        ],
      ),
    );
  }
}

/// Empty state widget when no schedules are set up
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.pets,
              size: 64,
              color: AppColors.primary,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              "Let's Get Started!",
              style: AppTextStyles.h1.copyWith(
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              "Set up tracking for your cat's treatment",
              textAlign: TextAlign.center,
              style: AppTextStyles.body,
            ),
            const SizedBox(height: AppSpacing.xl),

            // Medication tracking option
            SizedBox(
              width: double.infinity,
              height: 140,
              child: SelectionCard(
                icon: Icons.medication_outlined,
                title: 'Track Medications',
                subtitle: 'Set up medication schedules and reminders',
                layout: CardLayout.rectangle,
                onTap: () => context.push('/profile/medication'),
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Fluid therapy option
            SizedBox(
              width: double.infinity,
              height: 140,
              child: SelectionCard(
                icon: Icons.water_drop_outlined,
                title: 'Track Fluid Therapy',
                subtitle: 'Set up subcutaneous fluid tracking',
                layout: CardLayout.rectangle,
                onTap: () => context.push('/profile/fluid/create'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dashboard widget with treatment widgets and progressive disclosure
class _Dashboard extends ConsumerWidget {
  const _Dashboard({
    required this.hasFluid,
    required this.hasMedication,
  });

  final bool hasFluid;
  final bool hasMedication;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardProvider);
    final profileState = ref.watch(profileProvider);

    // Show loading skeletons while data is loading
    if (dashboardState.isLoading) {
      return const _LoadingSkeleton();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Error state
          if (dashboardState.errorMessage != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.error,
                      size: 48,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Failed to load treatments',
                      style: AppTextStyles.h3.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      dashboardState.errorMessage!,
                      style: AppTextStyles.caption,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextButton(
                      onPressed: () =>
                          ref.read(dashboardProvider.notifier).refresh(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ]
          // Pending treatments section
          else if (dashboardState.hasPendingTreatments) ...[
            Text(
              'Today, ${AppDateUtils.formatDayMonth(DateTime.now())}',
              style: AppTextStyles.h2.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Pending medication cards
            ...dashboardState.pendingMedications.map(
              (treatment) => PendingTreatmentCard(
                treatment: treatment,
                onTap: () =>
                    _HomeScreenContent._openMedicationLoggingFromDashboard(
                      context,
                      ref,
                      treatment,
                    ),
              ),
            ),

            // Pending fluid card
            if (dashboardState.pendingFluid != null)
              PendingFluidCard(
                fluidTreatment: dashboardState.pendingFluid!,
                onTap: () => _HomeScreenContent._openFluidLoggingFromDashboard(
                  context,
                  ref,
                  dashboardState.pendingFluid!,
                ),
              ),

            const SizedBox(height: AppSpacing.xl),
          ]
          // Success empty state (all completed for today)
          else if (hasFluid || hasMedication) ...[
            _SuccessEmptyState(profileState: profileState),
            const SizedBox(height: AppSpacing.xl),
          ],

          // Weekly progress card (only show if has fluid schedule)
          if (hasFluid) ...[
            Text(
              'This Week',
              style: AppTextStyles.h2.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const WaterDropProgressCard(),
            const SizedBox(height: AppSpacing.md),
          ],

          // Quality of Life tracking card
          const QolHomeCard(),
          const SizedBox(height: AppSpacing.lg),

          // Progressive disclosure CTAs
          if (!hasMedication || !hasFluid) ...[
            Text(
              'Add More Tracking',
              style: AppTextStyles.h3.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          if (!hasMedication)
            SizedBox(
              width: double.infinity,
              height: 140,
              child: SelectionCard(
                icon: Icons.medication_outlined,
                title: 'Track Medications',
                subtitle: 'Set up medication schedules',
                layout: CardLayout.rectangle,
                onTap: () => context.push('/profile/medication'),
              ),
            ),

          if (!hasFluid) ...[
            if (!hasMedication) const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              height: 140,
              child: SelectionCard(
                icon: Icons.water_drop_outlined,
                title: 'Track Fluid Therapy',
                subtitle: 'Set up subcutaneous fluid tracking',
                layout: CardLayout.rectangle,
                onTap: () => context.push('/profile/fluid/create'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Success empty state widget with completion count
class _SuccessEmptyState extends StatelessWidget {
  const _SuccessEmptyState({
    required this.profileState,
  });

  final ProfileState profileState;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    var count = 0;

    // Count medication reminder times for today
    if (profileState.medicationSchedules != null) {
      for (final schedule in profileState.medicationSchedules!) {
        if (schedule.isActive && schedule.hasReminderTimeToday(now)) {
          count += schedule.todaysReminderTimes(now).toList().length;
        }
      }
    }

    // Count fluid reminder times for today (count each scheduled session)
    if (profileState.fluidSchedule != null &&
        profileState.fluidSchedule!.isActive &&
        profileState.fluidSchedule!.hasReminderTimeToday(now)) {
      // For fluids, count the number of scheduled times (not volume)
      count += profileState.fluidSchedule!
          .todaysReminderTimes(now)
          .toList()
          .length;
    }

    return DashboardEmptyState(completedCount: count);
  }
}
