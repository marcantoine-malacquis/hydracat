import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/core/utils/date_utils.dart';
import 'package:hydracat/features/onboarding/models/treatment_data.dart';
import 'package:hydracat/features/profile/models/schedule.dart';

void main() {
  group('ScheduleDateHelpers', () {
    test('hasReminderOnDate returns false when no reminders today', () {
      final now = DateTime(2025, 10, 13, 12);
      final yesterday = AppDateUtils.startOfDay(
        now.subtract(const Duration(days: 1)),
      );
      final schedule = Schedule(
        id: 's1',
        treatmentType: TreatmentType.medication,
        frequency: TreatmentFrequency.onceDaily,
        reminderTimes: [yesterday.add(const Duration(hours: 9))],
        isActive: true,
        createdAt: now,
        updatedAt: now,
        medicationName: 'Amlodipine',
        targetDosage: 1,
        medicationUnit: 'mg',
      );

      expect(schedule.hasReminderOnDate(now), isFalse);
      expect(schedule.todaysReminderTimes(now), isEmpty);
    });

    test('hasReminderOnDate returns true when one reminder today', () {
      final now = DateTime(2025, 10, 13, 12);
      final today = AppDateUtils.startOfDay(now);
      final schedule = Schedule(
        id: 's2',
        treatmentType: TreatmentType.medication,
        frequency: TreatmentFrequency.onceDaily,
        reminderTimes: [today.add(const Duration(hours: 9))],
        isActive: true,
        createdAt: now,
        updatedAt: now,
        medicationName: 'Amlodipine',
        targetDosage: 1,
        medicationUnit: 'mg',
      );

      expect(schedule.hasReminderOnDate(now), isTrue);
      final times = schedule.todaysReminderTimes(now).toList();
      expect(times.length, 1);
      expect(times.first.hour, 9);
    });

    test('reminderTimesOnDate returns only today among mixed days', () {
      final now = DateTime(2025, 10, 13, 12);
      final today = AppDateUtils.startOfDay(now);
      final tomorrow = AppDateUtils.startOfDay(
        now.add(const Duration(days: 1)),
      );
      final schedule = Schedule(
        id: 's3',
        treatmentType: TreatmentType.medication,
        frequency: TreatmentFrequency.twiceDaily,
        reminderTimes: [
          today.add(const Duration(hours: 9)),
          tomorrow.add(const Duration(hours: 9)),
          today.add(const Duration(hours: 21)),
        ],
        isActive: true,
        createdAt: now,
        updatedAt: now,
        medicationName: 'Amlodipine',
        targetDosage: 1,
        medicationUnit: 'mg',
      );

      final times = schedule.todaysReminderTimes(now).toList();
      expect(times.length, 2);
      expect(times[0].hour, anyOf(9, 21));
      expect(times[1].hour, anyOf(9, 21));
    });

    test('midnight boundary handled via startOfDay normalization', () {
      final base = DateTime(2025, 3, 29, 23, 59, 59);
      final nextDay = base.add(const Duration(seconds: 1));
      // Reminder exactly at midnight of next day
      final schedule = Schedule(
        id: 's4',
        treatmentType: TreatmentType.medication,
        frequency: TreatmentFrequency.onceDaily,
        reminderTimes: [
          DateTime(nextDay.year, nextDay.month, nextDay.day),
        ],
        isActive: true,
        createdAt: base,
        updatedAt: base,
        medicationName: 'Amlodipine',
        targetDosage: 1,
        medicationUnit: 'mg',
      );

      expect(schedule.hasReminderOnDate(nextDay), isTrue);
      expect(schedule.hasReminderOnDate(base), isFalse);
    });
  });
}
