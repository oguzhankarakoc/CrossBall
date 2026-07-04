import '../../puzzle/domain/puzzle.dart';

abstract interface class PuzzleRepository {
  Future<Puzzle> getDailyPuzzle({bool forceRefresh = false});
  Future<Puzzle> getPuzzleById(String puzzleId);
  Future<Puzzle> getPracticePuzzle({
    required int gridSize,
    required String userUuid,
  });
  Future<Puzzle> getChallengePuzzle(String challengeId);
  Future<AnswerResult> validateAnswer({
    required String puzzleId,
    required String puzzleCellId,
    required String rowClubId,
    required String colClubId,
    required String playerId,
    required String sessionId,
  });
  Future<HintResult> requestHint({
    required String puzzleCellId,
    required String rowClubId,
    required String colClubId,
    required String sessionId,
    required HintType hintType,
  });
  Future<String> createSession({
    required String puzzleId,
    required PuzzleMode mode,
    required int gridSize,
  });
  Future<void> completeSession({
    required String sessionId,
    required double finalScore,
    required Map<String, dynamic> antiCheatMetadata,
  });
}
