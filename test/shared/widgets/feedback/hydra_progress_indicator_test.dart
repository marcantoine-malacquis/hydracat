import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/shared/widgets/feedback/hydra_progress_indicator.dart';

void main() {
  group('HydraProgressIndicator', () {
    testWidgets('renders CircularProgressIndicator on Material platform', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HydraProgressIndicator(),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(CupertinoActivityIndicator), findsNothing);
    });

    testWidgets('renders CupertinoActivityIndicator on iOS platform', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.iOS),
          home: const Scaffold(
            body: HydraProgressIndicator(),
          ),
        ),
      );

      expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('renders LinearProgressIndicator on Material platform', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HydraProgressIndicator(
              type: HydraProgressIndicatorType.linear,
            ),
          ),
        ),
      );

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets(
      'renders CupertinoActivityIndicator for indeterminate linear type on iOS',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(platform: TargetPlatform.iOS),
            home: const Scaffold(
              body: HydraProgressIndicator(
                type: HydraProgressIndicatorType.linear,
              ),
            ),
          ),
        );

        // Indeterminate linear type on iOS falls back
        // to CupertinoActivityIndicator
        expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
        expect(find.byType(CupertinoLinearActivityIndicator), findsNothing);
        expect(find.byType(LinearProgressIndicator), findsNothing);
      },
    );

    testWidgets(
      'renders CupertinoLinearActivityIndicator for determinate linear type '
      'on iOS',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(platform: TargetPlatform.iOS),
            home: const Scaffold(
              body: HydraProgressIndicator(
                type: HydraProgressIndicatorType.linear,
                value: 0.75,
              ),
            ),
          ),
        );

        expect(find.byType(CupertinoLinearActivityIndicator), findsOneWidget);
        expect(find.byType(CupertinoActivityIndicator), findsNothing);
        expect(find.byType(LinearProgressIndicator), findsNothing);
      },
    );

    testWidgets('passes value to Material circular indicator', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HydraProgressIndicator(
              value: 0.5,
            ),
          ),
        ),
      );

      final indicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(indicator.value, 0.5);
    });

    testWidgets('passes value to Material linear indicator', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HydraProgressIndicator(
              type: HydraProgressIndicatorType.linear,
              value: 0.75,
            ),
          ),
        ),
      );

      final indicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(indicator.value, 0.75);
    });

    testWidgets('passes color to Material indicator', (
      WidgetTester tester,
    ) async {
      const testColor = Colors.red;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HydraProgressIndicator(
              color: testColor,
            ),
          ),
        ),
      );

      final indicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(indicator.color, testColor);
    });

    testWidgets('passes strokeWidth to Material circular indicator', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HydraProgressIndicator(
              strokeWidth: 6,
            ),
          ),
        ),
      );

      final indicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(indicator.strokeWidth, 6.0);
    });

    testWidgets('passes minHeight to Material linear indicator', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HydraProgressIndicator(
              type: HydraProgressIndicatorType.linear,
              minHeight: 8,
            ),
          ),
        ),
      );

      final indicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(indicator.minHeight, 8.0);
    });

    testWidgets('passes backgroundColor to Material indicator', (
      WidgetTester tester,
    ) async {
      const testColor = Colors.grey;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HydraProgressIndicator(
              backgroundColor: testColor,
            ),
          ),
        ),
      );

      final indicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(indicator.backgroundColor, testColor);
    });

    testWidgets('passes color to CupertinoActivityIndicator', (
      WidgetTester tester,
    ) async {
      const testColor = Colors.blue;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.iOS),
          home: const Scaffold(
            body: HydraProgressIndicator(
              color: testColor,
            ),
          ),
        ),
      );

      final indicator = tester.widget<CupertinoActivityIndicator>(
        find.byType(CupertinoActivityIndicator),
      );
      expect(indicator.color, testColor);
    });

    testWidgets('passes color to CupertinoLinearActivityIndicator', (
      WidgetTester tester,
    ) async {
      const testColor = Colors.green;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.iOS),
          home: const Scaffold(
            body: HydraProgressIndicator(
              type: HydraProgressIndicatorType.linear,
              value: 0.5,
              color: testColor,
            ),
          ),
        ),
      );

      final indicator = tester.widget<CupertinoLinearActivityIndicator>(
        find.byType(CupertinoLinearActivityIndicator),
      );
      expect(indicator.color, testColor);
    });

    testWidgets('passes minHeight to CupertinoLinearActivityIndicator', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.iOS),
          home: const Scaffold(
            body: HydraProgressIndicator(
              type: HydraProgressIndicatorType.linear,
              value: 0.5,
              minHeight: 8,
            ),
          ),
        ),
      );

      final indicator = tester.widget<CupertinoLinearActivityIndicator>(
        find.byType(CupertinoLinearActivityIndicator),
      );
      expect(indicator.height, 8.0);
    });

    testWidgets(
      'uses default height for CupertinoLinearActivityIndicator when '
      'minHeight is null',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(platform: TargetPlatform.iOS),
            home: const Scaffold(
              body: HydraProgressIndicator(
                type: HydraProgressIndicatorType.linear,
                value: 0.5,
              ),
            ),
          ),
        );

        final indicator = tester.widget<CupertinoLinearActivityIndicator>(
          find.byType(CupertinoLinearActivityIndicator),
        );
        expect(indicator.height, 4.5);
      },
    );

    testWidgets('passes value to CupertinoLinearActivityIndicator', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.iOS),
          home: const Scaffold(
            body: HydraProgressIndicator(
              type: HydraProgressIndicatorType.linear,
              value: 0.65,
            ),
          ),
        ),
      );

      final indicator = tester.widget<CupertinoLinearActivityIndicator>(
        find.byType(CupertinoLinearActivityIndicator),
      );
      expect(indicator.progress, 0.65);
    });

    testWidgets(
      'clamps value to valid range for CupertinoLinearActivityIndicator',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(platform: TargetPlatform.iOS),
            home: const Scaffold(
              body: HydraProgressIndicator(
                type: HydraProgressIndicatorType.linear,
                value: 1.5, // Out of range
              ),
            ),
          ),
        );

        final indicator = tester.widget<CupertinoLinearActivityIndicator>(
          find.byType(CupertinoLinearActivityIndicator),
        );
        expect(indicator.progress, 1.0); // Clamped to 1.0
      },
    );

    testWidgets('defaults to circular type', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HydraProgressIndicator(),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });
  });
}
