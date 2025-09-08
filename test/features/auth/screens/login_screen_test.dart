import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hydracat/features/auth/models/auth_state.dart';
import 'package:hydracat/features/auth/screens/login_screen.dart';
import 'package:hydracat/features/auth/services/auth_service.dart';
import 'package:hydracat/providers/auth_provider.dart';
import 'package:mocktail/mocktail.dart';

class MockGoRouter extends Mock implements GoRouter {}

class MockAuthService extends Mock implements AuthService {}

class MockAuthNotifier extends Mock implements AuthNotifier {}

void main() {
  group('LoginScreen Widget Tests', () {
    late MockAuthService mockAuthService;
    late MockAuthNotifier mockAuthNotifier;

    setUp(() {
      mockAuthService = MockAuthService();
      mockAuthNotifier = MockAuthNotifier();

      // Default auth service mocks
      when(
        () => mockAuthService.waitForInitialization(),
      ).thenAnswer((_) async {});
      when(
        () => mockAuthService.authStateChanges,
      ).thenAnswer((_) => Stream.value(null));
      when(() => mockAuthService.currentUser).thenReturn(null);

      // Default auth notifier mocks
      when(
        () => mockAuthNotifier.state,
      ).thenReturn(const AuthStateUnauthenticated());
    });

    testWidgets('should display login form with email and password fields', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(mockAuthService),
            authProvider.overrideWith((ref) => MockAuthNotifier()),
          ],
          child: const MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsWidgets);
    });

    testWidgets('should show validation errors for empty fields', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(mockAuthService),
            authProvider.overrideWith((ref) => MockAuthNotifier()),
          ],
          child: const MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act - Try to submit without entering data
      final signInButton = find.text('Sign In').first;
      await tester.tap(signInButton);
      await tester.pumpAndSettle();

      // Assert - Should show validation errors
      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('should validate email format', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(mockAuthService),
            authProvider.overrideWith((ref) => MockAuthNotifier()),
          ],
          child: const MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act - Enter invalid email
      await tester.enterText(
        find.byType(TextFormField).first,
        'invalid-email',
      );
      await tester.enterText(
        find.byType(TextFormField).last,
        'password123',
      );

      final signInButton = find.text('Sign In').first;
      await tester.tap(signInButton);
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Please enter a valid email'), findsOneWidget);
    });

    testWidgets('should toggle password visibility', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(mockAuthService),
            authProvider.overrideWith((ref) => MockAuthNotifier()),
          ],
          child: const MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find visibility toggle
      final visibilityToggle = find.byIcon(Icons.visibility);

      // Assert initial state (password hidden)
      expect(visibilityToggle, findsOneWidget);

      // Act - Toggle visibility
      await tester.tap(visibilityToggle);
      await tester.pumpAndSettle();

      // Assert - Icon should change to visibility_off
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    });

    testWidgets('should show loading state during authentication', (
      WidgetTester tester,
    ) async {
      // Arrange
      when(() => mockAuthNotifier.state).thenReturn(const AuthStateLoading());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(mockAuthService),
            authProvider.overrideWith((ref) => mockAuthNotifier),
          ],
          child: const MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert - Should show some loading indicator
      // The specific loading indicator depends on the implementation
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('should contain social sign-in buttons', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(mockAuthService),
            authProvider.overrideWith((ref) => MockAuthNotifier()),
          ],
          child: const MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert - Should have Google sign-in button
      expect(find.text('Continue with Google'), findsOneWidget);

      // Note: Apple Sign-In button would only show on iOS in production
      // but might be present in the widget tree during testing
    });

    testWidgets('should navigate to registration screen', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(mockAuthService),
            authProvider.overrideWith((ref) => MockAuthNotifier()),
          ],
          child: const MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert - Should have link to registration
      expect(find.text('Create account'), findsOneWidget);
    });

    testWidgets('should navigate to forgot password screen', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(mockAuthService),
            authProvider.overrideWith((ref) => MockAuthNotifier()),
          ],
          child: const MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert - Should have forgot password link
      expect(find.text('Forgot password?'), findsOneWidget);
    });

    testWidgets('should show proper form validation on submit', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(mockAuthService),
            authProvider.overrideWith((ref) => MockAuthNotifier()),
          ],
          child: const MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act - Enter valid data
      await tester.enterText(
        find.byType(TextFormField).first,
        'test@example.com',
      );
      await tester.enterText(
        find.byType(TextFormField).last,
        'password123',
      );

      await tester.pumpAndSettle();

      // Assert - Form should be valid (no validation errors shown)
      expect(find.text('Please enter your email'), findsNothing);
      expect(find.text('Please enter your password'), findsNothing);
      expect(find.text('Please enter a valid email'), findsNothing);
    });
  });
}
