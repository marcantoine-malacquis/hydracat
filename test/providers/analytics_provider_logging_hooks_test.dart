import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/providers/analytics_provider.dart';
import 'package:mocktail/mocktail.dart';

class _MockFirebaseAnalytics extends Mock implements FirebaseAnalytics {}

void main() {
  setUpAll(() {
    registerFallbackValue(<String, Object>{});
  });

  group('AnalyticsService logging hooks', () {
    late _MockFirebaseAnalytics mock;
    late AnalyticsService service;

    setUp(() {
      mock = _MockFirebaseAnalytics();
      service = AnalyticsService(mock)..setEnabled(enabled: true);
    });

    test('trackSessionLogged includes source and durationMs', () async {
      when(
        () => mock.logEvent(
          name: any(named: 'name'),
          parameters: any(named: 'parameters'),
        ),
      ).thenAnswer((_) async {});

      await service.trackSessionLogged(
        treatmentType: 'medication',
        sessionCount: 1,
        isQuickLog: false,
        adherenceStatus: 'complete',
        medicationName: 'amlodipine',
        source: 'manual',
        durationMs: 123,
      );

      final captured =
          verify(
                () => mock.logEvent(
                  name: AnalyticsEvents.sessionLogged,
                  parameters: captureAny(named: 'parameters'),
                ),
              ).captured.single
              as Map<String, Object>;

      expect(captured['treatment_type'], 'medication');
      expect(captured['session_count'], 1);
      expect(captured['adherence_status'], 'complete');
      expect(captured['source'], 'manual');
      expect(captured['duration_ms'], 123);
      expect(captured['medication_name'], 'amlodipine');
    });

    test('trackQuickLogUsed includes durationMs when provided', () async {
      when(
        () => mock.logEvent(
          name: any(named: 'name'),
          parameters: any(named: 'parameters'),
        ),
      ).thenAnswer((_) async {});

      await service.trackQuickLogUsed(
        sessionCount: 5,
        medicationCount: 3,
        fluidCount: 2,
        durationMs: 456,
      );

      final captured =
          verify(
                () => mock.logEvent(
                  name: AnalyticsEvents.quickLogUsed,
                  parameters: captureAny(named: 'parameters'),
                ),
              ).captured.single
              as Map<String, Object>;

      expect(captured['session_count'], 5);
      expect(captured['medication_count'], 3);
      expect(captured['fluid_count'], 2);
      expect(captured['duration_ms'], 456);
    });

    test('trackLoggingFailure maps standard fields', () async {
      when(
        () => mock.logEvent(
          name: any(named: 'name'),
          parameters: any(named: 'parameters'),
        ),
      ).thenAnswer((_) async {});

      await service.trackLoggingFailure(
        errorType: 'batch_write_failure',
        treatmentType: 'fluid',
        source: 'update',
        errorCode: 'permission-denied',
        exception: 'FirebaseException',
        extra: {'queue_size': 7},
      );

      final captured =
          verify(
                () => mock.logEvent(
                  name: AnalyticsEvents.error,
                  parameters: captureAny(named: 'parameters'),
                ),
              ).captured.single
              as Map<String, Object>;

      expect(captured['error_type'], 'batch_write_failure');
      expect(captured['treatment_type'], 'fluid');
      expect(captured['source'], 'update');
      expect(captured['error_code'], 'permission-denied');
      expect(captured['exception'], 'FirebaseException');
      expect(captured['queue_size'], 7);
    });
  });
}
