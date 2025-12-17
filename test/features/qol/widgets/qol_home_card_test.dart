import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hydracat/features/home/widgets/qol_home_card.dart';
import 'package:hydracat/features/qol/models/qol_assessment.dart';
import 'package:hydracat/features/qol/models/qol_response.dart';
import 'package:hydracat/features/qol/widgets/qol_radar_chart.dart';
import 'package:hydracat/l10n/app_localizations.dart';
import 'package:hydracat/providers/analytics_provider.dart';
import 'package:hydracat/providers/qol_provider.dart';
import 'package:hydracat/shared/widgets/buttons/hydra_button.dart';
import 'package:hydracat/shared/widgets/cards/hydra_card.dart';
import 'package:mocktail/mocktail.dart';

void main() {
  Widget wrapWithApp(Widget child, {List<Override>? overrides}) {
    return ProviderScope(
      overrides: overrides ?? [],
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => Scaffold(body: child),
            ),
            GoRoute(
              path: '/profile/qol/new',
              builder: (context, state) => const Scaffold(
                body: Center(child: Text('New Assessment Screen')),
              ),
            ),
            GoRoute(
              path: '/profile/qol/detail/:id',
              builder: (context, state) => Scaffold(
                body: Center(
                  child: Text('Detail Screen: ${state.pathParameters['id']}'),
                ),
              ),
            ),
            GoRoute(
              path: '/profile/qol',
              builder: (context, state) => const Scaffold(
                body: Center(child: Text('History Screen')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  QolAssessment createTestAssessment({
    double? overallScore,
    String? scoreBand,
  }) {
    final responses = <QolResponse>[];

    if (overallScore != null) {
      // Create complete assessment with all domains
      final questions = [
        'vitality_1',
        'vitality_2',
        'vitality_3',
        'comfort_1',
        'comfort_2',
        'comfort_3',
        'emotional_1',
        'emotional_2',
        'emotional_3',
        'appetite_1',
        'appetite_2',
        'appetite_3',
        'treatment_1',
        'treatment_2',
      ];

      // Convert overall score to individual question scores
      final rawScore = ((overallScore / 100.0) * 4.0).round().clamp(0, 4);

      for (final questionId in questions) {
        responses.add(QolResponse(questionId: questionId, score: rawScore));
      }
    }

    return QolAssessment(
      id: 'test-assessment-id',
      userId: 'test-user',
      petId: 'test-pet',
      date: DateTime(2025, 1, 15),
      responses: responses,
      createdAt: DateTime(2025, 1, 15),
    );
  }

  group('QolHomeCard', () {
    testWidgets('empty state shows CTA button', (tester) async {
      final l10n = AppLocalizations.of(tester.binding.rootElement!)!;

      await tester.pumpWidget(
        wrapWithApp(
          const QolHomeCard(),
          overrides: [
            currentQolAssessmentProvider.overrideWith((ref) => null),
            analyticsServiceDirectProvider.overrideWithValue(
              MockAnalyticsService(),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      // Should find the CTA button
      expect(find.byType(HydraButton), findsOneWidget);
      expect(find.text(l10n.qolStartAssessment), findsOneWidget);

      // Should show empty state card
      expect(find.byType(HydraCard), findsOneWidget);
    });

    testWidgets('populated state shows radar chart', (tester) async {
      final assessment = createTestAssessment(overallScore: 75);

      await tester.pumpWidget(
        wrapWithApp(
          const QolHomeCard(),
          overrides: [
            currentQolAssessmentProvider.overrideWith((ref) => assessment),
            analyticsServiceDirectProvider.overrideWithValue(
              MockAnalyticsService(),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      // Should find the radar chart
      expect(find.byType(QolRadarChart), findsOneWidget);

      // Should be compact variant
      final radarChart = tester.widget<QolRadarChart>(
        find.byType(QolRadarChart),
      );
      expect(radarChart.isCompact, isTrue);
    });

    testWidgets('tap navigates to detail screen', (tester) async {
      final assessment = createTestAssessment(overallScore: 75);

      await tester.pumpWidget(
        wrapWithApp(
          const QolHomeCard(),
          overrides: [
            currentQolAssessmentProvider.overrideWith((ref) => assessment),
            analyticsServiceDirectProvider.overrideWithValue(
              MockAnalyticsService(),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      // Find the card and tap it
      final card = find.byType(HydraCard);
      expect(card, findsWidgets);

      // Tap the main card (first one)
      await tester.tap(card.first);
      await tester.pumpAndSettle();

      // Should navigate to detail screen
      expect(
        find.text('Detail Screen: ${assessment.documentId}'),
        findsOneWidget,
      );
    });

    testWidgets('empty state CTA button navigates to new assessment', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapWithApp(
          const QolHomeCard(),
          overrides: [
            currentQolAssessmentProvider.overrideWith((ref) => null),
            analyticsServiceDirectProvider.overrideWithValue(
              MockAnalyticsService(),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap the CTA button
      final button = find.byType(HydraButton);
      expect(button, findsOneWidget);

      await tester.tap(button);
      await tester.pumpAndSettle();

      // Should navigate to new assessment screen
      expect(find.text('New Assessment Screen'), findsOneWidget);
    });

    testWidgets('shows assessment date in populated state', (tester) async {
      final assessment = createTestAssessment(overallScore: 75);
      final l10n = AppLocalizations.of(tester.binding.rootElement!)!;

      await tester.pumpWidget(
        wrapWithApp(
          const QolHomeCard(),
          overrides: [
            currentQolAssessmentProvider.overrideWith((ref) => assessment),
            analyticsServiceDirectProvider.overrideWithValue(
              MockAnalyticsService(),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      // Should find the assessment date text
      expect(
        find.textContaining(
          l10n.qolAssessedOn(''),
          findRichText: true,
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows score badge in populated state', (tester) async {
      final assessment = createTestAssessment(overallScore: 75);

      await tester.pumpWidget(
        wrapWithApp(
          const QolHomeCard(),
          overrides: [
            currentQolAssessmentProvider.overrideWith((ref) => assessment),
            analyticsServiceDirectProvider.overrideWithValue(
              MockAnalyticsService(),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      // Should find the score badge (shows "75%")
      expect(find.textContaining('75'), findsOneWidget);
    });

    testWidgets('shows "View History" link in populated state', (tester) async {
      final assessment = createTestAssessment(overallScore: 75);
      final l10n = AppLocalizations.of(tester.binding.rootElement!)!;

      await tester.pumpWidget(
        wrapWithApp(
          const QolHomeCard(),
          overrides: [
            currentQolAssessmentProvider.overrideWith((ref) => assessment),
            analyticsServiceDirectProvider.overrideWithValue(
              MockAnalyticsService(),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      // Should find the "View History" link
      expect(find.text(l10n.viewHistory), findsOneWidget);
    });

    testWidgets('"View History" link navigates to history screen', (
      tester,
    ) async {
      final assessment = createTestAssessment(overallScore: 75);
      final l10n = AppLocalizations.of(tester.binding.rootElement!)!;

      await tester.pumpWidget(
        wrapWithApp(
          const QolHomeCard(),
          overrides: [
            currentQolAssessmentProvider.overrideWith((ref) => assessment),
            analyticsServiceDirectProvider.overrideWithValue(
              MockAnalyticsService(),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap the "View History" link
      final historyLink = find.text(l10n.viewHistory);
      expect(historyLink, findsOneWidget);

      await tester.tap(historyLink);
      await tester.pumpAndSettle();

      // Should navigate to history screen
      expect(find.text('History Screen'), findsOneWidget);
    });
  });
}

/// Mock AnalyticsService for testing
class MockAnalyticsService extends Mock implements AnalyticsService {}
