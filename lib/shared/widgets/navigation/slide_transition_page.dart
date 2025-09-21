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

  /// Builds the slide transition animation with automatic direction reversal
  static Widget _buildSlideTransition({
    required Animation<double> animation,
    required Animation<double> secondaryAnimation,
    required Widget child,
    required SlideDirection slideDirection,
  }) {
    // For forward navigation: slide in from right, slide out to left
    // For back navigation: slide in from left, slide out to right
    // The key insight: when going back, the roles of animation and
    // secondaryAnimation are swapped by GoRouter

    final forwardBeginOffset = _getBeginOffset(slideDirection);
    final reverseBeginOffset =
        _getBeginOffset(_getReverseDirection(slideDirection));

    // Create the main slide animation (incoming page)
    final slideAnimation = Tween<Offset>(
      begin: forwardBeginOffset,
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOut,
      ),
    );

    // Create the reverse slide animation (for when this page is being popped)
    final reverseSlideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: reverseBeginOffset,
    ).animate(
      CurvedAnimation(
        parent: secondaryAnimation,
        curve: Curves.easeInOut,
      ),
    );

    // Create fade animations
    final fadeInAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: animation,
        curve: const Interval(0, 0.3),
      ),
    );

    final fadeOutAnimation = Tween<double>(
      begin: 1,
      end: 0,
    ).animate(
      CurvedAnimation(
        parent: secondaryAnimation,
        curve: const Interval(0.7, 1),
      ),
    );

    return SlideTransition(
      position: slideAnimation,
      child: SlideTransition(
        position: reverseSlideAnimation,
        child: FadeTransition(
          opacity: fadeInAnimation,
          child: FadeTransition(
            opacity: fadeOutAnimation,
            child: child,
          ),
        ),
      ),
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

  /// Gets the reverse direction for bidirectional animations
  static SlideDirection _getReverseDirection(SlideDirection direction) {
    switch (direction) {
      case SlideDirection.rightToLeft:
        return SlideDirection.leftToRight;
      case SlideDirection.leftToRight:
        return SlideDirection.rightToLeft;
      case SlideDirection.bottomToTop:
        return SlideDirection.topToBottom;
      case SlideDirection.topToBottom:
        return SlideDirection.bottomToTop;
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
