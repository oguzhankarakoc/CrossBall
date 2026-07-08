import 'package:flutter/material.dart';

import '../../../ads/ads_service.dart';
import '../../../ads/presentation/banner_ad_widget.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/crossball_ui.dart';

class PuzzleResultScreen extends StatefulWidget {
  const PuzzleResultScreen({
    super.key,
    required this.score,
    required this.mistakes,
    required this.hintsUsed,
    required this.onHome,
    this.onCreateAndShareChallenge,
    this.streak = 0,
    this.subtitle,
    this.title,
    this.remainingSessions,
    this.sessionsUsed,
    this.sessionsLimit,
    this.onNewSession,
    this.newSessionLabel,
    this.newSessionRequiresAd = false,
  });

  final double score;
  final int mistakes;
  final int hintsUsed;
  final int streak;
  final VoidCallback onHome;
  final Future<void> Function(GlobalKey shareAnchorKey)? onCreateAndShareChallenge;
  final String? subtitle;
  final String? title;
  final int? remainingSessions;
  final int? sessionsUsed;
  final int? sessionsLimit;
  final VoidCallback? onNewSession;
  final String? newSessionLabel;
  final bool newSessionRequiresAd;

  @override
  State<PuzzleResultScreen> createState() => _PuzzleResultScreenState();
}

class _PuzzleResultScreenState extends State<PuzzleResultScreen> {
  final _challengeShareKey = GlobalKey();
  bool _creatingChallenge = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.cb;

    return Scaffold(
      body: PitchBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    const SizedBox(height: AppSpacing.lg),
                    Center(
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors.lime.withValues(alpha: 0.12),
                          border: Border.all(color: colors.lime.withValues(alpha: 0.35)),
                          boxShadow: AppElevation.limeGlow(colors.lime),
                        ),
                        child: Icon(Icons.workspace_premium_rounded, size: 48, color: colors.lime),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Semantics(
                      header: true,
                      child: Text(
                        widget.title ?? l10n.puzzleComplete,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      widget.subtitle ?? l10n.dailyChallengeDesc,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    if (widget.streak > 0) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        '${l10n.currentStreak}: ${widget.streak} 🔥',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: colors.lime,
                              fontWeight: FontWeight.w700,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    if (widget.remainingSessions != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        l10n.practiceSessionsRemaining(widget.remainingSessions!),
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: colors.lime,
                              fontWeight: FontWeight.w700,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    if (widget.sessionsUsed != null && widget.sessionsLimit != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        l10n.practiceDailyProgress(widget.sessionsUsed!, widget.sessionsLimit!),
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    CrossBallGlassPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CrossBallLabelCaps(l10n.totalScore),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            widget.score.toStringAsFixed(0),
                            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                  color: colors.lime,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 44,
                                ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Row(
                            children: [
                              Expanded(
                                child: _VictoryStat(
                                  label: l10n.mistakes,
                                  value: widget.mistakes.toString(),
                                ),
                              ),
                              Expanded(
                                child: _VictoryStat(
                                  label: l10n.hintsUsed,
                                  value: widget.hintsUsed.toString(),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    if (widget.onNewSession != null) ...[
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: widget.onNewSession,
                          icon: Icon(
                            widget.newSessionRequiresAd
                                ? Icons.play_circle_outline_rounded
                                : Icons.refresh_rounded,
                          ),
                          label: Text((widget.newSessionLabel ?? l10n.practiceNewSession).toUpperCase()),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    if (widget.onCreateAndShareChallenge != null) ...[
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          key: _challengeShareKey,
                          onPressed: _creatingChallenge
                              ? null
                              : () async {
                                  setState(() => _creatingChallenge = true);
                                  try {
                                    await widget.onCreateAndShareChallenge!(_challengeShareKey);
                                  } finally {
                                    if (mounted) {
                                      setState(() => _creatingChallenge = false);
                                    }
                                  }
                                },
                          icon: _creatingChallenge
                              ? SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: colors.lime,
                                  ),
                                )
                              : const Icon(Icons.people_outline_rounded),
                          label: Text(l10n.createAndShareChallenge.toUpperCase()),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
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
              const CrossBallBannerSlot(placement: AdPlacement.result),
            ],
          ),
        ),
      ),
    );
  }
}

class _VictoryStat extends StatelessWidget {
  const _VictoryStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CrossBallLabelCaps(label),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}
