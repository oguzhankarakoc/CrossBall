import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/ads/presentation/banner_ad_widget.dart';
import '../../features/ads/ads_service.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/crossball_ui.dart';

/// Persistent bottom navigation shell (Phase 2 — StatefulShellRoute host).
class MainShellScaffold extends ConsumerWidget {
  const MainShellScaffold({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BannerAdWidget(placement: AdPlacement.home),
          CrossBallQuickNav(
            currentIndex: navigationShell.currentIndex,
            onTap: _onTap,
            items: [
              CrossBallNavItem(icon: Icons.home_rounded, label: l10n.homeTitle),
              CrossBallNavItem(icon: Icons.sports_soccer_rounded, label: l10n.practice),
              CrossBallNavItem(icon: Icons.leaderboard_rounded, label: l10n.leaderboard),
              CrossBallNavItem(icon: Icons.settings_rounded, label: l10n.settings),
            ],
          ),
        ],
      ),
    );
  }
}
