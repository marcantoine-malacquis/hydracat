import 'package:firebase_auth/firebase_auth.dart';
import 'package:hydracat/features/auth/exceptions/auth_exceptions.dart';
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

  /// The authenticated user (null for operations like password reset)
  final AppUser? user;
}

/// Failed authentication result
class AuthFailure extends AuthResult {
  /// Creates an [AuthFailure] with an authentication exception
  const AuthFailure(this.exception);

  /// The authentication exception with user-friendly message
  final AuthException exception;

  /// Convenience getter for error message
  String get message => exception.message;

  /// Convenience getter for error code
  String? get code => exception.code;
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
  /// Creates a new user account without automatically sending email
  /// verification.
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
        return const AuthFailure(AccountCreationException());
      }

      final user = AppUser.fromFirebaseUser(firebaseUser);
      return AuthSuccess(user);
    } on FirebaseAuthException catch (e) {
      return AuthFailure(AuthExceptionMapper.mapFirebaseException(e));
    } on Exception catch (e) {
      return AuthFailure(AuthExceptionMapper.mapGenericException(e));
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
        return const AuthFailure(SignInException());
      }

      final user = AppUser.fromFirebaseUser(firebaseUser);
      return AuthSuccess(user);
    } on FirebaseAuthException catch (e) {
      return AuthFailure(AuthExceptionMapper.mapFirebaseException(e));
    } on Exception catch (e) {
      return AuthFailure(AuthExceptionMapper.mapGenericException(e));
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
  /// Returns [AuthResult] with success or failure details.
  Future<AuthResult> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
      return const AuthSuccess(null);
    } on FirebaseAuthException catch (e) {
      return AuthFailure(AuthExceptionMapper.mapFirebaseException(e));
    } on Exception catch (e) {
      return AuthFailure(AuthExceptionMapper.mapGenericException(e));
    }
  }

  /// Send email verification to current user
  ///
  /// Sends an email verification link to the currently authenticated user.
  /// Returns [AuthResult] with success or failure details.
  Future<AuthResult> sendEmailVerification() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        return const AuthSuccess(null);
      }
      return const AuthFailure(EmailVerificationException());
    } on FirebaseAuthException catch (e) {
      return AuthFailure(AuthExceptionMapper.mapFirebaseException(e));
    } on Exception catch (e) {
      return AuthFailure(AuthExceptionMapper.mapGenericException(e));
    }
  }

  /// Check if current user's email is verified
  ///
  /// Refreshes the current user's data and checks verification status.
  /// Returns true if email is verified, false otherwise.
  Future<bool> checkEmailVerification() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        await user.reload();
        final refreshedUser = _firebaseAuth.currentUser;
        return refreshedUser?.emailVerified ?? false;
      }
      return false;
    } on Exception {
      return false;
    }
  }

}
