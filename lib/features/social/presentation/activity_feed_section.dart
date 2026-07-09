import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/player_display_name.dart';
import '../../../core/utils/relative_time.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/social.dart';
import '../../../shared/widgets/crossball_ui.dart';
import 'activity_feed_utils.dart';

class ActivityFeedSection extends StatelessWidget {
  const ActivityFeedSection({
    super.key,
    required this.events,
    this.maxItems,
  });

  final List<ActivityEvent> events;
  final int? maxItems;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.cb;
    final visible = maxItems != null ? events.take(maxItems!).toList() : events;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CrossBallLabelCaps(l10n.activityFeed),
        const SizedBox(height: AppSpacing.sm),
        if (visible.isEmpty)
          CrossBallGlassPanel(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.groups_outlined, color: colors.textSecondary, size: 22),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    l10n.activityFeedEmpty,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.textSecondary,
                        ),
                  ),
                ),
              ],
            ),
          )
        else
          CrossBallGlassPanel(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.sm,
              horizontal: AppSpacing.md,
            ),
            child: Column(
              children: [
                for (var i = 0; i < visible.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      color: colors.glassBorder.withValues(alpha: 0.5),
                    ),
                  _ActivityFeedRow(event: visible[i]),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _ActivityFeedRow extends StatelessWidget {
  const _ActivityFeedRow({required this.event});

  final ActivityEvent event;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.cb;
    final label = event.displayLabel;
    final initial = playerAvatarInitial(label);
    final anonymous = isResolvedAnonymousLabel(label);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: anonymous
                ? colors.surfaceElevated.withValues(alpha: 0.65)
                : colors.primary.withValues(alpha: 0.25),
            child: Text(
              initial,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: anonymous ? colors.textSecondary : colors.accent,
                  ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      formatRelativeTime(l10n, event.createdAt),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: colors.textSecondary,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      activityEventIcon(event.eventType),
                      size: 14,
                      color: colors.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        formatActivityAction(l10n, event),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.textSecondary,
                              height: 1.35,
                            ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
