import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hydracat/app/app_shell.dart';
import 'package:hydracat/features/auth/models/app_user.dart';
import 'package:hydracat/features/auth/models/auth_state.dart';
import 'package:hydracat/features/auth/screens/email_verification_screen.dart';
import 'package:hydracat/features/auth/screens/forgot_password_screen.dart';
import 'package:hydracat/features/auth/screens/login_screen.dart';
import 'package:hydracat/features/auth/screens/register_screen.dart';
import 'package:hydracat/features/health/screens/symptoms_screen.dart';
import 'package:hydracat/features/health/screens/weight_screen.dart';
import 'package:hydracat/features/home/screens/component_demo_screen.dart';
import 'package:hydracat/features/home/screens/home_screen.dart';
import 'package:hydracat/features/inventory/screens/inventory_screen.dart';
import 'package:hydracat/features/learn/screens/discover_screen.dart';
import 'package:hydracat/features/onboarding/debug_onboarding_replay.dart';
import 'package:hydracat/features/onboarding/screens/ckd_medical_info_screen.dart';
import 'package:hydracat/features/onboarding/screens/onboarding_completion_screen.dart';
import 'package:hydracat/features/onboarding/screens/pet_basics_screen.dart';
import 'package:hydracat/features/onboarding/screens/welcome_screen.dart';
import 'package:hydracat/features/profile/screens/ckd_profile_screen.dart';
import 'package:hydracat/features/profile/screens/create_fluid_schedule_screen.dart';
import 'package:hydracat/features/profile/screens/fluid_schedule_screen.dart';
import 'package:hydracat/features/profile/screens/medication_schedule_screen.dart';
import 'package:hydracat/features/profile/screens/profile_screen.dart';
import 'package:hydracat/features/progress/screens/injection_sites_analytics_screen.dart';
import 'package:hydracat/features/progress/screens/progress_screen.dart';
import 'package:hydracat/features/qol/screens/qol_detail_screen.dart';
import 'package:hydracat/features/qol/screens/qol_history_screen.dart';
import 'package:hydracat/features/qol/screens/qol_questionnaire_screen.dart';
import 'package:hydracat/features/settings/screens/notification_settings_screen.dart';
import 'package:hydracat/features/settings/screens/settings_screen.dart';
import 'package:hydracat/providers/auth_provider.dart';
import 'package:hydracat/shared/widgets/layout/layout.dart';
import 'package:hydracat/shared/widgets/navigation/app_page_transitions.dart';

/// Listenable that triggers GoRouter refreshes from multiple sources
class GoRouterRefreshStream extends ChangeNotifier {
  /// Creates a [GoRouterRefreshStream] instance
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<dynamic> _subscription;

  /// Manually trigger a refresh (useful for Riverpod state changes)
  void refresh() {
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// Provider for the router refresh stream
final routerRefreshStreamProvider = Provider<GoRouterRefreshStream>((ref) {
  final authService = ref.read(authServiceProvider);
  final refreshStream = GoRouterRefreshStream(authService.authStateChanges);

  // Listen to Riverpod state changes and trigger refresh
  // without rebuilding router
  ref
    ..listen<AuthState>(authProvider, (previous, next) {
      refreshStream.refresh();
    })
    ..listen<bool>(hasCompletedOnboardingProvider, (previous, next) {
      refreshStream.refresh();
    })
    ..listen<bool>(hasSkippedOnboardingProvider, (previous, next) {
      refreshStream.refresh();
    })
    ..listen<AppUser?>(currentUserProvider, (previous, next) {
      refreshStream.refresh();
    })
    ..listen<bool>(debugOnboardingReplayProvider, (previous, next) {
      refreshStream.refresh();
    })
    ..onDispose(refreshStream.dispose);
  return refreshStream;
});

/// Provider for the app router with authentication logic
final appRouterProvider = Provider<GoRouter>((ref) {
  // Get the refresh stream (stable instance - don't watch to avoid rebuilds)
  final refreshStream = ref.read(routerRefreshStreamProvider);

  return GoRouter(
    initialLocation: '/',
    // Ensure redirects are re-evaluated when auth state changes
    refreshListenable: refreshStream,
    redirect: (context, state) async {
      // Read latest values inside redirect
      // (not watch in provider to avoid rebuilds)
      final authState = ref.read(authProvider);
      final hasCompletedOnboarding = ref.read(hasCompletedOnboardingProvider);
      final hasSkippedOnboarding = ref.read(hasSkippedOnboardingProvider);
      final currentUser = ref.read(currentUserProvider);
      final isDebugReplay = ref.read(debugOnboardingReplayProvider);

      // Don't redirect while auth is still loading/initializing
      if (authState is AuthStateLoading) {
        if (kDebugMode) {
          debugPrint('[Router] Auth still loading, no redirect');
        }
        return null;
      }

      final isAuthenticated = authState is AuthStateAuthenticated;
      final isError = authState is AuthStateError;
      final currentLocation = state.matchedLocation;

      if (kDebugMode) {
        debugPrint(
          '[Router] Evaluating redirect: '
          'location=$currentLocation, '
          'isAuth=$isAuthenticated, '
          'isError=$isError, '
          'hasOnboarding=$hasCompletedOnboarding, '
          'hasSkipped=$hasSkippedOnboarding',
        );
      }

      // Define page types for cleaner logic
      final isOnAuthPage = [
        '/login',
        '/register',
        '/forgot-password',
      ].contains(currentLocation);
      final isOnVerificationPage = currentLocation.startsWith(
        '/email-verification',
      );
      final isOnOnboardingPage = currentLocation.startsWith('/onboarding');

      // Allow staying on auth pages when there's an error
      // This ensures error messages can be displayed without redirecting away
      if (isError && isOnAuthPage) {
        if (kDebugMode) {
          debugPrint('[Router] Error state on auth page, allowing to stay');
        }
        return null;
      }

      // 1. Authentication check - redirect unauthenticated users to login
      if (!isAuthenticated && !isOnAuthPage && !isOnVerificationPage) {
        if (kDebugMode) {
          debugPrint('[Router] Redirecting unauthenticated user to login');
        }
        return '/login';
      }

      // 2. For authenticated users, check email verification
      if (isAuthenticated && !isOnVerificationPage) {
        if (currentUser != null && !currentUser.emailVerified) {
          // User is authenticated but email not verified
          if (!isOnAuthPage) {
            return '/email-verification?email=${currentUser.email ?? ''}';
          }
        }
      }

      // 3. Onboarding flow logic for authenticated & verified users
      if (isAuthenticated) {
        final isEmailVerified = currentUser?.emailVerified ?? false;

        // Only apply onboarding logic if email is verified
        if (isEmailVerified) {
          // Check if debug replay mode is active
          if (isDebugReplay && kDebugMode) {
            // In replay mode: allow navigation to onboarding even if completed
            if (kDebugMode) {
              debugPrint(
                '[Router] Debug replay mode active - allowing onboarding '
                'navigation',
              );
            }
            // Don't redirect away from onboarding pages in replay mode
          } else {
            // Normal mode: apply standard onboarding redirect logic
            // Users who completed onboarding should not be in onboarding flow
            if (hasCompletedOnboarding && isOnOnboardingPage) {
              if (kDebugMode) {
                debugPrint(
                  '[Router] Redirecting completed user away from onboarding '
                  'to home',
                );
              }
              return '/';
            }

            // Users who haven't completed AND haven't skipped onboarding
            // should be redirected to onboarding (unless already there)
            if (!hasCompletedOnboarding &&
                !hasSkippedOnboarding &&
                !isOnOnboardingPage &&
                !isOnAuthPage) {
              if (kDebugMode) {
                debugPrint('[Router] Redirecting fresh user to onboarding');
              }
              // Resume onboarding from appropriate step
              // For now, start from welcome - could be enhanced to resume
              // from last step
              return '/onboarding/welcome';
            }
          }

          // Users who skipped onboarding can access main app but with
          // limited functionality - individual screens will
          //handle content gating
        }
      }

      // 4. Redirect authenticated users away from auth pages
      if (isAuthenticated && isOnAuthPage) {
        return '/';
      }

      // No redirect needed
      if (kDebugMode) {
        debugPrint('[Router] No redirect needed, staying at $currentLocation');
      }
      return null;
    },
    routes: [
      // ShellRoute wraps all tab navigation routes
      // Uses builder (not pageBuilder) so nested routes
      // can have their own transitions
      // Tab switching is handled by TabFadeSwitcher in AppShell
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          // Tab root routes: Use NoTransitionPage
          // (tab fade handled by AppShell)
          GoRoute(
            path: '/',
            name: 'home',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(),
            ),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfileScreen(),
            ),
          ),
          GoRoute(
            path: '/discover',
            name: 'discover',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DiscoverScreen(),
            ),
          ),
          GoRoute(
            path: '/progress',
            name: 'progress',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProgressScreen(),
            ),
          ),
          GoRoute(
            path: '/resources',
            name: 'resources',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DiscoverScreen(),
            ),
          ),
          GoRoute(
            path: '/demo',
            name: 'demo',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ComponentDemoScreen(),
            ),
          ),
          // Settings routes - inside ShellRoute to show bottom nav bar
          // Use bidirectional slide transitions and manage their own Scaffold
          GoRoute(
            path: '/profile/settings',
            name: 'profile-settings',
            pageBuilder: (context, state) =>
                AppPageTransitions.bidirectionalSlide(
              child: const SettingsScreen(),
              key: state.pageKey,
            ),
            routes: [
              GoRoute(
                path: 'notifications',
                name: 'notification-settings',
                pageBuilder: (context, state) =>
                    AppPageTransitions.bidirectionalSlide(
                      child: const NotificationSettingsScreen(),
                      key: state.pageKey,
                    ),
              ),
            ],
          ),
          // QoL routes - inside ShellRoute to show bottom nav bar
          // Use bidirectional slide transitions and manage their own Scaffold
          GoRoute(
            path: '/profile/qol',
            name: 'profile-qol',
            pageBuilder: (context, state) =>
                AppPageTransitions.bidirectionalSlide(
                  child: const QolHistoryScreen(),
                  key: state.pageKey,
                ),
            routes: [
              GoRoute(
                path: 'new',
                name: 'profile-qol-new',
                pageBuilder: (context, state) =>
                    AppPageTransitions.bidirectionalSlide(
                      child: const QolQuestionnaireScreen(),
                      key: state.pageKey,
                    ),
              ),
              GoRoute(
                path: 'edit/:assessmentId',
                name: 'profile-qol-edit',
                pageBuilder: (context, state) {
                  final assessmentId = state.pathParameters['assessmentId']!;
                  return AppPageTransitions.bidirectionalSlide(
                    child: QolQuestionnaireScreen(assessmentId: assessmentId),
                    key: state.pageKey,
                  );
                },
              ),
              GoRoute(
                path: 'detail/:assessmentId',
                name: 'profile-qol-detail',
                pageBuilder: (context, state) {
                  final assessmentId = state.pathParameters['assessmentId']!;
                  return AppPageTransitions.bidirectionalSlide(
                    child: QolDetailScreen(assessmentId: assessmentId),
                    key: state.pageKey,
                  );
                },
              ),
            ],
          ),
          // Weight routes - inside ShellRoute to show bottom nav bar
          // Use bidirectional slide transitions and manage their own Scaffold
          GoRoute(
            path: '/profile/weight',
            name: 'profile-weight',
            pageBuilder: (context, state) =>
                AppPageTransitions.bidirectionalSlide(
              child: const WeightScreen(),
              key: state.pageKey,
            ),
          ),
          GoRoute(
            path: '/progress/weight',
            name: 'progress-weight',
            pageBuilder: (context, state) =>
                AppPageTransitions.bidirectionalSlide(
              child: const WeightScreen(),
              key: state.pageKey,
            ),
          ),
          // Progress analytics routes - inside ShellRoute to show bottom nav
          // Use bidirectional slide transitions and manage their own Scaffold
          GoRoute(
            path: '/progress/injection-sites',
            name: 'progress-injection-sites',
            pageBuilder: (context, state) =>
                AppPageTransitions.bidirectionalSlide(
              child: const InjectionSitesAnalyticsScreen(),
              key: state.pageKey,
            ),
          ),
          GoRoute(
            path: '/progress/symptoms',
            name: 'progress-symptoms',
            pageBuilder: (context, state) =>
                AppPageTransitions.bidirectionalSlide(
              child: const SymptomsScreen(),
              key: state.pageKey,
            ),
          ),
          // Profile detail routes - inside ShellRoute to show bottom nav
          // Use bidirectional slide transitions and manage their own Scaffold
          GoRoute(
            path: '/profile/ckd',
            name: 'profile-ckd',
            pageBuilder: (context, state) =>
                AppPageTransitions.bidirectionalSlide(
              child: const CkdProfileScreen(),
              key: state.pageKey,
            ),
          ),
          GoRoute(
            path: '/profile/fluid',
            name: 'profile-fluid',
            pageBuilder: (context, state) =>
                AppPageTransitions.bidirectionalSlide(
              child: const FluidScheduleScreen(),
              key: state.pageKey,
            ),
            routes: [
              GoRoute(
                path: 'create',
                name: 'profile-fluid-create',
                pageBuilder: (context, state) =>
                    AppPageTransitions.bidirectionalSlide(
                  child: const CreateFluidScheduleScreen(),
                  key: state.pageKey,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/profile/medication',
            name: 'profile-medication',
            pageBuilder: (context, state) =>
                AppPageTransitions.bidirectionalSlide(
              child: const MedicationScheduleScreen(),
              key: state.pageKey,
            ),
          ),
          GoRoute(
            path: '/profile/inventory',
            name: 'profile-inventory',
            pageBuilder: (context, state) =>
                AppPageTransitions.bidirectionalSlide(
              child: const InventoryScreen(),
              key: state.pageKey,
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (context, state) => AppPageTransitions.bidirectionalSlide(
          child: const AppScaffold(
            showAppBar: false,
            body: LoginScreen(),
          ),
          key: state.pageKey,
        ),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        pageBuilder: (context, state) => AppPageTransitions.bidirectionalSlide(
          child: const AppScaffold(
            showAppBar: false,
            body: RegisterScreen(),
          ),
          key: state.pageKey,
        ),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        pageBuilder: (context, state) => AppPageTransitions.bidirectionalSlide(
          child: const AppScaffold(
            showAppBar: false,
            body: ForgotPasswordScreen(),
          ),
          key: state.pageKey,
        ),
      ),
      GoRoute(
        path: '/email-verification',
        name: 'email-verification',
        pageBuilder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return AppPageTransitions.bidirectionalSlide(
            child: AppScaffold(
              showAppBar: false,
              body: EmailVerificationScreen(email: email),
            ),
            key: state.pageKey,
          );
        },
      ),
      // Onboarding flow routes - nested under /onboarding
      GoRoute(
        path: '/onboarding',
        redirect: (context, state) {
          // Only redirect when the parent '/onboarding' is targeted directly
          final fullPath = state.fullPath;
          if (fullPath == '/onboarding') {
            return '/onboarding/welcome';
          }
          return null;
        },
        routes: [
          GoRoute(
            path: 'welcome',
            name: 'onboarding-welcome',
            pageBuilder: (context, state) =>
                AppPageTransitions.bidirectionalSlide(
                  child: const OnboardingWelcomeScreen(),
                  key: state.pageKey,
                ),
          ),
          GoRoute(
            path: 'basics',
            name: 'onboarding-basics',
            pageBuilder: (context, state) =>
                AppPageTransitions.bidirectionalSlide(
                  child: const PetBasicsScreen(),
                  key: state.pageKey,
                ),
          ),
          GoRoute(
            path: 'medical',
            name: 'onboarding-medical',
            pageBuilder: (context, state) =>
                AppPageTransitions.bidirectionalSlide(
                  child: const CkdMedicalInfoScreen(),
                  key: state.pageKey,
                ),
          ),
          GoRoute(
            path: 'completion',
            name: 'onboarding-completion',
            pageBuilder: (context, state) =>
                AppPageTransitions.bidirectionalSlide(
                  child: const OnboardingCompletionScreen(),
                  key: state.pageKey,
                ),
          ),
        ],
      ),
    ],
  );
});
