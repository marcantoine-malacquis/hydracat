import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/shared/widgets/dialogs/hydra_alert_dialog.dart';

void main() {
  group('HydraAlertDialog', () {
    testWidgets('shows Material AlertDialog on Android', (tester) async {
      final testWidget = MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (context) => const HydraAlertDialog(
                      title: Text('Test Title'),
                      content: Text('Test Content'),
                      actions: [
                        TextButton(
                          onPressed: null,
                          child: Text('Cancel'),
                        ),
                      ],
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

      // Verify Material AlertDialog is shown
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.byType(CupertinoAlertDialog), findsNothing);
      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Test Content'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('shows CupertinoAlertDialog on iOS', (tester) async {
      final testWidget = MaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (context) => const HydraAlertDialog(
                      title: Text('Test Title'),
                      content: Text('Test Content'),
                      actions: [
                        TextButton(
                          onPressed: null,
                          child: Text('Cancel'),
                        ),
                      ],
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

      // Verify CupertinoAlertDialog is shown
      expect(find.byType(CupertinoAlertDialog), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Test Content'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('converts Material buttons to CupertinoDialogAction on iOS', (
      tester,
    ) async {
      final testWidget = MaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (context) => HydraAlertDialog(
                      title: const Text('Test'),
                      content: const Text('Content'),
                      actions: [
                        TextButton(
                          onPressed: () {},
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () {},
                          child: const Text('OK'),
                        ),
                      ],
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

      // Verify CupertinoDialogAction widgets are created
      expect(find.byType(CupertinoDialogAction), findsNWidgets(2));
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);
    });

    testWidgets('passes through title and content correctly', (tester) async {
      final testWidget = MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (context) => const HydraAlertDialog(
                      title: Text('My Title'),
                      content: Text('My Content'),
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

      expect(find.text('My Title'), findsOneWidget);
      expect(find.text('My Content'), findsOneWidget);
    });

    testWidgets('handles scrollable content on Material', (tester) async {
      final testWidget = MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (context) => const HydraAlertDialog(
                      title: Text('Test'),
                      scrollable: true,
                      content: Text('Long content'),
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

      // Verify SingleChildScrollView is present when scrollable is true
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('handles icon on Material (ignored on Cupertino)', (
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
                    builder: (context) => const HydraAlertDialog(
                      icon: Icon(Icons.warning),
                      title: Text('Test'),
                      content: Text('Content'),
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

      // Icon should be present in Material AlertDialog
      expect(find.byIcon(Icons.warning), findsOneWidget);
    });

    testWidgets('handles empty actions list', (tester) async {
      final testWidget = MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (context) => const HydraAlertDialog(
                      title: Text('Test'),
                      content: Text('Content'),
                      actions: [],
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

      // Dialog should still render without actions
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Test'), findsOneWidget);
    });
  });

  group('showHydraAlertDialog', () {
    testWidgets('calls showDialog on Material platforms', (tester) async {
      final testWidget = MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  showHydraAlertDialog<void>(
                    context: context,
                    builder: (context) => const HydraAlertDialog(
                      title: Text('Test'),
                      content: Text('Content'),
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

      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('calls showCupertinoDialog on iOS', (tester) async {
      final testWidget = MaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  showHydraAlertDialog<void>(
                    context: context,
                    builder: (context) => const HydraAlertDialog(
                      title: Text('Test'),
                      content: Text('Content'),
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

      expect(find.byType(CupertinoAlertDialog), findsOneWidget);
    });
  });
}
