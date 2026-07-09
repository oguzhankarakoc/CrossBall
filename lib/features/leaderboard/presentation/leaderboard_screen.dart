import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/components/components.dart';
import '../../../shared/widgets/crossball_error_panel.dart';
import '../../../shared/widgets/crossball_ui.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../../core/network/network_providers.dart';
import '../data/leaderboard_repository_impl.dart';
import '../domain/leaderboard.dart';

final leaderboardRepositoryProvider = Provider<LeaderboardRepository>((ref) {
  return LeaderboardRepositoryImpl(httpClient: ref.watch(apiHttpClientProvider));
});

final leaderboardProvider = FutureProvider.family<List<LeaderboardEntry>, String?>(
  (ref, league) async {
    return ref.watch(leaderboardRepositoryProvider).getLeaderboard(league: league);
  },
);

final weeklyDailyLeaderboardProvider = FutureProvider<WeeklyDailyLeaderboardSnapshot?>(
  (ref) async {
    final profile = ref.watch(userProfileProvider).valueOrNull;
    return ref.watch(leaderboardRepositoryProvider).getWeeklyDailyLeaderboard(
          userUuid: profile?.userUuid,
        );
  },
);

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: CrossBallAppBar(
        title: l10n.leaderboard,
        tabBar: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.leaderboardWeeklyTab),
            Tab(text: l10n.leaderboardRatingTab),
          ],
        ),
      ),
      body: AppScreenBody(
        bottom: false,
        child: TabBarView(
          controller: _tabController,
          children: [
            _WeeklyDailyLeaderboardTab(l10n: l10n),
            _RatingLeaderboardTab(l10n: l10n),
          ],
        ),
      ),
    );
  }
}

class _WeeklyDailyLeaderboardTab extends ConsumerWidget {
  const _WeeklyDailyLeaderboardTab({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshotAsync = ref.watch(weeklyDailyLeaderboardProvider);
    final profile = ref.watch(userProfileProvider).valueOrNull;

    return snapshotAsync.when(
      loading: () => const AppListSkeleton(),
      error: (_, __) => Center(
        child: CrossBallErrorPanel(
          message: l10n.errorGeneric,
          onRetry: () => ref.invalidate(weeklyDailyLeaderboardProvider),
        ),
      ),
      data: (snapshot) {
        if (snapshot == null) {
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

        final entries = snapshot.entries;
        final myEntry = snapshot.myEntry;

        if (entries.isEmpty && myEntry == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: CrossBallEmptyState(
                icon: Icons.leaderboard_outlined,
                message: l10n.weeklyLeaderboardEmpty,
              ),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            CrossBallGlassPanel(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.weeklyLeaderboardTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.weekResetsMonday,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.cb.textSecondary,
                        ),
                  ),
                  if (snapshot.weekStart.isNotEmpty && snapshot.weekEnd.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${snapshot.weekStart} → ${snapshot.weekEnd}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            if (myEntry != null) ...[
              const SizedBox(height: AppSpacing.md),
              _WeeklyLeaderboardCard(
                entry: myEntry,
                isMe: true,
                highlight: true,
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            ...entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _WeeklyLeaderboardCard(
                  entry: entry,
                  isMe: entry.userUuid == profile?.userUuid,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _WeeklyLeaderboardCard extends StatelessWidget {
  const _WeeklyLeaderboardCard({
    required this.entry,
    required this.isMe,
    this.highlight = false,
  });

  final WeeklyDailyLeaderboardEntry entry;
  final bool isMe;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.cb;
    final dayFormatter = DateFormat.E(Localizations.localeOf(context).toString());

    return CrossBallGlassPanel(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 36,
                child: Text(
                  '#${entry.rank}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: entry.rank <= 3 ? colors.lime : null,
                      ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.displayLabel,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: isMe || highlight ? FontWeight.w900 : FontWeight.w600,
                          ),
                    ),
                    Text(
                      l10n.daysPlayedCount(entry.daysPlayed),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Text(
                entry.totalScore.toStringAsFixed(0),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colors.lime,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: entry.dailyScores.map((day) {
              final date = DateTime.tryParse(day.date);
              final label = date != null
                  ? dayFormatter.format(date.toLocal())
                  : day.date.substring(5);
              final played = day.score > 0;

              return Container(
                width: 44,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: played
                      ? colors.primary.withValues(alpha: 0.18)
                      : colors.surface.withValues(alpha: 0.35),
                  borderRadius: AppRadius.mdBorder,
                ),
                child: Column(
                  children: [
                    Text(label, style: Theme.of(context).textTheme.labelSmall),
                    const SizedBox(height: 2),
                    Text(
                      played ? day.score.toStringAsFixed(0) : '—',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: played ? colors.lime : colors.textSecondary,
                          ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          if (entry.totalHints > 0 || entry.totalMistakes > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.weeklyLeaderboardPenalties(entry.totalHints, entry.totalMistakes),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RatingLeaderboardTab extends ConsumerWidget {
  const _RatingLeaderboardTab({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final league = ref.watch(playerProgressionProvider).valueOrNull?.currentLeague;
    final entriesAsync = ref.watch(leaderboardProvider(league));

    return entriesAsync.when(
      loading: () => const AppListSkeleton(),
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
              label: '${entry.displayLabel}, ${entry.competitiveRating.toStringAsFixed(0)}',
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
                            entry.displayLabel,
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
    );
  }
}

String _formatLeague(String slug) =>
    slug.isEmpty ? slug : slug[0].toUpperCase() + slug.substring(1);
