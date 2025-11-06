import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hydracat/core/theme/theme.dart';

/// Special Floating Action Button for logging sessions.
/// Implements the droplet FAB design from the UI guidelines.
class HydraFab extends StatefulWidget {
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
  State<HydraFab> createState() => _HydraFabState();
}

class _HydraFabState extends State<HydraFab> {
  Timer? _longPressTimer;

  @override
  void dispose() {
    _longPressTimer?.cancel();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    // Trigger haptic feedback immediately on touch down
    HapticFeedback.selectionClick();
    
    if (widget.onLongPress != null && !widget.isLoading) {
      _longPressTimer = Timer(const Duration(milliseconds: 500), () {
        widget.onLongPress!();
      });
    }
  }

  void _onTapUp(TapUpDetails details) {
    _longPressTimer?.cancel();
  }

  void _onTapCancel() {
    _longPressTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    // If we have a long press handler, create a custom FAB that handles
    // gestures properly
    if (widget.onLongPress != null) {
      return Material(
        shape: const CircleBorder(
          side: BorderSide(
            color: AppColors.border,
          ),
        ),
        color: AppColors.surface,
        child: InkWell(
          onTap: widget.isLoading ? null : widget.onPressed,
          // Use InkWell's native long-press to avoid conflicts
          onLongPress: widget.isLoading
              ? null
              : () {
                  widget.onLongPress?.call();
                },
          // Keep these for safety, but long-press above is the primary path
          onTapDown: _onTapDown,
          onTapUp: _onTapUp,
          onTapCancel: _onTapCancel,
          customBorder: const CircleBorder(),
          child: Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
            ),
            // IMPORTANT: Do NOT wrap in Tooltip here; Tooltip captures
            // long-press gestures on mobile and prevents our handler
            child: Icon(
              widget.icon,
              size: 32,
              color: AppColors.primary,
            ),
          ),
        ),
      );
    }

    // Fallback to standard FloatingActionButton for simple press-only case
    return FloatingActionButton(
      onPressed: widget.isLoading
          ? null
          : () {
              HapticFeedback.selectionClick();
              widget.onPressed?.call();
            },
      tooltip: widget.tooltip,
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
  }

  Widget _buildFabContent() {
    if (widget.isLoading) {
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
      widget.icon,
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
