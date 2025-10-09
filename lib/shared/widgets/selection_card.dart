import 'package:flutter/material.dart';
import 'package:hydracat/core/constants/app_accessibility.dart';
import 'package:hydracat/core/constants/app_colors.dart';
import 'package:hydracat/core/theme/app_spacing.dart';
import 'package:hydracat/core/theme/app_text_styles.dart';

/// Layout options for the selection card
enum CardLayout {
  /// Square card for compact display
  square,

  /// Rectangle card for expanded display
  rectangle,
}

/// A generic selectable card component with 3D press effects and loading states
///
/// This widget provides a reusable card UI with:
/// - 3D press animations (elevation and scale)
/// - Loading overlay
/// - Customizable icon, title, and optional subtitle
/// - Square or rectangle layouts
/// - Selection state styling
///
/// Usage:
/// ```dart
/// SelectionCard(
///   icon: Icons.medication_outlined,
///   title: 'Track Medications',
///   subtitle: 'Set up medication schedules',
///   layout: CardLayout.rectangle,
///   onTap: () => context.push('/profile/medication'),
/// )
/// ```
class SelectionCard extends StatefulWidget {
  /// Creates a [SelectionCard]
  const SelectionCard({
    required this.icon,
    required this.title,
    required this.onTap,
    super.key,
    this.subtitle,
    this.layout = CardLayout.square,
    this.isSelected = false,
    this.isLoading = false,
    this.iconColor,
    this.iconBackgroundColor,
  });

  /// Icon to display in the card
  final IconData icon;

  /// Main title text
  final String title;

  /// Optional subtitle text (only shown in rectangle layout)
  final String? subtitle;

  /// Layout style for the card
  final CardLayout layout;

  /// Whether this card is currently selected
  final bool isSelected;

  /// Whether this card is in a loading state
  final bool isLoading;

  /// Custom icon color (defaults to primary color)
  final Color? iconColor;

  /// Custom icon background color (defaults to primary light with opacity)
  final Color? iconBackgroundColor;

  /// Callback when the card is tapped
  final VoidCallback onTap;

  @override
  State<SelectionCard> createState() => _SelectionCardState();
}

class _SelectionCardState extends State<SelectionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _elevationAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    // Elevation animation for 3D effect (2 -> 8 when pressed)
    _elevationAnimation =
        Tween<double>(
          begin: 2,
          end: 8,
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOut,
          ),
        );

    // Subtle scale animation for tactile feedback
    _scaleAnimation =
        Tween<double>(
          begin: 1,
          end: 0.98,
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOut,
          ),
        );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.isLoading) return;

    _animationController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.isLoading) return;

    _animationController.reverse();
  }

  void _onTapCancel() {
    if (widget.isLoading) return;

    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTap: widget.isLoading ? null : widget.onTap,
            onTapDown: _onTapDown,
            onTapUp: _onTapUp,
            onTapCancel: _onTapCancel,
            child: Material(
              elevation: _elevationAnimation.value,
              borderRadius: BorderRadius.circular(12),
              color: AppColors.surface,
              child: Container(
                constraints: const BoxConstraints(
                  minWidth: AppAccessibility.minTouchTarget,
                  minHeight: AppAccessibility.minTouchTarget,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.isSelected
                        ? AppColors.primary
                        : AppColors.border,
                    width: widget.isSelected ? 2 : 1,
                  ),
                ),
                child: Stack(
                  children: [
                    // Main content
                    Positioned.fill(
                      child: Padding(
                        padding: widget.layout == CardLayout.rectangle
                            ? const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.md,
                              )
                            : const EdgeInsets.all(AppSpacing.md),
                        child: Center(
                          child: _buildContent(),
                        ),
                      ),
                    ),

                    // Loading overlay
                    if (widget.isLoading) _buildLoadingOverlay(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent() {
    final isRectangle = widget.layout == CardLayout.rectangle;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icon container
        Container(
          width: isRectangle ? 56 : 40,
          height: isRectangle ? 56 : 40,
          decoration: BoxDecoration(
            color:
                widget.iconBackgroundColor ??
                AppColors.primaryLight.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            widget.icon,
            size: isRectangle ? 28 : 20,
            color: widget.iconColor ?? AppColors.primary,
          ),
        ),

        SizedBox(
          height: isRectangle ? AppSpacing.sm : AppSpacing.xs,
        ),

        // Title
        Text(
          widget.title,
          style: isRectangle
              ? AppTextStyles.body.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  height: 1.3,
                )
              : AppTextStyles.body.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  height: 1.2,
                ),
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),

        // Subtitle (only in rectangle layout)
        if (isRectangle && widget.subtitle != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            widget.subtitle!,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Widget _buildLoadingOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: AppColors.surface.withValues(alpha: 0.9),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }
}
