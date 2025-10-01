import 'package:flutter/material.dart';
import 'package:hydracat/core/constants/app_accessibility.dart';
import 'package:hydracat/core/constants/app_colors.dart';
import 'package:hydracat/core/theme/app_spacing.dart';
import 'package:hydracat/core/theme/app_text_styles.dart';
import 'package:hydracat/features/profile/models/user_persona.dart';

/// Layout options for the persona selection card
enum CardLayout {
  /// Square card for compact display
  square,

  /// Rectangle card for expanded display
  rectangle,
}

/// A selectable card component for displaying user treatment personas
/// with 3D press effects and loading states
class PersonaSelectionCard extends StatefulWidget {
  /// Creates a [PersonaSelectionCard]
  const PersonaSelectionCard({
    required this.persona,
    required this.onTap,
    super.key,
    this.layout = CardLayout.square,
    this.isSelected = false,
    this.isLoading = false,
  });

  /// The treatment persona this card represents
  final UserPersona persona;

  /// Layout style for the card
  final CardLayout layout;

  /// Whether this card is currently selected
  final bool isSelected;

  /// Whether this card is in a loading state
  final bool isLoading;

  /// Callback when the card is tapped
  final VoidCallback onTap;

  @override
  State<PersonaSelectionCard> createState() => _PersonaSelectionCardState();
}

class _PersonaSelectionCardState extends State<PersonaSelectionCard>
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icon placeholder for future illustrations
        Container(
          width: widget.layout == CardLayout.square ? 40 : 56,
          height: widget.layout == CardLayout.square ? 40 : 56,
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getPersonaIcon(),
            size: widget.layout == CardLayout.square ? 20 : 28,
            color: AppColors.primary,
          ),
        ),

        SizedBox(
          height: widget.layout == CardLayout.square
              ? AppSpacing.xs
              : AppSpacing.sm,
        ),

        // Title
        Text(
          _getPersonaTitle(),
          style: widget.layout == CardLayout.square
              ? AppTextStyles.body.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  height: 1.2,
                )
              : AppTextStyles.body.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  height: 1.3,
                ),
          textAlign: TextAlign.center,
          maxLines: widget.layout == CardLayout.square ? 3 : 3,
          overflow: TextOverflow.ellipsis,
        ),
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

  IconData _getPersonaIcon() {
    return switch (widget.persona) {
      UserPersona.medicationOnly => Icons.medication_outlined,
      UserPersona.fluidTherapyOnly => Icons.water_drop_outlined,
      UserPersona.medicationAndFluidTherapy => Icons.healing_outlined,
    };
  }

  String _getPersonaTitle() {
    return switch (widget.persona) {
      UserPersona.medicationOnly => 'Medication\nOnly',
      UserPersona.fluidTherapyOnly => 'Fluid Therapy\nOnly',
      UserPersona.medicationAndFluidTherapy =>
        'Medication &\nFluid Therapy',
    };
  }
}
