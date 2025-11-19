import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hydracat/core/constants/app_accessibility.dart';
import 'package:hydracat/core/constants/app_colors.dart';
import 'package:hydracat/core/constants/app_icons.dart';
import 'package:hydracat/core/theme/app_layout.dart';
import 'package:hydracat/core/theme/app_spacing.dart';
import 'package:hydracat/shared/widgets/accessibility/hydra_touch_target.dart';
import 'package:hydracat/shared/widgets/buttons/hydra_fab.dart';
import 'package:hydracat/shared/widgets/icons/hydra_icon.dart';

// Indicator visual constants (kept local to avoid ripple across themes)
const double _indicatorHeight = 3;
// Edge spacing for full-width indicators
const double _indicatorHorizontalPadding = 4;
const double _indicatorRadius = 12;
const int _indicatorAnimMs = 160;

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
    this.onFabLongPress,
    this.showVerificationBadge = false,
    this.isFabLoading = false,
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

  /// Callback when the FAB is long-pressed (for quick-log).
  final VoidCallback? onFabLongPress;

  /// Whether to show verification badge on profile tab.
  final bool showVerificationBadge;

  /// Whether the FAB should show loading state.
  final bool isFabLoading;

  @override
  State<HydraNavigationBar> createState() => _HydraNavigationBarState();
}

class _HydraNavigationBarState extends State<HydraNavigationBar> {
  int? _lastAnnouncedIndex;

  Duration _indicatorDuration(BuildContext context) {
    final mq = MediaQuery.maybeOf(context);
    final reducedMotion = mq?.disableAnimations ?? false;
    return reducedMotion
        ? Duration.zero
        : const Duration(milliseconds: _indicatorAnimMs);
  }

  @override
  void didUpdateWidget(covariant HydraNavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newIndex = widget.currentIndex;
    if (newIndex >= 0 && newIndex != _lastAnnouncedIndex) {
      // Light haptic feedback once per selection change
      HapticFeedback.selectionClick();
      _lastAnnouncedIndex = newIndex;
    }
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
      child: Stack(
        children: [
          // Main navigation content
          Padding(
            padding: const EdgeInsets.only(
              top: _indicatorHeight,
              bottom: 20,
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
                    onLongPress: widget.onFabLongPress,
                    icon: _getIconData(AppIcons.logSession),
                    isLoading: widget.isFabLoading,
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

          // Top indicators layer
          if (widget.currentIndex >= 0)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildTopIndicators(context),
            ),
        ],
      ),
    );
  }

  Widget _buildTopIndicators(BuildContext context) {
    return Row(
      children: [
        // Left side items indicators
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: widget.items.take(2).map((item) {
              final index = widget.items.indexOf(item);
              final isSelected = index == widget.currentIndex;
              return Expanded(
                child: AnimatedOpacity(
                  duration: _indicatorDuration(context),
                  opacity: isSelected ? 1.0 : 0.0,
                  child: AnimatedScale(
                    duration: _indicatorDuration(context),
                    scale: isSelected ? 1.0 : 0.9,
                    curve: Curves.easeInOut,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: _indicatorHorizontalPadding,
                      ),
                      child: Container(
                        key: Key('navTopIndicator-$index'),
                        height: _indicatorHeight,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(
                            _indicatorRadius,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        // Center FAB space (no indicator)
        const SizedBox(width: AppSpacing.md),
        const SizedBox(width: AppAccessibility.fabTouchTarget),
        const SizedBox(width: AppSpacing.md),

        // Right side items indicators
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: widget.items.skip(2).map((item) {
              final index = widget.items.indexOf(item);
              final isSelected = index == widget.currentIndex;
              return Expanded(
                child: AnimatedOpacity(
                  duration: _indicatorDuration(context),
                  opacity: isSelected ? 1.0 : 0.0,
                  child: AnimatedScale(
                    duration: _indicatorDuration(context),
                    scale: isSelected ? 1.0 : 0.9,
                    curve: Curves.easeInOut,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: _indicatorHorizontalPadding,
                      ),
                      child: Container(
                        key: Key('navTopIndicator-$index'),
                        height: _indicatorHeight,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(
                            _indicatorRadius,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationItem(
    BuildContext context,
    HydraNavigationItem item,
    int index,
  ) {
    final isSelected = widget.currentIndex >= 0 && index == widget.currentIndex;
    final color = isSelected ? AppColors.primary : AppColors.textSecondary;

    return GestureDetector(
      onTap: () => widget.onTap(index),
      child: Semantics(
        button: true,
        selected: isSelected,
        label: item.label,
        child: HydraTouchTarget(
          minSize: 48, // Accessibility touch target
          child: Container(
            margin: const EdgeInsets.only(
              bottom: 4,
              left: 2,
              right: 2,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                HydraIcon(
                  icon: item.icon,
                  color: color,
                  semanticLabel: item.label,
                  size: 26,
                ),
                const SizedBox(height: 2),
                Flexible(
                  child: Text(
                    item.label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: color,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                      fontSize: 10,
                      height: 1,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
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
