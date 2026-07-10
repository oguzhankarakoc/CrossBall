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

  bool _looksLikeDefaultProgression(PlayerProgression p) =>
      p.currentLevel <= 1 &&
      p.experiencePoints <= 0 &&
      p.competitiveRating <= 1000.01 &&
      p.gamesCompleted <= 0;

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(userStatsProvider);
    ref.invalidate(playerProgressionProvider);
    ref.invalidate(clubMasteryProvider);
    ref.invalidate(seasonInfoProvider);
    await Future.wait([
      ref.read(userStatsProvider.future),
      ref.read(playerProgressionProvider.future),
      ref.read(clubMasteryProvider.future),
    ]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.cb;
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
                data: (stats) {
                  final progression = progressionAsync.valueOrNull;
                  final progressionStale = progression != null &&
                      _looksLikeDefaultProgression(progression) &&
                      stats.gamesPlayed > 0;

                  return RefreshIndicator(
                    color: colors.lime,
                    onRefresh: () => _refresh(ref),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      children: [
                        Text(
                          l10n.statsCareerTitle,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        if (progressionAsync.isLoading && progression == null)
                          const AppStatsSkeleton()
                        else if (progression == null || progressionStale)
                          CrossBallGlassPanel(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: Row(
                              children: [
                                Icon(Icons.sync_problem_rounded, color: colors.accent),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Text(
                                    l10n.statsProgressUnavailable,
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => _refresh(ref),
                                  child: Text(l10n.retry),
                                ),
                              ],
                            ),
                          )
                        else
                          _CareerHeroCard(progression: progression, l10n: l10n),
                        if (progression != null &&
                            !progressionStale &&
                            progression.achievements.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.md),
                          _AchievementsSection(
                            achievements: progression.achievements,
                            emptyLabel: l10n.noAchievementsYet,
                            title: l10n.achievements,
                          ),
                        ],
                        const SizedBox(height: AppSpacing.xl),
                        Text(
                          l10n.statsActivityTitle,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _ActivityGrid(stats: stats, l10n: l10n),
                        if (stats.weeklyDailyScores.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.md),
                          _WeeklyDailyScoresSection(
                            title: l10n.weeklyDailyScores,
                            scores: stats.weeklyDailyScores,
                            noPlayLabel: l10n.noDailyScore,
                          ),
                        ],
                        clubMasteryAsync.when(
                          loading: () => const SizedBox.shrink(),
                          error: (_, _) => const SizedBox.shrink(),
                          data: (clubs) => Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.md),
                            child: ClubMasterySection(
                              clubs: clubs,
                              emptyLabel: l10n.clubMasteryEmpty,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Text(
                          l10n.rarityBreakdown,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          l10n.rarityBreakdownHint,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colors.textSecondary,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        if (!isPremium)
                          CrossBallGlassPanel(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Row(
                              children: [
                                Icon(Icons.lock_outline, color: colors.lime),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(child: Text(l10n.premiumFeatureStats)),
                                TextButton(
                                  onPressed: () => context.push(AppRoutes.premium),
                                  child: Text(l10n.upgradePremium),
                                ),
                              ],
                            ),
                          )
                        else
                          _RarityBreakdownPanel(stats: stats, l10n: l10n),
                        const SizedBox(height: AppSpacing.xl),
                      ],
                    ),
                  );
                },
              ),
            ),
            const CrossBallBannerSlot(placement: AdPlacement.stats),
          ],
        ),
      ),
    );
  }
}

class _CareerHeroCard extends StatelessWidget {
  const _CareerHeroCard({required this.progression, required this.l10n});

  final PlayerProgression progression;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final colors = context.cb;
    final league = progression.currentLeague.isEmpty
        ? '—'
        : progression.currentLeague[0].toUpperCase() +
            progression.currentLeague.substring(1);

    return CrossBallGlassPanel(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.lime.withValues(alpha: 0.55), width: 2),
                  color: colors.primary.withValues(alpha: 0.18),
                ),
                child: Text(
                  '${progression.currentLevel}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: colors.lime,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${l10n.level} ${progression.currentLevel}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$league · ${progression.competitiveRating.toStringAsFixed(0)} ${l10n.competitiveRating}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    progression.experiencePoints.toString(),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: colors.lime,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  Text(
                    l10n.experiencePoints,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: AppRadius.pillBorder,
            child: LinearProgressIndicator(
              value: progression.levelProgress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: colors.surfaceElevated,
              color: colors.lime,
            ),
          ),
          if (progression.xpToNextLevel > 0) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${progression.xpToNextLevel} XP → ${l10n.level} ${progression.currentLevel + 1}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.textSecondary,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActivityGrid extends StatelessWidget {
  const _ActivityGrid({required this.stats, required this.l10n});

  final UserStats stats;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final items = [
      (l10n.gamesPlayed, stats.gamesPlayed.toString(), Icons.sports_soccer),
      (l10n.currentStreak, stats.currentStreak.toString(), Icons.local_fire_department),
      (l10n.bestStreak, stats.bestStreak.toString(), Icons.emoji_events),
      (l10n.totalScore, stats.totalScore.toStringAsFixed(0), Icons.leaderboard),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > 420;
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: items.map((item) {
            return SizedBox(
              width: wide
                  ? (constraints.maxWidth - AppSpacing.md) / 2
                  : constraints.maxWidth,
              child: _CompactStatTile(
                label: item.$1,
                value: item.$2,
                icon: item.$3,
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _CompactStatTile extends StatelessWidget {
  const _CompactStatTile({
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
    return CrossBallGlassPanel(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Icon(icon, color: colors.lime, size: 22),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colors.lime,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _RarityBreakdownPanel extends StatelessWidget {
  const _RarityBreakdownPanel({required this.stats, required this.l10n});

  final UserStats stats;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final colors = context.cb;
    final total = RarityTier.values.fold<int>(
      0,
      (sum, tier) => sum + (stats.rarityBreakdown[tier.name] ?? 0),
    );

    return CrossBallGlassPanel(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: total == 0
          ? Text(
              l10n.rarityBreakdownEmpty,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
            )
          : Column(
              children: RarityTier.values.map((tier) {
                final count = stats.rarityBreakdown[tier.name] ?? 0;
                final fraction = total > 0 ? count / total : 0.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: tier.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(child: Text(tier.label)),
                          Text(
                            count.toString(),
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: colors.lime,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: AppRadius.pillBorder,
                        child: LinearProgressIndicator(
                          value: fraction.clamp(0.0, 1.0),
                          minHeight: 6,
                          backgroundColor: colors.surfaceElevated,
                          color: tier.color,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }
}

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

    return CrossBallGlassPanel(
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

    return CrossBallGlassPanel(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          ...scores.map((entry) {
            final date = DateTime.tryParse(entry.date);
            final dayLabel =
                date != null ? dayFormatter.format(date.toLocal()) : entry.date;
            final played = entry.score > 0;

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: Text(dayLabel, style: Theme.of(context).textTheme.titleSmall),
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
    );
  }
}
