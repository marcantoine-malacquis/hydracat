import 'package:flutter/material.dart';

/// Animation duration and timing constants for consistent app-wide animations.
class AppAnimations {
  const AppAnimations._();

  // Loading overlay animations
  /// Duration for loading overlay fade-in animation.
  static const Duration loadingFadeInDuration = Duration(milliseconds: 200);

  /// Duration for success indicator display.
  static const Duration successDisplayDuration = Duration(milliseconds: 500);

  /// Duration for error indicator display.
  static const Duration errorDisplayDuration = Duration(milliseconds: 300);

  // Popup overlay animations (from OverlayService)
  /// Duration for slide-up popup animation.
  static const Duration slideUpDuration = Duration(milliseconds: 200);

  /// Duration for slide-from-right popup animation.
  static const Duration slideFromRightDuration = Duration(milliseconds: 250);

  /// Duration for slide-from-left popup animation.
  static const Duration slideFromLeftDuration = Duration(milliseconds: 250);

  /// Duration for scale-in popup animation.
  static const Duration scaleInDuration = Duration(milliseconds: 300);

  // Drag-to-dismiss animations
  /// Duration for drag spring-back animation.
  static const Duration dragSpringBackDuration = Duration(milliseconds: 200);

  /// Duration for drag dismiss animation.
  static const Duration dragDismissDuration = Duration(milliseconds: 250);

  // Common animation curves
  /// Default animation curve for general animations.
  static const Curve defaultCurve = Curves.easeInOut;

  /// Animation curve for slide-up transitions.
  static const Curve slideUpCurve = Curves.easeOut;

  /// Animation curve for scale-in transitions.
  static const Curve scaleInCurve = Curves.easeOutBack;

  /// Curve for drag spring-back animation.
  static const Curve dragSpringBackCurve = Curves.easeOutCubic;

  /// Curve for drag dismiss animation.
  static const Curve dragDismissCurve = Curves.easeInCubic;

  // Opacity values
  /// Opacity of content when overlay is visible.
  static const double contentDimmedOpacity = 0.3;

  /// Opacity of overlay background.
  static const double overlayBackgroundOpacity = 0.3;

  // Accessibility support
  /// Check if animations should be disabled for accessibility.
  /// Returns true if user has enabled "Reduce Motion" in system settings.
  static bool shouldReduceMotion(BuildContext context) {
    return MediaQuery.disableAnimationsOf(context);
  }

  /// Get animation duration with reduced motion support.
  /// Returns Duration.zero if reduce motion is enabled.
  static Duration getDuration(BuildContext context, Duration duration) {
    return shouldReduceMotion(context) ? Duration.zero : duration;
  }
}
