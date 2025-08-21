import 'package:go_router/go_router.dart';
import 'package:hydracat/features/auth/screens/login_screen.dart';
import 'package:hydracat/features/home/screens/home_screen.dart';
import 'package:hydracat/features/logging/screens/logging_screen.dart';
import 'package:hydracat/features/profile/screens/profile_screen.dart';
import 'package:hydracat/features/progress/screens/progress_screen.dart';
import 'package:hydracat/features/resources/screens/resources_screen.dart';

/// The main router configuration for the HydraCat application.
final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/profile',
      name: 'profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/logging',
      name: 'logging',
      builder: (context, state) => const LoggingScreen(),
    ),
    GoRoute(
      path: '/progress',
      name: 'progress',
      builder: (context, state) => const ProgressScreen(),
    ),
    GoRoute(
      path: '/resources',
      name: 'resources',
      builder: (context, state) => const ResourcesScreen(),
    ),
  ],
);
