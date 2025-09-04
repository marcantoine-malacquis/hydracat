import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hydracat/core/constants/app_icons.dart';
import 'package:hydracat/shared/widgets/navigation/hydra_navigation_bar.dart';

/// Main app shell that provides consistent navigation and layout.
class AppShell extends StatefulWidget {
  /// Creates an AppShell with the specified child.
  const AppShell({
    required this.child,
    super.key,
  });

  /// The main content to display.
  final Widget child;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
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
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: HydraNavigationBar(
        items: _navigationItems,
        currentIndex: _currentIndex,
        onTap: _onNavigationTap,
        onFabPressed: _onFabPressed,
      ),
    );
  }
}
