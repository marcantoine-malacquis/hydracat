import 'package:flutter/material.dart';
import 'package:hydracat/core/constants/app_colors.dart';
import 'package:hydracat/core/theme/app_spacing.dart';
import 'package:hydracat/core/theme/app_text_styles.dart';
import 'package:hydracat/features/logging/models/fluid_session.dart';
import 'package:hydracat/features/onboarding/models/treatment_data.dart';

/// Dialog for editing a fluid session from calendar popup.
///
/// Features:
/// - Adjust volume with +/- buttons (0-500ml range, 10ml increments)
/// - Select injection site (optional)
/// - Select stress level (optional)
/// - Edit notes (max 500 characters)
/// - Explicit Save/Cancel confirmation
///
/// Example:
/// ```dart
/// final result = await showDialog<FluidSession>(
///   context: context,
///   builder: (context) => FluidEditDialog(
///     session: existingSession,
///   ),
/// );
/// ```
class FluidEditDialog extends StatefulWidget {
  /// Creates a [FluidEditDialog]
  const FluidEditDialog({
    required this.session,
    super.key,
  });

  /// The fluid session to edit
  final FluidSession session;

  @override
  State<FluidEditDialog> createState() => _FluidEditDialogState();
}

class _FluidEditDialogState extends State<FluidEditDialog> {
  late double _volumeGiven;
  late FluidLocation? _injectionSite;
  late String? _stressLevel;
  late TextEditingController _notesController;

  static const List<String> _stressLevels = ['low', 'medium', 'high'];

  @override
  void initState() {
    super.initState();
    _volumeGiven = widget.session.volumeGiven;
    _injectionSite = widget.session.injectionSite;
    _stressLevel = widget.session.stressLevel;
    _notesController = TextEditingController(text: widget.session.notes ?? '');
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  /// Check if any changes were made
  bool get _hasChanges =>
      _volumeGiven != widget.session.volumeGiven ||
      _injectionSite != widget.session.injectionSite ||
      _stressLevel != widget.session.stressLevel ||
      _notesController.text != (widget.session.notes ?? '');

  /// Increment volume by 10ml
  void _incrementVolume() {
    setState(() {
      if (_volumeGiven < 500) {
        _volumeGiven = (_volumeGiven + 10).clamp(0, 500);
      }
    });
  }

  /// Decrement volume by 10ml
  void _decrementVolume() {
    setState(() {
      if (_volumeGiven > 0) {
        _volumeGiven = (_volumeGiven - 10).clamp(0, 500);
      }
    });
  }

  /// Handle save
  void _handleSave() {
    if (!_hasChanges) {
      Navigator.of(context).pop();
      return;
    }

    // Validate volume
    if (_volumeGiven < 0 || _volumeGiven > 500) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Volume must be between 0 and 500ml'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Create updated session
    final updatedSession = widget.session.copyWith(
      volumeGiven: _volumeGiven,
      injectionSite: _injectionSite,
      stressLevel: _stressLevel,
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
          maxHeight: mediaQuery.size.height * 0.75,
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
                    // Volume adjuster
                    _buildVolumeAdjuster(theme),
                    const SizedBox(height: AppSpacing.lg),

                    // Injection site selector
                    _buildInjectionSiteSelector(theme),
                    const SizedBox(height: AppSpacing.lg),

                    // Stress level selector
                    _buildStressLevelSelector(theme),
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

  /// Build header
  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit Fluid Therapy',
                style: AppTextStyles.h2.copyWith(
                  color: theme.colorScheme.onSurface,
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

  /// Build volume adjuster with +/- buttons
  Widget _buildVolumeAdjuster(ThemeData theme) {
    final displayVolume = _volumeGiven == _volumeGiven.toInt()
        ? _volumeGiven.toInt().toString()
        : _volumeGiven.toStringAsFixed(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Volume',
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
                onPressed: _decrementVolume,
                enabled: _volumeGiven > 0,
              ),
              const SizedBox(width: AppSpacing.lg),

              // Display
              Column(
                children: [
                  Text(
                    displayVolume,
                    style: AppTextStyles.display.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontSize: 40,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ml',
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
                onPressed: _incrementVolume,
                enabled: _volumeGiven < 500,
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

  /// Build injection site selector
  Widget _buildInjectionSiteSelector(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Injection Site (optional)',
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        DropdownButtonFormField<FluidLocation?>(
          initialValue: _injectionSite,
          decoration: InputDecoration(
            hintText: 'Select location',
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
          ),
          items: [
            const DropdownMenuItem<FluidLocation?>(
              child: Text('None'),
            ),
            ...FluidLocation.values.map(
              (location) => DropdownMenuItem<FluidLocation?>(
                value: location,
                child: Text(location.displayName),
              ),
            ),
          ],
          onChanged: (value) {
            setState(() {
              _injectionSite = value;
            });
          },
        ),
      ],
    );
  }

  /// Build stress level selector
  Widget _buildStressLevelSelector(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Stress Level (optional)',
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        DropdownButtonFormField<String?>(
          initialValue: _stressLevel,
          decoration: InputDecoration(
            hintText: 'Select stress level',
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
          ),
          items: [
            const DropdownMenuItem<String?>(
              child: Text('None'),
            ),
            ..._stressLevels.map(
              (level) => DropdownMenuItem<String?>(
                value: level,
                child: Text(level[0].toUpperCase() + level.substring(1)),
              ),
            ),
          ],
          onChanged: (value) {
            setState(() {
              _stressLevel = value;
            });
          },
        ),
      ],
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
            hintText: 'Add any notes about this session...',
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
