import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/core/theme/theme.dart';
import 'package:hydracat/features/notifications/services/reminder_plugin.dart';
import 'package:hydracat/features/notifications/utils/notification_id.dart';
import 'package:hydracat/l10n/app_localizations.dart';
import 'package:hydracat/providers/auth_provider.dart';
import 'package:hydracat/providers/profile_provider.dart';
import 'package:permission_handler/permission_handler.dart';
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

                // Reset action
                _buildResetAction(context, ref),

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
      // Clear profile cache first
      ref.read(profileProvider.notifier).clearCache();

      // Reset auth state (onboarding + primary pet)
      await ref.read(authProvider.notifier).debugResetUserState();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              '✅ Complete user data wipe successful! '
              'All Firestore and local data cleared.',
            ),
            backgroundColor: Colors.green.shade600,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } on Exception catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Reset failed: $e'),
            backgroundColor: Colors.red.shade600,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Shows confirmation dialog before reset
  Future<bool> _showConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
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

  /// Handles test medication notification button tap
  Future<void> _handleTestMedicationNotification(
    BuildContext context,
    WidgetRef ref,
  ) async {
    // Get localized strings before any async operations
    final l10n = AppLocalizations.of(context)!;

    try {
      // Check notification permission
      final hasPermission = await _checkNotificationPermission();
      if (!hasPermission) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Please grant notification permissions in Settings',
              ),
              backgroundColor: Colors.red.shade600,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // Get required data
      final profileState = ref.read(profileProvider);
      final medicationSchedule = profileState.medicationSchedules?.first;
      if (medicationSchedule == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('No medication schedule found'),
              backgroundColor: Colors.red.shade600,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      final currentUser = ref.read(currentUserProvider);
      final primaryPet = ref.read(primaryPetProvider);
      if (currentUser == null || primaryPet == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('User or pet data not available'),
              backgroundColor: Colors.red.shade600,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // Generate notification parameters
      final timeSlot = _getCurrentTimeSlot();
      final notificationId = generateNotificationId(
        userId: currentUser.id,
        petId: primaryPet.id,
        scheduleId: medicationSchedule.id,
        timeSlot: timeSlot,
        kind: 'initial',
      );

      // Build payload
      final payload = {
        'userId': currentUser.id,
        'petId': primaryPet.id,
        'scheduleId': medicationSchedule.id,
        'timeSlot': timeSlot,
        'kind': 'initial',
        'treatmentType': 'medication',
      };

      // Generate notification content
      final title = l10n.notificationMedicationTitle;
      final body = l10n.notificationMedicationBody(primaryPet.name);

      // Schedule notification
      final plugin = ReminderPlugin();
      await plugin.showZoned(
        id: notificationId,
        title: title,
        body: body,
        scheduledDate: _getTestScheduleTime(),
        payload: jsonEncode(payload),
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Medication test notification scheduled - '
              'will appear in 5 seconds',
            ),
            backgroundColor: Colors.green.shade600,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } on Exception catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to schedule notification: $e'),
            backgroundColor: Colors.red.shade600,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Handles test fluid notification button tap
  Future<void> _handleTestFluidNotification(
    BuildContext context,
    WidgetRef ref,
  ) async {
    // Get localized strings before any async operations
    final l10n = AppLocalizations.of(context)!;

    try {
      // Check notification permission
      final hasPermission = await _checkNotificationPermission();
      if (!hasPermission) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Please grant notification permissions in Settings',
              ),
              backgroundColor: Colors.red.shade600,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // Get required data
      final profileState = ref.read(profileProvider);
      final fluidSchedule = profileState.fluidSchedule;
      if (fluidSchedule == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('No fluid schedule found'),
              backgroundColor: Colors.red.shade600,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      final currentUser = ref.read(currentUserProvider);
      final primaryPet = ref.read(primaryPetProvider);
      if (currentUser == null || primaryPet == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('User or pet data not available'),
              backgroundColor: Colors.red.shade600,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // Generate notification parameters
      final timeSlot = _getCurrentTimeSlot();
      final notificationId = generateNotificationId(
        userId: currentUser.id,
        petId: primaryPet.id,
        scheduleId: fluidSchedule.id,
        timeSlot: timeSlot,
        kind: 'initial',
      );

      // Build payload
      final payload = {
        'userId': currentUser.id,
        'petId': primaryPet.id,
        'scheduleId': fluidSchedule.id,
        'timeSlot': timeSlot,
        'kind': 'initial',
        'treatmentType': 'fluid',
      };

      // Generate notification content
      final title = l10n.notificationFluidTitle;
      final body = l10n.notificationFluidBody(primaryPet.name);

      // Schedule notification
      final plugin = ReminderPlugin();
      await plugin.showZoned(
        id: notificationId,
        title: title,
        body: body,
        scheduledDate: _getTestScheduleTime(),
        channelId: 'fluid_reminders',
        payload: jsonEncode(payload),
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Fluid test notification scheduled - '
              'will appear in 5 seconds',
            ),
            backgroundColor: Colors.green.shade600,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } on Exception catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to schedule notification: $e'),
            backgroundColor: Colors.red.shade600,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Checks if notification permission is granted
  Future<bool> _checkNotificationPermission() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  /// Returns the scheduled time for test notifications (now + 5 seconds)
  tz.TZDateTime _getTestScheduleTime() {
    final now = DateTime.now();
    final scheduledTime = now.add(const Duration(seconds: 5));
    return tz.TZDateTime.from(scheduledTime, tz.local);
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
    final hasMedication =
        profileState.medicationSchedules?.isNotEmpty ?? false;
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
      ],
    );
  }
}
