import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Platform-adaptive bottom sheet widget for HydraCat.
///
/// Wraps Material bottom sheet styling on Material platforms and provides
/// Cupertino-style bottom sheet on iOS/macOS, while mirroring the core
/// Material bottom sheet API used in the app.
///
/// This widget provides consistent styling (rounded top corners, background
/// color from theme, safe area handling) suitable for both platforms.
class HydraBottomSheet extends StatelessWidget {
  /// Creates a platform-adaptive bottom sheet widget.
  ///
  /// The [child] parameter is required and contains the bottom sheet content.
  const HydraBottomSheet({
    required this.child,
    this.heightFraction,
    this.padding,
    this.backgroundColor,
    this.borderRadius,
    super.key,
  });

  /// The widget below this widget in the tree.
  ///
  /// Typically a [Column], [SingleChildScrollView], or other layout widget
  /// containing the bottom sheet's content.
  final Widget child;

  /// Optional height as a fraction of screen height (0.0 to 1.0).
  ///
  /// If null, the bottom sheet will size to its content.
  /// Defaults to null (content-sized).
  final double? heightFraction;

  /// Optional padding around the content.
  ///
  /// Defaults to platform-appropriate padding if not provided.
  final EdgeInsets? padding;

  /// Optional background color.
  ///
  /// Defaults to scaffold background color from theme if not provided.
  final Color? backgroundColor;

  /// Optional border radius for the top corners.
  ///
  /// Defaults to platform-appropriate radius if not provided.
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;
    final theme = Theme.of(context);

    // Resolve default values
    final resolvedBackgroundColor =
        backgroundColor ?? theme.scaffoldBackgroundColor;
    final resolvedBorderRadius =
        borderRadius ??
        (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS
            ? const BorderRadius.vertical(top: Radius.circular(20))
            : const BorderRadius.vertical(top: Radius.circular(20)));
    final resolvedPadding =
        padding ??
        (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS
            ? EdgeInsets.zero
            : EdgeInsets.zero);

    Widget content = Container(
      decoration: BoxDecoration(
        color: resolvedBackgroundColor,
        borderRadius: resolvedBorderRadius,
      ),
      padding: resolvedPadding,
      child: child,
    );

    // Apply height fraction if specified
    if (heightFraction != null) {
      final screenHeight = MediaQuery.of(context).size.height;
      content = SizedBox(
        height: screenHeight * heightFraction!.clamp(0.0, 1.0),
        child: content,
      );
    }

    // Wrap in SafeArea for iOS/macOS
    if (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS) {
      return SafeArea(
        top: false,
        child: content,
      );
    }

    return content;
  }
}

/// Shows a platform-adaptive bottom sheet.
///
/// This is a convenience function that wraps [showModalBottomSheet] on Material
/// platforms and [showCupertinoModalPopup] on iOS/macOS, displaying a
/// platform-appropriate bottom sheet.
///
/// Returns a [Future] that resolves to the value passed to [Navigator.pop]
/// when the bottom sheet is dismissed.
///
/// Example:
/// ```dart
/// await showHydraBottomSheet<void>(
///   context: context,
///   builder: (context) => HydraBottomSheet(
///     heightFraction: 0.85,
///     child: Column(
///       children: [
///         Text('Bottom Sheet Content'),
///         ElevatedButton(
///           onPressed: () => Navigator.of(context).pop(),
///           child: const Text('Close'),
///         ),
///       ],
///     ),
///   ),
/// );
/// ```
Future<T?> showHydraBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  Color? backgroundColor,
  double? elevation,
  ShapeBorder? shape,
  Clip? clipBehavior,
  BoxConstraints? constraints,
  Color? barrierColor,
  bool isScrollControlled = false,
  bool useRootNavigator = false,
  bool isDismissible = true,
  bool enableDrag = true,
  bool useSafeArea = false,
  RouteSettings? routeSettings,
  AnimationController? transitionAnimationController,
  Offset? anchorPoint,
}) {
  final platform = Theme.of(context).platform;
  final theme = Theme.of(context);

  if (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS) {
    return _showCupertinoBottomSheet<T>(
      context: context,
      builder: builder,
      barrierColor: barrierColor,
      useRootNavigator: useRootNavigator,
      isDismissible: isDismissible,
      routeSettings: routeSettings,
    );
  }

  // Provide a default background color if none is specified
  // This ensures the bottom sheet is never transparent by default
  final resolvedBackgroundColor =
      backgroundColor ?? theme.scaffoldBackgroundColor;

  return showModalBottomSheet<T>(
    context: context,
    builder: builder,
    backgroundColor: resolvedBackgroundColor,
    elevation: elevation,
    shape: shape,
    clipBehavior: clipBehavior,
    constraints: constraints,
    barrierColor: barrierColor,
    isScrollControlled: isScrollControlled,
    useRootNavigator: useRootNavigator,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    useSafeArea: useSafeArea,
    routeSettings: routeSettings,
    transitionAnimationController: transitionAnimationController,
    anchorPoint: anchorPoint,
  );
}

/// Internal helper to show Cupertino-style bottom sheet.
Future<T?> _showCupertinoBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  Color? barrierColor,
  bool useRootNavigator = false,
  bool isDismissible = true,
  RouteSettings? routeSettings,
}) {
  // For Cupertino, we use showCupertinoModalPopup which provides the
  // iOS-style modal presentation. The builder should return a widget
  // wrapped in HydraBottomSheet for consistent styling.
  return showCupertinoModalPopup<T>(
    context: context,
    builder: builder,
    barrierColor: barrierColor ?? CupertinoColors.black.withValues(alpha: 0.4),
    useRootNavigator: useRootNavigator,
    semanticsDismissible: isDismissible,
    routeSettings: routeSettings,
  );
}
