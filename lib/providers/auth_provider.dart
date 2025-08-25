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
    _listenToAuthChanges();
  }

  final AuthService _authService;

  /// Listen to Firebase auth state changes and update the state accordingly
  void _listenToAuthChanges() {
    _authService.authStateChanges.listen((user) {
      if (user != null) {
        state = AuthStateAuthenticated(user: user);
      } else {
        state = const AuthStateUnauthenticated();
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
      state = AuthStateError(
        message: result.message,
        code: result.code,
      );
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
    return _authService.sendPasswordResetEmail(email);
  }

  /// Clear error state
  /// 
  /// Resets the error state back to the appropriate auth state
  /// (authenticated or unauthenticated based on current user).
  void clearError() {
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

/// Convenience provider to get the current authenticated user
/// 
/// Returns the current user if authenticated, null otherwise.
/// This is useful for widgets that only need to know about the current user
/// without caring about loading or error states.
final currentUserProvider = Provider<AppUser?>((ref) {
  final authState = ref.watch(authProvider);
  return authState.user;
});

/// Convenience provider to check if user is authenticated
/// 
/// Returns true if user is currently authenticated, false otherwise.
/// This is useful for conditional UI rendering and navigation guards.
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);
  return authState.isAuthenticated;
});
