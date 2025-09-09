import 'package:flutter/material.dart';
import 'package:hydracat/core/constants/app_accessibility.dart';
import 'package:hydracat/core/constants/app_colors.dart';
import 'package:hydracat/core/constants/app_icons.dart';
import 'package:hydracat/core/theme/app_layout.dart';
import 'package:hydracat/core/theme/app_shadows.dart';
import 'package:hydracat/core/theme/app_spacing.dart';
import 'package:hydracat/shared/widgets/accessibility/hydra_touch_target.dart';
import 'package:hydracat/shared/widgets/buttons/hydra_fab.dart';
import 'package:hydracat/shared/widgets/icons/hydra_icon.dart';

/// Custom bottom navigation bar with accessibility support.
class HydraNavigationBar extends StatefulWidget {
  /// Creates a HydraNavigationBar with the specified items and current index.
  const HydraNavigationBar({
    required this.items,
    required this.currentIndex,
    required this.onTap,
    super.key,
    this.backgroundColor,
    this.onFabPressed,
    this.showVerificationBadge = false,
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

  /// Whether to show verification badge on profile tab.
  final bool showVerificationBadge;

  @override
  State<HydraNavigationBar> createState() => _HydraNavigationBarState();
}

class _HydraNavigationBarState extends State<HydraNavigationBar> {
  int? _pressedIndex;

  void _setPressedIndex(int? index) {
    setState(() => _pressedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppLayout.bottomNavHeight,
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? AppColors.surface,
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
                children: widget.items.take(2).map((item) {
                  final index = widget.items.indexOf(item);
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
                onPressed: widget.onFabPressed,
                icon: _getIconData(AppIcons.logSession),
              ),
            ),
            const SizedBox(width: AppSpacing.md),

            // Right side items (Progress, Profile)
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: widget.items.skip(2).map((item) {
                  final index = widget.items.indexOf(item);
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
    final isSelected = widget.currentIndex >= 0 && index == widget.currentIndex;
    final isPressed = _pressedIndex == index;
    final color = isSelected ? AppColors.primary : AppColors.textSecondary;

    return GestureDetector(
      onTapDown: (_) => _setPressedIndex(index),
      onTapUp: (_) {
        // Add delay to make the effect visible
        Future.delayed(const Duration(milliseconds: 120), () {
          if (mounted) _setPressedIndex(null);
        });
      },
      onTapCancel: () => _setPressedIndex(null),
      onTap: () => widget.onTap(index),
      child: HydraTouchTarget(
        minSize: 48, // Accessibility touch target
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          decoration: BoxDecoration(
            boxShadow: isPressed 
                ? [AppShadows.navigationIconPressed]
                : null,
            borderRadius: BorderRadius.circular(12),
          ),
          child: AnimatedScale(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeInOut,
            scale: isPressed ? 0.95 : 1.0,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Column(
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
                          fontWeight: isSelected 
                              ? FontWeight.w600 
                              : FontWeight.w400,
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
                // Show badge on profile tab for unverified users
                if (widget.showVerificationBadge && item.label == 'Profile')
                  Positioned(
                    right: 0,
                    top: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
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
