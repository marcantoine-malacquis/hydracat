import 'package:flutter/foundation.dart';

import 'package:hydracat/features/onboarding/migration/step_type_migration.dart';
import 'package:hydracat/features/onboarding/models/onboarding_step.dart';
import 'package:hydracat/features/onboarding/models/onboarding_step_id.dart';

/// Overall progress tracking for the onboarding flow
@immutable
class OnboardingProgress {
  /// Creates an [OnboardingProgress] instance
  const OnboardingProgress({
    required this.currentStepId,
    required this.steps,
    required this.startedAt,
    this.completedAt,
    this.userId,
    this.totalTimeSpent = Duration.zero,
  });

  /// Creates initial progress for a new onboarding session
  factory OnboardingProgress.initial({String? userId}) {
    final allSteps = OnboardingSteps.all
        .map(OnboardingStep.initial)
        .toList();

    // Mark welcome step as started and valid since user is already
    // on that screen and it has no validation requirements
    final welcomeStepIndex = allSteps.indexWhere(
      (step) => step.id == OnboardingSteps.welcome,
    );
    if (welcomeStepIndex != -1) {
      allSteps[welcomeStepIndex] = allSteps[welcomeStepIndex]
          .markStarted()
          .updateValidation(isValid: true);
    }

    return OnboardingProgress(
      currentStepId: OnboardingSteps.welcome,
      steps: allSteps,
      startedAt: DateTime.now(),
      userId: userId,
    );
  }

  /// Creates an [OnboardingProgress] from JSON data with migration support
  factory OnboardingProgress.fromJson(Map<String, dynamic> json) {
    // Support both old 'currentStep' field and new 'currentStepId' field
    final currentStepData = json['currentStepId'] ?? json['currentStep'];
    OnboardingStepId currentStepId;

    if (currentStepData is String) {
      // Parse step ID (handles both old and new formats)
      currentStepId = StepTypeMigration.parseStepId(currentStepData);
    } else {
      // Fallback to welcome
      currentStepId = OnboardingSteps.welcome;
    }

    final stepsData = json['steps'] as List<dynamic>;
    final steps = stepsData
        .map(
          (stepData) =>
              OnboardingStep.fromJson(stepData as Map<String, dynamic>),
        )
        .toList();

    return OnboardingProgress(
      currentStepId: currentStepId,
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

  /// Current step ID in the onboarding flow
  final OnboardingStepId currentStepId;

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

  /// Progress percentage (0.0 to 1.0)
  ///
  /// Note: This is based on total steps in the flow. For dynamic progress
  /// based on visible steps, use the flow's navigation resolver.
  double get progressPercentage {
    final completedSteps = steps.where((step) => step.isCompleted).length;
    return completedSteps / steps.length;
  }

  /// Number of completed steps
  int get completedStepsCount => steps.where((step) => step.isCompleted).length;

  /// Current step details
  OnboardingStep get currentStepDetails {
    return steps.firstWhere(
      (step) => step.id == currentStepId,
      orElse: () => OnboardingStep.initial(currentStepId),
    );
  }

  /// Whether the current step is valid and can progress
  bool get canProgressFromCurrentStep => currentStepDetails.canProgress;

  /// List of completed step IDs
  List<OnboardingStepId> get completedStepIds {
    return steps
        .where((step) => step.isCompleted)
        .map((step) => step.id)
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
      'currentStepId': currentStepId.id, // Store as string ID
      'steps': steps.map((step) => step.toJson()).toList(),
      'startedAt': startedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'userId': userId,
      'totalTimeSpentMs': totalTimeSpent.inMilliseconds,
    };
  }

  /// Creates a copy of this [OnboardingProgress] with the given fields replaced
  OnboardingProgress copyWith({
    OnboardingStepId? currentStepId,
    List<OnboardingStep>? steps,
    DateTime? startedAt,
    DateTime? completedAt,
    String? userId,
    Duration? totalTimeSpent,
  }) {
    return OnboardingProgress(
      currentStepId: currentStepId ?? this.currentStepId,
      steps: steps ?? this.steps,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      userId: userId ?? this.userId,
      totalTimeSpent: totalTimeSpent ?? this.totalTimeSpent,
    );
  }

  /// Moves to a specific step
  ///
  /// Marks the target step as started if not already.
  /// The caller (typically OnboardingService) should use the flow's
  /// navigation resolver to determine which step to move to.
  OnboardingProgress moveToStep(OnboardingStepId stepId) {
    // Start the target step if not already started
    final targetStepDetails = steps.firstWhere(
      (s) => s.id == stepId,
      orElse: () => OnboardingStep.initial(stepId),
    );

    final updatedSteps = _updateStepInList(
      targetStepDetails.markStarted(),
    );

    return copyWith(
      currentStepId: stepId,
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
      return step.id == updatedStep.id ? updatedStep : step;
    }).toList();
  }

  /// Validates the entire progress state
  List<String> validate() {
    final errors = <String>[];

    // Check if current step exists in steps list
    final hasCurrentStep = steps.any((step) => step.id == currentStepId);
    if (!hasCurrentStep) {
      errors.add('Current step not found in steps list');
    }

    // Check if all expected step IDs are represented
    for (final expectedStepId in OnboardingSteps.all) {
      final hasStep = steps.any((step) => step.id == expectedStepId);
      if (!hasStep) {
        errors.add('Missing step: ${expectedStepId.id}');
      }
    }

    // Check completion consistency
    if (isComplete) {
      if (currentStepId != OnboardingSteps.completion) {
        errors.add('Onboarding marked complete but not on completion step');
      }
    }

    return errors;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is OnboardingProgress &&
        other.currentStepId == currentStepId &&
        listEquals(other.steps, steps) &&
        other.startedAt == startedAt &&
        other.completedAt == completedAt &&
        other.userId == userId &&
        other.totalTimeSpent == totalTimeSpent;
  }

  @override
  int get hashCode {
    return Object.hash(
      currentStepId,
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
        'currentStepId: $currentStepId, '
        'steps: ${steps.length}, '
        'startedAt: $startedAt, '
        'completedAt: $completedAt, '
        'userId: $userId, '
        'totalTimeSpent: $totalTimeSpent'
        ')';
  }
}
