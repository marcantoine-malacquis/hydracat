import 'package:flutter/foundation.dart';

import 'package:hydracat/features/onboarding/models/onboarding_step.dart';

/// Overall progress tracking for the onboarding flow
@immutable
class OnboardingProgress {
  /// Creates an [OnboardingProgress] instance
  const OnboardingProgress({
    required this.currentStep,
    required this.steps,
    required this.startedAt,
    this.completedAt,
    this.userId,
    this.totalTimeSpent = Duration.zero,
  });

  /// Creates initial progress for a new onboarding session
  factory OnboardingProgress.initial({String? userId}) {
    final allSteps = OnboardingStepType.values
        .map(OnboardingStep.initial)
        .toList();

    return OnboardingProgress(
      currentStep: OnboardingStepType.welcome,
      steps: allSteps,
      startedAt: DateTime.now(),
      userId: userId,
    );
  }

  /// Creates an [OnboardingProgress] from JSON data
  factory OnboardingProgress.fromJson(Map<String, dynamic> json) {
    final stepsData = json['steps'] as List<dynamic>;
    final steps = stepsData
        .map(
          (stepData) =>
              OnboardingStep.fromJson(stepData as Map<String, dynamic>),
        )
        .toList();

    return OnboardingProgress(
      currentStep:
          OnboardingStepType.fromString(json['currentStep'] as String) ??
          OnboardingStepType.welcome,
      steps: steps,
      startedAt: DateTime.parse(json['startedAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      userId: json['userId'] as String?,
      totalTimeSpent: Duration(
        milliseconds: json['totalTimeSpentMs'] as int? ?? 0,
      ),
    );
  }

  /// Current step in the onboarding flow
  final OnboardingStepType currentStep;

  /// List of all steps with their completion status
  final List<OnboardingStep> steps;

  /// When the onboarding was started
  final DateTime startedAt;

  /// When the onboarding was completed (null if not completed)
  final DateTime? completedAt;

  /// User ID (if available)
  final String? userId;

  /// Total time spent in onboarding so far
  final Duration totalTimeSpent;

  /// Whether the onboarding flow is complete
  bool get isComplete => completedAt != null;

  /// Current step index (0-based)
  int get currentStepIndex => currentStep.stepIndex;

  /// Progress percentage (0.0 to 1.0)
  double get progressPercentage {
    final completedSteps = steps.where((step) => step.isCompleted).length;
    return completedSteps / OnboardingStepType.totalSteps;
  }

  /// Number of completed steps
  int get completedStepsCount => steps.where((step) => step.isCompleted).length;

  /// Current step details
  OnboardingStep get currentStepDetails {
    return steps.firstWhere(
      (step) => step.type == currentStep,
      orElse: () => OnboardingStep.initial(currentStep),
    );
  }

  /// Whether the current step is valid and can progress
  bool get canProgressFromCurrentStep => currentStepDetails.canProgress;

  /// Whether user can go back from current step
  bool get canGoBack => currentStep.canGoBack;

  /// Whether user can skip current step
  bool get canSkipCurrentStep => currentStep.canSkip;

  /// Next step in the flow (null if current is last)
  OnboardingStepType? get nextStep => currentStep.nextStep;

  /// Previous step in the flow (null if current is first)
  OnboardingStepType? get previousStep => currentStep.previousStep;

  /// Whether current step triggers a checkpoint save
  bool get isCurrentStepCheckpoint => currentStep.isCheckpoint;

  /// List of completed checkpoints
  List<OnboardingStepType> get completedCheckpoints {
    return steps
        .where((step) => step.isCompleted && step.type.isCheckpoint)
        .map((step) => step.type)
        .toList();
  }

  /// Time spent on current step (if started)
  Duration? get timeOnCurrentStep {
    final currentStepDetail = currentStepDetails;
    if (currentStepDetail.startedAt != null) {
      final endTime = currentStepDetail.completedAt ?? DateTime.now();
      return endTime.difference(currentStepDetail.startedAt!);
    }
    return null;
  }

  /// Total duration of completed onboarding (if complete)
  Duration? get totalDuration {
    if (completedAt != null) {
      return completedAt!.difference(startedAt);
    }
    return null;
  }

  /// Converts [OnboardingProgress] to JSON data
  Map<String, dynamic> toJson() {
    return {
      'currentStep': currentStep.name,
      'steps': steps.map((step) => step.toJson()).toList(),
      'startedAt': startedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'userId': userId,
      'totalTimeSpentMs': totalTimeSpent.inMilliseconds,
    };
  }

  /// Creates a copy of this [OnboardingProgress] with the given fields replaced
  OnboardingProgress copyWith({
    OnboardingStepType? currentStep,
    List<OnboardingStep>? steps,
    DateTime? startedAt,
    DateTime? completedAt,
    String? userId,
    Duration? totalTimeSpent,
  }) {
    return OnboardingProgress(
      currentStep: currentStep ?? this.currentStep,
      steps: steps ?? this.steps,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      userId: userId ?? this.userId,
      totalTimeSpent: totalTimeSpent ?? this.totalTimeSpent,
    );
  }

  /// Moves to the next step in the flow
  OnboardingProgress moveToNextStep() {
    final next = nextStep;
    if (next == null) return this;

    // Mark current step as completed if not already
    final updatedSteps = _updateStepInList(
      currentStepDetails.markCompleted(),
    );

    // Mark next step as started
    final nextStepDetails = updatedSteps.firstWhere(
      (step) => step.type == next,
    );
    final finalSteps = _updateStepInList(
      nextStepDetails.markStarted(),
      steps: updatedSteps,
    );

    return copyWith(
      currentStep: next,
      steps: finalSteps,
    );
  }

  /// Moves to the previous step in the flow
  OnboardingProgress moveToPreviousStep() {
    final previous = previousStep;
    if (previous == null || !canGoBack) return this;

    return copyWith(currentStep: previous);
  }

  /// Moves to a specific step
  OnboardingProgress moveToStep(OnboardingStepType step) {
    // Start the target step if not already started
    final targetStepDetails = steps.firstWhere(
      (s) => s.type == step,
      orElse: () => OnboardingStep.initial(step),
    );

    final updatedSteps = _updateStepInList(
      targetStepDetails.markStarted(),
    );

    return copyWith(
      currentStep: step,
      steps: updatedSteps,
    );
  }

  /// Updates the current step's validation status
  OnboardingProgress updateCurrentStepValidation({
    required bool isValid,
    List<String> validationErrors = const [],
  }) {
    final updatedStep = currentStepDetails.updateValidation(
      isValid: isValid,
      validationErrors: validationErrors,
    );

    return copyWith(
      steps: _updateStepInList(updatedStep),
    );
  }

  /// Marks the entire onboarding as completed
  OnboardingProgress markCompleted() {
    // Mark current step as completed
    final updatedSteps = _updateStepInList(
      currentStepDetails.markCompleted(),
    );

    return copyWith(
      steps: updatedSteps,
      completedAt: DateTime.now(),
    );
  }

  /// Updates total time spent
  OnboardingProgress updateTimeSpent(Duration additionalTime) {
    return copyWith(
      totalTimeSpent: totalTimeSpent + additionalTime,
    );
  }

  /// Helper method to update a specific step in the steps list
  List<OnboardingStep> _updateStepInList(
    OnboardingStep updatedStep, {
    List<OnboardingStep>? steps,
  }) {
    final stepsList = steps ?? this.steps;
    return stepsList.map((step) {
      return step.type == updatedStep.type ? updatedStep : step;
    }).toList();
  }

  /// Validates the entire progress state
  List<String> validate() {
    final errors = <String>[];

    // Check if current step exists in steps list
    final hasCurrentStep = steps.any((step) => step.type == currentStep);
    if (!hasCurrentStep) {
      errors.add('Current step not found in steps list');
    }

    // Check if all step types are represented
    for (final stepType in OnboardingStepType.values) {
      final hasStep = steps.any((step) => step.type == stepType);
      if (!hasStep) {
        errors.add('Missing step: ${stepType.displayName}');
      }
    }

    // Check completion consistency
    if (isComplete) {
      if (currentStep != OnboardingStepType.completion) {
        errors.add('Onboarding marked complete but not on completion step');
      }
    }

    return errors;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is OnboardingProgress &&
        other.currentStep == currentStep &&
        listEquals(other.steps, steps) &&
        other.startedAt == startedAt &&
        other.completedAt == completedAt &&
        other.userId == userId &&
        other.totalTimeSpent == totalTimeSpent;
  }

  @override
  int get hashCode {
    return Object.hash(
      currentStep,
      Object.hashAll(steps),
      startedAt,
      completedAt,
      userId,
      totalTimeSpent,
    );
  }

  @override
  String toString() {
    return 'OnboardingProgress('
        'currentStep: $currentStep, '
        'steps: ${steps.length}, '
        'startedAt: $startedAt, '
        'completedAt: $completedAt, '
        'userId: $userId, '
        'totalTimeSpent: $totalTimeSpent'
        ')';
  }
}
