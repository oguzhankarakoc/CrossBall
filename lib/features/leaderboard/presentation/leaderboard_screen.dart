import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/widgets/crossball_error_panel.dart';
import '../../../shared/widgets/crossball_ui.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/leaderboard_repository_impl.dart';
import '../domain/leaderboard.dart';

final leaderboardRepositoryProvider = Provider<LeaderboardRepository>((ref) {
  return LeaderboardRepositoryImpl();
});

final leaderboardProvider = FutureProvider.family<List<LeaderboardEntry>, String?>(
  (ref, league) async {
    return ref.watch(leaderboardRepositoryProvider).getLeaderboard(league: league);
  },
);

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final league = ref.watch(playerProgressionProvider).valueOrNull?.currentLeague;
    final entriesAsync = ref.watch(leaderboardProvider(league));

    return Scaffold(
      appBar: CrossBallAppBar(title: l10n.leaderboard),
      body: PitchBackground(
        child: entriesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Center(
            child: CrossBallErrorPanel(
              message: l10n.errorGeneric,
              onRetry: () => ref.invalidate(leaderboardProvider(league)),
            ),
          ),
          data: (entries) {
            if (entries.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: CrossBallEmptyState(
                    icon: Icons.leaderboard_outlined,
                    message: l10n.leaderboardEmpty,
                  ),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: entries.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final entry = entries[index];
                final isMe = entry.userUuid == profile?.userUuid;

                return Semantics(
                  label: '${entry.displayName}, ${entry.competitiveRating.toStringAsFixed(0)}',
                  child: CrossBallGlassPanel(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 36,
                          child: Text(
                            '#${entry.rank}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: index < 3 ? context.cb.lime : null,
                                ),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.displayName,
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: isMe ? FontWeight.w900 : FontWeight.w600,
                                    ),
                              ),
                              Text(
                                '${_formatLeague(entry.currentLeague)} · ${l10n.level} ${entry.currentLevel}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          entry.competitiveRating.toStringAsFixed(0),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: context.cb.lime,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

String _formatLeague(String slug) =>
    slug.isEmpty ? slug : slug[0].toUpperCase() + slug.substring(1);
