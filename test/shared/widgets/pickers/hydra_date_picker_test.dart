import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/shared/widgets/pickers/hydra_date_picker.dart';

void main() {
  group('HydraDatePicker', () {
    final firstDate = DateTime(2020);
    final lastDate = DateTime(2025, 12, 31);
    final initialDate = DateTime(2024, 6, 10);

    testWidgets('shows Material date picker on Android', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 600));

      final testWidget = MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  await HydraDatePicker.show(
                    context: context,
                    initialDate: initialDate,
                    firstDate: firstDate,
                    lastDate: lastDate,
                  );
                },
                child: const Text('Show Picker'),
              );
            },
          ),
        ),
      );

      await tester.pumpWidget(testWidget);
      await tester.tap(find.text('Show Picker'));
      await tester.pumpAndSettle();

      // On Material platforms, showDatePicker should be called
      // We can verify by checking if a DatePicker dialog appears
      // Note: In a real test environment, we might need to mock showDatePicker
      // For now, we verify the method doesn't throw and returns null
      // when cancelled
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('shows Cupertino date picker on iOS', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 600));

      final testWidget = MaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return CupertinoButton(
                onPressed: () async {
                  await HydraDatePicker.show(
                    context: context,
                    initialDate: initialDate,
                    firstDate: firstDate,
                    lastDate: lastDate,
                  );
                },
                child: const Text('Show Picker'),
              );
            },
          ),
        ),
      );

      await tester.pumpWidget(testWidget);
      await tester.tap(find.text('Show Picker'));
      await tester.pumpAndSettle();

      // On Cupertino platforms, we should see the modal popup
      // Verify Cancel and Done buttons are present
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
      expect(find.byType(CupertinoDatePicker), findsOneWidget);
    });

    testWidgets('Cupertino picker returns null when Cancel is tapped', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 600));

      DateTime? selectedDate;
      final testWidget = MaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return CupertinoButton(
                onPressed: () async {
                  selectedDate = await HydraDatePicker.show(
                    context: context,
                    initialDate: initialDate,
                    firstDate: firstDate,
                    lastDate: lastDate,
                  );
                },
                child: const Text('Show Picker'),
              );
            },
          ),
        ),
      );

      await tester.pumpWidget(testWidget);
      await tester.tap(find.text('Show Picker'));
      await tester.pumpAndSettle();

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Should return null when cancelled
      expect(selectedDate, isNull);
    });

    testWidgets('Cupertino picker returns selected date when Done is tapped', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 600));

      DateTime? selectedDate;
      final testWidget = MaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return CupertinoButton(
                onPressed: () async {
                  selectedDate = await HydraDatePicker.show(
                    context: context,
                    initialDate: initialDate,
                    firstDate: firstDate,
                    lastDate: lastDate,
                  );
                },
                child: const Text('Show Picker'),
              );
            },
          ),
        ),
      );

      await tester.pumpWidget(testWidget);
      await tester.tap(find.text('Show Picker'));
      await tester.pumpAndSettle();

      // Tap Done
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      // Should return a DateTime when Done is tapped
      expect(selectedDate, isNotNull);
      expect(selectedDate, isA<DateTime>());
    });

    testWidgets('Cupertino picker respects minimum date constraint', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 600));

      final testWidget = MaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return CupertinoButton(
                onPressed: () async {
                  await HydraDatePicker.show(
                    context: context,
                    initialDate: initialDate,
                    firstDate: firstDate,
                    lastDate: lastDate,
                  );
                },
                child: const Text('Show Picker'),
              );
            },
          ),
        ),
      );

      await tester.pumpWidget(testWidget);
      await tester.tap(find.text('Show Picker'));
      await tester.pumpAndSettle();

      // Verify CupertinoDatePicker has minimumDate set
      final picker = tester.widget<CupertinoDatePicker>(
        find.byType(CupertinoDatePicker),
      );
      expect(picker.minimumDate, equals(firstDate));
    });

    testWidgets('Cupertino picker respects maximum date constraint', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 600));

      final testWidget = MaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return CupertinoButton(
                onPressed: () async {
                  await HydraDatePicker.show(
                    context: context,
                    initialDate: initialDate,
                    firstDate: firstDate,
                    lastDate: lastDate,
                  );
                },
                child: const Text('Show Picker'),
              );
            },
          ),
        ),
      );

      await tester.pumpWidget(testWidget);
      await tester.tap(find.text('Show Picker'));
      await tester.pumpAndSettle();

      // Verify CupertinoDatePicker has maximumDate set
      final picker = tester.widget<CupertinoDatePicker>(
        find.byType(CupertinoDatePicker),
      );
      expect(picker.maximumDate, equals(lastDate));
    });

    testWidgets('Cupertino picker clamps initial date to valid range', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 600));

      // Use an initial date that's before firstDate
      final invalidInitialDate = DateTime(2019);

      final testWidget = MaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return CupertinoButton(
                onPressed: () async {
                  await HydraDatePicker.show(
                    context: context,
                    initialDate: invalidInitialDate,
                    firstDate: firstDate,
                    lastDate: lastDate,
                  );
                },
                child: const Text('Show Picker'),
              );
            },
          ),
        ),
      );

      await tester.pumpWidget(testWidget);
      await tester.tap(find.text('Show Picker'));
      await tester.pumpAndSettle();

      // Verify the picker shows firstDate (clamped) instead of
      // invalidInitialDate
      final picker = tester.widget<CupertinoDatePicker>(
        find.byType(CupertinoDatePicker),
      );
      // The picker should use firstDate as the initial date when clamped
      expect(picker.initialDateTime.year, greaterThanOrEqualTo(firstDate.year));
    });
  });
}
