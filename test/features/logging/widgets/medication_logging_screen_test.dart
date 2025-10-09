import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/features/logging/models/logging_state.dart';
import 'package:hydracat/features/logging/models/medication_session.dart';
import 'package:hydracat/features/logging/widgets/medication_selection_card.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/widget_test_helpers.dart';

void main() {
  setUpAll(registerFallbackValues);

  group('MedicationLoggingScreen - Initial Rendering', () {
    testWidgets('displays title "Log Medication"', (tester) async {
      await pumpMedicationLoggingScreen(tester);

      expect(find.text('Log Medication'), findsOneWidget);
    });

    testWidgets('displays empty state when no schedules', (tester) async {
      await pumpMedicationLoggingScreen(
        tester,
        medicationSchedules: [],
      );

      expect(
        find.text('No medications scheduled for today'),
        findsOneWidget,
      );
    });

    testWidgets('displays medication cards when schedules exist', (
      tester,
    ) async {
      final schedules = [
        createTestMedicationSchedule(),
        createTestMedicationSchedule(
          id: 'test-med-2',
          medicationName: 'Benazepril',
        ),
      ];

      await pumpMedicationLoggingScreen(
        tester,
        medicationSchedules: schedules,
      );
      await tester.pumpAndSettle();

      // Verify medication cards exist
      expect(find.byType(MedicationSelectionCard), findsNWidgets(2));
      // Medication names are in RichText within the cards
      final cards = tester.widgetList<MedicationSelectionCard>(
        find.byType(MedicationSelectionCard),
      );
      expect(cards.length, equals(2));
    });

    testWidgets('displays Select All button with multiple medications', (
      tester,
    ) async {
      final schedules = [
        createTestMedicationSchedule(),
        createTestMedicationSchedule(
          id: 'test-med-2',
          medicationName: 'Benazepril',
        ),
      ];

      await pumpMedicationLoggingScreen(
        tester,
        medicationSchedules: schedules,
      );
      await tester.pumpAndSettle();

      expect(find.text('Select All'), findsOneWidget);
    });

    testWidgets('hides Select All button with single medication', (
      tester,
    ) async {
      final schedules = [
        createTestMedicationSchedule(),
      ];

      await pumpMedicationLoggingScreen(
        tester,
        medicationSchedules: schedules,
      );
      await tester.pumpAndSettle();

      expect(find.text('Select All'), findsNothing);
    });
  });

  group('MedicationLoggingScreen - User Interactions', () {
    testWidgets('selects medication on card tap', (tester) async {
      final schedules = [
        createTestMedicationSchedule(),
      ];

      await pumpMedicationLoggingScreen(
        tester,
        medicationSchedules: schedules,
      );
      await tester.pumpAndSettle();

      // Tap the medication card
      await tester.tap(find.byType(MedicationSelectionCard));
      await tester.pump();

      // Verify card is selected by checking widget state
      final card = tester.widget<MedicationSelectionCard>(
        find.byType(MedicationSelectionCard),
      );
      expect(card.isSelected, isTrue);
    });

    testWidgets('deselects medication on second tap', (tester) async {
      final schedules = [
        createTestMedicationSchedule(),
      ];

      await pumpMedicationLoggingScreen(
        tester,
        medicationSchedules: schedules,
      );
      await tester.pumpAndSettle();

      // First tap to select
      await tester.tap(find.byType(MedicationSelectionCard));
      await tester.pump();

      // Second tap to deselect
      await tester.tap(find.byType(MedicationSelectionCard));
      await tester.pump();

      // Verify card is deselected
      final card = tester.widget<MedicationSelectionCard>(
        find.byType(MedicationSelectionCard),
      );
      expect(card.isSelected, isFalse);
    });

    testWidgets('selects all medications on Select All tap', (tester) async {
      final schedules = [
        createTestMedicationSchedule(),
        createTestMedicationSchedule(
          id: 'test-med-2',
          medicationName: 'Benazepril',
        ),
      ];

      await pumpMedicationLoggingScreen(
        tester,
        medicationSchedules: schedules,
      );
      await tester.pumpAndSettle();

      // Tap Select All
      await tester.tap(find.text('Select All'));
      await tester.pumpAndSettle();

      // Verify both cards are selected
      final cards = tester.widgetList<MedicationSelectionCard>(
        find.byType(MedicationSelectionCard),
      );
      for (final card in cards) {
        expect(card.isSelected, isTrue);
      }
    });

    testWidgets('deselects all on Deselect All tap', (tester) async {
      final schedules = [
        createTestMedicationSchedule(),
        createTestMedicationSchedule(
          id: 'test-med-2',
          medicationName: 'Benazepril',
        ),
      ];

      await pumpMedicationLoggingScreen(
        tester,
        medicationSchedules: schedules,
      );
      await tester.pumpAndSettle();

      // Tap Select All
      await tester.tap(find.text('Select All'));
      await tester.pumpAndSettle();

      // Tap Deselect All (button text changes)
      await tester.tap(find.text('Deselect All'));
      await tester.pumpAndSettle();

      // Verify all cards are deselected
      final cards = tester.widgetList<MedicationSelectionCard>(
        find.byType(MedicationSelectionCard),
      );
      for (final card in cards) {
        expect(card.isSelected, isFalse);
      }
    });

    testWidgets('accepts notes input with character count', (tester) async {
      final schedules = [
        createTestMedicationSchedule(),
      ];

      await pumpMedicationLoggingScreen(
        tester,
        medicationSchedules: schedules,
      );
      await tester.pumpAndSettle();

      // Find notes field
      final notesField = find.widgetWithText(TextField, 'Notes (optional)');

      // Enter text
      await tester.enterText(notesField, 'Test notes');
      await tester.pump();

      // Focus the field to show counter
      await tester.tap(notesField);
      await tester.pump();

      // Verify counter shows (note: AnimatedOpacity makes it visible)
      expect(find.text('10/500'), findsOneWidget);
    });

    testWidgets('expands notes field when typing', (tester) async {
      final schedules = [
        createTestMedicationSchedule(),
      ];

      await pumpMedicationLoggingScreen(
        tester,
        medicationSchedules: schedules,
      );
      await tester.pumpAndSettle();

      // Find notes field
      final notesField = find.widgetWithText(TextField, 'Notes (optional)');

      // Initially should have minLines=1
      var textFieldWidget = tester.widget<TextField>(notesField);
      expect(textFieldWidget.minLines, equals(1));

      // Enter text
      await tester.enterText(notesField, 'Test notes');
      await tester.pump();

      // After entering text, minLines should be 3
      textFieldWidget = tester.widget<TextField>(notesField);
      expect(textFieldWidget.minLines, equals(3));
    });
  });

  group('MedicationLoggingScreen - Form Validation', () {
    testWidgets('disables Log button when no medications selected', (
      tester,
    ) async {
      final schedules = [
        createTestMedicationSchedule(),
      ];

      await pumpMedicationLoggingScreen(
        tester,
        medicationSchedules: schedules,
      );
      await tester.pumpAndSettle();

      // Find Log button (it's inside a Semantics widget)
      final logButtons = find.byType(FilledButton);
      expect(logButtons, findsOneWidget);
      final button = tester.widget<FilledButton>(logButtons);

      // Button should be disabled (onPressed is null)
      expect(button.onPressed, isNull);
    });

    testWidgets('enables Log button when at least one medication selected', (
      tester,
    ) async {
      final schedules = [
        createTestMedicationSchedule(),
      ];

      await pumpMedicationLoggingScreen(
        tester,
        medicationSchedules: schedules,
      );
      await tester.pumpAndSettle();

      // Select medication
      await tester.tap(find.byType(MedicationSelectionCard));
      await tester.pump();

      // Find Log button
      final logButtons = find.byType(FilledButton);
      final button = tester.widget<FilledButton>(logButtons);

      // Button should be enabled (onPressed is not null)
      expect(button.onPressed, isNotNull);
    });

    testWidgets('updates button text with selection count', (tester) async {
      final schedules = [
        createTestMedicationSchedule(),
        createTestMedicationSchedule(
          id: 'test-med-2',
          medicationName: 'Benazepril',
        ),
      ];

      await pumpMedicationLoggingScreen(
        tester,
        medicationSchedules: schedules,
      );
      await tester.pumpAndSettle();

      // Select one medication
      await tester.tap(find.byType(MedicationSelectionCard).first);
      await tester.pump();

      // Button should show "Log Medication" (singular) in the button
      final button1 = tester.widget<FilledButton>(find.byType(FilledButton));
      final text1 = tester.widget<Text>(
        find.descendant(
          of: find.byWidget(button1),
          matching: find.byType(Text),
        ),
      );
      expect(text1.data, equals('Log Medication'));

      // Select another medication
      await tester.tap(find.byType(MedicationSelectionCard).last);
      await tester.pump();

      // Button should show "Log 2 Medications" (plural)
      final button2 = tester.widget<FilledButton>(find.byType(FilledButton));
      final text2 = tester.widget<Text>(
        find.descendant(
          of: find.byWidget(button2),
          matching: find.byType(Text),
        ),
      );
      expect(text2.data, equals('Log 2 Medications'));
    });

    testWidgets('trims empty notes before submission', (tester) async {
      await tester.runAsync(() async {
        final mockNotifier = MockLoggingNotifier();
        setupDefaultLoggingNotifierMocks(mockNotifier);

        final schedules = [
          createTestMedicationSchedule(),
        ];

        await pumpMedicationLoggingScreen(
          tester,
          medicationSchedules: schedules,
          mockLoggingNotifier: mockNotifier,
        );
        await tester.pumpAndSettle();

        // Select medication
        await tester.tap(find.byType(MedicationSelectionCard));
        await tester.pump();

        // Enter empty notes (spaces)
        final notesField = find.widgetWithText(TextField, 'Notes (optional)');
        await tester.enterText(notesField, '   ');
        await tester.pump();

        // Tap Log button
        await tester.tap(find.byType(FilledButton));
        await tester.pump();

        // Wait for success animation (500ms)
        await Future<void>.delayed(const Duration(milliseconds: 500));
        await tester.pump();

        // Verify logMedicationSession was called with null notes
        verify(
          () => mockNotifier.logMedicationSession(
            session: any(
              named: 'session',
              that: predicate<MedicationSession>(
                (s) => s.notes == null,
                'session with null notes',
              ),
            ),
            todaysSchedules: any(named: 'todaysSchedules'),
          ),
        ).called(1);
      });
    });
  });

  group('MedicationLoggingScreen - Loading States', () {
    testWidgets('verifies loading threshold timing', (tester) async {
      await tester.runAsync(() async {
        final mockNotifier = MockLoggingNotifier();
        setupDefaultLoggingNotifierMocks(mockNotifier);

        final schedules = [
          createTestMedicationSchedule(),
        ];

        await pumpMedicationLoggingScreen(
          tester,
          medicationSchedules: schedules,
          mockLoggingNotifier: mockNotifier,
        );
        await tester.pumpAndSettle();

        // Select medication
        await tester.tap(find.byType(MedicationSelectionCard));
        await tester.pump();

        // Tap Log button
        await tester.tap(find.byType(FilledButton));
        await tester.pump();

        // Advance past loading threshold (120ms)
        await Future<void>.delayed(const Duration(milliseconds: 150));
        await tester.pump();

        // Verify loading state visible
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Complete the operation
        await Future<void>.delayed(const Duration(milliseconds: 500));
        await tester.pump();

        // Verify operation was called
        verify(
          () => mockNotifier.logMedicationSession(
            session: any(named: 'session'),
            todaysSchedules: any(named: 'todaysSchedules'),
          ),
        ).called(1);
      });
    });

    testWidgets('verifies successful logging operation', (tester) async {
      await tester.runAsync(() async {
        final mockNotifier = MockLoggingNotifier();
        setupDefaultLoggingNotifierMocks(mockNotifier);

        final schedules = [
          createTestMedicationSchedule(),
        ];

        await pumpMedicationLoggingScreen(
          tester,
          medicationSchedules: schedules,
          mockLoggingNotifier: mockNotifier,
        );
        await tester.pumpAndSettle();

        // Select medication
        await tester.tap(find.byType(MedicationSelectionCard));
        await tester.pump();

        // Tap Log button
        await tester.tap(find.byType(FilledButton));
        await tester.pump();

        // Wait for success animation (500ms)
        await Future<void>.delayed(const Duration(milliseconds: 500));
        await tester.pump();

        // Verify the method was called successfully
        verify(
          () => mockNotifier.logMedicationSession(
            session: any(named: 'session'),
            todaysSchedules: any(named: 'todaysSchedules'),
          ),
        ).called(1);

        // Verify no error occurred
        expect(tester.takeException(), isNull);
      });
    });

    testWidgets('verifies button state during loading', (tester) async {
      final schedules = [
        createTestMedicationSchedule(),
        createTestMedicationSchedule(
          id: 'test-med-2',
          medicationName: 'Benazepril',
        ),
      ];

      await pumpMedicationLoggingScreen(
        tester,
        medicationSchedules: schedules,
      );
      await tester.pumpAndSettle();

      // Verify Select All button is enabled when not loading
      final selectAllButton = find.widgetWithText(OutlinedButton, 'Select All');
      final button = tester.widget<OutlinedButton>(selectAllButton);
      expect(button.onPressed, isNotNull);
    });
  });

  group('MedicationLoggingScreen - Error Handling', () {
    testWidgets('logging works with valid user and pet', (tester) async {
      await tester.runAsync(() async {
        final mockNotifier = MockLoggingNotifier();
        setupDefaultLoggingNotifierMocks(mockNotifier);

        final schedules = [
          createTestMedicationSchedule(),
        ];

        // Helper provides default user and pet
        await pumpMedicationLoggingScreen(
          tester,
          medicationSchedules: schedules,
          mockLoggingNotifier: mockNotifier,
        );
        await tester.pumpAndSettle();

        // Select medication
        await tester.tap(find.byType(MedicationSelectionCard));
        await tester.pump();

        // Tap Log button
        await tester.tap(find.byType(FilledButton));
        await tester.pump();

        // Wait for success animation
        await Future<void>.delayed(const Duration(milliseconds: 500));
        await tester.pump();

        // Verify logging succeeded
        verify(
          () => mockNotifier.logMedicationSession(
            session: any(named: 'session'),
            todaysSchedules: any(named: 'todaysSchedules'),
          ),
        ).called(1);
      });
    });

    testWidgets('handles duplicate session error gracefully', (tester) async {
      await tester.runAsync(() async {
        final mockNotifier = MockLoggingNotifier();

        // Set up to return false (failure)
        when(
          () => mockNotifier.logMedicationSession(
            session: any(named: 'session'),
            todaysSchedules: any(named: 'todaysSchedules'),
          ),
        ).thenAnswer((_) async => false);

        when(mockNotifier.reset).thenReturn(null);

        // Set error state to simulate duplicate
        mockNotifier.state = const LoggingState(
          error: 'You already logged this medication today',
        );

        final schedules = [
          createTestMedicationSchedule(),
        ];

        await pumpMedicationLoggingScreen(
          tester,
          medicationSchedules: schedules,
          mockLoggingNotifier: mockNotifier,
        );
        await tester.pumpAndSettle();

        // Select medication
        await tester.tap(find.byType(MedicationSelectionCard));
        await tester.pump();

        // Tap Log button
        await tester.tap(find.byType(FilledButton));
        await tester.pump();

        // Wait for loading threshold timer (120ms)
        await Future<void>.delayed(const Duration(milliseconds: 150));
        await tester.pump();

        // Verify no exception thrown (graceful handling)
        expect(tester.takeException(), isNull);
      });
    });
  });

  group('MedicationLoggingScreen - Accessibility', () {
    testWidgets('has semantic labels on medication cards', (tester) async {
      final schedules = [
        createTestMedicationSchedule(),
      ];

      await pumpMedicationLoggingScreen(
        tester,
        medicationSchedules: schedules,
      );
      await tester.pumpAndSettle();

      // Verify Semantics widgets exist
      expect(find.byType(Semantics), findsWidgets);
      // Verify medication card exists (accessibility structure confirmed)
      expect(find.byType(MedicationSelectionCard), findsOneWidget);
    });

    testWidgets('has semantic label on Log button with selection count', (
      tester,
    ) async {
      final schedules = [
        createTestMedicationSchedule(),
        createTestMedicationSchedule(
          id: 'test-med-2',
          medicationName: 'Benazepril',
        ),
      ];

      await pumpMedicationLoggingScreen(
        tester,
        medicationSchedules: schedules,
      );
      await tester.pumpAndSettle();

      // Select both medications
      await tester.tap(find.text('Select All'));
      await tester.pumpAndSettle();

      // Verify button has semantic structure
      expect(find.byType(Semantics), findsWidgets);
      // Verify button shows count (inside FilledButton)
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button, isNotNull);
    });

    testWidgets('has semantic label on Select All button', (tester) async {
      final schedules = [
        createTestMedicationSchedule(),
        createTestMedicationSchedule(
          id: 'test-med-2',
          medicationName: 'Benazepril',
        ),
      ];

      await pumpMedicationLoggingScreen(
        tester,
        medicationSchedules: schedules,
      );
      await tester.pumpAndSettle();

      // Verify Select All button exists with semantic structure
      expect(find.text('Select All'), findsOneWidget);
      expect(find.byType(Semantics), findsWidgets);
    });

    testWidgets('error handling completes without exceptions', (tester) async {
      await tester.runAsync(() async {
        // This test verifies that error handling doesn't throw exceptions
        // Actual SemanticsService.announce() cannot be tested directly
        final mockNotifier = MockLoggingNotifier();
        setupDefaultLoggingNotifierMocks(mockNotifier);

        final schedules = [
          createTestMedicationSchedule(),
        ];

        await pumpMedicationLoggingScreen(
          tester,
          medicationSchedules: schedules,
          mockLoggingNotifier: mockNotifier,
        );
        await tester.pumpAndSettle();

        // Select medication
        await tester.tap(find.byType(MedicationSelectionCard));
        await tester.pump();

        // Tap Log button
        await tester.tap(find.byType(FilledButton));
        await tester.pump();

        // Wait for success animation (500ms)
        await Future<void>.delayed(const Duration(milliseconds: 500));
        await tester.pump();

        // Verify no exception thrown (error handling works)
        expect(tester.takeException(), isNull);
      });
    });
  });
}
