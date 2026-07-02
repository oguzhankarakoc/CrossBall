import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/puzzle/domain/puzzle.dart';
import '../../features/puzzle/presentation/puzzle_screen.dart';
import '../../features/challenge/presentation/challenge_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/premium/presentation/premium_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/stats/presentation/stats_screen.dart';
import '../../shared/widgets/splash_screen.dart';
import 'app_routes.dart';

GoRouter createAppRouter({required bool onboardingComplete}) {
  return GoRouter(
    initialLocation: onboardingComplete ? AppRoutes.home : AppRoutes.onboarding,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.puzzle,
        builder: (context, state) {
          final modeParam = state.uri.queryParameters['mode'] ?? 'daily';
          final mode = PuzzleMode.values.firstWhere(
            (m) => m.name == modeParam,
            orElse: () => PuzzleMode.daily,
          );
          return PuzzleScreen(mode: mode);
        },
      ),
      GoRoute(
        path: AppRoutes.challenge,
        builder: (context, state) {
          final id = state.uri.queryParameters['id'];
          return ChallengeScreen(challengeId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.stats,
        builder: (context, state) => const StatsScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.premium,
        builder: (context, state) => const PremiumScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Route not found: ${state.uri}')),
    ),
  );
}
