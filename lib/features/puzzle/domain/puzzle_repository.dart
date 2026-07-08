import '../../puzzle/domain/puzzle.dart';

abstract interface class PuzzleRepository {
  Future<Puzzle> getDailyPuzzle({bool forceRefresh = false, String? userUuid});
  Future<Map<String, dynamic>> fetchDailyRolloutStatus();
  Future<Puzzle> getPuzzleById(String puzzleId);
  Future<Puzzle> getPracticePuzzle({
    required int gridSize,
    required String userUuid,
    String? excludePuzzleId,
  });
  Future<Puzzle> getChallengePuzzle(String challengeId);
  Future<AnswerResult> validateAnswer({
    required String puzzleId,
    required String puzzleCellId,
    required String rowClubId,
    required String colClubId,
    required String playerId,
    required String sessionId,
    required String userUuid,
    int? responseTimeMs,
  });
  Future<HintResult> requestHint({
    required String rowClubId,
    required String colClubId,
    required String puzzleCellId,
    required String sessionId,
    required HintType hintType,
    String? userUuid,
    String? adToken,
  });
  Future<bool> grantHintAdToken({
    required String userUuid,
    required String adToken,
    required String sessionId,
  });
  Future<SessionStartResult> createSession({
    required String puzzleId,
    required PuzzleMode mode,
    required int gridSize,
    String? userUuid,
  });
  Future<void> completeSession({
    required String sessionId,
    required double finalScore,
    required Map<String, dynamic> antiCheatMetadata,
  });

  /// Sends completion to the server when online; returns authoritative score.
  Future<SessionFlushResult> flushSessionCompletion({
    required String sessionId,
    required String userUuid,
    required String mode,
    required bool finishedEarly,
    bool? challengeWon,
  });
}
