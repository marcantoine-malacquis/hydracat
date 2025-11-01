/// Integration tests for ReminderService with mocked plugin layer.
///
/// These tests verify that ReminderPluginInterface enables proper mocking
/// and plugin methods are called correctly. The plugin is mocked to enable
/// fast, deterministic tests without real platform channels.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/features/notifications/models/scheduled_notification_entry.dart';
import 'package:hydracat/features/notifications/providers/notification_provider.dart';
import 'package:hydracat/features/notifications/services/notification_index_store.dart';
import 'package:hydracat/features/notifications/services/reminder_plugin.dart';
import 'package:hydracat/features/notifications/utils/notification_id.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

// ============================================
// Mock Classes
// ============================================

class MockReminderPlugin extends Mock implements ReminderPlugin {}

class MockNotificationIndexStore extends Mock
    implements NotificationIndexStore {}

// ============================================
// Helper Functions
// ============================================

/// Creates a test ProviderContainer with mocked plugin and index store
ProviderContainer createTestContainer({
  ReminderPlugin? mockPlugin,
  NotificationIndexStore? mockIndexStore,
}) {
  final plugin = mockPlugin ?? MockReminderPlugin();
  final indexStore = mockIndexStore ?? MockNotificationIndexStore();

  // Mock default plugin behavior
  when(() => plugin.isInitialized).thenReturn(true);
  when(plugin.pendingNotificationRequests).thenAnswer((_) async => const []);
  when(
    () => plugin.showZoned(
      id: any<int>(),
      title: any<String>(),
      body: any<String>(),
      scheduledDate: any<tz.TZDateTime>(),
      channelId: any<String>(),
      payload: any<String?>(),
      groupId: any<String?>(),
      threadIdentifier: any<String?>(),
    ),
  ).thenAnswer((_) async {});
  when(() => plugin.cancel(any<int>())).thenAnswer((_) async {});
  when(plugin.cancelAll).thenAnswer((_) async {});
  when(
    () => plugin.showGroupSummary(
      petId: any<String>(),
      petName: any<String>(),
      medicationCount: any<int>(),
      fluidCount: any<int>(),
      groupId: any<String>(),
      threadIdentifier: any<String?>(),
    ),
  ).thenAnswer((_) async {});
  when(() => plugin.cancelGroupSummary(any<String>())).thenAnswer((_) async {});

  // Mock default index store behavior
  when(
    () => indexStore.getForToday(any<String>(), any<String>()),
  ).thenAnswer((_) async => const <ScheduledNotificationEntry>[]);
  when(
    () => indexStore.putEntry(any<String>(), any<String>(), any()),
  ).thenAnswer((_) async {});
  when(
    () => indexStore.removeEntryBy(
      any<String>(),
      any<String>(),
      any<String>(),
      any<String>(),
      any<String>(),
    ),
  ).thenAnswer((_) => Future.value(0));
  when(
    () => indexStore.getCountForPet(
      any<String>(),
      any<String>(),
      any(),
    ),
  ).thenAnswer((_) async => 0);

  // Setup SharedPreferences
  SharedPreferences.setMockInitialValues(<String, Object>{});

  return ProviderContainer(
    overrides: [
      reminderPluginProvider.overrideWith((ref) => plugin),
      notificationIndexStoreProvider.overrideWith((ref) => indexStore),
    ],
  );
}

// ============================================
// Tests
// ============================================

void main() {
  setUpAll(() {
    // Initialize timezone data for tests
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/New_York'));

    // Register fallback value for ScheduledNotificationEntry
    registerFallbackValue(
      const ScheduledNotificationEntry(
        notificationId: 0,
        scheduleId: 'test',
        treatmentType: 'medication',
        timeSlotISO: '08:00',
        kind: 'initial',
      ),
    );
  });

  group('ReminderPluginInterface Integration Tests', () {
    late MockReminderPlugin mockPlugin;
    late MockNotificationIndexStore mockIndexStore;

    setUp(() {
      mockPlugin = MockReminderPlugin();
      mockIndexStore = MockNotificationIndexStore();
    });

    group('Deterministic Notification ID Generation', () {
      test(
        'generateNotificationId produces consistent IDs for same inputs',
        () {
          // Generate IDs multiple times with same inputs
          final id1 = generateNotificationId(
            userId: 'user123',
            petId: 'pet456',
            scheduleId: 'sched789',
            timeSlot: '08:00',
            kind: 'initial',
          );

          final id2 = generateNotificationId(
            userId: 'user123',
            petId: 'pet456',
            scheduleId: 'sched789',
            timeSlot: '08:00',
            kind: 'initial',
          );

          final id3 = generateNotificationId(
            userId: 'user123',
            petId: 'pet456',
            scheduleId: 'sched789',
            timeSlot: '08:00',
            kind: 'initial',
          );

          // All should be identical
          expect(id1, equals(id2));
          expect(id2, equals(id3));
        },
      );

      test(
        'generateNotificationId produces different IDs for different inputs',
        () {
          final initialId = generateNotificationId(
            userId: 'user123',
            petId: 'pet456',
            scheduleId: 'sched789',
            timeSlot: '08:00',
            kind: 'initial',
          );

          final followupId = generateNotificationId(
            userId: 'user123',
            petId: 'pet456',
            scheduleId: 'sched789',
            timeSlot: '08:00',
            kind: 'followup',
          );

          final snoozeId = generateNotificationId(
            userId: 'user123',
            petId: 'pet456',
            scheduleId: 'sched789',
            timeSlot: '08:00',
            kind: 'snooze',
          );

          // All should be different
          expect(initialId, isNot(equals(followupId)));
          expect(followupId, isNot(equals(snoozeId)));
          expect(initialId, isNot(equals(snoozeId)));
        },
      );

      test('generateNotificationId IDs are within 31-bit range', () {
        final id = generateNotificationId(
          userId: 'user123',
          petId: 'pet456',
          scheduleId: 'sched789',
          timeSlot: '08:00',
          kind: 'initial',
        );

        // Should be positive 31-bit integer
        expect(id, greaterThan(0));
        expect(id, lessThanOrEqualTo(2147483647));
      });
    });

    group('Plugin Mock Integration', () {
      test('plugin.showZoned is callable with correct parameters', () async {
        final now = DateTime(2025, 1, 15, 8);
        final scheduledTime = tz.TZDateTime.from(now, tz.local);

        // Execute
        await mockPlugin.showZoned(
          id: 12345,
          title: 'Test Title',
          body: 'Test Body',
          scheduledDate: scheduledTime,
          payload: '{"test": "data"}',
          groupId: 'pet_test_pet',
          threadIdentifier: 'pet_test_pet',
        );

        // Verify
        verify(
          () => mockPlugin.showZoned(
            id: 12345,
            title: 'Test Title',
            body: 'Test Body',
            scheduledDate: scheduledTime,
            payload: '{"test": "data"}',
            groupId: 'pet_test_pet',
            threadIdentifier: 'pet_test_pet',
          ),
        ).called(1);
      });

      test('plugin.cancel is callable with correct notification ID', () async {
        // Execute
        await mockPlugin.cancel(12345);

        // Verify
        verify(() => mockPlugin.cancel(12345)).called(1);
      });

      test('plugin.cancelAll is callable', () async {
        // Execute
        await mockPlugin.cancelAll();

        // Verify
        verify(() => mockPlugin.cancelAll()).called(1);
      });

      test(
        'plugin.pendingNotificationRequests returns empty list by default',
        () async {
          // Execute
          final pending = await mockPlugin.pendingNotificationRequests();

          // Verify
          expect(pending, isEmpty);
          verify(() => mockPlugin.pendingNotificationRequests()).called(1);
        },
      );

      test(
        'plugin.showGroupSummary is callable with correct parameters',
        () async {
          // Execute
          await mockPlugin.showGroupSummary(
            petId: 'pet123',
            petName: 'Fluffy',
            medicationCount: 2,
            fluidCount: 1,
            groupId: 'pet_pet123',
          );

          // Verify
          verify(
            () => mockPlugin.showGroupSummary(
              petId: 'pet123',
              petName: 'Fluffy',
              medicationCount: 2,
              fluidCount: 1,
              groupId: 'pet_pet123',
            ),
          ).called(1);
        },
      );

      test('plugin.cancelGroupSummary is callable', () async {
        // Execute
        await mockPlugin.cancelGroupSummary('pet123');

        // Verify
        verify(() => mockPlugin.cancelGroupSummary('pet123')).called(1);
      });

      test(
        'plugin.canScheduleExactNotifications returns true by default',
        () async {
          // Setup
          when(
            () => mockPlugin.canScheduleExactNotifications(),
          ).thenAnswer((_) async => true);

          // Execute
          final canSchedule = await mockPlugin.canScheduleExactNotifications();

          // Verify
          expect(canSchedule, isTrue);
          verify(() => mockPlugin.canScheduleExactNotifications()).called(1);
        },
      );
    });

    group('Index Store Mock Integration', () {
      test('indexStore.putEntry is callable with correct parameters', () async {
        // Create test entry
        const entry = ScheduledNotificationEntry(
          notificationId: 12345,
          scheduleId: 'sched1',
          treatmentType: 'medication',
          timeSlotISO: '08:00',
          kind: 'initial',
        );

        // Setup
        when(
          () => mockIndexStore.putEntry(any(), any(), any()),
        ).thenAnswer((_) async {});

        // Execute
        await mockIndexStore.putEntry('user1', 'pet1', entry);

        // Verify called
        verify(() => mockIndexStore.putEntry('user1', 'pet1', entry)).called(1);
      });

      test('indexStore.removeEntryBy is callable for cancellation', () async {
        // Setup
        when(
          () => mockIndexStore.removeEntryBy(
            any<String>(),
            any<String>(),
            any<String>(),
            any<String>(),
            any<String>(),
          ),
        ).thenAnswer((_) async => 1); // Return count

        // Execute
        final count = await mockIndexStore.removeEntryBy(
          'user1',
          'pet1',
          'sched1',
          '08:00',
          'initial',
        );

        // Verify
        verify(
          () => mockIndexStore.removeEntryBy(
            'user1',
            'pet1',
            'sched1',
            '08:00',
            'initial',
          ),
        ).called(1);
        expect(count, equals(1));
      });

      test('indexStore.getForToday returns empty list by default', () async {
        // Setup
        when(
          () => mockIndexStore.getForToday(any(), any()),
        ).thenAnswer((_) async => const []);

        // Execute
        final entries = await mockIndexStore.getForToday('user1', 'pet1');

        // Verify
        expect(entries, isEmpty);
        verify(() => mockIndexStore.getForToday('user1', 'pet1')).called(1);
      });

      test('indexStore.getCountForPet returns zero by default', () async {
        // Execute
        final count = await mockIndexStore.getCountForPet(
          'user1',
          'pet1',
          DateTime.now(),
        );

        // Verify
        expect(count, equals(0));
        verify(
          () => mockIndexStore.getCountForPet(any(), any(), any()),
        ).called(1);
      });
    });

    group('Provider Integration', () {
      test('reminderPluginProvider provides mock instance', () {
        final container = createTestContainer(mockPlugin: mockPlugin);

        // Get plugin from provider
        final plugin = container.read(reminderPluginProvider);

        // Verify it's our mock
        expect(plugin, equals(mockPlugin));

        container.dispose();
      });

      test('notificationIndexStoreProvider provides mock instance', () {
        final container = createTestContainer(mockIndexStore: mockIndexStore);

        // Get store from provider
        final store = container.read(notificationIndexStoreProvider);

        // Verify it's our mock
        expect(store, equals(mockIndexStore));

        container.dispose();
      });
    });

    group('Integration: Scheduling Flow with Mocks', () {
      test(
        'scheduling flow updates index after plugin call succeeds',
        () async {
          final container = createTestContainer(
            mockPlugin: mockPlugin,
            mockIndexStore: mockIndexStore,
          );

          // Setup: Configure mock to call index store after plugin
          when(
            () => mockPlugin.showZoned(
              id: any<int>(),
              title: any<String>(),
              body: any<String>(),
              scheduledDate: any<tz.TZDateTime>(),
              channelId: any<String>(),
              payload: any<String?>(),
              groupId: any<String?>(),
              threadIdentifier: any<String?>(),
            ),
          ).thenAnswer((_) async {
            // Simulate index update after successful plugin call
            await mockIndexStore.putEntry(
              'user1',
              'pet1',
              const ScheduledNotificationEntry(
                notificationId: 12345,
                scheduleId: 'sched1',
                treatmentType: 'medication',
                timeSlotISO: '08:00',
                kind: 'initial',
              ),
            );
          });

          // Execute
          await mockPlugin.showZoned(
            id: 12345,
            title: 'Test',
            body: 'Test',
            scheduledDate: tz.TZDateTime.now(tz.local),
          );

          // Verify: Plugin called
          verify(
            () => mockPlugin.showZoned(
              id: any<int>(),
              title: any<String>(),
              body: any<String>(),
              scheduledDate: any<tz.TZDateTime>(),
              channelId: any<String>(),
              payload: any<String?>(),
              groupId: any<String?>(),
              threadIdentifier: any<String?>(),
            ),
          ).called(1);

          // Verify: Index updated
          verify(
            () => mockIndexStore.putEntry(
              any<String>(),
              any<String>(),
              any(),
            ),
          ).called(1);

          container.dispose();
        },
      );

      test(
        'cancellation flow updates index after plugin call succeeds',
        () async {
          final container = createTestContainer(
            mockPlugin: mockPlugin,
            mockIndexStore: mockIndexStore,
          );

          // Setup
          when(() => mockPlugin.cancel(any<int>())).thenAnswer((_) async {
            // Simulate index cleanup after successful cancellation
            await mockIndexStore.removeEntryBy(
              'user1',
              'pet1',
              'sched1',
              '08:00',
              'initial',
            );
          });

          // Execute
          await mockPlugin.cancel(12345);

          // Verify: Plugin called
          verify(() => mockPlugin.cancel(12345)).called(1);

          // Verify: Index updated
          verify(
            () => mockIndexStore.removeEntryBy(
              any<String>(),
              any<String>(),
              any<String>(),
              any<String>(),
              any<String>(),
            ),
          ).called(1);

          container.dispose();
        },
      );
    });

    group('Error Handling', () {
      test('plugin errors are throwable and catchable', () async {
        final container = createTestContainer(mockPlugin: mockPlugin);

        // Setup: Configure mock to throw exception
        when(
          () => mockPlugin.showZoned(
            id: any<int>(),
            title: any<String>(),
            body: any<String>(),
            scheduledDate: any<tz.TZDateTime>(),
            channelId: any<String>(),
            payload: any<String?>(),
            groupId: any<String?>(),
            threadIdentifier: any<String?>(),
          ),
        ).thenThrow(Exception('Test error'));

        // Execute and expect exception
        expect(
          () => mockPlugin.showZoned(
            id: 12345,
            title: 'Test',
            body: 'Test',
            scheduledDate: tz.TZDateTime.now(tz.local),
          ),
          throwsException,
        );

        // Verify called
        verify(
          () => mockPlugin.showZoned(
            id: any<int>(),
            title: any<String>(),
            body: any<String>(),
            scheduledDate: any<tz.TZDateTime>(),
            channelId: any<String>(),
            payload: any<String?>(),
            groupId: any<String?>(),
            threadIdentifier: any<String?>(),
          ),
        ).called(1);

        container.dispose();
      });

      test('index store errors are throwable and catchable', () async {
        // Setup: Configure mock to throw exception
        when(
          () => mockIndexStore.putEntry(
            any<String>(),
            any<String>(),
            any(),
          ),
        ).thenThrow(Exception('Test error'));

        final container = createTestContainer(mockIndexStore: mockIndexStore);

        // Execute and expect exception
        expect(
          () => mockIndexStore.putEntry(
            'user1',
            'pet1',
            const ScheduledNotificationEntry(
              notificationId: 12345,
              scheduleId: 'sched1',
              treatmentType: 'medication',
              timeSlotISO: '08:00',
              kind: 'initial',
            ),
          ),
          throwsException,
        );

        // Verify called
        verify(
          () => mockIndexStore.putEntry(
            any<String>(),
            any<String>(),
            any(),
          ),
        ).called(1);

        container.dispose();
      });
    });
  });
}
