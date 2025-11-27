import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Platform-adaptive alert dialog for HydraCat.
///
/// Wraps [AlertDialog] on Material platforms and [CupertinoAlertDialog] on
/// iOS/macOS, while mirroring the core [AlertDialog] API used in the app.
///
/// This is a drop-in replacement for [AlertDialog] in most cases. Some
/// Material-specific properties (like [icon], [shape], [backgroundColor]) are
/// ignored on Cupertino platforms.
class HydraAlertDialog extends StatelessWidget {
  /// Creates a platform-adaptive alert dialog.
  ///
  /// The [title] and [content] parameters are typically used to display
  /// information to the user. The [actions] parameter provides buttons
  /// for user interaction.
  const HydraAlertDialog({
    this.title,
    this.content,
    this.actions,
    this.icon,
    this.scrollable = false,
    this.shape,
    this.backgroundColor,
    this.insetPadding,
    this.constraints,
    this.semanticLabel,
    super.key,
  });

  /// The (optional) title of the dialog is displayed in the largest font at
  /// the top of the dialog, below the [icon] (if one is provided).
  ///
  /// Typically a [Text] widget.
  final Widget? title;

  /// The (optional) content of the dialog is displayed in the center of the
  /// dialog in a lighter font.
  ///
  /// Typically this is a [Text] widget or a [SingleChildScrollView] containing
  /// a longer message.
  final Widget? content;

  /// The (optional) set of actions that are displayed at the bottom of the
  /// dialog.
  ///
  /// Typically this is a list of [TextButton], [ElevatedButton], or
  /// [FilledButton] widgets. On Cupertino platforms, these are automatically
  /// converted to [CupertinoDialogAction] widgets.
  final List<Widget>? actions;

  /// The (optional) icon to display at the top of the dialog.
  ///
  /// Typically an [Icon] widget. This property is ignored on Cupertino
  /// platforms.
  final Widget? icon;

  /// Whether the content should be scrollable.
  ///
  /// On Material platforms, this controls whether the content is wrapped in
  /// a scrollable widget. On Cupertino platforms, the content is always
  /// scrollable if needed.
  final bool scrollable;

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
  /// This property is ignored on Cupertino platforms.
  final EdgeInsets? insetPadding;

  /// The constraints for the dialog's size.
  ///
  /// This property is ignored on Cupertino platforms.
  final BoxConstraints? constraints;

  /// The semantic label of the dialog used by accessibility frameworks.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;

    if (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS) {
      return _buildCupertinoDialog(context);
    }

    return _buildMaterialDialog(context);
  }

  Widget _buildMaterialDialog(BuildContext context) {
    final dialogContent = scrollable && content != null
        ? SingleChildScrollView(child: content)
        : content;

    return AlertDialog(
      title: title,
      content: dialogContent,
      actions: actions,
      icon: icon,
      shape: shape,
      backgroundColor: backgroundColor,
      insetPadding: insetPadding,
      constraints: constraints,
      semanticLabel: semanticLabel,
    );
  }

  Widget _buildCupertinoDialog(BuildContext context) {
    // Convert actions to CupertinoDialogAction
    final cupertinoActions = _convertActionsToCupertino(context, actions);

    return CupertinoAlertDialog(
      title: title,
      content: content,
      actions: cupertinoActions,
    );
  }

  /// Converts Material action widgets to CupertinoDialogAction widgets.
  ///
  /// Attempts to extract text and onPressed callbacks from common Material
  /// button widgets (TextButton, ElevatedButton, FilledButton). For complex
  /// widgets that cannot be converted, wraps them in a CupertinoDialogAction
  /// with a generic handler.
  List<CupertinoDialogAction> _convertActionsToCupertino(
    BuildContext context,
    List<Widget>? actions,
  ) {
    if (actions == null || actions.isEmpty) {
      return [];
    }

    final theme = Theme.of(context);
    final errorColor = theme.colorScheme.error;

    return actions.map((action) {
      // Try to extract text and onPressed from common button types
      final extracted = _extractButtonInfo(context, action, errorColor);
      if (extracted != null) {
        return CupertinoDialogAction(
          onPressed: extracted.onPressed,
          isDefaultAction: extracted.isDefault,
          isDestructiveAction: extracted.isDestructive,
          child: Text(extracted.text),
        );
      }

      // For complex widgets, wrap in a CupertinoDialogAction
      // This is a fallback for widgets we can't automatically convert
      return CupertinoDialogAction(
        child: action,
      );
    }).toList();
  }

  /// Extracts text, onPressed, and styling info from common Material buttons.
  ///
  /// Returns null if the widget cannot be automatically converted.
  _ButtonInfo? _extractButtonInfo(
    BuildContext context,
    Widget widget,
    Color errorColor,
  ) {
    // Handle TextButton
    if (widget is TextButton) {
      final text = _extractTextFromChild(widget.child);
      if (text != null) {
        // Check if foreground color suggests destructive action
        final isDestructive =
            widget.style?.foregroundColor?.resolve({}) == errorColor ||
            widget.style?.foregroundColor?.resolve({}) == Colors.red ||
            widget.style?.foregroundColor?.resolve({}) == Colors.orange;
        return _ButtonInfo(
          text: text,
          onPressed: widget.onPressed,
          isDefault: false,
          isDestructive: isDestructive,
        );
      }
    }

    // Handle ElevatedButton
    if (widget is ElevatedButton) {
      final text = _extractTextFromChild(widget.child);
      if (text != null) {
        // Check if it's destructive based on background or foreground color
        final bgColor = widget.style?.backgroundColor?.resolve({});
        final fgColor = widget.style?.foregroundColor?.resolve({});
        final isDestructive =
            bgColor == errorColor ||
            bgColor == Colors.red ||
            fgColor == errorColor ||
            fgColor == Colors.red;
        return _ButtonInfo(
          text: text,
          onPressed: widget.onPressed,
          isDefault: true,
          isDestructive: isDestructive,
        );
      }
    }

    // Handle FilledButton
    if (widget is FilledButton) {
      final text = _extractTextFromChild(widget.child);
      if (text != null) {
        // Check if it's destructive based on background or foreground color
        final bgColor = widget.style?.backgroundColor?.resolve({});
        final fgColor = widget.style?.foregroundColor?.resolve({});
        final isDestructive =
            bgColor == errorColor ||
            bgColor == Colors.red ||
            fgColor == errorColor ||
            fgColor == Colors.red;
        return _ButtonInfo(
          text: text,
          onPressed: widget.onPressed,
          isDefault: true,
          isDestructive: isDestructive,
        );
      }
    }

    // Handle OutlinedButton
    if (widget is OutlinedButton) {
      final text = _extractTextFromChild(widget.child);
      if (text != null) {
        // Check if foreground color suggests destructive action
        final isDestructive =
            widget.style?.foregroundColor?.resolve({}) == errorColor ||
            widget.style?.foregroundColor?.resolve({}) == Colors.red;
        return _ButtonInfo(
          text: text,
          onPressed: widget.onPressed,
          isDefault: false,
          isDestructive: isDestructive,
        );
      }
    }

    return null;
  }

  /// Extracts text from a widget, handling Text widgets and common patterns.
  String? _extractTextFromChild(Widget? child) {
    if (child == null) return null;

    if (child is Text) {
      return child.data ?? child.textSpan?.toPlainText();
    }

    // Handle SizedBox with Text inside (common pattern)
    if (child is SizedBox) {
      return _extractTextFromChild(child.child);
    }

    // Handle Row/Column with Text (less common but possible)
    if (child is Row || child is Column) {
      // Try to find Text in children
      // This is a simplified approach - for complex layouts, we return null
      return null;
    }

    return null;
  }
}

/// Internal helper class to hold extracted button information.
class _ButtonInfo {
  const _ButtonInfo({
    required this.text,
    required this.onPressed,
    required this.isDefault,
    required this.isDestructive,
  });

  final String text;
  final VoidCallback? onPressed;
  final bool isDefault;
  final bool isDestructive;
}

/// Shows a platform-adaptive alert dialog.
///
/// This is a convenience function that wraps [showDialog] on Material
/// platforms and [showCupertinoDialog] on iOS/macOS, displaying a
/// [HydraAlertDialog] widget.
///
/// Returns a [Future] that resolves to the value passed to [Navigator.pop]
/// when the dialog is dismissed.
///
/// Example:
/// ```dart
/// final confirmed = await showHydraAlertDialog<bool>(
///   context: context,
///   builder: (context) => HydraAlertDialog(
///     title: const Text('Confirm'),
///     content: const Text('Are you sure?'),
///     actions: [
///       TextButton(
///         onPressed: () => Navigator.of(context).pop(false),
///         child: const Text('Cancel'),
///       ),
///       FilledButton(
///         onPressed: () => Navigator.of(context).pop(true),
///         child: const Text('OK'),
///       ),
///     ],
///   ),
/// );
/// ```
Future<T?> showHydraAlertDialog<T>({
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
