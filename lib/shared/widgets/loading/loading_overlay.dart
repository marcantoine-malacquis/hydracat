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

  bool get _isOverlayVisible =>
      state == LoadingOverlayState.loading ||
      state == LoadingOverlayState.success;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main content with dynamic opacity
        Opacity(
          opacity: _isOverlayVisible ? contentOpacity : 1.0,
          child: child,
        ),

        // Loading/Success overlay
        if (_isOverlayVisible)
          Positioned.fill(
            child: Semantics(
              liveRegion: true,
              label: state == LoadingOverlayState.loading
                  ? (loadingMessage ?? 'Loading')
                  : 'Success',
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
