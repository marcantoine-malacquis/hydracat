import 'package:flutter/material.dart';
import 'package:hydracat/core/theme/theme.dart';

/// Card component for HydraCat with water theme styling.
/// Implements the card design specifications from the UI guidelines.
class HydraCard extends StatelessWidget {
  /// Creates a HydraCard.
  const HydraCard({
    required this.child,
    super.key,
    this.padding,
    this.margin,
    this.elevation,
    this.borderRadius,
    this.borderColor,
    this.backgroundColor,
    this.onTap,
  });

  /// Card content
  final Widget child;

  /// Internal padding
  final EdgeInsetsGeometry? padding;

  /// External margin
  final EdgeInsetsGeometry? margin;

  /// Card elevation (0 for flat design)
  final double? elevation;

  /// Border radius (12px default)
  final double? borderRadius;

  /// Border color
  final Color? borderColor;

  /// Background color
  final Color? backgroundColor;

  /// Tap callback for interactive cards
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Card(
      elevation: elevation ?? 0,
      color: backgroundColor ?? AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius ?? 12),
        side: BorderSide(
          color: borderColor ?? AppColors.border,
        ),
      ),
      margin: margin ?? const EdgeInsets.all(AppSpacing.sm),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(AppSpacing.md),
        child: child,
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius ?? 12),
        child: card,
      );
    }

    return card;
  }
}

/// Section card for grouping related content
class HydraSectionCard extends StatelessWidget {
  /// Creates a HydraSectionCard.
  const HydraSectionCard({
    required this.title,
    required this.child,
    super.key,
    this.subtitle,
    this.actions,
    this.isExpanded = false,
  });

  /// Section title
  final String title;

  /// Section subtitle (optional)
  final String? subtitle;

  /// Section content
  final Widget child;

  /// Action buttons in the header
  final List<Widget>? actions;

  /// Whether the card should expand to fill available space
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    return HydraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: isExpanded ? MainAxisSize.max : MainAxisSize.min,
        children: [
          _buildHeader(),
          const SizedBox(height: AppSpacing.md),
          if (isExpanded)
            Expanded(
              child: child,
            )
          else
            child,
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.h3,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle!,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (actions != null) ...[
          const SizedBox(width: AppSpacing.sm),
          ...actions!,
        ],
      ],
    );
  }
}

/// Info card for displaying important information
class HydraInfoCard extends StatelessWidget {
  /// Creates a HydraInfoCard.
  const HydraInfoCard({
    required this.message,
    super.key,
    this.type = HydraInfoType.info,
    this.icon,
    this.actions,
  });

  /// Information message
  final String message;

  /// Type of information (affects styling)
  final HydraInfoType type;

  /// Custom icon (optional)
  final IconData? icon;

  /// Action buttons
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return HydraCard(
      backgroundColor: _getBackgroundColor(),
      borderColor: _getBorderColor(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon ?? _getDefaultIcon(),
                color: _getIconColor(),
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  message,
                  style: AppTextStyles.body.copyWith(
                    color: _getTextColor(),
                  ),
                ),
              ),
            ],
          ),
          if (actions != null) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: actions!,
            ),
          ],
        ],
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (type) {
      case HydraInfoType.info:
        return AppColors.primaryLight.withValues(alpha: 0.1);
      case HydraInfoType.success:
        return AppColors.successLight.withValues(alpha: 0.1);
      case HydraInfoType.warning:
        return AppColors.warningLight.withValues(alpha: 0.1);
      case HydraInfoType.error:
        return AppColors.errorLight.withValues(alpha: 0.1);
    }
  }

  Color _getBorderColor() {
    switch (type) {
      case HydraInfoType.info:
        return AppColors.primaryLight;
      case HydraInfoType.success:
        return AppColors.successLight;
      case HydraInfoType.warning:
        return AppColors.warningLight;
      case HydraInfoType.error:
        return AppColors.errorLight;
    }
  }

  Color _getIconColor() {
    switch (type) {
      case HydraInfoType.info:
        return AppColors.primary;
      case HydraInfoType.success:
        return AppColors.success;
      case HydraInfoType.warning:
        return AppColors.warning;
      case HydraInfoType.error:
        return AppColors.error;
    }
  }

  Color _getTextColor() {
    switch (type) {
      case HydraInfoType.info:
        return AppColors.textPrimary;
      case HydraInfoType.success:
        return AppColors.textPrimary;
      case HydraInfoType.warning:
        return AppColors.textPrimary;
      case HydraInfoType.error:
        return AppColors.textPrimary;
    }
  }

  IconData _getDefaultIcon() {
    switch (type) {
      case HydraInfoType.info:
        return Icons.info_outline;
      case HydraInfoType.success:
        return Icons.check_circle_outline;
      case HydraInfoType.warning:
        return Icons.warning_amber_outlined;
      case HydraInfoType.error:
        return Icons.error_outline;
    }
  }
}

/// Types of information cards
enum HydraInfoType {
  /// General information
  info,

  /// Success message
  success,

  /// Warning message
  warning,

  /// Error message
  error,
}
