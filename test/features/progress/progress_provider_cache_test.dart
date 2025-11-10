import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/core/utils/date_utils.dart';
import 'package:hydracat/features/auth/models/app_user.dart';
import 'package:hydracat/features/logging/services/summary_service.dart';
import 'package:hydracat/features/profile/models/cat_profile.dart';
import 'package:hydracat/providers/auth_provider.dart';
import 'package:hydracat/providers/logging_provider.dart';
import 'package:hydracat/providers/profile_provider.dart';
import 'package:hydracat/providers/progress_provider.dart';
import 'package:hydracat/shared/models/daily_summary.dart';

/// Verifies weekSummariesProvider reflects today's cache immediately.
void main() {
  test(
    'weekSummariesProvider overrides today using cache/lightweight summary',
    () async {
      final container = ProviderContainer(
        overrides: [
          // Provide dummy user and pet
          currentUserProvider.overrideWithValue(
            const AppUser(id: 'u1'),
          ),
          primaryPetProvider.overrideWithValue(
            CatProfile(
              id: 'p1',
              userId: 'u1',
              name: 'Milo',
              ageYears: 5,
              createdAt: DateTime(2025),
              updatedAt: DateTime(2025),
            ),
          ),
          // Stub SummaryService: return null for history, lightweight for today
          summaryServiceProvider.overrideWithValue(_FakeSummaryService()),
        ],
      );

      final weekStart = AppDateUtils.startOfWeekMonday(DateTime.now());
      final map = await container.read(weekSummariesProvider(weekStart).future);

      final today = AppDateUtils.startOfDay(DateTime.now());
      expect(map[today], isNotNull, reason: 'today summary should exist');
      expect(map[today]!.overallTreatmentDone, true);
    },
  );
}

class _FakeSummaryService implements SummaryService {
  @override
  Future<DailySummary?> getDailySummary({
    required String userId,
    required String petId,
    required DateTime date,
  }) async {
    // Simulate no Firestore data for history
    return null;
  }

  @override
  Future<DailySummary?> getTodaySummary({
    required String userId,
    required String petId,
    bool lightweight = false,
  }) async {
    final today = AppDateUtils.startOfDay(DateTime.now());
    return DailySummary(
      date: today,
      overallStreak: 0,
      medicationTotalDoses: 1,
      medicationScheduledDoses: 1,
      medicationMissedCount: 0,
      fluidTotalVolume: 0,
      fluidTreatmentDone: false,
      fluidScheduledSessions: 0,
      fluidSessionCount: 0,
      overallTreatmentDone: true,
      createdAt: today,
    );
  }

  // Unused in this test
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
