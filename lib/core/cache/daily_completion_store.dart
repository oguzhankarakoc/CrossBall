import 'package:shared_preferences/shared_preferences.dart';

import '../utils/daily_puzzle_schedule.dart';

/// Client-side guard: daily puzzle finished for today's UTC calendar date.
/// Survives app restarts when server stats lag or session finalize failed.
class DailyCompletionStore {
  DailyCompletionStore({SharedPreferences? prefs}) : _prefsOverride = prefs;

  final SharedPreferences? _prefsOverride;
  static const _dateKeyPrefix = 'daily_completed_date_v1_';
  static const _scoreKeyPrefix = 'daily_completed_score_v1_';

  Future<SharedPreferences> get _prefs async =>
      _prefsOverride ?? SharedPreferences.getInstance();

  String _dateKey(String userUuid) => '$_dateKeyPrefix$userUuid';
  String _scoreKey(String userUuid) => '$_scoreKeyPrefix$userUuid';

  Future<bool> isCompletedToday({required String userUuid}) async {
    final prefs = await _prefs;
    return prefs.getString(_dateKey(userUuid)) ==
        DailyPuzzleSchedule.todayPuzzleDateUtc();
  }

  Future<double?> getTodayScore({required String userUuid}) async {
    final prefs = await _prefs;
    if (prefs.getString(_dateKey(userUuid)) !=
        DailyPuzzleSchedule.todayPuzzleDateUtc()) {
      return null;
    }
    return prefs.getDouble(_scoreKey(userUuid));
  }

  Future<void> markCompletedToday({
    required String userUuid,
    double? score,
  }) async {
    final prefs = await _prefs;
    final today = DailyPuzzleSchedule.todayPuzzleDateUtc();
    await prefs.setString(_dateKey(userUuid), today);
    if (score != null && score > 0) {
      await prefs.setDouble(_scoreKey(userUuid), score);
    }
  }

  Future<void> clearForUser({required String userUuid}) async {
    final prefs = await _prefs;
    await prefs.remove(_dateKey(userUuid));
    await prefs.remove(_scoreKey(userUuid));
  }
}
