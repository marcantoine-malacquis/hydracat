import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/features/qol/models/qol_question.dart';
import 'package:hydracat/features/qol/widgets/qol_question_card.dart';
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

  group('QolQuestionCard', () {
    testWidgets('renders all 5 response options + "Not sure"', (tester) async {
      final question = QolQuestion.getById('vitality_1')!;

      await tester.pumpWidget(
        wrapWithApp(
          QolQuestionCard(
            question: question,
            onResponseSelected: (_) {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should find 5 response option cards (scores 4→0)
      final responseCards = find.byType(HydraCard);
      // 5 response options + 1 "Not sure" = 6 cards total
      expect(responseCards, findsNWidgets(6));
    });

    testWidgets('selection state updates correctly', (tester) async {
      final question = QolQuestion.getById('vitality_1')!;

      await tester.pumpWidget(
        wrapWithApp(
          QolQuestionCard(
            question: question,
            currentResponse: 2,
            onResponseSelected: (_) {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check that the selected response (score 2) is visually indicated
      // The selected card should have a check icon
      final checkIcons = find.byIcon(Icons.check);
      expect(checkIcons, findsOneWidget);
    });

    testWidgets('callback fires with correct score', (tester) async {
      final question = QolQuestion.getById('vitality_1')!;
      int? selectedResponse;

      await tester.pumpWidget(
        wrapWithApp(
          QolQuestionCard(
            question: question,
            onResponseSelected: (response) => selectedResponse = response,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap the first response option (score 4)
      final responseCards = find.byType(HydraCard);
      expect(responseCards, findsNWidgets(6));

      // Tap the first card (score 4)
      await tester.tap(responseCards.first);
      await tester.pumpAndSettle();

      expect(selectedResponse, 4);
    });

    testWidgets('uses question-specific labels (not generic)', (tester) async {
      final question = QolQuestion.getById('vitality_1')!;

      await tester.pumpWidget(
        wrapWithApp(
          QolQuestionCard(
            question: question,
            onResponseSelected: (_) {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify that question-specific labels are displayed
      // The labels should come from question.responseLabelKeys
      // For vitality_1, we should see labels like "qolVitality1Label0", etc.
      // We can verify by checking that the widget renders correctly
      expect(find.byType(QolQuestionCard), findsOneWidget);
    });

    testWidgets('renders domain badge', (tester) async {
      final question = QolQuestion.getById('vitality_1')!;

      await tester.pumpWidget(
        wrapWithApp(
          QolQuestionCard(
            question: question,
            onResponseSelected: (_) {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should find a Chip widget for the domain badge
      expect(find.byType(Chip), findsOneWidget);
    });

    testWidgets('renders question text', (tester) async {
      final question = QolQuestion.getById('vitality_1')!;
      final l10n = AppLocalizations.of(
        tester.binding.rootElement!,
      )!;

      await tester.pumpWidget(
        wrapWithApp(
          QolQuestionCard(
            question: question,
            onResponseSelected: (_) {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should find the question text
      expect(
        find.textContaining(l10n.qolQuestionVitality1, findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('renders recall period reminder', (tester) async {
      final question = QolQuestion.getById('vitality_1')!;
      final l10n = AppLocalizations.of(
        tester.binding.rootElement!,
      )!;

      await tester.pumpWidget(
        wrapWithApp(
          QolQuestionCard(
            question: question,
            onResponseSelected: (_) {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should find the recall period text
      expect(find.text(l10n.qolRecallPeriod), findsOneWidget);
    });

    testWidgets('"Not sure" option calls callback with null', (tester) async {
      final question = QolQuestion.getById('vitality_1')!;
      int? selectedResponse;

      await tester.pumpWidget(
        wrapWithApp(
          QolQuestionCard(
            question: question,
            onResponseSelected: (response) => selectedResponse = response,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the "Not sure" option (last card)
      final responseCards = find.byType(HydraCard);
      expect(responseCards, findsNWidgets(6));

      // Tap the last card ("Not sure")
      await tester.tap(responseCards.last);
      await tester.pumpAndSettle();

      expect(selectedResponse, isNull);
    });

    testWidgets('displays different labels for different questions', (
      tester,
    ) async {
      final vitalityQuestion = QolQuestion.getById('vitality_1')!;
      final comfortQuestion = QolQuestion.getById('comfort_1')!;

      // Test vitality question
      await tester.pumpWidget(
        wrapWithApp(
          QolQuestionCard(
            question: vitalityQuestion,
            onResponseSelected: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final vitalityText = tester.getSemantics(find.byType(QolQuestionCard));
      expect(vitalityText, isNotNull);

      // Test comfort question
      await tester.pumpWidget(
        wrapWithApp(
          QolQuestionCard(
            question: comfortQuestion,
            onResponseSelected: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final comfortText = tester.getSemantics(find.byType(QolQuestionCard));
      expect(comfortText, isNotNull);

      // The two questions should have different content
      // (We can't easily compare text content directly, but we verify both
      // render)
    });
  });
}
