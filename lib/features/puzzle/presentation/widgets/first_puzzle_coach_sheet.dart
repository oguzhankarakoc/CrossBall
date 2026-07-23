import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/feature_info/crossball_tip_sheet.dart';

/// Contextual how-to sheet shown once on the first daily puzzle (not a second onboarding).
Future<void> showFirstPuzzleCoachSheet(BuildContext context) {
  return showCrossBallTipSheet<void>(
    context: context,
    builder: (context) => const _FirstPuzzleCoachSheet(),
  );
}

class _FirstPuzzleCoachSheet extends StatelessWidget {
  const _FirstPuzzleCoachSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return CrossBallTipCard(
      eyebrow: l10n.tipSheetEyebrow,
      title: l10n.firstPuzzleCoachTitle,
      subtitle: l10n.firstPuzzleCoachSubtitle,
      steps: [
        (
          icon: Icons.touch_app_rounded,
          title: l10n.firstPuzzleCoachStep1Title,
          body: l10n.firstPuzzleCoachStep1Body,
        ),
        (
          icon: Icons.sports_soccer_rounded,
          title: l10n.firstPuzzleCoachStep2Title,
          body: l10n.firstPuzzleCoachStep2Body,
        ),
        (
          icon: Icons.auto_awesome_rounded,
          title: l10n.firstPuzzleCoachStep3Title,
          body: l10n.firstPuzzleCoachStep3Body,
        ),
      ],
      ctaLabel: l10n.firstPuzzleCoachCta,
      onCta: () => Navigator.of(context).pop(),
    );
  }
}
