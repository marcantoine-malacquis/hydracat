import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hydracat/core/theme/app_spacing.dart';
import 'package:hydracat/shared/widgets/bottom_sheets/hydra_bottom_sheet.dart';
import 'package:hydracat/shared/widgets/custom_dropdown.dart';

/// Platform-adaptive dropdown widget for HydraCat.
///
/// Wraps [CustomDropdown] on Material platforms and uses a [CupertinoButton]
/// that opens a modal bottom sheet with selectable options on iOS/macOS,
/// while mirroring the core [CustomDropdown] API used in the app.
///
/// **API Differences:**
/// - Material: Uses [CustomDropdown] with overlay-based dropdown menu
/// - Cupertino: Uses [CupertinoButton] that opens a bottom sheet with
///   [CupertinoListTile] options, matching iOS native patterns
class HydraDropdown<T> extends StatelessWidget {
  /// Creates a platform-adaptive dropdown.
  const HydraDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
    required this.itemBuilder,
    this.labelText,
    this.enabled = true,
    this.hintText,
    this.width,
    super.key,
  });

  /// Currently selected value
  final T? value;

  /// List of available items
  final List<T> items;

  /// Callback when selection changes
  final ValueChanged<T?> onChanged;

  /// Builder for individual dropdown items
  final Widget Function(T item) itemBuilder;

  /// Label text for the dropdown
  final String? labelText;

  /// Whether the dropdown is enabled
  final bool enabled;

  /// Hint text when no value is selected
  final String? hintText;

  /// Optional width constraint for the dropdown
  final double? width;

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;

    if (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS) {
      return _buildCupertino(context);
    }

    return _buildMaterial(context);
  }

  Widget _buildMaterial(BuildContext context) {
    return SizedBox(
      width: width,
      child: CustomDropdown<T>(
        value: value,
        items: items,
        onChanged: enabled ? onChanged : (_) {},
        itemBuilder: itemBuilder,
        labelText: labelText,
        enabled: enabled,
        hintText: hintText,
      ),
    );
  }

  Widget _buildCupertino(BuildContext context) {
    final theme = Theme.of(context);
    final displayText = value != null
        ? itemBuilder(value as T)
        : Text(
            hintText ?? '',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          );

    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (labelText != null) ...[
            Text(
              labelText!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: enabled ? () => _showCupertinoPicker(context) : null,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: enabled
                    ? theme.colorScheme.surface
                    : theme.colorScheme.surface.withValues(alpha: 0.5),
                border: Border.all(
                  color: enabled
                      ? theme.colorScheme.outline
                      : theme.colorScheme.outline.withValues(alpha: 0.5),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: displayText),
                  Icon(
                    CupertinoIcons.chevron_down,
                    size: 16,
                    color: enabled
                        ? theme.colorScheme.onSurfaceVariant
                        : theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.5,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCupertinoPicker(BuildContext context) {
    showHydraBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _CupertinoDropdownSheet<T>(
        items: items,
        selectedValue: value,
        itemBuilder: itemBuilder,
        onSelected: (item) {
          onChanged(item);
          Navigator.of(context).pop();
        },
      ),
    );
  }
}

class _CupertinoDropdownSheet<T> extends StatelessWidget {
  const _CupertinoDropdownSheet({
    required this.items,
    required this.selectedValue,
    required this.itemBuilder,
    required this.onSelected,
  });

  final List<T> items;
  final T? selectedValue;
  final Widget Function(T item) itemBuilder;
  final ValueChanged<T?> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return HydraBottomSheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: AppSpacing.sm),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outline.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Options list
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: items.map((item) {
                final isSelected = selectedValue == item;
                return CupertinoListTile(
                  title: itemBuilder(item),
                  trailing: isSelected
                      ? Icon(
                          CupertinoIcons.check_mark,
                          color: theme.colorScheme.primary,
                          size: 20,
                        )
                      : null,
                  onTap: () => onSelected(item),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}
