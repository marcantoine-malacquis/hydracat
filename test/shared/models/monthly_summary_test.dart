import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/shared/models/monthly_summary.dart';

MonthlySummary _buildSummary({
  List<int>? dailyVolumes,
  List<int>? dailyGoals,
  List<int>? dailyScheduledSessions,
  List<int>? dailyMedicationDoses,
  List<int>? dailyMedicationScheduledDoses,
}) {
  return MonthlySummary(
    startDate: DateTime(2025, 10),
    endDate: DateTime(2025, 10, 31),
    dailyVolumes: dailyVolumes ?? List.filled(31, 0),
    dailyGoals: dailyGoals ?? List.filled(31, 0),
    dailyScheduledSessions: dailyScheduledSessions ?? List.filled(31, 0),
    dailyMedicationDoses: dailyMedicationDoses ?? List.filled(31, 0),
    dailyMedicationScheduledDoses:
        dailyMedicationScheduledDoses ?? List.filled(31, 0),
    fluidTreatmentDays: 0,
    fluidMissedDays: 0,
    fluidLongestStreak: 0,
    fluidCurrentStreak: 0,
    medicationMonthlyAdherence: 0,
    medicationLongestStreak: 0,
    medicationCurrentStreak: 0,
    overallTreatmentDays: 0,
    overallMissedDays: 0,
    overallLongestStreak: 0,
    overallCurrentStreak: 0,
    medicationTotalDoses: 0,
    medicationScheduledDoses: 0,
    medicationMissedCount: 0,
    fluidTotalVolume: 0,
    fluidTreatmentDone: false,
    fluidSessionCount: 0,
    fluidScheduledSessions: 0,
    overallTreatmentDone: false,
    createdAt: DateTime(2025, 10),
  );
}

void main() {
  group('MonthlySummary List Fields', () {
    group('Serialization and Deserialization', () {
      test('toJson and fromJson roundtrip preserves lists', () {
        final original = MonthlySummary(
          startDate: DateTime(2025, 10),
          endDate: DateTime(2025, 10, 31),
          dailyVolumes: List.generate(31, (i) => i * 10),
          dailyGoals: List.filled(31, 250),
          dailyScheduledSessions: List.filled(31, 2),
          dailyMedicationDoses: List.generate(31, (i) => i % 4),
          dailyMedicationScheduledDoses: List.filled(31, 3),
          fluidTreatmentDays: 15,
          fluidMissedDays: 10,
          fluidLongestStreak: 5,
          fluidCurrentStreak: 3,
          medicationMonthlyAdherence: 0.85,
          medicationLongestStreak: 10,
          medicationCurrentStreak: 8,
          overallTreatmentDays: 20,
          overallMissedDays: 5,
          overallLongestStreak: 12,
          overallCurrentStreak: 6,
          medicationTotalDoses: 85,
          medicationScheduledDoses: 100,
          medicationMissedCount: 15,
          fluidTotalVolume: 7500,
          fluidTreatmentDone: true,
          fluidSessionCount: 45,
          fluidScheduledSessions: 62,
          overallTreatmentDone: true,
          createdAt: DateTime(2025, 10),
        );

        final json = original.toJson();
        final parsed = MonthlySummary.fromJson(json);

        expect(parsed, equals(original));
        expect(parsed.dailyVolumes.length, 31);
        expect(parsed.dailyVolumes[0], 0);
        expect(parsed.dailyVolumes[5], 50);
        expect(parsed.dailyGoals, List.filled(31, 250));
        expect(parsed.dailyScheduledSessions, List.filled(31, 2));
        expect(parsed.dailyMedicationDoses, List.generate(31, (i) => i % 4));
        expect(parsed.dailyMedicationScheduledDoses, List.filled(31, 3));
      });

      test('fromJson handles missing lists by defaulting to zeros', () {
        final json = {
          'startDate': '2025-10-01T00:00:00.000',
          'endDate': '2025-10-31T23:59:59.000',
          'fluidTreatmentDays': 0,
          'fluidMissedDays': 0,
          'fluidLongestStreak': 0,
          'fluidCurrentStreak': 0,
          'medicationMonthlyAdherence': 0.0,
          'medicationLongestStreak': 0,
          'medicationCurrentStreak': 0,
          'overallTreatmentDays': 0,
          'overallMissedDays': 0,
          'overallLongestStreak': 0,
          'overallCurrentStreak': 0,
          'medicationTotalDoses': 0,
          'medicationScheduledDoses': 0,
          'medicationMissedCount': 0,
          'fluidTotalVolume': 0,
          'fluidTreatmentDone': false,
          'fluidSessionCount': 0,
          'fluidScheduledSessions': 0,
          'overallTreatmentDone': false,
          'createdAt': '2025-10-01T00:00:00.000',
          // dailyVolumes, dailyGoals, dailyScheduledSessions are missing
        };

        final summary = MonthlySummary.fromJson(json);

        expect(summary.dailyVolumes, List.filled(31, 0));
        expect(summary.dailyGoals, List.filled(31, 0));
        expect(summary.dailyScheduledSessions, List.filled(31, 0));
        expect(summary.dailyMedicationDoses, List.filled(31, 0));
        expect(summary.dailyMedicationScheduledDoses, List.filled(31, 0));
      });

      test('fromJson handles null lists by defaulting to zeros', () {
        final json = {
          'startDate': '2025-10-01T00:00:00.000',
          'endDate': '2025-10-31T23:59:59.000',
          'dailyVolumes': null,
          'dailyGoals': null,
          'dailyScheduledSessions': null,
          'fluidTreatmentDays': 0,
          'fluidMissedDays': 0,
          'fluidLongestStreak': 0,
          'fluidCurrentStreak': 0,
          'medicationMonthlyAdherence': 0.0,
          'medicationLongestStreak': 0,
          'medicationCurrentStreak': 0,
          'overallTreatmentDays': 0,
          'overallMissedDays': 0,
          'overallLongestStreak': 0,
          'overallCurrentStreak': 0,
          'medicationTotalDoses': 0,
          'medicationScheduledDoses': 0,
          'medicationMissedCount': 0,
          'fluidTotalVolume': 0,
          'fluidTreatmentDone': false,
          'fluidSessionCount': 0,
          'fluidScheduledSessions': 0,
          'overallTreatmentDone': false,
          'createdAt': '2025-10-01T00:00:00.000',
        };

        final summary = MonthlySummary.fromJson(json);

        expect(summary.dailyVolumes, List.filled(31, 0));
        expect(summary.dailyGoals, List.filled(31, 0));
        expect(summary.dailyScheduledSessions, List.filled(31, 0));
        expect(summary.dailyMedicationDoses, List.filled(31, 0));
        expect(summary.dailyMedicationScheduledDoses, List.filled(31, 0));
      });
    });

    group('Padding and Truncation', () {
      test('pads short lists with zeros', () {
        final json = {
          'startDate': '2025-10-01T00:00:00.000',
          'endDate': '2025-10-31T23:59:59.000',
          'dailyVolumes': <int>[100, 200], // Only 2 for 31-day month
          'dailyGoals': <int>[250], // Only 1
          'dailyScheduledSessions': <int>[], // Empty
          'dailyMedicationDoses': <int>[1, 2, 3],
          'dailyMedicationScheduledDoses': <int>[4],
          'fluidTreatmentDays': 0,
          'fluidMissedDays': 0,
          'fluidLongestStreak': 0,
          'fluidCurrentStreak': 0,
          'medicationMonthlyAdherence': 0.0,
          'medicationLongestStreak': 0,
          'medicationCurrentStreak': 0,
          'overallTreatmentDays': 0,
          'overallMissedDays': 0,
          'overallLongestStreak': 0,
          'overallCurrentStreak': 0,
          'medicationTotalDoses': 0,
          'medicationScheduledDoses': 0,
          'medicationMissedCount': 0,
          'fluidTotalVolume': 0,
          'fluidTreatmentDone': false,
          'fluidSessionCount': 0,
          'fluidScheduledSessions': 0,
          'overallTreatmentDone': false,
          'createdAt': '2025-10-01T00:00:00.000',
        };

        final summary = MonthlySummary.fromJson(json);

        expect(summary.dailyVolumes.length, 31);
        expect(summary.dailyVolumes.sublist(0, 2), [100, 200]);
        expect(summary.dailyVolumes.sublist(2), List.filled(29, 0));

        expect(summary.dailyGoals.length, 31);
        expect(summary.dailyGoals[0], 250);
        expect(summary.dailyGoals.sublist(1), List.filled(30, 0));

        expect(summary.dailyScheduledSessions.length, 31);
        expect(summary.dailyScheduledSessions, List.filled(31, 0));

        expect(summary.dailyMedicationDoses.length, 31);
        expect(summary.dailyMedicationDoses.sublist(0, 3), [1, 2, 3]);
        expect(summary.dailyMedicationDoses.sublist(3), List.filled(28, 0));

        expect(summary.dailyMedicationScheduledDoses.length, 31);
        expect(summary.dailyMedicationScheduledDoses[0], 4);
        expect(
          summary.dailyMedicationScheduledDoses.sublist(1),
          List.filled(30, 0),
        );
      });

      test('truncates long lists', () {
        final json = {
          'startDate': '2025-10-01T00:00:00.000',
          'endDate': '2025-10-31T23:59:59.000',
          'dailyVolumes': List.filled(50, 100), // 50 for 31-day month
          'dailyGoals': List.filled(40, 250),
          'dailyScheduledSessions': List.filled(35, 2),
          'dailyMedicationDoses': List.filled(60, 5),
          'dailyMedicationScheduledDoses': List.filled(45, 6),
          'fluidTreatmentDays': 0,
          'fluidMissedDays': 0,
          'fluidLongestStreak': 0,
          'fluidCurrentStreak': 0,
          'medicationMonthlyAdherence': 0.0,
          'medicationLongestStreak': 0,
          'medicationCurrentStreak': 0,
          'overallTreatmentDays': 0,
          'overallMissedDays': 0,
          'overallLongestStreak': 0,
          'overallCurrentStreak': 0,
          'medicationTotalDoses': 0,
          'medicationScheduledDoses': 0,
          'medicationMissedCount': 0,
          'fluidTotalVolume': 0,
          'fluidTreatmentDone': false,
          'fluidSessionCount': 0,
          'fluidScheduledSessions': 0,
          'overallTreatmentDone': false,
          'createdAt': '2025-10-01T00:00:00.000',
        };

        final summary = MonthlySummary.fromJson(json);

        expect(summary.dailyVolumes.length, 31);
        expect(summary.dailyVolumes, List.filled(31, 100));

        expect(summary.dailyGoals.length, 31);
        expect(summary.dailyGoals, List.filled(31, 250));

        expect(summary.dailyScheduledSessions.length, 31);
        expect(summary.dailyScheduledSessions, List.filled(31, 2));

        expect(summary.dailyMedicationDoses.length, 31);
        expect(summary.dailyMedicationDoses, List.filled(31, 5));

        expect(summary.dailyMedicationScheduledDoses.length, 31);
        expect(summary.dailyMedicationScheduledDoses, List.filled(31, 6));
      });
    });

    group('Validation', () {
      test('valid lists pass validation', () {
        final summary = MonthlySummary.empty(DateTime(2025, 10, 15));
        expect(summary.validate(), isEmpty);
      });

      test('detects wrong list lengths', () {
        final summary = _buildSummary(
          dailyVolumes: List.filled(30, 0), // Wrong: 30 instead of 31
        );

        final errors = summary.validate();
        expect(
          errors.any(
            (e) => e.contains('dailyVolumes length (30) must match'),
          ),
          isTrue,
        );
      });

      test('detects out-of-bounds values in dailyVolumes', () {
        final volumes = List<int>.filled(31, 0);
        volumes[0] = -10; // Negative
        volumes[15] = 6000; // Too high

        final summary = _buildSummary(dailyVolumes: volumes);

        final errors = summary.validate();
        expect(
          errors.any((e) => e.contains('dailyVolumes[1] value (-10)')),
          isTrue,
        );
        expect(
          errors.any((e) => e.contains('dailyVolumes[16] value (6000)')),
          isTrue,
        );
      });

      test('detects out-of-bounds values in dailyScheduledSessions', () {
        final sessions = List<int>.filled(31, 0);
        sessions[10] = 15; // Too high (max is 10)

        final summary = _buildSummary(dailyScheduledSessions: sessions);

        final errors = summary.validate();
        expect(
          errors.any(
            (e) => e.contains('dailyScheduledSessions[11] value (15)'),
          ),
          isTrue,
        );
      });

      test('detects wrong medication list lengths', () {
        final summary = _buildSummary(
          dailyMedicationDoses: List.filled(30, 0),
        );

        final errors = summary.validate();
        expect(
          errors.any(
            (e) => e.contains('dailyMedicationDoses length (30) must match'),
          ),
          isTrue,
        );
      });

      test('detects out-of-bounds medication arrays', () {
        final medicationDoses = List<int>.filled(31, 0);
        medicationDoses[0] = -1;
        medicationDoses[5] = 25;

        final medicationScheduled = List<int>.filled(31, 0);
        medicationScheduled[2] = 12;

        final summary = _buildSummary(
          dailyMedicationDoses: medicationDoses,
          dailyMedicationScheduledDoses: medicationScheduled,
        );

        final errors = summary.validate();
        expect(
          errors.any(
            (e) => e.contains('dailyMedicationDoses[1] value (-1)'),
          ),
          isTrue,
        );
        expect(
          errors.any(
            (e) => e.contains('dailyMedicationDoses[6] value (25)'),
          ),
          isTrue,
        );
        expect(
          errors.any(
            (e) =>
                e.contains('dailyMedicationScheduledDoses[3] value (12)'),
          ),
          isTrue,
        );
      });
    });

    group('Edge Cases', () {
      test('handles February leap year (29 days)', () {
        final summary = MonthlySummary.empty(DateTime(2024, 2, 15));
        expect(summary.dailyVolumes.length, 29);
        expect(summary.dailyGoals.length, 29);
        expect(summary.dailyScheduledSessions.length, 29);
        expect(summary.dailyMedicationDoses.length, 29);
        expect(summary.dailyMedicationScheduledDoses.length, 29);
        expect(summary.daysInMonth, 29);
        expect(summary.validate(), isEmpty);
      });

      test('handles February non-leap year (28 days)', () {
        final summary = MonthlySummary.empty(DateTime(2025, 2, 15));
        expect(summary.dailyVolumes.length, 28);
        expect(summary.dailyGoals.length, 28);
        expect(summary.dailyScheduledSessions.length, 28);
        expect(summary.dailyMedicationDoses.length, 28);
        expect(summary.dailyMedicationScheduledDoses.length, 28);
        expect(summary.daysInMonth, 28);
        expect(summary.validate(), isEmpty);
      });

      test('handles 30-day months', () {
        final summary = MonthlySummary.empty(DateTime(2025, 4, 15)); // April
        expect(summary.dailyVolumes.length, 30);
        expect(summary.dailyGoals.length, 30);
        expect(summary.dailyScheduledSessions.length, 30);
        expect(summary.dailyMedicationDoses.length, 30);
        expect(summary.dailyMedicationScheduledDoses.length, 30);
        expect(summary.daysInMonth, 30);
        expect(summary.validate(), isEmpty);
      });

      test('handles 31-day months', () {
        final summary = MonthlySummary.empty(DateTime(2025, 1, 15)); // January
        expect(summary.dailyVolumes.length, 31);
        expect(summary.dailyGoals.length, 31);
        expect(summary.dailyScheduledSessions.length, 31);
        expect(summary.dailyMedicationDoses.length, 31);
        expect(summary.dailyMedicationScheduledDoses.length, 31);
        expect(summary.daysInMonth, 31);
        expect(summary.validate(), isEmpty);
      });

      test('clamps extreme values during deserialization', () {
        final json = {
          'startDate': '2025-10-01T00:00:00.000',
          'endDate': '2025-10-31T23:59:59.000',
          'dailyVolumes': [-500, 10000, 250],
          'dailyGoals': [-100, 250, 8000],
          'dailyScheduledSessions': List.filled(31, 0),
          'dailyMedicationDoses': [-5, 12, 4],
          'dailyMedicationScheduledDoses': [20, -1, 8],
          'fluidTreatmentDays': 0,
          'fluidMissedDays': 0,
          'fluidLongestStreak': 0,
          'fluidCurrentStreak': 0,
          'medicationMonthlyAdherence': 0.0,
          'medicationLongestStreak': 0,
          'medicationCurrentStreak': 0,
          'overallTreatmentDays': 0,
          'overallMissedDays': 0,
          'overallLongestStreak': 0,
          'overallCurrentStreak': 0,
          'medicationTotalDoses': 0,
          'medicationScheduledDoses': 0,
          'medicationMissedCount': 0,
          'fluidTotalVolume': 0,
          'fluidTreatmentDone': false,
          'fluidSessionCount': 0,
          'fluidScheduledSessions': 0,
          'overallTreatmentDone': false,
          'createdAt': '2025-10-01T00:00:00.000',
        };

        final summary = MonthlySummary.fromJson(json);

        // Clamped from -500 to 0
        expect(summary.dailyVolumes[0], 0);
        // Clamped from 10000 to 5000
        expect(summary.dailyVolumes[1], 5000);
        // Unchanged
        expect(summary.dailyVolumes[2], 250);

        // Clamped from -100 to 0
        expect(summary.dailyGoals[0], 0);
        // Unchanged
        expect(summary.dailyGoals[1], 250);
        // Clamped from 8000 to 5000
        expect(summary.dailyGoals[2], 5000);

        // Medication clamps to 0-10
        expect(summary.dailyMedicationDoses[0], 0);
        expect(summary.dailyMedicationDoses[1], 10);
        expect(summary.dailyMedicationDoses[2], 4);
        expect(summary.dailyMedicationScheduledDoses[0], 10);
        expect(summary.dailyMedicationScheduledDoses[1], 0);
        expect(summary.dailyMedicationScheduledDoses[2], 8);
      });
    });

    group('copyWith', () {
      test('replacing lists works correctly', () {
        final original = MonthlySummary.empty(DateTime(2025, 10, 15));
        final newVolumes = List.generate(31, (i) => i * 5);
        final newGoals = List.filled(31, 300);
        final newMedDoses = List.filled(31, 2);
        final newMedScheduled = List.filled(31, 3);

        final updated = original.copyWith(
          dailyVolumes: newVolumes,
          dailyGoals: newGoals,
          dailyMedicationDoses: newMedDoses,
          dailyMedicationScheduledDoses: newMedScheduled,
        );

        expect(updated.dailyVolumes, newVolumes);
        expect(updated.dailyGoals, newGoals);
        expect(
          updated.dailyScheduledSessions,
          original.dailyScheduledSessions,
        );
        expect(updated.dailyMedicationDoses, newMedDoses);
        expect(updated.dailyMedicationScheduledDoses, newMedScheduled);
      });

      test('unchanged lists remain the same', () {
        final original = MonthlySummary.empty(DateTime(2025, 10, 15));
        final updated = original.copyWith(fluidTreatmentDays: 5);

        expect(updated.dailyVolumes, original.dailyVolumes);
        expect(updated.dailyGoals, original.dailyGoals);
        expect(updated.dailyScheduledSessions, original.dailyScheduledSessions);
        expect(updated.dailyMedicationDoses, original.dailyMedicationDoses);
        expect(
          updated.dailyMedicationScheduledDoses,
          original.dailyMedicationScheduledDoses,
        );
      });
    });

    group('Equality', () {
      test('lists affect equality comparison', () {
        final createdAt = DateTime(2025, 10);
        final summary1 = MonthlySummary.empty(
          DateTime(2025, 10, 15),
        ).copyWith(createdAt: createdAt);
        final summary2 = MonthlySummary.empty(
          DateTime(2025, 10, 15),
        ).copyWith(createdAt: createdAt);

        expect(summary1, equals(summary2));
      });

      test('identical lists produce equality', () {
        final createdAt = DateTime(2025, 10);
        final volumes = List.generate(31, (i) => i * 10);
        final summary1 = MonthlySummary.empty(
          DateTime(2025, 10, 15),
        ).copyWith(dailyVolumes: volumes, createdAt: createdAt);
        final summary2 = MonthlySummary.empty(
          DateTime(2025, 10, 15),
        ).copyWith(dailyVolumes: List<int>.from(volumes), createdAt: createdAt);

        expect(summary1, equals(summary2));
      });

      test('different lists produce inequality', () {
        final summary1 = MonthlySummary.empty(DateTime(2025, 10, 15));
        final summary2 = MonthlySummary.empty(DateTime(2025, 10, 15)).copyWith(
          dailyVolumes: List.generate(31, (i) => i * 10),
        );

        expect(summary1, isNot(equals(summary2)));
      });

      test('hashCode includes lists', () {
        final summary1 = MonthlySummary.empty(DateTime(2025, 10, 15));
        final summary2 = MonthlySummary.empty(DateTime(2025, 10, 15)).copyWith(
          dailyVolumes: List.generate(31, (i) => i * 10),
        );

        expect(summary1.hashCode, isNot(equals(summary2.hashCode)));
      });
    });
  });
}
