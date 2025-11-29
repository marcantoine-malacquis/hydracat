import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hydracat/core/constants/app_icons.dart';
import 'package:hydracat/core/theme/theme.dart';
import 'package:hydracat/features/settings/widgets/weight_unit_selector.dart';
import 'package:hydracat/providers/auth_provider.dart';
import 'package:hydracat/providers/cache_management_provider.dart';
import 'package:hydracat/providers/profile_provider.dart';
import 'package:hydracat/providers/theme_provider.dart';
import 'package:hydracat/shared/widgets/widgets.dart';

/// A screen that displays app settings and preferences.
class SettingsScreen extends ConsumerWidget {
  /// Creates a settings screen.
  const SettingsScreen({super.key});

  /// Show confirmation dialog before clearing cache
  Future<bool> _showClearCacheConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => HydraAlertDialog(
        title: const Text('Clear Cache?'),
        content: const Text(
          'This will clear locally cached summary data. '
          'Data will be reloaded from the server.\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear Cache'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  /// Clear cache and show feedback
  Future<void> _clearCache(BuildContext context, WidgetRef ref) async {
    // Show confirmation
    final confirmed = await _showClearCacheConfirmation(context);
    if (!confirmed || !context.mounted) return;

    final user = ref.read(currentUserProvider);
    final pet = ref.read(primaryPetProvider);

    if (user == null || pet == null) {
      if (context.mounted) {
        HydraSnackBar.showError(
          context,
          'Unable to clear cache: User or pet not found',
        );
      }
      return;
    }

    try {
      final cacheService = ref.read(cacheManagementServiceProvider);

      // Clear daily summaries from SharedPreferences
      final clearedCount = await cacheService.clearDailySummaries(
        user.id,
        pet.id,
      );

      // Invalidate providers to trigger refresh
      await cacheService.invalidateProviders(ref);

      if (context.mounted) {
        HydraSnackBar.showSuccess(
          context,
          'Cache cleared successfully ($clearedCount items)',
          duration: const Duration(seconds: 3),
        );
      }
    } on Exception catch (e) {
      if (context.mounted) {
        HydraSnackBar.showError(
          context,
          'Failed to clear cache: $e',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: HydraAppBar(
        title: const Text('Settings'),
        leading: HydraBackButton(
          onPressed: () {
            // Check if we can pop, otherwise navigate back to profile
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/profile');
            }
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // Weight unit selector section
          const WeightUnitSelector(),

          const SizedBox(height: AppSpacing.lg),

          // Notifications section
          InkWell(
            onTap: () => context.push('/profile/settings/notifications'),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              child: Row(
                children: [
                  HydraIcon(
                    icon: AppIcons.reminder,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Expanded(
                    child: Text(
                      'Notifications',
                      style: AppTextStyles.body,
                    ),
                  ),
                  const HydraIcon(
                    icon: AppIcons.chevronRight,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Theme toggle section
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            child: Row(
              children: [
                HydraIcon(
                  icon: AppIcons.theme,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                const Expanded(
                  child: Text(
                    'App Theme',
                    style: AppTextStyles.body,
                  ),
                ),
                Consumer(
                  builder: (context, ref, _) {
                    final currentTheme = ref.watch(themeProvider);

                    return HydraSlidingSegmentedControl<ThemeMode>(
                      value: currentTheme,
                      segments: const {
                        ThemeMode.light: HydraIcon(
                          icon: AppIcons.lightMode,
                          size: 18,
                        ),
                        ThemeMode.dark: HydraIcon(
                          icon: AppIcons.darkMode,
                          size: 18,
                        ),
                      },
                      onChanged: (ThemeMode newTheme) {
                        ref.read(themeProvider.notifier).setThemeMode(newTheme);
                      },
                      segmentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Clear Cache section
          InkWell(
            onTap: () => _clearCache(context, ref),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Clear Cache',
                          style: AppTextStyles.body,
                        ),
                        Text(
                          'Clear local cached summary data',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const HydraIcon(
                    icon: AppIcons.clearCache,
                    color: AppColors.warning,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Logout button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () => ref.read(authProvider.notifier).signOut(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: AppColors.error,
                elevation: 0,
                side: const BorderSide(color: AppColors.error, width: 1.5),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Log Out'),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // User email at bottom
          Consumer(
            builder: (context, ref, _) {
              final currentUser = ref.watch(currentUserProvider);
              if (currentUser == null) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Text(
                  'Logged in as: ${currentUser.email ?? 'No email'}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
