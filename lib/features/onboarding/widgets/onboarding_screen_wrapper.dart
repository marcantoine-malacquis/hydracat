import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/core/constants/app_colors.dart';
import 'package:hydracat/core/theme/app_spacing.dart';
import 'package:hydracat/core/theme/app_text_styles.dart';
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
    this.showProgressInAppBar = false,
    this.appBarActions,
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

  /// Whether to show the progress indicator in the app bar instead of header
  final bool showProgressInAppBar;

  /// Optional actions to show in the app bar (e.g., Skip button)
  final List<Widget>? appBarActions;

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
      appBar: _buildAppBar(),
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

  PreferredSizeWidget? _buildAppBar() {
    // Show app bar if we have a back button OR if showing progress in app bar
    // OR if we have actions
    if (!widget.showProgressInAppBar &&
        (!widget.showBackButton || widget.onBackPressed == null) &&
        (widget.appBarActions?.isEmpty ?? true)) {
      return null;
    }

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: (widget.showBackButton && widget.onBackPressed != null)
          ? IconButton(
              onPressed: widget.isLoading ? null : widget.onBackPressed,
              icon: const Icon(Icons.arrow_back_ios),
              iconSize: 20,
              color: AppColors.textSecondary,
              tooltip: widget.backButtonText,
            )
          : null,
      title: widget.showProgressInAppBar
          ? OnboardingProgressIndicator(
              currentStep: widget.currentStep,
              totalSteps: widget.totalSteps,
            )
          : null,
      centerTitle: true,
      actions: widget.appBarActions,
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          // Progress indicator (only show if not in app bar)
          if (!widget.showProgressInAppBar)
            OnboardingProgressIndicator(
              currentStep: widget.currentStep,
              totalSteps: widget.totalSteps,
            ),

          if (widget.title != null) ...[
            SizedBox(height: widget.showProgressInAppBar ? 0 : AppSpacing.xl),
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

          // Only show skipAction in header if not using app bar actions
          if (widget.skipAction != null &&
              (widget.appBarActions?.isEmpty ?? true)) ...[
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
    // Don't show bottom navigation if both buttons are hidden
    if (!widget.showBackButton && !widget.showNextButton) {
      return const SizedBox(height: AppSpacing.lg);
    }

    // If only back button is shown and we have app bar,
    // don't show bottom navigation
    if (widget.showBackButton &&
        !widget.showNextButton &&
        widget.onBackPressed != null) {
      return const SizedBox(height: AppSpacing.lg);
    }

    // Show bottom navigation for next button or when both buttons are needed
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
            // Back button or spacer (only if no app bar back button)
            if (widget.showBackButton &&
                widget.onBackPressed != null &&
                widget.showNextButton)
              Expanded(
                child: HydraButton(
                  onPressed: widget.isLoading ? null : widget.onBackPressed,
                  variant: HydraButtonVariant.secondary,
                  isFullWidth: true,
                  size: HydraButtonSize.large,
                  child: Text(widget.backButtonText),
                ),
              )
            else if (widget.showNextButton)
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
                  isFullWidth: true,
                  size: HydraButtonSize.large,
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
