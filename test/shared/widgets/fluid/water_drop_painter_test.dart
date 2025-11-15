import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/shared/widgets/fluid/water_drop_painter.dart';

void main() {
  group('WaterDropWidget', () {
    testWidgets('renders with initial fill percentage', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WaterDropWidget(
              fillPercentage: 0.75,
              height: 220,
            ),
          ),
        ),
      );

      expect(find.byType(WaterDropWidget), findsOneWidget);
      expect(find.byType(CustomPaint), findsOneWidget);
    });

    testWidgets('shows completion badge when fillPercentage >= 1.0',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WaterDropWidget(
              fillPercentage: 1,
              height: 220,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check for completion badge (checkmark icon)
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('hides completion badge when fillPercentage < 1.0',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WaterDropWidget(
              fillPercentage: 0.5,
              height: 220,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Completion badge should not be visible
      expect(find.byIcon(Icons.check), findsNothing);
    });

    testWidgets('has semantic label for accessibility', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WaterDropWidget(
              fillPercentage: 0.75,
              height: 220,
            ),
          ),
        ),
      );

      // Find semantics by label pattern
      final semanticsFinder = find.bySemanticsLabel(
        RegExp('Water drop showing .* percent progress'),
      );

      expect(semanticsFinder, findsOneWidget);
    });

    testWidgets('calculates correct widget dimensions', (tester) async {
      const testHeight = 220.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: WaterDropWidget(
                fillPercentage: 0.5,
                height: testHeight,
              ),
            ),
          ),
        ),
      );

      final customPaint = tester.widget<CustomPaint>(
        find.byType(CustomPaint),
      );

      // Width should be height * 0.83
      const expectedWidth = testHeight * 0.83;

      expect(customPaint.size, isNotNull);
      expect(customPaint.size.width, equals(expectedWidth));
      expect(customPaint.size.height, equals(testHeight));
    });

    testWidgets('widget disposes cleanly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WaterDropWidget(
              fillPercentage: 0.75,
              height: 220,
            ),
          ),
        ),
      );

      // Widget should be present
      expect(find.byType(WaterDropWidget), findsOneWidget);

      // Remove widget from tree
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox.shrink(),
          ),
        ),
      );

      // Widget should be gone
      expect(find.byType(WaterDropWidget), findsNothing);

      // Should not throw any errors
    });
  });
}
