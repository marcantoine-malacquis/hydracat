import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/features/auth/exceptions/auth_exceptions.dart';
import 'package:hydracat/features/auth/models/app_user.dart';
import 'package:hydracat/features/auth/models/auth_state.dart';
import 'package:hydracat/features/auth/services/auth_service.dart';
import 'package:hydracat/providers/auth_provider.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthService extends Mock implements AuthService {}

class MockAuthNotifier extends AuthNotifier {
  MockAuthNotifier(AuthState initialState) : super(MockAuthService()) {
    state = initialState;
  }
}

void main() {
  group('AuthProvider', () {
    late MockAuthService mockAuthService;
    late ProviderContainer container;

    setUp(() {
      mockAuthService = MockAuthService();

      // Mock auth service defaults
      when(
        () => mockAuthService.waitForInitialization(),
      ).thenAnswer((_) async {});
      when(
        () => mockAuthService.authStateChanges,
      ).thenAnswer((_) => Stream.value(null));
      when(() => mockAuthService.currentUser).thenReturn(null);

      container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(mockAuthService),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    group('AuthNotifier', () {
      test('should initialize with loading state', () async {
        // Act
        final authState = container.read(authProvider);

        // Assert
        expect(authState, isA<AuthStateLoading>());
      });

      test(
        'should transition to unauthenticated when no user is signed in',
        () async {
          // Arrange
          when(() => mockAuthService.currentUser).thenReturn(null);

          // Act
          await Future<void>.delayed(Duration.zero); // Let initialization
          // complete

          // Assert
          final state = container.read(authProvider);
          expect(state, isA<AuthStateUnauthenticated>());
        },
      );

      test(
        'should transition to authenticated when user is signed in',
        () async {
          // Arrange
          const testUser = AppUser(
            id: 'test-uid',
            email: 'test@example.com',
            emailVerified: true,
          );
          when(() => mockAuthService.currentUser).thenReturn(testUser);

          // Create a new container for this test
          final testContainer = ProviderContainer(
            overrides: [
              authServiceProvider.overrideWithValue(mockAuthService),
            ],
          );

          // Act
          await Future<void>.delayed(Duration.zero); // Let initialization
          // complete

          // Assert
          final state = testContainer.read(authProvider);
          expect(state, isA<AuthStateAuthenticated>());
          if (state is AuthStateAuthenticated) {
            expect(state.user.id, equals('test-uid'));
          }

          testContainer.dispose();
        },
      );

      test('should handle sign up successfully', () async {
        // Arrange
        const testUser = AppUser(
          id: 'new-user-uid',
          email: 'new@example.com',
        );

        when(
          () => mockAuthService.signUp(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => const AuthSuccess(testUser));

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

        // Act
        final notifier = container.read(authProvider.notifier);
        await notifier.signUp(email: 'test@example.com', password: 'weak');

        // Assert
        final state = container.read(authProvider);
        expect(state, isA<AuthStateError>());
        if (state is AuthStateError) {
          expect(state.message, contains('stronger password'));
        }
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
          expect(state.message, contains('password is incorrect'));
        }
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

        // Act
        final notifier = container.read(authProvider.notifier);
        await notifier.signInWithGoogle();

        // Assert
        final state = container.read(authProvider);
        expect(state, isA<AuthStateAuthenticated>());
        if (state is AuthStateAuthenticated) {
          expect(state.user.email, equals('google@example.com'));
        }
      });

      test('should handle sign out successfully', () async {
        // Arrange
        when(() => mockAuthService.signOut()).thenAnswer((_) async => true);

        // Act
        final notifier = container.read(authProvider.notifier);
        await notifier.signOut();

        // Assert
        final state = container.read(authProvider);
        expect(state, isA<AuthStateUnauthenticated>());
      });

      test('should handle sign out failure gracefully', () async {
        // Arrange
        when(() => mockAuthService.signOut()).thenAnswer((_) async => false);

        // Act
        final notifier = container.read(authProvider.notifier);
        await notifier.signOut();

        // Assert - Should still transition to unauthenticated for UX
        final state = container.read(authProvider);
        expect(state, isA<AuthStateUnauthenticated>());
      });

      test('should send email verification successfully', () async {
        // Arrange
        when(
          () => mockAuthService.sendEmailVerification(),
        ).thenAnswer((_) async => const AuthSuccess(null));

        // Act
        final notifier = container.read(authProvider.notifier);
        final result = await notifier.sendEmailVerification();

        // Assert
        expect(result, equals(true));
      });

      test('should handle email verification failure', () async {
        // Arrange
        const exception = EmailVerificationException();
        when(
          () => mockAuthService.sendEmailVerification(),
        ).thenAnswer((_) async => const AuthFailure(exception));

        // Act
        final notifier = container.read(authProvider.notifier);
        final result = await notifier.sendEmailVerification();

        // Assert
        expect(result, equals(false));
      });

      test('should send password reset email successfully', () async {
        // Arrange
        when(
          () => mockAuthService.sendPasswordResetEmail(any()),
        ).thenAnswer((_) async => const AuthSuccess(null));

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
      });
    });

    group('Convenience Providers', () {
      test(
        'currentUserProvider should return current user when authenticated',
        () async {
          // Arrange
          final testContainer = ProviderContainer(
            overrides: [
              authProvider.overrideWith(
                (ref) => MockAuthNotifier(
                  const AuthStateAuthenticated(
                    user: AppUser(
                      id: 'test-uid',
                      email: 'test@example.com',
                      emailVerified: true,
                    ),
                  ),
                ),
              ),
            ],
          );

          // Act
          final user = testContainer.read(currentUserProvider);

          // Assert
          expect(user?.id, equals('test-uid'));
          expect(user?.email, equals('test@example.com'));

          testContainer.dispose();
        },
      );

      test(
        'isAuthenticatedProvider should return true when authenticated',
        () async {
          // Arrange
          final testContainer = ProviderContainer(
            overrides: [
              authProvider.overrideWith(
                (ref) => MockAuthNotifier(
                  const AuthStateAuthenticated(
                    user: AppUser(
                      id: 'test-uid',
                      email: 'test@example.com',
                      emailVerified: true,
                    ),
                  ),
                ),
              ),
            ],
          );

          // Act
          final isAuthenticated = testContainer.read(isAuthenticatedProvider);

          // Assert
          expect(isAuthenticated, equals(true));

          testContainer.dispose();
        },
      );

      test(
        'isAuthenticatedProvider should return false when unauthenticated',
        () async {
          // Arrange
          final testContainer = ProviderContainer(
            overrides: [
              authProvider.overrideWith(
                (ref) => MockAuthNotifier(const AuthStateUnauthenticated()),
              ),
            ],
          );

          // Act
          final isAuthenticated = testContainer.read(isAuthenticatedProvider);

          // Assert
          expect(isAuthenticated, equals(false));

          testContainer.dispose();
        },
      );
    });
  });
}
