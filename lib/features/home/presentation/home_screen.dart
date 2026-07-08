import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/debug/crossball_debug_log.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/daily_puzzle_schedule.dart';
import '../../../features/economy/domain/player_progression.dart';
import '../../../features/economy/presentation/daily_missions_card.dart';
import '../../../features/economy/presentation/season_card.dart';
import '../../../features/liveops/domain/liveops_event_extensions.dart';
import '../../../features/liveops/presentation/liveops_providers.dart';
import '../../../features/social/presentation/activity_feed_card.dart';
import '../../../features/social/presentation/football_fact_banner.dart';
import '../../../features/social/presentation/football_fact_copy.dart';
import '../../../features/liveops/presentation/widgets/liveops_widgets.dart';
import '../../../features/puzzle/presentation/daily_puzzle_rollout_provider.dart';
import '../../../l10n/app_localizations.dart';
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
    final showFriendChallenge = ref.watch(featureFlagProvider('friend_challenges'));
    final showStats = ref.watch(featureFlagProvider('statistics'));
    final showEvents = ref.watch(featureFlagProvider('special_events'));
    final showActivityFeed = ref.watch(featureFlagProvider('friend_activity_feed'));
    final showTimeline = ref.watch(featureFlagProvider('timeline_mode'));
    final showTournament = ref.watch(featureFlagProvider('tournament_mode'));
    final showAiFacts = ref.watch(featureFlagProvider('ai_features'));
    final activityFeed = ref.watch(activityFeedProvider).valueOrNull ?? const [];
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
    final season = ref.watch(seasonInfoProvider).valueOrNull;
    final stats = ref.watch(userStatsProvider).valueOrNull;
    final rollout = ref.watch(dailyPuzzleRolloutProvider).valueOrNull;
    final isDailyRefreshing = rollout?.isBlocked ?? false;
    final dailyCompleted = !isDailyRefreshing && (stats?.dailyCompletedToday ?? false);
    final isNewPlayer = (stats?.gamesPlayed ?? progression?.gamesPlayed ?? 0) < 7;
    final streak = stats?.currentStreak ?? 0;
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

    return Scaffold(
      extendBody: true,
      appBar: CrossBallAppBar(
        title: l10n.homeTitle,
        actions: [
          IconButton(
            icon: Icon(Icons.emoji_events_rounded, color: colors.accent),
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
                      label: progression != null ? '${l10n.level} ${progression.currentLevel}' : l10n.level,
                      isLoading: progressionAsync.isLoading,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (announcement != null)
                      LiveOpsAnnouncementBanner(announcement: announcement),
                    if (liveOps?.isMaintenanceMode == true)
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
                                  Text(l10n.maintenanceNotice,
                                      style: Theme.of(context).textTheme.titleMedium),
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
                    if (liveOps?.isMaintenanceMode == true)
                      const SizedBox(height: AppSpacing.md),
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
                      onTap: () {
                        cbDebug('Daily', 'home → open daily puzzle', {
                          'dailyCompleted': dailyCompleted,
                        });
                        ref.invalidate(userStatsProvider);
                        context.push('${AppRoutes.puzzle}?mode=daily');
                      },
                    ),
                    if (season != null && season.isActive) SeasonCard(season: season),
                    FootballFactBanner(text: footballFactText),
                    if (showActivityFeed && activityFeed.isNotEmpty)
                      ActivityFeedCard(events: activityFeed),
                    if (missions.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      DailyMissionsCard(missions: missions),
                    ],
                    if (showEvents && liveOps != null && liveOps.activeEvents.isNotEmpty) ...[
                      CrossBallLabelCaps(l10n.activeEvents),
                      const SizedBox(height: AppSpacing.sm),
                      ...liveOps.activeEvents.map(
                        (event) => LiveOpsEventCard(
                          event: event,
                          isLocked: event.isLocked,
                          lockedBadge: event.isLocked ? l10n.eventLockedBadge : null,
                          onTap: () {
                            if (event.isLocked) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(l10n.eventLockedMessage)),
                              );
                              return;
                            }
                            if (event.eventType == 'tournament') {
                              context.push(AppRoutes.tournament);
                            } else {
                              context.push('${AppRoutes.puzzle}?mode=daily');
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: _QuickStatTile(
                            label: l10n.experiencePoints,
                            value: progression?.experiencePoints.toString() ?? '—',
                            icon: Icons.star_rounded,
                            tint: colors.accent,
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
                    if (liveOps != null && liveOps.communityGoals.isNotEmpty) ...[
                      CrossBallLabelCaps(l10n.communityGoals),
                      const SizedBox(height: AppSpacing.sm),
                      ...liveOps.communityGoals.map(
                        (goal) => LiveOpsCommunityGoalBar(goal: goal),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    CrossBallCard(
                      icon: Icons.fitness_center_rounded,
                      title: l10n.practice,
                      subtitle: l10n.practiceDesc,
                      onTap: () => context.push('${AppRoutes.puzzle}?mode=practice'),
                    ),
                    if (showTimeline)
                      CrossBallCard(
                        icon: Icons.timeline_rounded,
                        title: l10n.timelineMode,
                        subtitle: l10n.timelineModeDesc,
                        onTap: () => context.push('${AppRoutes.puzzle}?mode=timeline'),
                      ),
                    if (showTournament)
                      CrossBallCard(
                        icon: Icons.emoji_events_outlined,
                        title: l10n.tournament,
                        subtitle: l10n.tournamentDesc,
                        onTap: () => context.push(AppRoutes.tournament),
                      ),
                    if (showFriendChallenge)
                      CrossBallCard(
                        icon: Icons.people_outline_rounded,
                        title: l10n.friendChallenge,
                        subtitle: l10n.friendChallengeDesc,
                        onTap: () => context.push(AppRoutes.challenge),
                      ),
                    if (showStats)
                      CrossBallCard(
                        icon: Icons.insights_rounded,
                        title: l10n.stats,
                        subtitle: l10n.gamesPlayed,
                        onTap: () => context.push(AppRoutes.stats),
                      ),
                    CrossBallCard(
                      icon: Icons.leaderboard_rounded,
                      title: l10n.leaderboard,
                      subtitle: l10n.competitiveRating,
                      onTap: () => context.push(AppRoutes.leaderboard),
                    ),
                    CrossBallCard(
                      icon: Icons.settings_rounded,
                      title: l10n.settings,
                      onTap: () => context.push(AppRoutes.settings),
                    ),
                  ],
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
  });

  final String label;
  final String value;
  final IconData icon;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return CrossBallGlassPanel(
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
  }
}
