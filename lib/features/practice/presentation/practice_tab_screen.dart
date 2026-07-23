import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/game_constants.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../features/premium/premium_service.dart';
import '../../../features/liveops/presentation/liveops_providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/providers/practice_session_provider.dart';
import '../../../shared/widgets/crossball_ui.dart';

/// Practice tab — launches training sessions (shell branch 1).
class PracticeTabScreen extends ConsumerWidget {
  const PracticeTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.cb;
    final session = ref.watch(practiceSessionProvider);
    final isPremium = ref.watch(isPremiumProvider);
    final showTimeline = ref.watch(featureFlagProvider('timeline_mode'));

    return Scaffold(
      appBar: CrossBallAppBar(title: l10n.practice),
      body: PitchBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              CrossBallHeroCard(
                title: l10n.practiceNewSession,
                subtitle: l10n.practiceCompleteDesc,
                actionLabel: l10n.continueButton,
                badge: l10n.practiceSessionsPlayedToday(session.completedToday),
                badgeIcon: Icons.fitness_center_rounded,
                onTap: () => context.push('${AppRoutes.puzzle}?mode=practice'),
              ),
              if (showTimeline) ...[
                const SizedBox(height: AppSpacing.md),
                CrossBallCard(
                  icon: Icons.timeline_rounded,
                  title: l10n.timelineMode,
                  subtitle: l10n.timelineModeDesc,
                  onTap: () => context.push('${AppRoutes.puzzle}?mode=timeline'),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              CrossBallCard(
                icon: Icons.flash_on_rounded,
                title: l10n.quickGridMode,
                subtitle: l10n.quickGridModeDesc,
                onTap: () => context.push('${AppRoutes.puzzle}?mode=quickGrid'),
              ),
              const SizedBox(height: AppSpacing.md),
              CrossBallCard(
                icon: Icons.swipe_rounded,
                title: l10n.matchGridMode,
                subtitle: l10n.matchGridModeDesc,
                onTap: () => context.push('${AppRoutes.puzzle}?mode=matchGrid'),
              ),
              const SizedBox(height: AppSpacing.lg),
              CrossBallGlassPanel(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.practiceSessionsPlayedToday(session.completedToday),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      isPremium
                          ? l10n.practicePremiumSkipAds
                          : l10n.practiceUnlimitedHint,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              if (isPremium) ...[
                const SizedBox(height: AppSpacing.md),
                CrossBallCard(
                  icon: Icons.grid_4x4_rounded,
                  title: l10n.practiceGrid4Title,
                  subtitle: l10n.practiceGrid4Desc,
                  onTap: () => context.push(
                    '${AppRoutes.puzzle}?mode=practice&grid=${GameConstants.premiumGridSize}',
                  ),
                ),
              ],
              if (!isPremium) ...[
                const SizedBox(height: AppSpacing.md),
                CrossBallCard(
                  icon: Icons.workspace_premium_rounded,
                  title: l10n.premium,
                  subtitle: l10n.premiumFeaturePractice,
                  onTap: () => context.push(AppRoutes.premium),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
