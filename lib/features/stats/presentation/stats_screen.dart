import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/rarity.dart';
import '../../../features/ads/ads_service.dart';
import '../../../features/ads/presentation/banner_ad_widget.dart';
import '../../../features/premium/premium_service.dart';
import '../../../l10n/app_localizations.dart';
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

    return Scaffold(
      appBar: CrossBallAppBar(title: l10n.stats),
      body: PitchBackground(
        child: Column(
          children: [
            Expanded(
              child: statsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('$e')),
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
                    const SizedBox(height: AppSpacing.lg),
                    Text(l10n.rarityBreakdown, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: AppSpacing.md),
                    if (!isPremium)
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.lock_outline),
                          title: Text(l10n.premiumFeatureStats),
                          trailing: TextButton(
                            onPressed: () => context.push(AppRoutes.premium),
                            child: Text(l10n.upgradePremium),
                          ),
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
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
            const BannerAdWidget(placement: AdPlacement.stats),
          ],
        ),
      ),
    );
  }
}

String _formatLeague(String slug) =>
    slug.isEmpty ? slug : slug[0].toUpperCase() + slug.substring(1);

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

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: ListTile(
        leading: Icon(icon, color: colors.primary),
        title: Text(label),
        trailing: Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: colors.accent,
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
    );
  }
}
