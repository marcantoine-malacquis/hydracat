import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/features/auth/models/app_user.dart';
import 'package:hydracat/features/notifications/providers/notification_provider.dart';
import 'package:hydracat/features/notifications/widgets/notification_status_widget.dart';
import 'package:hydracat/l10n/app_localizations.dart';
import 'package:hydracat/providers/auth_provider.dart';

void main() {
  Widget wrapWithApp(Widget child) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(appBar: AppBar(actions: [child])),
    );
  }

  testWidgets('Bell icon shows when permission granted + setting enabled', (
    WidgetTester tester,
  ) async {
    const appUser = AppUser(id: 'user1', hasCompletedOnboarding: true);

    final container = ProviderContainer(
      overrides: [
        currentUserProvider.overrideWithValue(appUser),
        isAuthenticatedProvider.overrideWithValue(true),
        // Permission granted
        notificationPermissionStatusProvider.overrideWith((ref) {
          return NotificationPermissionNotifier()
            ..state = const AsyncValue.data(
              NotificationPermissionStatus.granted,
            );
        }),
        // Settings provider defaults to enableNotifications: true
        notificationSettingsProvider('user1').overrideWith((ref) {
          return NotificationSettingsNotifier('user1');
        }),
      ],
    );

    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: wrapWithApp(const NotificationStatusWidget()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const Key('notif_bell')), findsOneWidget);
  });

  testWidgets('Bell shows denied state when permission denied', (
    WidgetTester tester,
  ) async {
    const appUser = AppUser(id: 'user1');

    final container = ProviderContainer(
      overrides: [
        currentUserProvider.overrideWithValue(appUser),
        isAuthenticatedProvider.overrideWithValue(true),
        // Permission denied
        notificationPermissionStatusProvider.overrideWith((ref) {
          return NotificationPermissionNotifier()
            ..state = const AsyncValue.data(
              NotificationPermissionStatus.denied,
            );
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
        child: wrapWithApp(const NotificationStatusWidget()),
      ),
    );
    await tester.pumpAndSettle();

    // Confirm denied icon renders
    expect(find.byIcon(Icons.notifications_off), findsOneWidget);
  });
}

// No fakes needed in simplified version
