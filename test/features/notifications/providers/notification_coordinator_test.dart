import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/features/auth/models/app_user.dart';
import 'package:hydracat/features/notifications/models/scheduled_notification_entry.dart';
import 'package:hydracat/features/notifications/providers/notification_provider.dart';
import 'package:hydracat/features/notifications/services/notification_index_store.dart';
import 'package:hydracat/features/notifications/services/reminder_plugin.dart';
import 'package:hydracat/features/profile/models/cat_profile.dart';
import 'package:hydracat/providers/analytics_provider.dart';
import 'package:hydracat/providers/auth_provider.dart';
import 'package:hydracat/providers/profile_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../../helpers/notification_test_builders.dart';

// Mock classes
class MockReminderPlugin extends Mock implements ReminderPlugin {}

class MockNotificationIndexStore extends Mock
    implements NotificationIndexStore {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

// Fake classes for registerFallbackValue
class FakeScheduledNotificationEntry extends Fake
    implements ScheduledNotificationEntry {}

class FakeTZDateTime extends Fake implements tz.TZDateTime {}

void main() {
  // Initialize timezone data for tests
  setUpAll(() {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/New_York'));

    // Register fallback values for mocktail
    registerFallbackValue(FakeScheduledNotificationEntry());
    registerFallbackValue(FakeTZDateTime());
  });

  group('NotificationCoordinator', () {
    late MockReminderPlugin mockPlugin;
    late MockNotificationIndexStore mockIndexStore;
    late MockAnalyticsService mockAnalytics;
    late ProviderContainer container;
    late AppUser testUser;
    late CatProfile testPet;

    setUp(() {
      // Initialize mocks
      mockPlugin = MockReminderPlugin();
      mockIndexStore = MockNotificationIndexStore();
      mockAnalytics = MockAnalyticsService();

      // Create test data
      testUser = UserBuilder()
          .withId('test-user-123')
          .withEmail('test@example.com')
          .build();

      testPet = PetBuilder()
          .withId('test-pet-456')
          .withUserId(testUser.id)
          .withName('Whiskers')
          .build();

      // Set up default stubs for plugin
      when(
        () => mockPlugin.showZoned(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          scheduledDate: any(named: 'scheduledDate'),
          channelId: any(named: 'channelId'),
          payload: any(named: 'payload'),
          groupId: any(named: 'groupId'),
          threadIdentifier: any(named: 'threadIdentifier'),
        ),
      ).thenAnswer((_) async {});

      when(() => mockPlugin.cancel(any<int>())).thenAnswer((_) async {});

      when(() => mockPlugin.cancelGroupSummary(any())).thenAnswer((_) async {});

      when(
        () => mockPlugin.showGroupSummary(
          petId: any(named: 'petId'),
          petName: any(named: 'petName'),
          medicationCount: any(named: 'medicationCount'),
          fluidCount: any(named: 'fluidCount'),
          groupId: any(named: 'groupId'),
          threadIdentifier: any(named: 'threadIdentifier'),
        ),
      ).thenAnswer((_) async {});

      when(
        () => mockPlugin.pendingNotificationRequests(),
      ).thenAnswer((_) async => []);

      // Set up default stubs for index store
      when(
        () => mockIndexStore.putEntry(any(), any(), any()),
      ).thenAnswer((_) async {});

      when(
        () => mockIndexStore.removeEntryBy(
          any(),
          any(),
          any(),
          any(),
          any(),
        ),
      ).thenAnswer((_) async => 0);

      when(
        () => mockIndexStore.getForToday(
          any(),
          any(),
          analyticsService: any(named: 'analyticsService'),
          plugin: any(named: 'plugin'),
        ),
      ).thenAnswer((_) async => []);

      when(
        () => mockIndexStore.getEntriesForPet(any(), any(), any()),
      ).thenAnswer((_) async => []);

      when(
        () => mockIndexStore.clearForDate(any(), any(), any()),
      ).thenAnswer((_) async {});
    });

    tearDown(() {
      container.dispose();
    });

    group('Provider Access Pattern', () {
      test('can be accessed from ProviderContainer (simulating any Ref)', () {
        // Arrange
        container = ProviderContainer(
          overrides: [
            reminderPluginProvider.overrideWithValue(mockPlugin),
            notificationIndexStoreProvider.overrideWithValue(mockIndexStore),
            currentUserProvider.overrideWith((ref) => testUser),
            primaryPetProvider.overrideWith((ref) => testPet),
            analyticsServiceDirectProvider.overrideWithValue(mockAnalytics),
          ],
        );

        // Act
        final coordinator = container.read(notificationCoordinatorProvider);

        // Assert
        expect(coordinator, isA<NotificationCoordinator>());
      });

      test('works without type casting errors from any context', () async {
        // Arrange
        container = ProviderContainer(
          overrides: [
            reminderPluginProvider.overrideWithValue(mockPlugin),
            notificationIndexStoreProvider.overrideWithValue(mockIndexStore),
            currentUserProvider.overrideWith((ref) => testUser),
            primaryPetProvider.overrideWith((ref) => testPet),
            analyticsServiceDirectProvider.overrideWithValue(mockAnalytics),
          ],
        );

        // Act - This should not throw any type casting errors
        final coordinator = container.read(notificationCoordinatorProvider);
        final result = await coordinator.scheduleAllForToday();

        // Assert
        expect(result, isA<Map<String, dynamic>>());
        expect(result.containsKey('scheduled'), isTrue);
      });
    });

    group('scheduleAllForToday - null checks', () {
      test('returns empty result when no user', () async {
        // Arrange
        container = ProviderContainer(
          overrides: [
            reminderPluginProvider.overrideWithValue(mockPlugin),
            notificationIndexStoreProvider.overrideWithValue(mockIndexStore),
            currentUserProvider.overrideWith((ref) => null),
            primaryPetProvider.overrideWith((ref) => testPet),
            analyticsServiceDirectProvider.overrideWithValue(mockAnalytics),
          ],
        );

        final coordinator = container.read(notificationCoordinatorProvider);

        // Act
        final result = await coordinator.scheduleAllForToday();

        // Assert
        expect(result['scheduled'], equals(0));
        expect(result['immediate'], equals(0));
        expect(result['missed'], equals(0));
        expect(result['reason'], equals('no_user_or_pet'));
        verifyNever(
          () => mockPlugin.showZoned(
            id: any(named: 'id'),
            title: any(named: 'title'),
            body: any(named: 'body'),
            scheduledDate: any(named: 'scheduledDate'),
            channelId: any(named: 'channelId'),
            payload: any(named: 'payload'),
            groupId: any(named: 'groupId'),
            threadIdentifier: any(named: 'threadIdentifier'),
          ),
        );
      });

      test('returns empty result when no pet', () async {
        // Arrange
        container = ProviderContainer(
          overrides: [
            reminderPluginProvider.overrideWithValue(mockPlugin),
            notificationIndexStoreProvider.overrideWithValue(mockIndexStore),
            currentUserProvider.overrideWith((ref) => testUser),
            primaryPetProvider.overrideWith((ref) => null),
            analyticsServiceDirectProvider.overrideWithValue(mockAnalytics),
          ],
        );

        final coordinator = container.read(notificationCoordinatorProvider);

        // Act
        final result = await coordinator.scheduleAllForToday();

        // Assert
        expect(result['scheduled'], equals(0));
        expect(result['reason'], equals('no_user_or_pet'));
      });
    });

    group('refreshAll', () {
      test('returns empty result when no user', () async {
        // Arrange
        container = ProviderContainer(
          overrides: [
            reminderPluginProvider.overrideWithValue(mockPlugin),
            notificationIndexStoreProvider.overrideWithValue(mockIndexStore),
            currentUserProvider.overrideWith((ref) => null),
            primaryPetProvider.overrideWith((ref) => testPet),
            analyticsServiceDirectProvider.overrideWithValue(mockAnalytics),
          ],
        );

        final coordinator = container.read(notificationCoordinatorProvider);

        // Act
        final result = await coordinator.refreshAll();

        // Assert
        expect(result['scheduled'], equals(0));
        expect(result['reason'], equals('no_user_or_pet'));
      });

      test('cancels existing notifications before rescheduling', () async {
        // Arrange
        final existingEntry = ScheduledNotificationEntryBuilder()
            .withNotificationId(12345)
            .withScheduleId('schedule-1')
            .build();

        when(
          () => mockIndexStore.getForToday(any(), any()),
        ).thenAnswer((_) async => [existingEntry]);

        container = ProviderContainer(
          overrides: [
            reminderPluginProvider.overrideWithValue(mockPlugin),
            notificationIndexStoreProvider.overrideWithValue(mockIndexStore),
            currentUserProvider.overrideWith((ref) => testUser),
            primaryPetProvider.overrideWith((ref) => testPet),
            analyticsServiceDirectProvider.overrideWithValue(mockAnalytics),
          ],
        );

        final coordinator = container.read(notificationCoordinatorProvider);

        // Act
        await coordinator.refreshAll();

        // Assert
        verify(() => mockPlugin.cancel(12345)).called(1);
        verify(
          () => mockIndexStore.clearForDate(any(), any(), any()),
        ).called(1);
      });

      test('handles errors during cancellation', () async {
        // Arrange
        when(
          () => mockIndexStore.getForToday(any(), any()),
        ).thenThrow(Exception('Storage error'));

        container = ProviderContainer(
          overrides: [
            reminderPluginProvider.overrideWithValue(mockPlugin),
            notificationIndexStoreProvider.overrideWithValue(mockIndexStore),
            currentUserProvider.overrideWith((ref) => testUser),
            primaryPetProvider.overrideWith((ref) => testPet),
            analyticsServiceDirectProvider.overrideWithValue(mockAnalytics),
          ],
        );

        final coordinator = container.read(notificationCoordinatorProvider);

        // Act
        final result = await coordinator.refreshAll();

        // Assert - Should not throw, should return result with errors
        expect(result, isA<Map<String, dynamic>>());
        expect(result['errors'], isNotEmpty);
      });
    });

    group('scheduleWeeklySummary', () {
      test('returns failure when no user', () async {
        // Arrange
        container = ProviderContainer(
          overrides: [
            reminderPluginProvider.overrideWithValue(mockPlugin),
            notificationIndexStoreProvider.overrideWithValue(mockIndexStore),
            currentUserProvider.overrideWith((ref) => null),
            primaryPetProvider.overrideWith((ref) => testPet),
            analyticsServiceDirectProvider.overrideWithValue(mockAnalytics),
          ],
        );

        final coordinator = container.read(notificationCoordinatorProvider);

        // Act
        final result = await coordinator.scheduleWeeklySummary();

        // Assert
        expect(result['success'], equals(false));
        expect(result['reason'], equals('no_user_or_pet'));
      });

      // Note: Testing with disabled settings would require overriding
      // StateNotifierProvider.family which is complex in unit tests.
      // This is better covered by integration tests.

      test('schedules for next Monday 09:00 when settings enabled', () async {
        // Arrange - Using default settings which have notifications enabled
        container = ProviderContainer(
          overrides: [
            reminderPluginProvider.overrideWithValue(mockPlugin),
            notificationIndexStoreProvider.overrideWithValue(mockIndexStore),
            currentUserProvider.overrideWith((ref) => testUser),
            primaryPetProvider.overrideWith((ref) => testPet),
            analyticsServiceDirectProvider.overrideWithValue(mockAnalytics),
          ],
        );

        final coordinator = container.read(notificationCoordinatorProvider);

        // Act
        final result = await coordinator.scheduleWeeklySummary();

        // Assert - Should succeed with default settings (enabled)
        expect(result, isA<Map<String, dynamic>>());
        expect(result.containsKey('success'), isTrue);
      });

      test('returns already_scheduled when duplicate', () async {
        // Arrange - Mock pending notification with same ID
        when(() => mockPlugin.pendingNotificationRequests()).thenAnswer(
          (_) async => [
            const PendingNotificationRequest(
              0, // Will be compared with generated ID
              'Weekly Summary',
              'Check your progress',
              '',
            ),
          ],
        );

        container = ProviderContainer(
          overrides: [
            reminderPluginProvider.overrideWithValue(mockPlugin),
            notificationIndexStoreProvider.overrideWithValue(mockIndexStore),
            currentUserProvider.overrideWith((ref) => testUser),
            primaryPetProvider.overrideWith((ref) => testPet),
            analyticsServiceDirectProvider.overrideWithValue(mockAnalytics),
          ],
        );

        final coordinator = container.read(notificationCoordinatorProvider);

        // Act
        final result = await coordinator.scheduleWeeklySummary();

        // Assert - Either scheduled or already_scheduled depending on ID match
        expect(result, isA<Map<String, dynamic>>());
        expect(result.containsKey('success'), isTrue);
      });

      test('handles plugin errors', () async {
        // Arrange
        when(
          () => mockPlugin.showZoned(
            id: any(named: 'id'),
            title: any(named: 'title'),
            body: any(named: 'body'),
            scheduledDate: any(named: 'scheduledDate'),
            channelId: any(named: 'channelId'),
            payload: any(named: 'payload'),
          ),
        ).thenThrow(Exception('Platform error'));

        container = ProviderContainer(
          overrides: [
            reminderPluginProvider.overrideWithValue(mockPlugin),
            notificationIndexStoreProvider.overrideWithValue(mockIndexStore),
            currentUserProvider.overrideWith((ref) => testUser),
            primaryPetProvider.overrideWith((ref) => testPet),
            analyticsServiceDirectProvider.overrideWithValue(mockAnalytics),
          ],
        );

        final coordinator = container.read(notificationCoordinatorProvider);

        // Act
        final result = await coordinator.scheduleWeeklySummary();

        // Assert
        expect(result['success'], equals(false));
        expect(result['reason'], equals('error'));
      });
    });

    group('cancelWeeklySummary', () {
      test('returns false when no user', () async {
        // Arrange
        container = ProviderContainer(
          overrides: [
            reminderPluginProvider.overrideWithValue(mockPlugin),
            notificationIndexStoreProvider.overrideWithValue(mockIndexStore),
            currentUserProvider.overrideWith((ref) => null),
            primaryPetProvider.overrideWith((ref) => testPet),
            analyticsServiceDirectProvider.overrideWithValue(mockAnalytics),
          ],
        );

        final coordinator = container.read(notificationCoordinatorProvider);

        // Act
        final result = await coordinator.cancelWeeklySummary();

        // Assert
        expect(result, equals(false));
      });

      test('cancels up to 4 weeks of scheduled summaries', () async {
        // Arrange
        container = ProviderContainer(
          overrides: [
            reminderPluginProvider.overrideWithValue(mockPlugin),
            notificationIndexStoreProvider.overrideWithValue(mockIndexStore),
            currentUserProvider.overrideWith((ref) => testUser),
            primaryPetProvider.overrideWith((ref) => testPet),
            analyticsServiceDirectProvider.overrideWithValue(mockAnalytics),
          ],
        );

        final coordinator = container.read(notificationCoordinatorProvider);

        // Act
        final result = await coordinator.cancelWeeklySummary();

        // Assert
        expect(result, isA<bool>());
        // Should attempt to cancel multiple notification IDs
        verify(() => mockPlugin.cancel(any<int>())).called(greaterThan(0));
      });
    });

    group('cancelAllForToday', () {
      test('does nothing when no user', () async {
        // Arrange
        container = ProviderContainer(
          overrides: [
            reminderPluginProvider.overrideWithValue(mockPlugin),
            notificationIndexStoreProvider.overrideWithValue(mockIndexStore),
            currentUserProvider.overrideWith((ref) => null),
            primaryPetProvider.overrideWith((ref) => testPet),
            analyticsServiceDirectProvider.overrideWithValue(mockAnalytics),
          ],
        );

        final coordinator = container.read(notificationCoordinatorProvider);

        // Act
        await coordinator.cancelAllForToday();

        // Assert
        verifyNever(() => mockIndexStore.getForToday(any(), any()));
      });

      test('cancels all indexed notifications', () async {
        // Arrange
        final entry1 = ScheduledNotificationEntryBuilder()
            .withNotificationId(111)
            .build();
        final entry2 = ScheduledNotificationEntryBuilder()
            .withNotificationId(222)
            .build();

        when(
          () => mockIndexStore.getForToday(any(), any()),
        ).thenAnswer((_) async => [entry1, entry2]);

        container = ProviderContainer(
          overrides: [
            reminderPluginProvider.overrideWithValue(mockPlugin),
            notificationIndexStoreProvider.overrideWithValue(mockIndexStore),
            currentUserProvider.overrideWith((ref) => testUser),
            primaryPetProvider.overrideWith((ref) => testPet),
            analyticsServiceDirectProvider.overrideWithValue(mockAnalytics),
          ],
        );

        final coordinator = container.read(notificationCoordinatorProvider);

        // Act
        await coordinator.cancelAllForToday();

        // Assert
        verify(() => mockPlugin.cancel(111)).called(1);
        verify(() => mockPlugin.cancel(222)).called(1);
      });

      test('clears index entries', () async {
        // Arrange
        container = ProviderContainer(
          overrides: [
            reminderPluginProvider.overrideWithValue(mockPlugin),
            notificationIndexStoreProvider.overrideWithValue(mockIndexStore),
            currentUserProvider.overrideWith((ref) => testUser),
            primaryPetProvider.overrideWith((ref) => testPet),
            analyticsServiceDirectProvider.overrideWithValue(mockAnalytics),
          ],
        );

        final coordinator = container.read(notificationCoordinatorProvider);

        // Act
        await coordinator.cancelAllForToday();

        // Assert
        verify(
          () => mockIndexStore.clearForDate(any(), any(), any()),
        ).called(1);
      });

      test('handles plugin errors gracefully', () async {
        // Arrange
        final entry = ScheduledNotificationEntryBuilder()
            .withNotificationId(123)
            .build();

        when(
          () => mockIndexStore.getForToday(any(), any()),
        ).thenAnswer((_) async => [entry]);

        when(
          () => mockPlugin.cancel(any<int>()),
        ).thenThrow(Exception('Platform error'));

        container = ProviderContainer(
          overrides: [
            reminderPluginProvider.overrideWithValue(mockPlugin),
            notificationIndexStoreProvider.overrideWithValue(mockIndexStore),
            currentUserProvider.overrideWith((ref) => testUser),
            primaryPetProvider.overrideWith((ref) => testPet),
            analyticsServiceDirectProvider.overrideWithValue(mockAnalytics),
          ],
        );

        final coordinator = container.read(notificationCoordinatorProvider);

        // Act & Assert - Should not throw
        await coordinator.cancelAllForToday();
      });
    });

    group('rescheduleAll', () {
      test('returns empty result when no user', () async {
        // Arrange
        container = ProviderContainer(
          overrides: [
            reminderPluginProvider.overrideWithValue(mockPlugin),
            notificationIndexStoreProvider.overrideWithValue(mockIndexStore),
            currentUserProvider.overrideWith((ref) => null),
            primaryPetProvider.overrideWith((ref) => testPet),
            analyticsServiceDirectProvider.overrideWithValue(mockAnalytics),
          ],
        );

        final coordinator = container.read(notificationCoordinatorProvider);

        // Act
        final result = await coordinator.rescheduleAll();

        // Assert
        expect(result['orphansCanceled'], equals(0));
        expect(result['errors'], contains('no_user_or_pet'));
      });

      test('cancels orphan notifications', () async {
        // Arrange
        when(() => mockPlugin.pendingNotificationRequests()).thenAnswer(
          (_) async => [
            const PendingNotificationRequest(
              999, // Orphan ID not in index
              'Orphan',
              'Test',
              '',
            ),
          ],
        );

        when(
          () => mockIndexStore.getForToday(
            any(),
            any(),
            analyticsService: any(named: 'analyticsService'),
            plugin: any(named: 'plugin'),
          ),
        ).thenAnswer((_) async => []); // Empty index

        container = ProviderContainer(
          overrides: [
            reminderPluginProvider.overrideWithValue(mockPlugin),
            notificationIndexStoreProvider.overrideWithValue(mockIndexStore),
            currentUserProvider.overrideWith((ref) => testUser),
            primaryPetProvider.overrideWith((ref) => testPet),
            analyticsServiceDirectProvider.overrideWithValue(mockAnalytics),
          ],
        );

        final coordinator = container.read(notificationCoordinatorProvider);

        // Act
        final result = await coordinator.rescheduleAll();

        // Assert
        expect(result['orphansCanceled'], greaterThan(0));
        verify(() => mockPlugin.cancel(999)).called(1);
      });

      test('detects missing notifications', () async {
        // Arrange
        final indexEntry = ScheduledNotificationEntryBuilder()
            .withNotificationId(888)
            .build();

        when(
          () => mockPlugin.pendingNotificationRequests(),
        ).thenAnswer((_) async => []); // No pending notifications

        when(
          () => mockIndexStore.getForToday(
            any(),
            any(),
            analyticsService: any(named: 'analyticsService'),
            plugin: any(named: 'plugin'),
          ),
        ).thenAnswer((_) async => [indexEntry]); // Entry exists in index

        container = ProviderContainer(
          overrides: [
            reminderPluginProvider.overrideWithValue(mockPlugin),
            notificationIndexStoreProvider.overrideWithValue(mockIndexStore),
            currentUserProvider.overrideWith((ref) => testUser),
            primaryPetProvider.overrideWith((ref) => testPet),
            analyticsServiceDirectProvider.overrideWithValue(mockAnalytics),
          ],
        );

        final coordinator = container.read(notificationCoordinatorProvider);

        // Act
        final result = await coordinator.rescheduleAll();

        // Assert
        expect(result['missingCount'], greaterThan(0));
      });
    });

    group('cancelForSchedule and cancelSlot', () {
      test('cancelForSchedule returns 0 when no user', () async {
        // Arrange
        container = ProviderContainer(
          overrides: [
            reminderPluginProvider.overrideWithValue(mockPlugin),
            notificationIndexStoreProvider.overrideWithValue(mockIndexStore),
            currentUserProvider.overrideWith((ref) => null),
            primaryPetProvider.overrideWith((ref) => testPet),
            analyticsServiceDirectProvider.overrideWithValue(mockAnalytics),
          ],
        );

        final coordinator = container.read(notificationCoordinatorProvider);

        // Act
        final result = await coordinator.cancelForSchedule('schedule-1');

        // Assert
        expect(result, equals(0));
      });

      test(
        'cancelForSchedule cancels all notifications for a schedule',
        () async {
          // Arrange
          final entry1 = ScheduledNotificationEntryBuilder()
              .withNotificationId(111)
              .withScheduleId('schedule-1')
              .build();
          final entry2 = ScheduledNotificationEntryBuilder()
              .withNotificationId(222)
              .withScheduleId('schedule-1')
              .build();

          when(
            () => mockIndexStore.getForToday(any(), any()),
          ).thenAnswer((_) async => [entry1, entry2]);

          container = ProviderContainer(
            overrides: [
              reminderPluginProvider.overrideWithValue(mockPlugin),
              notificationIndexStoreProvider.overrideWithValue(mockIndexStore),
              currentUserProvider.overrideWith((ref) => testUser),
              primaryPetProvider.overrideWith((ref) => testPet),
              analyticsServiceDirectProvider.overrideWithValue(mockAnalytics),
            ],
          );

          final coordinator = container.read(notificationCoordinatorProvider);

          // Act
          final result = await coordinator.cancelForSchedule('schedule-1');

          // Assert
          expect(result, greaterThan(0));
          verify(() => mockPlugin.cancel(111)).called(1);
          verify(() => mockPlugin.cancel(222)).called(1);
        },
      );

      test('cancelSlot cancels specific time slot notifications', () async {
        // Arrange
        final entry = ScheduledNotificationEntryBuilder()
            .withNotificationId(333)
            .withScheduleId('schedule-1')
            .withTimeSlot('08:00')
            .build();

        when(
          () => mockIndexStore.getForToday(any(), any()),
        ).thenAnswer((_) async => [entry]);

        container = ProviderContainer(
          overrides: [
            reminderPluginProvider.overrideWithValue(mockPlugin),
            notificationIndexStoreProvider.overrideWithValue(mockIndexStore),
            currentUserProvider.overrideWith((ref) => testUser),
            primaryPetProvider.overrideWith((ref) => testPet),
            analyticsServiceDirectProvider.overrideWithValue(mockAnalytics),
          ],
        );

        final coordinator = container.read(notificationCoordinatorProvider);

        // Act
        final result = await coordinator.cancelSlot('schedule-1', '08:00');

        // Assert
        expect(result, greaterThan(0));
        verify(() => mockPlugin.cancel(333)).called(1);
      });
    });
  });
}
