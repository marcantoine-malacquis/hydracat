import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hydracat/core/constants/app_colors.dart';
import 'package:hydracat/shared/widgets/navigation/hydra_app_bar.dart';

/// A shared scaffold widget that centralizes Scaffold, optional AppBar,
/// SafeArea, and SystemUiOverlayStyle management.
///
/// This widget provides a consistent way to wrap screens with proper
/// scaffolding, system UI styling, and optional app bar support.
///
/// Example:
/// ```dart
/// // Screen without app bar
/// AppScaffold(
///   showAppBar: false,
///   body: MyScreenContent(),
/// )
///
/// // Screen with app bar
/// AppScaffold(
///   title: 'My Screen',
///   actions: [IconButton(...)],
///   body: MyScreenContent(),
/// )
/// ```
class AppScaffold extends StatelessWidget {
  /// Creates an AppScaffold.
  const AppScaffold({
    required this.body,
    this.title,
    this.titleWidget,
    this.actions,
    this.leading,
    this.showAppBar = true,
    this.safeArea = true,
    this.extendBodyBehindAppBar = false,
    this.backgroundColor,
    this.appBarStyle = HydraAppBarStyle.default_,
    super.key,
  });

  /// The main content to display.
  final Widget body;

  /// Optional title text for the app bar.
  ///
  /// If both [title] and [titleWidget] are provided,
  /// [titleWidget] takes precedence.
  final String? title;

  /// Optional title widget for the app bar.
  ///
  /// Takes precedence over [title] if both are provided.
  final Widget? titleWidget;

  /// Optional actions to display in the app bar.
  final List<Widget>? actions;

  /// Optional leading widget for the app bar.
  final Widget? leading;

  /// Whether to show the app bar.
  ///
  /// Defaults to `true`.
  final bool showAppBar;

  /// Whether to wrap the body in a SafeArea.
  ///
  /// Defaults to `true`.
  final bool safeArea;

  /// Whether to extend the body behind the app bar.
  ///
  /// Defaults to `false`.
  final bool extendBodyBehindAppBar;

  /// Background color for the scaffold.
  ///
  /// Defaults to [AppColors.background] if not provided.
  final Color? backgroundColor;

  /// Style variant for the app bar.
  ///
  /// Defaults to [HydraAppBarStyle.default_].
  final HydraAppBarStyle appBarStyle;

  /// Gets the system UI overlay style based on background brightness.
  SystemUiOverlayStyle _getSystemUiOverlayStyle(Color bgColor) {
    // Calculate brightness of background
    final brightness = ThemeData.estimateBrightnessForColor(bgColor);
    return brightness == Brightness.dark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;
  }

  @override
  Widget build(BuildContext context) {
    final resolvedBackgroundColor = backgroundColor ?? AppColors.background;
    final systemOverlayStyle = _getSystemUiOverlayStyle(
      resolvedBackgroundColor,
    );

    // Build app bar if needed
    final appBar = showAppBar
        ? HydraAppBar(
            title: titleWidget ?? (title != null ? Text(title!) : null),
            leading: leading,
            actions: actions,
            style: appBarStyle,
          )
        : null;

    // Build body with optional SafeArea
    var bodyWidget = body;
    if (safeArea) {
      bodyWidget = SafeArea(child: body);
    }

    // Apply system UI overlay style and build scaffold
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemOverlayStyle,
      child: Scaffold(
        backgroundColor: resolvedBackgroundColor,
        appBar: appBar,
        extendBodyBehindAppBar: extendBodyBehindAppBar,
        body: bodyWidget,
      ),
    );
  }
}
