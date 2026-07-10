import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/responsive/app_breakpoints.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/debug/crossball_debug_log.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/daily_puzzle_schedule.dart';
import '../../../features/community/presentation/widgets/community_hub_teaser.dart';
import '../../../features/economy/domain/player_progression.dart';
import '../../../features/economy/presentation/season_card.dart';
import '../../../features/leaderboard/presentation/leaderboard_screen.dart';
import '../../../features/liveops/domain/liveops_snapshot.dart';
import '../../../features/liveops/domain/liveops_event_extensions.dart';
import '../../../features/liveops/presentation/liveops_providers.dart';
import '../../../features/social/presentation/football_fact_banner.dart';
import '../../../features/social/presentation/football_fact_copy.dart';
import '../../../features/liveops/presentation/widgets/coming_modes_panel.dart';
import '../../../features/liveops/presentation/widgets/liveops_widgets.dart';
import '../../../features/puzzle/presentation/daily_puzzle_rollout_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/components/app_snackbar.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/widgets/crossball_ui.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.cb;
    final liveOps = ref.watch(liveOpsSnapshotProvider).valueOrNull;
    final announcement = ref.watch(topAnnouncementProvider);
    final showEvents = ref.watch(featureFlagProvider('special_events'));
    final showAiFacts = ref.watch(featureFlagProvider('ai_features'));
    final localFact = FootballFactCopy.pickTip(l10n);
    final footballFactText = showAiFacts
        ? ref.watch(footballFactProvider('intersection')).maybeWhen(
            data: (fact) => fact.isValid ? fact.text : localFact,
            orElse: () => localFact,
          )
        : localFact;
    final progressionAsync = ref.watch(playerProgressionProvider);
    final progression = progressionAsync.valueOrNull;
    final missions = ref.watch(playerMissionsProvider).valueOrNull ?? const [];
    final dailyMissions = missions.where((m) => m.period == 'daily').toList();
    final completedMissions = dailyMissions.where((m) => m.isCompleted).length;
    final activityFeed = ref.watch(activityFeedProvider).valueOrNull ?? const [];
    final season = ref.watch(seasonInfoProvider).valueOrNull;
    final stats = ref.watch(userStatsProvider).valueOrNull;
    final rollout = ref.watch(dailyPuzzleRolloutProvider).valueOrNull;
    final isDailyRefreshing = rollout?.isBlocked ?? false;
    final dailyCompletedAsync = ref.watch(dailyCompletedTodayProvider);
    final dailyCompleted = !isDailyRefreshing &&
        (dailyCompletedAsync.valueOrNull ?? stats?.dailyCompletedToday ?? false);
    final isNewPlayer = (stats?.gamesPlayed ?? progression?.gamesPlayed ?? 0) < 7;
    final streak = stats?.currentStreak ?? 0;
    final weeklySnapshot = ref.watch(weeklyDailyLeaderboardProvider).valueOrNull;
    final myWeekly = weeklySnapshot?.myEntry;
    final weeklyScoreLabel = myWeekly == null
        ? '—'
        : myWeekly.rank > 0
            ? '${myWeekly.totalScore.round()} · #${myWeekly.rank}'
            : '${myWeekly.totalScore.round()}';
    final localeName = Localizations.localeOf(context).toString();
    final dailySubtitle = [
      if (isDailyRefreshing)
        l10n.dailyPuzzleRefreshHomeSubtitle
      else if (dailyCompleted)
        l10n.dailyAlreadyCompletedHomeSubtitle
      else
        isNewPlayer ? l10n.dailyChallengeEasyDesc : l10n.dailyChallengeDesc,
      if (!isDailyRefreshing)
        DailyPuzzleSchedule.scheduleNote(l10n, localeName),
    ].join('\n');
    final dailyBadge = isDailyRefreshing
        ? l10n.dailyPuzzleRefreshBadge
        : dailyCompleted
            ? l10n.dailyAlreadyCompletedBadge
            : streak > 0
                ? '$streak ${l10n.currentStreak}'
                : l10n.dailyChallenge;
    final dailyBadgeIcon = isDailyRefreshing
        ? Icons.hourglass_top_rounded
        : dailyCompleted
            ? Icons.check_circle_outline_rounded
            : streak > 0
                ? Icons.local_fire_department_rounded
                : Icons.calendar_today_rounded;
    final allEvents =
        showEvents && liveOps != null ? liveOps.activeEvents : const <LiveOpsEvent>[];
    final playableEvents = allEvents.where((e) => !e.isLocked).toList();
    final lockedEvents = allEvents.where((e) => e.isLocked).toList();

    return Scaffold(
      appBar: CrossBallAppBar(
        title: l10n.homeTitle,
        actions: [
          IconButton(
            icon: Icon(Icons.insights_rounded, color: colors.accent),
            tooltip: l10n.stats,
            onPressed: () => context.push(AppRoutes.stats),
          ),
          IconButton(
            icon: Icon(Icons.emoji_events_rounded, color: colors.accent),
            tooltip: l10n.premium,
            onPressed: () => context.push(AppRoutes.premium),
          ),
        ],
      ),
      body: PitchBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Expanded(
                child: ResponsiveContent(
                  padding: EdgeInsets.zero,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.containerMargin,
                      AppSpacing.sm,
                      AppSpacing.containerMargin,
                      AppSpacing.xl,
                    ),
                    children: [
                      CrossBallLevelStrip(
                        level: progression?.currentLevel ?? 1,
                        progress: progression?.levelProgress ?? 0,
                        label: progression != null
                            ? '${l10n.level} ${progression.currentLevel}'
                            : l10n.level,
                        isLoading: progressionAsync.isLoading,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      if (announcement != null) ...[
                        LiveOpsAnnouncementBanner(announcement: announcement),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      if (liveOps?.isMaintenanceMode == true) ...[
                        CrossBallGlassPanel(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Row(
                            children: [
                              Icon(Icons.build_circle_outlined, color: colors.error),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.maintenanceNotice,
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                    Text(
                                      liveOps?.emergency['message'] as String? ??
                                          l10n.maintenanceNoticeBody,
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      CrossBallHeroCard(
                        title: l10n.dailyChallenge,
                        subtitle: dailySubtitle,
                        actionLabel: isDailyRefreshing
                            ? l10n.dailyPuzzleRefreshCheckAgain
                            : dailyCompleted
                                ? l10n.dailyAlreadyCompletedViewSummary
                                : l10n.continueButton,
                        badge: dailyBadge,
                        badgeIcon: dailyBadgeIcon,
                        onTap: () async {
                          ref.invalidate(dailyPuzzleRolloutProvider);
                          ref.invalidate(userStatsProvider);
                          ref.invalidate(dailyCompletedTodayProvider);
                          ref.invalidate(playerProgressionProvider);
                          ref.invalidate(seasonInfoProvider);
                          final completed =
                              await ref.read(dailyCompletedTodayProvider.future);
                          cbDebug('Daily', 'home → open daily puzzle', {
                            'dailyCompleted': completed,
                          });
                          if (!context.mounted) return;
                          context.push('${AppRoutes.puzzle}?mode=daily');
                        },
                      ),
                      if (playableEvents.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.lg),
                        CrossBallLabelCaps(l10n.activeEvents),
                        const SizedBox(height: AppSpacing.sm),
                        ...playableEvents.map(
                          (event) => LiveOpsEventCard(
                            event: event,
                            isLocked: false,
                            onTap: () {
                              if (event.eventType == 'tournament') {
                                context.push(AppRoutes.tournament);
                              } else {
                                context.push('${AppRoutes.puzzle}?mode=daily');
                              }
                            },
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: _QuickStatTile(
                              label: l10n.homeWeeklyScoreLabel,
                              value: weeklyScoreLabel,
                              icon: Icons.leaderboard_rounded,
                              tint: colors.accent,
                              onTap: () => context.go(AppRoutes.leaderboard),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: _QuickStatTile(
                              label: l10n.currentStreak,
                              value: streak.toString(),
                              icon: Icons.local_fire_department_rounded,
                              tint: colors.lime,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      CommunityHubTeaser(
                        missionCount: dailyMissions.length,
                        completedMissions: completedMissions,
                        goalCount: liveOps?.communityGoals.length ?? 0,
                        activityCount: activityFeed.length,
                        onTap: () => context.push(AppRoutes.community),
                      ),
                      if (season != null && season.isActive) ...[
                        const SizedBox(height: AppSpacing.md),
                        SeasonCard(season: season),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      CrossBallLabelCaps(l10n.comingModesTitle),
                      const SizedBox(height: AppSpacing.sm),
                      if (lockedEvents.isNotEmpty) ...[
                        ...lockedEvents.map(
                          (event) => LiveOpsEventCard(
                            event: event,
                            isLocked: true,
                            lockedBadge: l10n.eventLockedBadge,
                            onTap: () => AppSnackbar.show(
                              context,
                              message: l10n.eventLockedMessage,
                              icon: Icons.lock_outline_rounded,
                            ),
                          ),
                        ),
                      ],
                      const ComingModesPanel(),
                      if (isNewPlayer) ...[
                        const SizedBox(height: AppSpacing.lg),
                        FootballFactBanner(text: footballFactText),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickStatTile extends StatelessWidget {
  const _QuickStatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.tint,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color tint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final child = CrossBallGlassPanel(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: tint, size: 22),
          const SizedBox(height: AppSpacing.sm),
          CrossBallLabelCaps(label),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 26,
                ),
          ),
        ],
      ),
    );
    if (onTap == null) return child;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.lgBorder,
        child: child,
      ),
    );
  }
}
