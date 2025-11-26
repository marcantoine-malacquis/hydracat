import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/features/health/models/symptom_raw_value.dart';
import 'package:hydracat/features/health/widgets/symptom_enum_input.dart';

void main() {
  group('SymptomEnumInput', () {
    testWidgets('displays label and N/A checkbox', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SymptomEnumInput<DiarrheaQuality>(
              label: 'Diarrhea',
              value: null,
              options: DiarrheaQuality.values,
              getLabel: (quality) => quality.label,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Diarrhea'), findsOneWidget);
      expect(find.text('N/A'), findsOneWidget);
      expect(find.byType(Checkbox), findsOneWidget);
    });

    testWidgets('N/A checkbox toggles between null and first option', (
      tester,
    ) async {
      DiarrheaQuality? capturedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SymptomEnumInput<DiarrheaQuality>(
              label: 'Diarrhea',
              value: null,
              options: DiarrheaQuality.values,
              getLabel: (quality) => quality.label,
              onChanged: (value) => capturedValue = value,
            ),
          ),
        ),
      );

      // Initially null, checkbox should be unchecked
      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, false);

      // Tap checkbox to enable (should set to first option)
      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      expect(capturedValue, DiarrheaQuality.normal);

      // Reset and test unchecking
      capturedValue = null;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SymptomEnumInput<DiarrheaQuality>(
              label: 'Diarrhea',
              value: DiarrheaQuality.soft,
              options: DiarrheaQuality.values,
              getLabel: (quality) => quality.label,
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

    testWidgets('displays segmented control when value is not null', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SymptomEnumInput<DiarrheaQuality>(
              label: 'Diarrhea',
              value: DiarrheaQuality.soft,
              options: DiarrheaQuality.values,
              getLabel: (quality) => quality.label,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      // Should find the segmented control
      expect(find.byType(SymptomEnumInput<DiarrheaQuality>), findsOneWidget);
      // Should find labels for all options
      expect(find.text('Normal'), findsOneWidget);
      expect(find.text('Soft'), findsOneWidget);
      expect(find.text('Loose'), findsOneWidget);
      expect(find.text('Watery / liquid'), findsOneWidget);
    });

    testWidgets('tapping segment triggers onChanged with correct enum', (
      tester,
    ) async {
      DiarrheaQuality? capturedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SymptomEnumInput<DiarrheaQuality>(
              label: 'Diarrhea',
              value: DiarrheaQuality.normal,
              options: DiarrheaQuality.values,
              getLabel: (quality) => quality.label,
              onChanged: (value) => capturedValue = value,
            ),
          ),
        ),
      );

      // Find and tap on "Loose" segment
      await tester.tap(find.text('Loose'));
      await tester.pump();

      // Verify the callback was called with the correct enum value
      expect(capturedValue, DiarrheaQuality.loose);
    });

    testWidgets('widget is disabled when enabled is false', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SymptomEnumInput<DiarrheaQuality>(
              label: 'Diarrhea',
              value: DiarrheaQuality.soft,
              options: DiarrheaQuality.values,
              getLabel: (quality) => quality.label,
              enabled: false,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.onChanged, isNull);

      // Should find AbsorbPointer when disabled (may be multiple, find
      // the one with absorbing: true)
      final absorbPointers = find.byType(AbsorbPointer);
      final absorbingPointer = tester
          .widgetList<AbsorbPointer>(absorbPointers)
          .firstWhere(
            (pointer) => pointer.absorbing == true,
          );
      expect(absorbingPointer.absorbing, true);
    });

    testWidgets('works with different enum types', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SymptomEnumInput<EnergyLevel>(
              label: 'Energy',
              value: EnergyLevel.normal,
              options: EnergyLevel.values,
              getLabel: (level) => level.label,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Energy'), findsOneWidget);
      expect(find.text('Normal energy'), findsOneWidget);
      expect(find.text('Slightly reduced energy'), findsOneWidget);
      expect(find.text('Low energy'), findsOneWidget);
      expect(find.text('Very low energy'), findsOneWidget);
    });

    testWidgets('hides segmented control when value is null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SymptomEnumInput<ConstipationLevel>(
              label: 'Constipation',
              value: null,
              options: ConstipationLevel.values,
              getLabel: (level) => level.label,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      // Should not find any segment labels when value is null
      expect(find.text('Normal stooling'), findsNothing);
      expect(find.text('Mild straining'), findsNothing);
    });
  });
}
