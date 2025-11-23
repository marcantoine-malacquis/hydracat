import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Platform-adaptive refresh indicator for HydraCat.
///
/// Wraps [RefreshIndicator] on Material platforms and
/// [CupertinoSliverRefreshControl] on iOS/macOS, while mirroring the core
/// [RefreshIndicator] API.
///
/// On iOS/macOS, the [child] must be a scrollable widget (e.g., [ListView],
/// [SingleChildScrollView], [CustomScrollView]). If the child is not a
/// scrollable, pull-to-refresh will not be active on iOS/macOS.
///
/// Provides a unified, native-feeling pull-to-refresh experience across
/// platforms with:
/// - Minimum refresh duration to ensure the pulled state is visible
/// - Haptic feedback when refresh starts
/// - Smooth snap-back animation after refresh completes
///
/// Example:
/// ```dart
/// HydraRefreshIndicator(
///   onRefresh: () async {
///     await ref.invalidate(someProvider);
///   },
///   child: SingleChildScrollView(
///     child: Column(
///       children: [...],
///     ),
///   ),
/// )
/// ```
class HydraRefreshIndicator extends StatelessWidget {
  /// Creates a platform-adaptive refresh indicator.
  ///
  /// The [onRefresh] callback is called when the user pulls down to refresh.
  /// The [child] should be a scrollable widget.
  ///
  /// The [minRefreshDuration] ensures the refresh indicator stays visible
  /// for at least this duration, providing a consistent UX across platforms.
  /// If null, no minimum duration is enforced. Defaults to 700ms.
  ///
  /// The [enableHaptics] parameter controls whether haptic feedback is
  /// triggered when refresh starts. Defaults to true.
  const HydraRefreshIndicator({
    required this.onRefresh,
    required this.child,
    this.color,
    this.backgroundColor,
    this.displacement = 40.0,
    this.edgeOffset = 0.0,
    this.strokeWidth = 2.0,
    this.triggerMode = RefreshIndicatorTriggerMode.onEdge,
    this.minRefreshDuration = const Duration(milliseconds: 700),
    this.enableHaptics = true,
    super.key,
  });

  /// Callback function that is called when the user pulls down to refresh.
  ///
  /// Must return a [Future] that completes when the refresh operation is done.
  final Future<void> Function() onRefresh;

  /// The widget to display below the refresh indicator.
  ///
  /// Should be a scrollable widget (e.g., [ListView], [SingleChildScrollView],
  /// [CustomScrollView]). On iOS/macOS, if this is not a scrollable widget,
  /// pull-to-refresh will not be active.
  final Widget child;

  /// Color of the refresh indicator.
  ///
  /// On Material platforms, this is the color of the circular progress
  /// indicator. On iOS/macOS, this is ignored (Cupertino uses its default
  /// styling).
  final Color? color;

  /// Background color of the refresh indicator.
  ///
  /// On Material platforms, this is the background color of the circular
  /// progress indicator. On iOS/macOS, this is ignored.
  final Color? backgroundColor;

  /// The distance from the top of the scrollable widget to show the refresh
  /// indicator.
  ///
  /// Defaults to 40.0. On iOS/macOS, this is ignored (Cupertino uses its
  /// default positioning).
  final double displacement;

  /// The offset from the top edge of the scrollable widget.
  ///
  /// Defaults to 0.0. On iOS/macOS, this is ignored.
  final double edgeOffset;

  /// The width of the progress indicator's stroke.
  ///
  /// Only applies to Material platforms. On iOS/macOS, this is ignored.
  final double strokeWidth;

  /// The trigger mode for the refresh indicator.
  ///
  /// Only applies to Material platforms. On iOS/macOS, this is ignored.
  final RefreshIndicatorTriggerMode triggerMode;

  /// Minimum duration for the refresh operation.
  ///
  /// Ensures the refresh indicator stays visible for at least this duration,
  /// providing a consistent, native-feeling UX across platforms. If null,
  /// no minimum duration is enforced.
  ///
  /// This is a platform-agnostic UX control applied consistently to both
  /// Material and Cupertino implementations.
  final Duration? minRefreshDuration;

  /// Whether to enable haptic feedback when refresh starts.
  ///
  /// When true, triggers haptic feedback when the refresh operation begins,
  /// providing tactile confirmation to the user.
  ///
  /// This is a platform-agnostic UX control applied consistently to both
  /// Material and Cupertino implementations.
  final bool enableHaptics;

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;

    if (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS) {
      return _buildCupertinoRefreshIndicator(context);
    }

    return _buildMaterialRefreshIndicator(context);
  }

  /// Wraps the [onRefresh] callback to enforce minimum duration and trigger
  /// haptics when refresh starts.
  ///
  /// Returns a new callback that:
  /// - Triggers haptic feedback when refresh starts (if enabled)
  /// - Enforces a minimum refresh duration (if specified)
  Future<void> Function() _wrapOnRefreshWithMinDuration() {
    return () async {
      // Trigger haptic feedback when refresh starts
      if (enableHaptics) {
        unawaited(HapticFeedback.mediumImpact());
      }

      // Record start time
      final startTime = DateTime.now();

      // Execute the original refresh callback
      await onRefresh();

      // Enforce minimum duration if specified
      if (minRefreshDuration != null) {
        final elapsed = DateTime.now().difference(startTime);
        if (elapsed < minRefreshDuration!) {
          await Future<void>.delayed(minRefreshDuration! - elapsed);
        }
      }
    };
  }

  Widget _buildMaterialRefreshIndicator(BuildContext context) {
    // Calculate the app bar height to position the refresh indicator
    // in the visible space below the app bar
    final appBarTheme = Theme.of(context).appBarTheme;
    final appBarHeight = appBarTheme.toolbarHeight ?? kToolbarHeight;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final totalTopHeight = appBarHeight + statusBarHeight;

    // Position the indicator in the middle of the free space below the app bar
    // The displacement should account for the app bar + status bar +
    // some padding
    // to ensure it's clearly visible in the "refresh free space"
    final calculatedDisplacement = totalTopHeight + displacement;

    return RefreshIndicator(
      onRefresh: _wrapOnRefreshWithMinDuration(),
      color: color,
      backgroundColor: backgroundColor,
      displacement: calculatedDisplacement,
      edgeOffset: edgeOffset,
      strokeWidth: strokeWidth,
      triggerMode: triggerMode,
      child: child,
    );
  }

  /// Builds a [CupertinoSliverRefreshControl] with haptic feedback support.
  ///
  /// Uses a custom builder to trigger haptics when the refresh indicator
  /// becomes armed (ready to refresh).
  Widget _buildCupertinoRefreshControl() {
    // Track previous mode to detect transitions to armed state
    // This variable is captured in the builder closure and persists
    // across builder calls during the refresh control's lifetime
    RefreshIndicatorMode? previousMode;

    return CupertinoSliverRefreshControl(
      onRefresh: _wrapOnRefreshWithMinDuration(),
      builder:
          (
            BuildContext context,
            RefreshIndicatorMode mode,
            double pulledExtent,
            double refreshTriggerPullDistance,
            double refreshIndicatorExtent,
          ) {
            // Trigger haptic feedback when transitioning to armed state
            // (user has pulled far enough to trigger refresh)
            if (enableHaptics &&
                mode == RefreshIndicatorMode.armed &&
                previousMode != RefreshIndicatorMode.armed) {
              HapticFeedback.mediumImpact();
            }

            previousMode = mode;

            // Clamp the extent to avoid negative/overshoot values.
            final extent = pulledExtent.clamp(0.0, refreshIndicatorExtent);

            // Only show the spinner while actively refreshing / armed.
            // We intentionally *don't* show it in drag/other states to avoid
            // brief re-appearances during the bounce-back animation after a
            // completed refresh.
            final showSpinner =
                mode == RefreshIndicatorMode.armed ||
                mode == RefreshIndicatorMode.refresh;

            return SizedBox(
              height: extent,
              width: double.infinity,
              child: Center(
                child: showSpinner
                    ? const CupertinoActivityIndicator()
                    : const SizedBox.shrink(),
              ),
            );
          },
    );
  }

  Widget _buildCupertinoRefreshIndicator(BuildContext context) {
    // For iOS/macOS, we need to wrap the child in a CustomScrollView
    // and add CupertinoSliverRefreshControl as the first sliver.
    // If the child is already a CustomScrollView, we extract its slivers
    // and add the refresh control. Otherwise, we wrap it.

    if (child is CustomScrollView) {
      final customScrollView = child as CustomScrollView;
      return CustomScrollView(
        key: customScrollView.key,
        scrollDirection: customScrollView.scrollDirection,
        reverse: customScrollView.reverse,
        controller: customScrollView.controller,
        primary: customScrollView.primary,
        physics: customScrollView.physics,
        scrollBehavior: customScrollView.scrollBehavior,
        shrinkWrap: customScrollView.shrinkWrap,
        center: customScrollView.center,
        anchor: customScrollView.anchor,
        cacheExtent: customScrollView.cacheExtent,
        semanticChildCount: customScrollView.semanticChildCount,
        dragStartBehavior: customScrollView.dragStartBehavior,
        keyboardDismissBehavior: customScrollView.keyboardDismissBehavior,
        restorationId: customScrollView.restorationId,
        clipBehavior: customScrollView.clipBehavior,
        slivers: [
          _buildCupertinoRefreshControl(),
          ...customScrollView.slivers,
        ],
      );
    }

    // For SingleChildScrollView, extract its child and wrap it in a
    // CustomScrollView with SliverToBoxAdapter to avoid nested scrolling.
    if (child is SingleChildScrollView) {
      final singleChildScrollView = child as SingleChildScrollView;
      // Access the child property directly (it's public in
      // SingleChildScrollView)
      final scrollChild = singleChildScrollView.child;

      return CustomScrollView(
        scrollDirection: singleChildScrollView.scrollDirection,
        reverse: singleChildScrollView.reverse,
        controller: singleChildScrollView.controller,
        primary: singleChildScrollView.primary,
        physics: singleChildScrollView.physics,
        dragStartBehavior: singleChildScrollView.dragStartBehavior,
        keyboardDismissBehavior: singleChildScrollView.keyboardDismissBehavior,
        restorationId: singleChildScrollView.restorationId,
        clipBehavior: singleChildScrollView.clipBehavior,
        slivers: [
          _buildCupertinoRefreshControl(),
          SliverPadding(
            padding: singleChildScrollView.padding ?? EdgeInsets.zero,
            sliver: SliverToBoxAdapter(
              child: scrollChild,
            ),
          ),
        ],
      );
    }

    // For ListView and other scrollable widgets, wrap in CustomScrollView
    if (child is ScrollView) {
      final scrollView = child as ScrollView;
      return CustomScrollView(
        scrollDirection: scrollView.scrollDirection,
        reverse: scrollView.reverse,
        controller: scrollView.controller,
        primary: scrollView.primary,
        physics: scrollView.physics,
        scrollBehavior: scrollView.scrollBehavior,
        shrinkWrap: scrollView.shrinkWrap,
        cacheExtent: scrollView.cacheExtent,
        semanticChildCount: scrollView.semanticChildCount,
        dragStartBehavior: scrollView.dragStartBehavior,
        keyboardDismissBehavior: scrollView.keyboardDismissBehavior,
        restorationId: scrollView.restorationId,
        clipBehavior: scrollView.clipBehavior,
        slivers: [
          _buildCupertinoRefreshControl(),
          SliverFillRemaining(
            child: child,
          ),
        ],
      );
    }

    // For non-scrollable widgets, wrap in CustomScrollView with
    // SliverToBoxAdapter
    return CustomScrollView(
      slivers: [
        _buildCupertinoRefreshControl(),
        SliverToBoxAdapter(
          child: child,
        ),
      ],
    );
  }
}
