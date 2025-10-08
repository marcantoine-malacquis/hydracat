import 'package:flutter/material.dart';
import 'package:hydracat/core/constants/app_animations.dart';
import 'package:hydracat/features/logging/widgets/success_indicator.dart';

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
        // Main content - no opacity changes for success state
        Opacity(
          opacity: state == LoadingOverlayState.loading ? contentOpacity : 1.0,
          child: child,
        ),

        // Loading overlay (only show background for loading state)
        if (state == LoadingOverlayState.loading)
          Positioned.fill(
            child: Semantics(
              liveRegion: true,
              label: loadingMessage ?? 'Loading',
              child: ColoredBox(
                color:
                    overlayColor ??
                    Colors.black.withValues(
                      alpha: AppAnimations.overlayBackgroundOpacity,
                    ),
                child: Center(
                  child: _buildOverlayContent(),
                ),
              ),
            ),
          ),

        // Success overlay (no background, just the indicator)
        if (state == LoadingOverlayState.success)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            child: Semantics(
              liveRegion: true,
              label: 'Success',
              child: IgnorePointer(
                // Prevent any touch events from reaching the background
                child: Center(
                  child: _buildOverlayContent(),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildOverlayContent() {
    switch (state) {
      case LoadingOverlayState.loading:
        return const CircularProgressIndicator();
      case LoadingOverlayState.success:
        return const SuccessIndicator();
      case LoadingOverlayState.none:
        return const SizedBox.shrink();
    }
  }
}
