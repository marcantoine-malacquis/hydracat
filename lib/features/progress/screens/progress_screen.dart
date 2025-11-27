import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hydracat/core/theme/theme.dart';
import 'package:hydracat/features/progress/providers/injection_sites_provider.dart';
import 'package:hydracat/features/progress/widgets/calendar_help_popup.dart';
import 'package:hydracat/features/progress/widgets/progress_day_detail_popup.dart';
import 'package:hydracat/features/progress/widgets/progress_week_calendar.dart';
import 'package:hydracat/providers/auth_provider.dart';
import 'package:hydracat/providers/calendar_help_provider.dart';
import 'package:hydracat/providers/logging_provider.dart';
import 'package:hydracat/providers/profile_provider.dart';
import 'package:hydracat/providers/progress_provider.dart';
import 'package:hydracat/shared/models/daily_summary.dart';
import 'package:hydracat/shared/widgets/empty_states/onboarding_cta_empty_state.dart';
import 'package:hydracat/shared/widgets/widgets.dart';

/// A screen that displays user progress and analytics.
class ProgressScreen extends ConsumerStatefulWidget {
  /// Creates a progress screen.
  ///
  /// If [bodyOnly] is true, returns only the body content without Scaffold.
  const ProgressScreen({super.key, this.bodyOnly = false});

  /// If true, returns only the body content without Scaffold.
  final bool bodyOnly;

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();

  /// Builds the body content for the progress screen.
  /// This static method can be used by AppShell to get body-only content.
  static Widget buildBody(
    BuildContext context,
    WidgetRef ref,
    bool hasCompletedOnboarding,
  ) {
    return _ProgressScreenContent.buildBody(context, ref, hasCompletedOnboarding);
  }
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  @override
  void initState() {
    super.initState();
    // Auto-show calendar help popup logic needs to be handled in AppShell
    // or moved to a separate lifecycle handler
  }

  @override
  Widget build(BuildContext context) {
    final hasCompletedOnboarding = ref.watch(hasCompletedOnboardingProvider);

    final body = ProgressScreen.buildBody(context, ref, hasCompletedOnboarding);

    if (widget.bodyOnly) {
      return body;
    }

    // Auto-show calendar help popup on first data load
    final hasSeenHelp = ref.watch(calendarHelpSeenProvider);
    if (hasCompletedOnboarding && !hasSeenHelp) {
      final weekStart = ref.watch(focusedWeekStartProvider);

      ref.listen<AsyncValue<Map<DateTime, DailySummary?>>>(
        weekSummariesProvider(weekStart),
        (prev, next) {
          if (!mounted) return;

          final alreadySeen = ref.read(calendarHelpSeenProvider);
          if (alreadySeen) return;

          final hasAnySummary = next.maybeWhen(
            data: (map) => map.values.any((s) => s != null),
            orElse: () => false,
          );

          if (hasAnySummary) {
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              if (!mounted) return;
              showCalendarHelpPopup(context);
              await ref.read(calendarHelpSeenProvider.notifier).markSeen();
            });
          }
        },
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: HydraAppBar(
        title: const Text('Progress & Analytics'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: hasCompletedOnboarding
            ? [
                IconButton(
                  icon: const Icon(Icons.help_outline),
                  onPressed: () => showCalendarHelpPopup(context),
                  tooltip: 'Calendar help',
                ),
              ]
            : null,
      ),
      body: body,
    );
  }
}

/// Internal helper class for ProgressScreen body content.
class _ProgressScreenContent {
  static Widget buildBody(
    BuildContext context,
    WidgetRef ref,
    bool hasCompletedOnboarding,
  ) {
    return hasCompletedOnboarding
          ? HydraRefreshIndicator(
              onRefresh: () async {
                // Clear monthly cache for current month to force fresh read
                final user = ref.read(currentUserProvider);
                final pet = ref.read(primaryPetProvider);
                if (user != null && pet != null) {
                  ref
                      .read(summaryServiceProvider)
                      .clearMonthlyCacheForMonth(
                        userId: user.id,
                        petId: pet.id,
                        date: DateTime.now(),
                      );
                }

                // Invalidate schedule data
                // (may have changed in Profile screen)
                ref
                  ..invalidate(medicationSchedulesProvider)
                  ..invalidate(fluidScheduleProvider)
                  // Invalidate calendar data
                  ..invalidate(weekSummariesProvider)
                  ..invalidate(weekStatusProvider)
                  // Invalidate injection sites data
                  ..invalidate(injectionSitesStatsProvider)
                  // Invalidate symptoms summary
                  ..invalidate(currentMonthSymptomsSummaryProvider);

                // Brief delay to allow providers to rebuild
                await Future<void>.delayed(
                  const Duration(milliseconds: 500),
                );
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Calendar
                    ProgressWeekCalendar(
                      onDaySelected: (day) {
                        showProgressDayDetailPopup(context, day);
                      },
                    ),

                    // Insights section
                    const SizedBox(height: 28),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Insights',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 12),

                          // Injection sites card
                          NavigationCard(
                            title: 'Injection Sites',
                            metadata: 'Track rotation patterns',
                            icon: Icons.location_on,
                            onTap: () =>
                                context.push('/progress/injection-sites'),
                            margin: EdgeInsets.zero,
                          ),

                          const SizedBox(height: 12),

                          // Weight tracking card
                          _WeightCard(),

                          const SizedBox(height: 12),

                          // Symptoms tracking card
                          const _SymptomsCard(),

                          // Future insights cards will be added here
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            )
          : OnboardingEmptyStates.progress(
              onGetStarted: () => context.go('/onboarding/welcome'),
            );
  }
}

/// Weight tracking card widget
///
/// Displays a NavigationCard for weight tracking with pet name in metadata.
class _WeightCard extends ConsumerWidget {
  const _WeightCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petName = ref.watch(petNameProvider);
    return NavigationCard(
      title: 'Weight',
      metadata: petName != null
          ? "Track $petName's weight"
          : "Track your cat's weight",
      icon: Icons.monitor_weight,
      onTap: () => context.push('/progress/weight'),
      margin: EdgeInsets.zero,
    );
  }
}

/// Symptoms tracking card widget
///
/// Displays a NavigationCard for symptoms tracking with metadata showing
/// the number of days with symptoms this month.
class _SymptomsCard extends ConsumerWidget {
  const _SymptomsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthlySummaryAsync = ref.watch(currentMonthSymptomsSummaryProvider);

    final metadata = monthlySummaryAsync.maybeWhen(
      data: (summary) {
        if (kDebugMode) {
          final summaryStr = summary == null
              ? 'null'
              : 'days=${summary.daysWithAnySymptoms}';
          debugPrint('[SymptomsCard] summary=$summaryStr');
        }
        if (summary == null) {
          return 'No symptoms logged yet this month';
        }
        final days = summary.daysWithAnySymptoms;
        if (days == 0) {
          return 'No symptoms logged yet this month';
        }
        return 'This month: $days ${days == 1 ? 'day' : 'days'} with symptoms';
      },
      loading: () => 'Loading symptom data…',
      error: (_, _) => 'No symptoms logged yet this month',
      orElse: () => 'No symptoms logged yet this month',
    );

    return NavigationCard(
      title: 'Symptoms',
      metadata: metadata,
      icon: Icons.medical_services,
      onTap: () => context.push('/progress/symptoms'),
      margin: EdgeInsets.zero,
    );
  }
}
