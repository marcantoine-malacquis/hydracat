import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Enum to define slide directions for page transitions
enum SlideDirection {
  /// Slide from right to left (forward navigation)
  rightToLeft,

  /// Slide from left to right (back navigation)
  leftToRight,

  /// Slide from bottom to top
  bottomToTop,

  /// Slide from top to bottom
  topToBottom,
}

/// A custom page that provides slide transition animations for GoRouter
///
/// This page wrapper enables smooth slide transitions between screens,
/// commonly used for onboarding flows and navigation stacks.
class SlideTransitionPage<T> extends CustomTransitionPage<T> {
  /// Creates a [SlideTransitionPage] with the specified child
  /// and slide direction
  ///
  /// [child] is the widget to be displayed on this page
  /// [slideDirection] determines the direction of the slide animation
  /// [duration] is the animation duration (defaults to 300ms)
  /// [reverseDuration] is the reverse animation duration (defaults to duration)
  SlideTransitionPage({
    required super.child,
    SlideDirection slideDirection = SlideDirection.rightToLeft,
    Duration duration = const Duration(milliseconds: 300),
    Duration? reverseDuration,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  }) : super(
         transitionDuration: duration,
         reverseTransitionDuration: reverseDuration ?? duration,
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           return _buildSlideTransition(
             animation: animation,
             secondaryAnimation: secondaryAnimation,
             child: child,
             slideDirection: slideDirection,
           );
         },
       );

  /// Builds the slide transition animation
  static Widget _buildSlideTransition({
    required Animation<double> animation,
    required Animation<double> secondaryAnimation,
    required Widget child,
    required SlideDirection slideDirection,
  }) {
    // Calculate the slide offset based on direction
    final beginOffset = _getBeginOffset(slideDirection);
    const endOffset = Offset.zero;

    // Create slide animation
    final slideAnimation =
        Tween<Offset>(
          begin: beginOffset,
          end: endOffset,
        ).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          ),
        );

    // Create fade animation for smooth appearance
    final fadeAnimation =
        Tween<double>(
          begin: 0,
          end: 1,
        ).animate(
          CurvedAnimation(
            parent: animation,
            curve: const Interval(0, 0.3),
          ),
        );

    // Create outgoing slide animation for the previous page
    final outgoingSlideAnimation =
        Tween<Offset>(
          begin: Offset.zero,
          end: _getOutgoingOffset(slideDirection),
        ).animate(
          CurvedAnimation(
            parent: secondaryAnimation,
            curve: Curves.easeInOut,
          ),
        );

    return Stack(
      children: [
        // Outgoing page
        if (secondaryAnimation.status != AnimationStatus.dismissed)
          SlideTransition(
            position: outgoingSlideAnimation,
            child: FadeTransition(
              opacity: Tween<double>(
                begin: 1,
                end: 0.8,
              ).animate(secondaryAnimation),
              child: Container(), // Placeholder for previous page
            ),
          ),

        // Incoming page
        SlideTransition(
          position: slideAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: child,
          ),
        ),
      ],
    );
  }

  /// Gets the begin offset based on slide direction
  static Offset _getBeginOffset(SlideDirection direction) {
    switch (direction) {
      case SlideDirection.rightToLeft:
        return const Offset(1, 0);
      case SlideDirection.leftToRight:
        return const Offset(-1, 0);
      case SlideDirection.bottomToTop:
        return const Offset(0, 1);
      case SlideDirection.topToBottom:
        return const Offset(0, -1);
    }
  }

  /// Gets the outgoing offset for the previous page
  static Offset _getOutgoingOffset(SlideDirection direction) {
    switch (direction) {
      case SlideDirection.rightToLeft:
        return const Offset(-0.3, 0);
      case SlideDirection.leftToRight:
        return const Offset(0.3, 0);
      case SlideDirection.bottomToTop:
        return const Offset(0, -0.3);
      case SlideDirection.topToBottom:
        return const Offset(0, 0.3);
    }
  }
}

/// Extension for easy transition page creation
extension PageTransitionHelpers on GoRouter {
  /// Creates a slide transition page for forward navigation
  static SlideTransitionPage<T> slideForward<T>({
    required Widget child,
    Duration duration = const Duration(milliseconds: 300),
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
      duration: duration,
    );
  }

  /// Creates a slide transition page for back navigation
  static SlideTransitionPage<T> slideBack<T>({
    required Widget child,
    Duration duration = const Duration(milliseconds: 300),
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
      duration: duration,
    );
  }
}
