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
import 'package:hydracat/features/profile/screens/profile_screen.dart';
import 'package:hydracat/features/progress/screens/progress_screen.dart';
import 'package:hydracat/providers/auth_provider.dart';

/// Provider for the app router with authentication logic
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) async {
      // Don't redirect while auth is still loading/initializing
      if (authState is AuthStateLoading) {
        return null;
      }
      
      final isAuthenticated = authState is AuthStateAuthenticated;
      final isOnLoginPage = state.matchedLocation == '/login';
      final isOnRegisterPage = state.matchedLocation == '/register';
      final isOnForgotPasswordPage =
          state.matchedLocation == '/forgot-password';
      final isOnVerificationPage = state.matchedLocation.startsWith(
        '/email-verification',
      );

      // If not authenticated and not on auth pages, redirect to login
      if (!isAuthenticated &&
          !isOnLoginPage &&
          !isOnRegisterPage &&
          !isOnForgotPasswordPage &&
          !isOnVerificationPage) {
        return '/login';
      }

      // If authenticated, check email verification status for main app access
      if (isAuthenticated && !isOnVerificationPage) {
        final authService = ref.read(authServiceProvider);
        final currentUser = authService.currentUser;

        if (currentUser != null && !currentUser.emailVerified) {
          // User is authenticated but email not verified,
          // redirect to verification
          if (!isOnLoginPage && !isOnRegisterPage && !isOnForgotPasswordPage) {
            return '/email-verification?email=${currentUser.email ?? ''}';
          }
        }
      }

      // If authenticated and on auth pages, redirect to home
      if (isAuthenticated &&
          (isOnLoginPage || isOnRegisterPage || isOnForgotPasswordPage)) {
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
    ],
  );
});
