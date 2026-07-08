import '../../features/puzzle/domain/puzzle.dart';
import '../../features/puzzle/presentation/daily_puzzle_rollout_provider.dart';
import '../utils/daily_puzzle_schedule.dart';

/// Business rules for the global daily puzzle lifecycle.
///
/// Timeline (Turkey UTC+3):
/// - 03:00 — GitHub Action starts (rollout: generating)
/// - 03:00–06:00 — puzzle may not exist yet; client must block stale play
/// - ~06:00 — pipeline finishes; rollout: ready; puzzle immutable for the UTC day
abstract final class DailyPuzzleContract {
  static String get todayUtc => DailyPuzzleSchedule.todayPuzzleDateUtc();

  /// Server rollout says play is not allowed yet.
  static bool shouldBlockLoad(DailyPuzzleRolloutStatus rollout) {
    if (rollout.puzzleDate != todayUtc) return true;
    if (rollout.phase == DailyPuzzleRolloutPhase.generating) return true;
    if (rollout.phase == DailyPuzzleRolloutPhase.pending) return true;
    if (rollout.phase == DailyPuzzleRolloutPhase.unavailable) return true;
    return false;
  }

  static String errorKeyForRollout(DailyPuzzleRolloutStatus rollout) {
    if (rollout.isFailed) return 'daily_puzzle_failed';
    return 'daily_puzzle_generating';
  }

  /// Active puzzle snapshot must match today's UTC calendar puzzle.
  static bool isSnapshotForToday(Map<String, dynamic>? snapshot) {
    if (snapshot == null) return false;
    final puzzleJson = snapshot['puzzle'] as Map<String, dynamic>?;
    if (puzzleJson == null) return false;
    final date = puzzleJson['date'] as String?;
    if (date == null || date != todayUtc) return false;
    final cachedDate = snapshot['puzzle_date'] as String?;
    if (cachedDate != null && cachedDate != todayUtc) return false;
    return true;
  }

  /// Published daily layout for [date] must not change mid-day.
  static bool layoutMatches(Puzzle cached, Puzzle fresh) =>
      cached.layoutFingerprint == fresh.layoutFingerprint;

  static Map<String, dynamic> snapshotMetadataFor(Puzzle puzzle) => {
        'puzzle_date': puzzle.date,
        'layout_fingerprint': puzzle.layoutFingerprint,
        'puzzle_id': puzzle.id,
      };
}
