import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/features/notifications/models/scheduled_notification_entry.dart';

void main() {
  group('ScheduledNotificationEntry - constructor and validation', () {
    test('creates valid entry', () {
      const entry = ScheduledNotificationEntry(
        notificationId: 12345,
        scheduleId: 'schedule_abc',
        treatmentType: 'medication',
        timeSlotISO: '08:00',
        kind: 'initial',
      );

      expect(entry.notificationId, 12345);
      expect(entry.scheduleId, 'schedule_abc');
      expect(entry.treatmentType, 'medication');
      expect(entry.timeSlotISO, '08:00');
      expect(entry.kind, 'initial');
    });

    test('isValidTreatmentType accepts valid values', () {
      expect(
        ScheduledNotificationEntry.isValidTreatmentType('medication'),
        isTrue,
      );
      expect(ScheduledNotificationEntry.isValidTreatmentType('fluid'), isTrue);
    });

    test('isValidTreatmentType rejects invalid values', () {
      expect(ScheduledNotificationEntry.isValidTreatmentType(''), isFalse);
      expect(ScheduledNotificationEntry.isValidTreatmentType('med'), isFalse);
      expect(
        ScheduledNotificationEntry.isValidTreatmentType('fluids'),
        isFalse,
      );
      expect(ScheduledNotificationEntry.isValidTreatmentType('other'), isFalse);
    });

    test('isValidTimeSlot accepts valid HH:mm values', () {
      expect(ScheduledNotificationEntry.isValidTimeSlot('00:00'), isTrue);
      expect(ScheduledNotificationEntry.isValidTimeSlot('08:00'), isTrue);
      expect(ScheduledNotificationEntry.isValidTimeSlot('12:30'), isTrue);
      expect(ScheduledNotificationEntry.isValidTimeSlot('23:59'), isTrue);
    });

    test('isValidTimeSlot rejects invalid formats and ranges', () {
      expect(ScheduledNotificationEntry.isValidTimeSlot('8:00'), isFalse);
      expect(ScheduledNotificationEntry.isValidTimeSlot('08:0'), isFalse);
      expect(ScheduledNotificationEntry.isValidTimeSlot('08:00:00'), isFalse);
      expect(ScheduledNotificationEntry.isValidTimeSlot('invalid'), isFalse);
      expect(ScheduledNotificationEntry.isValidTimeSlot('25:00'), isFalse);
      expect(ScheduledNotificationEntry.isValidTimeSlot('12:60'), isFalse);
      expect(ScheduledNotificationEntry.isValidTimeSlot('24:00'), isFalse);
      expect(ScheduledNotificationEntry.isValidTimeSlot('-01:00'), isFalse);
    });

    test('isValidKind accepts valid values', () {
      expect(ScheduledNotificationEntry.isValidKind('initial'), isTrue);
      expect(ScheduledNotificationEntry.isValidKind('followup'), isTrue);
    });

    test('isValidKind rejects invalid values', () {
      expect(ScheduledNotificationEntry.isValidKind(''), isFalse);
      expect(ScheduledNotificationEntry.isValidKind('Initial'), isFalse);
      expect(ScheduledNotificationEntry.isValidKind('reminder'), isFalse);
      expect(ScheduledNotificationEntry.isValidKind('unknown'), isFalse);
      expect(ScheduledNotificationEntry.isValidKind('snooze'), isFalse);
    });
  });

  group('ScheduledNotificationEntry - JSON serialization', () {
    test('toJson and fromJson round-trip', () {
      const original = ScheduledNotificationEntry(
        notificationId: 2147483647,
        scheduleId: 'sched_123',
        treatmentType: 'fluid',
        timeSlotISO: '23:59',
        kind: 'followup',
      );

      final json = original.toJson();
      final parsed = ScheduledNotificationEntry.fromJson(json);

      expect(parsed, equals(original));
      expect(parsed.hashCode, equals(original.hashCode));
    });

    test('fromJson rejects missing fields', () {
      expect(
        () => ScheduledNotificationEntry.fromJson(const {}),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => ScheduledNotificationEntry.fromJson(const {
          'notificationId': 1,
          'scheduleId': 's',
          'treatmentType': 'medication',
          'timeSlotISO': '08:00',
          // missing kind
        }),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('fromJson rejects invalid field values', () {
      // Invalid treatmentType
      expect(
        () => ScheduledNotificationEntry.fromJson(const {
          'notificationId': 1,
          'scheduleId': 's',
          'treatmentType': 'invalid',
          'timeSlotISO': '08:00',
          'kind': 'initial',
        }),
        throwsA(isA<ArgumentError>()),
      );

      // Invalid timeSlotISO
      expect(
        () => ScheduledNotificationEntry.fromJson(const {
          'notificationId': 1,
          'scheduleId': 's',
          'treatmentType': 'medication',
          'timeSlotISO': '8:00',
          'kind': 'initial',
        }),
        throwsA(isA<ArgumentError>()),
      );

      // Invalid kind
      expect(
        () => ScheduledNotificationEntry.fromJson(const {
          'notificationId': 1,
          'scheduleId': 's',
          'treatmentType': 'medication',
          'timeSlotISO': '08:00',
          'kind': 'invalid',
        }),
        throwsA(isA<ArgumentError>()),
      );

      // Type mismatch - throws TypeError before ArgumentError
      expect(
        () => ScheduledNotificationEntry.fromJson(const {
          'notificationId': '1', // should be int
          'scheduleId': 's',
          'treatmentType': 'medication',
          'timeSlotISO': '08:00',
          'kind': 'initial',
        }),
        throwsA(anyOf(isA<ArgumentError>(), isA<TypeError>())),
      );
    });
  });

  group('ScheduledNotificationEntry - equality, copy, toString', () {
    test('equality and hashCode reflect all fields', () {
      const a = ScheduledNotificationEntry(
        notificationId: 1,
        scheduleId: 's',
        treatmentType: 'medication',
        timeSlotISO: '08:00',
        kind: 'initial',
      );
      const b = ScheduledNotificationEntry(
        notificationId: 1,
        scheduleId: 's',
        treatmentType: 'medication',
        timeSlotISO: '08:00',
        kind: 'initial',
      );
      final c = b.copyWith(kind: 'followup');

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a == c, isFalse);
    });

    test('copyWith updates fields immutably', () {
      const original = ScheduledNotificationEntry(
        notificationId: 1,
        scheduleId: 's',
        treatmentType: 'medication',
        timeSlotISO: '08:00',
        kind: 'initial',
      );

      final updated = original.copyWith(
        notificationId: 2,
        scheduleId: 's2',
        treatmentType: 'fluid',
        timeSlotISO: '09:30',
        kind: 'followup',
      );

      expect(updated.notificationId, 2);
      expect(updated.scheduleId, 's2');
      expect(updated.treatmentType, 'fluid');
      expect(updated.timeSlotISO, '09:30');
      expect(updated.kind, 'followup');

      // Original unchanged
      expect(original.notificationId, 1);
      expect(original.scheduleId, 's');
      expect(original.treatmentType, 'medication');
      expect(original.timeSlotISO, '08:00');
      expect(original.kind, 'initial');
    });

    test('toString includes key fields', () {
      const entry = ScheduledNotificationEntry(
        notificationId: 1,
        scheduleId: 'sched',
        treatmentType: 'medication',
        timeSlotISO: '08:00',
        kind: 'initial',
      );
      final s = entry.toString();

      expect(s, contains('notificationId: 1'));
      expect(s, contains('scheduleId: sched'));
      expect(s, contains('treatmentType: medication'));
      expect(s, contains('timeSlotISO: 08:00'));
      expect(s, contains('kind: initial'));
    });
  });
}
