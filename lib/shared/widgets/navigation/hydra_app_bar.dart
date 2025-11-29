import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hydracat/core/constants/app_colors.dart';
import 'package:hydracat/core/theme/app_spacing.dart';

/// App bar style variants.
///
/// - [default_]: Subtle tonal surface (6% primary blend) with border.
///   Use for all standard app surfaces (default behavior).
/// - [accent]: Stronger primary blend (12% primary blend) with border.
///   **Reserved for analytics/insights screens only** (e.g., Progress & Analytics,
///   Injection Sites Analytics). Use consistently on all screens of that type.
/// - [transparent]: Fully transparent background, no border.
///   Use for onboarding or overlay screens where content extends behind
///   the app bar.
enum HydraAppBarStyle {
  /// Default variant: subtle tonal surface with border.
  ///
  /// Use for all standard app surfaces. This is the default and should be used
  /// unless there's a specific semantic reason for accent.
  default_,

  /// Accent variant: stronger primary blend with border.
  ///
  /// **Reserved exclusively for analytics/insights screens** that need visual
  /// framing or hierarchy. Currently used on:
  /// - Progress & Analytics screen
  /// - Injection Sites Analytics screen
  ///
  /// Never mix arbitrarily: each screen type should consistently use the same
  /// variant. No per-screen "pick a color" decisions.
  accent,

  /// Transparent variant: no background, no border.
  ///
  /// Use for onboarding or overlay screens where content extends behind
  /// the app bar.
  transparent,
}

/// Platform-adaptive app bar for HydraCat.
///
/// Wraps [AppBar] on Material platforms and [CupertinoNavigationBar] on iOS/macOS,
/// while mirroring the core [AppBar] API used in the app.
///
/// **Style Variants:**
/// - [HydraAppBarStyle.default_]: Subtle tonal surface (6% primary blend)
///   with border. Use for all standard app surfaces. This is the default
///   and should be used unless there's a specific semantic reason for accent.
/// - [HydraAppBarStyle.accent]: Stronger primary blend (12% primary blend)
///   with border. **Reserved exclusively for analytics/insights screens**
///   that need visual framing or hierarchy (e.g., Progress & Analytics,
///   Injection Sites Analytics). Use consistently on all screens of that type.
///   Never mix arbitrarily.
/// - [HydraAppBarStyle.transparent]: Fully transparent background,
///   no border. Use for onboarding or overlay screens where content extends
///   behind the app bar.
///
/// **API Differences:**
/// - Material: Full [AppBar] support including `title`, `actions`, `leading`,
///   `elevation`, `centerTitle`, etc.
/// - Cupertino: `title` maps to `middle`, `actions` maps to `trailing`
///   (wrapped in a [Row] if multiple), `leading` maps directly.
///   `backgroundColor` is applied where supported. `elevation` is ignored on
///   Cupertino (no elevation concept). `centerTitle` controls title alignment.
///   `foregroundColor` maps to text color.
///
/// Example:
/// ```dart
/// // Standard screen (uses default variant)
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
///
/// // Analytics/insights screen (uses accent variant)
/// Scaffold(
///   appBar: HydraAppBar(
///     title: const Text('Progress & Analytics'),
///     style: HydraAppBarStyle.accent,
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
    this.style = HydraAppBarStyle.default_,
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

  /// The style variant for the app bar.
  ///
  /// Defaults to [HydraAppBarStyle.default_].
  final HydraAppBarStyle style;

  /// The background color of the app bar.
  ///
  /// If provided, this overrides the color from [style].
  /// On Material platforms, this is used as the [AppBar.backgroundColor].
  /// On Cupertino platforms, this is used as the
  /// [CupertinoNavigationBar.backgroundColor].
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
  /// If null, uses [AppSpacing.appBarHeight] from theme.
  /// On Material platforms, this is used as the [AppBar.toolbarHeight].
  /// On Cupertino platforms, this is used to determine the preferred size.
  final double? toolbarHeight;

  @override
  Size get preferredSize {
    final height = toolbarHeight ?? AppSpacing.appBarHeight;
    return Size.fromHeight(height);
  }

  /// Gets the background color for the current style.
  Color _getBackgroundColor() {
    if (backgroundColor != null) {
      return backgroundColor!;
    }

    switch (style) {
      case HydraAppBarStyle.default_:
        return Color.alphaBlend(
          AppColors.primary.withValues(alpha: 0.06),
          AppColors.background,
        );
      case HydraAppBarStyle.accent:
        return Color.alphaBlend(
          AppColors.primary.withValues(alpha: 0.12),
          AppColors.background,
        );
      case HydraAppBarStyle.transparent:
        return Colors.transparent;
    }
  }

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
    final platform = Theme.of(context).platform;
    final resolvedBackgroundColor = _getBackgroundColor();
    final systemOverlayStyle = _getSystemUiOverlayStyle(
      resolvedBackgroundColor,
    );

    // Apply system UI overlay style
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemOverlayStyle,
      child: Builder(
        builder: (context) {
          if (platform == TargetPlatform.iOS ||
              platform == TargetPlatform.macOS) {
            return _buildCupertinoAppBar(context, resolvedBackgroundColor);
          }

          return _buildMaterialAppBar(context, resolvedBackgroundColor);
        },
      ),
    );
  }

  Widget _buildMaterialAppBar(
    BuildContext context,
    Color resolvedBackgroundColor,
  ) {
    // Wrap title with horizontal padding
    final paddedTitle = title != null
        ? Padding(
            padding: AppSpacing.appBarContentPadding,
            child: title,
          )
        : null;

    // Wrap actions with padding (right padding on last action)
    final paddedActions = actions != null && actions!.isNotEmpty
        ? actions!.asMap().entries.map((entry) {
            final index = entry.key;
            final action = entry.value;
            return Padding(
              padding: EdgeInsets.only(
                right: index == actions!.length - 1 ? AppSpacing.md : 0,
              ),
              child: action,
            );
          }).toList()
        : null;

    return AppBar(
      title: paddedTitle,
      leading: leading,
      actions: paddedActions,
      backgroundColor: resolvedBackgroundColor,
      foregroundColor: foregroundColor,
      elevation: elevation,
      surfaceTintColor: Colors.transparent,
      centerTitle: centerTitle ?? true,
      automaticallyImplyLeading: automaticallyImplyLeading,
      toolbarHeight: toolbarHeight ?? AppSpacing.appBarHeight,
      titleSpacing: 0, // Remove default spacing since we handle padding
      leadingWidth:
          AppSpacing.appBarContentPadding.horizontal + 56, // Icon + padding
    );
  }

  Widget _buildCupertinoAppBar(
    BuildContext context,
    Color resolvedBackgroundColor,
  ) {
    // Build trailing widget from actions with padding
    final trailing = actions != null && actions!.isNotEmpty
        ? (actions!.length == 1
              ? Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.md),
                  child: actions!.first,
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: actions!.asMap().entries.map((entry) {
                    final index = entry.key;
                    final action = entry.value;
                    return Padding(
                      padding: EdgeInsets.only(
                        left: index == 0 ? 0 : AppSpacing.sm,
                        right: index == actions!.length - 1 ? AppSpacing.md : 0,
                      ),
                      child: action,
                    );
                  }).toList(),
                ))
        : null;

    // Determine if we should show a border
    final showBorder =
        style != HydraAppBarStyle.transparent &&
        resolvedBackgroundColor != Colors.transparent;

    // Apply foreground color to title and icons if provided
    var middleWidget = title;
    final titleValue = title;
    if (foregroundColor != null && titleValue != null) {
      if (titleValue is Text) {
        final text = titleValue;
        middleWidget = Padding(
          padding: AppSpacing.appBarContentPadding,
          child: Text(
            text.data ?? '',
            style:
                text.style?.copyWith(color: foregroundColor) ??
                TextStyle(color: foregroundColor),
            textAlign: (centerTitle ?? false) ? TextAlign.center : null,
          ),
        );
      } else {
        middleWidget = Padding(
          padding: AppSpacing.appBarContentPadding,
          child: DefaultTextStyle(
            style: TextStyle(color: foregroundColor),
            child: titleValue,
          ),
        );
      }
    } else {
      if (titleValue != null) {
        if (titleValue is Text && (centerTitle ?? false)) {
          middleWidget = Padding(
            padding: AppSpacing.appBarContentPadding,
            child: Text(
              titleValue.data ?? '',
              style: titleValue.style,
              textAlign: TextAlign.center,
            ),
          );
        } else {
          middleWidget = Padding(
            padding: AppSpacing.appBarContentPadding,
            child: titleValue,
          );
        }
      }
    }

    return CupertinoNavigationBar(
      middle: middleWidget,
      leading: leading != null
          ? Padding(
              padding: const EdgeInsets.only(left: AppSpacing.md),
              child: leading,
            )
          : null,
      trailing: trailing,
      backgroundColor: resolvedBackgroundColor,
      border: showBorder
          ? const Border(
              bottom: BorderSide(
                color: AppColors.border,
              ),
            )
          : null,
    );
  }
}
