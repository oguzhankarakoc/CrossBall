import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/crossball_ui.dart';
import '../domain/player_progression.dart';
import 'achievement_providers.dart';

/// Shows a celebration dialog when [newlyUnlockedAchievementsProvider] is set.
class AchievementUnlockListener extends ConsumerWidget {
  const AchievementUnlockListener({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(newlyUnlockedAchievementsProvider, (previous, next) {
      if (next.isEmpty || !context.mounted) return;
      _showUnlockDialog(context, ref, next);
    });
    return child;
  }

  Future<void> _showUnlockDialog(
    BuildContext context,
    WidgetRef ref,
    List<PlayerAchievement> achievements,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.cb;

    for (final achievement in achievements) {
      if (!context.mounted) break;
      await showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (ctx) => AlertDialog(
          backgroundColor: colors.surface,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.xlBorder),
          title: Row(
            children: [
              Icon(Icons.emoji_events, color: colors.lime, size: 28),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l10n.achievementUnlocked,
                  style: Theme.of(ctx).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                achievement.title,
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: colors.lime,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                achievement.description,
                style: Theme.of(ctx).textTheme.bodyMedium,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.continueButton),
            ),
          ],
        ),
      );
    }

    ref.read(newlyUnlockedAchievementsProvider.notifier).state = const [];
  }
}
