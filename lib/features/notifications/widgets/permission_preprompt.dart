import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/core/theme/theme.dart';
import 'package:hydracat/features/notifications/providers/notification_provider.dart';
import 'package:hydracat/features/notifications/widgets/privacy_details_bottom_sheet.dart';
import 'package:hydracat/l10n/app_localizations.dart';
import 'package:hydracat/providers/analytics_provider.dart';
import 'package:hydracat/providers/auth_provider.dart';
import 'package:hydracat/providers/profile_provider.dart';
import 'package:hydracat/shared/widgets/widgets.dart';
import 'package:permission_handler/permission_handler.dart';

/// Educational pre-prompt dialog that requests notification permission
/// or directs to Settings based on current permission state.
///
/// This dialog serves as a "pre-prompt" that explains the benefits of
/// notifications before triggering the system permission dialog. Research
/// shows this approach significantly increases permission acceptance rates
/// (60-80% vs 20-40% for cold system prompts).
///
/// Shows context-appropriate messages based on permission status:
/// - notDetermined: Educational content + "Allow Notifications" button
/// - denied: Encourages enabling + "Allow Notifications" to retry
/// - permanentlyDenied: Explains need + "Open Settings" button (Android)
///
/// Features:
/// - Personalized with pet name for emotional connection
/// - Platform-specific messaging (iOS lighter, Android more emphatic)
/// - Benefit-focused language emphasizing treatment adherence
/// - In-app permission request (no app exit required)
/// - Auto-enables app setting when permission granted
/// - Complete analytics tracking for optimization
class NotificationPermissionPreprompt extends ConsumerStatefulWidget {
  /// Creates a notification permission pre-prompt dialog.
  const NotificationPermissionPreprompt({super.key});

  @override
  ConsumerState<NotificationPermissionPreprompt> createState() =>
      _NotificationPermissionPrepromptState();
}

class _NotificationPermissionPrepromptState
    extends ConsumerState<NotificationPermissionPreprompt> {
  bool _isRequesting = false;

  @override
  void initState() {
    super.initState();
    // Track dialog shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final permissionStatus =
          ref.read(notificationPermissionStatusProvider).value;
      final currentUser = ref.read(currentUserProvider);
      final reason = currentUser != null
          ? ref.read(notificationDisabledReasonProvider(currentUser.id))
          : null;

      ref
          .read(analyticsProvider.notifier)
          .service
          .trackNotificationPermissionDialogShown(
            reason: reason?.name ?? 'unknown',
            permissionStatus: permissionStatus?.name ?? 'unknown',
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final permissionStatusAsync =
        ref.watch(notificationPermissionStatusProvider);
    final primaryPet = ref.watch(primaryPetProvider);

    return permissionStatusAsync.when(
      data: (permissionStatus) => _buildDialog(
        context,
        l10n,
        permissionStatus,
        primaryPet?.name,
      ),
      loading: () => _buildLoadingDialog(context, l10n),
      error: (error, stack) =>
          _buildDialog(context, l10n, null, primaryPet?.name),
    );
  }

  /// Builds the main dialog with appropriate content based on permission state
  Widget _buildDialog(
    BuildContext context,
    AppLocalizations l10n,
    NotificationPermissionStatus? permissionStatus,
    String? petName,
  ) {
    final isPermanentlyDenied =
        permissionStatus == NotificationPermissionStatus.permanentlyDenied;

    // Determine message based on status
    final String message;
    if (petName != null) {
      if (permissionStatus == NotificationPermissionStatus.notDetermined) {
        message = l10n.notificationPermissionMessageNotDetermined(petName);
      } else if (isPermanentlyDenied) {
        message = l10n.notificationPermissionMessagePermanent(petName);
      } else {
        message = l10n.notificationPermissionMessageDenied(petName);
      }
    } else {
      // Fallback without pet name
      message = l10n.notificationPermissionMessageGeneric;
    }

    // Platform-specific hint for context
    final platformHint = Platform.isIOS
        ? l10n.notificationPermissionIosHint
        : l10n.notificationPermissionAndroidHint;

    return HydraAlertDialog(
      title: Text(l10n.notificationPermissionDialogTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main educational message
          Text(message),

          const SizedBox(height: AppSpacing.md),

          // Platform-specific hint
          if (!isPermanentlyDenied) ...[
            Text(
              platformHint,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Privacy notice
          Text(
            l10n.notificationPrivacyNoticeShort,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),

          // "Learn More" button
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => _handleLearnMoreTap(context),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                l10n.notificationPrivacyLearnMoreButton,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
      actions: [
        // Secondary button: Maybe Later
        TextButton(
          onPressed: _isRequesting ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.notificationPermissionMaybeLaterButton),
        ),

        // Primary button: Allow or Open Settings
        ElevatedButton(
          onPressed: _isRequesting
              ? null
              : () => isPermanentlyDenied
                  ? _handleOpenSettings()
                  : _handleAllowNotifications(),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: _isRequesting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  isPermanentlyDenied
                      ? l10n.notificationPermissionOpenSettingsButton
                      : l10n.notificationPermissionAllowButton,
                ),
        ),
      ],
    );
  }

  /// Builds loading dialog
  Widget _buildLoadingDialog(BuildContext context, AppLocalizations l10n) {
    return HydraAlertDialog(
      title: Text(l10n.notificationPermissionDialogTitle),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: AppSpacing.md),
          Text('Checking permission status...'),
        ],
      ),
    );
  }

  /// Handles "Learn More" button tap to show privacy details
  Future<void> _handleLearnMoreTap(BuildContext context) async {
    // Track analytics
    await ref
        .read(analyticsProvider.notifier)
        .service
        .trackNotificationPrivacyLearnMore(source: 'preprompt');

    if (!context.mounted) return;

    // Show privacy details bottom sheet
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const PrivacyDetailsBottomSheet(),
    );
  }

  /// Handles "Open Settings" button tap for permanently denied permission
  Future<void> _handleOpenSettings() async {
    await openAppSettings();

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  /// Handles "Allow Notifications" button tap to request permission
  Future<void> _handleAllowNotifications() async {
    if (_isRequesting) return;

    setState(() => _isRequesting = true);

    final previousStatus = ref.read(notificationPermissionStatusProvider).value;

    try {
      final newStatus = await ref
          .read(notificationPermissionStatusProvider.notifier)
          .requestPermission();

      // Track permission request result
      await ref
          .read(analyticsProvider.notifier)
          .service
          .trackNotificationPermissionRequested(
            previousStatus: previousStatus?.name ?? 'unknown',
            newStatus: newStatus.name,
            granted: newStatus == NotificationPermissionStatus.granted,
          );

      if (!mounted) return;

      final l10n = AppLocalizations.of(context)!;
      Navigator.of(context).pop();

      // If granted, also enable in app settings
      if (newStatus == NotificationPermissionStatus.granted) {
        final currentUser = ref.read(currentUserProvider);
        if (currentUser != null) {
          await ref
              .read(notificationSettingsProvider(currentUser.id).notifier)
              .setEnableNotifications(enabled: true);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.notificationPermissionGrantedSuccess),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else if (mounted) {
        // Permission denied - show gentle feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.notificationPermissionDeniedFeedback),
            backgroundColor: AppColors.textSecondary,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } on Exception catch (e) {
      // Handle error gracefully
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error requesting permission: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRequesting = false);
      }
    }
  }
}
