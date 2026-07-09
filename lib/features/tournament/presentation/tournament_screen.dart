import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/player_display_name.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/components/components.dart';
import '../../../shared/widgets/crossball_ui.dart';

class TournamentScreen extends ConsumerWidget {
  const TournamentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.cb;
    final theme = Theme.of(context);
    final tournamentAsync = ref.watch(tournamentSnapshotProvider);

    return Scaffold(
      appBar: CrossBallAppBar(title: l10n.tournament),
      body: AppScreenBody(
        bottom: false,
        child: tournamentAsync.when(
          loading: () => const AppListSkeleton(),
          error: (error, _) => Center(
            child: AppErrorState(
              error: error,
              onRetry: () => ref.invalidate(tournamentSnapshotProvider),
            ),
          ),
          data: (snapshot) {
            if (!snapshot.isActive) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: CrossBallEmptyState(
                    icon: Icons.emoji_events_outlined,
                    message: l10n.tournamentInactive,
                  ),
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                CrossBallGlassPanel(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  highlight: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: colors.lime.withValues(alpha: 0.14),
                              borderRadius: AppRadius.mdBorder,
                              border: Border.all(color: colors.lime.withValues(alpha: 0.35)),
                            ),
                            child: Icon(Icons.emoji_events_rounded, color: colors.lime, size: 28),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  snapshot.title,
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: colors.textPrimary,
                                  ),
                                ),
                                if (snapshot.description.isNotEmpty) ...[
                                  const SizedBox(height: AppSpacing.sm),
                                  Text(
                                    snapshot.description,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: colors.textSecondary,
                                      height: 1.45,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (snapshot.userRank != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          l10n.tournamentYourRank(snapshot.userRank!),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colors.lime,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (snapshot.entries.isEmpty)
                  CrossBallEmptyState(
                    icon: Icons.leaderboard_outlined,
                    message: l10n.tournamentEmpty,
                  )
                else
                  ...snapshot.entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: CrossBallGlassPanel(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 36,
                              child: Text(
                                '#${entry.rank}',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: entry.rank <= 3 ? colors.lime : colors.textPrimary,
                                ),
                              ),
                            ),
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: isResolvedAnonymousLabel(entry.displayLabel)
                                  ? colors.surfaceElevated.withValues(alpha: 0.65)
                                  : colors.primary.withValues(alpha: 0.25),
                              child: Text(
                                playerAvatarInitial(entry.displayLabel),
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: isResolvedAnonymousLabel(entry.displayLabel)
                                      ? colors.textSecondary
                                      : colors.accent,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                entry.displayLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: colors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Text(
                              entry.bestScore.toStringAsFixed(0),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: colors.lime,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
