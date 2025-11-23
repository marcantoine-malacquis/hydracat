import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/shared/widgets/dialogs/hydra_dialog.dart';

void main() {
  group('HydraDialog', () {
    testWidgets('shows Material Dialog on Android', (tester) async {
      final testWidget = MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (context) => const HydraDialog(
                      child: Text('Test Content'),
                    ),
                  );
                },
                child: const Text('Show Dialog'),
              );
            },
          ),
        ),
      );

      await tester.pumpWidget(testWidget);
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify Material Dialog is shown
      expect(find.byType(Dialog), findsOneWidget);
      expect(find.byType(CupertinoPopupSurface), findsNothing);
      expect(find.text('Test Content'), findsOneWidget);
    });

    testWidgets('shows CupertinoPopupSurface on iOS', (tester) async {
      final testWidget = MaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (context) => const HydraDialog(
                      child: Text('Test Content'),
                    ),
                  );
                },
                child: const Text('Show Dialog'),
              );
            },
          ),
        ),
      );

      await tester.pumpWidget(testWidget);
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify CupertinoPopupSurface is shown
      expect(find.byType(CupertinoPopupSurface), findsOneWidget);
      expect(find.byType(Dialog), findsNothing);
      expect(find.text('Test Content'), findsOneWidget);
    });

    testWidgets('passes through child correctly', (tester) async {
      final testWidget = MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (context) => const HydraDialog(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Title'),
                          Text('Content'),
                        ],
                      ),
                    ),
                  );
                },
                child: const Text('Show Dialog'),
              );
            },
          ),
        ),
      );

      await tester.pumpWidget(testWidget);
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Title'), findsOneWidget);
      expect(find.text('Content'), findsOneWidget);
    });

    testWidgets('handles shape on Material (ignored on Cupertino)', (
      tester,
    ) async {
      final testWidget = MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (context) => HydraDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text('Test'),
                    ),
                  );
                },
                child: const Text('Show Dialog'),
              );
            },
          ),
        ),
      );

      await tester.pumpWidget(testWidget);
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Dialog should render with custom shape
      expect(find.byType(Dialog), findsOneWidget);
      expect(find.text('Test'), findsOneWidget);
    });

    testWidgets('handles insetPadding on both platforms', (tester) async {
      final testWidget = MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (context) => const HydraDialog(
                      insetPadding: EdgeInsets.all(20),
                      child: Text('Test'),
                    ),
                  );
                },
                child: const Text('Show Dialog'),
              );
            },
          ),
        ),
      );

      await tester.pumpWidget(testWidget);
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Dialog should render with custom insetPadding
      expect(find.byType(Dialog), findsOneWidget);
      expect(find.text('Test'), findsOneWidget);
    });

    testWidgets('handles backgroundColor on Material (ignored on Cupertino)', (
      tester,
    ) async {
      final testWidget = MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (context) => const HydraDialog(
                      backgroundColor: Colors.red,
                      child: Text('Test'),
                    ),
                  );
                },
                child: const Text('Show Dialog'),
              );
            },
          ),
        ),
      );

      await tester.pumpWidget(testWidget);
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Dialog should render with custom backgroundColor
      expect(find.byType(Dialog), findsOneWidget);
      expect(find.text('Test'), findsOneWidget);
    });
  });

  group('showHydraDialog', () {
    testWidgets('calls showDialog on Material platforms', (tester) async {
      final testWidget = MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  showHydraDialog<void>(
                    context: context,
                    builder: (context) => const HydraDialog(
                      child: Text('Test'),
                    ),
                  );
                },
                child: const Text('Show Dialog'),
              );
            },
          ),
        ),
      );

      await tester.pumpWidget(testWidget);
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsOneWidget);
      expect(find.text('Test'), findsOneWidget);
    });

    testWidgets('calls showCupertinoDialog on iOS', (tester) async {
      final testWidget = MaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  showHydraDialog<void>(
                    context: context,
                    builder: (context) => const HydraDialog(
                      child: Text('Test'),
                    ),
                  );
                },
                child: const Text('Show Dialog'),
              );
            },
          ),
        ),
      );

      await tester.pumpWidget(testWidget);
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.byType(CupertinoPopupSurface), findsOneWidget);
      expect(find.text('Test'), findsOneWidget);
    });

    testWidgets('returns value from Navigator.pop', (tester) async {
      String? result;

      final testWidget = MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  result = await showHydraDialog<String>(
                    context: context,
                    builder: (context) => HydraDialog(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Test'),
                          ElevatedButton(
                            onPressed: () => Navigator.of(context).pop('OK'),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                child: const Text('Show Dialog'),
              );
            },
          ),
        ),
      );

      await tester.pumpWidget(testWidget);
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Test'), findsOneWidget);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(result, equals('OK'));
    });
  });
}
