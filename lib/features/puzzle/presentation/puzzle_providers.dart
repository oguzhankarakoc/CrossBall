import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/game_constants.dart';
import '../../../core/utils/anti_cheat_tracker.dart';
import '../../../core/utils/scoring.dart';
import '../../../features/ads/ads_service.dart';
import '../../../features/auth/presentation/auth_providers.dart';
import '../../../features/challenge/domain/challenge.dart';
import '../../search/domain/search.dart';
import '../domain/puzzle.dart';
import '../domain/puzzle_repository.dart';
import '../../../features/premium/premium_service.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/providers/session_providers.dart';

class PuzzleGameParams extends Equatable {
  const PuzzleGameParams({required this.mode, this.challengeId});

  final PuzzleMode mode;
  final String? challengeId;

  @override
  List<Object?> get props => [mode, challengeId];
}

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
    this.challengeId,
    this.challengeCreatorScore,
    this.challengeResult,
    this.startedAt,
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
  final String? challengeId;
  final double? challengeCreatorScore;
  final ChallengeResult? challengeResult;
  final DateTime? startedAt;

  int get solvedCount => cells.values.where((c) => c.isSolved).length;
  int get totalCells => puzzle?.totalCells ?? 0;

  PuzzleCell? get selectedCell {
    if (selectedRow == null || selectedCol == null || puzzle == null) return null;
    return cells['${selectedRow}_$selectedCol'];
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
    String? challengeId,
    double? challengeCreatorScore,
    ChallengeResult? challengeResult,
    DateTime? startedAt,
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
        challengeId: challengeId ?? this.challengeId,
        challengeCreatorScore: challengeCreatorScore ?? this.challengeCreatorScore,
        challengeResult: challengeResult ?? this.challengeResult,
        startedAt: startedAt ?? this.startedAt,
      );
}

class PuzzleGameNotifier extends StateNotifier<PuzzleGameState> {
  PuzzleGameNotifier(this._ref, {required this.params})
      : super(const PuzzleGameState());

  final Ref _ref;
  final PuzzleGameParams params;
  AntiCheatTracker? _antiCheat;

  PuzzleRepository get _repo => _ref.read(puzzleRepositoryProvider);

  Future<void> loadPuzzle({int? gridSize}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final isPremium = _ref.read(isPremiumProvider);
      final size = gridSize ??
          (isPremium ? GameConstants.premiumGridSize : GameConstants.freeGridSize);

      if (params.mode == PuzzleMode.practice && !isPremium) {
        final played = _ref.read(practiceGamesPlayedProvider);
        if (played >= GameConstants.freePracticeLimit) {
          state = state.copyWith(
            isLoading: false,
            error: 'practice_limit_reached',
          );
          return;
        }
      }

      Puzzle puzzle;
      double? creatorScore;
      if (params.mode == PuzzleMode.challenge && params.challengeId != null) {
        final challenge =
            await _ref.read(challengeRepositoryProvider).getChallenge(params.challengeId!);
        puzzle = await _repo.getChallengePuzzle(params.challengeId!);
        creatorScore = challenge.creatorScore;
      } else if (params.mode == PuzzleMode.practice) {
        puzzle = await _repo.getPracticePuzzle(gridSize: size);
      } else {
        puzzle = await _repo.getDailyPuzzle();
      }

      final cells = <String, PuzzleCell>{};
      for (final cell in puzzle.cells) {
        cells['${cell.row}_${cell.col}'] = cell;
      }

      final sessionId = await _repo.createSession(
        puzzleId: puzzle.id,
        mode: params.mode,
        gridSize: puzzle.gridSize,
      );

      _antiCheat = AntiCheatTracker(gridSize: puzzle.gridSize);
      final startedAt = DateTime.now();

      _ref.read(analyticsProvider).track('puzzle_started', properties: {
        'mode': params.mode.name,
        'grid_size': puzzle.gridSize,
        'challenge_id': params.challengeId,
      });

      state = state.copyWith(
        puzzle: puzzle,
        cells: cells,
        sessionId: sessionId,
        isLoading: false,
        challengeId: params.challengeId,
        challengeCreatorScore: creatorScore,
        startedAt: startedAt,
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
    final submitStart = DateTime.now();

    final result = await _repo.validateAnswer(
      puzzleId: puzzle.id,
      puzzleCellId: cell.id,
      rowClubId: rowClub.id,
      colClubId: colClub.id,
      playerId: player.id,
      sessionId: state.sessionId!,
    );

    final latencyMs = DateTime.now().difference(submitStart).inMilliseconds;
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

      final isComplete =
          newCells.values.where((c) => c.isSolved).length == puzzle.totalCells;

      state = state.copyWith(
        cells: newCells,
        totalScore: sessionScore,
        isComplete: isComplete,
        clearSelection: true,
      );

      _ref.read(analyticsProvider).track('answer_submitted', properties: {
        'correct': true,
        'rarity_tier': result.rarityTier,
        'latency_ms': latencyMs,
      });

      if (isComplete) await _completeSession();
    } else {
      state = state.copyWith(mistakes: state.mistakes + 1);
      _ref.read(analyticsProvider).track('answer_submitted', properties: {
        'correct': false,
        'latency_ms': latencyMs,
      });
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

  Future<HintResult?> requestHint(HintType hintType) async {
    final puzzle = state.puzzle;
    final row = state.selectedRow;
    final col = state.selectedCol;
    final sessionId = state.sessionId;
    if (puzzle == null || row == null || col == null || sessionId == null) {
      return null;
    }

    final isPremium = _ref.read(isPremiumProvider);
    final hintsOnCell = state.hintsRevealed['${row}_$col']?.length ?? 0;

    if (hintType == HintType.firstLetter && !isPremium) {
      final rewarded = await _ref.read(adsServiceProvider).showRewarded();
      if (!rewarded) return null;
    } else if (!isPremium) {
      final rewarded = await _ref.read(adsServiceProvider).showRewarded();
      if (!rewarded) return null;
    }

    final key = '${row}_$col';
    final cell = state.cells[key];
    if (cell == null) return null;

    final result = await _repo.requestHint(
      puzzleCellId: cell.id,
      rowClubId: puzzle.rowClubAt(row).id,
      colClubId: puzzle.colClubAt(col).id,
      sessionId: sessionId,
      hintType: hintType,
    );

    addHint(key, result.hintValue);
    _ref.read(analyticsProvider).track('hint_used', properties: {
      'hint_type': hintType.name,
      'ad_watched': !isPremium,
      'hint_index': hintsOnCell + 1,
    });
    return result;
  }

  Future<void> _completeSession() async {
    _antiCheat?.evaluate();
    final metadata = _antiCheat?.toMetadata() ?? {};
    final durationMs = state.startedAt != null
        ? DateTime.now().difference(state.startedAt!).inMilliseconds
        : metadata['total_duration_ms'] as int? ?? 0;

    final profile = await _ref.read(userProfileProvider.future);
    await _repo.completeSession(
      sessionId: state.sessionId!,
      finalScore: state.totalScore,
      antiCheatMetadata: {
        ...metadata,
        'user_uuid': profile.userUuid,
        'mistakes': state.mistakes,
        'hints_used': state.hintsUsed,
        'total_duration_ms': durationMs,
      },
    );

    _ref.read(lastCompletedSessionProvider.notifier).state = CompletedSessionInfo(
      puzzleId: state.puzzle!.id,
      sessionId: state.sessionId!,
      score: state.totalScore,
      mistakes: state.mistakes,
      hintsUsed: state.hintsUsed,
      durationMs: durationMs,
    );

    if (params.mode == PuzzleMode.practice) {
      _ref.read(practiceGamesPlayedProvider.notifier).increment();
      final count = _ref.read(practiceGamesPlayedProvider);
      if (count % GameConstants.interstitialEveryNPractice == 0) {
        await _ref.read(adsServiceProvider).showInterstitial();
        _ref.read(analyticsProvider).track('ad_impression', properties: {
          'placement': 'interstitial_practice',
        });
      }
    } else {
      await _ref.read(adsServiceProvider).showInterstitial();
      _ref.read(analyticsProvider).track('ad_impression', properties: {
        'placement': 'interstitial_complete',
      });
    }

    ChallengeResult? challengeResult;
    if (params.mode == PuzzleMode.challenge && params.challengeId != null) {
      challengeResult = await _ref.read(challengeRepositoryProvider).completeChallenge(
            challengeId: params.challengeId!,
            sessionId: state.sessionId!,
            challengerScore: state.totalScore,
            userUuid: profile.userUuid,
            mistakes: state.mistakes,
            hintsUsed: state.hintsUsed,
            durationMs: durationMs,
          );
      _ref.read(analyticsProvider).track('challenge_completed', properties: {
        'challenge_id': params.challengeId,
        'you_won': challengeResult.youWon,
      });
      state = state.copyWith(challengeResult: challengeResult);
    }

    _ref.read(analyticsProvider).track('puzzle_completed', properties: {
      'score': state.totalScore,
      'duration_ms': durationMs,
      'hints': state.hintsUsed,
      'mode': params.mode.name,
    });
  }

  @override
  void dispose() {
    _antiCheat?.dispose();
    super.dispose();
  }
}

final puzzleGameProvider = StateNotifierProvider.family<
    PuzzleGameNotifier, PuzzleGameState, PuzzleGameParams>(
  (ref, params) {
    final notifier = PuzzleGameNotifier(ref, params: params);
    notifier.loadPuzzle();
    return notifier;
  },
);
