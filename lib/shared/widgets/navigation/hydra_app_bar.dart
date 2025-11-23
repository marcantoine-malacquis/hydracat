import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Platform-adaptive app bar for HydraCat.
///
/// Wraps [AppBar] on Material platforms and [CupertinoNavigationBar] on iOS/macOS,
/// while mirroring the core [AppBar] API used in the app.
///
/// **API Differences:**
/// - Material: Full [AppBar] support including `title`, `actions`, `leading`,
///   `backgroundColor`, `elevation`, `centerTitle`, etc.
/// - Cupertino: `title` maps to `middle`, `actions` maps to `trailing`
///   (wrapped in a [Row] if multiple), `leading` maps directly.
///   `backgroundColor` is applied where supported. `elevation` is ignored on
///   Cupertino (no elevation concept). `centerTitle` controls title alignment.
///   `foregroundColor` maps to text color.
///
/// Example:
/// ```dart
/// Scaffold(
///   appBar: HydraAppBar(
///     title: const Text('My Screen'),
///     actions: [
///       IconButton(
///         icon: const Icon(Icons.settings),
///         onPressed: () {},
///       ),
///     ],
///   ),
///   body: ...,
/// )
/// ```
class HydraAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Creates a platform-adaptive app bar.
  const HydraAppBar({
    this.title,
    this.leading,
    this.actions,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.centerTitle,
    this.automaticallyImplyLeading = true,
    this.toolbarHeight,
    super.key,
  });

  /// The primary widget displayed in the app bar.
  ///
  /// On Material platforms, this is used as the [AppBar.title].
  /// On Cupertino platforms, this is used as the
  /// [CupertinoNavigationBar.middle].
  final Widget? title;

  /// Widget to display before the [title].
  ///
  /// On Material platforms, this is used as the [AppBar.leading].
  /// On Cupertino platforms, this is used as the
  /// [CupertinoNavigationBar.leading].
  ///
  /// If null and [automaticallyImplyLeading] is true, Material will show a back
  /// button. Cupertino does not automatically show a back button.
  final Widget? leading;

  /// Widgets to display after the [title].
  ///
  /// On Material platforms, these are used as the [AppBar.actions].
  /// On Cupertino platforms, these are wrapped in a [Row] and used as the
  /// [CupertinoNavigationBar.trailing].
  final List<Widget>? actions;

  /// The background color of the app bar.
  ///
  /// On Material platforms, this is used as the [AppBar.backgroundColor].
  /// On Cupertino platforms, this is used as the
  /// [CupertinoNavigationBar.backgroundColor].
  /// If the color is transparent, the Cupertino border is removed.
  final Color? backgroundColor;

  /// The foreground color of the app bar.
  ///
  /// On Material platforms, this is used as the [AppBar.foregroundColor].
  /// On Cupertino platforms, this affects the text color of the title and
  /// icons.
  final Color? foregroundColor;

  /// The elevation of the app bar.
  ///
  /// Only applies to Material platforms. On Cupertino platforms, this is
  /// ignored (Cupertino does not use elevation).
  final double? elevation;

  /// Whether the title should be centered.
  ///
  /// On Material platforms, this is used as the [AppBar.centerTitle].
  /// On Cupertino platforms, this controls whether the title is centered in the
  /// middle section.
  final bool? centerTitle;

  /// Whether to automatically imply a leading widget if there is none.
  ///
  /// On Material platforms, this is used as the
  /// [AppBar.automaticallyImplyLeading].
  /// On Cupertino platforms, this is ignored (Cupertino does not automatically
  /// show a back button).
  final bool automaticallyImplyLeading;

  /// The height of the app bar.
  ///
  /// On Material platforms, this is used as the [AppBar.toolbarHeight].
  /// On Cupertino platforms, this is used to determine the preferred size.
  final double? toolbarHeight;

  @override
  Size get preferredSize {
    final height = toolbarHeight ?? kToolbarHeight;
    return Size.fromHeight(height);
  }

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;

    if (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS) {
      return _buildCupertinoAppBar(context);
    }

    return _buildMaterialAppBar(context);
  }

  Widget _buildMaterialAppBar(BuildContext context) {
    return AppBar(
      title: title,
      leading: leading,
      actions: actions,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      elevation: elevation,
      centerTitle: centerTitle,
      automaticallyImplyLeading: automaticallyImplyLeading,
      toolbarHeight: toolbarHeight,
    );
  }

  Widget _buildCupertinoAppBar(BuildContext context) {
    // Build trailing widget from actions
    Widget? trailing;
    if (actions != null && actions!.isNotEmpty) {
      if (actions!.length == 1) {
        trailing = actions!.first;
      } else {
        // Wrap multiple actions in a Row
        trailing = Row(
          mainAxisSize: MainAxisSize.min,
          children: actions!,
        );
      }
    }

    // Determine if we should show a border
    // If backgroundColor is transparent, remove the border for a cleaner look
    final showBorder = backgroundColor != Colors.transparent;

    // Apply foreground color to title and icons if provided
    var middleWidget = title;
    final titleValue = title;
    if (foregroundColor != null && titleValue != null) {
      if (titleValue is Text) {
        final text = titleValue;
        middleWidget = Text(
          text.data ?? '',
          style: text.style?.copyWith(color: foregroundColor) ??
              TextStyle(color: foregroundColor),
          textAlign: (centerTitle ?? false) ? TextAlign.center : null,
        );
      } else {
        // For non-Text titles, wrap in DefaultTextStyle
        middleWidget = DefaultTextStyle(
          style: TextStyle(color: foregroundColor),
          child: titleValue,
        );
      }
    } else if ((centerTitle ?? false) && titleValue is Text) {
      // Apply center alignment if requested
      final text = titleValue;
      middleWidget = Text(
        text.data ?? '',
        style: text.style,
        textAlign: TextAlign.center,
      );
    }

    return CupertinoNavigationBar(
      middle: middleWidget,
      leading: leading,
      trailing: trailing,
      backgroundColor: backgroundColor,
      border: showBorder
          ? const Border(
              bottom: BorderSide(
                color: CupertinoColors.separator,
                width: 0, // Hairline width
              ),
            )
          : null,
    );
  }
}
