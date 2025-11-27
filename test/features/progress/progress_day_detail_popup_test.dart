import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/features/logging/models/daily_summary_cache.dart';
import 'package:hydracat/features/logging/models/fluid_session.dart';
import 'package:hydracat/features/logging/models/medication_session.dart';
import 'package:hydracat/features/logging/services/session_read_service.dart';
import 'package:hydracat/features/onboarding/models/treatment_data.dart';
import 'package:hydracat/features/profile/models/schedule.dart';
import 'package:hydracat/features/profile/models/schedule_history_entry.dart';
import 'package:hydracat/features/progress/widgets/progress_day_detail_popup.dart';
import 'package:hydracat/providers/auth_provider.dart';
import 'package:hydracat/providers/logging_provider.dart';
import 'package:hydracat/providers/profile_provider.dart';
import 'package:hydracat/providers/progress_provider.dart';
import 'package:hydracat/providers/schedule_history_provider.dart';
import 'package:hydracat/shared/models/daily_summary.dart';
import 'package:hydracat/shared/widgets/widgets.dart';

import '../../helpers/widget_test_helpers.dart';

void main() {
  // Test data constants
  final pastDate = DateTime(2025, 10, 10); // Last week
  final futureDate = DateTime(2025, 10, 20); // Next week

  group('ProgressDayDetailPopup - Logged View', () {
    testWidgets('displays medication sessions for past date', (tester) async {
      final medSession = MedicationSession.create(
        petId: 'test-pet-id',
        userId: 'test-user-id',
        dateTime: pastDate.add(const Duration(hours: 8)),
        medicationName: 'Amlodipine',
        dosageGiven: 1,
        dosageScheduled: 1,
        medicationUnit: 'pills',
        completed: true,
      );

      await tester.pumpWidget(
        createTestPopup(
          date: pastDate,
          medicationSessions: [medSession],
        ),
      );
      await tester.pumpAndSettle();

      // Verify medication section header
      expect(find.text('Medications'), findsOneWidget);

      // Verify medication details
      expect(find.text('Amlodipine'), findsOneWidget);
      expect(find.textContaining('pills'), findsOneWidget);

      // Verify completion icon
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('displays fluid sessions for past date', (tester) async {
      final fluidSession = FluidSession.create(
        petId: 'test-pet-id',
        userId: 'test-user-id',
        dateTime: pastDate.add(const Duration(hours: 9)),
        volumeGiven: 150,
        injectionSite: FluidLocation.shoulderBladeLeft,
      );

      await tester.pumpWidget(
        createTestPopup(
          date: pastDate,
          fluidSessions: [fluidSession],
        ),
      );
      await tester.pumpAndSettle();

      // Verify fluid section header
      expect(find.text('Fluid therapy'), findsOneWidget);

      // Verify fluid details
      expect(find.textContaining('ml'), findsOneWidget);

      // Verify water drop icon
      expect(find.byIcon(Icons.water_drop), findsOneWidget);
    });

    testWidgets('displays both medication and fluid sessions', (
      tester,
    ) async {
      final medSession = MedicationSession.create(
        petId: 'test-pet-id',
        userId: 'test-user-id',
        dateTime: pastDate.add(const Duration(hours: 8)),
        medicationName: 'Benazepril',
        dosageGiven: 0.5,
        dosageScheduled: 0.5,
        medicationUnit: 'pills',
        completed: true,
      );

      final fluidSession = FluidSession.create(
        petId: 'test-pet-id',
        userId: 'test-user-id',
        dateTime: pastDate.add(const Duration(hours: 9)),
        volumeGiven: 100,
        injectionSite: FluidLocation.shoulderBladeLeft,
      );

      await tester.pumpWidget(
        createTestPopup(
          date: pastDate,
          medicationSessions: [medSession],
          fluidSessions: [fluidSession],
        ),
      );
      await tester.pumpAndSettle();

      // Verify both sections exist
      expect(find.text('Medications'), findsOneWidget);
      expect(find.text('Fluid therapy'), findsOneWidget);

      // Verify both treatments
      expect(find.text('Benazepril'), findsOneWidget);
      expect(find.textContaining('ml'), findsOneWidget);
    });

    testWidgets('shows missed medication without completion tick', (
      tester,
    ) async {
      final missedSession = MedicationSession.create(
        petId: 'test-pet-id',
        userId: 'test-user-id',
        dateTime: pastDate.add(const Duration(hours: 8)),
        medicationName: 'Missed Med',
        dosageGiven: 0,
        dosageScheduled: 1,
        medicationUnit: 'pills',
        completed: false,
      );

      await tester.pumpWidget(
        createTestPopup(
          date: pastDate,
          medicationSessions: [missedSession],
        ),
      );
      await tester.pumpAndSettle();

      // Should not show completion check for missed medication
      expect(find.byIcon(Icons.check_circle), findsNothing);
      expect(find.text('Missed Med'), findsOneWidget);
    });
  });

  group('ProgressDayDetailPopup - Planned View', () {
    testWidgets('displays planned medications for future date', (
      tester,
    ) async {
      final medSchedule = createTestMedicationSchedule(
        medicationName: 'Future Med',
      );

      await tester.pumpWidget(
        createTestPopup(
          date: futureDate,
          medicationSchedules: [medSchedule],
        ),
      );
      await tester.pumpAndSettle();

      // Verify planned section header
      expect(find.text('Medications'), findsOneWidget);

      // Verify medication details
      expect(find.text('Future Med'), findsOneWidget);
      expect(find.textContaining('pills'), findsOneWidget);
    });

    testWidgets('displays planned fluid therapy for future date', (
      tester,
    ) async {
      final fluidSchedule = createTestFluidSchedule(
        targetVolume: 120,
      );

      await tester.pumpWidget(
        createTestPopup(
          date: futureDate,
          fluidSchedule: fluidSchedule,
        ),
      );
      await tester.pumpAndSettle();

      // Verify planned section header
      expect(find.text('Fluid therapy'), findsOneWidget);

      // Verify fluid details
      expect(find.textContaining('ml'), findsOneWidget);
    });

    testWidgets('displays both planned treatments', (tester) async {
      final medSchedule = createTestMedicationSchedule();
      final fluidSchedule = createTestFluidSchedule();

      await tester.pumpWidget(
        createTestPopup(
          date: futureDate,
          medicationSchedules: [medSchedule],
          fluidSchedule: fluidSchedule,
        ),
      );
      await tester.pumpAndSettle();

      // Verify both planned sections
      expect(find.text('Medications'), findsOneWidget);
      expect(find.text('Fluid therapy'), findsOneWidget);
    });
  });

  group('ProgressDayDetailPopup - Summary Cards', () {
    testWidgets('displays medication summary card with correct counts', (
      tester,
    ) async {
      final medSchedule = createTestMedicationSchedule();
      final medSession = MedicationSession.create(
        petId: 'test-pet-id',
        userId: 'test-user-id',
        dateTime: pastDate.add(const Duration(hours: 8)),
        medicationName: 'Test Med',
        dosageGiven: 1,
        dosageScheduled: 1,
        medicationUnit: 'pills',
        completed: true,
      );

      final summary = DailySummary.empty(pastDate).copyWith(
        medicationTotalDoses: 1,
      );

      await tester.pumpWidget(
        createTestPopup(
          date: pastDate,
          medicationSchedules: [medSchedule],
          medicationSessions: [medSession],
          summaries: {pastDate: summary},
        ),
      );
      await tester.pumpAndSettle();

      // Verify summary card shows "1" and "/ 1 doses" (new layout matches fluid card)
      expect(find.text('1'), findsWidgets); // Appears in h3 style
      expect(find.text('/ 1 doses'), findsOneWidget);
      // Verify goal reached chip appears
      expect(find.text('Goal reached'), findsOneWidget);
      // Verify progress bar is present
      expect(find.byType(HydraProgressIndicator), findsWidgets);
    });

    testWidgets('displays fluid summary card with correct counts', (
      tester,
    ) async {
      final fluidSchedule = createTestFluidSchedule();
      final fluidSession = FluidSession.create(
        petId: 'test-pet-id',
        userId: 'test-user-id',
        dateTime: pastDate.add(const Duration(hours: 9)),
        volumeGiven: 100,
        injectionSite: FluidLocation.shoulderBladeLeft,
      );

      final summary = DailySummary.empty(pastDate).copyWith(
        fluidSessionCount: 1,
        fluidTotalVolume: 100,
      );

      await tester.pumpWidget(
        createTestPopup(
          date: pastDate,
          fluidSchedule: fluidSchedule,
          fluidSessions: [fluidSession],
          summaries: {pastDate: summary},
        ),
      );
      await tester.pumpAndSettle();

      // Verify summary card shows volume
      expect(find.textContaining('100 mL'), findsOneWidget);
      expect(find.textContaining('/ 100 mL'), findsOneWidget);
    });

    testWidgets('shows incomplete status in medication card', (tester) async {
      final medSchedule = createTestMedicationSchedule();
      final summary = DailySummary.empty(pastDate); // All counts at 0

      await tester.pumpWidget(
        createTestPopup(
          date: pastDate,
          medicationSchedules: [medSchedule],
          summaries: {pastDate: summary},
        ),
      );
      await tester.pumpAndSettle();

      // Verify summary shows "0" and "/ 1 doses" (new layout matches fluid card)
      expect(find.text('0'), findsWidgets); // Appears in h3 style
      expect(find.text('/ 1 doses'), findsOneWidget);
      // Verify missed chip appears for past incomplete days
      expect(find.text('Missed'), findsOneWidget);
      // Verify progress bar is present
      expect(find.byType(HydraProgressIndicator), findsWidgets);
    });

    testWidgets(
      'displays both medication and fluid summary cards together',
      (tester) async {
        final medSchedule = createTestMedicationSchedule();
        final fluidSchedule = createTestFluidSchedule();
        final medSession = MedicationSession.create(
          petId: 'test-pet-id',
          userId: 'test-user-id',
          dateTime: pastDate.add(const Duration(hours: 8)),
          medicationName: 'Test Med',
          dosageGiven: 1,
          dosageScheduled: 1,
          medicationUnit: 'pills',
          completed: true,
        );
        final fluidSession = FluidSession.create(
          petId: 'test-pet-id',
          userId: 'test-user-id',
          dateTime: pastDate.add(const Duration(hours: 9)),
          volumeGiven: 100,
          injectionSite: FluidLocation.shoulderBladeLeft,
        );

        final summary = DailySummary.empty(pastDate).copyWith(
          medicationTotalDoses: 1,
          fluidSessionCount: 1,
          fluidTotalVolume: 100,
        );

        await tester.pumpWidget(
          createTestPopup(
            date: pastDate,
            medicationSchedules: [medSchedule],
            medicationSessions: [medSession],
            fluidSchedule: fluidSchedule,
            fluidSessions: [fluidSession],
            summaries: {pastDate: summary},
          ),
        );
        await tester.pumpAndSettle();

        // Verify both summary cards appear
        expect(find.text('1'), findsWidgets); // Medication card h3
        expect(find.text('/ 1 doses'), findsOneWidget);
        expect(find.textContaining('100 mL'), findsOneWidget);
        expect(find.textContaining('/ 100 mL'), findsOneWidget);
        // Verify progress bars are present for both cards
        expect(find.byType(HydraProgressIndicator), findsNWidgets(2));
      },
    );
  });

  group('ProgressDayDetailPopup - Empty States', () {
    testWidgets('shows empty message for past date with no schedules', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestPopup(
          date: pastDate,
          medicationSessions: [],
          fluidSessions: [],
        ),
      );
      await tester.pumpAndSettle();

      // With new planned-with-status view, message is the same as future
      expect(
        find.text('No treatments scheduled for this day'),
        findsOneWidget,
      );
    });

    testWidgets('shows empty message for future date with no schedules', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestPopup(
          date: futureDate,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('No treatments scheduled for this day'),
        findsOneWidget,
      );
    });

    testWidgets('hides summary cards when no schedules exist', (tester) async {
      await tester.pumpWidget(
        createTestPopup(
          date: pastDate,
        ),
      );
      await tester.pumpAndSettle();

      // Should not show any summary cards
      expect(find.textContaining('Medication:'), findsNothing);
      expect(find.textContaining('mL'), findsNothing);
    });
  });

  group('ProgressDayDetailPopup - Accessibility', () {
    testWidgets('has live region semantics', (tester) async {
      await tester.pumpWidget(
        createTestPopup(date: pastDate),
      );
      await tester.pumpAndSettle();

      // Find the Semantics widget with liveRegion
      final semanticsFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics && (widget.properties.liveRegion ?? false),
      );

      expect(semanticsFinder, findsOneWidget);
    });

    testWidgets('has close button with tooltip', (tester) async {
      await tester.pumpWidget(
        createTestPopup(date: pastDate),
      );
      await tester.pumpAndSettle();

      final closeButton = find.byIcon(Icons.close);
      expect(closeButton, findsOneWidget);

      // Verify tooltip exists
      expect(find.byTooltip('Close'), findsOneWidget);
    });

    testWidgets('displays formatted date in header', (tester) async {
      await tester.pumpWidget(
        createTestPopup(date: DateTime(2025, 10, 15)), // Wednesday
      );
      await tester.pumpAndSettle();

      // Verify date format "Weekday, Month Day"
      expect(find.textContaining('Wednesday'), findsOneWidget);
      expect(find.textContaining('October 15'), findsOneWidget);
    });

    testWidgets('close button is tappable', (tester) async {
      await tester.pumpWidget(
        createTestPopup(date: pastDate),
      );
      await tester.pumpAndSettle();

      // Verify popup is visible
      expect(find.byType(ProgressDayDetailPopup), findsOneWidget);

      // Tap close button (should be tappable)
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Note: In a real scenario with OverlayService, the popup would be
      // dismissed. This test verifies the button is tappable.
    });

    testWidgets('close button meets minimum touch target', (tester) async {
      await tester.pumpWidget(
        createTestPopup(date: pastDate),
      );
      await tester.pumpAndSettle();

      // Find the IconButton widget (not just the icon)
      final buttonFinder = find.ancestor(
        of: find.byIcon(Icons.close),
        matching: find.byType(IconButton),
      );
      expect(buttonFinder, findsOneWidget);

      // Get the button's size from its render box
      final renderBox = tester.renderObject(buttonFinder);
      final size = renderBox.paintBounds.size;

      // Verify touch target meets 44px minimum
      // (wrapped in SizedBox with AppSpacing.minTouchTarget = 44px)
      expect(
        size.width,
        greaterThanOrEqualTo(44),
        reason: 'Close button width should be at least 44px',
      );
      expect(
        size.height,
        greaterThanOrEqualTo(44),
        reason: 'Close button height should be at least 44px',
      );
    });
  });
}

/// Helper to create ProgressDayDetailPopup with mocked providers.
Widget createTestPopup({
  required DateTime date,
  List<MedicationSession>? medicationSessions,
  List<FluidSession>? fluidSessions,
  List<Schedule>? medicationSchedules,
  Schedule? fluidSchedule,
  Map<DateTime, DailySummary?>? summaries,
}) {
  return ProviderScope(
    overrides: [
      currentUserProvider.overrideWith((ref) => createTestUser()),
      primaryPetProvider.overrideWith((ref) => createTestPet()),
      medicationSchedulesProvider.overrideWith(
        (ref) => medicationSchedules ?? [],
      ),
      fluidScheduleProvider.overrideWith((ref) => fluidSchedule),
      weekSummariesProvider.overrideWith(
        (ref, weekStart) async => summaries ?? {},
      ),
      sessionReadServiceProvider.overrideWith((ref) {
        return MockSessionReadService(
          medicationSessions: medicationSessions ?? [],
          fluidSessions: fluidSessions ?? [],
        );
      }),
      dailyCacheProvider.overrideWith(
        (ref) => DailySummaryCache.empty('2025-10-15'),
      ),
      scheduleHistoryForDateProvider.overrideWith(
        (ref, date) async => <String, ScheduleHistoryEntry>{},
      ),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: ProgressDayDetailPopup(date: date),
      ),
    ),
  );
}

/// Mock implementation of SessionReadService for testing.
class MockSessionReadService implements SessionReadService {
  /// Creates a mock session read service with predefined session lists.
  MockSessionReadService({
    required this.medicationSessions,
    required this.fluidSessions,
  });

  /// The list of medication sessions to return.
  final List<MedicationSession> medicationSessions;

  /// The list of fluid sessions to return.
  final List<FluidSession> fluidSessions;

  @override
  Future<List<MedicationSession>> getMedicationSessionsForDate({
    required String userId,
    required String petId,
    required DateTime date,
    int limit = 50,
  }) async {
    return medicationSessions;
  }

  @override
  Future<List<FluidSession>> getFluidSessionsForDate({
    required String userId,
    required String petId,
    required DateTime date,
    int limit = 50,
  }) async {
    return fluidSessions;
  }

  @override
  Future<(List<MedicationSession>, List<FluidSession>)> getAllSessionsForDate({
    required String userId,
    required String petId,
    required DateTime date,
    int limit = 50,
  }) async {
    return (medicationSessions, fluidSessions);
  }
}
