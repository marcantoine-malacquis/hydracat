import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hydracat/core/constants/app_colors.dart';

/// Platform-adaptive back button for HydraCat.
///
/// Wraps [IconButton] on Material platforms
/// and [CupertinoNavigationBarBackButton]
/// on iOS/macOS, while providing consistent styling and behavior.
///
/// **Platform Behavior:**
/// - **Material**: Uses [IconButton] with iOS-style
///  chevron icon (Icons.arrow_back_ios),
///   20px icon size, textSecondary color (#636E72), and tooltip support.
/// - **Cupertino**: Uses [CupertinoNavigationBarBackButton] with
///  native iOS styling
///   and behavior. Tooltips are not supported on Cupertino
///  (tooltip parameter is ignored).
///
/// Example usage:
/// ```dart
/// AppBar(
///   leading: HydraBackButton(
///     onPressed: () => context.pop(),
///   ),
///   automaticallyImplyLeading: false,
/// )
/// ```
class HydraBackButton extends StatelessWidget {
  /// Creates a platform-adaptive back button.
  const HydraBackButton({
    required this.onPressed,
    this.tooltip = 'Back',
    this.semanticLabel,
    super.key,
  });

  /// Callback when the back button is pressed.
  /// Set to null to disable the button.
  final VoidCallback? onPressed;

  /// Tooltip text shown on long press.
  /// Defaults to 'Back'.
  /// Note: Tooltips are only supported on Material platforms.
  final String tooltip;

  /// Optional semantic label for screen readers.
  /// Falls back to [tooltip] if not provided.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;

    if (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS) {
      return _buildCupertinoButton(context);
    }

    return _buildMaterialButton(context);
  }

  Widget _buildMaterialButton(BuildContext context) {
    final button = IconButton(
      onPressed: onPressed,
      icon: const Icon(Icons.arrow_back_ios),
      iconSize: 20,
      color: AppColors.textSecondary,
      tooltip: tooltip,
    );

    // Wrap with Semantics if custom label provided
    if (semanticLabel != null) {
      return Semantics(
        label: semanticLabel,
        button: true,
        child: button,
      );
    }

    return button;
  }

  Widget _buildCupertinoButton(BuildContext context) {
    // CupertinoNavigationBarBackButton doesn't support tooltips
    // or custom colors directly.
    // It uses CupertinoTheme for styling. We override the theme
    // to match our color.
    final button = CupertinoTheme(
      data: CupertinoTheme.of(context).copyWith(
        primaryColor: AppColors.textSecondary,
      ),
      child: CupertinoNavigationBarBackButton(
        onPressed: onPressed,
        // previousPageTitle can be null - it will just show the back arrow
      ),
    );

    // Wrap with Semantics if custom label provided
    if (semanticLabel != null) {
      return Semantics(
        label: semanticLabel,
        button: true,
        child: button,
      );
    }

    return button;
  }
}
