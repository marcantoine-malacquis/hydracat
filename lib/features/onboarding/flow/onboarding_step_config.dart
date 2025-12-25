/// Step configuration model for declarative onboarding flow
///
/// Defines all properties and behaviors for a single onboarding step,
/// including validation, navigation, and visibility rules.
library;

import 'package:flutter/foundation.dart';
import 'package:hydracat/features/onboarding/flow/step_validator.dart';
import 'package:hydracat/features/onboarding/models/onboarding_data.dart';
import 'package:hydracat/features/onboarding/models/onboarding_step_id.dart';

/// Type for navigation resolver function
///
/// Given the current onboarding data, returns the ID of the next step
/// to navigate to, or null if there is no next step.
typedef NavigationResolver = OnboardingStepId? Function(OnboardingData data);

/// Type for step visibility condition
///
/// Given the current onboarding data, returns true if this step should
/// be shown in the flow, false if it should be skipped.
typedef StepVisibilityCondition = bool Function(OnboardingData data);

/// Configuration for a single onboarding step
///
/// This is an immutable configuration object that defines all aspects
/// of an onboarding step: its identity, display properties, validation
/// rules, and navigation behavior.
@immutable
class OnboardingStepConfig {
  /// Creates an [OnboardingStepConfig]
  const OnboardingStepConfig({
    required this.id,
    required this.displayName,
    required this.route,
    required this.analyticsEventName,
    this.canSkip = false,
    this.canGoBack = true,
    this.isCheckpoint = false,
    this.validator = const AlwaysValidValidator(),
    this.visibilityCondition,
    this.navigationResolver,
  });

  /// Unique identifier for this step
  final OnboardingStepId id;

  /// User-friendly display name shown in the UI
  final String displayName;

  /// GoRouter route path (e.g., '/onboarding/welcome')
  final String route;

  /// Firebase Analytics event name for this step
  final String analyticsEventName;

  /// Whether this step can be skipped by the user
  final bool canSkip;

  /// Whether user can navigate back from this step
  final bool canGoBack;

  /// Whether this step triggers automatic checkpoint save
  ///
  /// When true, onboarding progress will be saved to local storage
  /// after completing this step, allowing users to resume from here.
  final bool isCheckpoint;

  /// Validator for this step's data requirements
  ///
  /// Defines what data must be present and valid before progressing
  /// from this step.
  final StepValidator validator;

  /// Optional condition to determine if step should be shown
  ///
  /// If null, step is always shown. If provided, the function is called
  /// with the current onboarding data and should return true to show
  /// the step, false to skip it.
  final StepVisibilityCondition? visibilityCondition;

  /// Optional custom navigation logic
  ///
  /// If null, uses default linear navigation from the flow. If provided,
  /// this function is called to determine the next step based on the
  /// current onboarding data.
  final NavigationResolver? navigationResolver;

  /// Whether this step should be shown based on current data
  bool isVisible(OnboardingData data) {
    return visibilityCondition?.call(data) ?? true;
  }

  /// Validates data for this step
  bool isValid(OnboardingData data) {
    return validator.isValid(data);
  }

  /// Gets missing required fields for this step
  List<String> getMissingFields(OnboardingData data) {
    return validator.getMissingFields(data);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OnboardingStepConfig && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'StepConfig($id)';
}
