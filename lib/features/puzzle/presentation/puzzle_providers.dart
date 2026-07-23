import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/cache/active_puzzle_cache.dart';
import '../../../core/config/app_config.dart';
import '../../../core/constants/game_constants.dart';
import '../../../core/daily/daily_puzzle_contract.dart';
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
import '../../../features/stats/domain/stats.dart';

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
    this.validatingCellKey,
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
  final String? validatingCellKey;

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
    String? validatingCellKey,
    bool clearValidatingCell = false,
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
        validatingCellKey:
            clearValidatingCell ? null : (validatingCellKey ?? this.validatingCellKey),
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
        validatingCellKey,
      ];
}

class PuzzleGameNotifier extends StateNotifier<PuzzleGameState> {
  PuzzleGameNotifier(this._ref, {required this.params})
      : super(const PuzzleGameState());

  final Ref _ref;
  final PuzzleGameParams params;
  final _uuid = const Uuid();
  static final _cellIdPattern = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );
  AntiCheatTracker? _antiCheat;
  bool _sessionFinalized = false;

  bool _cellsNeedHydration(Puzzle puzzle) {
    if (!AppConfig.isSupabaseConfigured) return false;
    if (puzzle.cells.isEmpty) return true;
    return puzzle.cells.any((cell) => !_cellIdPattern.hasMatch(cell.id));
  }

  String? _resolvePuzzleCellId({
    required Puzzle puzzle,
    required int row,
    required int col,
    required PuzzleCell cell,
  }) {
    final canonical = puzzle.cellAt(row, col);
    if (canonical != null && _cellIdPattern.hasMatch(canonical.id)) {
      return canonical.id;
    }
    if (_cellIdPattern.hasMatch(cell.id)) return cell.id;
    return null;
  }

  Map<String, PuzzleCell> _syncCellIdsFromPuzzle(
    Map<String, PuzzleCell> cells,
    Puzzle puzzle,
  ) {
    final synced = Map<String, PuzzleCell>.from(cells);
    for (final cell in puzzle.cells) {
      final key = '${cell.row}_${cell.col}';
      final existing = synced[key];
      if (existing != null && existing.id != cell.id) {
        synced[key] = existing.copyWith(id: cell.id);
      }
    }
    return synced;
  }

  bool _cellsDifferFromPuzzle(Map<String, PuzzleCell> cells, Puzzle puzzle) {
    for (final cell in puzzle.cells) {
      final key = '${cell.row}_${cell.col}';
      final stateCell = cells[key];
      if (stateCell == null || stateCell.id != cell.id) return true;
    }
    return false;
  }

  Future<PuzzleCell?> _ensureCellReady({
    required String key,
    required int row,
    required int col,
  }) async {
    final puzzle = state.puzzle;
    if (puzzle == null) return null;
    final cached = state.cells[key];
    if (cached == null) return null;

    final canonical = puzzle.cellAt(row, col);
    if (canonical != null && canonical.id != cached.id) {
      cbDebug('Session', 'syncing stale cell id before request', {
        'key': key,
        'cachedCellId': cached.id,
        'canonicalCellId': canonical.id,
        'puzzleId': puzzle.id,
      });
      final synced = cached.copyWith(id: canonical.id);
      state = state.copyWith(
        cells: {...state.cells, key: synced},
      );
      return synced;
    }
    return cached;
  }

  Map<String, PuzzleCell> _mergeCellsPreservingProgress(
    Map<String, PuzzleCell> refreshedCells,
  ) {
    final merged = Map<String, PuzzleCell>.from(refreshedCells);
    for (final entry in state.cells.entries) {
      final existing = merged[entry.key];
      if (existing == null) continue;
      merged[entry.key] = existing.copyWith(
        solvedPlayerId: entry.value.solvedPlayerId,
        solvedPlayerName: entry.value.solvedPlayerName,
        isCorrect: entry.value.isCorrect,
        usagePercentage: entry.value.usagePercentage,
        rarityScore: entry.value.rarityScore,
        cellScore: entry.value.cellScore,
      );
    }
    return merged;
  }

  Future<bool> _refreshCellsFromServer() async {
    final puzzle = state.puzzle;
    if (puzzle == null || !AppConfig.isSupabaseConfigured) return false;

    final oldIds = puzzle.cells.map((cell) => cell.id).toList();
    cbDebug('Session', 'force-refreshing puzzle cells after cell_not_found', {
      'puzzleId': puzzle.id,
      'oldCellIds': oldIds,
    });

    try {
      final profile = await _ref.read(userProfileProvider.future);
      Puzzle synced;
      if (params.mode == PuzzleMode.daily) {
        await _repo.clearDailyPuzzleCache();
        synced = await _repo.getDailyPuzzle(
          forceRefresh: true,
          userUuid: profile.userUuid,
        );
      } else {
        synced = await _repo.hydratePuzzleCells(puzzle);
      }

      if (synced.cells.isEmpty) {
        cbDebugError('Session', 'cell refresh returned no cells', {
          'puzzleId': puzzle.id,
        });
        return false;
      }

      final newIds = synced.cells.map((cell) => cell.id).toList();
      final refreshedCells = _cellsMapFromPuzzle(synced);
      final needsSync = oldIds.join(',') != newIds.join(',') ||
          _cellsDifferFromPuzzle(state.cells, synced);
      if (!needsSync) {
        cbDebugError('Session', 'cell ids unchanged after refresh', {
          'puzzleId': puzzle.id,
          'cellIds': newIds,
        });
        return false;
      }

      final merged = _mergeCellsPreservingProgress(refreshedCells);
      state = state.copyWith(
        puzzle: Puzzle(
          id: synced.id,
          date: synced.date,
          gridSize: synced.gridSize,
          rowClubs: synced.rowClubs,
          colClubs: synced.colClubs,
          cells: synced.cells,
          mode: puzzle.mode,
          difficulty: synced.difficulty,
          difficultyTier: synced.difficultyTier,
          qualityScore: synced.qualityScore,
          puzzleHash: synced.puzzleHash,
        ),
        cells: merged,
      );
      unawaited(_persistSnapshot());

      cbDebug('Session', 'puzzle cells refreshed', {
        'puzzleId': synced.id,
        'newCellIds': newIds,
      });
      return true;
    } catch (e, st) {
      cbDebugError('Session', 'cell refresh failed', e, st);
      return false;
    }
  }

  bool _isCellNotFoundError(Object error) {
    if (error is PuzzleFetchException) {
      final code = error.errorCode ?? error.message;
      return code.contains('cell_not_found');
    }
    if (error is HintRequestException) {
      final code = error.errorCode ?? error.message;
      return code.contains('cell_not_found');
    }
    return false;
  }

  PuzzleRepository get _repo => _ref.read(puzzleRepositoryProvider);
  ActivePuzzleCache get _activeCache => _ref.read(activePuzzleCacheProvider);

  int get _gridSizeForCache =>
      params.gridSize ?? state.puzzle?.gridSize ?? GameConstants.gridSize;

  Map<String, PuzzleCell> _cellsMapFromPuzzle(Puzzle puzzle) {
    final cells = <String, PuzzleCell>{};
    for (final cell in puzzle.cells) {
      cells['${cell.row}_${cell.col}'] = cell;
    }
    return cells;
  }

  bool _isCachedSnapshotValid(Map<String, dynamic> snapshot) {
    if (params.mode == PuzzleMode.daily) {
      return DailyPuzzleContract.isSnapshotForToday(snapshot);
    }
    final puzzleJson = snapshot['puzzle'] as Map<String, dynamic>?;
    if (puzzleJson == null) return false;
    if (params.mode == PuzzleMode.challenge) {
      return snapshot['challenge_id'] == params.challengeId;
    }
    if (_isTrainingMode) {
      final cachedUsageDate = snapshot['usage_date'] as String?;
      final quotaDate = _ref.read(practiceSessionProvider).dateKey;
      if (cachedUsageDate != null &&
          quotaDate.isNotEmpty &&
          cachedUsageDate != quotaDate) {
        return false;
      }
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

  bool _isStaleDemoHintSet(List<HintResult> hints) {
    if (hints.length != kHintSequence.length) return false;
    const staleValues = [
      'Brazil',
      'Midfielder',
      'D _ _ _',
      'Premier League',
      'Active',
      'Arsenal',
    ];
    for (var i = 0; i < hints.length; i++) {
      if (hints[i].hintType != kHintSequence[i]) return false;
      if (hints[i].hintValue != staleValues[i]) return false;
    }
    return true;
  }

  Map<String, List<HintResult>> _stripStaleDemoHints(
    Map<String, List<HintResult>> hints,
  ) {
    if (!AppConfig.isSupabaseConfigured) return hints;
    final cleaned = <String, List<HintResult>>{};
    for (final entry in hints.entries) {
      if (_isStaleDemoHintSet(entry.value)) continue;
      cleaned[entry.key] = entry.value;
    }
    return cleaned;
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

  double _scoreFromCells(
    Map<String, PuzzleCell> cells,
    int hintsUsed, {
    required int mistakes,
    required int totalCells,
    required bool applyCompletionBonus,
  }) {
    final scores = cells.values
        .where((c) => c.cellScore != null)
        .map((c) => c.cellScore!)
        .toList();
    final fullGrid = cells.values.where((c) => c.isSolved).length >= totalCells;
    final completionBonus = applyCompletionBonus
        ? ScoringEngine.completionBonusForMode(
            params.mode.name,
            fullGrid: fullGrid,
          )
        : 0;
    return ScoringEngine.calculateSessionScore(
      cellScores: scores,
      hintsUsed: hintsUsed,
      mistakes: mistakes,
      completionBonus: completionBonus,
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

    final usageDate = _isTrainingMode
        ? _ref.read(practiceSessionProvider).dateKey
        : null;

    await _activeCache.save(
      mode: params.mode,
      challengeId: params.challengeId,
      gridSize: _gridSizeForCache,
      snapshot: {
        'puzzle': puzzle.toJson(),
        if (params.mode == PuzzleMode.daily)
          ...DailyPuzzleContract.snapshotMetadataFor(puzzle),
        if (usageDate != null && usageDate.isNotEmpty) 'usage_date': usageDate,
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

  bool get _isTrainingMode => params.mode.isTraining;

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

      if (params.mode == PuzzleMode.daily &&
          profile != null &&
          AppConfig.isSupabaseConfigured) {
        final dailyStore = _ref.read(dailyCompletionStoreProvider);
        if (await dailyStore.isCompletedToday(userUuid: profile.userUuid)) {
          await _clearCachedSnapshot();
          state = state.copyWith(isLoading: false, error: 'daily_already_completed');
          return;
        }
        _ref.invalidate(userStatsProvider);
        // Stats + rollout in parallel — both are network gates before grid load.
        late final UserStats stats;
        late final DailyPuzzleRolloutStatus rollout;
        try {
          final results = await Future.wait([
            _ref.read(userStatsProvider.future),
            _ref.read(dailyPuzzleRolloutProvider.future),
          ]);
          stats = results[0] as UserStats;
          rollout = results[1] as DailyPuzzleRolloutStatus;
        } catch (e, st) {
          cbDebugError('Daily', 'stats/rollout pre-check failed — blocking daily load', e, st);
          state = state.copyWith(isLoading: false, error: 'puzzle_load_failed');
          return;
        }
        if (stats.dailyCompletedToday) {
          await dailyStore.markCompletedToday(
            userUuid: profile.userUuid,
            score: stats.todayDailyScore > 0 ? stats.todayDailyScore : null,
          );
          await _clearCachedSnapshot();
          state = state.copyWith(isLoading: false, error: 'daily_already_completed');
          return;
        }

        // Gate: never play a stale grid while today's puzzle is still rolling out.
        if (DailyPuzzleContract.shouldBlockLoad(rollout)) {
          cbDebug('Daily', 'blocked by rollout gate', {
            'phase': rollout.phase.name,
            'puzzleDate': rollout.puzzleDate,
            'todayUtc': DailyPuzzleContract.todayUtc,
          });
          await _clearCachedSnapshot();
          await _repo.clearDailyPuzzleCache();
          state = state.copyWith(
            isLoading: false,
            error: DailyPuzzleContract.errorKeyForRollout(rollout),
          );
          return;
        }
      }

      if (_isTrainingMode) {
        if (profile == null) {
          state = state.copyWith(isLoading: false, error: 'practice_load_failed');
          return;
        }
        await _ref.read(practiceSessionProvider.notifier).syncFromServer(profile.userUuid);
        final session = _ref.read(practiceSessionProvider);
        if (session.syncError != null) {
          practiceDebug('blocked: quota sync failed', {'error': session.syncError});
          state = state.copyWith(isLoading: false, error: 'practice_load_failed');
          return;
        }
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
          cbDebug('Daily', 'resuming session — force network refresh for cell ids', {
            'puzzleId': (cachedSnapshot['puzzle'] as Map<String, dynamic>?)?['puzzle_id'],
          });
          await _repo.clearDailyPuzzleCache();
          puzzle = await _repo.getDailyPuzzle(
            forceRefresh: true,
            userUuid: profile?.userUuid,
          );
          cbDebug('Daily', 'daily puzzle refreshed for resumed session', {
            'puzzleId': puzzle.id,
            'date': puzzle.date,
            'cellIds': puzzle.cells.map((c) => c.id).toList(),
            'rowClubs': puzzle.rowClubs.map((c) => c.shortLabel).toList(),
            'colClubs': puzzle.colClubs.map((c) => c.shortLabel).toList(),
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

      if (_cellsNeedHydration(puzzle)) {
        puzzle = await _repo.hydratePuzzleCells(puzzle);
        if (puzzle.cells.isEmpty) {
          cbDebugError(logTag, 'puzzle has no cells after server sync', {
            'puzzleId': puzzle.id,
          });
        } else if (_cellsNeedHydration(puzzle)) {
          cbDebugError(logTag, 'puzzle cells still invalid after hydration', {
            'puzzleId': puzzle.id,
            'cellIds': puzzle.cells.map((c) => c.id).toList(),
          });
        }
      } else {
        cbDebug(logTag, 'puzzle cells ready — skip hydrate', {
          'puzzleId': puzzle.id,
          'cellCount': puzzle.cells.length,
        });
      }

      var cells = _cellsMapFromPuzzle(puzzle);
      var hintsRevealed = <String, List<HintResult>>{};
      var mistakes = 0;
      var hintsUsed = 0;
      var totalScore = 0.0;
      var forceNewSession = false;

      if (cachedSnapshot != null && params.mode == PuzzleMode.daily) {
        final cachedPuzzleJson =
            cachedSnapshot['puzzle'] as Map<String, dynamic>?;
        if (cachedPuzzleJson != null) {
          final cachedPuzzle = Puzzle.fromJson(cachedPuzzleJson);
          final cachedFingerprint =
              cachedSnapshot['layout_fingerprint'] as String? ??
                  cachedPuzzle.layoutFingerprint;
          if (cachedFingerprint != puzzle.layoutFingerprint ||
              cachedPuzzle.id != puzzle.id) {
            cbDebug('Daily', 'puzzle layout changed — resetting session', {
              'puzzleId': puzzle.id,
              'cachedFingerprint': cachedFingerprint,
              'freshFingerprint': puzzle.layoutFingerprint,
              'cachedRowClubs': cachedPuzzle.rowClubs.map((c) => c.shortLabel).toList(),
              'freshRowClubs': puzzle.rowClubs.map((c) => c.shortLabel).toList(),
              'cachedColClubs': cachedPuzzle.colClubs.map((c) => c.shortLabel).toList(),
              'freshColClubs': puzzle.colClubs.map((c) => c.shortLabel).toList(),
            });
            forceNewSession = true;
            cachedSnapshot = null;
            await _clearCachedSnapshot();
          }
        }
      }

      if (cachedSnapshot != null) {
        hintsRevealed = _stripStaleDemoHints(
          _hintsFromJson(
            cachedSnapshot['hints_revealed'] as Map<String, dynamic>?,
          ),
        );
        mistakes = cachedSnapshot['mistakes'] as int? ?? 0;
        hintsUsed = cachedSnapshot['hints_used'] as int? ?? 0;
        totalScore = (cachedSnapshot['total_score'] as num?)?.toDouble() ?? 0;
      }

      cbDebug(logTag, 'creating session', {
        'puzzleId': puzzle.id,
        'mode': params.mode.name,
        'userUuid': profile?.userUuid,
        'forceNew': forceNewSession,
      });
      final session = await _repo.createSession(
        puzzleId: puzzle.id,
        mode: params.mode,
        gridSize: puzzle.gridSize,
        userUuid: profile?.userUuid,
        forceNew: forceNewSession,
      );

      cells = _syncCellIdsFromPuzzle(
        _mergeProgressIntoCells(
          baseCells: cells,
          serverAnswers: session.answers,
          sessionId: session.sessionId,
          sessionResumed: session.resumed,
          cachedSnapshot: cachedSnapshot,
        ),
        puzzle,
      );
      hintsRevealed = _mergeSessionHints(hintsRevealed, session.hints);
      hintsUsed = hintsRevealed.values.fold<int>(0, (sum, list) => sum + list.length);
      mistakes = session.mistakes > mistakes ? session.mistakes : mistakes;
      totalScore = _scoreFromCells(
        cells,
        hintsUsed,
        mistakes: mistakes,
        totalCells: puzzle.totalCells,
        applyCompletionBonus: true,
      );

      final startedAt = session.startedAt;
      // Full grid → complete for all modes (incl. practice/timeline/quick grid).
      // Previously training forced isComplete=false so 9/9 stayed live until
      // manual "Finish" — bad UX and felt like a stuck session.
      final isComplete =
          cells.values.where((c) => c.isSolved).length == puzzle.totalCells;

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
              : e.isDailyAlreadyCompleted
                  ? 'daily_already_completed'
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
        PuzzleMode.quickGrid => 'QuickGrid',
        PuzzleMode.matchGrid => 'MatchGrid',
        PuzzleMode.challenge => 'Challenge',
      };

  int _quickGridRemainingMs() {
    final started = state.startedAt;
    final durationSec = params.mode == PuzzleMode.matchGrid
        ? GameConstants.matchGridDurationSec
        : GameConstants.quickGridDurationSec;
    if (started == null) return durationSec * 1000;
    final elapsed = DateTime.now().difference(started).inMilliseconds;
    final total = durationSec * 1000;
    return (total - elapsed).clamp(0, total);
  }

  /// Called when Quick/Match Grid countdown hits zero.
  Future<void> onQuickGridTimeUp() async {
    if (!params.mode.isTimedTraining) return;
    if (state.isComplete || _sessionFinalized) return;
    state = state.copyWith(isComplete: true, finishedEarly: true);
    await _completeSession();
  }

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
    final row = state.selectedRow;
    final col = state.selectedCol;
    if (state.puzzle == null || row == null || col == null) return null;

    _antiCheat?.recordInteraction();
    final key = '${row}_$col';
    final cell = await _ensureCellReady(key: key, row: row, col: col);
    if (cell == null) return null;

    final puzzle = state.puzzle!;
    final puzzleCellId = _resolvePuzzleCellId(
      puzzle: puzzle,
      row: row,
      col: col,
      cell: cell,
    );
    if (puzzleCellId == null) {
      cbDebugError('Session', 'invalid puzzle cell id for answer', {
        'cellId': cell.id,
        'row': row,
        'col': col,
        'puzzleId': puzzle.id,
      });
      throw const PuzzleFetchException(
        'cell_not_found',
        errorCode: 'cell_not_found',
      );
    }

    state = state.copyWith(validatingCellKey: key, clearSelection: true);

    final rowClub = puzzle.rowClubAt(row);
    final colClub = puzzle.colClubAt(col);
    final submitStart = DateTime.now();
    final profile = await _ref.read(userProfileProvider.future);
    final responseMs = state.cellStartTime != null
        ? DateTime.now().difference(state.cellStartTime!).inMilliseconds
        : 60000;

    AnswerResult? result;
    var activeCell = cell;
    var activePuzzleCellId = puzzleCellId;
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        result = await _repo.validateAnswer(
          puzzleId: puzzle.id,
          puzzleCellId: activePuzzleCellId,
          rowClubId: rowClub.id,
          colClubId: colClub.id,
          playerId: player.id,
          sessionId: state.sessionId!,
          userUuid: profile.userUuid,
          responseTimeMs: responseMs,
        );
        break;
      } catch (e, st) {
        if (attempt == 0 &&
            _isCellNotFoundError(e) &&
            await _refreshCellsFromServer()) {
          final refreshedCell = state.cells[key];
          if (refreshedCell == null) {
            state = state.copyWith(clearValidatingCell: true);
            rethrow;
          }
          activeCell = refreshedCell;
          activePuzzleCellId = _resolvePuzzleCellId(
                puzzle: state.puzzle!,
                row: row,
                col: col,
                cell: activeCell,
              ) ??
              activeCell.id;
          continue;
        }
        cbDebugError('Session', 'validateAnswer failed', e, st);
        state = state.copyWith(clearValidatingCell: true);
        rethrow;
      }
    }
    final answer = result;
    if (answer == null) {
      state = state.copyWith(clearValidatingCell: true);
      throw const PuzzleFetchException(
        'cell_not_found',
        errorCode: 'cell_not_found',
      );
    }

    final latencyMs = DateTime.now().difference(submitStart).inMilliseconds;

    if (answer.correct) {
      final remainingMs = params.mode.isTimedTraining
          ? _quickGridRemainingMs()
          : 0;
      final cellScore = params.mode.isTimedTraining
          ? ScoringEngine.quickGridCellScore(remainingSessionMs: remainingMs)
          : ScoringEngine.calculateCellScore(
              usagePercentage: answer.usagePercentage,
              responseTimeMs: responseMs,
              mistakesOnCell: 0,
            );

      final updatedCell = activeCell.copyWith(
        solvedPlayerId: player.id,
        solvedPlayerName: answer.playerName,
        isCorrect: true,
        usagePercentage: answer.usagePercentage,
        rarityScore: answer.rarityScore,
        cellScore: cellScore,
      );

      final newCells = Map<String, PuzzleCell>.from(state.cells);
      newCells[key] = updatedCell;

      final allScores = newCells.values
          .where((c) => c.cellScore != null)
          .map((c) => c.cellScore!)
          .toList();

      final allSolved =
          newCells.values.where((c) => c.isSolved).length == puzzle.totalCells;
      final isComplete = allSolved;

      final sessionScore = params.mode.isTimedTraining
          ? ScoringEngine.quickGridSessionScore(
              cellScores: allScores,
              mistakes: state.mistakes,
            )
          : ScoringEngine.calculateSessionScore(
              cellScores: allScores,
              hintsUsed: state.hintsUsed,
              mistakes: state.mistakes,
              completionBonus: ScoringEngine.completionBonusForMode(
                params.mode.name,
                fullGrid: allSolved,
              ),
            );

      state = state.copyWith(
        cells: newCells,
        totalScore: sessionScore,
        isComplete: isComplete,
        clearValidatingCell: true,
      );

      _ref.read(analyticsProvider).track('answer_submitted', properties: {
        'correct': true,
        'rarity_tier': answer.rarityTier,
        'latency_ms': latencyMs,
      });

      if (isComplete) {
        await _completeSession();
      } else {
        await _persistSnapshot();
      }
    } else {
      final nextMistakes = state.mistakes + 1;
      final previewScore = params.mode.isTimedTraining
          ? ScoringEngine.quickGridSessionScore(
              cellScores: state.cells.values
                  .where((c) => c.cellScore != null)
                  .map((c) => c.cellScore!)
                  .toList(),
              mistakes: nextMistakes,
            )
          : _scoreFromCells(
              state.cells,
              state.hintsUsed,
              mistakes: nextMistakes,
              totalCells: puzzle.totalCells,
              applyCompletionBonus: true,
            );
      state = state.copyWith(
        mistakes: nextMistakes,
        totalScore: previewScore,
        clearValidatingCell: true,
      );
      await _persistSnapshot();
      _ref.read(analyticsProvider).track('answer_submitted', properties: {
        'correct': false,
        'latency_ms': latencyMs,
      });
    }

    return answer;
  }

  void addHint(String cellKey, HintResult hint) {
    final hints = Map<String, List<HintResult>>.from(state.hintsRevealed);
    hints.putIfAbsent(cellKey, () => []).add(hint);
    final hintsUsed = state.hintsUsed + 1;
    final puzzle = state.puzzle;
    final totalScore = puzzle == null
        ? state.totalScore
        : _scoreFromCells(
            state.cells,
            hintsUsed,
            mistakes: state.mistakes,
            totalCells: puzzle.totalCells,
            applyCompletionBonus: true,
          );
    state = state.copyWith(
      hintsUsed: hintsUsed,
      hintsRevealed: hints,
      totalScore: totalScore,
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
      if (!rewarded) {
        throw const HintRequestException(
          'Ad unavailable',
          errorCode: 'ad_unavailable',
        );
      }
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

    final cell = await _ensureCellReady(key: key, row: row, col: col);
    if (cell == null) return null;

    final puzzleCellId = _resolvePuzzleCellId(
      puzzle: state.puzzle!,
      row: row,
      col: col,
      cell: cell,
    );
    if (puzzleCellId == null) {
      cbDebugError('Session', 'invalid puzzle cell id for hint', {
        'cellId': cell.id,
        'row': row,
        'col': col,
        'puzzleId': state.puzzle!.id,
      });
      throw const HintRequestException(
        'invalid_puzzle_cell_id',
        errorCode: 'invalid_puzzle_cell_id',
      );
    }

    HintResult? result;
    var activePuzzleCellId = puzzleCellId;
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        result = await _repo.requestHint(
          puzzleCellId: activePuzzleCellId,
          rowClubId: puzzle.rowClubAt(row).id,
          colClubId: puzzle.colClubAt(col).id,
          sessionId: sessionId,
          hintType: hintType,
          userUuid: profile.userUuid,
          adToken: adToken,
        );
        break;
      } on HintRequestException catch (e, st) {
        if (attempt == 0 &&
            _isCellNotFoundError(e) &&
            await _refreshCellsFromServer()) {
          final refreshedCell = state.cells[key];
          if (refreshedCell == null) {
            cbDebugError('Session', 'requestHint failed after refresh', e, st);
            rethrow;
          }
          activePuzzleCellId = _resolvePuzzleCellId(
                puzzle: state.puzzle!,
                row: row,
                col: col,
                cell: refreshedCell,
              ) ??
              refreshedCell.id;
          continue;
        }
        cbDebugError('Session', 'requestHint failed', e, st);
        rethrow;
      }
    }
    final hint = result;
    if (hint == null) {
      throw const HintRequestException(
        'cell_not_found',
        errorCode: 'cell_not_found',
      );
    }

    addHint(key, hint);
    _ref.read(analyticsProvider).track('hint_used', properties: {
      'hint_type': hint.hintType.name,
      'ad_watched': !isPremium,
      'hint_index': hintsOnCell + 1,
    });
    return hint;
  }

  Future<void> _completeSession() async {
    if (_sessionFinalized) return;

    _antiCheat?.evaluate();
    final metadata = _antiCheat?.toMetadata() ?? {};
    final durationMs = state.startedAt != null
        ? DateTime.now().difference(state.startedAt!).inMilliseconds
        : metadata['total_duration_ms'] as int? ?? 0;

    final profile = await _ref.read(userProfileProvider.future);
    final puzzle = state.puzzle!;
    final fullGrid =
        state.cells.values.where((c) => c.isSolved).length >= state.totalCells;

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
        'mode': params.mode.serverName,
        'finished_early': state.finishedEarly,
        if (params.mode == PuzzleMode.challenge && challengeResult != null)
          'challenge_won': challengeResult.youWon,
      },
    );

    SessionFlushResult flushResult = const SessionFlushResult(ok: false);
    for (var attempt = 0; attempt < 3; attempt++) {
      flushResult = await _repo.flushSessionCompletion(
        sessionId: state.sessionId!,
        userUuid: profile.userUuid,
        mode: params.mode.serverName,
        finishedEarly: state.finishedEarly,
        challengeWon: challengeResult?.youWon,
      );
      if (flushResult.ok || flushResult.isDailyAlreadyCompleted) break;
      await Future.delayed(Duration(milliseconds: 400 * (attempt + 1)));
    }

    final serverSynced = flushResult.ok || flushResult.isDailyAlreadyCompleted;
    if (!serverSynced &&
        !(params.mode == PuzzleMode.daily && fullGrid && !state.finishedEarly)) {
      cbDebug('Session', 'complete-session flush failed — will retry later', {
        'sessionId': state.sessionId,
        'error': flushResult.errorCode,
        'mode': params.mode.name,
      });
      return;
    }

    _sessionFinalized = true;

    if (flushResult.finalScore != null) {
      state = state.copyWith(totalScore: flushResult.finalScore!);
    }

    final resolvedScore = flushResult.finalScore ?? state.totalScore;

    if (params.mode == PuzzleMode.daily) {
      await _ref.read(dailyCompletionStoreProvider).markCompletedToday(
            userUuid: profile.userUuid,
            score: resolvedScore,
          );
      _ref.invalidate(dailyCompletedTodayProvider);
      _ref.invalidate(dailyTodayScoreProvider);
    }

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
      score: resolvedScore,
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
      'score': resolvedScore,
      'duration_ms': durationMs,
      'hints': state.hintsUsed,
      'mode': params.mode.name,
      'server_synced': serverSynced,
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
