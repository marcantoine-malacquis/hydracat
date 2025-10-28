import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/features/notifications/utils/time_slot_formatter.dart';

void main() {
  group('formatTimeSlotFromDateTime', () {
    test('formats morning time with single-digit hour', () {
      final dateTime = DateTime(2025, 1, 28, 9, 30);
      expect(formatTimeSlotFromDateTime(dateTime), '09:30');
    });

    test('formats morning time with single-digit minute', () {
      final dateTime = DateTime(2025, 1, 28, 9, 5);
      expect(formatTimeSlotFromDateTime(dateTime), '09:05');
    });

    test('formats afternoon time', () {
      final dateTime = DateTime(2025, 1, 28, 15, 45);
      expect(formatTimeSlotFromDateTime(dateTime), '15:45');
    });

    test('formats midnight', () {
      final dateTime = DateTime(2025, 1, 28);
      expect(formatTimeSlotFromDateTime(dateTime), '00:00');
    });

    test('formats noon', () {
      final dateTime = DateTime(2025, 1, 28, 12);
      expect(formatTimeSlotFromDateTime(dateTime), '12:00');
    });

    test('formats late evening time', () {
      final dateTime = DateTime(2025, 1, 28, 23, 59);
      expect(formatTimeSlotFromDateTime(dateTime), '23:59');
    });

    test('ignores date components', () {
      final dateTime1 = DateTime(2025, 1, 28, 9, 30);
      final dateTime2 = DateTime(2024, 12, 15, 9, 30);
      expect(
        formatTimeSlotFromDateTime(dateTime1),
        formatTimeSlotFromDateTime(dateTime2),
      );
    });

    test('ignores seconds and milliseconds', () {
      final dateTime = DateTime(2025, 1, 28, 9, 30, 45, 123);
      expect(formatTimeSlotFromDateTime(dateTime), '09:30');
    });
  });
}
