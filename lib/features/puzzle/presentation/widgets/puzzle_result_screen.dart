import 'package:flutter/material.dart';

import '../../../ads/ads_service.dart';
import '../../../ads/presentation/banner_ad_widget.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/crossball_ui.dart';

class PuzzleResultScreen extends StatelessWidget {
  const PuzzleResultScreen({
    super.key,
    required this.score,
    required this.mistakes,
    required this.hintsUsed,
    required this.onHome,
    required this.onShare,
  });

  final double score;
  final int mistakes;
  final int hintsUsed;
  final VoidCallback onHome;
  final VoidCallback onShare;

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
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.emoji_events, size: 64, color: colors.accent),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        l10n.puzzleComplete,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        score.toStringAsFixed(0),
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                              color: colors.accent,
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _StatRow(label: l10n.mistakes, value: mistakes.toString()),
                      _StatRow(label: l10n.hintsUsed, value: hintsUsed.toString()),
                      const SizedBox(height: AppSpacing.xl),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: onHome,
                          child: Text(l10n.backToHome),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: onShare,
                          child: Text(l10n.createChallenge),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const BannerAdWidget(placement: AdPlacement.result),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
