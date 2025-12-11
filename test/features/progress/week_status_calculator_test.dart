import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/features/onboarding/models/treatment_data.dart';
import 'package:hydracat/features/profile/models/schedule.dart';
import 'package:hydracat/features/progress/models/day_dot_status.dart';
import 'package:hydracat/features/progress/services/week_status_calculator.dart';
import 'package:hydracat/shared/models/daily_summary.dart';

void main() {
  group('computeWeekStatuses', () {
    test('future days return none', () {
      // Setup: Week starting Monday Oct 13, current time Monday 10 AM
      final weekStart = DateTime(2025, 10, 13);
      final now = DateTime(2025, 10, 13, 10);

      // No schedules
      final statuses = computeWeekStatuses(
        weekStart: weekStart,
        medicationSchedules: [],
        fluidSchedule: null,
        summaries: {},
        now: now,
      );

      // All days should be none (future days with zero schedules)
      expect(statuses[DateTime(2025, 10, 13)], DayDotStatus.today); // Today
      expect(statuses[DateTime(2025, 10, 14)], DayDotStatus.none); // Tue
      expect(statuses[DateTime(2025, 10, 15)], DayDotStatus.none); // Wed
      expect(statuses[DateTime(2025, 10, 16)], DayDotStatus.none); // Thu
      expect(statuses[DateTime(2025, 10, 17)], DayDotStatus.none); // Fri
      expect(statuses[DateTime(2025, 10, 18)], DayDotStatus.none); // Sat
      expect(statuses[DateTime(2025, 10, 19)], DayDotStatus.none); // Sun
    });

    test('past days with zero schedules return none', () {
      // Setup: Week starting Monday Oct 6, current time Monday Oct 13
      final weekStart = DateTime(2025, 10, 6);
      final now = DateTime(2025, 10, 13, 10);

      // No schedules, no summaries
      final statuses = computeWeekStatuses(
        weekStart: weekStart,
        medicationSchedules: [],
        fluidSchedule: null,
        summaries: {},
        now: now,
      );

      // All past days with zero schedules should be none
      for (var i = 0; i < 7; i++) {
        final date = weekStart.add(Duration(days: i));
        expect(
          statuses[date],
          DayDotStatus.none,
          reason: 'Day $i should be none',
        );
      }
    });

    test('today with zero schedules returns today', () {
      // Setup: Week containing today (Wednesday)
      final weekStart = DateTime(2025, 10, 6); // Monday
      final now = DateTime(2025, 10, 8, 10); // Wednesday 10 AM

      // No schedules
      final statuses = computeWeekStatuses(
        weekStart: weekStart,
        medicationSchedules: [],
        fluidSchedule: null,
        summaries: {},
        now: now,
      );

      // Past days with zero schedules → none
      expect(statuses[DateTime(2025, 10, 6)], DayDotStatus.none); // Mon
      expect(statuses[DateTime(2025, 10, 7)], DayDotStatus.none); // Tue
      // Today with zero schedules → today (gold)
      expect(statuses[DateTime(2025, 10, 8)], DayDotStatus.today); // Wed
      // Future days → none
      expect(statuses[DateTime(2025, 10, 9)], DayDotStatus.none); // Thu
      expect(statuses[DateTime(2025, 10, 10)], DayDotStatus.none); // Fri
      expect(statuses[DateTime(2025, 10, 11)], DayDotStatus.none); // Sat
      expect(statuses[DateTime(2025, 10, 12)], DayDotStatus.none); // Sun
    });

    test('past day complete when all schedules met', () {
      // Setup: Week starting Monday Oct 6, current time Monday Oct 13
      final weekStart = DateTime(2025, 10, 6);
      final now = DateTime(2025, 10, 13, 10);
      final wednesday = DateTime(2025, 10, 8);

      // 2 medication schedules, 1 dose each on Wednesday
      final schedule1 = _createMedicationSchedule(
        id: 'med1',
        createdAt: weekStart,
        frequency: TreatmentFrequency.onceDaily,
        reminderTimes: [DateTime(2025, 10, 1, 9)], // Time of day only
      );
      final schedule2 = _createMedicationSchedule(
        id: 'med2',
        createdAt: weekStart,
        frequency: TreatmentFrequency.onceDaily,
        reminderTimes: [DateTime(2025, 10, 1, 21)], // Time of day only
      );

      // Summary: both doses completed
      final summary = _createSummary(
        date: wednesday,
        medicationTotalDoses: 2,
        fluidSessionCount: 0,
      );

      final statuses = computeWeekStatuses(
        weekStart: weekStart,
        medicationSchedules: [schedule1, schedule2],
        fluidSchedule: null,
        summaries: {wednesday: summary},
        now: now,
      );

      // Wednesday should be complete (all 2 doses met)
      expect(statuses[wednesday], DayDotStatus.complete);
      // Other days have schedules but no summaries → missed
      expect(statuses[DateTime(2025, 10, 6)], DayDotStatus.missed);
      expect(statuses[DateTime(2025, 10, 7)], DayDotStatus.missed);
    });

    test('past day missed when schedules incomplete', () {
      // Setup: Week starting Monday Oct 6, current time Monday Oct 13
      final weekStart = DateTime(2025, 10, 6);
      final now = DateTime(2025, 10, 13, 10);
      final wednesday = DateTime(2025, 10, 8);

      // 2 medication schedules, 1 dose each on Wednesday
      final schedule1 = _createMedicationSchedule(
        id: 'med1',
        createdAt: weekStart,
        frequency: TreatmentFrequency.onceDaily,
        reminderTimes: [DateTime(2025, 10, 1, 9)],
      );
      final schedule2 = _createMedicationSchedule(
        id: 'med2',
        createdAt: weekStart,
        frequency: TreatmentFrequency.onceDaily,
        reminderTimes: [DateTime(2025, 10, 1, 21)],
      );

      // Summary: only 1 of 2 doses completed
      final summary = _createSummary(
        date: wednesday,
        medicationTotalDoses: 1,
        fluidSessionCount: 0,
      );

      final statuses = computeWeekStatuses(
        weekStart: weekStart,
        medicationSchedules: [schedule1, schedule2],
        fluidSchedule: null,
        summaries: {wednesday: summary},
        now: now,
      );

      // Wednesday should be missed (only 1 of 2 doses)
      expect(statuses[wednesday], DayDotStatus.missed);
    });

    test('past day missed when no summary but scheduled', () {
      // Setup: Week starting Monday Oct 6, current time Monday Oct 13
      final weekStart = DateTime(2025, 10, 6);
      final now = DateTime(2025, 10, 13, 10);
      final wednesday = DateTime(2025, 10, 8);

      // 1 medication schedule on Wednesday
      final schedule = _createMedicationSchedule(
        id: 'med1',
        createdAt: weekStart,
        frequency: TreatmentFrequency.onceDaily,
        reminderTimes: [DateTime(2025, 10, 1, 9)],
      );

      // No summary for Wednesday
      final statuses = computeWeekStatuses(
        weekStart: weekStart,
        medicationSchedules: [schedule],
        fluidSchedule: null,
        summaries: {}, // No summary
        now: now,
      );

      // Wednesday should be missed (scheduled but no data)
      expect(statuses[wednesday], DayDotStatus.missed);
    });

    test('today incomplete shows gold dot', () {
      // Setup: Week containing today (Wednesday)
      final weekStart = DateTime(2025, 10, 6);
      final now = DateTime(2025, 10, 8, 10); // Wednesday 10 AM
      final today = DateTime(2025, 10, 8);

      // 2 medication schedules today
      final schedule1 = _createMedicationSchedule(
        id: 'med1',
        createdAt: weekStart,
        frequency: TreatmentFrequency.onceDaily,
        reminderTimes: [DateTime(2025, 10, 1, 9)],
      );
      final schedule2 = _createMedicationSchedule(
        id: 'med2',
        createdAt: weekStart,
        frequency: TreatmentFrequency.onceDaily,
        reminderTimes: [DateTime(2025, 10, 1, 21)],
      );

      // Summary: only 1 of 2 doses completed
      final summary = _createSummary(
        date: today,
        medicationTotalDoses: 1,
        fluidSessionCount: 0,
      );

      final statuses = computeWeekStatuses(
        weekStart: weekStart,
        medicationSchedules: [schedule1, schedule2],
        fluidSchedule: null,
        summaries: {today: summary},
        now: now,
      );

      // Today should be today (gold, not yet complete)
      expect(statuses[today], DayDotStatus.today);
    });

    test('today complete flips to green', () {
      // Setup: Week containing today (Wednesday)
      final weekStart = DateTime(2025, 10, 6);
      final now = DateTime(2025, 10, 8, 10); // Wednesday 10 AM
      final today = DateTime(2025, 10, 8);

      // 2 medication schedules today
      final schedule1 = _createMedicationSchedule(
        id: 'med1',
        createdAt: weekStart,
        frequency: TreatmentFrequency.onceDaily,
        reminderTimes: [DateTime(2025, 10, 1, 9)],
      );
      final schedule2 = _createMedicationSchedule(
        id: 'med2',
        createdAt: weekStart,
        frequency: TreatmentFrequency.onceDaily,
        reminderTimes: [DateTime(2025, 10, 1, 21)],
      );

      // Summary: both doses completed
      final summary = _createSummary(
        date: today,
        medicationTotalDoses: 2,
        fluidSessionCount: 0,
      );

      final statuses = computeWeekStatuses(
        weekStart: weekStart,
        medicationSchedules: [schedule1, schedule2],
        fluidSchedule: null,
        summaries: {today: summary},
        now: now,
      );

      // Today should be complete (green, all done)
      expect(statuses[today], DayDotStatus.complete);
    });

    test('past day complete when actual exceeds scheduled (>= rule)', () {
      final weekStart = DateTime(2025, 10, 6);
      final now = DateTime(2025, 10, 13, 10);
      final monday = DateTime(2025, 10, 6);

      // 1 med schedule on Monday
      final schedule = _createMedicationSchedule(
        id: 'med1',
        createdAt: weekStart,
        frequency: TreatmentFrequency.onceDaily,
        reminderTimes: [DateTime(2025, 10, 1, 9)],
      );

      // Summary shows 2 doses (user split dose) → should still be complete
      final summary = _createSummary(
        date: monday,
        medicationTotalDoses: 2,
        fluidSessionCount: 0,
      );

      final statuses = computeWeekStatuses(
        weekStart: weekStart,
        medicationSchedules: [schedule],
        fluidSchedule: null,
        summaries: {monday: summary},
        now: now,
      );

      expect(statuses[monday], DayDotStatus.complete);
    });

    test('today complete when fluid sessions exceed scheduled (>= rule)', () {
      final weekStart = DateTime(2025, 10, 6);
      final now = DateTime(2025, 10, 8, 20);
      final today = DateTime(2025, 10, 8);

      final fluidSchedule = _createFluidSchedule(
        id: 'fluid1',
        createdAt: weekStart,
        frequency: TreatmentFrequency.onceDaily,
        reminderTimes: [DateTime(2025, 10, 1, 18)],
      );

      // Summary has 2 fluid sessions (split), scheduled is 1 → complete
      final summary = _createSummary(
        date: today,
        medicationTotalDoses: 0,
        fluidSessionCount: 2,
      );

      final statuses = computeWeekStatuses(
        weekStart: weekStart,
        medicationSchedules: [],
        fluidSchedule: fluidSchedule,
        summaries: {today: summary},
        now: now,
      );

      expect(statuses[today], DayDotStatus.complete);
    });

    test('mixed week realistic scenario', () {
      // Setup: Week starting Monday Oct 6, current time Wednesday Oct 8
      final weekStart = DateTime(2025, 10, 6);
      final now = DateTime(2025, 10, 8, 10); // Wednesday 10 AM

      final monday = DateTime(2025, 10, 6);
      final tuesday = DateTime(2025, 10, 7);
      final wednesday = DateTime(2025, 10, 8);
      final thursday = DateTime(2025, 10, 9);

      // 1 med schedule (once daily), 1 fluid schedule (once daily)
      final medSchedule = _createMedicationSchedule(
        id: 'med1',
        createdAt: weekStart,
        frequency: TreatmentFrequency.onceDaily,
        reminderTimes: [DateTime(2025, 10, 1, 9)],
      );
      final fluidSchedule = _createFluidSchedule(
        id: 'fluid1',
        createdAt: weekStart,
        frequency: TreatmentFrequency.onceDaily,
        reminderTimes: [DateTime(2025, 10, 1, 18)],
      );

      // Summaries
      final summaries = {
        monday: _createSummary(
          date: monday,
          medicationTotalDoses: 1,
          fluidSessionCount: 1,
        ), // Complete
        tuesday: _createSummary(
          date: tuesday,
          medicationTotalDoses: 1,
          fluidSessionCount: 0,
        ), // Missed fluid
        wednesday: _createSummary(
          date: wednesday,
          medicationTotalDoses: 0,
          fluidSessionCount: 0,
        ), // Today, incomplete
      };

      final statuses = computeWeekStatuses(
        weekStart: weekStart,
        medicationSchedules: [medSchedule],
        fluidSchedule: fluidSchedule,
        summaries: summaries,
        now: now,
      );

      // Monday: complete (both done)
      expect(statuses[monday], DayDotStatus.complete);
      // Tuesday: missed (fluid not done)
      expect(statuses[tuesday], DayDotStatus.missed);
      // Wednesday (today): today (incomplete)
      expect(statuses[wednesday], DayDotStatus.today);
      // Thursday-Sunday: future
      expect(statuses[thursday], DayDotStatus.none);
      expect(statuses[DateTime(2025, 10, 10)], DayDotStatus.none);
      expect(statuses[DateTime(2025, 10, 11)], DayDotStatus.none);
      expect(statuses[DateTime(2025, 10, 12)], DayDotStatus.none);
    });

    test('every other day schedule respects frequency', () {
      // Setup: Week starting Monday Oct 6, current time Monday Oct 13
      final weekStart = DateTime(2025, 10, 6);
      final now = DateTime(2025, 10, 13, 10);

      final monday = DateTime(2025, 10, 6);
      final tuesday = DateTime(2025, 10, 7);
      final wednesday = DateTime(2025, 10, 8);
      final thursday = DateTime(2025, 10, 9);
      final friday = DateTime(2025, 10, 10);
      final saturday = DateTime(2025, 10, 11);
      final sunday = DateTime(2025, 10, 12);

      // Every other day schedule, created on Monday
      final schedule = _createMedicationSchedule(
        id: 'med1',
        createdAt: monday,
        frequency: TreatmentFrequency.everyOtherDay,
        reminderTimes: [DateTime(2025, 10, 1, 9)],
      );

      // Summaries for scheduled days (Mon, Wed, Fri, Sun)
      // Every other day from Monday: Mon (day 0), Wed (day 2),
      // Fri (day 4), Sun (day 6)
      final summaries = {
        monday: _createSummary(
          date: monday,
          medicationTotalDoses: 1,
          fluidSessionCount: 0,
        ),
        wednesday: _createSummary(
          date: wednesday,
          medicationTotalDoses: 1,
          fluidSessionCount: 0,
        ),
        friday: _createSummary(
          date: friday,
          medicationTotalDoses: 1,
          fluidSessionCount: 0,
        ),
        sunday: _createSummary(
          date: sunday,
          medicationTotalDoses: 1,
          fluidSessionCount: 0,
        ),
      };

      final statuses = computeWeekStatuses(
        weekStart: weekStart,
        medicationSchedules: [schedule],
        fluidSchedule: null,
        summaries: summaries,
        now: now,
      );

      // Scheduled days
      // (Mon, Wed, Fri, Sun - every other day from Mon): complete
      expect(statuses[monday], DayDotStatus.complete);
      expect(statuses[wednesday], DayDotStatus.complete);
      expect(statuses[friday], DayDotStatus.complete);
      expect(statuses[sunday], DayDotStatus.complete);
      // Non-scheduled days (Tue, Thu, Sat): none (no schedules per frequency)
      expect(statuses[tuesday], DayDotStatus.none);
      expect(statuses[thursday], DayDotStatus.none);
      expect(statuses[saturday], DayDotStatus.none);
    });

    test('mixed schedules: medication complete but fluid missed', () {
      // Edge case: One treatment type completed, another missed
      final weekStart = DateTime(2025, 10, 6);
      final now = DateTime(2025, 10, 13, 10);
      final monday = DateTime(2025, 10, 6);

      // Both medication and fluid scheduled
      final medSchedule = _createMedicationSchedule(
        id: 'med1',
        createdAt: weekStart,
        frequency: TreatmentFrequency.onceDaily,
        reminderTimes: [DateTime(2025, 10, 1, 9)],
      );
      final fluidSchedule = _createFluidSchedule(
        id: 'fluid1',
        createdAt: weekStart,
        frequency: TreatmentFrequency.onceDaily,
        reminderTimes: [DateTime(2025, 10, 1, 18)],
      );

      // Summary: medication done (1 of 1), fluid missed (0 of 1)
      final summary = _createSummary(
        date: monday,
        medicationTotalDoses: 1,
        fluidSessionCount: 0,
      );

      final statuses = computeWeekStatuses(
        weekStart: weekStart,
        medicationSchedules: [medSchedule],
        fluidSchedule: fluidSchedule,
        summaries: {monday: summary},
        now: now,
      );

      // Should be missed because fluid was not completed
      expect(statuses[monday], DayDotStatus.missed);
    });

    test('mixed schedules: fluid complete but medication missed', () {
      // Edge case: Opposite - fluid done, medication missed
      final weekStart = DateTime(2025, 10, 6);
      final now = DateTime(2025, 10, 13, 10);
      final monday = DateTime(2025, 10, 6);

      final medSchedule = _createMedicationSchedule(
        id: 'med1',
        createdAt: weekStart,
        frequency: TreatmentFrequency.onceDaily,
        reminderTimes: [DateTime(2025, 10, 1, 9)],
      );
      final fluidSchedule = _createFluidSchedule(
        id: 'fluid1',
        createdAt: weekStart,
        frequency: TreatmentFrequency.onceDaily,
        reminderTimes: [DateTime(2025, 10, 1, 18)],
      );

      // Summary: medication missed (0 of 1), fluid done (1 of 1)
      final summary = _createSummary(
        date: monday,
        medicationTotalDoses: 0,
        fluidSessionCount: 1,
      );

      final statuses = computeWeekStatuses(
        weekStart: weekStart,
        medicationSchedules: [medSchedule],
        fluidSchedule: fluidSchedule,
        summaries: {monday: summary},
        now: now,
      );

      // Should be missed because medication was not completed
      expect(statuses[monday], DayDotStatus.missed);
    });

    test('multiple medications: some complete some missed', () {
      // Edge case: 3 medications, 2 completed, 1 missed
      final weekStart = DateTime(2025, 10, 6);
      final now = DateTime(2025, 10, 13, 10);
      final monday = DateTime(2025, 10, 6);

      final schedule1 = _createMedicationSchedule(
        id: 'med1',
        createdAt: weekStart,
        frequency: TreatmentFrequency.onceDaily,
        reminderTimes: [DateTime(2025, 10, 1, 8)],
      );
      final schedule2 = _createMedicationSchedule(
        id: 'med2',
        createdAt: weekStart,
        frequency: TreatmentFrequency.onceDaily,
        reminderTimes: [DateTime(2025, 10, 1, 12)],
      );
      final schedule3 = _createMedicationSchedule(
        id: 'med3',
        createdAt: weekStart,
        frequency: TreatmentFrequency.onceDaily,
        reminderTimes: [DateTime(2025, 10, 1, 20)],
      );

      // Summary: only 2 of 3 doses
      final summary = _createSummary(
        date: monday,
        medicationTotalDoses: 2,
        fluidSessionCount: 0,
      );

      final statuses = computeWeekStatuses(
        weekStart: weekStart,
        medicationSchedules: [schedule1, schedule2, schedule3],
        fluidSchedule: null,
        summaries: {monday: summary},
        now: now,
      );

      // Should be missed (not all medications completed)
      expect(statuses[monday], DayDotStatus.missed);
    });

    test('only medication scheduled and completed', () {
      // Edge case: Only medication type scheduled, fluid not scheduled
      final weekStart = DateTime(2025, 10, 6);
      final now = DateTime(2025, 10, 13, 10);
      final monday = DateTime(2025, 10, 6);

      final medSchedule = _createMedicationSchedule(
        id: 'med1',
        createdAt: weekStart,
        frequency: TreatmentFrequency.onceDaily,
        reminderTimes: [DateTime(2025, 10, 1, 9)],
      );

      final summary = _createSummary(
        date: monday,
        medicationTotalDoses: 1,
        fluidSessionCount: 0,
      );

      final statuses = computeWeekStatuses(
        weekStart: weekStart,
        medicationSchedules: [medSchedule],
        fluidSchedule: null, // No fluid scheduled
        summaries: {monday: summary},
        now: now,
      );

      // Should be complete (medication done, fluid not required)
      expect(statuses[monday], DayDotStatus.complete);
    });

    test('only fluid scheduled and completed', () {
      // Edge case: Only fluid type scheduled, medication not scheduled
      final weekStart = DateTime(2025, 10, 6);
      final now = DateTime(2025, 10, 13, 10);
      final monday = DateTime(2025, 10, 6);

      final fluidSchedule = _createFluidSchedule(
        id: 'fluid1',
        createdAt: weekStart,
        frequency: TreatmentFrequency.onceDaily,
        reminderTimes: [DateTime(2025, 10, 1, 18)],
      );

      final summary = _createSummary(
        date: monday,
        medicationTotalDoses: 0,
        fluidSessionCount: 1,
      );

      final statuses = computeWeekStatuses(
        weekStart: weekStart,
        medicationSchedules: [], // No medication scheduled
        fluidSchedule: fluidSchedule,
        summaries: {monday: summary},
        now: now,
      );

      // Should be complete (fluid done, medication not required)
      expect(statuses[monday], DayDotStatus.complete);
    });

    test('today with mixed types: one complete one incomplete', () {
      // Edge case: Today with medication complete but fluid incomplete
      final weekStart = DateTime(2025, 10, 6);
      final now = DateTime(2025, 10, 8, 10); // Wednesday 10 AM
      final today = DateTime(2025, 10, 8);

      final medSchedule = _createMedicationSchedule(
        id: 'med1',
        createdAt: weekStart,
        frequency: TreatmentFrequency.onceDaily,
        reminderTimes: [DateTime(2025, 10, 1, 9)],
      );
      final fluidSchedule = _createFluidSchedule(
        id: 'fluid1',
        createdAt: weekStart,
        frequency: TreatmentFrequency.onceDaily,
        reminderTimes: [DateTime(2025, 10, 1, 18)],
      );

      // Summary: medication complete, fluid not yet done
      final summary = _createSummary(
        date: today,
        medicationTotalDoses: 1,
        fluidSessionCount: 0,
      );

      final statuses = computeWeekStatuses(
        weekStart: weekStart,
        medicationSchedules: [medSchedule],
        fluidSchedule: fluidSchedule,
        summaries: {today: summary},
        now: now,
      );

      // Should be today (gold) because fluid not yet complete
      expect(statuses[today], DayDotStatus.today);
    });
  });
}

// Helper functions

Schedule _createMedicationSchedule({
  required String id,
  required DateTime createdAt,
  required TreatmentFrequency frequency,
  required List<DateTime> reminderTimes,
}) {
  return Schedule(
    id: id,
    treatmentType: TreatmentType.medication,
    frequency: frequency,
    reminderTimes: reminderTimes,
    isActive: true,
    createdAt: createdAt,
    updatedAt: createdAt,
    medicationName: 'TestMed',
    targetDosage: 1,
    medicationUnit: 'mg',
  );
}

Schedule _createFluidSchedule({
  required String id,
  required DateTime createdAt,
  required TreatmentFrequency frequency,
  required List<DateTime> reminderTimes,
}) {
  return Schedule(
    id: id,
    treatmentType: TreatmentType.fluid,
    frequency: frequency,
    reminderTimes: reminderTimes,
    isActive: true,
    createdAt: createdAt,
    updatedAt: createdAt,
    targetVolume: 100,
    preferredLocation: FluidLocation.shoulderBladeLeft,
    needleGauge: NeedleGauge.gauge18,
  );
}

DailySummary _createSummary({
  required DateTime date,
  required int medicationTotalDoses,
  required int fluidSessionCount,
}) {
  return DailySummary(
    date: date,
    overallStreak: 0,
    medicationTotalDoses: medicationTotalDoses,
    medicationScheduledDoses: 0,
    medicationMissedCount: 0,
    fluidTotalVolume: 0,
    fluidTreatmentDone: false,
    fluidSessionCount: fluidSessionCount,
    fluidScheduledSessions: 0,
    overallTreatmentDone: false,
    createdAt: date,
  );
}
