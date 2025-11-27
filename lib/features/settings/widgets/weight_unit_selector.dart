import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/core/constants/app_icons.dart';
import 'package:hydracat/core/theme/theme.dart';
import 'package:hydracat/providers/weight_unit_provider.dart';
import 'package:hydracat/shared/widgets/widgets.dart';

/// A widget that displays and allows selection of weight unit preference.
class WeightUnitSelector extends ConsumerWidget {
  /// Creates a weight unit selector.
  const WeightUnitSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUnit = ref.watch(weightUnitProvider);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
      child: Row(
        children: [
          HydraIcon(
            icon: AppIcons.weightUnit,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: AppSpacing.sm),
          const Expanded(
            child: Text(
              'Weight Unit',
              style: AppTextStyles.body,
            ),
          ),
          HydraSlidingSegmentedControl<String>(
            value: currentUnit,
            segments: const {
              'kg': Text('kg'),
              'lbs': Text('lbs'),
            },
            onChanged: (String newUnit) {
              ref.read(weightUnitProvider.notifier).setWeightUnit(newUnit);
            },
            segmentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
          ),
        ],
      ),
    );
  }
}
