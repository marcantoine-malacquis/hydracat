import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hydracat/features/progress/widgets/progress_day_detail_popup.dart';
import 'package:hydracat/features/progress/widgets/progress_week_calendar.dart';
import 'package:hydracat/providers/auth_provider.dart';
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
      ),
      body: hasCompletedOnboarding
          ? Column(
              children: [
                ProgressWeekCalendar(
                  onDaySelected: (day) {
                    showProgressDayDetailPopup(context, day);
                  },
                ),
                const Expanded(
                  child: Center(
                    child: Text('Analytics cards coming soon'),
                  ),
                ),
              ],
            )
          : OnboardingEmptyStates.progress(
              onGetStarted: () => context.go('/onboarding/welcome'),
            ),
    );
  }
}
