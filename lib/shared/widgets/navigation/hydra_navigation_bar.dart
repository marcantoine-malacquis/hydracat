import 'package:flutter/material.dart';
import 'package:hydracat/core/constants/app_accessibility.dart';
import 'package:hydracat/core/constants/app_colors.dart';
import 'package:hydracat/core/constants/app_icons.dart';
import 'package:hydracat/core/theme/app_layout.dart';
import 'package:hydracat/core/theme/app_spacing.dart';
import 'package:hydracat/shared/widgets/accessibility/hydra_touch_target.dart';
import 'package:hydracat/shared/widgets/buttons/hydra_fab.dart';
import 'package:hydracat/shared/widgets/icons/hydra_icon.dart';

/// Custom bottom navigation bar with accessibility support.
class HydraNavigationBar extends StatelessWidget {
  /// Creates a HydraNavigationBar with the specified items and current index.
  const HydraNavigationBar({
    required this.items,
    required this.currentIndex,
    required this.onTap,
    super.key,
    this.backgroundColor,
    this.onFabPressed,
  });

  /// The navigation items to display.
  final List<HydraNavigationItem> items;

  /// The currently selected index.
  final int currentIndex;

  /// Callback when a navigation item is tapped.
  final ValueChanged<int> onTap;

  /// Background color for the navigation bar.
  final Color? backgroundColor;

  /// Callback when the FAB is pressed.
  final VoidCallback? onFabPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppLayout.bottomNavHeight,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surface,
        border: const Border(
          top: BorderSide(
            color: AppColors.border,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.only(
          bottom: 20, // Reduced bottom padding to move icons higher
        ),
        child: Row(
          children: [
            // Left side items (Home, Schedule)
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: items.take(2).map((item) {
                  final index = items.indexOf(item);
                  return Expanded(
                    child: _buildNavigationItem(context, item, index),
                  );
                }).toList(),
              ),
            ),

            // Center FAB
            const SizedBox(width: AppSpacing.md),
            HydraTouchTarget(
              minSize: AppAccessibility.fabTouchTarget,
              child: HydraFab(
                onPressed: onFabPressed,
                icon: _getIconData(AppIcons.logSession),
              ),
            ),
            const SizedBox(width: AppSpacing.md),

            // Right side items (Progress, Profile)
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: items.skip(2).map((item) {
                  final index = items.indexOf(item);
                  return Expanded(
                    child: _buildNavigationItem(context, item, index),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationItem(
    BuildContext context,
    HydraNavigationItem item,
    int index,
  ) {
    final isSelected = index == currentIndex;
    final color = isSelected ? AppColors.primary : AppColors.textSecondary;

    return HydraTouchTarget(
      minSize: 48, // Slightly larger touch target
      child: GestureDetector(
        onTap: () => onTap(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            HydraIcon(
              icon: item.icon,
              color: color,
              semanticLabel: item.label,
              size: 26, // Larger icon for better visibility
            ),
            const SizedBox(height: 2), // Reduced spacing to fit text
            Flexible(
              child: Text(
                item.label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 10, // Smaller text to prevent truncation
                  height: 1, // Tighter line height
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 1, // Ensure single line
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case AppIcons.logSession:
        return Icons.water_drop;
      default:
        return Icons.help_outline;
    }
  }
}

/// Represents a navigation item in the HydraNavigationBar.
class HydraNavigationItem {
  /// Creates a HydraNavigationItem with the specified properties.
  const HydraNavigationItem({
    required this.icon,
    required this.label,
    this.route,
  });

  /// The icon name from AppIcons.
  final String icon;

  /// The label text for the navigation item.
  final String label;

  /// The route to navigate to when tapped.
  final String? route;
}
