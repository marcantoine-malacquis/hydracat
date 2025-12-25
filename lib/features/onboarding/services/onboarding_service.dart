/// Onboarding service for managing multi-step flow and persistence
///
/// Handles onboarding flow state, automatic checkpoint saves, analytics
/// integration, and seamless integration with pet profile creation.
library;

import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:hydracat/features/onboarding/debug_onboarding_replay.dart';
import 'package:hydracat/features/onboarding/exceptions/onboarding_exceptions.dart';
import 'package:hydracat/features/onboarding/flow/onboarding_flow.dart';
import 'package:hydracat/features/onboarding/models/onboarding_data.dart';
import 'package:hydracat/features/onboarding/models/onboarding_progress.dart';
import 'package:hydracat/features/onboarding/models/onboarding_step_id.dart';
import 'package:hydracat/features/profile/models/cat_profile.dart';
import 'package:hydracat/features/profile/models/lab_measurement.dart';
import 'package:hydracat/features/profile/models/lab_result.dart';
import 'package:hydracat/features/profile/services/pet_service.dart';
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
  /// Factory constructor with optional flow injection
  factory OnboardingService({OnboardingFlow? flow}) {
    _instance ??= OnboardingService._(flow: flow);
    return _instance!;
  }

  /// Private constructor
  OnboardingService._({OnboardingFlow? flow})
      : _flow = flow ?? getOnboardingFlow();

  static OnboardingService? _instance;

  /// Onboarding flow configuration
  final OnboardingFlow _flow;

  /// Pet service for profile operations
  final PetService _petService = PetService();

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
      // Check if debug replay mode is active - if so, bypass existing pet check
      final isDebugReplay = isDebugOnboardingReplayActive();
      if (isDebugReplay && kDebugMode) {
        debugPrint(
          '[OnboardingService] Debug replay mode active - bypassing existing '
          'pet check',
        );
      } else {
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
        'current_step': progress.currentStepId.id,
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
      final currentConfig = _flow.getStep(_currentProgress!.currentStepId);
      if (currentConfig?.isCheckpoint ?? false) {
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

      // Use flow navigation resolver to get next step
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

      final previousStepId = _currentProgress!.currentStepId;

      // Move to next step
      _currentProgress = _currentProgress!.moveToStep(nextStepId);

      // Track step completion analytics
      await _trackAnalyticsEvent('onboarding_step_completed', {
        'user_id': _currentData!.userId,
        'step': previousStepId.id,
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

  /// Moves to the previous step in the onboarding flow
  ///
  /// Only allows backward navigation when permitted by step configuration.
  Future<OnboardingResult> moveToPreviousStep() async {
    try {
      if (_currentProgress == null || _currentData == null) {
        return const OnboardingFailure(
          OnboardingServiceException('No active onboarding session'),
        );
      }

      // Use flow navigation resolver to get previous step
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
  ///
  /// Used to fix progress mismatches between UI state and onboarding progress.
  Future<OnboardingResult> setCurrentStep(OnboardingStepId stepId) async {
    try {
      if (_currentProgress == null) {
        return const OnboardingFailure(
          OnboardingServiceException('No active onboarding session'),
        );
      }

      _currentProgress = _currentProgress!.moveToStep(stepId);

      // Notify listeners
      _progressController.add(_currentProgress);

      return const OnboardingSuccess();
    } on Exception {
      return OnboardingFailure(
        OnboardingServiceException(
          'Failed to set current step to ${stepId.id}',
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

      // Ensure we have all required data (pet basics)
      if (!_currentData!.isComplete) {
        final missingFields = _currentData!.getMissingRequiredFields();
        return OnboardingFailure(
          OnboardingValidationException(missingFields),
        );
      }

      // Check if debug replay mode is active
      final isDebugReplay = isDebugOnboardingReplayActive();
      CatProfile petProfile;

      if (isDebugReplay && kDebugMode) {
        // In replay mode: create a mock pet profile without Firestore writes
        debugPrint(
          '[OnboardingService] Debug replay mode - creating mock pet profile '
          '(no Firestore writes)',
        );

        final mockPetId =
            'debug_replay_dummy_pet_${DateTime.now().millisecondsSinceEpoch}';
        final mockCatProfile = _currentData!.toCatProfile(petId: mockPetId);

        if (mockCatProfile == null) {
          return const OnboardingFailure(
            OnboardingValidationException([
              'Failed to create mock pet profile',
            ]),
          );
        }

        petProfile = mockCatProfile;

        if (kDebugMode) {
          debugPrint(
            '[OnboardingService] Created mock pet profile ${petProfile.id} '
            '(not persisted to Firestore)',
          );
        }
      } else {
        // Normal mode: create pet profile via PetService (with Firestore write)
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

        petProfile = (petResult as PetSuccess).pet;

        if (kDebugMode) {
          debugPrint(
            '[OnboardingService] Successfully created pet profile '
            '${petProfile.id}. '
            'Schedules can be added later from profile screens.',
          );
        }

        // Create lab result if lab data was provided during onboarding
        if (_currentData!.hasCompleteLabData) {
          if (kDebugMode) {
            debugPrint(
              '[OnboardingService] Creating lab result from onboarding data',
            );
          }

          final labResult = _createLabResultFromOnboardingData(
            petProfile.id,
            _currentData!,
          );

          final labResultResult = await _petService.createLabResult(
            petId: petProfile.id,
            labResult: labResult,
            preferredUnitSystem: 'us', // Default to US units
          );

          if (labResultResult is PetFailure) {
            // Log error but don't fail onboarding
            // User can add lab results later
            if (kDebugMode) {
              debugPrint(
                '[OnboardingService] WARNING: Failed to create lab result: '
                '${labResultResult.message}',
              );
            }
          } else if (kDebugMode) {
            debugPrint(
              '[OnboardingService] Successfully created lab result '
              '${labResult.id}',
            );
          }
        }
      }

      // Mark onboarding as completed
      _currentProgress = _currentProgress!.markCompleted();

      // Track completion analytics (skip in replay mode to avoid
      // polluting analytics)
      if (!isDebugReplay) {
        await _trackAnalyticsEvent('onboarding_completed', {
          'user_id': _currentData!.userId,
          'pet_id': petProfile.id,
          'duration_seconds': _currentProgress!.totalDuration?.inSeconds,
          'completion_rate': 1.0,
        });
      } else if (kDebugMode) {
        debugPrint(
          '[OnboardingService] Skipping analytics tracking in debug replay '
          'mode',
        );
      }

      // Clean up temporary data (checkpoint cleanup is safe even in
      // replay mode)
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
    final currentConfig = _flow.getStep(_currentProgress!.currentStepId);
    return currentConfig?.isValid(data) ?? false;
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
      final onboardingData = OnboardingData.fromJson(dataJson);
      final progress = OnboardingProgress.fromJson(progressJson);

      return (onboardingData, progress);
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

  /// Creates a LabResult from onboarding data
  ///
  /// Converts the flat lab value fields in OnboardingData to a structured
  /// LabResult with proper measurements and metadata.
  LabResult _createLabResultFromOnboardingData(
    String petId,
    OnboardingData data,
  ) {
    final values = <String, LabMeasurement>{};

    // Add creatinine if present
    if (data.creatinineMgDl != null) {
      values['creatinine'] = LabMeasurement(
        value: data.creatinineMgDl!,
        unit: 'mg/dL',
      );
    }

    // Add BUN if present
    if (data.bunMgDl != null) {
      values['bun'] = LabMeasurement(
        value: data.bunMgDl!,
        unit: 'mg/dL',
      );
    }

    // Add SDMA if present
    if (data.sdmaMcgDl != null) {
      values['sdma'] = LabMeasurement(
        value: data.sdmaMcgDl!,
        unit: 'µg/dL',
      );
    }

    // Create metadata if we have vet notes or IRIS stage
    LabResultMetadata? metadata;
    if (data.vetNotes != null || data.irisStage != null) {
      metadata = LabResultMetadata(
        source: 'manual',
        enteredBy: data.userId,
        vetNotes: data.vetNotes,
        irisStage: data.irisStage,
      );
    }

    // Create the lab result using the factory constructor
    return LabResult.create(
      petId: petId,
      testDate: data.bloodworkDate!,
      values: values,
      metadata: metadata,
    );
  }
}
