import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hydracat/app/app_shell.dart';
import 'package:hydracat/features/auth/models/auth_state.dart';
import 'package:hydracat/features/auth/screens/email_verification_screen.dart';
import 'package:hydracat/features/auth/screens/forgot_password_screen.dart';
import 'package:hydracat/features/auth/screens/login_screen.dart';
import 'package:hydracat/features/auth/screens/register_screen.dart';
import 'package:hydracat/features/home/screens/component_demo_screen.dart';
import 'package:hydracat/features/home/screens/home_screen.dart';
import 'package:hydracat/features/learn/screens/learn_screen.dart';
import 'package:hydracat/features/onboarding/screens/ckd_medical_info_screen.dart';
import 'package:hydracat/features/onboarding/screens/onboarding_completion_screen.dart';
import 'package:hydracat/features/onboarding/screens/pet_basics_screen.dart';
import 'package:hydracat/features/onboarding/screens/treatment_fluid_screen.dart';
import 'package:hydracat/features/onboarding/screens/treatment_medication_screen.dart';
import 'package:hydracat/features/onboarding/screens/user_persona_screen.dart';
import 'package:hydracat/features/onboarding/screens/welcome_screen.dart';
import 'package:hydracat/features/profile/screens/ckd_profile_screen.dart';
import 'package:hydracat/features/profile/screens/fluid_schedule_screen.dart';
import 'package:hydracat/features/profile/screens/medication_schedule_screen.dart';
import 'package:hydracat/features/profile/screens/profile_screen.dart';
import 'package:hydracat/features/progress/screens/progress_screen.dart';
import 'package:hydracat/features/settings/screens/settings_screen.dart';
import 'package:hydracat/providers/auth_provider.dart';
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
  ref.onDispose(refreshStream.dispose);
  return refreshStream;
});

/// Provider for the app router with authentication logic
final appRouterProvider = Provider<GoRouter>((ref) {
  // Watch auth state and onboarding status to trigger router rebuilds
  final authState = ref.watch(authProvider);
  final hasCompletedOnboarding = ref.watch(hasCompletedOnboardingProvider);
  final hasSkippedOnboarding = ref.watch(hasSkippedOnboardingProvider);
  final currentUser = ref.watch(currentUserProvider);

  // Get the refresh stream
  final refreshStream = ref.watch(routerRefreshStreamProvider);

  return GoRouter(
    initialLocation: '/',
    // Ensure redirects are re-evaluated when auth state changes
    refreshListenable: refreshStream,
    redirect: (context, state) async {
      // Use the watched values instead of ref.read() to avoid timing conflicts

      // Don't redirect while auth is still loading/initializing
      if (authState is AuthStateLoading) {
        if (kDebugMode) {
          debugPrint('[Router] Auth still loading, no redirect');
        }
        return null;
      }

      final isAuthenticated = authState is AuthStateAuthenticated;
      final currentLocation = state.matchedLocation;

      if (kDebugMode) {
        debugPrint(
          '[Router] Evaluating redirect: '
          'location=$currentLocation, '
          'isAuth=$isAuthenticated, '
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
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        pageBuilder: (context, state, child) => NoTransitionPage(
          child: AppShell(child: child),
        ),
        routes: [
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
            routes: [
              GoRoute(
                path: 'settings',
                name: 'profile-settings',
                pageBuilder: (context, state) =>
                    AppPageTransitions.bidirectionalSlide(
                      child: const SettingsScreen(),
                      key: state.pageKey,
                    ),
              ),
              GoRoute(
                path: 'ckd',
                name: 'profile-ckd',
                pageBuilder: (context, state) =>
                    AppPageTransitions.bidirectionalSlide(
                      child: const CkdProfileScreen(),
                      key: state.pageKey,
                    ),
              ),
              GoRoute(
                path: 'fluid',
                name: 'profile-fluid',
                pageBuilder: (context, state) =>
                    AppPageTransitions.bidirectionalSlide(
                      child: const FluidScheduleScreen(),
                      key: state.pageKey,
                    ),
              ),
              GoRoute(
                path: 'medication',
                name: 'profile-medication',
                pageBuilder: (context, state) =>
                    AppPageTransitions.bidirectionalSlide(
                      child: const MedicationScheduleScreen(),
                      key: state.pageKey,
                    ),
              ),
            ],
          ),
          GoRoute(
            path: '/learn',
            name: 'learn',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ResourcesScreen(),
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
              child: ResourcesScreen(),
            ),
          ),
          GoRoute(
            path: '/demo',
            name: 'demo',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ComponentDemoScreen(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/email-verification',
        name: 'email-verification',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return EmailVerificationScreen(email: email);
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
            path: 'persona',
            name: 'onboarding-persona',
            pageBuilder: (context, state) =>
                AppPageTransitions.bidirectionalSlide(
                  child: const UserPersonaScreen(),
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
          // Treatment medication route
          GoRoute(
            path: 'treatment/medication',
            name: 'onboarding-treatment-medication',
            pageBuilder: (context, state) =>
                AppPageTransitions.bidirectionalSlide(
                  child: const TreatmentMedicationScreen(),
                  key: state.pageKey,
                ),
          ),
          // Treatment fluid route
          GoRoute(
            path: 'treatment/fluid',
            name: 'onboarding-treatment-fluid',
            pageBuilder: (context, state) =>
                AppPageTransitions.bidirectionalSlide(
                  child: const TreatmentFluidScreen(),
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
