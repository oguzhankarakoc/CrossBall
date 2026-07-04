import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/social.dart';
import '../../../shared/widgets/crossball_ui.dart';

class ActivityFeedCard extends StatelessWidget {
  const ActivityFeedCard({super.key, required this.events});

  final List<ActivityEvent> events;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final colors = context.cb;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: CrossBallGlassPanel(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.groups_rounded, color: colors.accent, size: 22),
                const SizedBox(width: AppSpacing.sm),
                Text(l10n.activityFeed, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ...events.take(5).map(
                  (event) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.circle, size: 8, color: colors.lime),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            _formatEvent(l10n, event),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: colors.textSecondary,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  String _formatEvent(AppLocalizations l10n, ActivityEvent event) {
    final score = (event.payload['final_score'] as num?)?.toDouble();
    final scoreText = score != null ? score.toStringAsFixed(0) : '';
    return switch (event.eventType) {
      'daily_completed' => l10n.activityDailyCompleted(event.displayName, scoreText),
      'challenge_completed' => l10n.activityChallengeCompleted(event.displayName),
      'timeline_completed' => l10n.activityTimelineCompleted(event.displayName, scoreText),
      _ => l10n.activityGeneric(event.displayName, event.eventType.replaceAll('_', ' ')),
    };
  }
}
