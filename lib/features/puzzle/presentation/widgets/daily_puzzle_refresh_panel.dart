import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/daily_puzzle_schedule.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/crossball_ui.dart';

class DailyPuzzleRefreshPanel extends StatefulWidget {
  const DailyPuzzleRefreshPanel({
    super.key,
    required this.startedAt,
    required this.elapsedSeconds,
    required this.isFailed,
    required this.onRetry,
    this.errorMessage,
    this.retryAfterSeconds = 30,
  });

  final DateTime? startedAt;
  final int elapsedSeconds;
  final bool isFailed;
  final VoidCallback onRetry;
  final String? errorMessage;
  final int retryAfterSeconds;

  @override
  State<DailyPuzzleRefreshPanel> createState() => _DailyPuzzleRefreshPanelState();
}

class _DailyPuzzleRefreshPanelState extends State<DailyPuzzleRefreshPanel> {
  Timer? _ticker;
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _elapsedSeconds = widget.elapsedSeconds;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _elapsedSeconds = widget.startedAt != null
            ? DateTime.now().toUtc().difference(widget.startedAt!.toUtc()).inSeconds
            : _elapsedSeconds + 1;
      });
    });
  }

  @override
  void didUpdateWidget(covariant DailyPuzzleRefreshPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.elapsedSeconds != widget.elapsedSeconds) {
      _elapsedSeconds = widget.elapsedSeconds;
    }
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
    final elapsedLabel = DailyPuzzleSchedule.formatElapsed(_elapsedSeconds);
    final nextReset = DailyPuzzleSchedule.scheduleNote(l10n, localeName);

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
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.surfaceElevated.withValues(alpha: 0.85),
                    border: Border.all(color: colors.glassBorder),
                  ),
                  child: Icon(
                    widget.isFailed
                        ? Icons.cloud_off_outlined
                        : Icons.hourglass_top_rounded,
                    color: widget.isFailed ? colors.error : colors.accent,
                    size: 34,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  widget.isFailed
                      ? l10n.dailyPuzzleRefreshFailedTitle
                      : l10n.dailyPuzzleRefreshTitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  widget.isFailed
                      ? l10n.dailyPuzzleRefreshFailedBody
                      : l10n.dailyPuzzleRefreshBody,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                        height: 1.45,
                      ),
                ),
                if (!widget.isFailed) ...[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surfaceElevated.withValues(alpha: 0.75),
                      borderRadius: AppRadius.mdBorder,
                      border: Border.all(color: colors.glassBorder),
                    ),
                    child: Column(
                      children: [
                        Text(
                          l10n.dailyPuzzleRefreshElapsed(elapsedLabel),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: colors.lime,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.dailyPuzzleRefreshWindowHint,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colors.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (widget.isFailed && widget.errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    widget.errorMessage!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                Text(
                  nextReset,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton.icon(
                  onPressed: widget.onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(
                    widget.isFailed
                        ? l10n.dailyPuzzleRefreshRetry
                        : l10n.dailyPuzzleRefreshCheckAgain,
                  ),
                ),
                if (!widget.isFailed) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.dailyPuzzleRefreshAutoHint(widget.retryAfterSeconds),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
