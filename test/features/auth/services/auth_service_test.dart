import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/features/auth/exceptions/auth_exceptions.dart';
import 'package:hydracat/features/auth/models/app_user.dart';
import 'package:hydracat/features/auth/services/auth_service.dart';
import 'package:hydracat/shared/models/login_attempt_data.dart';
import 'package:hydracat/shared/services/firebase_service.dart';
import 'package:hydracat/shared/services/login_attempt_service.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockFirebaseService extends Mock implements FirebaseService {}

class MockUser extends Mock implements User {}

class MockUserCredential extends Mock implements UserCredential {}

class MockLoginAttemptService extends Mock implements LoginAttemptService {}

void main() {
  group('AuthService', () {
    late MockFirebaseAuth mockFirebaseAuth;
    late MockFirebaseService mockFirebaseService;
    late MockLoginAttemptService mockLoginAttemptService;
    late AuthService authService;

    setUp(() {
      mockFirebaseAuth = MockFirebaseAuth();
      mockFirebaseService = MockFirebaseService();
      mockLoginAttemptService = MockLoginAttemptService();

      // Setup FirebaseService mock
      when(() => mockFirebaseService.auth).thenReturn(mockFirebaseAuth);

      // Mock auth state stream
      when(
        () => mockFirebaseAuth.authStateChanges(),
      ).thenAnswer((_) => Stream.value(null));

      // Mock login attempt service defaults
      when(
        () => mockLoginAttemptService.isAccountLockedOut(any()),
      ).thenAnswer((_) async => false);
      when(
        () => mockLoginAttemptService.recordSuccessfulLogin(any()),
      ).thenAnswer((_) async {});
      when(
        () => mockLoginAttemptService.recordFailedAttempt(any()),
      ).thenAnswer(
        (_) async => const LoginAttemptData(
          email: 'test@example.com',
          failedAttempts: 1,
        ),
      );

      authService = AuthService(loginAttemptService: mockLoginAttemptService);
    });

    group('Email/Password Authentication', () {
      test('should sign up with valid email and password', () async {
        // Arrange
        final mockUser = MockUser();
        final mockCredential = MockUserCredential();

        when(() => mockUser.uid).thenReturn('test-uid');
        when(() => mockUser.email).thenReturn('test@example.com');
        when(() => mockUser.emailVerified).thenReturn(false);
        when(() => mockCredential.user).thenReturn(mockUser);

        when(
          () => mockFirebaseAuth.createUserWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => mockCredential);

        // Act
        final result = await authService.signUp(
          email: 'test@example.com',
          password: 'password123',
        );

        // Assert
        expect(result, isA<AuthSuccess>());
        final success = result as AuthSuccess;
        expect(success.user?.email, equals('test@example.com'));

        verify(
          () => mockFirebaseAuth.createUserWithEmailAndPassword(
            email: 'test@example.com',
            password: 'password123',
          ),
        ).called(1);
      });

      test('should throw WeakPasswordException on weak password', () async {
        // Arrange
        when(
          () => mockFirebaseAuth.createUserWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(FirebaseAuthException(code: 'weak-password'));

        // Act
        final result = await authService.signUp(
          email: 'test@example.com',
          password: '123',
        );

        // Assert
        expect(result, isA<AuthFailure>());
        final failure = result as AuthFailure;
        expect(failure.exception, isA<WeakPasswordException>());
      });

      test('should sign in with valid email and password', () async {
        // Arrange
        final mockUser = MockUser();
        final mockCredential = MockUserCredential();

        when(() => mockUser.uid).thenReturn('test-uid');
        when(() => mockUser.email).thenReturn('test@example.com');
        when(() => mockUser.emailVerified).thenReturn(true);
        when(() => mockCredential.user).thenReturn(mockUser);

        when(
          () => mockFirebaseAuth.signInWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => mockCredential);

        // Act
        final result = await authService.signIn(
          email: 'test@example.com',
          password: 'password123',
        );

        // Assert
        expect(result, isA<AuthSuccess>());
        final success = result as AuthSuccess;
        expect(success.user?.email, equals('test@example.com'));

        verify(
          () => mockLoginAttemptService.recordSuccessfulLogin(
            'test@example.com',
          ),
        ).called(1);
      });

      test('should record failed attempt on invalid credentials', () async {
        // Arrange
        when(
          () => mockFirebaseAuth.signInWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(FirebaseAuthException(code: 'invalid-credential'));

        // Act
        final result = await authService.signIn(
          email: 'test@example.com',
          password: 'wrongpassword',
        );

        // Assert
        expect(result, isA<AuthFailure>());
        verify(
          () => mockLoginAttemptService.recordFailedAttempt(
            'test@example.com',
          ),
        ).called(1);
      });

      test('should handle account lockout', () async {
        // Arrange
        when(
          () => mockLoginAttemptService.isAccountLockedOut(
            'test@example.com',
          ),
        ).thenAnswer((_) async => true);
        when(
          () => mockLoginAttemptService.getTimeUntilUnlock(
            'test@example.com',
          ),
        ).thenAnswer((_) async => const Duration(minutes: 5));

        // Act
        final result = await authService.signIn(
          email: 'test@example.com',
          password: 'password123',
        );

        // Assert
        expect(result, isA<AuthFailure>());
        final failure = result as AuthFailure;
        expect(failure.exception, isA<AccountTemporarilyLockedException>());

        // Should not call Firebase Auth when locked out
        verifyNever(
          () => mockFirebaseAuth.signInWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        );
      });
    });

    group('Email Verification', () {
      test('should send verification email successfully', () async {
        // Arrange
        final mockUser = MockUser();
        when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);
        when(() => mockUser.emailVerified).thenReturn(false);
        when(mockUser.sendEmailVerification).thenAnswer((_) async {});

        // Act
        final result = await authService.sendEmailVerification();

        // Assert
        expect(result, isA<AuthSuccess>());
        verify(mockUser.sendEmailVerification).called(1);
      });

      test('should fail when no user is signed in', () async {
        // Arrange
        when(() => mockFirebaseAuth.currentUser).thenReturn(null);

        // Act
        final result = await authService.sendEmailVerification();

        // Assert
        expect(result, isA<AuthFailure>());
        final failure = result as AuthFailure;
        expect(failure.exception, isA<EmailVerificationException>());
      });

      test('should check email verification status', () async {
        // Arrange
        final mockUser = MockUser();
        when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);
        when(mockUser.reload).thenAnswer((_) async {});
        when(() => mockUser.emailVerified).thenReturn(true);

        // Act
        final result = await authService.checkEmailVerification();

        // Assert
        expect(result, equals(true));
        verify(mockUser.reload).called(1);
      });

      test('should handle offline verification check gracefully', () async {
        // Arrange
        final mockUser = MockUser();
        when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);
        when(mockUser.reload).thenThrow(Exception('Network error'));
        when(() => mockUser.emailVerified).thenReturn(false);

        // Act
        final result = await authService.checkEmailVerification();

        // Assert
        expect(result, equals(false)); // Returns cached status
      });
    });

    group('Password Recovery', () {
      test('should send password reset email', () async {
        // Arrange
        when(
          () => mockFirebaseAuth.sendPasswordResetEmail(
            email: any(named: 'email'),
          ),
        ).thenAnswer((_) async {});

        // Act
        final result = await authService.sendPasswordResetEmail(
          'test@example.com',
        );

        // Assert
        expect(result, isA<AuthSuccess>());
        verify(
          () => mockFirebaseAuth.sendPasswordResetEmail(
            email: 'test@example.com',
          ),
        ).called(1);
      });

      test('should handle invalid email for password reset', () async {
        // Arrange
        when(
          () => mockFirebaseAuth.sendPasswordResetEmail(
            email: any(named: 'email'),
          ),
        ).thenThrow(FirebaseAuthException(code: 'user-not-found'));

        // Act
        final result = await authService.sendPasswordResetEmail(
          'invalid@example.com',
        );

        // Assert
        expect(result, isA<AuthFailure>());
        final failure = result as AuthFailure;
        expect(failure.exception, isA<UserNotFoundException>());
      });
    });

    group('Error Handling', () {
      test('should map Firebase exceptions to app exceptions', () async {
        // Arrange
        when(
          () => mockFirebaseAuth.signInWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(FirebaseAuthException(code: 'user-not-found'));

        // Act
        final result = await authService.signIn(
          email: 'test@example.com',
          password: 'password123',
        );

        // Assert
        expect(result, isA<AuthFailure>());
        final failure = result as AuthFailure;
        expect(failure.exception, isA<UserNotFoundException>());
      });

      test('should handle network errors gracefully', () async {
        // Arrange
        when(
          () => mockFirebaseAuth.signInWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(FirebaseAuthException(code: 'network-request-failed'));

        // Act
        final result = await authService.signIn(
          email: 'test@example.com',
          password: 'password123',
        );

        // Assert
        expect(result, isA<AuthFailure>());

        // Should not record failed attempt for network errors
        verifyNever(() => mockLoginAttemptService.recordFailedAttempt(any()));
      });

      test('should maintain auth state during offline periods', () async {
        // Arrange
        final mockUser = MockUser();
        when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);
        when(() => mockUser.uid).thenReturn('test-uid');
        when(() => mockUser.email).thenReturn('test@example.com');
        when(() => mockUser.emailVerified).thenReturn(true);

        // Act
        final user = authService.currentUser;
        final hasUser = authService.hasAuthenticatedUser;

        // Assert
        expect(user, isA<AppUser>());
        expect(hasUser, equals(true));
        expect(user?.email, equals('test@example.com'));
      });
    });

    group('Sign Out', () {
      test('should sign out successfully', () async {
        // Arrange
        when(() => mockFirebaseAuth.signOut()).thenAnswer((_) async {});

        // Act
        final result = await authService.signOut();

        // Assert
        expect(result, equals(true));
        verify(() => mockFirebaseAuth.signOut()).called(1);
      });

      test('should handle sign out errors gracefully', () async {
        // Arrange
        when(
          () => mockFirebaseAuth.signOut(),
        ).thenThrow(Exception('Sign out failed'));

        // Act
        final result = await authService.signOut();

        // Assert
        expect(result, equals(false));
      });
    });

    group('Auth State Management', () {
      test('should provide auth state changes stream', () {
        // Arrange
        final mockUser = MockUser();
        when(() => mockUser.uid).thenReturn('test-uid');
        when(() => mockUser.email).thenReturn('test@example.com');
        when(() => mockUser.emailVerified).thenReturn(true);

        when(
          () => mockFirebaseAuth.authStateChanges(),
        ).thenAnswer((_) => Stream.fromIterable([mockUser, null]));

        // Act
        final stream = authService.authStateChanges;

        // Assert
        expect(stream, isA<Stream<AppUser?>>());

        stream.listen((user) {
          if (user != null) {
            expect(user.email, equals('test@example.com'));
          }
        });
      });
    });
  });
}
