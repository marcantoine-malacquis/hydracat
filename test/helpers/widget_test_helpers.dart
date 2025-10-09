/// Test helpers for widget testing
///
/// Provides mock notifiers, provider overrides, and helper functions for
/// pumping widgets with test data.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/features/auth/models/app_user.dart';
import 'package:hydracat/features/logging/models/daily_summary_cache.dart';
import 'package:hydracat/features/logging/models/fluid_session.dart';
import 'package:hydracat/features/logging/models/logging_state.dart';
import 'package:hydracat/features/logging/models/medication_session.dart';
import 'package:hydracat/features/logging/models/treatment_choice.dart';
import 'package:hydracat/features/logging/screens/fluid_logging_screen.dart';
import 'package:hydracat/features/logging/screens/medication_logging_screen.dart';
import 'package:hydracat/features/logging/widgets/treatment_choice_popup.dart';
import 'package:hydracat/features/onboarding/models/treatment_data.dart';
import 'package:hydracat/features/profile/models/cat_profile.dart';
import 'package:hydracat/features/profile/models/schedule.dart';
import 'package:hydracat/features/profile/models/user_persona.dart';
import 'package:hydracat/providers/analytics_provider.dart';
import 'package:hydracat/providers/auth_provider.dart';
import 'package:hydracat/providers/connectivity_provider.dart';
import 'package:hydracat/providers/logging_provider.dart';
import 'package:hydracat/providers/profile_provider.dart';
import 'package:mocktail/mocktail.dart';

// ============================================
// Mock Notifier Classes
// ============================================

/// Mock LoggingNotifier for testing
class MockLoggingNotifier extends StateNotifier<LoggingState>
    with Mock
    implements LoggingNotifier {
  /// Creates a MockLoggingNotifier with default initial state
  MockLoggingNotifier() : super(const LoggingState.initial());
}

/// Mock AnalyticsService for testing
class MockAnalyticsService extends Mock implements AnalyticsService {}

// ============================================
// Default Test Data
// ============================================

/// Creates a default test user
AppUser createTestUser({
  String id = 'test-user-id',
  String email = 'test@example.com',
  String displayName = 'Test User',
}) {
  return AppUser(
    id: id,
    email: email,
    displayName: displayName,
    hasCompletedOnboarding: true,
    primaryPetId: 'test-pet-id',
  );
}

/// Creates a default test pet profile
CatProfile createTestPet({
  String id = 'test-pet-id',
  String userId = 'test-user-id',
  String name = 'Whiskers',
  UserPersona treatmentApproach = UserPersona.medicationAndFluidTherapy,
}) {
  return CatProfile(
    id: id,
    userId: userId,
    name: name,
    ageYears: 8,
    treatmentApproach: treatmentApproach,
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
  );
}

/// Creates a default test medication schedule
Schedule createTestMedicationSchedule({
  String id = 'test-med-schedule-id',
  String medicationName = 'Amlodipine',
  double targetDosage = 1.0,
  String medicationUnit = 'pills',
  String? medicationStrengthAmount = '2.5',
  String? medicationStrengthUnit = 'mg',
}) {
  final now = DateTime.now();
  return Schedule(
    id: id,
    treatmentType: TreatmentType.medication,
    frequency: TreatmentFrequency.onceDaily,
    isActive: true,
    reminderTimes: [DateTime(now.year, now.month, now.day, 8)],
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
    medicationName: medicationName,
    targetDosage: targetDosage,
    medicationUnit: medicationUnit,
    medicationStrengthAmount: medicationStrengthAmount,
    medicationStrengthUnit: medicationStrengthUnit,
  );
}

/// Creates a default test fluid schedule
Schedule createTestFluidSchedule({
  String id = 'test-fluid-schedule-id',
  double targetVolume = 100.0,
  FluidLocation preferredLocation = FluidLocation.shoulderBladeLeft,
}) {
  final now = DateTime.now();
  return Schedule(
    id: id,
    treatmentType: TreatmentType.fluid,
    frequency: TreatmentFrequency.onceDaily,
    isActive: true,
    reminderTimes: [DateTime(now.year, now.month, now.day, 9)],
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
    targetVolume: targetVolume,
    preferredLocation: preferredLocation,
  );
}

/// Creates a default test daily summary cache
DailySummaryCache createTestDailyCache({
  String? date,
  int medicationSessionCount = 0,
  int fluidSessionCount = 0,
  List<String>? medicationNames,
  double totalMedicationDosesGiven = 0.0,
  double totalFluidVolumeGiven = 0.0,
}) {
  final now = DateTime.now();
  final cacheDate =
      date ??
      '${now.year}-'
          '${now.month.toString().padLeft(2, '0')}-'
          '${now.day.toString().padLeft(2, '0')}';

  return DailySummaryCache(
    date: cacheDate,
    medicationSessionCount: medicationSessionCount,
    fluidSessionCount: fluidSessionCount,
    medicationNames: medicationNames ?? [],
    totalMedicationDosesGiven: totalMedicationDosesGiven,
    totalFluidVolumeGiven: totalFluidVolumeGiven,
  );
}

// ============================================
// Provider Override Helpers
// ============================================

/// Creates a ProviderScope with test data for widget testing
///
/// All parameters are optional. If not provided, default test data is used.
///
/// Example:
/// ```dart
/// await tester.pumpWidget(
///   createTestProviderScope(
///     child: MaterialApp(home: MedicationLoggingScreen()),
///     currentUser: createTestUser(),
///     medicationSchedules: [createTestMedicationSchedule()],
///   ),
/// );
/// ```
ProviderScope createTestProviderScope({
  required Widget child,
  LoggingState? loggingState,
  AppUser? currentUser,
  CatProfile? primaryPet,
  List<Schedule>? medicationSchedules,
  Schedule? fluidSchedule,
  DailySummaryCache? dailyCache,
  bool isConnected = true,
  MockLoggingNotifier? mockLoggingNotifier,
  MockAnalyticsService? mockAnalyticsService,
}) {
  // Create default test data if not provided
  final user = currentUser ?? createTestUser();
  final pet = primaryPet ?? createTestPet();
  final cache = dailyCache ?? createTestDailyCache();

  // Create mock notifier if not provided
  final loggingNotifier = mockLoggingNotifier ?? MockLoggingNotifier();

  // Set initial state if provided
  if (loggingState != null) {
    loggingNotifier.state = loggingState;
  }

  // Create mock analytics service if not provided
  final analyticsService = mockAnalyticsService ?? MockAnalyticsService();

  // Default analytics service behavior (no-op)
  when(
    () => analyticsService.trackFeatureUsed(
      featureName: any(named: 'featureName'),
    ),
  ).thenAnswer(
    (_) async {},
  );
  when(
    () => analyticsService.trackTreatmentChoiceSelected(
      choice: any(named: 'choice'),
    ),
  ).thenAnswer((_) async {});
  when(
    () => analyticsService.trackSessionLogged(
      treatmentType: any(named: 'treatmentType'),
      sessionCount: any(named: 'sessionCount'),
      isQuickLog: any(named: 'isQuickLog'),
      adherenceStatus: any(named: 'adherenceStatus'),
      medicationName: any(named: 'medicationName'),
      volumeGiven: any(named: 'volumeGiven'),
    ),
  ).thenAnswer((_) async {});

  return ProviderScope(
    overrides: [
      // Auth provider - provide authenticated user
      currentUserProvider.overrideWith((ref) => user),

      // Profile provider - provide pet and schedules
      primaryPetProvider.overrideWith((ref) => pet),
      todaysMedicationSchedulesProvider.overrideWith(
        (ref) => medicationSchedules ?? [],
      ),
      todaysFluidScheduleProvider.overrideWith((ref) => fluidSchedule),

      // Logging provider - provide state and cache
      loggingProvider.overrideWith((ref) => loggingNotifier),
      dailyCacheProvider.overrideWith((ref) => cache),
      isLoggingProvider.overrideWith((ref) => loggingNotifier.state.isLoading),
      loggingErrorProvider.overrideWith((ref) => loggingNotifier.state.error),

      // Connectivity provider
      isConnectedProvider.overrideWith((ref) => isConnected),

      // Analytics provider
      analyticsServiceDirectProvider.overrideWith((ref) => analyticsService),
    ],
    child: child,
  );
}

// ============================================
// Pump Helper Functions
// ============================================

/// Pumps MedicationLoggingScreen with test data
///
/// Example:
/// ```dart
/// await pumpMedicationLoggingScreen(
///   tester,
///   medicationSchedules: [
///     createTestMedicationSchedule(medicationName: 'Amlodipine'),
///     createTestMedicationSchedule(medicationName: 'Benazepril'),
///   ],
/// );
/// ```
Future<void> pumpMedicationLoggingScreen(
  WidgetTester tester, {
  LoggingState? loggingState,
  AppUser? currentUser,
  CatProfile? primaryPet,
  List<Schedule>? medicationSchedules,
  DailySummaryCache? dailyCache,
  MockLoggingNotifier? mockLoggingNotifier,
  MockAnalyticsService? mockAnalyticsService,
}) async {
  await tester.pumpWidget(
    createTestProviderScope(
      child: const MaterialApp(
        home: MedicationLoggingScreen(),
      ),
      loggingState: loggingState,
      currentUser: currentUser,
      primaryPet: primaryPet,
      medicationSchedules: medicationSchedules,
      dailyCache: dailyCache,
      mockLoggingNotifier: mockLoggingNotifier,
      mockAnalyticsService: mockAnalyticsService,
    ),
  );
}

/// Pumps FluidLoggingScreen with test data
///
/// Example:
/// ```dart
/// await pumpFluidLoggingScreen(
///   tester,
///   fluidSchedule: createTestFluidSchedule(targetVolume: 150),
/// );
/// ```
Future<void> pumpFluidLoggingScreen(
  WidgetTester tester, {
  LoggingState? loggingState,
  AppUser? currentUser,
  CatProfile? primaryPet,
  Schedule? fluidSchedule,
  DailySummaryCache? dailyCache,
  MockLoggingNotifier? mockLoggingNotifier,
  MockAnalyticsService? mockAnalyticsService,
}) async {
  await tester.pumpWidget(
    createTestProviderScope(
      child: const MaterialApp(
        home: FluidLoggingScreen(),
      ),
      loggingState: loggingState,
      currentUser: currentUser,
      primaryPet: primaryPet,
      fluidSchedule: fluidSchedule,
      dailyCache: dailyCache,
      mockLoggingNotifier: mockLoggingNotifier,
      mockAnalyticsService: mockAnalyticsService,
    ),
  );
}

/// Pumps TreatmentChoicePopup with test data and callbacks
///
/// Example:
/// ```dart
/// var medicationSelected = false;
/// await pumpTreatmentChoicePopup(
///   tester,
///   onMedicationSelected: () => medicationSelected = true,
///   onFluidSelected: () {},
/// );
/// ```
Future<void> pumpTreatmentChoicePopup(
  WidgetTester tester, {
  required VoidCallback onMedicationSelected,
  required VoidCallback onFluidSelected,
  MockLoggingNotifier? mockLoggingNotifier,
  MockAnalyticsService? mockAnalyticsService,
}) async {
  await tester.pumpWidget(
    createTestProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: TreatmentChoicePopup(
            onMedicationSelected: onMedicationSelected,
            onFluidSelected: onFluidSelected,
          ),
        ),
      ),
      mockLoggingNotifier: mockLoggingNotifier,
      mockAnalyticsService: mockAnalyticsService,
    ),
  );
}

// ============================================
// Mock Setup Helpers
// ============================================

/// Sets up default mock behavior for LoggingNotifier
///
/// By default, all operations return success (true).
void setupDefaultLoggingNotifierMocks(MockLoggingNotifier mockNotifier) {
  // logMedicationSession returns success
  when(
    () => mockNotifier.logMedicationSession(
      session: any(named: 'session'),
      todaysSchedules: any(named: 'todaysSchedules'),
    ),
  ).thenAnswer((_) async => true);

  // logFluidSession returns success
  when(
    () => mockNotifier.logFluidSession(
      session: any(named: 'session'),
    ),
  ).thenAnswer((_) async => true);

  // reset method
  when(() => mockNotifier.reset()).thenReturn(null);

  // setTreatmentChoice method
  when(() => mockNotifier.setTreatmentChoice(any())).thenReturn(null);
}

/// Registers fallback values for mocktail matchers
void registerFallbackValues() {
  // Register MedicationSession fallback
  registerFallbackValue(
    MedicationSession.create(
      petId: 'test-pet-id',
      userId: 'test-user-id',
      dateTime: DateTime.now(),
      medicationName: 'Test Med',
      dosageGiven: 1,
      dosageScheduled: 1,
      medicationUnit: 'pills',
      completed: true,
    ),
  );

  // Register FluidSession fallback
  registerFallbackValue(
    FluidSession.create(
      petId: 'test-pet-id',
      userId: 'test-user-id',
      dateTime: DateTime.now(),
      volumeGiven: 100,
    ),
  );

  // Register TreatmentChoice fallback
  registerFallbackValue(TreatmentChoice.medication);

  // Register List<Schedule> fallback
  registerFallbackValue(<Schedule>[]);
}
