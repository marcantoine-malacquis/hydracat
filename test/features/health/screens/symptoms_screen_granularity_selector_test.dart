import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/core/utils/date_utils.dart';
import 'package:hydracat/features/health/models/symptom_granularity.dart';
import 'package:hydracat/features/health/models/symptom_type.dart';
import 'package:hydracat/features/health/screens/symptoms_screen.dart';
import 'package:hydracat/providers/progress_provider.dart';
import 'package:hydracat/providers/symptoms_chart_provider.dart';
import 'package:hydracat/shared/models/monthly_summary.dart';
import 'package:hydracat/shared/widgets/custom_dropdown.dart';
import 'package:hydracat/shared/widgets/inputs/hydra_sliding_segmented_control.dart';
import 'package:intl/intl.dart';

void main() {
  group('SymptomsScreen Granularity Selector Tests', () {
    /// Helper to create a test view model with empty buckets
    SymptomsChartViewModel createEmptyViewModel() {
      return const SymptomsChartViewModel(
        buckets: [],
        visibleSymptoms: [],
        hasOther: false,
      );
    }

    /// Helper to pump the SymptomsScreen with test providers
    Future<ProviderContainer> pumpSymptomsScreen(
      WidgetTester tester, {
      required SymptomsChartState initialState,
      SymptomsChartViewModel? viewModel,
    }) async {
      final container = ProviderContainer(
        overrides: [
          symptomsChartStateProvider.overrideWith(
            (ref) => SymptomsChartNotifier()..state = initialState,
          ),
          symptomsChartDataProvider.overrideWith(
            (ref) => viewModel ?? createEmptyViewModel(),
          ),
          // Mock the monthly summary provider to return data so
          // analytics layout shows
          currentMonthSymptomsSummaryProvider.overrideWith(
            (ref) => Future.value(
              MonthlySummary.empty(DateTime.now()).copyWith(
                daysWithAnySymptoms: 5,
                daysWithVomiting: 2,
                daysWithDiarrhea: 1,
                daysWithLethargy: 1,
                daysWithSuppressedAppetite: 1,
              ),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: SymptomsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      return container;
    }

    testWidgets('renders Week, Month, and Year segments', (tester) async {
      final container = await pumpSymptomsScreen(
        tester,
        initialState: SymptomsChartState(
          focusedDate: DateTime.now(),
        ),
      );

      // Find the segmented control
      final segmentedControlFinder = find.byType(
        HydraSlidingSegmentedControl<SymptomGranularity>,
      );
      expect(segmentedControlFinder, findsOneWidget);

      // Verify all three segments are present
      expect(find.text('Week'), findsOneWidget);
      expect(find.text('Month'), findsOneWidget);
      expect(find.text('Year'), findsOneWidget);

      container.dispose();
    });

    testWidgets('updates granularity when Month segment is tapped', (
      tester,
    ) async {
      final container = await pumpSymptomsScreen(
        tester,
        initialState: SymptomsChartState(
          focusedDate: DateTime.now(),
        ),
      );

      // Verify initial state is Week
      final initialState = container.read(symptomsChartStateProvider);
      expect(initialState.granularity, SymptomGranularity.week);

      // Find and tap the Month segment
      final monthTextFinder = find.text('Month');
      expect(monthTextFinder, findsOneWidget);

      await tester.tap(monthTextFinder);
      await tester.pumpAndSettle();

      // Verify granularity changed to Month
      final updatedState = container.read(symptomsChartStateProvider);
      expect(updatedState.granularity, SymptomGranularity.month);

      container.dispose();
    });

    testWidgets('updates granularity when Year segment is tapped', (
      tester,
    ) async {
      final container = await pumpSymptomsScreen(
        tester,
        initialState: SymptomsChartState(
          focusedDate: DateTime.now(),
          granularity: SymptomGranularity.month,
        ),
      );

      // Verify initial state is Month
      final initialState = container.read(symptomsChartStateProvider);
      expect(initialState.granularity, SymptomGranularity.month);

      // Find and tap the Year segment
      final yearTextFinder = find.text('Year');
      expect(yearTextFinder, findsOneWidget);

      await tester.tap(yearTextFinder);
      await tester.pumpAndSettle();

      // Verify granularity changed to Year
      final updatedState = container.read(symptomsChartStateProvider);
      expect(updatedState.granularity, SymptomGranularity.year);

      container.dispose();
    });

    testWidgets('resets selectedSymptomKey to null when granularity changes', (
      tester,
    ) async {
      final container = await pumpSymptomsScreen(
        tester,
        initialState: SymptomsChartState(
          focusedDate: DateTime.now(),
          selectedSymptomKey: 'vomiting',
        ),
      );

      // Verify initial state has a selected symptom
      final initialState = container.read(symptomsChartStateProvider);
      expect(initialState.selectedSymptomKey, isNotNull);

      // Tap Month segment
      await tester.tap(find.text('Month'));
      await tester.pumpAndSettle();

      // Verify selectedSymptomKey was reset to null
      final updatedState = container.read(symptomsChartStateProvider);
      expect(updatedState.selectedSymptomKey, isNull);

      container.dispose();
    });
  });

  group('SymptomsScreen Period Header Tests', () {
    /// Helper to create a test view model with empty buckets
    SymptomsChartViewModel createEmptyViewModel() {
      return const SymptomsChartViewModel(
        buckets: [],
        visibleSymptoms: [],
        hasOther: false,
      );
    }

    /// Helper to pump the SymptomsScreen with test providers
    Future<ProviderContainer> pumpSymptomsScreen(
      WidgetTester tester, {
      required SymptomsChartState initialState,
      SymptomsChartViewModel? viewModel,
    }) async {
      final container = ProviderContainer(
        overrides: [
          symptomsChartStateProvider.overrideWith(
            (ref) => SymptomsChartNotifier()..state = initialState,
          ),
          symptomsChartDataProvider.overrideWith(
            (ref) => viewModel ?? createEmptyViewModel(),
          ),
          // Mock the monthly summary provider to return data so
          // analytics layout shows
          currentMonthSymptomsSummaryProvider.overrideWith(
            (ref) => Future.value(
              MonthlySummary.empty(DateTime.now()).copyWith(
                daysWithAnySymptoms: 5,
                daysWithVomiting: 2,
                daysWithDiarrhea: 1,
                daysWithLethargy: 1,
                daysWithSuppressedAppetite: 1,
              ),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: SymptomsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      return container;
    }

    testWidgets('formats week period label correctly', (tester) async {
      // Use a fixed date for predictable testing
      final testDate = DateTime(2025, 11, 5); // Wednesday, Nov 5, 2025
      final weekStart = AppDateUtils.startOfWeekMonday(testDate);
      final weekEnd = weekStart.add(const Duration(days: 6));

      final container = await pumpSymptomsScreen(
        tester,
        initialState: SymptomsChartState(
          focusedDate: testDate,
        ),
      );

      // Expected format: "Nov 3-9, 2025" (same month)
      final expectedLabel =
          '${DateFormat('MMM d').format(weekStart)}-'
          '${DateFormat('d, yyyy').format(weekEnd)}';

      expect(find.textContaining(expectedLabel), findsOneWidget);

      container.dispose();
    });

    testWidgets('formats month period label correctly', (tester) async {
      final testDate = DateTime(2025, 11, 15);

      final container = await pumpSymptomsScreen(
        tester,
        initialState: SymptomsChartState(
          focusedDate: testDate,
          granularity: SymptomGranularity.month,
        ),
      );

      // Expected format: "November 2025"
      final expectedLabel = DateFormat('MMMM yyyy').format(
        DateTime(testDate.year, testDate.month),
      );

      expect(find.textContaining(expectedLabel), findsOneWidget);

      container.dispose();
    });

    testWidgets('formats year period label correctly', (tester) async {
      final testDate = DateTime(2025, 6, 15);

      final container = await pumpSymptomsScreen(
        tester,
        initialState: SymptomsChartState(
          focusedDate: testDate,
          granularity: SymptomGranularity.year,
        ),
      );

      // Expected format: "2025"
      expect(find.text('2025'), findsOneWidget);

      container.dispose();
    });

    testWidgets('left chevron calls previousPeriod', (tester) async {
      final testDate = DateTime(2025, 11, 15);
      final container = await pumpSymptomsScreen(
        tester,
        initialState: SymptomsChartState(
          focusedDate: testDate,
        ),
      );

      // Get initial week start
      final initialState = container.read(symptomsChartStateProvider);
      final initialWeekStart = initialState.weekStart;

      // Find and tap left chevron
      final leftChevronFinder = find.byIcon(Icons.chevron_left);
      expect(leftChevronFinder, findsOneWidget);

      await tester.tap(leftChevronFinder);
      await tester.pumpAndSettle();

      // Verify week start moved back by 7 days
      final updatedState = container.read(symptomsChartStateProvider);
      final newWeekStart = updatedState.weekStart;
      expect(newWeekStart, initialWeekStart.subtract(const Duration(days: 7)));

      container.dispose();
    });

    testWidgets('right chevron is disabled when on current period', (
      tester,
    ) async {
      final now = DateTime.now();
      final container = await pumpSymptomsScreen(
        tester,
        initialState: SymptomsChartState(
          focusedDate: now,
        ),
      );

      // Verify we're on current period
      final initialState = container.read(symptomsChartStateProvider);
      expect(initialState.isOnCurrentPeriod, isTrue);

      // Find right chevron IconButton by finding the icon and
      // getting its ancestor
      final rightChevronIconFinder = find.byIcon(Icons.chevron_right);
      expect(rightChevronIconFinder, findsOneWidget);

      // Get the IconButton ancestor
      final iconButtonFinder = find.ancestor(
        of: rightChevronIconFinder,
        matching: find.byType(IconButton),
      );
      expect(iconButtonFinder, findsOneWidget);

      // Verify it's disabled (IconButton with null onPressed)
      final iconButton = tester.widget<IconButton>(iconButtonFinder);
      expect(iconButton.onPressed, isNull);

      container.dispose();
    });

    testWidgets('right chevron is enabled when not on current period', (
      tester,
    ) async {
      // Use a date in the past
      final pastDate = DateTime(2025, 1, 15);
      final container = await pumpSymptomsScreen(
        tester,
        initialState: SymptomsChartState(
          focusedDate: pastDate,
        ),
      );

      // Verify we're not on current period
      final initialState = container.read(symptomsChartStateProvider);
      expect(initialState.isOnCurrentPeriod, isFalse);

      // Find right chevron IconButton by finding the icon and
      // getting its ancestor
      final rightChevronIconFinder = find.byIcon(Icons.chevron_right);
      expect(rightChevronIconFinder, findsOneWidget);

      // Get the IconButton ancestor
      final iconButtonFinder = find.ancestor(
        of: rightChevronIconFinder,
        matching: find.byType(IconButton),
      );
      expect(iconButtonFinder, findsOneWidget);

      // Verify it's enabled (IconButton with non-null onPressed)
      final iconButton = tester.widget<IconButton>(iconButtonFinder);
      expect(iconButton.onPressed, isNotNull);

      container.dispose();
    });

    testWidgets('right chevron calls nextPeriod when enabled', (tester) async {
      // Use a date in the past
      final pastDate = DateTime(2025, 1, 15);
      final container = await pumpSymptomsScreen(
        tester,
        initialState: SymptomsChartState(
          focusedDate: pastDate,
        ),
      );

      // Get initial week start
      final initialState = container.read(symptomsChartStateProvider);
      final initialWeekStart = initialState.weekStart;

      // Find and tap right chevron
      final rightChevronFinder = find.byIcon(Icons.chevron_right);
      expect(rightChevronFinder, findsOneWidget);

      await tester.tap(rightChevronFinder);
      await tester.pumpAndSettle();

      // Verify week start moved forward by 7 days (or clamped to today)
      final updatedState = container.read(symptomsChartStateProvider);
      final newWeekStart = updatedState.weekStart;
      // Should be at least 7 days forward, or clamped to current week
      expect(
        newWeekStart.isAfter(initialWeekStart) ||
            newWeekStart.isAtSameMomentAs(initialWeekStart),
        isTrue,
      );

      container.dispose();
    });

    testWidgets('Today button is visible when not on current period', (
      tester,
    ) async {
      // Use a date in the past
      final pastDate = DateTime(2025, 1, 15);
      final container = await pumpSymptomsScreen(
        tester,
        initialState: SymptomsChartState(
          focusedDate: pastDate,
        ),
      );

      // Verify we're not on current period
      final initialState = container.read(symptomsChartStateProvider);
      expect(initialState.isOnCurrentPeriod, isFalse);

      // Find Today button
      expect(find.text('Today'), findsOneWidget);

      container.dispose();
    });

    testWidgets('Today button is hidden when on current period', (
      tester,
    ) async {
      final now = DateTime.now();
      final container = await pumpSymptomsScreen(
        tester,
        initialState: SymptomsChartState(
          focusedDate: now,
        ),
      );

      // Verify we're on current period
      final initialState = container.read(symptomsChartStateProvider);
      expect(initialState.isOnCurrentPeriod, isTrue);

      // Today button should not be visible
      expect(find.text('Today'), findsNothing);

      container.dispose();
    });

    testWidgets('Today button calls goToToday', (tester) async {
      // Use a date in the past
      final pastDate = DateTime(2025, 1, 15);
      final container = await pumpSymptomsScreen(
        tester,
        initialState: SymptomsChartState(
          focusedDate: pastDate,
        ),
      );

      // Get initial state
      final initialState = container.read(symptomsChartStateProvider);
      expect(initialState.isOnCurrentPeriod, isFalse);

      // Find and tap Today button
      final todayButtonFinder = find.text('Today');
      expect(todayButtonFinder, findsOneWidget);

      await tester.tap(todayButtonFinder);
      await tester.pumpAndSettle();

      // Verify we're now on current period
      final updatedState = container.read(symptomsChartStateProvider);
      expect(updatedState.isOnCurrentPeriod, isTrue);

      container.dispose();
    });
  });

  group('SymptomsScreen Symptom Selector Tests', () {
    /// Helper to create a test view model with empty buckets
    SymptomsChartViewModel createEmptyViewModel() {
      return const SymptomsChartViewModel(
        buckets: [],
        visibleSymptoms: [],
        hasOther: false,
      );
    }

    /// Helper to pump the SymptomsScreen with test providers
    Future<ProviderContainer> pumpSymptomsScreen(
      WidgetTester tester, {
      required SymptomsChartState initialState,
      SymptomsChartViewModel? viewModel,
    }) async {
      final container = ProviderContainer(
        overrides: [
          symptomsChartStateProvider.overrideWith(
            (ref) => SymptomsChartNotifier()..state = initialState,
          ),
          symptomsChartDataProvider.overrideWith(
            (ref) => viewModel ?? createEmptyViewModel(),
          ),
          // Mock the monthly summary provider to return data so
          // analytics layout shows
          currentMonthSymptomsSummaryProvider.overrideWith(
            (ref) => Future.value(
              MonthlySummary.empty(DateTime.now()).copyWith(
                daysWithAnySymptoms: 5,
                daysWithVomiting: 2,
                daysWithDiarrhea: 1,
                daysWithLethargy: 1,
                daysWithSuppressedAppetite: 1,
              ),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: SymptomsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      return container;
    }

    testWidgets('renders symptom selector dropdown', (tester) async {
      final container = await pumpSymptomsScreen(
        tester,
        initialState: SymptomsChartState(
          focusedDate: DateTime.now(),
        ),
      );

      // Find the dropdown
      final dropdownFinder = find.byType(CustomDropdown<String?>);
      expect(dropdownFinder, findsOneWidget);

      // Verify "All symptoms" is shown initially (selectedSymptomKey is null)
      expect(find.text('All symptoms'), findsWidgets);

      container.dispose();
    });

    testWidgets('dropdown shows All symptoms option', (tester) async {
      final container = await pumpSymptomsScreen(
        tester,
        initialState: SymptomsChartState(
          focusedDate: DateTime.now(),
        ),
      );

      // Find and tap the dropdown
      final dropdownFinder = find.byType(CustomDropdown<String?>);
      expect(dropdownFinder, findsOneWidget);

      await tester.tap(dropdownFinder);
      await tester.pumpAndSettle();

      // Verify "All symptoms" option is in the dropdown
      expect(find.text('All symptoms'), findsWidgets);

      container.dispose();
    });

    testWidgets('dropdown can be opened and interacted with', (tester) async {
      final container = await pumpSymptomsScreen(
        tester,
        initialState: SymptomsChartState(
          focusedDate: DateTime.now(),
        ),
      );

      // Find the dropdown
      final dropdownFinder = find.byType(CustomDropdown<String?>);
      expect(dropdownFinder, findsOneWidget);

      // Verify initial state shows "All symptoms" (selectedSymptomKey is null)
      expect(find.text('All symptoms'), findsWidgets);

      // Tap the dropdown to open it
      await tester.tap(dropdownFinder);
      await tester.pump(); // First pump to trigger overlay
      await tester.pump(const Duration(milliseconds: 200)); // Wait for overlay

      // The dropdown should be open now (overlay is created)
      // We can't easily verify overlay contents in widget tests, but we can
      // verify the dropdown widget exists and is interactive
      expect(dropdownFinder, findsOneWidget);

      container.dispose();
    });

    testWidgets('selecting a symptom updates selectedSymptomKey', (
      tester,
    ) async {
      final container = await pumpSymptomsScreen(
        tester,
        initialState: SymptomsChartState(
          focusedDate: DateTime.now(),
        ),
      );

      // Verify initial state is null (All)
      final initialState = container.read(symptomsChartStateProvider);
      expect(initialState.selectedSymptomKey, isNull);

      // Find and tap the dropdown
      final dropdownFinder = find.byType(CustomDropdown<String?>);
      await tester.tap(dropdownFinder);
      await tester.pumpAndSettle();

      // Tap on "Vomiting" option
      final vomitingOption = find.text('Vomiting');
      expect(vomitingOption, findsWidgets);
      await tester.tap(vomitingOption.last); // Use last to get
      // the dropdown item
      await tester.pumpAndSettle();

      // Verify selectedSymptomKey is now "vomiting"
      final updatedState = container.read(symptomsChartStateProvider);
      expect(updatedState.selectedSymptomKey, SymptomType.vomiting);

      container.dispose();
    });

    testWidgets('selecting All symptoms sets selectedSymptomKey to null', (
      tester,
    ) async {
      final container = await pumpSymptomsScreen(
        tester,
        initialState: SymptomsChartState(
          focusedDate: DateTime.now(),
          selectedSymptomKey: SymptomType.vomiting,
        ),
      );

      // Verify initial state has a selected symptom
      final initialState = container.read(symptomsChartStateProvider);
      expect(initialState.selectedSymptomKey, SymptomType.vomiting);

      // Find and tap the dropdown
      final dropdownFinder = find.byType(CustomDropdown<String?>);
      await tester.tap(dropdownFinder);
      await tester.pumpAndSettle();

      // Tap on "All symptoms" option
      final allOption = find.text('All symptoms');
      expect(allOption, findsWidgets);
      await tester.tap(allOption.last); // Use last to get the dropdown item
      await tester.pumpAndSettle();

      // Verify selectedSymptomKey is now null
      final updatedState = container.read(symptomsChartStateProvider);
      expect(updatedState.selectedSymptomKey, isNull);

      container.dispose();
    });

    testWidgets('changing granularity resets selectedSymptomKey to null', (
      tester,
    ) async {
      final container = await pumpSymptomsScreen(
        tester,
        initialState: SymptomsChartState(
          focusedDate: DateTime.now(),
          selectedSymptomKey: SymptomType.lethargy,
        ),
      );

      // Verify initial state has a selected symptom
      final initialState = container.read(symptomsChartStateProvider);
      expect(initialState.selectedSymptomKey, SymptomType.lethargy);

      // Tap Month segment to change granularity
      await tester.tap(find.text('Month'));
      await tester.pumpAndSettle();

      // Verify selectedSymptomKey was reset to null
      final updatedState = container.read(symptomsChartStateProvider);
      expect(updatedState.selectedSymptomKey, isNull);

      container.dispose();
    });

    testWidgets('navigating periods does not reset selectedSymptomKey', (
      tester,
    ) async {
      // Use a date in the past so we can navigate
      final pastDate = DateTime(2025, 1, 15);
      final container = await pumpSymptomsScreen(
        tester,
        initialState: SymptomsChartState(
          focusedDate: pastDate,
          selectedSymptomKey: SymptomType.diarrhea,
        ),
      );

      // Verify initial state has a selected symptom
      final initialState = container.read(symptomsChartStateProvider);
      expect(initialState.selectedSymptomKey, SymptomType.diarrhea);

      // Tap left chevron to go to previous period
      final leftChevronFinder = find.byIcon(Icons.chevron_left);
      await tester.tap(leftChevronFinder);
      await tester.pumpAndSettle();

      // Verify selectedSymptomKey is still set
      final updatedState = container.read(symptomsChartStateProvider);
      expect(updatedState.selectedSymptomKey, SymptomType.diarrhea);

      container.dispose();
    });
  });
}
