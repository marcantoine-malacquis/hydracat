import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hydracat/core/constants/app_colors.dart';
import 'package:hydracat/core/theme/app_spacing.dart';
import 'package:hydracat/core/theme/app_text_styles.dart';
import 'package:hydracat/core/validation/models/validation_result.dart';

/// Consistent error display component for validation errors
///
/// Provides a unified way to display validation errors across all onboarding
/// screens with actionable buttons and clear visual hierarchy.
class ValidationErrorDisplay extends StatelessWidget {
  /// Creates a [ValidationErrorDisplay] widget
  const ValidationErrorDisplay({
    required this.validationResult,
    super.key,
    this.title = 'Setup could not be completed',
    this.showTitle = true,
    this.compact = false,
    this.onActionPressed,
  });

  /// Validation result containing errors to display
  final ValidationResult validationResult;

  /// Title text for the error display
  final String title;

  /// Whether to show the title
  final bool showTitle;

  /// Whether to use compact layout (for smaller spaces)
  final bool compact;

  /// Callback when an action button is pressed
  final void Function(String actionRoute)? onActionPressed;

  @override
  Widget build(BuildContext context) {
    if (validationResult.isValid || validationResult.errors.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(compact ? AppSpacing.md : AppSpacing.lg),
      margin: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.sm : AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(compact ? 8 : 12),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showTitle) ...[
            _buildTitle(),
            SizedBox(height: compact ? AppSpacing.sm : AppSpacing.md),
          ],

          _buildErrorList(),

          SizedBox(height: compact ? AppSpacing.sm : AppSpacing.md),

          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Row(
      children: [
        Icon(
          Icons.error_outline,
          color: AppColors.error,
          size: compact ? 16 : 20,
        ),
        SizedBox(width: compact ? AppSpacing.xs : AppSpacing.sm),
        Expanded(
          child: Text(
            title,
            style: (compact ? AppTextStyles.body : AppTextStyles.h3).copyWith(
              color: AppColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: validationResult.errors.map((error) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: compact ? AppSpacing.xs : AppSpacing.sm,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '• ',
                style: TextStyle(
                  color: AppColors.error,
                  fontSize: compact ? 14 : 16,
                ),
              ),
              Expanded(
                child: Text(
                  error.message,
                  style: (compact ? AppTextStyles.caption : AppTextStyles.body)
                      .copyWith(color: AppColors.error),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final actionableErrors = validationResult.getActionableErrors();

    if (actionableErrors.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'You can fix this by:',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),

        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: actionableErrors.map((error) {
            return _buildActionButton(context, error);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, ValidationError error) {
    return ElevatedButton.icon(
      onPressed: () => _handleActionPressed(context, error),
      icon: Icon(
        Icons.arrow_forward,
        size: compact ? 14 : 16,
      ),
      label: Text(
        error.suggestedAction!,
        style: TextStyle(
          fontSize: compact ? 12 : 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.error,
        foregroundColor: AppColors.surface,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 12,
          vertical: compact ? 6 : 8,
        ),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  void _handleActionPressed(BuildContext context, ValidationError error) {
    if (onActionPressed != null && error.actionRoute != null) {
      onActionPressed!(error.actionRoute!);
    } else if (error.actionRoute != null && context.mounted) {
      context.go(error.actionRoute!);
    }
  }
}

/// Compact version of ValidationErrorDisplay for inline use
class CompactValidationErrorDisplay extends StatelessWidget {
  /// Creates a [CompactValidationErrorDisplay] widget
  const CompactValidationErrorDisplay({
    required this.validationResult,
    super.key,
    this.onActionPressed,
  });

  /// Validation result containing errors to display
  final ValidationResult validationResult;

  /// Callback when an action button is pressed
  final void Function(String actionRoute)? onActionPressed;

  @override
  Widget build(BuildContext context) {
    return ValidationErrorDisplay(
      validationResult: validationResult,
      showTitle: false,
      compact: true,
      onActionPressed: onActionPressed,
    );
  }
}

/// Dialog version of ValidationErrorDisplay for modal presentation
class ValidationErrorDialog extends StatelessWidget {
  /// Creates a [ValidationErrorDialog] widget
  const ValidationErrorDialog({
    required this.validationResult,
    super.key,
    this.title = 'Missing Information',
    this.onDismiss,
    this.onActionPressed,
  });

  /// Validation result containing errors to display
  final ValidationResult validationResult;

  /// Title for the dialog
  final String title;

  /// Callback when dialog is dismissed
  final VoidCallback? onDismiss;

  /// Callback when an action button is pressed
  final void Function(String actionRoute)? onActionPressed;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: ValidationErrorDisplay(
          validationResult: validationResult,
          showTitle: false,
          compact: true,
          onActionPressed: onActionPressed,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            if (onDismiss != null) {
              onDismiss!();
            } else {
              Navigator.of(context).pop();
            }
          },
          child: const Text('OK'),
        ),
        if (validationResult.getActionableErrors().isNotEmpty)
          ElevatedButton(
            onPressed: () {
              final firstAction = validationResult.getActionableErrors().first;
              if (onActionPressed != null && firstAction.actionRoute != null) {
                onActionPressed!(firstAction.actionRoute!);
              }
            },
            child: const Text('Fix Now'),
          ),
      ],
    );
  }

  /// Shows the validation error dialog
  static Future<void> show(
    BuildContext context, {
    required ValidationResult validationResult,
    String title = 'Missing Information',
    VoidCallback? onDismiss,
    void Function(String actionRoute)? onActionPressed,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => ValidationErrorDialog(
        validationResult: validationResult,
        title: title,
        onDismiss: onDismiss,
        onActionPressed: onActionPressed,
      ),
    );
  }
}
