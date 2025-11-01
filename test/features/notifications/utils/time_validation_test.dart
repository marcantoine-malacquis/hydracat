import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/features/notifications/utils/time_validation.dart';

void main() {
  group('isValidTimeString - valid times', () {
    test('accepts midnight (00:00)', () {
      expect(isValidTimeString('00:00'), isTrue);
    });

    test('accepts morning time (08:00)', () {
      expect(isValidTimeString('08:00'), isTrue);
    });

    test('accepts noon (12:00)', () {
      expect(isValidTimeString('12:00'), isTrue);
    });

    test('accepts afternoon time with minutes (12:30)', () {
      expect(isValidTimeString('12:30'), isTrue);
    });

    test('accepts end of day (23:59)', () {
      expect(isValidTimeString('23:59'), isTrue);
    });

    test('accepts all valid hours (00-23)', () {
      for (var hour = 0; hour < 24; hour++) {
        final timeString = '${hour.toString().padLeft(2, '0')}:00';
        expect(
          isValidTimeString(timeString),
          isTrue,
          reason: 'Hour $hour should be valid',
        );
      }
    });

    test('accepts all valid minutes (00-59)', () {
      for (var minute = 0; minute < 60; minute++) {
        final timeString = '12:${minute.toString().padLeft(2, '0')}';
        expect(
          isValidTimeString(timeString),
          isTrue,
          reason: 'Minute $minute should be valid',
        );
      }
    });
  });

  group('isValidTimeString - invalid formats', () {
    test('rejects single-digit hour (8:00)', () {
      expect(isValidTimeString('8:00'), isFalse);
    });

    test('rejects single-digit minute (08:0)', () {
      expect(isValidTimeString('08:0'), isFalse);
    });

    test('rejects both single digits (8:0)', () {
      expect(isValidTimeString('8:0'), isFalse);
    });

    test('rejects time with seconds (08:00:00)', () {
      expect(isValidTimeString('08:00:00'), isFalse);
    });

    test('rejects invalid format (invalid)', () {
      expect(isValidTimeString('invalid'), isFalse);
    });

    test('rejects empty string', () {
      expect(isValidTimeString(''), isFalse);
    });

    test('rejects missing colon (0800)', () {
      expect(isValidTimeString('0800'), isFalse);
    });

    test('rejects wrong separator (08.00)', () {
      expect(isValidTimeString('08.00'), isFalse);
    });

    test('rejects too many digits (008:00)', () {
      expect(isValidTimeString('008:00'), isFalse);
    });

    test('rejects too many digits for minutes (08:000)', () {
      expect(isValidTimeString('08:000'), isFalse);
    });

    test('rejects letters (ab:cd)', () {
      expect(isValidTimeString('ab:cd'), isFalse);
    });
  });

  group('isValidTimeString - invalid ranges', () {
    test('rejects hour 24 (24:00)', () {
      expect(isValidTimeString('24:00'), isFalse);
    });

    test('rejects hour 25 (25:00)', () {
      expect(isValidTimeString('25:00'), isFalse);
    });

    test('rejects minute 60 (12:60)', () {
      expect(isValidTimeString('12:60'), isFalse);
    });

    test('rejects minute 99 (12:99)', () {
      expect(isValidTimeString('12:99'), isFalse);
    });

    test('rejects negative hour (-01:00)', () {
      expect(isValidTimeString('-01:00'), isFalse);
    });

    test('rejects negative minute (12:-01)', () {
      expect(isValidTimeString('12:-01'), isFalse);
    });
  });

  group('parseTimeString - valid parsing', () {
    test('parses midnight (00:00)', () {
      final (hour, minute) = parseTimeString('00:00');
      expect(hour, equals(0));
      expect(minute, equals(0));
    });

    test('parses morning time (08:30)', () {
      final (hour, minute) = parseTimeString('08:30');
      expect(hour, equals(8));
      expect(minute, equals(30));
    });

    test('parses noon (12:00)', () {
      final (hour, minute) = parseTimeString('12:00');
      expect(hour, equals(12));
      expect(minute, equals(0));
    });

    test('parses afternoon time (14:45)', () {
      final (hour, minute) = parseTimeString('14:45');
      expect(hour, equals(14));
      expect(minute, equals(45));
    });

    test('parses end of day (23:59)', () {
      final (hour, minute) = parseTimeString('23:59');
      expect(hour, equals(23));
      expect(minute, equals(59));
    });

    test('parses time with leading zeros (01:05)', () {
      final (hour, minute) = parseTimeString('01:05');
      expect(hour, equals(1));
      expect(minute, equals(5));
    });
  });

  group('parseTimeString - throws FormatException', () {
    test('throws on invalid format (8:00)', () {
      expect(
        () => parseTimeString('8:00'),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws on invalid format (08:0)', () {
      expect(
        () => parseTimeString('08:0'),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws on invalid format (invalid)', () {
      expect(
        () => parseTimeString('invalid'),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws on hour out of range (24:00)', () {
      expect(
        () => parseTimeString('24:00'),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws on hour out of range (25:00)', () {
      expect(
        () => parseTimeString('25:00'),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws on minute out of range (12:60)', () {
      expect(
        () => parseTimeString('12:60'),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws on negative hour (-01:00)', () {
      expect(
        () => parseTimeString('-01:00'),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws on empty string', () {
      expect(
        () => parseTimeString(''),
        throwsA(isA<FormatException>()),
      );
    });

    test('FormatException contains helpful message', () {
      try {
        parseTimeString('invalid');
        fail('Should have thrown FormatException');
      } on FormatException catch (e) {
        expect(e.message, contains('Invalid time format'));
        expect(e.message, contains('invalid'));
        expect(e.message, contains('HH:mm'));
        expect(e.message, contains('00:00 to 23:59'));
      }
    });
  });

  group('parseTimeString - integration with DateTime', () {
    test('can be used to construct DateTime objects', () {
      final (hour, minute) = parseTimeString('14:30');
      final dateTime = DateTime(2024, 1, 15, hour, minute);

      expect(dateTime.year, equals(2024));
      expect(dateTime.month, equals(1));
      expect(dateTime.day, equals(15));
      expect(dateTime.hour, equals(14));
      expect(dateTime.minute, equals(30));
    });

    test('handles midnight correctly in DateTime', () {
      final (hour, minute) = parseTimeString('00:00');
      final dateTime = DateTime(2024, 1, 15, hour, minute);

      expect(dateTime.hour, equals(0));
      expect(dateTime.minute, equals(0));
    });

    test('handles end of day correctly in DateTime', () {
      final (hour, minute) = parseTimeString('23:59');
      final dateTime = DateTime(2024, 1, 15, hour, minute);

      expect(dateTime.hour, equals(23));
      expect(dateTime.minute, equals(59));
    });
  });
}
