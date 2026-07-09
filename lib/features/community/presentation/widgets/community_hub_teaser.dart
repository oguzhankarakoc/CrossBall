import 'package:flutter/material.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/crossball_ui.dart';

class CommunityHubTeaser extends StatelessWidget {
  const CommunityHubTeaser({
    super.key,
    required this.onTap,
    this.missionCount = 0,
    this.completedMissions = 0,
    this.goalCount = 0,
    this.activityCount = 0,
  });

  final VoidCallback onTap;
  final int missionCount;
  final int completedMissions;
  final int goalCount;
  final int activityCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.cb;
    final parts = <String>[];
    if (missionCount > 0) {
      parts.add(l10n.communityHubTeaserMissionLine(completedMissions, missionCount));
    }
    if (goalCount > 0) {
      parts.add(l10n.communityHubTeaserGoalLine(goalCount));
    }
    if (activityCount > 0) {
      parts.add(l10n.communityHubTeaserActivityLine(activityCount));
    }
    final subtitle = parts.isEmpty ? l10n.communityHubTeaserEmpty : parts.join(' · ');

    return CrossBallCard(
      icon: Icons.groups_rounded,
      title: l10n.communityHubTitle,
      subtitle: subtitle,
      accentColor: colors.accent,
      trailing: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: colors.accent.withValues(alpha: 0.15),
          borderRadius: AppRadius.mdBorder,
          border: Border.all(color: colors.accent.withValues(alpha: 0.35)),
        ),
        child: Text(
          l10n.communityHubOpen,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colors.accent,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
      onTap: onTap,
    );
  }
}
