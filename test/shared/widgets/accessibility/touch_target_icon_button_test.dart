import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/core/constants/app_accessibility.dart';
import 'package:hydracat/shared/widgets/accessibility/touch_target_icon_button.dart';

void main() {
  group('TouchTargetIconButton', () {
    testWidgets('renders icon button with icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TouchTargetIconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.edit), findsOneWidget);
      expect(find.byType(IconButton), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TouchTargetIconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(TouchTargetIconButton));
      await tester.pumpAndSettle();

      expect(pressed, isTrue);
    });

    testWidgets('enforces minimum touch target constraints', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TouchTargetIconButton(
              icon: const Icon(Icons.edit, size: 16),
              onPressed: () {},
            ),
          ),
        ),
      );

      final iconButton = tester.widget<IconButton>(
        find.byType(IconButton),
      );

      expect(
        iconButton.constraints?.minWidth,
        equals(AppAccessibility.minTouchTarget),
      );
      expect(
        iconButton.constraints?.minHeight,
        equals(AppAccessibility.minTouchTarget),
      );
    });

    testWidgets('displays tooltip', (tester) async {
      const tooltip = 'Edit item';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TouchTargetIconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {},
              tooltip: tooltip,
            ),
          ),
        ),
      );

      expect(find.byTooltip(tooltip), findsOneWidget);
    });

    testWidgets('adds semantic label', (tester) async {
      const semanticLabel = 'Edit medication';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TouchTargetIconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {},
              semanticLabel: semanticLabel,
            ),
          ),
        ),
      );

      expect(find.bySemanticsLabel(semanticLabel), findsOneWidget);
    });

    testWidgets('uses tooltip as semantic label when not provided',
        (tester) async {
      const tooltip = 'Edit item';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TouchTargetIconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {},
              tooltip: tooltip,
            ),
          ),
        ),
      );

      expect(find.bySemanticsLabel(tooltip), findsOneWidget);
    });

    testWidgets('respects icon color', (tester) async {
      const iconColor = Colors.red;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TouchTargetIconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {},
              color: iconColor,
            ),
          ),
        ),
      );

      final iconButton = tester.widget<IconButton>(
        find.byType(IconButton),
      );

      expect(iconButton.color, equals(iconColor));
    });

    testWidgets('respects icon size', (tester) async {
      const iconSize = 24.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TouchTargetIconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {},
              iconSize: iconSize,
            ),
          ),
        ),
      );

      final iconButton = tester.widget<IconButton>(
        find.byType(IconButton),
      );

      expect(iconButton.iconSize, equals(iconSize));
    });

    testWidgets('disables button when onPressed is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TouchTargetIconButton(
              icon: Icon(Icons.edit),
              onPressed: null,
            ),
          ),
        ),
      );

      final iconButton = tester.widget<IconButton>(
        find.byType(IconButton),
      );

      expect(iconButton.onPressed, isNull);
    });

    testWidgets('actual rendered size meets minimum', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TouchTargetIconButton(
              icon: const Icon(Icons.edit, size: 16),
              onPressed: () {},
            ),
          ),
        ),
      );

      final size = tester.getSize(find.byType(TouchTargetIconButton));

      expect(
        size.width,
        greaterThanOrEqualTo(AppAccessibility.minTouchTarget),
      );
      expect(
        size.height,
        greaterThanOrEqualTo(AppAccessibility.minTouchTarget),
      );
    });

    testWidgets('respects visual density', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TouchTargetIconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {},
              visualDensity: VisualDensity.compact,
            ),
          ),
        ),
      );

      final iconButton = tester.widget<IconButton>(
        find.byType(IconButton),
      );

      expect(iconButton.visualDensity, equals(VisualDensity.compact));
    });

    testWidgets('applies custom padding', (tester) async {
      const customPadding = EdgeInsets.all(8);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TouchTargetIconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {},
              padding: customPadding,
            ),
          ),
        ),
      );

      final iconButton = tester.widget<IconButton>(
        find.byType(IconButton),
      );

      expect(iconButton.padding, equals(customPadding));
    });

    testWidgets('applies splash radius', (tester) async {
      const splashRadius = 20.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TouchTargetIconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {},
              splashRadius: splashRadius,
            ),
          ),
        ),
      );

      final iconButton = tester.widget<IconButton>(
        find.byType(IconButton),
      );

      expect(iconButton.splashRadius, equals(splashRadius));
    });
  });
}
