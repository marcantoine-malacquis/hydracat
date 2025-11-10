import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/features/onboarding/models/treatment_data.dart';
import 'package:hydracat/features/profile/models/schedule.dart';

void main() {
  group('ScheduleDateHelpers', () {
    test('hasReminderOnDate returns false when no reminders for '
        'non-scheduled day (everyOtherDay)', () {
      final createdAt = DateTime(2025, 10, 10, 10); // Thursday
      // Sunday (3 days later, not scheduled)
      final testDate = DateTime(2025, 10, 13, 12);

      final schedule = Schedule(
        id: 's1',
        treatmentType: TreatmentType.medication,
        frequency: TreatmentFrequency.everyOtherDay,
        // 9:00 AM on creation day
        reminderTimes: [createdAt.add(const Duration(hours: -1))],
        isActive: true,
        createdAt: createdAt,
        updatedAt: createdAt,
        medicationName: 'Amlodipine',
        targetDosage: 1,
        medicationUnit: 'mg',
      );

      expect(schedule.hasReminderOnDate(testDate), isFalse);
      expect(schedule.todaysReminderTimes(testDate), isEmpty);
    });

    test(
      'onceDaily returns reminder time for any date with same time-of-day',
      () {
        final createdAt = DateTime(2025, 10, 10, 12); // Created Oct 10
        final threeDaysLater = DateTime(2025, 10, 13, 12); // Test Oct 13

        final schedule = Schedule(
          id: 's2',
          treatmentType: TreatmentType.medication,
          frequency: TreatmentFrequency.onceDaily,
          reminderTimes: [DateTime(2025, 10, 10, 9)], // 9:00 AM on Oct 10
          isActive: true,
          createdAt: createdAt,
          updatedAt: createdAt,
          medicationName: 'Amlodipine',
          targetDosage: 1,
          medicationUnit: 'mg',
        );

        expect(schedule.hasReminderOnDate(threeDaysLater), isTrue);
        final times = schedule.todaysReminderTimes(threeDaysLater).toList();
        expect(times.length, 1);
        expect(times.first.year, 2025);
        expect(times.first.month, 10);
        expect(times.first.day, 13); // Returns Oct 13, not Oct 10
        expect(times.first.hour, 9);
      },
    );

    test('twiceDaily returns both times for requested date', () {
      final createdAt = DateTime(2025, 10, 10, 12);
      final nextWeek = DateTime(2025, 10, 17, 12);

      final schedule = Schedule(
        id: 's3',
        treatmentType: TreatmentType.medication,
        frequency: TreatmentFrequency.twiceDaily,
        reminderTimes: [
          DateTime(2025, 10, 10, 9), // 9 AM
          DateTime(2025, 10, 10, 21), // 9 PM
        ],
        isActive: true,
        createdAt: createdAt,
        updatedAt: createdAt,
        medicationName: 'Amlodipine',
        targetDosage: 1,
        medicationUnit: 'mg',
      );

      final times = schedule.todaysReminderTimes(nextWeek).toList();
      expect(times.length, 2);
      // Oct 17, not Oct 10
      expect(times[0].day, 17);
      expect(times[0].hour, 9);
      expect(times[1].day, 17);
      expect(times[1].hour, 21);
    });

    test('everyOtherDay returns times only on scheduled days', () {
      final createdAt = DateTime(2025, 10, 10, 10); // Thursday (anchor day)

      final schedule = Schedule(
        id: 's4',
        treatmentType: TreatmentType.medication,
        frequency: TreatmentFrequency.everyOtherDay,
        reminderTimes: [DateTime(2025, 10, 10, 9)], // 9 AM
        isActive: true,
        createdAt: createdAt,
        updatedAt: createdAt,
        medicationName: 'Amlodipine',
        targetDosage: 1,
        medicationUnit: 'mg',
      );

      // Day 0 (creation day): should have reminder
      expect(schedule.hasReminderOnDate(DateTime(2025, 10, 10)), isTrue);

      // Day 1: should NOT have reminder
      expect(schedule.hasReminderOnDate(DateTime(2025, 10, 11)), isFalse);

      // Day 2: should have reminder
      expect(schedule.hasReminderOnDate(DateTime(2025, 10, 12)), isTrue);
      final times = schedule
          .todaysReminderTimes(DateTime(2025, 10, 12))
          .toList();
      // Oct 12, not Oct 10
      expect(times[0].day, 12);
      expect(times[0].hour, 9);

      // Day 3: should NOT have reminder
      expect(schedule.hasReminderOnDate(DateTime(2025, 10, 13)), isFalse);

      // Day 4: should have reminder
      expect(schedule.hasReminderOnDate(DateTime(2025, 10, 14)), isTrue);
    });

    test('every3Days returns times only on scheduled days', () {
      final createdAt = DateTime(2025, 10, 10, 10); // Thursday (anchor day)

      final schedule = Schedule(
        id: 's5',
        treatmentType: TreatmentType.medication,
        frequency: TreatmentFrequency.every3Days,
        reminderTimes: [DateTime(2025, 10, 10, 9)], // 9 AM
        isActive: true,
        createdAt: createdAt,
        updatedAt: createdAt,
        medicationName: 'Mirtazapine',
        targetDosage: 1,
        medicationUnit: 'mg',
      );

      // Day 0 (creation day): should have reminder
      expect(schedule.hasReminderOnDate(DateTime(2025, 10, 10)), isTrue);

      // Days 1-2: should NOT have reminder
      expect(schedule.hasReminderOnDate(DateTime(2025, 10, 11)), isFalse);
      expect(schedule.hasReminderOnDate(DateTime(2025, 10, 12)), isFalse);

      // Day 3: should have reminder
      expect(schedule.hasReminderOnDate(DateTime(2025, 10, 13)), isTrue);
      final times = schedule
          .todaysReminderTimes(DateTime(2025, 10, 13))
          .toList();
      expect(times[0].day, 13);
      expect(times[0].hour, 9);

      // Days 4-5: should NOT have reminder
      expect(schedule.hasReminderOnDate(DateTime(2025, 10, 14)), isFalse);
      expect(schedule.hasReminderOnDate(DateTime(2025, 10, 15)), isFalse);

      // Day 6: should have reminder
      expect(schedule.hasReminderOnDate(DateTime(2025, 10, 16)), isTrue);
    });

    test('midnight boundary handled via startOfDay normalization', () {
      final base = DateTime(2025, 3, 29, 23, 59, 59);
      final nextDay = base.add(const Duration(seconds: 1));
      // Reminder exactly at midnight of next day
      final schedule = Schedule(
        id: 's6',
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

      // For onceDaily, both dates should have reminders since it recurs daily
      expect(schedule.hasReminderOnDate(nextDay), isTrue);
      expect(schedule.hasReminderOnDate(base), isTrue);

      // Verify times are normalized to midnight for each day
      final baseReminders = schedule.todaysReminderTimes(base).toList();
      final nextDayReminders = schedule.todaysReminderTimes(nextDay).toList();
      expect(baseReminders.length, 1);
      expect(nextDayReminders.length, 1);
      expect(baseReminders[0].day, base.day);
      expect(nextDayReminders[0].day, nextDay.day);
    });
  });
}
