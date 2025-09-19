import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/features/profile/exceptions/profile_exceptions.dart';
import 'package:hydracat/features/profile/models/cat_profile.dart';
import 'package:hydracat/features/profile/services/pet_service.dart';
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
    this.isLoading = false,
    this.isRefreshing = false,
    this.error,
    this.lastUpdated,
    this.cacheStatus = CacheStatus.fresh,
  });

  /// Creates initial empty state
  const ProfileState.initial()
    : primaryPet = null,
      isLoading = false,
      isRefreshing = false,
      error = null,
      lastUpdated = null,
      cacheStatus = CacheStatus.empty;

  /// Creates loading state
  const ProfileState.loading()
    : primaryPet = null,
      isLoading = true,
      isRefreshing = false,
      error = null,
      lastUpdated = null,
      cacheStatus = CacheStatus.empty;

  /// Current primary pet profile
  final CatProfile? primaryPet;

  /// Whether a profile operation is in progress
  final bool isLoading;

  /// Whether a manual refresh is in progress
  final bool isRefreshing;

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

  /// Creates a copy of this [ProfileState] with the given fields replaced
  ProfileState copyWith({
    CatProfile? primaryPet,
    bool? isLoading,
    bool? isRefreshing,
    ProfileException? error,
    DateTime? lastUpdated,
    CacheStatus? cacheStatus,
  }) {
    return ProfileState(
      primaryPet: primaryPet ?? this.primaryPet,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
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
        other.isLoading == isLoading &&
        other.isRefreshing == isRefreshing &&
        other.error == error &&
        other.lastUpdated == lastUpdated &&
        other.cacheStatus == cacheStatus;
  }

  @override
  int get hashCode {
    return Object.hash(
      primaryPet,
      isLoading,
      isRefreshing,
      error,
      lastUpdated,
      cacheStatus,
    );
  }

  @override
  String toString() {
    return 'ProfileState('
        'primaryPet: $primaryPet, '
        'isLoading: $isLoading, '
        'isRefreshing: $isRefreshing, '
        'error: $error, '
        'lastUpdated: $lastUpdated, '
        'cacheStatus: $cacheStatus'
        ')';
  }
}

/// Notifier class for managing profile state
class ProfileNotifier extends StateNotifier<ProfileState> {
  /// Creates a [ProfileNotifier] with the provided dependencies
  ProfileNotifier(this._petService, this._ref)
    : super(const ProfileState.initial());

  final PetService _petService;
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
}

/// Provider for the PetService instance
final petServiceProvider = Provider<PetService>((ref) {
  return PetService();
});

/// Provider for the profile state notifier
final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((
  ref,
) {
  final service = ref.read(petServiceProvider);
  return ProfileNotifier(service, ref);
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
