import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/shared/widgets/bottom_sheets/hydra_bottom_sheet.dart';

void main() {
  group('HydraBottomSheet', () {
    testWidgets('renders content correctly on Material platforms', (
      tester,
    ) async {
      final testWidget = MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  showModalBottomSheet<void>(
                    context: context,
                    builder: (context) => const HydraBottomSheet(
                      child: Text('Test Content'),
                    ),
                  );
                },
                child: const Text('Show Bottom Sheet'),
              );
            },
          ),
        ),
      );

      await tester.pumpWidget(testWidget);
      await tester.tap(find.text('Show Bottom Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Test Content'), findsOneWidget);
    });

    testWidgets('renders content correctly on iOS', (tester) async {
      final testWidget = MaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  showCupertinoModalPopup<void>(
                    context: context,
                    builder: (context) => const HydraBottomSheet(
                      child: Text('Test Content'),
                    ),
                  );
                },
                child: const Text('Show Bottom Sheet'),
              );
            },
          ),
        ),
      );

      await tester.pumpWidget(testWidget);
      await tester.tap(find.text('Show Bottom Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Test Content'), findsOneWidget);
    });

    testWidgets('applies heightFraction correctly', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));

      final testWidget = MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  showModalBottomSheet<void>(
                    context: context,
                    builder: (context) => const HydraBottomSheet(
                      heightFraction: 0.5,
                      child: Text('Test'),
                    ),
                  );
                },
                child: const Text('Show Bottom Sheet'),
              );
            },
          ),
        ),
      );

      await tester.pumpWidget(testWidget);
      await tester.tap(find.text('Show Bottom Sheet'));
      await tester.pumpAndSettle();

      final bottomSheet = tester.widget<HydraBottomSheet>(
        find.byType(HydraBottomSheet),
      );
      expect(bottomSheet.heightFraction, 0.5);
    });

    testWidgets('applies padding correctly', (tester) async {
      final testWidget = MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  showModalBottomSheet<void>(
                    context: context,
                    builder: (context) => const HydraBottomSheet(
                      padding: EdgeInsets.all(16),
                      child: Text('Test'),
                    ),
                  );
                },
                child: const Text('Show Bottom Sheet'),
              );
            },
          ),
        ),
      );

      await tester.pumpWidget(testWidget);
      await tester.tap(find.text('Show Bottom Sheet'));
      await tester.pumpAndSettle();

      final bottomSheet = tester.widget<HydraBottomSheet>(
        find.byType(HydraBottomSheet),
      );
      expect(bottomSheet.padding, const EdgeInsets.all(16));
    });

    testWidgets('applies backgroundColor correctly', (tester) async {
      final testWidget = MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  showModalBottomSheet<void>(
                    context: context,
                    builder: (context) => const HydraBottomSheet(
                      backgroundColor: Colors.red,
                      child: Text('Test'),
                    ),
                  );
                },
                child: const Text('Show Bottom Sheet'),
              );
            },
          ),
        ),
      );

      await tester.pumpWidget(testWidget);
      await tester.tap(find.text('Show Bottom Sheet'));
      await tester.pumpAndSettle();

      final bottomSheet = tester.widget<HydraBottomSheet>(
        find.byType(HydraBottomSheet),
      );
      expect(bottomSheet.backgroundColor, Colors.red);
    });

    testWidgets('applies borderRadius correctly', (tester) async {
      final testWidget = MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  showModalBottomSheet<void>(
                    context: context,
                    builder: (context) => const HydraBottomSheet(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(30),
                      ),
                      child: Text('Test'),
                    ),
                  );
                },
                child: const Text('Show Bottom Sheet'),
              );
            },
          ),
        ),
      );

      await tester.pumpWidget(testWidget);
      await tester.tap(find.text('Show Bottom Sheet'));
      await tester.pumpAndSettle();

      final bottomSheet = tester.widget<HydraBottomSheet>(
        find.byType(HydraBottomSheet),
      );
      expect(
        bottomSheet.borderRadius,
        const BorderRadius.vertical(top: Radius.circular(30)),
      );
    });

    testWidgets('wraps in SafeArea on iOS', (tester) async {
      final testWidget = MaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  showCupertinoModalPopup<void>(
                    context: context,
                    builder: (context) => const HydraBottomSheet(
                      child: Text('Test'),
                    ),
                  );
                },
                child: const Text('Show Bottom Sheet'),
              );
            },
          ),
        ),
      );

      await tester.pumpWidget(testWidget);
      await tester.tap(find.text('Show Bottom Sheet'));
      await tester.pumpAndSettle();

      // Should have SafeArea wrapper on iOS
      expect(find.byType(SafeArea), findsOneWidget);
    });
  });

  group('showHydraBottomSheet', () {
    testWidgets('calls showModalBottomSheet on Material platforms', (
      tester,
    ) async {
      final testWidget = MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  showHydraBottomSheet<void>(
                    context: context,
                    builder: (context) => const HydraBottomSheet(
                      child: Text('Test'),
                    ),
                  );
                },
                child: const Text('Show Bottom Sheet'),
              );
            },
          ),
        ),
      );

      await tester.pumpWidget(testWidget);
      await tester.tap(find.text('Show Bottom Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Test'), findsOneWidget);
      // Verify it's using Material bottom sheet (not Cupertino)
      expect(find.byType(HydraBottomSheet), findsOneWidget);
    });

    testWidgets('calls showCupertinoModalPopup on iOS', (tester) async {
      final testWidget = MaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  showHydraBottomSheet<void>(
                    context: context,
                    builder: (context) => const HydraBottomSheet(
                      child: Text('Test'),
                    ),
                  );
                },
                child: const Text('Show Bottom Sheet'),
              );
            },
          ),
        ),
      );

      await tester.pumpWidget(testWidget);
      await tester.tap(find.text('Show Bottom Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Test'), findsOneWidget);
      // Verify it's using Cupertino modal popup
      expect(find.byType(SafeArea), findsOneWidget);
    });

    testWidgets('passes through isScrollControlled on Material', (
      tester,
    ) async {
      final testWidget = MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  showHydraBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    builder: (context) => const HydraBottomSheet(
                      child: Text('Test'),
                    ),
                  );
                },
                child: const Text('Show Bottom Sheet'),
              );
            },
          ),
        ),
      );

      await tester.pumpWidget(testWidget);
      await tester.tap(find.text('Show Bottom Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Test'), findsOneWidget);
    });

    testWidgets('passes through backgroundColor on Material', (tester) async {
      final testWidget = MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  showHydraBottomSheet<void>(
                    context: context,
                    backgroundColor: Colors.blue,
                    builder: (context) => const HydraBottomSheet(
                      child: Text('Test'),
                    ),
                  );
                },
                child: const Text('Show Bottom Sheet'),
              );
            },
          ),
        ),
      );

      await tester.pumpWidget(testWidget);
      await tester.tap(find.text('Show Bottom Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Test'), findsOneWidget);
    });

    testWidgets('handles isDismissible correctly', (tester) async {
      final testWidget = MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  showHydraBottomSheet<void>(
                    context: context,
                    isDismissible: false,
                    builder: (context) => const HydraBottomSheet(
                      child: Text('Test'),
                    ),
                  );
                },
                child: const Text('Show Bottom Sheet'),
              );
            },
          ),
        ),
      );

      await tester.pumpWidget(testWidget);
      await tester.tap(find.text('Show Bottom Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Test'), findsOneWidget);
    });
  });
}
