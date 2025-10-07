import 'dart:ui';

import 'package:flutter/material.dart';

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

  /// Shows a full-screen popup with blurred background.
  ///
  /// The [child] widget will be displayed over a blurred background that
  /// covers the entire screen including system UI areas.
  ///
  /// Parameters:
  /// - [context]: Build context for overlay insertion
  /// - [child]: Widget to display in the popup
  /// - [onDismiss]: Optional callback when popup is dismissed
  /// - [blurSigma]: Blur intensity (default: 10.0)
  /// - [backgroundColor]: Background color with opacity (default: black 30%)
  /// - [dismissible]: Whether tapping background dismisses popup (default: true)
  static void showFullScreenPopup({
    required BuildContext context,
    required Widget child,
    VoidCallback? onDismiss,
    double blurSigma = 10.0,
    Color backgroundColor = const Color(0x4D000000), // Black with 30% opacity
    bool dismissible = true,
  }) {
    // Remove any existing overlay first
    hide();

    _currentOverlay = OverlayEntry(
      builder: (context) => _FullScreenBlurOverlay(
        child: child,
        onDismiss: onDismiss,
        blurSigma: blurSigma,
        backgroundColor: backgroundColor,
        dismissible: dismissible,
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

/// Internal widget that handles the full-screen blur overlay.
class _FullScreenBlurOverlay extends StatelessWidget {
  const _FullScreenBlurOverlay({
    required this.child,
    this.onDismiss,
    this.blurSigma = 10.0,
    this.backgroundColor = const Color(0x4D000000),
    this.dismissible = true,
  });

  final Widget child;
  final VoidCallback? onDismiss;
  final double blurSigma;
  final Color backgroundColor;
  final bool dismissible;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // Full-screen blur background
          Positioned.fill(
            child: GestureDetector(
              onTap: dismissible ? _handleDismiss : null,
              behavior: HitTestBehavior.opaque,
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: blurSigma,
                  sigmaY: blurSigma,
                ),
                child: Container(
                  color: backgroundColor,
                ),
              ),
            ),
          ),

          // Popup content
          child,
        ],
      ),
    );
  }

  void _handleDismiss() {
    OverlayService.hide();
    onDismiss?.call();
  }
}
