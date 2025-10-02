import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/core/theme/theme.dart';
import 'package:hydracat/providers/auth_provider.dart';
import 'package:hydracat/providers/profile_provider.dart';

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
}
