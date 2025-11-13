import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hydracat/core/theme/theme.dart';
import 'package:hydracat/features/notifications/providers/notification_provider.dart';
import 'package:hydracat/features/notifications/widgets/permission_preprompt.dart';
import 'package:hydracat/l10n/app_localizations.dart';
import 'package:hydracat/providers/analytics_provider.dart';
import 'package:hydracat/providers/auth_provider.dart';

/// A widget that displays notification status in the app bar with a bell icon.
///
/// The icon adapts based on permission and settings state:
/// - Enabled: Normal bell (green/primary color)
/// - Disabled (not permanent): Barred bell (grey)
/// - Permanently denied: Barred bell (orange/warning)
///
/// Tapping the icon either navigates to settings or shows permission dialog
/// based on the current state.
class NotificationStatusWidget extends ConsumerWidget {
  /// Creates a notification status widget.
  const NotificationStatusWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentUser = ref.watch(currentUserProvider);
    final permissionStatusAsync =
        ref.watch(notificationPermissionStatusProvider);

    // If no user, show disabled icon (shouldn't happen in normal flow)
    if (currentUser == null) {
      return IconButton(
        icon: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryDark.withValues(alpha: 0.4),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: const Icon(
            Icons.notifications_off,
            size: 20,
            color: AppColors.textSecondary,
          ),
        ),
        tooltip: 'Notifications disabled',
        onPressed: null, // Disabled when no user
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        padding: const EdgeInsets.all(8),
      );
    }

    final isEnabled = ref.watch(isNotificationEnabledProvider(currentUser.id));

    return permissionStatusAsync.when(
      data: (permissionStatus) {
        // Determine icon
        final icon =
            isEnabled ? Icons.notifications : Icons.notifications_off;

        // Determine color
        final Color iconColor;
        if (isEnabled) {
          iconColor = AppColors.success;
        } else if (permissionStatus ==
            NotificationPermissionStatus.permanentlyDenied) {
          iconColor = AppColors.warning;
        } else {
          iconColor = AppColors.textSecondary;
        }

        // Determine tooltip
        final String tooltip;
        if (isEnabled) {
          tooltip = l10n.notificationStatusEnabledTooltip;
        } else if (permissionStatus ==
            NotificationPermissionStatus.permanentlyDenied) {
          tooltip = l10n.notificationStatusPermanentTooltip;
        } else {
          tooltip = l10n.notificationStatusDisabledTooltip;
        }

        return IconButton(
          key: const Key('notif_bell'),
          icon: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryDark.withValues(alpha: 0.4),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          tooltip: tooltip,
          onPressed: () => _handleTap(context, ref, isEnabled),
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          padding: const EdgeInsets.all(8),
        );
      },
      loading: () => IconButton(
        icon: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryDark.withValues(alpha: 0.4),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: const Icon(
            Icons.notifications_off,
            size: 20,
            color: AppColors.textSecondary,
          ),
        ),
        tooltip: 'Loading...',
        onPressed: null, // Disabled while loading
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        padding: const EdgeInsets.all(8),
      ),
      error: (error, stackTrace) => IconButton(
        icon: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryDark.withValues(alpha: 0.4),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: const Icon(
            Icons.notifications_off,
            size: 20,
            color: AppColors.textSecondary,
          ),
        ),
        tooltip: 'Unable to check notification status',
        onPressed: null, // Disabled on error
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        padding: const EdgeInsets.all(8),
      ),
    );
  }

  /// Handles tap on the notification icon.
  ///
  /// Decision logic:
  /// 1. If enabled (both permission + setting) → Navigate to settings
  /// 2. If disabled but reason is settingDisabled → Navigate to settings
  /// 3. If disabled due to permission → Show permission dialog
  Future<void> _handleTap(
    BuildContext context,
    WidgetRef ref,
    bool isEnabled,
  ) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return; // Should not happen

    // If enabled, navigate to notification settings
    if (isEnabled) {
      await Future.wait([
        context.push('/profile/settings/notifications'),
        ref
            .read(analyticsProvider.notifier)
            .service
            .trackNotificationIconTapped(
              permissionStatus: 'enabled',
              actionTaken: 'navigated_to_app_settings',
            ),
      ]);
      return;
    }

    // Check the reason for being disabled
    final reason = ref.read(notificationDisabledReasonProvider(currentUser.id));

    if (reason == NotificationDisabledReason.settingDisabled) {
      // Permission granted but app setting disabled → Go to settings
      await Future.wait([
        context.push('/profile/settings/notifications'),
        ref
            .read(analyticsProvider.notifier)
            .service
            .trackNotificationIconTapped(
              permissionStatus: 'setting_disabled',
              actionTaken: 'navigated_to_app_settings',
            ),
      ]);
    } else {
      // Permission issue → Show dialog
      final permissionStatus =
          ref.read(notificationPermissionStatusProvider).value;
      await ref
          .read(analyticsProvider.notifier)
          .service
          .trackNotificationIconTapped(
            permissionStatus: permissionStatus?.name ?? 'unknown',
            actionTaken: 'opened_permission_dialog',
          );

      if (context.mounted) {
        await showDialog<void>(
          context: context,
          builder: (context) => const NotificationPermissionPreprompt(),
        );
      }
    }
  }
}
