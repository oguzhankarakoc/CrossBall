import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../features/ads/presentation/banner_ad_widget.dart';
import '../../../features/ads/ads_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/crossball_ui.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.cb;

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
                    CrossBallCard(
                      icon: Icons.calendar_today_outlined,
                      title: l10n.dailyChallenge,
                      subtitle: l10n.dailyChallengeDesc,
                      onTap: () => context.push('${AppRoutes.puzzle}?mode=daily'),
                    ),
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
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => context.push(AppRoutes.stats),
                            child: Text(l10n.stats),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
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
