import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/features/auth/models/app_user.dart';
import 'package:hydracat/features/auth/models/auth_state.dart';
import 'package:hydracat/features/auth/services/auth_service.dart';

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

      // Clear error flag after allowing UI to process the error
      Future.delayed(const Duration(seconds: 3), () {
        _hasRecentError = false;
      });
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
  /// Refreshes the current user's data and checks verification status.
  /// Returns true if email is verified, false otherwise.
  Future<bool> checkEmailVerification() async {
    return _authService.checkEmailVerification();
  }

  /// Sign in with Google
  ///
  /// Initiates Google Sign-In flow and authenticates with Firebase.
  /// Updates the state to show loading, success, or error states.
  Future<void> signInWithGoogle() async {
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
