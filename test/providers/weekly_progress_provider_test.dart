import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/features/auth/models/app_user.dart';
import 'package:hydracat/features/auth/models/auth_state.dart';
import 'package:hydracat/features/auth/services/auth_service.dart';
import 'package:hydracat/features/logging/services/summary_service.dart';
import 'package:hydracat/features/profile/models/cat_profile.dart';
import 'package:hydracat/features/profile/services/pet_service.dart';
import 'package:hydracat/features/profile/services/schedule_service.dart';
import 'package:hydracat/providers/auth_provider.dart';
import 'package:hydracat/providers/logging_provider.dart';
import 'package:hydracat/providers/profile_provider.dart';
import 'package:hydracat/providers/weekly_progress_provider.dart';
import 'package:hydracat/shared/models/weekly_summary.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/widget_test_helpers.dart';

/// Mock services
class MockAuthService extends Mock implements AuthService {}

class MockPetService extends Mock implements PetService {}

class MockScheduleService extends Mock implements ScheduleService {}

class MockSharedPreferences extends Mock implements SharedPreferences {}

/// Simple mock notifiers for testing
class SimpleAuthNotifier extends AuthNotifier {
  SimpleAuthNotifier(super.authService, AuthState initialState) {
    state = initialState;
  }
}

class SimpleProfileNotifier extends ProfileNotifier {
  SimpleProfileNotifier(
    super.petService,
    super.scheduleService,
    super.ref,
    ProfileState initialState,
  ) {
    state = initialState;
  }
}

void main() {
  group('WeeklyProgressProvider', () {
    late AppUser testUser;
    late CatProfile testPet;
    late MockAuthService mockAuthService;
    late MockPetService mockPetService;
    late MockScheduleService mockScheduleService;
    late MockSharedPreferences mockSharedPreferences;

    setUp(() {
      testUser = createTestUser();
      testPet = createTestPet();
      mockAuthService = MockAuthService();
      mockPetService = MockPetService();
      mockScheduleService = MockScheduleService();
      mockSharedPreferences = MockSharedPreferences();

      // Default auth service stubs
      when(() => mockAuthService.waitForInitialization())
          .thenAnswer((_) async {});
      when(() => mockAuthService.authStateChanges)
          .thenAnswer((_) => const Stream.empty());
      when(() => mockAuthService.currentUser).thenReturn(null);

      // Default shared preferences stubs
      when(() => mockSharedPreferences.getString(any()))
          .thenReturn(null);
      when(() => mockSharedPreferences.setString(any(), any()))
          .thenAnswer((_) async => true);
    });

    test('returns null when user is not authenticated', () async {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(mockSharedPreferences),
          authProvider.overrideWith(
            (ref) => SimpleAuthNotifier(
              mockAuthService,
              const AuthStateUnauthenticated(),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(weeklyProgressProvider.future);

      expect(result, isNull);
    });

    test('returns null when primary pet is null', () async {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(mockSharedPreferences),
          authProvider.overrideWith(
            (ref) => SimpleAuthNotifier(
              mockAuthService,
              AuthStateAuthenticated(user: testUser),
            ),
          ),
          profileProvider.overrideWith(
            (ref) => SimpleProfileNotifier(
              mockPetService,
              mockScheduleService,
              ref,
              const ProfileState(),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(weeklyProgressProvider.future);

      expect(result, isNull);
    });

    test('correctly calculates fill percentage', () async {
      final weeklySummary = WeeklySummary(
        fluidTotalVolume: 700,
        fluidScheduledVolume: 1400,
        fluidTreatmentDays: 3,
        fluidMissedDays: 2,
        medicationAvgAdherence: 0,
        overallTreatmentDays: 3,
        overallMissedDays: 2,
        medicationTotalDoses: 0,
        medicationScheduledDoses: 0,
        medicationMissedCount: 0,
        fluidTreatmentDone: false,
        fluidSessionCount: 3,
        fluidScheduledSessions: 7,
        overallTreatmentDone: false,
        createdAt: DateTime(2025),
        startDate: DateTime(2025, 1, 13),
        endDate: DateTime(2025, 1, 19),
      );

      final fakeSummaryService = _FakeSummaryService(weeklySummary);

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(mockSharedPreferences),
          authProvider.overrideWith(
            (ref) => SimpleAuthNotifier(
              mockAuthService,
              AuthStateAuthenticated(user: testUser),
            ),
          ),
          profileProvider.overrideWith(
            (ref) => SimpleProfileNotifier(
              mockPetService,
              mockScheduleService,
              ref,
              ProfileState(primaryPet: testPet),
            ),
          ),
          summaryServiceProvider.overrideWithValue(fakeSummaryService),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(weeklyProgressProvider.future);

      expect(result, isNotNull);
      expect(result!.givenMl, equals(700));
      expect(result.goalMl, equals(1400));
      expect(result.fillPercentage, closeTo(0.5, 0.01));
    });

    test('shows "None yet" when no injection site logged', () async {
      final weeklySummary = WeeklySummary.empty(DateTime.now());

      final petWithoutSite = testPet.copyWith(
        lastFluidInjectionSite: null,
      );

      final fakeSummaryService = _FakeSummaryService(weeklySummary);

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(mockSharedPreferences),
          authProvider.overrideWith(
            (ref) => SimpleAuthNotifier(
              mockAuthService,
              AuthStateAuthenticated(user: testUser),
            ),
          ),
          profileProvider.overrideWith(
            (ref) => SimpleProfileNotifier(
              mockPetService,
              mockScheduleService,
              ref,
              ProfileState(primaryPet: petWithoutSite),
            ),
          ),
          summaryServiceProvider.overrideWithValue(fakeSummaryService),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(weeklyProgressProvider.future);

      expect(result, isNotNull);
      expect(result!.lastInjectionSite, equals('None yet'));
    });

    test('falls back to schedule calculation when goal not stored', () async {
      final weeklySummary = WeeklySummary.empty(DateTime.now());

      final fluidSchedule = createTestFluidSchedule(targetVolume: 200);

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(mockSharedPreferences),
          authProvider.overrideWith(
            (ref) => SimpleAuthNotifier(
              mockAuthService,
              AuthStateAuthenticated(user: testUser),
            ),
          ),
          profileProvider.overrideWith(
            (ref) => SimpleProfileNotifier(
              mockPetService,
              mockScheduleService,
              ref,
              ProfileState(
                primaryPet: testPet,
                fluidSchedule: fluidSchedule,
              ),
            ),
          ),
          summaryServiceProvider.overrideWithValue(
            _FakeSummaryService(weeklySummary),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(weeklyProgressProvider.future);

      expect(result, isNotNull);
      expect(result!.goalMl, equals(1400)); // 200ml * 7 days
    });

    test('formats injection site correctly', () async {
      final weeklySummary = WeeklySummary.empty(DateTime.now());

      final petWithSite = testPet.copyWith(
        lastFluidInjectionSite: 'leftFlank',
      );

      final fakeSummaryService = _FakeSummaryService(weeklySummary);

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(mockSharedPreferences),
          authProvider.overrideWith(
            (ref) => SimpleAuthNotifier(
              mockAuthService,
              AuthStateAuthenticated(user: testUser),
            ),
          ),
          profileProvider.overrideWith(
            (ref) => SimpleProfileNotifier(
              mockPetService,
              mockScheduleService,
              ref,
              ProfileState(primaryPet: petWithSite),
            ),
          ),
          summaryServiceProvider.overrideWithValue(fakeSummaryService),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(weeklyProgressProvider.future);

      expect(result, isNotNull);
      expect(result!.lastInjectionSite, equals('Left Flank'));
    });

    test('handles error states gracefully', () async {
      final fakeSummaryService = _FakeSummaryService(null, throwError: true);

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(mockSharedPreferences),
          authProvider.overrideWith(
            (ref) => SimpleAuthNotifier(
              mockAuthService,
              AuthStateAuthenticated(user: testUser),
            ),
          ),
          profileProvider.overrideWith(
            (ref) => SimpleProfileNotifier(
              mockPetService,
              mockScheduleService,
              ref,
              ProfileState(primaryPet: testPet),
            ),
          ),
          summaryServiceProvider.overrideWithValue(fakeSummaryService),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(weeklyProgressProvider.future);

      expect(result, isNull);
    });
  });
}

/// Fake implementation of SummaryService for testing
class _FakeSummaryService implements SummaryService {
  _FakeSummaryService(this._weeklySummary, {this.throwError = false});

  final WeeklySummary? _weeklySummary;
  final bool throwError;

  @override
  Future<WeeklySummary?> getWeeklySummary({
    required String userId,
    required String petId,
    required DateTime date,
  }) async {
    if (throwError) {
      throw Exception('Test error');
    }
    return _weeklySummary;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
