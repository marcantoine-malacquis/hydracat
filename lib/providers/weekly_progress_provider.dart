import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/features/onboarding/models/treatment_data.dart';
import 'package:hydracat/features/profile/models/schedule.dart';
import 'package:hydracat/providers/auth_provider.dart';
import 'package:hydracat/providers/logging_provider.dart';
import 'package:hydracat/providers/profile_provider.dart';

/// View model for weekly progress display
///
/// Composes weekly summary data with pet profile data to provide
/// a complete view of weekly fluid treatment progress.
@immutable
class WeeklyProgressViewModel {
  /// Creates a [WeeklyProgressViewModel] instance
  const WeeklyProgressViewModel({
    required this.givenMl,
    required this.goalMl,
    required this.fillPercentage,
    required this.lastInjectionSite,
  });

  /// Total volume given this week (ml)
  final double givenMl;

  /// Weekly goal volume (ml)
  final int goalMl;

  /// Fill percentage (0.0 to 2.0, allowing for >100% progress)
  final double fillPercentage;

  /// Last injection site used (continuous across weeks)
  /// Shows "None yet" only if no sessions have ever been logged
  final String lastInjectionSite;
}

/// Provider for weekly progress data
///
/// Composes:
/// - Weekly summary (from SummaryService with 15-min cache) - 0-1 reads
/// - Weekly goal (from fluidScheduledVolume in summary) - 0 reads
/// - Last injection site (from pet profile, already cached) - 0 reads
///
/// Automatically invalidates when today's cache changes
/// (after logging session).
///
/// Returns null if:
/// - User or pet is not available
/// - Data fetch fails
final AutoDisposeFutureProvider<WeeklyProgressViewModel?>
    weeklyProgressProvider =
    FutureProvider.autoDispose<WeeklyProgressViewModel?>((ref) async {
  if (kDebugMode) {
    debugPrint('[WeeklyProgressProvider] ===== START =====');
  }

  // Watch for invalidation triggers (refetch after logging)
  ref.watch(dailyCacheProvider);

  final user = ref.read(currentUserProvider);
  final pet = ref.watch(primaryPetProvider);

  if (kDebugMode) {
    debugPrint('[WeeklyProgressProvider] User: ${user?.id ?? "null"}');
    debugPrint('[WeeklyProgressProvider] Pet: ${pet?.id ?? "null"}');
  }

  if (user == null || pet == null) {
    if (kDebugMode) {
      debugPrint(
        '[WeeklyProgressProvider] User or pet not available - returning null',
      );
    }
    return null;
  }

  final summaryService = ref.read(summaryServiceProvider);

  try {
    if (kDebugMode) {
      debugPrint('[WeeklyProgressProvider] Fetching weekly summary...');
      debugPrint('[WeeklyProgressProvider] Date: ${DateTime.now()}');
    }

    // 1. Get weekly summary (cached, 0-1 read)
    final weeklySummary = await summaryService.getWeeklySummary(
      userId: user.id,
      petId: pet.id,
      date: DateTime.now(),
    );

    if (kDebugMode) {
      debugPrint(
        '[WeeklyProgressProvider] Weekly summary: '
        '${weeklySummary != null ? "found" : "null"}',
      );
      if (weeklySummary != null) {
        debugPrint(
          '[WeeklyProgressProvider]   fluidTotalVolume: '
          '${weeklySummary.fluidTotalVolume}',
        );
        debugPrint(
          '[WeeklyProgressProvider]   fluidScheduledVolume: '
          '${weeklySummary.fluidScheduledVolume}',
        );
      }
    }

    final givenMl = weeklySummary?.fluidTotalVolume ?? 0.0;

    // 2. Get weekly goal from summary (0 reads, already in summary)
    // Fallback to calculating from schedule if not yet logged this week
    final fluidSchedule = ref.read(fluidScheduleProvider);

    if (kDebugMode) {
      debugPrint(
        '[WeeklyProgressProvider] Fluid schedule: '
        '${fluidSchedule != null ? "found" : "null"}',
      );
      if (fluidSchedule != null) {
        debugPrint(
          '[WeeklyProgressProvider]   targetVolume: '
          '${fluidSchedule.targetVolume}',
        );
        debugPrint(
          '[WeeklyProgressProvider]   frequency: '
          '${fluidSchedule.frequency}',
        );
      }
    }

    final goalMl = weeklySummary?.fluidScheduledVolume ??
        _calculateWeeklyGoalFromSchedule(fluidSchedule);

    if (kDebugMode) {
      debugPrint('[WeeklyProgressProvider] Goal: $goalMl ml');
    }

    // 3. Get last injection site from pet profile (0 reads, already cached)
    final lastSite = pet.lastFluidInjectionSite;
    final lastInjectionSite =
        lastSite != null ? _formatInjectionSite(lastSite) : 'None yet';

    if (kDebugMode) {
      debugPrint(
        '[WeeklyProgressProvider] Last injection site: $lastInjectionSite',
      );
    }

    // 4. Calculate fill percentage (clamped to 0.0-2.0 for UI)
    final fillPercentage =
        goalMl > 0 ? (givenMl / goalMl).clamp(0.0, 2.0) : 0.0;

    if (kDebugMode) {
      debugPrint(
        '[WeeklyProgressProvider] SUCCESS: ${givenMl.round()}ml / ${goalMl}ml '
        '(${(fillPercentage * 100).round()}%), last site: $lastInjectionSite',
      );
      debugPrint('[WeeklyProgressProvider] ===== END SUCCESS =====');
    }

    return WeeklyProgressViewModel(
      givenMl: givenMl,
      goalMl: goalMl,
      fillPercentage: fillPercentage,
      lastInjectionSite: lastInjectionSite,
    );
  } catch (e, stackTrace) {
    if (kDebugMode) {
      debugPrint('[WeeklyProgressProvider] ===== ERROR =====');
      debugPrint('[WeeklyProgressProvider] Error type: ${e.runtimeType}');
      debugPrint('[WeeklyProgressProvider] Error: $e');
      debugPrint('[WeeklyProgressProvider] Stack trace:');
      debugPrint(stackTrace.toString());
      debugPrint('[WeeklyProgressProvider] ===== END ERROR =====');
    }
    rethrow; // Rethrow to see error in UI
  }
});

/// Calculate weekly goal from fluid schedule (fallback for new weeks)
///
/// Used only when fluidScheduledVolume not yet written to weekly summary
/// (i.e., first home screen load before any sessions logged this week)
int _calculateWeeklyGoalFromSchedule(Schedule? fluidSchedule) {
  if (fluidSchedule == null || fluidSchedule.targetVolume == null) {
    return 0;
  }

  final dailyVolume = fluidSchedule.targetVolume!;
  final frequency = fluidSchedule.frequency;

  switch (frequency) {
    case TreatmentFrequency.onceDaily:
      return (dailyVolume * 7).round();
    case TreatmentFrequency.twiceDaily:
      return (dailyVolume * 2 * 7).round();
    case TreatmentFrequency.thriceDaily:
      return (dailyVolume * 3 * 7).round();
    case TreatmentFrequency.everyOtherDay:
      return (dailyVolume * 3.5).round(); // ~3-4 times per week
    case TreatmentFrequency.every3Days:
      return (dailyVolume * 2.33).round(); // ~2-3 times per week
  }
}

/// Format injection site enum value for display
///
/// Converts values like "left_flank" or "leftFlank" to "Left Flank"
String _formatInjectionSite(String siteValue) {
  // Convert "left_flank" or "leftFlank" to "Left Flank"
  return siteValue
      .replaceAll('_', ' ')
      .split(' ')
      .map((word) => word.isEmpty
          ? ''
          : word[0].toUpperCase() + word.substring(1))
      .join(' ');
}
