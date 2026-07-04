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
  });

  final LiveOpsEvent event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.cb;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: CrossBallGlassPanel(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.local_fire_department, color: colors.accent),
          title: Text(event.title),
          subtitle: Text(event.description, maxLines: 2, overflow: TextOverflow.ellipsis),
          trailing: event.ctaLabel != null
              ? Text(event.ctaLabel!, style: TextStyle(color: colors.primary))
              : null,
          onTap: onTap,
        ),
      ),
    );
  }
}

class LiveOpsCommunityGoalBar extends StatelessWidget {
  const LiveOpsCommunityGoalBar({
    super.key,
    required this.goal,
  });

  final LiveOpsCommunityGoal goal;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: CrossBallGlassPanel(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              goal.title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            LinearProgressIndicator(value: goal.progressPct / 100),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${goal.progressPct.toStringAsFixed(1)}% · ${goal.currentValue}/${goal.targetValue}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
