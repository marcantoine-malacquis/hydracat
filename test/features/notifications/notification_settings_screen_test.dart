import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/features/auth/models/app_user.dart';
import 'package:hydracat/features/notifications/providers/notification_provider.dart';
import 'package:hydracat/features/settings/screens/notification_settings_screen.dart';
import 'package:hydracat/l10n/app_localizations.dart';
import 'package:hydracat/providers/analytics_provider.dart';
import 'package:hydracat/providers/auth_provider.dart';
import 'package:hydracat/providers/profile_provider.dart';

void main() {
  Widget wrapWithApp(Widget child) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );
  }

  testWidgets('NotificationSettingsScreen shows toggles for user', (
    WidgetTester tester,
  ) async {
    const appUser = AppUser(
      id: 'user1',
      hasCompletedOnboarding: true,
      emailVerified: true,
    );

    // Provide a ProfileState override for controlled test behavior
    // (using defaults; widget-only assertions here)
    final container = ProviderContainer(
      overrides: [
        currentUserProvider.overrideWithValue(appUser),
        isAuthenticatedProvider.overrideWithValue(true),
        hasCompletedOnboardingProvider.overrideWithValue(true),
        // Analytics direct calls become no-ops
        analyticsServiceDirectProvider.overrideWithValue(
          AnalyticsService(_FakeFirebaseAnalytics()),
        ),
        // Permission granted
        notificationPermissionStatusProvider.overrideWith((ref) {
          // Provide granted state immediately
          return NotificationPermissionNotifier()
            ..state = const AsyncValue.data(
              NotificationPermissionStatus.granted,
            );
        }),
        // Profile with a primary pet (minimal state)
        profileProvider.overrideWith((ref) {
          return ProfileNotifier(
            ref.read(petServiceProvider),
            ref.read(scheduleServiceProvider),
            ref,
          )..state = const ProfileState();
        }),
        // Settings default to enableNotifications: true; notifier
        //loads defaults
        notificationSettingsProvider('user1').overrideWith((ref) {
          return NotificationSettingsNotifier('user1');
        }),
      ],
    );

    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: wrapWithApp(const NotificationSettingsScreen()),
      ),
    );

    // Allow initial async notifiers to settle
    await tester.pumpAndSettle();

    // Master toggle key should be present
    expect(find.byKey(const Key('notif_master_toggle')), findsOneWidget);

    // Weekly toggle key should be present
    expect(find.byKey(const Key('notif_weekly_toggle')), findsOneWidget);

    // Privacy row validated in integration tests; core toggles present here
  });

  // Dialog behavior covered in integration; widget test asserts remain minimal

  testWidgets('Helper banner shows when no pet profile', (
    WidgetTester tester,
  ) async {
    const appUser = AppUser(id: 'user1');

    final container = ProviderContainer(
      overrides: [
        currentUserProvider.overrideWithValue(appUser),
        isAuthenticatedProvider.overrideWithValue(true),
        hasCompletedOnboardingProvider.overrideWithValue(true),
        analyticsServiceDirectProvider.overrideWithValue(
          AnalyticsService(_FakeFirebaseAnalytics()),
        ),
        notificationPermissionStatusProvider.overrideWith((ref) {
          return NotificationPermissionNotifier()
            ..state = const AsyncValue.data(
              NotificationPermissionStatus.granted,
            );
        }),
        // Profile with no pet
        profileProvider.overrideWith((ref) {
          return ProfileNotifier(
            ref.read(petServiceProvider),
            ref.read(scheduleServiceProvider),
            ref,
          )..state = const ProfileState.initial();
        }),
        notificationSettingsProvider('user1').overrideWith((ref) {
          return NotificationSettingsNotifier('user1');
        }),
      ],
    );

    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: wrapWithApp(const NotificationSettingsScreen()),
      ),
    );

    await tester.pumpAndSettle();

    // Helper banner should be visible when no pet profile
    expect(find.byKey(const Key('notif_helper_banner')), findsOneWidget);
  });
}

class _FakeFirebaseAnalytics implements FirebaseAnalytics {
  @override
  Future<void> setAnalyticsCollectionEnabled(bool enabled) async {}

  @override
  Future<void> setUserId({String? id, Object? callOptions}) async {}

  @override
  Future<void> setUserProperty({
    required String name,
    String? value,
    Object? callOptions,
  }) async {}

  @override
  Future<void> logEvent({
    required String name,
    Map<String, Object?>? parameters,
    Object? callOptions,
  }) async {}

  @override
  Future<void> logScreenView({
    String? screenClass,
    String? screenName,
    Map<String, Object?>? parameters,
    Object? callOptions,
  }) async {}

  @override
  Future<void> resetAnalyticsData() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
