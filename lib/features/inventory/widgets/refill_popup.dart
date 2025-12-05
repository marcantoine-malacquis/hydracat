import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/core/theme/theme.dart';
import 'package:hydracat/features/inventory/models/inventory_state.dart';
import 'package:hydracat/features/profile/models/schedule.dart';
import 'package:hydracat/providers/auth_provider.dart';
import 'package:hydracat/providers/inventory_provider.dart';
import 'package:hydracat/providers/profile_provider.dart';
import 'package:hydracat/shared/widgets/widgets.dart';
import 'package:intl/intl.dart';

/// Bottom sheet for adding or resetting inventory.
class RefillPopup extends ConsumerStatefulWidget {
  /// Creates a new refill popup.
  const RefillPopup({
    this.currentInventory,
    super.key,
  });

  /// Current inventory state; null when activating for the first time.
  final InventoryState? currentInventory;

  @override
  ConsumerState<RefillPopup> createState() => _RefillPopupState();
}

class _RefillPopupState extends ConsumerState<RefillPopup> {
  final TextEditingController _customVolumeController = TextEditingController();
  final NumberFormat _volumeFormat = NumberFormat.decimalPattern();

  double _selectedVolume = 500;
  int _quantity = 1;
  int _reminderSessionsLeft = 10;
  bool _isReset = false;
  bool _isSaving = false;

  double get _currentVolume =>
      widget.currentInventory?.inventory.remainingVolume ?? 0;

  double get _totalVolumeAdded => _selectedVolume * _quantity;

  double get _newTotal => (_isReset || widget.currentInventory == null)
      ? _totalVolumeAdded
      : _currentVolume + _totalVolumeAdded;

  @override
  void dispose() {
    _customVolumeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final thresholdPreview = _buildThresholdPreview();
    final hasInventory = widget.currentInventory != null;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            const SizedBox(height: AppSpacing.lg),
            _buildQuickSelect(),
            const SizedBox(height: AppSpacing.md),
            _buildCustomInput(),
            const SizedBox(height: AppSpacing.md),
            _buildQuantitySelector(),
            if (hasInventory) ...[
              const SizedBox(height: AppSpacing.sm),
              _buildResetToggle(),
            ],
            const SizedBox(height: AppSpacing.md),
            _buildLivePreview(hasInventory: hasInventory),
            const SizedBox(height: AppSpacing.md),
            _buildReminderSlider(thresholdPreview),
            const SizedBox(height: AppSpacing.lg),
            HydraButton(
              onPressed: _totalVolumeAdded <= 0 || _isSaving
                  ? null
                  : _handleSave,
              isFullWidth: true,
              isLoading: _isSaving,
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Refill Inventory',
            style: AppTextStyles.h2,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildQuickSelect() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Select',
          style: AppTextStyles.body.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            _QuickSelectChip(
              label: '500 mL',
              selected:
                  _customVolumeController.text.isEmpty &&
                  _selectedVolume == 500,
              onSelected: () {
                setState(() {
                  _selectedVolume = 500;
                  _customVolumeController.clear();
                });
              },
            ),
            _QuickSelectChip(
              label: '1000 mL',
              selected:
                  _customVolumeController.text.isEmpty &&
                  _selectedVolume == 1000,
              onSelected: () {
                setState(() {
                  _selectedVolume = 1000;
                  _customVolumeController.clear();
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCustomInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Or Enter Custom Volume',
          style: AppTextStyles.body.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        HydraTextField(
          controller: _customVolumeController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp('[0-9.,]')),
          ],
          decoration: const InputDecoration(
            hintText: 'e.g. 750',
            suffixText: 'mL',
          ),
          onChanged: (value) {
            final parsed = double.tryParse(value.replaceAll(',', ''));
            setState(() {
              _selectedVolume = (parsed != null && parsed > 0) ? parsed : 0;
            });
          },
        ),
      ],
    );
  }

  Widget _buildQuantitySelector() {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Quantity',
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: _quantity > 1
              ? () => setState(() => _quantity = _quantity - 1)
              : null,
        ),
        Text(
          '$_quantity',
          style: AppTextStyles.h3,
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: () => setState(() => _quantity = _quantity + 1),
        ),
      ],
    );
  }

  Widget _buildResetToggle() {
    return CheckboxListTile(
      value: _isReset,
      onChanged: (value) {
        setState(() {
          _isReset = value ?? false;
        });
      },
      contentPadding: EdgeInsets.zero,
      activeColor: AppColors.primary,
      title: const Text('Reset inventory (ignore current amount)'),
      controlAffinity: ListTileControlAffinity.leading,
    );
  }

  Widget _buildLivePreview({required bool hasInventory}) {
    final currentText = hasInventory
        ? 'Current: ${_volumeFormat.format(_currentVolume)} mL'
        : 'Not started yet';
    final addingText = '+${_volumeFormat.format(_totalVolumeAdded)} mL';
    final newTotalText = 'New inventory: ${_volumeFormat.format(_newTotal)} mL';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        border: Border.all(color: AppColors.primary),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                currentText,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                addingText,
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(
            color: AppColors.border,
            height: AppSpacing.sm,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            newTotalText,
            style: AppTextStyles.h3.copyWith(
              color: AppColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderSlider(String thresholdPreview) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Remind me when low',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            Text(
              '$_reminderSessionsLeft sessions left',
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        HydraSlider(
          value: _reminderSessionsLeft.toDouble(),
          min: 1,
          max: 20,
          divisions: 19,
          activeColor: AppColors.primary,
          onChanged: (value) {
            setState(() {
              _reminderSessionsLeft = value.round();
            });
          },
        ),
        Text(
          thresholdPreview,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  String _buildThresholdPreview() {
    final average = _computeAverageVolumePerSession();
    if (average <= 0) {
      return 'Unable to estimate (no active schedules)';
    }

    final threshold = (_reminderSessionsLeft * average).round();
    return 'Remind at ~${_volumeFormat.format(threshold)} mL';
  }

  double _computeAverageVolumePerSession() {
    final profileState = ref.read(profileProvider);
    final schedules = <Schedule>[];
    if (profileState.fluidSchedule != null) {
      schedules.add(profileState.fluidSchedule!);
    }

    var totalDailyVolume = 0.0;
    var totalSessions = 0;

    for (final schedule in schedules) {
      if (!schedule.isActive ||
          !schedule.isFluidTherapy ||
          schedule.targetVolume == null ||
          schedule.reminderTimes.isEmpty) {
        continue;
      }

      final sessionsPerDay = schedule.reminderTimes.length;
      totalDailyVolume += schedule.targetVolume! * sessionsPerDay;
      totalSessions += sessionsPerDay;
    }

    return totalSessions > 0 ? totalDailyVolume / totalSessions : 0;
  }

  Future<void> _handleSave() async {
    if (_totalVolumeAdded <= 0) {
      HydraSnackBar.showError(context, 'Enter a volume to add');
      return;
    }

    final user = ref.read(currentUserProvider);
    if (user == null) {
      HydraSnackBar.showError(
        context,
        'You must be signed in to update inventory',
      );
      return;
    }

    final inventoryService = ref.read(inventoryServiceProvider);

    setState(() {
      _isSaving = true;
    });

    try {
      if (widget.currentInventory == null) {
        await inventoryService.createInventory(
          userId: user.id,
          volumeAdded: _totalVolumeAdded,
          reminderSessionsLeft: _reminderSessionsLeft,
        );
      } else {
        await inventoryService.addRefill(
          userId: user.id,
          volumeAdded: _totalVolumeAdded,
          reminderSessionsLeft: _reminderSessionsLeft,
          isReset: _isReset,
        );
      }

      if (!mounted) return;

      HydraSnackBar.showSuccess(
        context,
        'Inventory updated: ${_volumeFormat.format(_newTotal)} mL',
      );
      Navigator.of(context).pop();
    } on Object catch (e) {
      if (mounted) {
        HydraSnackBar.showError(
          context,
          'Failed to save refill: $e',
        );
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}

class _QuickSelectChip extends StatelessWidget {
  const _QuickSelectChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      selectedColor: AppColors.primary.withValues(alpha: 0.15),
      checkmarkColor: AppColors.primaryDark,
      onSelected: (_) => onSelected(),
      avatar: selected
          ? const Icon(
              Icons.check,
              size: 18,
              color: AppColors.primaryDark,
            )
          : null,
      backgroundColor: AppColors.surface,
      side: BorderSide(
        color: selected ? AppColors.primary : AppColors.border,
      ),
    );
  }
}
