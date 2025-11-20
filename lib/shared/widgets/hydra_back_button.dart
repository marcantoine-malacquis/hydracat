import 'package:flutter/material.dart';
import 'package:hydracat/core/constants/app_colors.dart';

/// Standard back button used throughout the Hydracat app.
///
/// Provides consistent styling and behavior for all back navigation buttons:
/// - iOS-style chevron icon (Icons.arrow_back_ios)
/// - 20px icon size
/// - textSecondary color (#636E72)
/// - Accessibility tooltip
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
  /// Creates a standard back button with consistent styling.
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
  final String tooltip;

  /// Optional semantic label for screen readers.
  /// Falls back to [tooltip] if not provided.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
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
}
