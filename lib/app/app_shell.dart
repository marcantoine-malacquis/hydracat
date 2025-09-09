import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hydracat/core/constants/app_icons.dart';
import 'package:hydracat/providers/auth_provider.dart';
import 'package:hydracat/shared/widgets/navigation/hydra_navigation_bar.dart';

/// Main app shell that provides consistent navigation and layout.
class AppShell extends ConsumerStatefulWidget {
  /// Creates an AppShell with the specified child.
  const AppShell({
    required this.child,
    super.key,
  });

  /// The main content to display.
  final Widget child;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  final List<HydraNavigationItem> _navigationItems = const [
    HydraNavigationItem(icon: AppIcons.home, label: 'Home', route: '/'),
    HydraNavigationItem(
      icon: AppIcons.progress,
      label: 'Progress',
      route: '/progress',
    ),
    HydraNavigationItem(
      icon: AppIcons.learn,
      label: 'Learn',
      route: '/learn',
    ),
    HydraNavigationItem(
      icon: AppIcons.profile,
      label: 'Profile',
      route: '/profile',
    ),
  ];

  int get _currentIndex {
    final currentLocation = GoRouterState.of(context).uri.path;
    for (var i = 0; i < _navigationItems.length; i++) {
      if (_navigationItems[i].route == currentLocation) {
        return i;
      }
    }
    // If on logging screen, don't highlight any nav item
    if (currentLocation == '/logging') {
      return -1;
    }
    return 0; // Default to home
  }

  void _onNavigationTap(int index) {
    final route = _navigationItems[index].route;
    if (route != null) {
      context.go(route);
    }
  }

  void _onFabPressed() {
    context.go('/logging');
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authIsLoadingProvider);
    final currentUser = ref.watch(currentUserProvider);
    final isVerified = currentUser?.emailVerified ?? false;

    return Scaffold(
      body: Column(
        children: [
          // Show verification banner for verified users only 
          // (not during loading)
          if (currentUser != null && !currentUser.emailVerified)
            _buildVerificationBanner(context, currentUser.email),
          Expanded(
            child: isLoading
                ? _buildLoadingContent(context)
                : widget.child,
          ),
        ],
      ),
      bottomNavigationBar: HydraNavigationBar(
        items: _navigationItems,
        // No selection during loading
        currentIndex: isLoading ? -1 : _currentIndex,
        // Disable navigation during loading
        onTap: isLoading ? (_) {} : _onNavigationTap,
        // Disable FAB during loading
        onFabPressed: isLoading ? null : _onFabPressed,
        showVerificationBadge: !isLoading && !isVerified,
      ),
    );
  }

  /// Build loading content with skeleton UI
  Widget _buildLoadingContent(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Loading header
          Container(
            height: 24,
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 24),
            child: Row(
              children: [
                // Skeleton for greeting/title
                Container(
                  height: 20,
                  width: 120,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const Spacer(),
                // Skeleton for user avatar/icon
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),

          // Loading content cards
          Expanded(
            child: ListView.separated(
              itemCount: 3,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) => _buildLoadingSkeleton(context),
            ),
          ),

          // Loading status
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.primary.withValues(
                      alpha: 0.6,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Setting up your account...',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build a skeleton loading card
  Widget _buildLoadingSkeleton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(
            alpha: 0.2,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title skeleton
          Container(
            height: 16,
            width: double.infinity * 0.7,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 12),
          // Subtitle skeleton
          Container(
            height: 12,
            width: double.infinity * 0.5,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer.withValues(
                alpha: 0.7,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  /// Build verification status banner
  Widget _buildVerificationBanner(BuildContext context, String? email) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 20,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Verify your email to unlock all features',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          TextButton(
            onPressed: () =>
                context.go('/email-verification?email=${email ?? ''}'),
            child: Text(
              'Verify',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
