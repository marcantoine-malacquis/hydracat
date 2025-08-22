import 'package:flutter/material.dart';
import 'package:hydracat/core/constants/app_colors.dart';
import 'package:hydracat/shared/widgets/layout/layout_wrapper.dart';

/// A wrapper for screens that provides consistent background, padding,
/// and safe area handling.
class ScreenWrapper extends StatelessWidget {
  /// Creates a screen wrapper with optional customization.
  const ScreenWrapper({
    required this.child,
    super.key,
    this.backgroundColor,
    this.padding,
    this.scrollable = false,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
  });

  /// The main content of the screen.
  final Widget child;

  /// Background color for the screen.
  final Color? backgroundColor;

  /// Custom padding for the content.
  final EdgeInsetsGeometry? padding;

  /// Whether the content should be scrollable.
  final bool scrollable;

  /// Optional app bar for the screen.
  final PreferredSizeWidget? appBar;

  /// Optional bottom navigation bar.
  final Widget? bottomNavigationBar;

  /// Optional floating action button.
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final content = LayoutWrapper(
      padding: padding,
      child: child,
    );

    final body = scrollable
        ? SingleChildScrollView(
            child: content,
          )
        : content;

    return Scaffold(
      backgroundColor: backgroundColor ?? AppColors.background,
      appBar: appBar,
      body: SafeArea(
        child: body,
      ),
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }
}
