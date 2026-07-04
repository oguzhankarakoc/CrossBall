import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/social.dart';
import '../../../shared/widgets/crossball_ui.dart';

Future<void> showCareerTimelineSheet(
  BuildContext context, {
  required CareerTimeline timeline,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => _CareerTimelineSheet(timeline: timeline),
  );
}

class _CareerTimelineSheet extends StatelessWidget {
  const _CareerTimelineSheet({required this.timeline});

  final CareerTimeline timeline;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.cb;

    return DraggableScrollableSheet(
      initialChildSize: 0.45,
      minChildSize: 0.3,
      maxChildSize: 0.75,
      expand: false,
      builder: (context, scrollController) {
        return Material(
          color: Colors.transparent,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
            child: CrossBallGlassPanel(
              padding: EdgeInsets.zero,
              borderRadius: AppRadius.xxl,
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: colors.textSecondary.withValues(alpha: 0.35),
                        borderRadius: AppRadius.pillBorder,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    l10n.timelineSheetTitle(timeline.playerName),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (timeline.entries.isEmpty)
                    Text(
                      l10n.timelineEmpty,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colors.textSecondary,
                          ),
                    )
                  else
                    ...timeline.entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: entry.highlight ? colors.lime : colors.textSecondary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text(
                                entry.clubName,
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight:
                                          entry.highlight ? FontWeight.w800 : FontWeight.w600,
                                      color: entry.highlight ? colors.lime : null,
                                    ),
                              ),
                            ),
                            Text(
                              entry.yearLabel(l10n.present),
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: colors.textSecondary,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
