import 'package:flutter/material.dart';

import '../../../core/club_identity/club_display_resolver.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/club_mastery.dart';
import '../../../shared/widgets/club_identity/club_identity_widgets.dart';
import '../../../shared/widgets/crossball_ui.dart';

class ClubMasterySection extends StatelessWidget {
  const ClubMasterySection({
    super.key,
    required this.clubs,
    required this.emptyLabel,
  });

  final List<ClubMasteryEntry> clubs;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.cb;
    final maxCount = clubs.isEmpty
        ? 1
        : clubs.map((c) => c.intersectionsSolved).reduce((a, b) => a > b ? a : b);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: CrossBallGlassPanel(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.clubMastery, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.md),
            if (clubs.isEmpty)
              Text(
                emptyLabel,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
              )
            else
              ...clubs.map(
                (entry) {
                  final club = ClubDisplayResolver.standalone(
                    id: entry.clubId,
                    name: entry.clubName,
                    shortName: entry.shortName.isNotEmpty ? entry.shortName : null,
                  );
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Row(
                      children: [
                        LeaderboardClubIcon(club: club, size: 32),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            entry.shortName.isNotEmpty ? entry.shortName : entry.clubName,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                        Text(
                          entry.intersectionsSolved.toString(),
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: colors.lime,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          flex: 2,
                          child: ClipRRect(
                            borderRadius: AppRadius.pillBorder,
                            child: LinearProgressIndicator(
                              value: entry.intersectionsSolved / maxCount,
                              minHeight: 6,
                              backgroundColor: colors.textSecondary.withValues(alpha: 0.15),
                              color: colors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
