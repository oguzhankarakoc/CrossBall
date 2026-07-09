import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:intl/intl.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/rarity.dart';
import '../../../features/ads/ads_service.dart';
import '../../../features/ads/presentation/banner_ad_widget.dart';
import '../../../features/economy/domain/player_progression.dart';
import '../../../features/economy/presentation/club_mastery_section.dart';
import '../../../features/premium/premium_service.dart';
import '../domain/stats.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/components/components.dart';
import '../../../shared/widgets/crossball_error_panel.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/widgets/crossball_ui.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final statsAsync = ref.watch(userStatsProvider);
    final progressionAsync = ref.watch(playerProgressionProvider);
    final isPremium = ref.watch(isPremiumProvider);
    final clubMasteryAsync = ref.watch(clubMasteryProvider);

    return Scaffold(
      appBar: CrossBallAppBar(title: l10n.stats),
      body: AppScreenBody(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: statsAsync.when(
                loading: () => const AppStatsSkeleton(),
                error: (e, _) => Center(
                  child: CrossBallErrorPanel(
                    message: localizedErrorMessage(l10n, 'unknown_error'),
                    onRetry: () => ref.invalidate(userStatsProvider),
                  ),
                ),
                data: (stats) => ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    progressionAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (progression) => Column(
                        children: [
                          _StatCard(
                            label: l10n.level,
                            value: '${progression.currentLevel}',
                            icon: Icons.military_tech,
                          ),
                          _StatCard(
                            label: l10n.experiencePoints,
                            value: progression.experiencePoints.toString(),
                            icon: Icons.star,
                          ),
                          _StatCard(
                            label: l10n.competitiveRating,
                            value: progression.competitiveRating.toStringAsFixed(0),
                            icon: Icons.trending_up,
                          ),
                          _StatCard(
                            label: l10n.league,
                            value: _formatLeague(progression.currentLeague),
                            icon: Icons.emoji_events,
                          ),
                          if (progression.achievementPoints > 0)
                            _StatCard(
                              label: l10n.achievementPoints,
                              value: progression.achievementPoints.toString(),
                              icon: Icons.workspace_premium,
                            ),
                          _AchievementsSection(
                            achievements: progression.achievements,
                            emptyLabel: l10n.noAchievementsYet,
                            title: l10n.achievements,
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                      ),
                    ),
                    _StatCard(
                      label: l10n.gamesPlayed,
                      value: stats.gamesPlayed.toString(),
                      icon: Icons.sports_soccer,
                    ),
                    _StatCard(
                      label: l10n.currentStreak,
                      value: stats.currentStreak.toString(),
                      icon: Icons.local_fire_department,
                    ),
                    _StatCard(
                      label: l10n.bestStreak,
                      value: stats.bestStreak.toString(),
                      icon: Icons.emoji_events,
                    ),
                    _StatCard(
                      label: l10n.totalScore,
                      value: stats.totalScore.toStringAsFixed(0),
                      icon: Icons.leaderboard,
                    ),
                    if (stats.weeklyDailyScores.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _WeeklyDailyScoresSection(
                        title: l10n.weeklyDailyScores,
                        scores: stats.weeklyDailyScores,
                        noPlayLabel: l10n.noDailyScore,
                      ),
                    ],
                    clubMasteryAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (clubs) => ClubMasterySection(
                        clubs: clubs,
                        emptyLabel: l10n.clubMasteryEmpty,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(l10n.rarityBreakdown, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: AppSpacing.md),
                    if (!isPremium)
                      CrossBallGlassPanel(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Row(
                          children: [
                            const Icon(Icons.lock_outline),
                            Expanded(child: Text(l10n.premiumFeatureStats)),
                            TextButton(
                              onPressed: () => context.push(AppRoutes.premium),
                              child: Text(l10n.upgradePremium),
                            ),
                          ],
                        ),
                      )
                    else
                      ...RarityTier.values.map((tier) {
                        final count = stats.rarityBreakdown[tier.name] ?? 0;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: tier.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(child: Text(tier.label)),
                              Text(
                                count.toString(),
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: context.cb.lime,
                                    ),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
            const CrossBallBannerSlot(placement: AdPlacement.stats),
          ],
        ),
      ),
    );
  }
}

String _formatLeague(String slug) =>
    slug.isEmpty ? slug : slug[0].toUpperCase() + slug.substring(1);

class _AchievementsSection extends StatelessWidget {
  const _AchievementsSection({
    required this.achievements,
    required this.title,
    required this.emptyLabel,
  });

  final List<PlayerAchievement> achievements;
  final String title;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.cb;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: CrossBallGlassPanel(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.md),
            if (achievements.isEmpty)
              Text(
                emptyLabel,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
              )
            else
              ...achievements.map(
                (a) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.emoji_events, color: colors.lime, size: 22),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              a.title,
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            Text(
                              a.description,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colors.textSecondary,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyDailyScoresSection extends StatelessWidget {
  const _WeeklyDailyScoresSection({
    required this.title,
    required this.scores,
    required this.noPlayLabel,
  });

  final String title;
  final List<DailyScoreEntry> scores;
  final String noPlayLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.cb;
    final dayFormatter = DateFormat.E(Localizations.localeOf(context).toString());

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: CrossBallGlassPanel(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.md),
            ...scores.map((entry) {
              final date = DateTime.tryParse(entry.date);
              final dayLabel = date != null
                  ? dayFormatter.format(date.toLocal())
                  : entry.date;
              final played = entry.score > 0;

              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        dayLabel,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    Text(
                      played ? entry.score.toStringAsFixed(0) : noPlayLabel,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: played ? colors.lime : colors.textSecondary,
                          ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.cb;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: CrossBallGlassPanel(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.15),
                borderRadius: AppRadius.lgBorder,
              ),
              child: Icon(icon, color: colors.lime, size: 24),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(label, style: Theme.of(context).textTheme.titleMedium)),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: colors.lime,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
