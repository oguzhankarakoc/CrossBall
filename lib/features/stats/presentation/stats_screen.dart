import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/rarity.dart';
import '../../../features/ads/ads_service.dart';
import '../../../features/ads/presentation/banner_ad_widget.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/widgets/crossball_ui.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final statsAsync = ref.watch(userStatsProvider);

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
                  padding: const EdgeInsets.all(20),
                  children: [
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
                    const SizedBox(height: 24),
                    Text(
                      l10n.rarityBreakdown,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    ...RarityTier.values.map((tier) {
                      final count = stats.rarityBreakdown[tier.name] ?? 0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
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
                            const SizedBox(width: 12),
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
      margin: const EdgeInsets.only(bottom: 12),
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
