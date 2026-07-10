import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/crossball_ui.dart';
import '../domain/player_mission.dart';

class DailyMissionsCard extends StatelessWidget {
  const DailyMissionsCard({
    super.key,
    required this.missions,
  });

  final List<PlayerMission> missions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final daily = missions.where((m) => m.period == 'daily').toList();
    if (daily.isEmpty) return const SizedBox.shrink();

    final completed = daily.where((m) => m.isCompleted).length;

    return Semantics(
      label: l10n.dailyMissions,
      child: CrossBallGlassPanel(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flag_rounded, color: context.cb.lime, size: 22),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    l10n.dailyMissions,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                Text(
                  l10n.missionsProgress(completed, daily.length),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: context.cb.lime,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ...daily.map((m) => _MissionRow(mission: m)),
          ],
        ),
      ),
    );
  }
}

class _MissionRow extends StatelessWidget {
  const _MissionRow({required this.mission});

  final PlayerMission mission;

  @override
  Widget build(BuildContext context) {
    final colors = context.cb;
    final l10n = AppLocalizations.of(context)!;
    final (title, description) = _localizedMission(l10n, mission);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            mission.isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            color: mission.isCompleted ? colors.lime : colors.textSecondary,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        decoration: mission.isCompleted ? TextDecoration.lineThrough : null,
                      ),
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                ),
                if (!mission.isCompleted && mission.progressTarget > 1) ...[
                  const SizedBox(height: AppSpacing.xs),
                  LinearProgressIndicator(value: mission.progressFraction),
                  const SizedBox(height: 2),
                  Text(
                    '${mission.progressCurrent}/${mission.progressTarget}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                  ),
                ],
              ],
            ),
          ),
          if (mission.rewardXp > 0)
            Text(
              '+${mission.rewardXp} XP',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.accent,
                    fontWeight: FontWeight.w700,
                  ),
            ),
        ],
      ),
    );
  }
}

(String, String) _localizedMission(AppLocalizations l10n, PlayerMission mission) {
  return switch (mission.slug) {
    'daily_play_one' => (l10n.missionDailyPlayOneTitle, l10n.missionDailyPlayOneDesc),
    'daily_no_hints' => (l10n.missionDailyNoHintsTitle, l10n.missionDailyNoHintsDesc),
    'daily_legendary' => (l10n.missionDailyLegendaryTitle, l10n.missionDailyLegendaryDesc),
    'weekly_hard_3' => (l10n.missionWeeklyHard3Title, l10n.missionWeeklyHard3Desc),
    _ => (mission.title, mission.description),
  };
}
