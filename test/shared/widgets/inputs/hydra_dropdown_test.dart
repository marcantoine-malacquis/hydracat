import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/shared/widgets/widgets.dart';

void main() {
  group('HydraDropdown', () {
    testWidgets('renders Material dropdown on Android', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            platform: TargetPlatform.android,
          ),
          home: Scaffold(
            body: HydraDropdown<String>(
              value: 'Option 1',
              items: const ['Option 1', 'Option 2', 'Option 3'],
              onChanged: (_) {},
              itemBuilder: Text.new,
              labelText: 'Select Option',
            ),
          ),
        ),
      );

      // Verify the dropdown is rendered
      expect(find.byType(HydraDropdown<String>), findsOneWidget);
      // Verify CustomDropdown is used internally on Material
      expect(find.text('Option 1'), findsWidgets);
      expect(find.text('Select Option'), findsWidgets);
    });

    testWidgets('renders Cupertino button on iOS', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            platform: TargetPlatform.iOS,
          ),
          home: Scaffold(
            body: HydraDropdown<String>(
              value: 'Option 1',
              items: const ['Option 1', 'Option 2', 'Option 3'],
              onChanged: (_) {},
              itemBuilder: Text.new,
              labelText: 'Select Option',
            ),
          ),
        ),
      );

      // Verify the dropdown is rendered
      expect(find.byType(HydraDropdown<String>), findsOneWidget);
      // Verify CupertinoButton is used on iOS
      expect(find.byType(CupertinoButton), findsOneWidget);
      expect(find.text('Option 1'), findsWidgets);
      expect(find.text('Select Option'), findsWidgets);
    });

    testWidgets('shows hint text when value is null on Material', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            platform: TargetPlatform.android,
          ),
          home: Scaffold(
            body: HydraDropdown<String?>(
              value: null,
              items: const ['Option 1', 'Option 2'],
              onChanged: (_) {},
              itemBuilder: (item) => Text(item ?? ''),
              hintText: 'Select an option',
            ),
          ),
        ),
      );

      expect(find.text('Select an option'), findsWidgets);
    });

    testWidgets('shows hint text when value is null on iOS', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            platform: TargetPlatform.iOS,
          ),
          home: Scaffold(
            body: HydraDropdown<String?>(
              value: null,
              items: const ['Option 1', 'Option 2'],
              onChanged: (_) {},
              itemBuilder: (item) => Text(item ?? ''),
              hintText: 'Select an option',
            ),
          ),
        ),
      );

      expect(find.text('Select an option'), findsWidgets);
    });

    testWidgets('opens bottom sheet on iOS when tapped', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            platform: TargetPlatform.iOS,
          ),
          home: Scaffold(
            body: HydraDropdown<String>(
              value: 'Option 1',
              items: const ['Option 1', 'Option 2', 'Option 3'],
              onChanged: (_) {},
              itemBuilder: Text.new,
              labelText: 'Select Option',
            ),
          ),
        ),
      );

      // Find and tap the CupertinoButton
      final button = find.byType(CupertinoButton);
      expect(button, findsOneWidget);
      await tester.tap(button);
      await tester.pumpAndSettle();

      // Verify bottom sheet is shown
      expect(find.byType(CupertinoListTile), findsWidgets);
      expect(find.text('Option 1'), findsWidgets);
      expect(find.text('Option 2'), findsWidgets);
      expect(find.text('Option 3'), findsWidgets);
    });

    testWidgets('calls onChanged when item is selected on iOS', (tester) async {
      String? selectedValue;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            platform: TargetPlatform.iOS,
          ),
          home: Scaffold(
            body: HydraDropdown<String>(
              value: 'Option 1',
              items: const ['Option 1', 'Option 2', 'Option 3'],
              onChanged: (value) {
                selectedValue = value;
              },
              itemBuilder: Text.new,
            ),
          ),
        ),
      );

      // Open the dropdown
      final button = find.byType(CupertinoButton);
      await tester.tap(button);
      await tester.pumpAndSettle();

      // Tap on Option 2
      final option2 = find.text('Option 2').last;
      await tester.tap(option2);
      await tester.pumpAndSettle();

      // Verify onChanged was called
      expect(selectedValue, 'Option 2');
    });

    testWidgets('respects enabled state on iOS', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            platform: TargetPlatform.iOS,
          ),
          home: Scaffold(
            body: HydraDropdown<String>(
              value: 'Option 1',
              items: const ['Option 1', 'Option 2'],
              onChanged: (_) {},
              itemBuilder: Text.new,
              enabled: false,
            ),
          ),
        ),
      );

      // Find the CupertinoButton
      final button = find.byType(CupertinoButton);
      expect(button, findsOneWidget);

      // Verify button is disabled (onPressed is null)
      final buttonWidget = tester.widget<CupertinoButton>(button);
      expect(buttonWidget.onPressed, isNull);
    });

    testWidgets('respects width constraint', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            platform: TargetPlatform.android,
          ),
          home: Scaffold(
            body: HydraDropdown<String>(
              value: 'Option 1',
              items: const ['Option 1', 'Option 2'],
              onChanged: (_) {},
              itemBuilder: Text.new,
              width: 200,
            ),
          ),
        ),
      );

      // Find the SizedBox wrapper
      final sizedBox = find.byType(SizedBox);
      expect(sizedBox, findsWidgets);

      // Verify width constraint is applied
      final sizedBoxWidget = tester.widget<SizedBox>(
        find
            .ancestor(
              of: find.byType(HydraDropdown<String>),
              matching: find.byType(SizedBox),
            )
            .first,
      );
      expect(sizedBoxWidget.width, 200);
    });
  });
}
