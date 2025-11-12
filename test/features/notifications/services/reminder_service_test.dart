import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/features/notifications/utils/scheduling_helpers.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUpAll(() {
    // Initialize timezone data for tests
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/New_York'));
  });

  group('schedulingHelpers - zonedDateTimeForToday', () {
    test('converts valid time slot to TZDateTime for today', () {
      final referenceDate = DateTime(2024, 1, 15, 10, 30);
      final result = zonedDateTimeForToday('08:00', referenceDate);

      expect(result.year, equals(2024));
      expect(result.month, equals(1));
      expect(result.day, equals(15));
      expect(result.hour, equals(8));
      expect(result.minute, equals(0));
    });

    test('handles different time slots correctly', () {
      final referenceDate = DateTime(2024, 1, 15);

      expect(
        zonedDateTimeForToday('00:00', referenceDate).hour,
        equals(0),
      );
      expect(
        zonedDateTimeForToday('12:30', referenceDate).hour,
        equals(12),
      );
      expect(
        zonedDateTimeForToday('12:30', referenceDate).minute,
        equals(30),
      );
      expect(
        zonedDateTimeForToday('23:59', referenceDate).hour,
        equals(23),
      );
      expect(
        zonedDateTimeForToday('23:59', referenceDate).minute,
        equals(59),
      );
    });

    test('throws FormatException for invalid time format', () {
      final referenceDate = DateTime(2024, 1, 15);

      expect(
        () => zonedDateTimeForToday('8:00', referenceDate),
        throwsFormatException,
      );
      expect(
        () => zonedDateTimeForToday('08:0', referenceDate),
        throwsFormatException,
      );
      expect(
        () => zonedDateTimeForToday('invalid', referenceDate),
        throwsFormatException,
      );
      expect(
        () => zonedDateTimeForToday('25:00', referenceDate),
        throwsFormatException,
      );
      expect(
        () => zonedDateTimeForToday('12:60', referenceDate),
        throwsFormatException,
      );
    });
  });

  group('schedulingHelpers - evaluateGracePeriod', () {
    test('returns scheduled for future times', () {
      final now = DateTime(2024, 1, 15, 8);
      final scheduledTime = DateTime(2024, 1, 15, 8, 30);

      final result = evaluateGracePeriod(
        scheduledTime: scheduledTime,
        now: now,
      );

      expect(result, equals(NotificationSchedulingDecision.scheduled));
    });

    test('returns immediate for times within grace period', () {
      final now = DateTime(2024, 1, 15, 8, 15);
      final scheduledTime = DateTime(2024, 1, 15, 8); // 15 min ago

      final result = evaluateGracePeriod(
        scheduledTime: scheduledTime,
        now: now,
      );

      expect(result, equals(NotificationSchedulingDecision.immediate));
    });

    test('returns immediate at grace period boundary (30 min)', () {
      final now = DateTime(2024, 1, 15, 8, 30);
      final scheduledTime = DateTime(2024, 1, 15, 8); // Exactly 30 min ago

      final result = evaluateGracePeriod(
        scheduledTime: scheduledTime,
        now: now,
      );

      expect(result, equals(NotificationSchedulingDecision.immediate));
    });

    test('returns missed for times past grace period', () {
      final now = DateTime(2024, 1, 15, 8, 35);
      final scheduledTime = DateTime(2024, 1, 15, 8); // 35 min ago

      final result = evaluateGracePeriod(
        scheduledTime: scheduledTime,
        now: now,
      );

      expect(result, equals(NotificationSchedulingDecision.missed));
    });

    test('respects custom grace period parameter', () {
      final now = DateTime(2024, 1, 15, 8, 45);
      final scheduledTime = DateTime(2024, 1, 15, 8); // 45 min ago

      // With 30 min grace period: missed
      expect(
        evaluateGracePeriod(
          scheduledTime: scheduledTime,
          now: now,
        ),
        equals(NotificationSchedulingDecision.missed),
      );

      // With 60 min grace period: immediate
      expect(
        evaluateGracePeriod(
          scheduledTime: scheduledTime,
          now: now,
          gracePeriodMinutes: 60,
        ),
        equals(NotificationSchedulingDecision.immediate),
      );
    });
  });

  group('schedulingHelpers - calculateFollowupTime', () {
    test('adds offset hours when result is before end of day', () {
      final initialTime = tz.TZDateTime(tz.local, 2024, 1, 15, 8);

      final result = calculateFollowupTime(
        initialTime: initialTime,
        followupOffsetHours: 2,
      );

      expect(result.year, equals(2024));
      expect(result.month, equals(1));
      expect(result.day, equals(15)); // Same day
      expect(result.hour, equals(10)); // 8 + 2
      expect(result.minute, equals(0));
    });

    test('schedules for next morning when result would be past 23:59', () {
      final initialTime = tz.TZDateTime(tz.local, 2024, 1, 15, 22);

      final result = calculateFollowupTime(
        initialTime: initialTime,
        followupOffsetHours: 2,
      );

      expect(result.year, equals(2024));
      expect(result.month, equals(1));
      expect(result.day, equals(16)); // Next day
      expect(result.hour, equals(8)); // 08:00
      expect(result.minute, equals(0));
    });

    test('handles boundary at exactly 23:59', () {
      final initialTime = tz.TZDateTime(tz.local, 2024, 1, 15, 21, 59);

      final result = calculateFollowupTime(
        initialTime: initialTime,
        followupOffsetHours: 2,
      );

      // 21:59 + 2h = 23:59, which is after 23:00, so next morning
      expect(result.day, equals(16)); // Next day
      expect(result.hour, equals(8)); // 08:00
    });

    test('works with different offset hours', () {
      final initialTime = tz.TZDateTime(tz.local, 2024, 1, 15, 10);

      // 4-hour offset
      final result4h = calculateFollowupTime(
        initialTime: initialTime,
        followupOffsetHours: 4,
      );
      expect(result4h.hour, equals(14));
      expect(result4h.day, equals(15));

      // 1-hour offset
      final result1h = calculateFollowupTime(
        initialTime: initialTime,
        followupOffsetHours: 1,
      );
      expect(result1h.hour, equals(11));
      expect(result1h.day, equals(15));
    });

    test('handles late night times correctly', () {
      final initialTime = tz.TZDateTime(tz.local, 2024, 1, 15, 23, 30);

      final result = calculateFollowupTime(
        initialTime: initialTime,
        followupOffsetHours: 1,
      );

      // 23:30 + 1h would be 00:30 next day, but we schedule for 08:00 instead
      expect(result.day, equals(16)); // Next day
      expect(result.hour, equals(8)); // 08:00
      expect(result.minute, equals(0));
    });

    test('handles month boundary', () {
      final initialTime = tz.TZDateTime(tz.local, 2024, 1, 31, 22);

      final result = calculateFollowupTime(
        initialTime: initialTime,
        followupOffsetHours: 2,
      );

      expect(result.month, equals(2)); // February
      expect(result.day, equals(1)); // 1st
      expect(result.hour, equals(8));
    });

    test('handles year boundary', () {
      final initialTime = tz.TZDateTime(tz.local, 2024, 12, 31, 22);

      final result = calculateFollowupTime(
        initialTime: initialTime,
        followupOffsetHours: 2,
      );

      expect(result.year, equals(2025)); // Next year
      expect(result.month, equals(1)); // January
      expect(result.day, equals(1)); // 1st
      expect(result.hour, equals(8));
    });
  });

  group('Edge Cases', () {
    test('zonedDateTimeForToday handles DST transition', () {
      // This test ensures timezone-aware datetime creation
      final springForward = DateTime(2024, 3, 10); // DST spring forward
      final result = zonedDateTimeForToday('02:00', springForward);

      // The result should be valid even during DST transition
      expect(result.year, equals(2024));
      expect(result.month, equals(3));
      expect(result.day, equals(10));
      expect(result.hour, greaterThanOrEqualTo(0));
      expect(result.hour, lessThan(24));
    });

    test('calculateFollowupTime handles leap day', () {
      final initialTime = tz.TZDateTime(tz.local, 2024, 2, 29, 22);

      final result = calculateFollowupTime(
        initialTime: initialTime,
        followupOffsetHours: 2,
      );

      expect(result.year, equals(2024));
      expect(result.month, equals(3)); // March
      expect(result.day, equals(1)); // 1st
      expect(result.hour, equals(8));
    });
  });

  group('Performance', () {
    test('zonedDateTimeForToday executes quickly for many calls', () {
      final referenceDate = DateTime(2024, 1, 15);
      final stopwatch = Stopwatch()..start();

      for (var i = 0; i < 1000; i++) {
        zonedDateTimeForToday('08:00', referenceDate);
      }

      stopwatch.stop();
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(100),
        reason: '1000 conversions should complete in <100ms',
      );
    });

    test('calculateFollowupTime executes quickly for many calls', () {
      final initialTime = tz.TZDateTime(tz.local, 2024, 1, 15, 10);
      final stopwatch = Stopwatch()..start();

      for (var i = 0; i < 1000; i++) {
        calculateFollowupTime(
          initialTime: initialTime,
          followupOffsetHours: 2,
        );
      }

      stopwatch.stop();
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(100),
        reason: '1000 calculations should complete in <100ms',
      );
    });
  });
}
