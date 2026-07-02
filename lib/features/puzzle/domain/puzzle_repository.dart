import '../../puzzle/domain/puzzle.dart';

abstract interface class PuzzleRepository {
  Future<Puzzle> getDailyPuzzle({bool forceRefresh = false});
  Future<Puzzle> getPracticePuzzle({required int gridSize});
  Future<Puzzle> getChallengePuzzle(String challengeId);
  Future<AnswerResult> validateAnswer({
    required String puzzleId,
    required String puzzleCellId,
    required String rowClubId,
    required String colClubId,
    required String playerId,
    required String sessionId,
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
