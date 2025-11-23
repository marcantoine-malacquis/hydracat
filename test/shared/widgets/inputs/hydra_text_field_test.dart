import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/shared/widgets/inputs/hydra_text_field.dart';

void main() {
  group('HydraTextField', () {
    testWidgets('shows Material TextField on Android', (tester) async {
      final controller = TextEditingController(text: 'Test');

      final testWidget = MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: Scaffold(
          body: HydraTextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Test Field',
              hintText: 'Enter text',
            ),
          ),
        ),
      );

      await tester.pumpWidget(testWidget);

      // Verify Material TextField is shown
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(CupertinoTextField), findsNothing);
      expect(find.text('Test'), findsOneWidget);
    });

    testWidgets('shows CupertinoTextField on iOS', (tester) async {
      final controller = TextEditingController(text: 'Test');

      final testWidget = MaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS),
        home: Scaffold(
          body: HydraTextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Test Field',
              hintText: 'Enter text',
            ),
          ),
        ),
      );

      await tester.pumpWidget(testWidget);

      // Verify CupertinoTextField is shown
      expect(find.byType(CupertinoTextField), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Test'), findsOneWidget);
    });

    testWidgets('maps hintText to placeholder on iOS', (tester) async {
      final testWidget = MaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS),
        home: const Scaffold(
          body: HydraTextField(
            decoration: InputDecoration(
              hintText: 'Enter your name',
            ),
          ),
        ),
      );

      await tester.pumpWidget(testWidget);

      final cupertinoField = tester.widget<CupertinoTextField>(
        find.byType(CupertinoTextField),
      );
      expect(cupertinoField.placeholder, 'Enter your name');
    });

    testWidgets('maps suffixText to suffix widget on iOS', (tester) async {
      final testWidget = MaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS),
        home: const Scaffold(
          body: HydraTextField(
            decoration: InputDecoration(
              suffixText: 'kg',
            ),
          ),
        ),
      );

      await tester.pumpWidget(testWidget);

      final cupertinoField = tester.widget<CupertinoTextField>(
        find.byType(CupertinoTextField),
      );
      expect(cupertinoField.suffix, isNotNull);
    });

    testWidgets('shows error text separately on iOS', (tester) async {
      final testWidget = MaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS),
        home: const Scaffold(
          body: HydraTextField(
            decoration: InputDecoration(
              errorText: 'This field is required',
            ),
          ),
        ),
      );

      await tester.pumpWidget(testWidget);

      // Verify error text is shown below the field
      expect(find.text('This field is required'), findsOneWidget);
      expect(find.byType(CupertinoTextField), findsOneWidget);
    });

    testWidgets('passes through controller correctly', (tester) async {
      final controller = TextEditingController(text: 'Initial');

      final testWidget = MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: Scaffold(
          body: HydraTextField(
            controller: controller,
          ),
        ),
      );

      await tester.pumpWidget(testWidget);

      expect(find.text('Initial'), findsOneWidget);

      // Update controller
      controller.text = 'Updated';
      await tester.pump();

      expect(find.text('Updated'), findsOneWidget);
    });

    testWidgets('handles onChanged callback', (tester) async {
      String? changedValue;

      final testWidget = MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: Scaffold(
          body: HydraTextField(
            onChanged: (value) {
              changedValue = value;
            },
          ),
        ),
      );

      await tester.pumpWidget(testWidget);

      final textField = tester.widget<TextField>(find.byType(TextField));
      textField.controller?.text = 'Test';
      textField.onChanged?.call('Test');

      expect(changedValue, 'Test');
    });

    testWidgets('handles maxLength correctly', (tester) async {
      final controller = TextEditingController();

      final testWidget = MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: Scaffold(
          body: HydraTextField(
            controller: controller,
            maxLength: 10,
          ),
        ),
      );

      await tester.pumpWidget(testWidget);

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.maxLength, 10);
    });

    testWidgets('handles multiline correctly', (tester) async {
      final testWidget = MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: const Scaffold(
          body: HydraTextField(
            minLines: 3,
            maxLines: 5,
          ),
        ),
      );

      await tester.pumpWidget(testWidget);

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.minLines, 3);
      expect(textField.maxLines, 5);
    });

    testWidgets('handles inputFormatters correctly', (tester) async {
      final testWidget = MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: Scaffold(
          body: HydraTextField(
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
          ),
        ),
      );

      await tester.pumpWidget(testWidget);

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.inputFormatters, isNotEmpty);
    });
  });
}
