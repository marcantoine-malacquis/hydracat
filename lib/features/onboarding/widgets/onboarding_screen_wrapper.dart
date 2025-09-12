import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/core/constants/app_colors.dart';
import 'package:hydracat/core/theme/app_spacing.dart';
import 'package:hydracat/core/theme/app_text_styles.dart';
import 'package:hydracat/features/onboarding/models/onboarding_step.dart';
import 'package:hydracat/features/onboarding/widgets/onboarding_progress_indicator.dart';
import 'package:hydracat/providers/analytics_provider.dart';
import 'package:hydracat/shared/widgets/buttons/hydra_button.dart';

/// A wrapper widget that provides consistent layout and navigation for 
/// onboarding screens with automatic analytics tracking.
class OnboardingScreenWrapper extends ConsumerStatefulWidget {
  /// Creates an [OnboardingScreenWrapper].
  const OnboardingScreenWrapper({
    required this.child,
    required this.currentStep,
    required this.totalSteps,
    super.key,
    this.title,
    this.subtitle,
    this.onBackPressed,
    this.onNextPressed,
    this.nextButtonText = 'Next',
    this.backButtonText = 'Back',
    this.showBackButton = true,
    this.showNextButton = true,
    this.nextButtonEnabled = true,
    this.isLoading = false,
    this.skipAction,
    this.stepName,
  });

  /// The main content of the screen
  final Widget child;

  /// Current step index (0-based)
  final int currentStep;

  /// Total number of steps
  final int totalSteps;

  /// Optional title for the screen
  final String? title;

  /// Optional subtitle for the screen
  final String? subtitle;

  /// Callback for back button press
  final VoidCallback? onBackPressed;

  /// Callback for next button press
  final VoidCallback? onNextPressed;

  /// Text for the next button
  final String nextButtonText;

  /// Text for the back button
  final String backButtonText;

  /// Whether to show the back button
  final bool showBackButton;

  /// Whether to show the next button
  final bool showNextButton;

  /// Whether the next button is enabled
  final bool nextButtonEnabled;

  /// Whether to show loading state
  final bool isLoading;

  /// Optional skip action widget (usually for welcome screen)
  final Widget? skipAction;

  /// Optional step name for analytics tracking
  final String? stepName;

  @override
  ConsumerState<OnboardingScreenWrapper> createState() => 
      _OnboardingScreenWrapperState();
}

class _OnboardingScreenWrapperState 
    extends ConsumerState<OnboardingScreenWrapper> {
  late DateTime _screenStartTime;
  AnalyticsService? _analyticsService;

  @override
  void initState() {
    super.initState();
    _screenStartTime = DateTime.now();
    _analyticsService = ref.read(analyticsServiceDirectProvider);
    _trackScreenView();
  }

  @override
  void dispose() {
    _trackScreenTiming();
    super.dispose();
  }

  void _trackScreenView() {
    final stepName = widget.stepName ?? 'step_${widget.currentStep}';
    
    _analyticsService?.trackScreenView(
      screenName: 'onboarding_$stepName',
      screenClass: 'OnboardingScreen',
    );
  }

  void _trackScreenTiming() {
    if (!mounted || _analyticsService == null) return;
    
    final duration = DateTime.now().difference(_screenStartTime);
    final stepName = widget.stepName ?? 'step_${widget.currentStep}';
    
    // Track as a feature usage with timing data
    _analyticsService!.trackFeatureUsed(
      featureName: 'onboarding_screen_timing',
      additionalParams: {
        'step_name': stepName,
        'step_index': widget.currentStep,
        'duration_seconds': duration.inSeconds,
        'duration_milliseconds': duration.inMilliseconds,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header with progress indicator
            _buildHeader(),
            
            // Main content area
            Expanded(
              child: _buildContent(),
            ),
            
            // Navigation buttons
            _buildNavigation(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          // Progress indicator
          OnboardingProgressIndicator(
            currentStep: widget.currentStep,
            totalSteps: widget.totalSteps,
          ),
          
          if (widget.title != null) ...[
            const SizedBox(height: AppSpacing.xl),
            Text(
              widget.title!,
              style: AppTextStyles.h1.copyWith(
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          
          if (widget.subtitle != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              widget.subtitle!,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          
          if (widget.skipAction != null) ...[
            const SizedBox(height: AppSpacing.lg),
            widget.skipAction!,
          ],
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: widget.child,
    );
  }

  Widget _buildNavigation() {
    // Don't show navigation if both buttons are hidden
    if (!widget.showBackButton && !widget.showNextButton) {
      return const SizedBox(height: AppSpacing.lg);
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(
            color: AppColors.border,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Back button or spacer
            if (widget.showBackButton && widget.onBackPressed != null)
              Expanded(
                child: HydraButton(
                  onPressed: widget.isLoading ? null : widget.onBackPressed,
                  variant: HydraButtonVariant.secondary,
                  child: Text(widget.backButtonText),
                ),
              )
            else
              const Expanded(child: SizedBox()),

            // Spacing between buttons
            if (widget.showBackButton && widget.showNextButton) 
              const SizedBox(width: AppSpacing.md),

            // Next button or spacer
            if (widget.showNextButton && widget.onNextPressed != null)
              Expanded(
                child: HydraButton(
                  onPressed: (widget.isLoading || !widget.nextButtonEnabled) 
                      ? null 
                      : widget.onNextPressed,
                  child: Text(widget.nextButtonText),
                ),
              )
            else
              const Expanded(child: SizedBox()),
          ],
        ),
      ),
    );
  }
}

/// A specialized wrapper for the welcome screen that includes skip
/// functionality
class OnboardingWelcomeWrapper extends StatelessWidget {
  /// Creates an [OnboardingWelcomeWrapper].
  const OnboardingWelcomeWrapper({
    required this.child,
    required this.onGetStarted,
    super.key,
    this.title,
    this.subtitle,
    this.onSkip,
  });

  /// The main content of the screen
  final Widget child;

  /// Title of the welcome screen
  final String? title;

  /// Subtitle of the welcome screen
  final String? subtitle;

  /// Callback for "Get Started" button
  final VoidCallback onGetStarted;

  /// Optional callback for skip action
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    return OnboardingScreenWrapper(
      currentStep: 0,
      totalSteps: OnboardingStepType.totalSteps,
      title: title,
      subtitle: subtitle,
      showBackButton: false,
      nextButtonText: 'Get Started',
      onNextPressed: onGetStarted,
      stepName: 'welcome',
      skipAction: onSkip != null
          ? _buildSkipButton()
          : null,
      child: child,
    );
  }

  Widget _buildSkipButton() {
    return TextButton(
      onPressed: onSkip,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.textTertiary,
        textStyle: AppTextStyles.caption,
      ),
      child: const Text(
"Skip for now\n(You'll have limited access to tracking "
        'features until you complete setup)',
        textAlign: TextAlign.center,
      ),
    );
  }
}
