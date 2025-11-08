import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hydracat/core/theme/theme.dart';
import 'package:hydracat/core/utils/date_utils.dart';
import 'package:hydracat/core/utils/weight_utils.dart';
import 'package:hydracat/features/profile/models/cat_profile.dart';
import 'package:hydracat/features/profile/widgets/debug_panel.dart';
import 'package:hydracat/features/profile/widgets/profile_navigation_tile.dart';
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

    return DevBanner(
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Profile'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          actions: [
            IconButton(
              onPressed: () => context.go('/profile/settings'),
              icon: const Icon(Icons.settings),
              tooltip: 'Settings',
            ),
          ],
        ),
        drawer: _buildDrawer(context, ref),
        body: hasCompletedOnboarding
            ? RefreshIndicator(
                onRefresh: () => _handleRefresh(ref),
                child: _buildProfileContent(context, ref),
              )
            : OnboardingEmptyStates.profile(
                onGetStarted: () => context.go('/onboarding/welcome'),
              ),
      ),
    );
  }

  /// Handles manual refresh of profile data
  Future<void> _handleRefresh(WidgetRef ref) async {
    await ref.read(profileProvider.notifier).refreshPrimaryPet();
  }

  /// Builds the full profile content for users who have completed onboarding
  Widget _buildProfileContent(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Pet information section
            _buildPetInfoCard(context, ref),

            const SizedBox(height: AppSpacing.xl),

            // Profile sections
            _buildProfileSections(context, ref),
          ],
        ),
      ),
    );
  }

  /// Builds the pet information card
  Widget _buildPetInfoCard(BuildContext context, WidgetRef ref) {
    return Consumer(
      builder: (context, ref, _) {
        final primaryPet = ref.watch(primaryPetProvider);
        final isLoading = ref.watch(profileIsLoadingProvider);
        final isRefreshing = ref.watch(profileIsRefreshingProvider);
        final cacheStatus = ref.watch(profileCacheStatusProvider);
        final lastUpdated = ref.watch(profileLastUpdatedProvider);

        if (isLoading && primaryPet == null) {
          return _buildPetInfoSkeleton(context);
        }

        if (primaryPet == null) {
          return _buildNoPetInfo(context);
        }

        return _buildPetInfoContent(
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
  Widget _buildPetInfoContent(
    BuildContext context,
    WidgetRef ref,
    CatProfile pet, {
    required bool isRefreshing,
    required CacheStatus cacheStatus,
    required DateTime? lastUpdated,
  }) {
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
          // Header with title and refresh indicator
          Row(
            children: [
              Icon(
                Icons.pets,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Pet Information',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (isRefreshing)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
            ],
          ),

          // Cache status indicator (if stale or offline)
          if (cacheStatus == CacheStatus.stale && lastUpdated != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.orange.shade300),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.wifi_off,
                    size: 14,
                    color: Colors.orange.shade700,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'Offline – last updated '
                      '${AppDateUtils.getRelativeTimeCompact(lastUpdated)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.md),

          // Pet information grid
          _buildPetInfoGrid(context, pet),
        ],
      ),
    );
  }

  /// Builds the pet information grid
  Widget _buildPetInfoGrid(BuildContext context, CatProfile pet) {
    final infoItems = [
      _PetInfoItem(
        label: 'Name',
        value: pet.name,
        icon: Icons.pets,
        color: AppColors.info,
      ),
      _PetInfoItem(
        label: 'Age',
        value: '${pet.ageYears} years',
        icon: Icons.cake,
        color: AppColors.info,
      ),
      _PetInfoItem(
        label: 'Gender',
        value: pet.gender ?? 'Unknown',
        icon: Icons.female,
        color: AppColors.info,
      ),
      _PetInfoItem(
        label: 'Breed',
        value: pet.breed ?? 'Unknown',
        icon: Icons.category,
        color: AppColors.info,
      ),
      _PetInfoItem(
        label: 'CKD Stage',
        value: pet.medicalInfo.irisStage?.displayName ?? 'Unknown',
        icon: Icons.medical_information,
        color: AppColors.info,
      ),
      _PetInfoItem(
        label: 'Weight',
        value: pet.weightKg != null ? '' : 'Unknown', // Will be formatted below
        icon: Icons.scale,
        color: AppColors.info,
      ),
    ];

    return Column(
      children: [
        // First row - Name and Age
        Row(
          children: [
            Expanded(
              child: _buildPremiumInfoItem(
                context,
                infoItems[0],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildPremiumInfoItem(
                context,
                infoItems[1],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // Second row - Gender and Breed
        Row(
          children: [
            Expanded(
              child: _buildPremiumInfoItem(context, infoItems[2]),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildPremiumInfoItem(context, infoItems[3]),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // Third row - CKD Stage and Weight
        Consumer(
          builder: (context, ref, _) {
            final weightUnit = ref.watch(weightUnitProvider);
            final weightItem = infoItems[5].copyWith(
              value: WeightUtils.formatWeight(pet.weightKg, weightUnit),
            );

            return Row(
              children: [
                Expanded(
                  child: _buildPremiumInfoItem(
                    context,
                    infoItems[4],
                    isMedical: true,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _buildPremiumInfoItem(context, weightItem),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  /// Builds a premium info item with water-themed styling
  Widget _buildPremiumInfoItem(
    BuildContext context,
    _PetInfoItem item, {
    bool isHighlighted = false,
    bool isFullWidth = false,
    bool isMedical = false,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(isHighlighted ? AppSpacing.md : AppSpacing.sm),
      decoration: BoxDecoration(
        gradient: isHighlighted
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  item.color.withValues(alpha: 0.1),
                  item.color.withValues(alpha: 0.05),
                ],
              )
            : null,
        color: isHighlighted ? null : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(isFullWidth ? 12 : 10),
        border: Border.all(
          color: isHighlighted
              ? item.color.withValues(alpha: 0.3)
              : theme.colorScheme.outline.withValues(alpha: 0.2),
          width: isHighlighted ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isHighlighted
                ? item.color.withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: isHighlighted ? 8 : 4,
            offset: Offset(0, isHighlighted ? 2 : 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon and label row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  item.icon,
                  size: isHighlighted ? 20 : 18,
                  color: item.color,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  item.label.toUpperCase(),
                  style: AppTextStyles.small.copyWith(
                    color: item.color,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          // Value with special treatment for medical info
          if (isMedical)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                item.value,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          else
            Text(
              item.value,
              style: AppTextStyles.body.copyWith(
                fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w500,
                color: isHighlighted
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }

  /// Builds skeleton loading state
  Widget _buildPetInfoSkeleton(BuildContext context) {
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
                  child: _buildPremiumInfoItemSkeleton(
                    context,
                    isHighlighted: i == 0,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _buildPremiumInfoItemSkeleton(
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
  Widget _buildPremiumInfoItemSkeleton(
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
  Widget _buildNoPetInfo(BuildContext context) {
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
  Widget _buildDrawer(BuildContext context, WidgetRef ref) {
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
  Widget _buildProfileSections(BuildContext context, WidgetRef ref) {
    final primaryPet = ref.watch(primaryPetProvider);
    final profileState = ref.watch(profileProvider);
    final petName = primaryPet?.name ?? 'Your Cat';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // CKD Profile section
        ProfileNavigationTile(
          title: "$petName's CKD Profile",
          icon: Icons.medical_information,
          onTap: () => context.go('/profile/ckd'),
        ),

        // Fluid Schedule section (only if user has fluid schedule)
        if (profileState.hasFluidSchedule) ...[
          const SizedBox(height: AppSpacing.sm),
          ProfileNavigationTile(
            title: "$petName's Fluid Schedule",
            icon: Icons.water_drop,
            onTap: () => context.go('/profile/fluid'),
          ),
        ],

        // Add Fluid Therapy button (if no fluid schedule exists)
        if (!profileState.hasFluidSchedule) ...[
          const SizedBox(height: AppSpacing.sm),
          ProfileNavigationTile(
            title: 'Add Fluid Therapy Tracking',
            icon: Icons.add_circle_outline,
            onTap: () => context.push('/profile/fluid/create'),
          ),
        ],

        // Medication Schedule section (only if user has medication schedules)
        if (profileState.hasMedicationSchedules) ...[
          const SizedBox(height: AppSpacing.sm),
          ProfileNavigationTile(
            title: "$petName's Medication Schedule",
            icon: Icons.medication,
            onTap: () => context.go('/profile/medication'),
          ),
        ],

        // Add Medication button (if no medication schedules exist)
        if (!profileState.hasMedicationSchedules) ...[
          const SizedBox(height: AppSpacing.sm),
          ProfileNavigationTile(
            title: 'Add Medication Tracking',
            icon: Icons.add_circle_outline,
            onTap: () => context.push('/profile/medication'),
          ),
        ],

        // Weight section - always shown
        const SizedBox(height: AppSpacing.sm),
        ProfileNavigationTile(
          title: 'Weight',
          icon: Icons.scale,
          onTap: () => context.push('/profile/weight'),
        ),

        // Future sections will be added here
        // Example: Treatment Plan, etc.
      ],
    );
  }
}

/// Data class for pet information items
class _PetInfoItem {
  const _PetInfoItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  /// Creates a copy with updated values
  _PetInfoItem copyWith({
    String? label,
    String? value,
    IconData? icon,
    Color? color,
  }) {
    return _PetInfoItem(
      label: label ?? this.label,
      value: value ?? this.value,
      icon: icon ?? this.icon,
      color: color ?? this.color,
    );
  }
}
