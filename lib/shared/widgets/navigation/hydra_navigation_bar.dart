import 'package:flutter/material.dart';
import 'package:hydracat/core/theme/theme.dart';
import 'package:hydracat/shared/widgets/buttons/hydra_fab.dart';

/// Custom navigation bar for HydraCat with droplet FAB.
/// Uses Flutter's built-in Scaffold APIs for proper layout handling.
class HydraNavigationBar extends StatelessWidget {
  /// Creates a HydraNavigationBar.
  const HydraNavigationBar({
    required this.currentIndex,
    required this.onTap,
    super.key,
    this.items,
  });

  /// Current selected index
  final int currentIndex;

  /// Callback when navigation item is tapped
  final ValueChanged<int> onTap;

  /// Navigation items (defaults to standard HydraCat navigation)
  final List<HydraNavigationItem>? items;

  @override
  Widget build(BuildContext context) {
    final navigationItems = items ?? _getDefaultNavigationItems();

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
      selectedLabelStyle: AppTextStyles.navigationLabel,
      unselectedLabelStyle: AppTextStyles.navigationLabel,
      items: navigationItems.map((item) {
        return BottomNavigationBarItem(
          icon: Icon(
            currentIndex == navigationItems.indexOf(item)
                ? item.activeIcon
                : item.inactiveIcon,
          ),
          label: item.label,
        );
      }).toList(),
    );
  }

  List<HydraNavigationItem> _getDefaultNavigationItems() {
    return [
      const HydraNavigationItem(
        label: 'Home',
        activeIcon: Icons.pets,
        inactiveIcon: Icons.pets_outlined,
      ),
      const HydraNavigationItem(
        label: 'Schedule',
        activeIcon: Icons.calendar_today,
        inactiveIcon: Icons.calendar_today_outlined,
      ),
      const HydraNavigationItem(
        label: 'Log',
        activeIcon: Icons.add_circle,
        inactiveIcon: Icons.add_circle_outline,
      ),
      const HydraNavigationItem(
        label: 'Progress',
        activeIcon: Icons.show_chart,
        inactiveIcon: Icons.show_chart_outlined,
      ),
      const HydraNavigationItem(
        label: 'Profile',
        activeIcon: Icons.pets,
        inactiveIcon: Icons.pets_outlined,
      ),
    ];
  }
}

/// Navigation item configuration
class HydraNavigationItem {
  /// Creates a HydraNavigationItem.
  const HydraNavigationItem({
    required this.label,
    required this.activeIcon,
    required this.inactiveIcon,
  });

  /// Item label
  final String label;

  /// Icon when item is active (filled)
  final IconData activeIcon;

  /// Icon when item is inactive (outlined)
  final IconData inactiveIcon;
}

/// Helper class to create complete Scaffold configurations with navigation
class HydraScaffold {
  /// Creates a Scaffold with HydraCat navigation bar and FAB
  static Scaffold create({
    required BuildContext context,
    required Widget body,
    required int currentIndex,
    required ValueChanged<int> onTap,
    PreferredSizeWidget? appBar,
    Color? backgroundColor,
    Widget? floatingActionButton,
    VoidCallback? onFabPressed,
    List<HydraNavigationItem>? navigationItems,
  }) {
    return Scaffold(
      appBar: appBar,
      backgroundColor: backgroundColor ?? AppColors.background,
      body: body,
      bottomNavigationBar: HydraNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        items: navigationItems,
      ),
      floatingActionButton:
          floatingActionButton ??
          HydraFab(
            onPressed: onFabPressed ?? () => onTap(2), // Default to log index
          ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

/// Extended navigation bar with custom FAB positioning
class HydraNavigationBarExtended extends StatelessWidget {
  /// Creates a HydraNavigationBarExtended.
  const HydraNavigationBarExtended({
    required this.currentIndex,
    required this.onTap,
    required this.fabOnPressed,
    super.key,
    this.fabLabel,
    this.fabIcon,
    this.items,
  });

  /// Current selected index
  final int currentIndex;

  /// Callback when navigation item is tapped
  final ValueChanged<int> onTap;

  /// FAB onPressed callback
  final VoidCallback fabOnPressed;

  /// FAB label (for extended FAB)
  final String? fabLabel;

  /// FAB icon
  final IconData? fabIcon;

  /// Navigation items
  final List<HydraNavigationItem>? items;

  @override
  Widget build(BuildContext context) {
    final navigationItems = items ?? _getDefaultNavigationItems();

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
      selectedLabelStyle: AppTextStyles.navigationLabel,
      unselectedLabelStyle: AppTextStyles.navigationLabel,
      items: navigationItems.map((item) {
        return BottomNavigationBarItem(
          icon: Icon(
            currentIndex == navigationItems.indexOf(item)
                ? item.activeIcon
                : item.inactiveIcon,
          ),
          label: item.label,
        );
      }).toList(),
    );
  }

  List<HydraNavigationItem> _getDefaultNavigationItems() {
    return [
      const HydraNavigationItem(
        label: 'Home',
        activeIcon: Icons.pets,
        inactiveIcon: Icons.pets_outlined,
      ),
      const HydraNavigationItem(
        label: 'Schedule',
        activeIcon: Icons.calendar_today,
        inactiveIcon: Icons.calendar_today_outlined,
      ),
      const HydraNavigationItem(
        label: 'Log',
        activeIcon: Icons.add_circle,
        inactiveIcon: Icons.add_circle_outline,
      ),
      const HydraNavigationItem(
        label: 'Progress',
        activeIcon: Icons.show_chart,
        inactiveIcon: Icons.show_chart_outlined,
      ),
      const HydraNavigationItem(
        label: 'Profile',
        activeIcon: Icons.pets,
        inactiveIcon: Icons.pets_outlined,
      ),
    ];
  }
}
