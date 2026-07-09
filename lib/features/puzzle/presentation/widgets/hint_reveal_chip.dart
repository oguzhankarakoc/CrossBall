import 'package:flutter/material.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/hint_display.dart';
import '../../../../core/utils/country_flags.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/country_flag_badge.dart';
import '../../../../shared/widgets/crossball_ui.dart';
import '../../domain/puzzle.dart';

/// Single revealed hint pill — constrained width, ellipsis-safe.
class HintRevealChip extends StatelessWidget {
  const HintRevealChip({
    super.key,
    required this.hint,
    required this.maxWidth,
  });

  final HintResult hint;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.cb;
    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colors.primary,
          fontWeight: FontWeight.w600,
        );
    final shortLabel = _shortLabel(hint.hintType, l10n);
    final showNationalityFlag = hint.hintType == HintType.nationality &&
        !HintDisplayFormatter.isUnknown(hint.hintValue) &&
        CountryFlags.hasKnownNationality(hint.hintValue);

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm + 2,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: colors.primary.withValues(alpha: 0.15),
          borderRadius: AppRadius.pillBorder,
          border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_icon(hint.hintType), size: 14, color: colors.primary),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: showNationalityFlag
                  ? Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 4,
                      runSpacing: 2,
                      children: [
                        Text('$shortLabel: ', style: labelStyle),
                        NationalityHintValue(
                          code: hint.hintValue,
                          unknownLabel: l10n.hintValueUnknown,
                          style: labelStyle,
                        ),
                      ],
                    )
                  : Text(
                      '$shortLabel: ${HintDisplayFormatter.formatValue(
                        type: hint.hintType,
                        raw: hint.hintValue,
                        l10n: l10n,
                      )}',
                      style: labelStyle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  static IconData _icon(HintType type) => switch (type) {
        HintType.nationality => Icons.flag_outlined,
        HintType.position => Icons.sports_soccer_outlined,
        HintType.firstLetter => Icons.abc_outlined,
        HintType.careerLeague => Icons.emoji_events_outlined,
        HintType.retiredStatus => Icons.schedule_outlined,
        HintType.careerClub => Icons.shield_outlined,
      };

  static String _shortLabel(HintType type, AppLocalizations l10n) => switch (type) {
        HintType.nationality => l10n.hintChipNationality,
        HintType.position => l10n.hintChipPosition,
        HintType.firstLetter => l10n.hintChipFirstLetter,
        HintType.careerLeague => l10n.league,
        HintType.retiredStatus => l10n.hintChipStatus,
        HintType.careerClub => l10n.hintChipClub,
      };
}
