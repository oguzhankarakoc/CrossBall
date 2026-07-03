import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/crossball_ui.dart';
import '../../challenge/domain/challenge.dart';
import '../domain/puzzle.dart';
import 'puzzle_providers.dart';
import 'widgets/player_search_modal.dart';
import 'widgets/puzzle_grid.dart';
import 'widgets/puzzle_result_screen.dart';
import 'widgets/puzzle_timer.dart';

class PuzzleScreen extends ConsumerStatefulWidget {
  const PuzzleScreen({
    super.key,
    required this.params,
  });

  final PuzzleGameParams params;

  @override
  ConsumerState<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends ConsumerState<PuzzleScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.cb;
    final game = ref.watch(puzzleGameProvider(widget.params));

    if (game.isComplete) {
      if (game.challengeResult != null) {
        return ChallengeResultScreen(
          result: game.challengeResult!,
          yourScore: game.totalScore,
          onHome: () => context.go(AppRoutes.home),
        );
      }
      return PuzzleResultScreen(
        score: game.totalScore,
        mistakes: game.mistakes,
        hintsUsed: game.hintsUsed,
        onHome: () => context.go(AppRoutes.home),
        onShare: _createChallengeFromResult,
      );
    }

    return Scaffold(
      appBar: CrossBallAppBar(
        title: _title(l10n),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: Center(
              child: Text(
                '${game.solvedCount}/${game.totalCells}',
                style: TextStyle(
                  color: colors.accent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: PitchBackground(
        child: game.isLoading
            ? const Center(child: CircularProgressIndicator())
            : game.error == 'practice_limit_reached'
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(l10n.practiceLimitReached, textAlign: TextAlign.center),
                          const SizedBox(height: AppSpacing.md),
                          FilledButton(
                            onPressed: () => context.push(AppRoutes.premium),
                            child: Text(l10n.upgradePremium),
                          ),
                        ],
                      ),
                    ),
                  )
                : game.error != null
                    ? Center(child: Text(game.error!))
                    : game.puzzle == null
                        ? Center(child: Text(l10n.comingSoon))
                        : SafeArea(
                            child: Column(
                              children: [
                                PuzzleTimer(startedAt: game.startedAt ?? DateTime.now()),
                                Expanded(
                                  child: Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.md,
                                        vertical: AppSpacing.sm,
                                      ),
                                      child: PuzzleGrid(
                                        puzzle: game.puzzle!,
                                        cells: game.cells,
                                        selectedRow: game.selectedRow,
                                        selectedCol: game.selectedCol,
                                        onCellTap: _onCellTap,
                                      ),
                                    ),
                                  ),
                                ),
                                if (game.totalScore > 0)
                                  Padding(
                                    padding: const EdgeInsets.all(AppSpacing.md),
                                    child: Text(
                                      '${l10n.score}: ${game.totalScore.toStringAsFixed(0)}',
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                            color: colors.accent,
                                          ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
      ),
    );
  }

  String _title(AppLocalizations l10n) => switch (widget.params.mode) {
        PuzzleMode.daily => l10n.dailyChallenge,
        PuzzleMode.practice => l10n.practice,
        PuzzleMode.challenge => l10n.friendChallenge,
      };

  Future<void> _createChallengeFromResult() async {
    context.push(AppRoutes.challenge);
  }

  Future<void> _onCellTap(int row, int col) async {
    final notifier = ref.read(puzzleGameProvider(widget.params).notifier);
    notifier.selectCell(row, col);

    final game = ref.read(puzzleGameProvider(widget.params));
    final puzzle = game.puzzle;
    if (puzzle == null) return;

    final cellKey = '${row}_$col';
    final player = await showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => PlayerSearchModal(
        params: widget.params,
        rowClub: puzzle.rowClubAt(row),
        colClub: puzzle.colClubAt(col),
        revealedHints: game.hintsRevealed[cellKey] ?? const [],
      ),
    );

    if (player == null || !mounted) {
      notifier.clearSelection();
      return;
    }

    final result = await notifier.submitAnswer(player);
    if (result != null && mounted) {
      await showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (_) => AnswerResultSheet(result: result),
      );
    }
  }
}

class ChallengeResultScreen extends StatelessWidget {
  const ChallengeResultScreen({
    super.key,
    required this.result,
    required this.yourScore,
    required this.onHome,
  });

  final ChallengeResult result;
  final double yourScore;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.cb;
    final title = result.isTie
        ? l10n.challengeTie
        : result.youWon
            ? l10n.challengeYouWon
            : l10n.challengeYouLost;

    return Scaffold(
      body: PitchBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  result.youWon ? Icons.emoji_events : Icons.sports_soccer,
                  size: 64,
                  color: colors.accent,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(title, style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.lg),
                _ScoreCompareRow(label: l10n.challengeCreator, score: result.creatorScore),
                _ScoreCompareRow(label: l10n.challengeYou, score: yourScore),
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(onPressed: onHome, child: Text(l10n.backToHome)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScoreCompareRow extends StatelessWidget {
  const _ScoreCompareRow({required this.label, required this.score});

  final String label;
  final double score;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(score.toStringAsFixed(0), style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    );
  }
}
