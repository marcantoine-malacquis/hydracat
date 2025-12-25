import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hydracat/app/router.dart';
import 'package:hydracat/core/theme/theme.dart';
import 'package:hydracat/features/notifications/providers/notification_provider.dart';
import 'package:hydracat/features/notifications/services/reminder_plugin.dart';
import 'package:hydracat/features/notifications/utils/notification_id.dart';
import 'package:hydracat/features/onboarding/debug_onboarding_replay.dart';
import 'package:hydracat/l10n/app_localizations.dart';
import 'package:hydracat/providers/auth_provider.dart';
import 'package:hydracat/providers/onboarding_provider.dart';
import 'package:hydracat/providers/profile_provider.dart';
import 'package:hydracat/shared/widgets/widgets.dart';
import 'package:timezone/timezone.dart' as tz;

/// Debug panel for development testing - allows resetting user state
/// to test onboarding flows without re-authentication.
///
/// Only visible in debug mode (kDebugMode = true).
class DebugPanel extends ConsumerWidget {
  /// Creates a [DebugPanel].
  const DebugPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only show in debug mode
    if (!kDebugMode) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.orange.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(7),
                topRight: Radius.circular(7),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.bug_report,
                  size: 16,
                  color: Colors.orange.shade700,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Debug Tools (Dev Mode)',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current state display
                _buildStateDisplay(context, ref),

                const SizedBox(height: AppSpacing.sm),

                // Non-destructive replay onboarding button
                _buildReplayOnboardingAction(context, ref),

                const SizedBox(height: AppSpacing.sm),

                // Reset action
                _buildResetAction(context, ref),

                const SizedBox(height: AppSpacing.sm),

                // Restart onboarding flow
                _buildRestartOnboardingAction(context, ref),

                const SizedBox(height: AppSpacing.md),

                // Test notifications section
                _buildTestNotificationsSection(context, ref),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the current state display
  Widget _buildStateDisplay(BuildContext context, WidgetRef ref) {
    final hasCompletedOnboarding = ref.watch(hasCompletedOnboardingProvider);
    final hasPetProfile = ref.watch(hasPetProfileProvider);

    String stateDescription;
    Color stateColor;
    IconData stateIcon;

    if (hasCompletedOnboarding && hasPetProfile) {
      stateDescription = 'Completed User (has pet profile)';
      stateColor = Colors.green.shade600;
      stateIcon = Icons.check_circle;
    } else if (!hasCompletedOnboarding && !hasPetProfile) {
      stateDescription = 'Fresh User (no onboarding, no pet)';
      stateColor = Colors.blue.shade600;
      stateIcon = Icons.fiber_new;
    } else {
      stateDescription = 'Partial User (mixed state)';
      stateColor = Colors.amber.shade600;
      stateIcon = Icons.warning;
    }

    return Row(
      children: [
        Icon(
          stateIcon,
          size: 16,
          color: stateColor,
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            'Current State: $stateDescription',
            style: AppTextStyles.caption.copyWith(
              color: stateColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  /// Builds the non-destructive replay onboarding button
  Widget _buildReplayOnboardingAction(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _handleReplayOnboarding(context, ref),
        icon: const Icon(Icons.play_arrow, size: 16),
        label: const Text('Replay Onboarding (Non-Destructive)'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.green.shade700,
          side: BorderSide(color: Colors.green.shade300),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
        ),
      ),
    );
  }

  /// Handles non-destructive onboarding replay
  Future<void> _handleReplayOnboarding(
    BuildContext context,
    WidgetRef ref,
  ) async {
    try {
      await startOnboardingReplay(ref, context);

      if (context.mounted) {
        HydraSnackBar.showSuccess(
          context,
          '✅ Replay mode activated! Safe to test onboarding UI/UX. '
          'No Firestore data will be modified.',
          duration: const Duration(seconds: 3),
        );
      }
    } on Exception catch (e) {
      if (context.mounted) {
        HydraSnackBar.showError(
          context,
          '❌ Replay failed: $e',
          duration: const Duration(seconds: 3),
        );
      }
    }
  }

  /// Builds the restart onboarding button
  Widget _buildRestartOnboardingAction(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _handleRestartOnboarding(context, ref),
        icon: const Icon(Icons.replay, size: 16),
        label: const Text('Reset & Open Onboarding'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.blue.shade700,
          side: BorderSide(color: Colors.blue.shade300),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
        ),
      ),
    );
  }

  /// Builds the reset action button
  Widget _buildResetAction(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _handleResetToFreshUser(context, ref),
        icon: const Icon(Icons.refresh, size: 16),
        label: const Text('Reset to Fresh User'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.orange.shade700,
          side: BorderSide(color: Colors.orange.shade300),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
        ),
      ),
    );
  }

  /// Handles the reset to fresh user action
  Future<void> _handleResetToFreshUser(
    BuildContext context,
    WidgetRef ref,
  ) async {
    // Show confirmation dialog
    final confirmed = await _showConfirmationDialog(context);
    if (!confirmed) return;

    try {
      // Perform the reset operation
      final userId = ref.read(currentUserProvider)?.id;
      if (userId == null) {
        if (context.mounted) {
          HydraSnackBar.showError(
            context,
            '❌ No authenticated user found',
            duration: const Duration(seconds: 3),
          );
        }
        return;
      }

      await _performFreshUserReset(ref, userId);

      if (context.mounted) {
        HydraSnackBar.showSuccess(
          context,
          '✅ Complete user data wipe successful! '
          'All Firestore and local data cleared.',
          duration: const Duration(seconds: 3),
        );
      }
    } on Exception catch (e) {
      if (context.mounted) {
        HydraSnackBar.showError(
          context,
          '❌ Reset failed: $e',
          duration: const Duration(seconds: 3),
        );
      }
    }
  }

  /// Handles restarting onboarding from the welcome screen
  Future<void> _handleRestartOnboarding(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await _showConfirmationDialog(context);
    if (!confirmed) return;

    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) {
      if (context.mounted) {
        HydraSnackBar.showError(
          context,
          '❌ No authenticated user found',
          duration: const Duration(seconds: 3),
        );
      }
      return;
    }

    try {
      await _performFreshUserReset(ref, userId);

      if (!context.mounted) return;

      HydraSnackBar.showSuccess(
        context,
        'User reset — redirecting to onboarding',
        duration: const Duration(seconds: 2),
      );

      // Jump straight to the welcome step after reset
      context.go('/onboarding/welcome');
    } on Exception catch (e) {
      if (context.mounted) {
        HydraSnackBar.showError(
          context,
          '❌ Restart failed: $e',
          duration: const Duration(seconds: 3),
        );
      }
    }
  }

  /// Performs a full reset for the current user and clears caches/state.
  Future<void> _performFreshUserReset(WidgetRef ref, String userId) async {
    // Clear local caches before wiping backend/local data
    ref.read(profileProvider.notifier).clearCache();

    // Ensure onboarding checkpoints and in-memory state are clean
    await ref.read(onboardingProvider.notifier).clearOnboardingData(userId);

    // Reset auth state (clears Firestore + local caches)
    await ref.read(authProvider.notifier).debugResetUserState();

    // Force router to re-run guards with the fresh onboarding state
    ref.read(routerRefreshStreamProvider).refresh();
  }

  /// Shows confirmation dialog before reset
  Future<bool> _showConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => HydraAlertDialog(
            title: const Text('Complete User Data Reset'),
            content: const Text(
              '⚠️ WARNING: This will COMPLETELY WIPE all user data:\n\n'
              '• All Firestore data (pets, schedules, medical records, etc.)\n'
              '• All local storage and cache data\n'
              '• All onboarding progress\n\n'
              'This provides a true fresh start for testing. '
              'Your authentication will remain intact.\n\n'
              'This action cannot be undone. Continue?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                ),
                child: const Text('WIPE ALL DATA'),
              ),
            ],
          ),
        ) ??
        false;
  }

  /// Handles test immediate notification button tap
  Future<void> _handleTestImmediateNotification(
    BuildContext context,
    WidgetRef ref,
  ) async {
    debugPrint('');
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('🧪 DEBUG PANEL - Test IMMEDIATE Notification');
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('Timestamp: ${DateTime.now().toIso8601String()}');

    try {
      final plugin = ReminderPlugin();
      final notificationId = DateTime.now().millisecondsSinceEpoch % 2147483647;

      debugPrint('Showing IMMEDIATE notification...');
      debugPrint('  Notification ID: $notificationId');

      // Schedule for 1 second in the future (minimum required)
      final scheduledTime = tz.TZDateTime.now(tz.local).add(
        const Duration(seconds: 1),
      );

      debugPrint('Scheduling for: $scheduledTime');

      await plugin.showZoned(
        id: notificationId,
        title: '🔔 IMMEDIATE TEST',
        body: 'This notification should appear in 1 second!',
        scheduledDate: scheduledTime,
        payload: '{"test": "immediate"}',
      );

      debugPrint('✅ Immediate notification triggered!');
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('');

      if (context.mounted) {
        HydraSnackBar.showSuccess(
          context,
          'Test notification scheduled - will appear in 1 second!',
          duration: const Duration(seconds: 2),
        );
      }
    } on Exception catch (e) {
      debugPrint('❌ ERROR: $e');
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('');

      if (context.mounted) {
        HydraSnackBar.showError(
          context,
          'Failed: $e',
          duration: const Duration(seconds: 3),
        );
      }
    }
  }

  /// Handles test medication notification button tap
  Future<void> _handleTestMedicationNotification(
    BuildContext context,
    WidgetRef ref,
  ) async {
    debugPrint('');
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('🧪 DEBUG PANEL - Test Medication Notification');
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('Timestamp: ${DateTime.now().toIso8601String()}');

    // Get localized strings before any async operations
    final l10n = AppLocalizations.of(context)!;

    try {
      // Check notification permission
      debugPrint('Checking notification permission...');
      final hasPermission = _checkNotificationPermission(ref);
      debugPrint('  hasPermission: $hasPermission');

      if (!hasPermission) {
        debugPrint('❌ Permission denied, aborting');
        debugPrint('═══════════════════════════════════════════════════════');
        if (context.mounted) {
          HydraSnackBar.showError(
            context,
            'Please grant notification permissions in Settings',
            duration: const Duration(seconds: 3),
          );
        }
        return;
      }

      // Check exact alarm permission (Android 12+)
      debugPrint('Checking exact alarm permission (Android 12+)...');
      final plugin = ReminderPlugin();
      final canScheduleExact = await plugin.canScheduleExactNotifications();
      debugPrint('  canScheduleExactNotifications: $canScheduleExact');

      if (!canScheduleExact) {
        debugPrint('⚠️  WARNING: Exact alarm permission not granted!');
        debugPrint(
          '  Notifications may be delayed or not appear on Android 12+',
        );
        debugPrint(
          '  Go to: Settings > Apps > Hydracat Dev > '
          'Alarms & reminders > Allow',
        );
      }

      // Get required data
      debugPrint('Getting medication schedule...');
      final profileState = ref.read(profileProvider);
      final medicationSchedule = profileState.medicationSchedules?.first;

      if (medicationSchedule == null) {
        debugPrint('❌ No medication schedule found');
        debugPrint('═══════════════════════════════════════════════════════');
        if (context.mounted) {
          HydraSnackBar.showError(
            context,
            'No medication schedule found',
            duration: const Duration(seconds: 3),
          );
        }
        return;
      }
      debugPrint('  Schedule ID: ${medicationSchedule.id}');

      debugPrint('Getting user and pet data...');
      final currentUser = ref.read(currentUserProvider);
      final primaryPet = ref.read(primaryPetProvider);

      if (currentUser == null || primaryPet == null) {
        debugPrint('❌ User or pet data not available');
        debugPrint('  currentUser: $currentUser');
        debugPrint('  primaryPet: $primaryPet');
        debugPrint('═══════════════════════════════════════════════════════');
        if (context.mounted) {
          HydraSnackBar.showError(
            context,
            'User or pet data not available',
            duration: const Duration(seconds: 3),
          );
        }
        return;
      }
      debugPrint('  User ID: ${currentUser.id}');
      debugPrint('  Pet ID: ${primaryPet.id}');
      debugPrint('  Pet Name: ${primaryPet.name}');

      // Generate notification parameters
      debugPrint('Generating notification parameters...');
      final timeSlot = _getCurrentTimeSlot();
      final notificationId = generateNotificationId(
        userId: currentUser.id,
        petId: primaryPet.id,
        scheduleId: medicationSchedule.id,
        timeSlot: timeSlot,
        kind: 'initial',
      );
      debugPrint('  Notification ID: $notificationId');
      debugPrint('  Time Slot: $timeSlot');

      // Build payload
      final payload = {
        'userId': currentUser.id,
        'petId': primaryPet.id,
        'scheduleId': medicationSchedule.id,
        'timeSlot': timeSlot,
        'kind': 'initial',
        'treatmentType': 'medication',
      };
      debugPrint('Payload: ${jsonEncode(payload)}');

      // Generate notification content
      final title = l10n.notificationMedicationTitle;
      final body = l10n.notificationMedicationBody(primaryPet.name);
      debugPrint('  Title: $title');
      debugPrint('  Body: $body');

      // Schedule notification
      final scheduledTime = _getTestScheduleTime();
      debugPrint('Scheduling notification for: $scheduledTime');
      debugPrint('  (in 5 seconds from now)');

      await plugin.showZoned(
        id: notificationId,
        title: title,
        body: body,
        scheduledDate: scheduledTime,
        payload: jsonEncode(payload),
      );

      debugPrint('✅ Notification scheduled successfully!');

      // Verify the notification is actually pending
      debugPrint('');
      debugPrint('Verifying pending notifications...');
      final pendingNotifications = await plugin.pendingNotificationRequests();
      debugPrint(
        '  Total pending notifications: ${pendingNotifications.length}',
      );

      final justScheduled = pendingNotifications
          .where((n) => n.id == notificationId)
          .toList();
      if (justScheduled.isNotEmpty) {
        debugPrint('  ✅ Found our notification in pending list!');
        debugPrint('     ID: ${justScheduled.first.id}');
        debugPrint('     Title: ${justScheduled.first.title}');
        debugPrint('     Body: ${justScheduled.first.body}');
      } else {
        debugPrint('  ❌ WARNING: Notification NOT in pending list!');
        debugPrint('     This means it was silently rejected by the system.');
      }

      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('');

      if (context.mounted) {
        HydraSnackBar.showSuccess(
          context,
          'Medication test notification scheduled - '
          'will appear in 5 seconds',
          duration: const Duration(seconds: 3),
        );
      }
    } on Exception catch (e) {
      debugPrint('❌ ERROR scheduling test notification: $e');
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('');

      if (context.mounted) {
        HydraSnackBar.showError(
          context,
          'Failed to schedule notification: $e',
          duration: const Duration(seconds: 3),
        );
      }
    }
  }

  /// Handles test fluid notification button tap
  Future<void> _handleTestFluidNotification(
    BuildContext context,
    WidgetRef ref,
  ) async {
    debugPrint('');
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('🧪 DEBUG PANEL - Test Fluid Notification');
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('Timestamp: ${DateTime.now().toIso8601String()}');

    // Get localized strings before any async operations
    final l10n = AppLocalizations.of(context)!;

    try {
      // Check notification permission
      debugPrint('Checking notification permission...');
      final hasPermission = _checkNotificationPermission(ref);
      debugPrint('  hasPermission: $hasPermission');

      if (!hasPermission) {
        debugPrint('❌ Permission denied, aborting');
        debugPrint('═══════════════════════════════════════════════════════');
        if (context.mounted) {
          HydraSnackBar.showError(
            context,
            'Please grant notification permissions in Settings',
            duration: const Duration(seconds: 3),
          );
        }
        return;
      }

      // Check exact alarm permission (Android 12+)
      debugPrint('Checking exact alarm permission (Android 12+)...');
      final plugin = ReminderPlugin();
      final canScheduleExact = await plugin.canScheduleExactNotifications();
      debugPrint('  canScheduleExactNotifications: $canScheduleExact');

      if (!canScheduleExact) {
        debugPrint('⚠️  WARNING: Exact alarm permission not granted!');
        debugPrint(
          '  Notifications may be delayed or not appear on Android 12+',
        );
        debugPrint(
          '  Go to: Settings > Apps > Hydracat Dev > '
          'Alarms & reminders > Allow',
        );
      }

      // Get required data
      debugPrint('Getting fluid schedule...');
      final profileState = ref.read(profileProvider);
      final fluidSchedule = profileState.fluidSchedule;

      if (fluidSchedule == null) {
        debugPrint('❌ No fluid schedule found');
        debugPrint('═══════════════════════════════════════════════════════');
        if (context.mounted) {
          HydraSnackBar.showError(
            context,
            'No fluid schedule found',
            duration: const Duration(seconds: 3),
          );
        }
        return;
      }
      debugPrint('  Schedule ID: ${fluidSchedule.id}');

      debugPrint('Getting user and pet data...');
      final currentUser = ref.read(currentUserProvider);
      final primaryPet = ref.read(primaryPetProvider);

      if (currentUser == null || primaryPet == null) {
        debugPrint('❌ User or pet data not available');
        debugPrint('  currentUser: $currentUser');
        debugPrint('  primaryPet: $primaryPet');
        debugPrint('═══════════════════════════════════════════════════════');
        if (context.mounted) {
          HydraSnackBar.showError(
            context,
            'User or pet data not available',
            duration: const Duration(seconds: 3),
          );
        }
        return;
      }
      debugPrint('  User ID: ${currentUser.id}');
      debugPrint('  Pet ID: ${primaryPet.id}');
      debugPrint('  Pet Name: ${primaryPet.name}');

      // Generate notification parameters
      debugPrint('Generating notification parameters...');
      final timeSlot = _getCurrentTimeSlot();
      final notificationId = generateNotificationId(
        userId: currentUser.id,
        petId: primaryPet.id,
        scheduleId: fluidSchedule.id,
        timeSlot: timeSlot,
        kind: 'initial',
      );
      debugPrint('  Notification ID: $notificationId');
      debugPrint('  Time Slot: $timeSlot');

      // Build payload
      final payload = {
        'userId': currentUser.id,
        'petId': primaryPet.id,
        'scheduleId': fluidSchedule.id,
        'timeSlot': timeSlot,
        'kind': 'initial',
        'treatmentType': 'fluid',
      };
      debugPrint('Payload: ${jsonEncode(payload)}');

      // Generate notification content
      final title = l10n.notificationFluidTitle;
      final body = l10n.notificationFluidBody(primaryPet.name);
      debugPrint('  Title: $title');
      debugPrint('  Body: $body');

      // Schedule notification
      final scheduledTime = _getTestScheduleTime();
      debugPrint('Scheduling notification for: $scheduledTime');
      debugPrint('  (in 5 seconds from now)');

      await plugin.showZoned(
        id: notificationId,
        title: title,
        body: body,
        scheduledDate: scheduledTime,
        channelId: 'fluid_reminders',
        payload: jsonEncode(payload),
      );

      debugPrint('✅ Notification scheduled successfully!');
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('');

      if (context.mounted) {
        HydraSnackBar.showSuccess(
          context,
          'Fluid test notification scheduled - '
          'will appear in 5 seconds',
          duration: const Duration(seconds: 3),
        );
      }
    } on Exception catch (e) {
      debugPrint('❌ ERROR scheduling test notification: $e');
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('');

      if (context.mounted) {
        HydraSnackBar.showError(
          context,
          'Failed to schedule notification: $e',
          duration: const Duration(seconds: 3),
        );
      }
    }
  }

  /// Checks if notification permission is granted
  bool _checkNotificationPermission(WidgetRef ref) {
    final permissionStatus = ref
        .read(notificationPermissionStatusProvider)
        .value;
    return permissionStatus == NotificationPermissionStatus.granted;
  }

  /// Returns the scheduled time for test notifications (now + 5 seconds)
  tz.TZDateTime _getTestScheduleTime() {
    // Use tz.TZDateTime.now() directly to avoid timezone conversion issues
    return tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5));
  }

  /// Returns current time as "HH:mm" format
  String _getCurrentTimeSlot() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}';
  }

  /// Builds the test notifications section with test buttons
  Widget _buildTestNotificationsSection(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileProvider);
    final hasMedication = profileState.medicationSchedules?.isNotEmpty ?? false;
    final hasFluid = profileState.fluidSchedule != null;

    // If no schedules exist, show info message
    if (!hasMedication && !hasFluid) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Test Notifications',
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.orange.shade700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Add medication/fluid schedules to test notifications',
            style: AppTextStyles.small.copyWith(
              color: Colors.orange.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Text(
          'Test Notifications',
          style: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.orange.shade700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Medication test button
        if (hasMedication) ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _handleTestImmediateNotification(context, ref),
              icon: const Icon(Icons.notification_add, size: 16),
              label: const Text('Test IMMEDIATE Notification'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.green.shade700,
                side: BorderSide(color: Colors.green.shade300),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _handleTestMedicationNotification(context, ref),
              icon: const Icon(Icons.medication, size: 16),
              label: const Text('Test Medication Reminder (5s)'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange.shade700,
                side: BorderSide(color: Colors.orange.shade300),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],

        // Fluid test button
        if (hasFluid)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _handleTestFluidNotification(context, ref),
              icon: const Icon(Icons.water_drop, size: 16),
              label: const Text('Test Fluid Reminder (5s)'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange.shade700,
                side: BorderSide(color: Colors.orange.shade300),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
              ),
            ),
          ),

        // Snooze test button (works with any schedule)
        if (hasMedication || hasFluid) ...[
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _handleTestSnoozeNotification(context, ref),
              icon: const Icon(Icons.snooze, size: 16),
              label: const Text('Test Snooze Action (5s)'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.purple.shade700,
                side: BorderSide(color: Colors.purple.shade300),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
              ),
            ),
          ),
        ],

        // View pending notifications button
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _handleViewPendingNotifications(context, ref),
            icon: const Icon(Icons.list_alt, size: 16),
            label: const Text('View Pending Notifications'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blue.shade700,
              side: BorderSide(color: Colors.blue.shade300),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Handles testing a snooze notification with both action buttons.
  ///
  /// Schedules a test notification 5 seconds in the future with both
  /// "Log now" and "Snooze 15 min" action buttons. Uses first available
  /// schedule (medication or fluid).
  Future<void> _handleTestSnoozeNotification(
    BuildContext context,
    WidgetRef ref,
  ) async {
    debugPrint('');
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('🧪 DEBUG PANEL - Test Snooze Notification');
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('Timestamp: ${DateTime.now().toIso8601String()}');

    // Get localized strings before any async operations
    final l10n = AppLocalizations.of(context)!;

    try {
      // Check notification permission
      debugPrint('Checking notification permission...');
      final hasPermission = _checkNotificationPermission(ref);
      debugPrint('  hasPermission: $hasPermission');

      if (!hasPermission) {
        debugPrint('❌ Permission denied, aborting');
        debugPrint('═══════════════════════════════════════════════════════');
        if (context.mounted) {
          HydraSnackBar.showError(
            context,
            'Please grant notification permissions in Settings',
            duration: const Duration(seconds: 3),
          );
        }
        return;
      }

      // Get required data
      debugPrint('Getting first available schedule...');
      final profileState = ref.read(profileProvider);
      final medicationSchedule = profileState.medicationSchedules?.first;
      final fluidSchedule = profileState.fluidSchedule;

      // Use medication schedule if available, otherwise fluid
      String scheduleId;
      String treatmentType;
      if (medicationSchedule != null) {
        scheduleId = medicationSchedule.id;
        treatmentType = 'medication';
        debugPrint('  Using medication schedule');
      } else if (fluidSchedule != null) {
        scheduleId = fluidSchedule.id;
        treatmentType = 'fluid';
        debugPrint('  Using fluid schedule');
      } else {
        debugPrint('❌ No schedule found');
        debugPrint('═══════════════════════════════════════════════════════');
        if (context.mounted) {
          HydraSnackBar.showError(
            context,
            'No schedule found for testing',
            duration: const Duration(seconds: 3),
          );
        }
        return;
      }
      debugPrint('  Schedule ID: $scheduleId');
      debugPrint('  Treatment type: $treatmentType');

      debugPrint('Getting user and pet data...');
      final currentUser = ref.read(currentUserProvider);
      final primaryPet = ref.read(primaryPetProvider);

      if (currentUser == null || primaryPet == null) {
        debugPrint('❌ User or pet data not available');
        debugPrint('═══════════════════════════════════════════════════════');
        if (context.mounted) {
          HydraSnackBar.showError(
            context,
            'User or pet data not available',
            duration: const Duration(seconds: 3),
          );
        }
        return;
      }
      debugPrint('  User ID: ${currentUser.id}');
      debugPrint('  Pet ID: ${primaryPet.id}');
      debugPrint('  Pet Name: ${primaryPet.name}');

      // Generate notification parameters
      debugPrint('Generating notification parameters...');
      final timeSlot = _getCurrentTimeSlot();
      debugPrint('  Time slot: $timeSlot');

      final notificationId = generateNotificationId(
        userId: currentUser.id,
        petId: primaryPet.id,
        scheduleId: scheduleId,
        timeSlot: timeSlot,
        kind: 'initial',
      );
      debugPrint('  Notification ID: $notificationId');

      // Build payload
      final payload = json.encode({
        'userId': currentUser.id,
        'petId': primaryPet.id,
        'scheduleId': scheduleId,
        'timeSlot': timeSlot,
        'kind': 'initial',
        'treatmentType': treatmentType,
      });
      debugPrint('  Payload: $payload');

      // Schedule test notification for 5 seconds from now
      debugPrint('Scheduling test notification...');
      final scheduledTime = tz.TZDateTime.now(tz.local).add(
        const Duration(seconds: 5),
      );
      debugPrint('  Scheduled time: $scheduledTime');

      final plugin = ReminderPlugin();
      await plugin.showZoned(
        id: notificationId,
        title: treatmentType == 'medication'
            ? l10n.notificationMedicationTitle
            : l10n.notificationFluidTitle,
        body: treatmentType == 'medication'
            ? l10n.notificationMedicationBody(primaryPet.name)
            : l10n.notificationFluidBody(primaryPet.name),
        scheduledDate: scheduledTime,
        channelId: treatmentType == 'medication'
            ? 'medication_reminders'
            : 'fluid_reminders',
        payload: payload,
        groupId: 'pet_${primaryPet.id}',
        threadIdentifier: 'pet_${primaryPet.id}',
      );

      debugPrint('✅ Test notification scheduled successfully!');
      debugPrint('');
      debugPrint('Expected behavior:');
      debugPrint('  1. Notification appears in ~5 seconds');
      debugPrint('  2. Shows "Log now" and "Snooze 15 min" buttons');
      debugPrint('  3. Tapping "Snooze 15 min" should:');
      debugPrint('     - Dismiss the notification');
      debugPrint('     - Schedule a new notification for now+15min');
      debugPrint('     - New notification only has "Log now" button');
      debugPrint('  4. Tapping "Log now" or notification body should:');
      debugPrint('     - Open logging screen with treatment pre-selected');
      debugPrint('═══════════════════════════════════════════════════════');

      if (context.mounted) {
        HydraSnackBar.showSuccess(
          context,
          'Snooze test notification scheduled for '
          '${scheduledTime.toLocal()}',
          duration: const Duration(seconds: 3),
        );
      }
    } on Exception catch (e, stackTrace) {
      debugPrint('❌ ERROR: $e');
      debugPrint('Stack trace: $stackTrace');
      debugPrint('═══════════════════════════════════════════════════════');

      if (context.mounted) {
        HydraSnackBar.showError(
          context,
          'Failed to schedule test notification: $e',
        );
      }
    }
  }

  /// Handles viewing pending notifications.
  ///
  /// Fetches all pending notification requests from the platform and displays
  /// them in a bottom sheet with detailed information.
  Future<void> _handleViewPendingNotifications(
    BuildContext context,
    WidgetRef ref,
  ) async {
    debugPrint('');
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('🧪 DEBUG PANEL - View Pending Notifications');
    debugPrint('═══════════════════════════════════════════════════════');

    try {
      // Show loading indicator
      if (context.mounted) {
        HydraSnackBar.showInfo(
          context,
          'Fetching pending notifications...',
          duration: const Duration(seconds: 1),
        );
      }

      // Fetch pending notifications
      final plugin = ReminderPlugin();
      final pendingNotifications = await plugin.pendingNotificationRequests();

      debugPrint('Found ${pendingNotifications.length} pending notifications');

      if (context.mounted) {
        await _showPendingNotificationsBottomSheet(
          context,
          pendingNotifications,
        );
      }
    } on Exception catch (e, stackTrace) {
      debugPrint('❌ ERROR fetching pending notifications: $e');
      debugPrint('Stack trace: $stackTrace');
      debugPrint('═══════════════════════════════════════════════════════');

      if (context.mounted) {
        HydraSnackBar.showError(
          context,
          'Failed to fetch notifications: $e',
          duration: const Duration(seconds: 3),
        );
      }
    }
  }

  /// Shows the pending notifications in a bottom sheet.
  Future<void> _showPendingNotificationsBottomSheet(
    BuildContext context,
    // PendingNotificationRequest type not exported by plugin
    // ignore: avoid_dynamic_calls
    List<dynamic> pendingNotifications,
  ) async {
    await showHydraBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(16),
            ),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.list_alt, color: Colors.blue.shade700),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Pending Notifications '
                        '(${pendingNotifications.length})',
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                      color: Colors.blue.shade700,
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: pendingNotifications.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.notifications_off,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'No Pending Notifications',
                              style: AppTextStyles.body.copyWith(
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'All notifications have been delivered',
                              style: AppTextStyles.caption.copyWith(
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        itemCount: pendingNotifications.length,
                        itemBuilder: (context, index) {
                          return _buildNotificationListItem(
                            pendingNotifications[index],
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds a list item for a pending notification.
  // PendingNotificationRequest type not exported by plugin
  // ignore: avoid_annotating_with_dynamic
  Widget _buildNotificationListItem(dynamic notification) {
    // Extract basic info from notification object
    // PendingNotificationRequest type not exported by plugin
    // ignore: avoid_dynamic_calls
    final id = notification.id as int? ?? 0;
    // PendingNotificationRequest type not exported by plugin
    // ignore: avoid_dynamic_calls
    final title = notification.title as String? ?? 'No title';
    // PendingNotificationRequest type not exported by plugin
    // ignore: avoid_dynamic_calls
    final body = notification.body as String? ?? 'No body';
    // PendingNotificationRequest type not exported by plugin
    // ignore: avoid_dynamic_calls
    final payload = notification.payload as String?;

    // Parse payload
    final parsedPayload = _parseNotificationPayload(payload);

    // Determine treatment type and kind
    final treatmentType = parsedPayload?['treatmentType'] as String?;
    final kind = parsedPayload?['kind'] as String?;
    final timeSlot = parsedPayload?['timeSlot'] as String?;

    // Color coding based on treatment type
    Color accentColor;
    IconData icon;
    if (treatmentType == 'medication') {
      accentColor = Colors.orange.shade700;
      icon = Icons.medication;
    } else if (treatmentType == 'fluid') {
      accentColor = Colors.blue.shade700;
      icon = Icons.water_drop;
    } else {
      accentColor = Colors.grey.shade700;
      icon = Icons.notifications;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with ID and treatment type
            Row(
              children: [
                Icon(icon, size: 20, color: accentColor),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'ID: $id',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                ),
                if (treatmentType != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      treatmentType.toUpperCase(),
                      style: AppTextStyles.small.copyWith(
                        color: accentColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: AppSpacing.sm),

            // Title and Body
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    body,
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),

            // Metadata from payload
            if (parsedPayload != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  if (timeSlot != null)
                    _buildMetadataChip(
                      Icons.access_time,
                      'Time: $timeSlot',
                      Colors.green,
                    ),
                  if (kind != null)
                    _buildMetadataChip(
                      Icons.label,
                      'Kind: $kind',
                      Colors.purple,
                    ),
                ],
              ),
            ] else if (payload != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Invalid payload format',
                style: AppTextStyles.small.copyWith(
                  color: Colors.red.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Builds a metadata chip for notification details.
  Widget _buildMetadataChip(IconData icon, String label, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color.shade700),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.small.copyWith(
              color: color.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Parses the notification payload JSON.
  ///
  /// Returns a map of the parsed data, or null if parsing fails.
  Map<String, dynamic>? _parseNotificationPayload(String? payload) {
    if (payload == null || payload.isEmpty) {
      return null;
    }

    try {
      final parsed = json.decode(payload) as Map<String, dynamic>;
      return parsed;
    } on Exception catch (e) {
      debugPrint('Failed to parse notification payload: $e');
      return null;
    }
  }
}
