import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/features/notifications/models/scheduled_notification_entry.dart';
import 'package:hydracat/features/notifications/services/notification_index_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _userId = 'user_test_123';
const _petId = 'pet_test_456';
const _scheduleIdA = 'schedule_A';
const _scheduleIdB = 'schedule_B';

ScheduledNotificationEntry _entry({
  required int id,
  required String scheduleId,
  required String treatmentType,
  required String time,
  required String kind,
}) {
  return ScheduledNotificationEntry(
    notificationId: id,
    scheduleId: scheduleId,
    treatmentType: treatmentType,
    timeSlotISO: time,
    kind: kind,
  );
}

void main() {
  late NotificationIndexStore store;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    store = NotificationIndexStore();
  });

  group('NotificationIndexStore - put/remove/get', () {
    test('putEntry adds and updates idempotently', () async {
      await store.putEntry(
        _userId,
        _petId,
        _entry(
          id: 1,
          scheduleId: _scheduleIdA,
          treatmentType: 'medication',
          time: '08:00',
          kind: 'initial',
        ),
      );
      var entries = await store.getForToday(_userId, _petId);
      expect(entries.length, 1);

      // Adding same id should update, not duplicate
      await store.putEntry(
        _userId,
        _petId,
        _entry(
          id: 1,
          scheduleId: _scheduleIdA,
          treatmentType: 'medication',
          time: '08:00',
          kind: 'followup',
        ),
      );
      entries = await store.getForToday(_userId, _petId);
      expect(entries.length, 1);
      expect(entries.first.kind, 'followup');
    });

    test('removeEntryBy removes matching entries only', () async {
      await store.putEntry(
        _userId,
        _petId,
        _entry(
          id: 1,
          scheduleId: _scheduleIdA,
          treatmentType: 'medication',
          time: '08:00',
          kind: 'initial',
        ),
      );
      await store.putEntry(
        _userId,
        _petId,
        _entry(
          id: 2,
          scheduleId: _scheduleIdA,
          treatmentType: 'medication',
          time: '08:00',
          kind: 'followup',
        ),
      );
      await store.putEntry(
        _userId,
        _petId,
        _entry(
          id: 3,
          scheduleId: _scheduleIdB,
          treatmentType: 'fluid',
          time: '09:00',
          kind: 'initial',
        ),
      );

      final removed = await store.removeEntryBy(
        _userId,
        _petId,
        _scheduleIdA,
        '08:00',
        'initial',
      );
      expect(removed, 1);

      final entries = await store.getForToday(_userId, _petId);
      expect(entries.map((e) => e.notificationId).toSet(), equals({2, 3}));
    });

    test('removeAllForSchedule removes all entries for schedule', () async {
      await store.putEntry(
        _userId,
        _petId,
        _entry(
          id: 1,
          scheduleId: _scheduleIdA,
          treatmentType: 'medication',
          time: '08:00',
          kind: 'initial',
        ),
      );
      await store.putEntry(
        _userId,
        _petId,
        _entry(
          id: 2,
          scheduleId: _scheduleIdA,
          treatmentType: 'medication',
          time: '08:00',
          kind: 'followup',
        ),
      );
      await store.putEntry(
        _userId,
        _petId,
        _entry(
          id: 3,
          scheduleId: _scheduleIdB,
          treatmentType: 'fluid',
          time: '09:00',
          kind: 'initial',
        ),
      );

      final removed = await store.removeAllForSchedule(
        _userId,
        _petId,
        _scheduleIdA,
      );
      expect(removed, 2);

      final entries = await store.getForToday(_userId, _petId);
      expect(entries.length, 1);
      expect(entries.first.notificationId, 3);
    });

    test('getCountForPet returns correct count and 0 on error', () async {
      expect(await store.getCountForPet(_userId, _petId, DateTime.now()), 0);
      await store.putEntry(
        _userId,
        _petId,
        _entry(
          id: 1,
          scheduleId: _scheduleIdA,
          treatmentType: 'medication',
          time: '08:00',
          kind: 'initial',
        ),
      );
      expect(await store.getCountForPet(_userId, _petId, DateTime.now()), 1);
    });
  });

  group('NotificationIndexStore - categorizeByType', () {
    test('categorizes medication vs fluid correctly', () async {
      final entries = [
        _entry(
          id: 1,
          scheduleId: _scheduleIdA,
          treatmentType: 'medication',
          time: '08:00',
          kind: 'initial',
        ),
        _entry(
          id: 2,
          scheduleId: _scheduleIdB,
          treatmentType: 'fluid',
          time: '09:00',
          kind: 'followup',
        ),
        _entry(
          id: 3,
          scheduleId: _scheduleIdA,
          treatmentType: 'medication',
          time: '10:00',
          kind: 'snooze',
        ),
      ];

      final breakdown = NotificationIndexStore.categorizeByType(entries);
      expect(breakdown['medication'], 2);
      expect(breakdown['fluid'], 1);
    });
  });

  group('NotificationIndexStore - corruption and rebuild', () {
    test('returns [] on invalid stored JSON', () async {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now();
      final dateStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-'
          '${today.day.toString().padLeft(2, '0')}';
      final key = 'notif_index_v2_${_userId}_${_petId}_$dateStr';

      // Store invalid JSON string
      await prefs.setString(key, '{"invalid": true');

      final entries = await store.getForToday(_userId, _petId);

      expect(entries, isEmpty);
    });
  });

  group('NotificationIndexStore - date-based cleanup', () {
    test('clearForDate and clearAllForYesterday work as expected', () async {
      final today = DateTime.now();
      final yesterday = DateTime.now().subtract(const Duration(days: 1));

      // Put entries for today
      await store.putEntry(
        _userId,
        _petId,
        _entry(
          id: 1,
          scheduleId: _scheduleIdA,
          treatmentType: 'medication',
          time: '08:00',
          kind: 'initial',
        ),
      );
      expect((await store.getForToday(_userId, _petId)).length, 1);

      // Create a fake key for yesterday manually
      final prefs = await SharedPreferences.getInstance();
      final yDateStr =
          '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-'
          '${yesterday.day.toString().padLeft(2, '0')}';
      final yKey = 'notif_index_v2_${_userId}_${_petId}_$yDateStr';
      await prefs.setString(
        yKey,
        jsonEncode({
          'checksum': '00000000',
          'entries': <Map<String, dynamic>>[],
        }),
      );

      // Clear yesterday
      await store.clearAllForYesterday();
      expect(prefs.getString(yKey), isNull);

      // clearForDate(today)
      await store.clearForDate(_userId, _petId, today);
      expect((await store.getForToday(_userId, _petId)).length, 0);
    });
  });
}
