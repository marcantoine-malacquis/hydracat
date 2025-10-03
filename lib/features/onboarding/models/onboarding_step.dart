import 'package:flutter/foundation.dart';
import 'package:hydracat/features/profile/models/user_persona.dart';

/// Navigation System Overview
///
/// This enum provides persona-aware routing for the onboarding flow:
///
/// **Flow for Medication Only:**
/// Welcome → Persona → Basics → Medical → Medication → Completion
///
/// **Flow for Fluid Therapy Only:**
/// Welcome → Persona → Basics → Medical → Fluid → Completion
///
/// **Flow for Medication & Fluid:**
/// Welcome → Persona → Basics → Medical → Medication → Fluid → Completion
///
/// Use `getRouteName(persona)` for route strings and `getNextStep(persona)`
/// for navigation logic. The persona parameter is required for treatment steps.
///
/// Enumeration of onboarding steps in the flow
enum OnboardingStepType {
  /// Welcome screen - entry point with skip option
  welcome,

  /// User persona selection - treatment approach
  userPersona,

  /// Pet basics - name, age, weight
  petBasics,

  /// CKD medical information - IRIS stage and lab values
  ckdMedicalInfo,

  /// Treatment medication setup - for medication-based personas
  treatmentMedication,

  /// Treatment fluid setup - for fluid-based personas
  treatmentFluid,

  /// Completion screen - success and next steps
  completion;

  /// User-friendly display name for the step
  String get displayName => switch (this) {
    OnboardingStepType.welcome => 'Welcome',
    OnboardingStepType.userPersona => 'Treatment Approach',
    OnboardingStepType.petBasics => 'Pet Information',
    OnboardingStepType.ckdMedicalInfo => 'Medical Information',
    OnboardingStepType.treatmentMedication => 'Medication Setup',
    OnboardingStepType.treatmentFluid => 'Fluid Therapy Setup',
    OnboardingStepType.completion => 'Complete',
  };

  /// Analytics event name for this step
  String get analyticsEventName => switch (this) {
    OnboardingStepType.welcome => 'onboarding_welcome_viewed',
    OnboardingStepType.userPersona => 'onboarding_persona_viewed',
    OnboardingStepType.petBasics => 'onboarding_basics_viewed',
    OnboardingStepType.ckdMedicalInfo => 'onboarding_medical_viewed',
    OnboardingStepType.treatmentMedication => 'onboarding_medication_viewed',
    OnboardingStepType.treatmentFluid => 'onboarding_fluid_viewed',
    OnboardingStepType.completion => 'onboarding_completion_viewed',
  };

  /// Gets the route name for navigation with persona-aware routing
  ///
  /// For treatment steps, returns different routes based on selected persona:
  /// - Medication Only: Uses medication route, skips to completion after
  /// - Fluid Therapy Only: Uses fluid route directly, skips medication
  /// - Medication & Fluid: Uses both routes in sequence
  ///
  /// For non-treatment steps, persona parameter is ignored.
  String getRouteName([UserPersona? persona]) {
    // Non-treatment steps: same route for all personas
    if (this != OnboardingStepType.treatmentMedication &&
        this != OnboardingStepType.treatmentFluid) {
      return switch (this) {
        OnboardingStepType.welcome => '/onboarding/welcome',
        OnboardingStepType.userPersona => '/onboarding/persona',
        OnboardingStepType.petBasics => '/onboarding/basics',
        OnboardingStepType.ckdMedicalInfo => '/onboarding/medical',
        OnboardingStepType.completion => '/onboarding/completion',
        _ => '/onboarding/welcome', // Fallback
      };
    }

    // Treatment steps require persona context for correct routing
    if (persona == null) {
      // Fallback if no persona (should rarely happen in practice)
      return this == OnboardingStepType.treatmentMedication
          ? '/onboarding/treatment/medication'
          : '/onboarding/treatment/fluid';
    }

    // Persona-aware treatment routing
    return switch (this) {
      OnboardingStepType.treatmentMedication => switch (persona) {
          UserPersona.medicationOnly => '/onboarding/treatment/medication',
          UserPersona.fluidTherapyOnly =>
            '/onboarding/treatment/fluid', // Skip to fluid
          UserPersona.medicationAndFluidTherapy =>
            '/onboarding/treatment/medication',
        },
      OnboardingStepType.treatmentFluid => switch (persona) {
          UserPersona.medicationOnly =>
            '/onboarding/completion', // Skip fluid
          UserPersona.fluidTherapyOnly => '/onboarding/treatment/fluid',
          UserPersona.medicationAndFluidTherapy =>
            '/onboarding/treatment/fluid',
        },
      _ => '/onboarding/welcome', // Should never reach here
    };
  }

  /// Route name for navigation (deprecated - use getRouteName)
  ///
  /// Deprecated: Use getRouteName for persona-aware routing
  @Deprecated('Use getRouteName for persona-aware routing')
  String get routeName => getRouteName();

  /// Gets the route name for a specific persona's treatment setup
  /// Returns null for non-treatment steps
  String? getTreatmentRouteForPersona(String? personaName) {
    if (personaName == null) return null;

    return switch (personaName) {
      'medicationOnly' => '/onboarding/treatment/medication',
      'fluidTherapyOnly' => '/onboarding/treatment/fluid',
      'medicationAndFluidTherapy' => '/onboarding/treatment/medication',
      _ => null,
    };
  }

  /// Whether this step can be skipped
  bool get canSkip => switch (this) {
    OnboardingStepType.welcome => true,
    OnboardingStepType.userPersona => false,
    OnboardingStepType.petBasics => false,
    OnboardingStepType.ckdMedicalInfo => true,
    OnboardingStepType.treatmentMedication => true,
    OnboardingStepType.treatmentFluid => true,
    OnboardingStepType.completion => false,
  };

  /// Whether user can navigate back from this step
  bool get canGoBack => switch (this) {
    OnboardingStepType.welcome => false,
    OnboardingStepType.userPersona => true,
    OnboardingStepType.petBasics => true,
    OnboardingStepType.ckdMedicalInfo => true,
    OnboardingStepType.treatmentMedication => true,
    OnboardingStepType.treatmentFluid => true,
    OnboardingStepType.completion =>
      true, // Allow back navigation to review settings
  };

  /// Whether this step triggers a checkpoint save
  bool get isCheckpoint => switch (this) {
    OnboardingStepType.welcome => false,
    OnboardingStepType.userPersona => true, // First checkpoint
    OnboardingStepType.petBasics => true, // Second checkpoint
    OnboardingStepType.ckdMedicalInfo => false,
    OnboardingStepType.treatmentMedication => true, // Saves medications
    OnboardingStepType.treatmentFluid => true, // Saves fluid therapy
    OnboardingStepType.completion => true, // Final save
  };

  /// Step index in the flow (0-based)
  int get stepIndex => switch (this) {
    OnboardingStepType.welcome => 0,
    OnboardingStepType.userPersona => 1,
    OnboardingStepType.petBasics => 2,
    OnboardingStepType.ckdMedicalInfo => 3,
    OnboardingStepType.treatmentMedication => 4,
    OnboardingStepType.treatmentFluid => 5,
    OnboardingStepType.completion => 6,
  };

  /// Next step in the flow based on the selected persona (null if last step)
  ///
  /// The navigation is persona-aware:
  /// - Medication Only: skips treatmentFluid
  /// - Fluid Therapy Only: skips treatmentMedication
  /// - Medication & Fluid Therapy: goes through both treatment screens
  OnboardingStepType? getNextStep([UserPersona? persona]) {
    return switch (this) {
      OnboardingStepType.welcome => OnboardingStepType.userPersona,
      OnboardingStepType.userPersona => OnboardingStepType.petBasics,
      OnboardingStepType.petBasics => OnboardingStepType.ckdMedicalInfo,
      OnboardingStepType.ckdMedicalInfo =>
        _getNextStepAfterMedicalInfo(persona),
      OnboardingStepType.treatmentMedication =>
        _getNextStepAfterMedication(persona),
      OnboardingStepType.treatmentFluid => OnboardingStepType.completion,
      OnboardingStepType.completion => null,
    };
  }

  /// Helper to determine next step after medical info based on persona
  OnboardingStepType _getNextStepAfterMedicalInfo(UserPersona? persona) {
    if (persona == null) {
      // Default to medication if no persona selected yet
      return OnboardingStepType.treatmentMedication;
    }

    return switch (persona) {
      UserPersona.medicationOnly => OnboardingStepType.treatmentMedication,
      UserPersona.fluidTherapyOnly => OnboardingStepType.treatmentFluid,
      UserPersona.medicationAndFluidTherapy =>
        OnboardingStepType.treatmentMedication,
    };
  }

  /// Helper to determine next step after medication based on persona
  OnboardingStepType _getNextStepAfterMedication(UserPersona? persona) {
    if (persona == null ||
        persona == UserPersona.medicationAndFluidTherapy) {
      // If no persona or combined therapy, go to fluid therapy
      return OnboardingStepType.treatmentFluid;
    }

    // For medicationOnly, skip fluid therapy and go to completion
    return OnboardingStepType.completion;
  }

  /// Next step in the flow (null if this is the last step)
  ///
  /// Deprecated: Use getNextStep instead for persona-aware navigation
  @Deprecated('Use getNextStep instead for persona-aware navigation')
  OnboardingStepType? get nextStep => getNextStep();

  /// Previous step based on the selected persona (null if first step)
  ///
  /// The navigation is persona-aware:
  /// - Medication Only: completion → treatmentMedication
  /// - Fluid Therapy Only: treatmentFluid → ckdMedicalInfo
  /// - Medication & Fluid Therapy: follows full sequence
  OnboardingStepType? getPreviousStep([UserPersona? persona]) {
    return switch (this) {
      OnboardingStepType.welcome => null,
      OnboardingStepType.userPersona => OnboardingStepType.welcome,
      OnboardingStepType.petBasics => OnboardingStepType.userPersona,
      OnboardingStepType.ckdMedicalInfo => OnboardingStepType.petBasics,
      OnboardingStepType.treatmentMedication =>
        OnboardingStepType.ckdMedicalInfo,
      OnboardingStepType.treatmentFluid =>
        _getPreviousStepBeforeFluid(persona),
      OnboardingStepType.completion =>
        _getPreviousStepBeforeCompletion(persona),
    };
  }

  /// Helper to determine previous step before fluid based on persona
  OnboardingStepType _getPreviousStepBeforeFluid(UserPersona? persona) {
    if (persona == UserPersona.fluidTherapyOnly) {
      // Skip medication screen for fluid-only persona
      return OnboardingStepType.ckdMedicalInfo;
    }

    // For combined therapy or no persona, come from medication
    return OnboardingStepType.treatmentMedication;
  }

  /// Helper to determine previous step before completion based on persona
  OnboardingStepType _getPreviousStepBeforeCompletion(
    UserPersona? persona,
  ) {
    if (persona == null) {
      // Default to fluid therapy if no persona
      return OnboardingStepType.treatmentFluid;
    }

    return switch (persona) {
      UserPersona.medicationOnly =>
        OnboardingStepType.treatmentMedication,
      UserPersona.fluidTherapyOnly => OnboardingStepType.treatmentFluid,
      UserPersona.medicationAndFluidTherapy =>
        OnboardingStepType.treatmentFluid,
    };
  }

  /// Previous step in the flow (null if this is the first step)
  ///
  /// Deprecated: Use getPreviousStep instead
  @Deprecated('Use getPreviousStep instead')
  OnboardingStepType? get previousStep => getPreviousStep();

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
    required this.type,
    required this.isCompleted,
    required this.isValid,
    this.startedAt,
    this.completedAt,
    this.validationErrors = const [],
  });

  /// Creates an initial step that hasn't been started
  const OnboardingStep.initial(this.type)
    : isCompleted = false,
      isValid = false,
      startedAt = null,
      completedAt = null,
      validationErrors = const [];

  /// Creates an [OnboardingStep] from JSON data
  factory OnboardingStep.fromJson(Map<String, dynamic> json) {
    return OnboardingStep(
      type:
          OnboardingStepType.fromString(json['type'] as String) ??
          OnboardingStepType.welcome,
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

  /// The type of onboarding step
  final OnboardingStepType type;

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
      'type': type.name,
      'isCompleted': isCompleted,
      'isValid': isValid,
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'validationErrors': validationErrors,
    };
  }

  /// Creates a copy of this [OnboardingStep] with the given fields replaced
  OnboardingStep copyWith({
    OnboardingStepType? type,
    bool? isCompleted,
    bool? isValid,
    DateTime? startedAt,
    DateTime? completedAt,
    List<String>? validationErrors,
  }) {
    return OnboardingStep(
      type: type ?? this.type,
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
        other.type == type &&
        other.isCompleted == isCompleted &&
        other.isValid == isValid &&
        other.startedAt == startedAt &&
        other.completedAt == completedAt &&
        listEquals(other.validationErrors, validationErrors);
  }

  @override
  int get hashCode {
    return Object.hash(
      type,
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
        'type: $type, '
        'isCompleted: $isCompleted, '
        'isValid: $isValid, '
        'startedAt: $startedAt, '
        'completedAt: $completedAt, '
        'validationErrors: $validationErrors'
        ')';
  }
}
