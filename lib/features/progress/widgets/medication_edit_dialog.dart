import 'package:flutter/material.dart';
import 'package:hydracat/core/constants/app_colors.dart';
import 'package:hydracat/core/theme/app_spacing.dart';
import 'package:hydracat/core/theme/app_text_styles.dart';
import 'package:hydracat/features/logging/models/medication_session.dart';
import 'package:hydracat/features/profile/models/schedule.dart';

/// Dialog for editing a medication session from calendar popup.
///
/// Features:
/// - Toggle completion status (completed/missed)
/// - Adjust dosage with +/- buttons (0 to 100 range)
/// - Edit notes (max 500 characters)
/// - Explicit Save/Cancel confirmation
///
/// Example:
/// ```dart
/// final result = await showDialog<MedicationSession>(
///   context: context,
///   builder: (context) => MedicationEditDialog(
///     session: existingSession,
///     schedule: schedule,
///   ),
/// );
/// ```
class MedicationEditDialog extends StatefulWidget {
  /// Creates a [MedicationEditDialog]
  const MedicationEditDialog({
    required this.session,
    required this.schedule,
    super.key,
  });

  /// The medication session to edit
  final MedicationSession session;

  /// The schedule this session is associated with
  final Schedule schedule;

  @override
  State<MedicationEditDialog> createState() => _MedicationEditDialogState();
}

class _MedicationEditDialogState extends State<MedicationEditDialog> {
  late bool _completed;
  late double _dosageGiven;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _completed = widget.session.completed;
    _dosageGiven = widget.session.dosageGiven;
    _notesController = TextEditingController(text: widget.session.notes ?? '');
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  /// Check if any changes were made
  bool get _hasChanges =>
      _completed != widget.session.completed ||
      _dosageGiven != widget.session.dosageGiven ||
      _notesController.text != (widget.session.notes ?? '');

  /// Increment dosage
  void _incrementDosage() {
    setState(() {
      if (_dosageGiven < 100) {
        _dosageGiven += 0.5;
      }
    });
  }

  /// Decrement dosage
  void _decrementDosage() {
    setState(() {
      if (_dosageGiven > 0) {
        _dosageGiven = (_dosageGiven - 0.5).clamp(0, 100);
      }
    });
  }

  /// Handle save
  void _handleSave() {
    if (!_hasChanges) {
      Navigator.of(context).pop();
      return;
    }

    // Create updated session
    final updatedSession = widget.session.copyWith(
      completed: _completed,
      dosageGiven: _dosageGiven,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      updatedAt: DateTime.now(),
    );

    Navigator.of(context).pop(updatedSession);
  }

  /// Handle cancel
  void _handleCancel() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 400,
          maxHeight: mediaQuery.size.height * 0.7,
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            _buildHeader(theme),
            const SizedBox(height: AppSpacing.lg),

            // Scrollable content
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Completion status toggle
                    _buildCompletionToggle(theme),
                    const SizedBox(height: AppSpacing.lg),

                    // Dosage adjuster
                    _buildDosageAdjuster(theme),
                    const SizedBox(height: AppSpacing.lg),

                    // Notes field
                    _buildNotesField(theme),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Action buttons
            _buildActionButtons(theme),
          ],
        ),
      ),
    );
  }

  /// Build header with medication name
  Widget _buildHeader(ThemeData theme) {
    final medicationName = widget.schedule.medicationName ?? 'Medication';
    final strengthAmount = widget.schedule.medicationStrengthAmount;
    final strengthUnit = widget.schedule.medicationStrengthUnit ?? '';
    final strengthText =
        strengthAmount != null ? ' $strengthAmount$strengthUnit' : '';

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'Edit Medication',
                style: AppTextStyles.h2.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$medicationName$strengthText',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: _handleCancel,
          tooltip: 'Cancel',
        ),
      ],
    );
  }

  /// Build completion status toggle
  Widget _buildCompletionToggle(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status',
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _buildStatusButton(
                label: 'Completed',
                icon: Icons.check_circle,
                isSelected: _completed,
                onTap: () => setState(() => _completed = true),
                theme: theme,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _buildStatusButton(
                label: 'Missed',
                icon: Icons.cancel,
                isSelected: !_completed,
                onTap: () => setState(() => _completed = false),
                theme: theme,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build individual status button
  Widget _buildStatusButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryLight.withValues(alpha: 0.2)
              : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                label,
                style: AppTextStyles.body.copyWith(
                  color:
                      isSelected ? AppColors.primary : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build dosage adjuster with +/- buttons
  Widget _buildDosageAdjuster(ThemeData theme) {
    final unit = widget.schedule.medicationUnit ?? 'dose';
    final displayDosage = _dosageGiven == _dosageGiven.toInt()
        ? _dosageGiven.toInt().toString()
        : _dosageGiven.toStringAsFixed(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dosage',
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Decrement button
              _buildCircularButton(
                icon: Icons.remove,
                onPressed: _decrementDosage,
                enabled: _dosageGiven > 0,
              ),
              const SizedBox(width: AppSpacing.lg),

              // Display
              Column(
                children: [
                  Text(
                    displayDosage,
                    style: AppTextStyles.display.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontSize: 40,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    unit,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),

              const SizedBox(width: AppSpacing.lg),

              // Increment button
              _buildCircularButton(
                icon: Icons.add,
                onPressed: _incrementDosage,
                enabled: _dosageGiven < 100,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build circular +/- button
  Widget _buildCircularButton({
    required IconData icon,
    required VoidCallback onPressed,
    required bool enabled,
  }) {
    return Material(
      color: enabled
          ? AppColors.primaryLight.withValues(alpha: 0.3)
          : AppColors.disabled,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: enabled ? onPressed : null,
        customBorder: const CircleBorder(),
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          child: Icon(
            icon,
            color: enabled ? AppColors.primaryDark : AppColors.textTertiary,
            size: 24,
          ),
        ),
      ),
    );
  }

  /// Build notes text field
  Widget _buildNotesField(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notes (optional)',
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _notesController,
          maxLength: 500,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Add any notes about this dose...',
            hintStyle: AppTextStyles.body.copyWith(
              color: AppColors.textTertiary,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.all(AppSpacing.md),
            counterStyle: AppTextStyles.small.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          style: AppTextStyles.body,
        ),
      ],
    );
  }

  /// Build action buttons (Cancel/Save)
  Widget _buildActionButtons(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Save button
        ElevatedButton(
          onPressed: _handleSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            'Save',
            style: AppTextStyles.buttonPrimary.copyWith(
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Cancel button
        OutlinedButton(
          onPressed: _handleCancel,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            side: const BorderSide(color: AppColors.border),
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            'Cancel',
            style: AppTextStyles.buttonSecondary.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
