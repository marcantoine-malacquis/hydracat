import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/features/qol/models/qol_assessment.dart';
import 'package:hydracat/features/qol/models/qol_response.dart';
import 'package:hydracat/features/qol/widgets/qol_score_summary_card.dart';
import 'package:hydracat/l10n/app_localizations.dart';

void main() {
  Widget wrapWithApp(Widget child) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );
  }

  QolAssessment createAssessment({
    double? overallScore,
    String? scoreBand,
    bool hasLowConfidence = false,
    bool isComplete = true,
  }) {
    final responses = <QolResponse>[];

    if (overallScore != null && !hasLowConfidence) {
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
      // overallScore is 0-100, need to convert to 0-4 scale
      final rawScore = ((overallScore / 100.0) * 4.0).round().clamp(0, 4);

      for (final questionId in questions) {
        responses.add(QolResponse(questionId: questionId, score: rawScore));
      }
    } else if (hasLowConfidence) {
      // Create assessment with only some domains answered
      // Answer only 1 question per domain (less than 50% threshold)
      responses
        ..add(const QolResponse(questionId: 'vitality_1', score: 4))
        ..add(const QolResponse(questionId: 'comfort_1', score: 3));
      // Other domains are not answered
    } else if (!isComplete) {
      // Create incomplete assessment
      responses
        ..add(const QolResponse(questionId: 'vitality_1', score: 4))
        ..add(const QolResponse(questionId: 'vitality_2', score: 3));
      // Only 2 of 14 questions answered
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

  group('QolScoreSummaryCard', () {
    testWidgets('renders score circle with overall score', (tester) async {
      final assessment = createAssessment(overallScore: 75);

      await tester.pumpWidget(
        wrapWithApp(QolScoreSummaryCard(assessment: assessment)),
      );

      await tester.pumpAndSettle();

      // Should find the score display (75)
      expect(find.text('75'), findsOneWidget);
    });

    testWidgets('renders score band label', (tester) async {
      final assessment = createAssessment(overallScore: 75);
      final l10n = AppLocalizations.of(tester.binding.rootElement!)!;

      await tester.pumpWidget(
        wrapWithApp(QolScoreSummaryCard(assessment: assessment)),
      );

      await tester.pumpAndSettle();

      // Should find the score band label (e.g., "Good" for 75)
      expect(find.text(l10n.qolScoreBandGood), findsOneWidget);
    });

    testWidgets('shows low confidence badge when applicable', (tester) async {
      final assessment = createAssessment(hasLowConfidence: true);
      final l10n = AppLocalizations.of(tester.binding.rootElement!)!;

      await tester.pumpWidget(
        wrapWithApp(QolScoreSummaryCard(assessment: assessment)),
      );

      await tester.pumpAndSettle();

      // Should find the low confidence badge
      // The badge shows "Based on X domains"
      expect(
        find.textContaining(l10n.qolBasedOnDomains(2)),
        findsOneWidget,
      );
    });

    testWidgets('renders assessment date', (tester) async {
      final assessment = createAssessment(overallScore: 75);
      final l10n = AppLocalizations.of(tester.binding.rootElement!)!;

      await tester.pumpWidget(
        wrapWithApp(QolScoreSummaryCard(assessment: assessment)),
      );

      await tester.pumpAndSettle();

      // Should find the assessment date text
      // Format: "Assessed on [date]"
      expect(
        find.textContaining(l10n.qolAssessedOn(''), findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('shows completion indicator when incomplete', (tester) async {
      final assessment = createAssessment(isComplete: false);
      final l10n = AppLocalizations.of(tester.binding.rootElement!)!;

      await tester.pumpWidget(
        wrapWithApp(QolScoreSummaryCard(assessment: assessment)),
      );

      await tester.pumpAndSettle();

      // Should find the completion indicator
      expect(
        find.textContaining(
          l10n.qolQuestionsAnswered(2, 14),
          findRichText: true,
        ),
        findsOneWidget,
      );
    });

    testWidgets('does not show completion indicator when complete', (
      tester,
    ) async {
      final assessment = createAssessment(overallScore: 75);
      final l10n = AppLocalizations.of(tester.binding.rootElement!)!;

      await tester.pumpWidget(
        wrapWithApp(QolScoreSummaryCard(assessment: assessment)),
      );

      await tester.pumpAndSettle();

      // Should not find the completion indicator
      expect(
        find.textContaining(
          l10n.qolQuestionsAnswered(14, 14),
          findRichText: true,
        ),
        findsNothing,
      );
    });

    testWidgets('renders different score bands correctly', (tester) async {
      final l10n = AppLocalizations.of(tester.binding.rootElement!)!;

      // Test "Very Good" band (>= 80)
      final veryGoodAssessment = createAssessment(overallScore: 85);
      await tester.pumpWidget(
        wrapWithApp(QolScoreSummaryCard(assessment: veryGoodAssessment)),
      );
      await tester.pumpAndSettle();
      expect(find.text(l10n.qolScoreBandVeryGood), findsOneWidget);

      // Test "Good" band (60-79)
      final goodAssessment = createAssessment(overallScore: 70);
      await tester.pumpWidget(
        wrapWithApp(QolScoreSummaryCard(assessment: goodAssessment)),
      );
      await tester.pumpAndSettle();
      expect(find.text(l10n.qolScoreBandGood), findsOneWidget);

      // Test "Fair" band (40-59)
      final fairAssessment = createAssessment(overallScore: 50);
      await tester.pumpWidget(
        wrapWithApp(QolScoreSummaryCard(assessment: fairAssessment)),
      );
      await tester.pumpAndSettle();
      expect(find.text(l10n.qolScoreBandFair), findsOneWidget);

      // Test "Low" band (< 40)
      final lowAssessment = createAssessment(overallScore: 30);
      await tester.pumpWidget(
        wrapWithApp(QolScoreSummaryCard(assessment: lowAssessment)),
      );
      await tester.pumpAndSettle();
      expect(find.text(l10n.qolScoreBandLow), findsOneWidget);
    });

    testWidgets('handles null overall score', (tester) async {
      final assessment = createAssessment();

      await tester.pumpWidget(
        wrapWithApp(QolScoreSummaryCard(assessment: assessment)),
      );

      await tester.pumpAndSettle();

      // Should show 0 for null score
      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('low confidence badge is tappable', (tester) async {
      final assessment = createAssessment(hasLowConfidence: true);

      await tester.pumpWidget(
        wrapWithApp(QolScoreSummaryCard(assessment: assessment)),
      );

      await tester.pumpAndSettle();

      // Find the low confidence badge (InkWell)
      final inkWell = find.byType(InkWell);
      expect(inkWell, findsOneWidget);

      // Tap the badge
      await tester.tap(inkWell);
      await tester.pumpAndSettle();

      // Should show a dialog
      expect(find.byType(Dialog), findsOneWidget);
    });
  });
}
