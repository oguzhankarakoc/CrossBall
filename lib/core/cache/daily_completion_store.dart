import 'package:shared_preferences/shared_preferences.dart';

import '../utils/daily_puzzle_schedule.dart';

/// Client-side guard: daily puzzle finished for today's UTC calendar date.
/// Survives app restarts when server stats lag or session finalize failed.
class DailyCompletionStore {
  DailyCompletionStore({SharedPreferences? prefs}) : _prefsOverride = prefs;

  final SharedPreferences? _prefsOverride;
  static const _keyPrefix = 'daily_completed_date_v1_';

  Future<SharedPreferences> get _prefs async =>
      _prefsOverride ?? SharedPreferences.getInstance();

  String _key(String userUuid) => '$_keyPrefix$userUuid';

  Future<bool> isCompletedToday({required String userUuid}) async {
    final prefs = await _prefs;
    return prefs.getString(_key(userUuid)) ==
        DailyPuzzleSchedule.todayPuzzleDateUtc();
  }

  Future<void> markCompletedToday({required String userUuid}) async {
    final prefs = await _prefs;
    await prefs.setString(
      _key(userUuid),
      DailyPuzzleSchedule.todayPuzzleDateUtc(),
    );
  }

  Future<void> clearForUser({required String userUuid}) async {
    final prefs = await _prefs;
    await prefs.remove(_key(userUuid));
  }
}
