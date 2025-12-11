import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/features/onboarding/models/treatment_data.dart';
import 'package:hydracat/features/onboarding/screens/add_medication_bottom_sheet.dart';
import 'package:hydracat/features/onboarding/screens/add_medication_screen.dart';

void main() {
  group('AddMedicationBottomSheet frequency selector (HydraList)', () {
    testWidgets('selects new frequency and shows check on iOS', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.iOS),
          home: const Scaffold(
            body: AddMedicationBottomSheet(),
          ),
        ),
      );

      // Initial selection checkmark exists.
      expect(
        find.byIcon(CupertinoIcons.check_mark_circled_solid),
        findsOneWidget,
      );

      // Tap a different frequency.
      await tester.tap(find.text(TreatmentFrequency.thriceDaily.displayName));
      await tester.pumpAndSettle();

      // Checkmark moves to the selected row.
      final check = find.byIcon(CupertinoIcons.check_mark_circled_solid);
      expect(check, findsOneWidget);
      final selectedTile = find.ancestor(
        of: check,
        matching: find.byType(CupertinoListTile),
      );
      expect(
        find.descendant(
          of: selectedTile,
          matching: find.text(TreatmentFrequency.thriceDaily.displayName),
        ),
        findsOneWidget,
      );
    });
  });

  group('AddMedicationScreen frequency selector (HydraList)', () {
    testWidgets('updates selected frequency label on tap', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AddMedicationScreen(),
          ),
        ),
      );

      expect(find.textContaining('Selected: Once daily'), findsOneWidget);

      await tester.tap(find.text(TreatmentFrequency.thriceDaily.displayName));
      await tester.pumpAndSettle();

      expect(find.textContaining('Selected: Thrice daily'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsWidgets);
    });
  });
}
