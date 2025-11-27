import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Describes the UI components (AppBar, body, drawer) for a tab page or route.
///
/// This is the contract that 'AppShell' uses to render tab content without
/// hard-coding path prefixes or importing feature screens directly.
///
/// Example usage:
/// ```dart
/// TabPageDescriptor(
///   appBar: HydraAppBar(title: Text('Home')),
///   body: HomeScreen.buildBody(context, ref, hasOnboarding),
///   isTabRoute: true,
/// )
/// ```
class TabPageDescriptor {
  /// Creates a [TabPageDescriptor] with the specified components.
  const TabPageDescriptor({
    required this.appBar,
    required this.body,
    this.drawer,
    this.isTabRoute = true,
    this.showBottomNav = true,
  });

  /// The AppBar to display for this route.
  ///
  /// If null, no AppBar will be shown (the route handles its own AppBar).
  final PreferredSizeWidget? appBar;

  /// The body content to display for this route.
  ///
  /// This is the main content area that will be wrapped in 'TabFadeSwitcher'
  /// for tab routes to enable smooth transitions.
  final Widget body;

  /// Optional drawer widget (e.g. for Profile screen).
  final Widget? drawer;

  /// Whether this route is part of the tab navigation system.
  ///
  /// If true, the route will be rendered with the tab shell
  /// (AppBar, bottom nav).
  /// If false, the route will be rendered as-is via the route's child.
  final bool isTabRoute;

  /// Whether to show the bottom navigation bar for this route.
  ///
  /// Defaults to true for tab routes. Can be set to false for detail pages
  /// that should still use the tab shell but hide the bottom nav.
  final bool showBottomNav;
}

/// Typedef for a function that builds a [TabPageDescriptor] from a context.
///
/// Used by the tab page registry to construct descriptors dynamically.
typedef TabPageBuilder =
    TabPageDescriptor Function(
      BuildContext context,
      WidgetRef ref,
    );
