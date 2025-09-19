import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hydracat/core/theme/theme.dart';
import 'package:hydracat/features/profile/models/cat_profile.dart';
import 'package:hydracat/features/profile/widgets/debug_panel.dart';
import 'package:hydracat/providers/auth_provider.dart';
import 'package:hydracat/providers/profile_provider.dart';
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
              onPressed: () => context.go('/settings'),
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
                      '${_formatLastUpdated(lastUpdated)}',
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
        icon: Icons.label,
      ),
      _PetInfoItem(
        label: 'Age',
        value: '${pet.ageYears} years',
        icon: Icons.cake,
      ),
      _PetInfoItem(
        label: 'Gender',
        value: pet.gender ?? 'Unknown',
        icon: Icons.pets,
      ),
      _PetInfoItem(
        label: 'Breed',
        value: pet.breed ?? 'Unknown',
        icon: Icons.category,
      ),
      _PetInfoItem(
        label: 'CKD Stage',
        value: pet.medicalInfo.irisStage?.displayName ?? 'Unknown',
        icon: Icons.medical_information,
      ),
    ];

    return Column(
      children: [
        for (int i = 0; i < infoItems.length; i += 2) ...[
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(context, infoItems[i]),
              ),
              if (i + 1 < infoItems.length) ...[
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _buildInfoItem(context, infoItems[i + 1]),
                ),
              ],
            ],
          ),
          if (i + 2 < infoItems.length) const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }

  /// Builds an individual info item
  Widget _buildInfoItem(BuildContext context, _PetInfoItem item) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                item.icon,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  item.label,
                  style: AppTextStyles.caption.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            item.value,
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w500,
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
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                width: 120,
                height: 16,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.1),
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
                Expanded(child: _buildInfoItemSkeleton(context)),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: _buildInfoItemSkeleton(context)),
              ],
            ),
            if (i < 2) const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }

  /// Builds skeleton for individual info items
  Widget _buildInfoItemSkeleton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 80,
            height: 12,
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Container(
            width: 60,
            height: 16,
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.1),
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

  /// Formats the last updated timestamp
  String _formatLastUpdated(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
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
                        color: Theme.of(context)
                            .colorScheme
                            .onPrimary
                            .withValues(alpha: 0.8),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Debug Panel
          const DebugPanel(),

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
}

/// Data class for pet information items
class _PetInfoItem {
  const _PetInfoItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;
}
