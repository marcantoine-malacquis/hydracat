import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/features/logging/models/daily_summary_cache.dart';

void main() {
  group('DailySummaryCache', () {
    group('hasMedicationLoggedNear', () {
      test('returns false when medication not logged today', () {
        const cache = DailySummaryCache(
          date: '2025-10-13',
          medicationSessionCount: 0,
          fluidSessionCount: 0,
          medicationNames: [],
          totalMedicationDosesGiven: 0,
          totalFluidVolumeGiven: 0,
          medicationRecentTimes: {},
        );

        final scheduledTime = DateTime(2025, 10, 13, 8); // 8:00 AM
        final result = cache.hasMedicationLoggedNear(
          'Amlodipine',
          scheduledTime,
        );

        expect(result, false);
      });

      test(
        'returns false when medication logged but outside time window (>2h)',
        () {
          final scheduledTime = DateTime(2025, 10, 13, 8); // 8:00 AM
          final loggedTime = DateTime(
            2025,
            10,
            13,
            11,
          ); // 11:00 AM (3 hours later)

          final cache = DailySummaryCache(
            date: '2025-10-13',
            medicationSessionCount: 1,
            fluidSessionCount: 0,
            medicationNames: const ['Amlodipine'],
            totalMedicationDosesGiven: 2.5,
            totalFluidVolumeGiven: 0,
            medicationRecentTimes: {
              'Amlodipine': [loggedTime.toIso8601String()],
            },
          );

          final result = cache.hasMedicationLoggedNear(
            'Amlodipine',
            scheduledTime,
          );

          expect(result, false);
        },
      );

      test('returns true when medication logged within 2h window (before)', () {
        final scheduledTime = DateTime(2025, 10, 13, 8); // 8:00 AM
        final loggedTime = DateTime(
          2025,
          10,
          13,
          6,
          30,
        ); // 6:30 AM (1.5h before)

        final cache = DailySummaryCache(
          date: '2025-10-13',
          medicationSessionCount: 1,
          fluidSessionCount: 0,
          medicationNames: const ['Amlodipine'],
          totalMedicationDosesGiven: 2.5,
          totalFluidVolumeGiven: 0,
          medicationRecentTimes: {
            'Amlodipine': [loggedTime.toIso8601String()],
          },
        );

        final result = cache.hasMedicationLoggedNear(
          'Amlodipine',
          scheduledTime,
        );

        expect(result, true);
      });

      test('returns true when medication logged within 2h window (after)', () {
        final scheduledTime = DateTime(2025, 10, 13, 8); // 8:00 AM
        final loggedTime = DateTime(
          2025,
          10,
          13,
          9,
          30,
        ); // 9:30 AM (1.5h after)

        final cache = DailySummaryCache(
          date: '2025-10-13',
          medicationSessionCount: 1,
          fluidSessionCount: 0,
          medicationNames: const ['Amlodipine'],
          totalMedicationDosesGiven: 2.5,
          totalFluidVolumeGiven: 0,
          medicationRecentTimes: {
            'Amlodipine': [loggedTime.toIso8601String()],
          },
        );

        final result = cache.hasMedicationLoggedNear(
          'Amlodipine',
          scheduledTime,
        );

        expect(result, true);
      });

      test('returns true when medication logged exactly at scheduled time', () {
        final scheduledTime = DateTime(2025, 10, 13, 8); // 8:00 AM
        final loggedTime = DateTime(2025, 10, 13, 8); // 8:00 AM (exact)

        final cache = DailySummaryCache(
          date: '2025-10-13',
          medicationSessionCount: 1,
          fluidSessionCount: 0,
          medicationNames: const ['Amlodipine'],
          totalMedicationDosesGiven: 2.5,
          totalFluidVolumeGiven: 0,
          medicationRecentTimes: {
            'Amlodipine': [loggedTime.toIso8601String()],
          },
        );

        final result = cache.hasMedicationLoggedNear(
          'Amlodipine',
          scheduledTime,
        );

        expect(result, true);
      });

      test('returns true at exactly 2 hour boundary', () {
        final scheduledTime = DateTime(2025, 10, 13, 8); // 8:00 AM
        final loggedTime = DateTime(
          2025,
          10,
          13,
          10,
        ); // 10:00 AM (exactly 2h)

        final cache = DailySummaryCache(
          date: '2025-10-13',
          medicationSessionCount: 1,
          fluidSessionCount: 0,
          medicationNames: const ['Amlodipine'],
          totalMedicationDosesGiven: 2.5,
          totalFluidVolumeGiven: 0,
          medicationRecentTimes: {
            'Amlodipine': [loggedTime.toIso8601String()],
          },
        );

        final result = cache.hasMedicationLoggedNear(
          'Amlodipine',
          scheduledTime,
        );

        expect(result, true);
      });

      test('handles edge case of empty recentTimes list', () {
        const cache = DailySummaryCache(
          date: '2025-10-13',
          medicationSessionCount: 1,
          fluidSessionCount: 0,
          medicationNames: ['Amlodipine'],
          totalMedicationDosesGiven: 2.5,
          totalFluidVolumeGiven: 0,
          medicationRecentTimes: <String, List<String>>{
            'Amlodipine': <String>[], // Empty list
          },
        );

        final scheduledTime = DateTime(2025, 10, 13, 8);
        final result = cache.hasMedicationLoggedNear(
          'Amlodipine',
          scheduledTime,
        );

        expect(result, false);
      });

      test(
        'returns true if ANY logged time is within window (multiple times)',
        () {
          final scheduledTime = DateTime(2025, 10, 13, 8); // 8:00 AM
          final farTime = DateTime(
            2025,
            10,
            13,
            3,
          ); // 3:00 AM (5h before - out of window)
          final nearTime = DateTime(
            2025,
            10,
            13,
            7,
          ); // 7:00 AM (1h before - in window)

          final cache = DailySummaryCache(
            date: '2025-10-13',
            medicationSessionCount: 2,
            fluidSessionCount: 0,
            medicationNames: const ['Amlodipine'],
            totalMedicationDosesGiven: 5,
            totalFluidVolumeGiven: 0,
            medicationRecentTimes: {
              'Amlodipine': [
                farTime.toIso8601String(),
                nearTime.toIso8601String(),
              ],
            },
          );

          final result = cache.hasMedicationLoggedNear(
            'Amlodipine',
            scheduledTime,
          );

          expect(result, true);
        },
      );

      test('returns false if ALL logged times are outside window', () {
        final scheduledTime = DateTime(2025, 10, 13, 8); // 8:00 AM
        final earlyTime = DateTime(2025, 10, 13, 3); // 3:00 AM (5h before)
        final lateTime = DateTime(2025, 10, 13, 15); // 3:00 PM (7h after)

        final cache = DailySummaryCache(
          date: '2025-10-13',
          medicationSessionCount: 2,
          fluidSessionCount: 0,
          medicationNames: const ['Amlodipine'],
          totalMedicationDosesGiven: 5,
          totalFluidVolumeGiven: 0,
          medicationRecentTimes: {
            'Amlodipine': [
              earlyTime.toIso8601String(),
              lateTime.toIso8601String(),
            ],
          },
        );

        final result = cache.hasMedicationLoggedNear(
          'Amlodipine',
          scheduledTime,
        );

        expect(result, false);
      });

      test('returns false for different medication', () {
        final scheduledTime = DateTime(2025, 10, 13, 8);
        final loggedTime = DateTime(2025, 10, 13, 8);

        final cache = DailySummaryCache(
          date: '2025-10-13',
          medicationSessionCount: 1,
          fluidSessionCount: 0,
          medicationNames: const ['Benazepril'],
          totalMedicationDosesGiven: 2.5,
          totalFluidVolumeGiven: 0,
          medicationRecentTimes: {
            'Benazepril': [loggedTime.toIso8601String()],
          },
        );

        // Query for different medication
        final result = cache.hasMedicationLoggedNear(
          'Amlodipine',
          scheduledTime,
        );

        expect(result, false);
      });

      test('handles medication in names but not in recentTimes map', () {
        const cache = DailySummaryCache(
          date: '2025-10-13',
          medicationSessionCount: 1,
          fluidSessionCount: 0,
          medicationNames: ['Amlodipine'],
          totalMedicationDosesGiven: 2.5,
          totalFluidVolumeGiven: 0,
          medicationRecentTimes: {}, // Empty map
        );

        final scheduledTime = DateTime(2025, 10, 13, 8);
        final result = cache.hasMedicationLoggedNear(
          'Amlodipine',
          scheduledTime,
        );

        expect(result, false);
      });
    });

    group('Factory Constructors', () {
      test('empty() creates cache with all counts at zero', () {
        final cache = DailySummaryCache.empty('2025-10-13');

        expect(cache.date, '2025-10-13');
        expect(cache.medicationSessionCount, 0);
        expect(cache.fluidSessionCount, 0);
        expect(cache.medicationNames, const <String>[]);
        expect(cache.totalMedicationDosesGiven, 0);
        expect(cache.totalFluidVolumeGiven, 0);
        expect(cache.medicationRecentTimes, const <String, List<String>>{});
      });
    });

    group('Validation', () {
      test('isValidFor returns true for matching date', () {
        final cache = DailySummaryCache.empty('2025-10-13');

        expect(cache.isValidFor('2025-10-13'), true);
      });

      test('isValidFor returns false for different date', () {
        final cache = DailySummaryCache.empty('2025-10-13');

        expect(cache.isValidFor('2025-10-14'), false);
      });
    });

    group('Query Methods', () {
      test('hasAnySessions returns false for empty cache', () {
        final cache = DailySummaryCache.empty('2025-10-13');

        expect(cache.hasAnySessions, false);
      });

      test('hasAnySessions returns true when medication session exists', () {
        const cache = DailySummaryCache(
          date: '2025-10-13',
          medicationSessionCount: 1,
          fluidSessionCount: 0,
          medicationNames: ['Amlodipine'],
          totalMedicationDosesGiven: 2.5,
          totalFluidVolumeGiven: 0,
        );

        expect(cache.hasAnySessions, true);
      });

      test('hasAnySessions returns true when fluid session exists', () {
        const cache = DailySummaryCache(
          date: '2025-10-13',
          medicationSessionCount: 0,
          fluidSessionCount: 1,
          medicationNames: [],
          totalMedicationDosesGiven: 0,
          totalFluidVolumeGiven: 150,
        );

        expect(cache.hasAnySessions, true);
      });

      test('hasMedicationLogged returns true for existing medication', () {
        const cache = DailySummaryCache(
          date: '2025-10-13',
          medicationSessionCount: 1,
          fluidSessionCount: 0,
          medicationNames: ['Amlodipine'],
          totalMedicationDosesGiven: 2.5,
          totalFluidVolumeGiven: 0,
        );

        expect(cache.hasMedicationLogged('Amlodipine'), true);
      });

      test('hasMedicationLogged returns false for non-existing medication', () {
        const cache = DailySummaryCache(
          date: '2025-10-13',
          medicationSessionCount: 1,
          fluidSessionCount: 0,
          medicationNames: ['Amlodipine'],
          totalMedicationDosesGiven: 2.5,
          totalFluidVolumeGiven: 0,
        );

        expect(cache.hasMedicationLogged('Benazepril'), false);
      });
    });

    group('copyWithSession', () {
      test('adds medication session correctly', () {
        final cache = DailySummaryCache.empty('2025-10-13');

        final updated = cache.copyWithSession(
          medicationName: 'Amlodipine',
          dosageGiven: 2.5,
        );

        expect(updated.medicationSessionCount, 1);
        expect(updated.medicationNames, contains('Amlodipine'));
        expect(updated.totalMedicationDosesGiven, 2.5);
        expect(updated.fluidSessionCount, 0);
      });

      test('adds fluid session correctly', () {
        final cache = DailySummaryCache.empty('2025-10-13');

        final updated = cache.copyWithSession(
          volumeGiven: 150,
        );

        expect(updated.fluidSessionCount, 1);
        expect(updated.totalFluidVolumeGiven, 150);
        expect(updated.medicationSessionCount, 0);
      });

      test('does not add duplicate medication names', () {
        const cache = DailySummaryCache(
          date: '2025-10-13',
          medicationSessionCount: 1,
          fluidSessionCount: 0,
          medicationNames: ['Amlodipine'],
          totalMedicationDosesGiven: 2.5,
          totalFluidVolumeGiven: 0,
        );

        final updated = cache.copyWithSession(
          medicationName: 'Amlodipine',
          dosageGiven: 2.5,
        );

        expect(updated.medicationSessionCount, 2);
        expect(updated.medicationNames.length, 1); // Still only one unique name
        expect(updated.totalMedicationDosesGiven, 5.0); // Doses accumulate
      });
    });

    group('JSON Serialization', () {
      test('toJson includes all fields', () {
        const cache = DailySummaryCache(
          date: '2025-10-13',
          medicationSessionCount: 2,
          fluidSessionCount: 1,
          medicationNames: ['Amlodipine', 'Benazepril'],
          totalMedicationDosesGiven: 5,
          totalFluidVolumeGiven: 150,
          medicationRecentTimes: <String, List<String>>{
            'Amlodipine': <String>['2025-10-13T08:00:00.000'],
          },
        );

        final json = cache.toJson();

        expect(json['date'], '2025-10-13');
        expect(json['medicationSessionCount'], 2);
        expect(json['fluidSessionCount'], 1);
        expect(json['medicationNames'], ['Amlodipine', 'Benazepril']);
        expect(json['totalMedicationDosesGiven'], 5.0);
        expect(json['totalFluidVolumeGiven'], 150);
        expect(json['medicationRecentTimes'], {
          'Amlodipine': ['2025-10-13T08:00:00.000'],
        });
      });

      test('fromJson parses all fields correctly', () {
        final json = <String, dynamic>{
          'date': '2025-10-13',
          'medicationSessionCount': 2,
          'fluidSessionCount': 1,
          'medicationNames': <String>['Amlodipine', 'Benazepril'],
          'totalMedicationDosesGiven': 5.0,
          'totalFluidVolumeGiven': 150.0,
          'medicationRecentTimes': <String, List<String>>{
            'Amlodipine': <String>['2025-10-13T08:00:00.000'],
          },
        };

        final cache = DailySummaryCache.fromJson(json);

        expect(cache.date, '2025-10-13');
        expect(cache.medicationSessionCount, 2);
        expect(cache.fluidSessionCount, 1);
        expect(cache.medicationNames, ['Amlodipine', 'Benazepril']);
        expect(cache.totalMedicationDosesGiven, 5.0);
        expect(cache.totalFluidVolumeGiven, 150.0);
        expect(cache.medicationRecentTimes['Amlodipine'], [
          '2025-10-13T08:00:00.000',
        ]);
      });

      test('round-trip: toJson → fromJson preserves data', () {
        const original = DailySummaryCache(
          date: '2025-10-13',
          medicationSessionCount: 2,
          fluidSessionCount: 1,
          medicationNames: ['Amlodipine'],
          totalMedicationDosesGiven: 5,
          totalFluidVolumeGiven: 150,
          medicationRecentTimes: <String, List<String>>{
            'Amlodipine': <String>[
              '2025-10-13T08:00:00.000',
              '2025-10-13T20:00:00.000',
            ],
          },
        );

        final json = original.toJson();
        final restored = DailySummaryCache.fromJson(json);

        expect(restored.date, original.date);
        expect(
          restored.medicationSessionCount,
          original.medicationSessionCount,
        );
        expect(restored.fluidSessionCount, original.fluidSessionCount);
        expect(restored.medicationNames, original.medicationNames);
        expect(
          restored.totalMedicationDosesGiven,
          original.totalMedicationDosesGiven,
        );
        expect(restored.totalFluidVolumeGiven, original.totalFluidVolumeGiven);
        expect(restored.medicationRecentTimes, original.medicationRecentTimes);
      });
    });

    group('toString', () {
      test('includes medicationRecentTimes in output', () {
        const cache = DailySummaryCache(
          date: '2025-10-13',
          medicationSessionCount: 1,
          fluidSessionCount: 0,
          medicationNames: ['Amlodipine'],
          totalMedicationDosesGiven: 2.5,
          totalFluidVolumeGiven: 0,
          medicationRecentTimes: <String, List<String>>{
            'Amlodipine': <String>['2025-10-13T08:00:00.000'],
          },
        );

        final str = cache.toString();

        expect(str, contains('medicationRecentTimes'));
        expect(str, contains('Amlodipine'));
      });
    });
  });
}
