import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/features/health/models/symptom_raw_value.dart';
import 'package:hydracat/features/health/widgets/symptom_slider.dart';

void main() {
  group('SymptomSlider', () {
    testWidgets('shows label and N/A by default when value is null', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SymptomSlider<DiarrheaQuality>(
              label: 'Diarrhea',
              value: null,
              options: DiarrheaQuality.values,
              getLabel: _diarrheaLabel,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Diarrhea'), findsOneWidget);
      expect(find.text('N/A'), findsOneWidget);
    });

    testWidgets('moving slider off zero calls onChanged with first option', (
      tester,
    ) async {
      DiarrheaQuality? changedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SymptomSlider<DiarrheaQuality>(
              label: 'Diarrhea',
              value: null,
              options: DiarrheaQuality.values,
              getLabel: _diarrheaLabel,
              onChanged: (value) => changedValue = value,
            ),
          ),
        ),
      );

      // Drag the slider a bit to move away from N/A (index 0)
      final sliderFinder = find.byType(Slider);
      expect(sliderFinder, findsOneWidget);

      await tester.drag(sliderFinder, const Offset(50, 0));
      await tester.pumpAndSettle();

      expect(changedValue, isNotNull);
    });

    testWidgets('descriptor updates when value is non-null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SymptomSlider<DiarrheaQuality>(
              label: 'Diarrhea',
              value: DiarrheaQuality.soft,
              options: DiarrheaQuality.values,
              getLabel: _diarrheaLabel,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Soft'), findsOneWidget);
    });

    testWidgets('renders label, descriptor, and slider together', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SymptomSlider<DiarrheaQuality>(
              label: 'Long Symptom Label',
              value: null,
              options: DiarrheaQuality.values,
              getLabel: _diarrheaLabel,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      // Label and descriptor text are both present
      expect(find.text('Long Symptom Label'), findsOneWidget);
      expect(find.text('N/A'), findsOneWidget);
      // Slider is present in the layout
      expect(find.byType(Slider), findsOneWidget);
    });
  });
}

String _diarrheaLabel(DiarrheaQuality quality) => quality.label;
