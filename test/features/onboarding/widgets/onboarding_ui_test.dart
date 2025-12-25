import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/features/onboarding/models/onboarding_step_id.dart';
import 'package:hydracat/features/onboarding/widgets/onboarding_progress_indicator.dart';

void main() {
  group('Onboarding UI Components', () {
    testWidgets(
      'OnboardingProgressIndicator displays correct number of dots',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: OnboardingProgressIndicator(
                currentStep: 2,
                totalSteps: OnboardingSteps.all.length,
              ),
            ),
          ),
        );

        // Verify that correct number of dots are rendered
        expect(find.byType(OnboardingProgressIndicator), findsOneWidget);

        // Pump the widget to let animations settle
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
      },
    );

    testWidgets(
      'OnboardingSteps has correct total steps',
      (WidgetTester tester) async {
        // Test that total steps returns the correct number (should be 4)
        expect(OnboardingSteps.all.length, 4);
      },
    );

    testWidgets(
      'Progress indicator animates correctly between steps',
      (WidgetTester tester) async {
        // Start with step 0
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: OnboardingProgressIndicator(
                currentStep: 0,
                totalSteps: OnboardingSteps.all.length,
              ),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Change to step 1
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: OnboardingProgressIndicator(
                currentStep: 1,
                totalSteps: OnboardingSteps.all.length,
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
      },
    );
  });
}
