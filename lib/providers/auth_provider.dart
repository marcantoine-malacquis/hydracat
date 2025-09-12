import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/features/auth/models/app_user.dart';
import 'package:hydracat/features/auth/models/auth_state.dart';
import 'package:hydracat/features/auth/services/auth_service.dart';
import 'package:hydracat/shared/services/firebase_service.dart';

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

      // Set initial state based on current user
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        state = AuthStateAuthenticated(user: currentUser);
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

  /// Listen to Firebase auth state changes and update the state accordingly
  void _listenToAuthChanges() {
    _authService.authStateChanges.listen((user) {
      if (user != null) {
        _hasRecentError = false; // Clear error flag on successful auth
        state = AuthStateAuthenticated(user: user);
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
  /// and primary pet ID. Returns true if successful, false otherwise.
  Future<bool> markOnboardingComplete(String primaryPetId) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return false;

    try {
      // Update user data in Firestore
      await _updateUserDataInFirestore(
        currentUser.id,
        hasCompletedOnboarding: true,
        primaryPetId: primaryPetId,
      );

      // Update local state
      final updatedUser = currentUser.copyWith(
        hasCompletedOnboarding: true,
        primaryPetId: primaryPetId,
      );
      state = AuthStateAuthenticated(user: updatedUser);

      return true;
    } on Exception {
      return false;
    }
  }

  /// Mark onboarding as skipped for the current user
  ///
  /// Updates both local state and Firestore with onboarding skip status.
  /// Returns true if successful, false otherwise.
  Future<bool> markOnboardingSkipped() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return false;

    try {
      // Update user data in Firestore
      await _updateUserDataInFirestore(
        currentUser.id,
        hasSkippedOnboarding: true,
      );

      // Update local state
      final updatedUser = currentUser.copyWith(
        hasSkippedOnboarding: true,
      );
      state = AuthStateAuthenticated(user: updatedUser);

      return true;
    } on Exception {
      return false;
    }
  }

  /// Update onboarding status for the current user
  ///
  /// More flexible method for updating onboarding state and pet ID.
  /// Returns true if successful, false otherwise.
  Future<bool> updateOnboardingStatus({
    bool? hasCompletedOnboarding,
    bool? hasSkippedOnboarding,
    String? primaryPetId,
  }) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return false;

    try {
      // Update user data in Firestore
      await _updateUserDataInFirestore(
        currentUser.id,
        hasCompletedOnboarding: hasCompletedOnboarding,
        hasSkippedOnboarding: hasSkippedOnboarding,
        primaryPetId: primaryPetId,
      );

      // Update local state
      final updatedUser = currentUser.copyWith(
        hasCompletedOnboarding: hasCompletedOnboarding,
        hasSkippedOnboarding: hasSkippedOnboarding,
        primaryPetId: primaryPetId,
      );
      state = AuthStateAuthenticated(user: updatedUser);

      return true;
    } on Exception {
      return false;
    }
  }

  /// Update user data in Firestore
  ///
  /// Private helper method to persist user data changes to Firestore.
  Future<void> _updateUserDataInFirestore(
    String userId, {
    bool? hasCompletedOnboarding,
    bool? hasSkippedOnboarding,
    String? primaryPetId,
  }) async {
    final userDoc = _firestore.collection('users').doc(userId);
    
    final updateData = <String, dynamic>{};
    if (hasCompletedOnboarding != null) {
      updateData['hasCompletedOnboarding'] = hasCompletedOnboarding;
    }
    if (hasSkippedOnboarding != null) {
      updateData['hasSkippedOnboarding'] = hasSkippedOnboarding;
    }
    if (primaryPetId != null) {
      updateData['primaryPetId'] = primaryPetId;
    }
    
    if (updateData.isNotEmpty) {
      updateData['updatedAt'] = FieldValue.serverTimestamp();
      await userDoc.set(updateData, SetOptions(merge: true));
    }
  }

  /// Get current user with latest state
  ///
  /// Helper method to get the current user from the auth state.
  AppUser? getCurrentUser() {
    return state.user;
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
  return ref.watch(authProvider.select((state) => 
    state is AuthStateError ? state : null));
});

/// Optimized provider to check if user has completed onboarding
///
/// Returns true if user has completed onboarding, false otherwise.
/// Only rebuilds when onboarding completion status changes.
final hasCompletedOnboardingProvider = Provider<bool>((ref) {
  return ref.watch(authProvider.select((state) => 
    state.user?.hasCompletedOnboarding ?? false));
});

/// Optimized provider to check if user has skipped onboarding
///
/// Returns true if user has deliberately skipped onboarding, false otherwise.
/// Only rebuilds when onboarding skip status changes.
final hasSkippedOnboardingProvider = Provider<bool>((ref) {
  return ref.watch(authProvider.select((state) => 
    state.user?.hasSkippedOnboarding ?? false));
});

/// Optimized provider to get user's primary pet ID
///
/// Returns the primary pet ID if set, null otherwise.
/// Only rebuilds when primary pet ID changes.
final primaryPetIdProvider = Provider<String?>((ref) {
  return ref.watch(authProvider.select((state) => 
    state.user?.primaryPetId));
});
