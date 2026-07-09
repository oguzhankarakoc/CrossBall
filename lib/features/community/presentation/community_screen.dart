import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../features/economy/presentation/daily_missions_card.dart';
import '../../../features/liveops/presentation/liveops_providers.dart';
import '../../../features/liveops/presentation/widgets/liveops_widgets.dart';
import '../../../features/social/presentation/activity_feed_section.dart';
import '../../../features/social/presentation/football_fact_banner.dart';
import '../../../features/social/presentation/football_fact_copy.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/widgets/crossball_ui.dart';

class CommunityScreen extends ConsumerWidget {
  const CommunityScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(liveOpsSnapshotProvider);
    ref.invalidate(playerMissionsProvider);
    ref.invalidate(activityFeedProvider);
    ref.invalidate(footballFactProvider('intersection'));
    await Future.wait([
      ref.read(liveOpsSnapshotProvider.future),
      ref.read(playerMissionsProvider.future),
      ref.read(activityFeedProvider.future),
    ]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.cb;
    final liveOps = ref.watch(liveOpsSnapshotProvider).valueOrNull;
    final missions = ref.watch(playerMissionsProvider).valueOrNull ?? const [];
    final dailyMissions = missions.where((m) => m.period == 'daily').toList();
    final showActivityFeed = ref.watch(featureFlagProvider('friend_activity_feed'));
    final showAiFacts = ref.watch(featureFlagProvider('ai_features'));
    final activityFeed = ref.watch(activityFeedProvider).valueOrNull ?? const [];
    final localFact = FootballFactCopy.pickTip(l10n);
    final footballFactText = showAiFacts
        ? ref.watch(footballFactProvider('intersection')).maybeWhen(
            data: (fact) => fact.isValid ? fact.text : localFact,
            orElse: () => localFact,
          )
        : localFact;

    return Scaffold(
      appBar: CrossBallAppBar(title: l10n.communityHubTitle),
      body: PitchBackground(
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            color: colors.accent,
            onRefresh: () => _refresh(ref),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.containerMargin,
                AppSpacing.sm,
                AppSpacing.containerMargin,
                AppSpacing.xl,
              ),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Text(
                  l10n.communityHubSubtitle,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: colors.textSecondary,
                        height: 1.4,
                      ),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (dailyMissions.isNotEmpty)
                  DailyMissionsCard(missions: missions)
                else ...[
                  CrossBallLabelCaps(l10n.dailyMissions),
                  const SizedBox(height: AppSpacing.sm),
                  CrossBallGlassPanel(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.flag_outlined, color: colors.textSecondary, size: 22),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            l10n.communityMissionsEmpty,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: colors.textSecondary,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                CrossBallLabelCaps(l10n.communityGoals),
                const SizedBox(height: AppSpacing.sm),
                if (liveOps != null && liveOps.communityGoals.isNotEmpty)
                  ...liveOps.communityGoals.map(
                    (goal) => LiveOpsCommunityGoalBar(goal: goal, expanded: true),
                  )
                else
                  CrossBallGlassPanel(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.flag_circle_outlined, color: colors.textSecondary, size: 22),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            l10n.communityGoalsEmpty,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: colors.textSecondary,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (showActivityFeed) ...[
                  const SizedBox(height: AppSpacing.lg),
                  ActivityFeedSection(events: activityFeed),
                ],
                const SizedBox(height: AppSpacing.lg),
                FootballFactBanner(text: footballFactText),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
