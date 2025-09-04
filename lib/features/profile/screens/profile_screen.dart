import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hydracat/core/theme/theme.dart';
import 'package:hydracat/features/auth/models/auth_state.dart';
import 'package:hydracat/providers/auth_provider.dart';
import 'package:hydracat/shared/services/feature_gate_service.dart';
import 'package:hydracat/shared/widgets/widgets.dart';

/// A screen that displays user profile information.
class ProfileScreen extends ConsumerWidget {
  /// Creates a profile screen.
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DevBanner(
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Profile'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          actions: [
            IconButton(
              onPressed: () => ref.read(authProvider.notifier).signOut(),
              icon: const Icon(Icons.logout),
              tooltip: 'Sign Out',
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Current verification status
              Consumer(
                builder: (context, ref, _) {
                  final authState = ref.watch(authProvider);
                  return authState.when(
                    loading: () => const SizedBox.shrink(),
                    unauthenticated: () => const SizedBox.shrink(),
                    authenticated: (user) {
                      final isVerified = FeatureGateService.isUserVerified;
                      return Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: isVerified
                              ? Colors.green.shade50
                              : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isVerified ? Colors.green : Colors.orange,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isVerified ? Icons.verified : Icons.warning,
                              color: isVerified ? Colors.green : Colors.orange,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isVerified
                                        ? 'Account verified'
                                        : 'Email verification pending',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isVerified
                                          ? Colors.green.shade700
                                          : Colors.orange.shade700,
                                    ),
                                  ),
                                  Text(
                                    isVerified
                                        ? 'All features available'
                                        : 'Verify your email to unlock '
                                              'premium features',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isVerified
                                          ? Colors.green.shade600
                                          : Colors.orange.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!isVerified)
                              TextButton(
                                onPressed: () =>
                                    context.go('/email-verification'),
                                child: const Text('Verify'),
                              ),
                          ],
                        ),
                      );
                    },
                    error: (message, code, details) => const SizedBox.shrink(),
                  );
                },
              ),

              const SizedBox(height: AppSpacing.xl),
              const Center(
                child: Text(
                  'Profile Screen - Coming Soon',
                  style: AppTextStyles.body,
                ),
              ),
              
              const Spacer(),
              
              // User email at bottom
              Consumer(
                builder: (context, ref, _) {
                  final authState = ref.watch(authProvider);
                  return authState.when(
                    loading: () => const SizedBox.shrink(),
                    unauthenticated: () => const SizedBox.shrink(),
                    authenticated: (user) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: Text(
                          'Logged in as: ${user.email ?? 'No email'}',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    },
                    error: (message, code, details) => const SizedBox.shrink(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
