import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/daily_puzzle_schedule.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/crossball_ui.dart';

class DailyPuzzleCompletedPanel extends StatefulWidget {
  const DailyPuzzleCompletedPanel({
    super.key,
    required this.todayScore,
    required this.streak,
    required this.onHome,
    this.onPractice,
  });

  final double todayScore;
  final int streak;
  final VoidCallback onHome;
  final VoidCallback? onPractice;

  @override
  State<DailyPuzzleCompletedPanel> createState() => _DailyPuzzleCompletedPanelState();
}

class _DailyPuzzleCompletedPanelState extends State<DailyPuzzleCompletedPanel> {
  Timer? _ticker;
  Duration _untilNext = DailyPuzzleSchedule.timeUntilNextReset();

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      setState(() => _untilNext = DailyPuzzleSchedule.timeUntilNextReset());
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.cb;
    final localeName = Localizations.localeOf(context).toString();
    final countdown = DailyPuzzleSchedule.formatCountdown(_untilNext);
    final resetNote = l10n.dailyAlreadyCompletedNextPuzzle(
      DailyPuzzleSchedule.formatLocalResetTime(localeName),
      countdown,
    );

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: CrossBallGlassPanel(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.lime.withValues(alpha: 0.12),
                    border: Border.all(color: colors.lime.withValues(alpha: 0.35)),
                    boxShadow: AppElevation.limeGlow(colors.lime),
                  ),
                  child: Icon(Icons.check_circle_rounded, color: colors.lime, size: 44),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l10n.dailyAlreadyCompletedTitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.dailyAlreadyCompletedBody,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                        height: 1.45,
                      ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: colors.surfaceElevated.withValues(alpha: 0.75),
                    borderRadius: AppRadius.mdBorder,
                    border: Border.all(color: colors.glassBorder),
                  ),
                  child: Column(
                    children: [
                      CrossBallLabelCaps(l10n.totalScore),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        widget.todayScore.toStringAsFixed(0),
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              color: colors.lime,
                              fontWeight: FontWeight.w800,
                              fontSize: 40,
                            ),
                      ),
                      if (widget.streak > 0) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.local_fire_department_rounded,
                                color: colors.accent, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              '${l10n.currentStreak}: ${widget.streak}',
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: colors.accent,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  resetNote,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                        height: 1.4,
                      ),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (widget.onPractice != null) ...[
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: widget.onPractice,
                      icon: const Icon(Icons.fitness_center_rounded),
                      label: Text(l10n.practice),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: widget.onHome,
                    icon: const Icon(Icons.home_rounded),
                    label: Text(l10n.backToHome),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
