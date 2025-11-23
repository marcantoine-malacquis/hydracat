import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/shared/widgets/buttons/hydra_button.dart';

void main() {
  group('HydraButton', () {
    testWidgets('shows Material ElevatedButton on Android', (tester) async {
      final testWidget = MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: Scaffold(
          body: HydraButton(
            onPressed: () {},
            child: const Text('Test Button'),
          ),
        ),
      );

      await tester.pumpWidget(testWidget);

      // Verify Material ElevatedButton is shown
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.byType(CupertinoButton), findsNothing);
      expect(find.text('Test Button'), findsOneWidget);
    });

    testWidgets('shows CupertinoButton on iOS', (tester) async {
      final testWidget = MaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS),
        home: Scaffold(
          body: HydraButton(
            onPressed: () {},
            child: const Text('Test Button'),
          ),
        ),
      );

      await tester.pumpWidget(testWidget);

      // Verify CupertinoButton is shown
      expect(find.byType(CupertinoButton), findsOneWidget);
      expect(find.byType(ElevatedButton), findsNothing);
      expect(find.text('Test Button'), findsOneWidget);
    });

    testWidgets('shows CupertinoButton on macOS', (tester) async {
      final testWidget = MaterialApp(
        theme: ThemeData(platform: TargetPlatform.macOS),
        home: Scaffold(
          body: HydraButton(
            onPressed: () {},
            child: const Text('Test Button'),
          ),
        ),
      );

      await tester.pumpWidget(testWidget);

      // Verify CupertinoButton is shown
      expect(find.byType(CupertinoButton), findsOneWidget);
      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets('primary variant uses CupertinoButton.filled on iOS', (
      tester,
    ) async {
      final testWidget = MaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS),
        home: Scaffold(
          body: HydraButton(
            onPressed: () {},
            child: const Text('Primary'),
          ),
        ),
      );

      await tester.pumpWidget(testWidget);

      // Verify CupertinoButton is shown (filled variant)
      expect(find.byType(CupertinoButton), findsOneWidget);
      expect(find.text('Primary'), findsOneWidget);
    });

    testWidgets('secondary variant shows border on iOS', (tester) async {
      final testWidget = MaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS),
        home: Scaffold(
          body: HydraButton(
            onPressed: () {},
            variant: HydraButtonVariant.secondary,
            child: const Text('Secondary'),
          ),
        ),
      );

      await tester.pumpWidget(testWidget);

      // Verify CupertinoButton with Container decoration is shown
      expect(find.byType(CupertinoButton), findsOneWidget);
      expect(find.byType(Container), findsWidgets);
      expect(find.text('Secondary'), findsOneWidget);
    });

    testWidgets('text variant uses plain CupertinoButton on iOS', (
      tester,
    ) async {
      final testWidget = MaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS),
        home: Scaffold(
          body: HydraButton(
            onPressed: () {},
            variant: HydraButtonVariant.text,
            child: const Text('Text'),
          ),
        ),
      );

      await tester.pumpWidget(testWidget);

      // Verify plain CupertinoButton is shown
      expect(find.byType(CupertinoButton), findsOneWidget);
      expect(find.text('Text'), findsOneWidget);
    });

    testWidgets('respects isFullWidth property', (tester) async {
      final testWidget = MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: Scaffold(
          body: HydraButton(
            onPressed: () {},
            isFullWidth: true,
            child: const Text('Full Width'),
          ),
        ),
      );

      await tester.pumpWidget(testWidget);

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(sizedBox.width, double.infinity);
    });

    testWidgets('shows loading indicator when isLoading is true', (
      tester,
    ) async {
      final testWidget = MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: Scaffold(
          body: HydraButton(
            onPressed: () {},
            isLoading: true,
            child: const Text('Loading'),
          ),
        ),
      );

      await tester.pumpWidget(testWidget);

      // Verify loading indicator is shown
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading'), findsNothing);
    });

    testWidgets('disables button when onPressed is null', (tester) async {
      final testWidget = MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: const Scaffold(
          body: HydraButton(
            onPressed: null,
            child: Text('Disabled'),
          ),
        ),
      );

      await tester.pumpWidget(testWidget);

      // Verify button is disabled
      final elevatedButton = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton),
      );
      expect(elevatedButton.onPressed, isNull);
    });

    testWidgets('disables button when isLoading is true', (tester) async {
      final testWidget = MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: Scaffold(
          body: HydraButton(
            onPressed: () {},
            isLoading: true,
            child: const Text('Loading'),
          ),
        ),
      );

      await tester.pumpWidget(testWidget);

      // Verify button is disabled
      final elevatedButton = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton),
      );
      expect(elevatedButton.onPressed, isNull);
    });

    testWidgets('respects size property on Material', (tester) async {
      final testWidget = MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: Scaffold(
          body: HydraButton(
            onPressed: () {},
            size: HydraButtonSize.large,
            child: const Text('Large'),
          ),
        ),
      );

      await tester.pumpWidget(testWidget);

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(sizedBox.height, 54); // Large size min height
    });

    testWidgets('respects size property on Cupertino', (tester) async {
      final testWidget = MaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS),
        home: Scaffold(
          body: HydraButton(
            onPressed: () {},
            size: HydraButtonSize.small,
            child: const Text('Small'),
          ),
        ),
      );

      await tester.pumpWidget(testWidget);

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(sizedBox.height, 32); // Small size min height
    });
  });
}
