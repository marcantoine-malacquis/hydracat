import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/features/notifications/providers/notification_provider.dart';
import 'package:hydracat/features/notifications/services/notification_error_handler.dart';
import 'package:hydracat/features/profile/exceptions/profile_exceptions.dart';
import 'package:hydracat/features/profile/models/cat_profile.dart';
import 'package:hydracat/features/profile/models/schedule.dart';
import 'package:hydracat/features/profile/services/pet_service.dart';
import 'package:hydracat/features/profile/services/schedule_service.dart';
import 'package:hydracat/providers/analytics_provider.dart';
import 'package:hydracat/providers/auth_provider.dart';
import 'package:hydracat/providers/connectivity_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cache status enum to track data freshness
enum CacheStatus {
  /// Data is fresh from Firestore
  fresh,

  /// Data is from cache but still valid
  cached,

  /// Data is from cache but may be stale (offline)
  stale,

  /// No data available
  empty,
}

/// Profile state that holds pet profile information
@immutable
class ProfileState {
  /// Creates a [ProfileState] instance
  const ProfileState({
    this.primaryPet,
    this.fluidSchedule,
    this.medicationSchedules,
    this.isLoading = false,
    this.isRefreshing = false,
    this.scheduleIsLoading = false,
    this.error,
    this.lastUpdated,
    this.cacheStatus = CacheStatus.fresh,
    this.schedulesLoadedAt,
    this.schedulesLoadedDate,
  });

  /// Creates initial empty state
  const ProfileState.initial()
    : primaryPet = null,
      fluidSchedule = null,
      medicationSchedules = null,
      isLoading = false,
      isRefreshing = false,
      scheduleIsLoading = false,
      error = null,
      lastUpdated = null,
      cacheStatus = CacheStatus.empty,
      schedulesLoadedAt = null,
      schedulesLoadedDate = null;

  /// Creates loading state
  const ProfileState.loading()
    : primaryPet = null,
      fluidSchedule = null,
      medicationSchedules = null,
      isLoading = true,
      isRefreshing = false,
      scheduleIsLoading = false,
      error = null,
      lastUpdated = null,
      cacheStatus = CacheStatus.empty,
      schedulesLoadedAt = null,
      schedulesLoadedDate = null;

  /// Current primary pet profile
  final CatProfile? primaryPet;

  /// Current cached fluid schedule
  final Schedule? fluidSchedule;

  /// Current cached medication schedules
  final List<Schedule>? medicationSchedules;

  /// Whether a profile operation is in progress
  final bool isLoading;

  /// Whether a manual refresh is in progress
  final bool isRefreshing;

  /// Whether a schedule operation is in progress
  final bool scheduleIsLoading;

  /// Current error if any
  final ProfileException? error;

  /// When the profile was last updated
  final DateTime? lastUpdated;

  /// Status of the cached data
  final CacheStatus cacheStatus;

  /// When schedules were last loaded (for cache validation)
  final DateTime? schedulesLoadedAt;

  /// Date for which schedules are cached (YYYY-MM-DD format)
  final String? schedulesLoadedDate;

  /// Whether user has a pet profile
  bool get hasPetProfile => primaryPet != null;

  /// Whether there's an error
  bool get hasError => error != null;

  /// Pet's name if available
  String? get petName => primaryPet?.name;

  /// Pet's age if available
  int? get petAge => primaryPet?.ageYears;

  /// Whether user has a fluid schedule
  bool get hasFluidSchedule => fluidSchedule != null;

  /// Fluid schedule frequency if available
  String? get scheduleFrequency => fluidSchedule?.frequency.displayName;

  /// Fluid schedule volume if available
  double? get scheduleVolume => fluidSchedule?.targetVolume;

  /// Whether user has medication schedules
  bool get hasMedicationSchedules =>
      medicationSchedules != null && medicationSchedules!.isNotEmpty;

  /// Number of medication schedules
  int get medicationScheduleCount => medicationSchedules?.length ?? 0;

  /// Whether cached schedules are valid for today
  bool get hasValidSchedulesForToday {
    if (schedulesLoadedDate == null) return false;

    final today = DateTime.now();
    final todayStr =
        '${today.year}-'
        '${today.month.toString().padLeft(2, '0')}-'
        '${today.day.toString().padLeft(2, '0')}';

    return schedulesLoadedDate == todayStr;
  }

  /// Creates a copy of this [ProfileState] with the given fields replaced
  ProfileState copyWith({
    CatProfile? primaryPet,
    Schedule? fluidSchedule,
    List<Schedule>? medicationSchedules,
    bool? isLoading,
    bool? isRefreshing,
    bool? scheduleIsLoading,
    ProfileException? error,
    DateTime? lastUpdated,
    CacheStatus? cacheStatus,
    DateTime? schedulesLoadedAt,
    String? schedulesLoadedDate,
    bool clearError = false,
  }) {
    return ProfileState(
      primaryPet: primaryPet ?? this.primaryPet,
      fluidSchedule: fluidSchedule ?? this.fluidSchedule,
      medicationSchedules: medicationSchedules ?? this.medicationSchedules,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      scheduleIsLoading: scheduleIsLoading ?? this.scheduleIsLoading,
      error: clearError ? null : (error ?? this.error),
      lastUpdated: lastUpdated ?? this.lastUpdated,
      cacheStatus: cacheStatus ?? this.cacheStatus,
      schedulesLoadedAt: schedulesLoadedAt ?? this.schedulesLoadedAt,
      schedulesLoadedDate: schedulesLoadedDate ?? this.schedulesLoadedDate,
    );
  }

  /// Creates a copy with error cleared
  ProfileState clearError() {
    return copyWith(clearError: true);
  }

  /// Creates a copy with loading state
  ProfileState withLoading({required bool loading}) {
    return copyWith(isLoading: loading);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ProfileState &&
        other.primaryPet == primaryPet &&
        other.fluidSchedule == fluidSchedule &&
        listEquals(other.medicationSchedules, medicationSchedules) &&
        other.isLoading == isLoading &&
        other.isRefreshing == isRefreshing &&
        other.scheduleIsLoading == scheduleIsLoading &&
        other.error == error &&
        other.lastUpdated == lastUpdated &&
        other.cacheStatus == cacheStatus &&
        other.schedulesLoadedAt == schedulesLoadedAt &&
        other.schedulesLoadedDate == schedulesLoadedDate;
  }

  @override
  int get hashCode {
    return Object.hash(
      primaryPet,
      fluidSchedule,
      Object.hashAll(medicationSchedules ?? []),
      isLoading,
      isRefreshing,
      scheduleIsLoading,
      error,
      lastUpdated,
      cacheStatus,
      schedulesLoadedAt,
      schedulesLoadedDate,
    );
  }

  @override
  String toString() {
    return 'ProfileState('
        'primaryPet: $primaryPet, '
        'fluidSchedule: $fluidSchedule, '
        'medicationSchedules: $medicationSchedules, '
        'isLoading: $isLoading, '
        'isRefreshing: $isRefreshing, '
        'scheduleIsLoading: $scheduleIsLoading, '
        'error: $error, '
        'lastUpdated: $lastUpdated, '
        'cacheStatus: $cacheStatus, '
        'schedulesLoadedAt: $schedulesLoadedAt, '
        'schedulesLoadedDate: $schedulesLoadedDate'
        ')';
  }
}

/// Notifier class for managing profile state
class ProfileNotifier extends StateNotifier<ProfileState> {
  /// Creates a [ProfileNotifier] with the provided dependencies
  ProfileNotifier(this._petService, this._scheduleService, this._ref)
    : super(const ProfileState.initial());

  final PetService _petService;
  final ScheduleService _scheduleService;
  final Ref _ref;

  /// Load the primary pet profile
  Future<bool> loadPrimaryPet() async {
    if (kDebugMode) {
      debugPrint('[ProfileNotifier] loadPrimaryPet: Starting...');
    }
    state = state.withLoading(loading: true);

    try {
      if (kDebugMode) {
        debugPrint(
          '[ProfileNotifier] loadPrimaryPet: Calling getPrimaryPet...',
        );
      }
      final pet = await _petService.getPrimaryPet();
      final cacheTimestamp = _petService.getCacheTimestamp();

      if (kDebugMode) {
        debugPrint(
          '[ProfileNotifier] loadPrimaryPet: Got pet = ${pet?.name ?? 'null'}',
        );
      }

      // Cache pet ID for background FCM handler
      if (pet != null) {
        await _cachePrimaryPetId(pet.id);
      }

      state = state.copyWith(
        primaryPet: pet,
        isLoading: false,
        lastUpdated: cacheTimestamp ?? DateTime.now(),
        cacheStatus: pet != null ? CacheStatus.cached : CacheStatus.empty,
      );

      // Proactively load schedules after pet is loaded
      if (pet != null) {
        if (kDebugMode) {
          debugPrint(
            '[ProfileNotifier] loadPrimaryPet: Loading schedules for pet '
            '${pet.id}',
          );
        }
        await loadAllSchedules();
      }

      if (kDebugMode) {
        debugPrint(
          '[ProfileNotifier] loadPrimaryPet: Complete, success=${pet != null}',
        );
      }
      return pet != null;
    } on Object catch (e, stackTrace) {
      // Catches all throwables including TypeError from JSON parsing
      // This prevents the app from hanging if deserialization fails
      if (kDebugMode) {
        debugPrint('[ProfileNotifier] loadPrimaryPet: ERROR: $e');
        debugPrint(
          '[ProfileNotifier] loadPrimaryPet: Stack trace: $stackTrace',
        );
      }
      state = state.copyWith(
        isLoading: false,
        error: PetServiceException('Failed to load pet profile: $e'),
        cacheStatus: CacheStatus.empty,
      );
      return false;
    }
  }

  /// Manually refresh the primary pet profile from Firestore
  Future<bool> refreshPrimaryPet() async {
    state = state.copyWith(isRefreshing: true, clearError: true);

    try {
      final pet = await _petService.getPrimaryPet(forceRefresh: true);

      state = state.copyWith(
        primaryPet: pet,
        isRefreshing: false,
        lastUpdated: DateTime.now(),
        cacheStatus: pet != null ? CacheStatus.fresh : CacheStatus.empty,
        clearError: true,
      );

      return pet != null;
    } on Object catch (e) {
      // Catches all throwables including TypeError from JSON parsing
      // This prevents the refresh spinner from hanging forever
      // Don't clear existing pet data if refresh fails
      state = state.copyWith(
        isRefreshing: false,
        error: PetServiceException('Failed to refresh pet profile: $e'),
        cacheStatus: state.primaryPet != null
            ? CacheStatus.stale
            : CacheStatus.empty,
      );
      return false;
    }
  }

  /// Create a new pet profile
  Future<bool> createPet(CatProfile profile) async {
    state = state.withLoading(loading: true);

    final result = await _petService.createPet(profile);

    switch (result) {
      case PetSuccess(pet: final pet):
        // Cache pet ID for background FCM handler
        await _cachePrimaryPetId(pet.id);

        state = state.copyWith(
          primaryPet: pet,
          isLoading: false,
          lastUpdated: DateTime.now(),
          cacheStatus: CacheStatus.fresh,
        );
        return true;

      case PetFailure(exception: final exception):
        state = state.copyWith(
          isLoading: false,
          error: exception,
          cacheStatus: CacheStatus.empty,
        );
        return false;
    }
  }

  /// Update an existing pet profile
  Future<bool> updatePet(CatProfile updatedProfile) async {
    state = state.withLoading(loading: true);

    final result = await _petService.updatePet(updatedProfile);

    switch (result) {
      case PetSuccess(pet: final pet):
        state = state.copyWith(
          primaryPet: pet,
          isLoading: false,
          lastUpdated: DateTime.now(),
          cacheStatus: CacheStatus.fresh,
        );
        return true;

      case PetFailure(exception: final exception):
        state = state.copyWith(
          isLoading: false,
          error: exception,
          // Keep current cache status if update fails
        );
        return false;
    }
  }

  /// Delete the current pet profile
  Future<bool> deletePet(String petId) async {
    state = state.withLoading(loading: true);

    final result = await _petService.deletePet(petId);

    switch (result) {
      case PetSuccess():
        // Clear the primary pet and update auth state
        state = const ProfileState.initial();

        // Update auth to reflect no primary pet
        final authNotifier = _ref.read(authProvider.notifier);
        await authNotifier.updateOnboardingStatus(
          hasCompletedOnboarding: false,
        );

        return true;

      case PetFailure(exception: final exception):
        state = state.copyWith(
          isLoading: false,
          error: exception,
        );
        return false;
    }
  }

  /// Check for pet name conflicts
  Future<List<String>> checkNameConflicts(String name) async {
    return _petService.checkNameConflicts(name);
  }

  /// Clear the current error
  void clearError() {
    state = state.clearError();
  }

  /// Refresh the primary pet data
  Future<void> refresh() async {
    await loadPrimaryPet();
  }

  /// Clear all cached data
  void clearCache() {
    _petService.clearCache();
    state = const ProfileState.initial();
  }

  /// Caches primary pet ID in SharedPreferences for background FCM handler.
  Future<void> _cachePrimaryPetId(String petId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_primary_pet_id', petId);
      if (kDebugMode) {
        debugPrint('[Profile] Cached primary pet ID for background access');
      }
    } on Exception catch (e) {
      if (kDebugMode) {
        debugPrint('[Profile] Failed to cache pet ID: $e');
      }
      // Non-critical, don't throw
    }
  }

  /// Clear only schedule cache
  void clearScheduleCache() {
    if (state.fluidSchedule != null || state.medicationSchedules != null) {
      state = state.copyWith();
    }
  }

  /// Load the fluid schedule for the primary pet
  Future<bool> loadFluidSchedule() async {
    final primaryPet = state.primaryPet;
    if (primaryPet == null) {
      state = state.copyWith(scheduleIsLoading: false);
      return false;
    }

    final currentUser = _ref.read(currentUserProvider);
    if (currentUser == null) {
      state = state.copyWith(scheduleIsLoading: false);
      return false;
    }

    state = state.copyWith(scheduleIsLoading: true);

    try {
      final schedule = await _scheduleService.getFluidSchedule(
        userId: currentUser.id,
        petId: primaryPet.id,
      );

      // Update state with date tracking
      final now = DateTime.now();
      final todayStr =
          '${now.year}-'
          '${now.month.toString().padLeft(2, '0')}-'
          '${now.day.toString().padLeft(2, '0')}';

      state = state.copyWith(
        fluidSchedule: schedule,
        scheduleIsLoading: false,
        lastUpdated: now,
        schedulesLoadedAt: now,
        schedulesLoadedDate: todayStr,
      );

      return schedule != null;
    } on FormatException catch (e) {
      // Handle serialization/parsing errors specifically
      state = state.copyWith(
        scheduleIsLoading: false,
        error: const PetServiceException(
          'Schedule data format error. '
          'Please contact support if this persists.',
        ),
      );
      if (kDebugMode) {
        debugPrint('[ProfileNotifier] Schedule serialization error: $e');
      }
      return false;
    } on Exception catch (e) {
      state = state.copyWith(
        scheduleIsLoading: false,
        error: PetServiceException('Failed to load fluid schedule: $e'),
      );
      if (kDebugMode) {
        debugPrint('[ProfileNotifier] Error loading fluid schedule: $e');
      }
      return false;
    }
  }

  /// Manually refresh the fluid schedule from Firestore
  Future<bool> refreshFluidSchedule() async {
    final primaryPet = state.primaryPet;
    if (primaryPet == null) return false;

    final currentUser = _ref.read(currentUserProvider);
    if (currentUser == null) return false;

    state = state.copyWith(scheduleIsLoading: true);

    try {
      final schedule = await _scheduleService.getFluidSchedule(
        userId: currentUser.id,
        petId: primaryPet.id,
      );

      state = state.copyWith(
        fluidSchedule: schedule,
        scheduleIsLoading: false,
        lastUpdated: DateTime.now(),
      );

      return schedule != null;
    } on FormatException catch (e) {
      // Handle serialization/parsing errors specifically
      state = state.copyWith(
        scheduleIsLoading: false,
        error: const PetServiceException(
          'Schedule data format error. '
          'Please contact support if this persists.',
        ),
      );
      if (kDebugMode) {
        debugPrint(
          '[ProfileNotifier] Schedule serialization error on refresh: $e',
        );
      }
      return false;
    } on Exception catch (e) {
      // Don't clear existing schedule data if refresh fails for other reasons
      state = state.copyWith(
        scheduleIsLoading: false,
        error: PetServiceException('Failed to refresh fluid schedule: $e'),
      );
      if (kDebugMode) {
        debugPrint('[ProfileNotifier] Error refreshing fluid schedule: $e');
      }
      return false;
    }
  }

  /// Get the fluid schedule for the primary pet (deprecated - use cached data)
  @Deprecated('Use cached schedule data from state instead')
  Future<Schedule?> getFluidSchedule() async {
    await loadFluidSchedule();
    return state.fluidSchedule;
  }

  /// Create a new fluid schedule
  Future<bool> createFluidSchedule(Schedule schedule) async {
    final primaryPet = state.primaryPet;
    if (primaryPet == null) return false;

    final currentUser = _ref.read(currentUserProvider);
    if (currentUser == null) return false;

    state = state.copyWith(scheduleIsLoading: true);

    try {
      final scheduleId = await _scheduleService.createSchedule(
        userId: currentUser.id,
        petId: primaryPet.id,
        scheduleDto: schedule.toDto(),
      );

      // Create the new schedule with the assigned ID
      final newSchedule = schedule.copyWith(id: scheduleId);

      // Update the cache with the new schedule data
      state = state.copyWith(
        fluidSchedule: newSchedule,
        scheduleIsLoading: false,
        lastUpdated: DateTime.now(),
      );

      // Schedule notifications if online (Step 6.2)
      if (_isOnline()) {
        await _scheduleNotificationsForSchedule(
          schedule: newSchedule,
          operationType: 'create',
        );
      }

      return true;
    } on Exception catch (e) {
      state = state.copyWith(
        scheduleIsLoading: false,
        error: PetServiceException('Failed to create fluid schedule: $e'),
      );
      if (kDebugMode) {
        debugPrint('[ProfileNotifier] Error creating fluid schedule: $e');
      }
      return false;
    }
  }

  /// Update a fluid schedule
  Future<bool> updateFluidSchedule(Schedule schedule) async {
    final primaryPet = state.primaryPet;
    if (primaryPet == null) return false;

    final currentUser = _ref.read(currentUserProvider);
    if (currentUser == null) return false;

    // Store old schedule to check if isActive changed
    final oldSchedule = state.fluidSchedule;

    state = state.copyWith(scheduleIsLoading: true);

    try {
      await _scheduleService.updateSchedule(
        userId: currentUser.id,
        petId: primaryPet.id,
        scheduleId: schedule.id,
        updates: schedule.toJson(),
      );

      // Update the cache with the new schedule data
      state = state.copyWith(
        fluidSchedule: schedule,
        scheduleIsLoading: false,
        lastUpdated: DateTime.now(),
      );

      // Handle notification updates if online (Step 6.2)
      if (_isOnline()) {
        // Check if schedule was deactivated
        if (oldSchedule != null && oldSchedule.isActive && !schedule.isActive) {
          // Schedule was deactivated - cancel notifications
          await _cancelNotificationsForSchedule(
            scheduleId: schedule.id,
            treatmentType: schedule.treatmentType.name,
            operationType: 'deactivate',
          );
        } else if (schedule.isActive) {
          // Schedule is active (either stayed active or was activated)
          // Reschedule notifications
          await _scheduleNotificationsForSchedule(
            schedule: schedule,
            operationType: 'update',
          );
        }
      }

      return true;
    } on Exception catch (e) {
      state = state.copyWith(
        scheduleIsLoading: false,
        error: PetServiceException('Failed to update fluid schedule: $e'),
      );
      if (kDebugMode) {
        debugPrint('[ProfileNotifier] Error updating fluid schedule: $e');
      }
      return false;
    }
  }

  /// Load medication schedules for the primary pet
  Future<bool> loadMedicationSchedules() async {
    final primaryPet = state.primaryPet;
    if (primaryPet == null) {
      state = state.copyWith(scheduleIsLoading: false);
      return false;
    }

    final currentUser = _ref.read(currentUserProvider);
    if (currentUser == null) {
      state = state.copyWith(scheduleIsLoading: false);
      return false;
    }

    state = state.copyWith(scheduleIsLoading: true);

    try {
      final schedules = await _scheduleService.getMedicationSchedules(
        userId: currentUser.id,
        petId: primaryPet.id,
      );

      // Update state with date tracking
      final now = DateTime.now();
      final todayStr =
          '${now.year}-'
          '${now.month.toString().padLeft(2, '0')}-'
          '${now.day.toString().padLeft(2, '0')}';

      state = state.copyWith(
        medicationSchedules: schedules,
        scheduleIsLoading: false,
        lastUpdated: now,
        schedulesLoadedAt: now,
        schedulesLoadedDate: todayStr,
      );

      return schedules.isNotEmpty;
    } on FormatException catch (e) {
      // Handle serialization/parsing errors specifically
      state = state.copyWith(
        scheduleIsLoading: false,
        error: const PetServiceException(
          'Medication schedule data format error. '
          'Please contact support if this persists.',
        ),
      );
      if (kDebugMode) {
        debugPrint(
          '[ProfileNotifier] Medication schedule '
          'serialization error: $e',
        );
      }
      return false;
    } on Exception catch (e) {
      state = state.copyWith(
        scheduleIsLoading: false,
        error: PetServiceException('Failed to load medication schedules: $e'),
      );
      if (kDebugMode) {
        debugPrint('[ProfileNotifier] Error loading medication schedules: $e');
      }
      return false;
    }
  }

  /// Manually refresh medication schedules from Firestore
  Future<bool> refreshMedicationSchedules() async {
    final primaryPet = state.primaryPet;
    if (primaryPet == null) return false;

    final currentUser = _ref.read(currentUserProvider);
    if (currentUser == null) return false;

    state = state.copyWith(scheduleIsLoading: true);

    try {
      final schedules = await _scheduleService.getMedicationSchedules(
        userId: currentUser.id,
        petId: primaryPet.id,
      );

      state = state.copyWith(
        medicationSchedules: schedules,
        scheduleIsLoading: false,
        lastUpdated: DateTime.now(),
      );

      return schedules.isNotEmpty;
    } on FormatException catch (e) {
      // Handle serialization/parsing errors specifically
      state = state.copyWith(
        scheduleIsLoading: false,
        error: const PetServiceException(
          'Medication schedule data format error. '
          'Please contact support if this persists.',
        ),
      );
      if (kDebugMode) {
        debugPrint(
          '[ProfileNotifier] Medication schedule serialization error '
          'on refresh: $e',
        );
      }
      return false;
    } on Exception catch (e) {
      // Don't clear existing schedule data if refresh fails for other reasons
      state = state.copyWith(
        scheduleIsLoading: false,
        error: PetServiceException(
          'Failed to refresh medication schedules: $e',
        ),
      );
      if (kDebugMode) {
        debugPrint(
          '[ProfileNotifier] Error refreshing medication '
          'schedules: $e',
        );
      }
      return false;
    }
  }

  /// Update a medication schedule
  Future<bool> updateMedicationSchedule(Schedule schedule) async {
    final primaryPet = state.primaryPet;
    if (primaryPet == null) return false;

    final currentUser = _ref.read(currentUserProvider);
    if (currentUser == null) return false;

    // Store old schedule to check if isActive changed
    final currentSchedules = state.medicationSchedules ?? [];
    final oldSchedule = currentSchedules
        .where((s) => s.id == schedule.id)
        .firstOrNull;

    state = state.copyWith(scheduleIsLoading: true);

    try {
      await _scheduleService.updateSchedule(
        userId: currentUser.id,
        petId: primaryPet.id,
        scheduleId: schedule.id,
        updates: schedule.toJson(),
      );

      // Update the cache with the new schedule data
      final updatedSchedules = currentSchedules.map((s) {
        return s.id == schedule.id ? schedule : s;
      }).toList();

      state = state.copyWith(
        medicationSchedules: updatedSchedules,
        scheduleIsLoading: false,
        lastUpdated: DateTime.now(),
      );

      // Handle notification updates if online (Step 6.2)
      if (_isOnline()) {
        // Check if schedule was deactivated
        if (oldSchedule != null && oldSchedule.isActive && !schedule.isActive) {
          // Schedule was deactivated - cancel notifications
          await _cancelNotificationsForSchedule(
            scheduleId: schedule.id,
            treatmentType: schedule.treatmentType.name,
            operationType: 'deactivate',
          );
        } else if (schedule.isActive) {
          // Schedule is active (either stayed active or was activated)
          // Reschedule notifications
          await _scheduleNotificationsForSchedule(
            schedule: schedule,
            operationType: 'update',
          );
        }
      }

      return true;
    } on Exception catch (e) {
      state = state.copyWith(
        scheduleIsLoading: false,
        error: PetServiceException('Failed to update medication schedule: $e'),
      );
      if (kDebugMode) {
        debugPrint(
          '[ProfileNotifier] Error updating medication '
          'schedule: $e',
        );
      }
      return false;
    }
  }

  /// Add a new medication schedule
  Future<bool> addMedicationSchedule(Schedule schedule) async {
    final primaryPet = state.primaryPet;
    if (primaryPet == null) return false;

    final currentUser = _ref.read(currentUserProvider);
    if (currentUser == null) return false;

    state = state.copyWith(scheduleIsLoading: true);

    try {
      final scheduleId = await _scheduleService.createSchedule(
        userId: currentUser.id,
        petId: primaryPet.id,
        scheduleDto: schedule.toDto(),
      );

      // Create the new schedule with the assigned ID
      final newSchedule = schedule.copyWith(id: scheduleId);

      // Add to the cache
      final currentSchedules = state.medicationSchedules ?? [];
      final updatedSchedules = [...currentSchedules, newSchedule];

      state = state.copyWith(
        medicationSchedules: updatedSchedules,
        scheduleIsLoading: false,
        lastUpdated: DateTime.now(),
      );

      // Schedule notifications if online (Step 6.2)
      if (_isOnline()) {
        await _scheduleNotificationsForSchedule(
          schedule: newSchedule,
          operationType: 'create',
        );
      }

      return true;
    } on Exception catch (e) {
      state = state.copyWith(
        scheduleIsLoading: false,
        error: PetServiceException('Failed to add medication schedule: $e'),
      );
      if (kDebugMode) {
        debugPrint('[ProfileNotifier] Error adding medication schedule: $e');
      }
      return false;
    }
  }

  /// Delete a medication schedule
  Future<bool> deleteMedicationSchedule(String scheduleId) async {
    final primaryPet = state.primaryPet;
    if (primaryPet == null) return false;

    final currentUser = _ref.read(currentUserProvider);
    if (currentUser == null) return false;

    // Store schedule info before deletion for notification cancellation
    final currentSchedules = state.medicationSchedules ?? [];
    final scheduleToDelete = currentSchedules
        .where((s) => s.id == scheduleId)
        .firstOrNull;

    state = state.copyWith(scheduleIsLoading: true);

    try {
      await _scheduleService.deleteSchedule(
        userId: currentUser.id,
        petId: primaryPet.id,
        scheduleId: scheduleId,
      );

      // Remove from the cache
      final updatedSchedules = currentSchedules
          .where((s) => s.id != scheduleId)
          .toList();

      state = state.copyWith(
        medicationSchedules: updatedSchedules,
        scheduleIsLoading: false,
        lastUpdated: DateTime.now(),
      );

      // Cancel notifications if online (Step 6.2)
      if (_isOnline() && scheduleToDelete != null) {
        await _cancelNotificationsForSchedule(
          scheduleId: scheduleId,
          treatmentType: scheduleToDelete.treatmentType.name,
          operationType: 'delete',
        );
      }

      return true;
    } on Exception catch (e) {
      state = state.copyWith(
        scheduleIsLoading: false,
        error: PetServiceException('Failed to delete medication schedule: $e'),
      );
      if (kDebugMode) {
        debugPrint('[ProfileNotifier] Error deleting medication schedule: $e');
      }
      return false;
    }
  }

  /// Proactively load all schedules for today
  ///
  /// Called automatically on:
  /// - App startup (after authentication)
  /// - App resume from background
  /// - Onboarding completion
  ///
  /// Silently fails and logs to analytics if unsuccessful
  Future<void> loadAllSchedules() async {
    final primaryPet = state.primaryPet;
    if (primaryPet == null) return;

    final currentUser = _ref.read(currentUserProvider);
    if (currentUser == null) return;

    // Check if cache is still valid for today
    if (state.hasValidSchedulesForToday) {
      if (kDebugMode) {
        debugPrint('[ProfileNotifier] Schedules cache valid, skipping reload');
      }

      // Track cache hit
      final analyticsService = _ref.read(analyticsServiceDirectProvider);
      await analyticsService.trackFeatureUsed(
        featureName: AnalyticsEvents.schedulesCacheHit,
      );
      return;
    }

    if (kDebugMode) {
      debugPrint('[ProfileNotifier] Pre-loading schedules for today');
    }

    try {
      // Load both schedules concurrently
      final results = await Future.wait([
        _scheduleService.getFluidSchedule(
          userId: currentUser.id,
          petId: primaryPet.id,
        ),
        _scheduleService.getMedicationSchedules(
          userId: currentUser.id,
          petId: primaryPet.id,
        ),
      ]);

      final fluidSchedule = results[0] as Schedule?;
      final medicationSchedules = results[1] as List<Schedule>? ?? [];

      // Update state with new schedules and date tracking
      final now = DateTime.now();
      final todayStr =
          '${now.year}-'
          '${now.month.toString().padLeft(2, '0')}-'
          '${now.day.toString().padLeft(2, '0')}';

      state = state.copyWith(
        fluidSchedule: fluidSchedule,
        medicationSchedules: medicationSchedules,
        schedulesLoadedAt: now,
        schedulesLoadedDate: todayStr,
      );

      // Track successful pre-load
      final analyticsService = _ref.read(analyticsServiceDirectProvider);
      await analyticsService.trackFeatureUsed(
        featureName: AnalyticsEvents.schedulesPreloaded,
        additionalParams: {
          AnalyticsParams.medicationCount: medicationSchedules.length,
          AnalyticsParams.hasFluidSchedule: fluidSchedule != null,
          AnalyticsParams.cacheMiss: true,
        },
      );

      if (kDebugMode) {
        debugPrint(
          '[ProfileNotifier] Schedules preloaded: '
          '${medicationSchedules.length} medications, '
          'fluid: ${fluidSchedule != null}',
        );
      }
    } on Exception catch (e) {
      // Silent failure - log to analytics but don't show error to user
      // Logging popups will fall back to on-demand loading

      final analyticsService = _ref.read(analyticsServiceDirectProvider);
      await analyticsService.trackError(
        errorType: 'schedules_preload_failed',
        errorContext: e.toString(),
      );

      if (kDebugMode) {
        debugPrint('[ProfileNotifier] Failed to preload schedules: $e');
      }
    }
  }

  /// Handle app resume from background
  ///
  /// Called by AppShell when app lifecycle changes to resumed.
  /// Refreshes schedule cache if date has changed.
  Future<void> onAppResumed() async {
    if (kDebugMode) {
      debugPrint('[ProfileNotifier] App resumed - checking schedule cache');
    }

    // Check if date has changed since last load
    if (!state.hasValidSchedulesForToday) {
      if (kDebugMode) {
        debugPrint('[ProfileNotifier] Date changed - reloading schedules');
      }
      await loadAllSchedules();
    }
  }

  // ==========================================================================
  // NOTIFICATION INTEGRATION (Step 6.2)
  // ==========================================================================

  /// Check if device is currently online
  ///
  /// Uses ConnectivityProvider to determine network status.
  /// Returns false if provider is unavailable or device is offline.
  ///
  /// This check is used to determine whether to schedule/cancel
  /// notifications during schedule CRUD operations. When offline,
  /// notification operations are skipped and will reconcile on next app
  /// resume via rescheduleAll().
  bool _isOnline() {
    try {
      return _ref.read(isConnectedProvider);
    } on Exception catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[ProfileNotifier] Failed to check connectivity status: $e',
        );
      }
      // Default to offline if connectivity provider unavailable
      return false;
    }
  }

  /// Schedule notifications for a schedule (silent, non-blocking)
  ///
  /// Called after successful schedule create/update operations.
  /// Failures are logged to analytics but do not block the schedule
  /// operation.
  ///
  /// Note: This method uses a workaround to call ReminderService with Ref
  /// instead of WidgetRef. ReminderService only uses ref.read() internally,
  /// which is available on both types, so the cast is safe.
  ///
  /// Algorithm:
  /// 1. Validate prerequisites (currentUser, primaryPet)
  /// 2. Get ReminderService from ref
  /// 3. Call reminderService.scheduleForSchedule() with ref cast
  /// 4. Catch all exceptions and log silently with analytics
  /// 5. Never throw/rethrow
  ///
  /// Parameters:
  /// - [schedule]: The schedule to schedule notifications for
  /// - [operationType]: 'create' or 'update' for analytics tracking
  ///
  /// Returns: void (all errors logged silently)
  Future<void> _scheduleNotificationsForSchedule({
    required Schedule schedule,
    required String operationType,
  }) async {
    try {
      // Validate prerequisites
      final currentUser = _ref.read(currentUserProvider);
      final primaryPet = state.primaryPet;

      if (currentUser == null || primaryPet == null) {
        if (kDebugMode) {
          debugPrint(
            '[ProfileNotifier] Cannot schedule notifications: '
            'missing user or pet',
          );
        }
        return;
      }

      if (kDebugMode) {
        debugPrint(
          '[ProfileNotifier] Scheduling notifications for '
          '${schedule.treatmentType.name} schedule ${schedule.id} '
          '(operation: $operationType)',
        );
      }

      // Get ReminderService
      final reminderService = _ref.read(reminderServiceProvider);

      // Schedule notifications (idempotent - cancels old ones first)
      // Note: We cast Ref to WidgetRef. This is safe because
      // ReminderService only uses ref.read() which is available on both
      // Ref and WidgetRef.
      // ignore: argument_type_not_assignable, cast_from_null_always_fails
      final result = await reminderService.scheduleForSchedule(
        currentUser.id,
        primaryPet.id,
        schedule,
        _ref as WidgetRef, // Safe cast: only uses ref.read()
      );

      if (kDebugMode) {
        debugPrint(
          '[ProfileNotifier] Notification scheduling result: '
          'scheduled=${result['scheduled']}, '
          'immediate=${result['immediate']}, '
          'missed=${result['missed']}',
        );
      }

      // Track analytics event for schedule create/update notification scheduling
      try {
        final analyticsService = _ref.read(analyticsServiceDirectProvider);
        if (operationType == 'create') {
          await analyticsService.trackScheduleCreatedRemindersScheduled(
            treatmentType: schedule.treatmentType.name,
            scheduleId: schedule.id,
            reminderCount: result['scheduled'] as int? ?? 0,
            result: 'success',
          );
        } else {
          await analyticsService.trackScheduleUpdatedRemindersRescheduled(
            treatmentType: schedule.treatmentType.name,
            scheduleId: schedule.id,
            reminderCount: result['scheduled'] as int? ?? 0,
            result: 'success',
          );
        }
      } on Exception catch (e) {
        if (kDebugMode) {
          debugPrint('[ProfileNotifier] Analytics tracking failed: $e');
        }
      }
    } on Exception catch (e) {
      // Silent error logging - don't block schedule operation
      if (kDebugMode) {
        debugPrint(
          '[ProfileNotifier] Failed to schedule notifications: $e',
        );
      }

      // Report to Crashlytics
      final currentUser = _ref.read(currentUserProvider);
      final primaryPet = state.primaryPet;
      if (currentUser != null && primaryPet != null) {
        NotificationErrorHandler.handleSchedulingError(
          context: null,
          operation: 'schedule_for_schedule_$operationType',
          error: e,
          userId: currentUser.id,
          petId: primaryPet.id,
          scheduleId: schedule.id,
        );
      }

      // Track error analytics for schedule create/update
      try {
        final analyticsService = _ref.read(analyticsServiceDirectProvider);
        if (operationType == 'create') {
          await analyticsService.trackScheduleCreatedRemindersScheduled(
            treatmentType: schedule.treatmentType.name,
            scheduleId: schedule.id,
            reminderCount: 0,
            result: 'error',
          );
        } else {
          await analyticsService.trackScheduleUpdatedRemindersRescheduled(
            treatmentType: schedule.treatmentType.name,
            scheduleId: schedule.id,
            reminderCount: 0,
            result: 'error',
          );
        }
      } on Exception catch (analyticsError) {
        if (kDebugMode) {
          debugPrint(
            '[ProfileNotifier] Analytics tracking failed: $analyticsError',
          );
        }
      }
    }
  }

  /// Cancel notifications for a schedule (silent, non-blocking)
  ///
  /// Called after successful schedule delete or deactivation operations.
  /// Failures are logged to analytics but do not block the schedule
  /// operation.
  ///
  /// Note: This method uses a workaround to call ReminderService with Ref
  /// instead of WidgetRef. ReminderService only uses ref.read() internally,
  /// which is available on both types, so the cast is safe.
  ///
  /// Algorithm:
  /// 1. Validate prerequisites (currentUser, primaryPet)
  /// 2. Get ReminderService from ref
  /// 3. Call reminderService.cancelForSchedule() with ref cast
  /// 4. Catch all exceptions and log silently with analytics
  /// 5. Never throw/rethrow
  ///
  /// Parameters:
  /// - [scheduleId]: The schedule ID to cancel notifications for
  /// - [treatmentType]: 'fluid' or 'medication' for analytics tracking
  /// - [operationType]: 'delete' or 'deactivate' for analytics tracking
  ///
  /// Returns: void (all errors logged silently)
  Future<void> _cancelNotificationsForSchedule({
    required String scheduleId,
    required String treatmentType,
    required String operationType,
  }) async {
    try {
      // Validate prerequisites
      final currentUser = _ref.read(currentUserProvider);
      final primaryPet = state.primaryPet;

      if (currentUser == null || primaryPet == null) {
        if (kDebugMode) {
          debugPrint(
            '[ProfileNotifier] Cannot cancel notifications: '
            'missing user or pet',
          );
        }
        return;
      }

      if (kDebugMode) {
        debugPrint(
          '[ProfileNotifier] Canceling notifications for '
          '$treatmentType schedule $scheduleId '
          '(operation: $operationType)',
        );
      }

      // Get ReminderService
      final reminderService = _ref.read(reminderServiceProvider);

      // Cancel notifications
      // Note: We cast Ref to WidgetRef. This is safe because
      // ReminderService only uses ref.read() which is available on both
      // Ref and WidgetRef.
      // ignore: argument_type_not_assignable, cast_from_null_always_fails
      final canceledCount = await reminderService.cancelForSchedule(
        currentUser.id,
        primaryPet.id,
        scheduleId,
        _ref as WidgetRef, // Safe cast: only uses ref.read()
      );

      if (kDebugMode) {
        debugPrint(
          '[ProfileNotifier] Canceled $canceledCount notification(s) '
          'for schedule $scheduleId',
        );
      }

      // Track analytics event for schedule delete/deactivate cancellation
      try {
        final analyticsService = _ref.read(analyticsServiceDirectProvider);
        final resultStr = canceledCount > 0 ? 'success' : 'none_found';
        if (operationType == 'delete') {
          await analyticsService.trackScheduleDeletedRemindersCanceled(
            treatmentType: treatmentType,
            scheduleId: scheduleId,
            canceledCount: canceledCount,
            result: resultStr,
          );
        } else {
          await analyticsService.trackScheduleDeactivatedRemindersCanceled(
            treatmentType: treatmentType,
            scheduleId: scheduleId,
            canceledCount: canceledCount,
            result: resultStr,
          );
        }
      } on Exception catch (e) {
        if (kDebugMode) {
          debugPrint('[ProfileNotifier] Analytics tracking failed: $e');
        }
      }
    } on Exception catch (e) {
      // Silent error logging - don't block schedule operation
      if (kDebugMode) {
        debugPrint(
          '[ProfileNotifier] Failed to cancel notifications: $e',
        );
      }

      // Report to Crashlytics
      final currentUser = _ref.read(currentUserProvider);
      final primaryPet = state.primaryPet;
      if (currentUser != null && primaryPet != null) {
        NotificationErrorHandler.handleSchedulingError(
          context: null,
          operation: 'cancel_for_schedule_$operationType',
          error: e,
          userId: currentUser.id,
          petId: primaryPet.id,
          scheduleId: scheduleId,
        );
      }

      // Track error analytics for schedule delete/deactivate
      try {
        final analyticsService = _ref.read(analyticsServiceDirectProvider);
        if (operationType == 'delete') {
          await analyticsService.trackScheduleDeletedRemindersCanceled(
            treatmentType: treatmentType,
            scheduleId: scheduleId,
            canceledCount: 0,
            result: 'error',
          );
        } else {
          await analyticsService.trackScheduleDeactivatedRemindersCanceled(
            treatmentType: treatmentType,
            scheduleId: scheduleId,
            canceledCount: 0,
            result: 'error',
          );
        }
      } on Exception catch (analyticsError) {
        if (kDebugMode) {
          debugPrint(
            '[ProfileNotifier] Analytics tracking failed: $analyticsError',
          );
        }
      }
    }
  }

  /// Updates the cached weight without a Firestore read
  ///
  /// This is an optimization for weight tracking - since WeightService
  /// already updates Firestore, we just need to sync our cache.
  /// Updates both ProfileState and PetService cache for consistency.
  void updateCachedWeight(double? weightKg) {
    if (state.primaryPet != null) {
      final updatedPet = state.primaryPet!.copyWith(
        weightKg: weightKg,
        updatedAt: DateTime.now(),
      );
      state = state.copyWith(
        primaryPet: updatedPet,
        lastUpdated: DateTime.now(),
        cacheStatus: CacheStatus.fresh,
      );

      // Also update PetService's cache
      _petService.updateCachedWeight(weightKg);
    }
  }
}

/// Provider for the PetService instance
final petServiceProvider = Provider<PetService>((ref) {
  return PetService();
});

/// Provider for the ScheduleService instance
final scheduleServiceProvider = Provider<ScheduleService>((ref) {
  return const ScheduleService();
});

/// Provider for the profile state notifier
final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((
  ref,
) {
  final petService = ref.read(petServiceProvider);
  final scheduleService = ref.read(scheduleServiceProvider);
  return ProfileNotifier(petService, scheduleService, ref);
});

/// Optimized provider to get the primary pet
final primaryPetProvider = Provider<CatProfile?>((ref) {
  return ref.watch(profileProvider.select((state) => state.primaryPet));
});

/// Optimized provider to check if user has a pet profile
final hasPetProfileProvider = Provider<bool>((ref) {
  return ref.watch(profileProvider.select((state) => state.hasPetProfile));
});

/// Optimized provider to check if profile is loading
final profileIsLoadingProvider = Provider<bool>((ref) {
  return ref.watch(profileProvider.select((state) => state.isLoading));
});

/// Optimized provider to check if profile is refreshing
final profileIsRefreshingProvider = Provider<bool>((ref) {
  return ref.watch(profileProvider.select((state) => state.isRefreshing));
});

/// Optimized provider to get current profile error
final profileErrorProvider = Provider<ProfileException?>((ref) {
  return ref.watch(profileProvider.select((state) => state.error));
});

/// Optimized provider to check if profile has an error
final profileHasErrorProvider = Provider<bool>((ref) {
  return ref.watch(profileProvider.select((state) => state.hasError));
});

/// Optimized provider to get pet name
final petNameProvider = Provider<String?>((ref) {
  return ref.watch(profileProvider.select((state) => state.petName));
});

/// Optimized provider to get pet age
final petAgeProvider = Provider<int?>((ref) {
  return ref.watch(profileProvider.select((state) => state.petAge));
});

/// Optimized provider to get when profile was last updated
final profileLastUpdatedProvider = Provider<DateTime?>((ref) {
  return ref.watch(profileProvider.select((state) => state.lastUpdated));
});

/// Optimized provider to get cache status
final profileCacheStatusProvider = Provider<CacheStatus>((ref) {
  return ref.watch(profileProvider.select((state) => state.cacheStatus));
});

/// Integration provider to determine if onboarding should be shown
final shouldShowOnboardingProvider = Provider<bool>((ref) {
  final hasCompletedOnboarding = ref.watch(hasCompletedOnboardingProvider);
  final hasPet = ref.watch(hasPetProfileProvider);

  // Show onboarding if user hasn't completed it AND doesn't have a pet
  return !hasCompletedOnboarding && !hasPet;
});

/// Integration provider to check if user needs to complete profile
final needsProfileCompletionProvider = Provider<bool>((ref) {
  final isAuthenticated = ref.watch(isAuthenticatedProvider);
  final hasCompletedOnboarding = ref.watch(hasCompletedOnboardingProvider);
  final hasPet = ref.watch(hasPetProfileProvider);

  // User needs to complete profile if authenticated but no onboarding/pet
  return isAuthenticated && (!hasCompletedOnboarding || !hasPet);
});

/// Optimized provider to get the cached fluid schedule
final fluidScheduleProvider = Provider<Schedule?>((ref) {
  return ref.watch(profileProvider.select((state) => state.fluidSchedule));
});

/// Optimized provider to check if the pet has a fluid schedule
final hasFluidScheduleProvider = Provider<bool>((ref) {
  return ref.watch(profileProvider.select((state) => state.hasFluidSchedule));
});

/// Optimized provider to check if schedule is loading
final scheduleIsLoadingProvider = Provider<bool>((ref) {
  return ref.watch(profileProvider.select((state) => state.scheduleIsLoading));
});

/// Optimized provider to get schedule frequency
final scheduleFrequencyProvider = Provider<String?>((ref) {
  return ref.watch(profileProvider.select((state) => state.scheduleFrequency));
});

/// Optimized provider to get schedule volume
final scheduleVolumeProvider = Provider<double?>((ref) {
  return ref.watch(profileProvider.select((state) => state.scheduleVolume));
});

/// Optimized provider to get the cached medication schedules
final medicationSchedulesProvider = Provider<List<Schedule>?>((ref) {
  return ref.watch(
    profileProvider.select((state) => state.medicationSchedules),
  );
});

/// Optimized provider to check if the pet has medication schedules
final hasMedicationSchedulesProvider = Provider<bool>((ref) {
  return ref.watch(
    profileProvider.select((state) => state.hasMedicationSchedules),
  );
});

/// Optimized provider to get medication schedule count
final medicationScheduleCountProvider = Provider<int>((ref) {
  return ref.watch(
    profileProvider.select((state) => state.medicationScheduleCount),
  );
});
