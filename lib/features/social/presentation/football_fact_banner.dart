import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/social.dart';
import '../../../shared/widgets/crossball_ui.dart';

class FootballFactBanner extends StatelessWidget {
  const FootballFactBanner({super.key, required this.fact});

  final FootballFact fact;

  @override
  Widget build(BuildContext context) {
    if (!fact.isValid) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final colors = context.cb;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: CrossBallGlassPanel(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.auto_stories_rounded, color: colors.accent, size: 22),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.footballFactTitle,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: colors.lime,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(fact.text, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
