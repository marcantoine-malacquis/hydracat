import 'package:firebase_auth/firebase_auth.dart';
import 'package:hydracat/features/auth/models/app_user.dart';
import 'package:hydracat/shared/services/firebase_service.dart';

/// Result type for authentication operations
sealed class AuthResult {
  /// Creates an [AuthResult] instance
  const AuthResult();
}

/// Successful authentication result
class AuthSuccess extends AuthResult {
  /// Creates an [AuthSuccess] with the authenticated user
  const AuthSuccess(this.user);

  /// The authenticated user
  final AppUser user;
}

/// Failed authentication result
class AuthFailure extends AuthResult {
  /// Creates an [AuthFailure] with error message and optional code
  const AuthFailure(this.message, [this.code]);

  /// The error message
  final String message;

  /// Optional error code from Firebase
  final String? code;
}

/// Minimal Firebase Authentication service
///
/// Handles basic email/password authentication operations with simple
/// error handling and clear success/failure responses.
class AuthService {
  /// Creates an [AuthService] instance
  AuthService();

  FirebaseAuth get _firebaseAuth => FirebaseService().auth;

  /// Current authenticated user, if any
  AppUser? get currentUser {
    final firebaseUser = _firebaseAuth.currentUser;
    return firebaseUser != null ? AppUser.fromFirebaseUser(firebaseUser) : null;
  }

  /// Stream of authentication state changes
  Stream<AppUser?> get authStateChanges {
    return _firebaseAuth.authStateChanges().map((firebaseUser) {
      return firebaseUser != null
          ? AppUser.fromFirebaseUser(firebaseUser)
          : null;
    });
  }

  /// Sign up with email and password
  ///
  /// Creates a new user account and automatically sends email verification.
  /// Returns [AuthSuccess] with user data or [AuthFailure] with error message.
  Future<AuthResult> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        return const AuthFailure('Account creation failed');
      }

      // Send email verification automatically
      await firebaseUser.sendEmailVerification();

      final user = AppUser.fromFirebaseUser(firebaseUser);
      return AuthSuccess(user);
    } on FirebaseAuthException catch (e) {
      return AuthFailure(_getErrorMessage(e), e.code);
    } on Exception catch (e) {
      return AuthFailure('An unexpected error occurred: $e');
    }
  }

  /// Sign in with email and password
  ///
  /// Authenticates existing user with email and password.
  /// Returns [AuthSuccess] with user data or [AuthFailure] with error message.
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        return const AuthFailure('Sign in failed');
      }

      final user = AppUser.fromFirebaseUser(firebaseUser);
      return AuthSuccess(user);
    } on FirebaseAuthException catch (e) {
      return AuthFailure(_getErrorMessage(e), e.code);
    } on Exception catch (e) {
      return AuthFailure('An unexpected error occurred: $e');
    }
  }

  /// Sign out current user
  ///
  /// Signs out the currently authenticated user.
  /// Returns true if successful, false if there was an error.
  Future<bool> signOut() async {
    try {
      await _firebaseAuth.signOut();
      return true;
    } on Exception {
      return false;
    }
  }

  /// Send password reset email
  ///
  /// Sends a password reset email to the specified email address.
  /// Returns true if successful, false if there was an error.
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
      return true;
    } on Exception {
      return false;
    }
  }

  /// Convert Firebase Auth errors to user-friendly messages
  String _getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-not-found':
        return 'No account found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection and try again.';
      default:
        return e.message ?? 'An authentication error occurred.';
    }
  }
}
