import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/core/constants/app_colors.dart';
import 'package:hydracat/core/constants/app_icons.dart';
import 'package:hydracat/core/theme/app_spacing.dart';
import 'package:hydracat/core/theme/app_text_styles.dart';
import 'package:hydracat/features/home/models/pending_fluid_treatment.dart';
import 'package:hydracat/features/home/models/pending_treatment.dart';
import 'package:hydracat/features/home/widgets/dashboard_success_popup.dart';
import 'package:hydracat/features/logging/services/overlay_service.dart';
import 'package:hydracat/providers/analytics_provider.dart';
import 'package:hydracat/providers/dashboard_provider.dart';
import 'package:hydracat/shared/widgets/buttons/hydra_button.dart';
import 'package:hydracat/shared/widgets/icons/hydra_icon.dart';

/// Full-screen blur popup for confirming or skipping treatments from dashboard.
///
/// Features:
/// - Two variants: Medication (with skip) and Fluid (confirm only)
/// - Slide-up animation with blur background
/// - Read-only summary of treatment details
/// - Analytics tracking for all actions
/// - Dismissible via close button or background tap
class TreatmentConfirmationPopup extends ConsumerWidget {
  /// Creates a [TreatmentConfirmationPopup].
  ///
  /// Exactly one of [medication] or [fluid] must be provided.
  const TreatmentConfirmationPopup({
    this.medication,
    this.fluid,
    super.key,
  }) : assert(
         (medication != null) ^ (fluid != null),
         'Exactly one of medication or fluid must be provided',
       );

  /// Pending medication treatment to display (null for fluid)
  final PendingTreatment? medication;

  /// Pending fluid treatment to display (null for medication)
  final PendingFluidTreatment? fluid;

  bool get _isMedication => medication != null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          // Track dismissal analytics
          ref
              .read(analyticsServiceDirectProvider)
              .trackLoggingPopupOpened(
                popupType:
                    'dashboard_'
                    '${_isMedication ? 'medication' : 'fluid'}_dismissed',
              );
        }
      },
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Material(
          type: MaterialType.transparency,
          child: Semantics(
            label: _isMedication
                ? 'Confirm medication: ${medication!.displayName}'
                : 'Confirm fluid therapy',
            child: Container(
              margin: EdgeInsets.only(
                left: AppSpacing.md,
                right: AppSpacing.md,
                bottom: mediaQuery.padding.bottom + AppSpacing.sm,
              ),
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, theme),
                  const SizedBox(height: AppSpacing.md),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.3,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildSummary(context, theme),
                  const SizedBox(height: AppSpacing.xl),
                  _buildActionButtons(context, ref),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build header section with icon, title, and close button
  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Row(
      children: [
        // Icon
        HydraIcon(
          icon: _isMedication ? AppIcons.medication : AppIcons.fluidTherapy,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          size: 28,
        ),
        const SizedBox(width: AppSpacing.sm),

        // Title
        Expanded(
          child: Text(
            _isMedication ? medication!.displayName : 'Fluid Therapy',
            style: AppTextStyles.h2.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),

        // Close button
        Semantics(
          label: 'Close',
          hint: 'Dismiss without logging',
          button: true,
          child: IconButton(
            icon: const Icon(Icons.close),
            onPressed: OverlayService.hide,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 44,
              minHeight: 44,
            ),
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  /// Build summary section with read-only treatment details
  Widget _buildSummary(BuildContext context, ThemeData theme) {
    if (_isMedication) {
      return _buildMedicationSummary(theme);
    } else {
      return _buildFluidSummary(theme);
    }
  }

  /// Build medication summary (name, strength, dosage, time)
  Widget _buildMedicationSummary(ThemeData theme) {
    final med = medication!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Dosage
        _buildSummaryRow(
          theme: theme,
          label: 'Dosage',
          value: med.displayDosage,
        ),

        // Strength (if available)
        if (med.displayStrength != null) ...[
          const SizedBox(height: AppSpacing.sm),
          _buildSummaryRow(
            theme: theme,
            label: 'Strength',
            value: med.displayStrength!,
          ),
        ],

        // Scheduled time
        const SizedBox(height: AppSpacing.sm),
        _buildSummaryRow(
          theme: theme,
          label: 'Scheduled',
          value: med.displayTime,
          isOverdue: med.isOverdue,
        ),
      ],
    );
  }

  /// Build fluid summary (remaining volume, scheduled times)
  Widget _buildFluidSummary(ThemeData theme) {
    final fluidTx = fluid!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Remaining volume
        _buildSummaryRow(
          theme: theme,
          label: 'Remaining Today',
          value: fluidTx.displayVolume,
        ),

        // Scheduled times
        const SizedBox(height: AppSpacing.sm),
        _buildSummaryRow(
          theme: theme,
          label: 'Scheduled Times',
          value: fluidTx.displayTimes,
          isOverdue: fluidTx.hasOverdueTimes,
        ),
      ],
    );
  }

  /// Build a single summary row
  Widget _buildSummaryRow({
    required ThemeData theme,
    required String label,
    required String value,
    bool isOverdue = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.body.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: AppTextStyles.body.copyWith(
            color: isOverdue ? AppColors.success : theme.colorScheme.onSurface,
            fontWeight: isOverdue ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// Build action buttons (skip + confirm for meds, confirm only for fluids)
  Widget _buildActionButtons(BuildContext context, WidgetRef ref) {
    if (_isMedication) {
      return Row(
        children: [
          // Skip button
          Expanded(
            child: HydraButton(
              onPressed: () => _handleSkip(context, ref),
              variant: HydraButtonVariant.secondary,
              child: const Text('Skip'),
            ),
          ),
          const SizedBox(width: AppSpacing.md),

          // Confirm button
          Expanded(
            child: HydraButton(
              onPressed: () => _handleConfirm(context, ref),
              child: const Text('Confirm'),
            ),
          ),
        ],
      );
    } else {
      // Fluid: Confirm only (full width)
      return HydraButton(
        onPressed: () => _handleConfirm(context, ref),
        isFullWidth: true,
        child: const Text('Confirm'),
      );
    }
  }

  /// Handle skip action (medications only)
  Future<void> _handleSkip(BuildContext context, WidgetRef ref) async {
    try {
      // Close confirmation popup first
      OverlayService.hide();

      // Perform skip action
      await ref
          .read(dashboardProvider.notifier)
          .skipMedicationTreatment(medication!);

      // Show success feedback
      if (context.mounted) {
        OverlayService.showFullScreenPopup(
          context: OverlayService.hostContext ?? context,
          child: const DashboardSuccessPopup(
            message: 'Treatment skipped',
            isSkipped: true,
          ),
          animationType: OverlayAnimationType.scaleIn,
        );
      }
    } on Exception catch (e) {
      debugPrint('Error skipping treatment: $e');
      // Error handling - could show error popup here
    }
  }

  /// Handle confirm action (both medications and fluids)
  Future<void> _handleConfirm(BuildContext context, WidgetRef ref) async {
    try {
      // Close confirmation popup first
      OverlayService.hide();

      // Perform confirm action
      if (_isMedication) {
        await ref
            .read(dashboardProvider.notifier)
            .confirmMedicationTreatment(medication!);
      } else {
        await ref
            .read(dashboardProvider.notifier)
            .confirmFluidTreatment(fluid!);
      }

      // Show success feedback
      if (context.mounted) {
        OverlayService.showFullScreenPopup(
          context: OverlayService.hostContext ?? context,
          child: const DashboardSuccessPopup(
            message: 'Treatment confirmed',
          ),
          animationType: OverlayAnimationType.scaleIn,
        );
      }
    } on Exception catch (e) {
      debugPrint('Error confirming treatment: $e');
      // Error handling - could show error popup here
    }
  }
}
