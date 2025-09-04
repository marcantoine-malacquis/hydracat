import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hydracat/core/constants/app_icons.dart';
import 'package:hydracat/features/auth/models/auth_state.dart';
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
    final authState = ref.watch(authProvider);
    final isVerified = authState is AuthStateAuthenticated && 
                      authState.user.emailVerified;

    return Scaffold(
      body: Column(
        children: [
          // Show verification banner for unverified users
          if (authState is AuthStateAuthenticated && 
              !authState.user.emailVerified)
            _buildVerificationBanner(context, authState.user.email),
          Expanded(child: widget.child),
        ],
      ),
      bottomNavigationBar: HydraNavigationBar(
        items: _navigationItems,
        currentIndex: _currentIndex,
        onTap: _onNavigationTap,
        onFabPressed: _onFabPressed,
        showVerificationBadge: !isVerified,
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
            onPressed: () => context.go('/email-verification?email=${email ?? ''}'),
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
