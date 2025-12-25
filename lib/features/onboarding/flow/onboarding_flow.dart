/// Onboarding flow configuration and registry
///
/// Defines the complete onboarding flow with all steps, their order,
/// validation rules, and navigation behavior.
library;

import 'package:flutter/foundation.dart';
import 'package:hydracat/features/onboarding/flow/navigation_resolver.dart'
    as navigation_resolver;
import 'package:hydracat/features/onboarding/flow/onboarding_step_config.dart';
import 'package:hydracat/features/onboarding/models/onboarding_step_id.dart';
import 'package:hydracat/features/onboarding/validators/validators.dart';

/// Registry and configuration for the entire onboarding flow
///
/// This class holds the complete flow configuration, including all steps
/// and their properties. It provides methods to access steps and navigation
/// functionality through its navigation resolver.
@immutable
class OnboardingFlow implements navigation_resolver.OnboardingFlowInterface {
  /// Creates an [OnboardingFlow] with the given steps
  OnboardingFlow(this.steps);

  @override
  /// All steps in this flow (order matters for linear navigation)
  final List<OnboardingStepConfig> steps;

  /// Navigation resolver for this flow
  late final navigation_resolver.NavigationResolver navigationResolver =
      navigation_resolver.NavigationResolver(this);

  @override
  /// Gets a step configuration by ID
  ///
  /// Returns null if no step with the given ID exists in this flow.
  OnboardingStepConfig? getStep(OnboardingStepId stepId) {
    final index = steps.indexWhere((step) => step.id == stepId);
    return index == -1 ? null : steps[index];
  }

  /// Gets a step by route
  ///
  /// Returns null if no step with the given route exists in this flow.
  /// Useful for handling deep links or router redirects.
  OnboardingStepConfig? getStepByRoute(String route) {
    final index = steps.indexWhere((step) => step.route == route);
    return index == -1 ? null : steps[index];
  }

  /// Total number of steps (including invisible ones)
  int get totalSteps => steps.length;

  /// First step in the flow
  OnboardingStepConfig get firstStep => steps.first;

  /// Last step in the flow
  OnboardingStepConfig get lastStep => steps.last;
}

/// Default onboarding flow configuration
///
/// Defines the standard 4-step onboarding flow:
/// 1. Welcome - Introduction with skip option
/// 2. Pet Basics - Required pet information (name, age, gender)
/// 3. Medical Info - Optional CKD medical information
/// 4. Completion - Final step before creating pet profile
final defaultOnboardingFlow = OnboardingFlow(const [
  // Step 1: Welcome
  OnboardingStepConfig(
    id: OnboardingSteps.welcome,
    displayName: 'Welcome',
    route: '/onboarding/welcome',
    analyticsEventName: 'onboarding_welcome_viewed',
    canSkip: true,
    canGoBack: false,
  ),

  // Step 2: Pet Basics (Required)
  OnboardingStepConfig(
    id: OnboardingSteps.petBasics,
    displayName: 'Pet Information',
    route: '/onboarding/basics',
    analyticsEventName: 'onboarding_basics_viewed',
    isCheckpoint: true, // Auto-save after this step
    validator: PetBasicsValidator(),
  ),

  // Step 3: CKD Medical Info (Optional)
  OnboardingStepConfig(
    id: OnboardingSteps.medicalInfo,
    displayName: 'Medical Information',
    route: '/onboarding/medical',
    analyticsEventName: 'onboarding_medical_viewed',
    canSkip: true,
  ),

  // Step 4: Completion
  OnboardingStepConfig(
    id: OnboardingSteps.completion,
    displayName: 'Complete',
    route: '/onboarding/completion',
    analyticsEventName: 'onboarding_completion_viewed',
    isCheckpoint: true, // Save before final submission
    validator: CompletionValidator(),
  ),
]);

/// Provider function for accessing the onboarding flow
///
/// This allows for easy testing by injecting different flow configurations,
/// and future expansion for A/B testing or remote configuration.
OnboardingFlow getOnboardingFlow() => defaultOnboardingFlow;
