import 'package:flutter/material.dart';
import 'package:hydracat/core/theme/theme.dart';
import 'package:hydracat/shared/widgets/accessibility/hydra_touch_target.dart';

/// A reusable button component with accessibility support.
class HydraButton extends StatelessWidget {
  /// Creates a HydraButton.
  const HydraButton({
    required this.onPressed,
    required this.child,
    super.key,
    this.variant = HydraButtonVariant.primary,
    this.size = HydraButtonSize.medium,
    this.isLoading = false,
    this.isFullWidth = false,
    this.semanticLabel,
  });

  /// Callback function when button is pressed.
  final VoidCallback? onPressed;

  /// The child widget to display in the button.
  final Widget child;

  /// The visual variant of the button.
  final HydraButtonVariant variant;

  /// The size of the button.
  final HydraButtonSize size;

  /// Whether to show loading state.
  final bool isLoading;

  /// Whether the button should take full width.
  final bool isFullWidth;

  /// Semantic label for accessibility.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final button = _buildButton(context);

    return HydraTouchTarget(
      child: button,
    );
  }

  Widget _buildButton(BuildContext context) {
    final buttonStyle = _getButtonStyle(context);
    final buttonSize = _getButtonSize();

    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: buttonStyle,
        child: SizedBox(
          height: buttonSize.height,
          child: _buildButtonContent(),
        ),
      ),
    );
  }

  Widget _buildButtonContent() {
    if (isLoading) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    return child;
  }

  ButtonStyle _getButtonStyle(BuildContext context) {
    switch (variant) {
      case HydraButtonVariant.primary:
        return ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: AppColors.primary.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        );
      case HydraButtonVariant.secondary:
        return ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.primary,
          elevation: 0,
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        );
      case HydraButtonVariant.text:
        return ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.primary,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        );
    }
  }

  Size _getButtonSize() {
    switch (size) {
      case HydraButtonSize.small:
        return const Size(80, 32);
      case HydraButtonSize.medium:
        return const Size(120, 44);
      case HydraButtonSize.large:
        return const Size(160, 48);
    }
  }
}

/// Button variants for different use cases.
enum HydraButtonVariant {
  /// Primary action button.
  primary,

  /// Secondary action button.
  secondary,

  /// Text-only button.
  text,
}

/// Button sizes for different contexts.
enum HydraButtonSize {
  /// Small button for compact layouts.
  small,

  /// Medium button for standard layouts.
  medium,

  /// Large button for prominent actions.
  large,
}
