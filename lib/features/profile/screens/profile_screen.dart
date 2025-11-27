import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hydracat/core/theme/theme.dart';
import 'package:hydracat/core/utils/weight_utils.dart';
import 'package:hydracat/features/profile/models/cat_profile.dart';
import 'package:hydracat/features/profile/widgets/debug_panel.dart';
import 'package:hydracat/features/profile/widgets/pet_info_card.dart';
import 'package:hydracat/providers/auth_provider.dart';
import 'package:hydracat/providers/profile_provider.dart';
import 'package:hydracat/providers/weight_unit_provider.dart';
import 'package:hydracat/shared/widgets/empty_states/onboarding_cta_empty_state.dart';
import 'package:hydracat/shared/widgets/widgets.dart';

/// A screen that displays user profile information.
class ProfileScreen extends ConsumerWidget {
  /// Creates a profile screen.
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasCompletedOnboarding = ref.watch(hasCompletedOnboardingProvider);
    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    final primaryPet = ref.watch(primaryPetProvider);
    final isLoading = ref.watch(profileIsLoadingProvider);

    // Trigger automatic loading if conditions are met
    if (hasCompletedOnboarding &&
        isAuthenticated &&
        primaryPet == null &&
        !isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(profileProvider.notifier).loadPrimaryPet();
      });
    }

    final body = buildBody(context, ref, hasCompletedOnboarding);

    return DevBanner(
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: HydraAppBar(
          title: const Text('Profile'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          actions: [
            IconButton(
              onPressed: () => context.push('/profile/settings'),
              icon: const Icon(Icons.settings),
              tooltip: 'Settings',
            ),
          ],
        ),
        drawer: _ProfileScreenContent._buildDrawer(context, ref),
        body: body,
      ),
    );
  }

  /// Builds the body content for the profile screen.
  /// This static method can be used by AppShell to get body-only content.
  static Widget buildBody(
    BuildContext context,
    WidgetRef ref,
    bool hasCompletedOnboarding,
  ) {
    return hasCompletedOnboarding
        ? HydraRefreshIndicator(
            onRefresh: () => ref.read(profileProvider.notifier).refreshPrimaryPet(),
            child: _ProfileScreenContent.buildProfileContent(context, ref),
          )
        : OnboardingEmptyStates.profile(
            onGetStarted: () => context.go('/onboarding/welcome'),
          );
  }

  /// Builds the navigation drawer for the profile screen.
  /// This static method can be used by AppShell to get the drawer widget.
  static Widget? buildDrawer(BuildContext context, WidgetRef ref) {
    return _ProfileScreenContent._buildDrawer(context, ref);
  }
}

/// Internal helper class for ProfileScreen body content.
class _ProfileScreenContent {
  static Widget buildProfileContent(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Pet information section
            _ProfileScreenContent._buildPetInfoCard(context, ref),

            const SizedBox(height: AppSpacing.xl),

            // Profile sections
            _ProfileScreenContent._buildProfileSections(context, ref),
          ],
        ),
      ),
    );
  }

  /// Builds the pet information card
  static Widget _buildPetInfoCard(BuildContext context, WidgetRef ref) {
    return Consumer(
      builder: (context, ref, _) {
        final primaryPet = ref.watch(primaryPetProvider);
        final isLoading = ref.watch(profileIsLoadingProvider);
        final isRefreshing = ref.watch(profileIsRefreshingProvider);
        final cacheStatus = ref.watch(profileCacheStatusProvider);
        final lastUpdated = ref.watch(profileLastUpdatedProvider);

        if (isLoading && primaryPet == null) {
          return _ProfileScreenContent._buildPetInfoSkeleton(context);
        }

        if (primaryPet == null) {
          return _ProfileScreenContent._buildNoPetInfo(context);
        }

        return _ProfileScreenContent._buildPetInfoContent(
          context,
          ref,
          primaryPet,
          isRefreshing: isRefreshing,
          cacheStatus: cacheStatus,
          lastUpdated: lastUpdated,
        );
      },
    );
  }

  /// Builds the main pet info content
  static Widget _buildPetInfoContent(
    BuildContext context,
    WidgetRef ref,
    CatProfile pet, {
    required bool isRefreshing,
    required CacheStatus cacheStatus,
    required DateTime? lastUpdated,
  }) {
    return PetInfoCard(
      pet: pet,
      isRefreshing: isRefreshing,
      cacheStatus: cacheStatus,
      lastUpdated: lastUpdated,
    );
  }

  /// Builds skeleton loading state
  static Widget _buildPetInfoSkeleton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header skeleton
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                width: 120,
                height: 16,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Grid skeleton
          for (int i = 0; i < 3; i++) ...[
            Row(
              children: [
                Expanded(
                  child: _ProfileScreenContent._buildPremiumInfoItemSkeleton(
                    context,
                    isHighlighted: i == 0,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _ProfileScreenContent._buildPremiumInfoItemSkeleton(
                    context,
                    isHighlighted: i == 0,
                  ),
                ),
              ],
            ),
            if (i < 2) const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }

  /// Builds premium skeleton for individual info items
  static Widget _buildPremiumInfoItemSkeleton(
    BuildContext context, {
    bool isHighlighted = false,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(isHighlighted ? AppSpacing.md : AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
          width: isHighlighted ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: isHighlighted ? 8 : 4,
            offset: Offset(0, isHighlighted ? 2 : 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon and label skeleton
          Row(
            children: [
              Container(
                width: isHighlighted ? 36 : 32,
                height: isHighlighted ? 36 : 32,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Value skeleton
          Container(
            width: isHighlighted ? 80 : 60,
            height: 16,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds state when no pet is available
  static Widget _buildNoPetInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.pets_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'No Pet Information',
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            "Complete onboarding to add your pet's information",
            style: AppTextStyles.caption.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }


  /// Builds the navigation drawer
  static Widget _buildDrawer(BuildContext context, WidgetRef ref) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.pets,
                  size: 32,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Profile Settings',
                  style: AppTextStyles.h3.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Consumer(
                  builder: (context, ref, _) {
                    final currentUser = ref.watch(currentUserProvider);
                    return Text(
                      currentUser?.email ?? 'No email',
                      style: AppTextStyles.caption.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onPrimary.withValues(alpha: 0.8),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Debug Panel
          if (kDebugMode) const DebugPanel(),

          // Divider
          const Divider(),

          // Settings options could go here in the future
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About'),
            onTap: () {
              Navigator.pop(context);
              // Navigate to about screen when implemented
            },
          ),
        ],
      ),
    );
  }

  /// Builds the profile sections list
  static Widget _buildProfileSections(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileProvider);
    final primaryPet = ref.watch(primaryPetProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // CKD Profile section with IRIS stage metadata
        NavigationCard(
          title: 'CKD Profile',
          icon: Icons.medical_information,
          metadata: primaryPet?.medicalInfo.irisStage?.displayName,
          onTap: () => context.push('/profile/ckd'),
          margin: EdgeInsets.zero,
        ),

        // Fluid Schedule section (only if user has fluid schedule)
        if (profileState.hasFluidSchedule) ...[
          const SizedBox(height: AppSpacing.sm),
          Consumer(
            builder: (context, ref, _) {
              final fluidSchedule = profileState.fluidSchedule;
              String? metadata;
              if (fluidSchedule != null) {
                final volume = fluidSchedule.targetVolume?.toInt() ?? 0;
                final frequency = fluidSchedule.frequency.displayName;
                metadata = '${volume}ml, $frequency';
              }
              return NavigationCard(
                title: 'Fluid Schedule',
                icon: Icons.water_drop,
                metadata: metadata,
                onTap: () => context.push('/profile/fluid'),
                margin: EdgeInsets.zero,
              );
            },
          ),
        ],

        // Add Fluid Therapy button (if no fluid schedule exists)
        if (!profileState.hasFluidSchedule) ...[
          const SizedBox(height: AppSpacing.sm),
          NavigationCard(
            title: 'Add Fluid Therapy Tracking',
            icon: Icons.add_circle_outline,
            onTap: () => context.push('/profile/fluid/create'),
            margin: EdgeInsets.zero,
          ),
        ],

        // Medication Schedule section (only if user has medication schedules)
        if (profileState.hasMedicationSchedules) ...[
          const SizedBox(height: AppSpacing.sm),
          Consumer(
            builder: (context, ref, _) {
              final count = ref.watch(medicationScheduleCountProvider);
              final metadata =
                  '$count ${count == 1 ? 'medication' : 'medications'}';
              return NavigationCard(
                title: 'Medication Schedule',
                icon: Icons.medication,
                metadata: metadata,
                onTap: () => context.push('/profile/medication'),
                margin: EdgeInsets.zero,
              );
            },
          ),
        ],

        // Add Medication button (if no medication schedules exist)
        if (!profileState.hasMedicationSchedules) ...[
          const SizedBox(height: AppSpacing.sm),
          NavigationCard(
            title: 'Add Medication Tracking',
            icon: Icons.add_circle_outline,
            onTap: () => context.push('/profile/medication'),
            margin: EdgeInsets.zero,
          ),
        ],

        // Weight section - always shown with current weight
        const SizedBox(height: AppSpacing.sm),
        Consumer(
          builder: (context, ref, _) {
            final weightUnit = ref.watch(weightUnitProvider);
            final metadata =
                WeightUtils.formatWeight(primaryPet?.weightKg, weightUnit);
            return NavigationCard(
              title: 'Weight',
              icon: Icons.scale,
              metadata: metadata,
              onTap: () => context.push('/profile/weight'),
              margin: EdgeInsets.zero,
            );
          },
        ),

        // Future sections will be added here
        // Example: Treatment Plan, etc.
      ],
    );
  }
}
