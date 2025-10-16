import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/core/utils/date_utils.dart';
import 'package:hydracat/features/auth/models/app_user.dart';
import 'package:hydracat/features/profile/models/cat_profile.dart';
import 'package:hydracat/providers/auth_provider.dart';
import 'package:hydracat/providers/profile_provider.dart';
import 'package:hydracat/providers/progress_provider.dart';
import 'package:hydracat/shared/models/daily_summary.dart';
import 'package:hydracat/shared/models/fluid_daily_summary_view.dart';

import '../../helpers/widget_test_helpers.dart';

void main() {
  test(
    'fluidDailySummaryViewProvider derives from week summaries and schedule',
    () async {
      final today = AppDateUtils.startOfDay(DateTime.now());
      final weekStart = AppDateUtils.startOfWeekMonday(today);

      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWithValue(const AppUser(id: 'u1')),
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
          // Provide week summaries with a fluid volume for today
          weekSummariesProvider.overrideWithProvider((start) {
            return FutureProvider.autoDispose<Map<DateTime, DailySummary?>>((
              ref,
            ) async {
              expect(start, weekStart);
              return {
                today: DailySummary.empty(today).copyWith(
                  fluidTotalVolume: 120,
                  fluidSessionCount: 1,
                ),
              };
            });
          }),
          // Provide a fluid schedule: 1 reminder today at 9:00, 100ml target
          fluidScheduleProvider.overrideWith((ref) {
            return createTestFluidSchedule(
              id: 'fs1',
            );
          }),
        ],
      );

      // Because mocking Schedule directly is heavy, we simply assert that
      // provider does not crash and returns a view based on summaries map.
      final view = container.read(fluidDailySummaryViewProvider(today));

      expect(view, isA<FluidDailySummaryView?>());
      expect(view!.givenMl, 120);
      expect(view.goalMl, 100); // 1 reminder × 100ml
    },
  );
}
