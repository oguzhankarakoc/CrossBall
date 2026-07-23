import 'package:flutter/material.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/crossball_ui.dart';

/// Contextual how-to sheet shown once on the first daily puzzle (not a second onboarding).
Future<void> showFirstPuzzleCoachSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const _FirstPuzzleCoachSheet(),
  );
}

class _FirstPuzzleCoachSheet extends StatelessWidget {
  const _FirstPuzzleCoachSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.cb;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: colors.glassBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: colors.textSecondary.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Text(
                l10n.firstPuzzleCoachTitle,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.firstPuzzleCoachSubtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              _CoachStep(
                index: 1,
                icon: Icons.touch_app_rounded,
                title: l10n.firstPuzzleCoachStep1Title,
                body: l10n.firstPuzzleCoachStep1Body,
              ),
              const SizedBox(height: AppSpacing.md),
              _CoachStep(
                index: 2,
                icon: Icons.sports_soccer_rounded,
                title: l10n.firstPuzzleCoachStep2Title,
                body: l10n.firstPuzzleCoachStep2Body,
              ),
              const SizedBox(height: AppSpacing.md),
              _CoachStep(
                index: 3,
                icon: Icons.auto_awesome_rounded,
                title: l10n.firstPuzzleCoachStep3Title,
                body: l10n.firstPuzzleCoachStep3Body,
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.firstPuzzleCoachCta),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoachStep extends StatelessWidget {
  const _CoachStep({
    required this.index,
    required this.icon,
    required this.title,
    required this.body,
  });

  final int index;
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final colors = context.cb;
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.lime.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: colors.lime.withValues(alpha: 0.35)),
          ),
          child: Icon(icon, size: 22, color: colors.lime),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$index. $title',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                body,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
