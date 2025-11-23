import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hydracat/core/theme/theme.dart';
import 'package:hydracat/shared/widgets/widgets.dart';

/// Platform-adaptive button component with accessibility support.
///
/// Wraps Material buttons (ElevatedButton) on Android/other platforms and
/// CupertinoButton on iOS/macOS, while mirroring the core Material button API.
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
    final platform = Theme.of(context).platform;
    final isCupertino =
        platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;
    final button = isCupertino
        ? _buildCupertinoButton(context)
        : _buildMaterialButton(context);

    return HydraTouchTarget(
      child: button,
    );
  }

  Widget _buildMaterialButton(BuildContext context) {
    final buttonStyle = _getButtonStyle(context);
    final minHeight = _getMinHeight();

    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: minHeight,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: buttonStyle,
        child: Container(
          height: minHeight,
          alignment: Alignment.center,
          child: _buildButtonContent(context, isCupertino: false),
        ),
      ),
    );
  }

  Widget _buildCupertinoButton(BuildContext context) {
    final minHeight = _getMinHeight();
    final buttonPadding = _getButtonPadding();
    final isDisabled = isLoading || onPressed == null;

    Widget button;
    switch (variant) {
      case HydraButtonVariant.primary:
        button = CupertinoButton.filled(
          onPressed: isLoading ? null : onPressed,
          padding: buttonPadding,
          minimumSize: Size(0, minHeight),
          borderRadius: BorderRadius.circular(8),
          color: AppColors.primary,
          disabledColor: AppColors.disabled,
          child: DefaultTextStyle(
            style: const TextStyle(
              color: AppColors.onPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            child: _buildButtonContent(context, isCupertino: true),
          ),
        );
      case HydraButtonVariant.secondary:
        button = Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: isDisabled ? AppColors.disabled : AppColors.primary,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: CupertinoButton(
            onPressed: isLoading ? null : onPressed,
            padding: buttonPadding,
            minimumSize: Size(0, minHeight),
            borderRadius: BorderRadius.circular(8),
            color: Colors.transparent,
            disabledColor: Colors.transparent,
            child: DefaultTextStyle(
              style: TextStyle(
                color: isDisabled ? AppColors.disabled : AppColors.primary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              child: _buildButtonContent(context, isCupertino: true),
            ),
          ),
        );
      case HydraButtonVariant.text:
        button = CupertinoButton(
          onPressed: isLoading ? null : onPressed,
          padding: buttonPadding,
          minimumSize: Size(0, minHeight),
          borderRadius: BorderRadius.circular(8),
          color: Colors.transparent,
          disabledColor: Colors.transparent,
          child: DefaultTextStyle(
            style: TextStyle(
              color: isDisabled ? AppColors.disabled : AppColors.primary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            child: _buildButtonContent(context, isCupertino: true),
          ),
        );
    }

    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: minHeight,
      child: button,
    );
  }

  Widget _buildButtonContent(
    BuildContext context, {
    required bool isCupertino,
  }) {
    if (isLoading) {
      // Determine loading indicator color based on variant and platform
      Color loadingColor;
      if (isCupertino) {
        // For Cupertino, use appropriate color based on variant
        switch (variant) {
          case HydraButtonVariant.primary:
            loadingColor = AppColors.onPrimary;
          case HydraButtonVariant.secondary:
          case HydraButtonVariant.text:
            loadingColor = AppColors.primary;
        }
      } else {
        // For Material, use white for primary, primary color for others
        switch (variant) {
          case HydraButtonVariant.primary:
            loadingColor = Colors.white;
          case HydraButtonVariant.secondary:
          case HydraButtonVariant.text:
            loadingColor = AppColors.primary;
        }
      }

      return SizedBox(
        width: 20,
        height: 20,
        child: HydraProgressIndicator(
          strokeWidth: 2,
          color: loadingColor,
        ),
      );
    }

    return child;
  }

  ButtonStyle _getButtonStyle(BuildContext context) {
    final buttonPadding = _getButtonPadding();
    final minHeight = _getMinHeight();

    switch (variant) {
      case HydraButtonVariant.primary:
        return ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: AppColors.primary.withValues(alpha: 0.3),
          padding: buttonPadding,
          minimumSize: Size(0, minHeight),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
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
          padding: buttonPadding,
          minimumSize: Size(0, minHeight),
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
          padding: buttonPadding,
          minimumSize: Size(0, minHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        );
    }
  }

  EdgeInsets _getButtonPadding() {
    switch (size) {
      case HydraButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
      case HydraButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
      case HydraButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 20);
    }
  }

  double _getMinHeight() {
    switch (size) {
      case HydraButtonSize.small:
        return 32;
      case HydraButtonSize.medium:
        return 44;
      case HydraButtonSize.large:
        return 54;
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
