import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/game_constants.dart';
import '../../../core/utils/anti_cheat_tracker.dart';
import '../../../core/utils/scoring.dart';
import '../../search/domain/search.dart';
import '../domain/puzzle.dart';
import '../domain/puzzle_repository.dart';
import '../../../shared/providers/app_providers.dart';

class PuzzleGameState {
  const PuzzleGameState({
    this.puzzle,
    this.cells = const {},
    this.sessionId,
    this.selectedRow,
    this.selectedCol,
    this.mistakes = 0,
    this.hintsUsed = 0,
    this.totalScore = 0,
    this.isComplete = false,
    this.isLoading = true,
    this.error,
    this.cellStartTime,
    this.hintsRevealed = const {},
  });

  final Puzzle? puzzle;
  final Map<String, PuzzleCell> cells;
  final String? sessionId;
  final int? selectedRow;
  final int? selectedCol;
  final int mistakes;
  final int hintsUsed;
  final double totalScore;
  final bool isComplete;
  final bool isLoading;
  final String? error;
  final DateTime? cellStartTime;
  final Map<String, List<String>> hintsRevealed;

  int get solvedCount => cells.values.where((c) => c.isSolved).length;
  int get totalCells => puzzle?.totalCells ?? 0;

  PuzzleCell? get selectedCell {
    if (selectedRow == null || selectedCol == null || puzzle == null) return null;
    final key = '${selectedRow}_$selectedCol';
    return cells[key];
  }

  PuzzleGameState copyWith({
    Puzzle? puzzle,
    Map<String, PuzzleCell>? cells,
    String? sessionId,
    int? selectedRow,
    int? selectedCol,
    int? mistakes,
    int? hintsUsed,
    double? totalScore,
    bool? isComplete,
    bool? isLoading,
    String? error,
    DateTime? cellStartTime,
    Map<String, List<String>>? hintsRevealed,
    bool clearSelection = false,
  }) =>
      PuzzleGameState(
        puzzle: puzzle ?? this.puzzle,
        cells: cells ?? this.cells,
        sessionId: sessionId ?? this.sessionId,
        selectedRow: clearSelection ? null : (selectedRow ?? this.selectedRow),
        selectedCol: clearSelection ? null : (selectedCol ?? this.selectedCol),
        mistakes: mistakes ?? this.mistakes,
        hintsUsed: hintsUsed ?? this.hintsUsed,
        totalScore: totalScore ?? this.totalScore,
        isComplete: isComplete ?? this.isComplete,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        cellStartTime: cellStartTime ?? this.cellStartTime,
        hintsRevealed: hintsRevealed ?? this.hintsRevealed,
      );
}

class PuzzleGameNotifier extends StateNotifier<PuzzleGameState> {
  PuzzleGameNotifier(this._ref, {required this.mode})
      : super(const PuzzleGameState());

  final Ref _ref;
  final PuzzleMode mode;
  AntiCheatTracker? _antiCheat;

  PuzzleRepository get _repo => _ref.read(puzzleRepositoryProvider);

  Future<void> loadPuzzle({int gridSize = GameConstants.freeGridSize}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final puzzle = mode == PuzzleMode.practice
          ? await _repo.getPracticePuzzle(gridSize: gridSize)
          : await _repo.getDailyPuzzle();

      final cells = <String, PuzzleCell>{};
      for (final cell in puzzle.cells) {
        cells['${cell.row}_${cell.col}'] = cell;
      }

      final sessionId = await _repo.createSession(
        puzzleId: puzzle.id,
        mode: mode,
        gridSize: puzzle.gridSize,
      );

      _antiCheat = AntiCheatTracker(gridSize: puzzle.gridSize);
      _ref.read(analyticsProvider).track('puzzle_started', properties: {
        'mode': mode.name,
        'grid_size': puzzle.gridSize,
      });

      state = state.copyWith(
        puzzle: puzzle,
        cells: cells,
        sessionId: sessionId,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void selectCell(int row, int col) {
    _antiCheat?.recordInteraction();
    state = state.copyWith(
      selectedRow: row,
      selectedCol: col,
      cellStartTime: DateTime.now(),
    );
  }

  void clearSelection() {
    state = state.copyWith(clearSelection: true);
  }

  Future<AnswerResult?> submitAnswer(Player player) async {
    final puzzle = state.puzzle;
    final row = state.selectedRow;
    final col = state.selectedCol;
    if (puzzle == null || row == null || col == null) return null;

    _antiCheat?.recordInteraction();
    final key = '${row}_$col';
    final cell = state.cells[key];
    if (cell == null) return null;

    final rowClub = puzzle.rowClubAt(row);
    final colClub = puzzle.colClubAt(col);

    final result = await _repo.validateAnswer(
      puzzleId: puzzle.id,
      puzzleCellId: cell.id,
      rowClubId: rowClub.id,
      colClubId: colClub.id,
      playerId: player.id,
      sessionId: state.sessionId!,
    );

    await _ref.read(searchRepositoryProvider).recordPick(player);

    if (result.correct) {
      final responseMs = state.cellStartTime != null
          ? DateTime.now().difference(state.cellStartTime!).inMilliseconds
          : 60000;

      final cellScore = ScoringEngine.calculateCellScore(
        usagePercentage: result.usagePercentage,
        responseTimeMs: responseMs,
        mistakesOnCell: 0,
      );

      final updatedCell = cell.copyWith(
        solvedPlayerId: player.id,
        solvedPlayerName: result.playerName,
        isCorrect: true,
        usagePercentage: result.usagePercentage,
        rarityScore: result.rarityScore,
        cellScore: cellScore,
      );

      final newCells = Map<String, PuzzleCell>.from(state.cells);
      newCells[key] = updatedCell;

      final allScores = newCells.values
          .where((c) => c.cellScore != null)
          .map((c) => c.cellScore!)
          .toList();

      final sessionScore = ScoringEngine.calculateSessionScore(
        cellScores: allScores,
        hintsUsed: state.hintsUsed,
      );

      final isComplete = newCells.values.where((c) => c.isSolved).length ==
          puzzle.totalCells;

      state = state.copyWith(
        cells: newCells,
        totalScore: sessionScore,
        isComplete: isComplete,
        clearSelection: true,
      );

      _ref.read(analyticsProvider).track('answer_submitted', properties: {
        'correct': true,
        'rarity_tier': result.rarityTier,
      });

      if (isComplete) await _completeSession();
    } else {
      state = state.copyWith(mistakes: state.mistakes + 1);
      _ref.read(analyticsProvider).track('answer_submitted', properties: {'correct': false});
    }

    return result;
  }

  void addHint(String cellKey, String hint) {
    final hints = Map<String, List<String>>.from(state.hintsRevealed);
    hints.putIfAbsent(cellKey, () => []).add(hint);
    state = state.copyWith(
      hintsUsed: state.hintsUsed + 1,
      hintsRevealed: hints,
    );
  }

  Future<void> _completeSession() async {
    _antiCheat?.evaluate();
    final metadata = _antiCheat?.toMetadata() ?? {};
    await _repo.completeSession(
      sessionId: state.sessionId!,
      finalScore: state.totalScore,
      antiCheatMetadata: metadata,
    );
    _ref.read(analyticsProvider).track('puzzle_completed', properties: {
      'score': state.totalScore,
      'duration_ms': metadata['total_duration_ms'],
      'hints': state.hintsUsed,
    });
  }

  @override
  void dispose() {
    _antiCheat?.dispose();
    super.dispose();
  }
}

final puzzleGameProvider = StateNotifierProvider.family<
    PuzzleGameNotifier, PuzzleGameState, PuzzleMode>(
  (ref, mode) {
    final notifier = PuzzleGameNotifier(ref, mode: mode);
    notifier.loadPuzzle();
    return notifier;
  },
);
