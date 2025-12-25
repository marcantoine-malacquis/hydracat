import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hydracat/app/app_shell.dart';
import 'package:hydracat/features/home/screens/home_screen.dart';
import 'package:hydracat/features/learn/screens/discover_screen.dart';
import 'package:hydracat/features/notifications/widgets/notification_status_widget.dart';
import 'package:hydracat/features/profile/screens/profile_screen.dart';
import 'package:hydracat/features/progress/screens/progress_screen.dart';
import 'package:hydracat/features/progress/widgets/calendar_help_popup.dart';
import 'package:hydracat/providers/auth_provider.dart';
import 'package:hydracat/providers/progress_provider.dart';
import 'package:hydracat/shared/navigation/tab_page_descriptor.dart';
import 'package:hydracat/shared/widgets/widgets.dart';
import 'package:table_calendar/table_calendar.dart';

/// Central registry that maps route locations
/// to [TabPageDescriptor] configurations.
///
/// This registry eliminates hard-coded path prefix checks
/// in [AppShell] and provides
/// a single source of truth for what to render (AppBar, body, drawer)
/// for each route.
///
/// **Route Classification:**
/// - **Tab routes** (`/`, `/progress`, `/profile`, `/discover`): Use tab fade transitions
///   when switching between tabs. These routes are managed
///   by the tab shell with a stable AppBar and bottom navigation bar.
///   a stable AppBar and bottom navigation bar.
/// - **Detail routes** (e.g., `/profile/settings`, `/progress/weight`): Use horizontal
///   slide transitions (push/pop). These routes are full-screen pages with their own
///   Scaffold and AppBar, and hide the bottom navigation bar.
///
/// Usage:
/// ```dart
/// final tabPage = buildTabPageForLocation(
///   context,
///   ref,
///   currentLocation,
///   widget.child,
/// );
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
  /// - [child]: The widget child from GoRouter
  ///  (used as fallback for non-tab routes).
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

    // Discover/Resources tab routes
    if (_isDiscoverRoute(location)) {
      return _buildDiscoverTabPage(context);
    }

    // Unknown route - treat as non-tab
    return null;
  }

  // Route classification helpers

  /// Checks if a route is a non-tab route
  /// (detail screen, auth, onboarding, etc.).
  ///
  /// Non-tab routes are full-screen pages that:
  /// - Use horizontal slide transitions (not tab fade)
  /// - Have their own Scaffold and AppBar
  /// - Are rendered as-is (not processed through tab page builders)
  ///
  /// Note: Non-tab routes can still show the bottom navigation bar
  /// if they're listed in [shouldShowBottomNavForNonTabRoute].
  ///
  /// Returns true for:
  /// - Auth routes (login, register, forgot-password, email-verification)
  /// - Onboarding routes
  /// - Logging overlay routes
  /// - Settings routes (show bottom nav)
  /// - QoL routes (show bottom nav)
  /// - Weight routes (show bottom nav)
  /// - Progress analytics routes (show bottom nav)
  /// - Profile detail routes (show bottom nav)
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
        // Settings routes that should show bottom nav
        location.startsWith('/profile/settings') ||
        // QoL routes (all subroutes) - full-screen with slide transitions
        location.startsWith('/profile/qol') ||
        // Weight routes - full-screen with slide transitions
        location == '/profile/weight' ||
        location == '/progress/weight' ||
        // Progress analytics routes - full-screen with slide transitions
        location == '/progress/injection-sites' ||
        location == '/progress/symptoms' ||
        // Profile detail routes - full-screen with slide transitions
        location == '/profile/ckd' ||
        location.startsWith('/profile/fluid') ||
        location == '/profile/medication' ||
        location == '/profile/inventory';
  }

  /// Checks if a non-tab route should still show the bottom navigation bar.
  ///
  /// Some routes (like settings) render their own Scaffold but should still
  /// display the bottom navigation bar for easy access to main tabs.
  ///
  /// Returns true for:
  /// - Settings routes (/profile/settings/*)
  /// - Quality of Life routes (/profile/qol/*)
  /// - Weight routes (/profile/weight, /progress/weight)
  /// - Progress analytics routes (/progress/injection-sites, /progress/symptoms)
  /// - Profile detail routes (/profile/ckd, /profile/fluid,
  ///   /profile/medication, /profile/inventory)
  static bool shouldShowBottomNavForNonTabRoute(String location) {
    return location.startsWith('/profile/settings') ||
        location.startsWith('/profile/qol') ||
        location == '/profile/weight' ||
        location == '/progress/weight' ||
        location == '/progress/injection-sites' ||
        location == '/progress/symptoms' ||
        location == '/profile/ckd' ||
        location.startsWith('/profile/fluid') ||
        location == '/profile/medication' ||
        location == '/profile/inventory';
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

  static bool _isDiscoverRoute(String location) {
    return location.startsWith('/discover') || location == '/resources';
  }

  // Tab page builders

  static TabPageDescriptor _buildHomeTabPage(
    BuildContext context,
    WidgetRef ref,
  ) {
    final hasCompletedOnboarding = ref.watch(hasCompletedOnboardingProvider);

    return TabPageDescriptor(
      appBar: _buildHomeAppBar(context),
      body: HomeScreen.buildBody(
        context,
        ref,
        hasCompletedOnboarding: hasCompletedOnboarding,
      ),
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
      body: ProgressScreen.buildBody(
        context,
        ref,
        hasCompletedOnboarding: hasCompletedOnboarding,
      ),
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
      body: ProfileScreen.buildBody(
        context,
        ref,
        hasCompletedOnboarding: hasCompletedOnboarding,
      ),
      // Only build drawer in debug mode (when DebugPanel is available)
      drawer: kDebugMode ? ProfileScreen.buildDrawer(context, ref) : null,
    );
  }

  static TabPageDescriptor _buildDiscoverTabPage(BuildContext context) {
    return TabPageDescriptor(
      appBar: _buildDiscoverAppBar(context),
      body: DiscoverScreen.buildBody(context),
    );
  }

  // AppBar builders

  static PreferredSizeWidget _buildHomeAppBar(BuildContext context) {
    return const HydraAppBar(
      title: Text('Home'),
      actions: [
        NotificationStatusWidget(),
      ],
    );
  }

  static PreferredSizeWidget _buildProgressAppBar(
    BuildContext context,
    WidgetRef ref,
  ) {
    final hasCompletedOnboarding = ref.watch(hasCompletedOnboardingProvider);

    // Build segmented control for bottom of app bar
    final formatBar = hasCompletedOnboarding
        ? _buildProgressFormatBar(context, ref)
        : null;

    // Help icon goes on the left (leading)
    final leading = hasCompletedOnboarding
        ? IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => showCalendarHelpPopup(context),
            tooltip: 'Calendar help',
          )
        : null;

    // Calendar icon goes on the right (actions)
    final actions = hasCompletedOnboarding
        ? [
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: 'Jump to date',
              icon: const Icon(Icons.calendar_month, size: 24),
              onPressed: () async {
                final theme = Theme.of(context);
                final focused = ref.read(focusedDayProvider);
                final picked = await HydraDatePicker.show(
                  context: context,
                  initialDate: focused,
                  firstDate: DateTime(2010),
                  lastDate: DateTime.now(),
                  builder: (context, child) => Theme(
                    data: theme.copyWith(colorScheme: theme.colorScheme),
                    child: child!,
                  ),
                );
                if (picked != null) {
                  ref.read(focusedDayProvider.notifier).state = picked;
                }
              },
            ),
          ]
        : null;

    return HydraAppBar(
      title: const Text('Progress & Analytics'),
      style: HydraAppBarStyle.accent,
      leading: leading,
      actions: actions,
      bottom: formatBar,
      bottomHeight: 44,
      centerTitle: true, // Explicitly center the title
    );
  }

  /// Builds the format bar with Week/Month toggle for the progress app bar.
  ///
  /// The segmented control is centered, with icons handled in app bar actions.
  static Widget _buildProgressFormatBar(
    BuildContext context,
    WidgetRef ref,
  ) {
    final format = ref.watch(calendarFormatProvider);

    return Center(
      child: HydraSlidingSegmentedControl<CalendarFormat>(
        value: format,
        segments: const {
          CalendarFormat.week: Text('Week'),
          CalendarFormat.month: Text('Month'),
        },
        onChanged: (CalendarFormat newFormat) {
          HapticFeedback.selectionClick();
          ref.read(calendarFormatProvider.notifier).state = newFormat;
        },
      ),
    );
  }

  static PreferredSizeWidget _buildProfileAppBar(BuildContext context) {
    return HydraAppBar(
      title: const Text('Profile'),
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

  static PreferredSizeWidget _buildDiscoverAppBar(BuildContext context) {
    return const HydraAppBar(
      title: Text('Discover'),
    );
  }
}
