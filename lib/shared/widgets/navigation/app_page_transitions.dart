import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hydracat/shared/widgets/navigation/slide_transition_page.dart';

/// Centralized page transition definitions for the HydraCat app
///
/// This class provides consistent transition animations across the app,
/// with specific configurations for different types of flows.
class AppPageTransitions {
  AppPageTransitions._();

  /// Default transition duration for most page transitions
  static const Duration defaultDuration = Duration(milliseconds: 300);

  /// Fast transition duration for quick actions
  static const Duration fastDuration = Duration(milliseconds: 200);

  /// Slow transition duration for important flows
  static const Duration slowDuration = Duration(milliseconds: 400);

  /// Creates a slide transition page for onboarding flow (forward)
  ///
  /// Used for progressing through onboarding steps with right-to-left slide
  static SlideTransitionPage<T> onboardingForward<T>({
    required Widget child,
    LocalKey? key,
    String? name,
    Object? arguments,
    String? restorationId,
  }) {
    return SlideTransitionPage<T>(
      key: key,
      name: name,
      arguments: arguments,
      restorationId: restorationId,
      child: child,
    );
  }

  /// Creates a slide transition page for onboarding flow (back)
  ///
  /// Used for going back through onboarding steps with left-to-right slide
  static SlideTransitionPage<T> onboardingBack<T>({
    required Widget child,
    LocalKey? key,
    String? name,
    Object? arguments,
    String? restorationId,
  }) {
    return SlideTransitionPage<T>(
      key: key,
      name: name,
      arguments: arguments,
      restorationId: restorationId,
      child: child,
      slideDirection: SlideDirection.leftToRight,
    );
  }

  /// Creates a bidirectional slide transition page
  ///
  /// Automatically handles both forward (right-to-left) and back
  /// (left-to-right) navigation with appropriate slide directions.
  /// This is the recommended approach for most navigation flows as it
  /// provides consistent UX.
  static SlideTransitionPage<T> bidirectionalSlide<T>({
    required Widget child,
    LocalKey? key,
    String? name,
    Object? arguments,
    String? restorationId,
    Duration duration = defaultDuration,
  }) {
    return SlideTransitionPage<T>(
      key: key,
      name: name,
      arguments: arguments,
      restorationId: restorationId,
      child: child,
      duration: duration,
    );
  }

  /// Creates a slide transition page for modal-like screens
  ///
  /// Used for screens that appear from bottom like modals or sheets
  static SlideTransitionPage<T> modalSlide<T>({
    required Widget child,
    LocalKey? key,
    String? name,
    Object? arguments,
    String? restorationId,
  }) {
    return SlideTransitionPage<T>(
      key: key,
      name: name,
      arguments: arguments,
      restorationId: restorationId,
      child: child,
      slideDirection: SlideDirection.bottomToTop,
      duration: fastDuration,
    );
  }

  /// Creates a fade transition page for gentle transitions
  ///
  /// Used for transitions that should be subtle and non-directional
  static CustomTransitionPage<T> fadeTransition<T>({
    required Widget child,
    Duration duration = defaultDuration,
    LocalKey? key,
    String? name,
    Object? arguments,
    String? restorationId,
  }) {
    return CustomTransitionPage<T>(
      key: key,
      name: name,
      arguments: arguments,
      restorationId: restorationId,
      child: child,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
          child: child,
        );
      },
    );
  }

  /// Creates a no transition page for instant navigation
  ///
  /// Used when transitions should be disabled (e.g., tab navigation)
  static NoTransitionPage<T> noTransition<T>({
    required Widget child,
    LocalKey? key,
    String? name,
    Object? arguments,
    String? restorationId,
  }) {
    return NoTransitionPage<T>(
      key: key,
      name: name,
      arguments: arguments,
      restorationId: restorationId,
      child: child,
    );
  }

  /// Creates a scale transition page for emphasis
  ///
  /// Used for important actions or confirmations that need emphasis
  static CustomTransitionPage<T> scaleTransition<T>({
    required Widget child,
    Duration duration = fastDuration,
    LocalKey? key,
    String? name,
    Object? arguments,
    String? restorationId,
  }) {
    return CustomTransitionPage<T>(
      key: key,
      name: name,
      arguments: arguments,
      restorationId: restorationId,
      child: child,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: Curves.elasticOut,
          ),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    );
  }
}

/// Extension on GoRoute for easy transition page creation
extension GoRouteTransitions on GoRoute {
  /// Creates a GoRoute with onboarding slide transition
  static GoRoute onboardingSlide({
    required String path,
    required Widget Function(BuildContext, GoRouterState) builder,
    String? name,
    String? Function(BuildContext context, GoRouterState state)? redirect,
    List<RouteBase> routes = const <RouteBase>[],
  }) {
    return GoRoute(
      path: path,
      name: name,
      redirect: redirect,
      routes: routes,
      pageBuilder: (context, state) => AppPageTransitions.onboardingForward(
        child: builder(context, state),
        key: state.pageKey,
        name: name,
        arguments: state.pathParameters,
        restorationId: state.uri.toString(),
      ),
    );
  }

  /// Creates a GoRoute with modal slide transition
  static GoRoute modalSlide({
    required String path,
    required Widget Function(BuildContext, GoRouterState) builder,
    String? name,
    String? Function(BuildContext context, GoRouterState state)? redirect,
    List<RouteBase> routes = const <RouteBase>[],
  }) {
    return GoRoute(
      path: path,
      name: name,
      redirect: redirect,
      routes: routes,
      pageBuilder: (context, state) => AppPageTransitions.modalSlide(
        child: builder(context, state),
        key: state.pageKey,
        name: name,
        arguments: state.pathParameters,
        restorationId: state.uri.toString(),
      ),
    );
  }

  /// Creates a GoRoute with fade transition
  static GoRoute fade({
    required String path,
    required Widget Function(BuildContext, GoRouterState) builder,
    String? name,
    String? Function(BuildContext context, GoRouterState state)? redirect,
    List<RouteBase> routes = const <RouteBase>[],
  }) {
    return GoRoute(
      path: path,
      name: name,
      redirect: redirect,
      routes: routes,
      pageBuilder: (context, state) => AppPageTransitions.fadeTransition(
        child: builder(context, state),
        key: state.pageKey,
        name: name,
        arguments: state.pathParameters,
        restorationId: state.uri.toString(),
      ),
    );
  }
}
