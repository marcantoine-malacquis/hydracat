import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/features/auth/exceptions/auth_exceptions.dart';
import 'package:hydracat/features/auth/models/app_user.dart';
import 'package:hydracat/features/auth/models/auth_state.dart';
import 'package:hydracat/features/auth/services/auth_service.dart';
import 'package:hydracat/providers/auth_provider.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthService extends Mock implements AuthService {}

/// Simple mock notifier for testing specific auth behaviors
class SimpleAuthNotifier extends AuthNotifier {
  SimpleAuthNotifier(this._authService, AuthState initialState)
    : super(_authService) {
    // Override the initial state after construction
    state = initialState;
  }

  final AuthService _authService;

  @override
  Future<void> signUp({required String email, required String password}) async {
    state = const AuthStateLoading();
    final result = await _authService.signUp(email: email, password: password);
    if (result is AuthSuccess) {
      state = AuthStateAuthenticated(user: result.user!);
    } else if (result is AuthFailure) {
      state = AuthStateError(
        message: result.message,
        code: result.code,
        details: result.exception,
      );
    }
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    state = const AuthStateLoading();
    final result = await _authService.signIn(email: email, password: password);
    if (result is AuthSuccess) {
      state = AuthStateAuthenticated(user: result.user!);
    } else if (result is AuthFailure) {
      state = AuthStateError(
        message: result.message,
        code: result.code,
        details: result.exception,
      );
    }
  }

  @override
  Future<void> signOut() async {
    state = const AuthStateLoading();
    final success = await _authService.signOut();
    if (!success) {
      state = const AuthStateError(
        message: 'Failed to sign out. Please try again.',
      );
    } else {
      state = const AuthStateUnauthenticated();
    }
  }

  @override
  Future<bool> sendPasswordResetEmail(String email) async {
    final result = await _authService.sendPasswordResetEmail(email);
    return result is AuthSuccess;
  }

  @override
  Future<bool> sendEmailVerification() async {
    final result = await _authService.sendEmailVerification();
    return result is AuthSuccess;
  }

  @override
  Future<void> signInWithGoogle() async {
    state = const AuthStateLoading();
    final result = await _authService.signInWithGoogle();
    if (result is AuthSuccess) {
      state = AuthStateAuthenticated(user: result.user!);
    } else if (result is AuthFailure) {
      state = AuthStateError(
        message: result.message,
        code: result.code,
        details: result.exception,
      );
    }
  }
}

void main() {
  group('AuthProvider', () {
    late MockAuthService mockAuthService;

    setUp(() {
      mockAuthService = MockAuthService();

      // Default mocks
      when(
        () => mockAuthService.waitForInitialization(),
      ).thenAnswer((_) async {});
      when(
        () => mockAuthService.authStateChanges,
      ).thenAnswer((_) => const Stream.empty());
      when(() => mockAuthService.currentUser).thenReturn(null);
    });

    group('AuthNotifier Basic Functionality', () {
      test('should handle sign up successfully', () async {
        // Arrange
        const testUser = AppUser(id: 'new-user-uid', email: 'new@example.com');

        when(
          () => mockAuthService.signUp(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => const AuthSuccess(testUser));

        final container = ProviderContainer(
          overrides: [
            authProvider.overrideWith(
              (ref) => SimpleAuthNotifier(
                mockAuthService,
                const AuthStateLoading(),
              ),
            ),
          ],
        );

        // Act
        final notifier = container.read(authProvider.notifier);
        await notifier.signUp(
          email: 'new@example.com',
          password: 'password123',
        );

        // Assert
        final state = container.read(authProvider);
        expect(state, isA<AuthStateAuthenticated>());
        if (state is AuthStateAuthenticated) {
          expect(state.user.email, equals('new@example.com'));
        }

        container.dispose();
      });

      test('should handle sign up failure', () async {
        // Arrange
        const exception = WeakPasswordException();
        when(
          () => mockAuthService.signUp(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => const AuthFailure(exception));

        final container = ProviderContainer(
          overrides: [
            authProvider.overrideWith(
              (ref) => SimpleAuthNotifier(
                mockAuthService,
                const AuthStateLoading(),
              ),
            ),
          ],
        );

        // Act
        final notifier = container.read(authProvider.notifier);
        await notifier.signUp(email: 'test@example.com', password: 'weak');

        // Assert
        final state = container.read(authProvider);
        expect(state, isA<AuthStateError>());
        if (state is AuthStateError) {
          expect(state.message, contains('stronger password'));
        }

        container.dispose();
      });

      test('should handle sign in successfully', () async {
        // Arrange
        const testUser = AppUser(
          id: 'existing-user-uid',
          email: 'existing@example.com',
        );

        when(
          () => mockAuthService.signIn(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => const AuthSuccess(testUser));

        final container = ProviderContainer(
          overrides: [
            authProvider.overrideWith(
              (ref) => SimpleAuthNotifier(
                mockAuthService,
                const AuthStateLoading(),
              ),
            ),
          ],
        );

        // Act
        final notifier = container.read(authProvider.notifier);
        await notifier.signIn(
          email: 'existing@example.com',
          password: 'password123',
        );

        // Assert
        final state = container.read(authProvider);
        expect(state, isA<AuthStateAuthenticated>());
        if (state is AuthStateAuthenticated) {
          expect(state.user.email, equals('existing@example.com'));
        }

        container.dispose();
      });

      test('should handle sign in failure', () async {
        // Arrange
        const exception = WrongPasswordException();
        when(
          () => mockAuthService.signIn(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => const AuthFailure(exception));

        final container = ProviderContainer(
          overrides: [
            authProvider.overrideWith(
              (ref) => SimpleAuthNotifier(
                mockAuthService,
                const AuthStateLoading(),
              ),
            ),
          ],
        );

        // Act
        final notifier = container.read(authProvider.notifier);
        await notifier.signIn(
          email: 'test@example.com',
          password: 'wrongpassword',
        );

        // Assert
        final state = container.read(authProvider);
        expect(state, isA<AuthStateError>());
        if (state is AuthStateError) {
          expect(
            state.message,
            contains("Password doesn't match. Please try again"),
          );
        }

        container.dispose();
      });

      test('should handle Google sign in successfully', () async {
        // Arrange
        const testUser = AppUser(
          id: 'google-user-uid',
          email: 'google@example.com',
          provider: AuthProvider.google,
        );

        when(
          () => mockAuthService.signInWithGoogle(),
        ).thenAnswer((_) async => const AuthSuccess(testUser));

        final container = ProviderContainer(
          overrides: [
            authProvider.overrideWith(
              (ref) => SimpleAuthNotifier(
                mockAuthService,
                const AuthStateLoading(),
              ),
            ),
          ],
        );

        // Act
        final notifier = container.read(authProvider.notifier);
        await notifier.signInWithGoogle();

        // Assert
        final state = container.read(authProvider);
        expect(state, isA<AuthStateAuthenticated>());
        if (state is AuthStateAuthenticated) {
          expect(state.user.email, equals('google@example.com'));
        }

        container.dispose();
      });

      test('should handle sign out successfully', () async {
        // Arrange
        when(() => mockAuthService.signOut()).thenAnswer((_) async => true);

        final container = ProviderContainer(
          overrides: [
            authProvider.overrideWith(
              (ref) => SimpleAuthNotifier(
                mockAuthService,
                const AuthStateAuthenticated(
                  user: AppUser(id: 'test', email: 'test@example.com'),
                ),
              ),
            ),
          ],
        );

        // Act
        final notifier = container.read(authProvider.notifier);
        await notifier.signOut();

        // Assert
        final state = container.read(authProvider);
        expect(state, isA<AuthStateUnauthenticated>());

        container.dispose();
      });

      test('should handle sign out failure', () async {
        // Arrange
        when(() => mockAuthService.signOut()).thenAnswer((_) async => false);

        final container = ProviderContainer(
          overrides: [
            authProvider.overrideWith(
              (ref) => SimpleAuthNotifier(
                mockAuthService,
                const AuthStateAuthenticated(
                  user: AppUser(id: 'test', email: 'test@example.com'),
                ),
              ),
            ),
          ],
        );

        // Act
        final notifier = container.read(authProvider.notifier);
        await notifier.signOut();

        // Assert
        final state = container.read(authProvider);
        expect(state, isA<AuthStateError>());

        container.dispose();
      });

      test('should send email verification successfully', () async {
        // Arrange
        when(
          () => mockAuthService.sendEmailVerification(),
        ).thenAnswer((_) async => const AuthSuccess(null));

        final container = ProviderContainer(
          overrides: [
            authProvider.overrideWith(
              (ref) => SimpleAuthNotifier(
                mockAuthService,
                const AuthStateAuthenticated(
                  user: AppUser(id: 'test', email: 'test@example.com'),
                ),
              ),
            ),
          ],
        );

        // Act
        final notifier = container.read(authProvider.notifier);
        final result = await notifier.sendEmailVerification();

        // Assert
        expect(result, equals(true));

        container.dispose();
      });

      test('should handle email verification failure', () async {
        // Arrange
        const exception = EmailVerificationException();
        when(
          () => mockAuthService.sendEmailVerification(),
        ).thenAnswer((_) async => const AuthFailure(exception));

        final container = ProviderContainer(
          overrides: [
            authProvider.overrideWith(
              (ref) => SimpleAuthNotifier(
                mockAuthService,
                const AuthStateAuthenticated(
                  user: AppUser(id: 'test', email: 'test@example.com'),
                ),
              ),
            ),
          ],
        );

        // Act
        final notifier = container.read(authProvider.notifier);
        final result = await notifier.sendEmailVerification();

        // Assert
        expect(result, equals(false));

        container.dispose();
      });

      test('should send password reset email successfully', () async {
        // Arrange
        when(
          () => mockAuthService.sendPasswordResetEmail(any()),
        ).thenAnswer((_) async => const AuthSuccess(null));

        final container = ProviderContainer(
          overrides: [
            authProvider.overrideWith(
              (ref) => SimpleAuthNotifier(
                mockAuthService,
                const AuthStateUnauthenticated(),
              ),
            ),
          ],
        );

        // Act
        final notifier = container.read(authProvider.notifier);
        final result = await notifier.sendPasswordResetEmail(
          'test@example.com',
        );

        // Assert
        expect(result, equals(true));
        verify(
          () => mockAuthService.sendPasswordResetEmail('test@example.com'),
        ).called(1);

        container.dispose();
      });
    });

    group('Convenience Providers', () {
      test(
        'currentUserProvider should return current user when authenticated',
        () {
          // Arrange
          const testUser = AppUser(
            id: 'test-uid',
            email: 'test@example.com',
            emailVerified: true,
          );

          final container = ProviderContainer(
            overrides: [
              authProvider.overrideWith(
                (ref) => SimpleAuthNotifier(
                  mockAuthService,
                  const AuthStateAuthenticated(user: testUser),
                ),
              ),
            ],
          );

          // Act
          final user = container.read(currentUserProvider);

          // Assert
          expect(user?.id, equals('test-uid'));
          expect(user?.email, equals('test@example.com'));

          container.dispose();
        },
      );

      test('currentUserProvider should return null when unauthenticated', () {
        final container = ProviderContainer(
          overrides: [
            authProvider.overrideWith(
              (ref) => SimpleAuthNotifier(
                mockAuthService,
                const AuthStateUnauthenticated(),
              ),
            ),
          ],
        );

        final user = container.read(currentUserProvider);

        expect(user, isNull);

        container.dispose();
      });

      test('isAuthenticatedProvider should return true when authenticated', () {
        const testUser = AppUser(
          id: 'test-uid',
          email: 'test@example.com',
          emailVerified: true,
        );

        final container = ProviderContainer(
          overrides: [
            authProvider.overrideWith(
              (ref) => SimpleAuthNotifier(
                mockAuthService,
                const AuthStateAuthenticated(user: testUser),
              ),
            ),
          ],
        );

        final isAuthenticated = container.read(isAuthenticatedProvider);

        expect(isAuthenticated, equals(true));

        container.dispose();
      });

      test(
        'isAuthenticatedProvider should return false when unauthenticated',
        () {
          final container = ProviderContainer(
            overrides: [
              authProvider.overrideWith(
                (ref) => SimpleAuthNotifier(
                  mockAuthService,
                  const AuthStateUnauthenticated(),
                ),
              ),
            ],
          );

          final isAuthenticated = container.read(isAuthenticatedProvider);

          expect(isAuthenticated, equals(false));

          container.dispose();
        },
      );

      test('isAuthenticatedProvider should return false when loading', () {
        final container = ProviderContainer(
          overrides: [
            authProvider.overrideWith(
              (ref) => SimpleAuthNotifier(
                mockAuthService,
                const AuthStateLoading(),
              ),
            ),
          ],
        );

        final isAuthenticated = container.read(isAuthenticatedProvider);

        expect(isAuthenticated, equals(false));

        container.dispose();
      });

      test('isAuthenticatedProvider should return false when error', () {
        final container = ProviderContainer(
          overrides: [
            authProvider.overrideWith(
              (ref) => SimpleAuthNotifier(
                mockAuthService,
                const AuthStateError(message: 'Test error'),
              ),
            ),
          ],
        );

        final isAuthenticated = container.read(isAuthenticatedProvider);

        expect(isAuthenticated, equals(false));

        container.dispose();
      });
    });
  });
}
