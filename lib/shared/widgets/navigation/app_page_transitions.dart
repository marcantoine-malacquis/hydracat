import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hydracat/core/constants/app_animations.dart';
import 'package:hydracat/shared/widgets/navigation/slide_transition_page.dart';

/// Centralized page transition definitions for the HydraCat app
///
/// This class provides consistent transition animations across the app,
/// with specific configurations for different types of flows.
class AppPageTransitions {
  AppPageTransitions._();

  /// Default transition duration for most page transitions.
  /// Uses centralized constant from AppAnimations for consistency.
  static const Duration defaultDuration = AppAnimations.pageSlideDuration;

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
  ///
  /// Uses centralized animation constants from AppAnimations.
  /// Reduce motion is handled automatically by SlideTransitionPage.
  static SlideTransitionPage<T> bidirectionalSlide<T>({
    required Widget child,
    LocalKey? key,
    String? name,
    Object? arguments,
    String? restorationId,
    Duration? duration,
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

/// A widget that provides smooth cross-fade transitions for tab navigation.
///
/// Uses [AnimatedSwitcher] to fade between tab content when the key changes.
/// Respects reduced motion preferences and provides a subtle, modern transition
/// that masks data loading on heavy screens.
///
/// The transition combines:
/// - Primary: [FadeTransition] for smooth opacity changes
/// - Optional: Very subtle scale (0.98 → 1.0) for depth without motion sickness
///
/// Example usage:
/// ```dart
/// TabFadeSwitcher(
///   key: ValueKey(currentTabRoute),
///   child: currentTabContent,
/// )
/// ```
class TabFadeSwitcher extends StatelessWidget {
  /// Creates a [TabFadeSwitcher] with the specified child.
  ///
  /// The [child] should have a [Key] that changes when switching tabs.
  /// The [duration] and [curve] can be customized, but default to app-wide
  /// constants for consistency.
  const TabFadeSwitcher({
    required this.child,
    super.key,
    this.duration,
    this.curve,
  });

  /// The child widget to display.
  ///
  /// Should have a [Key] that uniquely identifies the current tab.
  final Widget child;

  /// The duration of the fade transition.
  ///
  /// Defaults to [AppAnimations.tabFadeDuration] if not specified.
  final Duration? duration;

  /// The animation curve for the transition.
  ///
  /// Defaults to [AppAnimations.tabFadeCurve] if not specified.
  final Curve? curve;

  @override
  Widget build(BuildContext context) {
    // Check for reduced motion preference
    final shouldReduceMotion = AppAnimations.shouldReduceMotion(context);
    final effectiveDuration = shouldReduceMotion
        ? Duration.zero
        : (duration ?? AppAnimations.tabFadeDuration);
    final effectiveCurve = curve ?? AppAnimations.tabFadeCurve;

    // If animations are disabled, return child directly
    if (shouldReduceMotion) {
      // Debug: Help identify if animations are being disabled
      assert(
        () {
          debugPrint(
            '[TabFadeSwitcher] Animations disabled due to '
            'Reduce Motion setting',
          );
          return true;
        }(),
        'Animations disabled due to Reduce Motion setting',
      );
      return child;
    }

    // Ensure child has a key for AnimatedSwitcher to detect changes
    assert(
      child.key != null,
      'TabFadeSwitcher child must have a Key for animations to work. '
      'Wrap the child in KeyedSubtree with a ValueKey.',
    );

    return AnimatedSwitcher(
      duration: effectiveDuration,
      switchInCurve: effectiveCurve,
      switchOutCurve: effectiveCurve,
      layoutBuilder: (currentChild, previousChildren) {
        // Stack with incoming child strictly on top to prevent background flash
        // Previous children (exiting) stay underneath, new child (entering)
        // fades in on top
        return Stack(
          alignment: Alignment.topLeft,
          fit: StackFit.expand,
          children: <Widget>[
            // Exiting children stay underneath
            ...previousChildren,
            // Incoming child fades in on top
            if (currentChild != null) currentChild,
          ],
        );
      },
      transitionBuilder: (child, animation) {
        // Subtle soft fade - pure opacity cross-dissolve without scale
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: effectiveCurve,
          ),
          child: child,
        );
      },
      // Use child directly - it should already have a key from the parent
      child: child,
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
