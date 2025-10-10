import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hydracat/core/constants/app_animations.dart';

/// Animation types for overlay popups.
enum OverlayAnimationType {
  /// Slide up from bottom (default, for FAB press)
  slideUp,

  /// Slide in from right (for medication selection)
  slideFromRight,

  /// Slide in from left (for fluid selection)
  slideFromLeft,

  /// Scale in from center (for success feedback)
  scaleIn,
}

/// A simple service for showing full-screen popups with blur background.
///
/// Uses Flutter's built-in [Overlay] widget to create true full-screen overlays
/// that can blur the entire screen including system UI areas.
///
/// Features:
/// - Full-screen blur background using [BackdropFilter]
/// - Proper overlay lifecycle management
/// - Tap-to-dismiss functionality
/// - Animation support
class OverlayService {
  static OverlayEntry? _currentOverlay;
  // Keep a reference to the host screen context used to present the overlay.
  // This allows downstream flows (e.g., dialogs after closing the overlay)
  // to reliably obtain a navigator context that survives overlay dismissal.
  static BuildContext? _hostContext;

  /// Returns the last host [BuildContext] used to show an overlay.
  static BuildContext? get hostContext => _hostContext;

  /// Shows a full-screen popup with blurred background.
  ///
  /// The [child] widget will be displayed over a blurred background that
  /// covers the entire screen including system UI areas.
  ///
  /// Parameters:
  /// - [context]: Build context for overlay insertion
  /// - [child]: Widget to display in the popup
  /// - [onDismiss]: Optional callback when popup is dismissed
  /// - [animationType]: Animation type for popup entrance (default: slideUp)
  /// - [blurSigma]: Blur intensity (default: 10.0)
  /// - [backgroundColor]: Background color with opacity (default: black 30%)
  /// - [dismissible]: Whether tapping background dismisses popup
  ///   (default: true)
  static void showFullScreenPopup({
    required BuildContext context,
    required Widget child,
    VoidCallback? onDismiss,
    OverlayAnimationType animationType = OverlayAnimationType.slideUp,
    double blurSigma = 10.0,
    Color backgroundColor = const Color(0x4D000000), // Black with 30% opacity
    bool dismissible = true,
  }) {
    // Remove any existing overlay first
    hide();

    // Capture the host context so consumers can use a safe navigator context
    // even after the overlay content is disposed.
    _hostContext = context;

    _currentOverlay = OverlayEntry(
      builder: (context) => _FullScreenBlurOverlay(
        onDismiss: onDismiss,
        animationType: animationType,
        blurSigma: blurSigma,
        backgroundColor: backgroundColor,
        dismissible: dismissible,
        child: child,
      ),
    );

    Overlay.of(context).insert(_currentOverlay!);
  }

  /// Hides the current full-screen popup if one is showing.
  static void hide() {
    _currentOverlay?.remove();
    _currentOverlay = null;
  }

  /// Returns true if a popup is currently showing.
  static bool get isShowing => _currentOverlay != null;
}

/// Internal widget that handles the full-screen blur overlay with configurable
///  animations.
class _FullScreenBlurOverlay extends StatefulWidget {
  const _FullScreenBlurOverlay({
    required this.child,
    this.onDismiss,
    this.animationType = OverlayAnimationType.slideUp,
    this.blurSigma = 10.0,
    this.backgroundColor = const Color(0x4D000000),
    this.dismissible = true,
  });

  final Widget child;
  final VoidCallback? onDismiss;
  final OverlayAnimationType animationType;
  final double blurSigma;
  final Color backgroundColor;
  final bool dismissible;

  @override
  State<_FullScreenBlurOverlay> createState() => _FullScreenBlurOverlayState();
}

class _FullScreenBlurOverlayState extends State<_FullScreenBlurOverlay>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _startAnimation();
  }

  void _setupAnimation() {
    _animationController = AnimationController(
      duration: _getAnimationDuration(),
      vsync: this,
    );

    // Setup slide animation for slide-based transitions
    _slideAnimation =
        Tween<Offset>(
          begin: _getAnimationBegin(),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    // Setup scale animation for scale-based transitions
    _scaleAnimation =
        Tween<double>(
          begin: 0,
          end: 1,
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: AppAnimations.scaleInCurve,
          ),
        );
  }

  /// Get animation duration based on animation type.
  Duration _getAnimationDuration() {
    switch (widget.animationType) {
      case OverlayAnimationType.slideUp:
        return AppAnimations.slideUpDuration;
      case OverlayAnimationType.slideFromRight:
      case OverlayAnimationType.slideFromLeft:
        return AppAnimations.slideFromRightDuration;
      case OverlayAnimationType.scaleIn:
        return AppAnimations.scaleInDuration;
    }
  }

  /// Get animation begin offset based on animation type.
  Offset _getAnimationBegin() {
    switch (widget.animationType) {
      case OverlayAnimationType.slideUp:
        return const Offset(0, 1); // Start from bottom
      case OverlayAnimationType.slideFromRight:
        return const Offset(1, 0); // Start from right
      case OverlayAnimationType.slideFromLeft:
        return const Offset(-1, 0); // Start from left
      case OverlayAnimationType.scaleIn:
        return Offset.zero; // Not used for scale animation
    }
  }

  void _startAnimation() {
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // Static blur background (no animation)
          Positioned.fill(
            child: GestureDetector(
              onTap: widget.dismissible ? _handleDismiss : null,
              behavior: HitTestBehavior.opaque,
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: widget.blurSigma,
                  sigmaY: widget.blurSigma,
                ),
                child: Container(
                  color: widget.backgroundColor,
                ),
              ),
            ),
          ),

          // Animated popup content
          _buildAnimatedContent(),
        ],
      ),
    );
  }

  /// Build animated content based on animation type
  Widget _buildAnimatedContent() {
    if (widget.animationType == OverlayAnimationType.scaleIn) {
      return ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      );
    } else {
      return SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      );
    }
  }

  Future<void> _handleDismiss() async {
    // Animate popup sliding down
    await _animationController.reverse();
    // Remove overlay and call dismiss callback
    OverlayService.hide();
    widget.onDismiss?.call();
  }
}
