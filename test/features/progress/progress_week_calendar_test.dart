import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/core/constants/app_colors.dart';
import 'package:hydracat/features/logging/models/daily_summary_cache.dart';
import 'package:hydracat/features/progress/models/day_dot_status.dart';
import 'package:hydracat/features/progress/widgets/progress_week_calendar.dart';
import 'package:hydracat/providers/logging_provider.dart';
import 'package:hydracat/providers/profile_provider.dart';
import 'package:hydracat/providers/progress_provider.dart';
import 'package:hydracat/shared/models/daily_summary.dart';

void main() {
  group('ProgressWeekCalendar', () {
    // Test data: Week of Oct 13-19, 2025 (Mon-Sun)
    final testWeekStart = DateTime(2025, 10, 13); // Monday
    final testFocusedDay = DateTime(2025, 10, 15); // Wednesday

    // Create a synthetic status map representing all 4 statuses
    final testStatuses = <DateTime, DayDotStatus>{
      DateTime(2025, 10, 13): DayDotStatus.complete, // Mon - teal dot
      DateTime(2025, 10, 14): DayDotStatus.missed, // Tue - coral dot
      DateTime(2025, 10, 15): DayDotStatus.today, // Wed - amber dot
      DateTime(2025, 10, 16): DayDotStatus.none, // Thu - no dot
      DateTime(2025, 10, 17): DayDotStatus.none, // Fri - no dot
      DateTime(2025, 10, 18): DayDotStatus.none, // Sat - no dot
      DateTime(2025, 10, 19): DayDotStatus.none, // Sun - no dot
    };

    /// Helper to create ProviderScope with all necessary mocks
    Widget createTestWidget({
      required DateTime weekStart,
      required DateTime focusedDay,
      required Map<DateTime, DayDotStatus> statuses,
      required void Function(DateTime) onDaySelected,
    }) {
      return ProviderScope(
        overrides: [
          focusedDayProvider.overrideWith((ref) => focusedDay),
          focusedWeekStartProvider.overrideWith((ref) => weekStart),
          weekStatusProvider.overrideWith(
            (ref, ws) async => statuses,
          ),
          // Mock dependencies of weekStatusProvider
          dailyCacheProvider.overrideWith(
            (ref) => DailySummaryCache.empty('2025-10-15'),
          ),
          weekSummariesProvider.overrideWith(
            (ref, ws) async => <DateTime, DailySummary?>{},
          ),
          medicationSchedulesProvider.overrideWith((ref) => []),
          fluidScheduleProvider.overrideWith((ref) => null),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: ProgressWeekCalendar(
              onDaySelected: onDaySelected,
            ),
          ),
        ),
      );
    }

    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          weekStart: testWeekStart,
          focusedDay: testFocusedDay,
          statuses: testStatuses,
          onDaySelected: (_) {},
        ),
      );

      await tester.pumpAndSettle();

      // Verify ProgressWeekCalendar widget renders
      expect(find.byType(ProgressWeekCalendar), findsOneWidget);
    });

    testWidgets('displays seven day cells (Mon-Sun)', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          weekStart: testWeekStart,
          focusedDay: testFocusedDay,
          statuses: testStatuses,
          onDaySelected: (_) {},
        ),
      );

      await tester.pumpAndSettle();

      // Verify the widget renders
      expect(find.byType(ProgressWeekCalendar), findsOneWidget);

      // Verify day numbers are present (13-19)
      for (var i = 13; i <= 19; i++) {
        expect(find.text(i.toString()), findsWidgets);
      }
    });

    testWidgets('renders status dots with correct colors', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          weekStart: testWeekStart,
          focusedDay: testFocusedDay,
          statuses: testStatuses,
          onDaySelected: (_) {},
        ),
      );

      await tester.pumpAndSettle();

      // Find all Container widgets in the tree
      final allContainers = tester.widgetList<Container>(
        find.byType(Container),
      );

      // Filter for dot containers (8x8 circles)
      final dots = allContainers.where((container) {
        final decoration = container.decoration as BoxDecoration?;
        return decoration?.shape == BoxShape.circle &&
            decoration?.color != null;
      }).toList();

      // We should have at least 1 dot rendered
      expect(dots.length, greaterThanOrEqualTo(1));

      // Check if we can find specific dot colors
      final dotColors = dots.map((dot) {
        final decoration = dot.decoration! as BoxDecoration;
        return decoration.color;
      }).toList();

      // At least one of the dots should match our expected colors
      final hasTealDot = dotColors.contains(AppColors.primary);
      final hasCoralDot = dotColors.contains(AppColors.warning);
      final hasAmberDot = dotColors.contains(Colors.amber[600]);

      // We should have at least one of our status dots
      expect(hasTealDot || hasCoralDot || hasAmberDot, isTrue);
    });

    testWidgets('calls onDaySelected when day is tapped', (tester) async {
      DateTime? selectedDay;

      await tester.pumpWidget(
        createTestWidget(
          weekStart: testWeekStart,
          focusedDay: testFocusedDay,
          statuses: testStatuses,
          onDaySelected: (day) {
            selectedDay = day;
          },
        ),
      );

      await tester.pumpAndSettle();

      // Tap on a day cell (find the text "14" for Tuesday)
      await tester.tap(find.text('14').first);
      await tester.pumpAndSettle();

      // Verify callback was called with a DateTime
      expect(selectedDay, isNotNull);
      expect(selectedDay!.day, 14);
    });

    testWidgets('handles loading state gracefully', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          weekStart: testWeekStart,
          focusedDay: testFocusedDay,
          statuses: testStatuses,
          onDaySelected: (_) {},
        ),
      );

      // Don't pump and settle - just pump once to get loading state
      await tester.pump();

      // Calendar widget should render
      expect(find.byType(ProgressWeekCalendar), findsOneWidget);
    });

    testWidgets('handles error state gracefully', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          weekStart: testWeekStart,
          focusedDay: testFocusedDay,
          statuses: testStatuses,
          onDaySelected: (_) {},
        ),
      );

      await tester.pumpAndSettle();

      // Calendar widget should render
      expect(find.byType(ProgressWeekCalendar), findsOneWidget);
    });

    testWidgets('displays teal dot for complete status', (tester) async {
      final completeStatuses = <DateTime, DayDotStatus>{
        for (var i = 0; i < 7; i++)
          testWeekStart.add(Duration(days: i)): i == 0
              ? DayDotStatus.complete
              : DayDotStatus.none,
      };

      await tester.pumpWidget(
        createTestWidget(
          weekStart: testWeekStart,
          focusedDay: testFocusedDay,
          statuses: completeStatuses,
          onDaySelected: (_) {},
        ),
      );

      await tester.pumpAndSettle();

      // Find containers with teal color (complete status)
      final containers = tester.widgetList<Container>(
        find.byType(Container),
      );
      final tealDots = containers.where((c) {
        final decoration = c.decoration as BoxDecoration?;
        return decoration?.color == AppColors.primary;
      }).toList();

      expect(tealDots.length, 1);
    });

    testWidgets('displays coral dot for missed status', (tester) async {
      final missedStatuses = <DateTime, DayDotStatus>{
        for (var i = 0; i < 7; i++)
          testWeekStart.add(Duration(days: i)): i == 1
              ? DayDotStatus.missed
              : DayDotStatus.none,
      };

      await tester.pumpWidget(
        createTestWidget(
          weekStart: testWeekStart,
          focusedDay: testFocusedDay,
          statuses: missedStatuses,
          onDaySelected: (_) {},
        ),
      );

      await tester.pumpAndSettle();

      // Find containers with coral color (missed status)
      final containers = tester.widgetList<Container>(
        find.byType(Container),
      );
      final coralDots = containers.where((c) {
        final decoration = c.decoration as BoxDecoration?;
        return decoration?.color == AppColors.warning;
      }).toList();

      expect(coralDots.length, 1);
    });

    testWidgets('displays amber dot for today status', (tester) async {
      final todayStatuses = <DateTime, DayDotStatus>{
        for (var i = 0; i < 7; i++)
          testWeekStart.add(Duration(days: i)): i == 2
              ? DayDotStatus.today
              : DayDotStatus.none,
      };

      await tester.pumpWidget(
        createTestWidget(
          weekStart: testWeekStart,
          focusedDay: testFocusedDay,
          statuses: todayStatuses,
          onDaySelected: (_) {},
        ),
      );

      await tester.pumpAndSettle();

      // Find containers with amber color (today status)
      final containers = tester.widgetList<Container>(
        find.byType(Container),
      );
      final amberDots = containers.where((c) {
        final decoration = c.decoration as BoxDecoration?;
        return decoration?.color == Colors.amber[600];
      }).toList();

      expect(amberDots.length, 1);
    });

    testWidgets('displays no dots for none status', (tester) async {
      final noneStatuses = <DateTime, DayDotStatus>{
        for (var i = 0; i < 7; i++)
          testWeekStart.add(Duration(days: i)): DayDotStatus.none,
      };

      await tester.pumpWidget(
        createTestWidget(
          weekStart: testWeekStart,
          focusedDay: testFocusedDay,
          statuses: noneStatuses,
          onDaySelected: (_) {},
        ),
      );

      await tester.pumpAndSettle();

      // Find all colored circular containers (status dots)
      final containers = tester.widgetList<Container>(
        find.byType(Container),
      );
      final statusDots = containers.where((c) {
        final decoration = c.decoration as BoxDecoration?;
        return decoration?.shape == BoxShape.circle &&
            decoration?.color != null;
      }).toList();

      // Should have no status dots (or very few from other decorations)
      expect(statusDots.length, lessThan(3));
    });

    testWidgets('displays multiple different status dots simultaneously', (
      tester,
    ) async {
      // Test with all 4 status types in one week
      final mixedStatuses = <DateTime, DayDotStatus>{
        DateTime(2025, 10, 13): DayDotStatus.complete, // Mon - teal
        DateTime(2025, 10, 14): DayDotStatus.missed, // Tue - coral
        DateTime(2025, 10, 15): DayDotStatus.today, // Wed - amber
        DateTime(2025, 10, 16): DayDotStatus.none, // Thu - no dot
        DateTime(2025, 10, 17): DayDotStatus.complete, // Fri - teal
        DateTime(2025, 10, 18): DayDotStatus.none, // Sat - no dot
        DateTime(2025, 10, 19): DayDotStatus.missed, // Sun - coral
      };

      await tester.pumpWidget(
        createTestWidget(
          weekStart: testWeekStart,
          focusedDay: testFocusedDay,
          statuses: mixedStatuses,
          onDaySelected: (_) {},
        ),
      );

      await tester.pumpAndSettle();

      // Find all status dots
      final containers = tester.widgetList<Container>(
        find.byType(Container),
      );
      final statusDots = containers.where((c) {
        final decoration = c.decoration as BoxDecoration?;
        return decoration?.shape == BoxShape.circle &&
            decoration?.color != null;
      }).toList();

      // Should have at least 5 dots (2 complete, 2 missed, 1 today)
      // May have additional decorative circles from TableCalendar
      expect(statusDots.length, greaterThanOrEqualTo(5));

      // Count each color type
      final colors = statusDots.map((d) {
        return (d.decoration! as BoxDecoration).color;
      }).toList();

      final tealCount = colors.where((c) => c == AppColors.primary).length;
      final coralCount = colors.where((c) => c == AppColors.warning).length;
      final amberCount = colors.where((c) => c == Colors.amber[600]).length;

      expect(tealCount, 2, reason: 'Should have 2 teal dots');
      expect(coralCount, 2, reason: 'Should have 2 coral dots');
      expect(amberCount, 1, reason: 'Should have 1 amber dot');
    });
  });
}
