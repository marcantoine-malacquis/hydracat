import 'package:flutter/material.dart';
import 'package:hydracat/core/constants/app_colors.dart';
import 'package:hydracat/shared/widgets/accessibility/touch_target_icon_button.dart';
import 'package:hydracat/shared/widgets/widgets.dart';

/// A reusable wrapper for treatment setup popups
class TreatmentPopupWrapper extends StatelessWidget {
  /// Creates a [TreatmentPopupWrapper]
  const TreatmentPopupWrapper({
    required this.title,
    required this.child,
    this.onPrevious,
    this.onNext,
    this.onSave,
    this.onCancel,
    this.nextButtonText = 'Next',
    this.saveButtonText = 'Save',
    this.showPreviousButton = true,
    this.isNextEnabled = true,
    this.isLoading = false,
    super.key,
  });

  /// Title of the popup
  final String title;

  /// Main content widget
  final Widget child;

  /// Callback for previous button
  final VoidCallback? onPrevious;

  /// Callback for next button
  final VoidCallback? onNext;

  /// Callback for save button (alternative to next)
  final VoidCallback? onSave;

  /// Callback for cancel/close button
  final VoidCallback? onCancel;

  /// Text for next button
  final String nextButtonText;

  /// Text for save button
  final String saveButtonText;

  /// Whether to show previous button
  final bool showPreviousButton;

  /// Whether next/save button is enabled
  final bool isNextEnabled;

  /// Whether to show loading state
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);

    return HydraDialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: mediaQuery.size.height * 0.8,
          maxWidth: 400,
        ),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(context, theme),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: child,
              ),
            ),

            // Footer with action buttons
            _buildFooter(context, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),

          TouchTargetIconButton(
            onPressed: onCancel,
            icon: Icon(
              Icons.close,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            tooltip: 'Close',
            semanticLabel: 'Close popup',
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          // Previous button
          if (showPreviousButton && onPrevious != null)
            Expanded(
              child: OutlinedButton(
                onPressed: isLoading ? null : onPrevious,
                child: const Text('Previous'),
              ),
            ),

          if (showPreviousButton &&
              onPrevious != null &&
              (onNext != null || onSave != null))
            const SizedBox(width: 12),

          // Next or Save button
          if (onNext != null || onSave != null)
            Expanded(
              child: ElevatedButton(
                onPressed: isLoading || !isNextEnabled
                    ? null
                    : (onSave ?? onNext),
                child: isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: HydraProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.onPrimary,
                        ),
                      )
                    : Text(onSave != null ? 'Save' : nextButtonText),
              ),
            ),
        ],
      ),
    );
  }
}

/// A specialized popup for medication input steps
class MedicationStepPopup extends StatelessWidget {
  /// Creates a [MedicationStepPopup]
  const MedicationStepPopup({
    required this.title,
    required this.child,
    required this.currentStep,
    required this.totalSteps,
    this.onPrevious,
    this.onNext,
    this.onSave,
    this.onCancel,
    this.isNextEnabled = true,
    this.isLoading = false,
    super.key,
  });

  /// Title of the popup
  final String title;

  /// Main content widget
  final Widget child;

  /// Current step number (1-based)
  final int currentStep;

  /// Total number of steps
  final int totalSteps;

  /// Callback for previous button
  final VoidCallback? onPrevious;

  /// Callback for next button
  final VoidCallback? onNext;

  /// Callback for save button (final step)
  final VoidCallback? onSave;

  /// Callback for cancel/close button
  final VoidCallback? onCancel;

  /// Whether next/save button is enabled
  final bool isNextEnabled;

  /// Whether to show loading state
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final isLastStep = currentStep == totalSteps;

    return TreatmentPopupWrapper(
      title: title,
      showPreviousButton: currentStep > 1,
      onPrevious: onPrevious,
      onNext: isLastStep ? null : onNext,
      onSave: isLastStep ? onSave : null,
      onCancel: onCancel,
      nextButtonText: isLastStep ? 'Save' : 'Next',
      saveButtonText: 'Save Medication',
      isNextEnabled: isNextEnabled,
      isLoading: isLoading,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Add slight top spacing so the step indicator sits lower
          //under the header
          const SizedBox(height: 12),
          // Step indicator
          _buildStepIndicator(context),
          const SizedBox(height: 24),

          // Content
          child,
        ],
      ),
    );
  }

  Widget _buildStepIndicator(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        // Step indicators with flexible spacing
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(totalSteps, (index) {
              final stepNumber = index + 1;
              final isActive = stepNumber == currentStep;
              final isCompleted = stepNumber < currentStep;

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: isActive || isCompleted
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: isCompleted
                          ? Icon(
                              Icons.check,
                              size: 14,
                              color: theme.colorScheme.onPrimary,
                            )
                          : Text(
                              stepNumber.toString(),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: isActive
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.onSurface.withValues(
                                        alpha: 0.6,
                                      ),
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                    ),
                  ),
                  if (index < totalSteps - 1) ...[
                    Container(
                      width: 16,
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      color: isCompleted
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ],
                ],
              );
            }),
          ),
        ),

        // Step text
        Text(
          'Step $currentStep of $totalSteps',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

/// A confirmation dialog for treatment actions
class TreatmentConfirmationDialog extends StatelessWidget {
  /// Creates a [TreatmentConfirmationDialog]
  const TreatmentConfirmationDialog({
    required this.title,
    required this.content,
    this.confirmText = 'Confirm',
    this.cancelText = 'Cancel',
    this.onConfirm,
    this.onCancel,
    this.isDestructive = false,
    super.key,
  });

  /// Title of the dialog
  final String title;

  /// Content text or widget
  final Widget content;

  /// Text for confirm button
  final String confirmText;

  /// Text for cancel button
  final String cancelText;

  /// Callback for confirm action
  final VoidCallback? onConfirm;

  /// Callback for cancel action
  final VoidCallback? onCancel;

  /// Whether this is a destructive action
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return HydraAlertDialog(
      title: Text(title),
      content: content,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      actions: [
        TextButton(
          onPressed: onCancel ?? () => Navigator.of(context).pop(false),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.error,
          ),
          child: Text(cancelText),
        ),
        ElevatedButton(
          onPressed: onConfirm ?? () => Navigator.of(context).pop(true),
          style: isDestructive
              ? ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: theme.colorScheme.onError,
                )
              : null,
          child: Text(confirmText),
        ),
      ],
    );
  }

  /// Shows the confirmation dialog
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required Widget content,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => TreatmentConfirmationDialog(
        title: title,
        content: content,
        confirmText: confirmText,
        cancelText: cancelText,
        isDestructive: isDestructive,
      ),
    );
  }
}
