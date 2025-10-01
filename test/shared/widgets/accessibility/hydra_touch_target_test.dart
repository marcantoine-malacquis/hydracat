import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/core/constants/app_accessibility.dart';
import 'package:hydracat/shared/widgets/accessibility/hydra_touch_target.dart';

void main() {
  group('HydraTouchTarget', () {
    testWidgets('enforces minimum width constraint', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HydraTouchTarget(
              child: SizedBox(
                width: 10,
                height: 50,
              ),
            ),
          ),
        ),
      );

      final constrainedBox = tester.widget<ConstrainedBox>(
        find.descendant(
          of: find.byType(HydraTouchTarget),
          matching: find.byType(ConstrainedBox),
        ),
      );

      expect(
        constrainedBox.constraints.minWidth,
        equals(AppAccessibility.minTouchTarget),
      );
    });

    testWidgets('enforces minimum height constraint', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HydraTouchTarget(
              child: SizedBox(
                width: 50,
                height: 10,
              ),
            ),
          ),
        ),
      );

      final constrainedBox = tester.widget<ConstrainedBox>(
        find.descendant(
          of: find.byType(HydraTouchTarget),
          matching: find.byType(ConstrainedBox),
        ),
      );

      expect(
        constrainedBox.constraints.minHeight,
        equals(AppAccessibility.minTouchTarget),
      );
    });

    testWidgets('allows custom minimum size', (tester) async {
      const customSize = 60.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HydraTouchTarget(
              minSize: customSize,
              child: SizedBox(
                width: 10,
                height: 10,
              ),
            ),
          ),
        ),
      );

      final constrainedBox = tester.widget<ConstrainedBox>(
        find.descendant(
          of: find.byType(HydraTouchTarget),
          matching: find.byType(ConstrainedBox),
        ),
      );

      expect(constrainedBox.constraints.minWidth, equals(customSize));
      expect(constrainedBox.constraints.minHeight, equals(customSize));
    });

    testWidgets('respects alignment property', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HydraTouchTarget(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 10,
                height: 10,
              ),
            ),
          ),
        ),
      );

      final align = tester.widget<Align>(
        find.byType(Align),
      );

      expect(align.alignment, equals(Alignment.topLeft));
    });

    testWidgets('adds semantic label when provided', (tester) async {
      const semanticLabel = 'Test button';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HydraTouchTarget(
              semanticLabel: semanticLabel,
              child: SizedBox(
                width: 10,
                height: 10,
              ),
            ),
          ),
        ),
      );

      expect(find.bySemanticsLabel(semanticLabel), findsOneWidget);
    });

    testWidgets('does not add semantics when label is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HydraTouchTarget(
              child: SizedBox(
                width: 10,
                height: 10,
              ),
            ),
          ),
        ),
      );

      final semantics = find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.label != null,
      );

      expect(semantics, findsNothing);
    });

    testWidgets('marks as button in semantics', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HydraTouchTarget(
              semanticLabel: 'Test button',
              child: SizedBox(
                width: 10,
                height: 10,
              ),
            ),
          ),
        ),
      );

      final semantics = tester.widget<Semantics>(
        find.descendant(
          of: find.byType(HydraTouchTarget),
          matching: find.byType(Semantics),
        ),
      );

      expect(semantics.properties.button, isTrue);
    });

    testWidgets('excludes child semantics when requested', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HydraTouchTarget(
              semanticLabel: 'Override label',
              excludeSemantics: true,
              child: Text('Child text'),
            ),
          ),
        ),
      );

      final semantics = tester.widget<Semantics>(
        find.descendant(
          of: find.byType(HydraTouchTarget),
          matching: find.byType(Semantics),
        ),
      );

      expect(semantics.properties.label, equals('Override label'));
      expect(semantics.excludeSemantics, isTrue);
    });

    testWidgets('renders child widget', (tester) async {
      const testKey = Key('test-child');

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HydraTouchTarget(
              child: SizedBox(
                key: testKey,
                width: 10,
                height: 10,
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(testKey), findsOneWidget);
    });

    testWidgets('actual rendered size meets minimum', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HydraTouchTarget(
              child: SizedBox(
                width: 10,
                height: 10,
              ),
            ),
          ),
        ),
      );

      final size = tester.getSize(find.byType(HydraTouchTarget));

      expect(
        size.width,
        greaterThanOrEqualTo(AppAccessibility.minTouchTarget),
      );
      expect(
        size.height,
        greaterThanOrEqualTo(AppAccessibility.minTouchTarget),
      );
    });

    testWidgets('does not shrink large children', (tester) async {
      const largeSize = 100.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HydraTouchTarget(
              child: SizedBox(
                width: largeSize,
                height: largeSize,
              ),
            ),
          ),
        ),
      );

      final size = tester.getSize(find.byType(SizedBox));

      expect(size.width, equals(largeSize));
      expect(size.height, equals(largeSize));
    });
  });
}
