import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hydracat/core/theme/theme.dart';
import 'package:hydracat/shared/widgets/widgets.dart';

/// Platform-adaptive Floating Action Button for logging sessions.
///
/// Wraps [FloatingActionButton] on Material platforms and a custom
/// Cupertino-style circular button on iOS/macOS, while preserving the
/// droplet FAB design from the UI guidelines.
///
/// **Material (Android/others)**: Uses [FloatingActionButton] with Material
/// styling and ink ripple effects. Tooltips are supported.
///
/// **Cupertino (iOS/macOS)**: Uses a custom circular button with Cupertino
/// styling. Tooltips are not supported on iOS (tooltip parameter is ignored).
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

class _HydraFabState extends State<HydraFab>
    with SingleTickerProviderStateMixin {
  Timer? _longPressTimer;
  late AnimationController _longPressAnimationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // Animation duration matches long-press detection time (500ms)
    _longPressAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // Scale animation for visual feedback during long-press
    _scaleAnimation =
        Tween<double>(
          begin: 1,
          end: 0.92, // Slightly more pronounced than selection card
          // for FAB visibility
        ).animate(
          CurvedAnimation(
            parent: _longPressAnimationController,
            curve: Curves.easeInOut,
          ),
        );
  }

  @override
  void dispose() {
    _longPressTimer?.cancel();
    _longPressAnimationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    // Trigger haptic feedback immediately on touch down
    HapticFeedback.selectionClick();

    if (widget.onLongPress != null && !widget.isLoading) {
      // Start visual feedback animation
      _longPressAnimationController.forward();

      _longPressTimer = Timer(const Duration(milliseconds: 500), () {
        // Long-press detected - trigger action
        widget.onLongPress!();
        // Animation will stay at end state until user lifts finger,
        // then _onTapUp will reverse it back to normal
      });
    }
  }

  void _onTapUp(TapUpDetails details) {
    _longPressTimer?.cancel();
    // Reverse animation if long-press wasn't completed
    if (_longPressAnimationController.isAnimating ||
        _longPressAnimationController.value > 0) {
      _longPressAnimationController.reverse();
    }
  }

  void _onTapCancel() {
    _longPressTimer?.cancel();
    // Reverse animation if long-press was cancelled
    if (_longPressAnimationController.isAnimating ||
        _longPressAnimationController.value > 0) {
      _longPressAnimationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;

    if (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS) {
      return _buildCupertinoFab(context);
    }

    return _buildMaterialFab(context);
  }

  Widget _buildMaterialFab(BuildContext context) {
    // If we have a long press handler, create a custom FAB that handles
    // gestures properly
    if (widget.onLongPress != null) {
      return AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Material(
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
                // Keep these for safety,
                // but long-press above is the primary path
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
            ),
          );
        },
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

  Widget _buildCupertinoFab(BuildContext context) {
    // Cupertino does not have a direct FAB equivalent, so we create a custom
    // circular button that matches the Material FAB design while using
    // Cupertino interaction patterns (no ink ripple, no tooltip).
    final isDisabled = widget.isLoading || widget.onPressed == null;

    Widget fabContent = Opacity(
      opacity: isDisabled ? 0.5 : 1.0,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surface,
          border: Border.all(
            color: AppColors.border,
          ),
        ),
        child: _buildFabContent(),
      ),
    );

    // Apply scale animation if long-press is enabled
    if (widget.onLongPress != null) {
      fabContent = AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: fabContent,
      );
    }

    return GestureDetector(
      onTap: widget.isLoading ? null : widget.onPressed,
      onLongPress: widget.isLoading
          ? null
          : widget.onLongPress != null
          ? () {
              HapticFeedback.selectionClick();
              widget.onLongPress?.call();
            }
          : null,
      onTapDown: widget.onLongPress != null && !widget.isLoading
          ? _onTapDown
          : null,
      onTapUp: widget.onLongPress != null ? _onTapUp : null,
      onTapCancel: widget.onLongPress != null ? _onTapCancel : null,
      child: fabContent,
    );
  }

  Widget _buildFabContent() {
    if (widget.isLoading) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: HydraProgressIndicator(
          strokeWidth: 2,
          color: AppColors.primary,
        ),
      );
    }

    return Icon(
      widget.icon,
      size: 32, // Increased from 28 to make it stand out more
      color: AppColors.primary,
    );
  }
}

/// Platform-adaptive Extended FAB for more prominent actions.
///
/// Wraps [FloatingActionButton.extended] on Material platforms and a custom
/// Cupertino-style pill button on iOS/macOS, while preserving the extended
/// FAB design from the UI guidelines.
///
/// **Material (Android/others)**: Uses [FloatingActionButton.extended] with
/// Material styling and ink ripple effects. Supports glass morphism effect
/// via custom [BackdropFilter] implementation.
///
/// **Cupertino (iOS/macOS)**: Uses a custom pill-shaped button with Cupertino
/// styling. Glass morphism effect is supported on both platforms.
class HydraExtendedFab extends StatelessWidget {
  /// Creates a HydraExtendedFab.
  const HydraExtendedFab({
    required this.onPressed,
    required this.label,
    super.key,
    this.icon = Icons.water_drop,
    this.isLoading = false,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.useGlassEffect = false,
  });

  /// Callback function when FAB is pressed
  final VoidCallback? onPressed;

  /// Label text for the extended FAB
  final String label;

  /// Icon for the FAB
  final IconData icon;

  /// Whether to show loading state
  final bool isLoading;

  /// Background color for the FAB. Defaults to [AppColors.surface]
  final Color? backgroundColor;

  /// Foreground color for text and icon. Defaults to [AppColors.primary]
  final Color? foregroundColor;

  /// Elevation of the FAB. Defaults to 0
  final double? elevation;

  /// Whether to apply glass morphism effect (backdrop blur with
  /// semi-transparent background)
  final bool useGlassEffect;

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;

    if (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS) {
      return _buildCupertinoExtendedFab(context);
    }

    return _buildMaterialExtendedFab(context);
  }

  Widget _buildMaterialExtendedFab(BuildContext context) {
    final baseBackgroundColor =
        backgroundColor ?? AppColors.surface; // White background by default
    final baseForegroundColor =
        foregroundColor ?? AppColors.primary; // Teal text and icon by default

    if (!useGlassEffect) {
      // Standard FAB without glass effect
      return FloatingActionButton.extended(
        onPressed: isLoading ? null : onPressed,
        backgroundColor: baseBackgroundColor,
        foregroundColor: baseForegroundColor,
        elevation: elevation ?? 0,
        icon: _buildIcon(),
        label: _buildLabel(),
      );
    }

    // Apply glass morphism effect with custom widget
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: baseBackgroundColor.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: baseForegroundColor.withValues(
                alpha: 0.4,
              ),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: 0.05,
                ),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isLoading ? null : onPressed,
              borderRadius: BorderRadius.circular(999),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildIcon(),
                    const SizedBox(width: 8),
                    _buildLabel(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCupertinoExtendedFab(BuildContext context) {
    final baseBackgroundColor =
        backgroundColor ?? AppColors.surface; // White background by default
    final baseForegroundColor =
        foregroundColor ?? AppColors.primary; // Teal text and icon by default

    // Cupertino does not have a direct extended FAB equivalent, so we create
    // a custom pill-shaped button that matches the Material extended FAB
    // design while using Cupertino interaction patterns (no ink ripple).
    final content = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildIcon(),
          const SizedBox(width: 8),
          _buildLabel(),
        ],
      ),
    );

    if (useGlassEffect) {
      // Apply glass morphism effect with custom widget
      // (works on both platforms)
      return ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              color: baseBackgroundColor.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: baseForegroundColor.withValues(
                  alpha: 0.4,
                ),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: 0.05,
                  ),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: CupertinoButton(
              onPressed: isLoading ? null : onPressed,
              padding: EdgeInsets.zero,
              borderRadius: BorderRadius.circular(999),
              color: Colors.transparent,
              disabledColor: Colors.transparent,
              child: content,
            ),
          ),
        ),
      );
    }

    // Standard Cupertino button without glass effect
    final isDisabled = isLoading || onPressed == null;

    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: Opacity(
        opacity: isDisabled ? 0.5 : 1.0,
        child: Container(
          decoration: BoxDecoration(
            color: baseBackgroundColor,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: baseForegroundColor.withValues(alpha: 0.2),
            ),
          ),
          child: content,
        ),
      ),
    );
  }

  Widget _buildIcon() {
    final baseForegroundColor = foregroundColor ?? AppColors.primary;

    if (isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(baseForegroundColor),
        ),
      );
    }

    return Icon(icon, color: baseForegroundColor);
  }

  Widget _buildLabel() {
    if (isLoading) {
      return const Text('Loading...');
    }

    return Text(
      label,
      style: AppTextStyles.buttonPrimary.copyWith(
        color:
            foregroundColor ??
            AppColors.primary, // Use custom color or default to teal
      ),
    );
  }
}
