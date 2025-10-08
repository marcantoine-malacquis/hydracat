import 'package:flutter/material.dart';
import 'package:hydracat/core/theme/theme.dart';

/// Special Floating Action Button for logging sessions.
/// Implements the droplet FAB design from the UI guidelines.
class HydraFab extends StatelessWidget {
  /// Creates a HydraFab.
  const HydraFab({
    required this.onPressed,
    super.key,
    this.onLongPress,
    this.icon = Icons.water_drop,
    this.isLoading = false,
    this.tooltip = 'Log Session',
  });

  /// Callback function when FAB is pressed
  final VoidCallback? onPressed;

  /// Callback function when FAB is long-pressed (for quick-log)
  final VoidCallback? onLongPress;

  /// Icon to display in the FAB
  final IconData icon;

  /// Whether to show loading state
  final bool isLoading;

  /// Tooltip text for the FAB
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final fab = FloatingActionButton(
      onPressed: isLoading ? null : onPressed,
      tooltip: tooltip,
      backgroundColor: AppColors.surface, // White background
      foregroundColor: AppColors.primary, // Teal droplet
      elevation: 0,
      shape: const CircleBorder(
        side: BorderSide(
          color: AppColors.border,
        ),
      ),
      child: _buildFabContent(),
    );

    // Wrap with GestureDetector if long press is provided
    if (onLongPress != null) {
      return GestureDetector(
        onLongPress: isLoading ? null : onLongPress,
        child: fab,
      );
    }

    return fab;
  }

  Widget _buildFabContent() {
    if (isLoading) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.onPrimary),
        ),
      );
    }

    return Icon(
      icon,
      size: 32, // Increased from 28 to make it stand out more
    );
  }
}

/// Extended FAB for more prominent actions
class HydraExtendedFab extends StatelessWidget {
  /// Creates a HydraExtendedFab.
  const HydraExtendedFab({
    required this.onPressed,
    required this.label,
    super.key,
    this.icon = Icons.water_drop,
    this.isLoading = false,
  });

  /// Callback function when FAB is pressed
  final VoidCallback? onPressed;

  /// Label text for the extended FAB
  final String label;

  /// Icon for the FAB
  final IconData icon;

  /// Whether to show loading state
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: isLoading ? null : onPressed,
      backgroundColor: AppColors.surface, // White background
      foregroundColor: AppColors.primary, // Teal text and icon
      elevation: 0,
      icon: _buildIcon(),
      label: _buildLabel(),
    );
  }

  Widget _buildIcon() {
    if (isLoading) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.onPrimary),
        ),
      );
    }

    return Icon(icon);
  }

  Widget _buildLabel() {
    if (isLoading) {
      return const Text('Loading...');
    }

    return Text(
      label,
      style: AppTextStyles.buttonPrimary.copyWith(
        color: AppColors.primary, // Teal text color
      ),
    );
  }
}
