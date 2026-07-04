import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Last completed puzzle session — used for challenge creation.
class CompletedSessionInfo {
  const CompletedSessionInfo({
    required this.puzzleId,
    required this.sessionId,
    required this.score,
    required this.mistakes,
    required this.hintsUsed,
    required this.durationMs,
    this.mode = 'daily',
  });

  final String puzzleId;
  final String sessionId;
  final double score;
  final int mistakes;
  final int hintsUsed;
  final int durationMs;
  final String mode;
}

final lastCompletedSessionProvider =
    StateProvider<CompletedSessionInfo?>((ref) => null);
