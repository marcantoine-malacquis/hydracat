import 'package:flutter/material.dart';
import 'package:hydracat/core/constants/app_animations.dart';
import 'package:hydracat/features/logging/widgets/success_indicator.dart';
import 'package:hydracat/shared/widgets/widgets.dart';

/// Loading state enum
enum LoadingOverlayState {
  /// No overlay shown
  none,

  /// Loading indicator shown
  loading,

  /// Success indicator shown
  success,
}

/// Reusable loading overlay that displays loading, success, or nothing
/// over content with proper dimming and accessibility.
///
/// Usage:
/// ```dart
/// LoadingOverlay(
///   state: _isLoading
///       ? LoadingOverlayState.loading
///       : LoadingOverlayState.none,
///   child: YourContent(),
/// )
/// ```
class LoadingOverlay extends StatelessWidget {
  /// Creates a [LoadingOverlay].
  const LoadingOverlay({
    required this.state,
    required this.child,
    super.key,
    this.loadingMessage,
    this.contentOpacity = AppAnimations.contentDimmedOpacity,
    this.overlayColor,
  });

  /// Current loading state
  final LoadingOverlayState state;

  /// Content to display under overlay
  final Widget child;

  /// Optional message to announce to screen readers during loading
  final String? loadingMessage;

  /// Opacity of content when overlay is shown (default 0.3)
  final double contentOpacity;

  /// Background color of overlay (default black with 30% opacity)
  final Color? overlayColor;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main content
        child,

        // Unified overlay for loading and success
        if (state != LoadingOverlayState.none)
          Positioned.fill(
            child: Semantics(
              liveRegion: true,
              label: state == LoadingOverlayState.loading
                  ? (loadingMessage ?? 'Loading')
                  : 'Success',
              child: IgnorePointer(
                child: AnimatedContainer(
                  duration: AppAnimations.loadingFadeInDuration,
                  curve: Curves.easeOut,
                  // Transparent background to avoid any gray flash
                  color: Colors.transparent,
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AnimatedOpacity(
                          duration: AppAnimations.loadingFadeInDuration,
                          curve: Curves.easeOut,
                          opacity: state == LoadingOverlayState.loading
                              ? 1.0
                              : 0.0,
                          child: const HydraProgressIndicator(),
                        ),
                        AnimatedOpacity(
                          duration: AppAnimations.loadingFadeInDuration,
                          curve: Curves.easeOut,
                          opacity: state == LoadingOverlayState.success
                              ? 1.0
                              : 0.0,
                          child: const SuccessIndicator(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
