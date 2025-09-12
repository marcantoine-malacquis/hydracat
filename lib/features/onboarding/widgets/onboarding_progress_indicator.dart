import 'package:flutter/material.dart';
import 'package:hydracat/core/constants/app_colors.dart';
import 'package:hydracat/core/theme/app_spacing.dart';

/// A progress indicator widget for the onboarding flow.
/// Dynamically shows dots representing all onboarding screens with animated 
/// transitions.
class OnboardingProgressIndicator extends StatefulWidget {
  /// Creates an [OnboardingProgressIndicator].
  const OnboardingProgressIndicator({
    required this.currentStep,
    required this.totalSteps,
    super.key,
  });

  /// The current step (0-based index)
  final int currentStep;

  /// Total number of steps in the onboarding flow
  final int totalSteps;

  @override
  State<OnboardingProgressIndicator> createState() =>
      _OnboardingProgressIndicatorState();
}

class _OnboardingProgressIndicatorState
    extends State<OnboardingProgressIndicator>
    with TickerProviderStateMixin {
  late AnimationController _sizeController;
  late AnimationController _fillController;
  late List<Animation<double>> _sizeAnimations;
  late List<Animation<double>> _fillAnimations;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  @override
  void didUpdateWidget(OnboardingProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentStep != widget.currentStep) {
      _updateAnimations();
    }
  }

  void _initializeAnimations() {
    _sizeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fillController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    _sizeAnimations = List.generate(
      widget.totalSteps,
      (index) => Tween<double>(
        begin: _getDotSize(index, widget.currentStep),
        end: _getDotSize(index, widget.currentStep),
      ).animate(
        CurvedAnimation(
          parent: _sizeController,
          curve: Curves.easeInOut,
        ),
      ),
    );

    _fillAnimations = List.generate(
      widget.totalSteps,
      (index) => Tween<double>(
        begin: _getFillValue(index, widget.currentStep),
        end: _getFillValue(index, widget.currentStep),
      ).animate(
        CurvedAnimation(
          parent: _fillController,
          curve: Curves.easeInOut,
        ),
      ),
    );
  }

  void _updateAnimations() {
    // Update size animations
    for (var i = 0; i < widget.totalSteps; i++) {
      _sizeAnimations[i] = Tween<double>(
        begin: _sizeAnimations[i].value,
        end: _getDotSize(i, widget.currentStep),
      ).animate(
        CurvedAnimation(
          parent: _sizeController,
          curve: Curves.easeInOut,
        ),
      );
    }

    // Update fill animations
    for (var i = 0; i < widget.totalSteps; i++) {
      _fillAnimations[i] = Tween<double>(
        begin: _fillAnimations[i].value,
        end: _getFillValue(i, widget.currentStep),
      ).animate(
        CurvedAnimation(
          parent: _fillController,
          curve: Curves.easeInOut,
        ),
      );
    }

    // Start animations
    _sizeController
      ..reset()
      ..forward();
    
    _fillController
      ..reset()
      ..forward();
  }

  double _getDotSize(int index, int currentStep) {
    // Current step is bigger (16px), others are normal (12px)
    return index == currentStep ? 16.0 : 12.0;
  }

  double _getFillValue(int index, int currentStep) {
    // Steps before current are filled (1.0), current and after are empty (0.0)
    return index < currentStep ? 1.0 : 0.0;
  }

  @override
  void dispose() {
    _sizeController.dispose();
    _fillController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_sizeController, _fillController]),
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            widget.totalSteps,
            _buildProgressDot,
          ),
        );
      },
    );
  }

  Widget _buildProgressDot(int index) {
    final isLast = index == widget.totalSteps - 1;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ProgressDot(
          size: _sizeAnimations[index].value,
          fillProgress: _fillAnimations[index].value,
          isCurrentStep: index == widget.currentStep,
        ),
        if (!isLast) 
          const SizedBox(width: AppSpacing.sm), // 8px spacing between dots
      ],
    );
  }
}

/// Individual progress dot widget with animation support
class _ProgressDot extends StatelessWidget {
  const _ProgressDot({
    required this.size,
    required this.fillProgress,
    required this.isCurrentStep,
  });

  final double size;
  final double fillProgress;
  final bool isCurrentStep;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.primary,
          width: 2,
        ),
        color: Color.lerp(
          Colors.transparent,
          AppColors.primary,
          fillProgress,
        ),
        // Add subtle shadow for current step
        boxShadow: isCurrentStep
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
    );
  }
}
