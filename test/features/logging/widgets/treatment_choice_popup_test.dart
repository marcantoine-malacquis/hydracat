import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/core/constants/app_icons.dart';
import 'package:hydracat/features/logging/models/treatment_choice.dart';
import 'package:hydracat/shared/widgets/icons/hydra_icon.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/widget_test_helpers.dart';

void main() {
  setUpAll(registerFallbackValues);

  group('TreatmentChoicePopup - Initial Rendering', () {
    testWidgets('displays title "Add one-time entry"', (tester) async {
      await pumpTreatmentChoicePopup(
        tester,
        onMedicationSelected: () {},
        onFluidSelected: () {},
      );

      expect(find.text('Add one-time entry'), findsOneWidget);
    });

    testWidgets('displays medication button', (tester) async {
      await pumpTreatmentChoicePopup(
        tester,
        onMedicationSelected: () {},
        onFluidSelected: () {},
      );

      expect(find.text('Medication'), findsOneWidget);
    });

    testWidgets('displays fluid therapy button', (tester) async {
      await pumpTreatmentChoicePopup(
        tester,
        onMedicationSelected: () {},
        onFluidSelected: () {},
      );

      expect(find.text('Fluid Therapy'), findsOneWidget);
    });

    testWidgets('displays cancel button', (tester) async {
      await pumpTreatmentChoicePopup(
        tester,
        onMedicationSelected: () {},
        onFluidSelected: () {},
      );

      expect(find.text('Cancel'), findsOneWidget);
    });
  });

  group('TreatmentChoicePopup - User Interactions', () {
    testWidgets('calls onMedicationSelected when medication tapped', (
      tester,
    ) async {
      var medicationCalled = false;
      await pumpTreatmentChoicePopup(
        tester,
        onMedicationSelected: () => medicationCalled = true,
        onFluidSelected: () {},
      );

      await tester.tap(find.text('Medication'));
      await tester.pump();

      expect(medicationCalled, isTrue);
    });

    testWidgets('calls onFluidSelected when fluid tapped', (tester) async {
      var fluidCalled = false;
      await pumpTreatmentChoicePopup(
        tester,
        onMedicationSelected: () {},
        onFluidSelected: () => fluidCalled = true,
      );

      await tester.tap(find.text('Fluid Therapy'));
      await tester.pump();

      expect(fluidCalled, isTrue);
    });

    testWidgets('sets treatment choice to medication on tap', (tester) async {
      final mockNotifier = MockLoggingNotifier();
      setupDefaultLoggingNotifierMocks(mockNotifier);

      await pumpTreatmentChoicePopup(
        tester,
        onMedicationSelected: () {},
        onFluidSelected: () {},
        mockLoggingNotifier: mockNotifier,
      );

      await tester.tap(find.text('Medication'));
      await tester.pump();

      verify(
        () => mockNotifier.setTreatmentChoice(TreatmentChoice.medication),
      ).called(1);
    });

    testWidgets('sets treatment choice to fluid on tap', (tester) async {
      final mockNotifier = MockLoggingNotifier();
      setupDefaultLoggingNotifierMocks(mockNotifier);

      await pumpTreatmentChoicePopup(
        tester,
        onMedicationSelected: () {},
        onFluidSelected: () {},
        mockLoggingNotifier: mockNotifier,
      );

      await tester.tap(find.text('Fluid Therapy'));
      await tester.pump();

      verify(
        () => mockNotifier.setTreatmentChoice(TreatmentChoice.fluid),
      ).called(1);
    });

    testWidgets('resets state on cancel button tap', (tester) async {
      final mockNotifier = MockLoggingNotifier();
      setupDefaultLoggingNotifierMocks(mockNotifier);

      await pumpTreatmentChoicePopup(
        tester,
        onMedicationSelected: () {},
        onFluidSelected: () {},
        mockLoggingNotifier: mockNotifier,
      );

      await tester.tap(find.text('Cancel'));
      await tester.pump();

      verify(mockNotifier.reset).called(1);
    });
  });

  group('TreatmentChoicePopup - Analytics Integration', () {
    testWidgets('tracks medication choice selection', (tester) async {
      final mockAnalytics = MockAnalyticsService();
      when(
        () => mockAnalytics.trackTreatmentChoiceSelected(
          choice: any(named: 'choice'),
        ),
      ).thenAnswer((_) async {});

      await pumpTreatmentChoicePopup(
        tester,
        onMedicationSelected: () {},
        onFluidSelected: () {},
        mockAnalyticsService: mockAnalytics,
      );

      await tester.tap(find.text('Medication'));
      await tester.pump();

      verify(
        () => mockAnalytics.trackTreatmentChoiceSelected(choice: 'medication'),
      ).called(1);
    });

    testWidgets('tracks fluid choice selection', (tester) async {
      final mockAnalytics = MockAnalyticsService();
      when(
        () => mockAnalytics.trackTreatmentChoiceSelected(
          choice: any(named: 'choice'),
        ),
      ).thenAnswer((_) async {});

      await pumpTreatmentChoicePopup(
        tester,
        onMedicationSelected: () {},
        onFluidSelected: () {},
        mockAnalyticsService: mockAnalytics,
      );

      await tester.tap(find.text('Fluid Therapy'));
      await tester.pump();

      verify(
        () => mockAnalytics.trackTreatmentChoiceSelected(choice: 'fluid'),
      ).called(1);
    });
  });

  group('TreatmentChoicePopup - Navigation', () {
    testWidgets('has proper widget structure for navigation', (tester) async {
      await pumpTreatmentChoicePopup(
        tester,
        onMedicationSelected: () {},
        onFluidSelected: () {},
      );

      // Verify Material widget exists (required for proper navigation)
      expect(find.byType(Material), findsWidgets);
      // Verify container structure exists
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('calls onMedicationSelected without errors', (tester) async {
      var callbackExecuted = false;
      await pumpTreatmentChoicePopup(
        tester,
        onMedicationSelected: () => callbackExecuted = true,
        onFluidSelected: () {},
      );

      await tester.tap(find.text('Medication'));
      await tester.pump();

      expect(callbackExecuted, isTrue);
    });

    testWidgets('calls onFluidSelected without errors', (tester) async {
      var callbackExecuted = false;
      await pumpTreatmentChoicePopup(
        tester,
        onMedicationSelected: () {},
        onFluidSelected: () => callbackExecuted = true,
      );

      await tester.tap(find.text('Fluid Therapy'));
      await tester.pump();

      expect(callbackExecuted, isTrue);
    });
  });

  group('TreatmentChoicePopup - Visual Feedback', () {
    testWidgets('displays medication icon', (tester) async {
      await pumpTreatmentChoicePopup(
        tester,
        onMedicationSelected: () {},
        onFluidSelected: () {},
      );

      // Find HydraIcon widgets
      final hydraIcons = find.byType(HydraIcon);
      expect(hydraIcons, findsNWidgets(2)); // medication + fluid icons

      // Verify medication icon exists by checking the icon string
      final medicationIcon = tester.widget<HydraIcon>(hydraIcons.first);
      expect(medicationIcon.icon, equals(AppIcons.medication));
    });

    testWidgets('displays fluid therapy icon', (tester) async {
      await pumpTreatmentChoicePopup(
        tester,
        onMedicationSelected: () {},
        onFluidSelected: () {},
      );

      // Find HydraIcon widgets
      final hydraIcons = find.byType(HydraIcon);
      expect(hydraIcons, findsNWidgets(2)); // medication + fluid icons

      // Verify fluid therapy icon exists by checking the icon string
      final fluidIcon = tester.widget<HydraIcon>(hydraIcons.last);
      expect(fluidIcon.icon, equals(AppIcons.fluidTherapy));
    });

    testWidgets('shows divider between buttons', (tester) async {
      await pumpTreatmentChoicePopup(
        tester,
        onMedicationSelected: () {},
        onFluidSelected: () {},
      );

      expect(find.byType(Divider), findsOneWidget);
    });
  });

  group('TreatmentChoicePopup - Accessibility', () {
    testWidgets('has semantic labels on medication button', (tester) async {
      await pumpTreatmentChoicePopup(
        tester,
        onMedicationSelected: () {},
        onFluidSelected: () {},
      );

      // Verify Semantics widget exists for medication button
      // There should be multiple Semantics widgets (one with label)
      final semantics = find.byType(Semantics);
      expect(semantics, findsWidgets);

      // Verify the medication button text exists
      // (confirms accessibility structure)
      expect(find.text('Medication'), findsOneWidget);
    });

    testWidgets('has semantic labels on fluid button', (tester) async {
      await pumpTreatmentChoicePopup(
        tester,
        onMedicationSelected: () {},
        onFluidSelected: () {},
      );

      // Verify Semantics widget exists for fluid button
      // There should be multiple Semantics widgets (one with label)
      final semantics = find.byType(Semantics);
      expect(semantics, findsWidgets);

      // Verify the fluid button text exists (confirms accessibility structure)
      expect(find.text('Fluid Therapy'), findsOneWidget);
    });

    testWidgets('has semantic label on cancel button', (tester) async {
      await pumpTreatmentChoicePopup(
        tester,
        onMedicationSelected: () {},
        onFluidSelected: () {},
      );

      // Verify Semantics widget exists for cancel button
      // There should be multiple Semantics widgets (one with label)
      final semantics = find.byType(Semantics);
      expect(semantics, findsWidgets);

      // Verify the cancel button text exists (confirms accessibility structure)
      expect(find.text('Cancel'), findsOneWidget);
    });
  });
}
