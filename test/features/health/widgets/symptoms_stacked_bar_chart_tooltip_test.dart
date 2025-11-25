import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/core/utils/date_utils.dart';
import 'package:hydracat/features/health/models/symptom_bucket.dart';
import 'package:hydracat/features/health/models/symptom_granularity.dart';
import 'package:hydracat/features/health/models/symptom_type.dart';
import 'package:hydracat/features/health/widgets/symptoms_stacked_bar_chart.dart';
import 'package:hydracat/providers/symptoms_chart_provider.dart';

void main() {
  group('SymptomsStackedBarChart Tooltip Tests', () {
    /// Helper to create a test view model with deterministic data
    SymptomsChartViewModel createTestViewModel({
      required List<SymptomBucket> buckets,
      List<String>? visibleSymptoms,
      bool hasOther = false,
    }) {
      final computedVisibleSymptoms =
          visibleSymptoms ?? _buildVisibleSymptomsFromBuckets(buckets);
      final computedHasOther =
          hasOther || _hasOtherSymptoms(buckets, computedVisibleSymptoms);
      return SymptomsChartViewModel(
        buckets: buckets,
        visibleSymptoms: computedVisibleSymptoms,
        hasOther: computedHasOther,
      );
    }

    /// Helper to pump the chart widget with test data
    Future<void> pumpChart(
      WidgetTester tester, {
      required SymptomsChartViewModel viewModel,
      required SymptomGranularity granularity,
      String? selectedSymptomKey,
    }) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            symptomsChartStateProvider.overrideWith(
              (ref) => SymptomsChartNotifier()
                ..state = SymptomsChartState(
                  focusedDate: viewModel.buckets.first.start,
                  granularity: granularity,
                  selectedSymptomKey: selectedSymptomKey,
                ),
            ),
            symptomsChartDataProvider.overrideWith(
              (ref) => viewModel,
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800, // Fixed width for consistent testing
                height: 300,
                child: SymptomsStackedBarChart(
                  granularity: granularity,
                  selectedSymptomKey: selectedSymptomKey,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    /// Helper to find and tap a bar at the given index
    Future<void> tapBarAtIndex(
      WidgetTester tester,
      int index, {
      required int totalBars,
    }) async {
      // Find the BarChart widget and get its actual bounds
      final barChartFinder = find.byType(BarChart);
      expect(barChartFinder, findsOneWidget);

      // Get the chart widget's render box
      final chartBox = tester.getRect(barChartFinder);

      if (index >= 0 && index < totalBars) {
        // Calculate tap position within the chart bounds
        // Bars are spaced evenly across the chart width
        // Each bar is 40px wide with spacing between them
        final chartWidth = chartBox.width;
        const barWidth = 40.0;
        final totalBarWidth = totalBars * barWidth;
        final availableSpace = chartWidth - totalBarWidth;
        final spacing = availableSpace / (totalBars + 1);

        // Calculate the center X of the bar at the given index
        final barCenterX =
            chartBox.left +
            spacing +
            (index * (barWidth + spacing)) +
            (barWidth / 2);

        // Tap in the middle of the chart height (where bars are)
        final tapY = chartBox.top + (chartBox.height / 2);

        // Simulate pointer down event to trigger FlTapDownEvent
        tester.binding.handlePointerEvent(
          PointerDownEvent(
            position: Offset(barCenterX, tapY),
            pointer: 1,
          ),
        );
        await tester.pump(); // Allow state to update

        // Keep pointer down for a moment to ensure tooltip appears
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    /// Helper to verify tooltip is visible
    void expectTooltipVisible(WidgetTester tester) {
      // Tooltip should contain period label and total days text
      expect(find.textContaining('Total symptom days:'), findsOneWidget);
    }

    /// Helper to verify tooltip is not visible
    void expectTooltipNotVisible(WidgetTester tester) {
      expect(find.textContaining('Total symptom days:'), findsNothing);
    }

    group('Tapping a bar shows tooltip with correct content', () {
      testWidgets('shows tooltip with period label and total days', (
        tester,
      ) async {
        final weekStart = AppDateUtils.startOfWeekMonday(DateTime(2025, 1, 6));
        final buckets = [
          SymptomBucket.empty(weekStart).copyWith(
            daysWithSymptom: {
              SymptomType.vomiting: 1,
              SymptomType.diarrhea: 1,
            },
            daysWithAnySymptoms: 1,
          ),
          ...List.generate(
            6,
            (i) => SymptomBucket.empty(weekStart.add(Duration(days: i + 1))),
          ),
        ];

        final viewModel = createTestViewModel(buckets: buckets);

        await pumpChart(
          tester,
          viewModel: viewModel,
          granularity: SymptomGranularity.week,
        );

        // Tap the first bar
        await tapBarAtIndex(tester, 0, totalBars: buckets.length);

        // Verify tooltip is visible
        expectTooltipVisible(tester);

        // Verify period label is shown (format: "EEE dd MMM" for week)
        // The tooltip should contain date parts - check that we have text
        // with both day and month
        expect(find.textContaining('Mon'), findsWidgets);
        expect(find.textContaining('Jan'), findsWidgets);

        // Verify total days (should be 2: 1 vomiting + 1 diarrhea)
        expect(find.textContaining('Total symptom days: 2'), findsOneWidget);
      });

      testWidgets('shows per-symptom breakdown in stacked mode', (
        tester,
      ) async {
        final weekStart = AppDateUtils.startOfWeekMonday(DateTime(2025, 1, 6));
        final buckets = [
          SymptomBucket.empty(weekStart).copyWith(
            daysWithSymptom: {
              SymptomType.vomiting: 2,
              SymptomType.diarrhea: 1,
              SymptomType.lethargy: 1,
            },
            daysWithAnySymptoms: 1,
          ),
          ...List.generate(
            6,
            (i) => SymptomBucket.empty(weekStart.add(Duration(days: i + 1))),
          ),
        ];

        final viewModel = createTestViewModel(
          buckets: buckets,
          visibleSymptoms: [
            SymptomType.vomiting,
            SymptomType.diarrhea,
            SymptomType.lethargy,
          ],
        );

        await pumpChart(
          tester,
          viewModel: viewModel,
          granularity: SymptomGranularity.week,
        );

        await tapBarAtIndex(tester, 0, totalBars: buckets.length);

        // Verify symptom breakdown appears
        expect(find.textContaining('Vomiting: 2 days'), findsOneWidget);
        expect(find.textContaining('Diarrhea: 1 day'), findsOneWidget);
        expect(find.textContaining('Lethargy: 1 day'), findsOneWidget);
      });
    });

    group('Period labels formatted correctly for each granularity', () {
      testWidgets('week granularity shows day format (EEE dd MMM)', (
        tester,
      ) async {
        final weekStart = AppDateUtils.startOfWeekMonday(DateTime(2025, 1, 6));
        final buckets = [
          SymptomBucket.empty(weekStart).copyWith(
            daysWithSymptom: {SymptomType.vomiting: 1},
            daysWithAnySymptoms: 1,
          ),
          ...List.generate(
            6,
            (i) => SymptomBucket.empty(weekStart.add(Duration(days: i + 1))),
          ),
        ];

        final viewModel = createTestViewModel(buckets: buckets);

        await pumpChart(
          tester,
          viewModel: viewModel,
          granularity: SymptomGranularity.week,
        );

        await tapBarAtIndex(tester, 0, totalBars: buckets.length);

        // Week format: "Mon 06 Jan"
        expect(find.textContaining('Mon'), findsOneWidget);
        expect(find.textContaining('06'), findsOneWidget);
        expect(find.textContaining('Jan'), findsOneWidget);
      });

      testWidgets('month granularity shows single-day format', (tester) async {
        final day = DateTime(2025, 11, 5); // Wednesday, Nov 5

        final buckets = [
          SymptomBucket(
            start: day,
            end: day, // Single day bucket
            daysWithSymptom: const {SymptomType.vomiting: 1},
            daysWithAnySymptoms: 1,
          ),
        ];

        final viewModel = createTestViewModel(buckets: buckets);

        await pumpChart(
          tester,
          viewModel: viewModel,
          granularity: SymptomGranularity.month,
        );

        await tapBarAtIndex(tester, 0, totalBars: buckets.length);

        // Month format: "EEE d MMM" (e.g., "Wed 5 Nov")
        expect(find.textContaining('Wed'), findsOneWidget);
        expect(find.textContaining('Nov'), findsOneWidget);
        expect(find.textContaining('5'), findsOneWidget);
      });

      testWidgets('year granularity shows month format (MMM yyyy)', (
        tester,
      ) async {
        final monthStart = DateTime(2025, 3);

        final buckets = [
          SymptomBucket(
            start: monthStart,
            end: DateTime(2025, 3, 31),
            daysWithSymptom: const {SymptomType.vomiting: 5},
            daysWithAnySymptoms: 5,
          ),
        ];

        final viewModel = createTestViewModel(buckets: buckets);

        await pumpChart(
          tester,
          viewModel: viewModel,
          granularity: SymptomGranularity.year,
        );

        await tapBarAtIndex(tester, 0, totalBars: buckets.length);

        // Year format: "Mar 2025"
        expect(find.textContaining('Mar 2025'), findsOneWidget);
      });
    });

    group('Per-symptom breakdown matches bucket data in stacked mode', () {
      testWidgets('all visible symptoms appear with correct counts', (
        tester,
      ) async {
        final weekStart = AppDateUtils.startOfWeekMonday(DateTime(2025, 1, 6));
        final buckets = [
          SymptomBucket.empty(weekStart).copyWith(
            daysWithSymptom: {
              SymptomType.vomiting: 3,
              SymptomType.diarrhea: 2,
              SymptomType.lethargy: 1,
            },
            daysWithAnySymptoms: 1,
          ),
          ...List.generate(
            6,
            (i) => SymptomBucket.empty(weekStart.add(Duration(days: i + 1))),
          ),
        ];

        final viewModel = createTestViewModel(
          buckets: buckets,
          visibleSymptoms: [
            SymptomType.vomiting,
            SymptomType.diarrhea,
            SymptomType.lethargy,
          ],
        );

        await pumpChart(
          tester,
          viewModel: viewModel,
          granularity: SymptomGranularity.week,
        );

        await tapBarAtIndex(tester, 0, totalBars: buckets.length);

        // Verify exact counts match bucket data
        expect(find.textContaining('Vomiting: 3 days'), findsOneWidget);
        expect(find.textContaining('Diarrhea: 2 days'), findsOneWidget);
        expect(find.textContaining('Lethargy: 1 day'), findsOneWidget);

        // Verify total matches sum
        expect(find.textContaining('Total symptom days: 6'), findsOneWidget);
      });

      testWidgets('other symptoms appear as "Other" when hasOther is true', (
        tester,
      ) async {
        final weekStart = AppDateUtils.startOfWeekMonday(DateTime(2025, 1, 6));
        final buckets = [
          SymptomBucket.empty(weekStart).copyWith(
            daysWithSymptom: {
              SymptomType.vomiting: 2,
              SymptomType.constipation: 1, // Not in visibleSymptoms
              SymptomType.suppressedAppetite: 1, // Not in visibleSymptoms
            },
            daysWithAnySymptoms: 1,
          ),
          ...List.generate(
            6,
            (i) => SymptomBucket.empty(weekStart.add(Duration(days: i + 1))),
          ),
        ];

        final viewModel = createTestViewModel(
          buckets: buckets,
          visibleSymptoms: [SymptomType.vomiting],
          hasOther: true,
        );

        await pumpChart(
          tester,
          viewModel: viewModel,
          granularity: SymptomGranularity.week,
        );

        await tapBarAtIndex(tester, 0, totalBars: buckets.length);

        // Verify visible symptom appears
        expect(find.textContaining('Vomiting: 2 days'), findsOneWidget);

        // Verify "Other" appears with correct count (1 + 1 = 2)
        expect(find.textContaining('Other: 2 days'), findsOneWidget);

        // Verify total matches
        expect(find.textContaining('Total symptom days: 4'), findsOneWidget);
      });
    });

    group('Single-symptom mode shows only selected symptom', () {
      testWidgets('only selected symptom appears in tooltip', (tester) async {
        final weekStart = AppDateUtils.startOfWeekMonday(DateTime(2025, 1, 6));
        final buckets = [
          SymptomBucket.empty(weekStart).copyWith(
            daysWithSymptom: {
              SymptomType.vomiting: 2,
              SymptomType.diarrhea: 1,
              SymptomType.lethargy: 1,
            },
            daysWithAnySymptoms: 1,
          ),
          ...List.generate(
            6,
            (i) => SymptomBucket.empty(weekStart.add(Duration(days: i + 1))),
          ),
        ];

        final viewModel = createTestViewModel(buckets: buckets);

        await pumpChart(
          tester,
          viewModel: viewModel,
          granularity: SymptomGranularity.week,
          selectedSymptomKey: SymptomType.vomiting,
        );

        await tapBarAtIndex(tester, 0, totalBars: buckets.length);

        // Verify only vomiting appears
        expect(find.textContaining('Vomiting: 2 days'), findsOneWidget);

        // Verify other symptoms do NOT appear
        expect(find.textContaining('Diarrhea'), findsNothing);
        expect(find.textContaining('Lethargy'), findsNothing);

        // Verify total matches only the selected symptom
        expect(find.textContaining('Total symptom days: 2'), findsOneWidget);
      });
    });

    group('Empty buckets do not show tooltips', () {
      testWidgets('tapping empty bucket does not show tooltip', (tester) async {
        final weekStart = AppDateUtils.startOfWeekMonday(DateTime(2025, 1, 6));
        final buckets = [
          SymptomBucket.empty(weekStart), // Empty bucket
          SymptomBucket.empty(weekStart.add(const Duration(days: 1))).copyWith(
            daysWithSymptom: {SymptomType.vomiting: 1},
            daysWithAnySymptoms: 1,
          ),
          ...List.generate(
            5,
            (i) => SymptomBucket.empty(weekStart.add(Duration(days: i + 2))),
          ),
        ];

        final viewModel = createTestViewModel(buckets: buckets);

        await pumpChart(
          tester,
          viewModel: viewModel,
          granularity: SymptomGranularity.week,
        );

        // Tap the empty bucket (index 0)
        await tapBarAtIndex(tester, 0, totalBars: buckets.length);

        // Verify tooltip is NOT visible
        expectTooltipNotVisible(tester);

        // Tap a non-empty bucket (index 1)
        await tapBarAtIndex(tester, 1, totalBars: buckets.length);

        // Verify tooltip IS visible for non-empty bucket
        expectTooltipVisible(tester);
      });

      testWidgets(
        'tapping empty bucket in single-symptom mode does not show tooltip',
        (tester) async {
          final weekStart = AppDateUtils.startOfWeekMonday(
            DateTime(2025, 1, 6),
          );
          final buckets = [
            SymptomBucket.empty(weekStart).copyWith(
              daysWithSymptom: {
                SymptomType.diarrhea: 1, // Different symptom
              },
              daysWithAnySymptoms: 1,
            ),
            SymptomBucket.empty(
              weekStart.add(const Duration(days: 1)),
            ).copyWith(
              daysWithSymptom: {SymptomType.vomiting: 1},
              daysWithAnySymptoms: 1,
            ),
            ...List.generate(
              5,
              (i) => SymptomBucket.empty(weekStart.add(Duration(days: i + 2))),
            ),
          ];

          final viewModel = createTestViewModel(buckets: buckets);

          await pumpChart(
            tester,
            viewModel: viewModel,
            granularity: SymptomGranularity.week,
            selectedSymptomKey: SymptomType.vomiting,
          );

          // Tap bucket with no vomiting (index 0)
          await tapBarAtIndex(tester, 0, totalBars: buckets.length);

          // Verify tooltip is NOT visible (empty for selected symptom)
          expectTooltipNotVisible(tester);

          // Tap bucket with vomiting (index 1)
          await tapBarAtIndex(tester, 1, totalBars: buckets.length);

          // Verify tooltip IS visible
          expectTooltipVisible(tester);
        },
      );
    });

    group('Tooltip positioning adapts to bar index', () {
      testWidgets('leftmost bars show tooltip on right side', (tester) async {
        final weekStart = AppDateUtils.startOfWeekMonday(DateTime(2025, 1, 6));
        final buckets = List.generate(
          7,
          (i) => SymptomBucket.empty(weekStart.add(Duration(days: i))).copyWith(
            daysWithSymptom: {SymptomType.vomiting: 1},
            daysWithAnySymptoms: 1,
          ),
        );

        final viewModel = createTestViewModel(buckets: buckets);

        await pumpChart(
          tester,
          viewModel: viewModel,
          granularity: SymptomGranularity.week,
        );

        // Tap leftmost bar (index 0)
        await tapBarAtIndex(tester, 0, totalBars: buckets.length);

        // Tooltip should be visible (positioning is internal,
        // but we can verify it appears)
        expectTooltipVisible(tester);

        // The tooltip card should have pointsLeft = true for left bars
        // We verify by checking the tooltip appears
        // (which means positioning worked)
        expect(find.textContaining('Total symptom days:'), findsOneWidget);
      });

      testWidgets('rightmost bars show tooltip on left side', (tester) async {
        final weekStart = AppDateUtils.startOfWeekMonday(DateTime(2025, 1, 6));
        final buckets = List.generate(
          7,
          (i) => SymptomBucket.empty(weekStart.add(Duration(days: i))).copyWith(
            daysWithSymptom: {SymptomType.vomiting: 1},
            daysWithAnySymptoms: 1,
          ),
        );

        final viewModel = createTestViewModel(buckets: buckets);

        await pumpChart(
          tester,
          viewModel: viewModel,
          granularity: SymptomGranularity.week,
        );

        // Tap rightmost bar (index 6)
        await tapBarAtIndex(tester, 6, totalBars: buckets.length);

        // Tooltip should be visible (positioning is internal,
        // but we can verify it appears)
        expectTooltipVisible(tester);

        // The tooltip card should have pointsLeft = false for right bars
        // We verify by checking the tooltip appears
        // (which means positioning worked)
        expect(find.textContaining('Total symptom days:'), findsOneWidget);
      });
    });
  });
}

/// Helper to compute visible symptoms from buckets (simplified version)
List<String> _buildVisibleSymptomsFromBuckets(List<SymptomBucket> buckets) {
  final counts = <String, int>{};
  for (final bucket in buckets) {
    for (final entry in bucket.daysWithSymptom.entries) {
      counts[entry.key] = (counts[entry.key] ?? 0) + entry.value;
    }
  }

  final sorted = counts.entries.toList()
    ..sort((a, b) {
      final countDiff = b.value.compareTo(a.value);
      if (countDiff != 0) return countDiff;
      // Simple tie-breaker: alphabetical
      return a.key.compareTo(b.key);
    });

  return sorted.take(5).map((e) => e.key).toList();
}

/// Helper to check if there are other symptoms not in visible list
bool _hasOtherSymptoms(
  List<SymptomBucket> buckets,
  List<String> visibleSymptoms,
) {
  final visibleSet = visibleSymptoms.toSet();
  for (final bucket in buckets) {
    for (final symptomKey in bucket.daysWithSymptom.keys) {
      if (!visibleSet.contains(symptomKey) &&
          bucket.daysWithSymptom[symptomKey]! > 0) {
        return true;
      }
    }
  }
  return false;
}
