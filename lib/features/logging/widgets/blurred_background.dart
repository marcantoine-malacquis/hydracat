import 'dart:ui';

import 'package:flutter/material.dart';

/// A reusable backdrop blur component for logging popups.
///
/// Provides a semi-transparent blurred background that covers the entire screen
/// including system UI areas (status bar, navigation bar, etc.).
///
/// Features:
/// - Blur effect with configurable sigma values
/// - Semi-transparent scrim
/// - Covers entire screen including system UI
/// - Excludes semantics (decorative only)
/// - Dismissable via tap gesture
class BlurredBackground extends StatelessWidget {
  /// Creates a [BlurredBackground].
  const BlurredBackground({
    this.onTap,
    this.sigmaX = 10.0,
    this.sigmaY = 10.0,
    this.opacity = 0.3,
    super.key,
  });

  /// Callback when the background is tapped.
  ///
  /// Typically used to dismiss the popup.
  final VoidCallback? onTap;

  /// Horizontal blur amount (default: 10.0).
  final double sigmaX;

  /// Vertical blur amount (default: 10.0).
  final double sigmaY;

  /// Opacity of the semi-transparent scrim (default: 0.3).
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: sigmaX,
            sigmaY: sigmaY,
          ),
          child: Container(
            color: Colors.black.withValues(alpha: opacity),
          ),
        ),
      ),
    );
  }
}
