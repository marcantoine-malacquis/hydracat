import 'package:flutter/foundation.dart';
import 'package:hydracat/features/onboarding/migration/step_type_migration.dart';
import 'package:hydracat/features/onboarding/models/onboarding_step_id.dart';

/// Navigation System Overview
///
/// Simplified onboarding flow with 4 steps:
/// Welcome → Pet Basics → CKD Medical Info → Completion
///
/// Treatment setup (medications, fluid therapy) has been moved out of
/// onboarding and is now handled through dedicated profile screens after
/// onboarding completes.
///
/// Enumeration of onboarding steps in the flow
///
/// **DEPRECATED**: Use [OnboardingStepId] instead. This enum is kept for
/// backward compatibility with saved checkpoints and will be removed in v2.0.
@Deprecated('Use OnboardingStepId instead. Will be removed in v2.0.')
enum OnboardingStepType {
  /// Welcome screen - entry point with skip option
  welcome,

  /// Pet basics - name, age, weight
  petBasics,

  /// CKD medical information - IRIS stage and lab values
  ckdMedicalInfo,

  /// Completion screen - success and next steps
  completion;

  /// User-friendly display name for the step
  String get displayName => switch (this) {
    OnboardingStepType.welcome => 'Welcome',
    OnboardingStepType.petBasics => 'Pet Information',
    OnboardingStepType.ckdMedicalInfo => 'Medical Information',
    OnboardingStepType.completion => 'Complete',
  };

  /// Analytics event name for this step
  String get analyticsEventName => switch (this) {
    OnboardingStepType.welcome => 'onboarding_welcome_viewed',
    OnboardingStepType.petBasics => 'onboarding_basics_viewed',
    OnboardingStepType.ckdMedicalInfo => 'onboarding_medical_viewed',
    OnboardingStepType.completion => 'onboarding_completion_viewed',
  };

  /// Gets the route name for navigation
  String get routeName => switch (this) {
    OnboardingStepType.welcome => '/onboarding/welcome',
    OnboardingStepType.petBasics => '/onboarding/basics',
    OnboardingStepType.ckdMedicalInfo => '/onboarding/medical',
    OnboardingStepType.completion => '/onboarding/completion',
  };

  /// Whether this step can be skipped
  bool get canSkip => switch (this) {
    OnboardingStepType.welcome => true,
    OnboardingStepType.petBasics => false,
    OnboardingStepType.ckdMedicalInfo => true,
    OnboardingStepType.completion => false,
  };

  /// Whether user can navigate back from this step
  bool get canGoBack => switch (this) {
    OnboardingStepType.welcome => false,
    OnboardingStepType.petBasics => true,
    OnboardingStepType.ckdMedicalInfo => true,
    OnboardingStepType.completion => true,
  };

  /// Whether this step triggers a checkpoint save
  bool get isCheckpoint => switch (this) {
    OnboardingStepType.welcome => false,
    OnboardingStepType.petBasics => true,
    OnboardingStepType.ckdMedicalInfo => false,
    OnboardingStepType.completion => true,
  };

  /// Step index in the flow (0-based)
  int get stepIndex => switch (this) {
    OnboardingStepType.welcome => 0,
    OnboardingStepType.petBasics => 1,
    OnboardingStepType.ckdMedicalInfo => 2,
    OnboardingStepType.completion => 3,
  };

  /// Next step in the flow (null if last step)
  OnboardingStepType? get nextStep => switch (this) {
    OnboardingStepType.welcome => OnboardingStepType.petBasics,
    OnboardingStepType.petBasics => OnboardingStepType.ckdMedicalInfo,
    OnboardingStepType.ckdMedicalInfo => OnboardingStepType.completion,
    OnboardingStepType.completion => null,
  };

  /// Previous step in the flow (null if first step)
  OnboardingStepType? get previousStep => switch (this) {
    OnboardingStepType.welcome => null,
    OnboardingStepType.petBasics => OnboardingStepType.welcome,
    OnboardingStepType.ckdMedicalInfo => OnboardingStepType.petBasics,
    OnboardingStepType.completion => OnboardingStepType.ckdMedicalInfo,
  };

  /// Total number of steps in the onboarding flow
  static int get totalSteps => OnboardingStepType.values.length;

  /// Creates an OnboardingStepType from a string value
  static OnboardingStepType? fromString(String value) {
    return OnboardingStepType.values
        .where((step) => step.name == value)
        .firstOrNull;
  }

  /// Creates an OnboardingStepType from step index
  static OnboardingStepType? fromStepIndex(int index) {
    return OnboardingStepType.values
        .where((step) => step.stepIndex == index)
        .firstOrNull;
  }
}

/// Detailed information about a specific onboarding step
@immutable
class OnboardingStep {
  /// Creates an [OnboardingStep] instance
  const OnboardingStep({
    required this.id,
    required this.isCompleted,
    required this.isValid,
    this.startedAt,
    this.completedAt,
    this.validationErrors = const [],
  });

  /// Creates an initial step that hasn't been started
  const OnboardingStep.initial(this.id)
    : isCompleted = false,
      isValid = false,
      startedAt = null,
      completedAt = null,
      validationErrors = const [];

  /// Creates an [OnboardingStep] from JSON data with migration support
  factory OnboardingStep.fromJson(Map<String, dynamic> json) {
    // Support both old 'type' field and new 'id' field
    final stepData = json['id'] ?? json['type'];
    OnboardingStepId stepId;

    if (stepData is String) {
      // Try to parse as new step ID format first
      stepId = StepTypeMigration.parseStepId(stepData);
    } else {
      // Fallback to welcome
      stepId = OnboardingSteps.welcome;
    }

    return OnboardingStep(
      id: stepId,
      isCompleted: json['isCompleted'] as bool? ?? false,
      isValid: json['isValid'] as bool? ?? false,
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      validationErrors:
          (json['validationErrors'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );
  }

  /// The unique identifier for this onboarding step
  final OnboardingStepId id;

  /// Whether this step has been completed
  final bool isCompleted;

  /// Whether the data for this step is valid
  final bool isValid;

  /// When the user started this step
  final DateTime? startedAt;

  /// When the user completed this step
  final DateTime? completedAt;

  /// List of validation errors for this step
  final List<String> validationErrors;

  /// Whether this step has been started
  bool get isStarted => startedAt != null;

  /// Duration spent on this step (if completed)
  Duration? get duration {
    if (startedAt != null && completedAt != null) {
      return completedAt!.difference(startedAt!);
    }
    return null;
  }

  /// Whether this step can be considered ready for progression
  bool get canProgress => isValid && validationErrors.isEmpty;

  /// Converts [OnboardingStep] to JSON data
  Map<String, dynamic> toJson() {
    return {
      'id': id.id, // Store as string ID
      'isCompleted': isCompleted,
      'isValid': isValid,
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'validationErrors': validationErrors,
    };
  }

  /// Creates a copy of this [OnboardingStep] with the given fields replaced
  OnboardingStep copyWith({
    OnboardingStepId? id,
    bool? isCompleted,
    bool? isValid,
    DateTime? startedAt,
    DateTime? completedAt,
    List<String>? validationErrors,
  }) {
    return OnboardingStep(
      id: id ?? this.id,
      isCompleted: isCompleted ?? this.isCompleted,
      isValid: isValid ?? this.isValid,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      validationErrors: validationErrors ?? this.validationErrors,
    );
  }

  /// Marks this step as started
  OnboardingStep markStarted() {
    return copyWith(
      startedAt: startedAt ?? DateTime.now(),
    );
  }

  /// Marks this step as completed with validation
  OnboardingStep markCompleted({bool isValid = true}) {
    return copyWith(
      isCompleted: true,
      isValid: isValid,
      completedAt: DateTime.now(),
      validationErrors: isValid ? [] : validationErrors,
    );
  }

  /// Updates validation status and errors
  OnboardingStep updateValidation({
    required bool isValid,
    List<String> validationErrors = const [],
  }) {
    return copyWith(
      isValid: isValid,
      validationErrors: validationErrors,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is OnboardingStep &&
        other.id == id &&
        other.isCompleted == isCompleted &&
        other.isValid == isValid &&
        other.startedAt == startedAt &&
        other.completedAt == completedAt &&
        listEquals(other.validationErrors, validationErrors);
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      isCompleted,
      isValid,
      startedAt,
      completedAt,
      Object.hashAll(validationErrors),
    );
  }

  @override
  String toString() {
    return 'OnboardingStep('
        'id: $id, '
        'isCompleted: $isCompleted, '
        'isValid: $isValid, '
        'startedAt: $startedAt, '
        'completedAt: $completedAt, '
        'validationErrors: $validationErrors'
        ')';
  }
}
