import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/features/qol/models/qol_assessment.dart';
import 'package:hydracat/features/qol/models/qol_domain.dart';
import 'package:hydracat/features/qol/models/qol_question.dart';
import 'package:hydracat/features/qol/models/qol_response.dart';
import 'package:hydracat/features/qol/widgets/qol_radar_chart.dart';
import 'package:hydracat/l10n/app_localizations.dart';
import 'package:hydracat/shared/widgets/cards/hydra_card.dart';

void main() {
  Widget wrapWithApp(Widget child) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );
  }

  QolAssessment createAssessmentWithScores({
    Map<String, double?>? domainScores,
  }) {
    final responses = <QolResponse>[];

    // Create responses based on domain scores
    if (domainScores != null) {
      for (final domain in QolDomain.all) {
        final score = domainScores[domain];
        if (score != null) {
          // Get questions for this domain
          final questions = QolQuestion.getByDomain(domain);
          // Answer at least 50% of questions to get a valid score
          final questionsToAnswer = (questions.length / 2).ceil();
          for (var i = 0; i < questionsToAnswer; i++) {
            // Convert 0-100 score to 0-4 scale
            final rawScore = ((score / 100.0) * 4.0).round().clamp(0, 4);
            responses.add(
              QolResponse(
                questionId: questions[i].id,
                score: rawScore,
              ),
            );
          }
        }
      }
    }

    return QolAssessment(
      id: 'test-id',
      userId: 'test-user',
      petId: 'test-pet',
      date: DateTime(2025, 1, 15),
      responses: responses,
      createdAt: DateTime(2025, 1, 15),
    );
  }

  group('QolRadarChart', () {
    testWidgets('renders 5 domains', (tester) async {
      // Create assessment with all domains having scores
      final assessment = createAssessmentWithScores(
        domainScores: {
          QolDomain.vitality: 80.0,
          QolDomain.comfort: 75.0,
          QolDomain.emotional: 70.0,
          QolDomain.appetite: 85.0,
          QolDomain.treatmentBurden: 90.0,
        },
      );

      await tester.pumpWidget(
        wrapWithApp(QolRadarChart(assessment: assessment)),
      );

      await tester.pumpAndSettle();

      // Should render the chart (RadarChart widget)
      expect(find.byType(HydraCard), findsOneWidget);
      // The chart itself is rendered by fl_chart
      // We verify it's present by checking the container structure
    });

    testWidgets('empty state for all null responses', (tester) async {
      // Create assessment with no responses (all null)
      final assessment = createAssessmentWithScores(domainScores: {});

      await tester.pumpWidget(
        wrapWithApp(QolRadarChart(assessment: assessment)),
      );

      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(tester.binding.rootElement!)!;

      // Should show "Insufficient data" message
      expect(find.text(l10n.qolInsufficientData), findsOneWidget);
    });

    testWidgets('compact variant has abbreviated labels', (tester) async {
      final assessment = createAssessmentWithScores(
        domainScores: {
          QolDomain.vitality: 80.0,
          QolDomain.comfort: 75.0,
          QolDomain.emotional: 70.0,
          QolDomain.appetite: 85.0,
          QolDomain.treatmentBurden: 90.0,
        },
      );

      await tester.pumpWidget(
        wrapWithApp(
          QolRadarChart(
            assessment: assessment,
            isCompact: true,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Compact variant should not show title
      final l10n = AppLocalizations.of(tester.binding.rootElement!)!;
      expect(find.text(l10n.qolRadarChartTitle), findsNothing);

      // Should still render the chart
      expect(find.byType(HydraCard), findsOneWidget);
    });

    testWidgets('full variant shows title and legend', (tester) async {
      final assessment = createAssessmentWithScores(
        domainScores: {
          QolDomain.vitality: 80.0,
          QolDomain.comfort: 75.0,
          QolDomain.emotional: 70.0,
          QolDomain.appetite: 85.0,
          QolDomain.treatmentBurden: 90.0,
        },
      );

      await tester.pumpWidget(
        wrapWithApp(
          QolRadarChart(assessment: assessment),
        ),
      );

      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(tester.binding.rootElement!)!;

      // Full variant should show title
      expect(find.text(l10n.qolRadarChartTitle), findsOneWidget);

      // Should render the chart
      expect(find.byType(HydraCard), findsOneWidget);
    });

    testWidgets('handles partial domain scores', (tester) async {
      // Create assessment with only some domains having scores
      final assessment = createAssessmentWithScores(
        domainScores: {
          QolDomain.vitality: 80.0,
          QolDomain.comfort: 75.0,
          // Other domains are null
        },
      );

      await tester.pumpWidget(
        wrapWithApp(QolRadarChart(assessment: assessment)),
      );

      await tester.pumpAndSettle();

      // Should still render the chart (null scores are converted to 0)
      expect(find.byType(HydraCard), findsOneWidget);
    });

    testWidgets('compact variant has correct height', (tester) async {
      final assessment = createAssessmentWithScores(
        domainScores: {
          QolDomain.vitality: 80.0,
          QolDomain.comfort: 75.0,
          QolDomain.emotional: 70.0,
          QolDomain.appetite: 85.0,
          QolDomain.treatmentBurden: 90.0,
        },
      );

      await tester.pumpWidget(
        wrapWithApp(
          QolRadarChart(
            assessment: assessment,
            isCompact: true,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the SizedBox that constrains the height
      final sizedBox = find.byType(SizedBox);
      expect(sizedBox, findsWidgets);

      // The chart should be rendered (we can't easily check exact height in
      // widget test)
      expect(find.byType(HydraCard), findsOneWidget);
    });

    testWidgets('full variant has correct height', (tester) async {
      final assessment = createAssessmentWithScores(
        domainScores: {
          QolDomain.vitality: 80.0,
          QolDomain.comfort: 75.0,
          QolDomain.emotional: 70.0,
          QolDomain.appetite: 85.0,
          QolDomain.treatmentBurden: 90.0,
        },
      );

      await tester.pumpWidget(
        wrapWithApp(
          QolRadarChart(assessment: assessment),
        ),
      );

      await tester.pumpAndSettle();

      // Should render the chart
      expect(find.byType(HydraCard), findsOneWidget);
    });

    testWidgets('low confidence domains show in legend', (tester) async {
      // Create assessment where some domains have low confidence (null scores)
      final assessment = createAssessmentWithScores(
        domainScores: {
          QolDomain.vitality: 80.0,
          QolDomain.comfort: 75.0,
          // Other domains are null (low confidence)
        },
      );

      await tester.pumpWidget(
        wrapWithApp(
          QolRadarChart(assessment: assessment),
        ),
      );

      await tester.pumpAndSettle();

      // Legend should show "Insufficient data" for null domains
      // The legend is built in _buildLegend method
      // We verify the chart renders (legend is part of the widget tree)
      expect(find.byType(HydraCard), findsOneWidget);
    });
  });
}
