import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/providers/analytics_provider.dart';
import 'package:mocktail/mocktail.dart';

class _MockFirebaseAnalytics extends Mock implements FirebaseAnalytics {}

void main() {
  setUpAll(() {
    registerFallbackValue(<String, Object>{});
  });

  group('AnalyticsService weekly progress tracking', () {
    late _MockFirebaseAnalytics mock;
    late AnalyticsService service;

    setUp(() {
      mock = _MockFirebaseAnalytics();
      service = AnalyticsService(mock)..setEnabled(enabled: true);
    });

    test('trackWeeklyProgressViewed includes all parameters', () async {
      when(
        () => mock.logEvent(
          name: any(named: 'name'),
          parameters: any(named: 'parameters'),
        ),
      ).thenAnswer((_) async {});

      await service.trackWeeklyProgressViewed(
        fillPercentage: 0.75,
        currentVolume: 1050,
        goalVolume: 1400,
        daysRemainingInWeek: 3,
        lastInjectionSite: 'Left Flank',
        petId: 'pet_123',
      );

      final captured = verify(
        () => mock.logEvent(
          name: AnalyticsEvents.weeklyProgressViewed,
          parameters: captureAny(named: 'parameters'),
        ),
      ).captured.single as Map<String, Object>;

      expect(captured['weekly_fill_percentage'], 0.75);
      expect(captured['weekly_current_volume'], 1050.0);
      expect(captured['weekly_goal_volume'], 1400);
      expect(captured['days_remaining_in_week'], 3);
      expect(captured['last_injection_site'], 'Left Flank');
      expect(captured['pet_id'], 'pet_123');
    });

    test('trackWeeklyProgressViewed omits optional parameters when null',
        () async {
      when(
        () => mock.logEvent(
          name: any(named: 'name'),
          parameters: any(named: 'parameters'),
        ),
      ).thenAnswer((_) async {});

      await service.trackWeeklyProgressViewed(
        fillPercentage: 0.5,
        currentVolume: 700,
        goalVolume: 1400,
        daysRemainingInWeek: 5,
      );

      final captured = verify(
        () => mock.logEvent(
          name: AnalyticsEvents.weeklyProgressViewed,
          parameters: captureAny(named: 'parameters'),
        ),
      ).captured.single as Map<String, Object>;

      expect(captured['weekly_fill_percentage'], 0.5);
      expect(captured['weekly_current_volume'], 700.0);
      expect(captured['weekly_goal_volume'], 1400);
      expect(captured['days_remaining_in_week'], 5);
      expect(captured.containsKey('last_injection_site'), false);
      expect(captured.containsKey('pet_id'), false);
    });

    test('trackWeeklyGoalAchieved includes all parameters', () async {
      when(
        () => mock.logEvent(
          name: any(named: 'name'),
          parameters: any(named: 'parameters'),
        ),
      ).thenAnswer((_) async {});

      await service.trackWeeklyGoalAchieved(
        finalVolume: 1450,
        goalVolume: 1400,
        daysRemainingInWeek: 3,
        achievedEarly: true,
        petId: 'pet_123',
      );

      final captured = verify(
        () => mock.logEvent(
          name: AnalyticsEvents.weeklyGoalAchieved,
          parameters: captureAny(named: 'parameters'),
        ),
      ).captured.single as Map<String, Object>;

      expect(captured['weekly_current_volume'], 1450.0);
      expect(captured['weekly_goal_volume'], 1400);
      expect(captured['days_remaining_in_week'], 3);
      expect(captured['achieved_early'], true);
      expect(captured['pet_id'], 'pet_123');
    });

    test('trackWeeklyGoalAchieved omits petId when null', () async {
      when(
        () => mock.logEvent(
          name: any(named: 'name'),
          parameters: any(named: 'parameters'),
        ),
      ).thenAnswer((_) async {});

      await service.trackWeeklyGoalAchieved(
        finalVolume: 1400,
        goalVolume: 1400,
        daysRemainingInWeek: 0,
        achievedEarly: false,
      );

      final captured = verify(
        () => mock.logEvent(
          name: AnalyticsEvents.weeklyGoalAchieved,
          parameters: captureAny(named: 'parameters'),
        ),
      ).captured.single as Map<String, Object>;

      expect(captured['weekly_current_volume'], 1400.0);
      expect(captured['weekly_goal_volume'], 1400);
      expect(captured['days_remaining_in_week'], 0);
      expect(captured['achieved_early'], false);
      expect(captured.containsKey('pet_id'), false);
    });

    test('trackWeeklyProgressViewed does not track when analytics disabled',
        () async {
      service.setEnabled(enabled: false);

      await service.trackWeeklyProgressViewed(
        fillPercentage: 0.75,
        currentVolume: 1050,
        goalVolume: 1400,
        daysRemainingInWeek: 3,
      );

      verifyNever(
        () => mock.logEvent(
          name: any(named: 'name'),
          parameters: any(named: 'parameters'),
        ),
      );
    });

    test('trackWeeklyGoalAchieved does not track when analytics disabled',
        () async {
      service.setEnabled(enabled: false);

      await service.trackWeeklyGoalAchieved(
        finalVolume: 1450,
        goalVolume: 1400,
        daysRemainingInWeek: 3,
        achievedEarly: true,
      );

      verifyNever(
        () => mock.logEvent(
          name: any(named: 'name'),
          parameters: any(named: 'parameters'),
        ),
      );
    });
  });
}
