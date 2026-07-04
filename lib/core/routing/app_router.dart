import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/challenge/presentation/challenge_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/leaderboard/presentation/leaderboard_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/practice/presentation/practice_tab_screen.dart';
import '../../features/premium/presentation/premium_screen.dart';
import '../../features/puzzle/domain/puzzle.dart';
import '../../features/puzzle/presentation/puzzle_providers.dart';
import '../../features/puzzle/presentation/puzzle_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/stats/presentation/stats_screen.dart';
import '../../features/tournament/presentation/tournament_screen.dart';
import '../../shared/widgets/splash_screen.dart';
import 'app_routes.dart';
import 'main_shell_scaffold.dart';

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
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShellScaffold(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.practiceHub,
                builder: (context, state) => const PracticeTabScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.leaderboard,
                builder: (context, state) => const LeaderboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.settings,
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.puzzle,
        builder: (context, state) {
          final modeParam = state.uri.queryParameters['mode'] ?? 'daily';
          final mode = PuzzleMode.values.firstWhere(
            (m) => m.name == modeParam,
            orElse: () => PuzzleMode.daily,
          );
          final challengeId = state.uri.queryParameters['id'];
          final gridParam = state.uri.queryParameters['grid'];
          final gridSize = gridParam != null ? int.tryParse(gridParam) : null;
          return PuzzleScreen(
            params: PuzzleGameParams(
              mode: mode,
              challengeId: challengeId,
              gridSize: gridSize,
            ),
          );
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
        path: AppRoutes.premium,
        builder: (context, state) => const PremiumScreen(),
      ),
      GoRoute(
        path: AppRoutes.tournament,
        builder: (context, state) => const TournamentScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Route not found: ${state.uri}')),
    ),
  );
}
