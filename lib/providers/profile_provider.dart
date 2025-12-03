import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/features/notifications/providers/notification_provider.dart';
import 'package:hydracat/features/profile/exceptions/profile_exceptions.dart';
import 'package:hydracat/features/profile/models/cat_profile.dart';
import 'package:hydracat/features/profile/models/lab_result.dart';
import 'package:hydracat/features/profile/models/schedule.dart';
import 'package:hydracat/features/profile/services/pet_service.dart';
import 'package:hydracat/features/profile/services/schedule_coordinator.dart';
import 'package:hydracat/features/profile/services/schedule_service.dart';
import 'package:hydracat/providers/analytics_provider.dart';
import 'package:hydracat/providers/auth_provider.dart';
import 'package:hydracat/providers/connectivity_provider.dart';
import 'package:hydracat/providers/profile/profile_cache_manager.dart';

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

/// Sentinel value for [ProfileState.copyWith] to distinguish between
/// "not provided" and "explicitly set to null"
const _undefined = Object();

/// Profile state that holds pet profile information
@immutable
class ProfileState {
  /// Creates a [ProfileState] instance
  const ProfileState({
    this.primaryPet,
    this.fluidSchedule,
    this.medicationSchedules,
    this.labResults,
    this.isLoading = false,
    this.isRefreshing = false,
    this.scheduleIsLoading = false,
    this.labResultsIsLoading = false,
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
      labResults = null,
      isLoading = false,
      isRefreshing = false,
      scheduleIsLoading = false,
      labResultsIsLoading = false,
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
      labResults = null,
      isLoading = true,
      isRefreshing = false,
      scheduleIsLoading = false,
      labResultsIsLoading = false,
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

  /// Current cached lab results
  final List<LabResult>? labResults;

  /// Whether a profile operation is in progress
  final bool isLoading;

  /// Whether a manual refresh is in progress
  final bool isRefreshing;

  /// Whether a schedule operation is in progress
  final bool scheduleIsLoading;

  /// Whether a lab results operation is in progress
  final bool labResultsIsLoading;

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

  /// Whether user has lab results
  bool get hasLabResults => labResults != null && labResults!.isNotEmpty;

  /// Number of lab results
  int get labResultCount => labResults?.length ?? 0;

  /// Latest lab result if available
  LabResult? get latestLabResult =>
      hasLabResults ? labResults!.first : null;

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
    Object? primaryPet = _undefined,
    Object? fluidSchedule = _undefined,
    Object? medicationSchedules = _undefined,
    Object? labResults = _undefined,
    bool? isLoading,
    bool? isRefreshing,
    bool? scheduleIsLoading,
    bool? labResultsIsLoading,
    Object? error = _undefined,
    Object? lastUpdated = _undefined,
    CacheStatus? cacheStatus,
    Object? schedulesLoadedAt = _undefined,
    Object? schedulesLoadedDate = _undefined,
  }) {
    return ProfileState(
      primaryPet: primaryPet == _undefined
          ? this.primaryPet
          : primaryPet as CatProfile?,
      fluidSchedule: fluidSchedule == _undefined
          ? this.fluidSchedule
          : fluidSchedule as Schedule?,
      medicationSchedules: medicationSchedules == _undefined
          ? this.medicationSchedules
          : medicationSchedules as List<Schedule>?,
      labResults: labResults == _undefined
          ? this.labResults
          : labResults as List<LabResult>?,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      scheduleIsLoading: scheduleIsLoading ?? this.scheduleIsLoading,
      labResultsIsLoading: labResultsIsLoading ?? this.labResultsIsLoading,
      error: error == _undefined ? this.error : error as ProfileException?,
      lastUpdated: lastUpdated == _undefined
          ? this.lastUpdated
          : lastUpdated as DateTime?,
      cacheStatus: cacheStatus ?? this.cacheStatus,
      schedulesLoadedAt: schedulesLoadedAt == _undefined
          ? this.schedulesLoadedAt
          : schedulesLoadedAt as DateTime?,
      schedulesLoadedDate: schedulesLoadedDate == _undefined
          ? this.schedulesLoadedDate
          : schedulesLoadedDate as String?,
    );
  }

  /// Creates a copy with error cleared
  ProfileState clearError() {
    return copyWith(error: null);
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
        listEquals(other.labResults, labResults) &&
        other.isLoading == isLoading &&
        other.isRefreshing == isRefreshing &&
        other.scheduleIsLoading == scheduleIsLoading &&
        other.labResultsIsLoading == labResultsIsLoading &&
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
      Object.hashAll(labResults ?? []),
      isLoading,
      isRefreshing,
      scheduleIsLoading,
      labResultsIsLoading,
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
        'labResults: $labResults, '
        'isLoading: $isLoading, '
        'isRefreshing: $isRefreshing, '
        'scheduleIsLoading: $scheduleIsLoading, '
        'labResultsIsLoading: $labResultsIsLoading, '
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
    : _scheduleCoordinator = ScheduleCoordinator(
        scheduleService: _scheduleService,
      ),
      _cacheManager = ProfileCacheManager(),
      super(const ProfileState.initial());

  final PetService _petService;
  // ignore: unused_field - Used in ScheduleCoordinator initialization
  final ScheduleService _scheduleService;
  final Ref _ref;
  final ScheduleCoordinator _scheduleCoordinator;
  final ProfileCacheManager _cacheManager;

  /// Refresh all notifications for the current user and pet.
  ///
  /// This is a convenience wrapper around NotificationCoordinator.refreshAll
  /// that handles error logging. Safe to call after any schedule operation -
  /// failures won't break the schedule CRUD operation.
  Future<void> _refreshNotifications() async {
    try {
      await _ref.read(notificationCoordinatorProvider).refreshAll();
      if (kDebugMode) {
        debugPrint('[ProfileProvider] Notifications refreshed successfully');
      }
    } on Exception catch (e) {
      if (kDebugMode) {
        debugPrint('[ProfileProvider] Notification refresh failed: $e');
      }
      // Don't rethrow - shouldn't break schedule operations
    }
  }

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
        await _cacheManager.cachePrimaryPetId(pet.id);
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
    state = state.copyWith(isRefreshing: true, error: null);

    try {
      final pet = await _petService.getPrimaryPet(forceRefresh: true);

      state = state.copyWith(
        primaryPet: pet,
        isRefreshing: false,
        lastUpdated: DateTime.now(),
        cacheStatus: pet != null ? CacheStatus.fresh : CacheStatus.empty,
        error: null,
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
        await _cacheManager.cachePrimaryPetId(pet.id);

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

    final result = await _scheduleCoordinator.loadFluidSchedule(
      userId: currentUser.id,
      petId: primaryPet.id,
    );

    if (result.success) {
      // Update state with date tracking
      final now = DateTime.now();
      final todayStr =
          '${now.year}-'
          '${now.month.toString().padLeft(2, '0')}-'
          '${now.day.toString().padLeft(2, '0')}';

      state = state.copyWith(
        fluidSchedule: result.schedule,
        scheduleIsLoading: false,
        lastUpdated: now,
        schedulesLoadedAt: now,
        schedulesLoadedDate: todayStr,
      );
    } else {
      state = state.copyWith(
        scheduleIsLoading: false,
        error: result.error,
      );
    }

    return result.success;
  }

  /// Manually refresh the fluid schedule from Firestore
  Future<bool> refreshFluidSchedule() async {
    final primaryPet = state.primaryPet;
    if (primaryPet == null) return false;

    final currentUser = _ref.read(currentUserProvider);
    if (currentUser == null) return false;

    state = state.copyWith(scheduleIsLoading: true);

    final result = await _scheduleCoordinator.refreshFluidSchedule(
      userId: currentUser.id,
      petId: primaryPet.id,
    );

    if (result.success) {
      state = state.copyWith(
        fluidSchedule: result.schedule,
        scheduleIsLoading: false,
        lastUpdated: DateTime.now(),
      );
    } else {
      // Don't clear existing schedule data if refresh fails
      state = state.copyWith(
        scheduleIsLoading: false,
        error: result.error,
      );
    }

    return result.success;
  }

  /// Create a new fluid schedule
  Future<bool> createFluidSchedule(Schedule schedule) async {
    final primaryPet = state.primaryPet;
    if (primaryPet == null) return false;

    final currentUser = _ref.read(currentUserProvider);
    if (currentUser == null) return false;

    state = state.copyWith(scheduleIsLoading: true);

    final result = await _scheduleCoordinator.createFluidSchedule(
      userId: currentUser.id,
      petId: primaryPet.id,
      schedule: schedule,
      onSuccess: (Schedule newSchedule) async {
        // Schedule notifications if online
        if (_ref.read(isConnectedProvider)) {
          await _refreshNotifications();
        }
      },
    );

    if (result.success) {
      // Update the cache with the new schedule data
      state = state.copyWith(
        fluidSchedule: result.schedule,
        scheduleIsLoading: false,
        lastUpdated: DateTime.now(),
      );
    } else {
      state = state.copyWith(
        scheduleIsLoading: false,
        error: result.error,
      );
    }

    return result.success;
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

    final result = await _scheduleCoordinator.updateFluidSchedule(
      userId: currentUser.id,
      petId: primaryPet.id,
      schedule: schedule,
      oldSchedule: oldSchedule,
      onDeactivated: (Schedule deactivatedSchedule) async {
        // Refresh all notifications if online
        if (_ref.read(isConnectedProvider)) {
          await _refreshNotifications();
        }
      },
      onActiveUpdate: (Schedule activeSchedule) async {
        // Handle notification rescheduling if online
        if (_ref.read(isConnectedProvider)) {
          await _refreshNotifications();
        }
      },
    );

    if (result.success) {
      // Update the cache with the new schedule data
      state = state.copyWith(
        fluidSchedule: schedule,
        scheduleIsLoading: false,
        lastUpdated: DateTime.now(),
      );
    } else {
      state = state.copyWith(
        scheduleIsLoading: false,
        error: result.error,
      );
    }

    return result.success;
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

    final result = await _scheduleCoordinator.loadMedicationSchedules(
      userId: currentUser.id,
      petId: primaryPet.id,
    );

    if (result.success) {
      // Update state with date tracking
      final now = DateTime.now();
      final todayStr =
          '${now.year}-'
          '${now.month.toString().padLeft(2, '0')}-'
          '${now.day.toString().padLeft(2, '0')}';

      state = state.copyWith(
        medicationSchedules: result.schedules,
        scheduleIsLoading: false,
        lastUpdated: now,
        schedulesLoadedAt: now,
        schedulesLoadedDate: todayStr,
      );
    } else {
      state = state.copyWith(
        scheduleIsLoading: false,
        error: result.error,
      );
    }

    return result.success;
  }

  /// Manually refresh medication schedules from Firestore
  Future<bool> refreshMedicationSchedules() async {
    final primaryPet = state.primaryPet;
    if (primaryPet == null) return false;

    final currentUser = _ref.read(currentUserProvider);
    if (currentUser == null) return false;

    state = state.copyWith(scheduleIsLoading: true);

    final result = await _scheduleCoordinator.refreshMedicationSchedules(
      userId: currentUser.id,
      petId: primaryPet.id,
    );

    if (result.success) {
      state = state.copyWith(
        medicationSchedules: result.schedules,
        scheduleIsLoading: false,
        lastUpdated: DateTime.now(),
      );
    } else {
      // Don't clear existing schedule data if refresh fails
      state = state.copyWith(
        scheduleIsLoading: false,
        error: result.error,
      );
    }

    return result.success;
  }

  /// Update a medication schedule
  Future<bool> updateMedicationSchedule(Schedule schedule) async {
    final primaryPet = state.primaryPet;
    if (primaryPet == null) return false;

    final currentUser = _ref.read(currentUserProvider);
    if (currentUser == null) return false;

    final currentSchedules = state.medicationSchedules ?? [];

    state = state.copyWith(scheduleIsLoading: true);

    final result = await _scheduleCoordinator.updateMedicationSchedule(
      userId: currentUser.id,
      petId: primaryPet.id,
      schedule: schedule,
      currentSchedules: currentSchedules,
      onDeactivated: (Schedule deactivatedSchedule) async {
        // Refresh all notifications if online
        if (_ref.read(isConnectedProvider)) {
          await _refreshNotifications();
        }
      },
      onActiveUpdate: (Schedule activeSchedule) async {
        // Handle notification rescheduling if online
        if (_ref.read(isConnectedProvider)) {
          await _refreshNotifications();
        }
      },
    );

    if (result.success) {
      // Update the cache with the new schedule data
      final updatedSchedules = currentSchedules.map((s) {
        return s.id == schedule.id ? schedule : s;
      }).toList();

      state = state.copyWith(
        medicationSchedules: updatedSchedules,
        scheduleIsLoading: false,
        lastUpdated: DateTime.now(),
      );
    } else {
      state = state.copyWith(
        scheduleIsLoading: false,
        error: result.error,
      );
    }

    return result.success;
  }

  /// Add a new medication schedule
  Future<bool> addMedicationSchedule(Schedule schedule) async {
    final primaryPet = state.primaryPet;
    if (primaryPet == null) return false;

    final currentUser = _ref.read(currentUserProvider);
    if (currentUser == null) return false;

    state = state.copyWith(scheduleIsLoading: true);

    final result = await _scheduleCoordinator.addMedicationSchedule(
      userId: currentUser.id,
      petId: primaryPet.id,
      schedule: schedule,
      onSuccess: (Schedule newSchedule) async {
        // Schedule notifications if online
        if (_ref.read(isConnectedProvider)) {
          await _refreshNotifications();
        }
      },
    );

    if (result.success) {
      // Add to the cache
      final currentSchedules = state.medicationSchedules ?? [];
      final updatedSchedules = [...currentSchedules, result.schedule!];

      state = state.copyWith(
        medicationSchedules: updatedSchedules,
        scheduleIsLoading: false,
        lastUpdated: DateTime.now(),
      );
    } else {
      state = state.copyWith(
        scheduleIsLoading: false,
        error: result.error,
      );
    }

    return result.success;
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

    final result = await _scheduleCoordinator.deleteMedicationSchedule(
      userId: currentUser.id,
      petId: primaryPet.id,
      scheduleId: scheduleId,
      scheduleToDelete: scheduleToDelete,
      onSuccess: (String deletedId, Schedule? deletedSchedule) async {
        // Refresh all notifications if online
        if (_ref.read(isConnectedProvider)) {
          await _refreshNotifications();
        }
      },
    );

    if (result.success) {
      // Remove from the cache
      final updatedSchedules = currentSchedules
          .where((s) => s.id != scheduleId)
          .toList();

      state = state.copyWith(
        medicationSchedules: updatedSchedules,
        scheduleIsLoading: false,
        lastUpdated: DateTime.now(),
      );
    } else {
      state = state.copyWith(
        scheduleIsLoading: false,
        error: result.error,
      );
    }

    return result.success;
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

    final result = await _scheduleCoordinator.loadAllSchedules(
      userId: currentUser.id,
      petId: primaryPet.id,
    );

    if (result.success) {
      // Update state with new schedules and date tracking
      final now = DateTime.now();
      final todayStr =
          '${now.year}-'
          '${now.month.toString().padLeft(2, '0')}-'
          '${now.day.toString().padLeft(2, '0')}';

      state = state.copyWith(
        fluidSchedule: result.schedule,
        medicationSchedules: result.schedules,
        schedulesLoadedAt: now,
        schedulesLoadedDate: todayStr,
      );

      // Track successful pre-load
      final analyticsService = _ref.read(analyticsServiceDirectProvider);
      await analyticsService.trackFeatureUsed(
        featureName: AnalyticsEvents.schedulesPreloaded,
        additionalParams: {
          AnalyticsParams.medicationCount: result.schedules?.length ?? 0,
          AnalyticsParams.hasFluidSchedule: result.schedule != null,
          AnalyticsParams.cacheMiss: true,
        },
      );

      if (kDebugMode) {
        debugPrint(
          '[ProfileNotifier] Schedules preloaded: '
          '${result.schedules?.length ?? 0} medications, '
          'fluid: ${result.schedule != null}',
        );
      }
    } else {
      // Silent failure - log to analytics but don't show error to user
      // Logging popups will fall back to on-demand loading

      final analyticsService = _ref.read(analyticsServiceDirectProvider);
      await analyticsService.trackError(
        errorType: 'schedules_preload_failed',
        errorContext: result.error?.toString() ?? 'Unknown error',
      );

      if (kDebugMode) {
        debugPrint(
          '[ProfileNotifier] Failed to preload schedules: ${result.error}',
        );
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
  // LAB RESULTS MANAGEMENT
  // ==========================================================================

  /// Load lab results for the primary pet
  ///
  /// Loads the most recent lab results from Firestore and caches them.
  /// Results are ordered by test date (most recent first).
  Future<bool> loadLabResults({int limit = 20}) async {
    final primaryPet = state.primaryPet;
    if (primaryPet == null) {
      state = state.copyWith(labResultsIsLoading: false);
      return false;
    }

    state = state.copyWith(labResultsIsLoading: true);

    try {
      final results = await _petService.getLabResults(
        primaryPet.id,
        limit: limit,
      );

      state = state.copyWith(
        labResults: results,
        labResultsIsLoading: false,
        lastUpdated: DateTime.now(),
      );

      return true;
    } on Exception catch (e) {
      debugPrint('Error loading lab results: $e');
      state = state.copyWith(
        labResultsIsLoading: false,
        error: PetServiceException('Failed to load lab results: $e'),
      );
      return false;
    }
  }

  /// Manually refresh lab results from Firestore
  Future<bool> refreshLabResults({int limit = 20}) async {
    final primaryPet = state.primaryPet;
    if (primaryPet == null) return false;

    state = state.copyWith(labResultsIsLoading: true);

    try {
      final results = await _petService.getLabResults(
        primaryPet.id,
        limit: limit,
      );

      state = state.copyWith(
        labResults: results,
        labResultsIsLoading: false,
        lastUpdated: DateTime.now(),
      );

      return true;
    } on Exception catch (e) {
      debugPrint('Error refreshing lab results: $e');
      // Don't clear existing results if refresh fails
      state = state.copyWith(
        labResultsIsLoading: false,
        error: PetServiceException('Failed to refresh lab results: $e'),
      );
      return false;
    }
  }

  /// Gets a specific lab result by ID
  Future<LabResult?> getLabResult(String labResultId) async {
    final primaryPet = state.primaryPet;
    if (primaryPet == null) return null;

    return _petService.getLabResult(primaryPet.id, labResultId);
  }

  /// Create a new lab result
  ///
  /// Creates a new lab result and updates both the denormalized snapshot
  /// on the pet document and the cached lab results list.
  Future<bool> createLabResult({
    required LabResult labResult,
    String? preferredUnitSystem,
  }) async {
    final primaryPet = state.primaryPet;
    if (primaryPet == null) return false;

    state = state.copyWith(labResultsIsLoading: true);

    final result = await _petService.createLabResult(
      petId: primaryPet.id,
      labResult: labResult,
      preferredUnitSystem: preferredUnitSystem,
    );

    switch (result) {
      case PetSuccess():
        // Reload lab results to get the updated list
        await loadLabResults();

        // Also reload the pet to get the updated latestLabResult
        await refreshPrimaryPet();

        return true;

      case PetFailure(exception: final exception):
        state = state.copyWith(
          labResultsIsLoading: false,
          error: exception,
        );
        return false;
    }
  }

  // ==========================================================================
  // NOTIFICATION INTEGRATION (Step 6.2)
  // ==========================================================================

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

/// Optimized provider to get the cached lab results
final labResultsProvider = Provider<List<LabResult>?>((ref) {
  return ref.watch(profileProvider.select((state) => state.labResults));
});

/// Optimized provider to check if the pet has lab results
final hasLabResultsProvider = Provider<bool>((ref) {
  return ref.watch(profileProvider.select((state) => state.hasLabResults));
});

/// Optimized provider to get lab result count
final labResultCountProvider = Provider<int>((ref) {
  return ref.watch(profileProvider.select((state) => state.labResultCount));
});

/// Optimized provider to get the latest lab result
final latestLabResultProvider = Provider<LabResult?>((ref) {
  return ref.watch(profileProvider.select((state) => state.latestLabResult));
});

/// Optimized provider to check if lab results are loading
final labResultsIsLoadingProvider = Provider<bool>((ref) {
  return ref.watch(
    profileProvider.select((state) => state.labResultsIsLoading),
  );
});
