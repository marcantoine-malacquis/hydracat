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

  // Common animation curves
  /// Default animation curve for general animations.
  static const Curve defaultCurve = Curves.easeInOut;

  /// Animation curve for slide-up transitions.
  static const Curve slideUpCurve = Curves.easeOut;

  /// Animation curve for scale-in transitions.
  static const Curve scaleInCurve = Curves.easeOutBack;

  // Opacity values
  /// Opacity of content when overlay is visible.
  static const double contentDimmedOpacity = 0.3;

  /// Opacity of overlay background.
  static const double overlayBackgroundOpacity = 0.3;
}
