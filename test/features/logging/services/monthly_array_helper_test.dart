import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/features/logging/services/monthly_array_helper.dart';

void main() {
  group('MonthlyArrayHelper.updateDailyArrayValue', () {
    group('Array Initialization', () {
      test('null array creates zero-filled array', () {
        final result = MonthlyArrayHelper.updateDailyArrayValue(
          currentArray: null,
          dayOfMonth: 5,
          monthLength: 31,
          newValue: 100,
        );

        expect(result.length, 31);
        expect(result[4], 100); // day 5 = index 4
        expect(result[0], 0);
        expect(result[30], 0);
      });

      test('empty array creates zero-filled array', () {
        final result = MonthlyArrayHelper.updateDailyArrayValue(
          currentArray: [],
          dayOfMonth: 1,
          monthLength: 28,
          newValue: 50,
        );

        expect(result.length, 28);
        expect(result[0], 50); // day 1 = index 0
        expect(result[27], 0);
      });
    });

    group('Array Resizing', () {
      test('short array (28) pads to 31 with zeros', () {
        final shortArray = List.filled(28, 10);

        final result = MonthlyArrayHelper.updateDailyArrayValue(
          currentArray: shortArray,
          dayOfMonth: 31,
          monthLength: 31,
          newValue: 200,
        );

        expect(result.length, 31);
        expect(result[30], 200); // day 31 = index 30
        expect(result[28], 0); // padded with zero
        expect(result[29], 0); // padded with zero
      });

      test('long array (31) truncates to 28', () {
        final longArray = List.generate(31, (i) => i + 1);

        final result = MonthlyArrayHelper.updateDailyArrayValue(
          currentArray: longArray,
          dayOfMonth: 15,
          monthLength: 28,
          newValue: 999,
        );

        expect(result.length, 28);
        expect(result[14], 999); // day 15 = index 14
        expect(result[27], 28); // last value preserved (1-indexed became 28)
      });

      test('correct length array not resized', () {
        final correctArray = List.filled(30, 5);

        final result = MonthlyArrayHelper.updateDailyArrayValue(
          currentArray: correctArray,
          dayOfMonth: 10,
          monthLength: 30,
          newValue: 150,
        );

        expect(result.length, 30);
        expect(result[9], 150); // day 10 = index 9
        expect(result[0], 5);
        expect(result[29], 5);
      });
    });

    group('Value Updates', () {
      test('day 1 updates index 0', () {
        final array = List.filled(31, 0);

        final result = MonthlyArrayHelper.updateDailyArrayValue(
          currentArray: array,
          dayOfMonth: 1,
          monthLength: 31,
          newValue: 500,
        );

        expect(result[0], 500);
        expect(result[1], 0);
      });

      test('day 15 updates index 14', () {
        final array = List.filled(31, 0);

        final result = MonthlyArrayHelper.updateDailyArrayValue(
          currentArray: array,
          dayOfMonth: 15,
          monthLength: 31,
          newValue: 300,
        );

        expect(result[14], 300);
        expect(result[13], 0);
        expect(result[15], 0);
      });

      test('day 31 updates index 30', () {
        final array = List.filled(31, 0);

        final result = MonthlyArrayHelper.updateDailyArrayValue(
          currentArray: array,
          dayOfMonth: 31,
          monthLength: 31,
          newValue: 250,
        );

        expect(result[30], 250);
        expect(result[29], 0);
      });

      test('preserves other values in array', () {
        final array = [100, 200, 300, 400, 500];

        final result = MonthlyArrayHelper.updateDailyArrayValue(
          currentArray: array,
          dayOfMonth: 3,
          monthLength: 5,
          newValue: 999,
        );

        expect(result[0], 100);
        expect(result[1], 200);
        expect(result[2], 999); // updated
        expect(result[3], 400);
        expect(result[4], 500);
      });
    });

    group('Bounds Clamping', () {
      test('dayOfMonth = 0 clamps to 1 (index 0)', () {
        final array = List.filled(31, 0);

        final result = MonthlyArrayHelper.updateDailyArrayValue(
          currentArray: array,
          dayOfMonth: 0,
          monthLength: 31,
          newValue: 100,
        );

        expect(result[0], 100);
      });

      test('dayOfMonth = 32 clamps to monthLength (31)', () {
        final array = List.filled(31, 0);

        final result = MonthlyArrayHelper.updateDailyArrayValue(
          currentArray: array,
          dayOfMonth: 32,
          monthLength: 31,
          newValue: 100,
        );

        expect(result[30], 100); // clamped to day 31 (index 30)
      });

      test('negative dayOfMonth clamps to 1', () {
        final array = List.filled(31, 0);

        final result = MonthlyArrayHelper.updateDailyArrayValue(
          currentArray: array,
          dayOfMonth: -5,
          monthLength: 31,
          newValue: 100,
        );

        expect(result[0], 100);
      });

      test('newValue = -100 clamps to 0', () {
        final array = List.filled(31, 0);

        final result = MonthlyArrayHelper.updateDailyArrayValue(
          currentArray: array,
          dayOfMonth: 10,
          monthLength: 31,
          newValue: -100,
        );

        expect(result[9], 0);
      });

      test('newValue = 6000 clamps to 5000', () {
        final array = List.filled(31, 0);

        final result = MonthlyArrayHelper.updateDailyArrayValue(
          currentArray: array,
          dayOfMonth: 10,
          monthLength: 31,
          newValue: 6000,
        );

        expect(result[9], 5000);
      });

      test('newValue at upper bound (5000) not clamped', () {
        final array = List.filled(31, 0);

        final result = MonthlyArrayHelper.updateDailyArrayValue(
          currentArray: array,
          dayOfMonth: 10,
          monthLength: 31,
          newValue: 5000,
        );

        expect(result[9], 5000);
      });

      test('newValue at lower bound (0) not clamped', () {
        final array = List.filled(31, 0);

        final result = MonthlyArrayHelper.updateDailyArrayValue(
          currentArray: array,
          dayOfMonth: 10,
          monthLength: 31,
          newValue: 0,
        );

        expect(result[9], 0);
      });

      test('supports custom max bounds (medication arrays)', () {
        final array = List.filled(31, 0);

        final result = MonthlyArrayHelper.updateDailyArrayValue(
          currentArray: array,
          dayOfMonth: 5,
          monthLength: 31,
          newValue: 25,
          maxValue: 10,
        );

        expect(result[4], 10);
      });
    });

    group('Month Length Variations', () {
      test('February leap year (29 days)', () {
        final array = List.filled(29, 0);

        final result = MonthlyArrayHelper.updateDailyArrayValue(
          currentArray: array,
          dayOfMonth: 29,
          monthLength: 29,
          newValue: 150,
        );

        expect(result.length, 29);
        expect(result[28], 150); // day 29 = index 28
      });

      test('February non-leap (28 days)', () {
        final array = List.filled(28, 0);

        final result = MonthlyArrayHelper.updateDailyArrayValue(
          currentArray: array,
          dayOfMonth: 28,
          monthLength: 28,
          newValue: 200,
        );

        expect(result.length, 28);
        expect(result[27], 200); // day 28 = index 27
      });

      test('30-day month (April, June, September, November)', () {
        final array = List.filled(30, 0);

        final result = MonthlyArrayHelper.updateDailyArrayValue(
          currentArray: array,
          dayOfMonth: 30,
          monthLength: 30,
          newValue: 300,
        );

        expect(result.length, 30);
        expect(result[29], 300); // day 30 = index 29
      });

      test('31-day month (Jan, Mar, May, Jul, Aug, Oct, Dec)', () {
        final array = List.filled(31, 0);

        final result = MonthlyArrayHelper.updateDailyArrayValue(
          currentArray: array,
          dayOfMonth: 31,
          monthLength: 31,
          newValue: 400,
        );

        expect(result.length, 31);
        expect(result[30], 400); // day 31 = index 30
      });
    });

    group('Edge Cases', () {
      test('updating same day multiple times', () {
        var array = List.filled(31, 0);

        // First update
        array = MonthlyArrayHelper.updateDailyArrayValue(
          currentArray: array,
          dayOfMonth: 10,
          monthLength: 31,
          newValue: 100,
        );
        expect(array[9], 100);

        // Second update (overwrite)
        array = MonthlyArrayHelper.updateDailyArrayValue(
          currentArray: array,
          dayOfMonth: 10,
          monthLength: 31,
          newValue: 250,
        );
        expect(array[9], 250);
      });

      test('updating different days preserves previous values', () {
        var array = List.filled(31, 0);

        array = MonthlyArrayHelper.updateDailyArrayValue(
          currentArray: array,
          dayOfMonth: 5,
          monthLength: 31,
          newValue: 100,
        );

        array = MonthlyArrayHelper.updateDailyArrayValue(
          currentArray: array,
          dayOfMonth: 10,
          monthLength: 31,
          newValue: 200,
        );

        array = MonthlyArrayHelper.updateDailyArrayValue(
          currentArray: array,
          dayOfMonth: 15,
          monthLength: 31,
          newValue: 300,
        );

        expect(array[4], 100); // day 5
        expect(array[9], 200); // day 10
        expect(array[14], 300); // day 15
      });
    });
  });
}
