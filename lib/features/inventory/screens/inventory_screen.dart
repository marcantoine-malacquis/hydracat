import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hydracat/core/theme/theme.dart';
import 'package:hydracat/core/utils/date_utils.dart';
import 'package:hydracat/features/inventory/models/inventory_state.dart';
import 'package:hydracat/features/inventory/widgets/refill_popup.dart';
import 'package:hydracat/features/profile/models/schedule.dart';
import 'package:hydracat/providers/auth_provider.dart';
import 'package:hydracat/providers/inventory_provider.dart';
import 'package:hydracat/providers/profile_provider.dart';
import 'package:hydracat/shared/widgets/widgets.dart';
import 'package:intl/intl.dart';

/// Displays the fluid inventory tracking experience for fluids, including
/// current volume, estimates, and refill entry points.
class InventoryScreen extends ConsumerWidget {
  /// Creates the inventory screen.
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventoryAsync = ref.watch(inventoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: HydraAppBar(
        title: const Text('Inventory'),
        leading: HydraBackButton(
          onPressed: () => context.pop(),
        ),
        actions: [
          if (inventoryAsync.valueOrNull != null)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Add refill',
              onPressed: () => _showRefillPopup(
                context,
                ref,
                inventoryAsync.valueOrNull,
              ),
            ),
        ],
      ),
      body: inventoryAsync.when(
        data: (inventoryState) => inventoryState == null
            ? _EmptyState(
                onStartTracking: () =>
                    _showRefillPopup(context, ref, inventoryState),
              )
            : _InventoryContent(
                inventoryState: inventoryState,
                onAdjust: () => _showVolumeAdjustmentDialog(
                  context,
                  ref,
                  inventoryState,
                ),
              ),
        loading: () => const Center(
          child: HydraProgressIndicator(color: AppColors.primary),
        ),
        error: (error, _) => Center(
          child: HydraInfoCard(
            message: 'Unable to load inventory: $error',
            type: HydraInfoType.error,
          ),
        ),
      ),
    );
  }

  Future<void> _showRefillPopup(
    BuildContext context,
    WidgetRef ref,
    InventoryState? currentInventory,
  ) async {
    await showHydraBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: AppColors.background,
      builder: (sheetContext) => HydraBottomSheet(
        backgroundColor: AppColors.background,
        child: RefillPopup(
          currentInventory: currentInventory,
        ),
      ),
    );
  }

  Future<void> _showVolumeAdjustmentDialog(
    BuildContext context,
    WidgetRef ref,
    InventoryState inventoryState,
  ) async {
    final controller = TextEditingController(
      text: inventoryState.inventory.remainingVolume.toStringAsFixed(0),
    );

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Adjust Inventory'),
          content: HydraTextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[0-9.,]')),
            ],
            decoration: const InputDecoration(
              labelText: 'Inventory (mL)',
              helperText: 'Correct for leaks, spills, or tracking errors',
              suffixText: 'mL',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final parsed = double.tryParse(
                  controller.text.trim().replaceAll(',', ''),
                );
                if (parsed == null || parsed.isNaN || parsed.isInfinite) {
                  HydraSnackBar.showError(
                    dialogContext,
                    'Enter a valid number',
                  );
                  return;
                }

                final user = ref.read(currentUserProvider);
                if (user == null) {
                  HydraSnackBar.showError(
                    dialogContext,
                    'You must be signed in to adjust inventory',
                  );
                  return;
                }

                final profile = ref.read(profileProvider);
                final pet = profile.primaryPet;
                if (pet == null) {
                  HydraSnackBar.showError(
                    dialogContext,
                    'No primary pet found for inventory notification',
                  );
                  return;
                }

                final schedules = _getActiveFluidSchedules(profile);
                final inventoryService = ref.read(inventoryServiceProvider);

                try {
                  final average = inventoryService
                      .calculateMetrics(
                        inventory: inventoryState.inventory,
                        schedules: schedules,
                      )
                      .averageVolumePerSession;

                  await inventoryService.updateVolume(
                    userId: user.id,
                    inventory: inventoryState.inventory,
                    newVolume: parsed,
                    averageVolumePerSession: average > 0 ? average : null,
                  );

                  // Re-run threshold check with an updated snapshot
                  // if available.
                  final refreshed = await ref.read(inventoryProvider.future);
                  final updatedInventory =
                      refreshed?.inventory ??
                      inventoryState.inventory.copyWith(
                        remainingVolume: parsed,
                        initialVolume: math.max(
                          inventoryState.inventory.initialVolume,
                          parsed,
                        ),
                      );

                  await inventoryService.checkThresholdAndNotify(
                    userId: user.id,
                    petId: pet.id,
                    petName: pet.name,
                    inventory: updatedInventory,
                    schedules: schedules,
                  );

                  if (context.mounted) {
                    Navigator.of(dialogContext).pop();
                    HydraSnackBar.showSuccess(
                      context,
                      'Inventory updated: '
                      '${NumberFormat.decimalPattern().format(parsed)} mL',
                    );
                  }
                } on Object catch (e) {
                  if (!dialogContext.mounted) return;
                  HydraSnackBar.showError(
                    dialogContext,
                    'Failed to update inventory: $e',
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  List<Schedule> _getActiveFluidSchedules(ProfileState profileState) {
    final schedules = <Schedule>[];
    if (profileState.fluidSchedule != null) {
      schedules.add(profileState.fluidSchedule!);
    }

    return schedules
        .where(
          (schedule) =>
              schedule.isActive &&
              schedule.isFluidTherapy &&
              schedule.targetVolume != null &&
              schedule.reminderTimes.isNotEmpty,
        )
        .toList();
  }
}

class _InventoryContent extends StatelessWidget {
  const _InventoryContent({
    required this.inventoryState,
    required this.onAdjust,
  });

  final InventoryState inventoryState;
  final VoidCallback onAdjust;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ProgressSection(
            inventoryState: inventoryState,
            onAdjust: onAdjust,
          ),
          const SizedBox(height: AppSpacing.lg),
          _EstimatesSection(inventoryState: inventoryState),
          const SizedBox(height: AppSpacing.lg),
          _LastRefillSection(inventoryState: inventoryState),
        ],
      ),
    );
  }
}

class _ProgressSection extends StatelessWidget {
  const _ProgressSection({
    required this.inventoryState,
    required this.onAdjust,
  });

  final InventoryState inventoryState;
  final VoidCallback onAdjust;

  @override
  Widget build(BuildContext context) {
    final progressColor = _getColorForPercentage(
      inventoryState.displayPercentage,
    );

    return HydraCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onAdjust,
            borderRadius: BorderRadius.circular(12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Inventory',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        inventoryState.displayVolumeText,
                        style: AppTextStyles.h1.copyWith(
                          color: progressColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.edit_outlined),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: inventoryState.displayPercentage.clamp(0, 1),
              minHeight: 18,
              backgroundColor: AppColors.disabled,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              inventoryState.displayPercentageText,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          if (inventoryState.isNegative &&
              inventoryState.overageText != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.errorLight.withValues(alpha: 0.1),
                border: Border.all(color: AppColors.errorLight),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.error,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      inventoryState.overageText!,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.errorDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getColorForPercentage(double percentage) {
    final pct = (percentage * 100).clamp(0, 100);
    if (pct > 50) return AppColors.primary;
    if (pct >= 25) return AppColors.warning;
    return AppColors.error;
  }
}

class _EstimatesSection extends StatelessWidget {
  const _EstimatesSection({required this.inventoryState});

  final InventoryState inventoryState;

  @override
  Widget build(BuildContext context) {
    return HydraCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Estimates',
            style: AppTextStyles.h3,
          ),
          const SizedBox(height: AppSpacing.md),
          _EstimateRow(
            icon: Icons.water_drop,
            label: 'Sessions remaining',
            value: inventoryState.sessionsLeftText,
          ),
          const SizedBox(height: AppSpacing.sm),
          _EstimateRow(
            icon: Icons.event_outlined,
            label: 'Estimated empty date',
            value: inventoryState.estimatedEndDateText ?? 'Unable to estimate',
          ),
        ],
      ),
    );
  }
}

class _EstimateRow extends StatelessWidget {
  const _EstimateRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                value,
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LastRefillSection extends StatelessWidget {
  const _LastRefillSection({required this.inventoryState});

  final InventoryState inventoryState;

  @override
  Widget build(BuildContext context) {
    final dateText = AppDateUtils.formatDate(
      inventoryState.inventory.lastRefillDate,
    );
    return HydraCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Last refill',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                dateText,
                style: AppTextStyles.h3,
              ),
            ],
          ),
          const Spacer(),
          Text(
            '${inventoryState.inventory.refillCount} total refills',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onStartTracking});

  final VoidCallback onStartTracking;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 80,
              color: AppColors.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'Track Your Fluid Inventory',
              style: AppTextStyles.h2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Know how much fluid you have left, estimate sessions remaining, '
              'and get low-inventory reminders.',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            HydraButton(
              onPressed: onStartTracking,
              child: const Text('Start Tracking'),
            ),
          ],
        ),
      ),
    );
  }
}
