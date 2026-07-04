import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../features/ads/presentation/banner_ad_widget.dart';
import '../../../features/ads/ads_service.dart';
import '../../../features/liveops/presentation/liveops_providers.dart';
import '../../../features/liveops/presentation/widgets/liveops_widgets.dart';
import '../../../l10n/app_localizations.dart';
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

    return Scaffold(
      appBar: CrossBallAppBar(
        title: l10n.homeTitle,
        actions: [
          IconButton(
            icon: const Icon(Icons.workspace_premium_outlined),
            onPressed: () => context.push(AppRoutes.premium),
          ),
        ],
      ),
      body: PitchBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    if (announcement != null)
                      LiveOpsAnnouncementBanner(announcement: announcement),
                    if (liveOps?.isMaintenanceMode == true)
                      Card(
                        color: AppColors.error.withValues(alpha: 0.15),
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: ListTile(
                          leading: const Icon(Icons.build_circle_outlined, color: AppColors.error),
                          title: Text(l10n.maintenanceNotice),
                          subtitle: Text(
                            liveOps?.emergency['message'] as String? ??
                                l10n.maintenanceNoticeBody,
                          ),
                        ),
                      ),
                    Center(child: CrossBallLogo(size: 72)),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      l10n.tagline,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: colors.accent,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xl - 4),
                    if (showEvents && liveOps != null && liveOps.activeEvents.isNotEmpty) ...[
                      Text(
                        l10n.activeEvents,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ...liveOps.activeEvents.map(
                        (event) => LiveOpsEventCard(
                          event: event,
                          onTap: () => context.push('${AppRoutes.puzzle}?mode=daily'),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    if (liveOps != null && liveOps.communityGoals.isNotEmpty) ...[
                      Text(
                        l10n.communityGoals,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ...liveOps.communityGoals.map(
                        (goal) => LiveOpsCommunityGoalBar(goal: goal),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    CrossBallCard(
                      icon: Icons.calendar_today_outlined,
                      title: l10n.dailyChallenge,
                      subtitle: l10n.dailyChallengeDesc,
                      onTap: () => context.push('${AppRoutes.puzzle}?mode=daily'),
                    ),
                    if (showFriendChallenge)
                      CrossBallCard(
                        icon: Icons.people_outline,
                        title: l10n.friendChallenge,
                        subtitle: l10n.friendChallengeDesc,
                        onTap: () => context.push(AppRoutes.challenge),
                      ),
                    CrossBallCard(
                      icon: Icons.fitness_center_outlined,
                      title: l10n.practice,
                      subtitle: l10n.practiceDesc,
                      onTap: () => context.push('${AppRoutes.puzzle}?mode=practice'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        if (showStats)
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => context.push(AppRoutes.stats),
                              child: Text(l10n.stats),
                            ),
                          ),
                        if (showStats) const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => context.push(AppRoutes.settings),
                            child: Text(l10n.settings),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const BannerAdWidget(placement: AdPlacement.home),
            ],
          ),
        ),
      ),
    );
  }
}
