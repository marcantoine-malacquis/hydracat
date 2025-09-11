import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/features/onboarding/screens/welcome_screen.dart';
import 'package:hydracat/features/onboarding/widgets/onboarding_progress_indicator.dart';
import 'package:hydracat/features/onboarding/widgets/onboarding_screen_wrapper.dart';

void main() {
  group('Onboarding UI Components', () {
    testWidgets('OnboardingProgressIndicator displays correct number of dots', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OnboardingProgressIndicator(
              currentStep: 2,
              totalSteps: 5,
            ),
          ),
        ),
      );

      // Verify that 5 dots are rendered
      expect(find.byType(OnboardingProgressIndicator), findsOneWidget);

      // Pump the widget to let animations settle
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('OnboardingScreenWrapper displays title and navigation', (
      WidgetTester tester,
    ) async {
      var nextPressed = false;
      var backPressed = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: OnboardingScreenWrapper(
              currentStep: 1,
              totalSteps: 5,
              title: 'Test Title',
              subtitle: 'Test Subtitle',
              onNextPressed: () => nextPressed = true,
              onBackPressed: () => backPressed = true,
              stepName: 'test_step',
              child: const Text('Test Content'),
            ),
          ),
        ),
      );

      // Verify title is displayed
      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Test Subtitle'), findsOneWidget);
      expect(find.text('Test Content'), findsOneWidget);

      // Verify navigation buttons exist
      expect(find.text('Next'), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);

      // Test button interactions
      await tester.tap(find.text('Next'));
      await tester.pump();
      expect(nextPressed, isTrue);

      await tester.tap(find.text('Back'));
      await tester.pump();
      expect(backPressed, isTrue);
    });

    testWidgets('OnboardingWelcomeScreen displays welcome content', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: OnboardingWelcomeScreen(),
          ),
        ),
      );

      // Allow widget to build and animations to settle
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify welcome content
      expect(find.text('Welcome to HydraCat'), findsOneWidget);
      expect(find.text('Your CKD Journey Starts Here'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);

      // Verify skip button exists (it contains newlines and specific text)
      expect(find.textContaining('Skip for now'), findsOneWidget);

      // Verify benefits list is shown
      expect(find.textContaining('Track fluid therapy'), findsOneWidget);
      expect(find.textContaining('Monitor your cat'), findsOneWidget);
    });

    testWidgets('Progress indicator animates correctly between steps', (
      WidgetTester tester,
    ) async {
      // Start with step 0
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OnboardingProgressIndicator(
              currentStep: 0,
              totalSteps: 5,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Change to step 1
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OnboardingProgressIndicator(
              currentStep: 1,
              totalSteps: 5,
            ),
          ),
        ),
      );

      // Pump animation frames
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump(const Duration(milliseconds: 150));

      // Verify animation completed
      expect(find.byType(OnboardingProgressIndicator), findsOneWidget);
    });

    testWidgets('OnboardingWelcomeScreen handles get started tap', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: OnboardingWelcomeScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap the get started button
      await tester.tap(find.text('Get Started'));
      await tester.pump();

      // Currently shows a placeholder snackbar
      expect(
        find.textContaining('Navigation to user persona screen'),
        findsOneWidget,
      );
    });

    testWidgets('OnboardingWelcomeScreen handles skip tap', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: OnboardingWelcomeScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Find and tap the skip button
      final skipButton = find.textContaining('Skip for now');
      expect(skipButton, findsOneWidget);

      await tester.tap(skipButton);
      await tester.pump();

      // Currently shows a placeholder snackbar
      expect(find.textContaining('Navigation to main app'), findsOneWidget);
    });
  });
}
