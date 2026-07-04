import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/season_info.dart';
import '../../../shared/widgets/crossball_ui.dart';

class SeasonCard extends StatelessWidget {
  const SeasonCard({super.key, required this.season});

  final SeasonInfo season;

  @override
  Widget build(BuildContext context) {
    if (!season.isActive) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final colors = context.cb;
    final nextTier = _nextTier(season);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: CrossBallGlassPanel(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_month_rounded, color: colors.accent, size: 22),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    season.label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                Text(
                  l10n.seasonPoints(season.seasonPoints),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: colors.lime,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
            if (nextTier != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.seasonNextReward(nextTier.points, nextTier.reward),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: AppRadius.pillBorder,
                child: LinearProgressIndicator(
                  value: (season.seasonPoints / nextTier.points).clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: colors.textSecondary.withValues(alpha: 0.2),
                  color: colors.lime,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  SeasonRewardTier? _nextTier(SeasonInfo season) {
    for (final tier in season.rewardTiers) {
      if (season.seasonPoints < tier.points) return tier;
    }
    return null;
  }
}
