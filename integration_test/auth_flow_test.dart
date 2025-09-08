import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/main_development.dart' as app;
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Authentication Flow Integration Tests', () {
    testWidgets('should display login screen on app launch', (
      WidgetTester tester,
    ) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify login screen elements are present
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
    });

    testWidgets('should show validation errors for empty login form', (
      WidgetTester tester,
    ) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Try to submit empty form
      final signInButton = find.text('Sign In').first;
      await tester.tap(signInButton);
      await tester.pumpAndSettle();

      // Should show validation errors
      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('should navigate to registration screen', (
      WidgetTester tester,
    ) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Tap on create account link
      await tester.tap(find.text('Create account'));
      await tester.pumpAndSettle();

      // Should navigate to registration screen
      expect(find.text('Create Account'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
    });

    testWidgets('should navigate to forgot password screen', (
      WidgetTester tester,
    ) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Tap on forgot password link
      await tester.tap(find.text('Forgot password?'));
      await tester.pumpAndSettle();

      // Should navigate to password reset screen
      expect(find.text('Reset Password'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
    });
  });
}
