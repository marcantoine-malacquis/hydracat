import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/features/notifications/utils/notification_id.dart';

void main() {
  group('generateNotificationId', () {
    group('Determinism', () {
      test('generates same ID for same inputs', () {
        const userId = 'user_abc123';
        const petId = 'pet_xyz789';
        const scheduleId = 'sched_medication_001';
        const timeSlot = '08:00';
        const kind = 'initial';

        final id1 = generateNotificationId(
          userId: userId,
          petId: petId,
          scheduleId: scheduleId,
          timeSlot: timeSlot,
          kind: kind,
        );

        final id2 = generateNotificationId(
          userId: userId,
          petId: petId,
          scheduleId: scheduleId,
          timeSlot: timeSlot,
          kind: kind,
        );

        expect(id1, equals(id2));
      });

      test('generates same ID across 100 calls', () {
        const userId = 'user1';
        const petId = 'pet1';
        const scheduleId = 'sched1';
        const timeSlot = '12:30';
        const kind = 'followup';

        final firstId = generateNotificationId(
          userId: userId,
          petId: petId,
          scheduleId: scheduleId,
          timeSlot: timeSlot,
          kind: kind,
        );

        for (var i = 0; i < 100; i++) {
          final id = generateNotificationId(
            userId: userId,
            petId: petId,
            scheduleId: scheduleId,
            timeSlot: timeSlot,
            kind: kind,
          );
          expect(id, equals(firstId));
        }
      });

      test('order of calls does not affect results', () {
        // Generate IDs in different order
        final id1 = generateNotificationId(
          userId: 'user1',
          petId: 'pet1',
          scheduleId: 'sched1',
          timeSlot: '08:00',
          kind: 'initial',
        );

        final id2 = generateNotificationId(
          userId: 'user2',
          petId: 'pet2',
          scheduleId: 'sched2',
          timeSlot: '14:00',
          kind: 'followup',
        );

        // Generate same IDs in reverse order
        final id2Again = generateNotificationId(
          userId: 'user2',
          petId: 'pet2',
          scheduleId: 'sched2',
          timeSlot: '14:00',
          kind: 'followup',
        );

        final id1Again = generateNotificationId(
          userId: 'user1',
          petId: 'pet1',
          scheduleId: 'sched1',
          timeSlot: '08:00',
          kind: 'initial',
        );

        expect(id1, equals(id1Again));
        expect(id2, equals(id2Again));
      });
    });

    group('Uniqueness', () {
      test('different userIds produce different IDs', () {
        final id1 = generateNotificationId(
          userId: 'user1',
          petId: 'pet1',
          scheduleId: 'sched1',
          timeSlot: '08:00',
          kind: 'initial',
        );

        final id2 = generateNotificationId(
          userId: 'user2', // Different
          petId: 'pet1',
          scheduleId: 'sched1',
          timeSlot: '08:00',
          kind: 'initial',
        );

        expect(id1, isNot(equals(id2)));
      });

      test('different petIds produce different IDs', () {
        final id1 = generateNotificationId(
          userId: 'user1',
          petId: 'pet1',
          scheduleId: 'sched1',
          timeSlot: '08:00',
          kind: 'initial',
        );

        final id2 = generateNotificationId(
          userId: 'user1',
          petId: 'pet2', // Different
          scheduleId: 'sched1',
          timeSlot: '08:00',
          kind: 'initial',
        );

        expect(id1, isNot(equals(id2)));
      });

      test('different scheduleIds produce different IDs', () {
        final id1 = generateNotificationId(
          userId: 'user1',
          petId: 'pet1',
          scheduleId: 'sched1',
          timeSlot: '08:00',
          kind: 'initial',
        );

        final id2 = generateNotificationId(
          userId: 'user1',
          petId: 'pet1',
          scheduleId: 'sched2', // Different
          timeSlot: '08:00',
          kind: 'initial',
        );

        expect(id1, isNot(equals(id2)));
      });

      test('different timeSlots produce different IDs', () {
        final id1 = generateNotificationId(
          userId: 'user1',
          petId: 'pet1',
          scheduleId: 'sched1',
          timeSlot: '08:00',
          kind: 'initial',
        );

        final id2 = generateNotificationId(
          userId: 'user1',
          petId: 'pet1',
          scheduleId: 'sched1',
          timeSlot: '08:01', // Different
          kind: 'initial',
        );

        expect(id1, isNot(equals(id2)));
      });

      test('different kinds produce different IDs', () {
        final id1 = generateNotificationId(
          userId: 'user1',
          petId: 'pet1',
          scheduleId: 'sched1',
          timeSlot: '08:00',
          kind: 'initial',
        );

        final id2 = generateNotificationId(
          userId: 'user1',
          petId: 'pet1',
          scheduleId: 'sched1',
          timeSlot: '08:00',
          kind: 'followup', // Different
        );

        expect(id1, isNot(equals(id2)));
      });

      test('all three kinds produce different IDs', () {
        final initialId = generateNotificationId(
          userId: 'user1',
          petId: 'pet1',
          scheduleId: 'sched1',
          timeSlot: '08:00',
          kind: 'initial',
        );

        final followupId = generateNotificationId(
          userId: 'user1',
          petId: 'pet1',
          scheduleId: 'sched1',
          timeSlot: '08:00',
          kind: 'followup',
        );

        final snoozeId = generateNotificationId(
          userId: 'user1',
          petId: 'pet1',
          scheduleId: 'sched1',
          timeSlot: '08:00',
          kind: 'snooze',
        );

        expect(initialId, isNot(equals(followupId)));
        expect(initialId, isNot(equals(snoozeId)));
        expect(followupId, isNot(equals(snoozeId)));
      });

      test('realistic dataset has no collisions', () {
        // Test with realistic app usage:
        // 10 users × 5 pets × 10 schedules × 24 time slots × 3 kinds
        // = 36,000 unique IDs
        final ids = <int>{};

        final users = List.generate(10, (i) => 'user_$i');
        final pets = List.generate(5, (i) => 'pet_$i');
        final schedules = List.generate(10, (i) => 'schedule_$i');
        final timeSlots = List.generate(24, (i) {
          final hour = i.toString().padLeft(2, '0');
          return '$hour:00';
        });
        const kinds = ['initial', 'followup', 'snooze'];

        var totalGenerated = 0;

        for (final userId in users) {
          for (final petId in pets) {
            for (final scheduleId in schedules) {
              for (final timeSlot in timeSlots) {
                for (final kind in kinds) {
                  final id = generateNotificationId(
                    userId: userId,
                    petId: petId,
                    scheduleId: scheduleId,
                    timeSlot: timeSlot,
                    kind: kind,
                  );
                  ids.add(id);
                  totalGenerated++;
                }
              }
            }
          }
        }

        // Verify no collisions
        expect(
          ids.length,
          equals(totalGenerated),
          reason: 'All 36,000 IDs should be unique (no collisions)',
        );
      });
    });

    group('31-bit constraint', () {
      test('all generated IDs are positive integers', () {
        final ids = [
          generateNotificationId(
            userId: 'user1',
            petId: 'pet1',
            scheduleId: 'sched1',
            timeSlot: '08:00',
            kind: 'initial',
          ),
          generateNotificationId(
            userId: 'user_very_long_id_12345',
            petId: 'pet_very_long_id_67890',
            scheduleId: 'sched_very_long_id_abcdef',
            timeSlot: '23:59',
            kind: 'snooze',
          ),
          generateNotificationId(
            userId: 'u',
            petId: 'p',
            scheduleId: 's',
            timeSlot: '00:00',
            kind: 'initial',
          ),
        ];

        for (final id in ids) {
          expect(id, greaterThan(0));
        }
      });

      test('all generated IDs are within 31-bit range', () {
        // Android max notification ID: 2,147,483,647 (2^31 - 1)
        const maxId = 2147483647;

        // Test with various inputs
        final testCases = [
          {'userId': 'user1', 'petId': 'pet1', 'scheduleId': 'sched1'},
          {
            'userId': 'user_very_long_id_with_many_characters_12345',
            'petId': 'pet_very_long_id_with_many_characters_67890',
            'scheduleId': 'schedule_very_long_id_with_many_characters_abcdef',
          },
          {'userId': 'u', 'petId': 'p', 'scheduleId': 's'},
        ];

        final timeSlots = ['00:00', '08:00', '12:30', '18:45', '23:59'];
        const kinds = ['initial', 'followup', 'snooze'];

        for (final testCase in testCases) {
          for (final timeSlot in timeSlots) {
            for (final kind in kinds) {
              final id = generateNotificationId(
                userId: testCase['userId']!,
                petId: testCase['petId']!,
                scheduleId: testCase['scheduleId']!,
                timeSlot: timeSlot,
                kind: kind,
              );

              expect(
                id,
                lessThanOrEqualTo(maxId),
                reason: 'ID must be ≤ 2,147,483,647 (31-bit max)',
              );
            }
          }
        }
      });

      test('no negative IDs are ever generated', () {
        // Generate large sample of IDs with diverse inputs
        for (var i = 0; i < 1000; i++) {
          final id = generateNotificationId(
            userId: 'user_$i',
            petId: 'pet_${i * 2}',
            scheduleId: 'schedule_${i * 3}',
            timeSlot: '${(i % 24).toString().padLeft(2, '0')}:00',
            kind: ['initial', 'followup', 'snooze'][i % 3],
          );

          expect(
            id,
            greaterThanOrEqualTo(0),
            reason: 'ID must be non-negative',
          );
        }
      });
    });

    group('Validation', () {
      test('throws ArgumentError for empty userId', () {
        expect(
          () => generateNotificationId(
            userId: '',
            petId: 'pet1',
            scheduleId: 'sched1',
            timeSlot: '08:00',
            kind: 'initial',
          ),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('userId must not be empty'),
            ),
          ),
        );
      });

      test('throws ArgumentError for empty petId', () {
        expect(
          () => generateNotificationId(
            userId: 'user1',
            petId: '',
            scheduleId: 'sched1',
            timeSlot: '08:00',
            kind: 'initial',
          ),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('petId must not be empty'),
            ),
          ),
        );
      });

      test('throws ArgumentError for empty scheduleId', () {
        expect(
          () => generateNotificationId(
            userId: 'user1',
            petId: 'pet1',
            scheduleId: '',
            timeSlot: '08:00',
            kind: 'initial',
          ),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('scheduleId must not be empty'),
            ),
          ),
        );
      });

      test('throws ArgumentError for empty timeSlot', () {
        expect(
          () => generateNotificationId(
            userId: 'user1',
            petId: 'pet1',
            scheduleId: 'sched1',
            timeSlot: '',
            kind: 'initial',
          ),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('timeSlot must not be empty'),
            ),
          ),
        );
      });

      test('throws ArgumentError for empty kind', () {
        expect(
          () => generateNotificationId(
            userId: 'user1',
            petId: 'pet1',
            scheduleId: 'sched1',
            timeSlot: '08:00',
            kind: '',
          ),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('kind must not be empty'),
            ),
          ),
        );
      });

      test('throws ArgumentError for invalid timeSlot format', () {
        final invalidTimeSlots = [
          '25:00', // Invalid hour
          '08:60', // Invalid minute
          '8:00', // Missing leading zero
          'invalid', // Not a time
          '08-00', // Wrong separator
        ];

        for (final timeSlot in invalidTimeSlots) {
          expect(
            () => generateNotificationId(
              userId: 'user1',
              petId: 'pet1',
              scheduleId: 'sched1',
              timeSlot: timeSlot,
              kind: 'initial',
            ),
            throwsA(
              isA<ArgumentError>().having(
                (e) => e.message,
                'message',
                contains('timeSlot must be in "HH:mm" format'),
              ),
            ),
            reason: 'Should reject invalid timeSlot: "$timeSlot"',
          );
        }
      });

      test('throws ArgumentError for invalid kind', () {
        final invalidKinds = [
          'invalid',
          'reminder',
          'notification',
          'Initial', // Wrong case
        ];

        for (final kind in invalidKinds) {
          expect(
            () => generateNotificationId(
              userId: 'user1',
              petId: 'pet1',
              scheduleId: 'sched1',
              timeSlot: '08:00',
              kind: kind,
            ),
            throwsA(
              isA<ArgumentError>().having(
                (e) => e.message,
                'message',
                contains('kind must be "initial", "followup", or "snooze"'),
              ),
            ),
            reason: 'Should reject invalid kind: "$kind"',
          );
        }
      });

      test('accepts all valid kinds', () {
        const validKinds = ['initial', 'followup', 'snooze'];

        for (final kind in validKinds) {
          expect(
            () => generateNotificationId(
              userId: 'user1',
              petId: 'pet1',
              scheduleId: 'sched1',
              timeSlot: '08:00',
              kind: kind,
            ),
            returnsNormally,
            reason: 'Should accept valid kind: "$kind"',
          );
        }
      });
    });

    group('Edge cases', () {
      test('handles boundary time slots', () {
        final boundaryTimes = ['00:00', '23:59'];

        for (final timeSlot in boundaryTimes) {
          expect(
            () => generateNotificationId(
              userId: 'user1',
              petId: 'pet1',
              scheduleId: 'sched1',
              timeSlot: timeSlot,
              kind: 'initial',
            ),
            returnsNormally,
            reason: 'Should accept boundary time: "$timeSlot"',
          );
        }
      });

      test('handles special characters in IDs', () {
        // Test with various special characters that might appear in IDs
        final specialIds = [
          'user_with-dashes',
          'user.with.dots',
          'user_with_underscores',
          'user@example.com',
          'user+tag',
        ];

        for (final userId in specialIds) {
          expect(
            () => generateNotificationId(
              userId: userId,
              petId: 'pet1',
              scheduleId: 'sched1',
              timeSlot: '08:00',
              kind: 'initial',
            ),
            returnsNormally,
            reason: 'Should handle special characters in: "$userId"',
          );
        }
      });

      test('handles very long strings', () {
        // Test with 100+ character strings
        final longUserId = 'u' * 150;
        final longPetId = 'p' * 150;
        final longScheduleId = 's' * 150;

        expect(
          () => generateNotificationId(
            userId: longUserId,
            petId: longPetId,
            scheduleId: longScheduleId,
            timeSlot: '08:00',
            kind: 'initial',
          ),
          returnsNormally,
        );
      });

      test('handles unicode characters', () {
        expect(
          () => generateNotificationId(
            userId: 'user_名前',
            petId: 'pet_猫',
            scheduleId: 'sched_スケジュール',
            timeSlot: '08:00',
            kind: 'initial',
          ),
          returnsNormally,
        );
      });

      test('single character IDs work correctly', () {
        final id = generateNotificationId(
          userId: 'u',
          petId: 'p',
          scheduleId: 's',
          timeSlot: '08:00',
          kind: 'initial',
        );

        expect(id, greaterThan(0));
        expect(id, lessThanOrEqualTo(2147483647));

        // Should be deterministic even with single chars
        final id2 = generateNotificationId(
          userId: 'u',
          petId: 'p',
          scheduleId: 's',
          timeSlot: '08:00',
          kind: 'initial',
        );

        expect(id, equals(id2));
      });
    });

    group('Performance', () {
      test('generates 10,000 IDs in under 100ms', () {
        final stopwatch = Stopwatch()..start();

        for (var i = 0; i < 10000; i++) {
          generateNotificationId(
            userId: 'user_$i',
            petId: 'pet_${i % 5}',
            scheduleId: 'schedule_${i % 10}',
            timeSlot: '${(i % 24).toString().padLeft(2, '0')}:00',
            kind: ['initial', 'followup', 'snooze'][i % 3],
          );
        }

        stopwatch.stop();

        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(100),
          reason: 'Should generate 10,000 IDs in under 100ms',
        );
      });
    });
  });
}
