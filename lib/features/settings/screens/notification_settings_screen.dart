import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hydracat/core/theme/theme.dart';
import 'package:hydracat/features/notifications/providers/notification_provider.dart';
import 'package:hydracat/features/notifications/services/notification_cleanup_service.dart';
import 'package:hydracat/features/notifications/widgets/permission_preprompt.dart';
import 'package:hydracat/features/notifications/widgets/privacy_details_bottom_sheet.dart';
import 'package:hydracat/l10n/app_localizations.dart';
import 'package:hydracat/providers/analytics_provider.dart';
import 'package:hydracat/providers/auth_provider.dart';
import 'package:hydracat/providers/profile_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// Screen for managing notification settings and preferences.
///
/// Provides toggles for:
/// - Master notification enable/disable
/// - Weekly summary notifications
/// - Snooze functionality for treatment reminders
///
/// Includes proper error handling, loading states, and analytics tracking.
class NotificationSettingsScreen extends ConsumerStatefulWidget {
  /// Creates a notification settings screen.
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  /// Loading state for weekly summary toggle
  bool _isWeeklySummaryLoading = false;

  @override
  Widget build(BuildContext context) {
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
    final profileState = ref.watch(profileProvider);
    final petId = profileState.primaryPet?.id;
    final noPetProfile = petId == null;
    final canUseFeatures = settings.enableNotifications;

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

          // Helper text when master toggle disabled or no pet profile
          if (!canUseFeatures || noPetProfile) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 16,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      noPetProfile
                          ? l10n
                              .notificationSettingsFeatureRequiresPetProfile
                          : l10n
                              .notificationSettingsFeatureRequiresMasterToggle,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Weekly Summary toggle section
          _buildToggleSection(
            context: context,
            icon: Icons.summarize,
            label: l10n.notificationSettingsWeeklySummaryLabel,
            description: l10n.notificationSettingsWeeklySummaryDescription,
            value: settings.weeklySummaryEnabled,
            isLoading: _isWeeklySummaryLoading,
            isEnabled: canUseFeatures && !noPetProfile,
            onChanged: (value) => _handleToggleWeeklySummary(
              context,
              ref,
              value,
              currentUser.id,
              petId,
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Snooze toggle section
          _buildToggleSection(
            context: context,
            icon: Icons.snooze,
            label: l10n.notificationSettingsSnoozeLabel,
            description: l10n.notificationSettingsSnoozeDescription,
            value: settings.snoozeEnabled,
            isLoading: false,
            isEnabled: canUseFeatures,
            onChanged: (value) => _handleToggleSnooze(
              context,
              ref,
              value,
              currentUser.id,
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Privacy Policy section
          InkWell(
            onTap: () => _handlePrivacyPolicyTap(context, ref),
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
                  Icon(
                    Icons.privacy_tip_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.notificationSettingsPrivacyPolicyLabel,
                          style: AppTextStyles.body,
                        ),
                        Text(
                          l10n.notificationSettingsPrivacyPolicyDescription,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Data Management section
          Container(
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
                Text(
                  l10n.notificationSettingsDataManagementTitle,
                  style: AppTextStyles.h3,
                ),
                const SizedBox(height: AppSpacing.sm),
                InkWell(
                  onTap: noPetProfile
                      ? null
                      : () => _handleClearData(
                            context,
                            ref,
                            currentUser.id,
                            petId,
                          ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xs,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline,
                          color: noPetProfile
                              ? AppColors.textSecondary
                              : AppColors.warning,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.notificationSettingsClearDataButton,
                                style: AppTextStyles.body.copyWith(
                                  color: noPetProfile
                                      ? AppColors.textSecondary
                                      : AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                l10n.notificationSettingsClearDataDescription,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a toggle section with icon, label, description, and switch
  Widget _buildToggleSection({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String description,
    required bool value,
    required bool isLoading,
    required bool isEnabled,
    // Matches Flutter's Switch.onChanged signature which uses positional bool
    // ignore: avoid_positional_boolean_parameters
    required Future<void> Function(bool) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isEnabled
            ? Theme.of(context).colorScheme.surface
            : Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isEnabled
              ? Theme.of(context).colorScheme.outline
              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: isEnabled
                    ? Theme.of(context).colorScheme.primary
                    : AppColors.textSecondary,
                size: 24,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.body.copyWith(
                    color: isEnabled
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
              if (isLoading)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                IgnorePointer(
                  ignoring: !isEnabled,
                  child: Switch(
                    value: value,
                    onChanged: onChanged,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Padding(
            padding: const EdgeInsets.only(left: 32),
            child: Text(
              description,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
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

  /// Handles toggling the weekly summary notifications switch
  Future<void> _handleToggleWeeklySummary(
    BuildContext context,
    WidgetRef ref,
    bool value,
    String userId,
    String? petId,
  ) async {
    // Capture context before async gaps
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final localizations = AppLocalizations.of(context)!;

    // Check if pet profile exists
    if (petId == null) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              localizations.notificationSettingsFeatureRequiresPetProfile,
            ),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    // Set loading state
    setState(() {
      _isWeeklySummaryLoading = true;
    });

    try {
      // Update settings
      await ref
          .read(notificationSettingsProvider(userId).notifier)
          .setWeeklySummaryEnabled(enabled: value);

      // Schedule or cancel weekly summary notification
      final reminderService = ref.read(reminderServiceProvider);
      final result = value
          ? await reminderService.scheduleWeeklySummary(
              userId,
              petId,
              ref,
            )
          : await reminderService.cancelWeeklySummary(
              userId,
              petId,
              ref,
            );

      // Cast to Map for type safety
      final resultMap = result as Map<String, dynamic>;

      // Check if operation was successful
      if (resultMap['success'] != true && resultMap['success'] != false) {
        // For scheduleWeeklySummary, check for specific failure reasons
        if (resultMap['reason'] == 'disabled_in_settings' ||
            resultMap['reason'] == 'already_scheduled') {
          // These are acceptable - treat as success
          if (!mounted) return;
          final message = value
              ? localizations.notificationSettingsWeeklySummarySuccess
              : localizations.notificationSettingsWeeklySummaryDisabledSuccess;
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 3),
            ),
          );
          await ref
              .read(analyticsServiceDirectProvider)
              .trackWeeklySummaryToggled(enabled: value, result: 'success');
        } else {
          // Unexpected result format
          throw Exception(resultMap['reason'] ?? 'Unknown error');
        }
      } else if (resultMap['success'] == false) {
        // Explicit failure
        throw Exception(resultMap['reason'] ?? 'Unknown error');
      } else {
        // Success
        if (!mounted) return;
        final message = value
            ? localizations.notificationSettingsWeeklySummarySuccess
            : localizations.notificationSettingsWeeklySummaryDisabledSuccess;
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 3),
          ),
        );
        await ref
            .read(analyticsServiceDirectProvider)
            .trackWeeklySummaryToggled(enabled: value, result: 'success');
      }
    } on Exception catch (e) {
      // Revert toggle on error
      if (!mounted) return;

      await ref
          .read(notificationSettingsProvider(userId).notifier)
          .setWeeklySummaryEnabled(enabled: !value);

      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(localizations.notificationSettingsWeeklySummaryError),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 3),
        ),
      );

      await ref.read(analyticsServiceDirectProvider).trackWeeklySummaryToggled(
            enabled: value,
            result: 'error',
            errorMessage: e.toString(),
          );
    } finally {
      // Clear loading state
      if (mounted) {
        setState(() {
          _isWeeklySummaryLoading = false;
        });
      }
    }
  }

  /// Handles toggling the snooze functionality switch
  Future<void> _handleToggleSnooze(
    BuildContext context,
    WidgetRef ref,
    bool value,
    String userId,
  ) async {
    // Capture context before async gap
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final localizations = AppLocalizations.of(context)!;

    // Update settings (local only, no scheduling needed)
    await ref
        .read(notificationSettingsProvider(userId).notifier)
        .setSnoozeEnabled(enabled: value);

    // Show success feedback
    if (!mounted) return;

    final message = value
        ? localizations.notificationSettingsSnoozeSuccess
        : localizations.notificationSettingsSnoozeDisabledSuccess;

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 3),
      ),
    );

    // Track analytics
    await ref
        .read(analyticsServiceDirectProvider)
        .trackSnoozeToggled(enabled: value);
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
        builder: (context) => const NotificationPermissionPreprompt(),
      );
      return;
    }

    // Otherwise, just toggle the setting
    await ref
        .read(notificationSettingsProvider(userId).notifier)
        .setEnableNotifications(enabled: value);
  }

  /// Handles tapping on the Privacy Policy row
  Future<void> _handlePrivacyPolicyTap(
    BuildContext context,
    WidgetRef ref,
  ) async {
    // Track analytics
    await ref
        .read(analyticsServiceDirectProvider)
        .trackNotificationPrivacyLearnMore(source: 'settings');

    if (!context.mounted) return;

    // Show privacy details bottom sheet
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const PrivacyDetailsBottomSheet(),
    );
  }

  /// Handles clearing notification data
  Future<void> _handleClearData(
    BuildContext context,
    WidgetRef ref,
    String userId,
    String petId,
  ) async {
    // Capture context before async gaps
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final localizations = AppLocalizations.of(context)!;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          localizations.notificationSettingsClearDataConfirmTitle,
        ),
        content: Text(
          localizations.notificationSettingsClearDataConfirmMessage,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(localizations.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.white,
            ),
            child: Text(
              localizations.notificationSettingsClearDataConfirmButton,
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      // Clear all notification data
      final cleanupService = ref.read(notificationCleanupServiceProvider);
      final result = await cleanupService.clearAllNotificationData(
        userId,
        petId,
        ref as Ref,
      );

      // Check result
      if (result['success'] == true) {
        final canceledCount = result['canceledCount'] as int;

        if (!context.mounted) return;
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              localizations.notificationSettingsClearDataSuccess(
                canceledCount,
              ),
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 3),
          ),
        );

        // Track analytics
        await ref
            .read(analyticsServiceDirectProvider)
            .trackNotificationDataCleared(
              result: 'success',
              canceledCount: canceledCount,
            );
      } else {
        // Operation failed
        throw Exception(result['error'] ?? 'Unknown error');
      }
    } on Exception catch (e) {
      if (!context.mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            localizations.notificationSettingsClearDataError(
              e.toString(),
            ),
          ),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 3),
        ),
      );

      // Track analytics
      await ref
          .read(analyticsServiceDirectProvider)
          .trackNotificationDataCleared(
            result: 'error',
            canceledCount: 0,
            errorMessage: e.toString(),
          );
    }
  }

  /// Convenience getter for localization
  AppLocalizations get l10n => AppLocalizations.of(context)!;
}
