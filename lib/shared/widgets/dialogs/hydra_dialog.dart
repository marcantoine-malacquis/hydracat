import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Platform-adaptive dialog for HydraCat.
///
/// Wraps [Dialog] on Material platforms and [CupertinoPopupSurface] on
/// iOS/macOS, while mirroring the core [Dialog] API used in the app.
///
/// This is a drop-in replacement for [Dialog] in most cases. Some
/// Material-specific properties (like [shape], [backgroundColor], [elevation])
/// are ignored on Cupertino platforms.
class HydraDialog extends StatelessWidget {
  /// Creates a platform-adaptive dialog.
  ///
  /// The [child] parameter is required and contains the dialog content.
  const HydraDialog({
    required this.child,
    this.shape,
    this.backgroundColor,
    this.insetPadding,
    this.clipBehavior,
    this.elevation,
    super.key,
  });

  /// The widget below this widget in the tree.
  ///
  /// Typically a [Column], [Row], or other layout widget containing the
  /// dialog's content.
  final Widget child;

  /// The shape of the dialog's [Material].
  ///
  /// This property is ignored on Cupertino platforms.
  final ShapeBorder? shape;

  /// The background color of the dialog.
  ///
  /// This property is ignored on Cupertino platforms.
  final Color? backgroundColor;

  /// The padding around the dialog.
  ///
  /// On Material platforms, this is the minimum padding around the dialog.
  /// On Cupertino platforms, this is used to determine spacing around the
  /// popup surface.
  final EdgeInsets? insetPadding;

  /// The clip behavior of the dialog.
  ///
  /// This property is ignored on Cupertino platforms.
  final Clip? clipBehavior;

  /// The elevation of the dialog's [Material].
  ///
  /// This property is ignored on Cupertino platforms.
  final double? elevation;

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;

    if (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS) {
      return _buildCupertinoDialog(context);
    }

    return _buildMaterialDialog(context);
  }

  Widget _buildMaterialDialog(BuildContext context) {
    return Dialog(
      shape: shape,
      backgroundColor: backgroundColor,
      insetPadding: insetPadding,
      clipBehavior: clipBehavior,
      elevation: elevation,
      child: child,
    );
  }

  Widget _buildCupertinoDialog(BuildContext context) {
    // CupertinoPopupSurface does not support shape, backgroundColor, elevation,
    // or clipBehavior. We use insetPadding to determine spacing around the
    // popup surface, defaulting to a reasonable value if not provided.
    final resolvedInsetPadding =
        insetPadding ??
        const EdgeInsets.symmetric(horizontal: 40, vertical: 24);

    return Center(
      child: Padding(
        padding: resolvedInsetPadding,
        child: CupertinoPopupSurface(
          child: child,
        ),
      ),
    );
  }
}

/// Shows a platform-adaptive dialog.
///
/// This is a convenience function that wraps [showDialog] on Material
/// platforms and [showCupertinoDialog] on iOS/macOS, displaying a
/// [HydraDialog] widget.
///
/// Returns a [Future] that resolves to the value passed to [Navigator.pop]
/// when the dialog is dismissed.
///
/// Example:
/// ```dart
/// final result = await showHydraDialog<String>(
///   context: context,
///   builder: (context) => HydraDialog(
///     shape: RoundedRectangleBorder(
///       borderRadius: BorderRadius.circular(16),
///     ),
///     child: Column(
///       mainAxisSize: MainAxisSize.min,
///       children: [
///         const Text('Custom Dialog'),
///         TextButton(
///           onPressed: () => Navigator.of(context).pop('OK'),
///           child: const Text('OK'),
///         ),
///       ],
///     ),
///   ),
/// );
/// ```
Future<T?> showHydraDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  Color? barrierColor,
  String? barrierLabel,
  bool useSafeArea = true,
  bool useRootNavigator = false,
  RouteSettings? routeSettings,
}) {
  final platform = Theme.of(context).platform;

  if (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS) {
    return showCupertinoDialog<T>(
      context: context,
      builder: builder,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
      barrierLabel: barrierLabel,
      useRootNavigator: useRootNavigator,
      routeSettings: routeSettings,
    );
  }

  return showDialog<T>(
    context: context,
    builder: builder,
    barrierDismissible: barrierDismissible,
    barrierColor: barrierColor,
    barrierLabel: barrierLabel,
    useSafeArea: useSafeArea,
    useRootNavigator: useRootNavigator,
    routeSettings: routeSettings,
  );
}
