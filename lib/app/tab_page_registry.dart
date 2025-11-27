import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hydracat/features/home/screens/home_screen.dart';
import 'package:hydracat/features/learn/screens/learn_screen.dart';
import 'package:hydracat/features/notifications/widgets/notification_status_widget.dart';
import 'package:hydracat/features/profile/screens/profile_screen.dart';
import 'package:hydracat/features/progress/screens/progress_screen.dart';
import 'package:hydracat/features/progress/widgets/calendar_help_popup.dart';
import 'package:hydracat/providers/auth_provider.dart';
import 'package:hydracat/shared/navigation/tab_page_descriptor.dart';
import 'package:hydracat/shared/widgets/widgets.dart';

/// Central registry that maps route locations to [TabPageDescriptor] configurations.
///
/// This registry eliminates hard-coded path prefix checks in [AppShell] and provides
/// a single source of truth for what to render (AppBar, body, drawer) for each route.
///
/// **Route Classification:**
/// - **Tab routes** (`/`, `/progress`, `/profile`, `/learn`): Use tab fade transitions
///   when switching between tabs. These routes are managed by the tab shell with
///   a stable AppBar and bottom navigation bar.
/// - **Detail routes** (e.g., `/profile/settings`, `/progress/weight`): Use horizontal
///   slide transitions (push/pop). These routes are full-screen pages with their own
///   Scaffold and AppBar, and hide the bottom navigation bar.
///
/// Usage:
/// ```dart
/// final tabPage = buildTabPageForLocation(context, ref, currentLocation, widget.child);
/// if (tabPage != null && tabPage.isTabRoute) {
///   // Render with tab shell
/// }
/// ```
class TabPageRegistry {
  /// Builds a [TabPageDescriptor] for the given location, or returns null if
  /// the route should be rendered as-is (non-tab route).
  ///
  /// Parameters:
  /// - [context]: Build context for accessing theme, router, etc.
  /// - [ref]: Riverpod widget ref for accessing providers.
  /// - [location]: The current route path (e.g. '/', '/progress', '/progress/weight').
  /// - [child]: The widget child from GoRouter (used as fallback for non-tab routes).
  ///
  /// Returns a [TabPageDescriptor] for tab routes, or null for non-tab routes
  /// (onboarding, logging, settings overlays, etc.).
  static TabPageDescriptor? buildTabPageForLocation(
    BuildContext context,
    WidgetRef ref,
    String location,
    Widget child,
  ) {
    // Non-tab routes that should be rendered as-is
    if (_isNonTabRoute(location)) {
      return null;
    }

    // Home tab routes
    if (_isHomeRoute(location)) {
      return _buildHomeTabPage(context, ref);
    }

    // Progress tab routes
    if (_isProgressRoute(location)) {
      return _buildProgressTabPage(context, ref, location, child);
    }

    // Profile tab routes
    if (_isProfileRoute(location)) {
      return _buildProfileTabPage(context, ref, location);
    }

    // Learn/Resources tab routes
    if (_isLearnRoute(location)) {
      return _buildLearnTabPage(context);
    }

    // Unknown route - treat as non-tab
    return null;
  }

  // Route classification helpers

  /// Checks if a route is a non-tab route (detail screen, auth, onboarding, etc.).
  ///
  /// Non-tab routes are full-screen pages that:
  /// - Use horizontal slide transitions (not tab fade)
  /// - Have their own Scaffold and AppBar
  /// - Hide the bottom navigation bar
  ///
  /// Returns true for:
  /// - Auth routes (login, register, forgot-password, email-verification)
  /// - Onboarding routes
  /// - Logging overlay routes
  /// - Profile detail routes (settings, ckd, fluid, medication, weight)
  /// - Progress detail routes (injection-sites, weight, symptoms)
  /// - Demo routes
  static bool isNonTabRoute(String location) {
    return _isNonTabRoute(location);
  }

  static bool _isNonTabRoute(String location) {
    return location == '/logging' ||
        location.startsWith('/onboarding') ||
        location == '/login' ||
        location == '/register' ||
        location == '/forgot-password' ||
        location == '/email-verification' ||
        location == '/demo' ||
        // Profile detail routes that should be full-screen with slide transitions
        [
          '/profile/settings',
          '/profile/settings/notifications',
          '/profile/ckd',
          '/profile/fluid',
          '/profile/fluid/create',
          '/profile/medication',
          '/profile/weight',
        ].contains(location) ||
        // Progress detail routes that should be full-screen with slide transitions
        [
          '/progress/injection-sites',
          '/progress/weight',
          '/progress/symptoms',
        ].contains(location);
  }

  static bool _isHomeRoute(String location) {
    return location == '/' || location.isEmpty;
  }

  static bool _isProgressRoute(String location) {
    // Only root progress route is a tab route
    // Detail routes (weight, injection-sites, symptoms) are full-screen
    return location == '/progress';
  }

  static bool _isProfileRoute(String location) {
    return location.startsWith('/profile') && !_isNonTabRoute(location);
  }

  static bool _isLearnRoute(String location) {
    return location.startsWith('/learn') || location == '/resources';
  }

  // Tab page builders

  static TabPageDescriptor _buildHomeTabPage(
    BuildContext context,
    WidgetRef ref,
  ) {
    final hasCompletedOnboarding = ref.watch(hasCompletedOnboardingProvider);

    return TabPageDescriptor(
      appBar: _buildHomeAppBar(context),
      body: HomeScreen.buildBody(context, ref, hasCompletedOnboarding),
      isTabRoute: true,
    );
  }

  static TabPageDescriptor _buildProgressTabPage(
    BuildContext context,
    WidgetRef ref,
    String location,
    Widget child,
  ) {
    final hasCompletedOnboarding = ref.watch(hasCompletedOnboardingProvider);

    // Progress root route only
    return TabPageDescriptor(
      appBar: _buildProgressAppBar(context, ref),
      body: ProgressScreen.buildBody(context, ref, hasCompletedOnboarding),
      isTabRoute: true,
    );
  }

  static TabPageDescriptor _buildProfileTabPage(
    BuildContext context,
    WidgetRef ref,
    String location,
  ) {
    final hasCompletedOnboarding = ref.watch(hasCompletedOnboardingProvider);

    return TabPageDescriptor(
      appBar: _buildProfileAppBar(context),
      body: ProfileScreen.buildBody(context, ref, hasCompletedOnboarding),
      // Only build drawer in debug mode (when DebugPanel is available)
      drawer: kDebugMode ? ProfileScreen.buildDrawer(context, ref) : null,
      isTabRoute: true,
    );
  }

  static TabPageDescriptor _buildLearnTabPage(BuildContext context) {
    return TabPageDescriptor(
      appBar: _buildLearnAppBar(context),
      body: ResourcesScreen.buildBody(context),
      isTabRoute: true,
    );
  }

  // AppBar builders

  static PreferredSizeWidget _buildHomeAppBar(BuildContext context) {
    return HydraAppBar(
      title: const Text('HydraCat'),
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      actions: const [
        NotificationStatusWidget(),
      ],
    );
  }

  static PreferredSizeWidget _buildProgressAppBar(
    BuildContext context,
    WidgetRef ref,
  ) {
    final hasCompletedOnboarding = ref.watch(hasCompletedOnboardingProvider);

    return HydraAppBar(
      title: const Text('Progress & Analytics'),
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      actions: hasCompletedOnboarding
          ? [
              IconButton(
                icon: const Icon(Icons.help_outline),
                onPressed: () => showCalendarHelpPopup(context),
                tooltip: 'Calendar help',
              ),
            ]
          : null,
    );
  }

  static PreferredSizeWidget _buildProfileAppBar(BuildContext context) {
    return HydraAppBar(
      title: const Text('Profile'),
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      // Only show hamburger icon in debug mode (when drawer exists)
      leading: kDebugMode
          ? Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
                tooltip: 'Open menu',
              ),
            )
          : null,
      actions: [
        IconButton(
          onPressed: () => context.go('/profile/settings'),
          icon: const Icon(Icons.settings),
          tooltip: 'Settings',
        ),
      ],
    );
  }

  static PreferredSizeWidget _buildLearnAppBar(BuildContext context) {
    return HydraAppBar(
      title: const Text('Learn'),
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
    );
  }
}
