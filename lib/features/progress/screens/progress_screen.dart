import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hydracat/core/constants/app_icons.dart';
import 'package:hydracat/core/icons/icon_provider.dart';
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
import 'package:table_calendar/table_calendar.dart';

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
    WidgetRef ref, {
    required bool hasCompletedOnboarding,
  }) {
    return _ProgressScreenContent.buildBody(
      context,
      ref,
      hasCompletedOnboarding: hasCompletedOnboarding,
    );
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

    final body = ProgressScreen.buildBody(
      context,
      ref,
      hasCompletedOnboarding: hasCompletedOnboarding,
    );

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

    // Build segmented control for bottom of app bar
    final formatBar = hasCompletedOnboarding
        ? _buildFormatBar(context, ref)
        : null;

    // Build actions with help and calendar icons
    final platform = Theme.of(context).platform;
    final isCupertino =
        platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;
    final actions = hasCompletedOnboarding
        ? [
            IconButton(
              icon: Icon(
                IconProvider.resolveIconData(
                  AppIcons.help,
                  isCupertino: isCupertino,
                ),
              ),
              onPressed: () => showCalendarHelpPopup(context),
              tooltip: 'Calendar help',
            ),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: 'Jump to date',
              icon: Icon(
                IconProvider.resolveIconData(
                  AppIcons.calendar,
                  isCupertino: isCupertino,
                ),
                size: 24,
              ),
              onPressed: () async {
                final theme = Theme.of(context);
                final focused = ref.read(focusedDayProvider);
                final picked = await HydraDatePicker.show(
                  context: context,
                  initialDate: focused,
                  firstDate: DateTime(2010),
                  lastDate: DateTime.now(),
                  builder: (context, child) => Theme(
                    data: theme.copyWith(colorScheme: theme.colorScheme),
                    child: child!,
                  ),
                );
                if (picked != null && mounted) {
                  ref.read(focusedDayProvider.notifier).state = picked;
                }
              },
            ),
          ]
        : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: HydraAppBar(
        title: const Text('Progress & Analytics'),
        style: HydraAppBarStyle.accent,
        actions: actions,
        bottom: formatBar,
        bottomHeight: 44,
      ),
      body: body,
    );
  }

  /// Builds the format bar with Week/Month toggle.
  ///
  /// The segmented control is centered, with icons handled in app bar actions.
  Widget _buildFormatBar(BuildContext context, WidgetRef ref) {
    final format = ref.watch(calendarFormatProvider);

    return Center(
      child: HydraSlidingSegmentedControl<CalendarFormat>(
        value: format,
        segments: const {
          CalendarFormat.week: Text('Week'),
          CalendarFormat.month: Text('Month'),
        },
        onChanged: (CalendarFormat newFormat) {
          HapticFeedback.selectionClick();
          ref.read(calendarFormatProvider.notifier).state = newFormat;
        },
      ),
    );
  }
}

/// Internal helper class for ProgressScreen body content.
class _ProgressScreenContent {
  static Widget buildBody(
    BuildContext context,
    WidgetRef ref, {
    required bool hasCompletedOnboarding,
  }) {
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
                        Builder(
                          builder: (context) {
                            final platform = Theme.of(context).platform;
                            final isCupertino =
                                platform == TargetPlatform.iOS ||
                                platform == TargetPlatform.macOS;
                            return NavigationCard(
                              title: 'Injection Sites',
                              icon: IconProvider.resolveIconData(
                                AppIcons.locationOn,
                                isCupertino: isCupertino,
                              ),
                              showBackgroundCircle: false,
                              onTap: () =>
                                  context.push('/progress/injection-sites'),
                              margin: EdgeInsets.zero,
                            );
                          },
                        ),

                        const SizedBox(height: 12),

                        // Weight tracking card
                        const _WeightCard(),

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
class _WeightCard extends StatelessWidget {
  const _WeightCard();

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;
    final isCupertino =
        platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;
    final customIconAsset = IconProvider.getPlatformSpecificIconAsset(
      AppIcons.scale,
      isCupertino: isCupertino,
    );
    return NavigationCard(
      title: 'Weight',
      icon: customIconAsset == null
          ? IconProvider.resolveIconData(
              AppIcons.scale,
              isCupertino: isCupertino,
            )
          : null,
      customIconAsset: customIconAsset,
      showBackgroundCircle: false,
      onTap: () => context.push('/progress/weight'),
      margin: EdgeInsets.zero,
    );
  }
}

/// Symptoms tracking card widget
class _SymptomsCard extends StatelessWidget {
  const _SymptomsCard();

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;
    final isCupertino =
        platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;
    return NavigationCard(
      title: 'Symptoms',
      icon: IconProvider.resolveIconData(
        AppIcons.symptoms,
        isCupertino: isCupertino,
      ),
      showBackgroundCircle: false,
      onTap: () => context.push('/progress/symptoms'),
      margin: EdgeInsets.zero,
    );
  }
}
