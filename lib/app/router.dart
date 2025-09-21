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
import 'package:hydracat/features/logging/screens/logging_screen.dart';
import 'package:hydracat/features/onboarding/screens/ckd_medical_info_screen.dart';
import 'package:hydracat/features/onboarding/screens/onboarding_completion_screen.dart';
import 'package:hydracat/features/onboarding/screens/pet_basics_screen.dart';
import 'package:hydracat/features/onboarding/screens/treatment_setup_screen.dart';
import 'package:hydracat/features/onboarding/screens/user_persona_screen.dart';
import 'package:hydracat/features/onboarding/screens/welcome_screen.dart';
import 'package:hydracat/features/profile/screens/ckd_profile_screen.dart';
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
  // Only refresh router when authentication status toggles,
  // not for transient states like loading or error
  ref
    ..watch(isAuthenticatedProvider)
    // Watch onboarding state changes for redirect decisions
    ..watch(hasCompletedOnboardingProvider)
    ..watch(hasSkippedOnboardingProvider);

  // Get the refresh stream
  final refreshStream = ref.watch(routerRefreshStreamProvider);

  return GoRouter(
    initialLocation: '/',
    // Ensure redirects are re-evaluated when auth state changes
    refreshListenable: refreshStream,
    redirect: (context, state) async {
      // Read auth state and onboarding status
      final authState = ref.read(authProvider);
      final hasCompletedOnboarding = ref.read(hasCompletedOnboardingProvider);
      final hasSkippedOnboarding = ref.read(hasSkippedOnboardingProvider);

      // Don't redirect while auth is still loading/initializing
      if (authState is AuthStateLoading) {
        return null;
      }

      final isAuthenticated = authState is AuthStateAuthenticated;
      final currentLocation = state.matchedLocation;


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
        return '/login';
      }

      // 2. For authenticated users, check email verification
      if (isAuthenticated && !isOnVerificationPage) {
        final authService = ref.read(authServiceProvider);
        final currentUser = authService.currentUser;

        if (currentUser != null && !currentUser.emailVerified) {
          // User is authenticated but email not verified
          if (!isOnAuthPage) {
            return '/email-verification?email=${currentUser.email ?? ''}';
          }
        }
      }

      // 3. Onboarding flow logic for authenticated & verified users
      if (isAuthenticated) {
        final authService = ref.read(authServiceProvider);
        final currentUser = authService.currentUser;
        final isEmailVerified = currentUser?.emailVerified ?? false;

        // Only apply onboarding logic if email is verified
        if (isEmailVerified) {
          // Users who completed onboarding should not be in onboarding flow
          if (hasCompletedOnboarding && isOnOnboardingPage) {
            return '/';
          }

          // Users who haven't completed AND haven't skipped onboarding
          // should be redirected to onboarding (unless already there)
          if (!hasCompletedOnboarding &&
              !hasSkippedOnboarding &&
              !isOnOnboardingPage &&
              !isOnAuthPage) {
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
          ),
          GoRoute(
            path: '/learn',
            name: 'learn',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ResourcesScreen(),
            ),
          ),
          GoRoute(
            path: '/logging',
            name: 'logging',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: LoggingScreen(),
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
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/profile/ckd',
        name: 'profile-ckd',
        builder: (context, state) => const CkdProfileScreen(),
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
                AppPageTransitions.onboardingForward(
                  child: const OnboardingWelcomeScreen(),
                  key: state.pageKey,
                ),
          ),
          GoRoute(
            path: 'persona',
            name: 'onboarding-persona',
            pageBuilder: (context, state) =>
                AppPageTransitions.onboardingForward(
                  child: const UserPersonaScreen(),
                  key: state.pageKey,
                ),
          ),
          GoRoute(
            path: 'basics',
            name: 'onboarding-basics',
            pageBuilder: (context, state) =>
                AppPageTransitions.onboardingForward(
                  child: const PetBasicsScreen(),
                  key: state.pageKey,
                ),
          ),
          GoRoute(
            path: 'medical',
            name: 'onboarding-medical',
            pageBuilder: (context, state) =>
                AppPageTransitions.onboardingForward(
                  child: const CkdMedicalInfoScreen(),
                  key: state.pageKey,
                ),
          ),
          GoRoute(
            path: 'treatment',
            name: 'onboarding-treatment',
            pageBuilder: (context, state) =>
                AppPageTransitions.onboardingForward(
                  child: const TreatmentSetupScreen(),
                  key: state.pageKey,
                ),
          ),
          GoRoute(
            path: 'completion',
            name: 'onboarding-completion',
            pageBuilder: (context, state) =>
                AppPageTransitions.onboardingForward(
                  child: const OnboardingCompletionScreen(),
                  key: state.pageKey,
                ),
          ),
        ],
      ),
    ],
  );
});
