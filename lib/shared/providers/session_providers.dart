import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Last completed puzzle session — used for challenge creation.
class CompletedSessionInfo {
  const CompletedSessionInfo({
    required this.puzzleId,
    required this.sessionId,
    required this.score,
    required this.mistakes,
    required this.hintsUsed,
    required this.durationMs,
  });

  final String puzzleId;
  final String sessionId;
  final double score;
  final int mistakes;
  final int hintsUsed;
  final int durationMs;
}

const _keyPracticeCount = 'crossball_practice_count';

final lastCompletedSessionProvider =
    StateProvider<CompletedSessionInfo?>((ref) => null);

final practiceGamesPlayedProvider =
    StateNotifierProvider<PracticeCounterNotifier, int>(
  (ref) => PracticeCounterNotifier(),
);

class PracticeCounterNotifier extends StateNotifier<int> {
  PracticeCounterNotifier() : super(0) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getInt(_keyPracticeCount) ?? 0;
  }

  Future<void> increment() async {
    state++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyPracticeCount, state);
  }

  Future<void> reset() async {
    state = 0;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPracticeCount);
  }
}
