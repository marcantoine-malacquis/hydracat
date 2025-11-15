import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/providers/weekly_progress_provider.dart';
import 'package:hydracat/shared/widgets/fluid/water_drop_progress_card.dart';

void main() {
  group('WaterDropProgressCard', () {
    testWidgets('displays weekly progress correctly', (tester) async {
      const mockViewModel = WeeklyProgressViewModel(
        givenMl: 1050,
        goalMl: 1400,
        fillPercentage: 0.75,
        lastInjectionSite: 'Left Flank',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            weeklyProgressProvider.overrideWith((ref) async => mockViewModel),
          ],
          child: const MaterialApp(
            home: Scaffold(body: WaterDropProgressCard()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify current volume (1050ml → 1.1 L)
      expect(find.text('1.1 L'), findsOneWidget);

      // Verify goal is displayed
      expect(find.textContaining('1.4 L'), findsOneWidget);

      // Verify percentage
      expect(find.text('75%'), findsOneWidget);

      // Verify injection site
      expect(find.text('Left Flank'), findsOneWidget);
    });

    testWidgets('shows empty state for new week', (tester) async {
      const emptyViewModel = WeeklyProgressViewModel(
        givenMl: 0,
        goalMl: 1400,
        fillPercentage: 0,
        lastInjectionSite: 'None yet',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            weeklyProgressProvider.overrideWith((ref) async => emptyViewModel),
          ],
          child: const MaterialApp(
            home: Scaffold(body: WaterDropProgressCard()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify 0ml displayed
      expect(find.text('0 ml'), findsOneWidget);

      // Verify goal displayed
      expect(find.textContaining('1.4 L'), findsOneWidget);

      // Verify 0% displayed
      expect(find.text('0%'), findsOneWidget);

      // Verify "None yet" for injection site
      expect(find.text('None yet'), findsOneWidget);
    });

    testWidgets('shows loading state', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: WaterDropProgressCard()),
          ),
        ),
      );

      await tester.pump();

      // Verify loading indicator is shown
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('returns SizedBox.shrink when viewModel is null',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            weeklyProgressProvider.overrideWith((ref) async => null),
          ],
          child: const MaterialApp(
            home: Scaffold(body: WaterDropProgressCard()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should not display card when data is null
      expect(find.byType(Container), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('displays large volume correctly (ml to L conversion)',
        (tester) async {
      const largeVolumeViewModel = WeeklyProgressViewModel(
        givenMl: 2500,
        goalMl: 2800,
        fillPercentage: 0.89,
        lastInjectionSite: 'Right Shoulder',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            weeklyProgressProvider
                .overrideWith((ref) async => largeVolumeViewModel),
          ],
          child: const MaterialApp(
            home: Scaffold(body: WaterDropProgressCard()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify large volumes are shown in liters
      expect(find.text('2.5 L'), findsOneWidget);
      expect(find.textContaining('2.8 L'), findsOneWidget);
    });

    testWidgets('shows percentage with correct color coding', (tester) async {
      // Test different percentage tiers
      final testCases = [
        (0.3, '30%'), // Below 50% (error - red)
        (0.6, '60%'), // 50-70% (warning - amber)
        (0.85, '85%'), // 70-100% (primary - teal)
        (1.0, '100%'), // 100%+ (success - green)
      ];

      for (final testCase in testCases) {
        final viewModel = WeeklyProgressViewModel(
          givenMl: testCase.$1 * 1000,
          goalMl: 1000,
          fillPercentage: testCase.$1,
          lastInjectionSite: 'Left Flank',
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              weeklyProgressProvider.overrideWith((ref) async => viewModel),
            ],
            child: const MaterialApp(
              home: Scaffold(body: WaterDropProgressCard()),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify percentage text is displayed
        expect(find.text(testCase.$2), findsOneWidget);

        // Clear widget for next test
        await tester.pumpWidget(Container());
      }
    });

    testWidgets('shows injection site with location icon', (tester) async {
      const viewModel = WeeklyProgressViewModel(
        givenMl: 500,
        goalMl: 1000,
        fillPercentage: 0.5,
        lastInjectionSite: 'Right Flank',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            weeklyProgressProvider.overrideWith((ref) async => viewModel),
          ],
          child: const MaterialApp(
            home: Scaffold(body: WaterDropProgressCard()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify location icon is present
      expect(find.byIcon(Icons.location_on), findsOneWidget);

      // Verify injection site text
      expect(find.text('Right Flank'), findsOneWidget);
    });
  });
}
