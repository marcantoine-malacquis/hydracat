import 'package:flutter/material.dart';
import 'package:hydracat/core/constants/app_colors.dart';
import 'package:hydracat/core/theme/app_spacing.dart';
import 'package:hydracat/core/theme/app_text_styles.dart';
import 'package:hydracat/shared/widgets/buttons/hydra_button.dart';

/// A reusable empty state widget that encourages users to complete onboarding
///
/// This widget is used across different screens to show users what they're
/// missing when they haven't completed the onboarding flow, with a clear
/// call-to-action to start or complete onboarding.
class OnboardingCtaEmptyState extends StatelessWidget {
  /// Creates an [OnboardingCtaEmptyState] widget
  ///
  /// [title] is the main heading text
  /// [subtitle] provides additional context about what completing
  /// onboarding unlocks
  /// [ctaText] is the text shown on the action button
  /// [onGetStarted] is called when the user taps the action button
  /// [icon] is an optional icon to display above the title
  /// [illustration] is an optional custom illustration widget
  const OnboardingCtaEmptyState({
    required this.title,
    required this.subtitle,
    required this.ctaText,
    required this.onGetStarted,
    this.icon,
    this.illustration,
    super.key,
  });

  /// The main heading text
  final String title;

  /// Additional context about what completing onboarding unlocks
  final String subtitle;

  /// Text shown on the action button
  final String ctaText;

  /// Called when the user taps the action button
  final VoidCallback onGetStarted;

  /// Optional icon to display above the title
  final IconData? icon;

  /// Optional custom illustration widget to replace the default icon
  final Widget? illustration;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustration or icon
            _buildVisual(context),

            const SizedBox(height: AppSpacing.xl),

            // Title
            Text(
              title,
              style: AppTextStyles.h2.copyWith(
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppSpacing.md),

            // Subtitle
            Text(
              subtitle,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppSpacing.xl),

            // Call-to-action button
            SizedBox(
              width: 200,
              child: HydraButton(
                onPressed: onGetStarted,
                child: Text(ctaText),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the visual element (illustration or icon)
  Widget _buildVisual(BuildContext context) {
    if (illustration != null) {
      return illustration!;
    }

    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(60),
        border: Border.all(
          color: AppColors.primaryLight.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Icon(
        icon ?? Icons.pets,
        size: 60,
        color: AppColors.primary.withValues(alpha: 0.7),
      ),
    );
  }
}

/// Predefined empty state configurations for common use cases
class OnboardingEmptyStates {
  OnboardingEmptyStates._();

  /// Empty state for the home screen when onboarding is not complete
  static Widget home({required VoidCallback onGetStarted}) {
    return OnboardingCtaEmptyState(
      title: 'Welcome to HydraCat!',
      subtitle:
          "Complete setup to start tracking your cat's CKD journey "
          'and unlock personalized care features.',
      ctaText: 'Complete Setup',
      onGetStarted: onGetStarted,
      icon: Icons.home_rounded,
    );
  }

  /// Empty state for the progress screen when onboarding is not complete
  static Widget progress({required VoidCallback onGetStarted}) {
    return OnboardingCtaEmptyState(
      title: 'Track Your Progress',
      subtitle:
          'Set up your pet profile to start tracking treatment '
          'progress, streaks, and health trends.',
      ctaText: 'Set Up Profile',
      onGetStarted: onGetStarted,
      icon: Icons.trending_up_rounded,
    );
  }

  /// Empty state for the profile screen when onboarding is not complete
  static Widget profile({required VoidCallback onGetStarted}) {
    return OnboardingCtaEmptyState(
      title: 'Create Pet Profile',
      subtitle:
          'Tell us about your cat to get personalized CKD management '
          'recommendations and treatment tracking.',
      ctaText: 'Create Profile',
      onGetStarted: onGetStarted,
      icon: Icons.pets_rounded,
    );
  }

  /// Empty state for logging when onboarding is not complete
  static Widget logging({required VoidCallback onGetStarted}) {
    return OnboardingCtaEmptyState(
      title: 'Ready to Log Treatments?',
      subtitle:
          'Complete setup first to unlock treatment logging and '
          "track your cat's health journey.",
      ctaText: 'Complete Setup',
      onGetStarted: onGetStarted,
      icon: Icons.add_circle_rounded,
    );
  }

  /// Empty state with custom illustration
  static Widget custom({
    required String title,
    required String subtitle,
    required String ctaText,
    required VoidCallback onGetStarted,
    Widget? illustration,
    IconData? icon,
  }) {
    return OnboardingCtaEmptyState(
      title: title,
      subtitle: subtitle,
      ctaText: ctaText,
      onGetStarted: onGetStarted,
      illustration: illustration,
      icon: icon,
    );
  }
}
