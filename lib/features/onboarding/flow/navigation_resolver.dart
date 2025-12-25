/// Navigation resolver for dynamic onboarding flow
///
/// Handles navigation between steps based on flow configuration and
/// user data, supporting both linear and conditional navigation.
library;

import 'package:hydracat/features/onboarding/flow/onboarding_step_config.dart';
import 'package:hydracat/features/onboarding/models/onboarding_data.dart';
import 'package:hydracat/features/onboarding/models/onboarding_step_id.dart';

/// Abstract interface for onboarding flow
/// (to avoid circular dependency with onboarding_flow.dart)
abstract class OnboardingFlowInterface {
  /// All steps in this flow
  List<OnboardingStepConfig> get steps;

  /// Gets a step configuration by ID
  OnboardingStepConfig? getStep(OnboardingStepId stepId);
}

/// Resolves navigation between onboarding steps
///
/// This class encapsulates all the logic for determining which step
/// comes next or previous, handling both linear navigation and
/// conditional branching based on user data.
class NavigationResolver {
  /// Creates a [NavigationResolver] for the given flow
  const NavigationResolver(this._flow);

  final OnboardingFlowInterface _flow;

  /// Gets the next step from the current step based on data
  ///
  /// Returns the ID of the next step to navigate to, or null if:
  /// - Current step is the last step
  /// - No visible next step exists
  /// - Current step configuration is not found
  ///
  /// Supports both custom navigation resolvers (defined in step config)
  /// and default linear navigation to the next visible step.
  OnboardingStepId? getNextStep(
    OnboardingStepId currentStepId,
    OnboardingData data,
  ) {
    final currentStep = _flow.getStep(currentStepId);
    if (currentStep == null) return null;

    // Use custom navigation resolver if defined
    if (currentStep.navigationResolver != null) {
      return currentStep.navigationResolver!(data);
    }

    // Default: linear navigation to next visible step
    final currentIndex = _flow.steps.indexOf(currentStep);
    if (currentIndex == -1 || currentIndex >= _flow.steps.length - 1) {
      return null; // At last step
    }

    // Find next visible step
    for (var i = currentIndex + 1; i < _flow.steps.length; i++) {
      final nextStep = _flow.steps[i];
      if (nextStep.isVisible(data)) {
        return nextStep.id;
      }
    }

    return null; // No visible next step
  }

  /// Gets the previous step from the current step
  ///
  /// Returns the ID of the previous step to navigate to, or null if:
  /// - Current step doesn't allow going back (canGoBack == false)
  /// - Current step is the first step
  /// - No visible previous step exists
  /// - Current step configuration is not found
  OnboardingStepId? getPreviousStep(
    OnboardingStepId currentStepId,
    OnboardingData data,
  ) {
    final currentStep = _flow.getStep(currentStepId);
    if (currentStep == null || !currentStep.canGoBack) {
      return null;
    }

    final currentIndex = _flow.steps.indexOf(currentStep);
    if (currentIndex <= 0) {
      return null; // At first step
    }

    // Find previous visible step
    for (var i = currentIndex - 1; i >= 0; i--) {
      final prevStep = _flow.steps[i];
      if (prevStep.isVisible(data)) {
        return prevStep.id;
      }
    }

    return null; // No visible previous step
  }

  /// Gets all visible steps in the flow
  ///
  /// Returns a list of step configurations that are currently visible
  /// based on the provided onboarding data. Steps with visibility
  /// conditions that evaluate to false are excluded.
  List<OnboardingStepConfig> getVisibleSteps(OnboardingData data) {
    return _flow.steps.where((step) => step.isVisible(data)).toList();
  }

  /// Calculates progress percentage based on visible steps
  ///
  /// Returns a value between 0.0 and 1.0 representing how far through
  /// the onboarding flow the user is, based on visible steps only.
  ///
  /// For example, if there are 4 visible steps and the user is on step 2,
  /// this returns 0.5 (50%).
  double calculateProgress(
    OnboardingStepId currentStepId,
    OnboardingData data,
  ) {
    final visibleSteps = getVisibleSteps(data);
    if (visibleSteps.isEmpty) return 0;

    final currentIndex =
        visibleSteps.indexWhere((step) => step.id == currentStepId);

    if (currentIndex == -1) return 0;

    return (currentIndex + 1) / visibleSteps.length;
  }

  /// Gets the route for a step ID
  ///
  /// Returns the GoRouter route path for the given step ID,
  /// or null if the step is not found in the flow.
  String? getRoute(OnboardingStepId stepId) {
    return _flow.getStep(stepId)?.route;
  }
}
