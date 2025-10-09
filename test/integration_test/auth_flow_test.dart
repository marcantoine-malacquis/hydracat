/// Integration tests for authentication flow
///
/// Tests the auth UI screens with mocked services to verify:
/// - Login screen UI and validation
/// - Registration screen navigation
/// - Password reset navigation
/// - Form validation behavior
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hydracat/features/auth/models/app_user.dart';
import 'package:hydracat/features/auth/models/auth_state.dart';
import 'package:hydracat/features/auth/screens/forgot_password_screen.dart';
import 'package:hydracat/features/auth/screens/login_screen.dart';
import 'package:hydracat/features/auth/screens/register_screen.dart';
import 'package:hydracat/features/auth/services/auth_service.dart';
import 'package:hydracat/providers/auth_provider.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthService extends Mock implements AuthService {}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthService mockAuthService;

  setUp(() {
    mockAuthService = MockAuthService();

    // Stub the required methods
    when(
      () => mockAuthService.waitForInitialization(),
    ).thenAnswer((_) async => {});
    when(
      () => mockAuthService.authStateChanges,
    ).thenAnswer((_) => Stream<AppUser?>.value(null));
    when(() => mockAuthService.currentUser).thenReturn(null);
    when(() => mockAuthService.hasAuthenticatedUser).thenReturn(false);
  });

  /// Helper to create a testable app with GoRouter navigation
  Widget createTestApp({
    required String initialLocation,
    required Widget Function(BuildContext, GoRouterState) builder,
  }) {
    final router = GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        authProvider.overrideWith(
          (ref) => SimpleAuthNotifier(
            mockAuthService,
            const AuthStateUnauthenticated(),
          ),
        ),
      ],
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  group('Authentication Flow Integration Tests', () {
    testWidgets('should display login screen with all elements', (
      WidgetTester tester,
    ) async {
      // Arrange & Act: Render the login screen
      await tester.pumpWidget(
        createTestApp(
          initialLocation: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Assert: Verify all login screen elements are present
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('Welcome back to Hydracat'), findsOneWidget);
    });

    testWidgets('should show validation errors for empty login form', (
      WidgetTester tester,
    ) async {
      // Arrange: Render the login screen
      await tester.pumpWidget(
        createTestApp(
          initialLocation: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Act: Try to submit empty form
      final signInButton = find.widgetWithText(ElevatedButton, 'Sign In');
      await tester.tap(signInButton);
      await tester.pumpAndSettle();

      // Assert: Validation errors should be shown
      expect(
        find.text('We need your email to continue'),
        findsOneWidget,
      );
      expect(
        find.text('Password required to access your account'),
        findsOneWidget,
      );
    });

    testWidgets('should validate email format', (
      WidgetTester tester,
    ) async {
      // Arrange: Render the login screen
      await tester.pumpWidget(
        createTestApp(
          initialLocation: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Act: Enter invalid email and submit
      final emailField = find.widgetWithText(TextFormField, 'Email');
      await tester.enterText(emailField, 'invalid-email');

      final signInButton = find.widgetWithText(ElevatedButton, 'Sign In');
      await tester.tap(signInButton);
      await tester.pumpAndSettle();

      // Assert: Email format error should be shown
      expect(
        find.text('Please enter a valid email'),
        findsOneWidget,
      );
    });

    testWidgets('should validate password length', (
      WidgetTester tester,
    ) async {
      // Arrange: Render the login screen
      await tester.pumpWidget(
        createTestApp(
          initialLocation: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Act: Enter valid email but short password
      final emailField = find.widgetWithText(TextFormField, 'Email');
      await tester.enterText(emailField, 'test@example.com');

      final passwordField = find.widgetWithText(TextFormField, 'Password');
      await tester.enterText(passwordField, 'short');

      final signInButton = find.widgetWithText(ElevatedButton, 'Sign In');
      await tester.tap(signInButton);
      await tester.pumpAndSettle();

      // Assert: Password length error should be shown
      expect(
        find.text('8 characters minimum for security'),
        findsOneWidget,
      );
    });

    testWidgets('should navigate to registration screen', (
      WidgetTester tester,
    ) async {
      // Arrange: Render the login screen with router
      await tester.pumpWidget(
        createTestApp(
          initialLocation: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Act: Scroll to and tap on create account link
      final signUpButton = find.text('Sign Up');
      expect(signUpButton, findsOneWidget);
      await tester.ensureVisible(signUpButton);
      await tester.pumpAndSettle();
      await tester.tap(signUpButton);
      await tester.pumpAndSettle();

      // Assert: Should navigate to registration screen
      expect(find.text('Join Hydracat'), findsOneWidget);
      expect(find.text('Email'), findsWidgets);
      expect(find.text('Password'), findsWidgets);
      expect(find.text('Confirm Password'), findsOneWidget);
    });

    testWidgets('should navigate to forgot password screen', (
      WidgetTester tester,
    ) async {
      // Arrange: Render the login screen with router
      await tester.pumpWidget(
        createTestApp(
          initialLocation: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Act: Scroll to and tap on forgot password link
      final resetPasswordButton = find.text('Reset Password');
      expect(resetPasswordButton, findsOneWidget);
      await tester.ensureVisible(resetPasswordButton);
      await tester.pumpAndSettle();
      await tester.tap(resetPasswordButton);
      await tester.pumpAndSettle();

      // Assert: Should navigate to password reset screen
      expect(find.text('Reset Your Password'), findsOneWidget);
      expect(find.text('Email'), findsWidgets);
      expect(
        find.textContaining('Enter your email address'),
        findsOneWidget,
      );
    });

    testWidgets('should toggle password visibility', (
      WidgetTester tester,
    ) async {
      // Arrange: Render the login screen
      await tester.pumpWidget(
        createTestApp(
          initialLocation: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Find the password field and visibility toggle
      final passwordField = find.widgetWithText(TextFormField, 'Password');
      expect(passwordField, findsOneWidget);

      // Act: Tap the visibility toggle
      final visibilityToggle = find.descendant(
        of: passwordField,
        matching: find.byType(IconButton),
      );
      expect(visibilityToggle, findsOneWidget);
      await tester.tap(visibilityToggle);
      await tester.pumpAndSettle();

      // Assert: The icon should change (we can verify the toggle worked)
      // The visibility icon changes from visibility to visibility_off
      expect(find.byIcon(Icons.visibility_off), findsAtLeastNWidgets(1));
    });
  });
}

/// Simple mock notifier for testing
class SimpleAuthNotifier extends AuthNotifier {
  SimpleAuthNotifier(super.authService, AuthState initialState) {
    state = initialState;
  }

  @override
  Future<void> signUp({required String email, required String password}) async {
    state = const AuthStateLoading();
    // Mock implementation - just set state
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    state = const AuthStateLoading();
    // Mock implementation - just set state
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }

  @override
  Future<void> signOut() async {
    state = const AuthStateLoading();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    state = const AuthStateUnauthenticated();
  }

  @override
  Future<bool> sendPasswordResetEmail(String email) async {
    return true;
  }

  @override
  Future<bool> sendEmailVerification() async {
    return true;
  }

  @override
  Future<void> signInWithGoogle() async {
    state = const AuthStateLoading();
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }

  @override
  Future<void> signInWithApple() async {
    state = const AuthStateLoading();
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
}
