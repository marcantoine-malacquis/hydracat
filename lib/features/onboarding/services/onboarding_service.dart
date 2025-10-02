/// Onboarding service for managing multi-step flow and persistence
///
/// Handles onboarding flow state, automatic checkpoint saves, analytics
/// integration, and seamless integration with pet profile creation.
library;

import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:hydracat/features/onboarding/exceptions/onboarding_exceptions.dart';
import 'package:hydracat/features/onboarding/models/onboarding_data.dart';
import 'package:hydracat/features/onboarding/models/onboarding_progress.dart';
import 'package:hydracat/features/onboarding/models/onboarding_step.dart';
import 'package:hydracat/features/profile/models/user_persona.dart';
import 'package:hydracat/features/profile/services/pet_service.dart';
import 'package:hydracat/features/profile/services/schedule_service.dart';
import 'package:hydracat/shared/services/firebase_service.dart';
import 'package:hydracat/shared/services/secure_preferences_service.dart';

/// Result type for onboarding service operations
sealed class OnboardingResult {
  /// Creates an [OnboardingResult] instance
  const OnboardingResult();
}

/// Successful onboarding operation result
class OnboardingSuccess extends OnboardingResult {
  /// Creates an [OnboardingSuccess] with optional data
  const OnboardingSuccess([this.data]);

  /// Optional result data
  final dynamic data;
}

/// Failed onboarding operation result
class OnboardingFailure extends OnboardingResult {
  /// Creates an [OnboardingFailure] with an onboarding exception
  const OnboardingFailure(this.exception);

  /// The onboarding exception with user-friendly message
  final OnboardingException exception;

  /// Convenience getter for error message
  String get message => exception.message;

  /// Convenience getter for error code
  String? get code => exception.code;
}

/// Service for managing onboarding flow with automatic checkpoints
///
/// Provides comprehensive onboarding management including:
/// - Multi-step flow navigation
/// - Automatic checkpoint saves
/// - Analytics integration
/// - Pet profile creation
/// - Offline support
class OnboardingService {
  /// Factory constructor to get the singleton instance
  factory OnboardingService() => _instance ??= OnboardingService._();

  /// Private constructor
  OnboardingService._();
  static OnboardingService? _instance;

  /// Pet service for profile operations
  final PetService _petService = PetService();

  /// Schedule service for treatment schedule operations
  final ScheduleService _scheduleService = const ScheduleService();

  /// Secure preferences for local storage
  final SecurePreferencesService _preferences = SecurePreferencesService();

  /// Firebase Analytics instance
  FirebaseAnalytics get _analytics => FirebaseService().analytics;

  /// Preference keys for local storage
  static const String _onboardingDataKey = 'onboarding_data';
  static const String _onboardingProgressKey = 'onboarding_progress';

  /// Current onboarding session data
  OnboardingData? _currentData;
  OnboardingProgress? _currentProgress;

  /// Stream controller for onboarding state changes
  final StreamController<OnboardingProgress?> _progressController =
      StreamController<OnboardingProgress?>.broadcast();

  /// Stream of onboarding progress updates
  Stream<OnboardingProgress?> get progressStream => _progressController.stream;

  /// Current onboarding progress (read-only)
  OnboardingProgress? get currentProgress => _currentProgress;

  /// Current onboarding data (read-only)
  OnboardingData? get currentData => _currentData;

  /// Whether onboarding is currently active
  bool get isActive =>
      _currentProgress != null && !_currentProgress!.isComplete;

  /// Starts a new onboarding session for the given user
  ///
  /// Returns [OnboardingSuccess] if started successfully,
  /// [OnboardingFailure] if user already has completed onboarding.
  Future<OnboardingResult> startOnboarding(String userId) async {
    if (kDebugMode) {
      debugPrint('[OnboardingService] Starting onboarding for user: $userId');
    }

    try {
      // Check if user already completed onboarding by checking for existing
      // pets
      if (kDebugMode) {
        debugPrint('[OnboardingService] Checking for existing pets...');
      }

      final existingPet = await _petService.getPrimaryPet();

      if (kDebugMode) {
        final resultMessage = existingPet != null
            ? 'Found pet ${existingPet.name}'
            : 'No pets found';
        debugPrint(
          '[OnboardingService] Existing pet check result: $resultMessage',
        );
      }

      if (existingPet != null) {
        if (kDebugMode) {
          debugPrint(
            '[OnboardingService] Onboarding blocked - user already has pet: '
            '${existingPet.name}',
          );
        }
        return const OnboardingFailure(
          OnboardingAlreadyCompletedException(),
        );
      }

      if (kDebugMode) {
        debugPrint('[OnboardingService] Initializing fresh onboarding data...');
      }

      // Initialize fresh onboarding data and progress
      _currentData = const OnboardingData.empty().copyWith(userId: userId);
      _currentProgress = OnboardingProgress.initial(userId: userId);

      if (kDebugMode) {
        debugPrint('[OnboardingService] Tracking analytics event...');
      }

      // Track analytics
      await _trackAnalyticsEvent('onboarding_started', {
        'user_id': userId,
        'timestamp': DateTime.now().toIso8601String(),
      });

      if (kDebugMode) {
        debugPrint('[OnboardingService] Saving initial checkpoint...');
      }

      // Save initial state
      await _saveCheckpoint();

      if (kDebugMode) {
        debugPrint('[OnboardingService] Notifying progress listeners...');
      }

      // Notify listeners
      _progressController.add(_currentProgress);

      if (kDebugMode) {
        debugPrint('[OnboardingService] Onboarding started successfully');
      }

      return const OnboardingSuccess();
    } on Exception catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[OnboardingService] ERROR: Failed to start onboarding: $e',
        );
        debugPrint('[OnboardingService] Stack trace: ${StackTrace.current}');
      }
      return OnboardingFailure(
        OnboardingServiceException('Failed to start onboarding: $e'),
      );
    }
  }

  /// Resumes onboarding from saved checkpoint data
  ///
  /// Returns [OnboardingSuccess] with existing data if found,
  /// [OnboardingFailure] if no saved data exists.
  Future<OnboardingResult> resumeOnboarding(String userId) async {
    try {
      // Load saved data from preferences
      final savedData = await _loadFromCheckpoint(userId);
      if (savedData == null) {
        return const OnboardingFailure(
          OnboardingDataNotFoundException(),
        );
      }

      final (data, progress) = savedData;
      _currentData = data;
      _currentProgress = progress;

      // Track analytics
      await _trackAnalyticsEvent('onboarding_resumed', {
        'user_id': userId,
        'current_step': progress.currentStep.name,
        'progress_percentage': progress.progressPercentage,
      });

      // Notify listeners
      _progressController.add(_currentProgress);

      return OnboardingSuccess(_currentData);
    } on Exception catch (e) {
      return OnboardingFailure(
        OnboardingServiceException('Failed to resume onboarding: $e'),
      );
    }
  }

  /// Updates onboarding data and triggers automatic checkpoint saves
  ///
  /// Automatically saves at checkpoint steps (persona, petBasics).
  Future<OnboardingResult> updateData(OnboardingData newData) async {
    try {
      if (_currentProgress == null) {
        return const OnboardingFailure(
          OnboardingServiceException('No active onboarding session'),
        );
      }

      // Validate the new data
      final validationErrors = newData.validate();
      if (validationErrors.isNotEmpty) {
        return OnboardingFailure(
          OnboardingValidationException(validationErrors),
        );
      }

      // Update current data
      _currentData = newData;

      // Update progress validation
      final isValid = _isCurrentStepValid(newData);
      _currentProgress = _currentProgress!.updateCurrentStepValidation(
        isValid: isValid,
        validationErrors: validationErrors,
      );

      // Auto-save at checkpoint steps
      if (_currentProgress!.isCurrentStepCheckpoint) {
        await _saveCheckpoint();
      }

      // Notify listeners
      _progressController.add(_currentProgress);

      return const OnboardingSuccess();
    } on Exception catch (e) {
      return OnboardingFailure(
        OnboardingServiceException('Failed to update data: $e'),
      );
    }
  }

  /// Moves to the next step in the onboarding flow
  ///
  /// Validates current step before proceeding and tracks analytics.
  Future<OnboardingResult> moveToNextStep() async {
    try {
      if (_currentProgress == null || _currentData == null) {
        return const OnboardingFailure(
          OnboardingServiceException('No active onboarding session'),
        );
      }

      // Check if current step can progress
      if (!_currentProgress!.canProgressFromCurrentStep) {
        return const OnboardingFailure(
          OnboardingIncompleteDataException(),
        );
      }

      final previousStep = _currentProgress!.currentStep;

      // Move to next step
      _currentProgress = _currentProgress!.moveToNextStep();

      // Track step completion analytics
      await _trackAnalyticsEvent('onboarding_step_completed', {
        'user_id': _currentData!.userId,
        'step': previousStep.name,
        'next_step': _currentProgress!.currentStep.name,
        'progress_percentage': _currentProgress!.progressPercentage,
      });

      // Auto-save if new step is a checkpoint
      if (_currentProgress!.isCurrentStepCheckpoint) {
        await _saveCheckpoint();
      }

      // Notify listeners
      _progressController.add(_currentProgress);

      return const OnboardingSuccess();
    } on Exception {
      return OnboardingFailure(
        OnboardingNavigationException(
          _currentProgress?.currentStep.name ?? 'unknown',
        ),
      );
    }
  }

  /// Moves to the previous step in the onboarding flow
  ///
  /// Only allows backward navigation when permitted by step configuration.
  Future<OnboardingResult> moveToPreviousStep() async {
    try {
      if (_currentProgress == null) {
        return const OnboardingFailure(
          OnboardingServiceException('No active onboarding session'),
        );
      }

      if (!_currentProgress!.canGoBack) {
        return OnboardingFailure(
          OnboardingNavigationException(
            'back from ${_currentProgress!.currentStep.name}',
          ),
        );
      }

      _currentProgress = _currentProgress!.moveToPreviousStep();

      // Notify listeners
      _progressController.add(_currentProgress);

      return const OnboardingSuccess();
    } on Exception {
      return OnboardingFailure(
        OnboardingNavigationException(
          'back from ${_currentProgress?.currentStep.name ?? 'unknown'}',
        ),
      );
    }
  }

  /// Sets the current step in the onboarding flow
  ///
  /// Used to fix progress mismatches between UI state and onboarding progress.
  Future<OnboardingResult> setCurrentStep(OnboardingStepType step) async {
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
          'Failed to set current step to ${step.name}',
        ),
      );
    }
  }

  /// Completes the onboarding flow and creates the pet profile
  ///
  /// Integrates with PetService to create the final pet profile
  /// and cleans up temporary onboarding data.
  Future<OnboardingResult> completeOnboarding() async {
    try {
      if (_currentData == null || _currentProgress == null) {
        return const OnboardingFailure(
          OnboardingServiceException('No active onboarding session'),
        );
      }

      // Ensure we have all required data
      if (!_currentData!.isReadyForProfileCreation) {
        return const OnboardingFailure(
          OnboardingIncompleteDataException('complete pet information'),
        );
      }

      // Create pet profile via PetService
      final petResult = await _petService.createPet(
        _currentData!.toCatProfile(
          petId: _generatePetId(),
        )!,
      );

      if (petResult is PetFailure) {
        return OnboardingFailure(
          OnboardingProfileCreationException(petResult.message),
        );
      }

      final petProfile = (petResult as PetSuccess).pet;

      // Create fluid therapy schedule if applicable
      if (_currentData!.fluidTherapy != null &&
          _currentData!.treatmentApproach!.includesFluidTherapy) {
        try {
          final scheduleDto = _currentData!.fluidTherapy!.toSchedule();
          await _scheduleService.createSchedule(
            userId: _currentData!.userId!,
            petId: petProfile.id,
            scheduleDto: scheduleDto,
          );

          if (kDebugMode) {
            debugPrint(
              '[OnboardingService] Successfully created fluid schedule '
              'for pet ${petProfile.id}',
            );
          }
        } on Exception catch (e) {
          // Log the error but don't fail the entire onboarding
          if (kDebugMode) {
            debugPrint(
              '[OnboardingService] Failed to create fluid schedule: $e',
            );
          }
          // Could optionally track this as a non-fatal error
        }
      }

      // Create medication schedules if applicable
      if (_currentData!.medications != null &&
          _currentData!.medications!.isNotEmpty) {
        try {
          if (kDebugMode) {
            debugPrint(
              '[OnboardingService] Creating '
              '${_currentData!.medications!.length} medication schedules '
              'for pet ${petProfile.id}',
            );
          }

          // Create all schedules in a single batch operation for efficiency
          final scheduleDtos = _currentData!.medications!
              .map((medication) => medication.toSchedule())
              .toList();

          await _scheduleService.createSchedulesBatch(
            userId: _currentData!.userId!,
            petId: petProfile.id,
            scheduleDtos: scheduleDtos,
          );

          if (kDebugMode) {
            debugPrint(
              '[OnboardingService] Successfully created all medication '
              'schedules for pet ${petProfile.id}',
            );
          }
        } on Exception catch (e) {
          // Log the error but don't fail the entire onboarding
          if (kDebugMode) {
            debugPrint(
              '[OnboardingService] Failed to create medication schedules: $e',
            );
          }
          // Could optionally track this as a non-fatal error
        }
      }

      // Mark onboarding as completed
      _currentProgress = _currentProgress!.markCompleted();

      // Track completion analytics
      await _trackAnalyticsEvent('onboarding_completed', {
        'user_id': _currentData!.userId,
        'pet_id': petProfile.id,
        'treatment_approach': _currentData!.treatmentApproach!.name,
        'duration_seconds': _currentProgress!.totalDuration?.inSeconds,
        'completion_rate': 1.0,
      });

      // Clean up temporary data
      await _clearCheckpointData(_currentData!.userId!);

      // Notify listeners of completion
      _progressController.add(_currentProgress);

      // Clear current session
      _currentData = null;
      _currentProgress = null;

      return OnboardingSuccess(petProfile);
    } on Exception catch (e) {
      return OnboardingFailure(
        OnboardingProfileCreationException(e.toString()),
      );
    }
  }

  /// Checks if user has incomplete onboarding data
  ///
  /// Used to determine if user should be prompted to complete onboarding.
  Future<bool> hasIncompleteOnboarding(String userId) async {
    try {
      final savedData = await _loadFromCheckpoint(userId);
      if (savedData == null) return false;

      final (_, progress) = savedData;
      return !progress.isComplete;
    } on Exception {
      return false;
    }
  }

  /// Clears all onboarding data for a user
  ///
  /// Used for cleanup after completion or when starting fresh.
  Future<void> clearOnboardingData(String userId) async {
    try {
      await _clearCheckpointData(userId);

      // Clear current session if it matches the user
      if (_currentData?.userId == userId) {
        _currentData = null;
        _currentProgress = null;
        _progressController.add(null);
      }
    } on Exception catch (e) {
      debugPrint('Failed to clear onboarding data: $e');
    }
  }

  /// Disposes of resources and closes streams
  void dispose() {
    _progressController.close();
  }

  // Private helper methods

  /// Validates if current step has valid data
  bool _isCurrentStepValid(OnboardingData data) {
    return switch (_currentProgress!.currentStep) {
      OnboardingStepType.welcome => true,
      OnboardingStepType.userPersona => data.hasPersonaSelection,
      OnboardingStepType.petBasics => data.hasBasicPetInfo,
      OnboardingStepType.ckdMedicalInfo => true, // Optional step, always valid
      OnboardingStepType.treatmentMedication =>
        // For medication step, validate based on persona:
        // 1. For medicationOnly: require at least one medication
        // 2. For medicationAndFluidTherapy: require at least one medication
        // 3. For fluidTherapyOnly: allow progression (skip medications)
        data.treatmentApproach == UserPersona.fluidTherapyOnly ||
            (data.medications != null && data.medications!.isNotEmpty),
      OnboardingStepType.treatmentFluid => data.fluidTherapy != null,
      OnboardingStepType.completion => data.isReadyForProfileCreation,
    };
  }

  /// Saves current onboarding state to local checkpoint
  Future<void> _saveCheckpoint() async {
    if (_currentData == null || _currentProgress == null) return;

    try {
      final userId = _currentData!.userId!;

      await Future.wait<void>([
        _preferences.setSecureData(
          '${_onboardingDataKey}_$userId',
          _currentData!.toJson(),
        ),
        _preferences.setSecureData(
          '${_onboardingProgressKey}_$userId',
          _currentProgress!.toJson(),
        ),
      ]);
    } on Exception {
      throw const OnboardingCheckpointException('save');
    }
  }

  /// Loads onboarding state from local checkpoint
  Future<(OnboardingData, OnboardingProgress)?> _loadFromCheckpoint(
    String userId,
  ) async {
    try {
      final dataJson = await _preferences.getSecureData(
        '${_onboardingDataKey}_$userId',
      );
      final progressJson = await _preferences.getSecureData(
        '${_onboardingProgressKey}_$userId',
      );

      if (dataJson == null || progressJson == null) return null;

      // Parse JSON data back to objects
      final data = OnboardingData.fromJson(dataJson);
      final progress = OnboardingProgress.fromJson(progressJson);

      return (data, progress);
    } on Exception {
      return null;
    }
  }

  /// Clears checkpoint data from local storage
  Future<void> _clearCheckpointData(String userId) async {
    try {
      await Future.wait<void>([
        _preferences.removeSecureData('${_onboardingDataKey}_$userId'),
        _preferences.removeSecureData('${_onboardingProgressKey}_$userId'),
      ]);
    } on Exception {
      throw const OnboardingCheckpointException('clear');
    }
  }

  /// Tracks analytics event with error handling
  Future<void> _trackAnalyticsEvent(
    String eventName,
    Map<String, dynamic> parameters,
  ) async {
    try {
      await _analytics.logEvent(
        name: eventName,
        parameters: Map<String, Object>.from(parameters),
      );
    } on Exception catch (e) {
      // Don't fail the operation for analytics errors
      debugPrint('Analytics tracking failed for $eventName: $e');
    }
  }

  /// Generates a unique pet ID
  String _generatePetId() {
    return 'pet_${DateTime.now().millisecondsSinceEpoch}';
  }
}
