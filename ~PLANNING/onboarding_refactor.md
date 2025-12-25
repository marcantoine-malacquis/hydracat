# Onboarding Refactor: Option B - Modern Architecture

## 📊 Project Overview

**Goal:** Transform the enum-based linear onboarding into a declarative, graph-based system that supports conditional navigation while preserving existing functionality.

**Effort Estimate:** 5-7 days (1 developer)
**Risk Level:** Medium
**Breaking Changes:** Minimal (mostly internal refactoring)

---

## 🎯 Success Criteria

- ✅ All existing 4 screens continue working without changes
- ✅ New screens can be added by writing configuration objects (no switch expressions)
- ✅ Support for conditional navigation (data-driven next step)
- ✅ Step visibility conditions (when to show/hide steps)
- ✅ Backward compatible with existing `OnboardingData` and `OnboardingProgress`
- ✅ All existing tests pass
- ✅ No regression in checkpoint/resume functionality
- ✅ Analytics continue tracking correctly

---

## 🏗️ Architecture Design

### **New Core Components**

```
lib/features/onboarding/
├── flow/                           # NEW - Flow configuration system
│   ├── onboarding_flow.dart           # Flow definition and registry
│   ├── onboarding_step_config.dart    # Step configuration model
│   ├── navigation_resolver.dart        # Dynamic navigation logic
│   ├── step_validator.dart             # Step validation interface
│   └── step_visibility.dart            # Conditional step visibility
├── validators/                     # NEW - Step-specific validators
│   ├── pet_basics_validator.dart
│   ├── medical_info_validator.dart
│   └── completion_validator.dart
├── models/                         # MODIFIED
│   ├── onboarding_step.dart           # Keep but simplify
│   └── onboarding_step_id.dart        # NEW - Replaces enum partially
├── services/                       # MODIFIED
│   └── onboarding_service.dart        # Refactor to use flow engine
└── [existing screens, widgets, etc.]
```

---

## 📝 Implementation Phases

## **Phase 1: Foundation (Day 1)**

### 1.1 Create Step ID System

**File:** `lib/features/onboarding/models/onboarding_step_id.dart`

```dart
/// Sealed class for type-safe step identification
sealed class OnboardingStepId {
  const OnboardingStepId(this.id);

  final String id;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OnboardingStepId && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => id;
}

/// Predefined step IDs (extensible)
class WelcomeStepId extends OnboardingStepId {
  const WelcomeStepId() : super('welcome');
}

class PetBasicsStepId extends OnboardingStepId {
  const PetBasicsStepId() : super('pet_basics');
}

class MedicalInfoStepId extends OnboardingStepId {
  const MedicalInfoStepId() : super('medical_info');
}

class CompletionStepId extends OnboardingStepId {
  const CompletionStepId() : super('completion');
}

/// Step ID constants for easy access
class OnboardingSteps {
  static const welcome = WelcomeStepId();
  static const petBasics = PetBasicsStepId();
  static const medicalInfo = MedicalInfoStepId();
  static const completion = CompletionStepId();

  /// All steps in default order
  static const all = [welcome, petBasics, medicalInfo, completion];
}
```

**Why:** Type-safe identifiers that can be extended without modifying enums.

---

### 1.2 Create Step Validator Interface

**File:** `lib/features/onboarding/flow/step_validator.dart`

```dart
import 'package:hydracat/core/validation/models/validation_result.dart';
import 'package:hydracat/features/onboarding/models/onboarding_data.dart';

/// Interface for step-specific validation
abstract class StepValidator {
  /// Validates the data for this step
  ///
  /// Returns [ValidationResult.valid()] if data is valid,
  /// or [ValidationResult.invalid()] with error messages if not.
  ValidationResult validate(OnboardingData data);

  /// Gets list of missing required fields for user-friendly error messages
  List<String> getMissingFields(OnboardingData data);

  /// Quick check if step data is valid (for progress indicators)
  bool isValid(OnboardingData data) => validate(data).isValid;
}

/// Base validator with common helpers
abstract class BaseStepValidator implements StepValidator {
  const BaseStepValidator();

  @override
  ValidationResult validate(OnboardingData data) {
    final missing = getMissingFields(data);

    if (missing.isEmpty) {
      return ValidationResult.valid();
    }

    return ValidationResult.invalid(
      errors: missing
          .map((field) => '$field is required')
          .toList(),
    );
  }
}

/// Validator for steps with no required data (always valid)
class AlwaysValidValidator extends BaseStepValidator {
  const AlwaysValidValidator();

  @override
  List<String> getMissingFields(OnboardingData data) => [];
}
```

---

### 1.3 Create Step Configuration Model

**File:** `lib/features/onboarding/flow/onboarding_step_config.dart`

```dart
import 'package:flutter/foundation.dart';
import 'package:hydracat/features/onboarding/flow/step_validator.dart';
import 'package:hydracat/features/onboarding/models/onboarding_data.dart';
import 'package:hydracat/features/onboarding/models/onboarding_step_id.dart';

/// Type for navigation resolver function
typedef NavigationResolver = OnboardingStepId? Function(OnboardingData data);

/// Type for step visibility condition
typedef StepVisibilityCondition = bool Function(OnboardingData data);

/// Configuration for a single onboarding step
@immutable
class OnboardingStepConfig {
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

  /// User-friendly display name
  final String displayName;

  /// GoRouter route path
  final String route;

  /// Firebase Analytics event name
  final String analyticsEventName;

  /// Whether this step can be skipped
  final bool canSkip;

  /// Whether user can navigate back from this step
  final bool canGoBack;

  /// Whether this step triggers automatic checkpoint save
  final bool isCheckpoint;

  /// Validator for this step's data requirements
  final StepValidator validator;

  /// Optional condition to determine if step should be shown
  /// If null, step is always shown
  final StepVisibilityCondition? visibilityCondition;

  /// Optional custom navigation logic
  /// If null, uses default linear navigation from flow
  final NavigationResolver? navigationResolver;

  /// Whether this step should be shown based on current data
  bool isVisible(OnboardingData data) {
    return visibilityCondition?.call(data) ?? true;
  }

  /// Validates data for this step
  bool isValid(OnboardingData data) {
    return validator.isValid(data);
  }

  /// Gets missing required fields
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
```

---

## **Phase 2: Flow Engine (Day 2)**

### 2.1 Create Navigation Resolver

**File:** `lib/features/onboarding/flow/navigation_resolver.dart`

```dart
import 'package:flutter/foundation.dart';
import 'package:hydracat/features/onboarding/flow/onboarding_step_config.dart';
import 'package:hydracat/features/onboarding/models/onboarding_data.dart';
import 'package:hydracat/features/onboarding/models/onboarding_step_id.dart';

/// Resolves navigation between onboarding steps
class NavigationResolver {
  const NavigationResolver(this._flow);

  final OnboardingFlow _flow;

  /// Gets the next step from the current step based on data
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
  List<OnboardingStepConfig> getVisibleSteps(OnboardingData data) {
    return _flow.steps
        .where((step) => step.isVisible(data))
        .toList();
  }

  /// Calculates progress percentage based on visible steps
  double calculateProgress(
    OnboardingStepId currentStepId,
    OnboardingData data,
  ) {
    final visibleSteps = getVisibleSteps(data);
    if (visibleSteps.isEmpty) return 0.0;

    final currentIndex = visibleSteps
        .indexWhere((step) => step.id == currentStepId);

    if (currentIndex == -1) return 0.0;

    return (currentIndex + 1) / visibleSteps.length;
  }

  /// Gets the route for a step ID
  String? getRoute(OnboardingStepId stepId) {
    return _flow.getStep(stepId)?.route;
  }
}
```

---

### 2.2 Create Onboarding Flow Definition

**File:** `lib/features/onboarding/flow/onboarding_flow.dart`

```dart
import 'package:flutter/foundation.dart';
import 'package:hydracat/features/onboarding/flow/navigation_resolver.dart';
import 'package:hydracat/features/onboarding/flow/onboarding_step_config.dart';
import 'package:hydracat/features/onboarding/models/onboarding_step_id.dart';
import 'package:hydracat/features/onboarding/validators/validators.dart';

/// Registry and configuration for the entire onboarding flow
@immutable
class OnboardingFlow {
  const OnboardingFlow(this.steps);

  /// All steps in this flow (order matters for linear navigation)
  final List<OnboardingStepConfig> steps;

  /// Navigation resolver for this flow
  late final NavigationResolver navigationResolver =
      NavigationResolver(this);

  /// Gets a step configuration by ID
  OnboardingStepConfig? getStep(OnboardingStepId stepId) {
    try {
      return steps.firstWhere((step) => step.id == stepId);
    } on StateError {
      return null;
    }
  }

  /// Gets a step by route
  OnboardingStepConfig? getStepByRoute(String route) {
    try {
      return steps.firstWhere((step) => step.route == route);
    } on StateError {
      return null;
    }
  }

  /// Total number of steps (including invisible ones)
  int get totalSteps => steps.length;

  /// First step in the flow
  OnboardingStepConfig get firstStep => steps.first;

  /// Last step in the flow
  OnboardingStepConfig get lastStep => steps.last;
}

/// Default onboarding flow configuration
const defaultOnboardingFlow = OnboardingFlow([
  // Step 1: Welcome
  OnboardingStepConfig(
    id: OnboardingSteps.welcome,
    displayName: 'Welcome',
    route: '/onboarding/welcome',
    analyticsEventName: 'onboarding_welcome_viewed',
    canSkip: true,
    canGoBack: false,
    isCheckpoint: false,
    validator: AlwaysValidValidator(),
  ),

  // Step 2: Pet Basics
  OnboardingStepConfig(
    id: OnboardingSteps.petBasics,
    displayName: 'Pet Information',
    route: '/onboarding/basics',
    analyticsEventName: 'onboarding_basics_viewed',
    canSkip: false,
    canGoBack: true,
    isCheckpoint: true,
    validator: PetBasicsValidator(),
  ),

  // Step 3: CKD Medical Info
  OnboardingStepConfig(
    id: OnboardingSteps.medicalInfo,
    displayName: 'Medical Information',
    route: '/onboarding/medical',
    analyticsEventName: 'onboarding_medical_viewed',
    canSkip: true,
    canGoBack: true,
    isCheckpoint: false,
    validator: AlwaysValidValidator(), // Optional step
  ),

  // Step 4: Completion
  OnboardingStepConfig(
    id: OnboardingSteps.completion,
    displayName: 'Complete',
    route: '/onboarding/completion',
    analyticsEventName: 'onboarding_completion_viewed',
    canSkip: false,
    canGoBack: true,
    isCheckpoint: true,
    validator: CompletionValidator(),
  ),
]);

/// Provider for accessing the onboarding flow
OnboardingFlow getOnboardingFlow() => defaultOnboardingFlow;
```

---

## **Phase 3: Validators (Day 2-3)**

### 3.1 Create Validators Barrel File

**File:** `lib/features/onboarding/validators/validators.dart`

```dart
export 'always_valid_validator.dart';
export 'completion_validator.dart';
export 'medical_info_validator.dart';
export 'pet_basics_validator.dart';
```

---

### 3.2 Always Valid Validator

**File:** `lib/features/onboarding/validators/always_valid_validator.dart`

```dart
import 'package:hydracat/features/onboarding/flow/step_validator.dart';
import 'package:hydracat/features/onboarding/models/onboarding_data.dart';

/// Validator for steps with no required data (always valid)
class AlwaysValidValidator extends BaseStepValidator {
  const AlwaysValidValidator();

  @override
  List<String> getMissingFields(OnboardingData data) => [];
}
```

---

### 3.3 Pet Basics Validator

**File:** `lib/features/onboarding/validators/pet_basics_validator.dart`

```dart
import 'package:hydracat/core/validation/models/validation_result.dart';
import 'package:hydracat/features/onboarding/flow/step_validator.dart';
import 'package:hydracat/features/onboarding/models/onboarding_data.dart';

/// Validates pet basics step requirements
class PetBasicsValidator extends BaseStepValidator {
  const PetBasicsValidator();

  @override
  List<String> getMissingFields(OnboardingData data) {
    final missing = <String>[];

    // Pet name is required
    if (data.petName == null || data.petName!.trim().isEmpty) {
      missing.add('Pet name');
    }

    // Age OR date of birth is required
    if ((data.petAge == null || data.petAge! <= 0) &&
        data.petDateOfBirth == null) {
      missing.add('Pet age or date of birth');
    }

    // Gender is required
    if (data.petGender == null || data.petGender!.isEmpty) {
      missing.add('Gender');
    }

    return missing;
  }

  @override
  ValidationResult validate(OnboardingData data) {
    final missing = getMissingFields(data);

    if (missing.isEmpty) {
      // Additional validation rules
      if (data.petName != null && data.petName!.length > 50) {
        return ValidationResult.invalid(
          errors: ['Pet name must be 50 characters or less'],
        );
      }

      if (data.petAge != null && data.petAge! > 30) {
        return ValidationResult.invalid(
          errors: ['Pet age seems unusually high. Please verify.'],
        );
      }

      return ValidationResult.valid();
    }

    return ValidationResult.invalid(
      errors: missing.map((field) => '$field is required').toList(),
    );
  }
}
```

---

### 3.4 Medical Info Validator

**File:** `lib/features/onboarding/validators/medical_info_validator.dart`

```dart
import 'package:hydracat/features/onboarding/flow/step_validator.dart';
import 'package:hydracat/features/onboarding/models/onboarding_data.dart';

/// Validates medical info step (currently optional, so always valid)
class MedicalInfoValidator extends BaseStepValidator {
  const MedicalInfoValidator();

  @override
  List<String> getMissingFields(OnboardingData data) {
    // Medical info is optional, no required fields
    return [];
  }
}
```

---

### 3.5 Completion Validator

**File:** `lib/features/onboarding/validators/completion_validator.dart`

```dart
import 'package:hydracat/core/validation/models/validation_result.dart';
import 'package:hydracat/features/onboarding/flow/step_validator.dart';
import 'package:hydracat/features/onboarding/models/onboarding_data.dart';

/// Validates that all required data is complete before finishing
class CompletionValidator extends BaseStepValidator {
  const CompletionValidator();

  @override
  List<String> getMissingFields(OnboardingData data) {
    // Use the existing comprehensive validation from OnboardingData
    return data.getMissingRequiredFields();
  }

  @override
  ValidationResult validate(OnboardingData data) {
    if (data.isComplete) {
      return ValidationResult.valid();
    }

    final missing = getMissingFields(data);
    return ValidationResult.invalid(
      errors: missing.map((field) => '$field is required').toList(),
    );
  }
}
```

---

## **Phase 4: Service Layer Refactor (Day 3-4)**

### 4.1 Update OnboardingProgress Model

**File:** `lib/features/onboarding/models/onboarding_progress.dart`

**Key Changes:**
- Replace `OnboardingStepType currentStep` with `OnboardingStepId currentStepId`
- Update `List<OnboardingStep> steps` to use step IDs instead of types
- Keep all existing methods but adapt to use flow configuration
- Add migration logic for backward compatibility with saved checkpoints

```dart
// Add to existing file:

import 'package:hydracat/features/onboarding/models/onboarding_step_id.dart';
import 'package:hydracat/features/onboarding/migration/step_type_migration.dart';

class OnboardingProgress {
  const OnboardingProgress({
    required this.currentStepId, // Changed from OnboardingStepType
    required this.steps,
    required this.startedAt,
    this.completedAt,
    this.userId,
  });

  final OnboardingStepId currentStepId;
  // ... rest of properties

  /// Creates initial progress for a new onboarding session
  factory OnboardingProgress.initial({String? userId}) {
    return OnboardingProgress(
      currentStepId: OnboardingSteps.welcome,
      steps: OnboardingSteps.all.map((id) => OnboardingStep.initial(id)).toList(),
      startedAt: DateTime.now(),
      userId: userId,
    );
  }

  /// Creates from JSON with migration support
  factory OnboardingProgress.fromJson(Map<String, dynamic> json) {
    // Check if saved data uses old enum format
    final currentStepData = json['currentStep'];

    OnboardingStepId currentStepId;
    if (currentStepData is String) {
      // Try to parse as legacy enum first
      final legacyType = OnboardingStepType.fromString(currentStepData);
      if (legacyType != null) {
        // Migrate from old enum to new step ID
        currentStepId = StepTypeMigration.migrateStepType(legacyType);
      } else {
        // Already new format - parse step ID
        currentStepId = _parseStepId(currentStepData);
      }
    } else {
      // Fallback to default
      currentStepId = OnboardingSteps.welcome;
    }

    return OnboardingProgress(
      currentStepId: currentStepId,
      steps: (json['steps'] as List<dynamic>?)
          ?.map((e) => OnboardingStep.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'] as String)
          : DateTime.now(),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      userId: json['userId'] as String?,
    );
  }

  /// Helper to parse step ID from string
  static OnboardingStepId _parseStepId(String idString) {
    return switch (idString) {
      'welcome' => OnboardingSteps.welcome,
      'pet_basics' => OnboardingSteps.petBasics,
      'medical_info' => OnboardingSteps.medicalInfo,
      'completion' => OnboardingSteps.completion,
      _ => OnboardingSteps.welcome, // Fallback
    };
  }

  /// Converts to JSON
  Map<String, dynamic> toJson() {
    return {
      'currentStep': currentStepId.id, // Store as string ID
      'steps': steps.map((s) => s.toJson()).toList(),
      'startedAt': startedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'userId': userId,
    };
  }

  /// Move to a specific step
  OnboardingProgress moveToStep(OnboardingStepId stepId) {
    return copyWith(currentStepId: stepId);
  }

  // Update copyWith to use OnboardingStepId
  OnboardingProgress copyWith({
    OnboardingStepId? currentStepId,
    // ... rest of parameters
  }) {
    return OnboardingProgress(
      currentStepId: currentStepId ?? this.currentStepId,
      // ... rest of properties
    );
  }
}
```

---

### 4.2 Update OnboardingStep Model

**File:** `lib/features/onboarding/models/onboarding_step.dart`

```dart
// Update to use OnboardingStepId instead of OnboardingStepType

import 'package:flutter/foundation.dart';
import 'package:hydracat/features/onboarding/models/onboarding_step_id.dart';

/// Detailed information about a specific onboarding step
@immutable
class OnboardingStep {
  const OnboardingStep({
    required this.id, // Changed from 'type'
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

  /// Creates from JSON with migration support
  factory OnboardingStep.fromJson(Map<String, dynamic> json) {
    final stepData = json['type'] ?? json['id'];
    OnboardingStepId stepId;

    if (stepData is String) {
      // Parse step ID (handles both old enum names and new IDs)
      stepId = _parseStepId(stepData);
    } else {
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
      validationErrors: (json['validationErrors'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );
  }

  static OnboardingStepId _parseStepId(String idString) {
    // Handle both old enum names and new step IDs
    return switch (idString) {
      'welcome' => OnboardingSteps.welcome,
      'petBasics' || 'pet_basics' => OnboardingSteps.petBasics,
      'ckdMedicalInfo' || 'medical_info' => OnboardingSteps.medicalInfo,
      'completion' => OnboardingSteps.completion,
      _ => OnboardingSteps.welcome,
    };
  }

  final OnboardingStepId id;
  final bool isCompleted;
  final bool isValid;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final List<String> validationErrors;

  /// Converts to JSON
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

  // ... rest of methods (markStarted, markCompleted, etc.)
}
```

---

### 4.3 Create Migration Utilities

**File:** `lib/features/onboarding/migration/step_type_migration.dart`

```dart
import 'package:hydracat/features/onboarding/models/onboarding_step.dart';
import 'package:hydracat/features/onboarding/models/onboarding_step_id.dart';

/// Migrates old OnboardingStepType enum to new step IDs
class StepTypeMigration {
  /// Converts legacy enum to step ID
  static OnboardingStepId migrateStepType(OnboardingStepType oldType) {
    return switch (oldType) {
      OnboardingStepType.welcome => OnboardingSteps.welcome,
      OnboardingStepType.petBasics => OnboardingSteps.petBasics,
      OnboardingStepType.ckdMedicalInfo => OnboardingSteps.medicalInfo,
      OnboardingStepType.completion => OnboardingSteps.completion,
    };
  }

  /// Converts step ID back to legacy enum (for compatibility)
  static OnboardingStepType? migrateToLegacyType(OnboardingStepId stepId) {
    if (stepId == OnboardingSteps.welcome) return OnboardingStepType.welcome;
    if (stepId == OnboardingSteps.petBasics) return OnboardingStepType.petBasics;
    if (stepId == OnboardingSteps.medicalInfo) return OnboardingStepType.ckdMedicalInfo;
    if (stepId == OnboardingSteps.completion) return OnboardingStepType.completion;
    return null;
  }
}
```

---

### 4.4 Refactor OnboardingService

**File:** `lib/features/onboarding/services/onboarding_service.dart`

**Key changes:**

```dart
import 'package:hydracat/features/onboarding/flow/onboarding_flow.dart';
import 'package:hydracat/features/onboarding/models/onboarding_step_id.dart';

class OnboardingService {
  /// Factory constructor with optional flow injection
  factory OnboardingService({OnboardingFlow? flow}) {
    _instance ??= OnboardingService._(flow: flow);
    return _instance!;
  }

  OnboardingService._({OnboardingFlow? flow})
      : _flow = flow ?? getOnboardingFlow();

  static OnboardingService? _instance;

  final OnboardingFlow _flow;
  final PetService _petService = PetService();
  final SecurePreferencesService _preferences = SecurePreferencesService();

  // ... existing fields

  /// Move to the next step in the onboarding flow
  Future<OnboardingResult> moveToNextStep() async {
    try {
      if (_currentProgress == null || _currentData == null) {
        return const OnboardingFailure(
          OnboardingServiceException('No active onboarding session'),
        );
      }

      // NEW: Use flow navigation resolver
      final nextStepId = _flow.navigationResolver.getNextStep(
        _currentProgress!.currentStepId,
        _currentData!,
      );

      if (nextStepId == null) {
        return const OnboardingFailure(
          OnboardingNavigationException('No next step available'),
        );
      }

      // Validate current step using flow config
      final currentConfig = _flow.getStep(_currentProgress!.currentStepId);
      if (currentConfig == null) {
        return const OnboardingFailure(
          OnboardingServiceException('Current step configuration not found'),
        );
      }

      if (!currentConfig.isValid(_currentData!)) {
        final missingFields = currentConfig.getMissingFields(_currentData!);
        return OnboardingFailure(
          OnboardingValidationException(missingFields),
        );
      }

      final previousStep = _currentProgress!.currentStepId;

      // Move to next step
      _currentProgress = _currentProgress!.moveToStep(nextStepId);

      // Track step completion analytics
      await _trackAnalyticsEvent('onboarding_step_completed', {
        'user_id': _currentData!.userId,
        'step': previousStep.id,
        'next_step': nextStepId.id,
        'progress_percentage': _flow.navigationResolver.calculateProgress(
          nextStepId,
          _currentData!,
        ),
      });

      // Auto-save if new step is a checkpoint
      final nextConfig = _flow.getStep(nextStepId);
      if (nextConfig!.isCheckpoint) {
        await _saveCheckpoint();
      }

      // Notify listeners
      _progressController.add(_currentProgress);

      return const OnboardingSuccess();
    } on Exception {
      return OnboardingFailure(
        OnboardingNavigationException(
          _currentProgress?.currentStepId.id ?? 'unknown',
        ),
      );
    }
  }

  /// Move to the previous step in the onboarding flow
  Future<OnboardingResult> moveToPreviousStep() async {
    try {
      if (_currentProgress == null || _currentData == null) {
        return const OnboardingFailure(
          OnboardingServiceException('No active onboarding session'),
        );
      }

      // NEW: Use flow navigation resolver
      final previousStepId = _flow.navigationResolver.getPreviousStep(
        _currentProgress!.currentStepId,
        _currentData!,
      );

      if (previousStepId == null) {
        return OnboardingFailure(
          OnboardingNavigationException(
            'Cannot go back from ${_currentProgress!.currentStepId.id}',
          ),
        );
      }

      _currentProgress = _currentProgress!.moveToStep(previousStepId);

      // Notify listeners
      _progressController.add(_currentProgress);

      return const OnboardingSuccess();
    } on Exception {
      return OnboardingFailure(
        OnboardingNavigationException(
          'back from ${_currentProgress?.currentStepId.id ?? 'unknown'}',
        ),
      );
    }
  }

  /// Sets the current step in the onboarding flow
  Future<OnboardingResult> setCurrentStep(OnboardingStepId step) async {
    try {
      if (_currentProgress == null) {
        return const OnboardingFailure(
          OnboardingServiceException('No active onboarding session'),
        );
      }

      _currentProgress = _currentProgress!.moveToStep(step);

      // Notify listeners
      _progressController.add(_currentProgress);

      return const OnboardingSuccess();
    } on Exception {
      return OnboardingFailure(
        OnboardingServiceException(
          'Failed to set current step to ${step.id}',
        ),
      );
    }
  }

  // Remove old switch-based validation methods
  // Replace with flow-based validation

  /// Validates if current step has valid data
  bool _isCurrentStepValid(OnboardingData data) {
    final currentConfig = _flow.getStep(_currentProgress!.currentStepId);
    return currentConfig?.isValid(data) ?? false;
  }

  /// Gets list of missing required fields for the current step
  List<String> _getMissingFieldsForCurrentStep(OnboardingData data) {
    final currentConfig = _flow.getStep(_currentProgress!.currentStepId);
    return currentConfig?.getMissingFields(data) ?? [];
  }

  // ... rest of service methods remain largely the same
}
```

---

## **Phase 5: Provider Updates (Day 4)**

### 5.1 Update OnboardingProvider

**File:** `lib/providers/onboarding_provider.dart`

```dart
// Add new providers at the bottom of the file:

/// Provider for the onboarding flow configuration
final onboardingFlowProvider = Provider<OnboardingFlow>((ref) {
  return getOnboardingFlow();
});

/// Update OnboardingService provider to inject flow
final onboardingServiceProvider = Provider<OnboardingService>((ref) {
  final flow = ref.read(onboardingFlowProvider);
  return OnboardingService(flow: flow);
});

// Update OnboardingNotifier with flow-aware methods:
class OnboardingNotifier extends StateNotifier<OnboardingState> {
  OnboardingNotifier(this._onboardingService, this._ref)
    : super(const OnboardingState.initial()) {
    _listenToProgressStream();
  }

  final OnboardingService _onboardingService;
  final Ref _ref;
  // ... existing fields

  /// Get the current step configuration
  OnboardingStepConfig? getCurrentStepConfig() {
    if (state.progress == null) return null;

    final flow = _ref.read(onboardingFlowProvider);
    return flow.getStep(state.progress!.currentStepId);
  }

  /// Get all visible steps based on current data
  List<OnboardingStepConfig> getVisibleSteps() {
    if (state.data == null) return [];

    final flow = _ref.read(onboardingFlowProvider);
    return flow.navigationResolver.getVisibleSteps(state.data!);
  }

  // Update setCurrentStep to use OnboardingStepId
  Future<bool> setCurrentStep(OnboardingStepId step) async {
    state = state.withLoading(loading: true);

    final result = await _onboardingService.setCurrentStep(step);

    switch (result) {
      case OnboardingSuccess():
        state = state.copyWith(isLoading: false);
        return true;
      case OnboardingFailure(exception: final exception):
        state = state.copyWith(isLoading: false, error: exception);
        return false;
    }
  }

  // ... rest of methods remain the same
}

/// Provider for current step configuration
final currentStepConfigProvider = Provider<OnboardingStepConfig?>((ref) {
  final progress = ref.watch(onboardingProgressProvider);
  if (progress == null) return null;

  final flow = ref.read(onboardingFlowProvider);
  return flow.getStep(progress.currentStepId);
});

/// Provider for visible steps
final visibleStepsProvider = Provider<List<OnboardingStepConfig>>((ref) {
  final data = ref.watch(onboardingDataProvider);
  if (data == null) return [];

  final flow = ref.read(onboardingFlowProvider);
  return flow.navigationResolver.getVisibleSteps(data);
});

/// Provider for current step display name
final currentStepDisplayNameProvider = Provider<String>((ref) {
  final config = ref.watch(currentStepConfigProvider);
  return config?.displayName ?? '';
});
```

---

## **Phase 6: Screen & Widget Updates (Day 5)**

### 6.1 Update OnboardingScreenWrapper

**File:** `lib/features/onboarding/widgets/onboarding_screen_wrapper.dart`

```dart
// Update to use flow configuration:

class OnboardingScreenWrapper extends ConsumerWidget {
  const OnboardingScreenWrapper({
    required this.child,
    this.showProgress = true,
    super.key,
  });

  final Widget child;
  final bool showProgress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // NEW: Get current step config from flow
    final currentConfig = ref.watch(currentStepConfigProvider);
    final visibleSteps = ref.watch(visibleStepsProvider);
    final progress = ref.watch(onboardingProgressProvider);

    if (currentConfig == null) {
      return Scaffold(body: child);
    }

    // Calculate progress based on visible steps
    final currentIndex = visibleSteps.indexWhere(
      (step) => step.id == currentConfig.id,
    );
    final progressPercentage = currentIndex >= 0
        ? (currentIndex + 1) / visibleSteps.length
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(currentConfig.displayName),
        leading: currentConfig.canGoBack
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () async {
                  final route = await ref
                      .read(onboardingProvider.notifier)
                      .navigatePrevious();
                  if (route != null && context.mounted) {
                    context.go(route);
                  }
                },
              )
            : null,
      ),
      body: Column(
        children: [
          if (showProgress)
            OnboardingProgressIndicator(
              currentStep: currentIndex + 1,
              totalSteps: visibleSteps.length,
              percentage: progressPercentage,
            ),
          Expanded(child: child),
        ],
      ),
    );
  }
}
```

---

### 6.2 Update Screen Validations

Apply this pattern to all screens (`pet_basics_screen.dart`, `ckd_medical_info_screen.dart`, `onboarding_completion_screen.dart`):

```dart
// Before:
final canContinue = ref.watch(canProgressFromCurrentStepProvider);

// After:
final currentConfig = ref.watch(currentStepConfigProvider);
final onboardingData = ref.watch(onboardingDataProvider);
final canContinue = currentConfig?.isValid(
  onboardingData ?? const OnboardingData.empty()
) ?? false;

// Or use a computed provider for cleaner code:
final canContinueProvider = Provider<bool>((ref) {
  final config = ref.watch(currentStepConfigProvider);
  final data = ref.watch(onboardingDataProvider);
  return config?.isValid(data ?? const OnboardingData.empty()) ?? false;
});
```

---

## **Phase 7: Router Integration (Day 5)**

### 7.1 Update Router Configuration

**File:** `lib/app/router.dart`

**Option A: Keep Manual Route Definitions** (Recommended for initial implementation)

No changes needed - routes stay the same, just update redirect logic if using step IDs.

**Option B: Generate Routes from Flow** (Future enhancement)

```dart
// In appRouterProvider:
final flow = ref.read(onboardingFlowProvider);

return GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const AppShell(),
      routes: [
        // Onboarding parent route
        GoRoute(
          path: 'onboarding',
          routes: [
            // Generate onboarding routes from flow configuration
            ...flow.steps.map((stepConfig) {
              final pathSegment = stepConfig.route
                  .replaceFirst('/onboarding/', '');

              return GoRoute(
                path: pathSegment,
                name: stepConfig.id.id,
                builder: (context, state) => _buildStepScreen(stepConfig),
              );
            }),
          ],
        ),
        // Other routes...
      ],
    ),
  ],
);

// Helper to build screen for each step
Widget _buildStepScreen(OnboardingStepConfig config) {
  return switch (config.id) {
    OnboardingSteps.welcome => const WelcomeScreen(),
    OnboardingSteps.petBasics => const PetBasicsScreen(),
    OnboardingSteps.medicalInfo => const CkdMedicalInfoScreen(),
    OnboardingSteps.completion => const OnboardingCompletionScreen(),
    _ => throw UnimplementedError(
      'Screen not implemented for ${config.id}',
    ),
  };
}
```

---

## **Phase 8: Testing (Day 6-7)**

### 8.1 Unit Tests

**File:** `test/features/onboarding/flow/navigation_resolver_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/features/onboarding/flow/onboarding_flow.dart';
import 'package:hydracat/features/onboarding/models/onboarding_data.dart';
import 'package:hydracat/features/onboarding/models/onboarding_step_id.dart';

void main() {
  group('NavigationResolver', () {
    late OnboardingFlow flow;

    setUp(() {
      flow = defaultOnboardingFlow;
    });

    test('getNextStep returns pet basics after welcome', () {
      final next = flow.navigationResolver.getNextStep(
        OnboardingSteps.welcome,
        const OnboardingData.empty(),
      );

      expect(next, equals(OnboardingSteps.petBasics));
    });

    test('getNextStep returns null at completion', () {
      final next = flow.navigationResolver.getNextStep(
        OnboardingSteps.completion,
        const OnboardingData.empty(),
      );

      expect(next, isNull);
    });

    test('getPreviousStep returns null at welcome', () {
      final prev = flow.navigationResolver.getPreviousStep(
        OnboardingSteps.welcome,
        const OnboardingData.empty(),
      );

      expect(prev, isNull);
    });

    test('calculateProgress returns correct percentage', () {
      final progress = flow.navigationResolver.calculateProgress(
        OnboardingSteps.petBasics,
        const OnboardingData.empty(),
      );

      // Step 2 of 4 = 0.5
      expect(progress, equals(0.5));
    });

    test('getVisibleSteps returns all steps when no conditions', () {
      final visibleSteps = flow.navigationResolver.getVisibleSteps(
        const OnboardingData.empty(),
      );

      expect(visibleSteps.length, equals(4));
    });
  });
}
```

**File:** `test/features/onboarding/validators/pet_basics_validator_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/features/onboarding/models/onboarding_data.dart';
import 'package:hydracat/features/onboarding/validators/pet_basics_validator.dart';

void main() {
  group('PetBasicsValidator', () {
    const validator = PetBasicsValidator();

    test('validates complete data as valid', () {
      final data = const OnboardingData.empty().copyWith(
        petName: 'Fluffy',
        petAge: 5,
        petGender: 'female',
      );

      final result = validator.validate(data);
      expect(result.isValid, isTrue);
    });

    test('invalidates missing pet name', () {
      final data = const OnboardingData.empty().copyWith(
        petAge: 5,
        petGender: 'female',
      );

      final missing = validator.getMissingFields(data);
      expect(missing, contains('Pet name'));
    });

    test('invalidates missing age and date of birth', () {
      final data = const OnboardingData.empty().copyWith(
        petName: 'Fluffy',
        petGender: 'female',
      );

      final missing = validator.getMissingFields(data);
      expect(missing, contains('Pet age or date of birth'));
    });

    test('invalidates pet name over 50 characters', () {
      final data = const OnboardingData.empty().copyWith(
        petName: 'A' * 51,
        petAge: 5,
        petGender: 'female',
      );

      final result = validator.validate(data);
      expect(result.isValid, isFalse);
      expect(result.errors.first, contains('50 characters'));
    });
  });
}
```

---

### 8.2 Integration Tests

**File:** `test/features/onboarding/services/onboarding_service_test.dart`

```dart
// Update existing tests to work with new flow system

import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/features/onboarding/flow/onboarding_flow.dart';
import 'package:hydracat/features/onboarding/models/onboarding_step_id.dart';
import 'package:hydracat/features/onboarding/services/onboarding_service.dart';

void main() {
  group('OnboardingService with Flow', () {
    late OnboardingService service;

    setUp(() {
      service = OnboardingService(flow: defaultOnboardingFlow);
    });

    tearDown(() {
      service.dispose();
    });

    test('starts onboarding at welcome step', () async {
      final result = await service.startOnboarding('test_user');

      expect(result, isA<OnboardingSuccess>());
      expect(
        service.currentProgress?.currentStepId,
        equals(OnboardingSteps.welcome),
      );
    });

    test('navigation uses flow configuration', () async {
      await service.startOnboarding('test_user');

      // Should be at welcome step
      expect(
        service.currentProgress?.currentStepId,
        equals(OnboardingSteps.welcome),
      );

      // Move to next step
      await service.moveToNextStep();

      // Should be at pet basics
      expect(
        service.currentProgress?.currentStepId,
        equals(OnboardingSteps.petBasics),
      );
    });

    test('validates using flow configuration', () async {
      await service.startOnboarding('test_user');
      await service.moveToNextStep(); // Move to pet basics

      // Try to move without valid data - should fail
      final result = await service.moveToNextStep();

      expect(result, isA<OnboardingFailure>());
    });
  });
}
```

---

## **Phase 9: Documentation & Cleanup (Day 7)**

### 9.1 Create Architecture Documentation

**File:** `~PLANNING/onboarding_flow_architecture.md`

```markdown
# Onboarding Flow Architecture

## Overview
The onboarding system uses a declarative, graph-based flow configuration
that allows for conditional navigation and dynamic step visibility.

## Key Components

### OnboardingStepId
Type-safe step identifiers using sealed classes:
```dart
class MyStepId extends OnboardingStepId {
  const MyStepId() : super('my_step');
}
```

### OnboardingStepConfig
Configuration object for each step:
- `id`: Unique step identifier
- `displayName`: User-facing name
- `route`: GoRouter path
- `validator`: Step-specific validation
- `navigationResolver`: Custom navigation logic (optional)
- `visibilityCondition`: When to show step (optional)

### OnboardingFlow
Registry of all steps in the flow, provides navigation resolver.

## Adding a New Step

### 1. Define Step ID
```dart
class MyNewStepId extends OnboardingStepId {
  const MyNewStepId() : super('my_new_step');
}

// Add to OnboardingSteps
class OnboardingSteps {
  static const myNewStep = MyNewStepId();
  // ... other steps
}
```

### 2. Create Validator (if needed)
```dart
class MyNewStepValidator extends BaseStepValidator {
  const MyNewStepValidator();

  @override
  List<String> getMissingFields(OnboardingData data) {
    final missing = <String>[];

    if (data.myRequiredField == null) {
      missing.add('My Required Field');
    }

    return missing;
  }
}
```

### 3. Add to Flow Configuration
```dart
// In onboarding_flow.dart
const myFlow = OnboardingFlow([
  // ... existing steps

  OnboardingStepConfig(
    id: OnboardingSteps.myNewStep,
    displayName: 'My New Step',
    route: '/onboarding/my-step',
    analyticsEventName: 'onboarding_my_step_viewed',
    validator: MyNewStepValidator(),
    canSkip: false,
    canGoBack: true,
    isCheckpoint: true,
  ),
]);
```

### 4. Create Screen Widget
```dart
class MyNewStepScreen extends ConsumerStatefulWidget {
  const MyNewStepScreen({super.key});

  @override
  ConsumerState<MyNewStepScreen> createState() => _MyNewStepScreenState();
}

class _MyNewStepScreenState extends ConsumerState<MyNewStepScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final canContinue = ref.watch(currentStepConfigProvider)?.isValid(
      ref.watch(onboardingDataProvider) ?? const OnboardingData.empty()
    ) ?? false;

    return OnboardingScreenWrapper(
      child: Column(
        children: [
          // Your UI here

          ElevatedButton(
            onPressed: canContinue ? _handleContinue : null,
            child: Text(l10n.continueButton),
          ),
        ],
      ),
    );
  }

  Future<void> _handleContinue() async {
    final notifier = ref.read(onboardingProvider.notifier);

    // Update data if needed
    final updatedData = ref.read(onboardingDataProvider)!.copyWith(
      // ... your data updates
    );
    await notifier.updateData(updatedData);

    // Navigate to next step
    final nextRoute = await notifier.navigateNext();
    if (nextRoute != null && mounted) {
      context.go(nextRoute);
    }
  }
}
```

### 5. Add Route (if using manual routes)
```dart
// In router.dart
GoRoute(
  path: 'my-step',
  name: 'onboarding-my-step',
  builder: (context, state) => const MyNewStepScreen(),
),
```

### 6. Update OnboardingData (if collecting new data)
```dart
class OnboardingData {
  // Add your new field
  final String? myNewField;

  // Update copyWith, toJson, fromJson, etc.
}
```

## Conditional Navigation

### Basic Example: Skip Step Based on Condition
```dart
OnboardingStepConfig(
  id: ConditionalStepId(),
  visibilityCondition: (data) => data.someCondition == true,
  // ... other config
),
```

### Advanced Example: Branch Based on User Choice
```dart
OnboardingStepConfig(
  id: ChoiceStepId(),
  navigationResolver: (data) {
    if (data.userChoice == 'option_a') {
      return StepForOptionA();
    } else if (data.userChoice == 'option_b') {
      return StepForOptionB();
    } else {
      return DefaultNextStep();
    }
  },
  // ... other config
),
```

## Testing

### Unit Test a Validator
```dart
test('validator checks required field', () {
  const validator = MyValidator();
  final data = OnboardingData.empty();

  expect(validator.getMissingFields(data), contains('Required Field'));
});
```

### Test Navigation Flow
```dart
test('navigation follows custom resolver', () {
  final flow = OnboardingFlow([/* your steps */]);
  final data = OnboardingData.empty().copyWith(choice: 'option_a');

  final next = flow.navigationResolver.getNextStep(
    ChoiceStepId(),
    data,
  );

  expect(next, equals(StepForOptionA()));
});
```

## Best Practices

1. **Keep validators simple**: One validator per step, focused on that step's requirements
2. **Use visibility conditions for optional steps**: Better than complex navigation logic
3. **Prefer linear navigation**: Only use custom navigation resolvers when needed
4. **Test navigation paths**: Especially for conditional branches
5. **Document step dependencies**: In comments or architecture docs
6. **Use checkpoint saves strategically**: After steps with significant data entry

## Migration Notes

### From Legacy Enum System
- Old checkpoints are automatically migrated
- `OnboardingStepType` is deprecated but still supported
- New code should use `OnboardingStepId` system
- Migration happens transparently during checkpoint loading

### Deprecation Timeline
- v1.0: Both systems supported (current)
- v1.1: Warnings when loading legacy checkpoints
- v2.0: Remove legacy enum system completely
```

---

### 9.2 Update CLAUDE.md

Add this section to the main CLAUDE.md file:

```markdown
## Onboarding Flow System

The onboarding uses a declarative flow configuration system that supports conditional navigation and dynamic step visibility.

### Architecture
- **Step Configuration**: `lib/features/onboarding/flow/onboarding_flow.dart`
- **Step Identifiers**: Type-safe sealed classes in `lib/features/onboarding/models/onboarding_step_id.dart`
- **Validators**: Step-specific validators in `lib/features/onboarding/validators/`
- **Navigation**: Dynamic navigation via `NavigationResolver`

### Adding New Steps
1. Define a step ID class extending `OnboardingStepId`
2. Create a validator implementing `StepValidator` (if needed)
3. Add step config to `defaultOnboardingFlow` in `onboarding_flow.dart`
4. Create screen widget
5. Add route to router (if using manual routes)
6. Update `OnboardingData` model if collecting new data

See `~PLANNING/onboarding_flow_architecture.md` for detailed guide with examples.

### Key Benefits
- ✅ No switch expressions to update when adding steps
- ✅ Support for conditional navigation based on user data
- ✅ Step visibility conditions (show/hide steps dynamically)
- ✅ Centralized validation logic
- ✅ Easy to test navigation flows
- ✅ Backward compatible with existing checkpoints
```

---

## 🧪 Testing Checklist

### Unit Tests
- [ ] Navigation resolver tests (all paths)
- [ ] Step configuration tests
- [ ] Pet basics validator tests
- [ ] Medical info validator tests
- [ ] Completion validator tests
- [ ] Migration utility tests
- [ ] Step ID equality tests

### Integration Tests
- [ ] OnboardingService with new flow
- [ ] Navigation through all steps
- [ ] Validation at each step
- [ ] Checkpoint save/resume with new format
- [ ] Migration from legacy checkpoints

### Widget Tests
- [ ] Screen wrapper with flow configuration
- [ ] Pet basics screen with new validators
- [ ] Medical info screen
- [ ] Completion screen
- [ ] Progress indicators show correct values

### Manual Testing
- [ ] Complete happy path (all 4 steps)
- [ ] Skip welcome screen
- [ ] Back navigation from each step
- [ ] App close and resume from checkpoint
- [ ] Invalid data validation at each step
- [ ] Analytics events fire correctly
- [ ] Debug replay mode works
- [ ] Legacy checkpoint data loads correctly
- [ ] Progress indicators update correctly
- [ ] Error messages are user-friendly

---

## 🚀 Deployment Strategy

### Phase 1: Development Testing (Week 1)
- Deploy to development flavor only
- Internal team testing
- Verify all existing functionality works
- Monitor for any issues

### Phase 2: Staged Rollout (Week 2-3)
```dart
// Feature flag approach
final useNewFlowEngine = ref.watch(
  featureFlagProvider('new_onboarding_flow'),
);

final service = useNewFlowEngine
    ? OnboardingService(flow: defaultOnboardingFlow)
    : LegacyOnboardingService();
```

**Rollout schedule:**
- Day 1-3: 10% of users
- Day 4-7: 25% of users
- Day 8-10: 50% of users
- Day 11-14: 100% of users

**Rollback trigger:** If any metric degrades >5%

### Phase 3: Monitoring (Ongoing)
**Key Metrics:**
- Onboarding completion rate (target: no change)
- Average time per step (target: no change)
- Error rate (target: decrease by 10%+)
- Checkpoint resume success rate (target: increase)

**Alerts:**
- Completion rate drops >5% → Rollback
- Error rate increases >10% → Investigate
- Checkpoint failures >1% → Urgent fix

---

## 📊 Success Metrics

After 2 weeks at 100% rollout:

- [ ] Onboarding completion rate unchanged or improved
- [ ] No increase in abandonment rate
- [ ] Error rate decreased (better validation)
- [ ] Developer velocity improved (new step in <30min)
- [ ] Zero navigation bugs
- [ ] Test coverage >80%
- [ ] All legacy checkpoints migrated successfully

---

## 🎯 Future Enhancements

Once base refactor is stable, consider:

1. **A/B Testing Support**
   ```dart
   final flow = ref.read(abTestProvider).variant == 'short'
       ? shortOnboardingFlow
       : defaultOnboardingFlow;
   ```

2. **Remote Configuration**
   ```dart
   final flow = await FlowConfigService().loadFromFirebase();
   ```

3. **Visual Flow Editor** (Debug mode)
   - Show flow diagram
   - Click steps to preview
   - Highlight current path

4. **Analytics Funnel Visualization**
   - Where users drop off
   - Average time per step
   - Conversion optimization

5. **Conditional Sub-Flows**
   - Pet type-specific flows (cat vs dog)
   - Disease-specific flows (CKD vs diabetes)
   - Experience level flows (first-time vs experienced)

---

## 📁 Complete File Inventory

### New Files (18 files)
```
lib/features/onboarding/
├── flow/
│   ├── onboarding_flow.dart (200 lines)
│   ├── onboarding_step_config.dart (80 lines)
│   ├── navigation_resolver.dart (120 lines)
│   └── step_validator.dart (60 lines)
├── validators/
│   ├── validators.dart (5 lines)
│   ├── always_valid_validator.dart (12 lines)
│   ├── pet_basics_validator.dart (60 lines)
│   ├── medical_info_validator.dart (15 lines)
│   └── completion_validator.dart (30 lines)
├── models/
│   └── onboarding_step_id.dart (60 lines)
└── migration/
    └── step_type_migration.dart (30 lines)

~PLANNING/
├── onboarding_flow_architecture.md (300 lines)
└── onboarding_refactor.md (this file)

test/features/onboarding/
├── flow/
│   ├── navigation_resolver_test.dart (100 lines)
│   ├── onboarding_flow_test.dart (80 lines)
│   └── step_config_test.dart (60 lines)
├── validators/
│   ├── pet_basics_validator_test.dart (80 lines)
│   └── completion_validator_test.dart (50 lines)
└── migration/
    └── step_type_migration_test.dart (60 lines)
```

### Modified Files (10 files)
```
lib/features/onboarding/
├── models/
│   ├── onboarding_progress.dart (~50 lines changed)
│   └── onboarding_step.dart (~30 lines changed)
├── services/
│   └── onboarding_service.dart (~100 lines changed)
├── widgets/
│   └── onboarding_screen_wrapper.dart (~20 lines changed)
└── screens/
    ├── pet_basics_screen.dart (~10 lines changed)
    ├── ckd_medical_info_screen.dart (~10 lines changed)
    └── onboarding_completion_screen.dart (~10 lines changed)

lib/providers/
└── onboarding_provider.dart (~40 lines added)

lib/app/
└── router.dart (~5 lines changed, optional)

CLAUDE.md (~20 lines added)
```

### Deprecated Files (to mark)
```
lib/features/onboarding/models/
└── onboarding_step.dart
    - OnboardingStepType enum marked @Deprecated
    - Keep for migration support
    - Remove in v2.0
```

**Total LOC:**
- New code: ~1,400 lines
- Modified code: ~300 lines
- Tests: ~430 lines
- Documentation: ~500 lines

---

## ✅ Definition of Done

### Code Complete
- [ ] All 18 new files created and implemented
- [ ] All 10 modified files updated
- [ ] OnboardingStepType enum marked as deprecated
- [ ] Migration utilities implemented

### Testing Complete
- [ ] All existing tests pass (100%)
- [ ] New unit tests written and passing (>80% coverage)
- [ ] Integration tests pass
- [ ] Widget tests updated and passing
- [ ] Manual testing checklist completed

### Documentation Complete
- [ ] Architecture doc created (`onboarding_flow_architecture.md`)
- [ ] CLAUDE.md updated with new patterns
- [ ] Code comments updated
- [ ] Examples provided for common scenarios

### Deployment Ready
- [ ] Feature flag implemented
- [ ] Rollout plan approved
- [ ] Monitoring dashboards created
- [ ] Rollback procedure tested
- [ ] Analytics verification completed

### Team Ready
- [ ] Code review completed
- [ ] Team walkthrough conducted
- [ ] Migration guide shared
- [ ] Questions answered

---

## 🎓 Example: Complete New Step Implementation

Here's a complete example of adding a conditional "Medical Records Check" step:

### 1. Update OnboardingData
```dart
// Add to lib/features/onboarding/models/onboarding_data.dart
class OnboardingData {
  final bool? hasMedicalRecords;

  // Add to copyWith, toJson, fromJson
}
```

### 2. Create Step ID
```dart
// Add to lib/features/onboarding/models/onboarding_step_id.dart
class MedicalRecordsCheckStepId extends OnboardingStepId {
  const MedicalRecordsCheckStepId() : super('medical_records_check');
}

class OnboardingSteps {
  static const medicalRecordsCheck = MedicalRecordsCheckStepId();
  // ...
}
```

### 3. Create Screen
```dart
// lib/features/onboarding/screens/medical_records_check_screen.dart
class MedicalRecordsCheckScreen extends ConsumerWidget {
  const MedicalRecordsCheckScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    return OnboardingScreenWrapper(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l10n.medicalRecordsCheckTitle,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Text(l10n.medicalRecordsCheckDescription),
            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: () => _handleChoice(ref, context, hasRecords: true),
              child: Text(l10n.yesIHaveThem),
            ),
            const SizedBox(height: 16),

            OutlinedButton(
              onPressed: () => _handleChoice(ref, context, hasRecords: false),
              child: Text(l10n.noIDont),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleChoice(
    WidgetRef ref,
    BuildContext context, {
    required bool hasRecords,
  }) async {
    final notifier = ref.read(onboardingProvider.notifier);

    final updatedData = ref.read(onboardingDataProvider)!.copyWith(
      hasMedicalRecords: hasRecords,
    );

    await notifier.updateData(updatedData);

    final nextRoute = await notifier.navigateNext();
    if (nextRoute != null && context.mounted) {
      context.go(nextRoute);
    }
  }
}
```

### 4. Update Flow Configuration
```dart
// lib/features/onboarding/flow/onboarding_flow.dart
const defaultOnboardingFlow = OnboardingFlow([
  // ... welcome, pet basics

  // NEW: Medical records check
  OnboardingStepConfig(
    id: OnboardingSteps.medicalRecordsCheck,
    displayName: 'Medical Records',
    route: '/onboarding/medical-check',
    analyticsEventName: 'onboarding_medical_check_viewed',
    validator: AlwaysValidValidator(),
    canSkip: false,
    canGoBack: true,
    // Conditional navigation based on choice
    navigationResolver: (data) {
      if (data.hasMedicalRecords == true) {
        return OnboardingSteps.medicalInfo; // Show detailed medical info
      } else {
        return OnboardingSteps.completion; // Skip to end
      }
    },
  ),

  // Medical info step - only visible if user has records
  OnboardingStepConfig(
    id: OnboardingSteps.medicalInfo,
    // ... existing config
    visibilityCondition: (data) => data.hasMedicalRecords == true,
  ),

  // ... completion
]);
```

### 5. Add Route
```dart
// lib/app/router.dart
GoRoute(
  path: 'medical-check',
  name: 'onboarding-medical-check',
  builder: (context, state) => const MedicalRecordsCheckScreen(),
),
```

### 6. Add Localization
```json
// lib/l10n/app_en.arb
{
  "medicalRecordsCheckTitle": "Medical Records",
  "medicalRecordsCheckDescription": "Do you have your cat's medical records handy?",
  "yesIHaveThem": "Yes, I have them",
  "noIDont": "No, I don't"
}
```

**Time to implement:** ~20 minutes
**Files created:** 1
**Files modified:** 4
**Switch expressions updated:** 0
**Breaking changes:** 0

---

This plan provides a complete roadmap for modernizing your onboarding system. Each phase builds incrementally, and you can pause at any phase for testing and validation before proceeding. The key is maintaining backward compatibility while introducing the new system.
