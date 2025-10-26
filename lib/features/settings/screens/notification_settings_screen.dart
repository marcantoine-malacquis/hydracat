import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hydracat/core/theme/theme.dart';
import 'package:hydracat/features/notifications/providers/notification_provider.dart';
import 'package:hydracat/features/notifications/widgets/notification_permission_dialog.dart';
import 'package:hydracat/l10n/app_localizations.dart';
import 'package:hydracat/providers/auth_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// Screen for managing notification settings and preferences.
///
/// Currently a placeholder with master toggle. Will be expanded in Phase 5
/// to include:
/// - Weekly summary toggle
/// - Snooze toggle
/// - End-of-day reminder toggle and time picker
/// - Notification content privacy settings
class NotificationSettingsScreen extends ConsumerWidget {
  /// Creates a notification settings screen.
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentUser = ref.watch(currentUserProvider);
    final permissionStatusAsync =
        ref.watch(notificationPermissionStatusProvider);

    // Should not happen in normal flow (requires auth)
    if (currentUser == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(l10n.notificationSettingsTitle),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_ios),
            iconSize: 20,
            color: AppColors.textSecondary,
            tooltip: 'Back',
          ),
        ),
        body: const Center(
          child: Text('Please log in to manage notification settings'),
        ),
      );
    }

    final settings = ref.watch(notificationSettingsProvider(currentUser.id));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.notificationSettingsTitle),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios),
          iconSize: 20,
          color: AppColors.textSecondary,
          tooltip: 'Back',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // Permission status card
          permissionStatusAsync.when(
            data: (permissionStatus) =>
                _buildPermissionStatusCard(context, l10n, permissionStatus),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => _buildPermissionStatusCard(
              context,
              l10n,
              null,
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Master toggle section
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
                Icon(
                  Icons.notifications,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    l10n.notificationSettingsEnableToggleLabel,
                    style: AppTextStyles.body,
                  ),
                ),
                permissionStatusAsync.maybeWhen(
                  data: (permissionStatus) => Switch(
                    value: settings.enableNotifications,
                    onChanged: (value) => _handleToggleNotifications(
                      context,
                      ref,
                      value,
                      permissionStatus,
                      currentUser.id,
                    ),
                  ),
                  orElse: () => const Switch(value: false, onChanged: null),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Future features placeholder
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surface
                  .withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Coming Soon',
                      style: AppTextStyles.h3.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.notificationSettingsFuturePlaceholder,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds permission status card showing current state
  Widget _buildPermissionStatusCard(
    BuildContext context,
    AppLocalizations l10n,
    NotificationPermissionStatus? permissionStatus,
  ) {
    final isGranted =
        permissionStatus == NotificationPermissionStatus.granted;
    final isPermanentlyDenied =
        permissionStatus == NotificationPermissionStatus.permanentlyDenied;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isGranted
            ? AppColors.success.withValues(alpha: 0.1)
            : AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isGranted ? AppColors.success : AppColors.warning,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isGranted ? Icons.check_circle : Icons.warning,
                color: isGranted ? AppColors.success : AppColors.warning,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  isGranted
                      ? l10n.notificationSettingsPermissionGranted
                      : l10n.notificationSettingsPermissionDenied,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color:
                        isGranted ? AppColors.success : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),

          // Show "Open Settings" button if permission denied
          if (!isGranted) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.notificationSettingsPermissionBannerMessage,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: isPermanentlyDenied
                    ? openAppSettings
                    : null, // Will be handled by toggle
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.warning,
                  side: const BorderSide(color: AppColors.warning),
                ),
                child: Text(l10n.notificationSettingsOpenSettingsButton),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Handles toggling the enable notifications switch
  Future<void> _handleToggleNotifications(
    BuildContext context,
    WidgetRef ref,
    bool value,
    NotificationPermissionStatus permissionStatus,
    String userId,
  ) async {
    // If turning on and permission not granted, show permission dialog
    if (value &&
        permissionStatus != NotificationPermissionStatus.granted) {
      await showDialog<void>(
        context: context,
        builder: (context) => const NotificationPermissionDialog(),
      );
      return;
    }

    // Otherwise, just toggle the setting
    await ref
        .read(notificationSettingsProvider(userId).notifier)
        .setEnableNotifications(enabled: value);
  }
}
