import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hydracat/features/progress/providers/injection_sites_provider.dart';
import 'package:hydracat/features/progress/widgets/calendar_help_popup.dart';
import 'package:hydracat/features/progress/widgets/insights_card.dart';
import 'package:hydracat/features/progress/widgets/progress_day_detail_popup.dart';
import 'package:hydracat/features/progress/widgets/progress_week_calendar.dart';
import 'package:hydracat/providers/auth_provider.dart';
import 'package:hydracat/providers/profile_provider.dart';
import 'package:hydracat/providers/progress_provider.dart';
import 'package:hydracat/shared/widgets/empty_states/onboarding_cta_empty_state.dart';

/// A screen that displays user progress and analytics.
class ProgressScreen extends ConsumerWidget {
  /// Creates a progress screen.
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasCompletedOnboarding = ref.watch(hasCompletedOnboardingProvider);

    return Scaffold(
      appBar: AppBar(
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
      body: hasCompletedOnboarding
          ? RefreshIndicator(
              onRefresh: () async {
                // Invalidate schedule data
                // (may have changed in Profile screen)
                ref
                  ..invalidate(medicationSchedulesProvider)
                  ..invalidate(fluidScheduleProvider)
                  // Invalidate calendar data
                  ..invalidate(weekSummariesProvider)
                  ..invalidate(weekStatusProvider)
                  // Invalidate injection sites data
                  ..invalidate(injectionSitesStatsProvider);

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
                    const SizedBox(height: 32),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Insights',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 16),

                          // Injection sites card
                          InsightsCard(
                            title: 'Injection Sites',
                            subtitle: 'Track rotation patterns',
                            icon: Icons.location_on,
                            onTap: () =>
                                context.push('/progress/injection-sites'),
                          ),

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
            ),
    );
  }
}
