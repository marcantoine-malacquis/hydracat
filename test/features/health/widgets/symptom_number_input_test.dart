import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/features/health/widgets/symptom_number_input.dart';

void main() {
  group('SymptomNumberInput', () {
    testWidgets('displays label and N/A checkbox', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SymptomNumberInput(
              label: 'Vomiting',
              value: null,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Vomiting'), findsOneWidget);
      expect(find.text('N/A'), findsOneWidget);
      expect(find.byType(Checkbox), findsOneWidget);
    });

    testWidgets('N/A checkbox toggles between null and default value', (
      tester,
    ) async {
      int? capturedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SymptomNumberInput(
              label: 'Vomiting',
              value: null,
              onChanged: (value) => capturedValue = value,
            ),
          ),
        ),
      );

      // Initially null, checkbox should be unchecked
      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, false);

      // Tap checkbox to enable (should set to 0)
      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      expect(capturedValue, 0);

      // Reset and test unchecking
      capturedValue = null;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SymptomNumberInput(
              label: 'Vomiting',
              value: 2,
              onChanged: (value) => capturedValue = value,
            ),
          ),
        ),
      );

      // Checkbox should be checked when value is not null
      final checkbox2 = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox2.value, true);

      // Tap checkbox to disable (should set to null)
      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      expect(capturedValue, null);
    });

    testWidgets('displays increment/decrement buttons when value is not null', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SymptomNumberInput(
              label: 'Vomiting',
              value: 2,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.remove_circle_outline), findsOneWidget);
      expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);
      expect(find.text('episodes'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('increment button increases value', (tester) async {
      int? capturedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SymptomNumberInput(
              label: 'Vomiting',
              value: 2,
              onChanged: (value) => capturedValue = value,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pump();

      expect(capturedValue, 3);
    });

    testWidgets('decrement button decreases value', (tester) async {
      int? capturedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SymptomNumberInput(
              label: 'Vomiting',
              value: 3,
              onChanged: (value) => capturedValue = value,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.remove_circle_outline));
      await tester.pump();

      expect(capturedValue, 2);
    });

    testWidgets('increment button is disabled at maxValue', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SymptomNumberInput(
              label: 'Vomiting',
              value: 10,
              maxValue: 10,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      final iconButtons = find.byType(IconButton);
      final incrementButton = tester
          .widgetList<IconButton>(iconButtons)
          .firstWhere(
            (button) =>
                button.icon is Icon &&
                (button.icon as Icon).icon == Icons.add_circle_outline,
          );
      expect(incrementButton.onPressed, isNull);
    });

    testWidgets('decrement button is disabled at minValue', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SymptomNumberInput(
              label: 'Vomiting',
              value: 0,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      final iconButtons = find.byType(IconButton);
      final decrementButton = tester
          .widgetList<IconButton>(iconButtons)
          .firstWhere(
            (button) =>
                button.icon is Icon &&
                (button.icon as Icon).icon == Icons.remove_circle_outline,
          );
      expect(decrementButton.onPressed, isNull);
    });

    testWidgets('text field accepts valid integer input', (tester) async {
      int? capturedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SymptomNumberInput(
              label: 'Vomiting',
              value: 2,
              onChanged: (value) => capturedValue = value,
            ),
          ),
        ),
      );

      final textField = tester.widget<TextFormField>(
        find.byType(TextFormField),
      );
      textField.onChanged?.call('5');
      await tester.pump();

      expect(capturedValue, 5);
    });

    testWidgets('text field ignores invalid input', (tester) async {
      int? capturedValue = 2;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SymptomNumberInput(
              label: 'Vomiting',
              value: 2,
              onChanged: (value) => capturedValue = value,
            ),
          ),
        ),
      );

      final textField = tester.widget<TextFormField>(
        find.byType(TextFormField),
      );
      // Try invalid input (out of range)
      textField.onChanged?.call('200');
      await tester.pump();

      // Value should not change
      expect(capturedValue, 2);
    });

    testWidgets('text field respects minValue and maxValue', (tester) async {
      int? capturedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SymptomNumberInput(
              label: 'Vomiting',
              value: 5,
              maxValue: 10,
              onChanged: (value) => capturedValue = value,
            ),
          ),
        ),
      );

      final textField = tester.widget<TextFormField>(
        find.byType(TextFormField),
      );

      // Try value below min
      textField.onChanged?.call('-1');
      await tester.pump();
      expect(capturedValue, isNull); // Should not change

      // Try value above max
      textField.onChanged?.call('15');
      await tester.pump();
      expect(capturedValue, isNull); // Should not change

      // Try valid value
      textField.onChanged?.call('7');
      await tester.pump();
      expect(capturedValue, 7);
    });

    testWidgets('widget is disabled when enabled is false', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SymptomNumberInput(
              label: 'Vomiting',
              value: 2,
              enabled: false,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.onChanged, isNull);

      final iconButtons = find.byType(IconButton);
      final incrementButton = tester
          .widgetList<IconButton>(iconButtons)
          .firstWhere(
            (button) =>
                button.icon is Icon &&
                (button.icon as Icon).icon == Icons.add_circle_outline,
          );
      expect(incrementButton.onPressed, isNull);

      final textField = tester.widget<TextFormField>(
        find.byType(TextFormField),
      );
      expect(textField.enabled, false);
    });
  });
}
