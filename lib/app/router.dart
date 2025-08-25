import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hydracat/app/app_shell.dart';
import 'package:hydracat/features/auth/models/auth_state.dart';
import 'package:hydracat/features/auth/screens/login_screen.dart';
import 'package:hydracat/features/home/screens/component_demo_screen.dart';
import 'package:hydracat/features/home/screens/home_screen.dart';
import 'package:hydracat/features/logging/screens/logging_screen.dart';
import 'package:hydracat/features/profile/screens/profile_screen.dart';
import 'package:hydracat/features/progress/screens/progress_screen.dart';
import 'package:hydracat/features/resources/screens/resources_screen.dart';
import 'package:hydracat/features/schedule/screens/schedule_screen.dart';
import 'package:hydracat/providers/auth_provider.dart';

/// Provider for the app router with authentication logic
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isAuthenticated = authState is AuthStateAuthenticated;
      final isOnLoginPage = state.matchedLocation == '/login';

      // If not authenticated and not on login page, redirect to login
      if (!isAuthenticated && !isOnLoginPage) {
        return '/login';
      }

      // If authenticated and on login page, redirect to home
      if (isAuthenticated && isOnLoginPage) {
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
            path: '/schedule',
            name: 'schedule',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ScheduleScreen(),
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
    ],
  );
});
