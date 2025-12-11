import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hydracat/core/constants/app_icons.dart';
import 'package:hydracat/core/theme/theme.dart';
import 'package:hydracat/features/notifications/providers/notification_provider.dart';
import 'package:hydracat/features/notifications/services/notification_cleanup_service.dart';
import 'package:hydracat/features/notifications/widgets/permission_preprompt.dart';
import 'package:hydracat/features/notifications/widgets/privacy_details_bottom_sheet.dart';
import 'package:hydracat/l10n/app_localizations.dart';
import 'package:hydracat/providers/analytics_provider.dart';
import 'package:hydracat/providers/auth_provider.dart';
import 'package:hydracat/providers/profile_provider.dart';
import 'package:hydracat/shared/widgets/widgets.dart';
import 'package:permission_handler/permission_handler.dart';

/// Screen for managing notification settings and preferences.
///
/// Provides toggles for:
/// - Master notification enable/disable
/// - Weekly summary notifications
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
    final permissionStatusAsync = ref.watch(
      notificationPermissionStatusProvider,
    );

    // Should not happen in normal flow (requires auth)
    if (currentUser == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: HydraAppBar(
          title: Text(l10n.notificationSettingsTitle),
          leading: HydraBackButton(
            onPressed: () {
              // Check if we can pop, otherwise navigate back to settings
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/profile/settings');
              }
            },
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
      appBar: HydraAppBar(
        title: Text(l10n.notificationSettingsTitle),
        leading: HydraBackButton(
          onPressed: () {
            // Check if we can pop, otherwise navigate back to settings
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/profile/settings');
            }
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // A11y: Section header - Notifications
          Semantics(
            header: true,
            label: l10n.a11ySettingsHeaderNotifications,
            child: const SizedBox.shrink(),
          ),
          // Permission status card
          permissionStatusAsync.when(
            data: (permissionStatus) =>
                _buildPermissionStatusCard(context, l10n, permissionStatus),
            loading: () => const Center(
              child: HydraProgressIndicator(),
            ),
            error: (error, stack) => _buildPermissionStatusCard(
              context,
              l10n,
              null,
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Master toggle section
          Semantics(
            label: l10n.a11yNotifMasterLabel,
            value: settings.enableNotifications ? l10n.a11yOn : l10n.a11yOff,
            hint: l10n.a11yNotifMasterHint,
            toggled: settings.enableNotifications,
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
                  Expanded(
                    child: Text(
                      l10n.notificationSettingsEnableToggleLabel,
                      style: AppTextStyles.body,
                    ),
                  ),
                  permissionStatusAsync.maybeWhen(
                    data: (permissionStatus) => HydraSwitch(
                      key: const Key('notif_master_toggle'),
                      value: settings.enableNotifications,
                      onChanged: (value) => _handleToggleNotifications(
                        context,
                        ref,
                        value,
                        permissionStatus,
                        currentUser.id,
                      ),
                    ),
                    orElse: () => const HydraSwitch(value: false),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Helper text when master toggle disabled or no pet profile
          if (!canUseFeatures || noPetProfile) ...[
            Container(
              key: const Key('notif_helper_banner'),
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  const HydraIcon(
                    icon: AppIcons.info,
                    size: 16,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final requiresPet =
                            l10n.notificationSettingsFeatureRequiresPetProfile;
                        final requiresMaster = l10n
                            .notificationSettingsFeatureRequiresMasterToggle;
                        final helperText = noPetProfile
                            ? requiresPet
                            : requiresMaster;
                        return Text(
                          helperText,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // A11y: Section header - Reminder features
          Semantics(
            header: true,
            label: l10n.a11ySettingsHeaderReminderFeatures,
            child: const SizedBox.shrink(),
          ),

          // Weekly Summary toggle section
          _buildToggleSection(
            context: context,
            icon: AppIcons.weeklySummary,
            label: l10n.notificationSettingsWeeklySummaryLabel,
            description: l10n.notificationSettingsWeeklySummaryDescription,
            value: settings.weeklySummaryEnabled,
            isLoading: _isWeeklySummaryLoading,
            isEnabled: canUseFeatures && !noPetProfile,
            onChanged: (value) => _handleToggleWeeklySummary(
              ref,
              value,
              currentUser.id,
              petId,
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // A11y: Section header - Privacy & data
          Semantics(
            header: true,
            label: l10n.a11ySettingsHeaderPrivacyAndData,
            child: const SizedBox.shrink(),
          ),

          // Privacy Policy section
          InkWell(
            key: const Key('notif_privacy_row'),
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
                  HydraIcon(
                    icon: AppIcons.privacyTip,
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
                  const HydraIcon(
                    icon: AppIcons.chevronRight,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Clear Notification Data section
          InkWell(
            onTap: noPetProfile
                ? null
                : () => _handleClearData(
                    context,
                    ref,
                    currentUser.id,
                    petId,
                  ),
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
                  const SizedBox(width: AppSpacing.sm),
                  HydraIcon(
                    icon: AppIcons.delete,
                    color: noPetProfile
                        ? AppColors.textSecondary
                        : AppColors.warning,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a toggle section with icon, label, description, and switch
  Widget _buildToggleSection({
    required BuildContext context,
    required String icon,
    required String label,
    required String description,
    required bool value,
    required bool isLoading,
    required bool isEnabled,
    // Matches Flutter's Switch.onChanged signature which uses positional bool
    // ignore: avoid_positional_boolean_parameters
    required Future<void> Function(bool) onChanged,
  }) {
    return Semantics(
      label: label == l10n.notificationSettingsWeeklySummaryLabel
          ? l10n.a11yWeeklySummaryLabel
          : l10n.a11ySnoozeLabel,
      value: value ? l10n.a11yOn : l10n.a11yOff,
      hint: () {
        final baseHint = label == l10n.notificationSettingsWeeklySummaryLabel
            ? l10n.a11yWeeklySummaryHint
            : l10n.a11ySnoozeHint;
        if (!isEnabled) {
          // Provide context-aware reason when disabled
          if (label == l10n.notificationSettingsWeeklySummaryLabel) {
            final notifEnabled = ref
                .read(
                  notificationSettingsProvider(
                    ref.read(currentUserProvider)!.id,
                  ),
                )
                .enableNotifications;
            final requirement = notifEnabled
                ? l10n.notificationSettingsFeatureRequiresPetProfile
                : l10n.notificationSettingsFeatureRequiresMasterToggle;
            return '$baseHint. $requirement';
          }
          return '$baseHint. '
              '${l10n.notificationSettingsFeatureRequiresMasterToggle}';
        }
        return baseHint;
      }(),
      toggled: value,
      child: Container(
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
        child: Row(
          children: [
            HydraIcon(
              icon: icon,
              color: isEnabled
                  ? Theme.of(context).colorScheme.primary
                  : AppColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.body.copyWith(
                      color: isEnabled
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    description,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isLoading)
              const SizedBox(
                width: 24,
                height: 24,
                child: HydraProgressIndicator(strokeWidth: 2),
              )
            else
              IgnorePointer(
                ignoring: !isEnabled,
                child: HydraSwitch(
                  key: label.contains('Weekly')
                      ? const Key('notif_weekly_toggle')
                      : label.contains('Snooze')
                      ? const Key('notif_snooze_toggle')
                      : null,
                  value: value,
                  onChanged: onChanged,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Builds permission status card showing current state
  Widget _buildPermissionStatusCard(
    BuildContext context,
    AppLocalizations l10n,
    NotificationPermissionStatus? permissionStatus,
  ) {
    final isGranted = permissionStatus == NotificationPermissionStatus.granted;
    final isPermanentlyDenied =
        permissionStatus == NotificationPermissionStatus.permanentlyDenied;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isGranted
            ? AppColors.primary.withValues(alpha: 0.1)
            : AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isGranted ? AppColors.primary : AppColors.warning,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HydraIcon(
                icon: isGranted ? AppIcons.completed : AppIcons.warning,
                color: isGranted ? AppColors.primary : AppColors.warning,
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
                    color: isGranted
                        ? AppColors.primary
                        : AppColors.textPrimary,
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
              child: Semantics(
                button: true,
                label: l10n.a11yOpenSystemSettingsLabel,
                hint: l10n.a11yOpenSystemSettingsHint,
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
            ),
          ],
        ],
      ),
    );
  }

  /// Handles toggling the weekly summary notifications switch
  Future<void> _handleToggleWeeklySummary(
    WidgetRef ref,
    bool value,
    String userId,
    String? petId,
  ) async {
    // Capture context before async gaps
    final localizations = AppLocalizations.of(context)!;

    // Check if pet profile exists
    if (petId == null) {
      if (mounted) {
        HydraSnackBar.showError(
          context,
          localizations.notificationSettingsFeatureRequiresPetProfile,
          duration: const Duration(seconds: 3),
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
      final coordinator = ref.read(notificationCoordinatorProvider);
      final resultMap = value
          ? await coordinator.scheduleWeeklySummary()
          : (await coordinator.cancelWeeklySummary()
                ? {'success': true}
                : {'success': false});

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
          HydraSnackBar.showSuccess(
            context,
            message,
            duration: const Duration(seconds: 3),
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
        HydraSnackBar.showSuccess(
          context,
          message,
          duration: const Duration(seconds: 3),
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
      HydraSnackBar.showError(
        context,
        localizations.notificationSettingsWeeklySummaryError,
        duration: const Duration(seconds: 3),
      );

      await ref
          .read(analyticsServiceDirectProvider)
          .trackWeeklySummaryToggled(
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

  /// Handles toggling the enable notifications switch
  Future<void> _handleToggleNotifications(
    BuildContext context,
    WidgetRef ref,
    bool value,
    NotificationPermissionStatus permissionStatus,
    String userId,
  ) async {
    // If turning on and permission not granted, show permission dialog
    if (value && permissionStatus != NotificationPermissionStatus.granted) {
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
    await showHydraBottomSheet<void>(
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
    final localizations = AppLocalizations.of(context)!;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => HydraAlertDialog(
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
        HydraSnackBar.showSuccess(
          context,
          localizations.notificationSettingsClearDataSuccess(
            canceledCount,
          ),
          duration: const Duration(seconds: 3),
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
      HydraSnackBar.showError(
        context,
        localizations.notificationSettingsClearDataError(
          e.toString(),
        ),
        duration: const Duration(seconds: 3),
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

// Temporary extension to provide a11y getters until l10n is regenerated.
// When codegen adds these getters, the instance members will take precedence.
/// Temporary accessibility localization extension until codegen runs.
extension A11ySemanticsL10n on AppLocalizations {
  /// Accessible value meaning the toggle is on.
  String get a11yOn => 'on';

  /// Accessible value meaning the toggle is off.
  String get a11yOff => 'off';

  /// Screen reader label for the master notifications toggle.
  String get a11yNotifMasterLabel => 'Enable notifications';

  /// Screen reader hint for the master notifications toggle.
  String get a11yNotifMasterHint => 'Turns all notification features on or off';

  /// Screen reader label for the Weekly Summary toggle.
  String get a11yWeeklySummaryLabel => 'Weekly summary notifications';

  /// Screen reader hint for the Weekly Summary toggle.
  String get a11yWeeklySummaryHint => 'Sends a summary every Monday at 9 a.m.';

  /// Screen reader label for the Snooze toggle.
  String get a11ySnoozeLabel => 'Snooze reminders';

  /// Screen reader hint for the Snooze toggle.
  String get a11ySnoozeHint => 'Allows snoozing a reminder for 15 minutes';

  /// Screen reader label for the Open Settings button.
  String get a11yOpenSystemSettingsLabel => 'Open system notification settings';

  /// Screen reader hint for the Open Settings button.
  String get a11yOpenSystemSettingsHint =>
      'Opens the device settings to manage notification permission';

  /// Section header label: Notifications.
  String get a11ySettingsHeaderNotifications => 'Notifications';

  /// Section header label: Reminder features.
  String get a11ySettingsHeaderReminderFeatures => 'Reminder features';

  /// Section header label: Privacy & data.
  String get a11ySettingsHeaderPrivacyAndData => 'Privacy & data';
}
