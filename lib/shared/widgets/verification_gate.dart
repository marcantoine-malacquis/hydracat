import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hydracat/features/auth/models/auth_state.dart';
import 'package:hydracat/providers/auth_provider.dart';
import 'package:hydracat/shared/services/feature_gate_service.dart';

/// Widget that gates features based on email verification status
class VerificationGate extends ConsumerWidget {
  /// Creates a verification gate.
  const VerificationGate({
    required this.child,
    required this.featureId,
    super.key,
    this.fallbackWidget,
    this.showUpgradePrompt = true,
  });

  /// The widget to show when feature is accessible
  final Widget child;

  /// The feature identifier to check access for
  final String featureId;

  /// Optional widget to show when feature is blocked
  final Widget? fallbackWidget;

  /// Whether to show upgrade prompt when blocked
  final bool showUpgradePrompt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return authState.when(
      loading: () => const SizedBox.shrink(),
      unauthenticated: () =>
          fallbackWidget ??
          (showUpgradePrompt
              ? _buildUpgradePrompt(context)
              : const SizedBox.shrink()),
      authenticated: (user) {
        // Check if feature is accessible
        if (FeatureGateService.canAccessFeature(featureId)) {
          return child;
        }

        // Show fallback or upgrade prompt
        return fallbackWidget ??
            (showUpgradePrompt
                ? _buildUpgradePrompt(context)
                : const SizedBox.shrink());
      },
      error: (message, code, details) => const SizedBox.shrink(),
    );
  }

  Widget _buildUpgradePrompt(BuildContext context) {
    final reason = FeatureGateService.getBlockedReason(featureId);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.verified_user,
              size: 48,
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
            Text(
              'Verification Required',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              reason ?? 'This feature requires account verification.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => context.go('/email-verification'),
              icon: const Icon(Icons.email),
              label: const Text('Verify Email'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Simple verification gate that hides content when not accessible
class VerificationGateHidden extends ConsumerWidget {
  /// Creates a verification gate hidden.
  const VerificationGateHidden({
    required this.child,
    required this.featureId,
    super.key,
  });

  /// The widget to show when feature is accessible
  final Widget child;

  /// The feature identifier to check access for
  final String featureId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return authState.when(
      loading: () => const SizedBox.shrink(),
      unauthenticated: () => const SizedBox.shrink(),
      authenticated: (user) {
        return FeatureGateService.canAccessFeature(featureId)
            ? child
            : const SizedBox.shrink();
      },
      error: (message, code, details) => const SizedBox.shrink(),
    );
  }
}

/// Verification gate that shows a disabled state
class VerificationGateDisabled extends ConsumerWidget {
  /// Creates a verification gate disabled.
  const VerificationGateDisabled({
    required this.child,
    required this.featureId,
    super.key,
    this.onTap,
  });

  /// The widget to show when feature is accessible
  final Widget child;

  /// The feature identifier to check access for
  final String featureId;

  /// The callback to call when the feature is tapped
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return authState.when(
      loading: () => child,
      unauthenticated: () => GestureDetector(
        onTap: () => _showVerificationDialog(context),
        child: Opacity(opacity: 0.6, child: child),
      ),
      authenticated: (user) {
        final canAccess = FeatureGateService.canAccessFeature(featureId);

        return GestureDetector(
          onTap: canAccess
              ? onTap
              : () {
                  _showVerificationDialog(context);
                },
          child: Opacity(
            opacity: canAccess ? 1.0 : 0.6,
            child: child,
          ),
        );
      },
      error: (message, code, details) => child,
    );
  }

  void _showVerificationDialog(BuildContext context) {
    final reason = FeatureGateService.getBlockedReason(featureId);

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.verified_user, color: Colors.blue),
        title: const Text('Verification Required'),
        content: Text(reason ?? 'This feature requires account verification.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/email-verification');
            },
            child: const Text('Verify Email'),
          ),
        ],
      ),
    );
  }
}
