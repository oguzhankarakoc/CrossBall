import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/widgets/crossball_ui.dart';
import '../../domain/liveops_snapshot.dart';

class LiveOpsAnnouncementBanner extends StatelessWidget {
  const LiveOpsAnnouncementBanner({
    super.key,
    required this.announcement,
  });

  final LiveOpsAnnouncement announcement;

  @override
  Widget build(BuildContext context) {
    final colors = context.cb;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: CrossBallGlassPanel(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.campaign_outlined, color: colors.accent, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    announcement.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(announcement.body),
            if (announcement.buttonLabel != null &&
                announcement.deepLink != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.push(announcement.deepLink!),
                  child: Text(announcement.buttonLabel!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class LiveOpsEventCard extends StatelessWidget {
  const LiveOpsEventCard({
    super.key,
    required this.event,
    required this.onTap,
    this.isLocked = false,
    this.lockedBadge,
  });

  final LiveOpsEvent event;
  final VoidCallback onTap;
  final bool isLocked;
  final String? lockedBadge;

  @override
  Widget build(BuildContext context) {
    final colors = context.cb;
    final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          color: isLocked ? colors.textSecondary : null,
        );
    final subtitleStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: isLocked ? colors.textSecondary.withValues(alpha: 0.85) : null,
        );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Opacity(
        opacity: isLocked ? 0.72 : 1,
        child: CrossBallGlassPanel(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              _eventIcon(event.slug, isLocked),
              color: isLocked ? colors.textSecondary : colors.accent,
            ),
            title: Text(event.title, style: titleStyle),
            subtitle: Text(
              event.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: subtitleStyle,
            ),
            trailing: isLocked
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surfaceElevated.withValues(alpha: 0.8),
                      borderRadius: AppRadius.pillBorder,
                      border: Border.all(color: colors.glassBorder),
                    ),
                    child: Text(
                      lockedBadge ?? 'Coming soon',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: colors.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  )
                : event.ctaLabel != null
                    ? Text(event.ctaLabel!, style: TextStyle(color: colors.primary))
                    : null,
            onTap: onTap,
          ),
        ),
      ),
    );
  }
}

IconData _eventIcon(String slug, bool isLocked) {
  if (isLocked && slug != 'champions_league_week') {
    return Icons.lock_outline_rounded;
  }
  return switch (slug) {
    'champions_league_week' => Icons.sports_soccer_rounded,
    'matchday-weekend' => Icons.stadium_outlined,
    _ when slug.contains('tournament') => Icons.emoji_events_outlined,
    _ => isLocked ? Icons.lock_outline_rounded : Icons.local_fire_department,
  };
}

class LiveOpsCommunityGoalBar extends StatelessWidget {
  const LiveOpsCommunityGoalBar({
    super.key,
    required this.goal,
    this.expanded = false,
  });

  final LiveOpsCommunityGoal goal;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final colors = context.cb;
    final progress = (goal.progressPct / 100).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: CrossBallGlassPanel(
        padding: EdgeInsets.all(expanded ? AppSpacing.lg : AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  goal.isUnlocked ? Icons.emoji_events_rounded : Icons.flag_rounded,
                  color: goal.isUnlocked ? colors.lime : colors.accent,
                  size: expanded ? 24 : 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      if (expanded && goal.description.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          goal.description,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colors.textSecondary,
                                height: 1.35,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (goal.isUnlocked)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: colors.lime.withValues(alpha: 0.15),
                      borderRadius: AppRadius.mdBorder,
                    ),
                    child: Text(
                      '${goal.progressPct.toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: colors.lime,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  )
                else
                  Text(
                    '${goal.progressPct.toStringAsFixed(0)}%',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: AppRadius.smBorder,
              child: LinearProgressIndicator(
                value: progress,
                minHeight: expanded ? 8 : 4,
                backgroundColor: colors.surfaceElevated.withValues(alpha: 0.6),
                color: goal.isUnlocked ? colors.lime : colors.accent,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${goal.currentValue.toString()} / ${goal.targetValue.toString()} · ${goal.progressPct.toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
