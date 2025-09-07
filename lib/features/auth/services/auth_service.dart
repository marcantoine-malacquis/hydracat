import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hydracat/features/auth/exceptions/auth_exceptions.dart';
import 'package:hydracat/features/auth/models/app_user.dart';
import 'package:hydracat/shared/services/firebase_service.dart';
import 'package:hydracat/shared/services/login_attempt_service.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

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
/// Handles email/password and social authentication operations with simple
/// error handling and clear success/failure responses.
class AuthService {
  /// Creates an [AuthService] instance
  AuthService({LoginAttemptService? loginAttemptService}) {
    _loginAttemptService = loginAttemptService ?? LoginAttemptService();
    _initializeAuthState();
  }

  FirebaseAuth get _firebaseAuth => FirebaseService().auth;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  late final LoginAttemptService _loginAttemptService;

  bool _isInitialized = false;

  /// Initialize auth state and wait for Firebase to determine initial state
  void _initializeAuthState() {
    // Firebase Auth automatically determines initial state from persistence
    // This ensures we know if a user is logged in from a previous session
    _firebaseAuth.authStateChanges().first.then((_) {
      _isInitialized = true;
    });
  }

  /// Whether the auth service has determined the initial authentication state
  bool get isInitialized => _isInitialized;

  /// Whether there is a current authenticated user (cached, no network needed)
  bool get hasAuthenticatedUser => _firebaseAuth.currentUser != null;

  /// Wait for the auth service to determine initial authentication state
  ///
  /// This method completes when Firebase Auth has determined whether
  /// there is a persisted user session from a previous app launch.
  Future<void> waitForInitialization() async {
    if (_isInitialized) return;

    // Wait for the first auth state change which indicates initialization
    await _firebaseAuth.authStateChanges().first;
    _isInitialized = true;
  }

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
  /// Authenticates existing user with email and password with brute force
  /// protection. Returns [AuthSuccess] with user data or [AuthFailure] with
  /// error message.
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    final trimmedEmail = email.trim();

    try {
      // Check if account is locked out
      final isLockedOut = await _loginAttemptService.isAccountLockedOut(
        trimmedEmail,
      );
      if (isLockedOut) {
        final timeUntilUnlock = await _loginAttemptService.getTimeUntilUnlock(
          trimmedEmail,
        );
        return AuthFailure(
          AccountTemporarilyLockedException(
            timeRemaining: timeUntilUnlock ?? Duration.zero,
          ),
        );
      }

      // Attempt authentication with Firebase
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: trimmedEmail,
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        return const AuthFailure(SignInException());
      }

      // Success - clear any failed attempts
      await _loginAttemptService.recordSuccessfulLogin(trimmedEmail);

      final user = AppUser.fromFirebaseUser(firebaseUser);
      return AuthSuccess(user);
    } on FirebaseAuthException catch (e) {
      // Record failed attempt for authentication errors (wrong password, etc.)
      if (_shouldRecordFailedAttempt(e)) {
        await _recordFailedAttemptWithWarning(trimmedEmail, e);

        // After recording, check if this attempt triggered a lockout
        final nowLockedOut = await _loginAttemptService.isAccountLockedOut(
          trimmedEmail,
        );
        if (nowLockedOut) {
          final timeUntilUnlock = await _loginAttemptService.getTimeUntilUnlock(
            trimmedEmail,
          );
          // Return a lockout-specific failure so the UI can show the dialog
          return AuthFailure(
            AccountTemporarilyLockedException(
              timeRemaining: timeUntilUnlock ?? Duration.zero,
            ),
          );
        }
      } else {}
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
  ///
  /// This method gracefully handles offline scenarios by returning
  /// the cached verification status when network is unavailable.
  Future<bool> checkEmailVerification() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        try {
          // Attempt to reload user data (requires network)
          await user.reload();
          final refreshedUser = _firebaseAuth.currentUser;
          return refreshedUser?.emailVerified ?? false;
        } on Exception {
          // If reload fails (likely offline), return cached status
          return user.emailVerified;
        }
      }
      return false;
    } on Exception {
      return false;
    }
  }

  /// Sign in with Google
  ///
  /// Initiates Google Sign-In flow and authenticates with Firebase.
  /// Returns [AuthSuccess] with user data or [AuthFailure] with error message.
  Future<AuthResult> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final googleUser = await _googleSignIn.signIn();

      // If user cancels the sign-in process
      if (googleUser == null) {
        return const AuthFailure(
          SocialSignInException('Sign-in was cancelled'),
        );
      }

      // Obtain the auth details from the request
      final googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        return const AuthFailure(
          SocialSignInException('Failed to sign in with Google'),
        );
      }

      final user = AppUser.fromFirebaseUser(firebaseUser);
      return AuthSuccess(user);
    } on FirebaseAuthException catch (e) {
      return AuthFailure(AuthExceptionMapper.mapFirebaseException(e));
    } on Exception catch (e) {
      return AuthFailure(AuthExceptionMapper.mapGenericException(e));
    }
  }

  /// Sign in with Apple
  ///
  /// Initiates Apple Sign-In flow and authenticates with Firebase.
  /// Returns [AuthSuccess] with user data or [AuthFailure] with error message.
  Future<AuthResult> signInWithApple() async {
    try {
      // Check if Apple Sign-In is available
      final isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable) {
        return const AuthFailure(
          SocialSignInException('Apple Sign-In is not available'),
        );
      }

      // Request Apple ID credential
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // Create OAuth credential for Firebase
      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      // Sign in to Firebase with Apple credential
      final userCredential = await _firebaseAuth.signInWithCredential(
        oauthCredential,
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        return const AuthFailure(
          SocialSignInException('Failed to sign in with Apple'),
        );
      }

      final user = AppUser.fromFirebaseUser(firebaseUser);
      return AuthSuccess(user);
    } on SignInWithAppleException {
      return const AuthFailure(
        SocialSignInException('Apple Sign-In failed'),
      );
    } on FirebaseAuthException catch (e) {
      return AuthFailure(AuthExceptionMapper.mapFirebaseException(e));
    } on Exception catch (e) {
      return AuthFailure(AuthExceptionMapper.mapGenericException(e));
    }
  }

  /// Determines if a Firebase Auth exception should count as a failed attempt
  bool _shouldRecordFailedAttempt(FirebaseAuthException e) {
    // Record attempts for authentication failures, but not for network issues
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-email':
      case 'invalid-credential': // New in Firebase Auth v6+
      case 'user-disabled':
        return true;
      case 'network-request-failed':
      case 'too-many-requests':
        return false;
      default:
        return false;
    }
  }

  /// Records a failed attempt and returns appropriate warning exception
  Future<void> _recordFailedAttemptWithWarning(
    String email,
    FirebaseAuthException originalException,
  ) async {
    await _loginAttemptService.recordFailedAttempt(email);

    // If this attempt resulted in a lockout, the next login attempt will
    // be blocked by the lockout check at the start of signIn()

    // We don't modify the original exception here to maintain consistency
    // The UI can separately check for warning messages if needed
  }

  /// Gets a warning message for the user based on failed attempt count
  ///
  /// Returns null if no warning is needed.
  Future<String?> getLoginWarningMessage(String email) async {
    return _loginAttemptService.getWarningMessage(email.trim());
  }

  /// Gets the number of failed attempts for the given email
  ///
  /// Returns 0 if no attempts are recorded.
  Future<int> getFailedAttemptCount(String email) async {
    return _loginAttemptService.getFailedAttemptCount(email.trim());
  }
}
