import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hydracat/features/auth/models/app_user.dart';
import 'package:hydracat/features/auth/models/auth_state.dart';
import 'package:hydracat/features/auth/services/auth_service.dart';
import 'package:hydracat/features/onboarding/services/onboarding_service.dart';
import 'package:hydracat/features/profile/services/pet_service.dart';
import 'package:hydracat/shared/services/firebase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for the AuthService instance
///
/// This creates a single instance of AuthService that can be used throughout
/// the app for authentication operations.
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Notifier class for managing authentication state
///
/// Handles authentication operations and maintains the current auth state,
/// including loading states and error handling.
class AuthNotifier extends StateNotifier<AuthState> {
  /// Creates an [AuthNotifier] with the provided auth service
  AuthNotifier(this._authService) : super(const AuthStateLoading()) {
    _initializeAuth();
  }

  final AuthService _authService;
  bool _hasRecentError = false;

  /// Firestore instance for user data persistence
  FirebaseFirestore get _firestore => FirebaseService().firestore;

  /// Cache for user data to reduce Firestore calls
  AppUser? _cachedUserData;
  DateTime? _cacheTimestamp;
  String? _cachedUserId;

  /// Cache TTL in minutes (default: 5 minutes)
  static const int _cacheTTLMinutes = 5;

  /// Callback for handling authentication errors in UI
  void Function(AuthStateError)? errorCallback;

  /// Initialize authentication by waiting for auth service to be ready
  /// then listening to auth state changes
  Future<void> _initializeAuth() async {
    try {
      // Wait for Firebase Auth to determine initial state from persistence
      await _authService.waitForInitialization();

      // Now listen to auth state changes
      _listenToAuthChanges();

      // Set initial state based on current user with Firestore data
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        final completeUser = await _loadCompleteUserData(currentUser);
        state = AuthStateAuthenticated(user: completeUser);
      } else {
        state = const AuthStateUnauthenticated();
      }
    } on Exception catch (e) {
      state = AuthStateError(
        message: 'Failed to initialize authentication: $e',
        code: 'initialization_error',
      );
    }
  }

  /// Check if cached user data is valid and not expired
  bool _isCacheValid(String userId) {
    if (_cachedUserData == null ||
        _cacheTimestamp == null ||
        _cachedUserId != userId) {
      return false;
    }

    final now = DateTime.now();
    final cacheAge = now.difference(_cacheTimestamp!);
    return cacheAge.inMinutes < _cacheTTLMinutes;
  }

  /// Update cache with new user data
  void _updateCache(AppUser userData) {
    _cachedUserData = userData;
    _cacheTimestamp = DateTime.now();
    _cachedUserId = userData.id;

    if (kDebugMode) {
      debugPrint('Auth cache updated for user: ${userData.id}');
    }
  }

  /// Clear the user data cache
  void _clearCache() {
    _cachedUserData = null;
    _cacheTimestamp = null;
    _cachedUserId = null;

    if (kDebugMode) {
      debugPrint('Auth cache cleared');
    }
  }

  /// Load complete user data by merging Firebase Auth data with Firestore data
  /// Uses in-memory cache to reduce Firestore calls
  Future<AppUser> _loadCompleteUserData(AppUser firebaseUser) async {
    // Check if we have valid cached data for this user
    if (_isCacheValid(firebaseUser.id)) {
      if (kDebugMode) {
        debugPrint('Using cached user data for: ${firebaseUser.id}');
      }
      return _cachedUserData!;
    }

    if (kDebugMode) {
      debugPrint(
        'Fetching fresh user data from Firestore for: ${firebaseUser.id}',
      );
    }

    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(firebaseUser.id)
          .get();

      final AppUser completeUser;
      if (userDoc.exists) {
        final firestoreData = userDoc.data()!;
        completeUser = firebaseUser.copyWith(
          hasCompletedOnboarding:
              firestoreData['hasCompletedOnboarding'] as bool? ?? false,
          primaryPetId: firestoreData['primaryPetId'] as String?,
        );
      } else {
        // No Firestore document yet, return Firebase auth data with defaults
        completeUser = firebaseUser;
      }

      // Cache the result
      _updateCache(completeUser);
      return completeUser;
    } on Exception {
      // If Firestore fetch fails, return Firebase auth data with defaults
      // Don't cache failed results
      return firebaseUser;
    }
  }

  /// Listen to Firebase auth state changes and update the state accordingly
  void _listenToAuthChanges() {
    _authService.authStateChanges.listen((user) async {
      if (user != null) {
        _hasRecentError = false; // Clear error flag on successful auth
        try {
          final completeUser = await _loadCompleteUserData(user);
          state = AuthStateAuthenticated(user: completeUser);
        } on Exception {
          // If Firestore fetch fails, use Firebase auth data only
          state = AuthStateAuthenticated(user: user);
        }
      } else {
        // Only set to unauthenticated if we don't have a recent error
        // This prevents auth state changes from overriding error messages
        if (!_hasRecentError && state is! AuthStateError) {
          state = const AuthStateUnauthenticated();
        } else {}
      }
    });
  }

  /// Sign up with email and password
  ///
  /// Creates a new user account and automatically sends email verification.
  /// Updates the state to show loading, success, or error states.
  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    _hasRecentError = false; // Clear error flag when user attempts new action
    state = const AuthStateLoading();

    final result = await _authService.signUp(
      email: email,
      password: password,
    );

    if (result is AuthSuccess) {
      // State will be updated automatically by _listenToAuthChanges
      // when Firebase auth state changes
    } else if (result is AuthFailure) {
      state = AuthStateError(
        message: result.message,
        code: result.code,
        details: result.exception, // Store the original exception
      );
    }
  }

  /// Sign in with email and password
  ///
  /// Authenticates existing user with email and password.
  /// Updates the state to show loading, success, or error states.
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    _hasRecentError = false; // Clear error flag when user attempts new action
    state = const AuthStateLoading();

    final result = await _authService.signIn(
      email: email,
      password: password,
    );

    if (result is AuthSuccess) {
      // State will be updated automatically by _listenToAuthChanges
      // when Firebase auth state changes
    } else if (result is AuthFailure) {
      // Set error flag to prevent auth listener from overriding
      _hasRecentError = true;

      // Create error state
      final errorState = AuthStateError(
        message: result.message,
        code: result.code,
        details: result.exception, // Store the original exception
      );

      // Set error state immediately
      state = errorState;
      // Immediately call error callback if set (for UI handling)
      errorCallback?.call(errorState);
    }
  }

  /// Sign out current user
  ///
  /// Signs out the currently authenticated user and updates state.
  Future<void> signOut() async {
    state = const AuthStateLoading();

    // Clear cache on sign out
    _clearCache();

    final success = await _authService.signOut();
    if (!success) {
      state = const AuthStateError(
        message: 'Failed to sign out. Please try again.',
      );
    }
    // If successful, _listenToAuthChanges will update state to unauthenticated
  }

  /// Send password reset email
  ///
  /// Sends a password reset email to the specified email address.
  /// Returns true if successful, false if there was an error.
  Future<bool> sendPasswordResetEmail(String email) async {
    final result = await _authService.sendPasswordResetEmail(email);
    return result is AuthSuccess;
  }

  /// Send email verification to current user
  ///
  /// Sends an email verification link to the currently authenticated user.
  /// Returns true if successful, false if there was an error.
  Future<bool> sendEmailVerification() async {
    final result = await _authService.sendEmailVerification();
    return result is AuthSuccess;
  }

  /// Check if current user's email is verified
  ///
  /// Checks if current user's email is verified using smart caching.
  /// Returns true if email is verified, false otherwise.
  Future<bool> checkEmailVerification({bool forceReload = false}) async {
    return _authService.checkEmailVerification(forceReload: forceReload);
  }

  /// Sign in with Google
  ///
  /// Initiates Google Sign-In flow and authenticates with Firebase.
  /// Updates the state to show loading, success, or error states.
  Future<void> signInWithGoogle() async {
    _hasRecentError = false; // Clear error flag when user attempts new action
    state = const AuthStateLoading();

    final result = await _authService.signInWithGoogle();

    if (result is AuthSuccess) {
      // State will be updated automatically by _listenToAuthChanges
      // when Firebase auth state changes
    } else if (result is AuthFailure) {
      state = AuthStateError(
        message: result.message,
        code: result.code,
        details: result.exception, // Store the original exception
      );
    }
  }

  /// Sign in with Apple
  ///
  /// Initiates Apple Sign-In flow and authenticates with Firebase.
  /// Updates the state to show loading, success, or error states.
  Future<void> signInWithApple() async {
    _hasRecentError = false; // Clear error flag when user attempts new action
    state = const AuthStateLoading();

    final result = await _authService.signInWithApple();

    if (result is AuthSuccess) {
      // State will be updated automatically by _listenToAuthChanges
      // when Firebase auth state changes
    } else if (result is AuthFailure) {
      state = AuthStateError(
        message: result.message,
        code: result.code,
        details: result.exception, // Store the original exception
      );
    }
  }

  /// Clear error state
  ///
  /// Resets the error state back to the appropriate auth state
  /// (authenticated or unauthenticated based on current user).
  void clearError() {
    _hasRecentError = false; // Clear the error flag
    final currentUser = _authService.currentUser;
    if (currentUser != null) {
      state = AuthStateAuthenticated(user: currentUser);
    } else {
      state = const AuthStateUnauthenticated();
    }
  }

  /// Mark onboarding as complete for the current user
  ///
  /// Updates both local state and Firestore with onboarding completion
  /// and primary pet ID. Uses optimistic updates for better UX.
  /// Returns true if successful, false otherwise.
  Future<bool> markOnboardingComplete(String primaryPetId) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      if (kDebugMode) {
        debugPrint('WARNING: markOnboardingComplete called with null user');
      }
      return false;
    }

    // Create updated user with new data (optimistic update)
    final updatedUser = currentUser.copyWith(
      hasCompletedOnboarding: true,
      primaryPetId: primaryPetId,
    );

    // Update cache and local state immediately (optimistic)
    _updateCache(updatedUser);
    state = AuthStateAuthenticated(user: updatedUser);

    try {
      // Update user data in Firestore in the background
      await _updateUserDataInFirestore(
        currentUser.id,
        hasCompletedOnboarding: true,
        primaryPetId: primaryPetId,
      );

      if (kDebugMode) {
        debugPrint('Successfully synced onboarding completion to Firestore');
      }
      return true;
    } on Exception catch (e) {
      if (kDebugMode) {
        debugPrint(
          'ERROR: Failed to sync onboarding completion to Firestore: $e',
        );
      }
      // Even if Firestore update fails, we keep the optimistic update
      // The user sees the change immediately, and it will retry later
      return true; // Return true because user sees the update
    }
  }

  /// Mark onboarding as skipped for the current user
  ///
  /// Updates local state only (not persisted to Firestore).
  /// Returns true if successful, false otherwise.
  Future<bool> markOnboardingSkipped() async {
    // Prefer user from current auth state; fallback to auth service
    final stateUser = state.user;
    final currentUser = stateUser ?? _authService.currentUser;

    if (currentUser == null) {
      if (kDebugMode) {
        debugPrint('WARNING: markOnboardingSkipped called with null user');
      }
      return false;
    }

    try {
      // Create updated user with skip flag
      final updatedUser = currentUser.copyWith(
        hasSkippedOnboarding: true,
      );

      // Update cache with new data (local state only)
      _updateCache(updatedUser);

      // Update local state only (no Firestore persistence)
      state = AuthStateAuthenticated(user: updatedUser);

      return true;
    } on Exception catch (e) {
      if (kDebugMode) {
        debugPrint('ERROR: Failed to mark onboarding as skipped: $e');
      }
      return false;
    }
  }

  /// Update onboarding status for the current user
  ///
  /// Updates completion status and pet ID (skip status handled separately).
  /// Uses optimistic updates for better UX.
  /// Returns true if successful, false otherwise.
  Future<bool> updateOnboardingStatus({
    bool? hasCompletedOnboarding,
    String? primaryPetId,
  }) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      if (kDebugMode) {
        debugPrint('WARNING: updateOnboardingStatus called with null user');
      }
      return false;
    }

    // Create updated user with new data (optimistic update)
    final updatedUser = currentUser.copyWith(
      hasCompletedOnboarding: hasCompletedOnboarding,
      primaryPetId: primaryPetId,
    );

    // Update cache and local state immediately (optimistic)
    _updateCache(updatedUser);
    state = AuthStateAuthenticated(user: updatedUser);

    try {
      // Update user data in Firestore in the background
      await _updateUserDataInFirestore(
        currentUser.id,
        hasCompletedOnboarding: hasCompletedOnboarding,
        primaryPetId: primaryPetId,
      );

      if (kDebugMode) {
        debugPrint('Successfully synced onboarding status to Firestore');
      }
      return true;
    } on Exception catch (e) {
      if (kDebugMode) {
        debugPrint('ERROR: Failed to sync onboarding status to Firestore: $e');
      }
      // Keep optimistic update even if Firestore sync fails
      return true;
    }
  }

  /// Reset onboarding status for the current user
  ///
  /// This method resets completion flag to false and clears pet ID, allowing
  /// the user to go through onboarding again. Skip status is reset locally.
  /// Returns true if successful, false otherwise.
  Future<bool> resetOnboardingStatus() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      if (kDebugMode) {
        debugPrint('WARNING: resetOnboardingStatus called with null user');
      }
      return false;
    }

    try {
      // Update user data in Firestore
      await _updateUserDataInFirestore(
        currentUser.id,
        hasCompletedOnboarding: false,
        primaryPetId: '', // Use empty string to clear the field
      );

      // Create updated user with reset data
      final updatedUser = currentUser.copyWith(
        hasCompletedOnboarding: false,
        hasSkippedOnboarding: false,
      );

      // Update cache with new data
      _updateCache(updatedUser);

      // Update local state (including resetting skip status locally)
      state = AuthStateAuthenticated(user: updatedUser);

      return true;
    } on Exception catch (e) {
      if (kDebugMode) {
        debugPrint('ERROR: Failed to reset onboarding status: $e');
      }
      return false;
    }
  }

  /// Update user data in Firestore
  ///
  /// Private helper method to persist user data changes to Firestore.
  Future<void> _updateUserDataInFirestore(
    String userId, {
    bool? hasCompletedOnboarding,
    String? primaryPetId,
  }) async {
    final userDoc = _firestore.collection('users').doc(userId);

    final updateData = <String, dynamic>{};
    if (hasCompletedOnboarding != null) {
      updateData['hasCompletedOnboarding'] = hasCompletedOnboarding;
    }
    if (primaryPetId != null) {
      updateData['primaryPetId'] = primaryPetId;
    }

    if (updateData.isNotEmpty) {
      updateData['updatedAt'] = FieldValue.serverTimestamp();

      if (kDebugMode) {
        debugPrint(
          'Updating user data in Firestore for user: $userId '
          'with data: $updateData',
        );
      }

      await userDoc.set(updateData, SetOptions(merge: true));

      if (kDebugMode) {
        debugPrint('Successfully updated user data in Firestore');
      }
    } else {
      if (kDebugMode) {
        debugPrint(
          'No data to update in Firestore for user: $userId',
        );
      }
    }
  }

  /// Get current user with latest state
  ///
  /// Helper method to get the current user from the auth state.
  AppUser? getCurrentUser() {
    return state.user;
  }

  /// Debug method to reset user state for testing onboarding flows
  /// Completely wipes all user data from Firestore and local storage
  /// while keeping authentication. This provides a true fresh start.
  /// Only intended for development/testing purposes
  Future<void> debugResetUserState() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      throw Exception('No authenticated user found');
    }

    try {
      // Step 1: Delete ALL user data from Firestore
      await _deleteAllUserDataFromFirestore(currentUser.id);

      // Step 2: Clear all local caches and storage
      await _clearAllLocalData();

      // Step 3: Clear any existing onboarding data
      await _clearOnboardingData(currentUser.id);

      // Step 4: Reset local state to fresh user (no onboarding, no primary pet)
      // DO NOT call updateOnboardingStatus() here as it would recreate the
      // Firestore document we just deleted. Instead, update local state only.
      // We create a completely fresh user by keeping only auth data and
      // clearing all onboarding/profile data (defaults to false/null)
      final freshUser = AppUser(
        id: currentUser.id,
        email: currentUser.email,
        displayName: currentUser.displayName,
        photoURL: currentUser.photoURL,
        emailVerified: currentUser.emailVerified,
        provider: currentUser.provider,
        createdAt: currentUser.createdAt,
        lastSignInAt: currentUser.lastSignInAt,
      );

      // Update cache and state with fresh user (local only, no Firestore)
      _updateCache(freshUser);
      state = AuthStateAuthenticated(user: freshUser);

      // Step 5: Clear auth cache to ensure fresh data on next load
      _clearCache();

      if (kDebugMode) {
        debugPrint(
          'Debug: Completely reset user data for ${currentUser.id} - '
          'all Firestore data and local storage cleared',
        );
      }
    } catch (e) {
      throw Exception('Failed to reset user state: $e');
    }
  }

  /// Helper method to delete ALL user data from Firestore (debug only)
  Future<void> _deleteAllUserDataFromFirestore(String userId) async {
    final firestore = FirebaseFirestore.instance;
    final userDocRef = firestore.collection('users').doc(userId);

    try {
      // Check if user document exists
      final userDoc = await userDocRef.get();
      if (!userDoc.exists) {
        if (kDebugMode) {
          debugPrint('Debug: User document does not exist, nothing to delete');
        }
        return;
      }

      // Delete known subcollections that might exist
      final knownSubcollections = [
        'pets',
        'schedules',
        'fluidSessions',
        'weights',
        'medications',
        'onboarding',
        'checkpoints',
      ];

      if (kDebugMode) {
        debugPrint(
          'Debug: Deleting known subcollections: $knownSubcollections',
        );
      }

      // Delete all documents in each known subcollection
      for (final subcollectionName in knownSubcollections) {
        if (kDebugMode) {
          debugPrint('Debug: Processing subcollection: $subcollectionName');
        }
        await _deleteSubcollection(userDocRef.collection(subcollectionName));
      }

      // Finally, delete the user document itself
      if (kDebugMode) {
        debugPrint('Debug: Deleting user document for $userId');
      }
      await userDocRef.delete();

      // Verify user document is deleted
      final verifyDoc = await userDocRef.get();
      if (verifyDoc.exists) {
        if (kDebugMode) {
          debugPrint(
            'Debug: WARNING - User document still exists after deletion!',
          );
        }
      } else {
        if (kDebugMode) {
          debugPrint(
            'Debug: ✅ Verified - User document successfully deleted',
          );
        }
      }

      // Verify all subcollections are empty
      var allSubcollectionsEmpty = true;
      for (final subcollectionName in knownSubcollections) {
        final remainingDocs =
            await userDocRef.collection(subcollectionName).limit(1).get();
        if (remainingDocs.docs.isNotEmpty) {
          allSubcollectionsEmpty = false;
          if (kDebugMode) {
            debugPrint(
              'Debug: WARNING - Subcollection $subcollectionName still has '
              'documents after deletion!',
            );
          }
        }
      }

      if (kDebugMode) {
        if (allSubcollectionsEmpty) {
          debugPrint(
            'Debug: ✅ Successfully deleted all user data from Firestore - '
            'verified complete',
          );
        } else {
          debugPrint(
            'Debug: ⚠️ User data deletion completed with warnings - '
            'some subcollections may still have documents',
          );
        }
      }
    } on Exception catch (e) {
      if (kDebugMode) {
        debugPrint('Debug: Error deleting user data from Firestore: $e');
      }
      // Don't throw here - continue with reset even if Firestore deletion fails
    }
  }

  /// Helper method to delete all documents in a subcollection (debug only)
  /// Uses recursive deletion to handle pagination and ensures complete removal
  /// For the 'pets' subcollection, also recursively deletes nested
  /// subcollections
  Future<void> _deleteSubcollection(CollectionReference subcollection) async {
    const batchSize = 500; // Firestore batch limit
    var totalDeleted = 0;

    try {
      // Special handling for pets subcollection - need to delete nested
      // subcollections first
      final isPetsCollection = subcollection.id == 'pets';

      if (isPetsCollection && kDebugMode) {
        debugPrint(
          'Debug: Detected pets subcollection - '
          'will recursively delete nested subcollections',
        );
      }

      while (true) {
        // Get a batch of documents (Firestore queries may be paginated)
        final snapshot = await subcollection.limit(batchSize).get();

        if (snapshot.docs.isEmpty) {
          // No more documents to delete
          break;
        }

        if (kDebugMode) {
          debugPrint(
            'Debug: Found ${snapshot.docs.length} documents '
            'in ${subcollection.id}, deleting...',
          );
        }

        // For pets collection, delete nested subcollections first
        if (isPetsCollection) {
          for (final petDoc in snapshot.docs) {
            if (kDebugMode) {
              debugPrint(
                'Debug: Processing pet ${petDoc.id} - '
                'deleting nested subcollections',
              );
            }

            // Delete known nested subcollections under each pet
            final petNestedSubcollections = [
              'schedules',
              'fluidSessions',
              'weights',
              'medications',
            ];

            for (final nestedSubcollection in petNestedSubcollections) {
              final nestedCollectionRef =
                  petDoc.reference.collection(nestedSubcollection);

              if (kDebugMode) {
                debugPrint(
                  'Debug: Deleting ${petDoc.id}/$nestedSubcollection',
                );
              }

              // Recursively delete this nested subcollection
              await _deleteNestedSubcollection(nestedCollectionRef);
            }
          }
        }

        // Now delete all documents in this batch
        final batch = FirebaseFirestore.instance.batch();
        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();

        totalDeleted += snapshot.docs.length;

        // If we got fewer documents than the batch size, we're done
        if (snapshot.docs.length < batchSize) {
          break;
        }
      }

      if (kDebugMode && totalDeleted > 0) {
        debugPrint(
          'Debug: Successfully deleted $totalDeleted total documents '
          'from ${subcollection.id}',
        );
      }

      // Verify deletion completed successfully
      final verifySnapshot = await subcollection.limit(1).get();
      if (verifySnapshot.docs.isNotEmpty) {
        if (kDebugMode) {
          debugPrint(
            'Debug: WARNING - Subcollection ${subcollection.id} still has '
            'documents after deletion attempt!',
          );
        }
      }
    } on Exception catch (e) {
      if (kDebugMode) {
        debugPrint(
          'Debug: Error deleting subcollection ${subcollection.id}: $e',
        );
      }
      // Continue with other deletions even if one fails
    }
  }

  /// Helper method to delete nested subcollections (e.g., schedules under pets)
  /// Simpler version without nested subcollection handling since we know
  /// schedules/weights/etc don't have their own nested collections
  Future<void> _deleteNestedSubcollection(
    CollectionReference subcollection,
  ) async {
    const batchSize = 500;

    try {
      while (true) {
        final snapshot = await subcollection.limit(batchSize).get();

        if (snapshot.docs.isEmpty) {
          break;
        }

        final batch = FirebaseFirestore.instance.batch();
        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();

        if (snapshot.docs.length < batchSize) {
          break;
        }
      }
    } on Exception catch (e) {
      if (kDebugMode) {
        debugPrint(
          'Debug: Error deleting nested subcollection ${subcollection.id}: $e',
        );
      }
    }
  }

  /// Helper method to clear all local data (debug only)
  Future<void> _clearAllLocalData() async {
    try {
      // Clear PetService caches (now async, must await)
      await PetService().clearCache();

      // Clear SharedPreferences data
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Clear secure storage
      const secureStorage = FlutterSecureStorage();
      await secureStorage.deleteAll();

      if (kDebugMode) {
        debugPrint(
          'Debug: Cleared all local data '
          '(SharedPreferences, SecureStorage, caches)',
        );
      }
    } on Exception catch (e) {
      if (kDebugMode) {
        debugPrint('Debug: Error clearing local data: $e');
      }
      // Don't throw here - continue with reset even if local clearing fails
    }
  }

  /// Helper method to clear onboarding data (debug only)
  Future<void> _clearOnboardingData(String userId) async {
    try {
      await OnboardingService().clearOnboardingData(userId);

      if (kDebugMode) {
        debugPrint('Debug: Cleared onboarding data for user $userId');
      }
    } on Exception catch (e) {
      if (kDebugMode) {
        debugPrint('Debug: Error clearing onboarding data: $e');
      }
      // Don't throw here - continue with reset even if onboarding
      //clearing fails
    }
  }
}

/// Provider for the authentication state notifier
///
/// This manages the global authentication state of the app, including
/// user authentication status, loading states, and errors.
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.read(authServiceProvider);
  return AuthNotifier(authService);
});

/// Optimized provider to get the current authenticated user
///
/// Returns the current user if authenticated, null otherwise.
/// Only rebuilds when the user actually changes, not on loading/error states.
final currentUserProvider = Provider<AppUser?>((ref) {
  return ref.watch(authProvider.select((state) => state.user));
});

/// Optimized provider to check if user is authenticated
///
/// Returns true if user is currently authenticated, false otherwise.
/// Only rebuilds when authentication status changes, not on loading/error states.
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider.select((state) => state.isAuthenticated));
});

/// Optimized provider to check if authentication is loading
///
/// Returns true if authentication is currently in progress, false otherwise.
/// Only rebuilds when loading state changes.
final authIsLoadingProvider = Provider<bool>((ref) {
  return ref.watch(authProvider.select((state) => state is AuthStateLoading));
});

/// Optimized provider to get current authentication error
///
/// Returns the current error if in error state, null otherwise.
/// Only rebuilds when error state changes.
final authErrorProvider = Provider<AuthStateError?>((ref) {
  return ref.watch(
    authProvider.select((state) => state is AuthStateError ? state : null),
  );
});

/// Optimized provider to check if user has completed onboarding
///
/// Returns true if user has completed onboarding, false otherwise.
/// Only rebuilds when onboarding completion status changes.
final hasCompletedOnboardingProvider = Provider<bool>((ref) {
  return ref.watch(
    authProvider.select((state) => state.user?.hasCompletedOnboarding ?? false),
  );
});

/// Optimized provider to check if user has skipped onboarding
///
/// Returns true if user has deliberately skipped onboarding, false otherwise.
/// Only rebuilds when onboarding skip status changes.
final hasSkippedOnboardingProvider = Provider<bool>((ref) {
  return ref.watch(
    authProvider.select((state) => state.user?.hasSkippedOnboarding ?? false),
  );
});

/// Optimized provider to get user's primary pet ID
///
/// Returns the primary pet ID if set, null otherwise.
/// Only rebuilds when primary pet ID changes.
final primaryPetIdProvider = Provider<String?>((ref) {
  return ref.watch(authProvider.select((state) => state.user?.primaryPetId));
});
