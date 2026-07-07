import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/crossball_ui.dart';

/// Localized error panel with optional retry action.
class CrossBallErrorPanel extends StatelessWidget {
  const CrossBallErrorPanel({
    super.key,
    required this.message,
    this.onRetry,
    this.icon = Icons.error_outline_rounded,
  });

  final String message;
  final VoidCallback? onRetry;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.cb;

    return Semantics(
      label: message,
      child: CrossBallGlassPanel(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: colors.error, size: 40),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(l10n.retry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Maps known error codes to localized strings.
String localizedErrorMessage(AppLocalizations l10n, String? code) {
  return switch (code) {
    'puzzle_load_failed' => l10n.puzzleLoadFailed,
    'daily_puzzle_generating' => l10n.dailyPuzzleRefreshTitle,
    'daily_puzzle_failed' => l10n.dailyPuzzleRefreshFailedTitle,
    'daily_already_completed' => l10n.dailyAlreadyCompletedTitle,
    'practice_load_failed' => l10n.practiceLoadFailed,
    'practice_limit_reached' => l10n.practiceLimitReached,
    'practice_ad_required' => l10n.practiceAdRequired,
    'premium_required' => l10n.premiumFeatureStats,
    'premium_grid_required' => l10n.premiumGridRequired,
    'ad_token_required' || 'invalid_ad_token' => l10n.hintAdRequired,
    'network_error' => l10n.errorNetwork,
    'unknown_error' => l10n.errorGeneric,
    _ => l10n.errorGeneric,
  };
}
