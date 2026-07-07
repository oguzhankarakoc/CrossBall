import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/cache/active_puzzle_cache.dart';
import '../../../core/config/app_config.dart';
import '../../../core/constants/game_constants.dart';
import '../../../core/debug/crossball_debug_log.dart';
import '../../../core/debug/practice_debug_log.dart';
import '../../../core/utils/anti_cheat_tracker.dart';
import '../../../core/utils/scoring.dart';
import '../../../features/ads/ads_service.dart';
import '../../../features/auth/domain/user_profile.dart';
import '../../../features/auth/presentation/auth_providers.dart';
import '../../../features/challenge/domain/challenge.dart';
import '../../search/domain/search.dart';
import '../domain/puzzle.dart';
import '../domain/puzzle_fetch_exception.dart';
import '../domain/puzzle_repository.dart';
import 'daily_puzzle_rollout_provider.dart';
import '../../../features/premium/premium_service.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/providers/practice_session_provider.dart';
import '../../../shared/providers/session_providers.dart';
import '../../../features/economy/presentation/achievement_providers.dart';

class PuzzleGameParams extends Equatable {
  const PuzzleGameParams({required this.mode, this.challengeId, this.gridSize});

  final PuzzleMode mode;
  final String? challengeId;
  final int? gridSize;

  @override
  List<Object?> get props => [mode, challengeId, gridSize];
}

class PuzzleGameState extends Equatable {
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
    this.finishedEarly = false,
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
  final bool finishedEarly;
  final bool isLoading;
  final String? error;
  final DateTime? cellStartTime;
  final Map<String, List<HintResult>> hintsRevealed;
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
    bool? finishedEarly,
    bool? isLoading,
    String? error,
    DateTime? cellStartTime,
    Map<String, List<HintResult>>? hintsRevealed,
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
        finishedEarly: finishedEarly ?? this.finishedEarly,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        cellStartTime: cellStartTime ?? this.cellStartTime,
        hintsRevealed: hintsRevealed ?? this.hintsRevealed,
        challengeId: challengeId ?? this.challengeId,
        challengeCreatorScore: challengeCreatorScore ?? this.challengeCreatorScore,
        challengeResult: challengeResult ?? this.challengeResult,
        startedAt: startedAt ?? this.startedAt,
      );

  @override
  List<Object?> get props => [
        puzzle?.id,
        cells,
        sessionId,
        selectedRow,
        selectedCol,
        mistakes,
        hintsUsed,
        totalScore,
        isComplete,
        finishedEarly,
        isLoading,
        error,
        hintsRevealed,
        challengeResult,
      ];
}

class PuzzleGameNotifier extends StateNotifier<PuzzleGameState> {
  PuzzleGameNotifier(this._ref, {required this.params})
      : super(const PuzzleGameState());

  final Ref _ref;
  final PuzzleGameParams params;
  final _uuid = const Uuid();
  AntiCheatTracker? _antiCheat;
  bool _sessionFinalized = false;

  PuzzleRepository get _repo => _ref.read(puzzleRepositoryProvider);
  ActivePuzzleCache get _activeCache => _ref.read(activePuzzleCacheProvider);

  int get _gridSizeForCache =>
      params.gridSize ?? state.puzzle?.gridSize ?? GameConstants.gridSize;

  String get _todayDate => DateTime.now().toIso8601String().split('T').first;

  Map<String, PuzzleCell> _cellsMapFromPuzzle(Puzzle puzzle) {
    final cells = <String, PuzzleCell>{};
    for (final cell in puzzle.cells) {
      cells['${cell.row}_${cell.col}'] = cell;
    }
    return cells;
  }

  bool _isCachedSnapshotValid(Map<String, dynamic> snapshot) {
    final puzzleJson = snapshot['puzzle'] as Map<String, dynamic>?;
    if (puzzleJson == null) return false;
    if (params.mode == PuzzleMode.daily) {
      return puzzleJson['date'] == _todayDate;
    }
    if (params.mode == PuzzleMode.challenge) {
      return snapshot['challenge_id'] == params.challengeId;
    }
    return true;
  }

  Map<String, PuzzleCell> _mergeCachedCells(
    Map<String, PuzzleCell> base,
    Map<String, dynamic> cachedCells,
  ) {
    final merged = Map<String, PuzzleCell>.from(base);
    for (final entry in cachedCells.entries) {
      final raw = entry.value as Map<String, dynamic>;
      final existing = merged[entry.key];
      if (existing == null) continue;
      merged[entry.key] = existing.copyWith(
        solvedPlayerId: raw['solved_player_id'] as String?,
        solvedPlayerName: raw['solved_player_name'] as String?,
        isCorrect: raw['is_correct'] as bool?,
        usagePercentage: (raw['usage_percentage'] as num?)?.toDouble(),
        rarityScore: (raw['rarity_score'] as num?)?.toDouble(),
        cellScore: (raw['cell_score'] as num?)?.toDouble(),
      );
    }
    return merged;
  }

  Map<String, List<HintResult>> _hintsFromJson(Map<String, dynamic>? raw) {
    if (raw == null) return {};
    final hints = <String, List<HintResult>>{};
    for (final entry in raw.entries) {
      hints[entry.key] = (entry.value as List<dynamic>)
          .map((e) => HintResult.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return hints;
  }

  Map<String, List<HintResult>> _mergeSessionHints(
    Map<String, List<HintResult>> existing,
    List<SessionHintProgress> serverHints,
  ) {
    final merged = existing.map(
      (key, value) => MapEntry(key, List<HintResult>.from(value)),
    );
    for (final progress in serverHints) {
      final key = '${progress.row}_${progress.col}';
      final list = merged.putIfAbsent(key, () => []);
      if (list.any((h) => h.hintType == progress.hint.hintType)) continue;
      list.add(progress.hint);
    }
    for (final key in merged.keys) {
      merged[key]!.sort(
        (a, b) => kHintSequence
            .indexOf(a.hintType)
            .compareTo(kHintSequence.indexOf(b.hintType)),
      );
    }
    return merged;
  }

  Map<String, PuzzleCell> _mergeSessionAnswers(
    Map<String, PuzzleCell> cells,
    List<SessionAnswerProgress> answers,
  ) {
    final merged = Map<String, PuzzleCell>.from(cells);
    for (final answer in answers) {
      final key = '${answer.row}_${answer.col}';
      final cell = merged[key];
      if (cell == null) continue;
      final cellScore = ScoringEngine.calculateCellScore(
        usagePercentage: answer.usagePercentage,
        responseTimeMs: answer.responseTimeMs,
        mistakesOnCell: 0,
      );
      merged[key] = cell.copyWith(
        solvedPlayerId: answer.playerId,
        solvedPlayerName: answer.playerName,
        isCorrect: true,
        usagePercentage: answer.usagePercentage,
        rarityScore: answer.rarityScore,
        cellScore: cellScore,
      );
    }
    return merged;
  }

  Map<String, PuzzleCell> _mergeProgressIntoCells({
    required Map<String, PuzzleCell> baseCells,
    required List<SessionAnswerProgress> serverAnswers,
    required String sessionId,
    required bool sessionResumed,
    Map<String, dynamic>? cachedSnapshot,
  }) {
    var cells = Map<String, PuzzleCell>.from(baseCells);

    if (cachedSnapshot != null) {
      final cachedCells = cachedSnapshot['cells'] as Map<String, dynamic>?;
      if (cachedCells != null) {
        cells = _mergeCachedCells(cells, cachedCells);
      }
    }

    cells = _mergeSessionAnswers(cells, serverAnswers);

    final cachedSessionId = cachedSnapshot?['session_id'] as String?;
    final sameSession = cachedSessionId != null && cachedSessionId == sessionId;

    // Keep locally persisted solves while the session is resumed. Only strip
    // unverified solves when we know the user started a different session.
    if (sameSession || sessionResumed || serverAnswers.isEmpty) {
      return cells;
    }

    final serverKeys = serverAnswers.map((a) => '${a.row}_${a.col}').toSet();
    for (final entry in cells.entries.toList()) {
      final cell = entry.value;
      if (cell.isSolved && !serverKeys.contains(entry.key)) {
        cells[entry.key] = PuzzleCell(
          id: cell.id,
          row: cell.row,
          col: cell.col,
          validAnswerCount: cell.validAnswerCount,
          difficulty: cell.difficulty,
        );
      }
    }
    return cells;
  }

  double _scoreFromCells(Map<String, PuzzleCell> cells, int hintsUsed) {
    final scores = cells.values
        .where((c) => c.cellScore != null)
        .map((c) => c.cellScore!)
        .toList();
    return ScoringEngine.calculateSessionScore(
      cellScores: scores,
      hintsUsed: hintsUsed,
    );
  }

  Future<Map<String, dynamic>?> _loadCachedSnapshot() async {
    return _activeCache.load(
      mode: params.mode,
      challengeId: params.challengeId,
      gridSize: _gridSizeForCache,
    );
  }

  Future<void> _clearCachedSnapshot() async {
    await _activeCache.clear(
      mode: params.mode,
      challengeId: params.challengeId,
      gridSize: _gridSizeForCache,
    );
  }

  Future<void> _persistSnapshot() async {
    final puzzle = state.puzzle;
    final sessionId = state.sessionId;
    if (puzzle == null || sessionId == null || state.isComplete) return;

    final cellsJson = <String, dynamic>{};
    for (final entry in state.cells.entries) {
      final cell = entry.value;
      cellsJson[entry.key] = {
        'solved_player_id': cell.solvedPlayerId,
        'solved_player_name': cell.solvedPlayerName,
        'is_correct': cell.isCorrect,
        'usage_percentage': cell.usagePercentage,
        'rarity_score': cell.rarityScore,
        'cell_score': cell.cellScore,
      };
    }

    final hintsJson = <String, dynamic>{};
    for (final entry in state.hintsRevealed.entries) {
      hintsJson[entry.key] = entry.value.map((h) => h.toJson()).toList();
    }

    await _activeCache.save(
      mode: params.mode,
      challengeId: params.challengeId,
      gridSize: _gridSizeForCache,
      snapshot: {
        'puzzle': puzzle.toJson(),
        'session_id': sessionId,
        'started_at': state.startedAt?.toIso8601String(),
        'cells': cellsJson,
        'hints_revealed': hintsJson,
        'mistakes': state.mistakes,
        'hints_used': state.hintsUsed,
        'total_score': state.totalScore,
        'challenge_id': params.challengeId,
        'challenge_creator_score': state.challengeCreatorScore,
        'saved_at': DateTime.now().toIso8601String(),
      },
    );
  }

  bool get _isTrainingMode =>
      params.mode == PuzzleMode.practice || params.mode == PuzzleMode.timeline;

  Future<void> loadPuzzle({
    int? gridSize,
    bool forceRefresh = false,
    String? excludePuzzleId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    final loadStarted = Stopwatch()..start();
    final logTag = _debugTagForMode(params.mode);
    cbDebug(logTag, 'loadPuzzle start', {
      'mode': params.mode.name,
      'forceRefresh': forceRefresh,
      'gridSize': gridSize ?? params.gridSize ?? GameConstants.gridSize,
      'challengeId': params.challengeId,
      'supabaseConfigured': AppConfig.isSupabaseConfigured,
    });
    try {
      final size = gridSize ?? params.gridSize ?? GameConstants.gridSize;
      UserProfile? profile;
      if (AppConfig.isSupabaseConfigured) {
        profile = await _ref.read(userProfileProvider.future);
      }

      if (_isTrainingMode) {
        if (profile == null) {
          state = state.copyWith(isLoading: false, error: 'practice_load_failed');
          return;
        }
        await _ref.read(practiceSessionProvider.notifier).syncFromServer(profile.userUuid);
        final session = _ref.read(practiceSessionProvider);
        practiceDebug('loadPuzzle practice gate', {
          'isPremium': session.isPremium,
          'gridSize': size,
          'completedToday': session.completedToday,
          'remaining': session.remaining,
          'dailyLimit': session.dailyLimit,
          'adUnlockGranted': session.adUnlockGranted,
          'forceRefresh': forceRefresh,
          'excludePuzzleId': excludePuzzleId,
        });

        if (session.hasReachedLimit) {
          practiceDebug('blocked: daily limit reached');
          state = state.copyWith(
            isLoading: false,
            error: 'practice_limit_reached',
          );
          return;
        }
        if (size > GameConstants.freeGridSize && !session.isPremium) {
          practiceDebug('blocked: premium grid required');
          state = state.copyWith(
            isLoading: false,
            error: 'premium_grid_required',
          );
          return;
        }
        if (session.needsRewardedAdForNextSession) {
          practiceDebug('blocked: rewarded ad required');
          state = state.copyWith(
            isLoading: false,
            error: 'practice_ad_required',
          );
          return;
        }
      }

      Puzzle puzzle;
      double? creatorScore;
      Map<String, dynamic>? cachedSnapshot;
      if (!forceRefresh) {
        cachedSnapshot = await _loadCachedSnapshot();
        if (cachedSnapshot != null && !_isCachedSnapshotValid(cachedSnapshot)) {
          cachedSnapshot = null;
          await _clearCachedSnapshot();
        }
      } else {
        await _clearCachedSnapshot();
      }

      if (params.mode == PuzzleMode.challenge && params.challengeId != null) {
        final challenge =
            await _ref.read(challengeRepositoryProvider).getChallenge(params.challengeId!);
        if (cachedSnapshot != null && !forceRefresh) {
          puzzle = Puzzle.fromJson(cachedSnapshot['puzzle'] as Map<String, dynamic>);
        } else {
          puzzle = await _repo.getChallengePuzzle(params.challengeId!);
        }
        creatorScore = challenge.creatorScore;
      } else if (_isTrainingMode) {
        if (cachedSnapshot != null && !forceRefresh) {
          puzzle = Puzzle.fromJson(cachedSnapshot['puzzle'] as Map<String, dynamic>);
          practiceDebug('resuming cached practice puzzle', {
            'puzzleId': puzzle.id,
            'gridSize': puzzle.gridSize,
          });
        } else {
          final excludeId = excludePuzzleId ?? (forceRefresh ? state.puzzle?.id : null);
          puzzle = await _repo.getPracticePuzzle(
            gridSize: size,
            userUuid: profile!.userUuid,
            excludePuzzleId: excludeId,
          );
          practiceDebug('practice puzzle loaded', {
            'puzzleId': puzzle.id,
            'gridSize': puzzle.gridSize,
            'rowClubs': puzzle.rowClubs.map((c) => c.shortLabel).toList(),
            'colClubs': puzzle.colClubs.map((c) => c.shortLabel).toList(),
          });
        }
      } else {
        if (cachedSnapshot != null && !forceRefresh) {
          puzzle = Puzzle.fromJson(cachedSnapshot['puzzle'] as Map<String, dynamic>);
          cbDebug('Daily', 'resuming cached daily puzzle', {
            'puzzleId': puzzle.id,
            'date': puzzle.date,
          });
        } else {
          cbDebug('Daily', 'fetching daily puzzle', {'userUuid': profile?.userUuid});
          puzzle = await _repo.getDailyPuzzle(
            forceRefresh: forceRefresh,
            userUuid: profile?.userUuid,
          );
          cbDebug('Daily', 'daily puzzle loaded', {
            'puzzleId': puzzle.id,
            'date': puzzle.date,
            'rowClubs': puzzle.rowClubs.map((c) => c.shortLabel).toList(),
            'colClubs': puzzle.colClubs.map((c) => c.shortLabel).toList(),
          });
        }
      }

      var cells = _cellsMapFromPuzzle(puzzle);
      var hintsRevealed = <String, List<HintResult>>{};
      var mistakes = 0;
      var hintsUsed = 0;
      var totalScore = 0.0;

      if (cachedSnapshot != null) {
        hintsRevealed = _hintsFromJson(
          cachedSnapshot['hints_revealed'] as Map<String, dynamic>?,
        );
        mistakes = cachedSnapshot['mistakes'] as int? ?? 0;
        hintsUsed = cachedSnapshot['hints_used'] as int? ?? 0;
        totalScore = (cachedSnapshot['total_score'] as num?)?.toDouble() ?? 0;
      }

      cbDebug(logTag, 'creating session', {
        'puzzleId': puzzle.id,
        'mode': params.mode.name,
        'userUuid': profile?.userUuid,
      });
      final session = await _repo.createSession(
        puzzleId: puzzle.id,
        mode: params.mode,
        gridSize: puzzle.gridSize,
        userUuid: profile?.userUuid,
      );

      cells = _mergeProgressIntoCells(
        baseCells: cells,
        serverAnswers: session.answers,
        sessionId: session.sessionId,
        sessionResumed: session.resumed,
        cachedSnapshot: cachedSnapshot,
      );
      hintsRevealed = _mergeSessionHints(hintsRevealed, session.hints);
      hintsUsed = hintsRevealed.values.fold<int>(0, (sum, list) => sum + list.length);
      mistakes = session.mistakes > mistakes ? session.mistakes : mistakes;
      totalScore = _scoreFromCells(cells, hintsUsed);

      final startedAt = session.startedAt;
      final isComplete = _isTrainingMode
          ? false
          : cells.values.where((c) => c.isSolved).length == puzzle.totalCells;

      _antiCheat = AntiCheatTracker(
        gridSize: puzzle.gridSize,
        serverStartedAt: startedAt,
      );

      _ref.read(analyticsProvider).track('puzzle_started', properties: {
        'mode': params.mode.name,
        'grid_size': puzzle.gridSize,
        'challenge_id': params.challengeId,
        'resumed': session.resumed,
      });

      state = state.copyWith(
        puzzle: puzzle,
        cells: cells,
        sessionId: session.sessionId,
        isLoading: false,
        challengeId: params.challengeId,
        challengeCreatorScore: creatorScore,
        startedAt: startedAt,
        hintsRevealed: hintsRevealed,
        hintsUsed: hintsUsed,
        mistakes: mistakes,
        totalScore: totalScore,
        isComplete: isComplete,
      );
      if (isComplete) {
        await _completeSession();
        return;
      }
      await _persistSnapshot();
      if (_isTrainingMode) {
        practiceDebug('loadPuzzle success', {
          'elapsedMs': loadStarted.elapsedMilliseconds,
          'sessionId': session.sessionId,
          'resumed': session.resumed,
        });
      } else {
        cbDebug(logTag, 'loadPuzzle success', {
          'elapsedMs': loadStarted.elapsedMilliseconds,
          'sessionId': session.sessionId,
          'puzzleId': puzzle.id,
          'resumed': session.resumed,
        });
      }
    } catch (e, st) {
      if (_isTrainingMode) {
        practiceDebugError(
          'loadPuzzle failed after ${loadStarted.elapsedMilliseconds}ms',
          e,
          st,
        );
        if (e is PuzzleFetchException) {
          practiceDebug('PuzzleFetchException detail', {
            'message': e.message,
            'statusCode': e.statusCode,
          });
        }
      } else {
        cbDebugError(
          logTag,
          'loadPuzzle failed after ${loadStarted.elapsedMilliseconds}ms',
          e,
          st,
        );
        if (e is PuzzleFetchException) {
          cbDebug(logTag, 'PuzzleFetchException detail', {
            'message': e.message,
            'statusCode': e.statusCode,
            'errorCode': e.errorCode,
          });
        }
        if (!_isTrainingMode &&
            e is PuzzleFetchException &&
            (e.isGenerationInProgress || e.isGenerationFailed)) {
          _ref.invalidate(dailyPuzzleRolloutProvider);
        }
      }
      final message = e is PuzzleFetchException
          ? (_isTrainingMode
              ? 'practice_load_failed'
              : e.isGenerationInProgress
                  ? 'daily_puzzle_generating'
                  : e.isGenerationFailed
                      ? 'daily_puzzle_failed'
                      : 'puzzle_load_failed')
          : e.toString();
      cbDebug(logTag, 'loadPuzzle UI error key', {'errorKey': message});
      state = state.copyWith(isLoading: false, error: message);
    }
  }

  String _debugTagForMode(PuzzleMode mode) => switch (mode) {
        PuzzleMode.daily => 'Daily',
        PuzzleMode.practice => 'Practice',
        PuzzleMode.timeline => 'Practice',
        PuzzleMode.challenge => 'Challenge',
      };

  Future<void> startNewPracticeSession() async {
    _sessionFinalized = false;
    final previousId = state.puzzle?.id;
    await _clearCachedSnapshot();
    state = const PuzzleGameState(isLoading: true);
    await loadPuzzle(forceRefresh: true, excludePuzzleId: previousId);
  }

  Future<void> finishPractice() async {
    if (!_isTrainingMode) return;
    if (state.isComplete || _sessionFinalized) return;
    if (state.puzzle == null || state.sessionId == null) return;

    practiceDebug('finishPractice early', {
      'solved': state.solvedCount,
      'total': state.totalCells,
      'score': state.totalScore,
    });

    state = state.copyWith(isComplete: true, finishedEarly: true);
    await _completeSession();
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
    final profile = await _ref.read(userProfileProvider.future);
    final responseMs = state.cellStartTime != null
        ? DateTime.now().difference(state.cellStartTime!).inMilliseconds
        : 60000;

    final result = await _repo.validateAnswer(
      puzzleId: puzzle.id,
      puzzleCellId: cell.id,
      rowClubId: rowClub.id,
      colClubId: colClub.id,
      playerId: player.id,
      sessionId: state.sessionId!,
      userUuid: profile.userUuid,
      responseTimeMs: responseMs,
    );

    final latencyMs = DateTime.now().difference(submitStart).inMilliseconds;
    await _ref.read(searchRepositoryProvider).recordPick(player);

    if (result.correct) {
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

      final allSolved =
          newCells.values.where((c) => c.isSolved).length == puzzle.totalCells;
      final isComplete = allSolved && !_isTrainingMode;

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

      if (isComplete) {
        await _completeSession();
      } else {
        await _persistSnapshot();
      }
    } else {
      state = state.copyWith(mistakes: state.mistakes + 1);
      await _persistSnapshot();
      _ref.read(analyticsProvider).track('answer_submitted', properties: {
        'correct': false,
        'latency_ms': latencyMs,
      });
    }

    return result;
  }

  void addHint(String cellKey, HintResult hint) {
    final hints = Map<String, List<HintResult>>.from(state.hintsRevealed);
    hints.putIfAbsent(cellKey, () => []).add(hint);
    state = state.copyWith(
      hintsUsed: state.hintsUsed + 1,
      hintsRevealed: hints,
    );
    unawaited(_persistSnapshot());
  }

  Future<HintResult?> requestHint([HintType? requestedType]) async {
    final puzzle = state.puzzle;
    final row = state.selectedRow;
    final col = state.selectedCol;
    final sessionId = state.sessionId;
    if (puzzle == null || row == null || col == null || sessionId == null) {
      return null;
    }

    final isPremium = _ref.read(isPremiumProvider);
    final profile = await _ref.read(userProfileProvider.future);

    String? adToken;
    if (!isPremium) {
      final rewarded = await _ref.read(adsServiceProvider).showRewarded();
      if (!rewarded) return null;
      adToken = _uuid.v4();
      if (AppConfig.isSupabaseConfigured) {
        final granted = await _repo.grantHintAdToken(
          userUuid: profile.userUuid,
          adToken: adToken,
          sessionId: sessionId,
        );
        if (!granted) return null;
      }
    }

    final key = '${row}_$col';
    final hintsOnCell = state.hintsRevealed[key]?.length ?? 0;
    final hintType = requestedType ?? nextHintTypeForCount(hintsOnCell);
    if (hintType == null) return null;
    final cell = state.cells[key];
    if (cell == null) return null;

    final result = await _repo.requestHint(
      puzzleCellId: cell.id,
      rowClubId: puzzle.rowClubAt(row).id,
      colClubId: puzzle.colClubAt(col).id,
      sessionId: sessionId,
      hintType: hintType,
      userUuid: profile.userUuid,
      adToken: adToken,
    );

    addHint(key, result);
    _ref.read(analyticsProvider).track('hint_used', properties: {
      'hint_type': result.hintType.name,
      'ad_watched': !isPremium,
      'hint_index': hintsOnCell + 1,
    });
    return result;
  }

  Future<void> _completeSession() async {
    if (_sessionFinalized) return;
    _sessionFinalized = true;

    _antiCheat?.evaluate();
    final metadata = _antiCheat?.toMetadata() ?? {};
    final durationMs = state.startedAt != null
        ? DateTime.now().difference(state.startedAt!).inMilliseconds
        : metadata['total_duration_ms'] as int? ?? 0;

    final profile = await _ref.read(userProfileProvider.future);
    final puzzle = state.puzzle!;

    Set<String> priorAchievementSlugs = {};
    try {
      final prior = await _ref.read(playerProgressionProvider.future);
      priorAchievementSlugs = prior.achievements.map((a) => a.slug).toSet();
    } catch (_) {}

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

    await _repo.completeSession(
      sessionId: state.sessionId!,
      finalScore: state.totalScore,
      antiCheatMetadata: {
        ...metadata,
        'user_uuid': profile.userUuid,
        'mode': params.mode.name,
        'finished_early': state.finishedEarly,
        if (params.mode == PuzzleMode.challenge && challengeResult != null)
          'challenge_won': challengeResult.youWon,
      },
    );

    _ref.invalidate(playerProgressionProvider);
    _ref.invalidate(playerMissionsProvider);
    _ref.invalidate(userStatsProvider);

    try {
      final updated = await _ref.read(playerProgressionProvider.future);
      final unlocked = updated.achievements
          .where((a) => !priorAchievementSlugs.contains(a.slug))
          .toList();
      if (unlocked.isNotEmpty) {
        _ref.read(newlyUnlockedAchievementsProvider.notifier).state = unlocked;
      }
    } catch (_) {}

    _ref.read(lastCompletedSessionProvider.notifier).state = CompletedSessionInfo(
      puzzleId: puzzle.id,
      sessionId: state.sessionId!,
      score: state.totalScore,
      mistakes: state.mistakes,
      hintsUsed: state.hintsUsed,
      durationMs: durationMs,
      mode: params.mode.name,
    );

    if (_isTrainingMode) {
      await _ref.read(practiceSessionProvider.notifier).onPracticeSessionCompleted(profile.userUuid);
      _ref.read(analyticsProvider).track('practice_session_completed', properties: {
        'completed_today': _ref.read(practiceSessionProvider).completedToday,
        'finished_early': state.finishedEarly,
        'cells_solved': state.solvedCount,
        'mode': params.mode.name,
      });
    } else {
      await _ref.read(adsServiceProvider).showInterstitial();
      _ref.read(analyticsProvider).track('ad_impression', properties: {
        'placement': 'interstitial_complete',
      });
    }

    _ref.read(analyticsProvider).track('puzzle_completed', properties: {
      'score': state.totalScore,
      'duration_ms': durationMs,
      'hints': state.hintsUsed,
      'mode': params.mode.name,
    });

    await _clearCachedSnapshot();
  }

  @override
  void dispose() {
    if (state.puzzle != null &&
        state.sessionId != null &&
        !state.isComplete &&
        !state.isLoading) {
      unawaited(_persistSnapshot());
    }
    _antiCheat?.dispose();
    super.dispose();
  }
}

final puzzleGameProvider = StateNotifierProvider.autoDispose.family<
    PuzzleGameNotifier, PuzzleGameState, PuzzleGameParams>(
  (ref, params) {
    final notifier = PuzzleGameNotifier(ref, params: params);
    notifier.loadPuzzle(gridSize: params.gridSize);
    return notifier;
  },
);
