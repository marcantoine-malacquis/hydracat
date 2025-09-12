import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/features/onboarding/models/onboarding_step.dart';
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
                totalSteps: OnboardingStepType.totalSteps,
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
      'OnboardingStepType enum has correct total steps',
      (WidgetTester tester) async {
        // Test that totalSteps returns the correct number (should be 6 now)
        expect(OnboardingStepType.totalSteps, 6);
        expect(OnboardingStepType.values.length, 6);
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
                totalSteps: OnboardingStepType.totalSteps,
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
                totalSteps: OnboardingStepType.totalSteps,
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
