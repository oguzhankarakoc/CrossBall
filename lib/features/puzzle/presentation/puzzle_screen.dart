import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/crossball_ui.dart';
import '../domain/puzzle.dart';
import 'puzzle_providers.dart';
import 'widgets/player_search_modal.dart';
import 'widgets/puzzle_grid.dart';
import 'widgets/puzzle_result_screen.dart';
import 'widgets/puzzle_timer.dart';

class PuzzleScreen extends ConsumerStatefulWidget {
  const PuzzleScreen({super.key, this.mode = PuzzleMode.daily});

  final PuzzleMode mode;

  @override
  ConsumerState<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends ConsumerState<PuzzleScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.cb;
    final game = ref.watch(puzzleGameProvider(widget.mode));

    if (game.isComplete) {
      return PuzzleResultScreen(
        score: game.totalScore,
        mistakes: game.mistakes,
        hintsUsed: game.hintsUsed,
        onHome: () => context.go(AppRoutes.home),
        onShare: () {},
      );
    }

    return Scaffold(
      appBar: CrossBallAppBar(
        title: _title(l10n),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
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
            : game.error != null
                ? Center(child: Text(game.error!))
                : game.puzzle == null
                    ? Center(child: Text(l10n.comingSoon))
                    : SafeArea(
                        child: Column(
                          children: [
                            PuzzleTimer(startedAt: DateTime.now()),
                            Expanded(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(16),
                                child: PuzzleGrid(
                                  puzzle: game.puzzle!,
                                  cells: game.cells,
                                  selectedRow: game.selectedRow,
                                  selectedCol: game.selectedCol,
                                  onCellTap: _onCellTap,
                                ),
                              ),
                            ),
                            if (game.totalScore > 0)
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  'Score: ${game.totalScore.toStringAsFixed(0)}',
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

  String _title(AppLocalizations l10n) => switch (widget.mode) {
        PuzzleMode.daily => l10n.dailyChallenge,
        PuzzleMode.practice => l10n.practice,
        PuzzleMode.challenge => l10n.friendChallenge,
      };

  Future<void> _onCellTap(int row, int col) async {
    final notifier = ref.read(puzzleGameProvider(widget.mode).notifier);
    notifier.selectCell(row, col);

    final player = await showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PlayerSearchModal(),
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
