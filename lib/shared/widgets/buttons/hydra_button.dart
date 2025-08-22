import 'package:flutter/material.dart';
import 'package:hydracat/core/theme/theme.dart';

/// Base button component for HydraCat with water theme styling.
/// Implements the button design specifications from the UI guidelines.
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
  });

  /// Callback function when button is pressed
  final VoidCallback? onPressed;

  /// Button content
  final Widget child;

  /// Button variant (primary, secondary, text)
  final HydraButtonVariant variant;

  /// Button size (small, medium, large)
  final HydraButtonSize size;

  /// Whether to show loading state
  final bool isLoading;

  /// Whether button should take full width
  final bool isFullWidth;

  @override
  Widget build(BuildContext context) {
    final buttonStyle = _getButtonStyle();
    final buttonSize = _getButtonSize();

    var button = _buildButton(buttonStyle, buttonSize);

    if (isFullWidth) {
      button = SizedBox(
        width: double.infinity,
        child: button,
      );
    }

    return button;
  }

  Widget _buildButton(ButtonStyle buttonStyle, Size buttonSize) {
    switch (variant) {
      case HydraButtonVariant.primary:
        return ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: buttonStyle,
          child: _buildButtonContent(buttonSize),
        );
      case HydraButtonVariant.secondary:
        return OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: buttonStyle,
          child: _buildButtonContent(buttonSize),
        );
      case HydraButtonVariant.text:
        return TextButton(
          onPressed: isLoading ? null : onPressed,
          style: buttonStyle,
          child: _buildButtonContent(buttonSize),
        );
    }
  }

  Widget _buildButtonContent(Size buttonSize) {
    if (isLoading) {
      return SizedBox(
        width: buttonSize.height * 0.6,
        height: buttonSize.height * 0.6,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            variant == HydraButtonVariant.primary
                ? AppColors.onPrimary
                : AppColors.primary,
          ),
        ),
      );
    }

    return child;
  }

  ButtonStyle _getButtonStyle() {
    final baseStyle = variant == HydraButtonVariant.primary
        ? ElevatedButton.styleFrom()
        : variant == HydraButtonVariant.secondary
        ? OutlinedButton.styleFrom()
        : TextButton.styleFrom();

    return baseStyle.copyWith(
      minimumSize: WidgetStateProperty.all(_getButtonSize()),
      padding: WidgetStateProperty.all(_getButtonPadding()),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Size _getButtonSize() {
    switch (size) {
      case HydraButtonSize.small:
        return const Size(AppSpacing.minTouchTarget, AppSpacing.minTouchTarget);
      case HydraButtonSize.medium:
        return const Size(AppSpacing.minTouchTarget, AppSpacing.minTouchTarget);
      case HydraButtonSize.large:
        return const Size(
          AppSpacing.minTouchTarget,
          AppSpacing.minTouchTarget + 8,
        );
    }
  }

  EdgeInsets _getButtonPadding() {
    switch (size) {
      case HydraButtonSize.small:
        return const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        );
      case HydraButtonSize.medium:
        return const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        );
      case HydraButtonSize.large:
        return const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        );
    }
  }
}

/// Button variants for different use cases
enum HydraButtonVariant {
  /// Primary button with teal background
  primary,

  /// Secondary button with teal outline
  secondary,

  /// Text button with teal text
  text,
}

/// Button sizes for different contexts
enum HydraButtonSize {
  /// Small button for compact layouts
  small,

  /// Medium button for standard use
  medium,

  /// Large button for prominent actions
  large,
}
