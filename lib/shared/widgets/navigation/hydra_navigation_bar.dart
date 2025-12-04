import 'package:flutter/cupertino.dart';
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

// Animation durations - platform-specific
// Material: Standard Material motion (160ms)
const int _materialIndicatorAnimMs = 160;
// Cupertino: Lighter, faster iOS-style animations (120ms)
const int _cupertinoIndicatorAnimMs = 120;

// Icon sizes - platform-specific
// Material: Standard 26px
const double _materialIconSize = 26;
// Cupertino: Slightly smaller 24px for iOS feel
const double _cupertinoIconSize = 24;

/// Helper class to store indicator geometry (position and size).
class _IndicatorGeometry {
  const _IndicatorGeometry({
    required this.left,
    required this.width,
  });

  final double left;
  final double width;
}

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

  /// Gets the animation duration for indicators based on platform
  /// and accessibility.
  ///
  /// Material platforms use 160ms, Cupertino platforms use 120ms for
  /// lighter feel.
  /// Respects reduced motion preferences.
  Duration _indicatorDuration(BuildContext context, bool isCupertino) {
    final mq = MediaQuery.maybeOf(context);
    final reducedMotion = mq?.disableAnimations ?? false;
    if (reducedMotion) {
      return Duration.zero;
    }

    return Duration(
      milliseconds: isCupertino
          ? _cupertinoIndicatorAnimMs
          : _materialIndicatorAnimMs,
    );
  }

  /// Gets the icon size based on platform.
  ///
  /// Material uses 26px, Cupertino uses 24px for a more iOS-native feel.
  double _iconSize(bool isCupertino) {
    return isCupertino ? _cupertinoIconSize : _materialIconSize;
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
    final platform = Theme.of(context).platform;
    final isCupertino =
        platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;

    if (isCupertino) {
      return _buildCupertinoNavBar(context, isCupertino);
    }

    return _buildMaterialNavBar(context, isCupertino);
  }

  /// Builds the Material (Android) version of the navigation bar.
  ///
  /// Uses Material Design styling:
  /// - Elevation/shadow for depth
  /// - Standard Material colors and typography
  /// - Material motion animations (160ms)
  Widget _buildMaterialNavBar(BuildContext context, bool isCupertino) {
    return Container(
      height: AppLayout.bottomNavHeight,
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? AppColors.surface,
        border: const Border(
          top: BorderSide(
            color: AppColors.border,
          ),
        ),
        // Material: Use elevation/shadow for depth
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: _buildNavBarContent(context, isCupertino),
    );
  }

  /// Builds the Cupertino (iOS/macOS) version of the navigation bar.
  ///
  /// Uses iOS-native styling:
  /// - Border-only separator (no shadow/elevation)
  /// - Lighter, faster animations (120ms)
  /// - Slightly smaller icons (24px vs 26px)
  /// - More subtle selection animations
  Widget _buildCupertinoNavBar(BuildContext context, bool isCupertino) {
    return Container(
      height: AppLayout.bottomNavHeight,
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? AppColors.surface,
        // Cupertino: Use border-only separator (no shadow)
        // Similar to CupertinoTabBar and CupertinoNavigationBar
        border: const Border(
          top: BorderSide(
            color: CupertinoColors.separator,
            width: 0.5, // Hairline width for iOS feel
          ),
        ),
        // No boxShadow on iOS - flat design with border only
      ),
      child: _buildNavBarContent(context, isCupertino),
    );
  }

  /// Builds the shared navigation bar content structure.
  ///
  /// This is platform-agnostic and contains:
  /// - Navigation items (left and right)
  /// - Centered FAB
  /// - Top selection indicators
  Widget _buildNavBarContent(BuildContext context, bool isCupertino) {
    return Stack(
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
                      child: _buildNavigationItem(
                        context,
                        item,
                        index,
                        isCupertino,
                      ),
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
                      child: _buildNavigationItem(
                        context,
                        item,
                        index,
                        isCupertino,
                      ),
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
            child: _buildTopIndicators(context, isCupertino),
          ),
      ],
    );
  }

  /// Computes the geometry (left offset and width) for
  /// the indicator at a given index.
  ///
  /// The indicator needs to account for:
  /// - The center FAB gap (AppSpacing.md * 2 + AppAccessibility.fabTouchTarget)
  /// - Equal distribution of tabs on left and right sides
  /// - Horizontal padding for visual spacing
  _IndicatorGeometry _indicatorGeometryForIndex(
    int index,
    BoxConstraints constraints,
  ) {
    if (index < 0 || index >= widget.items.length) {
      return const _IndicatorGeometry(left: 0, width: 0);
    }

    final totalWidth = constraints.maxWidth;
    const gapWidth = AppSpacing.md * 2 + AppAccessibility.fabTouchTarget;
    final availableWidth = totalWidth - gapWidth;
    final itemWidth = availableWidth / widget.items.length;

    // Calculate left offset based on index
    // For indices 0-1: left side,
    // for indices 2-3: right side (accounting for gap)
    double left;
    if (index < 2) {
      // Left side items (0, 1)
      left = index * itemWidth;
    } else {
      // Right side items (2, 3) - need to account for gap
      left = (index * itemWidth) + gapWidth;
    }

    // Indicator width is itemWidth minus horizontal padding on both sides
    final width = itemWidth - (_indicatorHorizontalPadding * 2);

    return _IndicatorGeometry(
      left: left + _indicatorHorizontalPadding,
      width: width,
    );
  }

  Widget _buildTopIndicators(BuildContext context, bool isCupertino) {
    // iOS: Use easeOut for snappier feel, Material: easeInOut for smoother
    final animationCurve = isCupertino ? Curves.easeOut : Curves.easeInOut;
    final indicatorDuration = _indicatorDuration(context, isCupertino);

    // Hide indicator if no valid selection
    if (widget.currentIndex < 0 || widget.currentIndex >= widget.items.length) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final geometry = _indicatorGeometryForIndex(
          widget.currentIndex,
          constraints,
        );

        return SizedBox(
          height: _indicatorHeight,
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: indicatorDuration,
                curve: animationCurve,
                left: geometry.left,
                width: geometry.width,
                top: 0,
                height: _indicatorHeight,
                child: Container(
                  key: const Key('navTopIndicator'),
                  height: _indicatorHeight,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(_indicatorRadius),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavigationItem(
    BuildContext context,
    HydraNavigationItem item,
    int index,
    bool isCupertino,
  ) {
    final isSelected = widget.currentIndex >= 0 && index == widget.currentIndex;
    final color = isSelected ? AppColors.primary : AppColors.textSecondary;
    final iconSize = _iconSize(isCupertino);

    // iOS: Slightly lighter font weight for selected (w500 vs w600)
    // Material: Standard w600 for selected
    final selectedFontWeight = isCupertino ? FontWeight.w500 : FontWeight.w600;

    return Semantics(
      button: true,
      selected: isSelected,
      label: item.label,
      child: GestureDetector(
        onTap: () => widget.onTap(index),
        // Make entire area tappable (industry standard for bottom navigation)
        behavior: HitTestBehavior.opaque,
        child: Container(
          // Maintain minimum accessibility height (44-48px industry standard)
          constraints: const BoxConstraints(
            minHeight: AppAccessibility.minTouchTarget,
          ),
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
                size: iconSize, // Platform-specific size
              ),
              const SizedBox(height: 2),
              Flexible(
                child: Text(
                  item.label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: isSelected
                        ? selectedFontWeight
                        : FontWeight.w400,
                    fontSize: 12,
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
