import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hydracat/core/theme/app_spacing.dart';

/// Platform-adaptive bottom sheet widget for HydraCat.
///
/// Wraps Material bottom sheet styling on Material platforms and provides
/// Cupertino-style bottom sheet on iOS/macOS, while mirroring the core
/// Material bottom sheet API used in the app.
///
/// This widget provides consistent styling (rounded top corners, background
/// color from theme, safe area handling) suitable for both platforms.
///
/// Automatically adds bottom breathing room to ensure content
/// and primary actions
/// have comfortable clearance from the system home indicator on all platforms.
/// The bottom spacing includes the system safe area inset plus a minimum
/// breathing room constant (see [AppSpacing.bottomSheetInset]).
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
    final mediaQuery = MediaQuery.of(context);

    // Resolve default values
    final resolvedBackgroundColor =
        backgroundColor ?? theme.scaffoldBackgroundColor;
    // iOS-style rounded corners: use larger radius (24px) for iOS feel
    // Material Design typically uses smaller radius (20px)
    final resolvedBorderRadius =
        borderRadius ??
        (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS
            ? const BorderRadius.vertical(top: Radius.circular(24))
            : const BorderRadius.vertical(top: Radius.circular(20)));

    // Calculate bottom padding: add breathing room to any custom padding
    final basePadding = padding ?? EdgeInsets.zero;
    final resolvedPadding = EdgeInsets.only(
      left: basePadding.left,
      top: basePadding.top,
      right: basePadding.right,
      bottom: basePadding.bottom,
    );

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
      final screenHeight = mediaQuery.size.height;
      content = SizedBox(
        height: screenHeight * heightFraction!.clamp(0.0, 1.0),
        child: content,
      );
    }

    // Wrap in SafeArea with bottom breathing room for all platforms
    // This ensures content has comfortable clearance
    // from the system home indicator
    // The minimum parameter adds extra breathing room
    // beyond the system safe area
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: AppSpacing.bottomSheetInset),
      child: content,
    );
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
/// **Note**: The [useSafeArea] parameter defaults to `false` because
/// [HydraBottomSheet] handles safe area spacing internally.
/// Setting it to `true` may result in double-padding.
/// The bottom sheet automatically provides
/// comfortable breathing room from the system home indicator on all platforms.
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
  final theme = Theme.of(context);
  final platform = Theme.of(context).platform;

  // Provide a default background color if none is specified
  // This ensures the bottom sheet is never transparent by default
  final resolvedBackgroundColor =
      backgroundColor ?? theme.scaffoldBackgroundColor;

  // Give iOS/macOS a slightly stronger dimmed background by default,
  // while keeping Material platforms on the framework default when null.
  final resolvedBarrierColor =
      barrierColor ??
      (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS
          ? CupertinoColors.black.withValues(alpha: 0.4)
          : null);

  // iOS-style rounded corners: use larger radius (24px) for iOS feel
  // Material Design typically uses smaller radius (20px),
  // but we'll use iOS-style for consistency
  final resolvedShape =
      shape ??
      RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(
            platform == TargetPlatform.iOS || platform == TargetPlatform.macOS
                ? 24
                : 20,
          ),
        ),
      );

  return showModalBottomSheet<T>(
    context: context,
    builder: builder,
    backgroundColor: resolvedBackgroundColor,
    elevation: elevation,
    shape: resolvedShape,
    clipBehavior: clipBehavior ?? Clip.antiAlias,
    constraints: constraints,
    barrierColor: resolvedBarrierColor,
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
