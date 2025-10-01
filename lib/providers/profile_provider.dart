import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/features/profile/exceptions/profile_exceptions.dart';
import 'package:hydracat/features/profile/models/cat_profile.dart';
import 'package:hydracat/features/profile/models/schedule.dart';
import 'package:hydracat/features/profile/services/pet_service.dart';
import 'package:hydracat/features/profile/services/schedule_service.dart';
import 'package:hydracat/providers/auth_provider.dart';

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
      cacheStatus = CacheStatus.empty;

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
      cacheStatus = CacheStatus.empty;

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

  /// Whether user has a pet profile
  bool get hasPetProfile => primaryPet != null;

  /// Whether there's an error
  bool get hasError => error != null;

  /// Pet's name if available
  String? get petName => primaryPet?.name;

  /// Pet's age if available
  int? get petAge => primaryPet?.ageYears;

  /// Pet's treatment approach if available
  String? get treatmentApproach => primaryPet?.treatmentApproach.displayName;

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
  }) {
    return ProfileState(
      primaryPet: primaryPet ?? this.primaryPet,
      fluidSchedule: fluidSchedule ?? this.fluidSchedule,
      medicationSchedules: medicationSchedules ?? this.medicationSchedules,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      scheduleIsLoading: scheduleIsLoading ?? this.scheduleIsLoading,
      error: error ?? this.error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      cacheStatus: cacheStatus ?? this.cacheStatus,
    );
  }

  /// Creates a copy with error cleared
  ProfileState clearError() {
    return copyWith();
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
        other.cacheStatus == cacheStatus;
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
        'cacheStatus: $cacheStatus'
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
    state = state.withLoading(loading: true);

    try {
      final pet = await _petService.getPrimaryPet();
      final cacheTimestamp = _petService.getCacheTimestamp();

      state = state.copyWith(
        primaryPet: pet,
        isLoading: false,
        lastUpdated: cacheTimestamp ?? DateTime.now(),
        cacheStatus: pet != null ? CacheStatus.cached : CacheStatus.empty,
      );

      return pet != null;
    } on Exception catch (e) {
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
    state = state.copyWith(isRefreshing: true);

    try {
      final pet = await _petService.getPrimaryPet(forceRefresh: true);

      state = state.copyWith(
        primaryPet: pet,
        isRefreshing: false,
        lastUpdated: DateTime.now(),
        cacheStatus: pet != null ? CacheStatus.fresh : CacheStatus.empty,
      );

      return pet != null;
    } on Exception catch (e) {
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

  /// Update a fluid schedule
  Future<bool> updateFluidSchedule(Schedule schedule) async {
    final primaryPet = state.primaryPet;
    if (primaryPet == null) return false;

    final currentUser = _ref.read(currentUserProvider);
    if (currentUser == null) return false;

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

    state = state.copyWith(scheduleIsLoading: true);

    try {
      await _scheduleService.updateSchedule(
        userId: currentUser.id,
        petId: primaryPet.id,
        scheduleId: schedule.id,
        updates: schedule.toJson(),
      );

      // Update the cache with the new schedule data
      final currentSchedules = state.medicationSchedules ?? [];
      final updatedSchedules = currentSchedules.map((s) {
        return s.id == schedule.id ? schedule : s;
      }).toList();

      state = state.copyWith(
        medicationSchedules: updatedSchedules,
        scheduleIsLoading: false,
        lastUpdated: DateTime.now(),
      );

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

    state = state.copyWith(scheduleIsLoading: true);

    try {
      await _scheduleService.deleteSchedule(
        userId: currentUser.id,
        petId: primaryPet.id,
        scheduleId: scheduleId,
      );

      // Remove from the cache
      final currentSchedules = state.medicationSchedules ?? [];
      final updatedSchedules = currentSchedules
          .where((s) => s.id != scheduleId)
          .toList();

      state = state.copyWith(
        medicationSchedules: updatedSchedules,
        scheduleIsLoading: false,
        lastUpdated: DateTime.now(),
      );

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

/// Optimized provider to get treatment approach
final treatmentApproachProvider = Provider<String?>((ref) {
  return ref.watch(profileProvider.select((state) => state.treatmentApproach));
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
